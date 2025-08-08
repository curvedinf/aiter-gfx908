
import random
import torch
from typing import List, Tuple

import aiter

from aiter.test_common import checkAllclose, benchmark, run_perftest
from aiter.ops.shuffle import shuffle_weight

from aiter import dtypes


def construct_masked_grouped(num_groups: int, max_m: int, expected_m_per_group: int, k: int, n: int, quant_dtype=aiter.dtypes.fp8, dtypes=torch.bfloat16) -> \
        Tuple[Tuple[torch.Tensor, torch.Tensor], Tuple[torch.Tensor, torch.Tensor], torch.Tensor, torch.Tensor, torch.Tensor]:
    x = torch.randn((num_groups, max_m, k), device='cuda', dtype=torch.bfloat16)
    y = torch.randn((num_groups, n, k), device='cuda', dtype=torch.bfloat16)
    out = torch.zeros((num_groups, max_m, n), device='cuda', dtype=torch.bfloat16)

    x_fp8 = [torch.empty_like(x, dtype=quant_dtype), torch.empty((num_groups, max_m, 1), device='cuda', dtype=torch.float)]
    y_fp8 = [torch.empty_like(y, dtype=quant_dtype), torch.empty((num_groups, n, 1), device='cuda', dtype=torch.float)]
    # if dtypes not in [torch.bfloat16, torch.half]:
    if quant_dtype in [aiter.dtypes.fp8]:
        torch_quant = aiter.get_triton_quant(aiter.QuantType.per_Token)
        for i in range(num_groups):
            x_fp8[0][i], x_fp8[1][i] = torch_quant(x[i], quant_dtype=quant_dtype)
            y_fp8[0][i], y_fp8[1][i] = torch_quant(y[i], quant_dtype=quant_dtype)

        x = x_fp8[0].to(float) * x_fp8[1]
        y = y_fp8[0].to(float) * y_fp8[1]
    else :
        x_fp8[0] = x
        y_fp8[0] = y


    ref_out = torch.einsum('gmk,gnk->gmn', x, y).to(torch.bfloat16)

    masked_m = torch.empty((num_groups, ), device='cuda', dtype=torch.int)
    for j in range(num_groups):
        masked_m[j] = int(expected_m_per_group * random.uniform(0.7, 1.3))
        ref_out[j][masked_m[j]:] = 0
    assert masked_m.amax().item() <= max_m
    return x_fp8, y_fp8, masked_m, out, ref_out



print('Testing grouped masked FP8-GEMM:')
for num_groups, expected_m_per_group in ((2, 512), (4, 256)):
    for k, n in ((512, 256), (512, 256), ):
        # Test correctness
        for i in range(10):
            x_fp8, y_fp8, masked_m, out, ref_out = construct_masked_grouped(num_groups, 2048, expected_m_per_group, k, n)
            weightshuffle = shuffle_weight(y_fp8[0], layout=(16, 16))
            aiter.m_grouped_gemm(x_fp8[0], weightshuffle, out, masked_m, x_fp8[1], y_fp8[1])

        err = checkAllclose(
            out,
            ref_out,
            msg=f"")



print('Testing grouped masked BF16-GEMM:')
for num_groups, expected_m_per_group in ((2, 512), (4, 256)):
    for k, n in ((512, 256), (512, 256), ):
        # Test correctness
        for i in range(10):
            x_fp8, y_fp8, masked_m, out, ref_out = construct_masked_grouped(num_groups, 2048, expected_m_per_group, k, n, quant_dtype=torch.bfloat16)
            weightshuffle = shuffle_weight(y_fp8[0], layout=(16, 16))
            # No quant, no scale parameter
            aiter.m_grouped_gemm(x_fp8[0], weightshuffle, out, masked_m)

        # for j in range(num_groups):
            # print(f"{out[j, :masked_m[j].item()]=}")
        err = checkAllclose(
            out,
            ref_out,
            msg=f"")
