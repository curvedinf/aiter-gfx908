# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import torch.nn.functional as F
import aiter
from aiter import dtypes
from aiter.test_common import checkAllclose, perftest, benchmark
from aiter.ops.shuffle import shuffle_weight
from einops import rearrange
from einops import repeat as eirp
import pandas as pd

block_shape = (128, 128)


@perftest(num_iters=5)
def run_torch(x, weight, x_scale, w_scale, dtype=dtypes.bf16):
    block_shape_n, block_shape_k = block_shape
    m, k = x.shape
    n = weight.shape[0]
    scale_n = (n + block_shape_n - 1) // block_shape_n
    scale_k = (k + block_shape_k - 1) // block_shape_k
    x = x.to(x_scale.dtype).view(
        m, k // block_shape[1], block_shape[1]
    ) * x_scale.unsqueeze(-1)
    x = x.view(m, k)

    w_scale = rearrange(
        w_scale.view(-1, 1)
        .repeat(1, block_shape_n * block_shape_k)
        .view(scale_n, scale_k, block_shape_n, block_shape_k),
        "num_blk_n num_blk_k blk_n blk_k -> (num_blk_n blk_n) (num_blk_k blk_k)",
    )
    w_scale = w_scale[:n, :k]
    weight = weight.to(w_scale.dtype) * w_scale

    out = F.linear(x.to(dtypes.fp32), weight.to(dtypes.fp32))
    return out.to(dtype)


@perftest()
def run_gemm_ck(x, weight, x_scale, w_scale, dtype=dtypes.bf16):
    return aiter.gemm_a8w8_blockscale_CK(x, weight, x_scale, w_scale, dtype)

@perftest()
def run_gemm_ck_bpreshuffle(x, weight, x_scale, w_scale, dtype=dtypes.fp16):
    return aiter.gemm_a8w8_bpreshuffle_CK(x, weight, x_scale, w_scale, dtype)

@benchmark()
def test_gemm(dtype, m, n, k):
    dim = (m, n, k)
    block_shape_n, block_shape_k = block_shape
    scale_n = (n + block_shape_n - 1) // block_shape_n
    scale_k = (k + block_shape_k - 1) // block_shape_k
    x = (torch.rand((m, k), dtype=dtypes.fp16, device="cuda") / 10).to(dtypes.fp8)
    weight = (torch.rand((n, k), dtype=dtypes.fp16, device="cuda") / 10).to(dtypes.fp8)
    x_scale = torch.ones([m, scale_k], dtype=dtypes.fp32, device="cuda")
    w_scale = torch.ones([scale_n, scale_k], dtype=dtypes.fp32, device="cuda")
    weight_shuffle = shuffle_weight(weight, layout=(16, 16))
    # print("solin:====scale_k =", scale_k)
    # print("solin:====scale_n =", scale_n)
    a, avg_a = run_torch(x, weight, x_scale, w_scale, dtype)
    b, avg_b = run_gemm_ck(x, weight, x_scale, w_scale, dtype)
    c, avg_c = run_gemm_ck_bpreshuffle(x, weight_shuffle, x_scale, w_scale, dtype)


    msg = f"[perf] dim: {str(dim):<20} dtype: {dtype}, torch avg: {avg_a:<8.2f} us, ck avg: {avg_b:<8.2f} us, ck wpreshuffle avg: {avg_c:<8.2f} us uplift: {avg_a/min(avg_b, avg_c) -1:<5.1%}"
    print(msg)
    checkAllclose(a, b, msg="ck:", rtol=1e-2, atol=0.01)
    checkAllclose(a, c, msg="ck_wpreshuffle: ", rtol=1e-2, atol=0.01)
    tflops = 2 * m *n *k /avg_c /1e6

    return {"ck": avg_b, "ck_wpreshuffle": avg_c, "ck_wpreshuffle_tflops":tflops}


@perftest(num_iters=5)
def run_torch2(x, weight, x_scale, w_scale, dtype=torch.float16):
    block_shape_n, block_shape_k = block_shape
    m, k = x.shape
    n = weight.shape[0]

    x_scale_ = eirp(x_scale, "m k -> m (k repeat)", repeat=block_shape_k)
    x_scale_ = x_scale_[:m, :k]

    w_scale_ = eirp(w_scale, "n k -> (n repeat) k", repeat=block_shape_n)
    w_scale_ = eirp(w_scale_, "n k -> n (k repeat)", repeat=block_shape_k)
    w_scale_ = w_scale_[:n, :k]

    x_ = x.to(x_scale.dtype) * x_scale_
    weight_ = weight.to(w_scale.dtype) * w_scale_

    out = F.linear(x_.to(dtypes.fp32), weight_.to(dtypes.fp32))
    return out.to(dtype)

df = []
for dtype in [torch.float16]:
    for m in [2048]:
        for (n, k) in [(4096, 5120),]:
            test_gemm(dtype, m, n, k)
            break
            df.append(ret)
df = pd.DataFrame(df)
aiter.logger.info(f"summary:\n{df}")
