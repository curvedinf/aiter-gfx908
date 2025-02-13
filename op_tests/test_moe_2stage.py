# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

import torch
import torch.nn.functional as F
import triton.language as tl
import numpy as np
import sys
import os
from typing import Any, Callable, Dict, Optional, Tuple
import aiter
from aiter.test_common import checkAllclose, perftest
from aiter import pertoken_quant
from aiter.fused_moe_gelu import fused_topk
from aiter.fused_moe_bf16_asm import asm_moe, torch_moe, moe_sorting_ck
from aiter.ops.shuffle import shuffle_weight


@perftest(num_iters=3)
def torch_moe_stage1(hidden_states,
                     w1,  # E, inter_dim*2, model_dim
                     w2,  # E, model_dim, inter_dim
                     topk_weight, topk_ids,
                     # following for quant
                     fc1_scale=None,  # [expert, inter_dim, 1]
                     block_size=32
                     ):
    B, D = hidden_states.shape
    topk = topk_weight.shape[1]
    dtype = hidden_states.dtype
    num_experts, model_dim, inter_dim = w2.shape
    hidden_states = hidden_states.view(
        B, -1, D).repeat(1, topk, 1)

    max_num_tokens_padded = topk_ids.numel() + num_experts * block_size - topk
    # max_num_tokens_padded = int(
    #     (max_num_tokens_padded+block_size-1)//block_size)*block_size

    # gose to quant D_w8a8/w8a8
    if fc1_scale is not None:
        expert = w1.shape[0]
        w1 = (w1.view(-1, D).to(fc1_scale) *
              fc1_scale.view(-1, 1)).to(dtype).view(expert, -1, D)

    out = torch.zeros(
        (max_num_tokens_padded, inter_dim),
        dtype=dtype,
        device=hidden_states.device,
    )
    loc = 0
    for E_id in range(w1.shape[0]):
        mask = topk_ids == E_id
        if mask.sum():
            sub_tokens = hidden_states[mask]
            act_input = sub_tokens @ (w1[E_id].transpose(0, 1))
            out[loc:loc+act_input.shape[0]] = act_input
            loc += int((act_input.shape[0] +
                       block_size-1)//block_size)*block_size
    return out

@perftest(num_iters=3)
def torch_moe_stage2(hidden_states,
                     w1,  # E, inter_dim*2, model_dim
                     w2,  # E, model_dim, inter_dim
                     topk_weight, topk_ids,
                     # following for quant
                     fc2_scale=None,  # [expert, model_dim, 1]
                     block_size=32
                     ):
    B, D = topk_ids.shape[0], w1.shape[-1]
    topk = topk_weight.shape[1]
    dtype = hidden_states.dtype
    num_experts, model_dim, inter_dim = w2.shape

    # gose to quant D_w8a8/w8a8
    if fc2_scale is not None:
        expert = w1.shape[0]
        w2 = (w2.view(-1, inter_dim).to(fc2_scale) *
              fc2_scale.view(-1, 1)).to(dtype).view(expert, -1, inter_dim)

    out = torch.zeros(
        (B, topk, D),
        dtype=dtype,
        device=hidden_states.device,
    )
    loc = 0
    for E_id in range(w2.shape[0]):
        mask = topk_ids == E_id
        if mask.sum():
            len = mask.sum()
            sub_tokens = hidden_states[loc:loc+len]
            act_input = sub_tokens @ (w2[E_id].transpose(0, 1))
            out[mask] = act_input
            loc += int((len +
                       block_size-1)//block_size)*block_size
    return (
        out * topk_weight.view(B, -1, 1).to(out.dtype)
    ).sum(dim=1)

def torch_moe(hidden_states, w1, w2, topk_weight, topk_ids,
              # following for quant
              fc1_scale=None,  # [expert, inter_dim, 1]
              fc2_scale=None,  # [expert, model_dim, 1]
              fc1_smooth_scale=None,  # [expert, 1, model_dim]
              fc2_smooth_scale=None,  # [expert, 1, inter_dim]
              ):
    B, D = hidden_states.shape
    topk = topk_weight.shape[1]
    dtype = hidden_states.dtype
    hidden_states = hidden_states.view(
        B, -1, D).repeat(1, topk, 1)
    out = torch.zeros(
        (B, topk, D),
        dtype=dtype,
        device=hidden_states.device,
    )
    # g1u1(w1 include gate and up)
    if w2.shape[2]*2 == w1.shape[1]:
        moeType = "g1u1"
        inter_dim = w2.shape[2]
    # g1u0(w1 only include gate)
    else:
        moeType = "g1u0"
        inter_dim = w1.shape[1]
    # gose to quant D_w8a8/w8a8
    if fc1_scale is not None:
        expert = w1.shape[0]
        w2D = w2.shape[-1]
        w1 = (w1.view(-1, D).to(fc1_scale) *
              fc1_scale.view(-1, 1)).to(dtype).view(expert, -1, D)
        w2 = (w2.view(-1, w2D).to(fc2_scale) *
              fc2_scale.view(-1, 1)).to(dtype).view(expert, -1, w2D)
    if fc1_smooth_scale is not None:
        expert = fc1_smooth_scale.shape[0]
        fc1_smooth_scale = fc1_smooth_scale.view(expert, -1).to(dtype)
        fc2_smooth_scale = fc2_smooth_scale.view(expert, -1).to(dtype)

    for E_id in range(w1.shape[0]):
        mask = topk_ids == E_id
        if mask.sum():
            sub_tokens = hidden_states[mask]
            if fc1_smooth_scale is not None:
                sub_tokens = sub_tokens * (
                    fc1_smooth_scale[E_id])
            act_input = sub_tokens @ (w1[E_id].transpose(0, 1))
            if moeType == "g1u1":
                gate, up = act_input.split([inter_dim, inter_dim], dim=-1)
                act_out = F.silu(gate) * up
            else:
                act_out = F.gelu(act_input)
            if fc2_smooth_scale is not None:
                act_out = act_out * (
                    fc2_smooth_scale[E_id])
            out[mask] = act_out @ (w2[E_id].transpose(0, 1))

    return (
        out * topk_weight.view(B, -1, 1).to(out.dtype)
    ).sum(dim=1)


@perftest()
def ck_moe_stage1(hidden_states,
                  w1,  # [E, inter_dim*2, model_dim]
                  w2,  # [E, model_dim, inter_dim]
                  sorted_token_ids,  # [max_num_tokens_padded]
                  sorted_expert_ids,  # [max_num_m_blocks]
                  w1_scale, a1_scale, dtype,
                  block_size=32
                  ):
    num_experts, model_dim, inter_dim = w2.shape
    max_num_tokens_padded = sorted_token_ids.shape[0]
    # max_num_tokens_padded = sorted_expert_ids.shape[0]*block_size

    out = torch.zeros(
        (max_num_tokens_padded, inter_dim),
        dtype=dtype,
        device=hidden_states.device,
    )
    aiter.ck_moe_stage1(hidden_states, w1, w2, sorted_token_ids,
                        sorted_expert_ids, out, w1_scale, a1_scale)
    return out


def test_fmoe(dtype, token, model_dim, inter_dim, E, topk, quant='No', use_g1u1=False, shared_E=0):
    input = torch.randn((token, model_dim), dtype=dtype, device="cuda")
    if use_g1u1:
        w1 = torch.randn((E+shared_E, inter_dim*2, model_dim),
                         dtype=dtype, device="cuda") / 10
    else:
        w1 = torch.randn((E+shared_E, inter_dim, model_dim),
                         dtype=dtype, device="cuda")
    w2 = torch.randn((E+shared_E, model_dim, inter_dim),
                     dtype=dtype, device="cuda")
    score = torch.randn((token, E), device="cuda", dtype=dtype)
    topk_weights, topk_ids = fused_topk(input, score, topk, True)

    E, model_dim, inter_dim = w2.shape
    M, topk = topk_ids.shape
    sorted_ids, sorted_weights, sorted_expert_ids, num_tokens_post_padded, moe_buf = moe_sorting_ck(topk_ids, topk_weights, E,
                                                                                                    model_dim, dtype)

    BLOCK_SIZE_M = 32
    quant_dtype = torch.float8_e4m3fnuz
    w1_qt, w1_scale = aiter.per_tensor_quant(w1,  quant_dtype=quant_dtype)
    w2_qt, w2_scale = aiter.per_tensor_quant(w2,  quant_dtype=quant_dtype)
    a1_qt, a1_scale = aiter.per_tensor_quant(input,  quant_dtype=quant_dtype)

    out_ref, us_ref = torch_moe_stage1(input, w1,
                                       w2,
                                       topk_weights, topk_ids,
                                       #    w1_scale,
                                       None,
                                       BLOCK_SIZE_M)
    out, us = ck_moe_stage1(input,
                            shuffle_weight(w1, layout=(32, 32)),
                            w2,
                            sorted_ids,
                            sorted_expert_ids,
                            w1_scale, a1_scale,
                            dtype, BLOCK_SIZE_M)
    checkAllclose(out_ref, out,
                  msg=f'golden: {us_ref:.2f} us vs aiter:{us:.2f} us, {token*model_dim*inter_dim*topk*2/us/1000/1000:.2f} tflops......(quant:{quant_dtype})')


for dtype in [torch.float16]:
    for m in [32]:
        for dim in [8192]:
            for inter_dim in [6144]:
                expert, topk = 8, 2
                test_fmoe(dtype, m, dim, inter_dim, expert, topk,
                          quant='fp8smoothquant', use_g1u1=False)
