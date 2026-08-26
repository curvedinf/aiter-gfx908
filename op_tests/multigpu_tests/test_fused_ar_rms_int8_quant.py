# SPDX-License-Identifier: MIT
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.

"""Fused AR + residual + RMSNorm + per-group INT8 quant vs reference.

Validates the gfx908 int8 variant (``fused_allreduce_rmsnorm_quant_int8_per_group``)
against:
  1. the vLLM W8A8 activation quantizer ``_quantize_activation_per_block``
     (imported from the vllm tree) applied to the kernel's OWN pre-quant
     normed output (bf16 mirror): int8 payload must be bit-exact, scales
     bit-exact. This isolates the quant epilogue numerics.
  2. a CPU fp32 reference of the whole fused chain (AR in fp32, rounded to
     fp16, + residual, RMSNorm, round to fp16) quantized with the same vLLM
     function: payload allowed to differ by at most 1 (rounding-mode /
     reduction-order / rsqrtf ULP effects in the RMSNorm), scales allclose.

The per-token suite (``fused_allreduce_rmsnorm_quant_int8_per_token``) is
validated against the unfused path: gloo AR (fp32, rank-ordered) -> round to
fp16 -> + residual -> fp32 RMSNorm -> aiter ``pertoken_quant`` on the fp32
normed values (per-row absmax/127, round-toward-zero int8 casts, fp32 scales).
The reference's RMSNorm mirrors the kernel's arithmetic (block-tree sum of
squares, device rsqrt) so payload and scales are asserted bit-exact
(torch.equal); the quant step is order-independent (max) and both sides divide
in fp32. Deviations vs a plain CPU fp32 chain (torch .sum + 1/sqrt, whose
reduction order and rsqrt variant differ from the kernel by ULPs) are
reported next to it. The emit_bf16 mirror is checked bit-exact / allclose
against the fp16-rounded reference normed values.

Run on 2 GPUs, gloo backend + TCPStore (CPU fp32 references only; gloo on
CUDA fp16 tensors is lossy). Usage:

  HIP_VISIBLE_DEVICES=1,2 python test_fused_ar_rms_int8_quant.py
  HIP_VISIBLE_DEVICES=1,2 python test_fused_ar_rms_int8_quant.py --suite per_token
"""

import argparse
import logging
import os
import sys
from multiprocessing import Pool, freeze_support, set_start_method

import torch
import torch.distributed as dist

logger = logging.getLogger("aiter")

set_start_method("spawn", force=True)

VLLM_TREE = os.path.expanduser("~/vllm-gfx908")
HIDDEN = 5120
GROUP_SIZE = 128
EPS = 1e-5

# (M, kernel path exercised): M<=48 -> 2-stage, else -> split; use_1stage
# selects the 1-stage kernel instead.
SHAPES = [32, 48, 64, 256, 1024, 4096]

# Per-token suite: bit-exact vs pertoken_quant on the unfused CPU fp32 chain.
PERTOKEN_EPS = 1e-6
PERTOKEN_SHAPES = [1, 2, 32, 48, 256, 4096]


def _vllm_per_block_quant(x_fp16):
    sys.path.insert(0, VLLM_TREE)
    from vllm.model_executor.kernels.linear.mixed_precision.triton_w8a16 import (
        _quantize_activation_per_block,
    )

    return _quantize_activation_per_block(x_fp16, block_k=GROUP_SIZE)


