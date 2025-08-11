# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import triton
import triton.language as tl
from typing import Any, Dict, Optional

from aiter.ops.triton.quant import dynamic_per_tensor_quant_fp8_i8
from aiter.ops.triton.utils.types import torch_to_triton_dtype
from aiter.ops.triton.utils.logger import AiterTritonLogger

_LOGGER = AiterTritonLogger()

# Source:
# MoE Kernel adapted from VLLM

_PADDING_SIZE = 0

_MOE_A_QUANT_FUNC = dynamic_per_tensor_quant_fp8_i8

_USE_MOE_PERSISTENT_KERNEL = False


def moe_set_use_persistent_kernel(value: bool):
    global _USE_MOE_PERSISTENT_KERNEL
    _USE_MOE_PERSISTENT_KERNEL = value


def moe_set_padding_size(size: int):
    """
    Override padding size
    """
    global _PADDING_SIZE
    _PADDING_SIZE = size


def moe_set_quant_func(func):
    """
    Override 'A' matrix ie activations quantization function.
    Default function does dynamic quantization.
    """
    global _MOE_A_QUANT_FUNC
    _MOE_A_QUANT_FUNC = func


@triton.heuristics(
    {
        "EVEN_K": lambda args: args["K"] % args["BLOCK_SIZE_K"] == 0,
        "EVEN_K2": lambda args: args["K"] % args["BLOCK_SIZE_K2"] == 0,
    },
)
@triton.jit
def _e2e_moe_kernel(
    # Pointers to matrices
    a_ptr,
    b_ptr,
    c_ptr,
    o_ptr,
    sorted_token_ids_ptr,
    expert_ids_ptr,
    num_tokens_post_padded_ptr,
    # Matrix dimensions
    N,
    K,
    EM,
    num_valid_tokens,
    stride_am,
    stride_ak,
    stride_be,
    stride_bk,
    stride_bn,
    stride_ce,
    stride_cn,
    stride_ck,
    stride_om,
    stride_ok,
    # Meta-parameters
    BLOCK_SIZE_M: tl.constexpr,
    BLOCK_SIZE_N: tl.constexpr,
    BLOCK_SIZE_K: tl.constexpr,
    BLOCK_SIZE_K2: tl.constexpr,
    EVEN_K: tl.constexpr,
    EVEN_K2: tl.constexpr,
    NUM_WGS: tl.constexpr,
    top_k: tl.constexpr,
):
    """
    Implements the fused computation for a Mixture of Experts (MOE) using
    token and expert matrices.
    This is the persistent version of the fused_moe kernel.

    Key Parameters:
    - A: The input tensor representing tokens with shape (*, K), where '*' can
        be any shape representing batches and K is the feature dimension of
        each token.
    - B: The stacked MOE weight tensor with shape (E, N, K), where E is
        the number of experts, K is the input feature dimension, and N is
        the output feature dimension.
    - C: The second stacked MOE weight tensor with shape (E, K, N //2), where E is
        the number of experts, N // 2 is the input feature dimension (after silu), and K is
        the output feature dimension.
    - O: The output cache tensor with shape (M, topk, K), where M is the
        total number of tokens post padding, topk is the number of times
        each token is repeated, and K is the output feature dimension.
    - sorted_token_ids: A tensor containing the sorted indices of tokens,
        repeated topk times and arranged by the expert index they are
        assigned to.
    - expert_ids: A tensor containing the indices of the expert for each
        block. It determines which expert matrix from B should be used for
        each block in A.
    This kernel performs the multiplication of a token by its corresponding
    expert matrix as determined by `expert_ids`. The sorting of
    `sorted_token_ids` by expert index and padding ensures divisibility by
    BLOCK_SIZE_M, which is necessary to maintain consistency in block matrix
    multiplication across different blocks processed by the same expert.
    """

    start_tile = tl.program_id(axis=0)

    # Load number of non-padding tokens (runtime variable) and calculate number of tiles based on it
    num_tokens_post_padded = tl.load(num_tokens_post_padded_ptr)

    num_pid_m = tl.cdiv(num_tokens_post_padded, BLOCK_SIZE_M)
    num_pid_n = tl.cdiv(N, BLOCK_SIZE_N)

    offs_k = tl.arange(0, BLOCK_SIZE_K)

    num_tiles = num_pid_m * num_pid_n

    for tile_id in range(start_tile, num_tiles, step=NUM_WGS):
        pid_m = tile_id // num_pid_n
        pid_n = tile_id % num_pid_n

        # Prologue
        offs_token_id = pid_m * BLOCK_SIZE_M + tl.arange(0, BLOCK_SIZE_M).to(tl.int64)
        offs_token = tl.load(sorted_token_ids_ptr + offs_token_id)
        token_mask = offs_token < num_valid_tokens
        off_experts = tl.load(expert_ids_ptr + pid_m).to(tl.int64)

        # silu ptrs
        BLOCK_SIZE_HALF: tl.constexpr = BLOCK_SIZE_N // 2
        i = tl.arange(0, BLOCK_SIZE_N).to(tl.int64)
        # [0, 0, 1, 1, ..., BLOCK_SIZE_HALF - 1, BLOCK_SIZE_HALF - 1]
        i_floor = i // 2
        offs_half = (pid_n * (BLOCK_SIZE_N // 2) + i_floor) % (N // 2)
        # (i % 2): [0, 1, 0, 1,...] (alternating)
        # (i % 2) * (N // 2) : [0, (N // 2), 0, (N // 2),...]
        # So offs_bn now takes element from the first BLOCK_SIZE_HALF half and the second BLOCK_SIZE_HALF half in an alternating way (This allows us to do reshape without permute)
        offs_bn = (offs_half + (i % 2) * (N // 2)) % N

        # Compute the A pointer
        a_ptrs = a_ptr + (
            offs_token[:, None] // top_k * stride_am + offs_k[None, :] * stride_ak
        )
        # Compute the B pointer
        b_ptrs = (
            b_ptr
            + off_experts * stride_be
            + (offs_k[:, None] * stride_bk + offs_bn[None, :] * stride_bn)
        )

        accumulator = tl.zeros((BLOCK_SIZE_M, BLOCK_SIZE_N), dtype=tl.float32)

        for k in range(0, tl.cdiv(K, BLOCK_SIZE_K)):            
            # (first iter is part of the prologue)
            if EVEN_K:
                a = tl.load(a_ptrs, mask=token_mask[:, None], other=0.0)
                b = tl.load(b_ptrs)
            else:
                a = tl.load(
                    a_ptrs,
                    mask=token_mask[:, None] & (offs_k[None, :] < K - k * BLOCK_SIZE_K),
                    other=0.0,
                )
                b = tl.load(
                    b_ptrs, mask=offs_k[:, None] < K - k * BLOCK_SIZE_K, other=0.0
                )
            accumulator += tl.dot(a, b)
            # Advance the ptrs to the next K block.
            a_ptrs += BLOCK_SIZE_K * stride_ak
            b_ptrs += BLOCK_SIZE_K * stride_bk

        # silu_and_mul
        silu_acc, mul_acc = (
            accumulator.to(tl.float32).reshape(BLOCK_SIZE_M, BLOCK_SIZE_HALF, 2).split()
        )
        silu_acc = silu_acc / (1.0 + tl.exp2(-(silu_acc * 1.44269504089)))
        accumulator = (silu_acc * mul_acc).to(c_ptr.type.element_ty) # (BLOCK_SIZE_M, BLOCK_SIZE_N // 2)

        # Do the partial output compute with the accumulator
        offs_cn = pid_n * BLOCK_SIZE_HALF + tl.arange(0, BLOCK_SIZE_HALF)
        offs_k2 = tl.arange(0, BLOCK_SIZE_K2)

        c_ptrs = c_ptr + stride_cn * offs_cn[:, None] + stride_ck * offs_k2[None, :] + off_experts * stride_ce
        o_ptrs = o_ptr + stride_om * offs_token[:, None] + stride_ok * offs_k2[None, :]

        o_mask = token_mask[:, None]
        
        for k in range(0, tl.cdiv(K, BLOCK_SIZE_K2)):
            if EVEN_K2:
                c = tl.load(c_ptrs)
            else:
                c = tl.load(
                    c, mask=offs_k2[:, None] < (K - k * BLOCK_SIZE_K2), other=0.0
                )
                o_mask = o_mask & (offs_k2[None, :] < (K - k * BLOCK_SIZE_K2))

            # Epilogue
            partial_output = tl.dot(accumulator, c)
            tl.atomic_add(o_ptrs, partial_output, mask=o_mask, sem="relaxed")

            # Advance the ptrs to the next K block.
            c_ptrs += BLOCK_SIZE_K2 * stride_ck
            o_ptrs += BLOCK_SIZE_K2 * stride_ok
   

def e2e_moe(
    A: torch.Tensor,
    W1: torch.Tensor,
    W2: torch.Tensor,
    C: torch.Tensor,
    A_scale: Optional[torch.Tensor],
    W1_scale: Optional[torch.Tensor],
    W2_scale: Optional[torch.Tensor],
    topk_weights: torch.Tensor,
    sorted_token_ids: torch.Tensor,
    topk_ids,
    expert_ids: torch.Tensor,
    num_tokens_post_padded: torch.Tensor,
    mul_routed_weight: bool,
    top_k: int,
    use_fp8_w8a8: bool,
    use_int8_w8a16: bool,
    config: Optional[Dict[str, Any]] = None,
) -> None:
    """
    #TODO: Add doc
    """
    _LOGGER.info(
        f"MOE_E2E:  A={tuple(A.shape)}  W1={tuple(W1.shape)}  W2={tuple(W2.shape)}  topk_weights={tuple(topk_weights.shape)}"
        + f" sorted_token_ids={tuple(sorted_token_ids.shape)} expert_ids={tuple(expert_ids.shape)}"
        + f" num_tokens_post_padded={tuple(num_tokens_post_padded.shape)} top_k={top_k} "
    )
    assert topk_weights.stride(1) == 1
    assert sorted_token_ids.stride(0) == 1

    BLOCK_M = config["BLOCK_SIZE_M"]

    config = {
        "BLOCK_SIZE_M": BLOCK_M,
        "BLOCK_SIZE_N": 128,
        "BLOCK_SIZE_K": 128,
        "BLOCK_SIZE_K2": 128,
    }

    EM = sorted_token_ids.shape[0]
    if A.shape[0] < config["BLOCK_SIZE_M"]:
        # optimize for small batch_size.
        # We assume that top_ids of each token is unique, so
        # so num_valid_experts <= batch_size <= BLOCK_SIZE_M,
        # and we can skip some invalid blocks.
        EM = min(sorted_token_ids.shape[0], A.shape[0] * top_k * config["BLOCK_SIZE_M"])

    N = W1.shape[1]
    K = A.shape[1] - _PADDING_SIZE

    NUM_WGS = torch.cuda.get_device_properties("cuda").multi_processor_count
    grid = (NUM_WGS,)

    _e2e_moe_kernel[grid](
        A,
        W1,
        W2,
        C,
        sorted_token_ids,
        expert_ids,
        num_tokens_post_padded,
        N,
        K,
        EM,
        topk_ids.numel(),
        A.stride(0),
        A.stride(1),
        W1.stride(0),
        W1.stride(1),
        W1.stride(2),
        W2.stride(0),
        W2.stride(2),
        W2.stride(1),
        C.stride(1),
        C.stride(2),
        NUM_WGS=NUM_WGS,
        top_k=top_k,
        **config,
    )

    


    return C
    