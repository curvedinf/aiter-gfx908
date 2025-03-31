import torch
import triton
import triton.language as tl
from utils.benchmark_utils import get_model_configs, get_available_models, mha_input_helper

from typing import Optional, Tuple

@triton.jit
def cdiv_fn(x, y):
    return (x + y - 1) // y

@triton.jit
def compute_fp8_scaling_factors(x, fp8_max: tl.constexpr):
    # compute fp8 scaling and descaling factor for a block
    x_amax = tl.max(tl.abs(x)) # NOTE: abs deals with negative values
    x_amax = tl.where(x_amax <= 1e-9, 1e-9, x_amax)
    scale_x = fp8_max / x_amax
    descale_x = x_amax / fp8_max
    return scale_x, descale_x

def is_fp8(x):
    if x.dtype in {torch.float8_e4m3fnuz, torch.float8_e4m3fn, torch.float8_e5m2, torch.float8_e5m2fnuz}:
        if arch_supports_fp8():
            return True
        else:
            raise RuntimeError("This device does not support fp8")
    else:
        return False


def cast_to_fp8(
    x: torch.Tensor,
    fp8_dtype,
    layout,
    clamp_val=1e-9,
):
    if len(x.shape) != 4:
        raise ValueError(f"'bshd' tensor should have shape [batch, seqlen, heads, dim], got {x.shape}")
    reduce_dims = (1, 3)  # seq_len and dim dimensions
   
    # Compute the absolute max along reduce_dims, clamped to avoid 0-scale
    x_abs_max = x.abs().amax(dim=reduce_dims)
    x_abs_max = torch.maximum(x_abs_max, x.new_tensor(clamp_val))

    # Unsqueeze back to a shape suitable for broadcast
    unsqueeze_dims = sorted(reduce_dims)
    for d in unsqueeze_dims:
        x_abs_max = x_abs_max.unsqueeze(d)

    # compute scale and descale
    fp8_max = torch.finfo(fp8_dtype).max
    scale = fp8_max / x_abs_max
    descale_factor = x_abs_max / fp8_max

    # cast to FP8, optionally setting requires_grad
    x_fp8 = (x * scale).to(fp8_dtype)

    return x_fp8, descale_factor


def cast_varlen_to_fp8(
    x: torch.Tensor,
    fp8_dtype: torch.dtype,
    cu_seqlens,
    clamp_val: float = 1e-9,
) -> tuple[torch.Tensor, torch.Tensor]:
    # validate tensor shape
    if len(x.shape) != 3:
        raise ValueError(f"tensor should have shape [total_seqlen, heads, dim], got {x.shape}")
    num_heads = x.shape[1]
    
    # Get batch size from cu_seqlens
    batch = cu_seqlens.shape[0] - 1
    fp8_max = torch.finfo(fp8_dtype).max
    
    # Compute scale and descale factors per sequence
    x_fp8 = torch.zeros_like(x, dtype=fp8_dtype)
    descale_factors = torch.zeros((batch, num_heads), device=x.device, dtype=torch.float32)
    
    for i in range(batch):
        start = cu_seqlens[i]
        end = cu_seqlens[i + 1]
        x_slice = x[start:end]  # Slice for current sequence
        
        # Standard tensor (0: seq_len, 2: head_dim)
        x_abs_max = x_slice.abs().amax(dim=(0, 2))  # [heads]
        
        # apply minimum clamping
        x_abs_max = torch.maximum(x_abs_max, x.new_tensor(clamp_val))
        
        # compute scale and descale factors
        scale_i = fp8_max / x_abs_max
        descale_i = x_abs_max / fp8_max
        
        # store descale factors
        descale_factors[i, :] = descale_i
        
        scale_reshape = scale_i.reshape(1, num_heads, 1)
        
        # scale and cast to FP8
        x_fp8[start:end] = (x_slice * scale_reshape).to(fp8_dtype)
        
    return x_fp8, descale_factors


#TODO Move this to a common folder. Will need to add future arch list
def get_arch():
    return triton.runtime.driver.active.get_current_target().arch

def is_hip():
    return triton.runtime.driver.active.get_current_target().backend == "hip"

def arch_supports_fp8():
    return is_hip() and get_arch() in ('gfx942')

@triton.jit
def load_fn(ptrs, offset_first, offset_second, boundary_first, boundary_second):
    if offset_first is not None and offset_second is not None:
        mask = (offset_first[:, None] < boundary_first) & \
               (offset_second[None, :] < boundary_second)
        tensor = tl.load(ptrs, mask=mask, other=0.0)
    elif offset_first is not None:
        mask = offset_first[:, None] < boundary_first
        tensor = tl.load(ptrs, mask=mask, other=0.0)
    elif offset_second is not None:
        mask = offset_second[None, :] < boundary_second
        tensor = tl.load(ptrs, mask=mask, other=0.0)
    else:
        tensor = tl.load(ptrs)
    return tensor

@triton.jit
def compute_alibi_block(alibi_slope, seqlen_q, seqlen_k, offs_m, offs_n, transpose=False):
    # when seqlen_k and seqlen_q are different we want the diagonal to stick to the bottom right of the attention matrix
    # for casual mask we want something like this where (1 is kept and 0 is masked)
    # seqlen_q = 2 and seqlen_k = 5
    #   1 1 1 1 0
    #   1 1 1 1 1
    # seqlen_q = 5 and seqlen_k = 2
    #        0 0
    #        0 0
    #        0 0
    #        1 0
    #        1 1
    # for alibi the diagonal is 0 indicating no penalty for attending to that spot and increasing penalty for attending further from the diagonal
    # e.g. alibi_slope = 1, seqlen_q = 2, seqlen_k = 5, offs_m = [0, 1, 2, 3], offs_n = [0, 1, 2, 3, 4], transpose = False
    # 1. offs_m[:,None] = [[0],
    #                       [1],
    # 2. offs_m[:,None] + seqlen_k = [[5],
    #                                  [6],
    # 3. offs_m[:,None] + seqlen_k - seqlen_q = [[3],
    #                                             [4],
    # 4. offs_m[:,None] + seqlen_k - seqlen_q - offs_n[None,:] = [[3], - [[0, 1, 2, 3, 4]] =  [[ 3, 2, 1, 0,-1],
    #                                                            [4],                           [ 4, 3, 2, 1, 0]]
    # 5. -1 * alibi_slope * tl.abs(relative_pos_block) = [[ -3, -2, -1, 0,-1],
    #                                                     [ -4, -3, -2, -1, 0]],
    relative_pos_block = offs_m[:, None] + seqlen_k - seqlen_q - offs_n[None, :]
    alibi_block = -1 * alibi_slope * tl.abs(relative_pos_block)
    if transpose:
        return alibi_block.T
    else:
        return alibi_block

