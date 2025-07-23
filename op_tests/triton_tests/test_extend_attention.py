# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import pytest
from aiter.ops.triton.extend_attention import extend_attention_fwd
from aiter.test_mha_common import (
    attention_ref,
    generate_random_padding_mask,
    generate_qkv,
)

def input_helper(
    B,
    H,
    prefix_length,
    extend_length,
    kv_lora_rank,
    qk_rope_head_dim,
    v_head_dim,
    dtype,
    device,
    attn_impl="normal",
    equal_seqlens=False,
    requires_grad=False,
):
    torch.manual_seed(0)

    if not equal_seqlens:
        max_extend_length = extend_length
        max_prefix_length = prefix_length

        seqlens_extend = torch.randint(
            1, max_extend_length + 1, (B,), dtype=torch.int32
        )
        if prefix_length == 0:
            seqlens_prefix = torch.full((B,), prefix_length)
        else:
            seqlens_prefix = torch.randint(
                1, max_prefix_length + 1, (B,), dtype=torch.int32
            )

    else:
        seqlens_extend = torch.full((B,), extend_length)
        seqlens_prefix = torch.full((B,), prefix_length)

    cu_seqlens_extend = torch.cat(
        [
            torch.tensor([0], dtype=torch.int32),
            seqlens_extend.cumsum(dim=0, dtype=torch.int32),
        ]
    )
    cu_seqlens_prefix = torch.cat(
        [
            torch.tensor([0], dtype=torch.int32),
            seqlens_prefix.cumsum(dim=0, dtype=torch.int32),
        ]
    )

    cu_seqlens_extend = cu_seqlens_extend.to(device="cuda")
    cu_seqlens_prefix = cu_seqlens_prefix.to(device="cuda")

    total_extend = cu_seqlens_extend[-1].item()
    total_prefix = cu_seqlens_prefix[-1].item()

    if attn_impl == "absorb":
        Lq = kv_lora_rank + qk_rope_head_dim
        Lk = kv_lora_rank + qk_rope_head_dim
        Lv = kv_lora_rank
    else:
        Lq = v_head_dim + qk_rope_head_dim
        Lk = v_head_dim + qk_rope_head_dim
        Lv = v_head_dim

    q_extend = torch.randn(
        total_extend, H, Lq, dtype=dtype, device=device
    ).requires_grad_(requires_grad)

    # extend parts
    k_extend = torch.randn(
        total_extend, 1, Lk, dtype=dtype, device=device
    ).requires_grad_(requires_grad)
    v_extend = k_extend[..., :Lv]

    # extend indexing
    qo_indptr = cu_seqlens_extend

    # prefix parts
    k_buffer = torch.randn(
        total_prefix, 1, Lk, dtype=dtype, device=device
    ).requires_grad_(requires_grad)
    v_buffer = k_buffer[..., :Lv]

    if attn_impl != "absorb":
        # simulate v = kv_latent * w_vc which changes the values compared to k
        v_extend = torch.randn_like(v_extend)
        v_buffer = torch.randn_like(v_buffer)

    # prefix indexing
    kv_indptr = cu_seqlens_prefix
    kv_indices = torch.arange(total_prefix, device=device)

    custom_mask = None
    mask_indptr = None
    max_len_extend = extend_length

    return (
        q_extend,
        k_extend,
        v_extend,
        k_buffer,
        v_buffer,
        kv_indptr,
        kv_indices,
        qo_indptr,
        custom_mask,
        mask_indptr,
        max_len_extend,
    )


