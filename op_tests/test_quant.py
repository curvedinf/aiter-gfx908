# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

from aiter.test_common import (
    checkAllclose,
    perftest,
    tensor_dump,
    benchmark,
    run_perftest,
)
import torch
import torch.nn.functional as F
import numpy as np
import sys
import os
import aiter
from aiter.ops.shuffle import shuffle_weight
from aiter import dtypes
from aiter import get_hip_quant, get_torch_quant, get_triton_quant
from aiter import QuantType
import itertools

torch.set_default_device("cuda")


@perftest()
def test_aiter_perTensorQuantFp8(input, scale=None):
    q_func = get_hip_quant(QuantType.per_Tensor)
    out, scale = q_func(input, scale=scale)
    return out, scale


@perftest()
def test_torch_perTensorQuantFp8(input, scale=None):
    q_func = get_torch_quant(QuantType.per_Tensor)
    out, scale = q_func(input, scale=scale, quant_dtype=dtypes.fp8)
    return out, scale.view(1)


@perftest()
def test_aiter_perTokenQuantFp8(input):
    q_func = get_hip_quant(QuantType.per_Token)
    out, scale = q_func(input, quant_dtype=dtypes.fp8)
    return out, scale


@perftest()
def test_torch_perTokenQuantFp8(input):
    q_func = get_torch_quant(QuantType.per_Token)
    out, scale = q_func(input, quant_dtype=dtypes.fp8)
    return out, scale


@perftest()
def test_triton_perTokenQuantFp8(input):
    q_func = get_triton_quant(QuantType.per_Token)
    out, scale = q_func(input, quant_dtype=dtypes.fp8)
    return out, scale


# @perftest()
# def test_ck_perTokenQuanti8(input):
#     M, N = input.shape
#     device = input.device
#     out = torch.empty((M, N), dtype=dtypes.i8, device=device)
#     scale = torch.empty(M, dtype=dtypes.fp32, device=device)
#     smooth_scale = torch.ones(N, dtype=dtypes.fp32, device=device)
#     aiter.smoothquant_fwd(out, input, smooth_scale, scale)
#     return out, scale


@benchmark()
def test_quant(m, n, q_type, q_dtype, h_dtype):
    dim = (m, n)

    input = torch.randn(dim, dtype=h_dtype)
    ref, ref_scale = get_torch_quant(q_type)(input, quant_dtype=q_dtype)

    q_funcs = {
        # "triton": get_triton_quant,
        "hip": get_hip_quant,
    }
    for name, q_func in q_funcs.items():
        q_func = q_func(q_type)
        (out, scale), us1 = run_perftest(q_func, input, quant_dtype=q_dtype)
        checkAllclose(
            ref.to(dtypes.fp32),
            out.to(dtypes.fp32),
            rtol=0.125,
            atol=1e-3,
            msg=f"{name}: dynamic quant",
        )
        (out, scale), us2 = run_perftest(q_func, input, scale, quant_dtype=q_dtype)
        checkAllclose(
            ref.to(dtypes.fp32),
            out.to(dtypes.fp32),
            rtol=0.125,
            atol=1e-3,
            msg=f"{name}: static  quant",
        )


list_quant = [
    (aiter.QuantType.per_Tensor, dtypes.fp8),
    # (aiter.QuantType.per_Token, dtypes.fp8),
    # (aiter.QuantType.per_Token, dtypes.i8),
]
list_dtype = [dtypes.fp16, dtypes.bf16]
import pandas as pd

for (
    (q_type, q_dtype),
    h_dtype,
) in itertools.product(list_quant, list_dtype):
    df = []
    for m in [1, 16, 32, 64, 128, 192, 256, 512, 1024]:
        for n in [4096, 8192]:
            ret = test_quant(m, n, q_type, q_dtype, h_dtype)
            df.append(ret)
    df = pd.DataFrame(df)
    aiter.logger.info(f"summary:\n{df}")
