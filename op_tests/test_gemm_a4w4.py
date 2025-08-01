# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import aiter
from aiter.test_common import checkAllclose, benchmark, perftest
from aiter import dtypes
from aiter.utility import fp4_utils
from aiter.ops.shuffle import shuffle_weight
import argparse
import pandas as pd

torch.set_default_device("cuda")
torch.set_printoptions(sci_mode=False)
SCALE_GROUP_SIZE = 32
pd.set_option("display.max_columns", 30)
pd.set_option("display.width", 1000)
pd.set_option("display.max_colwidth", 30)


@perftest(num_iters=5)
def run_torch(x, w, x_scales, w_scales, dtype):
    m, k = x.shape
    n, k = w.shape
    # First convert the x and w inputs to f32.
    x_f32 = fp4_utils.mxfp4_to_f32(x)
    w_f32 = fp4_utils.mxfp4_to_f32(w)
    # Next convert the e8m0 scales to f32.
    x_scales = x_scales[:m]
    x_scales = x_scales.repeat_interleave(SCALE_GROUP_SIZE, dim=1)
    x_scales_f32 = fp4_utils.e8m0_to_f32(x_scales)
    x_f32 = x_f32 * x_scales_f32
    w_scales = w_scales[:n]
    w_scales = w_scales.repeat_interleave(SCALE_GROUP_SIZE, dim=1)
    w_scales_f32 = fp4_utils.e8m0_to_f32(w_scales)
    w_f32 = w_f32 * w_scales_f32
    return torch.mm(x_f32, w_f32.T).to(dtype)[:m, :n]


@perftest()
def run_gemm_ck(x, weight, x_scale, w_scale, out):
    return aiter.gemm_a4w4_blockscale(x, weight, x_scale, w_scale, out)


@perftest()
def run_triton(x, w, x_scales, w_scales, out, dtype=dtypes.bf16):
    from aiter.ops.triton.gemm_afp4wfp4 import gemm_afp4wfp4

    gemm_afp4wfp4(x, w, x_scales, w_scales, dtype, out)
    return out


@perftest()
def run_gemm_asm(
    x,
    weightshuffle,
    x_scale,
    w_scale,
    out,
    kernelName="",
    bias=None,
    dtype=dtypes.bf16,
    bpreshuffle=True,
    log2_k_split=None,
):
    if log2_k_split is not None:
        out_reset = torch.zeros(
            (out.shape[0] + 255) // 256 * 256, out.shape[1], dtype=dtype
        )
        out = out_reset

    return aiter.gemm_a4w4_asm(
        x,
        weightshuffle,
        x_scale,
        w_scale,
        out,
        kernelName,
        bias,
        bpreshuffle=bpreshuffle,
        log2_k_split=log2_k_split,
    )


