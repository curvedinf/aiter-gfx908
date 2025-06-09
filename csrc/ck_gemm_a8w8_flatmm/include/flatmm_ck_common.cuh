#pragma once
// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

#ifdef USE_ROCM

#undef __HIP_NO_HALF_OPERATORS__
#undef __HIP_NO_HALF_CONVERSIONS__

#include <iostream>
#include <numeric>
#include <initializer_list>
#include <cstdlib>

#include <ATen/ATen.h>
#include <torch/extension.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include <c10/cuda/CUDAStream.h>

#include "flatmm_basic.hpp"

using F16  = ck_tile::half_t;
using BF16 = ck_tile::bf16_t;
using FP8  = ck_tile::fp8_t;
using F32  = float;
using B16 = ck_tile::bf16_t;
using ADataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::ADataType;
using BDataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::BDataType;
using CDataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::CDataType;
using AccDataType = typename GemmBasicTypeConfig<ck_tile::fp8_t>::AccDataType;
using ALayout =  ck_tile::tensor_layout::gemm::RowMajor;
using BLayout =  ck_tile::tensor_layout::gemm::ColumnMajor;
using CLayout =  ck_tile::tensor_layout::gemm::RowMajor;

template <typename ADataType,
         typename BDataType,
         typename AccDataType,
         typename CDataType,
         typename ALayout,
         typename BLayout,
         typename CLayout,
         typename FlatmmTileConfig>
float flatmm_calc(const ck_tile::FlatmmHostArgs& args, const ck_tile::stream_config& s)
{
   constexpr bool kPadM = FlatmmTileConfig::kPadM;
   constexpr bool kPadN = FlatmmTileConfig::kPadN;
   constexpr bool kPadK = FlatmmTileConfig::kPadK;
   constexpr int kBlockPerCu = FlatmmTileConfig::kBlockPerCu;
   
   constexpr ck_tile::index_t M_Tile = FlatmmTileConfig::M_Tile;
   constexpr ck_tile::index_t N_Tile = FlatmmTileConfig::N_Tile;
   constexpr ck_tile::index_t K_Tile = FlatmmTileConfig::K_Tile;
   
   constexpr ck_tile::index_t M_Warp = FlatmmTileConfig::M_Warp;
   constexpr ck_tile::index_t N_Warp = FlatmmTileConfig::N_Warp;
   constexpr ck_tile::index_t K_Warp = FlatmmTileConfig::K_Warp;
   
   constexpr ck_tile::index_t M_Warp_Tile = FlatmmTileConfig::M_Warp_Tile;
   constexpr ck_tile::index_t N_Warp_Tile = FlatmmTileConfig::N_Warp_Tile;
   constexpr ck_tile::index_t K_Warp_Tile = FlatmmTileConfig::K_Warp_Tile;

   using CodegenFlatmmShape =
       ck_tile::TileFlatmmShape<ck_tile::sequence<M_Tile, N_Tile, K_Tile>,
                                ck_tile::sequence<M_Warp, N_Warp, K_Warp>,
                                ck_tile::sequence<M_Warp_Tile, N_Warp_Tile, K_Warp_Tile>>;

   using TilePartitioner = ck_tile::GemmTile1DPartitioner<CodegenFlatmmShape>;

   using CodegenGemmTraits =
       ck_tile::TileGemmTraits<kPadM, kPadN, kPadK, ALayout, BLayout, CLayout>;
   using CodegenPipelineProblem = ck_tile::GemmPipelineProblem<ADataType,
                                                               BDataType,
                                                               AccDataType,
                                                               CodegenFlatmmShape,
                                                               CodegenGemmTraits>;
  const auto Run               = [&](const auto memory_operation_) {
       constexpr auto memory_operation = memory_operation_.value;

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
       using Kernel = ck_tile::FlatmmKernel<TilePartitioner, CodegenFlatmmPipeline, GemmEpilogue>;

       auto kargs = Kernel::MakeKernelArgs(args);

       const dim3 grids      = Kernel::GridSize(args.M, args.N, args.k_batch);
       constexpr dim3 blocks = Kernel::BlockSize();

       if(!Kernel::IsSupportedArgument(kargs))
       {
           throw std::runtime_error("Wrong! Arguments not supported! Skipping gemm!\n");
       }

       if(s.log_level_ > 0)
       {
           std::cout << "Launching kernel with args:"
                     << " grid: {" << grids.x << ", " << grids.y << ", " << grids.z << "}"
                     << ", blocks: {" << blocks.x << ", " << blocks.y << ", " << blocks.z << "}"
                     << std::endl;
       }

       float ave_time = ck_tile::launch_kernel(
           s, ck_tile::make_kernel<blocks.x, kBlockPerCu>(Kernel{}, grids, blocks, 0, kargs));

       return ave_time;
   };
   if(args.k_batch == 1)
   {
       return Run(ck_tile::integral_constant<ck_tile::memory_operation_enum,
                                             ck_tile::memory_operation_enum::set>{});
   }
   else
   {
       return Run(ck_tile::integral_constant<ck_tile::memory_operation_enum,
                                             ck_tile::memory_operation_enum::atomic_add>{});
   }
}

