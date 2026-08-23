#!/usr/bin/env python3
"""Repro: aiter plain custom AR under CUDA-graph registered mode on gfx908.

Serving-shaped corruption probe. The eager path is bit-exact (existing tests);
serving corrupts. The one path serving exercises that tests don't is the
CUDA-graph registered-buffer mode: capture calls all_reduce(registered_input=
enable_register_for_capturing) and afterwards flush_graph_buffers registers the
graph's input/output addresses IPC-wide.

This harness reproduces that exactly:
  1. build CustomAllreduce over N GPUs (gloo world, like the other tests)
  2. allocate fresh input/output tensors
  3. with ca.capture(): graph-capture (stream capture + replay warmup) of
     ca.custom_all_reduce(inp)
  4. ca.register_graph_buffers()
  5. write NEW values into the same tensors, replay, compare vs gloo CPU fp32
  6. repeat replays with fresh values to catch cross-replay smearing

Run: HIP_VISIBLE_DEVICES=0,1,2,3 python test_car_graph_repro.py
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

HIDDEN = 5120
MS = [int(x) for x in __import__('os').environ.get('CAR_MS','1,8,32,80').split(',')]          # decode sizes (1-stage window) and beyond
N_REPLAYS = 8


def _worker(rank, world_size, port, copy_in=False, pre_register=False, naive=False):
    torch.cuda.set_device(rank)
    dist.init_process_group(
        "gloo",
        init_method=f"tcp://127.0.0.1:{port}",
        world_size=world_size,
        rank=rank,
    )
    from aiter.dist.device_communicators.custom_all_reduce import CustomAllreduce

    dev = torch.device(f"cuda:{rank}")
    ca = CustomAllreduce(
        group=dist.group.WORLD,
        device=dev,
        enable_register_for_capturing=not copy_in,
    )
    assert not ca.disabled, f"rank {rank}: custom AR disabled?"

    results = []
    for M in MS:
        shape = (M, HIDDEN)
        nbytes = M * HIDDEN * 2
        if not ca.should_custom_ar_bytes(torch.empty(shape, dtype=torch.float16, device=dev)):
            results.append({"M": M, "skip": True})
            continue

        torch.manual_seed(1234 + rank)
        inp = torch.randn(*shape, dtype=torch.float16, device=dev)

        # Warmup run (eager) so the launcher's first-call JIT/alloc happens
        # outside capture.
        out0 = ca.custom_all_reduce(inp)
        torch.cuda.synchronize()
        assert out0 is not None
        # eager correctness gate for THIS shape, before any capture:
        gather0 = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
        dist.all_gather(gather0, inp.float().cpu())
        ref0 = (sum(t for t in gather0)).to(torch.float16)
        eager0_ok = bool(torch.equal(out0.cpu(), ref0))
        if not eager0_ok:
            results.append({"M": M, "eager_pre_capture_ok": False,
                            "note": "shape already broken WITHOUT any capture"})
            continue

        # Capture: mimic vLLM's graph capture path.
        # IMPORTANT: the CAR flag protocol is a collective — every rank must
        # issue the SAME number of kernel calls in lockstep. Warmup iterations
        # are barrier-synced across ranks (vLLM workers capture together).
        g = torch.cuda.CUDAGraph()
        s = torch.cuda.Stream()
        s.wait_stream(torch.cuda.current_stream())
        with torch.cuda.stream(s):
            for _ in range(3):  # capture warmup iterations (mimic allocation)
                out = ca.custom_all_reduce(inp)
                torch.cuda.synchronize()
                dist.barrier()
        torch.cuda.current_stream().wait_stream(s)

        try:
            if pre_register:
                # Eagerly exchange IPC handles for the graph tensors BEFORE
                # capture, bypassing the RANGE_START_ADDR graph-meta batch.
                out = torch.empty_like(inp)
                ca.register_input_buffer(inp)
                ca.register_output_buffer(out)
                dist.barrier()
                # Eager call through the SAME registered pointers: validates
                # the registration itself, independent of graph capture.
                eg = ca.all_reduce(inp, out=out, registered_input=True)
                torch.cuda.synchronize()
                gather_e = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
                dist.all_gather(gather_e, inp.float().cpu())
                ref_e = (sum(t for t in gather_e)).to(torch.float16)
                eager_reg_ok = bool(torch.equal(eg.cpu(), ref_e))
                results.append({"M": M, "eager_registered_ok": eager_reg_ok})
                if not eager_reg_ok:
                    continue
            with ca.capture():
                with torch.cuda.graph(g):
                    out = ca.custom_all_reduce(inp, use_new=not naive)
        except Exception as e:
            results.append({"M": M, "capture_error": repr(e)})
            continue

        ca.register_graph_buffers()
        torch.cuda.synchronize()

        # Replay with fresh values in the SAME tensors and verify each replay.
        for it in range(N_REPLAYS):
            new = torch.randn(*shape, dtype=torch.float16, device=dev)
            if it == 0 and rank == 1:
                # probe: rank1 writes a distinctive constant so we can tell
                # "read stale/zero" (0-ish) from "read correct value" (100)
                new.fill_(100.0)
            inp.copy_(new)
            if it == 0:
                # capture-only probe: does eager still work BEFORE any replay?
                pre = ca.custom_all_reduce(inp)
                torch.cuda.synchronize()
                gather_p = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
                dist.all_gather(gather_p, inp.float().cpu())
                refp = (sum(t for t in gather_p)).to(torch.float16)
                results.append({"M": M, "eager_after_capture_before_replay_ok": bool(torch.equal(pre.cpu(), refp))})
            g.replay()
            torch.cuda.synchronize()

            # gloo CPU fp32 reference
            gather = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
            dist.all_gather(gather, inp.float().cpu())
            ref = torch.zeros(M, HIDDEN, dtype=torch.float32)
            for t in gather:
                ref += t
            ref_h = ref.to(torch.float16)

            got = out.cpu()
            ok = bool(torch.equal(got, ref_h))
            maxerr = float((got.float() - ref_h.float()).abs().max().item())
            if not ok:
                # Flag-state dump via ctypes hipMemcpy from the raw meta ptr.
                import ctypes

                lib = ctypes.CDLL("libamdhip64.so")
                words = 2 * 80 * 8 + 80  # start[80][8] + end[80][8] + _flag[80]
                host = (ctypes.c_uint32 * words)()
                lib.hipMemcpy(
                    host,
                    ctypes.c_void_p(ca._pool["meta"].data_ptr),
                    ctypes.c_size_t(words * 4),
                    2,  # hipMemcpyDeviceToHost
                )
                arr = list(host)
                start0 = arr[0:8]          # block0 start flags [peer]
                end0 = arr[80 * 8 : 80 * 8 + 8]  # block0 end flags
                flag0 = arr[2 * 80 * 8]    # block0 _flag
                results[-1].update(
                    {
                        "sig_start_b0": start0,
                        "sig_end_b0": end0,
                        "sig_flag_b0": flag0,
                    }
                ) if len(results) and isinstance(results[-1], dict) else results.append(
                    {"sig_start_b0": start0, "sig_end_b0": end0, "sig_flag_b0": flag0}
                )
                # Fingerprint the corruption mode: least-squares weight of
                # each rank's contribution actually present in the output
                # (1.0 = present, 0.0 = missing), plus stale-output check.
                contribs = torch.stack(gather).reshape(world_size, -1).t()
                b = got.float().reshape(-1).unsqueeze(1)
                alphas = torch.linalg.lstsq(contribs, b).solution.reshape(-1)
                alpha_str = ",".join(f"{a:.2f}" for a in alphas.tolist())
                stale = bool(torch.equal(got, out0.cpu()))
                results.append(
                    {
                        "M": M,
                        "replay": it,
                        "bitexact": ok,
                        "maxerr": maxerr,
                        "n_mismatch": int((got != ref_h).sum().item()),
                        "contrib_alphas": alpha_str,
                        "equals_eager_out": stale,
                    }
                )
                # eager-after-capture discriminator: same process, same tensors
                eager_out = ca.custom_all_reduce(inp)
                torch.cuda.synchronize()
                eg = eager_out.cpu()
                eager_ok = bool(torch.equal(eg, ref_h))
                results[-1]["eager_after_capture_ok"] = eager_ok

                # fresh-registration probe: does IPC still work for NEW
                # mappings created AFTER the graph capture/replay?
                inp2 = torch.randn(*shape, dtype=torch.float16, device=dev)
                out2 = torch.empty_like(inp2)
                ca.register_input_buffer(inp2)
                ca.register_output_buffer(out2)
                dist.barrier()
                eg2 = ca.all_reduce(inp2, out=out2, registered_input=True)
                torch.cuda.synchronize()
                gather2 = [torch.empty(M, HIDDEN, dtype=torch.float32) for _ in range(world_size)]
                dist.all_gather(gather2, inp2.float().cpu())
                ref2 = (sum(t for t in gather2)).to(torch.float16)
                results[-1]["fresh_registration_after_capture_ok"] = bool(
                    torch.equal(eg2.cpu(), ref2)
                )
                break
        else:
            results.append({"M": M, "replays": N_REPLAYS, "bitexact": True, "maxerr": 0.0})

    if dist.is_initialized():
        dist.destroy_process_group()
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--world-size", type=int, default=4)
    ap.add_argument("--port", type=int, default=29711)
    ap.add_argument("--copy-in", action="store_true",
                    help="force copy-in capture path (enable_register_for_capturing=False)")
    ap.add_argument("--pre-register", action="store_true",
                    help="eagerly IPC-register graph tensors before capture")
    ap.add_argument("--naive", action="store_true",
                    help="capture with use_new=False (vLLM-style naive kernels)")
    args = ap.parse_args()

    with Pool(processes=args.world_size) as pool:
        rets = [
            pool.apply_async(
                _worker, args=(r, args.world_size, args.port, args.copy_in, args.pre_register, args.naive)
            )
            for r in range(args.world_size)
        ]
        results = [r.get() for r in rets]

    any_fail = False
    for rank, rr in enumerate(results):
        for row in rr:
            tag = "SKIP" if row.get("skip") else ("FAIL" if not row.get("bitexact", False) else "PASS")
            if tag == "FAIL":
                any_fail = True
            print(f"rank{rank} M={row['M']:>5} {tag} {row}", flush=True)

    print("\nVERDICT:", "CORRUPTION REPRODUCED" if any_fail else "all clean")
    sys.exit(1 if any_fail else 0)


if __name__ == "__main__":
    freeze_support()
    main()
