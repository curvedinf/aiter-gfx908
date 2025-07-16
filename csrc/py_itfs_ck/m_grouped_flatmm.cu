// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include "py_itfs_common.h"
#include "grouped_flatmm.hpp"
#include <hip/hip_runtime.h>

template <typename ADataType,
         typename BDataType,
         typename AccDataType,
         typename CDataType,
         typename ALayout,
         typename BLayout,
         typename CLayout
        //  typename KernelArguments
         >
float grouped_flatmm(const ck_tile::MaskedGroupedFlatmmHostArgs& args, const ck_tile::stream_config& s)
{
    // The kPadM, kPadN, kPadK & kBlockPerCu should also come from the Codegen part.
    constexpr bool kPadM = false;
    constexpr bool kPadN = false;
    constexpr bool kPadK = false;

    constexpr int kBlockPerCu = 1;

    constexpr ck_tile::index_t M_Tile = GemmConfig<BDataType>::M_Tile;
    constexpr ck_tile::index_t N_Tile = GemmConfig<BDataType>::N_Tile;
    constexpr ck_tile::index_t K_Tile = GemmConfig<BDataType>::K_Tile;

    constexpr ck_tile::index_t M_Warp = GemmConfig<BDataType>::M_Warp;
    constexpr ck_tile::index_t N_Warp = GemmConfig<BDataType>::N_Warp;
    constexpr ck_tile::index_t K_Warp = GemmConfig<BDataType>::K_Warp;

    constexpr ck_tile::index_t M_Warp_Tile = GemmConfig<BDataType>::M_Warp_Tile;
    constexpr ck_tile::index_t N_Warp_Tile = GemmConfig<BDataType>::N_Warp_Tile;
    constexpr ck_tile::index_t K_Warp_Tile = GemmConfig<BDataType>::K_Warp_Tile;

    using Traits = ck_tile::TileGemmTraits<kPadM, kPadN, kPadK, ALayout, BLayout, CLayout>;

    using CodegenFlatmmShape =
        ck_tile::TileFlatmmShape<ck_tile::sequence<M_Tile, N_Tile, K_Tile>,
                                ck_tile::sequence<M_Warp, N_Warp, K_Warp>,
                                ck_tile::sequence<M_Warp_Tile, N_Warp_Tile, K_Warp_Tile>>;

    using TilePartitioner = ck_tile::GemmTile1DPartitioner<CodegenFlatmmShape>;

    using GemmPipelineProblem =
        ck_tile::GemmPipelineProblem<ADataType, BDataType, AccDataType, CodegenFlatmmShape, Traits>;

    using BaseGemmPipeline = ck_tile::BaseFlatmmPipelineAGmemBGmemCRegV1<GemmPipelineProblem>;

    // const ck_tile::index_t k_grain     = args.k_batch * K_Tile;
    // const ck_tile::index_t K_split     = (args.K + k_grain - 1) / k_grain * K_Tile;
    // const ck_tile::index_t num_loop    = TilePartitioner::GetLoopNum(K_split);
    // const bool has_hot_loop            = BaseGemmPipeline::BlockHasHotloop(num_loop);
    // const ck_tile::TailNumber tail_num = BaseGemmPipeline::GetBlockLoopTailNum(num_loop);

    const bool has_hot_loop            = true;
    const ck_tile::TailNumber tail_num = ck_tile::TailNumber::Even;

    using CodegenGemmTraits =
        ck_tile::TileGemmTraits<kPadM, kPadN, kPadK, ALayout, BLayout, CLayout>;

    float ave_time{0};

    const auto Run = [&](const auto has_hot_loop_,
                        const auto tail_number_,
                        const auto memory_operation_) {
        constexpr bool has_hot_loop_v   = has_hot_loop_.value;
        constexpr auto tail_number_v    = tail_number_.value;
        constexpr auto memory_operation = memory_operation_.value;
        using CodegenPipelineProblem    = ck_tile::FlatmmPipelineProblem<ADataType,
                                                                        BDataType,
                                                                        AccDataType,
                                                                        CodegenFlatmmShape,
                                                                        CodegenGemmTraits,
                                                                        has_hot_loop_v,
                                                                        tail_number_v>;

        using GemmEpilogue = ck_tile::CShuffleEpilogue<
            ck_tile::CShuffleEpilogueProblem<ADataType,
                                            BDataType,
                                            AccDataType,
                                            CDataType,
                                            CLayout,
                                            CodegenPipelineProblem::kBlockSize,
                                            TilePartitioner::MPerBlock,
                                            TilePartitioner::NPerBlock,
                                            M_Warp,
                                            N_Warp,
                                            M_Warp_Tile,
                                            N_Warp_Tile,
                                            K_Warp_Tile,
                                            CodegenPipelineProblem::TransposeC,
                                            memory_operation>>;

        using CodegenFlatmmPolicy = ck_tile::UniversalFlatmmPipelineAgBgCrPolicy;
        using CodegenFlatmmPipeline =
            ck_tile::FlatmmPipelineAGmemBGmemCRegV1<CodegenPipelineProblem, CodegenFlatmmPolicy>;

        // ToDo: Will add the codegen part to test different pipeline policies in GEMM.
        // Now we only use the BlockGemmASmemBSmemCRegV1DefaultPolicy.
        using Kernel =
            ck_tile::GroupedFlatmmKernel<TilePartitioner, CodegenFlatmmPipeline, GemmEpilogue>;

        auto kargs = Kernel::MakeKernelArgs(args);

        const dim3 grids      = Kernel::GridSize(kargs);
        constexpr dim3 blocks = Kernel::BlockSize();

        // if(!Kernel::IsSupportedArgument(kargs))
        // {
        //     throw std::runtime_error("Wrong! Arguments not supported! Skipping gemm!\n");
        // }

        if(s.log_level_ > 0)
        {
            std::cout << "Launching kernel with args:"
                    << " grid: {" << grids.x << ", " << grids.y << ", " << grids.z << "}"
                    << ", blocks: {" << blocks.x << ", " << blocks.y << ", " << blocks.z << "}"
                    << std::endl;
        }

        ave_time = ck_tile::launch_kernel(
            s, ck_tile::make_kernel<blocks.x, kBlockPerCu>(Kernel{}, grids, blocks, 0, kargs));

        return ave_time;
    };

    const auto RunSplitk = [&](const auto has_hot_loop_, const auto tail_number_) {
        if(args.k_batch == 1)
        {
            Run(has_hot_loop_,
                tail_number_,
                ck_tile::integral_constant<ck_tile::memory_operation_enum,
                                        ck_tile::memory_operation_enum::set>{});
        }
        else
        {
            Run(has_hot_loop_,
                tail_number_,
                ck_tile::integral_constant<ck_tile::memory_operation_enum,
                                        ck_tile::memory_operation_enum::atomic_add>{});
        }
    };

    if(tail_num == ck_tile::TailNumber::Odd)
    {
        RunSplitk(ck_tile::bool_constant<true>{},
                ck_tile::integral_constant<ck_tile::TailNumber, ck_tile::TailNumber::Odd>{});
    }
    else if(tail_num == ck_tile::TailNumber::Even)
    {
        RunSplitk(ck_tile::bool_constant<true>{},
                ck_tile::integral_constant<ck_tile::TailNumber, ck_tile::TailNumber::Even>{});
    }
    else
    {
        std::ostringstream err;
        err << "For compute pipeline tail number should always be Full, but have \"" << tail_num
            << "\" which is not supported! PrefetchStages: " << BaseGemmPipeline::PrefetchStages
            << "\n File: " << __FILE__ << ":" << __LINE__ << ", in function: " << __func__;
        throw std::runtime_error(err.str());
    }

    return ave_time;
}
void m_grouped_flatmm_ck(torch::Tensor &XQ,
                        torch::Tensor &WQ,
                        torch::Tensor &x_scale,
                        torch::Tensor &w_scale,
                        torch::Tensor &out,
                        torch::Tensor &group_layout)
{
    // TORCH_CHECK(false, "solin----flatmm_ck ----");
    TORCH_CHECK(XQ.dtype() == WQ.dtype(), "Weights and activations should have the same dtype!");
    TORCH_CHECK(x_scale.dtype() == w_scale.dtype(), "Scales should have the same dtype!");
    using ADataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::ADataType;
    using BDataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::BDataType;
    using CDataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::CDataType;
    using AccDataType = typename GemmBasicTypeConfig<ck_tile::fp8_t>::AccDataType;
    using ALayout =  ck_tile::tensor_layout::gemm::RowMajor;
    using BLayout =  ck_tile::tensor_layout::gemm::ColumnMajor;
    using CLayout =  ck_tile::tensor_layout::gemm::RowMajor;

    int group_count = XQ.size(0);
    int M = out.size(1);
    int N = out.size(2);
    int K = XQ.size(2);

    int Stride_A = K;
    int Stride_B = K;
    int Stride_C = N;

    printf("Group_countxMxNxK=%dx%dx%dx%d", group_count, M, N, K);

    ck_tile::MaskedGroupedFlatmmHostArgs kernel_args{
        reinterpret_cast<ck_tile::index_t *>(group_layout.data_ptr()),
        group_count,
        M,
        N,
        K,
        reinterpret_cast<void *>(XQ.data_ptr()),
        Stride_A,
        reinterpret_cast<void *>(WQ.data_ptr()),
        Stride_B,
        reinterpret_cast<void *>(out.data_ptr()),
        Stride_C,
        1, //KBatch
    };

    CDataType* c_ptr = reinterpret_cast<CDataType*>(out.data_ptr());
    size_t num_elements = out.numel(); 
    for (int i = 0; i < 8; ++i) {
        printf(" cptr %.4f ", static_cast<float>(c_ptr[i]));
    }
    printf("\n");

    const at::cuda::OptionalCUDAGuard device_guard(device_of(XQ));
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
    ck_tile::stream_config naive_config{stream};
    grouped_flatmm<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout>(kernel_args, naive_config);
    for (int i = 0; i < 8; ++i) {
        printf(" cptr %.4f ", static_cast<float>(c_ptr[i]));
    }
    printf("\n");
}
