// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#pragma once
#include "gemm_moe_2stages_blockscale.h"
#include <iostream>


//template <typename A0DataType, typename B0DataType, typename AccDataType, typename EDataType, typename CDEElementOp, int BLOCKSIZE, int MPerBlock, int NPerBlock, int KPerBlock, int MWaves, int NWaves, int MNPerXDL, bool Nswizzle, bool PerTensorQuant>
//void moe_stage1_gemm_blockscale(const hipStream_t &stream, int tokens, int sorted_size, int N, int K,
//                                int topk,
//                                void *&hidden_states,           // [m, k], input token
//                                void *&w1,                      // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
//                                void *&w2,                      // [expert, dim, inter_dim], pre-shuffle([e, nr, kr, w])
//                                void *&sorted_token_ids,        // [max_num_tokens_padded]
//                                void *&sorted_expert_ids,       // [max_num_m_blocks]
//                                void *&sorted_weights,          // [null for stage1]
//                                void *&num_valid_ids,           // [1]
//                                void *&out,                     // [max_num_tokens_padded, inter_dim]
//                               QuantType quant_type,
//                                std::optional<void *> w1_scale, // [e, 1, n], gate(up) scale                            
//                                std::optional<void *> a1_scale  // [m, 1], token scale
//)
//{
//    // ~~~~~~~~~~~~~~~~~~~~~~~~following start with ck things
//    // using A0DataType       = FP8;
//    using A1DataType = F32; // input scale
//    // using B0DataType       = FP8;
//    using B1DataType = F32; // input scale
//    ck::index_t StrideA = K;
//    ck::index_t StrideB = K;
//    ck::index_t StrideE = N;
//
//    using CShuffleDataType = F32;
//    using DsDataType = ck::Tuple<>;
//
//    using A0Layout = Row;
//    using B0Layout = Col;
//    using D0Layout = Row;
//    using D1Layout = Col;
//    using DsLayout = ck::Tuple<>;
//    using ELayout = Row;
//
//    using PassThrough = ck::tensor_operation::element_wise::PassThrough;
//    using AElementOp = PassThrough;
//    using BElementOp = PassThrough;
//    // using CDEElementOp = PassThrough;
//
//    static constexpr auto GemmSpec = ck::tensor_operation::device::GemmSpecialization::Default;
//    static constexpr ck::index_t Scale_Block_M = 1;
//    static constexpr ck::index_t Scale_Block_N = 128;
//    static constexpr ck::index_t Scale_Block_K = 128;
//
//    // static constexpr ck::index_t MPerBlock = 128; //vari
//    // static constexpr ck::index_t MNPerXDL = 32;//vari
//    // static constexpr ck::index_t BLOCKSIZE = 256;//vari
//    // static constexpr ck::index_t NPerBlock = 128;//vari
//    // static constexpr ck::index_t WAVES = BLOCKSIZE / 64;
//    // static constexpr ck::index_t MWaves = 2;//vari
//    // static constexpr ck::index_t NWaves = WAVES / MWaves;//vari
//    // static constexpr ck::index_t MXDLPerWave = MPerBlock / (MNPerXDL * MWaves);
//    // static constexpr ck::index_t NXDLPerWave = NPerBlock / (MNPerXDL * NWaves);
//    // static constexpr ck::index_t CShuffleMXDLPerWave = ck::is_same_v<B0DataType, I4> ? 1 : 2;
//    // static constexpr ck::index_t CShuffleNXDLPerWave = ck::is_same_v<B0DataType, I4> ? 1 : 2;
//    //// static constexpr ck::index_t KPerBlock = ck::is_same_v<B0DataType, I4> ? 128 : 256 / sizeof(A0DataType);//vari
//    // static constexpr ck::index_t AK1 = 16 / sizeof(A0DataType);
//    // static constexpr ck::index_t BK1 = ck::is_same_v<B0DataType, I4> ? 32 : 16 / sizeof(B0DataType);
//    // static constexpr ck::index_t EVec = 16 / sizeof(EDataType);
//    // static constexpr ck::index_t K0_A = KPerBlock / AK1;
//    // static constexpr ck::index_t K0_B = KPerBlock / BK1;
//    // static constexpr ck::index_t K0_M_A = BLOCKSIZE / K0_A;
//    // static constexpr ck::index_t K0_N_B = BLOCKSIZE / K0_B;
//    // static constexpr ck::index_t D0Vec = 1;
//    // static constexpr ck::index_t D1Vec = PerTensorQuant ? 1 : EVec;
//    using DeviceOpInstance = ck::tensor_operation::device::DeviceGemmMultiD_ABScale_Xdl_CShuffle_V3
//        // clang-format off
//         <Row, Col, DsLayout, ELayout,
//          A0DataType, A1DataType, B0DataType, B1DataType, DsDataType, EDataType, AccDataType, CShuffleDataType, 
//          AElementOp,  BElementOp, CDEElementOp, GemmSpec,
//          256, Scale_Block_M, Scale_Block_N, Scale_Block_K,
//          16, 128,
//          256, 16, 16,
//          16,   16,
//          1,    2,
//          S<16, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 16, 16, 0,
//          S<16, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 16, 16, 0,
//          1,    2,  S<1, 16, 1, 16>,  S<8>,
//          ck::BlockGemmPipelineScheduler::Intrawave, ck::BlockGemmPipelineVersion::v1, F8>;
//    // clang-format on
//
//    auto a_element_op = AElementOp{};
//    auto b_element_op = BElementOp{};
//    auto cde_element_op = CDEElementOp{};
//
//    constexpr ck::index_t NumDTensor = DsDataType::Size();
//
//    // do GEMM
//    auto device_op = DeviceOpInstance{};
//    auto invoker = device_op.MakeInvoker();
//    auto argument = device_op.MakeArgument(hidden_states,
//                                           w1,
//                                           std::array<const void *, NumDTensor>{},
//                                           out,
//                                           tokens,
//                                           N,
//                                           K,
//                                           StrideA,
//                                           StrideB,
//                                           std::array<ck::index_t, NumDTensor>{},
//                                           StrideE,
//                                           a1_scale,
//                                           w1_scale,
//                                           a_element_op,
//                                           b_element_op,
//                                           cde_element_op);
//
//    if (!device_op.IsSupportedArgument(argument))
//    {
//        throw std::runtime_error(
//            "wrong! device_gemm with the specified compilation parameters does "
//            "not support this GEMM problem");
//    }
//
//    invoker.Run(argument, StreamConfig{stream});
//}
//
//#define CK_MOE_STAGE1_GEMM_BLOCKSCALE_DEFINE(BLOCKSIZE, MPerBlock, NPerBlock, KPerBlock, MWaves, NWaves, MNPerXDL)                                                                                          \
//    template void moe_stage1_gemm_blockscale<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, BLOCKSIZE, MPerBlock, NPerBlock, KPerBlock, MWaves, NWaves, MNPerXDL, Nswizzle, PerTensorQuant>( \
//        const hipStream_t &stream,                                                                                                                                                                          \
//        int tokens, int sorted_size, int N, int K,                                                                                                                                                          \
//        int topk,                                                                                                                                                                                           \
//        void *&hidden_states,                                                                                                                                                                               \
//        void *&w1,                                                                                                                                                                                          \
//        void *&w2,                                                                                                                                                                                          \
//        void *&sorted_token_ids,                                                                                                                                                                            \
//        void *&sorted_expert_ids,                                                                                                                                                                           \
//        void *&sorted_weights,                                                                                                                                                                              \
//        void *&num_valid_ids,                                                                                                                                                                               \
//        void *&out,                                                                                                                                                                                         \
//        QuantType quant_type,                                                                                                                                                                               \                                                                                                                                                                               \
//        std::optional<void *> w1_scale,                                                                                                                                                                     \
//        std::optional<void *> a1_scale);
//


