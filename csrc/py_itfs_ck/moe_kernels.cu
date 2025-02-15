// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include "py_itfs_common.h"

#include "fused_moe.hpp"
#include "moe_ck_gemm.hpp"

torch::Tensor ck_moe(torch::Tensor &hidden_states,          // [m, k], input token
                     torch::Tensor &w1,                     // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
                     torch::Tensor &w2,                     // [e, n, k], pre-shuffle([e, nr, kr, w])
                     torch::Tensor &topk_weights,           // [tokens, topk]
                     torch::Tensor &topk_ids,               // [tokens, topk]
                     std::optional<torch::Tensor> w1_scale, // [e, 1, n], gate(up) scale
                     std::optional<torch::Tensor> w2_scale, // [e, 1, k], down scale
                     std::optional<torch::Tensor> a1_scale, // [m, 1], token scale
                     std::optional<torch::Tensor> a2_scale, // [e, 1, n], smooth-quant-scale for 2nd gemm input
                     std::optional<int> block_m = 32,
                     std::optional<torch::Tensor> expert_mask = std::nullopt)
{
    const at::cuda::OptionalCUDAGuard device_guard(device_of(hidden_states));
    auto device = hidden_states.device();
    int topk_ids_numel = topk_ids.numel();
    int experts = w1.size(0);
    int topk = topk_ids.size(1);
    int tokens = topk_ids.size(0);
    int hidden_size = w1.size(2);
    int shared_intermediate_size_0 = w1.size(1);
    int shared_intermediate_size = w2.size(-1);
    int block_size = block_m.value();

    int max_num_tokens_padded = topk_ids_numel + experts * block_size - topk;
    int max_num_m_blocks = (max_num_tokens_padded + block_size - 1) / block_size;

    auto sorted_ids = torch::empty({max_num_tokens_padded}, torch::TensorOptions().dtype(torch::kInt32).device(device));
    auto sorted_weights = torch::empty({max_num_tokens_padded}, torch::TensorOptions().dtype(torch::kFloat32).device(device));
    auto sorted_expert_ids = torch::empty({max_num_m_blocks}, torch::TensorOptions().dtype(torch::kInt32).device(device));
    auto num_valid_ids = torch::empty({1}, torch::TensorOptions().dtype(torch::kInt32).device(device));
    auto out = torch::empty({tokens, hidden_size}, torch::TensorOptions().dtype(hidden_states.dtype()).device(device));

    auto prec_i = torchDTypeToStr(hidden_states.dtype());
    auto prec_w = torchDTypeToStr(w1.dtype());
    auto prec_o = torchDTypeToStr(out.dtype());
    auto prec_kw = torchDTypeToStr(topk_weights.dtype());

    int gate_only = 1;
    int activation = 0;
    int fused_quant = 0;
    if (shared_intermediate_size_0 == 2 * shared_intermediate_size)
    {
        gate_only = 0;
        activation = 1;
    }

    if (!w1_scale.has_value())
    {
        fused_quant = 0;
    }
    else if (a1_scale.has_value() && a2_scale.has_value())
    {
        fused_quant = 1;
    }
    else
    {
        fused_quant = 2;
    }

    int stride = hidden_size;
    std::string prec_st = !a1_scale ? "fp32" : torchDTypeToStr(a1_scale->dtype());
    std::string prec_sw = !w1_scale ? "fp32" : torchDTypeToStr(w1_scale->dtype());
    std::string prec_sq = !a2_scale ? "fp32" : torchDTypeToStr(a2_scale->dtype());

    fused_moe_traits traits{
        prec_i,
        prec_w,
        prec_o,
        prec_st,
        prec_sw,
        prec_sq,
        prec_kw,
        block_size,
        // activation,
        gate_only,
        fused_quant,
        // expert_mask.has_value(),
    };

    fused_moe_args args{hidden_states.data_ptr(),
                        a1_scale.has_value() ? a1_scale.value().data_ptr() : nullptr,
                        w1.data_ptr(),
                        w2.data_ptr(),
                        w1_scale.has_value() ? w1_scale.value().data_ptr() : nullptr,
                        w2_scale.has_value() ? w2_scale.value().data_ptr() : nullptr,
                        a2_scale.has_value() ? a2_scale.value().data_ptr() : nullptr,
                        // expert_mask.has_value() ? expert_mask.value().data_ptr() : nullptr,
                        out.data_ptr(),

                        topk_ids.data_ptr(),
                        topk_weights.data_ptr(),
                        sorted_ids.data_ptr(),
                        sorted_weights.data_ptr(),
                        sorted_expert_ids.data_ptr(),
                        num_valid_ids.data_ptr(),

                        block_size,
                        hidden_size,
                        shared_intermediate_size,
                        tokens,
                        experts,
                        topk,
                        stride};

    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();

    fused_moe(traits, args, {stream});
    return out;
}

