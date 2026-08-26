#!/usr/bin/env python
# SPDX-License-Identifier: MIT
# Phase 4.3: tune the Triton a8w8 blockscale kernel per (N,K) on gfx908.
# Sweeps BLOCK_M/BLOCK_N/NUM_KSPLIT at decode Ms (BLOCK_K pinned to 128:
# kernel requires GROUP_K == BLOCK_SIZE_K and GS128 checkpoints fix the
# group at 128), picks the fastest config, writes specialized
# gfx908-GEMM-A8W8_BLOCKSCALE-N=x-K=y.json files.
import itertools
import json
import os

import torch

from aiter.ops.triton.gemm.basic.gemm_a8w8_blockscale import gemm_a8w8_blockscale

OUT_DIR = "aiter/ops/triton/configs/gemm"
SHAPES_KN = [
    (512, 1536), (1024, 1536), (1280, 1536), (1536, 1536), (2048, 1536),
    (3072, 1536), (1024, 4352), (1536, 4352), (2048, 4352), (3072, 4352),
    (4096, 4352), (1024, 5120), (1280, 5120), (1536, 5120), (2048, 5120),
]
MS = [1, 2, 4, 8, 16]  # decode regime
GRID = list(
    itertools.product(
        [16, 32],           # BLOCK_SIZE_M
        [64, 128, 256],     # BLOCK_SIZE_N
        [128],              # BLOCK_SIZE_K (== GROUP_K == 128)
        [1, 2, 4],          # NUM_KSPLIT
        [2, 4],             # num_stages
    )
)

dev = "cuda"
torch.manual_seed(0)
written = 0
for N, K in SHAPES_KN:
    tensors = []
    for M in MS:
        xq = torch.randint(-20, 21, (M, K), dtype=torch.int8, device=dev)
        xs = torch.rand(M, K // 128, dtype=torch.float32, device=dev) * 0.02
        ws = torch.rand(N // 128, K // 128, dtype=torch.float32, device=dev) * 0.02
        tensors.append((M, N, K, xq, xs, ws))
    wq = torch.randint(-20, 21, (N, K), dtype=torch.int8, device=dev)

    best = None
    for bm, bn, bk, ks, ns in GRID:
        if ks > 1 and (K // ks) < bk:
            continue
        cfg = {
            "BLOCK_SIZE_M": bm, "BLOCK_SIZE_N": bn, "BLOCK_SIZE_K": bk,
            "GROUP_SIZE_M": 4, "num_warps": 4, "num_stages": ns,
            "NUM_KSPLIT": ks,
        }
        try:
            us = []
            for M, N_, K_, xq, xs, ws in tensors:
                for _ in range(10):
                    gemm_a8w8_blockscale(xq, wq, xs, ws, dtype=torch.float16, config=dict(cfg))
                torch.cuda.synchronize()
                s, e = torch.cuda.Event(True), torch.cuda.Event(True)
                s.record()
                for _ in range(200):
                    gemm_a8w8_blockscale(xq, wq, xs, ws, dtype=torch.float16, config=dict(cfg))
                e.record()
                torch.cuda.synchronize()
                us.append(s.elapsed_time(e) * 1000 / 200)
            score = sum(us) / len(us)
            if best is None or score < best[0]:
                best = (score, cfg)
        except Exception:
            continue
    if best:
        score, cfg = best
        fn = os.path.join(OUT_DIR, f"gfx908-GEMM-A8W8_BLOCKSCALE-N={N}-K={K}.json")
        with open(fn, "w") as f:
            json.dump({"any": cfg}, f, indent=1)
        written += 1
        print(f"N={N:5d} K={K:5d}: {score:7.2f}us  BM={cfg['BLOCK_SIZE_M']} BN={cfg['BLOCK_SIZE_N']} KS={cfg['NUM_KSPLIT']} ns={cfg['num_stages']}")

print(f"\nwrote {written} specialized gfx908 blockscale configs")