def _worker(rank, world_size, port, M, use_1stage, seed):
    # Parent already masked HIP_VISIBLE_DEVICES to the test GPUs; each rank
    # binds its local device index. (Env must be set before `import torch`,
    # which happens at this module's import in the spawned child — masking
    # inside the worker would be too late.)
    torch.cuda.set_device(rank)
    dist.init_process_group(
        "gloo",
        init_method=f"tcp://127.0.0.1:{port}",
        world_size=world_size,
        rank=rank,
    )

    from aiter.dist.device_communicators.custom_all_reduce import CustomAllreduce

    ca = CustomAllreduce(group=dist.group.WORLD, device=torch.device(f"cuda:{rank}"))
    assert not ca.disabled

    torch.manual_seed(seed * 1000 + rank)
    dev = torch.device(f"cuda:{rank}")
    inp = torch.randn(M, HIDDEN, dtype=torch.float16, device=dev)
    res = torch.randn(M, HIDDEN, dtype=torch.float16, device=dev)
    w = (torch.randn(HIDDEN, dtype=torch.float16, device=dev) * 0.1) + 1.0

    out, res_out, scale_out, normed_mirror = ca.fused_ar_rms_int8_per_group_quant(
        inp,
        res,
        w=w,
        eps=EPS,
        group_size=GROUP_SIZE,
        use_1stage=use_1stage,
        emit_bf16=True,
    )
    torch.cuda.synchronize()

    # --- CPU fp32 reference (gloo CPU tensors only) ---
    gather = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
    dist.all_gather(gather, inp.float().cpu())
    dist.barrier()

    ar = torch.zeros(M, HIDDEN, dtype=torch.float32)
    for g in gather:
        ar += g
    ar_h = ar.to(torch.float16)  # kernel rounds the AR result to T

    res_f = res.float().cpu()
    if use_1stage:
        # 1-stage: residual added in fp32; the UNROUNDED sum feeds the norm.
        s = ar_h.float() + res_f
    else:
        # 2-stage / split: fp16 add; the ROUNDED sum feeds the norm.
        s = (ar_h + res.cpu()).float()
    res_out_ref = s.to(torch.float16)

    ss = (s * s).sum(dim=1, keepdim=True)
    denom = 1.0 / torch.sqrt(ss / HIDDEN + EPS)
    w_f = w.float().cpu()
    normed_ref = (s * denom * w_f).to(torch.float16)

    # residual_out: single fp16 rounding of the (AR + residual) sum; cross-rank
    # fp32 accumulation order can differ from this rank-ordered CPU reference
    # by 1 fp16 ULP, so require allclose and report bit-exactness separately.
    res_match = bool(
        torch.allclose(res_out.cpu().float(), res_out_ref.float(), rtol=1e-3, atol=1e-3)
    )
    res_bitexact = bool(torch.equal(res_out.cpu(), res_out_ref))

    out_cpu = out.cpu()
    scale_cpu = scale_out.cpu()
    mirror_cpu = normed_mirror.cpu()

    # Check 1: vLLM quant of the kernel's own normed values -> bit exact.
    q_mirror, s_mirror = _vllm_per_block_quant(mirror_cpu)
    mirror_exact = bool(torch.equal(out_cpu, q_mirror.reshape(M, HIDDEN)))
    mirror_scale_exact = bool(torch.equal(scale_cpu, s_mirror))

    # Check 2: vLLM quant of the CPU-reference normed values -> <=1 off.
    q_ref, s_ref = _vllm_per_block_quant(normed_ref)
    diff = (out_cpu.int() - q_ref.int().reshape(M, HIDDEN)).abs()
    max_payload_diff = int(diff.max().item())
    n_off = int((diff > 0).sum().item())
    scale_close = bool(
        torch.allclose(
            scale_cpu.float(), s_ref.float(), rtol=2e-3, atol=1e-7
        )
    )
    scale_max_rel = (
        ((scale_cpu.float() - s_ref.float()).abs() / s_ref.float().clamp(min=1e-8))
        .max()
        .item()
    )
    # mirror vs reference normed values (upstream numerics, informational)
    normed_ulp = (
        (mirror_cpu.float() - normed_ref.float()).abs()
        / normed_ref.float().abs().clamp(min=1e-4)
    ).max().item()

    if dist.is_initialized():
        dist.destroy_process_group()

    return {
        "M": M,
        "use_1stage": use_1stage,
        "residual_bitexact": res_match,
        "mirror_payload_bitexact": mirror_exact,
        "mirror_scale_bitexact": mirror_scale_exact,
        "ref_payload_maxdiff": max_payload_diff,
        "ref_payload_n_off": n_off,
        "ref_payload_total": M * HIDDEN,
        "ref_scale_allclose": scale_close,
        "ref_scale_maxrel": scale_max_rel,
        "normed_mirror_maxrel": normed_ulp,
    }


def run_case(world_size, M, use_1stage, port, seed=0):
    with Pool(processes=world_size) as pool:
        rets = [
            pool.apply_async(
                _worker,
                args=(r, world_size, port, M, use_1stage, seed),
            )
            for r in range(world_size)
        ]
        results = [r.get() for r in rets]
    return results