template <typename AccDataType, typename EDataType,
        bool PadM, bool PadN, bool PadK, int BlockPerCu, 
        int MTile, int NTile, int KTile,
        int MWarp, int NWarp , int KWarp,
        int MWTile, int NWTile, int KWTile>
using CustomConfig = CreateTileConfig<
          false,//kPadM
          false,//kPadN
          false,//kPadK
          2,   // BlockPerCu
          128,   // MTile
          128,   // NTile
          128,   // KTile
          1,     // MWarp
          4,     // NWarp
          1,     // KWarp
          16,    // MWTile
          16,    // NWTile
          64      // KWTile
      >;

template <typename DDataType, typename EDataType, typename FlatmmInstance>
__forceinline__ torch::Tensor flatmm_ck_impl(    
        torch::Tensor &XQ,
        torch::Tensor &WQ, 
        torch::Tensor &x_scale,
        torch::Tensor &w_scale,
        torch::Tensor &out      // Out:[M, N] fp16
        )
     {
        // printf("solin:-------kernel====.\n");
        TORCH_CHECK(XQ.dtype() == WQ.dtype(), "Weights and activations should have the same dtype!");
        TORCH_CHECK(x_scale.dtype() == w_scale.dtype(), "Scales should have the same dtype!");
        using ADataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::ADataType;
        using BDataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::BDataType;
        using CDataType   = typename GemmBasicTypeConfig<ck_tile::fp8_t>::CDataType;
        using AccDataType = typename GemmBasicTypeConfig<ck_tile::fp8_t>::AccDataType;
        using ALayout =  ck_tile::tensor_layout::gemm::RowMajor;
        using BLayout =  ck_tile::tensor_layout::gemm::ColumnMajor;
        using CLayout =  ck_tile::tensor_layout::gemm::RowMajor;
        int m = XQ.size(0);
        int n = out.size(1);
        int k = XQ.size(1);

        ck_tile::FlatmmHostArgs args;
        args.a_ptr         = (void *)XQ.data_ptr();
        args.b_shuffle_ptr = (void *)WQ.data_ptr();
        args.c_ptr = (void *)out.data_ptr();
     
        args.k_batch  = 1;
        args.M        = m;
        args.N        = n;
        args.K        = k;
        args.stride_A = k;
        args.stride_B = k;
        args.stride_C = n;
     
        CDataType* c_ptr = reinterpret_cast<CDataType*>(out.data_ptr());
     
        const at::cuda::OptionalCUDAGuard device_guard(device_of(XQ));
        const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
        ck_tile::stream_config naive_config{stream};
        flatmm_calc<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout, FlatmmInstance>(args, naive_config);
     
        return out;
     }

#endif // USE_ROCM
