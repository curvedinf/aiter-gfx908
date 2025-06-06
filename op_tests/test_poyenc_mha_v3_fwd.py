# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import aiter
from aiter import dtypes
from aiter.test_mha_common import (
    attention_ref,
)
import pytest


def run_torch(
    q,
    k,
    v,
    upcast=True,
    reorder_ops=False,
):
    out, _ = attention_ref(
        q,
        k,
        v,
        upcast=upcast,
        reorder_ops=reorder_ops
    )

    return out

def run_ck(
    q,
    k,
    v,
):
    """
    out = aiter.flash_attn_func(
        q,
        k,
        v
    )
    """
    """"""
    out = aiter.poyenc_mha_v3_fwd_func(
        q,
        k,
        v
    )
    """"""

    return out


@pytest.mark.parametrize("dtype", [dtypes.bf16])
@pytest.mark.parametrize("mha_type", ["mha", "mqa", "gqa"])
@pytest.mark.parametrize("batch_size", [5])
@pytest.mark.parametrize("nheads", [6])
@pytest.mark.parametrize(
    "d,d_v",
    [
        (32, 32),
        (40, 40),
        (59, 59),
        (64, 64),
        (96, 96),
        (111, 111),
        (128, 128),
        (160, 160),
        (192, 192),
        (224, 224),
        (256, 256),
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
def test_flash_attn_output(
    batch_size,
    nheads,
    seqlen_q,
    seqlen_k,
    d,
    d_v,
    mha_type,
    dtype,
):
    torch.random.manual_seed(0)
    torch.cuda.empty_cache()
    nheads_k = nheads if mha_type == "mha" else (1 if mha_type == "mqa" else 3)
    assert nheads % nheads_k == 0

    q = torch.randn(
        batch_size, seqlen_q, nheads, d, device="cuda", dtype=dtype, requires_grad=True
    )
    k = torch.randn(
        batch_size,
        seqlen_k,
        nheads_k,
        d,
        device="cuda",
        dtype=dtype,
        requires_grad=True,
    )
    v = torch.randn(
        batch_size,
        seqlen_k,
        nheads_k,
        d_v,
        device="cuda",
        dtype=dtype,
        requires_grad=True,
    )

    out = run_ck(
        q,
        k,
        v
    )

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

    print(f"Output max diff: {(out - out_ref).abs().max().item()}")
    print(f"Output Pytorch max diff: {(out_pt - out_ref).abs().max().item()}")
    out_tol = max(2 * (out_pt - out_ref).abs().max().item(), 0.01)
    assert (out - out_ref).abs().max().item() <= out_tol


if __name__ == "__main__":
    batch_size = 2
    nheads = 5
    (seqlen_q, seqlen_k) = (512, 512)
    d = 128
    d_v = 128
    mha_type = "mha"
    dtype = dtypes.bf16

    test_flash_attn_output(
        batch_size,
        nheads,
        seqlen_q,
        seqlen_k,
        d,
        d_v,
        mha_type,
        dtype,
    )
