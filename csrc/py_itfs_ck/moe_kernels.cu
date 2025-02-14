// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include "py_itfs_common.h"

#include "fused_moe.hpp"
#include "ck/ck.hpp"
#include "ck/tensor_operation/gpu/device/gemm_specialization.hpp"
#include "ck/tensor_operation/gpu/device/impl/device_moe_gemm.hpp"
#include "ck/tensor_operation/gpu/element/element_wise_operation.hpp"
#include "ck/tensor_operation/gpu/element/unary_element_wise_operation.hpp"

#include "ck/library/utility/device_memory.hpp"
#include "ck/library/utility/host_tensor.hpp"
#include "ck/library/utility/host_tensor_generator.hpp"
#include "ck/library/utility/literals.hpp"
#include "ck/library/reference_tensor_operation/cpu/reference_moe_gemm.hpp"
#include "ck/library/utility/check_err.hpp"

#include "ck/utility/blkgemmpipe_scheduler.hpp"

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
    auto num_tokens_post_pad = torch::empty({1}, torch::TensorOptions().dtype(torch::kInt32).device(device));
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
        activation,
        gate_only,
        fused_quant,
        expert_mask.has_value(), 
    };

    fused_moe_args args{hidden_states.data_ptr(),
                        a1_scale.has_value() ? a1_scale.value().data_ptr() : nullptr,
                        w1.data_ptr(),
                        w2.data_ptr(),
                        w1_scale.has_value() ? w1_scale.value().data_ptr() : nullptr,
                        w2_scale.has_value() ? w2_scale.value().data_ptr() : nullptr,
                        a2_scale.has_value() ? a2_scale.value().data_ptr() : nullptr,
                        expert_mask.has_value() ? expert_mask.value().data_ptr() : nullptr, 
                        out.data_ptr(),

                        topk_ids.data_ptr(),
                        topk_weights.data_ptr(),
                        sorted_ids.data_ptr(),
                        sorted_weights.data_ptr(),
                        sorted_expert_ids.data_ptr(),
                        num_tokens_post_pad.data_ptr(),

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

template <ck::index_t... Is>
using S = ck::Sequence<Is...>;
using F16 = ck::half_t;
using B16 = ck::bhalf_t;
using F32 = float;

using Row = ck::tensor_layout::gemm::RowMajor;
using Col = ck::tensor_layout::gemm::ColumnMajor;

using A0DataType = F16;
using B0DataType = F16;
using AccDataType = F32;
using CShuffleDataType = F32;
using D0DataType = F32;
using D1DataType = F32;
using DsDataType = ck::Tuple<D0DataType, D1DataType>;
using EDataType = F16;

using A0Layout = Row;
using B0Layout = Col;
using D0Layout = Row;
using D1Layout = Col;
using DsLayout = ck::Tuple<D0Layout, D1Layout>;
using ELayout = Row;
struct MulABScale
{
    template <typename E, typename C, typename D0, typename D1>
    __host__ __device__ constexpr void
    operator()(E &e, const C &c, const D0 &d0, const D1 &d1) const;

    template <>
    __host__ __device__ constexpr void operator()<EDataType, float, float, float>(EDataType &e,
                                                                                  const float &c,
                                                                                  const float &d0,
                                                                                  const float &d1) const
    {
        e = ck::type_convert<EDataType>(c * d1 * d0);
    }
};
struct TypeCast
{
    template <typename E, typename C, typename D0, typename D1>
    __host__ __device__ constexpr void
    operator()(E &e, const C &c, const D0 &d0, const D1 &d1) const;

    template <>
    __host__ __device__ constexpr void operator()<F16, float, float, float>(F16 &e, const float &c,
                                                                            const float &d0,
                                                                            const float &d1) const
    {
        // const float x0_f = c * d0 * d1;
        const float x0_f = c;
        e = ck::type_convert<F16>(x0_f);
    }

    template <>
    __host__ __device__ constexpr void operator()<B16, float, float, float>(B16 &e, const float &c,
                                                                            const float &d0,
                                                                            const float &d1) const
    {
        // const float x0_f = c * d0 * d1;
        const float x0_f = c;
        e = ck::type_convert<B16>(x0_f);
    }
};

void ck_moe_stage1_impl(int N, int K,
                        int tokens,
                        int sorted_size,
                        void *sorted_token_ids_ptr,
                        void *sorted_expert_ids_ptr,
                        void *num_valid_ids_ptr,
                        void *hidden_states_ptr,
                        void *w1_ptr,
                        void *a1_scale_ptr,
                        void *w1_scale_ptr,
                        void *out_ptr)
{
    ck::index_t StrideA = K;
    ck::index_t StrideB = K;
    ck::index_t StrideE = N;
    constexpr ck::index_t NumDTensor = DsDataType::Size();
    constexpr auto StrideDs = std::array<ck::index_t, NumDTensor>{0, 0};

    ck::index_t KBatch = 1;
    using PassThrough = ck::tensor_operation::element_wise::PassThrough;

    using AElementOp = PassThrough;
    using BElementOp = PassThrough;
    using CDEElementOp = TypeCast;

    static constexpr auto GemmSpec = ck::tensor_operation::device::GemmSpecialization::Default;
    static constexpr ck::index_t MPerBlock = 128;
    static constexpr ck::index_t MNPerXDL = 32;
    static constexpr ck::index_t CShuffleMXDLPerWave = MPerBlock / 32;
    static constexpr ck::index_t KPerBlock = 256 / sizeof(A0DataType);
    static constexpr ck::index_t MXDLPerWave = MPerBlock / 32; // todo fix this constraint
    static constexpr ck::index_t AK1 = 16 / sizeof(A0DataType);
    static constexpr ck::index_t BK1 = 16 / sizeof(B0DataType);
    static constexpr ck::index_t EVec = 16 / sizeof(EDataType);
    static constexpr ck::index_t D0Vec = 1;
    static constexpr ck::index_t D1Vec = 1;
    // using DeviceOpInstance = ck::tensor_operation::device::DeviceGemmMultiD_Xdl_CShuffle_V3
    using DeviceOpInstance = ck::tensor_operation::device::DeviceMoeGemm
        // clang-format off
///######|  ALayout|  BLayout| DsLayout| ELayout|      AData|      BData|     DsData|     EData|     AccData|         CShuffle|           A|           B|          CDE|           GEMM| Block|  MPer|  NPer|  KPer| AK1| BK1| MPer| NPer| MXdl| NXdl|  ABlockTransfer| ABlockTransfer| ABlockTransfer| ABlockTransfer| ABlockTransfer| ABlockTransfer| ABlockLds|  BBlockTransfer| BBlockTransfer| BBlockTransfer| BlockTransfer| BBlockTransfer| BBlockTransfer| BBlockLds|    CShuffle|    CShuffle| CBlockTransferClusterLengths|  CBlockTransfer|
///######|         |         |         |        |       Type|       Type|       Type|      Type|        Type|         DataType| Elementwise| Elementwise|  Elementwise| Spacialization|  Size| Block| Block| Block|    |    |  XDL|  XDL|  Per|  Per|   ThreadCluster|  ThreadCluster| SrcAccessOrder|   SrcVectorDim|      SrcScalar|      DstScalar| AddExtraM|   ThreadCluster|  ThreadCluster| SrcAccessOrder|  SrcVectorDim|      SrcScalar|      DstScalar| AddExtraN| MXdlPerWave| NXdlPerWave|         _MBlock_MWaveMPerXdl| ScalarPerVector|
///######|         |         |         |        |           |           |           |          |            |                 |   Operation|   Operation|    Operation|               |      |      |      |      |    |    |     |     | Wave| Wave| Lengths_K0_M_K1|   ArrangeOrder|               |               |      PerVector|   PerVector_K1|          | Lengths_K0_N_K1|   ArrangeOrder|               |              |      PerVector|   PerVector_K1|          |  PerShuffle|  PerShuffle|         _NBlock_NWaveNPerXdl|   _NWaveNPerXdl|
///######|         |         |         |        |           |           |           |          |            |                 |            |            |             |               |      |      |      |      |    |    |     |     |     |     |                |               |               |               |               |               |          |                |               |               |              |               |               |          |            |            |                             |    S<C, D0, D1>|
///###### RCR
        // kernel 1: 256->32x128x128 
        // <      Row,      Col, DsLayout, ELayout, A0DataType, B0DataType, DsDataType, EDataType, AccDataType, CShuffleDataType,  AElementOp,  BElementOp, CDEElementOp,       GemmSpec,   256,   32,   128,    128,  16,  16,  32,   32,    1,    1,     S<8, 32, 1>,     S<1, 0, 2>,    S<1, 0, 2>,               2,             16,             16,          0,     S<8, 32, 1>,    S<1, 0, 2>,     S<1, 0, 2>,             2,              16,             16,          0,          1,           1,               S<1, 32, 1, 8>,      S<8, 8, 1>,  ck::BlockGemmPipelineScheduler::Interwave, ck::BlockGemmPipelineVersion::v1, EDataType>;
        // <      Row,      Col, DsLayout, ELayout, A0DataType, B0DataType, DsDataType, EDataType, AccDataType, CShuffleDataType,  AElementOp,  BElementOp, CDEElementOp,       GemmSpec,   256,   32,   128,    256,  16,  16,  32,   32,    1,    1,     S<16, 16, 1>,     S<1, 0, 2>,    S<1, 0, 2>,               2,             16,             16,          0,     S<16, 16, 1>,    S<1, 0, 2>,     S<1, 0, 2>,             2,              16,             16,          0,          1,           1,               S<1, 32, 1, 8>,      S<8, 8, 1>,  ck::BlockGemmPipelineScheduler::Intrawave, ck::BlockGemmPipelineVersion::v3, EDataType>;
        <      Row,      Col, DsLayout, ELayout, A0DataType, B0DataType, DsDataType, EDataType, AccDataType, CShuffleDataType,
               AElementOp,  BElementOp, CDEElementOp,       GemmSpec,   
               //threadnum, mblock, nblock, kblock
               256,   MPerBlock,   128,    KPerBlock,
               // ak1, bk1
               AK1,   BK1,
               // mn_perxdl
               MNPerXDL,   MNPerXDL,
               // mn_xdlperwave 
               MXDLPerWave,    1,
               // a,b: loadtranfer cluster, cluster order, srcorder,VECDIM, srcpervec, dstpervec, lds_extra
            //    S<16, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, 0,
            //    S<16, 16, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, 8, 8, 0,
               S<8, 32, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, AK1, AK1, 0,
               S<8, 32, 1>, S<1, 0, 2>, S<1, 0, 2>, 2, AK1, AK1, 0,
               //    CShuffle|    CShuffle| CBlockTransferClusterLengths|  CBlockTransfer|
               //    MXdlPerWave| NXdlPerWave|         _MBlock_MWaveMPerXdl| ScalarPerVector|
                //  PerShuffle|  PerShuffle|         _NBlock_NWaveNPerXdl|   _NWaveNPerXdl|
               CShuffleMXDLPerWave,    1,   S<1, 32, 1, 8>, S<EVec, D0Vec, D1Vec>,
               ck::BlockGemmPipelineScheduler::Intrawave, ck::BlockGemmPipelineVersion::v1, true, A0DataType>;

    auto a_element_op   = AElementOp{};
    auto b_element_op   = BElementOp{};
    auto cde_element_op = CDEElementOp{};

    // do GEMM
    auto device_op = DeviceOpInstance{};

    auto invoker = device_op.MakeInvoker();
    auto argument =
        device_op.MakeArgument(sorted_token_ids_ptr,
                               sorted_expert_ids_ptr,
                               num_valid_ids_ptr,
                               hidden_states_ptr,
                               w1_ptr,
                               std::array<const void *, NumDTensor>{a1_scale_ptr,
                                                                    w1_scale_ptr},
                               out_ptr,
                               tokens,
                               sorted_size,
                               N,
                               K,
                               StrideA,
                               StrideB,
                               StrideDs,
                               StrideE,
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
    invoker.Run(argument, StreamConfig{at::cuda::getCurrentCUDAStream().stream()});
}

void ck_moe_stage1(torch::Tensor &hidden_states,          // [m, k], input token
                   torch::Tensor &w1,                     // [e, n, k]/[e, 2*n, k], pre-shuffle([e, nr, kr, w])
                   torch::Tensor &w2,                     // [expert, dim, inter_dim], pre-shuffle([e, nr, kr, w])
                   torch::Tensor &sorted_token_ids,       // [max_num_tokens_padded]
                   torch::Tensor &sorted_expert_ids,      // [max_num_m_blocks]
                   torch::Tensor &num_valid_ids,          // [1]
                   torch::Tensor &out,                    // [max_num_tokens_padded, inter_dim]
                   std::optional<torch::Tensor> w1_scale, // [e, 1, n], gate(up) scale
                   std::optional<torch::Tensor> a1_scale  // [m, 1], token scale
)
{
    int tokens = hidden_states.size(0);
    int sorted_size = out.size(0);
    int N = w1.size(1);
    int K = w1.size(2);

    ck_moe_stage1_impl(N, K,
                       tokens,
                       sorted_size,
                       sorted_token_ids.data_ptr(),
                       sorted_expert_ids.data_ptr(),
                       num_valid_ids.data_ptr(),
                       hidden_states.data_ptr(),
                       w1.data_ptr(),
                       a1_scale.has_value() ? a1_scale.value().data_ptr() : nullptr,
                       w1_scale.has_value() ? w1_scale.value().data_ptr() : nullptr,
                       out.data_ptr());

}