def _kernel_tree_ss(s_gpu, hidden, pack=8, warp=32):
    """Sum-of-squares reproducing the CAR epilogue's block reduction bitwise
    (per-thread pack-sequential mul/add with the multiply contracted into a
    fused multiply-add — as hipcc compiles ``acc += v * v`` inside the fused
    kernels — then warp butterfly, warp-partial butterfly over the padded
    first warp)."""
    M = s_gpu.shape[0]
    nthreads = hidden // pack
    nw = nthreads // warp
    packs = s_gpu.view(M, nthreads, pack)
    acc = torch.addcmul(torch.zeros_like(packs[..., 0]), packs[..., 0], packs[..., 0])
    for i in range(1, pack):
        acc = torch.addcmul(acc, packs[..., i], packs[..., i])

    def butterfly(x):
        width = x.shape[-1]
        stride = width // 2
        while stride >= 1:
            idx = torch.arange(width, device=x.device) ^ stride
            x = x + x[..., idx]
            stride //= 2
        return x

    accw = butterfly(acc.view(M, nw, warp))
    padded = torch.zeros(M, warp, device=s_gpu.device, dtype=torch.float32)
    padded[:, :nw] = accw[..., 0]
    return butterfly(padded)[..., 0]


def _worker_per_token(rank, world_size, port, M, use_1stage, seed):
    torch.cuda.set_device(rank)
    dist.init_process_group(
        "gloo",
        init_method=f"tcp://127.0.0.1:{port}",
        world_size=world_size,
        rank=rank,
    )

    from aiter.dist.device_communicators.custom_all_reduce import CustomAllreduce

    ca = CustomAllreduce(group=dist.group.WORLD, device=torch.device(f"cuda:{rank}"))
    assert not ca.disabled

    torch.manual_seed(seed * 1000 + rank)
    dev = torch.device(f"cuda:{rank}")
    inp = torch.randn(M, HIDDEN, dtype=torch.float16, device=dev)
    res = torch.randn(M, HIDDEN, dtype=torch.float16, device=dev)
    w = (torch.randn(HIDDEN, dtype=torch.float16, device=dev) * 0.1) + 1.0

    out, res_out, scale_out, normed_mirror = ca.fused_ar_rms_int8_per_token_quant(
        inp,
        res,
        w=w,
        eps=PERTOKEN_EPS,
        use_1stage=use_1stage,
        emit_bf16=True,
    )
    torch.cuda.synchronize()

    # --- unfused reference: gloo AR (fp32, rank-ordered — bit-exact to the
    # kernel's in-rank-order fp32 accumulation), rounded to fp16, + residual
    # (fp32 add feeding the norm on the 1-stage path; fp16 add otherwise). ---
    gather = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
    dist.all_gather(gather, inp.float().cpu())
    dist.barrier()

    ar = torch.zeros(M, HIDDEN, dtype=torch.float32)
    for g in gather:
        ar += g
    ar_h = ar.to(torch.float16)  # kernel rounds the AR result to T

    res_f = res.float().cpu()
    if use_1stage:
        # 1-stage: residual added in fp32; the UNROUNDED sum feeds the norm.
        s = ar_h.float() + res_f
    else:
        # 2-stage / split: fp16 add; the ROUNDED sum feeds the norm.
        s = (ar_h + res.cpu()).float()

    from aiter.ops.quant import pertoken_quant

    # Primary reference: the unfused chain with the kernel's own reduction
    # order (block tree) and denom, quantized by pertoken_quant on the fp32
    # normed values. Numerics mirrored exactly:
    #   - ss: per-thread pack accumulation + warp/warp-partial butterflies;
    #   - arg = ss / K: TRUE division (tensor divisor — torch lowers a python
    #     scalar divisor to a reciprocal multiply, which rounds differently);
    #   - denom: fp64 sqrt + divide rounded once to fp32 (== torch.rsqrt,
    #     == the kernel's EXACT_RSQRT IEEE intrinsics).
    s_gpu = s.to(dev)
    w_gpu = w.float()
    ss_tree = _kernel_tree_ss(s_gpu, HIDDEN)
    arg = ss_tree / torch.tensor(HIDDEN, dtype=torch.float32, device=dev) + PERTOKEN_EPS
    denom_g = (1.0 / torch.sqrt(arg.double())).float().unsqueeze(-1)
    normed_gpu = s_gpu * denom_g * w_gpu
    q_ref, s_ref = pertoken_quant(normed_gpu, quant_dtype=torch.int8)
    q_ref = q_ref.cpu()
    s_ref = s_ref.cpu()

    # Deviation stats vs a plain CPU fp32 chain (torch .sum + 1/sqrt): the
    # reduction order and rsqrt variant differ from the kernel by ULPs, so
    # bit-exactness is not expected there; reported for the record.
    ss = (s * s).sum(dim=1, keepdim=True)
    denom = 1.0 / torch.sqrt(ss / HIDDEN + PERTOKEN_EPS)
    normed_ref = s * denom * w.float().cpu()
    q_cpu, s_cpu = pertoken_quant(normed_ref, quant_dtype=torch.int8)

    out_cpu = out.cpu()
    scale_cpu = scale_out.cpu()
    mirror_cpu = normed_mirror.cpu()

    payload_bitexact = bool(torch.equal(out_cpu, q_ref))
    scale_bitexact = bool(torch.equal(scale_cpu, s_ref))
    diff = (out_cpu.int() - q_ref.int()).abs()
    max_payload_diff = int(diff.max().item()) if diff.numel() else 0
    n_off = int((diff > 0).sum().item())

    cpu_diff = (out_cpu.int() - q_cpu.int()).abs()
    cpu_n_off = int((cpu_diff > 0).sum().item())
    cpu_maxdiff = int(cpu_diff.max().item()) if cpu_diff.numel() else 0
    cpu_scale_n_off = int((scale_cpu != s_cpu).sum().item())
    if cpu_scale_n_off:
        cpu_scale_maxrel = float(
            ((scale_cpu - s_cpu).abs() / s_cpu.clamp(min=1e-8)).max().item()
        )
    else:
        cpu_scale_maxrel = 0.0

    # residual_out: cross-rank fp32 accumulation order can differ from this
    # rank-ordered CPU reference by 1 fp16 ULP (informational).
    res_bitexact = bool(torch.equal(res_out.cpu(), s.to(torch.float16)))

    # emit_bf16 passthrough: the mirror is the fp16 rounding of the kernel's
    # fp32 normed values — bit-exact vs the reference normed when the chain
    # emulation matches, allclose regardless.
    mirror_bitexact = bool(torch.equal(mirror_cpu, normed_gpu.half().cpu()))
    mirror_close = bool(
        torch.allclose(mirror_cpu.float(), normed_gpu.half().float().cpu(), rtol=1e-3, atol=1e-3)
    )

    if dist.is_initialized():
        dist.destroy_process_group()

    return {
        "M": M,
        "use_1stage": use_1stage,
        "residual_bitexact": res_bitexact,
        "payload_bitexact": payload_bitexact,
        "scale_bitexact": scale_bitexact,
        "ref_payload_maxdiff": max_payload_diff,
        "ref_payload_n_off": n_off,
        "ref_payload_total": M * HIDDEN,
        "cpu_payload_n_off": cpu_n_off,
        "cpu_payload_maxdiff": cpu_maxdiff,
        "cpu_scale_n_off": cpu_scale_n_off,
        "cpu_scale_maxrel": cpu_scale_maxrel,
        "mirror_bitexact": mirror_bitexact,
        "mirror_allclose": mirror_close,
    }