@triton.jit
def _attn_fwd_inner(
    acc,
    l_i,
    m_i,
    q,
    k_ptrs,
    v_ptrs,
    stride_kn,
    stride_vk,
    stride_sn,
    start_m,
    seqlen_k,
    seqlen_q, 
    dropout_p,
    sd_mask_ptrs,
    dropout_mask_ptrs,
    philox_seed,
    philox_ptrs,
    block_min,
    block_max,
    offs_n_causal,
    masked_blocks,
    n_extra_tokens,
    alibi_slope,
    descale_q, 
    descale_k, 
    descale_v,
    OFFS_M: tl.constexpr,
    OFFS_N: tl.constexpr,
    BLOCK_M: tl.constexpr,
    BLOCK_N: tl.constexpr,
    BLOCK_DMODEL: tl.constexpr,
    BLOCK_DMODEL_POW2: tl.constexpr,
    SM_SCALE: tl.constexpr,
    IS_CAUSAL: tl.constexpr,
    MASK_STEPS: tl.constexpr,
    ENABLE_DROPOUT: tl.constexpr,
    RETURN_SCORES: tl.constexpr,
    PADDED_HEAD: tl.constexpr,
    IS_FP8: tl.constexpr, 
    FP8_MAX: tl.constexpr,
):
    RCP_LN2: tl.constexpr = 1.4426950408889634

    # loop over k, v, and update accumulator

    for start_n in range(block_min, block_max, BLOCK_N):
        # For padded blocks, we will overrun the tensor size if
        # we load all BLOCK_N. For others, the blocks are all within range.
        if MASK_STEPS:
            k_offs_n = start_n + tl.arange(0, BLOCK_N)
        else:
            k_offs_n = None
        k_offs_k = None if not PADDED_HEAD else tl.arange(0, BLOCK_DMODEL_POW2)
        k = load_fn(k_ptrs, k_offs_k, k_offs_n, BLOCK_DMODEL, seqlen_k)

        qk = tl.zeros([BLOCK_M, BLOCK_N], dtype=tl.float32)
        # We start from end of seqlen_k so only the first iteration would need
        # to be checked for padding if it is not a multiple of block_n
        # TODO: This can be optimized to only be true for the padded block.
        if MASK_STEPS:
            # If this is the last block / iteration, we want to
            # mask if the sequence length is not a multiple of block size
            # a solution is to always do BLOCK_M // BLOCK_N + 1 steps if not is_modulo_mn.
            # last step might get wasted but that is okay. check if this masking works For
            # that case.
            if (start_n + BLOCK_N == block_max) and (n_extra_tokens != 0):
                boundary_m = tl.full([BLOCK_M], seqlen_k, dtype=tl.int32)
                size_n = start_n + OFFS_N[None, :]
                mask = size_n < boundary_m[:, None]
                qk = tl.where(mask, qk, float("-inf"))

        # compute masks
        q_mask = (OFFS_M[:, None] < seqlen_q)
        k_mask = ((start_n + tl.arange(0, BLOCK_N))[None, :] < seqlen_k)
        p_mask = q_mask & k_mask

        # -- compute qk ----
        if IS_FP8:
            qk += (tl.dot(q, k) * descale_q * descale_k)
        else:
            qk += tl.dot(q, k)
        qk_scaled =  qk * SM_SCALE

        if IS_CAUSAL:
            causal_boundary = start_n + offs_n_causal
            causal_mask = OFFS_M[:, None] >= causal_boundary[None, :]
            qk_scaled = tl.where(causal_mask, qk_scaled, float("-inf"))

        if alibi_slope is not None:
            # Compute the global position of each token within the sequence
            global_m_positions = start_m * BLOCK_M + tl.arange(0, BLOCK_M)
            global_n_positions = start_n + tl.arange(0, BLOCK_N)
            alibi_block = compute_alibi_block(alibi_slope, seqlen_q, seqlen_k, global_m_positions,
                                              global_n_positions)
            qk_scaled += alibi_block
        # get max scores so far
        m_ij = tl.maximum(m_i, tl.max(qk_scaled, 1))

        # scale and subtract max
        q_shifted = qk_scaled - m_ij[:, None]
        
        # Compute scaled QK and softmax probabilities
        p = tl.math.exp2(q_shifted * RCP_LN2)

        # CAVEAT: Must update l_ij before applying dropout
        l_ij = tl.sum(p, 1)
        if ENABLE_DROPOUT:
            rng_output = tl.rand(philox_seed, philox_ptrs)  # TODO: use tl.randint for better performance
            dropout_mask = rng_output > dropout_p
            tl.store(dropout_mask_ptrs, dropout_mask, mask=p_mask)

            # return scores with negative values for dropped vals
            sd_mask = tl.where(dropout_mask, p, -p)
            tl.store(sd_mask_ptrs, sd_mask, mask=p_mask)

            # apply dropout mask in place
            p = tl.where(dropout_mask, p, 0.0)
        elif RETURN_SCORES:
            # NOTE: the returned score is not the same as the reference because we need to adjust as we find new maxes per block. We are not doing that
            tl.store(sd_mask_ptrs, p, mask=p_mask)
        
        # -- update output accumulator --
        # alpha is an adjustment factor for acc and li as we loop and find new maxes
        # store the diff in maxes to adjust acc and li as we discover new maxes
        m_diff = m_i - m_ij
        alpha = tl.math.exp2(m_diff * RCP_LN2)
        acc = acc * alpha[:, None]
        v = load_fn(v_ptrs, k_offs_n, k_offs_k, seqlen_k, BLOCK_DMODEL)
        # -- update m_i and l_i
        l_i = l_i * alpha + l_ij
        # update m_i and l_i
        m_i = m_ij

        if IS_FP8:
            scale_p, descale_p = compute_fp8_scaling_factors(p, FP8_MAX)
            acc += (tl.dot((p * scale_p).to(v.type.element_ty), v) * descale_p * descale_v)
        else:
            acc += tl.dot(p.to(v.type.element_ty), v)

        k_ptrs += BLOCK_N * stride_kn
        v_ptrs += BLOCK_N * stride_vk
        if RETURN_SCORES:
            sd_mask_ptrs += BLOCK_N * stride_sn
        
        if ENABLE_DROPOUT:
            dropout_mask_ptrs += BLOCK_N * stride_sn
            philox_ptrs += BLOCK_N * stride_sn
    
    return acc, l_i, m_i


