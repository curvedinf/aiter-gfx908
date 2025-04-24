import torch
import triton
import triton.language as tl


@triton.jit
def _block_table_trans(K, V, K_new, V_new, K_cache, V_cache, B_Loc, B_Start_Loc, B_Seqlen, block_size, x, 
                        stride_k_bs,
                        stride_k_h,
                        stride_k_d,
                        stride_v_bs,
                        stride_v_h,
                        stride_v_d,
                        stride_k_new_bs,
                        stride_k_new_h,
                        stride_k_new_d,
                        stride_v_new_bs,
                        stride_v_new_h,
                        stride_v_new_d,
                        stride_k_cache_bs,
                        stride_k_cache_h,
                        stride_k_cache_d,
                        stride_k_cache_bl,
                        stride_k_cache_x, 
                        stride_v_cache_bs,
                        stride_v_cache_h,
                        stride_v_cache_d,
                        stride_v_cache_bl,
                        stride_b_loc_b,
                        stride_b_loc_s,
                        BLOCK_DMODEL: tl.constexpr,
                        BLOCK_DMODEL_PADDED: tl.constexpr, 
                        BLOCK_N: tl.constexpr):
    cur_batch = tl.program_id(0)
    cur_kv_head = tl.program_id(1)

    cur_batch_seq_len = tl.load(B_Seqlen + cur_batch)
    cur_batch_in_all_start_index = tl.load(B_Start_Loc + cur_batch)
    cur_batch_in_all_stop_index = tl.load(B_Start_Loc + cur_batch + 1)
    cur_batch_query_len = (cur_batch_in_all_stop_index -
                            cur_batch_in_all_start_index)
    cur_batch_ctx_len = cur_batch_seq_len - cur_batch_query_len
    
    offs_n = tl.arange(0, BLOCK_N)
    # [D]; starts at 0
    offs_d = tl.arange(0, BLOCK_DMODEL_PADDED)
    dim_mask = tl.where(
        tl.arange(0, BLOCK_DMODEL_PADDED) < BLOCK_DMODEL, 1, 0).to(tl.int1)
    
    for start_n in range(0, cur_batch_ctx_len, BLOCK_N):
        start_n = tl.multiple_of(start_n, BLOCK_N)
        # -- compute qk ----
        bn = tl.load(B_Loc + cur_batch * stride_b_loc_b +
                    ((start_n + offs_n) // block_size) * stride_b_loc_s,
                    mask=(start_n + offs_n) < cur_batch_ctx_len,
                    other=0.0)  # [N]
        # [D,N]
        off_k_cache = (bn[None, :] * stride_k_cache_bs +
                cur_kv_head * stride_k_cache_h +
                (offs_d[:, None] // x) * stride_k_cache_d +
                ((start_n + offs_n[None, :]) % block_size) *
                stride_k_cache_bl +
                (offs_d[:, None] % x) * stride_k_cache_x)
        # [D,N]
        off_v_cache = (bn[None, :] * stride_v_cache_bs +
                cur_kv_head * stride_v_cache_h +
                offs_d[:, None] * stride_v_cache_d +
                (start_n + offs_n[None, :]) % block_size * stride_v_cache_bl)
    
        k = tl.load(K_cache + off_k_cache,
                    mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len),
                    other=0.0)  # [D,N]
        v = tl.load(V_cache + off_v_cache,
                    mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len),
                    other=0.0)  # [D,N]
        
        off_k_new = (start_n + offs_n[None, :]) * stride_k_new_bs + cur_kv_head * stride_k_new_h + offs_d[:, None] * stride_k_new_d
        off_v_new = (start_n + offs_n[None, :]) * stride_v_new_bs + cur_kv_head * stride_v_new_h + offs_d[:, None] * stride_v_new_d

        tl.store(K_new + off_k_new, k, mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len))
        tl.store(V_new + off_v_new, v, mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len))
            
    for start_n in range(0, cur_batch_query_len, BLOCK_N):
        off_k = (start_n + offs_n[None, :]) * stride_k_bs + cur_kv_head * stride_k_h + offs_d[:, None] * stride_k_d
        off_v = (start_n + offs_n[None, :]) * stride_v_bs + cur_kv_head * stride_v_h + offs_d[:, None] * stride_v_d
        k = tl.load(K + off_k,
                    mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len),
                    other=0.0)  # [D,N]
        v = tl.load(V + off_v,
                    mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len),
                    other=0.0)  # [D,N]
        
        off_k_new = (cur_batch_ctx_len + start_n + offs_n[None, :]) * stride_k_new_bs + cur_kv_head * stride_k_new_h + offs_d[:, None] * stride_k_new_d
        off_v_new = (cur_batch_ctx_len + start_n + offs_n[None, :]) * stride_v_new_bs + cur_kv_head * stride_v_new_h + offs_d[:, None] * stride_v_new_d

        tl.store(K_new + off_k_new, k, mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len))
        tl.store(V_new + off_v_new, v, mask=dim_mask[:, None] &
                    ((start_n + offs_n[None, :]) < cur_batch_ctx_len))

def block_table_trans(k, v, k_cache, v_cache, b_loc, b_start_loc, b_seq_len):
    B = b_seq_len.shape[0]
    H_KV = k.shape[1]
    D = k.shape[2]
    dtype = k.dtype
    BLOCK_N = 64
    total_tokens = b_seq_len.sum().item()
    k_new = torch.empty((total_tokens, H_KV, D), dtype=dtype, device="cuda")
    v_new = torch.empty((total_tokens, H_KV, D), dtype=dtype, device="cuda")
    x = k_cache.shape[-1]
    grid = (B, H_KV)
    block_size = v_cache.shape[-1]
    _block_table_trans[grid](
        k,
        v,
        k_new,
        v_new,
        k_cache,
        v_cache,
        b_loc,
        b_start_loc,
        b_seq_len,
        block_size,
        x,
        k.stride(0),
        k.stride(1),
        k.stride(2),
        v.stride(0),
        v.stride(1),
        v.stride(2),    
        k_new.stride(0),
        k_new.stride(1),
        k_new.stride(2),
        v_new.stride(0),
        v_new.stride(1),
        v_new.stride(2),
        k_cache.stride(0),
        k_cache.stride(1),
        k_cache.stride(2),
        k_cache.stride(3),
        k_cache.stride(4),
        v_cache.stride(0),
        v_cache.stride(1),
        v_cache.stride(2),
        v_cache.stride(3),
        b_loc.stride(0),
        b_loc.stride(1),
        BLOCK_DMODEL=D,
        BLOCK_DMODEL_PADDED=triton.next_power_of_2(D),
        BLOCK_N=BLOCK_N,
    )

    return k_new, v_new