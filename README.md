# int8-aiter

A downstream fork of [ROCm/aiter](https://github.com/ROCm/aiter) (AI Tensor
Engine for ROCm) with one purpose: making aiter's INT8 W8A8 inference path
work — correctly and fast — on **AMD Instinct MI100 (gfx908, CDNA1)**.

Upstream aiter targets CDNA3/CDNA4 and RDNA (gfx942, gfx950, gfx1250, …);
gfx908 receives no upstream support. This fork carries the gfx908-specific
kernel, communication, and build changes needed to serve a production vLLM
stack on a 4×MI100 node.

## Serving stack this fork targets

The consumer is the companion vLLM fork,
[curvedinf/int8-vllm](https://github.com/curvedinf/int8-vllm), running:

- **Qwen3.8-27B-class** model, **W8A8 INT8** (GPTQ weights, per-token
  activation quant)
- **TP4** across 4×MI100
- fp16 activations, **DFlash2** speculative decoding
- aiter CK GEMMs + aiter custom all-reduce inside vLLM's CUDA-graph-captured
  decode path

## Enhancements over upstream

All fork changes sit on top of regular `upstream/main` merges and are kept
small and rebaseable. The fork-specific commits touch ~16 files.

### 1. CK INT8 W8A8 GEMM on gfx908

- `module_gemm_a8w8` (Composable Kernel `a8w8_rowwise` instances) builds and
  runs correctly on gfx908.
- The historical "garbled outputs on gfx908" report is resolved: it was a
  scale-contract issue, not a kernel bug. On gfx908 the CK A8W8 module accepts
  **per-token scales only** (`x_scale [M,1] fp32`, `w_scale [N,1] fp32`);
  per-128-block scale layouts are not supported by these instances.
- Verified by `op_tests/test_gemm_a8w8_int8_gfx908.py` — meanrel ~1.8e-4 vs
  dequantized reference across M ∈ {1, 8, 64, 512, 4096}.
- Benchmarks **1.8× (M=64) to 6.8× (M=8)** faster than vLLM's Triton W8A8
  path (packed-GPTQ baseline).

### 2. Custom all-reduce (CAR) on MI100

`module_custom_all_reduce` is enabled for gfx908 and hardened for serving:

- **CUDA graph capture fixes** — captured all-reduces previously corrupted
  output. Fixes include an uncached eager input pool, signal hardening, and a
  port of vLLM's graph-pool workaround: graph-captured ARs are routed through
  the pre-registered pool.
- **Fused AR + RMSNorm + INT8 quant** kernels, eliminating separate
  norm/quant passes in the TP4 hot path:
  - `fused_allreduce_rmsnorm_quant_int8_per_group` — per-group scales,
    vLLM W8A8 activation format (int8 `[M,K]`, fp16 scales `[M, K/group_size]`)
  - `fused_allreduce_rmsnorm_quant_int8_per_token` — per-token scales,
    aiter `pertoken_quant` format (int8 `[M,K]`, fp32 scales `[M,1]`)
- gfx908 CU count (120) registered in the JIT build/tuning tables
  (`aiter/jit/utils/build_targets.py`).
- Multigpu test coverage under `op_tests/multigpu_tests/`:
  `test_car_graph_repro.py`, `test_car_stress_mixed.py`,
  `test_ipc_graph_poison.py`, `test_fused_ar_rms_int8_quant.py`.

### 3. Triton tuning config for gfx908

`aiter/ops/triton/configs/gemm/gfx908-GEMM-A8W8_BLOCKSCALE.json` provides a
tuned A8W8 blockscale GEMM config — the no-CK-change fallback for blockwise
scales.

### 4. gfx908-only build plan (in progress)

Full upstream builds take ~6 hours on this box because they compile 124
modules and 72 CK `a8w8_rowwise` template instances — almost none of which
this stack calls. [`GFX908_BUILD_PLAN.md`](GFX908_BUILD_PLAN.md) lays out the
remediation (status: **PLAN**, not yet implemented):

- `PREBUILD_KERNELS=4` allowlist build profile (`AITER_MI100_MODULES`),
  pinning `GPU_ARCHS=gfx908` — target: full rebuild < 1 h
- CK instance pruning in `csrc/ck_gemm_a8w8/gen_instances.py` (drop fp8 and
  bf16-epilogue instances that can never run here; 72 → ~8–15 files)
- Fail-fast guard (`AITER_CK_STRICT=1`) so a missing tuned config is a loud
  error instead of a silent default-config fallback
- Tuning sweep to fill `aiter/configs/a8w8_tuned_gemm.csv` with gfx908 rows
  (currently zero — every production GEMM runs default config)
- W8A8 accuracy kernel variants (blockwise GS128 scale layouts) attacking the
  measured act-quant and requant error legs

Design rules: prune by exclusion (never delete sources, so upstream merges
stay clean); the Python package stays fully importable; only the compiled
module and CK instance sets shrink.

## Build

```bash
git clone --recursive <this repo>
cd aiter
GPU_ARCHS=gfx908 python3 setup.py develop
```

If you cloned without `--recursive`:

```bash
git submodule sync && git submodule update --init --recursive
```

Triton and other dependencies are installed by `setup.py develop`; see the
upstream docs for details.

## Verify

```bash
# INT8 W8A8 CK GEMM contract + correctness (single GPU)
python3 op_tests/test_gemm_a8w8_int8_gfx908.py

# Custom all-reduce (multi-GPU, run on the 4×MI100 node)
python3 op_tests/multigpu_tests/test_custom_allreduce.py
python3 op_tests/multigpu_tests/test_fused_ar_rms_int8_quant.py
```

End-to-end validation happens in the vLLM fork
([int8-vllm](https://github.com/curvedinf/int8-vllm)): KLD gate boot check plus the
iso-bench protocol (see `GFX908_BUILD_PLAN.md` for the verification order).

## Scope and known limitations

- **Not a general MI100 port.** Only the ops this serving stack calls are
  brought up and verified. Everything else from upstream is present but
  untested on gfx908 and may not compile or run.
- **No fp8.** gfx908 has no fp8 hardware; all fp8 kernels/instances are dead
  code here.
- **CK A8W8 is per-token-scale only** on gfx908 (see above). Blockwise GS128
  requires the new epilogue variants described in the build plan.
- **bf16 serving is out of scope**; the stack serves fp16. The planned CK
  instance filter drops bf16 epilogues accordingly.

## Relationship to upstream

This fork tracks [ROCm/aiter](https://github.com/ROCm/aiter) via merge
commits and intends to stay mergeable: fork changes avoid modifying shared
upstream code paths where possible and gate gfx908 behavior behind arch
checks and env flags. For general aiter documentation — operator catalog,
ecosystem, other architectures — see the
[upstream repository](https://github.com/ROCm/aiter) and
[rocm.github.io/aiter](https://rocm.github.io/aiter).
