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


@perftest(num_iters=5)
def run_torch(x, weight, x_scale, w_scale,  dtype=torch.bfloat16):
    x = x.to(dtypes.fp32) * x_scale
    weight = weight.to(dtypes.fp32) * w_scale
    out = F.linear(x, weight)
    return out.to(dtype)
@perftest()
def run_gemm_ck_bpreshuffle(x, weight, x_scale, w_scale, dtype=torch.float16):
    return aiter.gemm_a8w8_bpreshuffle_CK(x, weight, x_scale, w_scale, dtype)

@benchmark()
def test_flatmm_ck(dtype, m, n, k):
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
    a, avg_a = run_torch(x, weight, x_scale, w_scale, dtype)
    b, avg_b = run_gemm_ck_bpreshuffle(x, weight_shuffle, x_scale, w_scale, dtype)
    tflops = 2 * m *n *k /avg_b /1e6
    msg = f"[perf] tflops: {tflops} ,dim: {str(dim):<20} dtype: {dtype}, torch avg: {avg_a:<8.2f} us,ck wpreshuffle avg: {avg_b:<8.2f} us,uplift: {avg_a/avg_b -1:<5.1%}"
    checkAllclose(a, b, msg="ck_preshuffle: " + msg, rtol=1e-2, atol=0.01)
    return {"ck_preshuffle": avg_b}

df = []
for dtype in [torch.float16]:
    for (n, k) in [(9216, 4096),(4608, 4096),]:
        for m in [1, 2, 4, 8, 16, 32, 64, 128, 256, 1024, 2048, 4096, 16384, 32768]:
            ret = test_flatmm_ck(dtype, m, n, k)
            df.append(ret)
df = pd.DataFrame(df)
aiter.logger.info(f"summary:\n{df}")

