#!/usr/bin/env python
# SPDX-License-Identifier: MIT
# Kernel-level (graph-captured) default-vs-tuned a8w8 decode bench.
# Captures 100 GEMM launches in a CUDA graph, replays it: per-kernel time =
# graph time / 100. Removes the ~30us Python/launch wrapper floor that
# dominates the eager bench.
import os

import torch

import aiter

tuned_csv = os.environ["AITER_CONFIG_GEMM_A8W8"]
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
N_LAUNCH = 100
for M, N, K in SHAPES:
    try:
        xq = torch.randint(-20, 21, (M, K), dtype=torch.int8, device=dev)
        wq = torch.randint(-20, 21, (N, K), dtype=torch.int8, device=dev)
        xs = torch.rand(M, 1, dtype=torch.float32, device=dev) * 0.02
        ws = torch.rand(1, N, dtype=torch.float32, device=dev) * 0.02
        for _ in range(5):
            aiter.gemm_a8w8(xq, wq, xs, ws, dtype=torch.float16)
        torch.cuda.synchronize()
        # capture: N_LAUNCH dependent-free GEMMs (own buffers each)
        g = torch.cuda.CUDAGraph()
        bufs = []
        with torch.cuda.graph(g):
            for _ in range(N_LAUNCH):
                bufs.append(aiter.gemm_a8w8(xq, wq, xs, ws, dtype=torch.float16))
        for _ in range(3):
            g.replay()
        torch.cuda.synchronize()
        s, e = torch.cuda.Event(True), torch.cuda.Event(True)
        s.record()
        reps = 20
        for _ in range(reps):
            g.replay()
        e.record()
        torch.cuda.synchronize()
        us = s.elapsed_time(e) * 1000 / (reps * N_LAUNCH)
        print(f"{tag} {M} {N} {K} {us:.3f}")
    except RuntimeError as ex:
        print(f"{tag} {M} {N} {K} nan")
        print(f"# ERR {M}x{N}x{K}: {str(ex)[:100]}")
