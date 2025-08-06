
import random
import torch
from typing import List, Tuple

import aiter
from aiter.test_common import checkAllclose, benchmark, run_perftest
from aiter.ops.shuffle import shuffle_weight

def per_token_cast_to_fp8(x: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
    assert x.dim() == 2
    m, n = x.shape
    pad_size = (128 - (n % 128)) % 128
    x = torch.nn.functional.pad(x, (0, pad_size), value=0) if pad_size > 0 else x
    x_view = x.view(m, -1, 128)
    x_amax = x_view.abs().float().amax(dim=2).view(m, -1).clamp(1e-4)
    fp8_data = (x_view * (448.0 / x_amax.unsqueeze(2))).to(torch.float8_e4m3fn)
    return fp8_data.view(m, n + pad_size)[:, :n], (x_amax / 448.0).view(m, -1)

def per_block_cast_to_fp8(x: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
    assert x.dim() == 2
    m, n = x.shape
    x_padded = torch.zeros(((m + 127) // 128 * 128, (n + 127) // 128 * 128), dtype=x.dtype, device=x.device)
    x_padded[:m, :n] = x
    x_view = x_padded.view(-1, 128, x_padded.size(1) // 128, 128)
    x_amax = x_view.abs().float().amax(dim=(1, 3), keepdim=True).clamp(1e-4)
    x_scaled = (x_view * (448.0 / x_amax)).to(torch.float8_e4m3fn)
    return x_scaled.view_as(x_padded)[:m, :n].contiguous(), (x_amax / 448.0).view(x_view.size(0), x_view.size(2))

def construct_contiguous_grouped(num_groups: int, expected_m_per_group: int, k: int, n: int) -> \
        Tuple[int, Tuple[torch.Tensor, torch.Tensor], Tuple[torch.Tensor, torch.Tensor], torch.Tensor, torch.Tensor, torch.Tensor]:
    alignment = get_m_alignment_for_contiguous_layout()
    group_ms = [int(expected_m_per_group * random.uniform(0.7, 1.3)) for _ in range(num_groups)]
    m = sum([ceil_div(x, alignment) * alignment for x in group_ms])

    x = torch.randn((m, k), device='cuda', dtype=torch.bfloat16)
    y = torch.randn((num_groups, n, k), device='cuda', dtype=torch.bfloat16)
    m_indices = torch.empty(m, device='cuda', dtype=torch.int32)
    out = torch.empty((m, n), device='cuda', dtype=torch.bfloat16)
    ref_out = torch.randn((m, n), device='cuda', dtype=torch.bfloat16)

    start = 0
    for i, group_m in enumerate(group_ms):
        actual_end = start + group_m
        aligned_end = start + ceil_div(group_m, alignment) * alignment
        m_indices[start:actual_end] = i
        m_indices[actual_end:aligned_end] = -1
        ref_out[start:aligned_end] = x[start:aligned_end] @ y[i].t()
        start = aligned_end
    ref_out = torch.where((m_indices == -1).unsqueeze(1), torch.zeros_like(ref_out), ref_out)

    assert m % 4 == 0, f'TMA alignment error: {m}'
    x_fp8 = per_token_cast_to_fp8(x)
    y_fp8 = (torch.empty_like(y, dtype=torch.float8_e4m3fn), torch.empty((num_groups, ceil_div(n, 128), k // 128), device='cuda', dtype=torch.float))
    for i in range(num_groups):
        y_fp8[0][i], y_fp8[1][i] = per_block_cast_to_fp8(y[i])

    return m, x_fp8, y_fp8, m_indices, out, ref_out

def construct_masked_grouped(num_groups: int, max_m: int, expected_m_per_group: int, k: int, n: int, dtypes=torch.bfloat16) -> \
        Tuple[Tuple[torch.Tensor, torch.Tensor], Tuple[torch.Tensor, torch.Tensor], torch.Tensor, torch.Tensor, torch.Tensor]:
    x = torch.randn((num_groups, max_m, k), device='cuda', dtype=torch.bfloat16)
    y = torch.randn((num_groups, n, k), device='cuda', dtype=torch.bfloat16)
    out = torch.zeros((num_groups, max_m, n), device='cuda', dtype=torch.bfloat16)

    from aiter import dtypes
    assert max_m % 4 == 0, f'TMA alignment error: {max_m}'
    x_fp8 = [torch.empty_like(x, dtype=dtypes.fp8), torch.empty((num_groups, max_m, 1), device='cuda', dtype=torch.float)]
    y_fp8 = [torch.empty_like(y, dtype=dtypes.fp8), torch.empty((num_groups, n, 1), device='cuda', dtype=torch.float)]
    # if dtypes not in [torch.bfloat16, torch.half]:
    torch_quant = aiter.get_triton_quant(aiter.QuantType.per_Token)
    for i in range(num_groups):
        x_fp8[0][i], x_fp8[1][i] = torch_quant(x[i], quant_dtype=dtypes.fp8)
        y_fp8[0][i], y_fp8[1][i] = torch_quant(y[i], quant_dtype=dtypes.fp8)

    # else:
    #     x_fp8[0] = x
    #     y_fp8[0] = y
    # Transpose earlier so that the testing will not trigger transposing kernels
    # x_fp8 = (x_fp8[0], get_col_major_tma_aligned_tensor(x_fp8[1]))\

    print(x_fp8[0][i].shape, x_fp8[1][i].shape)
    x = x_fp8[0].to(float) * x_fp8[1]
    y = y_fp8[0].to(float) * y_fp8[1]
    ref_out = torch.einsum('gmk,gnk->gmn', x, y).to(torch.bfloat16)
    # Construct mask
    # TODO: remove follow line
    # ref_out = torch.einsum('gmk,gnk->gmn', x_fp8[0], y_fp8[0])
    masked_m = torch.empty((num_groups, ), device='cuda', dtype=torch.int)
    for j in range(num_groups):
        masked_m[j] = int(expected_m_per_group * random.uniform(0.7, 1.3))
    assert masked_m.amax().item() <= max_m
    return x_fp8, y_fp8, masked_m, out, ref_out

# print('Testing grouped contiguous GEMM:')
# for num_groups, expected_m_per_group in ((2, 512), (4, 256)):
#     for k, n in ((256, 256), (256, 256), ):
#         # Test correctness
#         for i in range(10):
#             x_fp8, y_fp8, masked_m, out, ref_out = construct_contiguous_grouped(num_groups, 2048, expected_m_per_group, k, n)
#             print(f"{masked_m=}")
#             weightshuffle = shuffle_weight(y_fp8[0], layout=(16, 16))
#             x = torch.ones_like(x_fp8[0])
#             y = torch.ones_like(weightshuffle)

#             aiter.m_grouped_flatmm_ck(x, y, x_fp8[1], y_fp8[1], out, masked_m)

#         for j in range(num_groups):
#             # print(f"{out[j, :masked_m[j].item()]=}")
#             # print(f"{torch.ones_like(x_fp8[0])=}")
#             err = checkAllclose(
#                 ref_out[j, :masked_m[j].item()],
#                 out[j, :masked_m[j].item()],
#                 msg=f"",
#             )

print('Testing grouped masked GEMM:')
for num_groups, expected_m_per_group in ((2, 512), (4, 256)):
    for k, n in ((512, 256), (512, 256), ):
        # Test correctness
        for i in range(10):
            x_fp8, y_fp8, masked_m, out, ref_out = construct_masked_grouped(num_groups, 2048, expected_m_per_group, k, n)
            print(f"{masked_m=}")
            weightshuffle = shuffle_weight(y_fp8[0], layout=(16, 16))
            aiter.m_grouped_gemm(x_fp8[0], weightshuffle, out, masked_m, x_fp8[1], y_fp8[1])

        for j in range(num_groups):
            # print(f"{out[j, :masked_m[j].item()]=}")
            err = checkAllclose(
                out[j, :masked_m[j].item()],
                ref_out[j, :masked_m[j].item()],
                msg=f"")

        # print(x_fp8[0])
        # print(x_fp8[1])
