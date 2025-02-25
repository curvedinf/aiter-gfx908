"""
Copyright (c) 2023 by FlashInfer team.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import math
from typing import Tuple

import pytest
import torch
import aiter

def is_cuda():
    return hasattr(torch, "cuda") and torch.version.cuda is not None

def get_compute_capability(device: torch.device) -> Tuple[int, int]:
    if device.type != "cuda":
        raise ValueError("device must be a cuda device")
    return torch.cuda.get_device_capability(device.index)

def mla_is_fa3_supported(device: torch.device) -> bool:
    if is_cuda():
        major, _ = get_compute_capability(device)
        return major == 9 and torch.version.cuda >= "12.3"
    else: 
        return True

def attention_ref(
    batch_size,
    q: torch.Tensor,
    k: torch.Tensor,
    v: torch.Tensor,
    causal: bool,
    sm_scale: float,
) -> torch.Tensor:
    qo_len = q.shape[0] // batch_size
    kv_len = k.shape[0] // batch_size
    num_qo_heads = q.shape[1]
    head_dim_qk = q.shape[2]
    head_dim_vo = v.shape[2]
    logits = (
        torch.einsum(
            "bmhd,bnhd->bhmn",
            q.view(batch_size, qo_len, num_qo_heads, head_dim_qk).float(),
            k.view(batch_size, kv_len, num_qo_heads, head_dim_qk).float(),
        )
        * sm_scale
    )

    if causal:
        mask = (
            torch.arange(kv_len - qo_len, kv_len).unsqueeze(1)
            >= torch.arange(0, kv_len).unsqueeze(0)
        ).to(q.device)
    else:
        mask = torch.ones(qo_len, kv_len).to(q.device)

    logits = logits.masked_fill(mask.unsqueeze(0).unsqueeze(0) == 0, float("-inf"))
    lse_ref = torch.logsumexp(logits, -1).transpose(-1, -2)
    p = torch.softmax(logits, dim=-1)
    o_ref = (
        torch.einsum(
            "bhmn,bnhd->bmhd",
            p,
            v.view(batch_size, kv_len, num_qo_heads, head_dim_vo).float(),
        )
        .contiguous()
        .view(batch_size * qo_len, num_qo_heads, head_dim_vo)
        .to(q)
    )

    return o_ref, lse_ref * math.log2(math.e)

def generate_kv_from_cache(ckv, kpe, kv_len, batch_size, num_heads):
    bs_page_num, page_size, ckv_dim = ckv.shape
    page_num = bs_page_num // batch_size
    _, _, kpe_dim = kpe.shape
    ckv = ckv.view(batch_size, page_num * page_size, ckv_dim)
    kpe = kpe.view(batch_size, page_num * page_size, kpe_dim)
    ckv = ckv[:, :kv_len, :]
    kpe = kpe[:, :kv_len, :]
    k = (
        torch.cat([ckv, kpe], dim=-1)
        .view(-1, 1, ckv_dim + kpe_dim)
        .repeat_interleave(num_heads, dim=1)
    )
    v = ckv.repeat_interleave(num_heads, dim=1)

    return k, v


@pytest.mark.parametrize("batch_size", [1, 2, 3, 4, 5, 6, 7])
@pytest.mark.parametrize("kv_len_0", [0, 1, 2, 3, 4, 11])
@pytest.mark.parametrize("kv_len_1", [17, 19, 33, 79, 114])
@pytest.mark.parametrize("kv_len_2", [514, 2743, 8736])
@pytest.mark.parametrize(
    "qo_len", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
)
@pytest.mark.parametrize("num_heads", [16, 32, 64])
@pytest.mark.parametrize("causal", [False, True])
@pytest.mark.parametrize("page_size", [1])
@pytest.mark.parametrize("backend", ["fa3"])
@pytest.mark.parametrize("dtype", [torch.half])
def test_batch_mla_varlen_page_attention(
    batch_size,
    kv_len_0,
    kv_len_1,
    kv_len_2,
    qo_len,
    num_heads,
    causal,
    page_size,
    backend,
    dtype,
):
    if not mla_is_fa3_supported(torch.device("cuda")):
        pytest.skip("FA3 is not supported on this device")
    if causal and qo_len > min(kv_len_0, kv_len_1, kv_len_2):
        pytest.skip("qo_len > kv_len not supported for causal attention")
    num_different_kv_len = 3
    kv_lens = torch.tensor([kv_len_0, kv_len_1, kv_len_2], dtype=torch.int32)
    torch.manual_seed(42)
    head_dim_ckv = 512
    head_dim_kpe = 64
    q_nope = torch.randn(
        num_different_kv_len * batch_size * qo_len,
        num_heads,
        head_dim_ckv,
        dtype=dtype,
        device="cuda",
    )
    q_pe = torch.randn(
        num_different_kv_len * batch_size * qo_len,
        num_heads,
        head_dim_kpe,
        dtype=dtype,
        device="cuda",
    )
    pages_nums = torch.tensor(
        [math.ceil(kv_len / page_size) for kv_len in kv_lens],
        dtype=torch.int32,
    )
    pages_nums_indptr = torch.zeros(num_different_kv_len + 1, dtype=torch.int32)
    pages_nums_indptr[1:] = pages_nums.cumsum(0)
    pages_nums_sum = pages_nums_indptr[-1]
    ckv = torch.randn(
        batch_size * pages_nums_sum,
        page_size,
        head_dim_ckv,
        dtype=dtype,
        device="cuda",
    )
    kpe = torch.randn(
        batch_size * pages_nums_sum,
        page_size,
        head_dim_kpe,
        dtype=dtype,
        device="cuda",
    )
    sm_scale = 1.0 / ((128 + 64) ** 0.5)
    workspace_buffer = torch.empty(128 * 1024 * 1024, dtype=torch.int8).to(0)
    wrapper = aiter.BatchMLAPagedAttentionWrapper(
        workspace_buffer, backend=backend
    )
    q_indptr = (
        torch.arange(0, num_different_kv_len * batch_size + 1).to(0).int() * qo_len
    )
    kv_indptr = torch.cat(
        [
            torch.arange(0, batch_size + 1).unsqueeze(-1).int() * pages_nums_sum
            + pages_nums_indptr[i]
            for i in range(num_different_kv_len)
        ],
        dim=-1,
    ).flatten()
    kv_indices = torch.arange(0, batch_size * pages_nums_sum).to(0).int()
    kv_lens = torch.tensor(kv_lens, dtype=torch.int32).to(0).repeat(batch_size)
    wrapper.plan(
        q_indptr,
        kv_indptr,
        kv_indices,
        kv_lens,
        num_heads,
        head_dim_ckv,
        head_dim_kpe,
        page_size,
        causal,
        sm_scale,
        q_nope.dtype,
        ckv.dtype,
    )
    o, lse = wrapper.run(q_nope, q_pe, ckv, kpe, return_lse=True)

    q_rows = (
        torch.arange(0, num_different_kv_len * qo_len)[None, :]
        + torch.arange(0, batch_size)[:, None] * num_different_kv_len * qo_len
    ).int()
    kv_rows = (
        torch.arange(0, pages_nums_sum)[None, :]
        + torch.arange(0, batch_size)[:, None] * pages_nums_sum
    ).int()
    q_rows_arr = [
        q_rows[:, i * qo_len : (i + 1) * qo_len].flatten()
        for i in range(num_different_kv_len)
    ]
    kv_rows_arr = [
        kv_rows[:, pages_nums_indptr[i] : pages_nums_indptr[i + 1]].flatten()
        for i in range(num_different_kv_len)
    ]
    for i in range(num_different_kv_len):
        k, v = generate_kv_from_cache(
            ckv[kv_rows_arr[i]], kpe[kv_rows_arr[i]], kv_lens[i], batch_size, num_heads
        )
        q = torch.cat([q_nope, q_pe], dim=-1)[q_rows_arr[i]]
        o_ref, lse_ref = attention_ref(batch_size, q, k, v, causal, sm_scale)
        lse_ref = lse_ref.flatten(0, 1)
        o_i = o[q_rows_arr[i]]
        lse_i = lse[q_rows_arr[i]]
        torch.testing.assert_close(o_i, o_ref, rtol=1e-3, atol=1e-3)
        # if kv_lens[i] != 0:
        #     torch.testing.assert_close(lse_i, lse_ref, rtol=1e-3, atol=1e-3)


@pytest.mark.parametrize("batch_size", [1, 2, 3, 4, 5, 6, 7, 157])
@pytest.mark.parametrize("kv_len", [0, 17, 33, 96, 97, 114, 514, 1024])
@pytest.mark.parametrize(
    "qo_len", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
)
@pytest.mark.parametrize("num_heads", [16])
@pytest.mark.parametrize("causal", [False, True])
@pytest.mark.parametrize("page_size", [1, 16])
@pytest.mark.parametrize("backend", ["fa2", "fa3"])
@pytest.mark.parametrize("use_cuda_graph", [True, False])
@pytest.mark.parametrize("dtype", [torch.half])
def test_batch_mla_page_attention(
    batch_size,
    kv_len,
    qo_len,
    num_heads,
    causal,
    page_size,
    backend,
    use_cuda_graph,
    dtype,
):
    if not mla_is_fa3_supported(torch.device("cuda")):
        pytest.skip("FA3 is not supported on this device")
    if causal and qo_len > kv_len:
        pytest.skip("qo_len > kv_len not supported for causal attention")
    torch.manual_seed(42)
    head_dim_ckv = 512
    head_dim_kpe = 64
    q_nope = torch.randn(
        batch_size * qo_len, num_heads, head_dim_ckv, dtype=dtype, device="cuda"
    )
    q_pe = torch.randn(
        batch_size * qo_len, num_heads, head_dim_kpe, dtype=dtype, device="cuda"
    )
    pages_num = math.ceil(kv_len / page_size)
    ckv = torch.randn(
        batch_size * pages_num,
        page_size,
        head_dim_ckv,
        dtype=dtype,
        device="cuda",
    )
    kpe = torch.randn(
        batch_size * pages_num,
        page_size,
        head_dim_kpe,
        dtype=dtype,
        device="cuda",
    )
    sm_scale = 1.0 / ((128 + 64) ** 0.5)  # use head dimension before matrix absorption
    workspace_buffer = torch.empty(128 * 1024 * 1024, dtype=torch.int8).to(0)
    wrapper = aiter.BatchMLAPagedAttentionWrapper(
        workspace_buffer,
        backend=backend,
        use_cuda_graph=True,
        qo_indptr=torch.empty(batch_size + 1, dtype=torch.int32, device="cuda"),
        kv_indptr=torch.empty(batch_size + 1, dtype=torch.int32, device="cuda"),
        kv_indices=torch.empty(1048576, dtype=torch.int32, device="cuda"),
        kv_len_arr=torch.empty(batch_size, dtype=torch.int32, device="cuda"),
    )
    q_indptr = torch.arange(0, batch_size + 1).to(0).int() * qo_len
    kv_indptr = torch.arange(0, batch_size + 1).to(0).int() * pages_num
    kv_indices = torch.arange(0, batch_size * pages_num).to(0).int()
    kv_lens = torch.full((batch_size,), kv_len, dtype=torch.int32).to(0)

    if use_cuda_graph:
        kv_indptr_warmup = torch.zeros(batch_size + 1).to(0).int()
        kv_indices_warmup = torch.arange(0, batch_size).to(0).int()
        kv_lens_warmup = torch.full((batch_size,), 0, dtype=torch.int32).to(0)
        wrapper.plan(
            q_indptr,
            kv_indptr_warmup,
            kv_indices_warmup,
            kv_lens_warmup,
            num_heads,
            head_dim_ckv,
            head_dim_kpe,
            page_size,
            causal,
            sm_scale,
            q_nope.dtype,
            ckv.dtype,
        )

        # warmup
        s = torch.cuda.Stream()
        s.wait_stream(torch.cuda.current_stream())
        with torch.cuda.stream(s):
            for _ in range(3):
                o, lse = wrapper.run(q_nope, q_pe, ckv, kpe, return_lse=True)
        torch.cuda.current_stream().wait_stream(s)

        # capture
        g = torch.cuda.CUDAGraph()
        with torch.cuda.graph(g):
            o, lse = wrapper.run(q_nope, q_pe, ckv, kpe, return_lse=True)

    wrapper.plan(
        q_indptr,
        kv_indptr,
        kv_indices,
        kv_lens,
        num_heads,
        head_dim_ckv,
        head_dim_kpe,
        page_size,
        causal,
        sm_scale,
        q_nope.dtype,
        ckv.dtype,
    )
    if use_cuda_graph:
        o.fill_(0)
        lse.fill_(0)
        g.replay()
    else:
        o, lse = wrapper.run(q_nope, q_pe, ckv, kpe, return_lse=True)

    k, v = generate_kv_from_cache(ckv, kpe, kv_len, batch_size, num_heads)

    q = torch.cat([q_nope, q_pe], dim=-1)
    o_ref, lse_ref = attention_ref(batch_size, q, k, v, causal, sm_scale)
    lse_ref = lse_ref.flatten(0, 1)
    torch.testing.assert_close(o, o_ref, rtol=1e-3, atol=1e-3)
    if kv_len != 0:
        torch.testing.assert_close(lse, lse_ref, rtol=1e-3, atol=1e-3)

    # test with pre-allocated output
    o_buffer = torch.empty_like(o)
    lse_buffer = torch.empty_like(lse)
    wrapper.run(q_nope, q_pe, ckv, kpe, out=o_buffer, lse=lse_buffer)
    torch.testing.assert_close(o, o_buffer, rtol=1e-3, atol=1e-3)
    torch.testing.assert_close(lse, lse_buffer, rtol=1e-3, atol=1e-3)


if __name__ == "__main__":
    test_batch_mla_varlen_page_attention(
        155, 0, 8, 8, 128, 16, False, 1, "fa3", torch.half
    )
    test_batch_mla_varlen_page_attention(
        155, 1024, 8, 128, 128, 16, False, 1, "fa3", torch.half
    )
    test_batch_mla_page_attention(1, 1024, 128, 128, False, 1, "fa2", True, torch.half)