template <typename A0DataType, typename B0DataType, typename AccDataType, typename EDataType, typename CDEElementOp, int BLOCKSIZE, int MPerBlock, int NPerBlock, int KPerBlock, int MWaves, int NWaves, int MNPerXDL, bool Nswizzle, bool PerTensorQuant>
void moe_stage2_gemm_blockscale(const hipStream_t &stream, int tokens, int sorted_size, int N, int K,
    int topk,
    void *&inter_states,            // [max_num_tokens_padded, k], input token
    void *&w1,                      // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
    void *&w2,                      // [expert, dim, inter_dim], pre-shuffle([e, nr, kr, w])
    void *&sorted_token_ids,        // [max_num_tokens_padded]
    void *&sorted_expert_ids,       // [max_num_m_blocks]
    void *&sorted_weights,          // [max_num_tokens_padded]
    void *&num_valid_ids,           // [1]
    void *&out,                     // [m, out_dim]
    QuantType quant_type,
    std::optional<void *> w2_scale, // [e, 1, n], gate(up) scale
    std::optional<void *> a2_scale  // [max_num_tokens_padded, 1], token scale
)      
{
    // ~~~~~~~~~~~~~~~~~~~~~~~~following start with ck things
    //using A0DataType       = FP8;
    using A1DataType       = F32; // input scale
    //using B0DataType       = FP8;
    using B1DataType       = F32;// input scale
    ck::index_t StrideA = K;
    ck::index_t StrideB = K;
    ck::index_t StrideE = N;
    ck::index_t KBatch = 1;

    using CShuffleDataType = F32;
    using D2DataType       = F32;
    using DsDataType       = ck::Tuple<D2DataType>;

    using A0Layout = Row;
    using B0Layout = Col;
    using ELayout = Row;
    using D0Layout = Row;
    using D1Layout = Col;
    using D2Layout = ELayout;
    using DsLayout = ck::Tuple<D2Layout>;

    using PassThrough = ck::tensor_operation::element_wise::PassThrough;
    using AElementOp = PassThrough;
    using BElementOp = PassThrough;
    //using CDEElementOp = MulABScaleExpertWeight;

    static constexpr auto GemmSpec = ck::tensor_operation::device::GemmSpecialization::Default;
    static constexpr ck::index_t Scale_Block_M = 1;
    static constexpr ck::index_t Scale_Block_N = 128;
    static constexpr ck::index_t Scale_Block_K = 128;
    constexpr ck::index_t NumDTensor = DsDataType::Size();
    constexpr auto StrideDs          = std::array<ck::index_t, NumDTensor>{0};
    static constexpr ck::index_t MXDLPerWave = MPerBlock / (MNPerXDL * MWaves);
    static constexpr ck::index_t NXDLPerWave = NPerBlock / (MNPerXDL * NWaves);
    static constexpr ck::index_t CShuffleMXDLPerWave = ck::is_same_v<B0DataType, I4> ? 1 : 2;
    static constexpr ck::index_t CShuffleNXDLPerWave = ck::is_same_v<B0DataType, I4> ? 1 : 2;
    static constexpr ck::index_t AK1 = 16 / sizeof(A0DataType);
    static constexpr ck::index_t BK1 = ck::is_same_v<B0DataType, I4> ? 32 : 16 / sizeof(B0DataType);
    static constexpr ck::index_t EVec = 16 / sizeof(EDataType);
    static constexpr ck::index_t K0_A = KPerBlock / AK1;
    static constexpr ck::index_t K0_B = KPerBlock / BK1;
    static constexpr ck::index_t K0_M_A = BLOCKSIZE / K0_A;
    static constexpr ck::index_t K0_N_B = BLOCKSIZE / K0_B;
    static constexpr ck::index_t D0Vec = 1;
    static constexpr ck::index_t D1Vec = PerTensorQuant ? 1 : EVec;
    using DeviceOpInstance = ck::tensor_operation::device::DeviceMoeGemmBlockScale<
                   Row, Col, DsLayout, ELayout,
                   A0DataType, A1DataType, B0DataType, B1DataType, DsDataType, EDataType, AccDataType, CShuffleDataType,
                   AElementOp,  BElementOp, CDEElementOp,   GemmSpec,   
                   256,  Scale_Block_M, Scale_Block_N, Scale_Block_K,
                   MPerBlock,   128,    128,
                   AK1,   BK1,
                   MNPerXDL,   MNPerXDL,
                   MXDLPerWave,    NXDLPerWave,
                   S<K0_A, K0_M_A, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, AK1, AK1, 0,
                   S<K0_B, K0_N_B, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, BK1, BK1, 0,
                   CShuffleMXDLPerWave,    CShuffleNXDLPerWave,   S<1, 32, 1, 8>, S<EVec, D0Vec, D1Vec>,
                   ck::BlockGemmPipelineScheduler::Intrawave, ck::BlockGemmPipelineVersion::v3, false, false, A0DataType>;


    auto a_element_op = AElementOp{};
    auto b_element_op = BElementOp{};
    auto cde_element_op = CDEElementOp{};

    // do GEMM
    auto device_op = DeviceOpInstance{};
    auto invoker   = device_op.MakeInvoker();               


    const void* a2_scale_ptr = *a2_scale; 
    const void* w2_scale_ptr = *w2_scale;  

    
    auto argument =
        device_op.MakeArgument(sorted_token_ids,
                               sorted_expert_ids,
                               num_valid_ids,
                               inter_states,
                               w2,
                               std::array<const void *, NumDTensor>{sorted_weights},
                               out,
                               tokens,
                               topk,
                               sorted_size,
                               N,
                               K,
                               StrideA,
                               StrideB,
                               StrideDs,
                               StrideE,
                               a2_scale_ptr,
                               w2_scale_ptr,
                               KBatch,
                               a_element_op,
                               b_element_op,
                               cde_element_op);

    if (!device_op.IsSupportedArgument(argument))
    {
        throw std::runtime_error(
            "wrong! device_gemm with the specified compilation parameters does "
            "not support this GEMM problem");
    }
    invoker.Run(argument, StreamConfig{stream});
}                

