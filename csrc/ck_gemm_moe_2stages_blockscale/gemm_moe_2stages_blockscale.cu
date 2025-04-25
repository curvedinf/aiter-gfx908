// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include "gemm_moe_2stages_blockscale_manifest.h"
#include "gemm_moe_2stages_blockscale_lookup.h"
#include "gemm_moe_2stages_blockscale.h"
#include <cmath>

std::string to_string(QuantType type)
{
    switch (type)
    {
    case QuantType::No:
        return "No quantization";
    case QuantType::per_Tensor:
        return "Per-tensor quantization";
    case QuantType::per_Token:
        return "Per-token quantization";
    case QuantType::per_1x128:
        return "Per-1x128 quantization";
    case QuantType::per_128x128:
        return "Per-128x128 quantization";
    default:
        return "Unknown quantization type";
    }
}

using MoeKernel = std::function<
    void(const hipStream_t &stream, int, int, int, int,
         int,
         void *&,
         void *&,
         void *&,
         void *&,
         void *&,
         void *&,
         void *&,
         void *&,
         QuantType,
         std::optional<void *>,
         std::optional<void *>)>;

struct FMoe2StageCKConfig
{
    std::string name;
    // typename inputtype,;
    // typename w1type;
    // int block_m;
    // int stage;
};
using MoeKernelMap = std::unordered_map<std::string, MoeKernel>;

MoeKernel moe_heuristics_dispatch(torch::ScalarType dtype, torch::ScalarType outtype, torch::ScalarType q_dtype, torch::ScalarType wq_dtype, QuantType q_type, int stage, int block_m)
{
    if (stage == 1)
    {
        TORCH_CHECK(false, "Unsupported STAGE1 GEMM FOR BLOCKSCALE");
    }
    else // moe stage2
    {
        if (q_type == QuantType::per_1x128)
        {
            if (q_dtype == at::ScalarType::Float8_e4m3fnuz && outtype == at::ScalarType::BFloat16)
            {
                using A0DataType = F8;
                using B0DataType = F8;
                using AccDataType = F32;
                using EDataType = B16;
                using CDEElementOp = MulABScaleExpertWeight;
                const bool Nswizzle = false;
                return moe_stage2_gemm_blockscale<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, 256, 128, 128, 128, 2, 2, 16, Nswizzle, false>;
            }
            else
            {
                    TORCH_CHECK(false, "Unsupported EDatatype:", torch::toString(dtype));
            }
        }
        else
        {
            TORCH_CHECK(false, "Unsupported QuantType:", to_string(q_type));
        }
    }
}

MoeKernel moe_dispatch(torch::ScalarType dtype, torch::ScalarType outtype, torch::ScalarType q_dtype, torch::ScalarType wq_dtype, QuantType q_type, int stage, int block_m, std::string &kernelName)
{
    // For a given shape, either find the best kernel via lookup or heuristic.
    static const auto lookup = []
    {
        return MoeKernelMap{GENERATE_LOOKUP_TABLE()};
    }();

    auto it = lookup.find(kernelName);

    // If we found an optimal kernel, use it.
    if (it != lookup.end())
    {
        std::cout << "[aiter] found CK kernel : " << kernelName << std::endl;
        return it->second;
    }
    std::cerr << "[aiter] CK kernel not found: " << kernelName << std::endl;

    // Otherwise, use heuristics.
    return moe_heuristics_dispatch(dtype, outtype, q_dtype, wq_dtype, q_type, stage, block_m);
}

// API for user aiter.moe_stage2_blockscale(...)

void moe_stage2_blockscale(torch::Tensor &inter_states,      // [m, k], input token
                           torch::Tensor &w1,                // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
                           torch::Tensor &w2,                // [expert, dim, inter_dim], pre-shuffle([e, nr, kr, w])
                           torch::Tensor &sorted_token_ids,  // [max_num_tokens_padded]
                           torch::Tensor &sorted_expert_ids, // [max_num_m_blocks]
                           torch::Tensor &sorted_weights,    // [max_num_tokens_padded]
                           torch::Tensor &num_valid_ids,     // [1]
                           torch::Tensor &out,               // [max_num_tokens_padded, inter_dim]
                           int topk,
                           std::string &kernelName,
                           QuantType quant_type = QuantType::No,
                           std::optional<torch::Tensor> w2_scale = std::nullopt, // [e, 1, n], gate(up) scale
                           std::optional<torch::Tensor> a2_scale = std::nullopt, // [m, 1], token scale
                           std::optional<int> block_m = 32)
{
    // TORCH_CHECK(inter_states.dtype() == w2.dtype(),
    //             "Weights and activations should both be same dtype!");
    //
    TORCH_CHECK(out.dtype() == at::ScalarType::BFloat16 || out.dtype() == at::ScalarType::Half,
                "Out dtype only support BFloat16/Float16!")

    int tokens = inter_states.size(0);
    int sorted_size = sorted_token_ids.size(0);
    int E = w1.size(0);
    int N = w2.size(1);
    int K = inter_states.size(-1);
    // int max_num_tokens_padded = sorted_token_ids.size(0);
    // int agvtokens_per_expert = max_num_tokens_padded / E;
    int MPerBlock = block_m.value();
    // int M = agvtokens_per_expert < 32 ? 32 : (agvtokens_per_expert < 64 ? 64 : 128);
    //bool isPerTensorQuant = (!w2_scale.has_value()) || (w2_scale.value().numel() == E);
    //QuantType q_type = QuantType::per_1x128;

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
    if (!inter_states_ptr || !w1_ptr || !w2_ptr || !sorted_token_ids_ptr || !sorted_expert_ids_ptr || !num_valid_ids_ptr || !out_ptr)
    {
        std::cerr << "detect null ptr ！" << std::endl;
        return;
    }
    moe_dispatch(inter_states.dtype().toScalarType(), out.dtype().toScalarType(), w1.dtype().toScalarType(), w2.dtype().toScalarType(), quant_type, 2, MPerBlock, kernelName)(at::cuda::getCurrentCUDAStream().stream(), tokens, sorted_size, N, K, topk,
                                                                                                                                                                          inter_states_ptr,
                                                                                                                                                                          w1_ptr,
                                                                                                                                                                          w2_ptr,
                                                                                                                                                                          sorted_token_ids_ptr,
                                                                                                                                                                          sorted_expert_ids_ptr,
                                                                                                                                                                          sorted_weights_ptr,
                                                                                                                                                                          num_valid_ids_ptr,
                                                                                                                                                                          out_ptr,
                                                                                                                                                                          quant_type,
                                                                                                                                                                          w2_scale_ptr,
                                                                                                                                                                          a2_scale_ptr);
}