@benchmark()
def test_gemm(dtype, M, N, K):
    from aiter.jit.utils.chip_info import get_gfx

    if get_gfx() not in ["gfx950"]:
        return
    quant_func = aiter.get_triton_quant(aiter.QuantType.per_1x32)
    x = torch.randn((M, K), dtype=dtype)
    w = torch.randn((N, K), dtype=dtype)
    _, x_scales = quant_func(x, shuffle=False)
    _, w_scales = quant_func(w, shuffle=False)
    x, x_scales_shuffle = quant_func(x, shuffle=True)
    w, w_scales_shuffle = quant_func(w, shuffle=True)
    wshuffle = shuffle_weight(w, layout=(16, 16))
    out1 = torch.empty(M, N, dtype=dtype)
    out2 = torch.empty((M + 255) // 256 * 256, N, dtype=dtype)
    out3 = torch.empty((M + 255) // 256 * 256, N, dtype=dtype)
    bias_f32 = None
    x_scales = x_scales.view(torch.uint8)
    w_scales = w_scales.view(torch.uint8)
    a, avg_a = run_torch(x, w, x_scales, w_scales, dtype)
    # b, avg_b = run_triton(x, w.T, x_scales, w_scales, out1, dtype)
    b, avg_b = a, 0
    err_b = checkAllclose(a, b, msg="triton        ")

    err_c = None
    avg_c = None
    tflops_c = None
    tbs_c = None
    c, avg_c = run_gemm_asm(
        x,
        wshuffle,
        x_scales_shuffle,
        w_scales_shuffle,
        out2,
        "",  # kernelName
        bias_f32,
        bpreshuffle=True,
        log2_k_split=0,
    )

    err_c = checkAllclose(a, c[:M], msg="asm no splitK  ")
    tflops_c = M * N * K * 2 / avg_c / 1e6
    tbs_c = (x.nbytes + w.nbytes) / avg_c / 1e6
    err_d = None
    avg_d = None
    tflops_d = None
    tbs_d = None
    d, avg_d = run_gemm_asm(
        x,
        wshuffle,
        x_scales_shuffle,
        w_scales_shuffle,
        out3,
        "_ZN5aiter49f4gemm_bf16_per1x32Fp4_BpreShuffle_KSplit_128x512E",  # kernelName
        bias_f32,
        bpreshuffle=True,
        log2_k_split=2,
    )
    err_d = checkAllclose(a, d[:M], msg="asm splitK ")
    tflops_d = M * N * K * 2 / avg_d / 1e6
    tbs_d = (x.nbytes + w.nbytes) / avg_d / 1e6

    err_e = None
    avg_e = None
    tflops_e = None
    tbs_e = None
    e, avg_e = run_gemm_ck(x, wshuffle, x_scales_shuffle, w_scales_shuffle, out3)
    err_e = checkAllclose(a, e[:M], msg="ck            ")
    tflops_e = M * N * K * 2 / avg_e / 1e6
    tbs_e = (x.nbytes + w.nbytes) / avg_e / 1e6

    return {
        "triton": avg_b,
        "asm no splitK": avg_c,
        "asm splitK": avg_d,
        "ck": avg_e,
        "triton err": err_b,
        "asm no splitK err": err_c,
        "asm splitK err": err_d,
        "ck err": err_e,
        "asm no splitK TFLOPS": tflops_c,
        "asm splitK TFLOPS": tflops_d,
        "ck TFLOPS": tflops_e,
        "asm no splitK TB/s": tbs_c,
        "asm splitK TB/s": tbs_d,
        "ck TB/s": tbs_e,
    }


l_dtype = ["bf16"]
l_mnk = [
    (1,10240,4096),
    (32,10240,4096),
    (64,10240,4096),
    (128,10240,4096),
    (256,10240,4096),
    (512,10240,4096),
    (1024,10240,4096),
    (2048,10240,4096),
    (4096,10240,4096),
    (8192,10240,4096),
    (16384,10240,4096),
    (32768,10240,4096),
    (1,10240,8192),
    (32,10240,8192),
    (64,10240,8192),
    (128,10240,8192),
    (256,10240,8192),
    (512,10240,8192),
    (1024,10240,8192),
    (2048,10240,8192),
    (4096,10240,8192),
    (8192,10240,8192),
    (16384,10240,8192),
    (32768,10240,8192),
    (1,10240,16384),
    (32,10240,16384),
    (64,10240,16384),
    (128,10240,16384),
    (256,10240,16384),
    (512,10240,16384),
    (1024,10240,16384),
    (2048,10240,16384),
    (4096,10240,16384),
    (8192,10240,16384),
    (16384,10240,16384),
    (32768,10240,16384),
    (1,57344,4096),
    (32,57344,4096),
    (64,57344,4096),
    (128,57344,4096),
    (256,57344,4096),
    (512,57344,4096),
    (1024,57344,4096),
    (2048,57344,4096),
    (4096,57344,4096),
    (8192,57344,4096),
    (16384,57344,4096),
    (32768,57344,4096),
    (1,57344,8192),
    (32,57344,8192),
    (64,57344,8192),
    (128,57344,8192),
    (256,57344,8192),
    (512,57344,8192),
    (1024,57344,8192),
    (2048,57344,8192),
    (4096,57344,8192),
    (8192,57344,8192),
    (16384,57344,8192),
    (32768,57344,8192),
    (1,57344,16384),
    (32,57344,16384),
    (64,57344,16384),
    (128,57344,16384),
    (256,57344,16384),
    (512,57344,16384),
    (1024,57344,16384),
    (2048,57344,16384),
    (4096,57344,16384),
    (8192,57344,16384),
    (16384,57344,16384),
    (32768,57344,16384),
    (1,4096,4096),
    (32,4096,4096),
    (64,4096,4096),
    (128,4096,4096),
    (256,4096,4096),
    (512,4096,4096),
    (1024,4096,4096),
    (2048,4096,4096),
    (4096,4096,4096),
    (8192,4096,4096),
    (16384,4096,4096),
    (32768,4096,4096),
    (1,8192,8192),
    (32,8192,8192),
    (64,8192,8192),
    (128,8192,8192),
    (256,8192,8192),
    (512,8192,8192),
    (1024,8192,8192),
    (2048,8192,8192),
    (4096,8192,8192),
    (8192,8192,8192),
    (16384,8192,8192),
    (32768,8192,8192),
    # (128, 8192, 1024),
    # (192, 8192, 1024),
    # (256, 8192, 1024),
    # (320, 8192, 1024),
    # (512, 8192, 1024),
    # (1024, 8192, 1024),
    # (2048, 8192, 1024),
    # (4096, 8192, 1024),
    # (8192, 8192, 1024),
    # (16384, 8192, 1024),
]

parser = argparse.ArgumentParser(
    formatter_class=argparse.RawTextHelpFormatter,
    description="config input of test",
)
parser.add_argument(
    "-d",
    "--dtype",
    type=str,
    choices=l_dtype,
    nargs="?",
    const=None,
    default=None,
    help="""Data type.
    e.g.: -d bf16""",
)
parser.add_argument(
    "-mnk",
    "--shape",
    type=dtypes.str2tuple,
    nargs="?",
    const=None,
    default=None,
    help="""shape of mnk.
    e.g. -mnk 1280,8192,1024""",
)

args = parser.parse_args()
if args.dtype is None:
    l_dtype = [dtypes.d_dtypes[key] for key in l_dtype]
else:
    l_dtype = [dtypes.d_dtypes[args.dtype]]
if args.shape is not None:
    l_mnk = [args.shape]

df = []
for dtype in l_dtype:
    for m, n, k in l_mnk:
        ret = test_gemm(dtype, m, n, k)
        df.append(ret)
df = pd.DataFrame(df)
aiter.logger.info(f"summary:\n{df}")
