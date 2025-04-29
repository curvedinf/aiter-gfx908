# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

import torch
import torch.nn.functional as F
import math
import sys
import os
from typing import Any, Callable, Dict, Optional, Tuple
import itertools
import aiter
from aiter.test_common import (
    checkAllclose,
    perftest,
    benchmark,
    tensor_dump,
    run_perftest,
)
from aiter.int4_utils import *

from aiter.fused_moe import (
    fused_topk,
    get_inter_dim,
    torch_moe,
    moe_sorting,
    fused_moe,
    asm_stage1,
    ck_stage1,
    ck_stage1_tune,
    torch_moe_stage1,
    torch_moe_stage2,
)
from aiter.fused_moe_bf16_asm import moe_sorting_ck, get_block_size, ck_moe_2stages

from aiter.ops.shuffle import shuffle_weight
from aiter import ActivationType

torch.int4 = getattr(torch, "int4", torch.uint32)
torch.set_default_device("cuda")



@perftest()
def moe_stage2_ck_tune(
    hidden_states,  # [M, topk, inter_dim]
    w1,  # [E, inter_dim*2, model_dim]
    w2,  # [E, model_dim, inter_dim]
    sorted_token_ids,  # [max_num_tokens_padded]
    sorted_expert_ids,  # [max_num_m_blocks]
    sorted_weights,  # [max_num_tokens_padded]
    num_valid_ids,  # [1]
    quant_type,
    w2_scale,
    a2_scale,
    dtype,
    topk,
    block_size=32,
):
    token_num = hidden_states.shape[0]
    D = w2.shape[1]
    num_experts, model_dim, inter_dim = w2.shape
    max_num_tokens_padded = sorted_token_ids.shape[0]
    # max_num_tokens_padded = sorted_expert_ids.shape[0]*block_size

    out = torch.zeros(
        (token_num, D),
        dtype=dtype,
        device=hidden_states.device,
    )
    
    if quant_type == aiter.QuantType.per_128x128:
        aiter.ck_moe_stage2_blockscale(
            hidden_states,
            w1,
            w2,
            sorted_token_ids,
            sorted_expert_ids,
            sorted_weights,
            num_valid_ids,
            out,
            topk,
            "",#"ck_moe_stage2_B16_F8_F8_PerTensor_256x128x128x128_2x2_16_MulABScaleExpertWeight_Nswizzle0_interwave_v1",
            quant_type,
            w2_scale,
            a2_scale,
            block_size,
        )        
    return out