#define CK_MOE_STAGE2_GEMM_BLOCKSCALE_DEFINE(BLOCKSIZE, MPerBlock, NPerBlock, KPerBlock, MWaves, NWaves, MNPerXDL)                                                                                          \
    template void moe_stage2_gemm_blockscale<A0DataType, B0DataType, AccDataType, EDataType, CDEElementOp, BLOCKSIZE, MPerBlock, NPerBlock, KPerBlock, MWaves, NWaves, MNPerXDL, Nswizzle, PerTensorQuant>( \
        const hipStream_t &stream,                                                                                                                                   \
        int tokens, int sorted_size, int N, int K,                                                                                                                   \
        int topk,                                                                                                                                                    \
        void *&inter_states,                                                                                                                                         \
        void *&w1,                                                                                                                                                   \
        void *&w2,                                                                                                                                                   \
        void *&sorted_token_ids,                                                                                                                                     \
        void *&sorted_expert_ids,                                                                                                                                    \
        void *&sorted_weights,                                                                                                                                       \
        void *&num_valid_ids,                                                                                                                                        \
        void *&out,                                                                                                                                                  \
        QuantType quant_type,                                                                                                                                        \
        std::optional<void *> w2_scale,                                                                                                                              \
        std::optional<void *> a2_scale);  
