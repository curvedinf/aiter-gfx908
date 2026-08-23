#!/usr/bin/env python3
"""Minimal: does an unrelated CUDA-graph capture break hipIpc peer reads?

2 ranks. Rank0 allocates a torch tensor, exports handle via the aiter ops,
rank1 opens it and reads eagerly. Then rank1 captures a trivial graph
(no CAR involved), and reads again. Isolates the runtime mechanism from
the CAR kernel entirely.

Run: HIP_VISIBLE_DEVICES=0,1 python test_ipc_graph_poison.py
"""

import ctypes
import sys
from multiprocessing import Pool, set_start_method

import torch
import torch.distributed as dist

set_start_method("spawn", force=True)


def _worker(rank, world_size, port):
    torch.cuda.set_device(rank)
    dist.init_process_group(
        "gloo", init_method=f"tcp://127.0.0.1:{port}", world_size=world_size, rank=rank
    )
    from aiter.ops import custom_all_reduce as car_ops

    dev = torch.device(f"cuda:{rank}")
    N = 512
    lib = ctypes.CDLL("libamdhip64.so")

    if rank == 0:
        t = torch.full((N,), 1.0, dtype=torch.float16, device=dev)
        handle = torch.empty(64, dtype=torch.uint8)
        ret = lib.hipIpcGetMemHandle(
            ctypes.c_void_p(handle.data_ptr()),
            ctypes.c_void_p(t.data_ptr()),
        )
        assert ret == 0, f"hipIpcGetMemHandle failed: {ret}"
        dist.broadcast(handle, 0)
        # mirror rank1's barrier sequence exactly: phases share one barrier
        # each; rank0 updates the value before the phase barrier.
        for phase in range(4):
            t.fill_(float(10 + phase))
            dist.barrier()
    else:
        handle = torch.empty(64, dtype=torch.uint8)
        dist.broadcast(handle, 0)
        lib = ctypes.CDLL("libamdhip64.so")
        peer_ptr = ctypes.c_void_p()
        ret = lib.hipIpcOpenMemHandle(
            ctypes.byref(peer_ptr),
            ctypes.c_void_p(handle.data_ptr()),
            1,  # hipIpcMemLazyEnablePeerAccess
        )
        assert ret == 0, f"hipIpcOpenMemHandle failed: {ret}"

        def read_peer(tag):
            host = (ctypes.c_uint16 * N)()
            lib.hipMemcpy(
                host, peer_ptr, ctypes.c_size_t(N * 2), 2  # D2H
            )
            vals = list(host)[:8]
            print(f"rank1 {tag}: peer[0:8] = {vals}", flush=True)
            return vals

        dist.barrier()
        read_peer("phase0:eager")

        # unrelated graph capture on rank1
        x = torch.ones(64, device=dev)
        g = torch.cuda.CUDAGraph()
        s = torch.cuda.Stream()
        s.wait_stream(torch.cuda.current_stream())
        with torch.cuda.stream(s):
            y = x * 2
        torch.cuda.current_stream().wait_stream(s)
        with torch.cuda.graph(g):
            y = x * 2
        torch.cuda.synchronize()
        dist.barrier()
        read_peer("phase1:post-capture(no-replay)")
        g.replay()
        torch.cuda.synchronize()
        dist.barrier()
        read_peer("phase2:post-replay")
        dist.barrier()
        read_peer("phase3:again")
        dist.barrier()

    if dist.is_initialized():
        dist.destroy_process_group()
    return None


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 29730
    with Pool(processes=2) as pool:
        rets = [pool.apply_async(_worker, args=(r, 2, port)) for r in range(2)]
        [r.get() for r in rets]


if __name__ == "__main__":
    main()