#define CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, MPerBlock)                                                                                                                                                                                                                \
    if (MPerBlock == 32)                                                                                                                                                                                                                                                                                                \
        ck_moe_stage1_gemm<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 32>(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk, hidden_states_ptr, w1_ptr, w2_ptr, sorted_token_ids_ptr, sorted_expert_ids_ptr, num_valid_ids_ptr, out_ptr, w1_scale_ptr, a1_scale_ptr); \
    else if (MPerBlock == 64)                                                                                                                                                                                                                                                                                           \
        ck_moe_stage1_gemm<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 64>(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk, hidden_states_ptr, w1_ptr, w2_ptr, sorted_token_ids_ptr, sorted_expert_ids_ptr, num_valid_ids_ptr, out_ptr, w1_scale_ptr, a1_scale_ptr); \
    else if (MPerBlock == 128)                                                                                                                                                                                                                                                                                          \
        ck_moe_stage1_gemm<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 128>(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk, hidden_states_ptr, w1_ptr, w2_ptr, sorted_token_ids_ptr, sorted_expert_ids_ptr, num_valid_ids_ptr, out_ptr, w1_scale_ptr, a1_scale_ptr);

void ck_moe_stage1(torch::Tensor &hidden_states,     // [m, k], input token
                   torch::Tensor &w1,                // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
                   torch::Tensor &w2,                // [expert, dim, inter_dim], pre-shuffle([e, nr, kr, w])
                   torch::Tensor &sorted_token_ids,  // [max_num_tokens_padded]
                   torch::Tensor &sorted_expert_ids, // [max_num_m_blocks]
                   torch::Tensor &num_valid_ids,     // [1]
                   torch::Tensor &out,               // [m * topk, inter_dim]
                   int topk,
                   std::optional<torch::Tensor> w1_scale = std::nullopt, // [e, 1, n], gate(up) scale
                   std::optional<torch::Tensor> a1_scale = std::nullopt, // [m, 1], token scale
                   std::optional<int> block_m = 32)
{
    const at::cuda::OptionalCUDAGuard device_guard(device_of(out));
    at::cuda::getCurrentCUDAStream().stream();
    TORCH_CHECK(hidden_states.dtype() == w1.dtype(),
                "Weights and activations should both be same dtype!");

    TORCH_CHECK(out.dtype() == at::ScalarType::BFloat16 || out.dtype() == at::ScalarType::Half,
                "Out dtype only support BFloat16/Float16!")

    int tokens = hidden_states.size(0);
    int sorted_size = sorted_token_ids.size(0);
    int E = w1.size(0);
    int N = w1.size(1);
    int K = w1.size(2);
    // int max_num_tokens_padded = sorted_token_ids.size(0);
    // int agvtokens_per_expert = max_num_tokens_padded / E;
    int MPerBlock = block_m.value();
    // int M = agvtokens_per_expert < 32 ? 32 : (agvtokens_per_expert < 64 ? 64 : 128);

    void *hidden_states_ptr = hidden_states.data_ptr();
    void *w1_ptr = w1.data_ptr();
    void *w2_ptr = w2.data_ptr();
    void *sorted_token_ids_ptr = sorted_token_ids.data_ptr();
    void *sorted_expert_ids_ptr = sorted_expert_ids.data_ptr();
    void *num_valid_ids_ptr = num_valid_ids.data_ptr();
    void *out_ptr = out.data_ptr();
    void *w1_scale_ptr = w1_scale.has_value() ? w1_scale.value().data_ptr() : nullptr;
    void *a1_scale_ptr = a1_scale.has_value() ? a1_scale.value().data_ptr() : nullptr;

    // BF16
    if (hidden_states.dtype() == at::ScalarType::BFloat16)
    {
        using A0DataType = B16;
        using B0DataType = B16;
        using AccDataType = F32;
        using EDataType = B16;
        using CDEElementOp = TypeCast;
        CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, MPerBlock);
    }
    // FP16
    else if (hidden_states.dtype() == at::ScalarType::Half)
    {
        using A0DataType = F16;
        using B0DataType = F16;
        using AccDataType = F32;
        using EDataType = F16;
        using CDEElementOp = TypeCast;
        CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, MPerBlock);
    }
    // FP8
    else if (hidden_states.dtype() == at::ScalarType::Float8_e4m3fnuz)
    {
        using A0DataType = F8;
        using B0DataType = F8;
        TORCH_CHECK(a1_scale.has_value() && w1_scale.has_value(),
                    "MoE Quant must input scale!");
        TORCH_CHECK(a1_scale.value().dtype() == at::ScalarType::Float,
                    "Scales must be Float dtype!");
        using AccDataType = F32;
        using CDEElementOp = MulABScale;
        if (out.dtype() == at::ScalarType::Half)
        {
            CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, F16, CDEElementOp, MPerBlock);
        }
        else if (out.dtype() == at::ScalarType::BFloat16)
        {
            CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, B16, CDEElementOp, MPerBlock);
        }
    }
    // // I8
    // else if (hidden_states.dtype() == at::ScalarType::Char)
    // {
    //     using A0DataType = I8;
    //     using B0DataType = I8;
    //     TORCH_CHECK(a1_scale.has_value() && w1_scale.has_value(),
    //                 "MoE Quant must input scale!");
    //     TORCH_CHECK(a1_scale.value().dtype() == at::ScalarType::Float,
    //                 "Scales must be Float dtype!");
    //     using AccDataType = I32;
    //     using CDEElementOp = MulABScale;
    //     if (out.dtype() == at::ScalarType::Half)
    //     {
    //         CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, F16, CDEElementOp, MPerBlock);
    //     }
    //     else if (out.dtype() == at::ScalarType::BFloat16)
    //     {
    //         CK_MOE_STAGE1_GEMM_IMPL(A0DataType, B0DataType, AccDataType, B16, CDEElementOp, MPerBlock);
    //     }
    // }
}

