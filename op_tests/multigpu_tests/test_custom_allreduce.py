# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import os

import torch
import torch.distributed as dist
import argparse
from aiter import dtypes

from aiter.dist.parallel_state import (
    ensure_model_parallel_initialized,
    init_distributed_environment,
    set_custom_all_reduce,
    get_tp_group,
    graph_capture,
    destroy_model_parallel,
    destroy_distributed_environment,
)
from aiter.dist.utils import get_open_port, get_distributed_init_method, get_ip
from aiter.dist.communication_op import tensor_model_parallel_all_reduce
from aiter.test_common import (
    checkAllclose,
    perftest,
    benchmark,
)
from multiprocessing import set_start_method, Pool, freeze_support
import logging

logger = logging.getLogger("aiter")

set_start_method("spawn", force=True)


def allreduce_custom(tp_size, pp_size, rankID, x, withGraph=False):
    device = torch.device(f"cuda:{rankID}")
    torch.cuda.set_device(device)
    # init
    logger.info(f"RANK: {rankID} {tp_size} init_process_group...")
    set_custom_all_reduce(True)
    init_distributed_environment(
        world_size=tp_size,
        rank=rankID,
        distributed_init_method=get_distributed_init_method(get_ip(), get_open_port()),
    )
    ensure_model_parallel_initialized(tp_size, pp_size)
    x = x.to(device)
    # dist.barrier(device_ids=[i for i in range(tp_size)])

    # warmup and align all gpu
    group = get_tp_group().device_group
    dist.all_reduce(torch.zeros(1).cuda(), group=group)
    torch.cuda.synchronize()

    if withGraph:
        graph = torch.cuda.CUDAGraph()
        with graph_capture() as gc:
            with torch.cuda.graph(graph, stream=gc.stream):
                out = tensor_model_parallel_all_reduce(x, block_limit = 2)#, threads=512, block_limit=80)
        out.fill_(0)

        @perftest()
        def run_ca():
            graph.replay()

        _, us = run_ca()
        out = (out, us)
    else:

        @perftest()
        def run_ca(x):
            return tensor_model_parallel_all_reduce(x)

        out = run_ca(x)

    # destroy
    if dist.is_initialized():
        destroy_model_parallel()
        destroy_distributed_environment()
        torch.cuda.empty_cache()
    return out


@benchmark()
def test_allreduce_custom(tp_size, pp_size, shape, dtype, withGraph=False):
    os.environ["MASTER_ADDR"] = "127.0.0.1"
    os.environ["MASTER_PORT"] = "49373"
    pool = Pool(processes=tp_size)
    ref = torch.zeros(shape, dtype=dtype)
    rets = []
    for i in range(tp_size):
        x = torch.randn(shape, dtype=dtype)
        ref += x
        rets.append(
            pool.apply_async(allreduce_custom, args=(tp_size, pp_size, i, x, withGraph))
        )
    pool.close()
    pool.join()
    rets = [el.get() for el in rets]
    for out, us in rets:
        msg = f"test_allreduce_custom: {shape=} {dtype=} {withGraph=} {us:>8.2f}"
        checkAllclose(ref, out.to(ref), msg=msg)


l_dtype = ["bf16"]
l_shape = [
    (32, 8192),
    # (1, 7168), 
    # (2, 7168), 
    # (3, 7168), 
    # (4, 7168), 
    # (5, 7168),
    # (6, 7168),
    # ========= start
    # (7, 7168),
    # (8, 7168), 
    # (9, 7168),
    # (10, 7168),
    # ========= end
    # (11, 7168),
    # (12, 7168),
    # (13, 7168),
    # (14, 7168),
    # (15, 7168),
    # (16, 7168),
    # ========= start
    # (17, 7168),
    # (18, 7168),
    # (19, 7168), (20, 7168),
    # ========= end
    # =========

    # (21, 7168), (22, 7168),
    # (23, 7168), (24, 7168), (25, 7168), (26, 7168), 
    # (27, 7168), (28, 7168), (29, 7168),
    # (30, 7168), (31, 7168), (32, 7168), (33, 7168), (36, 7168), (37, 7168), (39, 7168),
    # (40, 7168), (41, 7168), (42, 7168), (43, 7168), (44, 7168), (45, 7168), (46, 7168),
    # (47, 7168), (48, 7168),
    # (50, 7168), 
    #
    # ========= start
    # (51, 7168), 
    # (52, 7168), (53, 7168), (54, 7168), 
    # ========= end

    # (57, 7168), (58, 7168),
    # (60, 7168), 
    # (61, 7168), (63, 7168), 
    # (64, 7168), 
    # (65, 7168), 
    # (66, 7168), (67, 7168), (68, 7168), 
    # ========= start
    # (69, 7168),
    # (70, 7168), 
    # (71, 7168), 
    # (72, 7168), 
    # ========= end
    # (73, 7168),
    # (74, 7168), (75, 7168), 
    # (76, 7168), 
    # (77, 7168), (78, 7168), (79, 7168),
    # (80, 7168), (81, 7168), (82, 7168),
    # (83, 7168), (84, 7168), (85, 7168), (86, 7168), (87, 7168), (88, 7168), (89, 7168),
    # (90, 7168), 
    # ========= start
    # (93, 7168), (96, 7168), 
    # (128, 7168), (129, 7168),
    # ========= end
    # (192, 7168), 
    # (288, 7168), (384, 7168), (387, 7168),
]

parser = argparse.ArgumentParser(description="config input of test")
parser.add_argument(
    "-d",
    "--dtype",
    type=str,
    choices=l_dtype,
    nargs="?",
    const=None,
    default=None,
    help="data type",
)
parser.add_argument(
    "-s",
    "--shape",
    type=dtypes.str2tuple,
    choices=l_shape,
    nargs="?",
    const=None,
    default=None,
    help="shape",
)


if __name__ == "__main__":
    freeze_support()
    args = parser.parse_args()
    if args.dtype is None:
        l_dtype = [dtypes.d_dtypes[key] for key in l_dtype]
    else:
        l_dtype = [dtypes.d_dtypes[args.dtype]]
    if args.shape is not None:
        l_shape = [args.shape]
    for dtype in l_dtype:
        for shape in l_shape:
            test_allreduce_custom(8, 1, shape, dtype, withGraph=True)
            # test_allreduce_custom(8, 1, shape, dtype, withGraph=False)
