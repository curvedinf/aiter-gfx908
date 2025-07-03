# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import aiter
from aiter import dtypes
from aiter.test_common import (
    perftest,
)
from aiter.test_mha_common import (
    attention_ref,
)
import pytest
import sys


def run_torch(
    q,
    k,
    v,
    upcast=True,
    reorder_ops=False,
):
    out, _ = attention_ref(q, k, v, upcast=upcast, reorder_ops=reorder_ops)

    return out


@perftest()
def profile_func(target_func, *args, **kwargs):
    return target_func(*args, **kwargs)


@pytest.mark.parametrize("dtype", [dtypes.fp16, dtypes.bf16])
@pytest.mark.parametrize("mha_type", ["mha", "mqa", "gqa"])
@pytest.mark.parametrize("batch_size", [5])
@pytest.mark.parametrize("nheads", [6])
@pytest.mark.parametrize(
    "d,d_v",
    [
        (128, 128),
    ],
)
@pytest.mark.parametrize(
    "seqlen_q,seqlen_k",
    [
        (113, 203),
        (128, 217),
        (113, 211),
        (108, 256),
        (256, 512),
        (512, 256),
        (1024, 1024),
        (1023, 1024),
        (1024, 1023),
        (2048, 2048),
    ],
)
@pytest.mark.parametrize("seed", [None])
def test_flash_attn_output(
    batch_size,
    nheads,
    seqlen_q,
    seqlen_k,
    d,
    d_v,
    mha_type,
    dtype,
    seed,
    profile=False,
):
    if seed is not None:
        torch.random.manual_seed(seed)
    torch.cuda.empty_cache()
    nheads_k = nheads if mha_type == "mha" else (1 if mha_type == "mqa" else 3)
    assert nheads % nheads_k == 0

    def print_tensor(tensor, tensor_name):
        tensor_list = tensor.tolist()

        for i, row in enumerate(tensor_list):
            formatted_row = ", ".join("{:5.2f}".format(x) for x in row)
            print("[HOST] {0}[{1:3}] = {2}".format(tensor_name, i, formatted_row))
        sys.stdout.flush()

    q = torch.randn(
        batch_size, seqlen_q, nheads, d, device="cuda", dtype=dtype, requires_grad=False
    )
    k = torch.randn(
        batch_size,
        seqlen_k,
        nheads_k,
        d,
        device="cuda",
        dtype=dtype,
        requires_grad=False,
    )
    v = torch.randn(
        batch_size,
        seqlen_k,
        nheads_k,
        d_v,
        device="cuda",
        dtype=dtype,
        requires_grad=False,
    )
    print(f'{q.shape=}')
    print(f'{k.shape=}')
    print(f'{v.shape=}')

    def save_tensor(tensor, fname):
        tensor_np = tensor.cpu().numpy()
        tensor_np.tofile(fname)

    save_tensor(q.squeeze(0).squeeze(1), "q_256x128.bin")
    save_tensor(k.squeeze(0).squeeze(1), "k_32x128.bin")
    save_tensor(v.squeeze(0).squeeze(1), "v_32x128.bin")

    # print_tensor(q.squeeze(0).squeeze(1), 'Q')
    # print_tensor(k.squeeze(0).squeeze(1), 'K')
    # print_tensor(v.squeeze(0).squeeze(1), 'V')

    attention = aiter.poyenc_mha_v3_fwd_func
    if profile:
        out, time = profile_func(attention, q, k, v)
        print(f"time: {time}")
    else:
        out = attention(q, k, v)

    out_ref = run_torch(
        q,
        k,
        v,
    )

    out_pt = run_torch(
        q,
        k,
        v,
        upcast=False,
        reorder_ops=True,
    )

    # torch.testing.assert_allclose(out[:, :128, :, :], out_ref[:, :128, :, :], rtol=1e-3, atol=1e-3)

    if not profile:
        print(f"Output max diff: {(out - out_ref).abs().max().item()}")
        print(f"Output Pytorch max diff: {(out_pt - out_ref).abs().max().item()}")
    out_tol = max(2 * (out_pt - out_ref).abs().max().item(), 0.01)
    assert (out - out_ref).abs().max().item() <= out_tol


if __name__ == "__main__":
    batch_size = 1
    nheads = 1
    (seqlen_q, seqlen_k) = (256, 32)
    d = 128
    d_v = 128
    mha_type = "mha"
    dtype = dtypes.fp16
    seed = 0

    test_flash_attn_output(
        batch_size, nheads, seqlen_q, seqlen_k, d, d_v, mha_type, dtype, seed
    )