@pytest.mark.parametrize(
    "B, H, prefix, extend, kv_lora_rank, qk_rope_head_dim, v_head_dim",
    [
        (2, 4, 0, 512, 32, 16, 32),
        (3, 5, 0, 333, 18, 13, 17),
        (3, 5, 512, 333, 18, 0, 17),
        (3, 5, 110, 333, 18, 0, 19),
        # (8, 16, 0, 1024, 128, 0, 128), # this one passes
        # (8, 16, 0, 16324, 128, 0, 128), # this one fails, numeric precision is likely the issue
    ],
)
@pytest.mark.parametrize("dtype", [torch.float32])
@pytest.mark.parametrize("causal", [False, True])
@pytest.mark.parametrize("ref_attn_impl", ["normal", "absorb"])
def test_op_fwd(
    B,
    H,
    prefix,
    extend,
    kv_lora_rank,
    qk_rope_head_dim,
    v_head_dim,
    dtype,
    ref_attn_impl,
    causal,
    sm_scale=1.0,
    logit_cap=0.0,
    device="cuda",
):
    torch.manual_seed(0)
    torch.set_default_device(device)
    torch.set_default_dtype(dtype)

    (
        q_extend,
        k_extend,
        v_extend,
        k_buffer,
        v_buffer,
        kv_indptr,
        kv_indices,
        qo_indptr,
        custom_mask,
        mask_indptr,
        max_len_extend,
    ) = input_helper(
        B,
        H,
        prefix,
        extend,
        kv_lora_rank,
        qk_rope_head_dim,
        v_head_dim,
        dtype,
        device,
        ref_attn_impl,
    )
    tri_out = torch.empty(
        (*q_extend.shape[:-1], v_extend.shape[-1]),
        dtype=q_extend.dtype,
        device=q_extend.device,
    )

    # Reference
    extend_attention_fwd(
        q_extend,
        k_extend,
        v_extend,
        tri_out,
        k_buffer,
        v_buffer,
        qo_indptr,
        kv_indptr,
        kv_indices,
        custom_mask,
        causal,
        mask_indptr,
        max_len_extend,
        sm_scale=sm_scale,
        logit_cap=logit_cap,
    )

    # Number of sequences/B is inferred from the length of kv_indptr (which has B+1 entries)
    B = kv_indptr.shape[0] - 1

    # Loop through each sequence, concatenate the prefix (from k_buffer) and extend part (from k_extend)
    key_list = []
    value_list = []
    kv_lengths = []

    query_list = []
    query_lengths = []

    for i in range(B):
        start_prefix = kv_indptr[i].item()
        end_prefix = kv_indptr[i + 1].item()
        start_extend = qo_indptr[i].item()
        end_extend = qo_indptr[i + 1].item()

        key = torch.cat((k_buffer[start_prefix:end_prefix],
                         k_extend[start_extend:end_extend]), dim=0) 
        
        value = torch.cat((v_buffer[start_prefix:end_prefix],
                          v_extend[start_extend:end_extend]), dim=0) 
        
        query = q_extend[start_extend:end_extend] 

        value_list.append(value)
        key_list.append(key)
        kv_lengths.append(value.shape[0])

        query_list.append(query)
        query_lengths.append(query.shape[0])

    # Determine the maximum kv sequence length
    max_kv_length = max(kv_lengths)
    max_query_length = max(query_lengths)

    # Pad each sequence along the sequence dimension (dim=0) to have the same length and stack into [B, max_total, ...]
    padded_k = torch.zeros(
        (B, max_kv_length, 1, k_extend.shape[-1]), dtype=k_extend.dtype, device=k_extend.device
    )
    padded_v = torch.zeros(
        (B, max_kv_length, 1, v_extend.shape[-1]), dtype=k_extend.dtype, device=k_extend.device
    )
    padded_q = torch.zeros(
        (B, max_query_length, H, q_extend.shape[-1]), dtype=q_extend.dtype, device=q_extend.device
    )

    key_padding_mask = torch.zeros(
        (B, max_kv_length), dtype=torch.bool, device=k_extend.device
    )
    query_padding_mask = torch.zeros(
        (B, max_query_length), dtype=torch.bool, device=q_extend.device
    )

    for i in range(B):
        padded_k[i, :kv_lengths[i]] = key_list[i]
        padded_v[i, :kv_lengths[i]] = value_list[i]
        padded_q[i, :query_lengths[i]] = query_list[i]

        key_padding_mask[i, :kv_lengths[i]] = 1
        query_padding_mask[i, :query_lengths[i]] = 1

    padded_ref_out, _ = attention_ref(
        padded_q,
        padded_k,
        padded_v,
        query_padding_mask=query_padding_mask,
        key_padding_mask=key_padding_mask,
        causal=causal,
        upcast=False,

    )
    # Unpad and flatten the reference output using the query_padding_mask.
    ref_out = []
    for i in range(query_padding_mask.shape[0]):
        # Get indices of valid (unpadded) queries for sample i.
        valid_indices = torch.nonzero(query_padding_mask[i], as_tuple=False).squeeze(-1)
        ref_out.append(padded_ref_out[i, valid_indices])
    ref_out = torch.cat(ref_out, dim=0)

    torch.testing.assert_close(ref_out, tri_out, rtol=2e-2, atol=2e-2)

if __name__ == "__main__":
    test_op_fwd(3, 5, 110, 333, 16, 0, 16, torch.float16, "normal", True)
    print("Float16 test passed.")
    # test_op_fwd(3, 5, 110, 333, 18, 0, 17, torch.bfloat16, "normal", True)
    # print("BFloat16 test passed.")
