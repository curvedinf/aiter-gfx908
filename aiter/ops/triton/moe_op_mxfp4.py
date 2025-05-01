import torch
import triton
import triton.language as tl
from typing import Any, Dict, Optional, List
from aiter.ops.triton.quant import dynamic_per_tensor_fp8_quant
from aiter.ops.triton.utils.pid_preprocessing import pid_grid, remap_xcd
from triton_bench.numerics_details.mxfp import _unswizzle_mx_block, get_scaled_dot_format_string

#Source:
#MoE Kernel adapted from VLLM

_PADDING_SIZE = 0

_USE_MOE_PERSISTENT_KERNEL = False

def moe_set_use_persistent_kernel(value: bool):
    global _USE_MOE_PERSISTENT_KERNEL
    _USE_MOE_PERSISTENT_KERNEL = value

def moe_set_padding_size(size: int):
    """
    Override padding size
    """
    global _PADDING_SIZE
    _PADDING_SIZE = size


@triton.jit
def _write_zeros_to_output(c_ptr, stride_cm, stride_cn, pid_n, N, offs_token,
                          token_mask, BLOCK_SIZE_M, BLOCK_SIZE_N,
                          compute_type):
    accumulator = tl.zeros((BLOCK_SIZE_M, BLOCK_SIZE_N), dtype=compute_type)
    offs_cn = pid_n * BLOCK_SIZE_N + tl.arange(0, BLOCK_SIZE_N)
    c_ptrs = c_ptr + stride_cm * offs_token[:, None] + stride_cn * offs_cn[
        None, :]
    c_mask = token_mask[:, None] & (offs_cn[None, :] < N)
    tl.store(c_ptrs, accumulator, mask=c_mask)


SWIZZLE_ALIGN_INNER = 8
SWIZZLE_SIZE_INNER = 4
SWIZZLE_SIZE_OUTER = 128

