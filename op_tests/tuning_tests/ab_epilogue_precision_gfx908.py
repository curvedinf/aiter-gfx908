#!/usr/bin/env python
# SPDX-License-Identifier: MIT
# Phase 4.1 A/B: epilogue-precision for the gfx908 pruned a8w8 module.
#
# Calls module_gemm_a8w8's gemm_a8w8 directly (bypasses config lookup) with
# splitK=0 so the same kernel template runs for both variants; the ONLY
# difference is x_scale/w_scale dtype: fp32 -> <I8,F32,F16> (dF32), fp16 ->
# <I8,F16,F16> (dF16). Reference is fp64 dequant matmul.
#
# Run on an idle GPU: scripts/gpu_guard.sh --card 1 env HIP_VISIBLE_DEVICES=1 ...
import os
import sys

import torch

sys.path.insert(0, os.environ["AITER_JIT_DIR"])
import module_gemm_a8w8 as m  # noqa: E402

torch.manual_seed(0)
dev = "cuda"

# Production-typical rank-local shapes (decode M small, the accuracy-critical
# regime; K from the Qwen3.8-27B TP4 projection set).
SHAPES = [
    (1, 512, 1536),
    (16, 512, 1536),
    (16, 3072, 5120),
    (128, 2048, 1536),
    (2048, 1024, 4352),
]


def bench(M, N, K):
    xq = torch.randint(-20, 21, (M, K), dtype=torch.int8, device=dev)
    wq = torch.randint(-20, 21, (N, K), dtype=torch.int8, device=dev)
    # Scales like production pertoken/perchannel: small positive fp32.
    x_s = torch.rand(M, 1, dtype=torch.float32, device=dev) * 0.02
    w_s = torch.rand(1, N, dtype=torch.float32, device=dev) * 0.02

    ref = (
        (xq.double() * x_s.double()) @ (wq.double() * w_s.double()).t()
    )  # fp64 dequant ref

    out_f32 = torch.empty(M, N, dtype=torch.float16, device=dev)
    out_f16 = torch.empty(M, N, dtype=torch.float16, device=dev)
    m.gemm_a8w8(xq, wq, x_s, w_s, out_f32, None, 0)  # dF32 path
    m.gemm_a8w8(
        xq, wq, x_s.half(), w_s.half(), out_f16, None, 0
    )  # dF16 path

    def rel_l2(a):
        d = (a.double() - ref)
        return (d.norm() / ref.norm()).item()

    return rel_l2(out_f32), rel_l2(out_f16)


print(f"{'M,N,K':>24}  {'dF32 rel-L2':>12}  {'dF16 rel-L2':>12}  winner")
for M, N, K in SHAPES:
    try:
        r32, r16 = bench(M, N, K)
        w = "dF32" if r32 < r16 else ("dF16" if r16 < r32 else "tie")
        print(f"{f'{M},{N},{K}':>24}  {r32:12.6f}  {r16:12.6f}  {w}")
    except RuntimeError as e:
        print(f"{f'{M},{N},{K}':>24}  ERROR: {str(e)[:120]}")
