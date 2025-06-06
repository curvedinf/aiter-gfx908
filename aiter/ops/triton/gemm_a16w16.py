# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

from typing import Optional
import torch
import triton
import triton.language as tl
from aiter.ops.triton.utils.pid_preprocessing import pid_grid, remap_xcd
import os

@triton.heuristics(
    {
        "EVEN_K": lambda args: args["K"] % args["BLOCK_SIZE_K"] == 0,
        "GRID_MN": lambda args: triton.cdiv(args["M"], args["BLOCK_SIZE_M"])
        * triton.cdiv(args["N"], args["BLOCK_SIZE_N"]),
    }
)
@triton.jit
def _gemm_a16_w16_kernel(
    a_ptr,
    b_ptr,
    c_ptr,
    M,
    N,
    K,
    stride_am,
    stride_ak,
    stride_bk,
    stride_bn,
    stride_cm,
    stride_cn,
    # Meta-parameters
    BLOCK_SIZE_M: tl.constexpr,
    BLOCK_SIZE_N: tl.constexpr,
    BLOCK_SIZE_K: tl.constexpr,
    GROUP_SIZE_M: tl.constexpr,
    EVEN_K: tl.constexpr,
    GRID_MN: tl.constexpr,
):
    """Kernel for computing the matmul C = A x B.
    A has shape (M, K), B has shape (K, N) and C has shape (M, N)
    """

    tl.assume(stride_am > 0)
    tl.assume(stride_ak > 0)
    tl.assume(stride_bk > 0)
    tl.assume(stride_bn > 0)
    tl.assume(stride_cm > 0)
    tl.assume(stride_cn > 0)

    # -----------------------------------------------------------
    # Map program ids `pid` to the block of C it should compute.
    # This is done in a grouped ordering to promote L2 data reuse.
    pid = tl.program_id(axis=0)
    num_pid_m = tl.cdiv(M, BLOCK_SIZE_M)
    num_pid_n = tl.cdiv(N, BLOCK_SIZE_N)

    remap_xcd(pid, GRID_MN)

    pid_m, pid_n = pid_grid(pid, num_pid_m, num_pid_n, GROUP_SIZE_M=GROUP_SIZE_M)

    tl.assume(pid_m > 0)
    tl.assume(pid_n > 0)

    # Create pointers for first block of A and B input matrices
    offs_k = tl.arange(0, BLOCK_SIZE_K)
    offs_am = (pid_m.to(tl.int64) * BLOCK_SIZE_M + tl.arange(0, BLOCK_SIZE_M)) % M
    offs_bn = (pid_n.to(tl.int64) * BLOCK_SIZE_N + tl.arange(0, BLOCK_SIZE_N)) % N
    a_ptrs = a_ptr + (offs_am[:, None] * stride_am + offs_k[None, :] * stride_ak)
    b_ptrs = b_ptr + (offs_k[:, None] * stride_bk + offs_bn[None, :] * stride_bn)

    acc_dtype = tl.float32 if c_ptr.type.element_ty != tl.int8 else tl.int32
    accumulator = tl.zeros((BLOCK_SIZE_M, BLOCK_SIZE_N), dtype=acc_dtype)

    for k in range(0, tl.cdiv(K, BLOCK_SIZE_K)):
        # Load the next block of A and B, generate a mask by checking the K dimension.
        # If it is out of bounds, set it to 0.
        if EVEN_K:
            a = tl.load(a_ptrs)
            b = tl.load(b_ptrs)
        else:
            a = tl.load(a_ptrs, mask=offs_k[None, :] < K - k * BLOCK_SIZE_K, other=0.0)
            b = tl.load(b_ptrs, mask=offs_k[:, None] < K - k * BLOCK_SIZE_K, other=0.0)

        accumulator += tl.dot(a, b, input_precision="ieee")

        # Advance the ptrs to the next K block.
        a_ptrs += BLOCK_SIZE_K * stride_ak
        b_ptrs += BLOCK_SIZE_K * stride_bk

    c = accumulator.to(c_ptr.type.element_ty)

    # Write back the block of the output matrix C with masks.
    offs_cm = pid_m.to(tl.int64) * BLOCK_SIZE_M + tl.arange(0, BLOCK_SIZE_M)
    offs_cn = pid_n.to(tl.int64) * BLOCK_SIZE_N + tl.arange(0, BLOCK_SIZE_N)
    c_ptrs = c_ptr + stride_cm * offs_cm[:, None] + stride_cn * offs_cn[None, :]
    c_mask = (offs_cm[:, None] < M) & (offs_cn[None, :] < N)
    tl.store(c_ptrs, c, mask=c_mask)