@triton.jit
def _attn_fwd(q_ptr: torch.Tensor, 
            k_ptr: torch.Tensor, 
            v_ptr: torch.Tensor,
            descale_q_ptr: torch.Tensor,
            descale_k_ptr: torch.Tensor,
            descale_v_ptr: torch.Tensor,
            out_ptr: torch.Tensor,
            alibi_slopes_ptr: torch.Tensor,
            s_dmask_ptr: torch.Tensor,
            dropout_mask_ptr: torch.Tensor,
            softmax_lse_ptr: torch.Tensor,
            stride_qz, stride_qh, stride_qm, stride_qk,
            stride_kz, stride_kh, stride_kn, stride_kk,
            stride_vz, stride_vh, stride_vn, stride_vk,
            stride_descale_q_z, stride_descale_k_z, stride_descale_v_z,
            stride_oz, stride_oh, stride_om, stride_on,
            stride_alibi_z, stride_alibi_h,
            stride_sd_z, stride_sd_h, stride_sd_m, stride_sd_n,
            stride_lse_z, stride_lse_h, stride_lse_m,
            sm_scale,
            cu_seqlens_q,
            cu_seqlens_k,
            dropout_p,
            philox_seed,
            philox_offset,
            SEQLEN_Q: tl.constexpr,
            SEQLEN_K: tl.constexpr,
            IS_CAUSAL: tl.constexpr,
            NUM_Q_HEADS: tl.constexpr,
            NUM_K_HEADS: tl.constexpr,
            BLOCK_M: tl.constexpr,
            BLOCK_N: tl.constexpr,
            BLOCK_DMODEL: tl.constexpr,
            BLOCK_DMODEL_POW2: tl.constexpr,
            RETURN_SCORES: tl.constexpr,
            ENABLE_DROPOUT: tl.constexpr,
            IS_FP8: tl.constexpr,
            FP8_MAX: tl.constexpr,
            VARLEN: tl.constexpr,
):
    #calculate offsets
    start_m = tl.program_id(0) #seqlen_q
    off_q_head = tl.program_id(1)  #num_q_heads
    off_z = tl.program_id(2) #batch

    offs_m = start_m * BLOCK_M + tl.arange(0, BLOCK_M)
    offs_n = tl.arange(0, BLOCK_N)
    offs_d = tl.arange(0, BLOCK_DMODEL_POW2)

    if VARLEN:
        cu_seqlens_q_start = tl.load(cu_seqlens_q + off_z)
        cu_seqlens_q_end = tl.load(cu_seqlens_q + off_z + 1)

        seqlen_q = cu_seqlens_q_end - cu_seqlens_q_start
        # We have a one-size-fits-all grid in id(0). Some seqlens might be too
        # small for all start_m so for those we return early.
        if start_m * BLOCK_M > seqlen_q:
            return
        cu_seqlens_k_start = tl.load(cu_seqlens_k + off_z)
        cu_seqlens_k_end = tl.load(cu_seqlens_k + off_z + 1)
        seqlen_k = cu_seqlens_k_end - cu_seqlens_k_start
    else:
        cu_seqlens_q_start = 0
        cu_seqlens_k_start = 0
        seqlen_q = SEQLEN_Q
        seqlen_k = SEQLEN_K

    n_blocks = cdiv_fn(seqlen_k, BLOCK_N)

    # Now we compute whether we need to exit early due to causal masking.
    # This is because for seqlen_q > seqlen_k, M rows of the attn scores
    # are completely masked, resulting in 0s written to the output, and
    # inf written to LSE. We don't need to do any GEMMs in this case.
    # This block of code determines what N is, and if this WG is operating
    # on those M rows.
    if (IS_CAUSAL):
        # If seqlen_q == seqlen_k, the attn scores are a square matrix.
        # If seqlen_q != seqlen_k, attn scores are rectangular which means
        # the causal mask boundary is bottom right aligned, and ends at either
        # the top edge (seqlen_q < seqlen_k) or left edge.

        # This captures the decrease in n_blocks if we have a rectangular attn matrix
        n_blocks_seqlen = cdiv_fn((start_m + 1) * BLOCK_M + seqlen_k - seqlen_q, BLOCK_N)

        # This is what adjusts the block_max for the current WG, only
        # if IS_CAUSAL. Otherwise we want to always iterate through all n_blocks
        n_blocks = min(n_blocks, n_blocks_seqlen)

        # If we have no blocks after adjusting for seqlen deltas, this WG is part of
        # the blocks that are all 0. We exit early.
        if n_blocks <= 0:
            offs_out = (off_z * stride_oz + 
                        off_q_head * stride_oh + 
                        cu_seqlens_q_start * stride_om +
                        offs_m[:, None] * stride_om + 
                        offs_d[None, :] * stride_on)
            acc = tl.zeros([BLOCK_M, BLOCK_DMODEL_POW2], dtype=out_ptr.type.element_ty)
            out_mask = (offs_m[:, None] < seqlen_q) & (offs_d < BLOCK_DMODEL)
            tl.store(out_ptr + offs_out, acc, mask=out_mask)

            if softmax_lse_ptr is not None:
                offs_lse = (off_z * stride_lse_z + 
                            off_q_head * stride_lse_h +
                            cu_seqlens_q_start * stride_lse_m + 
                            offs_m*stride_lse_m
                            )
                lse_mask = offs_m < SEQLEN_Q
                lse = tl.full([BLOCK_M], value=0.0, dtype=tl.float32)
                tl.store(softmax_lse_ptr + offs_lse, lse, mask=lse_mask)
                # TODO: Should dropout and return encoded softmax be handled here too?

            return

    grp_sz:tl.constexpr = NUM_Q_HEADS // NUM_K_HEADS 
    if grp_sz != 1: #Grouped Query Attention
        off_k_head = off_q_head // grp_sz 
    else: 
        off_k_head = off_q_head

    #q,k,v offsets
    q_offs = (off_z * stride_qz + 
                off_q_head * stride_qh +
                cu_seqlens_q_start * stride_qm +
                offs_m[:, None] * stride_qm + offs_d[None, :]*stride_qk
    )
    q_ptrs = q_ptr + q_offs

    k_offs = (off_z * stride_kz + 
                off_k_head * stride_kh +
                cu_seqlens_k_start * stride_kn +
                offs_d[:, None] * stride_kk + offs_n[None, :]*stride_kn
    )
    k_ptrs = k_ptr + k_offs

    v_offs = (off_z * stride_vz + 
                off_k_head * stride_vh +
                cu_seqlens_k_start * stride_vn +
                offs_n[:, None] * stride_vn + offs_d[None, :]*stride_vk
    )
    v_ptrs = v_ptr + v_offs

    #alibi slopes
    if alibi_slopes_ptr is not None:
        alibi_offs = off_z * stride_alibi_z + off_q_head * stride_alibi_h
        alibi_slope = tl.load(alibi_slopes + alibi_offs)
    else:
        alibi_slope = None

    #s_dmask (return_scores)
    if s_dmask_ptr is not None:
        s_dmask_offs =  (off_z * stride_sd_z + 
                        off_q_head * stride_sd_h + 
                        offs_m[:, None] * stride_sd_m +
                        offs_n[None, :] * stride_sd_n
        )
        s_dmask_ptrs = s_dmask_ptr + s_dmask_offs
    else:
        s_dmask_ptrs = None

    #dropout 
    if dropout_mask_ptr is not None:
        dropout_mask_offs =  (off_z * stride_sd_z + 
                        off_q_head * stride_sd_h + 
                        offs_m[:, None] * stride_sd_m +
                        offs_n[None, :] * stride_sd_n
        )
        dropout_mask_ptrs = dropout_mask_ptr + dropout_mask_offs
        philox_ptrs = (philox_offset + 
                        off_z * stride_sd_z + 
                        off_q_head * stride_sd_h  + 
                        offs_m[:, None] * stride_sd_m + 
                        offs_n[None, :] * stride_sd_n
        )
    else:
        dropout_mask_ptrs = None
        philox_ptrs = None

    m_i = tl.full([BLOCK_M], float("-inf"), dtype=tl.float32)
    l_i = tl.full([BLOCK_M], 1.0, dtype=tl.float32)
    acc = tl.zeros([BLOCK_M, BLOCK_DMODEL_POW2], dtype=tl.float32)
    if (BLOCK_DMODEL == BLOCK_DMODEL_POW2):
        q_mask = (offs_m[:, None] < seqlen_q) 
    else:
        q_mask = (offs_m[:, None] < seqlen_q) & (offs_d[None, :] < BLOCK_DMODEL)
    q = tl.load(q_ptrs, mask=q_mask, other=0.0)

    if IS_FP8:
        descale_q = tl.load(descale_q_ptr + off_z * stride_descale_q_z + off_q_head)
        descale_k = tl.load(descale_k_ptr + off_z * stride_descale_k_z + off_k_head)
        descale_v = tl.load(descale_v_ptr + off_z * stride_descale_v_z + off_k_head)
    else:
        descale_q, descale_k ,descale_v = 1.0, 1.0, 1.0

    n_extra_tokens = 0
    if seqlen_k < BLOCK_N:
        n_extra_tokens = BLOCK_N -seqlen_k 
    elif seqlen_k % BLOCK_N:
        n_extra_tokens = seqlen_k % BLOCK_N
    
    #if CAUSAL, then determine masked_blocks and full blocks
    # Here we compute how many full and masked blocks we have.
    padded_block_k = n_extra_tokens != 0
    is_modulo_mn = not padded_block_k and (seqlen_q % BLOCK_M == 0)
    if IS_CAUSAL:
        # There are always at least BLOCK_M // BLOCK_N masked blocks.
        # Additionally there might be one more due to dissimilar seqlens.
        masked_blocks = BLOCK_M // BLOCK_N + (not is_modulo_mn)
    else:
        # Padding on Q does not need to be masked in the FA loop.
        masked_blocks = padded_block_k
    # if IS_CAUSAL, not is_modulo_mn does not always result in an additional block.
    # In this case we might exceed n_blocks so pick the min.
    masked_blocks = min(masked_blocks, n_blocks)
    n_full_blocks = n_blocks - masked_blocks
    block_min = 0
    block_max = n_blocks * BLOCK_N
    # Compute for full blocks. Here we set causal to false regardless of its actual
    # value because there is no masking. Similarly we do not need padding.
    if n_full_blocks > 0:
        block_max = (n_blocks - masked_blocks) * BLOCK_N
        acc, l_i, m_i = _attn_fwd_inner(acc, 
                                        l_i, 
                                        m_i, 
                                        q, 
                                        k_ptrs, 
                                        v_ptrs, 
                                        stride_kn, 
                                        stride_vn, 
                                        stride_sd_n,
                                        start_m, 
                                        seqlen_k, 
                                        seqlen_q, 
                                        dropout_p, 
                                        s_dmask_ptrs, dropout_mask_ptrs, philox_seed, philox_ptrs,
                                        block_min, block_max, 0, 0, 0, alibi_slope, 
                                        descale_q, descale_k, descale_v,
                                        offs_m, offs_n, BLOCK_M, BLOCK_N, BLOCK_DMODEL,BLOCK_DMODEL_POW2,
                                        sm_scale, IS_CAUSAL, MASK_STEPS=False, ENABLE_DROPOUT=ENABLE_DROPOUT, 
                                        RETURN_SCORES=RETURN_SCORES, PADDED_HEAD=BLOCK_DMODEL!=BLOCK_DMODEL_POW2,
                                        IS_FP8=IS_FP8, FP8_MAX=FP8_MAX
                                        )
        block_min = block_max
        block_max = n_blocks * BLOCK_N

      # Remaining blocks, if any, are full / not masked.
    if (masked_blocks > 0):
        if IS_CAUSAL:
            offs_n_causal = offs_n + (seqlen_q - seqlen_k)
        else:
            offs_n_causal = 0
        k_ptrs += n_full_blocks * BLOCK_N * stride_kn
        v_ptrs += n_full_blocks * BLOCK_N * stride_vn
        if RETURN_SCORES:
            s_dmask_ptrs += n_full_blocks * BLOCK_N * stride_sd_n
        if ENABLE_DROPOUT:
            dropout_mask_ptrs += n_full_blocks * BLOCK_N * stride_sd_n
        acc, l_i, m_i = _attn_fwd_inner(acc, 
                                        l_i, 
                                        m_i, 
                                        q, 
                                        k_ptrs, 
                                        v_ptrs, 
                                        stride_kn, stride_vn, stride_sd_n,
                                        start_m, seqlen_k, seqlen_q, 
                                        dropout_p, 
                                        s_dmask_ptrs, dropout_mask_ptrs, philox_seed, philox_ptrs,
                                        block_min, block_max, offs_n_causal, masked_blocks, n_extra_tokens, alibi_slope, 
                                        descale_q, descale_k, descale_v,
                                        offs_m, offs_n, BLOCK_M, BLOCK_N, BLOCK_DMODEL,BLOCK_DMODEL_POW2,
                                        sm_scale, IS_CAUSAL, MASK_STEPS=True, ENABLE_DROPOUT=ENABLE_DROPOUT, 
                                        RETURN_SCORES=RETURN_SCORES, PADDED_HEAD=BLOCK_DMODEL!=BLOCK_DMODEL_POW2,
                                        IS_FP8=IS_FP8, FP8_MAX=FP8_MAX
                                        )
    # epilogue
    # This helps the compiler do Newton Raphson on l_i vs on acc which is much larger.
    l_recip = 1 / l_i[:, None]
    acc = acc * l_recip

    if ENABLE_DROPOUT:
        dropout_scale = 1 / (1 - dropout_p)
        acc = acc * dropout_scale
    # If seqlen_q > seqlen_k but the delta is not a multiple of BLOCK_M,
    # then we have one block with a row of all NaNs which come from computing
    # softmax over a row of all -infs (-inf - inf = NaN). We check for that here
    # and store 0s where there are NaNs as these rows should've been zeroed out.
    end_m_idx = (start_m + 1) * BLOCK_M
    start_m_idx = start_m * BLOCK_M
    causal_start_idx = seqlen_q - seqlen_k
    if IS_CAUSAL:
        if causal_start_idx > start_m_idx and causal_start_idx < end_m_idx:
            out_mask_boundary = tl.full((BLOCK_DMODEL_POW2, ), causal_start_idx, dtype=tl.int32)
            mask_m_offsets = start_m_idx + tl.arange(0, BLOCK_M)
            out_ptrs_mask = mask_m_offsets[:, None] >= out_mask_boundary[None, :]
            z = 0.0
            acc = tl.where(out_ptrs_mask, acc, z.to(acc.type.element_ty))

    # write back LSE(Log Sum Exponents), the log of the normalization constant
    overflow_size = end_m_idx - seqlen_q 
    if softmax_lse_ptr is not None: 
        RCP_LN2: tl.constexpr = 1.4426950408889634
        LN2: tl.constexpr = 0.6931471824645996
        # compute log-sum-exp in base 2 units
        mi_base2 = m_i * RCP_LN2
        softmax_lse = mi_base2 + tl.math.log2(l_i)
        # convert back to natural units
        softmax_lse *= LN2
    
        if IS_CAUSAL:
            # zero out nans caused by -infs when doing causal
            lse_causal_mask = (start_m_idx + tl.arange(0, BLOCK_M)) < causal_start_idx
            softmax_lse = tl.where(lse_causal_mask, 0.0, softmax_lse)

        # If seqlen_q not multiple of BLOCK_M, we need to mask out the last few rows.
        # This is only true for the last M block. For others, overflow_size will be -ve
        offs_lse = off_z * stride_lse_z + off_q_head * stride_lse_h +  cu_seqlens_q_start * stride_lse_m + offs_m*stride_lse_m
        if overflow_size > 0:
            boundary = tl.full((BLOCK_M, ), BLOCK_M - overflow_size, dtype=tl.int32)
            lse_mask = tl.arange(0, BLOCK_M) < boundary
            tl.store(softmax_lse_ptr + offs_lse, softmax_lse, mask=lse_mask) # the log of the normalization constant
        else:
            tl.store(softmax_lse_ptr + offs_lse, softmax_lse) # the log of the normalization constant

    # write back O
    offs_out = (off_z * stride_oz + 
                off_q_head * stride_oh + 
                cu_seqlens_q_start * stride_om +
                offs_m[:, None] * stride_om + 
                offs_d[None, :] * stride_on) 
    out_mask = tl.full([BLOCK_M, BLOCK_DMODEL_POW2], 1, dtype=tl.int1)
    if overflow_size > 0:
        out_mask = out_mask & (offs_m[:, None] < seqlen_q)
    if BLOCK_DMODEL != BLOCK_DMODEL_POW2:
        out_mask = out_mask & (offs_d[None, :] < BLOCK_DMODEL)
    op =  acc.to(out_ptr.dtype.element_ty)
    tl.store(out_ptr + offs_out, op, mask=out_mask)