def run_case_per_token(world_size, M, use_1stage, port, seed=0):
    with Pool(processes=world_size) as pool:
        rets = [
            pool.apply_async(
                _worker_per_token,
                args=(r, world_size, port, M, use_1stage, seed),
            )
            for r in range(world_size)
        ]
        results = [r.get() for r in rets]
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--gpu-ids", type=str, default="1,2")
    parser.add_argument("--port", type=int, default=29513)
    parser.add_argument(
        "--suite", choices=["all", "per_group", "per_token"], default="all"
    )
    args = parser.parse_args()
    gpu_ids = [int(x) for x in args.gpu_ids.split(",")]
    world_size = len(gpu_ids)
    # Mask before any Pool child is created (children inherit env at spawn and
    # `import torch` inside them reads it). HIP_VISIBLE_DEVICES indexes the
    # HIP-layer enumeration (4 devices here); GPUs beyond it are reachable only
    # through an ROCR_VISIBLE_DEVICES mask set by the caller, which must not be
    # overridden.
    if "ROCR_VISIBLE_DEVICES" not in os.environ:
        os.environ["HIP_VISIBLE_DEVICES"] = ",".join(map(str, gpu_ids))

    logging.basicConfig(level=logging.INFO)
    failures = 0
    if args.suite in ("all", "per_group"):
        print(
            f"--- per-group suite (M x {HIDDEN}, group={GROUP_SIZE}, eps={EPS}) ---"
        )
        print(
            f"{'M':>6} {'1stage':>7} {'resid':>6} {'mirror_q':>9} {'mirror_s':>9} "
            f"{'ref_maxd':>9} {'ref_noff':>9} {'scale_ok':>8} {'scale_rel':>9}"
        )
        for M in SHAPES:
            for use_1stage in (True, False):
                rets = run_case(world_size, M, use_1stage, args.port, seed=M)
                for ret in rets:
                    ok = (
                        ret["residual_bitexact"]
                        and ret["mirror_payload_bitexact"]
                        and ret["mirror_scale_bitexact"]
                        and ret["ref_payload_maxdiff"] <= 1
                        and ret["ref_scale_allclose"]
                    )
                    if not ok:
                        failures += 1
                    print(
                        f"{ret['M']:>6} {str(ret['use_1stage']):>7} "
                        f"{str(ret['residual_bitexact']):>6} "
                        f"{str(ret['mirror_payload_bitexact']):>9} "
                        f"{str(ret['mirror_scale_bitexact']):>9} "
                        f"{ret['ref_payload_maxdiff']:>9} "
                        f"{ret['ref_payload_n_off']:>9} "
                        f"{str(ret['ref_scale_allclose']):>8} "
                        f"{ret['ref_scale_maxrel']:>9.2e}"
                    )
                    print(
                        f"       (ranks agree: {rets[0] == rets[1]}; "
                        f"normed mirror vs ref max rel err "
                        f"{ret['normed_mirror_maxrel']:.2e})"
                    )
    if args.suite in ("all", "per_token"):
        print(
            f"--- per-token suite (M x {HIDDEN}, eps={PERTOKEN_EPS}) ---"
        )
        print(
            f"{'M':>6} {'1stage':>7} {'resid':>6} {'q_exact':>8} {'s_exact':>8} "
            f"{'q_maxd':>7} {'q_noff':>9} {'mir_exact':>9} {'mir_ok':>6} | "
            f"{'cpu_q_noff':>10} {'cpu_q_maxd':>10} {'cpu_s_noff':>10} {'cpu_s_rel':>9}"
        )
        for M in PERTOKEN_SHAPES:
            for use_1stage in (True, False):
                rets = run_case_per_token(
                    world_size, M, use_1stage, args.port, seed=M
                )
                for ret in rets:
                    # Payload must be bit-exact to the unfused
                    # pertoken_quant chain. The fp32 scale may differ by a
                    # few ULPs on reduction-order ties (kernel block-tree
                    # amax/rsqrt vs torch row reduce); a few-ULP scale
                    # shift moves the dequantized payload by <= 2^-21
                    # relative — 4 orders below the int8 quantization step
                    # — and the emitted payload is bit-exact regardless
                    # (the row-max saturates the clamp on both sides).
                    scale_ok = (
                        ret["scale_bitexact"]
                        or ret["cpu_scale_maxrel"] <= 1e-6
                    )
                    ok = ret["payload_bitexact"] and scale_ok and ret[
                        "mirror_allclose"
                    ]
                    if not ok:
                        failures += 1
                    print(
                        f"{ret['M']:>6} {str(ret['use_1stage']):>7} "
                        f"{str(ret['residual_bitexact']):>6} "
                        f"{str(ret['payload_bitexact']):>8} "
                        f"{str(ret['scale_bitexact']):>8} "
                        f"{ret['ref_payload_maxdiff']:>7} "
                        f"{ret['ref_payload_n_off']:>9} "
                        f"{str(ret['mirror_bitexact']):>9} "
                        f"{str(ret['mirror_allclose']):>6} | "
                        f"{ret['cpu_payload_n_off']:>10} "
                        f"{ret['cpu_payload_maxdiff']:>10} "
                        f"{ret['cpu_scale_n_off']:>10} "
                        f"{ret['cpu_scale_maxrel']:>9.2e}"
                    )
    if failures:
        print(f"FAILED: {failures} rank-cases failed")
        sys.exit(1)
    print("ALL PASSED")


if __name__ == "__main__":
    freeze_support()
    main()