@benchmark()
def test_fmoe(
    dtype,
    token,
    model_dim,
    inter_dim,
    E,
    topk,
    actType,
    qType,
    AQDType,
    WQDType,
    use_g1u1=False,
    doweight_stage1=False,
):
    torch_quant = aiter.get_torch_quant(qType)
    torch_act = aiter.get_torch_act(actType)
    input = torch.randn((token, model_dim), dtype=dtype) / math.sqrt(inter_dim)
    device = input.device
    if use_g1u1:
        w1 = torch.randn((E, inter_dim * 2, model_dim), dtype=dtype)
    else:
        w1 = torch.randn((E, inter_dim, model_dim), dtype=dtype) 
    w2 = torch.randn((E, model_dim, inter_dim), dtype=dtype) 

    score = torch.randn((token, E), dtype=dtype)
    topk_weights, topk_ids = fused_topk(input, score, topk, True)
    
    M, _ = topk_ids.shape
    BLOCK_SIZE_M = get_block_size(M, topk, E)
    BLOCK_SIZE_M = 128
    _, us_moe_sort = run_perftest(
      moe_sorting,
      topk_ids, topk_weights, E, model_dim, dtype, BLOCK_SIZE_M,
    )

    sorted_ids, sorted_weights, sorted_expert_ids, num_valid_ids, moe_buf = moe_sorting(
        topk_ids, topk_weights, E, model_dim, dtype, BLOCK_SIZE_M
    )

    def weight_per_128x128_quant(weight, quant_dtype):
        E, dim1, dim2 = weight.shape  
        weight_blocks = weight.view(E, dim1 // 128, 128, dim2 // 128, 128)  # [E, num_blocks_dim1, 128, num_blocks_dim2, 128]
        weight_blocks = weight_blocks.permute(0, 1, 3, 2, 4).contiguous()   # [E, num_blocks_dim1, num_blocks_dim2, 128, 128]
        weight_blocks = weight_blocks.view(E, -1, 128 * 128)                # [E, num_blocks, 128*128]
        weight_qt, weight_scale = aiter.pertoken_quant(weight_blocks, quant_dtype=quant_dtype)
        weight_qt = weight_qt.view(E, dim1 // 128, dim2 // 128, 128, 128)     # [E, num_blocks_dim1, num_blocks_dim2, 128, 128]
        weight_qt = weight_qt.permute(0, 1, 3, 2, 4).contiguous()            # [E, num_blocks_dim1, 128, num_blocks_dim2, 128]
        weight_qt = weight_qt.view(E, dim1, dim2)                            # [E, dim1, dim2]
        weight_scale = weight_scale.view(E, dim1 // 128, dim2 // 128)        # [E, num_blocks_dim1, num_blocks_dim2]
        return weight_qt, weight_scale
    
    w1_qt, w1_scale = weight_per_128x128_quant(w1, quant_dtype=WQDType)
    w2_qt, w2_scale = weight_per_128x128_quant(w2, quant_dtype=WQDType)  

    w1_qt = w1_qt_aiter = w1_qt.view(w1.shape)
    w2_qt = w2_qt_aiter = w2_qt.view(w2.shape)


    triton_quant = aiter.get_triton_quant(aiter.QuantType.per_128x128)
    _, us_aq1 = run_perftest(
        triton_quant,
        input,
        quant_dtype=AQDType,
    )

    a1_qt, a1_scale = aiter.pertoken_quant(input.view(token, -1, 128), quant_dtype=AQDType)
    a1_qt = a1_qt.view(token, model_dim)
    a1_scale = a1_scale.squeeze(-1)

    out1_ref, us_ref = run_perftest(
        torch_moe_stage1,
        a1_qt,
        w1_qt,
        w2_qt,
        topk_weights,
        topk_ids,
        dtype=dtype,
        activation=actType,
        quant_type=qType,
        a1_scale=a1_scale,
        w1_scale=w1_scale,
        num_iters=3,
        doweight=doweight_stage1,
    )

    ######################## stage 1 asm ###########
    ratio = a1_scale.element_size() // a1_qt.element_size()
    out1_asm = torch.empty(
    (token + (token * ratio + 127) // 128, topk, inter_dim),
    dtype=torch.float8_e4m3fnuz,
    device=device,
    )

    _, us_asm_stage1 = run_perftest(
        asm_stage1,
        a1_qt,
        shuffle_weight(w1_qt, (16, 16)),
        shuffle_weight(w2_qt, (16, 16)),
        sorted_ids,
        sorted_expert_ids,
        num_valid_ids,
        out1_asm,
        kernelName="",
        w1_scale=w1_scale,
        a1_scale=a1_scale,
        activation=actType,
        quant_type=qType,
        block_m=BLOCK_SIZE_M,
    )

    out1_asm_v = out1_asm[:token, :, :]
    a2_scale = (
        out1_asm[token:, ...]
        .view(-1)[: token * topk * inter_dim * ratio // 128]
        .view(torch.float)
        .view(token, -1)
    )
    out1_asm = out1_asm_v
    

    w1_qt_aiter = shuffle_weight(w1_qt_aiter, layout=(16, 16))
    w2_qt_aiter = shuffle_weight(w2_qt_aiter, layout=(16, 16))

    # ######################## stage 2 start ###########

    a2_qt, a2_scale = aiter.pertoken_quant(out1_ref.view(token, -1, 128), quant_dtype=AQDType)
    a2_qt = a2_qt.view(token, topk, -1)
    a2_scale = a2_scale.view(token, topk, -1)

    checkAllclose(
        a2_qt.to(dtype),
        out1_asm.to(dtype),
        msg=f"[perf] asm_moe_stage1:{us_asm_stage1:>8.2f} us, {token*model_dim*inter_dim*topk*2/us_asm_stage1/1000/1000:>8.2f} tflops......(quant:{AQDType})",
    )

    out2_ref, us_ref = run_perftest(
        torch_moe_stage2,
        a2_qt,
        w1_qt,  # E, inter_dim*2, model_dim
        w2_qt,  # E, model_dim, inter_dim
        topk_weights,
        topk_ids,
        dtype=dtype,
        quant_type=qType,
        w2_scale=w2_scale,
        a2_scale=a2_scale,
        num_iters=3,
        doweight=not doweight_stage1,
    )
  
    out2_ck_tune, us = moe_stage2_ck_tune(
        a2_qt,
        w1_qt_aiter,
        w2_qt_aiter,
        sorted_ids,
        sorted_expert_ids,
        sorted_weights,
        num_valid_ids,
        qType,
        w2_scale,
        a2_scale,
        dtype,
        topk,
        BLOCK_SIZE_M,
    )

    checkAllclose(
        out2_ref,
        out2_ck_tune,
        msg=f"asm_stage1+ck_stage2: {us_moe_sort+us_aq1+us_asm_stage1+us:>8.2f} us, {token*model_dim*inter_dim*topk*2/us/1000/1000:>8.2f} tflops......(quant:{AQDType})",
    )
    print("asm_stage1+ck_stage2:",us_moe_sort+us_aq1+us_asm_stage1+us," us")
    print(" us_moe_sort:",us_moe_sort," us")
    print(" us_aq1: ",us_aq1," us")
    print(" us_asm_stage1: ",us_asm_stage1," us")
    print(" us_ck_stage2: ",us," us")
    ######################## stage 2 end ###########
    

    ##############fuse moe asm one stage############
    out2_aiter, us_fuse = run_perftest(
        fused_moe,
        input.view(token, model_dim),
        w1_qt_aiter,
        w2_qt_aiter,
        topk_weights,
        topk_ids,
        w1_scale=w1_scale,
        w2_scale=w2_scale,
        quant_type=qType,
        activation=actType,
        doweight_stage1=doweight_stage1,
    )

    err = checkAllclose(
        out2_ref,
        out2_aiter,
        msg=f"asm one stages: {us_fuse:>8.2f} us......",
    )
    return {"us": us, "err": err}

for dtype in [torch.bfloat16]:
    for m in [128]:
        for dim in [7168]:
            for inter_dim in [2048]:
                expert, topk = 8, 2
                test_fmoe(
                    dtype,
                    m,
                    dim,
                    inter_dim,
                    expert,
                    topk,
                    aiter.ActivationType.Silu,
                    aiter.QuantType.per_128x128,
                    torch.float8_e4m3fnuz,
                    torch.float8_e4m3fnuz,
                    use_g1u1=True,
                    doweight_stage1 = False,
                )