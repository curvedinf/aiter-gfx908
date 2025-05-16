// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
 #include <torch/all.h>
 #include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
 #include "py_itfs_common.h"

 #include "flatmm_basic.hpp"
// #include "ck_tile/ops/flatmm/kernel/flatmm_kernel.hpp"
 
//  struct __attribute__((packed)) KernelArgs
// {
//     const void* a_ptr;  // [m, k]
//     const void* b_ptr;  // [n, k] -> [n/128, k*128]
//     const void* c_ptr;  // 
//     const void* sa_ptr; // [k/128, m]
//     const void* sb_ptr; // [k/128, n/128]
//     void* d_ptr;        // 
//     void* d_f16_ptr;    // [m, n]
//     // void* dbg_int_ptr;
//     // void* dbg_fp8_ptr;
//     // void* dbg_f16_ptr;
//     // void* dbg_fp32_ptr;
//     index_t k_batch;
//     index_t M;
//     index_t N;
//     index_t K;
//     index_t stride_A;
//     index_t stride_B;
//     index_t stride_C;   
// };
template <typename ADataType,
          typename BDataType,
          typename AccDataType,
          typename CDataType,
          typename ALayout,
          typename BLayout,
          typename CLayout>
float flatmm_calc(const ck_tile::FlatmmHostArgs& args, const ck_tile::stream_config& s)
{

    // The kPadM, kPadN, kPadK & kBlockPerCu should also come from the Codegen part.
    constexpr bool kPadM = false;
    constexpr bool kPadN = false;
    constexpr bool kPadK = false;

    constexpr int kBlockPerCu = 2;

    // This part comes from the Codegen
    constexpr ck_tile::index_t M_Tile = 128;
    constexpr ck_tile::index_t N_Tile = 128;
    constexpr ck_tile::index_t K_Tile = 128;

    constexpr ck_tile::index_t M_Warp = 1;
    constexpr ck_tile::index_t N_Warp = 4;
    constexpr ck_tile::index_t K_Warp = 1;

    constexpr ck_tile::index_t M_Warp_Tile = is_8bit_type<ADataType>::value ? 16 : 32;
    constexpr ck_tile::index_t N_Warp_Tile = is_8bit_type<ADataType>::value ? 16 : 32;
    constexpr ck_tile::index_t K_Warp_Tile = is_8bit_type<ADataType>::value ? 64 : 16;
    //std::cout << "M_Tile = " << M_Tile << std::endl; 
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

torch::Tensor flatmm_ck(    
    torch::Tensor &XQ,
    torch::Tensor &WQ, 
    torch::Tensor &x_scale,
    torch::Tensor &w_scale,
    torch::Tensor &out      // Out:[M, N] fp16
    )
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
    int m = XQ.size(0);
    int n = out.size(1);
    int k = XQ.size(1);
   
    // std::cout << "m = " << m 
    // << ", n = " << n 
    // << ", k = " << k 
    // << std::endl; 
    ck_tile::FlatmmHostArgs args;
    args.a_ptr         = (void *)XQ.data_ptr();
    args.b_shuffle_ptr = (void *)WQ.data_ptr();
    args.c_ptr = (void *)out.data_ptr();
    
    // args.a_ptr         = reinterpret_cast<ADataType *>(XQ.data_ptr());
    // args.b_shuffle_ptr = reinterpret_cast<BDataType *>(WQ.data_ptr());
    // args.c_ptr = reinterpret_cast<CDataType *>(out.data_ptr());
    args.k_batch  = 1;
    args.M        = m;
    args.N        = n;
    args.K        = k;
    args.stride_A = k;
    args.stride_B = k;
    args.stride_C = n;

    CDataType* c_ptr = reinterpret_cast<CDataType*>(out.data_ptr());
    //size_t num_elements = out.numel(); 
    // for (int i = 0; i < 8; ++i) {
    //     printf(" cptr %.4f ", static_cast<float>(c_ptr[i]));
    // }
    // printf("\n");

    const at::cuda::OptionalCUDAGuard device_guard(device_of(XQ));
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
    ck_tile::stream_config naive_config{stream};
    flatmm_calc<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout>(args, naive_config);
    // for (int i = 0; i < 8; ++i) {
    //     printf(" cptr %.4f ", static_cast<float>(c_ptr[i]));
    // }
    // printf("\n");
    return out;

 }
 