def _flash_attn_forward(
    q: torch.Tensor,
    k: torch.Tensor,
    v: torch.Tensor,
    dropout_p: float,
    softmax_scale: float,
    causal: bool,
    window_size_left: int,
    window_size_right: int,
    alibi_slopes: Optional[torch.Tensor],
    return_lse: bool,
    return_softmax: bool,
    max_seqlen_q: int,
    max_seqlen_k: int,
    cu_seqlens_q: Optional[torch.Tensor] = None,
    cu_seqlens_k: Optional[torch.Tensor] = None,
    descale_q: Optional[torch.Tensor] = None,
    descale_k: Optional[torch.Tensor] = None,
    descale_v: Optional[torch.Tensor] = None,
) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor]:

    #FP8
    IS_FP8 = is_fp8(q)
    FP8_MAX: tl.constexpr=torch.finfo(q.dtype).max
    is_varlen = True if cu_seqlens_q is not None else False

    if IS_FP8:
        o = torch.zeros_like(q, dtype=torch.float32) 
    else:
        o = torch.zeros_like(q)
    
    if is_varlen:
        #Layout for q,k,v is thd ie [total_tokens, num_head, head_dim] 
        batch, seqlen_q, num_q_heads, head_sz  = len(cu_seqlens_q) - 1, max_seqlen_q, q.shape[1], q.shape[2]
        seqlen_k, num_k_heads =  max_seqlen_k, k.shape[1] 
        q_strides = (0, q.stride(1), q.stride(0), q.stride(2))
        k_strides = (0, k.stride(1), k.stride(0), k.stride(2))
        v_strides = (0, v.stride(1), v.stride(0), v.stride(2))
        o_strides = (0, o.stride(1), o.stride(0), o.stride(2))
    else:
        #Layout for q,k,v is bshd ie [batch, seq_len, num_head, head_dim] 
        batch, seqlen_q, num_q_heads, head_sz = q.shape
        seqlen_k = k.shape[1]
        num_k_heads = k.shape[2]
        q_strides = (q.stride(0), q.stride(2), q.stride(1), q.stride(3))
        k_strides = (k.stride(0), k.stride(2), k.stride(1), k.stride(3))
        v_strides = (v.stride(0), v.stride(2), v.stride(1), v.stride(3))
        o_strides = (o.stride(0), o.stride(2), o.stride(1), o.stride(3))

    #padding for head_dim. Power of 2 or 16
    BLOCK_DMODEL_POW2 = triton.next_power_of_2(head_sz)
    BLOCK_DMODEL_POW2 = max(BLOCK_DMODEL_POW2, 16)

    #softmax_lse [batch, num_q_heads, seqlen_q]
    if return_lse:
        if is_varlen:
            softmax_lse = torch.zeros((q.shape[0], num_q_heads), device=q.device, dtype=torch.float32)
            stride_lse_z, stride_lse_h, stride_lse_m = 0, softmax_lse.stride(1), softmax_lse.stride(0)
        else:
            softmax_lse = torch.zeros((batch, num_q_heads, max_seqlen_q), device=q.device, dtype=torch.float32)
            stride_lse_z, stride_lse_h, stride_lse_m = softmax_lse.stride()
    else:
        softmax_lse = None

    #exp_scores [batch, num_q_heads, seqlen_q, seqlen_k]
    enable_dropout = dropout_p > 0.0
    if enable_dropout:
        philox_seed = torch.randint(0, 0xffffff, (1,))[0].item() #No specific reason to restrict range to 0xffffff
        philox_offset = torch.randint(0, 0xffffff, (1,))[0].item() #Pass in an int, not Tensor
    else:
        philox_seed = 0
        philox_offset = 0
    if return_softmax or enable_dropout:
        s_dmask = torch.zeros((batch, num_q_heads, max_seqlen_q, max_seqlen_k), device=q.device, dtype=torch.float32)
        dropout_mask = torch.zeros((batch, num_q_heads, max_seqlen_q, max_seqlen_k), device=q.device, dtype=torch.float32)
    else:
        s_dmask = None
        dropout_mask = None


    BLOCK_M = 32 #TODO. Add config/tuning support
    BLOCK_N = 32 #TODO Add config/tuning support
    grid = lambda META:(triton.cdiv(seqlen_q, META['BLOCK_M']), num_q_heads, batch)


    _attn_fwd[grid](q,
                    k,
                    v,
                    descale_q,
                    descale_k,
                    descale_v,
                    o,
                    alibi_slopes,
                    s_dmask,
                    dropout_mask,
                    softmax_lse,
                    *q_strides,
                    *k_strides, 
                    *v_strides, 
                    descale_q.stride(0) if descale_q is not None else 0,
                    descale_k.stride(0) if descale_k is not None else 0,
                    descale_v.stride(0) if descale_v is not None else 0,
                    *o_strides,
                    alibi_slopes.stride(0) if alibi_slopes is not None else 0,
                    alibi_slopes.stride(1) if alibi_slopes is not None else 0,
                    s_dmask.stride(0) if s_dmask is not None else 0,
                    s_dmask.stride(1) if s_dmask is not None else 0,
                    s_dmask.stride(2) if s_dmask is not None else 0,
                    s_dmask.stride(3) if s_dmask is not None else 0,
                    stride_lse_z if softmax_lse is not None else 0,
                    stride_lse_h if softmax_lse is not None else 0,
                    stride_lse_m if softmax_lse is not None else 0,
                    softmax_scale, 
                    cu_seqlens_q,
                    cu_seqlens_k,
                    dropout_p,
                    philox_seed,
                    philox_offset,
                    SEQLEN_Q=max_seqlen_q,
                    SEQLEN_K=max_seqlen_k,
                    IS_CAUSAL=causal,
                    NUM_Q_HEADS=num_q_heads,
                    NUM_K_HEADS=num_k_heads,
                    BLOCK_M=BLOCK_M,
                    BLOCK_N=BLOCK_N,
                    BLOCK_DMODEL=head_sz,
                    BLOCK_DMODEL_POW2=BLOCK_DMODEL_POW2,
                    RETURN_SCORES=return_softmax,
                    ENABLE_DROPOUT=enable_dropout,
                    IS_FP8=IS_FP8,
                    FP8_MAX=FP8_MAX,
                    VARLEN=is_varlen,
    )

    return o, softmax_lse, s_dmask 


