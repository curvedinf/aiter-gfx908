// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include "py_itfs_common.h"
#include "moe_ck_gemm.hpp"

#define CK_MOE_STAGE1_GEMM_IMPL(moe_policy) \
    if (K % (256 / sizeof(A0DataType)) == 0)                                                                    \
    {                                                                                                           \
        ck_moe_stage1_gemm<moe_policy::A0DataType,                                                              \
                           moe_policy::B0DataType,                                                              \
                           moe_policy::AccDataType,                                                             \
                           moe_policy::EDataType,                                                               \
                           moe_policy::CDEElementOp,                                                            \
                           moe_policy::MPerBlock,                                                               \
                           256 / sizeof(A0DataType),                                                            \
                           1,                                                                                   \
                           4,                                                                                   \
                           moe_policy::Nswizzle,                                                                \
                           moe_policy::isPerTensorQuant,                                                        \
                           moe_policy::ActOP>(at::cuda::getCurrentCUDAStream().stream(),                        \
                              tokens,                                                                           \
                              sorted_size,                                                                      \
                              N,                                                                                \
                              K,                                                                                \
                              topk,                                                                             \
                              hidden_states_ptr,                                                                \
                              w1_ptr,                                                                           \
                              w2_ptr,                                                                           \
                              sorted_token_ids_ptr,                                                             \
                              sorted_expert_ids_ptr,                                                            \
                              num_valid_ids_ptr,                                                                \
                              out_ptr,                                                                          \
                              w1_scale_ptr,                                                                     \
                              a1_scale_ptr);                                                                    \
    }                                                                                                           \
    else                                                                                                        \
    {                                                                                                           \
        ck_moe_stage1_gemm<moe_policy::A0DataType,                                                              \
                           moe_policy::B0DataType,                                                              \
                           moe_policy::AccDataType,                                                             \
                           moe_policy::EDataType,                                                               \
                           moe_policy::CDEElementOp,                                                            \
                           moe_policy::MPerBlock,                                                               \
                           128 / sizeof(A0DataType),                                                            \
                           1,                                                                                   \
                           4,                                                                                   \
                           moe_policy::Nswizzle,                                                                \
                           moe_policy::isPerTensorQuant,                                                        \
                           moe_policy::ActOP>(at::cuda::getCurrentCUDAStream().stream(),                        \
                              tokens,                                                                           \
                              sorted_size,                                                                      \
                              N,                                                                                \
                              K,                                                                                \
                              topk,                                                                             \
                              hidden_states_ptr,                                                                \
                              w1_ptr,                                                                           \
                              w2_ptr,                                                                           \
                              sorted_token_ids_ptr,                                                             \
                              sorted_expert_ids_ptr,                                                            \
                              num_valid_ids_ptr,                                                                \
                              out_ptr,                                                                          \
                              w1_scale_ptr,                                                                     \
                              a1_scale_ptr);                                                                    \
    }                                                                                                           

#define CK_MOE_STAGE1_GEMM_IMPL_INT4(A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, Nswizzle, isPerTensorQuant, MPerBlock, ActOP)                                                                            \
ck_moe_stage1_gemm<moe_policy::A0DataType,                                                              \
                   moe_policy::B0DataType,                                                              \
                   moe_policy::AccDataType,                                                             \
                   moe_policy::EDataType,                                                               \
                   moe_policy::CDEElementOp,                                                            \
                   moe_policy::MPerBlock,                                                               \
                   128 / sizeof(A0DataType),                                                            \
                   1,                                                                                   \
                   4,                                                                                   \
                   moe_policy::Nswizzle,                                                                \
                   moe_policy::isPerTensorQuant,                                                        \
                   moe_policy::ActOP>(at::cuda::getCurrentCUDAStream().stream(),                        \
                      tokens,                                                                           \
                      sorted_size,                                                                      \
                      N,                                                                                \
                      K,                                                                                \
                      topk,                                                                             \
                      hidden_states_ptr,                                                                \
                      w1_ptr,                                                                           \
                      w2_ptr,                                                                           \
                      sorted_token_ids_ptr,                                                             \
                      sorted_expert_ids_ptr,                                                            \
                      num_valid_ids_ptr,                                                                \
                      out_ptr,                                                                          \
                      w1_scale_ptr,                                                                     \
                      a1_scale_ptr);                                                                    \