def swizzle_mx(tensor: torch.Tensor):
    """
    Swizzle the input tensor of shape (A, B, ... N, K) to (A, B, ... N // 128, K // 4, 32, 4, 4).
    Padding is applied if N and K are not multiples of 128 and 4 respectively.
    Returns the swizzled tensor repacked as (A, B, ... N, K), with padding.
    """
    *leading_shape, N, K, = tensor.shape
    pad_k = (SWIZZLE_ALIGN_INNER - (K % SWIZZLE_ALIGN_INNER)) % SWIZZLE_ALIGN_INNER
    pad_n = (SWIZZLE_SIZE_OUTER - (N % SWIZZLE_SIZE_OUTER)) % SWIZZLE_SIZE_OUTER
    if pad_k > 0 or pad_n > 0:
        tensor = torch.nn.functional.pad(tensor, (0, pad_k, 0, pad_n))
    padded_shape = tensor.shape
    tensor = tensor.reshape(*leading_shape, padded_shape[-2] // SWIZZLE_SIZE_OUTER, SWIZZLE_SIZE_OUTER // 32, 32, padded_shape[-1] // SWIZZLE_SIZE_INNER, SWIZZLE_SIZE_INNER)
    permute_order = list(range(len(tensor.shape)))
    permute_order[-2], permute_order[-4] = permute_order[-4], permute_order[-2]
    return tensor.permute(permute_order).reshape(*padded_shape)


@triton.heuristics({
'GRID_MN':
    lambda args: triton.cdiv(args['EM'], args['BLOCK_SIZE_M']) * triton.cdiv(args['N'], args['BLOCK_SIZE_N'])
})
@triton.jit
def _fused_moe_kernel(
        # Pointers to matrices
        a_ptr, b_ptr, c_ptr, a_scale_ptr, b_scale_ptr, mx_scale_ptr,
        topk_weights_ptr, sorted_token_ids_ptr, expert_ids_ptr,
        num_tokens_post_padded_ptr,
        # Matrix dimensions
        N, K, EM, num_valid_tokens,
        # Strides
        stride_am, stride_ak,
        stride_be, stride_bk, stride_bn,
        stride_cm, stride_cn,
        stride_mx_e, stride_mx_k, stride_mx_n,
        # Meta-parameters
        BLOCK_SIZE_M: tl.constexpr,
        BLOCK_SIZE_N: tl.constexpr,
        BLOCK_SIZE_K: tl.constexpr,
        GROUP_SIZE_M: tl.constexpr,
        MUL_ROUTED_WEIGHT: tl.constexpr,
        top_k: tl.constexpr,
        compute_type: tl.constexpr,
        GRID_MN: tl.constexpr,
        SWIZZLE_MX: tl.constexpr,
    ):
    """
    Implements the fused computation for a Mixture of Experts (MOE) using
    token and expert matrices.

    Key Parameters:
    - A: The input tensor representing tokens with shape (*, K), where '*' can
        be any shape representing batches and K is the feature dimension of
        each token.
    - B: The stacked MOE weight tensor with shape (E, N, K), where E is
        the number of experts, K is the input feature dimension, and N is
        the output feature dimension.
    - C: The output cache tensor with shape (M, topk, N), where M is the
        total number of tokens post padding, topk is the number of times
        each token is repeated, and N is the output feature dimension.
    - sorted_token_ids: A tensor containing the sorted indices of tokens,
        repeated topk times and arranged by the expert index they are
        assigned to.
    - expert_ids: A tensor containing the indices of the expert for each
        block. It determines which expert matrix from B should be used for
        each block in A.
    This kernel performs the multiplication of a token by its corresponding
    expert matrix as determined by `expert_ids`. The sorting of
    `sorted_token_ids` by expert index and padding ensures divisibility by
    BLOCK_SIZE_M, which is necessary to maintain consistency in block matrix
    multiplication across different blocks processed by the same expert.
    """
    is_microscaled_format: tl.constexpr = mx_scale_ptr is not None
    MX_PACK_DIVISOR: tl.constexpr = 32
    if is_microscaled_format:
        b_type: tl.constexpr = b_ptr.dtype.element_ty
        tl.static_assert(b_type == tl.uint8 or (b_type == tl.float8e4nv or b_type == tl.float8e5),
                         "mx_weight_ptr must be 1 byte")
        tl.static_assert(mx_scale_ptr.dtype.element_ty == tl.uint8, "mx_scale_ptr must be uint8")
        tl.static_assert(BLOCK_SIZE_K % MX_PACK_DIVISOR == 0, "BLOCK_SIZE_K must be a multiple of MX_PACK_DIVISOR")

    # -----------------------------------------------------------
    # Map program ids `pid` to the block of C it should compute.
    # This is done in a grouped ordering to promote L2 data reuse.
    pid = tl.program_id(axis=0)
    num_pid_m = tl.cdiv(EM, BLOCK_SIZE_M)
    num_pid_n = tl.cdiv(N, BLOCK_SIZE_N)

    NUM_XCDS: tl.constexpr = 8
    pid = remap_xcd(pid, GRID_MN, NUM_XCDS)
    pid_m, pid_n = pid_grid(pid, num_pid_m, num_pid_n, GROUP_SIZE_M)

    # ----------------------------------------------------------
    # Create pointers for the first blocks of A and B.
    # We will advance this pointer as we move in the K direction
    # and accumulate
    # `a_ptrs` is a block of [BLOCK_SIZE_M, BLOCK_SIZE_K] pointers
    # `b_ptrs` is a block of [BLOCK_SIZE_K, BLOCK_SIZE_N] pointers
    num_tokens_post_padded = tl.load(num_tokens_post_padded_ptr)
    if pid_m * BLOCK_SIZE_M >= num_tokens_post_padded:
        return
    offs_token_id = pid_m * BLOCK_SIZE_M + tl.arange(0, BLOCK_SIZE_M).to(tl.int64)
    offs_token = tl.load(sorted_token_ids_ptr + offs_token_id)
    token_mask = offs_token < num_valid_tokens

    off_expert = tl.load(expert_ids_ptr + pid_m).to(tl.int64)
    if off_expert == -1:
        # -----------------------------------------------------------
        # Write back zeros to the output when the expert is not
        # in the current expert parallel rank.
        _write_zeros_to_output(c_ptr, stride_cm, stride_cn, pid_n, N,
                              offs_token, token_mask, BLOCK_SIZE_M,
                              BLOCK_SIZE_N, compute_type)
        return

    # Load a_scale, b_scale
    a_scale = tl.load(a_scale_ptr)
    b_scale = tl.load(b_scale_ptr + off_expert)
    # NOTE: this is the vllm way of offs_bn, check the diff later
    # offs_bn = (pid_n * BLOCK_SIZE_N +
    #            tl.arange(0, BLOCK_SIZE_N).to(tl.int64)) % N
    offs_b_n = pid_n * BLOCK_SIZE_N + tl.arange(0, BLOCK_SIZE_N)
    offs_b_n = tl.max_contiguous(tl.multiple_of(offs_b_n % N, BLOCK_SIZE_N), BLOCK_SIZE_N)
    # Load b_mx_scale
    if is_microscaled_format:
        # We have pack 2 fp4 values in a byte
        B_PACK_DIVISOR: tl.constexpr = 2 if b_ptr.dtype.element_ty == tl.uint8 else 1
        PACKED_BLOCK_K_B: tl.constexpr = BLOCK_SIZE_K // B_PACK_DIVISOR  # 64
        MX_SCALE_BLOCK_K: tl.constexpr = BLOCK_SIZE_K // MX_PACK_DIVISOR  # 4

        mx_scale_ptr += off_expert * stride_mx_e

        if SWIZZLE_MX:
            tl.static_assert(BLOCK_SIZE_N % 128 == 0)
            tl.static_assert(MX_SCALE_BLOCK_K % 4 == 0)
            PACKED_MX_BLOCK: tl.constexpr = (MX_SCALE_BLOCK_K // 4) * 32 * 4 * 4
            offs_inner = tl.arange(0, PACKED_MX_BLOCK)
            offs_scale_n = (pid_n * (BLOCK_SIZE_N // 128) + tl.arange(0, BLOCK_SIZE_N // 128)) % N
            offs_scale_n = tl.max_contiguous(tl.multiple_of(offs_scale_n, BLOCK_SIZE_N // 128), BLOCK_SIZE_N // 128)

            mx_scale_ptrs = mx_scale_ptr + offs_scale_n.to(tl.int64)[:, None] * stride_mx_n + offs_inner[None, :]
        else:
            offs_scale_k = tl.arange(0, MX_SCALE_BLOCK_K)
            offs_scale_n = offs_b_n
            # K dimension must be the last dimension for the scales
            mx_scale_ptrs = mx_scale_ptr + offs_scale_k.to(tl.int64)[None, :] * stride_mx_k + offs_scale_n.to(tl.int64)[:, None] * stride_mx_n

    offs_b_k = tl.arange(0, PACKED_BLOCK_K_B)
    offs_a_k = tl.arange(0, BLOCK_SIZE_K)

    a_ptrs = a_ptr + (offs_token[:, None] // top_k * stride_am +
                      offs_a_k[None, :] * stride_ak)

    b_ptrs = b_ptr + off_expert * stride_be + (offs_b_k[:, None] * stride_bk +
                                                offs_b_n[None, :] * stride_bn)

    # -----------------------------------------------------------
    # Iterate to compute a block of the C matrix.
    # We accumulate into a `[BLOCK_SIZE_M, BLOCK_SIZE_N]` block
    # of fp32 values for higher accuracy.
    # `accumulator` will be converted back to fp16 after the loop.
    accumulator = tl.zeros((BLOCK_SIZE_M, BLOCK_SIZE_N), dtype=tl.float32)
    for k in range(0, tl.cdiv(K, BLOCK_SIZE_K)):
        # Load the next block of A and B, generate a mask by checking the
        # K dimension.
        a = tl.load(a_ptrs,
                    mask=token_mask[:, None] &
                    (offs_a_k[None, :] < K - k * BLOCK_SIZE_K),
                    other=0.0)
        b = tl.load(b_ptrs,
                    mask=offs_b_k[:, None] < (K - k * BLOCK_SIZE_K) // B_PACK_DIVISOR,
                    other=0.0)
        # We accumulate along the K dimension.
        if is_microscaled_format:
            x_format: tl.constexpr = get_scaled_dot_format_string(a.dtype)
            mx_format: tl.constexpr = get_scaled_dot_format_string(b.dtype)
            a_scales = tl.full((BLOCK_SIZE_M, BLOCK_SIZE_K // MX_PACK_DIVISOR), 127, dtype=tl.uint8)
            if SWIZZLE_MX:
                b_mx_scales = _unswizzle_mx_block(tl.load(mx_scale_ptrs))
            else:
                mask_k_scale = offs_scale_k < (K - k * BLOCK_SIZE_K) // MX_PACK_DIVISOR
                b_mx_scales = tl.load(mx_scale_ptrs, mask=mask_k_scale[None, :], other=0.0)
            accumulator = tl.dot_scaled(a, a_scales, x_format, b, b_mx_scales, mx_format, acc=accumulator, fast_math=True)
            if SWIZZLE_MX:
                mx_scale_ptrs += MX_SCALE_BLOCK_K // 4 * stride_mx_k
            else:
                mx_scale_ptrs += MX_SCALE_BLOCK_K * stride_mx_k
        # Advance the ptrs to the next K block.
        a_ptrs += BLOCK_SIZE_K * stride_ak
        b_ptrs += BLOCK_SIZE_K * stride_bk

    # Multiply with the scalar weight
    accumulator *= a_scale * b_scale
    if MUL_ROUTED_WEIGHT:
        moe_weight = tl.load(topk_weights_ptr + offs_token,
                             mask=token_mask,
                             other=0)
        accumulator = accumulator * moe_weight[:, None]
    accumulator = accumulator.to(compute_type)
    # -----------------------------------------------------------
    # Write back the block of the output
    offs_cn = pid_n * BLOCK_SIZE_N + tl.arange(0, BLOCK_SIZE_N)
    c_ptrs = c_ptr + stride_cm * offs_token[:, None] + stride_cn * offs_cn[
        None, :]
    c_mask = token_mask[:, None] & (offs_cn[None, :] < N)
    tl.store(c_ptrs, accumulator, mask=c_mask)


def fused_moe_mxfp4(A: torch.Tensor,
                    B: torch.Tensor,
                    C: torch.Tensor,
                    A_scale: torch.Tensor,
                    B_scale: torch.Tensor,
                    B_mx_scale: torch.Tensor,
                    topk_weights: torch.Tensor,
                    topk_ids: torch.Tensor,
                    sorted_token_ids: torch.Tensor,
                    expert_ids: torch.Tensor,
                    num_tokens_post_padded: torch.Tensor,
                    mul_routed_weight: bool,
                    top_k: int,
                    swizzle_mx: bool,
                    config: Dict[str, Any],
                    compute_type: tl.dtype) -> None:
    """
    #TODO: Add doc
    """
    assert topk_weights.stride(1) == 1
    assert sorted_token_ids.stride(0) == 1

    assert A_scale is not None
    assert B_scale is not None
    assert B_mx_scale is not None

    EM = sorted_token_ids.shape[0]
    if A.shape[0] < config["BLOCK_SIZE_M"]:
        # optimize for small batch_size.
        # We assume that top_ids of each token is unique, so
        # so num_valid_experts <= batch_size <= BLOCK_SIZE_M,
        # and we can skip some invalid blocks.
        EM = min(sorted_token_ids.shape[0],
                 A.shape[0] * top_k * config['BLOCK_SIZE_M'])

    grid = lambda META: (triton.cdiv(EM, META['BLOCK_SIZE_M']) * triton.cdiv(
        B.shape[1], META['BLOCK_SIZE_N']), )
    _fused_moe_kernel[grid](
        A, B, C, A_scale, B_scale, B_mx_scale,
        topk_weights, sorted_token_ids, expert_ids, num_tokens_post_padded,
        B.shape[1], A.shape[1] - _PADDING_SIZE, EM, topk_ids.numel(),
        A.stride(0), A.stride(1),
        B.stride(0), B.stride(2), B.stride(1),
        C.stride(1), C.stride(2),
        B_mx_scale.stride(0), B_mx_scale.stride(2), B_mx_scale.stride(1),
        MUL_ROUTED_WEIGHT=mul_routed_weight,
        top_k=top_k,
        compute_type=compute_type,
        SWIZZLE_MX=swizzle_mx,
        **config,
    )