class FlashAttnFunc(torch.autograd.Function):
    @staticmethod
    def forward(
        ctx,
        q,
        k,
        v,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_softmax,
        is_grad_enabled, #TODO add bkwd support
    ):
        is_grad = is_grad_enabled and any(
            x.requires_grad for x in [q,k,v]
        )
        if softmax_scale is None:
            softmax_scale = q.shape[-1] ** (-0.5)
        head_size_og = q.size(3)
        if head_size_og % 8 != 0:
            q = torch.nn.functional.pad(q, [0, 8 - head_size_og % 8])
            k = torch.nn.functional.pad(k, [0, 8 - head_size_og % 8])
            v = torch.nn.functional.pad(v, [0, 8 - head_size_og % 8])
        out_padded, softmax_lse, S_dmask = _flash_attn_forward(
            q,
            k,
            v,
            dropout_p,
            softmax_scale,
            causal=causal,
            window_size_left=window_size[0],
            window_size_right=window_size[1],
            alibi_slopes=alibi_slopes,
            return_lse=return_lse,
            return_softmax=return_softmax and dropout_p > 0,
            max_seqlen_q=q.shape[1],
            max_seqlen_k=k.shape[1],
        )

        out = out_padded[..., :head_size_og]
        result = [out]
        if return_lse:
            result.append(softmax_lse)
        if return_softmax:
            result.append(S_dmask)

        return tuple(result)

def flash_attn_func(
    q,
    k,
    v,
    dropout_p=0.0,
    softmax_scale=None,
    causal=False,
    window_size=(-1,-1),
    alibi_slopes=None,
    deterministic=True,
    return_lse=False,
    return_attn_probs=False,
):
    """dropout_p should be set to 0.0 during evaluation
    Supports multi-query and grouped-query attention (MQA/GQA) by passing in KV with fewer heads
    than Q. Note that the number of heads in Q must be divisible by the number of heads in KV.
    For example, if Q has 6 heads and K, V have 2 heads, head 0, 1, 2 of Q will attention to head
    0 of K, V, and head 3, 4, 5 of Q will attention to head 1 of K, V.

    If causal=True, the causal mask is aligned to the bottom right corner of the attention matrix.
    For example, if seqlen_q = 2 and seqlen_k = 5, the causal mask (1 = keep, 0 = masked out) is:
        1 1 1 1 0
        1 1 1 1 1
    If seqlen_q = 5 and seqlen_k = 2, the causal mask is:
        0 0
        0 0
        0 0
        1 0
        1 1
    If the row of the mask is all zero, the output will be zero.

    If window_size != (-1, -1), implements sliding window local attention. Query at position i
    will only attend to keys between
    [i + seqlen_k - seqlen_q - window_size[0], i + seqlen_k - seqlen_q + window_size[1]] inclusive.

    Arguments:
        q: (batch_size, seqlen, nheads, headdim)
        k: (batch_size, seqlen, nheads_k, headdim)
        v: (batch_size, seqlen, nheads_k, headdim)
        dropout_p: float. Dropout probability.
        softmax_scale: float. The scaling of QK^T before applying softmax.
            Default to 1 / sqrt(headdim).
        causal: bool. Whether to apply causal attention mask (e.g., for auto-regressive modeling).
        window_size: (left, right). If not (-1, -1), implements sliding window local attention.
        alibi_slopes: (nheads,) or (batch_size, nheads), fp32. A bias of
            (-alibi_slope * |i + seqlen_k - seqlen_q - j|)
            is added to the attention score of query i and key j.
        deterministic: bool. Whether to use the deterministic implementation of the backward pass,
            which is slightly slower and uses more memory. The forward pass is always deterministic.
        return_attn_probs: bool. Whether to return the attention probabilities. This option is for
           testing only. The returned probabilities are not guaranteed to be correct
           (they might not have the right scaling).
    Return:
        out: (batch_size, seqlen, nheads, headdim).
        softmax_lse [optional, if return_lse=True]: (batch_size, nheads, seqlen). The
            logsumexp of each row of the matrix QK^T * scaling (e.g., log of the softmax
            normalization factor).
        S_dmask [optional, if return_attn_probs=True]: (batch_size, nheads, seqlen, seqlen).
            The output of softmax (possibly with different scaling). It also encodes the dropout
            pattern (negative means that location was dropped, nonnegative means it was kept).
    """
    return FlashAttnFunc.apply(
        q,
        k,
        v,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_attn_probs,
        torch.is_grad_enabled()
    )


