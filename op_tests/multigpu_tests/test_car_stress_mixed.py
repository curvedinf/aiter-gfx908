#!/usr/bin/env python3
"""Statistical CAR stress harness: mixed-size eager AR loops on gfx908.

Reproduces the serving pattern that corrupted: large-M "prefill" ARs
(2-stage kernel) interleaved with small-M "decode" ARs (1-stage), many
iterations, every result verified against a gloo fp32 reference. The
missing trailing end_sync on 2-stage let a fast rank's NEXT call clobber
its tmp region while a slow peer still gathered — this harness catches
that as a mismatch, statistically.

Usage:
  HIP_VISIBLE_DEVICES=0,1,2,3 python test_car_stress_mixed.py -n 200
"""

import argparse
import sys
from multiprocessing import Pool, set_start_method

import torch
import torch.distributed as dist

set_start_method("spawn", force=True)

HIDDEN = 5120


def _worker(rank, world_size, port, iters):
    from aiter.dist.parallel_state import (
        ensure_model_parallel_initialized,
        init_distributed_environment,
        set_custom_all_reduce,
    )

    torch.cuda.set_device(rank)
    set_custom_all_reduce(True)
    init_distributed_environment(
        world_size=world_size,
        rank=rank,
        distributed_init_method=f"tcp://127.0.0.1:{port}",
        backend="nccl",
    )
    ensure_model_parallel_initialized(world_size, 1)
    from aiter.dist.communication_op import tensor_model_parallel_all_reduce

    dev = torch.device(f"cuda:{rank}")
    ar = tensor_model_parallel_all_reduce
    # Verify a CAR is actually engaged on the TP device communicator.
    from aiter.dist.parallel_state import get_tp_group

    dc = get_tp_group().device_communicator
    engaged = getattr(dc, "aiter_ar_comm", None) or getattr(dc, "ca_comm", None)
    print(f"rank{rank} AR-comm: {type(engaged).__name__ if engaged else None} disabled={getattr(engaged, 'disabled', 'n/a')}", flush=True)
    torch.manual_seed(1000 + rank)
    import os as _os2
    _MIX = int(_os2.environ["CAR_STRESS_ONLY"]) if _os2.environ.get("CAR_STRESS_ONLY") else None

    # Sizes: 2-stage territory (>=160KB at ws4) and 1-stage, mixed per iter.
    import os as _os
    _only = _os.environ.get("CAR_STRESS_ONLY")
    shapes = [
        (32, HIDDEN),    # prefill-ish: 320KB -> 2-stage
        (64, HIDDEN),    # 640KB -> 2-stage
        (8, HIDDEN),     # decode: 80KB -> 1-stage
        (1, HIDDEN),     # decode
        (128, HIDDEN),   # 1.25MB -> 2-stage
    ]
    if _only is not None:
        shapes = [shapes[int(_only)]]
    _pair = _os.environ.get("CAR_STRESS_PAIR")
    if _pair:
        a, b = (int(x) for x in _pair.split(","))
        shapes = [shapes[a], shapes[b]]
    tensors = [torch.randn(*s, dtype=torch.float16, device=dev) for s in shapes]

    fails = 0
    checks = 0
    # Upstream-style warmup: repeated calls before the verified one.
    for _ in range(20):
        outs = [ar(t) for t in (tensors if _MIX is None else [tensors[0]])]
    torch.cuda.synchronize()
    # Phase 1: pure CAR loop (per-iter verify mode available).
    last = None
    import os as _os3
    _periter = _os3.environ.get("CAR_STRESS_PERITER")
    for it in range(iters):
        outs = [ar(t).clone() for t in (tensors if _MIX is None else [tensors[0]])]
        last = outs if _MIX is None else [outs[0]]*len(tensors)
        if _periter:
            torch.cuda.synchronize()
            for si, t in enumerate(tensors):
                ref = t.clone()
                dist.all_reduce(ref)
                checks += 1
                if not torch.allclose(last[si].float(), ref.float(), atol=0.01, rtol=0.01):
                    fails += 1
                    if fails <= 2:
                        bad = (last[si] != ref).flatten().float()
                        B = 4096
                        nb = bad.numel() // B
                        fr = bad[: nb * B].view(nb, B).mean(1)
                        nz = [i for i, f in enumerate(fr.tolist()) if f > 0.5]
                        print(f"rank{rank} it={it} si={si} badblocks={nz[:6]}/{nb}", flush=True)
                        if it == 0 and si == 0:
                            oc0 = last[si].flatten()[:4].float()
                            rc0 = ref.flatten()[:4].float()
                            tc0 = t.flatten()[:4].float()
                            print(f"rank{rank} VALS out={oc0.tolist()} ref={rc0.tolist()} t={tc0.tolist()} out_ptr={last[si].data_ptr()} ref_ptr={ref.data_ptr()}", flush=True)
                            tb = torch.stack([tensors[0].flatten()[:4], tensors[1].flatten()[:4]]).float().cpu()
                            print(f"TT rank{rank}: a={tb[0].tolist()} b={tb[1].tolist()}", flush=True)
    torch.cuda.synchronize()
    # Phase 2: single verification, once.
    for si, t in enumerate(tensors):
        ref = t.clone()
        dist.all_reduce(ref)
        checks += 1
        oc = last[si].float(); rc = ref.float()
        eq_self = torch.allclose(oc, t.float(), atol=0.01)
        eq_ref = torch.allclose(oc, rc, atol=0.01, rtol=0.01)
        ratio = (oc / rc.clamp(min=1e-3)).mean().item()
        ok = torch.allclose(oc, rc, atol=0.01, rtol=0.01)
        if not ok:
            fails += 1
            bad = (oc != rc).flatten().float()
            B = 4096
            nb = bad.numel() // B
            fracs = bad[:nb*B].view(nb, B).mean(1)
            nz = [(i, f"{f:.2f}") for i, f in enumerate(fracs.tolist()) if f > 0.5]
            print(f"rank{rank} shape={si} badblocks(>0.5): {nz[:8]} total_nz={len(nz)}/{nb}", flush=True)
        if not eq_ref:
            fails += 1

    if dist.is_initialized():
        dist.destroy_process_group()
    return fails, checks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-n", "--iters", type=int, default=200)
    ap.add_argument("--world-size", type=int, default=4)
    ap.add_argument("--port", type=int, default=29760)
    args = ap.parse_args()

    with Pool(processes=args.world_size) as pool:
        rets = [
            pool.apply_async(_worker, (r, args.world_size, args.port, args.iters))
            for r in range(args.world_size)
        ]
        results = [r.get() for r in rets]

    total_f = sum(f for f, _ in results)
    total_c = sum(c for _, c in results)
    for rank, (f, c) in enumerate(results):
        print(f"rank{rank}: {f} fails / {c} checks")
    print("VERDICT:", "CLEAN" if total_f == 0 else f"{total_f} FAILURES / {total_c}")
    sys.exit(0 if total_f == 0 else 1)


if __name__ == "__main__":
    main()