# Wrapper for gemm kernel.
def gemm_a16w16(
    x,
    w,
    dtype: Optional[float] = torch.bfloat16,
    y: Optional[torch.Tensor] = None,
):
    """
    Computes the 16 bit matmul Y = X x W

    Key parameters:
    - X: Matrix X with shape (M, K).
    - W: Matrix W with shape (N, K).
    - dtype: Optional parameter to specifcy bf16 or fp16 datatype. Default is bf16
    - Y: Output Matrix Y with shape (M, N). If this is none, then it's created by this API and returned as output

    Returns:
    - Y: The output matrix with shape (M, N).
    """

    M, K = x.shape
    K, N = w.shape

    if y is None:
        y = torch.empty((M, N), dtype=dtype, device=x.device)

    BLOCK_SIZE_M = 256
    BLOCK_SIZE_N = 256
    BLOCK_SIZE_K = 32
    GROUP_SIZE_M = 4
    waves_per_eu = 2
    kpack = 1
    matrix_instr_nonkdim = 16
    num_warps = 8
    num_stages = 3

    num_M_slice = 1
    num_N_slice = 1
    slice_size_M = M
    slice_size_N = N
    shape_db = None

    TRITON_HIP_MNSPLIT = os.environ.get("TRITON_HIP_MNSPLIT", "0")
    #if TRITON_HIP_MNSPLIT == "1":
    if True:
        shape_db = {(8192, 10240, 65536):(8192, 10240),
            (8192, 65536, 10240):(4096, 4096),
            (10240, 65536, 8192):(10240, 4096),
            (8192, 65536, 8192):(8192, 8192),
            (8192, 65536, 28672):(8192, 4096),
            (128256, 65536, 8192):(42752, 8192),
            (8192, 65536, 128256):(8192, 4096),
            (8192, 128256, 65536):(8192, 128256),
            (28672, 65536, 8192):(4096, 8192),
            (8192, 57344, 65536):(4096, 4096),
            (57344, 65536, 8192):(8192, 4096),
            (28672, 8192, 65536):(4096, 4096),
            (8192, 65536, 8192):(8192, 8192),
            (8192, 65536, 57344):(8192, 4096),
            (8192, 8192, 65536):(4096, 4096),
        }
    elif TRITON_HIP_MNSPLIT == "2":
        shape_db = {(8192, 10240, 65536):(8192, 10240),
            (8192, 65536, 10240):(4096, 4096),
            (10240, 65536, 8192):(10240, 4096),
            (8192, 65536, 8192):(8192, 8192),
            #(8192, 65536, 28672):(8192, 4096),
            (128256, 65536, 8192):(42752, 8192),
            #(8192, 65536, 128256):(8192, 4096),
            (8192, 128256, 65536):(8192, 128256),
            (28672, 65536, 8192):(4096, 8192),
            (8192, 57344, 65536):(4096, 4096),
            (57344, 65536, 8192):(8192, 4096),
            (28672, 8192, 65536):(4096, 4096),
            (8192, 65536, 8192):(8192, 8192),
            #(8192, 65536, 57344):(8192, 4096),
            (8192, 8192, 65536):(4096, 4096),
        }
    if shape_db is not None :
        if (M, N, K) in shape_db:
            (slice_size_M, slice_size_N) = shape_db[(M, N, K)]
            assert(M % slice_size_M == 0)
            assert(N % slice_size_N == 0)
            num_M_slice = int(M / slice_size_M)
            num_N_slice = int(N / slice_size_N)
    
    #print (TRITON_HIP_MNSPLIT, num_M_slice,  num_N_slice,  slice_size_M, slice_size_N)

    x_sub = x.view(num_M_slice, slice_size_M, K) 
    w_sub = w.view(K, num_N_slice, slice_size_N) 
    y_sub = y.view(num_M_slice, slice_size_M, num_N_slice, slice_size_N)
    # Process blocks directly using .view()
    grid = lambda META: (triton.cdiv(slice_size_M, META['BLOCK_SIZE_M']) * triton.cdiv(slice_size_N, META['BLOCK_SIZE_N']), )
    for i in range(num_M_slice):
        for j in range(num_N_slice):
            # Extract A block using .view() e.g.: (8192, 65536) -> (2, 4096, 65536)[i]
            x_block = x_sub[i, :, :]  # Shape: (4096, 65536)

            # Extract B block using .view() e.g.: (65536, 28672) -> (65536, 7, 4096)[:, j, :]
            w_block = w_sub[:, j, :]  # Shape: (65536, 4096)
            
            # Create output view directly in final result tensor
            # Map (i,j) block to correct position e.g.: (8192, 28672) -> (2, 4096, 7, 4096)[i, :, j, :]
            output_view = y_sub[i, :, j, :]
            
            _gemm_a16_w16_kernel[grid](
                x_block,
                w_block,
                output_view,
                slice_size_M,
                slice_size_N,
                K,
                x_block.stride(0),
                x_block.stride(1),
                w_block.stride(0),
                w_block.stride(1),
                output_view.stride(0),
                output_view.stride(1),
                BLOCK_SIZE_M,
                BLOCK_SIZE_N,
                BLOCK_SIZE_K,
                GROUP_SIZE_M,
                waves_per_eu=waves_per_eu,
                kpack=kpack,
                matrix_instr_nonkdim=matrix_instr_nonkdim,
                num_warps=num_warps,
                num_stages=num_stages,
            )

    return y