class FlashAttnFP8Func(torch.autograd.Function):
    @staticmethod
    def forward(
        ctx,
        q,
        k,
        v,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_softmax,
        is_grad_enabled, #TODO add bkwd support
    ):
        is_grad = is_grad_enabled and any(
            x.requires_grad for x in [q,k,v]
        )
        if softmax_scale is None:
            softmax_scale = q.shape[-1] ** (-0.5)
        head_size_og = q.size(3)
        if head_size_og % 8 != 0:
            q = torch.nn.functional.pad(q, [0, 8 - head_size_og % 8])
            k = torch.nn.functional.pad(k, [0, 8 - head_size_og % 8])
            v = torch.nn.functional.pad(v, [0, 8 - head_size_og % 8])

        # cast input to fp8
        fp8_dtype = torch.float8_e4m3fnuz 
        q_fp8, descale_q = cast_to_fp8(q, fp8_dtype, "bshd")
        k_fp8, descale_k = cast_to_fp8(k, fp8_dtype, "bshd")
        v_fp8, descale_v = cast_to_fp8(v, fp8_dtype, "bshd")

        out_padded, softmax_lse, S_dmask = _flash_attn_forward(
            q,
            k,
            v,
            dropout_p,
            softmax_scale,
            causal=causal,
            window_size_left=window_size[0],
            window_size_right=window_size[1],
            alibi_slopes=alibi_slopes,
            return_lse=return_lse,
            return_softmax=return_softmax and dropout_p > 0,
            max_seqlen_q=q.shape[1],
            max_seqlen_k=k.shape[1],
            cu_seqlens_q=None,
            cu_seqlens_k=None,
            descale_q=descale_q,
            descale_k=descale_k,
            descale_v=descale_v
        )

        out = out_padded[..., :head_size_og]
        result = [out]
        if return_lse:
            result.append(softmax_lse)
        if return_softmax:
            result.append(S_dmask)

        return tuple(result)


def flash_attn_fp8_func(
    q,
    k,
    v,
    dropout_p=0.0,
    softmax_scale=None,
    causal=False,
    window_size=(-1, -1),  # -1 means infinite context window
    alibi_slopes=None,
    deterministic=False,
    return_lse=False,
    return_attn_probs=False
):
    return FlashAttnFP8Func.apply(
        q,
        k,
        v,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_attn_probs,
        torch.is_grad_enabled()
    ) 

class FlashAttnVarlenFunc(torch.autograd.Function):
    @staticmethod
    def forward(
        ctx,
        q,
        k,
        v,
        cu_seqlens_q,
        cu_seqlens_k,
        max_seqlen_q,
        max_seqlen_k,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_softmax,
        block_table,
        is_grad_enabled,
    ):
        is_grad = is_grad_enabled and any(
            x.requires_grad for x in [q, k, v]
        )
        if softmax_scale is None:
            softmax_scale = q.shape[-1] ** (-0.5)
        head_size_og = q.size(2)
        if head_size_og % 8 != 0:
            q = torch.nn.functional.pad(q, [0, 8 - head_size_og % 8])
            k = torch.nn.functional.pad(k, [0, 8 - head_size_og % 8])
            v = torch.nn.functional.pad(v, [0, 8 - head_size_og % 8])
        out_padded, softmax_lse, S_dmask =  _flash_attn_forward(
            q,
            k,
            v,
            dropout_p,
            softmax_scale,
            causal=causal,
            window_size_left=window_size[0],
            window_size_right=window_size[1],
            alibi_slopes=alibi_slopes,
            return_lse=return_lse,
            return_softmax=return_softmax and dropout_p > 0.0,
            max_seqlen_q=max_seqlen_q,
            max_seqlen_k=max_seqlen_k,
            cu_seqlens_q=cu_seqlens_q,
            cu_seqlens_k=cu_seqlens_k,
        )
        out = out_padded[..., :head_size_og]

        result = [out]
        if return_lse:
            result.append(softmax_lse)
        if return_softmax:
            result.append(S_dmask)
        
        return tuple(result)

def flash_attn_varlen_func(
    q,
    k,
    v,
    cu_seqlens_q,
    cu_seqlens_k,
    max_seqlen_q,
    max_seqlen_k,
    dropout_p=0.0,
    softmax_scale=None,
    causal=False,
    window_size=(-1,-1),
    alibi_slopes=None,
    deterministic=False,
    return_lse=False,
    return_attn_probs=False,
    block_table=None,
):
    """dropout_p should be set to 0.0 during evaluation
    Supports multi-query and grouped-query attention (MQA/GQA) by passing in K, V with fewer heads
    than Q. Note that the number of heads in Q must be divisible by the number of heads in KV.
    For example, if Q has 6 heads and K, V have 2 heads, head 0, 1, 2 of Q will attention to head
    0 of K, V, and head 3, 4, 5 of Q will attention to head 1 of K, V.

    If causal=True, the causal mask is aligned to the bottom right corner of the attention matrix.
    For example, if seqlen_q = 2 and seqlen_k = 5, the causal mask (1 = keep, 0 = masked out) is:
        1 1 1 1 0
        1 1 1 1 1
    If seqlen_q = 5 and seqlen_k = 2, the causal mask is:
        0 0
        0 0
        0 0
        1 0
        1 1
    If the row of the mask is all zero, the output will be zero.

    If window_size != (-1, -1), implements sliding window local attention. Query at position i
    will only attend to keys between
    [i + seqlen_k - seqlen_q - window_size[0], i + seqlen_k - seqlen_q + window_size[1]] inclusive.

    Arguments:
        q: (total_q, nheads, headdim), where total_q = total number of query tokens in the batch.
        k: (total_k, nheads_k, headdim), where total_k = total number of key tokens in the batch.
        v: (total_k, nheads_k, headdim), where total_k = total number of key tokens in the batch.
        cu_seqlens_q: (batch_size + 1,), dtype torch.int32. The cumulative sequence lengths
           of the sequences in the batch, used to index into q.
        cu_seqlens_k: (batch_size + 1,), dtype torch.int32. The cumulative sequence lengths
           of the sequences in the batch, used to index into kv.
        max_seqlen_q: int. Maximum query sequence length in the batch.
        max_seqlen_k: int. Maximum key sequence length in the batch.
        dropout_p: float. Dropout probability.
        softmax_scale: float. The scaling of QK^T before applying softmax.
            Default to 1 / sqrt(headdim).
        causal: bool. Whether to apply causal attention mask (e.g., for auto-regressive modeling).
        window_size: (left, right). If not (-1, -1), implements sliding window local attention.
        alibi_slopes: (nheads,) or (batch_size, nheads), fp32. A bias of
            (-alibi_slope * |i + seqlen_k - seqlen_q - j|)
            is added to the attention score of query i and key j.
        deterministic: bool. Whether to use the deterministic implementation of the backward pass,
            which is slightly slower and uses more memory. The forward pass is always deterministic.
        return_attn_probs: bool. Whether to return the attention probabilities. This option is for
           testing only. The returned probabilities are not guaranteed to be correct
           (they might not have the right scaling).
    Return:
        out: (total, nheads, headdim).
        softmax_lse [optional, if return_attn_probs=True]: (nheads, total_q_seqlen). The
            logsumexp of each row of the matrix QK^T * scaling (e.g., log of the softmax
            normalization factor).
        S_dmask [optional, if return_attn_probs=True]: (batch_size, nheads, seqlen, seqlen).
            The output of softmax (possibly with different scaling). It also encodes the dropout
            pattern (negative means that location was dropped, nonnegative means it was kept).
    """
    return FlashAttnVarlenFunc.apply(
        q,
        k,
        v,
        cu_seqlens_q,
        cu_seqlens_k,
        max_seqlen_q,
        max_seqlen_k,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_attn_probs,
        block_table,
        torch.is_grad_enabled(),
    )


