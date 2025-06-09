# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

from aiter.test_common import checkAllclose, perftest, tensor_dump, benchmark
import torch
import torch.nn.functional as F
import numpy as np
import sys
import os
import aiter
from aiter.utility import dtypes
from aiter.ops.shuffle  import shuffle_weight
import pandas as pd
from einops import rearrange
from einops import repeat as eirp

block_shape = (128, 128)

@perftest()
def run_flatmm(x, weight, x_scale, w_scale, dtype=torch.float):
    
    return aiter.flatmm_CK(x, weight, x_scale, w_scale, dtype)

@perftest()
def run_gemm_ck_bpreshuffle(x, weight, x_scale, w_scale, dtype=torch.float16):
    return aiter.gemm_a8w8_bpreshuffle_CK(x, weight, x_scale, w_scale, dtype)

@perftest(num_iters=5)
def run_torch(x, weight, x_scale, w_scale,  dtype=torch.float):
    x = x.to(dtypes.fp32)
    weight = weight.to(dtypes.fp32)
    out = F.linear(x, weight)
    return out.to(dtype)

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

    out = F.linear(x_.to(torch.float32), weight_.to(torch.float32))
    return out.to(dtype)

@benchmark()
def test_flatmm_ck(dtype, m, n, k):
    dim = (m, n, k)
    block_shape_n, block_shape_k = block_shape
    scale_m = m
    scale_n = (n + block_shape_n - 1) // block_shape_n
    scale_k = (k + block_shape_k - 1) // block_shape_k

    x = (torch.rand((m, k), dtype=torch.float32, device="cuda") / 10).to(
        torch.float8_e4m3fnuz
    )
    weight = (torch.rand((n, k), dtype=torch.float32, device="cuda") / 10).to(
        torch.float8_e4m3fnuz
    )
    x_scale = torch.ones([scale_k, scale_m], dtype=torch.float32, device="cuda")
    w_scale = torch.ones([scale_k, scale_n], dtype=torch.float32, device="cuda")
    x_scale_trans = torch.transpose(x_scale, 0, 1)
    w_scale_trans = torch.transpose(w_scale, 0, 1)

    flat_weight = weight.view(n // 16, 16, k // 64, 4, 16)
    flat_weight = flat_weight.permute(0, 2, 3, 1, 4).contiguous()
    flat_weight = flat_weight.view(n, -1)

    a, avg_a = run_torch2(x, weight, x_scale_trans, w_scale_trans, dtype)
    # a, avg_a = run_gemm_ck_bpreshuffle(x, flat_weight, x_scale, w_scale, dtype)
    b, avg_b = run_flatmm(x, flat_weight, x_scale, w_scale, dtype)
    tflops = 2 * m *n *k /avg_b /1e6
    print(a)
    print(b)
    msg = f"[solin  perf] tflops: {tflops} ,dim: {str(dim):<20} dtype: {dtype}, torch avg: {avg_a:<8.2f} us, cktile avg: {avg_b:<8.2f} us, uplift: {avg_a/avg_b -1:<5.1%}"
    checkAllclose(a, b, msg="a,b: " + msg, rtol=1e-2, atol=0.01)

@benchmark()
def test_flatmm(dtype, m, n, k):
    dim = (m, n, k)
    x = torch.randn((m, k), dtype=dtypes.fp16, device="cuda")
    weight = torch.randn((n, k), dtype=dtypes.fp16, device="cuda")
    x, x_scale = aiter.pertoken_quant(x, quant_dtype=dtypes.fp8)
    weight, w_scale = aiter.pertoken_quant(weight, quant_dtype=dtypes.fp8)
    weight_shuffle = shuffle_weight(weight, layout=(16, 16))
    out = torch.empty(m, n, dtype=dtypes.fp16, device="cuda")
    flat_weight = weight.view(n // 16, 16, k // 64, 4, 16)
    flat_weight = flat_weight.permute(0, 2, 3, 1, 4).contiguous()
    flat_weight = flat_weight.view(n, -1)
    #weight_shuffle = shuffle_weight(weight, layout=(16, 16))
    x_scale = torch.ones([1, m], dtype=torch.float32, device="cuda")
    w_scale = torch.ones([1, n], dtype=torch.float32, device="cuda")
    x_scale_trans = torch.transpose(x_scale, 0, 1)
    w_scale_trans = torch.transpose(w_scale, 0, 1)
    out = torch.empty(m, n, dtype=dtypes.fp16, device="cuda")

    a, avg_a = run_torch(x, weight, x_scale_trans, w_scale_trans, dtype)
    b, avg_b = run_flatmm(x, flat_weight, x_scale, w_scale, dtype)
    # flat_weight = weight.view(n // 16, 16, k // 64, 4, 16)
    # flat_weight = flat_weight.permute(0, 2, 3, 1, 4).contiguous()
    # flat_weight = flat_weight.view(n, -1)
    # x_scale = torch.ones_like(x_scale)
    # w_scale = torch.ones_like(w_scale)
    # x_scale_trans = torch.transpose(x_scale, 0, 1)
    # w_scale_trans = torch.transpose(w_scale, 0, 1)


    # a, avg_a = run_gemm_ck_bpreshuffle(x, weight_shuffle, x_scale, w_scale, dtype)
    # b, avg_b = run_flatmm(x, weight_shuffle, x_scale, w_scale, dtype)
    # scale = x_scale @ w_scale.transpose(0,1)
    # b_dequant = b * scale
    # a, avg_a = run_torch(x, weight, x_scale_trans, w_scale_trans, dtype)

    # b, avg_b = run_flatmm(x, weight_shuffle, x_scale, w_scale, dtype)
    tflops = 2 * m *n *k /avg_b /1e6
    msg = f"[perf] tflops: {tflops} ,dim: {str(dim):<20} dtype: {dtype}, torch avg: {avg_a:<8.2f} us,cktile flatmm avg: {avg_b:<8.2f} us,uplift: {avg_a/avg_b -1:<5.1%}"
    # checkAllclose(a, b_dequant.to(torch.float16), msg="cktile flatmm: " + msg, rtol=1e-2, atol=0.01)
    checkAllclose(a, b, msg="cktile flatmm: " + msg, rtol=1e-2, atol=0.01)
    return {"cktile flatmm": avg_b}


df = []
for dtype in [torch.float16]:
    for (n, k) in [(4096, 5120),]:
        for m in [2048]:
            # ret = test_flatmm_ck(dtype, m, n, k)//can pass
            ret = test_flatmm(dtype, m, n, k)
            df.append(ret)
df = pd.DataFrame(df)
aiter.logger.info(f"summary:\n{df}")