template<typename A0DataType_, typename B0DataType_, typename AccDataType_, typename EDataType_, 
        typename CDEElementOp_, bool Nswizzle_, bool isPerTensorQuant_, int MPerBlock_, int ActOP_>
struct ck_moe_policy 
{
    using A0DataType                         = A0DataType_;
    using B0DataType                         = B0DataType_;
    using AccDataType                        = AccDataType_;
    using EDataType                          = EDataType_;
    using CDEElementOp                       = CDEElementOp_;
    static constexpr bool Nswizzle           = Nswizzle_;
    static constexpr bool isPerTensorQuant   = isPerTensorQuant_;
    static constexpr int MPerBlock           = MPerBlock_;
    static constexpr int ActOP               = ActOP_;
}

struct ck_moe_dispatcher
{
    static constexpr int[] block_m_table {16, 32, 48, 64, 80, 96, 112, 128};
    static constexpr int[] act_op_table  {0, 2};
    static constexpr bool[] bool_table   {false, true};

    template<typename A0DataType_, typename B0DataType_, typename AccDataType_, typename EDataType_, typename CDEElementOp_>
    static constexpr auto dispatch_policy(int block_m, int act_op, bool n_swizzle, bool is_per_tensor_quant)
    {
        constexpr int Block_M = block_m_table[block_m / 32 - 1];
        constexpr int Act_OP = act_op_table[act_op / 2]; // hack here, need remove useless act type @jiaxiwen
        constexpr bool N_Swizzle = bool_table[n_swizzle];
        constexpr bool isPerTensorQuant = bool_table[is_per_tensor_quant];

        return ck_moe_policy<A0DataType_, B0DataType_, AccDataType_, EDataType_, CDEElementOp_, N_Swizzle, isPerTensorQuant, Block_M, Act_OP>{};
    }
}

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
                   std::optional<int> block_m = 32,
                   std::optional<int> ActOP   = 2)
{
    const at::cuda::OptionalCUDAGuard device_guard(device_of(out));
    at::cuda::getCurrentCUDAStream().stream();
    // TORCH_CHECK(hidden_states.dtype() == w1.dtype(),
    //             "Weights and activations should both be same dtype!");

    TORCH_CHECK(out.dtype() == at::ScalarType::BFloat16 || out.dtype() == at::ScalarType::Half,
                "Out dtype only support BFloat16/Float16!")

    int tokens = hidden_states.size(0);
    int sorted_size = sorted_token_ids.size(0);
    int E = w1.size(0);
    int N = w1.size(1) / 2;
    int K = hidden_states.size(-1);
    // int max_num_tokens_padded = sorted_token_ids.size(0);
    // int agvtokens_per_expert = max_num_tokens_padded / E;
    int MPerBlock = block_m.value();
    bool isPerTensorQuant = (!w1_scale.has_value()) || (w1_scale.value().numel() == E);

    // int M = agvtokens_per_expert < 32 ? 32 : (agvtokens_per_expert < 64 ? 64 : 128);

    void *hidden_states_ptr = hidden_states.data_ptr();
    void *w1_ptr = w1.transpose(1, 2).data_ptr();
    void *w2_ptr = w2.data_ptr();
    void *sorted_token_ids_ptr = sorted_token_ids.data_ptr();
    void *sorted_expert_ids_ptr = sorted_expert_ids.data_ptr();
    void *num_valid_ids_ptr = num_valid_ids.data_ptr();
    void *out_ptr = out.data_ptr();
    void *w1_scale_ptr = w1_scale.has_value() ? w1_scale.value().transpose(0, 1).data_ptr() : nullptr;
    void *a1_scale_ptr = a1_scale.has_value() ? a1_scale.value().data_ptr() : nullptr;

    // BF16
    if (hidden_states.dtype() == at::ScalarType::BFloat16)
    {
        using A0DataType = B16;
        using B0DataType = B16;
        using AccDataType = F32;
        using EDataType = B16;
        using CDEElementOp = TypeCast;
        const bool Nswizzle = false;

        constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp>(MPerBlock, ActOP, Nswizzle, isPerTensorQuant);
        CK_MOE_STAGE1_GEMM_IMPL(policy);
    }
    // FP16
    else if (hidden_states.dtype() == at::ScalarType::Half)
    {
        using A0DataType = F16;
        using B0DataType = F16;
        using AccDataType = F32;
        using EDataType = F16;
        using CDEElementOp = TypeCast;
        const bool Nswizzle = false;
        
        constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp>(MPerBlock, ActOP, Nswizzle, isPerTensorQuant);
        CK_MOE_STAGE1_GEMM_IMPL(policy);
    }
    // FP8 Wint4
    else if (hidden_states.dtype() == at::ScalarType::Float8_e4m3fnuz && w1.dtype() == at::ScalarType::UInt32)
    {
        using A0DataType = F8;
        using B0DataType = I4;
        const bool Nswizzle = false;
        TORCH_CHECK(a1_scale.has_value() && w1_scale.has_value(),
                    "MoE Quant must input scale!");
        TORCH_CHECK(a1_scale.value().dtype() == at::ScalarType::Float,
                    "Scales must be Float dtype!");
        using AccDataType = F32;
        using CDEElementOp = MulABScaleWint4;
        if (out.dtype() == at::ScalarType::Half)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, F16, CDEElementOp>(MPerBlock, ActOP, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE1_GEMM_IMPL_INT4(policy);
        }
        else if (out.dtype() == at::ScalarType::BFloat16)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, B16, CDEElementOp>(MPerBlock, ActOP, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE1_GEMM_IMPL_INT4(policy);        
        }
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
        const bool Nswizzle = false;
        if (out.dtype() == at::ScalarType::Half)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, F16, CDEElementOp>(MPerBlock, ActOP, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE1_GEMM_IMPL(policy);
        }
        else if (out.dtype() == at::ScalarType::BFloat16)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, B16, CDEElementOp>(MPerBlock, ActOP, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE1_GEMM_IMPL(policy);        
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
#define CK_MOE_STAGE2_GEMM_IMPL(moe_policy)                                                                                                                                                                                                                                                       \                                                                                                                                                                                                                                                                                                                                                          \
    if (K % (256 / sizeof(A0DataType)) == 0)                                                                                                                                                                                                                                                                                                                                                             \
    {                                                                                                                                                                                                                                                                                                                                                               \
        ck_moe_stage2_gemm<moe_policy::A0DataType,                                                              \
                           moe_policy::B0DataType,                                                              \
                           moe_policy::AccDataType,                                                             \
                           moe_policy::EDataType,                                                               \
                           moe_policy::CDEElementOp,                                                            \
                           moe_policy::MPerBlock,                                                               \
                           256 / sizeof(A0DataType),                                                            \
                           1,                                                                                   \
                           4,                                                                                   \
                           moe_policy::Nswizzle,                                                                \
                           moe_policy::isPerTensorQuant                                                        \
                           >(at::cuda::getCurrentCUDAStream().stream(),                                        \
                                tokens,                                                                           \
                                sorted_size,                                                                      \
                                N,                                                                                \
                                K,                                                                                \
                                topk,                                                                             \
                                hidden_states_ptr,                                                                \
                                w1_ptr,                                                                           \
                                w2_ptr,                                                                           \
                                sorted_token_ids_ptr,                                                             \
                                sorted_expert_ids_ptr,                                                            \
                                num_valid_ids_ptr,                                                                \
                                out_ptr,                                                                          \
                                w1_scale_ptr,                                                                     \
                                a1_scale_ptr);                                                                    \
        }                                                                                                                                                                                                                                                                                                                                                               \
    else                                                                                                                                                                                                                                                                                                                                                               \
    {                                                                                                                                                                                                                                                                                                                                                               \
        ck_moe_stage2_gemm<moe_policy::A0DataType,                                                              \
                           moe_policy::B0DataType,                                                              \
                           moe_policy::AccDataType,                                                             \
                           moe_policy::EDataType,                                                               \
                           moe_policy::CDEElementOp,                                                            \
                           moe_policy::MPerBlock,                                                               \
                           128 / sizeof(A0DataType),                                                            \
                           1,                                                                                   \
                           4,                                                                                   \
                           moe_policy::Nswizzle,                                                                \
                           moe_policy::isPerTensorQuant                                                        \
                           >(at::cuda::getCurrentCUDAStream().stream(),                                        \
                                tokens,                                                                           \
                                sorted_size,                                                                      \
                                N,                                                                                \
                                K,                                                                                \
                                topk,                                                                             \
                                hidden_states_ptr,                                                                \
                                w1_ptr,                                                                           \
                                w2_ptr,                                                                           \
                                sorted_token_ids_ptr,                                                             \
                                sorted_expert_ids_ptr,                                                            \
                                num_valid_ids_ptr,                                                                \
                                out_ptr,                                                                          \
                                w1_scale_ptr,                                                                     \
                                a1_scale_ptr);                                                                    \
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                \

#define CK_MOE_STAGE2_GEMM_IMPL_INT4(moe_policy)                                                                                                                                                                                                                                                  \
    ck_moe_stage2_gemm<moe_policy::A0DataType,                                                              \
                        moe_policy::B0DataType,                                                              \
                        moe_policy::AccDataType,                                                             \
                        moe_policy::EDataType,                                                               \
                        moe_policy::CDEElementOp,                                                            \
                        moe_policy::MPerBlock,                                                               \
                        128 / sizeof(A0DataType),                                                            \
                        1,                                                                                   \
                        4,                                                                                   \
                        moe_policy::Nswizzle,                                                                \
                        moe_policy::isPerTensorQuant                                                        \
                        >(at::cuda::getCurrentCUDAStream().stream(),                                        \
                            tokens,                                                                           \
                            sorted_size,                                                                      \
                            N,                                                                                \
                            K,                                                                                \
                            topk,                                                                             \
                            hidden_states_ptr,                                                                \
                            w1_ptr,                                                                           \
                            w2_ptr,                                                                           \
                            sorted_token_ids_ptr,                                                             \
                            sorted_expert_ids_ptr,                                                            \
                            num_valid_ids_ptr,                                                                \
                            out_ptr,                                                                          \
                            w1_scale_ptr,                                                                     \
                            a1_scale_ptr);

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
    bool isPerTensorQuant = (!w2_scale.has_value()) || (w2_scale.value().numel() == E);

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
        const bool Nswizzle = false;

        constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp>(MPerBlock, 0, Nswizzle, isPerTensorQuant);
        CK_MOE_STAGE2_GEMM_IMPL(policy);
    }
    // FP16
    else if (inter_states.dtype() == at::ScalarType::Half)
    {
        using A0DataType = F16;
        using B0DataType = F16;
        using AccDataType = F32;
        using EDataType = F16;
        using CDEElementOp = TypeCastExpertWeight;
        const bool Nswizzle = false;

        constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp>(MPerBlock, 0, Nswizzle, isPerTensorQuant);
        CK_MOE_STAGE2_GEMM_IMPL(policy);
    }
    // FP8 wint4
    else if (inter_states.dtype() == at::ScalarType::Float8_e4m3fnuz && w1.dtype() == at::ScalarType::UInt32)
    {
        using A0DataType = F8;
        using B0DataType = I4;
        const bool Nswizzle = false;
        TORCH_CHECK(a2_scale.has_value() && w2_scale.has_value(),
                    "MoE Quant must input scale!");
        TORCH_CHECK(a2_scale.value().dtype() == at::ScalarType::Float,
                    "Scales must be Float dtype!");
        using AccDataType = F32;
        using CDEElementOp = MulABScaleExpertWeightWin4;
        if (out.dtype() == at::ScalarType::Half)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, F16, CDEElementOp>(MPerBlock, 0, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE2_GEMM_IMPL_INT4(policy);
        }
        else if (out.dtype() == at::ScalarType::BFloat16)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, B16, CDEElementOp>(MPerBlock, 0, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE2_GEMM_IMPL_INT4(policy);        
        }
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
        using CDEElementOp = TypeCastExpertWeight;
        const bool Nswizzle = false;
        if (out.dtype() == at::ScalarType::Half)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, F16, CDEElementOp>(MPerBlock, 0, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE2_GEMM_IMPL(policy);
        }
        else if (out.dtype() == at::ScalarType::BFloat16)
        {
            constexpr auto policy = ck_moe_dispatcher::dispatch_policy<A0DataType, B0DataType, AccDataType, B16, CDEElementOp>(MPerBlock, 0, Nswizzle, isPerTensorQuant);
            CK_MOE_STAGE2_GEMM_IMPL(policy);
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