class FlashAttnVarlenFP8Func(torch.autograd.Function):
    @staticmethod
    def forward(
        ctx,
        q,
        k,
        v,
        cu_seqlens_q,
        cu_seqlens_k,
        max_seqlen_q,
        max_seqlen_k,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_softmax,
        block_table,
        is_grad_enabled,
    ):
        is_grad = is_grad_enabled and any(
            x.requires_grad for x in [q, k, v]
        )
        if softmax_scale is None:
            softmax_scale = q.shape[-1] ** (-0.5)
        head_size_og = q.size(2)
        if head_size_og % 8 != 0:
            q = torch.nn.functional.pad(q, [0, 8 - head_size_og % 8])
            k = torch.nn.functional.pad(k, [0, 8 - head_size_og % 8])
            v = torch.nn.functional.pad(v, [0, 8 - head_size_og % 8])
        
        # cast input to fp8
        fp8_dtype = torch.float8_e4m3fnuz 
        q_fp8, descale_q = cast_varlen_to_fp8(q, fp8_dtype, cu_seqlens=cu_seqlens_q) 
        k_fp8, descale_k = cast_varlen_to_fp8(k, fp8_dtype,  cu_seqlens=cu_seqlens_k)
        v_fp8, descale_v = cast_varlen_to_fp8(v, fp8_dtype,  cu_seqlens=cu_seqlens_k)

        out_padded, softmax_lse, S_dmask = _flash_attn_forward(
            q_fp8,
            k_fp8,
            v_fp8,
            dropout_p,
            softmax_scale,
            causal=causal,
            window_size_left=window_size[0],
            window_size_right=window_size[1],
            alibi_slopes=alibi_slopes,
            return_lse=return_lse,
            return_softmax=return_softmax and dropout_p > 0,
            max_seqlen_q=max_seqlen_q,
            max_seqlen_k=max_seqlen_k,
            cu_seqlens_q=cu_seqlens_q,
            cu_seqlens_k=cu_seqlens_k,
            descale_q=descale_q,
            descale_k=descale_k,
            descale_v=descale_v
        )
        out = out_padded[..., :head_size_og]
        result = [out]
        if return_lse:
            result.append(softmax_lse)
        if return_softmax:
            result.append(S_dmask)
        
        return tuple(result)

def flash_attn_varlen_fp8_func(
    q,
    k,
    v,
    cu_seqlens_q,
    cu_seqlens_k,
    max_seqlen_q,
    max_seqlen_k,
    dropout_p=0.0,
    softmax_scale=None,
    causal=False,
    window_size=(-1, -1),  # -1 means infinite context window
    alibi_slopes=None,
    deterministic=False,
    return_lse=False,
    return_attn_probs=False,
    block_table=None
):
    return FlashAttnVarlenFP8Func.apply(
        q,
        k,
        v,
        cu_seqlens_q,
        cu_seqlens_k,
        max_seqlen_q,
        max_seqlen_k,
        dropout_p,
        softmax_scale,
        causal,
        window_size,
        alibi_slopes,
        deterministic,
        return_lse,
        return_attn_probs,
        block_table,
        torch.is_grad_enabled()
    )

def model_benchmark_configs(args):
    config_file = args.model_configs
    configs = get_model_configs(config_path=config_file, models=args.model)
    fa_configs = []
    batch_size = args.b if args.b else 1

    for model_name, config in configs.items():
        HQ = config["num_attention_heads"]
        HK = HQ if config["num_key_value_heads"] is None else config["num_key_value_heads"]
        N_CTX_Q = args.sq if args.sq else 8192
        N_CTX_K = args.sk if args.sk else N_CTX_Q
        HEAD_DIM = config["hidden_size"] // HQ
        fa_configs.append((model_name, batch_size, HQ, HK, N_CTX_Q, N_CTX_K, HEAD_DIM))

    return fa_configs

