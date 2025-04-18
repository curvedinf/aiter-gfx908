import torch
import triton
import triton.language as tl

def is_hip():
    return triton.runtime.driver.active.get_current_target().backend == "hip"

is_cuda_available = torch.cuda.is_available()
if is_cuda_available:
    CUDA_CAPABILITY = torch.cuda.get_device_capability()

is_hip_ = is_hip()

@triton.jit
def binary_search(value, arr_ptr, arr_length):
    left = 0
    right = arr_length - 1
    
    while left <= right:
        mid = (left + right) // 2
        mid_value = tl.load(arr_ptr + mid)
        
        if mid_value <= value:
            left = mid + 1
        else:
            right = mid - 1
    
    return left - 1

@triton.jit
def _ragged_trans_kernel(
    k_buffer_ptr, 
    v_buffer_ptr, 
    k_extend_ptr, 
    v_extend_ptr,
    k_values_ptr, 
    v_values_ptr,
    qo_indptr_ptr, 
    kv_indptr_ptr, 
    kv_indices_ptr, 
    kv_cat_q_indptr_ptr,
    B, 
    E_DIM, 
    total_tokens,
    BLOCK_TOKEN: tl.constexpr, 
    BLOCK_E_DIM: tl.constexpr,
):
    token_block_idx = tl.program_id(0)
    p_token_offset = token_block_idx * BLOCK_TOKEN

    p_token_num = BLOCK_TOKEN * (p_token_offset < total_tokens)
    
    for local_idx in range(p_token_num):
        cur_token_idx = p_token_offset + local_idx
        if cur_token_idx >= total_tokens:
            batch_idx = -1
        else:
            batch_idx = binary_search(cur_token_idx, kv_cat_q_indptr_ptr, B + 1)
        if batch_idx >= 0 and batch_idx < B:
            batch_token_start = tl.load(kv_cat_q_indptr_ptr + batch_idx)
            kv_start = tl.load(kv_indptr_ptr + batch_idx)
            kv_end = tl.load(kv_indptr_ptr + batch_idx + 1)
            qo_start = tl.load(qo_indptr_ptr + batch_idx)

            local_p_token_offset = cur_token_idx - batch_token_start
            kv_len = kv_end - kv_start
            E_DIM_mask = tl.arange(0, BLOCK_E_DIM) < E_DIM

            if local_p_token_offset < kv_len:
                kv_idx = tl.load(kv_indices_ptr + kv_start + local_p_token_offset)
                kv_buffer_off = kv_idx * E_DIM + tl.arange(0, BLOCK_E_DIM)
                k_vals = tl.load(k_buffer_ptr + kv_buffer_off, mask=E_DIM_mask)
                v_vals = tl.load(v_buffer_ptr + kv_buffer_off, mask=E_DIM_mask)

            else:
                extend_idx = qo_start + local_p_token_offset - kv_len
                ext_buffer_off = extend_idx * E_DIM + tl.arange(0, BLOCK_E_DIM)
                k_vals = tl.load(k_extend_ptr + ext_buffer_off, mask=E_DIM_mask)
                v_vals = tl.load(v_extend_ptr + ext_buffer_off, mask=E_DIM_mask)
            
            tl.store(k_values_ptr + cur_token_idx * E_DIM + tl.arange(0, BLOCK_E_DIM), k_vals, mask=E_DIM_mask)
            tl.store(v_values_ptr + cur_token_idx * E_DIM + tl.arange(0, BLOCK_E_DIM), v_vals, mask=E_DIM_mask)

def ragged_layout_trans(qo_indptr, kv_indptr, kv_indices, k_buffer, v_buffer, k_extend, v_extend):
    B = kv_indptr.shape[0] - 1
    H_KV = k_extend.shape[1]
    D = k_extend.shape[2]
    dtype = k_extend.dtype

    kv_cat_q_indptr = kv_indptr + qo_indptr
    total_tokens = kv_cat_q_indptr[-1].item()
    k_values = torch.empty((kv_cat_q_indptr[-1], H_KV, D), dtype=dtype, device="cuda")
    v_values = torch.empty((kv_cat_q_indptr[-1], H_KV, D), dtype=dtype, device="cuda")

    BLOCK_TOKEN = 128
    BLOCK_E_DIM = triton.next_power_of_2(H_KV * D)

    token_blocks = triton.cdiv(total_tokens, BLOCK_TOKEN)

    grid = (token_blocks,)
    if is_hip_:
        extra_kargs = {"waves_per_eu": 1, "matrix_instr_nonkdim": 16, "kpack": 2}

    _ragged_trans_kernel[grid](
        k_buffer,
        v_buffer,
        k_extend,
        v_extend,
        k_values,
        v_values,
        qo_indptr,
        kv_indptr,
        kv_indices,
        kv_cat_q_indptr,
        B=B,
        E_DIM=H_KV * D,
        total_tokens=total_tokens,
        BLOCK_TOKEN=BLOCK_TOKEN,
        BLOCK_E_DIM=BLOCK_E_DIM,
        **extra_kargs,
    )

    return k_values, v_values, qo_indptr, kv_cat_q_indptr