#define CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, MPerBlock)                                                                                                                                                                                                                                   \
    if (MPerBlock == 32)                                                                                                                                                                                                                                                                                                                   \
        ck_moe_stage2_gemm<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 32>(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk, inter_states_ptr, w1_ptr, w2_ptr, sorted_token_ids_ptr, sorted_expert_ids_ptr, sorted_weights_ptr, num_valid_ids_ptr, out_ptr, w2_scale_ptr, a2_scale_ptr); \
    else if (MPerBlock == 64)                                                                                                                                                                                                                                                                                                              \
        ck_moe_stage2_gemm<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 64>(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk, inter_states_ptr, w1_ptr, w2_ptr, sorted_token_ids_ptr, sorted_expert_ids_ptr, sorted_weights_ptr, num_valid_ids_ptr, out_ptr, w2_scale_ptr, a2_scale_ptr); \
    else if (MPerBlock == 128)                                                                                                                                                                                                                                                                                                             \
        ck_moe_stage2_gemm<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 128>(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk, inter_states_ptr, w1_ptr, w2_ptr, sorted_token_ids_ptr, sorted_expert_ids_ptr, sorted_weights_ptr, num_valid_ids_ptr, out_ptr, w2_scale_ptr, a2_scale_ptr);

void ck_moe_stage2(torch::Tensor &inter_states,      // [m, k], input token
                   torch::Tensor &w1,                // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
                   torch::Tensor &w2,                // [expert, dim, inter_dim], pre-shuffle([e, nr, kr, w])
                   torch::Tensor &sorted_token_ids,  // [max_num_tokens_padded]
                   torch::Tensor &sorted_expert_ids, // [max_num_m_blocks]
                   torch::Tensor &sorted_weights,    // [max_num_tokens_padded]
                   torch::Tensor &num_valid_ids,     // [1]
                   torch::Tensor &out,               // [max_num_tokens_padded, inter_dim]
                   int topk,
                   std::optional<torch::Tensor> w2_scale = std::nullopt, // [e, 1, n], gate(up) scale
                   std::optional<torch::Tensor> a2_scale = std::nullopt, // [m, 1], token scale
                   std::optional<int> block_m = 32)
{
    TORCH_CHECK(inter_states.dtype() == w2.dtype(),
                "Weights and activations should both be same dtype!");

    TORCH_CHECK(out.dtype() == at::ScalarType::BFloat16 || out.dtype() == at::ScalarType::Half,
                "Out dtype only support BFloat16/Float16!")

    int tokens = inter_states.size(0);
    int sorted_size = sorted_token_ids.size(0);
    int E = w1.size(0);
    int N = w2.size(2);
    int K = w1.size(2);
    // int max_num_tokens_padded = sorted_token_ids.size(0);
    // int agvtokens_per_expert = max_num_tokens_padded / E;
    int MPerBlock = block_m.value();
    // int M = agvtokens_per_expert < 32 ? 32 : (agvtokens_per_expert < 64 ? 64 : 128);
    // std::cout<<"tokens: "<<tokens<<std::endl;
    // std::cout<<"sorted_size: "<<sorted_size<<std::endl;
    // std::cout<<"E: "<<E<<std::endl;
    // std::cout<<"N: "<<N<<std::endl;
    // std::cout<<"K: "<<K<<std::endl;
    // std::cout<<"MPerBlock: "<<MPerBlock<<std::endl;



    void *inter_states_ptr = inter_states.data_ptr();
    void *w1_ptr = w1.data_ptr();
    void *w2_ptr = w2.data_ptr();
    void *sorted_token_ids_ptr = sorted_token_ids.data_ptr();
    void *sorted_expert_ids_ptr = sorted_expert_ids.data_ptr();
    void *sorted_weights_ptr = sorted_weights.data_ptr();
    void *num_valid_ids_ptr = num_valid_ids.data_ptr();
    void *out_ptr = out.data_ptr();
    void *w2_scale_ptr = w2_scale.has_value() ? w2_scale.value().data_ptr() : nullptr;
    void *a2_scale_ptr = a2_scale.has_value() ? a2_scale.value().data_ptr() : nullptr;

    // BF16
    if (inter_states.dtype() == at::ScalarType::BFloat16)
    {
        using A0DataType = B16;
        using B0DataType = B16;
        using AccDataType = F32;
        using EDataType = B16;
        using CDEElementOp = TypeCastExpertWeight;
        CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, MPerBlock);
    }
    // FP16
    else if (inter_states.dtype() == at::ScalarType::Half)
    {
        using A0DataType = F16;
        using B0DataType = F16;
        using AccDataType = F32;
        using EDataType = F16;
        using CDEElementOp = TypeCastExpertWeight;
        CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, MPerBlock);
    }
    // FP8
    else if (inter_states.dtype() == at::ScalarType::Float8_e4m3fnuz)
    {
        using A0DataType = F8;
        using B0DataType = F8;
        TORCH_CHECK(a2_scale.has_value() && w2_scale.has_value(),
                    "MoE Quant must input scale!");
        TORCH_CHECK(a2_scale.value().dtype() == at::ScalarType::Float,
                    "Scales must be Float dtype!");
        using AccDataType = F32;
        using CDEElementOp = MulABScaleExpertWeight;
        if (out.dtype() == at::ScalarType::Half)
        {
            CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, F16, CDEElementOp, MPerBlock);
        }
        else if (out.dtype() == at::ScalarType::BFloat16)
        {
            CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, B16, CDEElementOp, MPerBlock);
        }
    }
    // // I8
    // else if (inter_states.dtype() == at::ScalarType::Char)
    // {
    //     using A0DataType = I8;
    //     using B0DataType = I8;
    //     TORCH_CHECK(a2_scale.has_value() && w2_scale.has_value(),
    //                 "MoE Quant must input scale!");
    //     TORCH_CHECK(a2_scale.value().dtype() == at::ScalarType::Float,
    //                 "Scales must be Float dtype!");
    //     using AccDataType = I32;
    //     using CDEElementOp = MulABScaleExpertWeight;
    //     if (out.dtype() == at::ScalarType::Half)
    //     {
    //         CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, F16, CDEElementOp, MPerBlock);
    //     }
    //     else if (out.dtype() == at::ScalarType::BFloat16)
    //     {
    //         CK_MOE_STAGE2_GEMM_IMPL(A0DataType, B0DataType, AccDataType, B16, CDEElementOp, MPerBlock);
    //     }
    // }
}