def test_correctness(custom, args):
    dtype = arg_to_torch_dtype[args.dtype]
    hk = args.hq if not args.hk else args.hk
    sk = args.sq if not args.sk else args.sk
    head_size = 128 if not args.d else args.d
    mode = 'fwd'
    x_names = ['BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K']
    causal = args.causal if not args.model else True
    int8 = args.int8
    quantize_p = args.quantize_p and int8
    int8_kv = args.int8_kv and int8

    assert not (args.bench_torch and args.varlen), "Torch sdpa does not support variable sequence lengths."
    
    if custom:
        x_vals_list = [(args.b, args.hq, hk, args.sq, sk)]
    else:
        x_vals_list = model_benchmark_configs(args)
        x_names = ['model', 'BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K', 'D_HEAD']


    def bench_flash_attention(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, causal, mode, provider, device="cuda",
                              model=None):
        assert mode in ["fwd", "bwd"]
        assert not (int8_kv and quantize_p)

        # Bwd pass only supports causal=True right now
        if mode == 'bwd':
            causal = True

        assert args.layout in supported_layouts(), f"Layout {args.layout} not supported. Supported layouts: {supported_layouts()}"
        q, k, v, cu_seqlens_q, cu_seqlens_k, sm_scale = mha_input_helper(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype,
                                                        is_varlen=args.varlen, layout=args.layout)
        
        if "Torch" in provider:
            assert not args.varlen, "Torch sdpa does not support variable sequence lengths"
            q = q.view(BATCH, N_CTX_Q, HQ, D_HEAD).transpose(1, 2)
            k = k.view(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            v = v.view(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            if HQ != HK:  # TODO: sdpa(..., enable_gqa=True) works but gives very bad perf
                k = k.repeat_interleave(q.size(-3) // k.size(-3), -3)
                v = v.repeat_interleave(q.size(-3) // v.size(-3), -3)
            fn = lambda: torch.nn.functional.scaled_dot_product_attention(
                q, k, v, attn_mask=None, dropout_p=0.0, is_causal=causal, scale=sm_scale)
        else:
            o = torch.empty_like(q)
            fn = lambda: flash_attn_varlen_func(q, k, v, cu_seqlens_q, cu_seqlens_k,
                                                N_CTX_Q, N_CTX_K, dropout_p=0.0, softmax_scale=sm_scale,
                                                causal=causal, window_size=(-1, -1), alibi_slopes=None, deterministic=False,
                                                return_lse=False, return_attn_probs=False)
            if mode == 'bwd':
                o, _ = fn()
                do = torch.randn_like(o)
                fn = lambda: o.backward(do, retain_graph=True)

        return fn()
        
    # Test correctness of the triton kernel by comparing the output to the torch sdpa output
    for config in x_vals_list:
        # Build a dictionary from x_names and config values, and add D_HEAD
        cfg = {name: value for name, value in zip(x_names, config)}
        cfg["D_HEAD"] = head_size  # head size computed above

        # Run benchmark with Triton provider
        triton_result = bench_flash_attention(
            **cfg,
            dtype=dtype,
            causal=causal,
            mode=mode,
            provider="Triton"
        )
        triton_result = triton_result[0]
        print("triton_result.shape", triton_result.shape)

        # Run benchmark with Torch provider
        torch_result = bench_flash_attention(
            **cfg,
            dtype=dtype,
            causal=causal,
            mode=mode,
            provider="Torch"
        )

        torch_result = torch_result.transpose(1,2).flatten(0,1) # Triton kernel flattens batch and sequence length dims

        # Check that the results are close
        torch.testing.assert_close(triton_result, torch_result, rtol=2e-2, atol=2e-2)
        print(f"Results are close for config: {cfg} for triton kernel and torch.sdpa!")
    


def run_benchmark(custom, args):
    
    dtype = arg_to_torch_dtype[args.dtype]
    hk = args.hq if not args.hk else args.hk
    sk = args.sq if not args.sk else args.sk
    head_size = 128 if not args.d else args.d
    mode = 'fwd'
    x_names = ['BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K']
    causal = args.causal if not args.model else True
    int8 = args.int8
    quantize_p = args.quantize_p and int8
    int8_kv = args.int8_kv and int8

    assert not (args.bench_torch and args.varlen), "Torch sdpa does not support variable sequence lengths"
    
    configs = []
    plot_name = f'fused-attention-{mode}-d{head_size}-layout{args.layout}'
    extra_args = {'D_HEAD': head_size, 'dtype': dtype, 'causal': causal, 'mode': mode}
    if custom:
        x_vals_list = [(args.b, args.hq, hk, args.sq, sk)]
    else:
        x_vals_list = model_benchmark_configs(args)
        x_names = ['model', 'BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K', 'D_HEAD']
        plot_name = f'fused-attention-{mode}-layout{args.layout}'
        extra_args = {'dtype': dtype, 'causal': causal, 'mode': mode}

    print_time = args.return_time

    if args.bench_torch:
        unit = 'ms' if print_time else 'TFLOPS'
        line_vals = [f'Triton ({unit})', f'Torch ({unit})']
    else:
        line_vals = ['Time (ms)' if print_time else 'TFLOPS'] 

    configs.append(
        triton.testing.Benchmark(x_names=x_names, x_vals=x_vals_list, line_arg='provider', line_vals=line_vals,
                                 line_names=line_vals, styles=[('green', '-'), ('red', '-')],
                                 ylabel='Time (ms)' if print_time else 'TFLOPS', plot_name=plot_name, args=extra_args))

    @triton.testing.perf_report(configs)
    def bench_flash_attention(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, causal, mode, provider, device="cuda",
                              model=None):
        assert mode in ["fwd", "bwd"]
        assert not (int8_kv and quantize_p)
        warmup = 25
        rep = 100

        # Bwd pass only supports causal=True right now
        if mode == 'bwd':
            causal = True

        flops_per_matmul = 0

        assert args.layout=="thd" or not args.varlen, "Only thd layout supported for variable sequence lengths"
        assert args.layout in supported_layouts(), f"Layout {args.layout} not supported. Supported layouts: {supported_layouts()}"
        q, k, v, cu_seqlens_q, cu_seqlens_k, sm_scale = mha_input_helper(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype,
                                                        is_varlen=args.varlen, layout=args.layout)
        
        if args.varlen:
            num_contexts = len(cu_seqlens_q) - 1
            for i in range(0, num_contexts):
                seqlen_q = (cu_seqlens_q[i + 1] - cu_seqlens_q[i]).item()
                seqlen_k = (cu_seqlens_k[i + 1] - cu_seqlens_k[i]).item()
                # x2 in both cases for 2 GEMMs
                if causal:
                    valid_out_elements = ((seqlen_k**2 + seqlen_k) / 2) if seqlen_q > seqlen_k else \
                            (seqlen_q * seqlen_k - ((seqlen_q**2 - seqlen_q) / 2))
                    flops_per_matmul += valid_out_elements * HQ * D_HEAD * 2
                else:
                    flops_per_matmul += seqlen_q * seqlen_k * HQ * D_HEAD * 2
        else: # Fixed sequence length
            if causal:
                valid_out_elements = ((N_CTX_K**2 + N_CTX_K) / 2) if N_CTX_Q > N_CTX_K else \
                        (N_CTX_Q * N_CTX_K - ((N_CTX_Q**2 - N_CTX_Q) / 2))
                flops_per_matmul = valid_out_elements * HQ * D_HEAD * 2
            else:
                flops_per_matmul = N_CTX_Q * N_CTX_K * HQ * D_HEAD * 2

        
        if "Torch" in provider:
            assert not args.varlen, "Torch sdpa does not support variable sequence lengths"
            q = q.reshape(BATCH, N_CTX_Q, HQ, D_HEAD).transpose(1, 2)
            k = k.reshape(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            v = v.reshape(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            if HQ != HK:  # TODO: sdpa(..., enable_gqa=True) works but gives very bad perf
                k = k.repeat_interleave(q.size(-3) // k.size(-3), -3)
                v = v.repeat_interleave(q.size(-3) // v.size(-3), -3)
            fn = lambda: torch.nn.functional.scaled_dot_product_attention(
                q, k, v, attn_mask=None, dropout_p=0.0, is_causal=causal, scale=sm_scale)
        else:
            o = torch.empty_like(q)
            # _flash_attn_forward uses is_varlen = cu_seqlens_q is not None
            fn = lambda: flash_attn_varlen_func(q, k, v, cu_seqlens_q, cu_seqlens_k,
                                                N_CTX_Q, N_CTX_K, dropout_p=0.0, softmax_scale=sm_scale,
                                                causal=causal, window_size=(-1, -1), alibi_slopes=None, deterministic=False,
                                                return_lse=False, return_attn_probs=False)
            if mode == 'bwd':
                o, _ = fn()
                do = torch.randn_like(o)
                fn = lambda: o.backward(do, retain_graph=True)

        ms = triton.testing.do_bench(fn, warmup=warmup, rep=rep)
        total_flops = 2 * flops_per_matmul
        if mode == "bwd":
            total_flops *= 2.5  # 2.0(bwd) + 0.5(recompute)
        if print_time:
            return ms
        else:
            return total_flops / ms * 1e-9

    bench_flash_attention.run(save_path=".", print_data=True, show_plots=True)


def supported_layouts():
    layouts = \
        'thd: Q, K, V are individual tensors of [total_q/k, num_heads, head_size]'
    return layouts


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
        prog="Benchmark FlashAttention",
        allow_abbrev=False,
    )
    parser.add_argument('-model_configs', type=str, default="utils/model_configs.json", help="Model config json file.")

    available_models = get_available_models()  # Dynamically load model names
    model_help = (
        "Model name to benchmark. Select from: [" + ", ".join(available_models) +
        "]. Use 'all' to benchmark all models. Provide model family (the part before -) to benchmark all models in that family. One can provide multiple as -model \"llama3,mistral_7B\""
    )
    parser.add_argument('-model', type=str, default="all", help=model_help)
    parser.add_argument("-b", type=int, default=0)
    parser.add_argument("-hq", type=int, default=0)
    parser.add_argument("-hk", type=int, default=0)
    parser.add_argument("-sq", type=int, default=0)
    parser.add_argument("-sk", type=int, default=0)
    parser.add_argument("-varlen", action='store_true', default=False,
                        help='If specified, uses variable sequence lengths. The t in the layout thd for q has maximum possible value of b*sq')
    parser.add_argument("-d", type=int, default=0)
    parser.add_argument("-causal", action='store_true', default=False)
    parser.add_argument("-int8", action='store_true', default=False)
    parser.add_argument("-quantize_p", action='store_true', default=False)
    parser.add_argument("-int8_kv", action='store_true', default=False)
    parser.add_argument("-dtype", default='fp16')
    parser.add_argument("-bench_torch", action='store_true', default=False)
    parser.add_argument("-return_time", action='store_true', default=False)
    parser.add_argument("-layout", type=str, default='thd', help=supported_layouts())
    parser.add_argument(
        "-persistent", nargs='?', const='fixed', choices=['fixed', 'dynamic'], default=None,
        help="Enable persistent kernels. Use '-persistent dynamic' for dynamic scheduling of the tiles.")
    return parser.parse_args()


arg_to_torch_dtype = {'fp16': torch.float16, 'bf16': torch.bfloat16, 'fp32': torch.float32}


def main():
    args = parse_args()
    custom_config = False
    # assert args.layout == 'thd' or not args.equal_seqlens or args.model, \
    #        "Equal sequence lengths arg must be used with the thd layout or a model config."
    if args.hq or args.hk or args.d:
        custom_config = True
        assert args.b and args.hq and args.sq and args.d, \
               "If custom config is specified, please provide \
                all of batch, number of Q heads, Q sequence length \
                and head size."

    if args.model:
        assert not (args.hq or args.hk or args.d), \
                "Specifying model fixes hq, hk and d already. Do not provide them!"

    assert args.dtype in arg_to_torch_dtype, \
           "Only fp16, bf16 and f32 types currently supported."

    if args.model:
        print("Note: Model config sets causal masking and THD layout (varlen) by default.")

    # test_correctness(custom_config, args)
    
    run_benchmark(custom_config, args)


if __name__ == '__main__':
    import sys
    sys.exit(main())




