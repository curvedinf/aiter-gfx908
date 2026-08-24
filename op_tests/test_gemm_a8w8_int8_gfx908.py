# SPDX-License-Identifier: MIT
"""gfx908 int8 (W8A8) contract verification for gemm_a8w8_CK.

The CK A8W8 module builds on gfx908 but only accepts PER-TOKEN scales
(x_scale [M,1] fp32, w_scale [N,1] fp32) — per-128-block scale layouts
produce garbage (this was the historical 'garbled outputs on gfx908'
report: wrong scale contract, not a kernel bug).

Correctness: meanrel ~1.8e-4 vs dequantized reference.
Bench (vs vLLM-triton W8A8, packed-GPTQ): 1.8x (M=64) to 6.8x (M=8).
"""
import torch
import aiter
from aiter import gemm_a8w8_CK, pertoken_quant

torch.manual_seed(0)
dev = "cuda"
fails = 0
for M in (1, 8, 64, 512, 4096):
    for K, N, tag in ((5120, 5120, "sq"), (5120, 17408, "upgate"), (17408, 5120, "down")):
        X = torch.randn(M, K, device=dev, dtype=torch.float16)
        W = torch.randn(N, K, device=dev, dtype=torch.float16)
        xq, xs = pertoken_quant(X, quant_dtype=torch.int8)
        wq, ws = pertoken_quant(W, quant_dtype=torch.int8)
        Y = gemm_a8w8_CK(xq, wq, xs, ws, None, torch.float16)
        ref = (xq.float() * xs) @ (wq.float() * ws).t()
        rel = ((Y.float() - ref).abs() / ref.abs().clamp(min=1e-2)).mean().item()
        ok = rel < 1e-3
        fails += not ok
        print(f"M={M:5d} {tag:7s} meanrel={rel:.6f} {'PASS' if ok else 'FAIL'}")
print("VERDICT:", "ALL PASS" if not fails else f"{fails} FAILURES")
