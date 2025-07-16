// SPDX-License-Identifier: MIT
// Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

#pragma once

#include <string>

#define USING_MFMA_16x16x32_F16
#define USING_MFMA_16x16x32_F8

#include "ck_tile/core.hpp"
#include "ck_tile/host/kernel_launch.hpp"
#include "ck_tile/ops/epilogue.hpp"
#include "ck_tile/ops/flatmm.hpp"
#include "ck_tile/ops/gemm.hpp"
#include <hip/hip_runtime.h>

template <typename ADataType,
          typename BDataType,
          typename AccDataType,
          typename CDataType,
          typename ALayout,
          typename BLayout,
          typename CLayout,
          int BLOCK_SIZE,
          int MBLOCK,
          int NBLOCK,
          int KBLOCK,
          int WAVE_TILE_M,
          int WAVE_TILE_N,
          int WAVE_TILE_K,
          int WAVE_MAP_M,
          int WAVE_MAP_N,
          ck_tile::GemmPipelineScheduler LOOP_SCHED,
          typename PIPELINE_VERSION>
void grouped_flatmm(torch::Tensor &XQ,
                    torch::Tensor &WQ,
                    torch::Tensor &x_scale,
                    torch::Tensor &w_scale,
                    torch::Tensor &Y,
                    torch::Tensor &group_layout)
{
    int M = XQ.size(0);
    int N = WQ.size(0);
    int K = XQ.size(1);

    int StrideA = K;
    int StrideB = K;
    int StrideE = N;

    ck_tile::ContiguousGroupedFlatmmHostArgs kernal_args{
        reinterpret_cast<void *>(group_layout.data_ptr()),
        M,
        N,
        K,
        reinterpret_cast<void *>(XQ.data_ptr()),
        stride_A,
        reinterpret_cast<void *>(WQ.data_ptr()),
        stride_B,
        reinterpret_cast<void *>(Y.data_ptr()),
        stride_C,
        1,
    };
    // The kPadM, kPadN, kPadK & kBlockPerCu should also come from the Codegen part.
    constexpr bool kPadM = false;
    constexpr bool kPadN = false;
    constexpr bool kPadK = false;

    constexpr int kBlockPerCu = 1;

    constexpr ck_tile::index_t M_Tile = MBLOCK;
    constexpr ck_tile::index_t N_Tile = NBLOCK;
    constexpr ck_tile::index_t K_Tile = KBLOCK;

    constexpr ck_tile::index_t M_Warp = WAVE_MAP_M;
    constexpr ck_tile::index_t N_Warp = WAVE_MAP_N;

    constexpr ck_tile::index_t M_Warp_Tile = WAVE_TILE_M;
    constexpr ck_tile::index_t N_Warp_Tile = WAVE_TILE_N;
    constexpr ck_tile::index_t K_Warp_Tile = WAVE_TILE_K;

    using Traits = ck_tile::TileGemmTraits<kPadM, kPadN, kPadK, ALayout, BLayout, CLayout>;

    using CodegenFlatmmShape =
        ck_tile::TileFlatmmShape<ck_tile::sequence<M_Tile, N_Tile, K_Tile>,
                                 ck_tile::sequence<M_Warp, N_Warp, K_Warp>,
                                 ck_tile::sequence<M_Warp_Tile, N_Warp_Tile, K_Warp_Tile>>;

    using TilePartitioner = ck_tile::GemmTile1DPartitioner<CodegenFlatmmShape>;

    using GemmPipelineProblem =
        ck_tile::GemmPipelineProblem<ADataType, BDataType, AccDataType, CodegenFlatmmShape, Traits>;

    // TODO: choose by pipeline version
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

        ck_tile::launch_kernel(
            s, ck_tile::make_kernel<blocks.x, kBlockPerCu>(Kernel{}, grids, blocks, 0, kargs));

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

}


