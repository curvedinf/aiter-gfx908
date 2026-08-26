#!/usr/bin/env python
# SPDX-License-Identifier: MIT
# Default-vs-tuned a8w8 decode performance on gfx908.
# Env AITER_CONFIG_GEMM_A8W8 selects the config CSV; run this script twice:
# once pointing at a no-gfx908 CSV (today's default: splitK=0 + C++ heuristic)
# and once at the tuned CSV. Prints per-shape us for later join.
import os

import torch

import aiter

tuned_csv = os.environ["AITER_CONFIG_GEMM_A8W8"]
tag = "TUNED" if "gfx908" in open(tuned_csv).read()[:0] + open(tuned_csv).read() else "TUNED"
tag = "TUNED" if any(l.startswith("gfx908") for l in open(tuned_csv)) else "DEFAULT"

SHAPES = [
    (1, 512, 1536), (1, 1024, 1536), (1, 1280, 1536), (1, 1536, 1536),
    (1, 2048, 1536), (1, 3072, 1536),
    (1, 1024, 4352), (1, 1536, 4352), (1, 2048, 4352), (1, 3072, 4352),
    (1, 4096, 4352),
    (1, 1024, 5120), (1, 1280, 5120), (1, 1536, 5120), (1, 2048, 5120),
    (16, 512, 1536), (16, 1024, 1536), (16, 1536, 5120), (16, 3072, 5120),
    (16, 2048, 4352),
]

torch.manual_seed(0)
dev = "cuda"
res = []
for M, N, K in SHAPES:
    xq = torch.randint(-20, 21, (M, K), dtype=torch.int8, device=dev)
    wq = torch.randint(-20, 21, (N, K), dtype=torch.int8, device=dev)
    xs = torch.rand(M, 1, dtype=torch.float32, device=dev) * 0.02
    ws = torch.rand(1, N, dtype=torch.float32, device=dev) * 0.02
    try:
        for _ in range(20):
            aiter.gemm_a8w8(xq, wq, xs, ws, dtype=torch.float16)
        torch.cuda.synchronize()
        s, e = torch.cuda.Event(True), torch.cuda.Event(True)
        s.record()
        iters = 1000 if M == 1 else 300
        for _ in range(iters):
            aiter.gemm_a8w8(xq, wq, xs, ws, dtype=torch.float16)
        e.record()
        torch.cuda.synchronize()
        us = s.elapsed_time(e) * 1000 / iters
        res.append((M, N, K, us))
    except RuntimeError as ex:
        res.append((M, N, K, float("nan")))
        print(f"# ERR {M}x{N}x{K}: {str(ex)[:80]}")

for M, N, K, us in res:
    print(f"{tag} {M} {N} {K} {us:.3f}")
