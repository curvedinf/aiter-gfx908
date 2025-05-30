// SPDX-License-Identifier: MIT
// Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

#include <torch/python.h>
#include <c10/cuda/CUDAGuard.h>
#include <ck_tile/core.hpp>
#include "ck_tile/core/tensor/tile_scatter_gather.hpp"

#include <ck_tile/host.hpp>
#include <ck_tile/host.hpp>
#include <ck_tile/ops/gemm.hpp>
#include <ck_tile/ops/gemm.hpp>

#include <ck_tile/ops/reduce/block/block_reduce.hpp>
#include <ck_tile/ops/fmha/block/page_block_navigator.hpp>

#define enable_lds 
// #define ZZDebug
// #define DEBUG_TID 128

// =====================================================================================================================
// Definitions and helper structures
//

template <int32_t kSizeD_,
          int32_t kSizeDV_,
          int32_t kBlockM0_,
          int32_t kBlockN0_,
          int32_t kBlockN1_,
          int32_t kNumWarps_>
struct FlashMlaKernelTrait
{
    static constexpr int32_t kSizeD                  = kSizeD_;    // hidden dimension size of query and key
    static constexpr int32_t kSizeDV                 = kSizeDV_;   // hidden dimension size of value
    static constexpr int32_t kNumWarps               = kNumWarps_;
    static constexpr int32_t kNumThreads             = kNumWarps * warpSize;
    static constexpr int32_t kNumWarpsSoftmax        = 2;
    static constexpr int32_t kNumThreadsSoftmax      = kNumWarpsSoftmax * warpSize;
    static constexpr int32_t kNumWarpsCombine        = 2;
    static constexpr int32_t kNumThreadsCombine      = kNumWarpsCombine * ck_tile::get_warp_size();
    static constexpr int32_t kBlockM                 = kBlockM0_;
    static constexpr int32_t kBlockN0                = kBlockN0_;

    static constexpr int32_t kBlockN1                = kBlockN1_;
    static constexpr int32_t kBlockK1                = kBlockN0;
    static constexpr int32_t kFixedOverheadNumBlocks = 5;
    static constexpr int32_t kMaxBatchSize           = 4096;

    static constexpr int32_t kBlockK0 = 64;

    static_assert(kSizeD % 64 == 0);
    static_assert(kSizeDV % 64 == 0);
    static_assert(kSizeD >= kSizeDV);

    using Gemm0BlockWarps = ck_tile::sequence<1, 4, 1>;
    using Gemm0WarpTile = ck_tile::sequence<16, 16, 16>;
    using Gemm0RopeWarpTile = ck_tile::sequence<16, 16, 16>;

    using Gemm1BlockWarps = ck_tile::sequence<1, 4, 1>;
    using Gemm1WarpTile = ck_tile::sequence<16, 16, 16>;

    static constexpr int32_t kNumGemm0Warps = kNumWarps_;
    static constexpr int32_t kNumGemm1Warps = kNumWarps_;
    static constexpr int32_t kBlockSize = kNumWarps * warpSize;

    static constexpr int32_t kStages = 2;
    static constexpr int32_t kPageSize = 16;

    static constexpr bool TransposeC = false;
    // static constexpr bool IsBReg = kBlockN * kSizeD * kStages * 2 >= 64 * 1024;
    static constexpr bool IsBReg = false;
    // static constexpr bool GemmPVLds = true;
    static constexpr bool GemmPVLds = true;

    static constexpr bool ReturnLse = false;
};

// using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<576, 512, 16, 64, 4>;
using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<576, 512, 16, 64, 64, 4>;

// using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<192, 128, 64, 64, 4>;
// using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<576, 512, 64, 64, 4>;

template <typename Traits, typename scalar_t, typename acc_t>
struct FlashMlaKernelPolicy
{
public:
    // constexpr static auto q_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeD);
    constexpr static auto k_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockN0, Traits::kSizeD);
    constexpr static auto lse_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockM);
    constexpr static auto o_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeDV);
    constexpr static auto I0 = ck_tile::number<0>{};
    constexpr static auto I1 = ck_tile::number<1>{};
    constexpr static auto I2 = ck_tile::number<2>{};
    constexpr static auto I3 = ck_tile::number<3>{};
    constexpr static auto kPackSize = 16 / sizeof(scalar_t);

    CK_TILE_DEVICE static constexpr auto MakeQDramBlockDistribution()
    {
        if constexpr (!Traits::IsBReg)
        {
			return ck_tile::remove_cvref_t<decltype(GetQKRopeBlockGemm())>::template MakeABlockTileDistribution<
				Traits::kBlockM,
				Traits::kSizeD>();
        }
        else
        {
			// return ck_tile::make_static_tile_distribution(
   //              ck_tile::remove_cvref_t<decltype(GetQKBlockGemm())>::MakeABlockDistributionEncode());

            // constexpr auto config = decltype(GetQKBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmQKProblem>();
            constexpr auto config = decltype(GetQKRopeBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmQKRopeProblem>();
            using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

            constexpr int32_t MWarp = Traits::Gemm0BlockWarps::at(ck_tile::number<0>{});
            constexpr int32_t NWarp = Traits::Gemm0BlockWarps::at(ck_tile::number<1>{});

            constexpr int32_t kMPerBlock = Traits::kBlockM;
            constexpr int32_t kKPerBlock = Traits::kBlockK0;

            constexpr int32_t MIterPerWarp = kMPerBlock / (MWarp * WarpGemm::kM);
            constexpr int32_t KIterPerWarp = kKPerBlock / WarpGemm::kK;

            constexpr auto q_tile_outer_encode =
                ck_tile::tile_distribution_encoding<
                    ck_tile::sequence<NWarp>,
                    ck_tile::tuple<ck_tile::sequence<MIterPerWarp, MWarp>, ck_tile::sequence<KIterPerWarp>>,
                    ck_tile::tuple<ck_tile::sequence<1, 0>>,
                    ck_tile::tuple<ck_tile::sequence<1, 0>>,
                    ck_tile::sequence<1, 2>,
                    ck_tile::sequence<0, 0>>{};

            constexpr auto q_dram_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
                q_tile_outer_encode, typename WarpGemm::AWarpDstrEncoding{});

            return ck_tile::make_static_tile_distribution(q_dram_block_dstr_encode);
        }
    }

    CK_TILE_DEVICE static constexpr auto MakeQRopeDramBlockDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::remove_cvref_t<decltype(GetQKRopeBlockGemm())>::MakeABlockDistributionEncode());
    }

   //  CK_TILE_DEVICE static constexpr auto MakeKLdsBlockDescriptor()
   //  {
   // //      constexpr auto kSizeInner = [&] {
   // //          if constexpr (!Traits::IsBReg)
   // //              return Traits::kSizeD;
   // //          else
   // //              return Traits::kSizeDV;
   // //      }();
			// //
   // //      constexpr auto k_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
   // //          ck_tile::make_tuple(Traits::kStages * Traits::kBlockN0,
   // //                              kSizeInner / kPackSize,
   // //                              kPackSize),
			// // //TODO: check this
   // //          // ck_tile::make_tuple((Traits::kSizeD / kPackSize + 1) * kPackSize,
   // //          ck_tile::make_tuple(kSizeInner,
   // //                              kPackSize,
   // //                              1),
   // //          ck_tile::number<kPackSize>{},
   // //          I1);
   // //      constexpr auto k_lds_block_desc_merge = ck_tile::transform_tensor_descriptor(
   // //          k_lds_block_desc,
   // //          ck_tile::make_tuple(
   // //                  ck_tile::make_pass_through_transform(ck_tile::number<Traits::kStages * Traits::kBlockN0>{}),
   // //                  ck_tile::make_merge_transform(
   // //                      ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV / kPackSize>{},
   // //                      kPackSize))),
   // //          ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2>{}),
   // //          ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
			// //
   // //      return k_lds_block_desc_merge;
   //
   //      constexpr auto k_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
   //          ck_tile::make_tuple(Traits::kBlockK0 / kPackSize,
   //                              Traits::kStages * Traits::kBlockN0,
   //                              kPackSize),
			// //TODO: check this
   //          // ck_tile::make_tuple((Traits::kSizeD / kPackSize + 1) * kPackSize,
   //          ck_tile::make_tuple((Traits::kStages * Traits::kBlockN0 + 1) * kPackSize,
   //                              kPackSize,
   //                              1),
   //          ck_tile::number<kPackSize>{},
   //          I1);
   //      constexpr auto k_lds_block_desc_merge = ck_tile::transform_tensor_descriptor(
   //          k_lds_block_desc,
   //          ck_tile::make_tuple(
   //                  ck_tile::make_pass_through_transform(ck_tile::number<Traits::kStages * Traits::kBlockN0>{}),
   //                  ck_tile::make_merge_transform(
   //                      ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV / kPackSize>{},
   //                      kPackSize))),
   //          ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0, 2>{}),
   //          ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
   //
   //      return k_lds_block_desc_merge;
   //  }

    // CK_TILE_HOST_DEVICE static constexpr auto MakeKLdsBlockDescriptor()
    // {
    //     constexpr int32_t kNPerBlock = Traits::kStages * Traits::kBlockN0;
    //     constexpr int32_t kKPerBlock = Traits::kBlockK0;
    //     constexpr int32_t kKPack     = 16 / sizeof(scalar_t);
    //
    //     constexpr auto k_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
    //         ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kNPerBlock>{}, ck_tile::number<kKPack>{}),
    //         ck_tile::make_tuple(ck_tile::number<(kNPerBlock + 1) * kKPack>{}, ck_tile::number<kKPack>{}, ck_tile::number<1>{}),
    //         ck_tile::number<kKPack>{},
    //         ck_tile::number<1>{});
    //
    //     constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
    //         k_lds_block_desc_0,
    //         ck_tile::make_tuple(
    //             ck_tile::make_pass_through_transform(ck_tile::number<kNPerBlock>{}),
    //             ck_tile::make_merge_transform(make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{}))),
    //         ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0, 2>{}),
    //         ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
    //
    //     return k_lds_block_desc;
    // }
    CK_TILE_HOST_DEVICE static constexpr auto MakeKLdsBlockDescriptor()
    {
        constexpr int32_t kNPerBlock = Traits::kStages * Traits::kBlockN0;
        constexpr int32_t kKPerBlock = Traits::kBlockK0;
        constexpr int32_t kKPack     = 16 / sizeof(scalar_t);

        constexpr auto k_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kNPerBlock>{}, ck_tile::number<kKPack>{}),
            ck_tile::make_tuple(ck_tile::number<(kNPerBlock + 1) * kKPack>{}, ck_tile::number<kKPack>{}, ck_tile::number<1>{}),
            ck_tile::number<kKPack>{},
            ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
            k_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_pass_through_transform(ck_tile::number<kNPerBlock>{}),
                ck_tile::make_merge_transform(make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc;
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeVLdsBlockDescriptor()
    {
        constexpr int32_t Banks        = 32; /// TODO: need change based on arch
        constexpr int32_t PixelsPerRow = Banks * 4 / sizeof(scalar_t);
        constexpr int32_t kKPack       = 16 / sizeof(scalar_t);
        static_assert(PixelsPerRow % kKPack == 0);
        constexpr int32_t NPerRow    = PixelsPerRow / kKPack;
        constexpr int32_t kNPerBlock = Traits::kBlockN1;
        constexpr int32_t kKPerBlock = Traits::kBlockK1;
        static_assert(kNPerBlock % NPerRow == 0);
        static_assert(kKPerBlock % kKPack == 0);

        constexpr int32_t SingleVSize = (kKPerBlock / kKPack) * (kNPerBlock / NPerRow) * (PixelsPerRow + kKPack);
        constexpr auto v_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(
                                // ck_tile::number<Traits::kStages>{},
                                ck_tile::number<1>{},
                                ck_tile::number<kKPerBlock / kKPack>{},
                                ck_tile::number<kNPerBlock / NPerRow>{},
                                ck_tile::number<NPerRow>{},
                                ck_tile::number<kKPack>{}),
            ck_tile::make_tuple(
                                ck_tile::number<SingleVSize>{},
                                ck_tile::number<(kNPerBlock / NPerRow) * (PixelsPerRow + kKPack)>{},
                                ck_tile::number<PixelsPerRow + kKPack>{},
                                ck_tile::number<kKPack>{},
                                ck_tile::number<1>{}),
            ck_tile::number<kKPack>{},
            ck_tile::number<1>{});

        constexpr auto v_lds_block_desc = ck_tile::transform_tensor_descriptor(
            v_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_merge_transform(ck_tile::make_tuple(
                    // ck_tile::number<Traits::kStages>{},
                    ck_tile::number<1>{},
                    ck_tile::number<kNPerBlock / NPerRow>{},
                    ck_tile::number<NPerRow>{})),
                ck_tile::make_merge_transform(ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<0, 2, 3>{}, ck_tile::sequence<1, 4>{}),
            // ck_tile::make_tuple(ck_tile::sequence<1, 2>{}, ck_tile::sequence<0, 3>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return v_lds_block_desc;
    }


    CK_TILE_HOST_DEVICE static constexpr auto MakeVLoadLdsBlockDescriptor()
    {
        constexpr int32_t kNPerBlock = Traits::kStages * Traits::kBlockN0;
        constexpr int32_t kKPerBlock = Traits::kBlockK0;
        constexpr int32_t kKPack     = 16 / sizeof(scalar_t);

        constexpr auto k_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kNPerBlock>{}, ck_tile::number<kKPack>{}),
            ck_tile::make_tuple(ck_tile::number<(kNPerBlock + 1) * kKPack>{}, ck_tile::number<kKPack>{}, ck_tile::number<1>{}),
            ck_tile::number<kKPack>{},
            ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
            k_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_merge_transform(make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{})),
                ck_tile::make_pass_through_transform(ck_tile::number<kNPerBlock>{})),
            ck_tile::make_tuple(ck_tile::sequence<0, 2>{}, ck_tile::sequence<1>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc;
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetSmemSizeSingleKV()
    {
        constexpr int32_t SingleKSize = MakeKLdsBlockDescriptor().get_element_space_size();
        constexpr int32_t SingleVSize =[&]() {
            constexpr int32_t Banks        = 32; /// TODO: need change based on arch
            constexpr int32_t PixelsPerRow = Banks * 4 / sizeof(scalar_t);
            constexpr int32_t kKPack       = 16 / sizeof(scalar_t);
            static_assert(PixelsPerRow % kKPack == 0);
            constexpr int32_t NPerRow    = PixelsPerRow / kKPack;
            constexpr int32_t kNPerBlock = Traits::kBlockN1;
            constexpr int32_t kKPerBlock = Traits::kBlockK1;
            static_assert(kNPerBlock % NPerRow == 0);
            static_assert(kKPerBlock % kKPack == 0);

            return (kKPerBlock / kKPack) * (kNPerBlock / NPerRow) * (PixelsPerRow + kKPack);
        }();

        return ck_tile::max(SingleKSize, SingleVSize) * sizeof(scalar_t);
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetSmemSize()
    {
        return GetSmemSizeSingleKV() + MakePShuffleLdsDescriptor().get_element_space_size() * sizeof(acc_t);
    }

   //  CK_TILE_DEVICE static constexpr auto MakeVLdsTransposeBlockDescriptor()
   //  {
   //      constexpr auto v_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
   //          ck_tile::make_tuple(ck_tile::number<Traits::kBlockK1>{},
   //                              ck_tile::number<Traits::kSizeDV / kPackSize>{},
   //                              kPackSize),
			// //TODO: check this
   //          // ck_tile::make_tuple((kStride / kPackSize + 1) * kPackSize,
   //          ck_tile::make_tuple(kStride,
   //                              kPackSize,
   //                              1),
   //          ck_tile::number<kPackSize>{},
   //          I1);
			//
   //      constexpr auto v_lds_block_desc_transpose = ck_tile::transform_tensor_descriptor(
   //          v_lds_block_desc,
   //          ck_tile::make_tuple(
   //                  ck_tile::make_pass_through_transform(ck_tile::number<Traits::kStages * Traits::kBlockN0>{}),
   //                  ck_tile::make_merge_transform(
   //                      ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV / kPackSize>{},
   //                      kPackSize))),
   //          ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2>{}),
   //          ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0>{}));
   //      return v_lds_block_desc_transpose;
   //  }

    CK_TILE_DEVICE static constexpr auto MakePShuffleLdsDescriptor()
    {
        constexpr auto p_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0 / kPackSize>{},
                                ck_tile::number<Traits::kBlockM>{},
                                ck_tile::number<kPackSize>{}),
            ck_tile::make_tuple(ck_tile::number<(Traits::kBlockM + 1) * kPackSize>{},
                                ck_tile::number<kPackSize>{},
                                ck_tile::number<1>{}),
            ck_tile::number<kPackSize>{},
            I1);

        constexpr auto p_lds_block_desc_merge = ck_tile::transform_tensor_descriptor(
            p_lds_block_desc,
            ck_tile::make_tuple(
                    ck_tile::make_pass_through_transform(ck_tile::number<Traits::kBlockM>{}),
                    ck_tile::make_merge_transform(
                        ck_tile::make_tuple(
                            ck_tile::number<Traits::kBlockN0 / kPackSize>{},
                            ck_tile::number<kPackSize>{}))),
            ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
        return p_lds_block_desc_merge;
    }

    CK_TILE_DEVICE static constexpr auto MakeScaleShuffleLdsDescriptor()
    {
        constexpr auto p_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockM / kPackSize>{},
                                ck_tile::number<kPackSize>{}),
            ck_tile::make_tuple(ck_tile::number<kPackSize>{},
                                ck_tile::number<1>{}),
            ck_tile::number<kPackSize>{},
            I1);

        constexpr auto p_lds_block_desc_merge = ck_tile::transform_tensor_descriptor(
            p_lds_block_desc,
            ck_tile::make_tuple(
                    ck_tile::make_merge_transform(
                        ck_tile::make_tuple(
                            ck_tile::number<Traits::kBlockM / kPackSize>{},
                            ck_tile::number<kPackSize>{}))),
            ck_tile::make_tuple(ck_tile::sequence<0, 1>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}));
        return p_lds_block_desc_merge;
    }

    CK_TILE_DEVICE static constexpr auto MakeVLds2RegBlockDistribution()
    {
        constexpr auto config = decltype(GetSubPVBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmSubPVProblem>();
        using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<0>{});
        constexpr int32_t NWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<1>{});

        constexpr int32_t kNPerBlock = Traits::kBlockN1;
        constexpr int32_t kKPerBlock = Traits::kBlockK1;

        constexpr int32_t NIterPerWarp = kNPerBlock / (NWarp * WarpGemm::kN);
        constexpr int32_t KIterPerWarp = kKPerBlock / WarpGemm::kK;

        constexpr auto vt_lds_outer_encode =
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<MWarp>,
                ck_tile::tuple<ck_tile::sequence<NIterPerWarp, NWarp>, ck_tile::sequence<KIterPerWarp>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>>,
                ck_tile::sequence<1, 2>,
                ck_tile::sequence<0, 0>>{};

        constexpr auto vt_lds_shuffle_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
            vt_lds_outer_encode, typename WarpGemm::BWarpDstrEncoding{});

        return ck_tile::make_static_tile_distribution(vt_lds_shuffle_block_dstr_encode);
    }

public:
    using GemmQKRopeProblem = ck_tile::BlockGemmProblem<
        scalar_t,
        scalar_t,
        acc_t,
        Traits::kNumGemm0Warps * ck_tile::get_warp_size(), 
        ck_tile::TileGemmShape<ck_tile::sequence<Traits::kBlockM,
                                                 Traits::kBlockN0,
                                                 Traits::kBlockK0>,
            typename Traits::Gemm0BlockWarps,
            typename Traits::Gemm0RopeWarpTile>>;

    using GemmSubPVProblem = ck_tile::BlockGemmProblem<
        scalar_t,
        scalar_t,
        acc_t,
        Traits::kNumGemm1Warps * ck_tile::get_warp_size(),
        ck_tile::TileGemmShape<ck_tile::sequence<Traits::kBlockM,
                                                 Traits::kBlockN1,
                                                 Traits::kBlockK1>,
            typename Traits::Gemm1BlockWarps,
            typename Traits::Gemm1WarpTile>>;

    CK_TILE_DEVICE static constexpr auto GetQKRopeBlockGemm()
    {
        constexpr auto warp_gemm = ck_tile::WarpGemmMfmaDispatcher<
            scalar_t,
            scalar_t,
            acc_t,
            Traits::Gemm0RopeWarpTile::at(ck_tile::number<0>{}),
            Traits::Gemm0RopeWarpTile::at(ck_tile::number<1>{}),
            Traits::Gemm0RopeWarpTile::at(ck_tile::number<2>{}),
            Traits::TransposeC>{};

        if constexpr (!Traits::IsBReg)
        {
            using BlockGemmPolicy =
                ck_tile::BlockGemmARegBSmemCRegV2CustomPolicy<scalar_t,
                                                     scalar_t,
                                                     acc_t,
                                                     typename Traits::Gemm0BlockWarps,
                                                     decltype(warp_gemm)>;
            return ck_tile::BlockGemmARegBSmemCRegV2<GemmQKRopeProblem, BlockGemmPolicy>{};
        }
        else
        {
            using BlockGemmPolicy = ck_tile::BlockGemmARegBRegCRegV1CustomPolicy<
                scalar_t,
                scalar_t,
                acc_t,
                typename Traits::Gemm0BlockWarps,
                decltype(warp_gemm)>;
            return ck_tile::BlockGemmARegBRegCRegV1<GemmQKRopeProblem, BlockGemmPolicy>{};
        }
    }

    CK_TILE_DEVICE static constexpr auto GetSubPVBlockGemm()
    {
        constexpr auto warp_gemm = ck_tile::WarpGemmMfmaDispatcher<
            scalar_t,
            scalar_t,
            acc_t,
            Traits::Gemm1WarpTile::at(ck_tile::number<0>{}),
            Traits::Gemm1WarpTile::at(ck_tile::number<1>{}),
            Traits::Gemm1WarpTile::at(ck_tile::number<2>{}),
            Traits::TransposeC>{};

        if constexpr (Traits::GemmPVLds)
        {
            using BlockGemmPolicy =
                ck_tile::BlockGemmARegBSmemCRegV2CustomPolicy<scalar_t,
                                                     scalar_t,
                                                     acc_t,
                                                     typename Traits::Gemm1BlockWarps,
                                                     decltype(warp_gemm)>;
            return ck_tile::BlockGemmARegBSmemCRegV2<GemmSubPVProblem, BlockGemmPolicy>{};
        }
        else
        {
            using BlockGemmPolicy =
                ck_tile::BlockGemmARegBRegCRegV1CustomPolicy<scalar_t,
                                                     scalar_t,
                                                     acc_t,
                                                     typename Traits::Gemm1BlockWarps,
                                                     decltype(warp_gemm)>;
            return ck_tile::BlockGemmARegBRegCRegV1<GemmSubPVProblem, BlockGemmPolicy>{};
        }
    }

    CK_TILE_DEVICE static auto MakeQDramTileWindow(
        const scalar_t* p_query_in,
        const int32_t size_s,
        const int32_t stride_s_q)
    {
        // q: [batch, size_s, size_h, sizeD]
        auto q_dram_naive =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_query_in,
                ck_tile::make_tuple(size_s, Traits::kSizeD), // lengths
                ck_tile::make_tuple(stride_s_q, 1),  // strides
                ck_tile::number<Traits::kSizeD>{},  // last dim alignment
                I1);                               // last dim stride

        // q_tile per block: [kBlockM, kSizeD], q load once
        auto q_dram_padding = ck_tile::pad_tensor_view(
            q_dram_naive,
            // q_dram_window_lengths,
            ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeD),
            ck_tile::sequence<true, false>{});

        return ck_tile::make_tile_window(
            q_dram_padding,
            // q_dram_window_lengths,
            ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeDV),
            {0, 0},
            MakeQDramBlockDistribution());
    }

    CK_TILE_DEVICE static auto MakeQBlockDramTileWindow(
        const scalar_t* p_query_in,
        const int32_t size_s,
        const int32_t stride_s_q)
    {
        // q: [batch, size_s, size_h, sizeD]
        auto q_dram_naive =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_query_in,
                ck_tile::make_tuple(size_s, Traits::kSizeD), // lengths
                ck_tile::make_tuple(stride_s_q, 1),  // strides
                ck_tile::number<Traits::kSizeD>{},  // last dim alignment
                I1);                               // last dim stride

        // q_tile per block: [kBlockM, kSizeD], q load once
        auto q_dram_padding = ck_tile::pad_tensor_view(
            q_dram_naive,
            // q_dram_window_lengths,
            ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeD),
            ck_tile::sequence<true, false>{});

        return ck_tile::make_tile_window(
            q_dram_padding,
            // q_dram_window_lengths,
            ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeD),
            {0, 0},
            MakeQDramBlockDistribution());
    }

    CK_TILE_DEVICE static auto MakeQRopeDramTileWindow(
        const scalar_t* p_query_in,
        const int32_t size_s,
        const int32_t stride_s_q)
    {
        // q: [batch, size_s, size_h, sizeD]
        auto q_dram_naive =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_query_in + Traits::kSizeDV,
                ck_tile::make_tuple(size_s, Traits::kBlockK0), // lengths
                ck_tile::make_tuple(stride_s_q, 1),  // strides
                ck_tile::number<Traits::kPageSize / 2>{},  // last dim alignment
                I1);                               // last dim stride

        // q_tile per block: [kBlockM, kSizeD], q load once
        auto q_dram_padding = ck_tile::pad_tensor_view(
            q_dram_naive,
            // q_dram_window_lengths,
            ck_tile::make_tuple(Traits::kBlockM, Traits::kBlockK0),
            ck_tile::sequence<true, false>{});

        return ck_tile::make_tile_window(
            q_dram_padding,
            // q_dram_window_lengths,
            ck_tile::make_tuple(Traits::kBlockM, Traits::kBlockK0),
            {0, 0},
            MakeQRopeDramBlockDistribution());
    }

    CK_TILE_DEVICE static auto MakeKDramTileWindow(
        const scalar_t* p_key,
        const int32_t total_seqlen_kv,
        const int32_t stride_s_k,
        const int32_t seqlen_k_begin,
        const int32_t seqlen_k_end = 0) //will be delete after correct
    {
        const auto k_dram_naive =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_key,
                ck_tile::make_tuple(total_seqlen_kv, Traits::kSizeD),
                ck_tile::make_tuple(stride_s_k, 1),
                ck_tile::number<Traits::kSizeD>{},
                I1);

        constexpr bool kPadSeqLenK_ = true;
        const int32_t seqlen_k_padding =
            ck_tile::integer_divide_ceil(total_seqlen_kv, Traits::kBlockN0) *
                Traits::kBlockN0;

        auto k_dram_padding = ck_tile::pad_tensor_view(
            k_dram_naive,
            // ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{}, ck_tile::number<Traits::kSizeD>{}),
            ck_tile::make_tuple(seqlen_k_padding, ck_tile::number<Traits::kSizeDV>{}),
            ck_tile::sequence<kPadSeqLenK_, false>{});

        auto k_dram_window = ck_tile::make_tile_window(
            k_dram_padding,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kSizeDV>{}),
            {0, 0});

        auto k_rope_dram_window = ck_tile::make_tile_window(
            k_dram_padding,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kBlockK0>{}),
            {0, Traits::kSizeDV});
        return ck_tile::make_tuple(k_dram_window, k_rope_dram_window);
    }

    CK_TILE_DEVICE static auto MakeKSplitDramTileWindow(
        const scalar_t* p_key,
        const int32_t total_seqlen_kv,
        const int32_t stride_s_k,
        const int32_t seqlen_k_begin = 0,
        const int32_t seqlen_k_end = 0) //will be delete after correct
    {
        const auto k_dram_naive =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_key,
                ck_tile::make_tuple(total_seqlen_kv, Traits::kSizeD),
                ck_tile::make_tuple(stride_s_k, 1),
                ck_tile::number<Traits::kSizeD>{},
                I1);

        constexpr bool kPadSeqLenK_ = true;
        const int32_t seqlen_k_padding =
            ck_tile::integer_divide_ceil(total_seqlen_kv, Traits::kBlockN0) *
                Traits::kBlockN0;

        auto k_dram_padding = ck_tile::pad_tensor_view(
            k_dram_naive,
            // ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{}, ck_tile::number<Traits::kSizeD>{}),
            ck_tile::make_tuple(seqlen_k_padding, ck_tile::number<Traits::kSizeDV>{}),
            ck_tile::sequence<kPadSeqLenK_, false>{});

        auto k_dram_window = ck_tile::make_tile_window(
            k_dram_padding,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kBlockK0>{}),
            {0, 0});

        return k_dram_window;
    }

    CK_TILE_DEVICE static auto MakeVSplitDramTileWindow(
        const scalar_t* p_key,
        const int32_t total_seqlen_kv,
        const int32_t stride_s_k,
        const int32_t seqlen_k_begin = 0,
        const int32_t seqlen_k_end = 0) //will be delete after correct
    {
        const auto v_dram_naive =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_key,
                ck_tile::make_tuple(total_seqlen_kv, Traits::kSizeD),
                ck_tile::make_tuple(stride_s_k, 1),
                ck_tile::number<Traits::kSizeD>{},
                I1);

        const auto v_dram_transposed = ck_tile::transform_tensor_view(
            v_dram_naive,
            ck_tile::make_tuple(ck_tile::make_pass_through_transform(Traits::kSizeDV),
                                ck_tile::make_pass_through_transform(total_seqlen_kv)),
            ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        constexpr bool kPadSeqLenK_ = true;
        const int32_t seqlen_k_padding =
            ck_tile::integer_divide_ceil(total_seqlen_kv, Traits::kBlockN0) *
                Traits::kBlockN0;

        auto v_dram_padding = ck_tile::pad_tensor_view(
            v_dram_transposed,
            ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV>{}, seqlen_k_padding),
            ck_tile::sequence<false, true>{});

        auto v_dram_window = ck_tile::make_tile_window(
            v_dram_padding,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kBlockK0>{}),
            {0, 0});

        return v_dram_window;
    }

    template<typename KDramBlockWindowType,
             typename VDramBlockWindowType>
    CK_TILE_DEVICE static auto MakeSubKVDramTileWindowPaged(
        const KDramBlockWindowType& k_dram_block_window,
        const VDramBlockWindowType& v_dram_block_window,
        const int32_t* block_indices,
        const int32_t stride_s_k,
        const int32_t cur_seqlen_k_idx,
        const int32_t page_block_size)
    {
        constexpr auto k_dist = MakeKDramTileDistribution();
		const auto k_coord = k_dist.calculate_index();
		using KDstrEncode = typename decltype(k_dist)::DstrEncode;
		constexpr ck_tile::index_t NRepeat = KDstrEncode::hs_lengthss_[I0][I0];
		ck_tile::statically_indexed_array<ck_tile::index_t, NRepeat> k_offsets;
        // if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && threadIdx.x == 0) {
        //     printf("cur_seqlen_k_idx %d, k_coord[I0]%d Traits::kBlockN0%d,NRepeat%d \n, block_indices[93]%d", cur_seqlen_k_idx, k_coord[I0], Traits::kBlockN0, NRepeat, block_indices[93] * 64);
        // }

		ck_tile::static_for<0, NRepeat, 1>{}([&](auto n0) {
            int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + k_coord[I0] + Traits::kBlockN0 / NRepeat * n0.value;
            int32_t page_idx = seqlen_k_idx_per_repeat / page_block_size;
            int32_t seq_idx = seqlen_k_idx_per_repeat % page_block_size;
			k_offsets[n0] = (block_indices[page_idx] * page_block_size + seq_idx) * stride_s_k;
            // if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && threadIdx.x == 0) {
            //     printf("seqlen_k_idx_per_repeat %d, k_offsets[]%d \n", seqlen_k_idx_per_repeat, k_offsets[n0]);
            // }
            // k_offsets[n0] = block_indices[k_coord[0] + Traits::kBlockN0 / NRepeat * n0.value] * stride_s_k;
		});
        auto k_dram_tile = ck_tile::make_tile_scatter_gather(
            k_dram_block_window.get_bottom_tensor_view(),
            k_dram_block_window.get_window_lengths(),
            k_dram_block_window.get_window_origin(),
            k_dist,
            k_offsets); // K DRAM tile window for




        constexpr auto v_dist = MakeVDramTileDistribution();
		const auto v_coord = v_dist.calculate_index();
		using VDstrEncode = typename decltype(v_dist)::DstrEncode;
		constexpr ck_tile::index_t KRepeat = VDstrEncode::hs_lengthss_[I1][I3];
		ck_tile::statically_indexed_array<ck_tile::index_t, NRepeat> v_offsets;
		ck_tile::static_for<0, KRepeat, 1>{}([&](auto k0) {
            int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + v_coord[I1] + k0.value;
            int32_t page_idx = seqlen_k_idx_per_repeat / page_block_size;
            int32_t seq_idx = seqlen_k_idx_per_repeat % page_block_size;
			v_offsets[k0] = (block_indices[page_idx] * page_block_size + seq_idx) * stride_s_k;
            // k_offsets[n0] = block_indices[v_coord[0] + Traits::kBlockN0 / NRepeat * n0.value] * stride_s_k;
		});
        auto v_dram_tile = ck_tile::make_tile_scatter_gather(
            v_dram_block_window.get_bottom_tensor_view(),
            v_dram_block_window.get_window_lengths(),
            v_dram_block_window.get_window_origin(),
            v_dist,
            v_offsets,
            I1); // K DRAM tile window for
        return ck_tile::make_tuple(k_dram_tile, v_dram_tile);
    }



  //   template<typename KDramBlockWindowType>
  //   CK_TILE_DEVICE static auto MakeSubKVDramTileWindowPaged(
  //       const KDramBlockWindowType& k_dram_block_window,
  //       const int32_t* block_indices,
  //       const int32_t stride_s_k,
  //       const int32_t cur_seqlen_k_idx,
  //       const int32_t page_block_size)
  //   {
  //       auto k_dist = MakeKDramTileDistribution();
  //       auto v_dist = MakeVDramTileDistribution();
		// auto k_coord = v_dist.calculate_index();
		// using KVDstrEncode = typename decltype(v_dist)::DstrEncode;
		// constexpr ck_tile::index_t NRepeat = KVDstrEncode::hs_lengthss_[I0][I3];
		// ck_tile::statically_indexed_array<ck_tile::index_t, NRepeat> kv_offsets;
		//
  //       if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && threadIdx.x == 0) {
  //           int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + k_coord[0];
  //           printf("NRepeat %d, seqlen_k_idx_per_repeat%d  \n", NRepeat, seqlen_k_idx_per_repeat);
  //       }
		//
		// ck_tile::static_for<0, NRepeat, 1>{}([&](auto n0) {
  //           int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + k_coord[0] + n0.value;
  //           // int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + k_coord[0] + Traits::kBlockN0 / NRepeat * n0.value;
  //           int32_t page_idx = seqlen_k_idx_per_repeat / page_block_size;
  //           int32_t seq_idx = seqlen_k_idx_per_repeat % page_block_size;
		// 	kv_offsets[n0] = (block_indices[page_idx] * page_block_size + seq_idx) * stride_s_k;
  //           // k_offsets[n0] = block_indices[k_coord[0] + Traits::kBlockN0 / NRepeat * n0.value] * stride_s_k;
		// });
		//
  //       auto k_dram_tile = ck_tile::make_tile_scatter_gather(
  //           k_dram_block_window.get_bottom_tensor_view(),
  //           k_dram_block_window.get_window_lengths(),
  //           k_dram_block_window.get_window_origin(),
  //           v_dist,
  //           kv_offsets); // K DRAM tile window for
  //       auto v_dram_tile = ck_tile::make_tile_scatter_gather(
  //           k_dram_block_window.get_bottom_tensor_view(),
  //           k_dram_block_window.get_window_lengths(),
  //           k_dram_block_window.get_window_origin(),
  //           v_dist,
  //           kv_offsets); // K DRAM tile window for
  //       return ck_tile::make_tuple(k_dram_tile, v_dram_tile);
  //   }

    template<typename KDramBlockWindowType,
             typename VDramBlockWindowType>
    CK_TILE_DEVICE static void UpdateSubKVDramTileWindow(
        KDramBlockWindowType& k_dram_block_window,
        VDramBlockWindowType& v_dram_block_window,
        const int32_t* block_indices,
        const int32_t stride_s_k,
        const int32_t cur_seqlen_k_idx,
        const int32_t page_block_size)
    {
        constexpr auto k_dist = MakeKDramTileDistribution();
		auto k_coord = k_dist.calculate_index();
		using KDstrEncode = typename decltype(k_dist)::DstrEncode;
		constexpr ck_tile::index_t NRepeat = KDstrEncode::hs_lengthss_[I0][I0];
		ck_tile::statically_indexed_array<ck_tile::index_t, NRepeat> kv_offsets;
		ck_tile::static_for<0, NRepeat, 1>{}([&](auto n0) {
            int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + k_coord[0] + Traits::kBlockN0 / NRepeat * n0.value;
            int32_t page_idx = seqlen_k_idx_per_repeat / page_block_size;
            int32_t seq_idx = seqlen_k_idx_per_repeat % page_block_size;
			kv_offsets[n0] = (block_indices[page_idx] * page_block_size + seq_idx) * stride_s_k;
            // kv_offsets[n0] = block_indices[k_coord[0] + Traits::kBlockN0 / NRepeat * n0.value] * stride_s_k;
            // if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && threadIdx.x == 0) {
            //     printf("update seqlen_k_idx_per_repeat %d, kv_offsets[]%d \n", seqlen_k_idx_per_repeat, kv_offsets[n0]);
            // }
		});
        k_dram_block_window.update_page_idx(kv_offsets);


        constexpr auto v_dist = MakeVDramTileDistribution();
		auto v_coord = v_dist.calculate_index();
		using VDstrEncode = typename decltype(v_dist)::DstrEncode;
		constexpr ck_tile::index_t KRepeat = VDstrEncode::hs_lengthss_[I1][I3];
		ck_tile::statically_indexed_array<ck_tile::index_t, NRepeat> v_offsets;
		ck_tile::static_for<0, KRepeat, 1>{}([&](auto k0) {
            int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + v_coord[I1] + k0.value;
            int32_t page_idx = seqlen_k_idx_per_repeat / page_block_size;
            int32_t seq_idx = seqlen_k_idx_per_repeat % page_block_size;
			v_offsets[k0] = (block_indices[page_idx] * page_block_size + seq_idx) * stride_s_k;
            // k_offsets[n0] = block_indices[v_coord[0] + Traits::kBlockN0 / NRepeat * n0.value] * stride_s_k;
		});
        v_dram_block_window.update_page_idx(v_offsets);
    }

    CK_TILE_DEVICE static auto MakeLSEDramTileWindow(
        acc_t* p_lse_out,
        const int32_t size_s,
        const ck_tile::index_t begin_idx = 0)
    {
        const auto lse_dram =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_lse_out,
                ck_tile::make_tuple(size_s),
                ck_tile::make_tuple(1),
                I1,
                I1);

        // lseacc window lengths: [BlockM]
        return ck_tile::make_tile_window(lse_dram, lse_dram_window_lengths, {begin_idx});
    }

    template<typename ODataType>
    CK_TILE_DEVICE static auto MakeODramTileWindow(
        ODataType* p_output_out,
        const int32_t size_s,
        const ck_tile::index_t begin_idx = 0)
    {
        const auto o_dram = 
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_output_out,
                ck_tile::make_tuple(size_s, Traits::kSizeDV),
                ck_tile::make_tuple(Traits::kSizeDV, 1),
                ck_tile::number<Traits::kSizeDV>{},
                I1);

        return ck_tile::make_tile_window(o_dram, o_dram_window_lengths, {begin_idx, 0});
    }

    CK_TILE_DEVICE static auto MakeKLdsTileWindow(scalar_t* k_lds_ptr)
    {
        auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            k_lds_ptr, MakeKLdsBlockDescriptor());

        // auto k_st_lds_window = ck_tile::make_tile_window(k_lds,
        //     ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
        //                         ck_tile::number<Traits::kSizeD>{}), {0, 0});
        // auto k_ld_lds_window = ck_tile::make_tile_window(k_lds,
        //     ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
        //                         ck_tile::number<Traits::kSizeD>{}), {0, 0});

        auto k_st_lds_window = ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kBlockK0>{}), {0, 0});
        auto k_ld_lds_window = ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kBlockK0>{}), {0, 0});

        return ck_tile::make_tuple(k_st_lds_window, k_ld_lds_window);
    }

    CK_TILE_DEVICE static auto MakeKLdsDebugTileWindow(scalar_t* k_lds_ptr)
    {
        auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            k_lds_ptr, MakeKLdsBlockDescriptor());

        return ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<Traits::kBlockK0>{}), {0, 0},
            MakeKDramTileDistribution());
    }

    CK_TILE_DEVICE static auto MakeVLdsDebugTileWindow(scalar_t* v_lds_ptr)
    {
        auto v_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            v_lds_ptr, MakeVLdsBlockDescriptor());
            // v_lds_ptr, MakeVLoadLdsBlockDescriptor();

        return ck_tile::make_tile_window(v_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN1>{},
                                ck_tile::number<Traits::kBlockK1>{}),
            {0, 0},
            MakeVLds2RegBlockDistribution());
    }

    CK_TILE_DEVICE static auto MakeVLdsTileWindow(scalar_t* v_lds_ptr)
    {
        auto v_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            v_lds_ptr, MakeVLdsBlockDescriptor());
            // v_lds_ptr, MakeVLoadLdsBlockDescriptor());

        if constexpr (Traits::GemmPVLds)
        {
            // return ck_tile::make_tile_window(v_lds,
            //     ck_tile::make_tuple(ck_tile::number<Traits::kBlockN1>{},
            //                         ck_tile::number<Traits::kBlockK1>{}),
            //     {0, 0});
			return ck_tile::make_tile_window(
				v_lds, MakeVLdsBlockDescriptor().get_lengths(), {0, 0});
        }
        else
        {
            return ck_tile::make_tile_window(v_lds,
                ck_tile::make_tuple(ck_tile::number<Traits::kBlockN1>{},
                                    ck_tile::number<Traits::kBlockK1>{}),
                {0, 0},
                MakeVLds2RegBlockDistribution());
        }
    }

    CK_TILE_DEVICE static auto MakeKPageBlockNavigator(
        void* p_key,
        const int32_t* p_block_table,
        const int32_t page_block_size,
        const int32_t stride_b_k,
        const int32_t stride_s_k,
        const int32_t batch_offset,
        const int32_t fixed_offset,
        const int32_t seqlen_kv_end)
    {
        const auto make_k_dram = [&](const scalar_t* data, int32_t height) {
            const auto k_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                data,
                ck_tile::make_tuple(height, Traits::kSizeD),
                ck_tile::make_tuple(stride_s_k, 1),
                ck_tile::number<Traits::kSizeD>{},  // last dim alignment
                I1);

            return ck_tile::pad_tensor_view(
                k_dram_naive,
                ck_tile::make_tuple(page_block_size, Traits::kSizeD),
                ck_tile::sequence<true, false>{});
        };

        const auto* block_indices = p_block_table + batch_offset;

        const int32_t num_blocks =
            ck_tile::integer_divide_ceil(seqlen_kv_end, page_block_size);

        return ck_tile::make_page_block_navigator<const scalar_t, 0>(
            reinterpret_cast<scalar_t*>(p_key),
            stride_b_k,
            fixed_offset,
            block_indices,
            num_blocks,
            page_block_size, // page_size
            make_k_dram(nullptr, page_block_size),
            make_k_dram(nullptr,
                        (seqlen_kv_end - (num_blocks - 1) * page_block_size)));
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeShuffledBRegTileDistribution()
    {
        constexpr ck_tile::index_t BlockSize   = Traits::kBlockSize;
        constexpr ck_tile::index_t NPerBlock   = Traits::kBlockN0;
        constexpr ck_tile::index_t KPerBlock   = Traits::kBlockK0;
        constexpr ck_tile::index_t VecLoadSize = 16 / sizeof(scalar_t);

        using TileEncodingPattern = ck_tile::TileDistributionEncodingPattern2D<BlockSize,
                                                                      KPerBlock,
                                                                      NPerBlock,
                                                                      VecLoadSize,
                                                                      ck_tile::tile_distribution_pattern::thread_raked>;
        return TileEncodingPattern::MakeShuffled2DStaticTileDistribution();
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeKDramTileDistribution()
    {
        // if constexpr(!AsyncCopy)
        if constexpr(true)
        {
            constexpr ck_tile::index_t kBlockSize = Traits::kNumWarps * ck_tile::get_warp_size();
            constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN0;
            constexpr ck_tile::index_t kKPerBlock = Traits::kBlockK0;

            constexpr ck_tile::index_t MaxVectorSize = 16 / sizeof(scalar_t);
            constexpr ck_tile::index_t ElemPerThread = (kNPerBlock * kKPerBlock) / kBlockSize;

            constexpr ck_tile::index_t K1 = ck_tile::min(MaxVectorSize, ElemPerThread); // 8
            constexpr ck_tile::index_t K0 = kKPerBlock / K1; //8
            constexpr ck_tile::index_t N2 = ck_tile::get_warp_size() / K0; // 8
            constexpr ck_tile::index_t N1 = kBlockSize / ck_tile::get_warp_size(); // 4
            constexpr ck_tile::index_t N0 = kNPerBlock / (N2 * N1); // 2

            // return ck_tile::make_static_tile_distribution(
            //     ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
            //                                ck_tile::tuple<ck_tile::sequence<N1, N2, N0>, ck_tile::sequence<K0, K1>>,
            //                                 ck_tile::tuple<ck_tile::sequence<1>, ck_tile::sequence<1, 2>>,
            //                                 ck_tile::tuple<ck_tile::sequence<0>, ck_tile::sequence<1, 0>>,
            //                                 ck_tile::sequence<1, 2>,
            //                                 ck_tile::sequence<2, 1>>{});
            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                           ck_tile::tuple<ck_tile::sequence<N0, N1, N2>, ck_tile::sequence<K0, K1>>,
                                            ck_tile::tuple<ck_tile::sequence<1>, ck_tile::sequence<1, 2>>,
                                            ck_tile::tuple<ck_tile::sequence<1>, ck_tile::sequence<2, 0>>,
                                            ck_tile::sequence<1, 2>,
                                            ck_tile::sequence<0, 1>>{});
        }
        else
        {
            // constexpr ck_tile::index_t kNPerBlock = kN0;
            // constexpr ck_tile::index_t kKPerBlock = Problem::BlockFmhaShape::kK1;
            // constexpr ck_tile::index_t kBlockSize = Problem::kBlockSize;
            // constexpr ck_tile::index_t NumWarps   = Problem::BlockFmhaShape::NumWarps;
            // constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();
            //
            // constexpr ck_tile::index_t KVector = GetAlignmentK<Problem>(); // this is for global load
            //
            // static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
            // constexpr ck_tile::index_t LanesPerK  = kKPerBlock / KVector; // within a wave
            // constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK; // within a wave
            // constexpr ick_tile::ndex_t NumIssues  = kNPerBlock / (LaneGroups * NumWarps);
            // static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));
            //
            // constexpr ck_tile::index_t N0 = NumIssues;
            // constexpr ck_tile::index_t N1 = LaneGroups;
            // constexpr ck_tile::index_t N2 = NumWarps;
            // constexpr ck_tile::index_t K0 = LanesPerK;
            // constexpr ck_tile::index_t K1 = KVector;
            //
            // return ck_tile::make_static_tile_distribution(
            //     ck_tile::tile_distribution_encoding<sequence<1>,
            //                                tuple<sequence<N0, N1, N2>, sequence<K0, K1>>,
            //                                tuple<sequence<1>, sequence<1, 2>>,
            //                                tuple<sequence<2>, sequence<1, 0>>,
            //                                sequence<1, 2>,
            //                                sequence<0, 1>>{});
        }
    }

    CK_TILE_HOST_DEVICE static constexpr auto GetAlignmentV()
    {
        constexpr ck_tile::index_t kBlockSize   = Traits::kBlockSize;
        constexpr ck_tile::index_t kNPerBlock   = Traits::kBlockN1;
        constexpr ck_tile::index_t kKPerBlock   = Traits::kBlockK1;
        constexpr ck_tile::index_t total_pixels = kNPerBlock * kKPerBlock / kBlockSize; // 16
        constexpr ck_tile::index_t kMaxVecLoad =
            ck_tile::min(total_pixels, static_cast<ck_tile::index_t>(16 / sizeof(scalar_t))); //8
        constexpr ck_tile::index_t kMinVecLoad = 4 / sizeof(scalar_t);

        constexpr ck_tile::index_t kVecLoad = ((total_pixels / kMaxVecLoad) >= kMinVecLoad) // 2
                                         ? kMaxVecLoad
                                         : (total_pixels / kMinVecLoad);

        return kVecLoad;
    }

    CK_TILE_DEVICE static constexpr auto MakeVDramTileDistribution()
    {
        constexpr ck_tile::index_t kBlockSize = Traits::kBlockSize;
        constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN1;
        constexpr ck_tile::index_t kKPerBlock = Traits::kBlockK1;

        constexpr ck_tile::index_t N1 = GetAlignmentV(); //8
        constexpr ck_tile::index_t N0 = kNPerBlock / N1; // 64 / 8 = 8

        constexpr ck_tile::index_t total_pixels = kNPerBlock * kKPerBlock / kBlockSize; // 16
        static_assert(total_pixels % N1 == 0); // TODO: this is not always true?
        constexpr ck_tile::index_t K3     = total_pixels / N1;  // 2
        constexpr ck_tile::index_t kKPack = 16 / sizeof(scalar_t); // 8
        static_assert(kKPack % K3 == 0);
        constexpr ck_tile::index_t K2 = kKPack / K3; // 8 / 2 = 4
        if constexpr(ck_tile::get_warp_size() % (K2 * N0) == 0)
        {
            constexpr ck_tile::index_t K1 = ck_tile::get_warp_size() / (K2 * N0); // 64 / 32 = 2
            constexpr ck_tile::index_t K0 = kBlockSize / ck_tile::get_warp_size(); // 4
            static_assert(kKPerBlock == K0 * K1 * K2 * K3); // 4 * 2 * 4 * 2= 64
            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                           ck_tile::tuple<ck_tile::sequence<N0, N1>, ck_tile::sequence<K0, K1, K2, K3>>,
                                           ck_tile::tuple<ck_tile::sequence<2>, ck_tile::sequence<2, 1, 2>>,
                                           ck_tile::tuple<ck_tile::sequence<0>, ck_tile::sequence<1, 0, 2>>,
                                           ck_tile::sequence<2, 1>,
                                           ck_tile::sequence<3, 1>>{});
        }
        else
        {
            constexpr ck_tile::index_t K1   = (K2 * N0) / ck_tile::get_warp_size();
            constexpr ck_tile::index_t K2_m = K2 / K1;
            constexpr ck_tile::index_t K0   = kBlockSize / ck_tile::get_warp_size() / K1;
            static_assert(kKPerBlock == K0 * K1 * K2_m * K3);
            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                           ck_tile::tuple<ck_tile::sequence<N0, N1>, ck_tile::sequence<K0, K1, K2_m, K3>>,
                                           ck_tile::tuple<ck_tile::sequence<2, 2>, ck_tile::sequence<1, 2>>,
                                           ck_tile::tuple<ck_tile::sequence<0, 1>, ck_tile::sequence<0, 2>>,
                                           ck_tile::sequence<2, 1>,
                                           ck_tile::sequence<3, 1>>{});
        }
    }

    CK_TILE_DEVICE static constexpr auto MakeKRopeDramTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::remove_cvref_t<decltype(GetQKRopeBlockGemm())>::MakeBBlockDistributionEncode());
        // constexpr auto config = decltype(GetQKRopeBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmQKRopeProblem>();
        // using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;
        //
        // constexpr int32_t MWarp = Traits::Gemm0BlockWarps::at(ck_tile::number<0>{});
        // constexpr int32_t NWarp = Traits::Gemm0BlockWarps::at(ck_tile::number<1>{});
        //
        // constexpr int32_t kNPerBlock = Traits::kBlockN0;
        // constexpr int32_t kKPerBlock = Traits::kBlockK0;
        //
        // constexpr int32_t NIterPerWarp = kNPerBlock / (NWarp * WarpGemm::kN);
        // constexpr int32_t KIterPerWarp = kKPerBlock / WarpGemm::kK;
        //
        // constexpr auto k_tile_outer_encode =
        //     ck_tile::tile_distribution_encoding<
        //         ck_tile::sequence<MWarp>,
        //         ck_tile::tuple<ck_tile::sequence<NIterPerWarp, NWarp>, ck_tile::sequence<KIterPerWarp>>,
        //         ck_tile::tuple<ck_tile::sequence<0, 1>>,
        //         ck_tile::tuple<ck_tile::sequence<0, 1>>,
        //         ck_tile::sequence<1, 2>,
        //         ck_tile::sequence<0, 0>>{};
        //
        // constexpr auto k_dram_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
        //     k_tile_outer_encode, typename WarpGemm::BWarpDstrEncoding{});
        //
        // return ck_tile::make_static_tile_distribution(k_dram_block_dstr_encode);
    }

    CK_TILE_DEVICE static constexpr auto MakeVShuffleTileDistribution()
    {
        // return ck_tile::make_static_tile_distribution(
        //     ck_tile::remove_cvref_t<decltype(GetPVBlockGemm())>::MakeBBlockDistributionEncode());

        constexpr auto config = decltype(GetSubPVBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GetSubPVBlockGemm>();
        using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<0>{});
        constexpr int32_t NWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<1>{});

        constexpr int32_t kNPerBlock = Traits::kBlockN1;
        constexpr int32_t kKPerBlock = Traits::kBlockK0;
        constexpr int32_t NIterPerWarp = kNPerBlock / (NWarp * WarpGemm::kN);
        constexpr int32_t KIterPerWarp = kKPerBlock / WarpGemm::kK;

        // constexpr int32_t NIterPerWarp = 4;
        // constexpr int32_t KIterPerWarp = 4;
        constexpr auto v_tile_outer_encode =
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<MWarp>,
                ck_tile::tuple<ck_tile::sequence<NIterPerWarp, NWarp>, ck_tile::sequence<KIterPerWarp>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>>,
                ck_tile::sequence<1, 2>,
                ck_tile::sequence<0, 0>>{};

        constexpr auto v_dram_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
            v_tile_outer_encode, typename WarpGemm::BWarpDstrEncoding{});

        return ck_tile::make_static_tile_distribution(v_dram_block_dstr_encode);
    }


    CK_TILE_DEVICE static constexpr auto MakePShuffleTileDistribution()
    {
   //      if constexpr (Traits::GemmPVLds)
   //      {
			// return ck_tile::remove_cvref_t<decltype(GetPVBlockGemm())>::template MakeABlockTileDistribution<
			// 	Traits::kBlockM,
			// 	Traits::kBlockN0>();
			//
   //          // constexpr auto p_encoding = decltype(GetQKBlockGemm().MakeCBlockTile())::get_tile_distribution().get_static_tile_distribution_encoding();
   //          // constexpr auto N = p_encoding.hs_lengthss_.at(I0);
   //          // constexpr auto K = p_encoding.hs_lengthss_.at(I1);
   //          //
   //          // return ck_tile::make_static_tile_distribution(
   //          //     ck_tile::tile_distribution_encoding<ck_tile::sequence<K[1]>,
   //          //            ck_tile::tuple<ck_tile::sequence<N[0], N[1], N[2]>, ck_tile::sequence<K[2], K[3], K[4]>>,
   //          //            ck_tile::tuple<ck_tile::sequence<1, 0>, ck_tile::sequence<2, 1>>,
   //          //            ck_tile::tuple<ck_tile::sequence<1, 0>, ck_tile::sequence<1, 2>>,
   //          //            ck_tile::sequence<1, 2, 2>,
   //          //            ck_tile::sequence<0, 0, 2>>{});
   //      }
   //      else
   //      {
   //          // return ck_tile::make_static_tile_distribution(
   //          //     ck_tile::remove_cvref_t<decltype(GetPVBlockGemm())>::MakeABlockDistributionEncode());
   //          // constexpr auto p_encoding = decltype(GetQKBlockGemm().MakeCBlockTile())::get_tile_distribution().get_static_tile_distribution_encoding();
   //          // constexpr auto N = p_encoding.hs_lengthss_.at(I0);
   //          // constexpr auto K = p_encoding.hs_lengthss_.at(I1);
   //          //
   //          // return ck_tile::make_static_tile_distribution(
   //          //     ck_tile::tile_distribution_encoding<ck_tile::sequence<K[1]>,
   //          //            ck_tile::tuple<ck_tile::sequence<N[0], N[1], K[2]>, ck_tile::sequence<K[0], N[3], N[4]>>,
   //          //            ck_tile::tuple<ck_tile::sequence<1, 0>, ck_tile::sequence<2, 1>>,
   //          //            ck_tile::tuple<ck_tile::sequence<1, 0>, ck_tile::sequence<1, 2>>,
   //          //            ck_tile::sequence<1, 2, 2>,
   //          //            ck_tile::sequence<0, 0, 2>>{});
   //          constexpr auto config = decltype(GetSubPVBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmSubPVProblem>();
   //          using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;
			//
   //          constexpr int32_t MWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<0>{});
   //          constexpr int32_t NWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<1>{});
			//
   //          constexpr int32_t kMPerBlock = Traits::kBlockM;
   //          constexpr int32_t kKPerBlock = Traits::kBlockN0;
			//
   //          constexpr int32_t MIterPerWarp = kMPerBlock / (MWarp * WarpGemm::kM);
   //          constexpr int32_t KIterPerWarp = kKPerBlock / WarpGemm::kK;
			//
   //          constexpr auto p_tile_outer_encode =
   //              ck_tile::tile_distribution_encoding<
   //                  ck_tile::sequence<NWarp>,
   //                  ck_tile::tuple<ck_tile::sequence<MIterPerWarp, MWarp>, ck_tile::sequence<KIterPerWarp>>,
   //                  ck_tile::tuple<ck_tile::sequence<1, 0>>,
   //                  ck_tile::tuple<ck_tile::sequence<1, 0>>,
   //                  ck_tile::sequence<1, 2>,
   //                  ck_tile::sequence<0, 0>>{};
			//
   //          constexpr auto p_dram_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
   //              p_tile_outer_encode, typename WarpGemm::AWarpDstrEncoding{});
			//
   //          return ck_tile::make_static_tile_distribution(p_dram_block_dstr_encode);
   //      }
        constexpr auto config = decltype(GetSubPVBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmSubPVProblem>();
        using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<0>{});
        constexpr int32_t NWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<1>{});

        constexpr int32_t kMPerBlock = Traits::kBlockM;
        constexpr int32_t kKPerBlock = Traits::kBlockN0;

        constexpr int32_t MIterPerWarp = kMPerBlock / (MWarp * WarpGemm::kM);
        constexpr int32_t KIterPerWarp = kKPerBlock / WarpGemm::kK;

        constexpr auto p_tile_outer_encode =
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<NWarp>,
                ck_tile::tuple<ck_tile::sequence<MIterPerWarp, MWarp>, ck_tile::sequence<KIterPerWarp>>,
                ck_tile::tuple<ck_tile::sequence<1, 0>>,
                ck_tile::tuple<ck_tile::sequence<1, 0>>,
                ck_tile::sequence<1, 2>,
                ck_tile::sequence<0, 0>>{};

        constexpr auto p_dram_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
            p_tile_outer_encode, typename WarpGemm::AWarpDstrEncoding{});

        return ck_tile::make_static_tile_distribution(p_dram_block_dstr_encode);
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeShuffledVRegBlockDescriptor()
    {
        // Only called when V is row-major
        constexpr ck_tile::index_t kBlockSize = Traits::kBlockSize;
        constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN1;
        constexpr ck_tile::index_t kKPerBlock = Traits::kBlockK1;

        constexpr ck_tile::index_t N1 = GetAlignmentV();
        constexpr ck_tile::index_t N0 = kNPerBlock / N1;

        constexpr ck_tile::index_t ElemPerThread = kNPerBlock * kKPerBlock / kBlockSize;
        static_assert(ElemPerThread % N1 == 0);
        constexpr ck_tile::index_t K3     = ElemPerThread / N1;
        constexpr ck_tile::index_t kKPack = 16 / sizeof(scalar_t);
        static_assert(kKPack % K3 == 0);
        constexpr ck_tile::index_t K2 = kKPack / K3;

        if constexpr(ck_tile::get_warp_size() % (K2 * N0) == 0)
        {
            constexpr ck_tile::index_t K1 = ck_tile::get_warp_size() / (K2 * N0);
            constexpr ck_tile::index_t K0 = kBlockSize / ck_tile::get_warp_size();
            static_assert(kKPerBlock == K0 * K1 * K2 * K3);
            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                                    ck_tile::tuple<ck_tile::sequence<N0, N1>, ck_tile::sequence<K0, K1, K2, K3>>,
                                                    ck_tile::tuple<ck_tile::sequence<2>, ck_tile::sequence<2, 1, 2>>,
                                                    ck_tile::tuple<ck_tile::sequence<0>, ck_tile::sequence<1, 0, 2>>,
                                                    ck_tile::sequence<1, 2>,
                                                    ck_tile::sequence<1, 3>>{});
        }
        else
        {
            constexpr ck_tile::index_t K1   = (K2 * N0) / ck_tile::get_warp_size();
            constexpr ck_tile::index_t K2_m = K2 / K1;
            constexpr ck_tile::index_t K0   = kBlockSize / ck_tile::get_warp_size() / K1;
            static_assert(kKPerBlock == K0 * K1 * K2_m * K3);
            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                                    ck_tile::tuple<ck_tile::sequence<N0, N1>, ck_tile::sequence<K0, K1, K2_m, K3>>,
                                                    ck_tile::tuple<ck_tile::sequence<2, 2>, ck_tile::sequence<1, 2>>,
                                                    ck_tile::tuple<ck_tile::sequence<0, 1>, ck_tile::sequence<0, 2>>,
                                                    ck_tile::sequence<1, 2>,
                                                    ck_tile::sequence<1, 3>>{});
        }
    }
};


//====================================

template <typename Traits, typename scalar_t, typename acc_t>
struct FlashMlaCombineKernelPolicy
{
private:
    // Returns count of warps which don't contain any idle thread.
    template <int32_t NumWarps, int32_t M, int32_t N>
    CK_TILE_HOST_DEVICE static constexpr auto GetMaxNumWarpsForTile()
    {
        static_assert(NumWarps == 1 || NumWarps == 2 || NumWarps == 4);
        constexpr int32_t ElemPerThread = (M * N) / (NumWarps * ck_tile::get_warp_size());
        if constexpr(0 < ElemPerThread)
        {
            return NumWarps;
        }
        else
        {
            return GetMaxNumWarpsForTile<NumWarps / 2, M, N>();
        }
    }

    // Returns vector size for given warp count for handing the specified matrix.
    template <int32_t NumWarps, int32_t M, int32_t N, typename DataType>
    CK_TILE_HOST_DEVICE static constexpr auto GetVectorSizeForTile()
    {
        constexpr int32_t MaxNumWarps = GetMaxNumWarpsForTile<NumWarps, M, N>();
        constexpr int32_t ElemPerThread = (M * N) / (MaxNumWarps * ck_tile::get_warp_size());
        constexpr int32_t MaxNPerThread = 16 / sizeof(DataType);
        return ck_tile::min(MaxNPerThread, ElemPerThread);
    }

    template <typename DataType>
    CK_TILE_DEVICE static constexpr auto MakeOutputTileDistribution()
    {
        constexpr int32_t kVectorN     = GetVectorSizeForTile<Traits::kNumWarpsCombine, 1, Traits::kSizeDV, DataType>();
        constexpr int32_t kThrPerWarpN = ck_tile::get_warp_size();
        constexpr int32_t kNumWarpN    = Traits::kNumWarpsCombine;

        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,    // no replicate
                ck_tile::tuple<ck_tile::sequence<1>,
                               ck_tile::sequence<kNumWarpN, kThrPerWarpN, kVectorN>>,
                ck_tile::tuple<ck_tile::sequence<2>, ck_tile::sequence<2>>,
                ck_tile::tuple<ck_tile::sequence<0>, ck_tile::sequence<1>>,
                ck_tile::sequence<1, 2>,
                ck_tile::sequence<0, 2>>{});
    }

public:
    CK_TILE_DEVICE static auto MakeOaccuTileWindow(
        void* p_output_accum,
        const int32_t hsidx,
        const int32_t size_hs,
        const int32_t split_offset,
        const int32_t num_splits)
    {
        const int32_t offset_oaccum = split_offset * size_hs * Traits::kSizeDV;

        // Shape of tensor for a block: [num_splits, Traits::kSizeDV]
        const auto naive_view =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                reinterpret_cast<acc_t*>(p_output_accum) + offset_oaccum,
                ck_tile::make_tuple(num_splits * size_hs, Traits::kSizeDV), // lengths
                ck_tile::make_tuple(Traits::kSizeDV, 1),                    // strides
                ck_tile::number<Traits::kSizeDV>{},                         // last dim alignment
                ck_tile::number<1>{});                                      // last dim stride

        // Each thread group handles tile whose shape is [1, Traits::kSizeDV]
        const auto tile_window = ck_tile::make_tile_window(
            naive_view,
            ck_tile::make_tuple(ck_tile::number<1>{},               // window size
                                ck_tile::number<Traits::kSizeDV>{}),
            {hsidx, 0});                          // origin

        return ck_tile::make_tile_window(tile_window, MakeOutputTileDistribution<acc_t>());
    }

    CK_TILE_DEVICE static auto MakeOutputTileWindow(
        void* p_output,
        const int32_t offset_b,
        const int32_t offset_s,
        const int32_t offset_h)
    {
        scalar_t* p_out = reinterpret_cast<scalar_t*>(p_output) + offset_b + offset_s + offset_h;

        const auto naive_view =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_out,
                ck_tile::make_tuple(1, Traits::kSizeDV),    // lengths
                ck_tile::make_tuple(Traits::kSizeDV, 1),    // strides
                ck_tile::number<Traits::kSizeDV>{},         // last dim alignment
                ck_tile::number<1>{});                      // last dim stride

        const auto tile_window = ck_tile::make_tile_window(
            naive_view,
            ck_tile::make_tuple(ck_tile::number<1>{},               // window size
                                ck_tile::number<Traits::kSizeDV>{}),
            {0, 0});                                                // origin

        return ck_tile::make_tile_window(tile_window, MakeOutputTileDistribution<scalar_t>());
    }
};

//====================================

union TileSchedulerMetaData
{
    struct Core
    {
        int32_t begin_batch_idx;
        int32_t begin_seqlen_idx;
        int32_t end_batch_idx;
        int32_t end_seqlen_idx;
        int32_t begin_n_split_idx;
    };
    uint32_t data[8];
    Core core;
};
constexpr size_t TileSchedulerMetaDataSizeInDw = sizeof(TileSchedulerMetaData) / sizeof(int32_t);
constexpr size_t TileSchedulerMetaDataSizeInInt4 = sizeof(TileSchedulerMetaData) / sizeof(int4);

struct FlashMlaFwdParams
{
    int32_t* __restrict__ p_cu_seqlens_k;
    int32_t* __restrict__ p_block_table;
    int32_t* __restrict__ p_tile_scheduler_metadata;
    int32_t* __restrict__ p_num_splits;
    
    void* __restrict__ p_query;
    void* __restrict__ p_key;
    void* __restrict__ p_value;
    void* __restrict__ p_output;
    void* __restrict__ p_softmax_lse;
    void* __restrict__ p_softmax_lseaccum;
    void* __restrict__ p_output_accum;

    void* __restrict__ p_debug_m;
    void* __restrict__ p_debug_value;
    void* __restrict__ p_debug_p;
    void* __restrict__ p_debug_output;

    int32_t size_b;
    int32_t size_s;
    int32_t size_h;
    int32_t hq_hk_ratio;
    int32_t num_groups;
    int32_t num_cu_parts;
    int64_t block_table_batch_stride;
    int32_t total_seqlen_kv;
    int32_t page_block_size;
    float   scale_softmax;
    float   scale_softmax_log2;
    bool    is_causal;

    // Use int64_t if there is int32 overflow case. For now, just use int32 to save sgpr and prevent using
    // spill table.
    using index_t = int32_t;

    index_t stride_b_q;     // stride in batch of query
    index_t stride_s_q;     //    ... in sequence ...
    index_t stride_h_q;     //    ... in head ...
    index_t stride_b_k;     // stride in batch of key
    index_t stride_s_k;     //    ... in sequence ...
    index_t stride_h_k;     //    ... in head ...
    index_t stride_b_v;     // stride in batch of value
    index_t stride_s_v;     //    ... in sequence ...
    index_t stride_h_v;     //    ... in head ...
    index_t stride_b_o;     // stride in batch of output
    index_t stride_s_o;     //    ... in sequence ...
    index_t stride_h_o;     //    ... in head ...
};

// template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
// __launch_bounds__(256, 2)
// __global__ void flash_fwd_splitkv_mla_kernel_lds(
//     const FlashMlaFwdParams params)
// {
//     using Policy  = FlashMlaKernelPolicy<Traits, scalar_t, float>;
//
//     constexpr int32_t kSizeD             = Traits::kSizeD; 
//     constexpr int32_t kSizeDV            = Traits::kSizeDV; 
//     constexpr int32_t kNumThreads        = Traits::kNumThreads;
//     constexpr int32_t kNumThreadsSoftmax = Traits::kNumThreadsSoftmax;
//     constexpr int32_t kBlockM            = Traits::kBlockM;
//     constexpr int32_t kBlockN            = Traits::kBlockN;
//     constexpr int32_t kBlockK0          = Traits::kBlockK0;
//     constexpr int32_t kBlockK1           = Traits::kBlockK1;
//
//     constexpr int32_t kPackScalar = 16 / sizeof(scalar_t);
//     constexpr int32_t kPackAcc = 16 / sizeof(scalar_t);
//     constexpr int32_t kKPack = kPackScalar;
//
//     constexpr auto I0 = ck_tile::number<0>{};
//     constexpr auto I1 = ck_tile::number<1>{};
//
// 	constexpr int32_t move_lds_length[2] = { kBlockN, -(Traits::kStages - 1) * kBlockN };
//
//     const int32_t i_block_m   = blockIdx.x;
//     const int32_t i_nhead     = blockIdx.y;
//     const int32_t i_nhead_k   = i_nhead / params.hq_hk_ratio;
//     const int32_t i_partition = blockIdx.z;
//
//     const ck_tile::index_t i_m0 = __builtin_amdgcn_readfirstlane(i_block_m * kBlockM);
//
//     const auto f_max = [](auto e0, auto e1) { return max(e0, e1); };
//     const auto f_sum = [](auto e0, auto e1) { return e0 + e1; };
//
//     extern __shared__ char shared_memory[];
// 	char *shared_ptr = (char *)(((size_t)shared_memory + 255) & ~255);
//
//     const int32_t tidx = threadIdx.x; 
//
//     // auto gemm_0 = Policy::GetQKBlockGemm();
//     auto gemm_0 = Policy::GetQKRopeBlockGemm();
//
//     auto s_acc = gemm_0.MakeCBlockTile();
//     using SBlockTileType = decltype(ck_tile::cast_tile<acc_t>(s_acc));
//     using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
//         SBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
//     auto m = MLBlockTileType{};
//     auto l = MLBlockTileType{};
//
//     auto gemm_1 = Policy::GetSubPVBlockGemm();
//     auto o_acc = gemm_1.MakeCBlockTile();
//
//     scalar_t* kv_lds_ptr = reinterpret_cast<scalar_t*>(shared_ptr);
//     scalar_t* p_shuffle_ptr = kv_lds_ptr;
//     // scalar_t* p_shuffle_ptr = kv_lds_ptr + Traits::kBlockN * Traits::kSizeDV * Traits::kStages;
//
//     TileSchedulerMetaData metadata;
//     reinterpret_cast<int4*>(&(metadata.data))[0] = reinterpret_cast<int4*>(
//         params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4];
//     reinterpret_cast<int4*>(&(metadata.data))[1] = reinterpret_cast<int4*>(
//         params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4 + 1];
//
//     const int32_t begin_batch_idx   = metadata.core.begin_batch_idx;
//     const int32_t begin_seqlen_idx  = metadata.core.begin_seqlen_idx;
//     const int32_t end_batch_idx     = metadata.core.end_batch_idx;
//     const int32_t end_seqlen_idx    = metadata.core.end_seqlen_idx;
//     const int32_t begin_n_split_idx = metadata.core.begin_n_split_idx;
//
//     auto p_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
//         p_shuffle_ptr, Policy::MakePShuffleLdsDescriptor());
//
//     auto p_st_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
//                             ck_tile::number<Traits::kBlockN>{}), {0, 0});
//     auto p_ld_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
//                             ck_tile::number<Traits::kBlockN>{}), {0, 0},
//         Policy::MakePShuffleTileDistribution());
//
//     for (int32_t i_batch = begin_batch_idx; i_batch <= end_batch_idx; ++i_batch)
//     {
//         const int32_t i_split = i_batch == begin_batch_idx ? begin_n_split_idx : 0;
//         const int32_t seqlen_k    = params.p_cu_seqlens_k[i_batch];
//         const int32_t n_block_min = i_batch == begin_batch_idx ? begin_seqlen_idx / kBlockN : 0;
//         const int32_t n_block_max = i_batch == end_batch_idx ? ck_tile::integer_divide_ceil(end_seqlen_idx, kBlockN) : ck_tile::integer_divide_ceil(seqlen_k, kBlockN);
//         const bool NoSplit = n_block_min == 0 && n_block_max == ck_tile::integer_divide_ceil(seqlen_k, kBlockN);
//         const int32_t split_seqlen_k_begin = i_batch == begin_batch_idx ? begin_seqlen_idx : 0;
//         const int32_t split_seqlen_k_end = i_batch == end_batch_idx ? end_seqlen_idx : seqlen_k;
//
//         int32_t i_block_n = n_block_max - 1;
//
//         const int32_t total_seqlen_kv = (n_block_max - n_block_min) * kBlockN;
//
//         // if (!NoSplit) continue;
//
//         if (i_batch > begin_batch_idx)
//         {
//             __syncthreads();
//         }
//
//         ck_tile::clear_tile(o_acc);
//         ck_tile::clear_tile(m);
//         ck_tile::clear_tile(l);
//
//         const int32_t q_offset = i_batch * params.stride_b_q +
//                                  i_block_m * kBlockM * params.stride_s_q +
//                                  i_nhead * params.stride_h_q;
//         auto q_dram_window = Policy::MakeQDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_query) + q_offset,
//             params.size_s,
//             params.stride_s_q);
//         auto q = load_tile(q_dram_window);
//
//         auto page_batch_offset = params.block_table_batch_stride * i_batch;
//         const auto* block_indices = params.p_block_table + page_batch_offset;
//         int32_t seqlen_k_begin = 0;
//         auto k_dram_block_window = Policy::MakeKSplitDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_key) +
//                 params.stride_h_k * i_nhead_k,
//             params.total_seqlen_kv,
//             params.stride_s_k,
//             seqlen_k_begin);
//         auto k_dram_window = Policy::template MakeSubKDramTileWindowPaged(
//             k_dram_block_window,
//             block_indices,
//             params.stride_s_k,
//             i_block_n * kBlockN,
//             params.page_block_size);
//
//         int32_t tail_offset = block_indices[split_seqlen_k_end / params.page_block_size] * params.page_block_size;
//         int32_t tail_begin = (tail_offset + split_seqlen_k_end % params.page_block_size) * Traits::kSizeD;
//         int32_t tail_end   = (tail_offset + params.page_block_size) * Traits::kSizeD;
//         auto k_block_tile = k_dram_window.load();
//
//
//         auto [k_st_lds_window, k_ld_lds_window] = Policy::MakeKLdsTileWindow(kv_lds_ptr);
//
//         auto v_ld_lds_window = Policy::MakeVLdsTileWindow(kv_lds_ptr);
//
//         int32_t k_st_lds_offset = kBlockN;
//         int32_t k_ld_lds_offset = kBlockN;
//         int32_t v_ld_lds_offset = kBlockN;
//
//         // auto k_block_tile = ck_tile::load_tile(k_dram_window_tail);
//         ck_tile::store_tile(k_st_lds_window, k_block_tile);
//
//         // auto [i_page_block_k, k_dram_window] = k_page_block_navigator.make_tile_window(
//         //     k_dram_window_lengths, {(n_block_max - 2) * kBlockN, 0}, Policy::MakeKDramTileDistribution());
//
//         ck_tile::move_tile_window(k_st_lds_window, {kBlockN, 0});
//
//         constexpr int n_masking_steps = !Is_causal ? 1 : ck_tile::integer_divide_ceil(kBlockM, kBlockN) + 1;
//         int masking_step = n_masking_steps;
//
//         constexpr ck_tile::index_t k0_loops = kSizeD / kBlockK0;
//         constexpr ck_tile::index_t k1_loops = kBlockN / kBlockK1;
//
// #pragma unroll 1
//         for (; i_block_n >= n_block_min; --masking_step, --i_block_n)
//         {
// 			ck_tile::clear_tile(s_acc);
//             ck_tile::block_sync_lds();
//             move_tile_window(k_dram_block_window, {-kBlockN, -Traits::kBlockK0 * (k0_loops - 1)});
//
//             //TODO: change into update offset
//             auto k_dram_window = Policy::template MakeSubKDramTileWindowPaged(
//                 k_dram_block_window,
//                 block_indices,
//                 params.stride_s_k,
//                 (i_block_n - 1) * kBlockN,
//                 params.page_block_size);
//
//             k_block_tile = load_tile(k_dram_window);
//             if constexpr(k0_loops > 1)
//             {
//                 ck_tile::static_for<0, k0_loops - 1, 1>{}([&](auto i_k0) {
//                     ck_tile::block_sync_lds();
//                     store_tile(k_st_lds_window, k_block_tile); // LDS write i + 1
//                     gemm_0(s_acc,
//                            ck_tile::get_slice_tile(q,
//                                           ck_tile::sequence<0, i_k0 * kBlockK0>{},
//                                           ck_tile::sequence<kBlockM, (i_k0 + 1) * kBlockK0>{}),
//                            k_block_tile);
//                     ck_tile::block_sync_lds();
//                     move_tile_window(k_dram_block_window, {0, kBlockK0});
//
//                     move_tile_window(k_st_lds_window, {0, kBlockK0}); // LDS write i + 1
//                     k_block_tile = load_tile(k_dram_window);                // global read i + 2
//                 });
//             }
//
//             {                                                 // tail
//                 gemm_0(s_acc,
//                        ck_tile::get_slice_tile(q,
//                                       ck_tile::sequence<0, (k0_loops - 1) * kBlockK0>{},
//                                       ck_tile::sequence<kBlockM, k0_loops * kBlockK0>{}),
//                        k_block_tile);
//             }
//
//             const bool is_masking_step = masking_step > 0;
//             const bool is_first_masking_step = masking_step == n_masking_steps;
//
//             // if seq_len == 1, never need to add mask to s
//             if (is_masking_step) {
//                 constexpr auto sacc_spans = decltype(s_acc)::get_distributed_spans();
//                 ck_tile::sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
//                     // constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                     ck_tile::sweep_tile_span(sacc_spans[I1], [&](auto idx1) {
//                         constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                         const auto tile_idx = get_x_indices_from_distributed_indices(
//                             s_acc.get_tile_distribution(), make_tuple(idx0, idx1));
//                         auto row_id = tile_idx.at(ck_tile::number<0>{});
//                         auto col_id = tile_idx.at(ck_tile::number<1>{});
//                         if constexpr (!Is_causal)
//                         {
//                             if (col_id >= int(seqlen_k - i_block_n * kBlockN))
//                                 s_acc(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//                         }
//                         else
//                         {
//                             int32_t col_limit_right = seqlen_k - 1 - i_block_n * kBlockN -
//                                 (params.size_s - 1 - (i_block_m * kBlockM + row_id)) / params.num_groups;
//                             if (col_id > col_limit_right)
//                                 s_acc(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//                         }
//                     });
//                 });
//             }
//
//             auto m_local = ck_tile::block_tile_reduce<acc_t>(
//                 s_acc,
//                 ck_tile::sequence<1>{},
//                 f_max,
//                 -ck_tile::numeric<acc_t>::infinity());
//             block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<true>{});
//
//             const auto m_old = m;
//
//             ck_tile::tile_elementwise_inout(
//                 [](auto& e0, auto e1, auto e2) { e0 = max(e1, e2); }, m, m_old, m_local);
//
//             auto p_compute = ck_tile::make_static_distributed_tensor<acc_t>(
//                 s_acc.get_tile_distribution());
//
//             constexpr auto p_spans = decltype(p_compute)::get_distributed_spans();
//             ck_tile::sweep_tile_span(p_spans[I0], [&](auto idx0) {
//                 constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                 auto row_max = params.scale_softmax_log2 * m[i_idx];
//                 ck_tile::sweep_tile_span(p_spans[I1], [&](auto idx1) {
//                     constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                     p_compute(i_j_idx) = exp2(params.scale_softmax_log2 * s_acc[i_j_idx] - row_max);
//                 });
//             });
//
//             ck_tile::store_tile(p_st_lds_window, ck_tile::cast_tile<scalar_t>(p_compute));
//
//             auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
//                 p_compute, ck_tile::sequence<1>{}, f_sum, acc_t{0});
//             ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<true>{});
//
//             // l{j}, Oacc{j}
//             constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
//             ck_tile::sweep_tile_span(o_spans[I0], [&](auto idx0) {
//                 constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                 const auto tmp = exp2(params.scale_softmax_log2 * m_old[i_idx] - params.scale_softmax_log2 * m[i_idx]);
//                 l(i_idx) = tmp * l[i_idx] + rowsum_p[i_idx];
//                 ck_tile::sweep_tile_span(o_spans[I1], [&](auto idx1) {
//                     constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                     o_acc(i_j_idx) = o_acc[i_j_idx] * tmp;
//                 });
//             });
//
// 			auto p_tile = load_tile(p_ld_lds_window);
//             auto v_tile = v_ld_lds_window.load();
// 			// auto p_tile = ck_tile::cast_tile<scalar_t>(p_compute);
//             if constexpr(k1_loops > 1)
//             {
//                 ck_tile::static_for<0, k1_loops - 1, 1>{}([&](auto i_k1) {
//                     ck_tile::block_sync_lds();
//                     gemm_1(o_acc,
//                            ck_tile::get_slice_tile(
//                                p_tile, ck_tile::sequence<0, i_k1 * kBlockK1>{}, ck_tile::sequence<kBlockM, (i_k1 + 1) * kBlockK1>{}),
//                            // v_ld_lds_window);
//                            v_tile);
//                     ck_tile::block_sync_lds();
//                     move_tile_window(v_ld_lds_window, {0, kBlockK1});
//                     auto v_tile = v_ld_lds_window.load();
//                 });
//             }
//             // tail
//             {
//                 ck_tile::block_sync_lds();
//                 gemm_1(o_acc,
//                        ck_tile::get_slice_tile(p_tile,
//                            ck_tile::sequence<0, (k1_loops - 1) * kBlockK1>{}, ck_tile::sequence<kBlockM, kBlockN>{}),
//                        // v_ld_lds_window);
//                        v_tile);
//                 ck_tile::block_sync_lds();
//             }
//             // // move K tile windows
//             // move_tile_window(k_dram_block_window, {kBlockN, 0});
//             // move_tile_window(k_ld_lds_window, {0, -kSizeD + kBlockK0});
//             // move_tile_window(v_ld_lds_window, {0, -kBlockN + kBlockK1});
//         }
//
//         // Epilogue
//         // auto lse_acc = ck_tile::make_static_distributed_tensor<acc_t>(m.get_tile_distribution());
//         // constexpr auto lse_acc_spans = decltype(lse_acc)::get_distributed_spans();
//         // ck_tile::sweep_tile_span(lse_acc_spans[I0], [&](auto idx0) {
//         //     constexpr auto i_idx = ck_tile::make_tuple(idx0);
//         //     lse_acc(i_idx) = m[i_idx] * params.scale_softmax + log(l[i_idx]);
//         // });
//         //
//         //
//         // if (NoSplit)
//         // {
//         //     const int32_t lse_offset = i_batch * params.size_s;
//         //     auto lse_dram_window = Policy::MakeLSEDramTileWindow(
//         //         reinterpret_cast<acc_t*>(params.p_softmax_lse) + lse_offset,
//         //         params.size_s,
//         //         i_m0);
//         //     ck_tile::store_tile(lse_dram_window, lse_acc);
//         // }
//         // else
//         // {
//         //     const int32_t split_offset = params.p_num_splits[i_batch];
//         //     const int32_t lseacc_offset =
//         //         ((split_offset + i_split) * params.size_h + i_nhead) *
//         //         params.size_s + i_block_m * kBlockM;
//         //     auto lseacc_dram_window = Policy::MakeLSEDramTileWindow(
//         //         reinterpret_cast<acc_t*>(params.p_softmax_lseaccum) + lseacc_offset,
//         //         params.size_s);
//         //     ck_tile::store_tile(lseacc_dram_window, lse_acc);
//         // }
//
//         __syncthreads();
//         constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
//         ck_tile::sweep_tile_span(o_spans[I0], [&](auto idx0) {
//             constexpr auto i_idx = ck_tile::make_tuple(idx0);
//             const auto tmp = [&]() {
//                     return l[i_idx] == 0.f ? 0.f : 1 / l[i_idx];
//             }();
//             ck_tile::sweep_tile_span(o_spans[I1], [&](auto idx1) {
//                 constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                 o_acc(i_j_idx) *= tmp;
//             });
//         });
//         if (NoSplit)
//         {
//             const int32_t o_offset = i_batch * params.stride_b_o;
//             auto o_dram_window = Policy::template MakeODramTileWindow<scalar_t>(
//                 reinterpret_cast<scalar_t*>(params.p_output) + o_offset,
//                 params.size_s,
//                 i_m0);
//             ck_tile::store_tile(o_dram_window, ck_tile::cast_tile<scalar_t>(o_acc));
//         }
//         else
//         {
//             const int32_t split_offset = params.p_num_splits[i_batch];
//             const int32_t oacc_offset =
//                 (((split_offset + i_split) * params.size_h + i_nhead) *
//                 params.size_s + i_block_m * kBlockM) * kSizeDV;
//             auto o_acc_dram_window = Policy::template MakeODramTileWindow<acc_t>(
//                 reinterpret_cast<acc_t*>(params.p_output_accum) + oacc_offset,
//                 params.size_s);
//             ck_tile::store_tile(o_acc_dram_window, o_acc);
//         }
// 		__syncthreads();
//     }
// }
// template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
// __launch_bounds__(256, 2)
// __global__ void flash_fwd_splitkv_mla_kernel_non_lds(
//     const FlashMlaFwdParams params)
// {
//     using Policy  = FlashMlaKernelPolicy<Traits, scalar_t, float>;
//
//     constexpr int32_t kSizeD             = Traits::kSizeD; 
//     constexpr int32_t kSizeDV            = Traits::kSizeDV; 
//     constexpr int32_t kNumThreads        = Traits::kNumThreads;
//     constexpr int32_t kNumThreadsSoftmax = Traits::kNumThreadsSoftmax;
//     constexpr int32_t kBlockM            = Traits::kBlockM;
//     constexpr int32_t kBlockN0           = Traits::kBlockN0;
//     constexpr int32_t kBlockN1           = Traits::kBlockN1;
//     constexpr int32_t kBlockK0          = Traits::kBlockK0;
//     constexpr int32_t kBlockK1           = Traits::kBlockK1;
//
//     constexpr int32_t kPackScalar = 16 / sizeof(scalar_t);
//     constexpr int32_t kPackAcc = 16 / sizeof(scalar_t);
//     constexpr int32_t kKPack = kPackScalar;
//
//     constexpr auto I0 = ck_tile::number<0>{};
//     constexpr auto I1 = ck_tile::number<1>{};
//
//     const int32_t i_block_m   = blockIdx.x;
//     const int32_t i_nhead     = blockIdx.y;
//     const int32_t i_nhead_k   = i_nhead / params.hq_hk_ratio;
//     const int32_t i_partition = blockIdx.z;
//
//     const ck_tile::index_t i_m0 = __builtin_amdgcn_readfirstlane(i_block_m * kBlockM);
//
//     const auto f_max = [](auto e0, auto e1) { return max(e0, e1); };
//     const auto f_sum = [](auto e0, auto e1) { return e0 + e1; };
//
//     __shared__ uint8_t shared_ptr[Policy::GetSmemSize()];
//
//     const int32_t tidx = threadIdx.x; 
//
//     constexpr ck_tile::index_t k0_loops = kSizeD / kBlockK0;
//     constexpr ck_tile::index_t k1_loops = kBlockN0 / kBlockK1;
//     constexpr ck_tile::index_t n1_loops = kSizeDV / kBlockN1;
//
//     // auto gemm_0 = Policy::GetQKBlockGemm();
//     auto gemm_0 = Policy::GetQKRopeBlockGemm();
//     auto gemm_1 = Policy::GetSubPVBlockGemm();
//
//     auto s_acc = gemm_0.MakeCBlockTile();
//     using SBlockTileType = decltype(ck_tile::cast_tile<acc_t>(s_acc));
//
//     using OaccBlockTileType = decltype(gemm_1.MakeCBlockTile());
//     OaccBlockTileType o_acc[n1_loops];
//     ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){ck_tile::clear_tile(o_acc[n1_id]);});
//
//     scalar_t* kv_lds_ptr = reinterpret_cast<scalar_t*>(shared_ptr);
//     acc_t* p_shuffle_ptr = reinterpret_cast<acc_t*>(shared_ptr + Policy::GetSmemSizeSingleKV());
//     // scalar_t* p_shuffle_ptr = kv_lds_ptr + Traits::kBlockN * Traits::kSizeDV * Traits::kStages;
//
//     TileSchedulerMetaData metadata;
//     reinterpret_cast<int4*>(&(metadata.data))[0] = reinterpret_cast<int4*>(
//         params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4];
//     reinterpret_cast<int4*>(&(metadata.data))[1] = reinterpret_cast<int4*>(
//         params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4 + 1];
//
//     const int32_t begin_batch_idx   = metadata.core.begin_batch_idx;
//     const int32_t begin_seqlen_idx  = metadata.core.begin_seqlen_idx;
//     const int32_t end_batch_idx     = metadata.core.end_batch_idx;
//     const int32_t end_seqlen_idx    = metadata.core.end_seqlen_idx;
//     const int32_t begin_n_split_idx = metadata.core.begin_n_split_idx;
//
//     auto p_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
//         p_shuffle_ptr, Policy::MakePShuffleLdsDescriptor());
//
//     auto p_st_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
//                             ck_tile::number<Traits::kBlockN0>{}), {0, 0});
//     auto p_ld_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
//                             ck_tile::number<Traits::kBlockN0>{}), {0, 0},
//         Policy::MakePShuffleTileDistribution());
//
//     // using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
//     //     SBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
//     // auto m = MLBlockTileType{};
//     // auto l = MLBlockTileType{};
//
//     using SInnerBlockTileType = decltype(p_ld_lds_window.load());
//     using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
//         SInnerBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
//     auto m = MLBlockTileType{};
//     auto l = MLBlockTileType{};
//
//     // auto q_default_dram_window = Policy::MakeQBlockDramTileWindow(
//     //     reinterpret_cast<scalar_t*>(params.p_query),
//     //     params.size_s,
//     //     params.stride_s_q);
//     // using QTile = decltype(q_default_dram_window.load());
//     // QTile q_tiles[k0_loops];
//
//     for (int32_t i_batch = begin_batch_idx; i_batch < end_batch_idx; ++i_batch)
//     // for (int32_t i_batch = begin_batch_idx; i_batch <= end_batch_idx; ++i_batch)
//     {
//         const int32_t i_split = i_batch == begin_batch_idx ? begin_n_split_idx : 0;
//         const int32_t seqlen_k    = params.p_cu_seqlens_k[i_batch];
//         const int32_t n_block_min = i_batch == begin_batch_idx ? begin_seqlen_idx / kBlockN0 : 0;
//         const int32_t n_block_max = i_batch == end_batch_idx ? ck_tile::integer_divide_ceil(end_seqlen_idx, kBlockN0) : ck_tile::integer_divide_ceil(seqlen_k, kBlockN0);
//         const bool NoSplit = n_block_min == 0 && n_block_max == ck_tile::integer_divide_ceil(seqlen_k, kBlockN0);
//         const int32_t split_seqlen_k_begin = i_batch == begin_batch_idx ? begin_seqlen_idx : 0;
//         const int32_t split_seqlen_k_end = i_batch == end_batch_idx ? end_seqlen_idx : seqlen_k;
//
//         int32_t i_block_n = n_block_max - 1;
//
//         const int32_t total_seqlen_kv = (n_block_max - n_block_min) * kBlockN0;
//
//         const int32_t q_offset = i_batch * params.stride_b_q +
//                                  i_block_m * kBlockM * params.stride_s_q +
//                                  i_nhead * params.stride_h_q;
//         auto q_dram_window = Policy::MakeQBlockDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_query) + q_offset,
//             params.size_s,
//             params.stride_s_q);
//         auto q = ck_tile::load_tile(q_dram_window);
//
//
//         if (i_batch > begin_batch_idx)
//         {
//             __syncthreads();
//         }
//
//         ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){ck_tile::clear_tile(o_acc[n1_id]);});
//         ck_tile::clear_tile(m);
//         ck_tile::clear_tile(l);
//
//         auto page_batch_offset = params.block_table_batch_stride * i_batch;
//         const auto* block_indices = params.p_block_table + page_batch_offset;
//         int32_t seqlen_k_begin = 0;
//         
//         auto [k_st_lds_window, k_ld_lds_window] = Policy::MakeKLdsTileWindow(kv_lds_ptr);
//         auto v_ld_lds_window = Policy::MakeVLdsTileWindow(kv_lds_ptr);
//         auto v_debug_lds_window = Policy::MakeVLdsDebugTileWindow(kv_lds_ptr);
//         // auto v_st_lds_window = Policy::MakeVStLdsTileWindow(kv_lds_ptr);
//
//
//         // using VTile = decltype(v_ld_lds_window.load());
//         // VTile v_tiles[n1_loops];
//
//         // auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
//         //     reinterpret_cast<scalar_t*>(shared_ptr), Policy::MakeKLdsBlockDescriptor());
//         // auto k_lds_window = ck_tile::make_tile_window(
//         //     k_lds, ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{}, ck_tile::number<Traits::kBlockK0>{}), {0, 0});
//
//         auto k_dram_block_window = Policy::MakeKSplitDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_key) +
//                 params.stride_h_k * i_nhead_k,
//             params.total_seqlen_kv,
//             params.stride_s_k,
//             seqlen_k_begin);
//
//         auto v_dram_block_window = Policy::MakeVSplitDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_key) +
//                 params.stride_h_k * i_nhead_k,
//             params.total_seqlen_kv,
//             params.stride_s_k,
//             seqlen_k_begin);
//
// 		//TODO: change into update offset
// 		auto [k_dram_window, v_dram_window] = Policy::template MakeSubKVDramTileWindowPaged(
// 			k_dram_block_window,
// 			v_dram_block_window,
// 			block_indices,
// 			params.stride_s_k,
// 			i_block_n * kBlockN0,
// 			params.page_block_size);
// 		using VBlockTileType = decltype(v_dram_window.load());
//         VBlockTileType v_block_tile[2];
//         // VBlockTileType v_block_tile;
//
//         constexpr int n_masking_steps = !Is_causal ? 1 : ck_tile::integer_divide_ceil(kBlockM, kBlockN0) + 1;
//         int masking_step = n_masking_steps;
//
//         constexpr ck_tile::array<int32_t, 2> qk_direction = {0, Traits::kBlockK0};
//         int k_ld_lds_offset = kBlockN0;
//         int k_st_lds_offset = kBlockN0;
//
// #pragma unroll 1
//         for (; i_block_n >= n_block_min; --masking_step, --i_block_n)
//         {
//             // --------------------------------------------------
//             {
//                 using KBlockTileType = decltype(k_dram_window.load());
//                 KBlockTileType k_block_tile[2]{ KBlockTileType{}, KBlockTileType{} };
//                 ck_tile::load_tile(k_block_tile[0], k_dram_window);
//                 ck_tile::move_tile_window(k_dram_window, {0, kBlockK0});
//                 ck_tile::store_tile(k_st_lds_window, k_block_tile[0]);
//                 // ck_tile::move_tile_window(k_st_lds_window, {k_st_lds_offset, 0});
//                 // k_st_lds_offset = -k_st_lds_offset ;
//
//                 // ck_tile::load_tile(v_tiles[0], v_ld_lds_window);
//
//                 ck_tile::load_tile(k_block_tile[1], k_dram_window);
//
//                 // auto b_shuffle_tmp = ck_tile::make_static_distributed_tensor<scalar_t>(
//                 //     Policy::MakeShuffledBRegTileDistribution());
//
//                 // ck_tile::transpose_tile2d(b_shuffle_tmp, k_block_tile[0]);
//
//                 if constexpr (k0_loops > 2)
//                 {
//                     ck_tile::static_for<0, k0_loops - 2, 1>{}(
//                         [&](auto i_k0)
//                         {
//                             ck_tile::block_sync_lds();
//                             gemm_0(s_acc,
//                                    ck_tile::get_slice_tile(q,
//                                                   ck_tile::sequence<0, i_k0 * kBlockK0>{},
//                                                   ck_tile::sequence<kBlockM, (i_k0 + 1) * kBlockK0>{}),
//                                    k_ld_lds_window);
//                                    // k_block_tile[i_k0 % 2]);
//
//                             // ck_tile::move_tile_window(k_ld_lds_window, {k_ld_lds_offset, 0});
//                             // k_ld_lds_offset = -k_ld_lds_offset;
//
//                             ck_tile::block_sync_lds();
//                             // pre-load k
//                             ck_tile::move_tile_window(k_dram_window, qk_direction);
//
//                             ck_tile::store_tile(k_st_lds_window, k_block_tile[(i_k0 + 1) % 2]);
//                             // ck_tile::move_tile_window(k_st_lds_window, {k_st_lds_offset, 0});
//                             // k_st_lds_offset = -k_st_lds_offset ;
//
//                             ck_tile::load_tile(k_block_tile[i_k0 % 2], k_dram_window);
//                             // ck_tile::load_tile(v_tiles[i_k0 + 1], v_ld_lds_window);
//                         });
//                 }
//
//                 // Tailing 2 tiles of QK GEMM_0
//                 ck_tile::load_tile(v_block_tile[0], v_dram_window);
//                 ck_tile::move_tile_window(v_dram_window, {0, kBlockN1});
//                 // v_block_tile = ck_tile::load_tile(v_dram_window);
//
//                 {
//                     ck_tile::block_sync_lds();
//                     gemm_0(s_acc,
//                            ck_tile::get_slice_tile(q,
//                                           ck_tile::sequence<0, (k0_loops - 2) * kBlockK0>{},
//                                           ck_tile::sequence<kBlockM, (k0_loops - 1) * kBlockK0>{}),
//                            k_ld_lds_window);
//                            // k_block_tile[(k0_loops - 2) % 2];
//
//                     // ck_tile::move_tile_window(k_ld_lds_window, {k_ld_lds_offset, 0});
//                     // k_ld_lds_offset = -k_ld_lds_offset;
//
//                     // ck_tile::block_sync_lds();
//                     ck_tile::store_tile(k_st_lds_window, k_block_tile[(k0_loops - 1) % 2]);
//
//                     ck_tile::block_sync_lds();
//                     gemm_0(s_acc,
//                            ck_tile::get_slice_tile(q,
//                                           ck_tile::sequence<0, (k0_loops - 1) * kBlockK0>{},
//                                           ck_tile::sequence<kBlockM, k0_loops * kBlockK0>{}),
//                            k_ld_lds_window);
//                            // k_block_tile[(k0_loops - 1) % 2]);
//                 }
//                 // --------------------------------------------------
//
//                 ck_tile::store_tile(p_st_lds_window, s_acc);
//                 k_dram_window.set_window_origin({0, 0});
// #ifdef ZZDebug
//                 __builtin_amdgcn_sched_barrier(0);
//                 if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 1 && i_batch == begin_batch_idx)
//                 {
//                     auto debug_k_dram = ck_tile::make_naive_tensor_view(
//                         reinterpret_cast<scalar_t*>(params.p_debug_value),
//                         ck_tile::make_tuple(kBlockN0, kBlockK0),
//                         ck_tile::make_tuple(kBlockK0, 1),  // strides
//                         ck_tile::number<8>{},
//                         I1);
//                     auto debug_k_window = ck_tile::make_tile_window(
//                         debug_k_dram,
//                         ck_tile::make_tuple(kBlockN0, Traits::kBlockK0),
//                         {0, 0});
//                     ck_tile::store_tile(debug_k_window, k_block_tile[0]);
//                     // ck_tile::store_tile(debug_k_window, b_shuffle_tmp);
//
//                     auto debug_s_dram = ck_tile::make_naive_tensor_view(
//                         reinterpret_cast<scalar_t*>(params.p_debug_p),
//                         ck_tile::make_tuple(kBlockM, kBlockN0),
//                         ck_tile::make_tuple(kBlockN0, 1),  // strides
//                         ck_tile::number<kBlockN0>{},
//                         I1);
//                     auto s_acc_inner = load_tile(p_ld_lds_window);
//                     auto debug_s_window = ck_tile::make_tile_window(
//                         debug_s_dram,
//                         ck_tile::make_tuple(kBlockM, kBlockN0),
//                         {0, 0});
//                     ck_tile::store_tile(debug_s_window, ck_tile::cast_tile<scalar_t>(s_acc_inner));
//                     // ck_tile::store_tile(debug_s_window, ck_tile::cast_tile<scalar_t>(s_acc));
//                 }
//                 __builtin_amdgcn_sched_barrier(0);
// #endif
//             }
//
//             const bool is_masking_step = masking_step > 0;
//             const bool is_first_masking_step = masking_step == n_masking_steps;
//
//             auto s_acc_inner = load_tile(p_ld_lds_window);
//
//             // if seq_len == 1, never need to add mask to s
//             if (is_masking_step) {
//                 constexpr auto sacc_spans = decltype(s_acc_inner)::get_distributed_spans();
//                 ck_tile::sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
//                     // constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                     ck_tile::sweep_tile_span(sacc_spans[I1], [&](auto idx1) {
//                         constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                         const auto tile_idx = get_x_indices_from_distributed_indices(
//                             s_acc_inner.get_tile_distribution(), make_tuple(idx0, idx1));
//                         auto row_id = tile_idx.at(ck_tile::number<0>{});
//                         auto col_id = tile_idx.at(ck_tile::number<1>{});
//                         if constexpr (!Is_causal)
//                         {
//                             if (col_id >= int(seqlen_k - i_block_n * kBlockN0))
//                                 s_acc_inner(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//                         }
//                         else
//                         {
//                             int32_t col_limit_right = seqlen_k - 1 - i_block_n * kBlockN0 -
//                                 (params.size_s - 1 - (i_block_m * kBlockM + row_id)) / params.num_groups;
//                             if (col_id > col_limit_right)
//                                 s_acc_inner(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//                         }
//                     });
//                 });
//             }
//
//             ck_tile::load_tile(v_block_tile[1], v_dram_window);
//             ck_tile::move_tile_window(v_dram_window, {0, kBlockN1});
//
//             auto m_local = ck_tile::block_tile_reduce<acc_t>(
//                 s_acc_inner,
//                 ck_tile::sequence<1>{},
//                 f_max,
//                 -ck_tile::numeric<acc_t>::infinity());
//             ck_tile::block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});
//
//             const auto m_old = m;
//
//             ck_tile::tile_elementwise_inout(
//                 [](auto& e0, auto e1, auto e2) { e0 = max(e1, e2); }, m, m_old, m_local);
//
//             auto p_compute = ck_tile::make_static_distributed_tensor<acc_t>(
//                 s_acc_inner.get_tile_distribution());
//
//             constexpr auto p_spans = decltype(p_compute)::get_distributed_spans();
//             ck_tile::sweep_tile_span(p_spans[I0], [&](auto idx0) {
//                 constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                 auto row_max = params.scale_softmax_log2 * m[i_idx];
//                 ck_tile::sweep_tile_span(p_spans[I1], [&](auto idx1) {
//                     constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                     p_compute(i_j_idx) = exp2(params.scale_softmax_log2 * s_acc_inner[i_j_idx] - row_max);
//                 });
//             });
//
//
//             auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
//                 p_compute, ck_tile::sequence<1>{}, f_sum, acc_t{0});
//             ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});
//
//             auto p_tile = ck_tile::cast_tile<scalar_t>(p_compute);
//
//             // l{j}, Oacc{j}
//             constexpr auto o_spans = ck_tile::remove_cvref_t<decltype(o_acc[0])>::get_distributed_spans();
//             ck_tile::sweep_tile_span(
//                 o_spans[ck_tile::number<0>{}],
//                 [&](auto id0)
//                 {
//                     constexpr auto i = ck_tile::make_tuple(id0);
//                     const auto temp_i = exp2(params.scale_softmax_log2 * m_old[i] - params.scale_softmax_log2 * m[i]);
//                     l(i) = temp_i * l[i] + rowsum_p[i];
//                     ck_tile::sweep_tile_span(
//                         o_spans[ck_tile::number<1>{}],
//                         [&](auto id1)
//                         {
//                             constexpr auto ij = ck_tile::make_tuple(id0, id1);
//                             ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){
// #if 1
//                                 acc_t o_acc_v = o_acc[n1_id](ij);
//                                 asm volatile("v_mul_f32 %[v_o_acc], %[v_tmp], %[v_o_acc]\n"
//                                             : [v_o_acc] "+v"(o_acc_v)
//                                             : [v_tmp] "v"(temp_i));
//                                 o_acc[n1_id](ij) = o_acc_v;
// #else
//                                 o_acc[n1_id](ij) *= temp_i;
// #endif
//                             });
//                         });
//                 });
//
//
//             ck_tile::static_for<0, n1_loops, 1>{}([&](auto i_n1) {
//                 auto v_shuffled = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledVRegBlockDescriptor());
//                 // ck_tile::shuffle_tile(v_shuffled, v_block_tile);
//                 // ck_tile::shuffle_tile(v_shuffled, v_block_tile[i_n1 % 2]);
//                 ck_tile::store_tile(v_ld_lds_window, v_shuffled);
//
//                 // auto v_tile = v_ld_lds_window.load();
//                 // if constexpr(k1_loops > 1)
//                 // {
//                 //     ck_tile::static_for<0, k1_loops - 1, 1>{}([&](auto i_k1) {
//                 //         ck_tile::block_sync_lds();
//                 //         gemm_1(o_acc[i_n1],
//                 //                ck_tile::get_slice_tile(
//                 //                    p_tile, ck_tile::sequence<0, i_k1 * kBlockK1>{},
//                 //                    ck_tile::sequence<kBlockM, (i_k1 + 1) * kBlockK1>{}),
//                 //                // v_tiles[i_n1]);
//                 //                v_ld_lds_window);
//                 //         ck_tile::block_sync_lds();
//                 //
//                 //         ck_tile::shuffle_tile(v_shuffled, v_tiles[i_n1 % 2]);
//                 //         ck_tile::store_tile(v_ld_lds_window, v_shuffled); // store the prefetch
//                 //     });
//                 // }
//                 // tail
//                 if constexpr (i_n1 < (n1_loops - 1))
//                 {
//                     ck_tile::load_tile(v_block_tile[i_n1 % 2], v_dram_window);
//                     // v_block_tile = ck_tile::load_tile(v_dram_window);
//                     ck_tile::move_tile_window(v_dram_window, {0, kBlockN1});
//                 }
//                 {
//                     ck_tile::block_sync_lds();
//                     gemm_1(o_acc[i_n1],
//                            p_tile,
//                            // ck_tile::get_slice_tile(p_tile,
//                            //     ck_tile::sequence<0, (k1_loops - 1) * kBlockK1>{},
//                            //     ck_tile::sequence<kBlockM, kBlockN0>{}),
//                            v_ld_lds_window);
//                            // v_tiles[i_n1]);
//                     ck_tile::block_sync_lds();
//                 }
//             });
//
// // #ifdef ZZDebug
// //             __builtin_amdgcn_sched_barrier(0);
// //             if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 1 && i_batch == begin_batch_idx)
// //             {
// //                 auto v_shuffled = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledVRegBlockDescriptor());
// //                 // ck_tile::shuffle_tile(v_shuffled, v_block_tile);
// //                 ck_tile::shuffle_tile(v_shuffled, v_block_tile[1]);
// //
// //                 auto debug_v_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_value),
// //                     ck_tile::make_tuple(kBlockN0, kBlockK0),
// //                     ck_tile::make_tuple(kBlockK0, 1),  // strides
// //                     ck_tile::number<8>{},
// //                     I1);
// //                 // auto debug_k_window = ck_tile::make_tile_window(
// //                 //     debug_k_dram,
// //                 //     ck_tile::make_tuple(kBlockN, kSizeDV),
// //                 //     {0, 0});
// //                 // ck_tile::store_tile(debug_k_window, k_block_tiles[k_ld_stage]);
// //
// //                 auto v_tile = ck_tile::load_tile(v_debug_lds_window);
// //                 auto debug_v_window = ck_tile::make_tile_window(
// //                     debug_v_dram,
// //                     ck_tile::make_tuple(kBlockN0, Traits::kBlockK0),
// //                     {0, 0});
// //                 ck_tile::store_tile(debug_v_window, v_block_tile[1]);
// //
// //                 auto debug_s_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_p),
// //                     ck_tile::make_tuple(kBlockM, kBlockN0),
// //                     ck_tile::make_tuple(kBlockN0, 1),  // strides
// //                     ck_tile::number<kBlockN0>{},
// //                     I1);
// //                 auto s_acc_inner = load_tile(p_ld_lds_window);
// //                 auto debug_s_window = ck_tile::make_tile_window(
// //                     debug_s_dram,
// //                     ck_tile::make_tuple(kBlockM, kBlockN0),
// //                     {0, 0});
// //                 ck_tile::store_tile(debug_s_window, ck_tile::cast_tile<scalar_t>(p_tile));
// //
// //
// //                 auto debug_o_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_output),
// //                     ck_tile::make_tuple(kBlockM, kBlockN1),
// //                     ck_tile::make_tuple(kBlockN1, 1),  // strides
// //                     ck_tile::number<8>{},
// //                     I1);
// //                 auto debug_o_window = ck_tile::make_tile_window(
// //                     debug_o_dram,
// //                     ck_tile::make_tuple(kBlockM, kBlockN1),
// //                     {0, 0});
// //                 ck_tile::store_tile(debug_o_window, ck_tile::cast_tile<scalar_t>(o_acc[0]));
// //
// //                 auto debug_m_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_m),
// //                     ck_tile::make_tuple(2 * kBlockM),
// //                     ck_tile::make_tuple(1),  // strides
// //                     ck_tile::number<1>{},
// //                     I1);
// //                 auto debug_m_window = ck_tile::make_tile_window(
// //                     debug_m_dram,
// //                     ck_tile::make_tuple(kBlockM),
// //                     {0});
// //                 ck_tile::store_tile(debug_m_window, ck_tile::cast_tile<scalar_t>(m));
// //
// //                 move_tile_window(debug_m_window, {kBlockM});
// //                 ck_tile::store_tile(debug_m_window, ck_tile::cast_tile<scalar_t>(m_local));
// //
// //             }
// //             __builtin_amdgcn_sched_barrier(0);
// // #endif
//
//             v_dram_window.set_window_origin({0, 0});
//             Policy::template UpdateSubKVDramTileWindow(
//                 k_dram_window,
//                 v_dram_window,
//                 block_indices,
//                 params.stride_s_k,
//                 (i_block_n - 1) * kBlockN0,
//                 params.page_block_size);
//         }
//
//         // Epilogue
//         auto lse_acc = ck_tile::make_static_distributed_tensor<acc_t>(m.get_tile_distribution());
//         constexpr auto lse_acc_spans = decltype(lse_acc)::get_distributed_spans();
//         ck_tile::sweep_tile_span(lse_acc_spans[I0], [&](auto idx0) {
//             constexpr auto i_idx = ck_tile::make_tuple(idx0);
//             lse_acc(i_idx) = m[i_idx] * params.scale_softmax + log(l[i_idx]);
//         });
//
//         if (NoSplit)
//         {
//             const int32_t lse_offset = i_batch * params.size_s;
//             auto lse_dram_window = Policy::MakeLSEDramTileWindow(
//                 reinterpret_cast<acc_t*>(params.p_softmax_lse) + lse_offset,
//                 params.size_s,
//                 i_m0);
//             ck_tile::store_tile(lse_dram_window, lse_acc);
//         }
//         else
//         {
//             const int32_t split_offset = params.p_num_splits[i_batch];
//             const int32_t lseacc_offset =
//                 ((split_offset + i_split) * params.size_h + i_nhead) *
//                 params.size_s + i_block_m * kBlockM;
//             auto lseacc_dram_window = Policy::MakeLSEDramTileWindow(
//                 reinterpret_cast<acc_t*>(params.p_softmax_lseaccum) + lseacc_offset,
//                 params.size_s);
//             ck_tile::store_tile(lseacc_dram_window, lse_acc);
//         }
//
//         __syncthreads();
//         constexpr auto o_spans = ck_tile::remove_cvref_t<decltype(o_acc[0])>::get_distributed_spans();;
//         ck_tile::sweep_tile_span(o_spans[ck_tile::number<0>{}], [&](auto id0) {
//             constexpr auto i = ck_tile::make_tuple(id0);
//             const auto tmp   = [&]() {
//                     return l[i] == 0.f ? 0.f : 1 / l[i];
//             }();
//             ck_tile::sweep_tile_span(o_spans[ck_tile::number<1>{}], [&](auto id1) {
//                 constexpr auto ij = ck_tile::make_tuple(id0, id1);
//                 ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id)
//                 {
// #if 1
//                     acc_t o_acc_v = o_acc[n1_id](ij);
//                     asm volatile("v_mul_f32 %[v_o_acc], %[v_tmp], %[v_o_acc]\n"
//                                  : [v_o_acc] "+v"(o_acc_v)
//                                  : [v_tmp] "v"(tmp));
//                     o_acc[n1_id](ij) = o_acc_v;
// #else
//                     o_acc[n1_id](ij) *= tmp;
// #endif
//                 });
//             });
//         });
//
//         if (NoSplit)
//         {
//             const int32_t o_offset = i_batch * params.stride_b_o;
//             auto o_dram_window = Policy::template MakeODramTileWindow<scalar_t>(
//                 reinterpret_cast<scalar_t*>(params.p_output) + o_offset,
//                 params.size_s,
//                 i_m0);
//             ck_tile::static_for<0, n1_loops, 1>{}(
//                 [&](auto n1_id){
//                     ck_tile::store_tile(o_dram_window, ck_tile::cast_tile<scalar_t>(o_acc[n1_id]));
//                     if constexpr (n1_id < (n1_loops - 1))
//                     {
//                         ck_tile::move_tile_window(o_dram_window, {0, Traits::kBlockN1});
//                     }
//                 }
//             );
//         }
//         else
//         {
//             const int32_t split_offset = params.p_num_splits[i_batch];
//             const int32_t oacc_offset =
//                 (((split_offset + i_split) * params.size_h + i_nhead) *
//                 params.size_s + i_block_m * kBlockM) * kSizeDV;
//             auto o_acc_dram_window = Policy::template MakeODramTileWindow<acc_t>(
//                 reinterpret_cast<acc_t*>(params.p_output_accum) + oacc_offset,
//                 params.size_s);
//             ck_tile::static_for<0, n1_loops, 1>{}(
//                 [&](auto n1_id){
//                     ck_tile::store_tile(o_acc_dram_window, ck_tile::cast_tile<acc_t>(o_acc[n1_id]));
//                     if constexpr (n1_id < (n1_loops - 1))
//                     {
//                         ck_tile::move_tile_window(o_acc_dram_window, {0, Traits::kBlockN1});
//                     }
//                 }
//             );
//         }
// 		__syncthreads();
//     }
// }
// template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
// __launch_bounds__(256, 2)
// __global__ void flash_fwd_splitkv_mla_kernel_non_lds(
//     const FlashMlaFwdParams params)
// {
//     using Policy  = FlashMlaKernelPolicy<Traits, scalar_t, float>;
//
//     constexpr int32_t kSizeD             = Traits::kSizeD; 
//     constexpr int32_t kSizeDV            = Traits::kSizeDV; 
//     constexpr int32_t kNumThreads        = Traits::kNumThreads;
//     constexpr int32_t kNumThreadsSoftmax = Traits::kNumThreadsSoftmax;
//     constexpr int32_t kBlockM            = Traits::kBlockM;
//     constexpr int32_t kBlockN0           = Traits::kBlockN0;
//     constexpr int32_t kBlockN1           = Traits::kBlockN1;
//     constexpr int32_t kBlockK0          = Traits::kBlockK0;
//     constexpr int32_t kBlockK1           = Traits::kBlockK1;
//
//     constexpr int32_t kPackScalar = 16 / sizeof(scalar_t);
//     constexpr int32_t kPackAcc = 16 / sizeof(scalar_t);
//     constexpr int32_t kKPack = kPackScalar;
//
//     constexpr auto I0 = ck_tile::number<0>{};
//     constexpr auto I1 = ck_tile::number<1>{};
//
//     const int32_t i_block_m   = blockIdx.x;
//     const int32_t i_nhead     = blockIdx.y;
//     const int32_t i_nhead_k   = i_nhead / params.hq_hk_ratio;
//     const int32_t i_partition = blockIdx.z;
//
//     const ck_tile::index_t i_m0 = __builtin_amdgcn_readfirstlane(i_block_m * kBlockM);
//
//     const auto f_max = [](auto e0, auto e1) { return max(e0, e1); };
//     const auto f_sum = [](auto e0, auto e1) { return e0 + e1; };
//
//     __shared__ uint8_t shared_ptr[Policy::GetSmemSize()];
//
//     const int32_t tidx = threadIdx.x; 
//
//     constexpr ck_tile::index_t k0_loops = kSizeD / kBlockK0;
//     constexpr ck_tile::index_t k1_loops = kBlockN0 / kBlockK1;
//     constexpr ck_tile::index_t n1_loops = kSizeDV / kBlockN1;
//
//     // auto gemm_0 = Policy::GetQKBlockGemm();
//     auto gemm_0 = Policy::GetQKRopeBlockGemm();
//     auto gemm_1 = Policy::GetSubPVBlockGemm();
//
//     auto s_acc = gemm_0.MakeCBlockTile();
//     using SBlockTileType = decltype(ck_tile::cast_tile<acc_t>(s_acc));
//
//     using OaccBlockTileType = decltype(gemm_1.MakeCBlockTile());
//     OaccBlockTileType o_acc[n1_loops];
//     ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){ck_tile::clear_tile(o_acc[n1_id]);});
//
//     scalar_t* kv_lds_ptr = reinterpret_cast<scalar_t*>(shared_ptr);
//     acc_t* p_shuffle_ptr = reinterpret_cast<acc_t*>(shared_ptr + Policy::GetSmemSizeSingleKV());
//     // scalar_t* p_shuffle_ptr = kv_lds_ptr + Traits::kBlockN * Traits::kSizeDV * Traits::kStages;
//
//     TileSchedulerMetaData metadata;
//     reinterpret_cast<int4*>(&(metadata.data))[0] = reinterpret_cast<int4*>(
//         params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4];
//     reinterpret_cast<int4*>(&(metadata.data))[1] = reinterpret_cast<int4*>(
//         params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4 + 1];
//
//     const int32_t begin_batch_idx   = metadata.core.begin_batch_idx;
//     const int32_t begin_seqlen_idx  = metadata.core.begin_seqlen_idx;
//     const int32_t end_batch_idx     = metadata.core.end_batch_idx;
//     const int32_t end_seqlen_idx    = metadata.core.end_seqlen_idx;
//     const int32_t begin_n_split_idx = metadata.core.begin_n_split_idx;
//
//     auto p_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
//         p_shuffle_ptr, Policy::MakePShuffleLdsDescriptor());
//
//     auto p_st_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
//                             ck_tile::number<Traits::kBlockN0>{}), {0, 0});
//     auto p_ld_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
//                             ck_tile::number<Traits::kBlockN0>{}), {0, 0},
//         Policy::MakePShuffleTileDistribution());
//
//     auto scale_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
//         p_shuffle_ptr, Policy::MakeScaleShuffleLdsDescriptor());
//     using ShuffleMLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
//         OaccBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
//     auto scale_st_lds_window = ck_tile::make_tile_window(scale_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}/* , ck_tile::number<4>{} */),
// 						    {0/* , 0 */});
//     auto scale_lds_window = ck_tile::make_tile_window(scale_shuffle_lds,
//         ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}/* , ck_tile::number<4>{} */),
// 						    {0/* , 0 */},
//         ShuffleMLBlockTileType::get_tile_distribution());
//
//     using SInnerBlockTileType = decltype(p_ld_lds_window.load());
//     using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
//         SInnerBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
//     auto m = MLBlockTileType{};
//     auto l = MLBlockTileType{};
//
//     // auto q_default_dram_window = Policy::MakeQBlockDramTileWindow(
//     //     reinterpret_cast<scalar_t*>(params.p_query),
//     //     params.size_s,
//     //     params.stride_s_q);
//     // using QTile = decltype(q_default_dram_window.load());
//     // QTile q_tiles[k0_loops];
//
//     for (int32_t i_batch = begin_batch_idx; i_batch <= end_batch_idx; ++i_batch)
//     {
//         const int32_t i_split = i_batch == begin_batch_idx ? begin_n_split_idx : 0;
//         const int32_t seqlen_k    = params.p_cu_seqlens_k[i_batch];
//         const int32_t n_block_min = i_batch == begin_batch_idx ? begin_seqlen_idx / kBlockN0 : 0;
//         const int32_t n_block_max = i_batch == end_batch_idx ? ck_tile::integer_divide_ceil(end_seqlen_idx, kBlockN0) : ck_tile::integer_divide_ceil(seqlen_k, kBlockN0);
//         const bool NoSplit = n_block_min == 0 && n_block_max == ck_tile::integer_divide_ceil(seqlen_k, kBlockN0);
//         const int32_t split_seqlen_k_begin = i_batch == begin_batch_idx ? begin_seqlen_idx : 0;
//         const int32_t split_seqlen_k_end = i_batch == end_batch_idx ? end_seqlen_idx : seqlen_k;
//
//         int32_t i_block_n = n_block_max - 1;
//
//         const int32_t q_offset = i_batch * params.stride_b_q +
//                                  i_block_m * kBlockM * params.stride_s_q +
//                                  i_nhead * params.stride_h_q;
//         auto q_dram_window = Policy::MakeQBlockDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_query) + q_offset,
//             params.size_s,
//             params.stride_s_q);
//         auto q = ck_tile::load_tile(q_dram_window);
//
//
//         if (i_batch > begin_batch_idx)
//         {
//             __syncthreads();
//         }
//
//         ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){ck_tile::clear_tile(o_acc[n1_id]);});
//         ck_tile::clear_tile(m);
//         ck_tile::clear_tile(l);
//
//         auto page_batch_offset = params.block_table_batch_stride * i_batch;
//         const auto* block_indices = params.p_block_table + page_batch_offset;
//         int32_t seqlen_k_begin = 0;
//         
//         auto [k_st_lds_window, k_ld_lds_window] = Policy::MakeKLdsTileWindow(kv_lds_ptr);
//         auto v_ld_lds_window = Policy::MakeVLdsTileWindow(kv_lds_ptr);
//         auto v_debug_lds_window = Policy::MakeVLdsDebugTileWindow(kv_lds_ptr);
//         // auto v_st_lds_window = Policy::MakeVStLdsTileWindow(kv_lds_ptr);
//
//
//         // using VTile = decltype(v_ld_lds_window.load());
//         using VTile = decltype(ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledBRegTileDistribution()));
//         VTile v_tiles[n1_loops];
//
//         // auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
//         //     reinterpret_cast<scalar_t*>(shared_ptr), Policy::MakeKLdsBlockDescriptor());
//         // auto k_lds_window = ck_tile::make_tile_window(
//         //     k_lds, ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{}, ck_tile::number<Traits::kBlockK0>{}), {0, 0});
//
//         auto k_dram_block_window = Policy::MakeKSplitDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_key) + params.stride_h_k * i_nhead_k,
//             params.total_seqlen_kv,
//             params.stride_s_k,
//             seqlen_k_begin);
//
//         auto v_dram_block_window = Policy::MakeVSplitDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_key) + params.stride_h_k * i_nhead_k,
//             params.total_seqlen_kv,
//             params.stride_s_k,
//             seqlen_k_begin);
//
// 		//TODO: change into update offset
// 		auto [k_dram_window, v_dram_window] = Policy::template MakeSubKVDramTileWindowPaged(
// 			k_dram_block_window,
//             v_dram_block_window,
// 			block_indices,
// 			params.stride_s_k,
// 			i_block_n * kBlockN0,
// 			params.page_block_size);
// 		using VBlockTileType = decltype(v_dram_window.load());
//         VBlockTileType v_block_tile[2] { VBlockTileType{}, VBlockTileType{} };
//
//         constexpr int n_masking_steps = !Is_causal ? 1 : ck_tile::integer_divide_ceil(kBlockM, kBlockN0) + 1;
//         int masking_step = n_masking_steps;
//
//         constexpr ck_tile::array<int32_t, 2> qk_direction = {0, Traits::kBlockK0};
//         int k_ld_lds_offset = kBlockN0;
//         int k_st_lds_offset = kBlockN0;
//
//         using KBlockTileType = decltype(k_dram_window.load());
//         KBlockTileType k_block_tile[2]{ KBlockTileType{}, KBlockTileType{} };
//
//
// #pragma unroll 1
//         for (; i_block_n >= n_block_min; --masking_step, --i_block_n)
//         {
//
// 			ck_tile::clear_tile(s_acc);
//
//             // --------------------------------------------------
//             {
//                 ck_tile::load_tile(k_block_tile[0], k_dram_window);
//                 ck_tile::move_tile_window(k_dram_window, {0, kBlockK0});
//                 ck_tile::store_tile(k_st_lds_window, k_block_tile[0]);
//                 ck_tile::move_tile_window(k_st_lds_window, {k_st_lds_offset, 0});
//                 k_st_lds_offset = -k_st_lds_offset ;
//
//                 ck_tile::load_tile(k_block_tile[1], k_dram_window);
//                 if constexpr (k0_loops > 2)
//                 {
//                     ck_tile::static_for<0, k0_loops - 2, 1>{}(
//                         [&](auto i_k0)
//                         {
//                             ck_tile::block_sync_lds();
//                             gemm_0(s_acc,
//                                    ck_tile::get_slice_tile(q,
//                                                   ck_tile::sequence<0, i_k0 * kBlockK0>{},
//                                                   ck_tile::sequence<kBlockM, (i_k0 + 1) * kBlockK0>{}),
//                                    k_ld_lds_window);
//
//                             ck_tile::move_tile_window(k_ld_lds_window, {k_ld_lds_offset, 0});
//                             k_ld_lds_offset = -k_ld_lds_offset;
//
//                             // ck_tile::block_sync_lds();
//                             // pre-load k
//                             ck_tile::move_tile_window(k_dram_window, qk_direction);
//
//                             ck_tile::store_tile(k_st_lds_window, k_block_tile[(i_k0 + 1) % 2]);
//                             ck_tile::move_tile_window(k_st_lds_window, {k_st_lds_offset, 0});
//                             k_st_lds_offset = -k_st_lds_offset ;
//
//                             ck_tile::load_tile(k_block_tile[i_k0 % 2], k_dram_window);
//                         });
//                 }
//
//                 // Tailing 2 tiles of QK GEMM_0
//                 ck_tile::load_tile(v_block_tile[0], v_dram_window);
//                 ck_tile::move_tile_window(v_dram_window, {kBlockN1, 0});
//
//                 {
//                     // ck_tile::block_sync_lds();
//                     gemm_0(s_acc,
//                            ck_tile::get_slice_tile(q,
//                                           ck_tile::sequence<0, (k0_loops - 2) * kBlockK0>{},
//                                           ck_tile::sequence<kBlockM, (k0_loops - 1) * kBlockK0>{}),
//                            k_ld_lds_window);
//                            // k_block_tile[(k0_loops - 2) % 2];
//
//                     ck_tile::move_tile_window(k_ld_lds_window, {k_ld_lds_offset, 0});
//                     k_ld_lds_offset = -k_ld_lds_offset;
//
//                     // ck_tile::block_sync_lds();
//                     ck_tile::store_tile(k_st_lds_window, k_block_tile[(k0_loops - 1) % 2]);
//
//                     ck_tile::block_sync_lds();
//                     gemm_0(s_acc,
//                            ck_tile::get_slice_tile(q,
//                                           ck_tile::sequence<0, (k0_loops - 1) * kBlockK0>{},
//                                           ck_tile::sequence<kBlockM, k0_loops * kBlockK0>{}),
//                            k_ld_lds_window);
//                            // k_block_tile[(k0_loops - 1) % 2]);
//                 }
//                 // --------------------------------------------------
//
//                 ck_tile::store_tile(p_st_lds_window, s_acc);
//                 k_dram_window.set_window_origin({0, 0});
//
// // #ifdef ZZDebug
// //                 __builtin_amdgcn_sched_barrier(0);
// //                 // if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 1 && i_batch == begin_batch_idx)
// //                 if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 2 && i_batch == begin_batch_idx)
// //                 {
// //                     auto debug_k_dram = ck_tile::make_naive_tensor_view(
// //                         reinterpret_cast<scalar_t*>(params.p_debug_value),
// //                         ck_tile::make_tuple(kBlockN0, kBlockK0),
// //                         ck_tile::make_tuple(kBlockK0, 1),  // strides
// //                         ck_tile::number<8>{},
// //                         I1);
// //                     auto debug_k_window = ck_tile::make_tile_window(
// //                         debug_k_dram,
// //                         ck_tile::make_tuple(kBlockN0, Traits::kBlockK0),
// //                         {0, 0});
// //
// //                     auto v_tile = ck_tile::load_tile(v_debug_lds_window);
// //                     auto k_debug_lds_window = Policy::MakeKLdsDebugTileWindow(kv_lds_ptr);
// //                     auto k_debug_tile = ck_tile::load_tile(k_debug_lds_window);
// //
// //                     ck_tile::store_tile(debug_k_window, k_debug_tile);
// //
// //                     // ck_tile::store_tile(debug_k_window, v_tiles[0]);
// //
// //                     auto debug_s_dram = ck_tile::make_naive_tensor_view(
// //                         reinterpret_cast<scalar_t*>(params.p_debug_p),
// //                         ck_tile::make_tuple(kBlockM, kBlockN0),
// //                         ck_tile::make_tuple(kBlockN0, 1),  // strides
// //                         ck_tile::number<kBlockN0>{},
// //                         I1);
// //                     auto s_acc_inner = load_tile(p_ld_lds_window);
// //                     auto debug_s_window = ck_tile::make_tile_window(
// //                         debug_s_dram,
// //                         ck_tile::make_tuple(kBlockM, kBlockN0),
// //                         {0, 0});
// //                     ck_tile::store_tile(debug_s_window, ck_tile::cast_tile<scalar_t>(s_acc));
// //                 }
// //                 __builtin_amdgcn_sched_barrier(0);
// // #endif
//             }
//
//             const bool is_masking_step = masking_step > 0;
//             const bool is_first_masking_step = masking_step == n_masking_steps;
//
// 			ck_tile::block_sync_lds();
//             auto s_acc_inner = load_tile(p_ld_lds_window);
// 			ck_tile::block_sync_lds();
//
//             // if seq_len == 1, never need to add mask to s
//             if (is_masking_step) {
//                 constexpr auto sacc_spans = decltype(s_acc_inner)::get_distributed_spans();
//                 ck_tile::sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
//                     // constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                     ck_tile::sweep_tile_span(sacc_spans[I1], [&](auto idx1) {
//                         constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                         const auto tile_idx = get_x_indices_from_distributed_indices(
//                             s_acc_inner.get_tile_distribution(), make_tuple(idx0, idx1));
//                         auto row_id = tile_idx.at(ck_tile::number<0>{});
//                         auto col_id = tile_idx.at(ck_tile::number<1>{});
//                         if constexpr (!Is_causal)
//                         {
//                             if (col_id >= int(seqlen_k - i_block_n * kBlockN0))
//                                 s_acc_inner(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//                         }
//                         else
//                         {
//                             int32_t col_limit_right = seqlen_k - 1 - i_block_n * kBlockN0 -
//                                 (params.size_s - 1 - (i_block_m * kBlockM + row_id)) / params.num_groups;
//                             if (col_id > col_limit_right)
//                                 s_acc_inner(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//                         }
//                     });
//                 });
//             }
//
//             ck_tile::load_tile(v_block_tile[1], v_dram_window);
//             ck_tile::move_tile_window(v_dram_window, {kBlockN1, 0});
//
//             auto m_local = ck_tile::block_tile_reduce<acc_t>(
//                 s_acc_inner,
//                 ck_tile::sequence<1>{},
//                 f_max,
//                 -ck_tile::numeric<acc_t>::infinity());
//             ck_tile::block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});
//
//             const auto m_old = m;
//
//             ck_tile::tile_elementwise_inout(
//                 [](auto& e0, auto e1, auto e2) { e0 = max(e1, e2); }, m, m_old, m_local);
//
//             auto p_compute = ck_tile::make_static_distributed_tensor<acc_t>(
//                 s_acc_inner.get_tile_distribution());
//
//             constexpr auto p_spans = decltype(p_compute)::get_distributed_spans();
//             ck_tile::sweep_tile_span(p_spans[I0], [&](auto idx0) {
//                 constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                 auto row_max = params.scale_softmax_log2 * m[i_idx];
//                 ck_tile::sweep_tile_span(p_spans[I1], [&](auto idx1) {
//                     constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                     p_compute(i_j_idx) = exp2(params.scale_softmax_log2 * s_acc_inner[i_j_idx] - row_max);
//                 });
//             });
//
//
//             auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
//                 p_compute, ck_tile::sequence<1>{}, f_sum, acc_t{0});
//             ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});
//
//             ck_tile::sweep_tile_span(p_spans[I0], [&](auto idx0) {
//                 constexpr auto i = ck_tile::make_tuple(idx0);
//                 auto temp_i = exp2(params.scale_softmax_log2 * (m_old[i] - m[i]));
//                 l(i) = temp_i * l[i] + rowsum_p[i];
//                 rowsum_p(i) = temp_i;
//             });
//
// 			ck_tile::block_sync_lds();
// 			ck_tile::store_tile(scale_st_lds_window, rowsum_p);
// 			ck_tile::block_sync_lds();
// 			auto temp_scale = ck_tile::load_tile(scale_lds_window);
// 			ck_tile::block_sync_lds();
//
//             // l{j}, Oacc{j}
//             constexpr auto o_spans = ck_tile::remove_cvref_t<decltype(o_acc[0])>::get_distributed_spans();
//             ck_tile::sweep_tile_span(o_spans[I0], [&](auto id0) {
//                 constexpr auto i = ck_tile::make_tuple(id0);
//                 // const auto temp_i = exp2(params.scale_softmax_log2 * (m_old[i] - m[i]));
//                 // l(i) = temp_i * l[i] + rowsum_p[i];
//
//                 ck_tile::sweep_tile_span(o_spans[I1], [&](auto id1) {
//                     constexpr auto ij = ck_tile::make_tuple(id0, id1);
// 					const auto tile_idx = get_x_indices_from_distributed_indices(o_acc[0].get_tile_distribution(), ij);
// 					// if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0)
// 					// 	printf("tid:%d o_acc [%d, %d]: %f scale: %f \n", threadIdx.x, tile_idx.at(I0), tile_idx.at(I1), ck_tile::type_convert<float>(o_acc[0][ij]), temp_scale[i]);
//
//                     ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){
// #if 1
//                         acc_t o_acc_v = o_acc[n1_id](ij);
//                         asm volatile("v_mul_f32 %[v_o_acc], %[v_tmp], %[v_o_acc]\n"
//                                     : [v_o_acc] "+v"(o_acc_v)
//                                     : [v_tmp] "v"(temp_scale[i]));
//                                     // : [v_tmp] "v"(rowsum_p[i]));
//                         o_acc[n1_id](ij) = o_acc_v;
// #else
//                         // o_acc[n1_id](ij) *= temp_i;
//                         o_acc[n1_id](ij) *= rowsum_p[i];
// #endif
//                     });
//                 });
//             });
//
// #ifdef ZZDebug
//             __syncthreads();
//             // if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 1 && i_batch == begin_batch_idx)
//             if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 3 && i_batch == begin_batch_idx)
//             {
//                 auto v_shuffled = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledVRegBlockDescriptor());
//                 // ck_tile::shuffle_tile(v_shuffled, v_block_tile);
//                 ck_tile::shuffle_tile(v_shuffled, v_block_tile[0]);
//
//                 auto debug_v_dram = ck_tile::make_naive_tensor_view(
//                     reinterpret_cast<scalar_t*>(params.p_debug_value),
//                     ck_tile::make_tuple(kBlockN0, kBlockK0),
//                     ck_tile::make_tuple(kBlockK0, 1),  // strides
//                     ck_tile::number<8>{},
//                     I1);
//                 // auto debug_k_window = ck_tile::make_tile_window(
//                 //     debug_k_dram,
//                 //     ck_tile::make_tuple(kBlockN, kSizeDV),
//                 //     {0, 0});
//                 // ck_tile::store_tile(debug_k_window, k_block_tiles[k_ld_stage]);
//
//                 auto v_tile = ck_tile::load_tile(v_debug_lds_window);
//                 auto debug_v_window = ck_tile::make_tile_window(
//                     debug_v_dram,
//                     ck_tile::make_tuple(kBlockM, Traits::kBlockK0),
//                     {0, 0});
//                 ck_tile::store_tile(debug_v_window, ck_tile::cast_tile<scalar_t>(o_acc[0]));
//
//
//             }
// 			// ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){ck_tile::clear_tile(o_acc[n1_id]);});
//             __syncthreads();
//
// #endif
//             auto p_tile = ck_tile::cast_tile<scalar_t>(p_compute);
//
//             ck_tile::static_for<0, n1_loops, 1>{}([&](auto i_n1) {
//                 auto v_shuffled = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledVRegBlockDescriptor());
//                 ck_tile::shuffle_tile(v_shuffled, v_block_tile[i_n1 % 2]);
//                 ck_tile::store_tile(v_ld_lds_window, v_shuffled);
//                 // ck_tile::store_tile(v_ld_lds_window, v_block_tile[i_n1 % 2]);
//
//                 // auto v_tile = v_ld_lds_window.load();
//                 // if constexpr(k1_loops > 1)
//                 // {
//                 //     ck_tile::static_for<0, k1_loops - 1, 1>{}([&](auto i_k1) {
//                 //         ck_tile::block_sync_lds();
//                 //         gemm_1(o_acc[i_n1],
//                 //                ck_tile::get_slice_tile(
//                 //                    p_tile, ck_tile::sequence<0, i_k1 * kBlockK1>{},
//                 //                    ck_tile::sequence<kBlockM, (i_k1 + 1) * kBlockK1>{}),
//                 //                // v_tiles[i_n1]);
//                 //                v_ld_lds_window);
//                 //         ck_tile::block_sync_lds();
//                 //
//                 //         ck_tile::shuffle_tile(v_shuffled, v_tiles[i_n1 % 2]);
//                 //         ck_tile::store_tile(v_ld_lds_window, v_shuffled); // store the prefetch
//                 //     });
//                 // }
//                 // // tail
// 				ck_tile::block_sync_lds();
//                 if constexpr (i_n1 < (n1_loops - 2))
//                 {
//                     ck_tile::load_tile(v_block_tile[i_n1 % 2], v_dram_window);
//                     ck_tile::move_tile_window(v_dram_window, {kBlockN1, 0});
//                 }
//                 {
//                     ck_tile::block_sync_lds();
//                     gemm_1(o_acc[i_n1],
//                            ck_tile::get_slice_tile(p_tile,
//                                ck_tile::sequence<0, (k1_loops - 1) * kBlockK1>{},
//                                ck_tile::sequence<kBlockM, kBlockN0>{}),
//                            v_ld_lds_window);
//                     ck_tile::block_sync_lds();
//                 }
//             });
//
// // #ifdef ZZDebug
// //             __syncthreads();
// //             // if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 1 && i_batch == begin_batch_idx)
// //             if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 3 && i_batch == begin_batch_idx)
// //             {
// //                 // auto v_shuffled = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledVRegBlockDescriptor());
// //                 // // ck_tile::shuffle_tile(v_shuffled, v_block_tile);
// //                 // ck_tile::shuffle_tile(v_shuffled, v_block_tile[0]);
// //                 //
// //                 // auto debug_v_dram = ck_tile::make_naive_tensor_view(
// //                 //     reinterpret_cast<scalar_t*>(params.p_debug_value),
// //                 //     ck_tile::make_tuple(kBlockN0, kBlockK0),
// //                 //     ck_tile::make_tuple(kBlockK0, 1),  // strides
// //                 //     ck_tile::number<8>{},
// //                 //     I1);
// //                 // // auto debug_k_window = ck_tile::make_tile_window(
// //                 // //     debug_k_dram,
// //                 // //     ck_tile::make_tuple(kBlockN, kSizeDV),
// //                 // //     {0, 0});
// //                 // // ck_tile::store_tile(debug_k_window, k_block_tiles[k_ld_stage]);
// //                 //
// //                 // auto v_tile = ck_tile::load_tile(v_debug_lds_window);
// //                 // auto debug_v_window = ck_tile::make_tile_window(
// //                 //     debug_v_dram,
// //                 //     ck_tile::make_tuple(kBlockN0, Traits::kBlockK0),
// //                 //     {0, 0});
// //                 // ck_tile::store_tile(debug_v_window, v_tile);
// //
// //                 auto debug_s_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_p),
// //                     ck_tile::make_tuple(kBlockM, kBlockN0),
// //                     ck_tile::make_tuple(kBlockN0, 1),  // strides
// //                     ck_tile::number<kBlockN0>{},
// //                     I1);
// //                 auto s_acc_inner = load_tile(p_ld_lds_window);
// //                 auto debug_s_window = ck_tile::make_tile_window(
// //                     debug_s_dram,
// //                     ck_tile::make_tuple(kBlockM, kBlockN0),
// //                     {0, 0});
// //                 ck_tile::store_tile(debug_s_window, ck_tile::cast_tile<scalar_t>(p_tile));
// //
// //
// //                 auto debug_o_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_output),
// //                     ck_tile::make_tuple(kBlockM, kBlockN1),
// //                     ck_tile::make_tuple(kBlockN1, 1),  // strides
// //                     ck_tile::number<8>{},
// //                     I1);
// //                 auto debug_o_window = ck_tile::make_tile_window(
// //                     debug_o_dram,
// //                     ck_tile::make_tuple(kBlockM, kBlockN1),
// //                     {0, 0});
// //                 ck_tile::store_tile(debug_o_window, ck_tile::cast_tile<scalar_t>(o_acc[0]));
// //
// //                 auto debug_m_dram = ck_tile::make_naive_tensor_view(
// //                     reinterpret_cast<scalar_t*>(params.p_debug_m),
// //                     ck_tile::make_tuple(2 * kBlockM),
// //                     ck_tile::make_tuple(1),  // strides
// //                     ck_tile::number<1>{},
// //                     I1);
// //                 auto debug_m_window = ck_tile::make_tile_window(
// //                     debug_m_dram,
// //                     ck_tile::make_tuple(kBlockM),
// //                     {0});
// //                 // ck_tile::store_tile(debug_m_window, ck_tile::cast_tile<scalar_t>(m));
// //                 ck_tile::store_tile(debug_m_window, ck_tile::cast_tile<scalar_t>(rowsum_p));
// //
// //                 move_tile_window(debug_m_window, {kBlockM});
// //                 // ck_tile::store_tile(debug_m_window, ck_tile::cast_tile<scalar_t>(rowsum_p));
// //                 ck_tile::store_tile(debug_m_window, ck_tile::cast_tile<scalar_t>(temp_scale));
// //
// //             }
// //             __builtin_amdgcn_sched_barrier(0);
// // #endif
//
//             v_dram_window.set_window_origin({0, 0});
//             Policy::template UpdateSubKVDramTileWindow(
//                 k_dram_window,
//                 v_dram_window,
//                 block_indices,
//                 params.stride_s_k,
//                 (i_block_n - 1) * kBlockN0,
//                 params.page_block_size);
//         }
//
//         // Epilogue
//         auto lse_acc = ck_tile::make_static_distributed_tensor<acc_t>(m.get_tile_distribution());
//         constexpr auto lse_acc_spans = decltype(lse_acc)::get_distributed_spans();
//         ck_tile::sweep_tile_span(lse_acc_spans[I0], [&](auto idx0) {
//             constexpr auto i_idx = ck_tile::make_tuple(idx0);
//             lse_acc(i_idx) = m[i_idx] * params.scale_softmax + log(l[i_idx]);
//         });
//
//         if (NoSplit)
//         {
//             const int32_t lse_offset = i_batch * params.size_s;
//             auto lse_dram_window = Policy::MakeLSEDramTileWindow(
//                 reinterpret_cast<acc_t*>(params.p_softmax_lse) + lse_offset,
//                 params.size_s,
//                 i_m0);
//             ck_tile::store_tile(lse_dram_window, lse_acc);
//         }
//         else
//         {
//             const int32_t split_offset = params.p_num_splits[i_batch];
//             const int32_t lseacc_offset =
//                 ((split_offset + i_split) * params.size_h + i_nhead) *
//                 params.size_s + i_block_m * kBlockM;
//             auto lseacc_dram_window = Policy::MakeLSEDramTileWindow(
//                 reinterpret_cast<acc_t*>(params.p_softmax_lseaccum) + lseacc_offset,
//                 params.size_s);
//             ck_tile::store_tile(lseacc_dram_window, lse_acc);
//         }
//
// 		ck_tile::store_tile(scale_st_lds_window, l);
// 		ck_tile::block_sync_lds();
// 		auto new_l = ck_tile::load_tile(scale_lds_window);
// 		ck_tile::block_sync_lds();
//
//         __syncthreads();
//         constexpr auto o_spans = ck_tile::remove_cvref_t<decltype(o_acc[0])>::get_distributed_spans();;
//         ck_tile::sweep_tile_span(o_spans[ck_tile::number<0>{}], [&](auto id0) {
//             constexpr auto i = ck_tile::make_tuple(id0);
//             const auto tmp   = [&]() {
//                     return new_l[i] == 0.f ? 0.f : 1 / new_l[i];
//                     // return l[i] == 0.f ? 0.f : 1 / l[i];
//             }();
//             ck_tile::sweep_tile_span(o_spans[ck_tile::number<1>{}], [&](auto id1) {
//                 constexpr auto ij = ck_tile::make_tuple(id0, id1);
//                 ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id)
//                 {
// #if 1
//                     acc_t o_acc_v = o_acc[n1_id](ij);
//                     asm volatile("v_mul_f32 %[v_o_acc], %[v_tmp], %[v_o_acc]\n"
//                                  : [v_o_acc] "+v"(o_acc_v)
//                                  : [v_tmp] "v"(tmp));
//                     o_acc[n1_id](ij) = o_acc_v;
// #else
//                     o_acc[n1_id](ij) *= tmp;
// #endif
//                 });
//             });
//         });
//
//         if (NoSplit)
//         {
//             const int32_t o_offset = i_batch * params.stride_b_o;
//             auto o_dram_window = Policy::template MakeODramTileWindow<scalar_t>(
//                 reinterpret_cast<scalar_t*>(params.p_output) + o_offset,
//                 params.size_s,
//                 i_m0);
//             ck_tile::static_for<0, n1_loops, 1>{}(
//                 [&](auto n1_id){
//                     ck_tile::store_tile(o_dram_window, ck_tile::cast_tile<scalar_t>(o_acc[n1_id]));
//                     if constexpr (n1_id < (n1_loops - 1))
//                     {
//                         ck_tile::move_tile_window(o_dram_window, {0, Traits::kBlockN1});
//                     }
//                 }
//             );
//         }
//         else
//         {
//             const int32_t split_offset = params.p_num_splits[i_batch];
//             const int32_t oacc_offset =
//                 (((split_offset + i_split) * params.size_h + i_nhead) *
//                 params.size_s + i_block_m * kBlockM) * kSizeDV;
//             auto o_acc_dram_window = Policy::template MakeODramTileWindow<acc_t>(
//                 reinterpret_cast<acc_t*>(params.p_output_accum) + oacc_offset,
//                 params.size_s);
//             ck_tile::static_for<0, n1_loops, 1>{}(
//                 [&](auto n1_id){
//                     ck_tile::store_tile(o_acc_dram_window, ck_tile::cast_tile<acc_t>(o_acc[n1_id]));
//                     if constexpr (n1_id < (n1_loops - 1))
//                     {
//                         ck_tile::move_tile_window(o_acc_dram_window, {0, Traits::kBlockN1});
//                     }
//                 }
//             );
//         }
// 		__syncthreads();
//     }
// }


template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
__launch_bounds__(256, 2)
__global__ void flash_fwd_splitkv_mla_kernel_non_lds(
    const FlashMlaFwdParams params)
{
    // 1. Misc. preparation
    using Policy  = FlashMlaKernelPolicy<Traits, scalar_t, float>;
    constexpr auto I0 = ck_tile::number<0>{};
    constexpr auto I1 = ck_tile::number<1>{};

    constexpr ck_tile::index_t kSizeD             = Traits::kSizeD; 
    constexpr ck_tile::index_t kSizeDV            = Traits::kSizeDV; 
    constexpr ck_tile::index_t kNumThreads        = Traits::kNumThreads;
    constexpr ck_tile::index_t kNumThreadsSoftmax = Traits::kNumThreadsSoftmax;
    constexpr ck_tile::index_t kBlockM            = Traits::kBlockM;
    constexpr ck_tile::index_t kBlockN0           = Traits::kBlockN0;
    constexpr ck_tile::index_t kBlockN1           = Traits::kBlockN1;
    constexpr ck_tile::index_t kBlockK0           = Traits::kBlockK0;
    constexpr ck_tile::index_t kBlockK1           = Traits::kBlockK1;

    constexpr ck_tile::index_t k0_loops  = kSizeD / kBlockK0;
    constexpr ck_tile::index_t k1_loops  = kBlockN0 / kBlockK1;
    constexpr ck_tile::index_t n1_loops  = kSizeDV / kBlockN1;

    const ck_tile::index_t i_block_m   = blockIdx.x;
    const ck_tile::index_t i_nhead     = blockIdx.y;
    const ck_tile::index_t i_nhead_k   = i_nhead / params.hq_hk_ratio;
    const ck_tile::index_t i_partition = blockIdx.z;
    const ck_tile::index_t i_m0        = __builtin_amdgcn_readfirstlane(i_block_m * kBlockM);

    const auto f_max = [](auto e0, auto e1) { return max(e0, e1); };
    const auto f_sum = [](auto e0, auto e1) { return e0 + e1; };

    auto gemm_0 = Policy::GetQKRopeBlockGemm();
    auto gemm_1 = Policy::GetSubPVBlockGemm();

    // 2. Allocate LDS
    __shared__ uint8_t shared_ptr[Policy::GetSmemSize()];

    scalar_t* kv_lds_ptr = reinterpret_cast<scalar_t*>(shared_ptr);
    acc_t* p_shuffle_ptr = reinterpret_cast<acc_t*>(shared_ptr + Policy::GetSmemSizeSingleKV());

    auto p_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
        p_shuffle_ptr, Policy::MakePShuffleLdsDescriptor());

    auto p_st_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
                            ck_tile::number<Traits::kBlockN0>{}), {0, 0});
    auto p_ld_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
                            ck_tile::number<Traits::kBlockN0>{}), {0, 0},
        Policy::MakePShuffleTileDistribution());

    // 3. sacc, S, P, M, L, Oacc
    auto s_acc = gemm_0.MakeCBlockTile();
    using SBlockTileType = decltype(ck_tile::cast_tile<acc_t>(s_acc));

    using OaccBlockTileType = decltype(gemm_1.MakeCBlockTile());
    OaccBlockTileType o_acc[n1_loops];

    using SInnerBlockTileType = decltype(p_ld_lds_window.load());
    using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
        SInnerBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
    auto m = MLBlockTileType{};
    auto l = MLBlockTileType{};

    auto scale_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
        p_shuffle_ptr, Policy::MakeScaleShuffleLdsDescriptor());
    using ShuffleMLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
        OaccBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
    auto scale_st_lds_window = ck_tile::make_tile_window(scale_shuffle_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}),
						    {0});
    auto scale_lds_window = ck_tile::make_tile_window(scale_shuffle_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}),
						    {0},
        ShuffleMLBlockTileType::get_tile_distribution());


    // 4. Load metadata
    TileSchedulerMetaData metadata;
    reinterpret_cast<int4*>(&(metadata.data))[0] = reinterpret_cast<int4*>(
        params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4];
    reinterpret_cast<int4*>(&(metadata.data))[1] = reinterpret_cast<int4*>(
        params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4 + 1];

    const ck_tile::index_t begin_batch_idx   = metadata.core.begin_batch_idx;
    const ck_tile::index_t begin_seqlen_idx  = metadata.core.begin_seqlen_idx;
    const ck_tile::index_t end_batch_idx     = metadata.core.end_batch_idx;
    const ck_tile::index_t end_seqlen_idx    = metadata.core.end_seqlen_idx;
    const ck_tile::index_t begin_n_split_idx = metadata.core.begin_n_split_idx;


    for (ck_tile::index_t i_batch = begin_batch_idx; i_batch <= end_batch_idx; ++i_batch)
    {
        const ck_tile::index_t i_split = i_batch == begin_batch_idx ? begin_n_split_idx : 0;
        const ck_tile::index_t seqlen_k    = params.p_cu_seqlens_k[i_batch];
        const ck_tile::index_t n_block_min = i_batch == begin_batch_idx ? begin_seqlen_idx / kBlockN0 : 0;
        const ck_tile::index_t n_block_max = i_batch == end_batch_idx ? ck_tile::integer_divide_ceil(end_seqlen_idx, kBlockN0) : ck_tile::integer_divide_ceil(seqlen_k, kBlockN0);
        const bool NoSplit = n_block_min == 0 && n_block_max == ck_tile::integer_divide_ceil(seqlen_k, kBlockN0);
        const ck_tile::index_t split_seqlen_k_begin = i_batch == begin_batch_idx ? begin_seqlen_idx : 0;
        const ck_tile::index_t split_seqlen_k_end = i_batch == end_batch_idx ? end_seqlen_idx : seqlen_k;

        ck_tile::index_t i_block_n = n_block_max - 1;



        // I. Load Q to reg
        const ck_tile::index_t q_offset = i_batch * params.stride_b_q +
                                 i_block_m * kBlockM * params.stride_s_q +
                                 i_nhead * params.stride_h_q;
        auto q_dram_window = Policy::MakeQBlockDramTileWindow(
            reinterpret_cast<scalar_t*>(params.p_query) + q_offset,
            params.size_s,
            params.stride_s_q);
        auto q = ck_tile::load_tile(q_dram_window);


        // II. Clear tiles 
        if (i_batch > begin_batch_idx)
        {
            __syncthreads();
        }

        ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){ck_tile::clear_tile(o_acc[n1_id]);});
        ck_tile::clear_tile(m);
        ck_tile::clear_tile(l);


        // III. Prepare KV
        auto page_batch_offset = params.block_table_batch_stride * i_batch;
        const auto* block_indices = params.p_block_table + page_batch_offset;
        
        auto [k_st_lds_window, k_ld_lds_window] = Policy::MakeKLdsTileWindow(kv_lds_ptr);
        auto v_ld_lds_window = Policy::MakeVLdsTileWindow(kv_lds_ptr);
        auto v_debug_lds_window = Policy::MakeVLdsDebugTileWindow(kv_lds_ptr);

        auto k_dram_block_window = Policy::MakeKSplitDramTileWindow(
            reinterpret_cast<scalar_t*>(params.p_key) + params.stride_h_k * i_nhead_k,
            params.total_seqlen_kv,
            params.stride_s_k);

        auto v_dram_block_window = Policy::MakeVSplitDramTileWindow(
            reinterpret_cast<scalar_t*>(params.p_key) + params.stride_h_k * i_nhead_k,
            params.total_seqlen_kv,
            params.stride_s_k);

		auto [k_dram_window, v_dram_window] = Policy::template MakeSubKVDramTileWindowPaged(
			k_dram_block_window,
            v_dram_block_window,
			block_indices,
			params.stride_s_k,
			i_block_n * kBlockN0,
			params.page_block_size);
        using KBlockTileType = decltype(k_dram_window.load());
        KBlockTileType k_block_tile[2];

		using VBlockTileType = decltype(v_dram_window.load());
        VBlockTileType v_block_tile[2];

        constexpr ck_tile::array<ck_tile::index_t, 2> qk_direction = {0, Traits::kBlockK0};
        int k_ld_lds_offset = kBlockN0;
        int k_st_lds_offset = kBlockN0;

        constexpr int n_masking_steps = !Is_causal ? 1 : ck_tile::integer_divide_ceil(kBlockM, kBlockN0) + 1;
        int masking_step = n_masking_steps;

#pragma unroll 1
        for (; i_block_n >= n_block_min; --masking_step, --i_block_n)
        {

			ck_tile::clear_tile(s_acc);

            // --------------------------------------------------
            {
                ck_tile::load_tile(k_block_tile[0], k_dram_window);
                ck_tile::move_tile_window(k_dram_window, qk_direction);
                ck_tile::store_tile(k_st_lds_window, k_block_tile[0]);
                ck_tile::move_tile_window(k_st_lds_window, {k_st_lds_offset, 0});
                k_st_lds_offset = -k_st_lds_offset;

                ck_tile::load_tile(k_block_tile[1], k_dram_window);

                if constexpr (k0_loops > 2)
                {
                    ck_tile::static_for<0, k0_loops - 2, 1>{}(
                        [&](auto i_k0)
                        {
                            ck_tile::move_tile_window(k_dram_window, qk_direction);

                            ck_tile::block_sync_lds();
                            gemm_0(s_acc,
                                   ck_tile::get_slice_tile(q,
                                                  ck_tile::sequence<0, i_k0 * kBlockK0>{},
                                                  ck_tile::sequence<kBlockM, (i_k0 + 1) * kBlockK0>{}),
                                   k_ld_lds_window);
                            ck_tile::move_tile_window(k_ld_lds_window, {k_ld_lds_offset, 0});
                            k_ld_lds_offset = -k_ld_lds_offset;

                            ck_tile::store_tile(k_st_lds_window, k_block_tile[(i_k0 + 1) % 2]);
                            ck_tile::move_tile_window(k_st_lds_window, {k_st_lds_offset, 0});
                            k_st_lds_offset = -k_st_lds_offset;

                            ck_tile::load_tile(k_block_tile[i_k0 % 2], k_dram_window);
                        });
                }

                // Tailing 2 tiles of QK GEMM_0
                ck_tile::load_tile(v_block_tile[0], v_dram_window);
                ck_tile::move_tile_window(v_dram_window, {kBlockN1, 0});

                {
                    // ck_tile::block_sync_lds();
                    gemm_0(s_acc,
                           ck_tile::get_slice_tile(q,
                                          ck_tile::sequence<0, (k0_loops - 2) * kBlockK0>{},
                                          ck_tile::sequence<kBlockM, (k0_loops - 1) * kBlockK0>{}),
                           k_ld_lds_window);

                    ck_tile::move_tile_window(k_ld_lds_window, {k_ld_lds_offset, 0});
                    k_ld_lds_offset = -k_ld_lds_offset;

                    ck_tile::store_tile(k_st_lds_window, k_block_tile[(k0_loops - 1) % 2]);

                    ck_tile::block_sync_lds();
                    gemm_0(s_acc,
                           ck_tile::get_slice_tile(q,
                                          ck_tile::sequence<0, (k0_loops - 1) * kBlockK0>{},
                                          ck_tile::sequence<kBlockM, k0_loops * kBlockK0>{}),
                           k_ld_lds_window);
                }
                // --------------------------------------------------

                ck_tile::store_tile(p_st_lds_window, s_acc);
                k_dram_window.set_window_origin({0, 0});
            }

            const bool is_masking_step = masking_step > 0;
            const bool is_first_masking_step = masking_step == n_masking_steps;

			ck_tile::block_sync_lds();
            auto s_acc_inner = load_tile(p_ld_lds_window);
			ck_tile::block_sync_lds();

            // if seq_len == 1, never need to add mask to s
            if (is_masking_step) {
                constexpr auto sacc_spans = decltype(s_acc_inner)::get_distributed_spans();
                ck_tile::sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
                    // constexpr auto i_idx = ck_tile::make_tuple(idx0);
                    ck_tile::sweep_tile_span(sacc_spans[I1], [&](auto idx1) {
                        constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
                        const auto tile_idx = get_x_indices_from_distributed_indices(
                            s_acc_inner.get_tile_distribution(), make_tuple(idx0, idx1));
                        auto row_id = tile_idx.at(ck_tile::number<0>{});
                        auto col_id = tile_idx.at(ck_tile::number<1>{});
                        if constexpr (!Is_causal)
                        {
                            if (col_id >= int(seqlen_k - i_block_n * kBlockN0))
                                s_acc_inner(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
                        }
                        else
                        {
                            ck_tile::index_t col_limit_right = seqlen_k - 1 - i_block_n * kBlockN0 -
                                (params.size_s - 1 - (i_block_m * kBlockM + row_id)) / params.num_groups;
                            if (col_id > col_limit_right)
                                s_acc_inner(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
                        }
                    });
                });
            }

            ck_tile::load_tile(v_block_tile[1], v_dram_window);
            ck_tile::move_tile_window(v_dram_window, {kBlockN1, 0});

            auto m_local = ck_tile::block_tile_reduce<acc_t>(
                s_acc_inner,
                ck_tile::sequence<1>{},
                f_max,
                -ck_tile::numeric<acc_t>::infinity());
            ck_tile::block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});

            const auto m_old = m;

            ck_tile::tile_elementwise_inout(
                [](auto& e0, auto e1, auto e2) { e0 = max(e1, e2); }, m, m_old, m_local);

            auto p_compute = ck_tile::make_static_distributed_tensor<acc_t>(
                s_acc_inner.get_tile_distribution());

            constexpr auto p_spans = decltype(p_compute)::get_distributed_spans();
            ck_tile::sweep_tile_span(p_spans[I0], [&](auto idx0) {
                constexpr auto i_idx = ck_tile::make_tuple(idx0);
                auto row_max = params.scale_softmax_log2 * m[i_idx];
                ck_tile::sweep_tile_span(p_spans[I1], [&](auto idx1) {
                    constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
                    p_compute(i_j_idx) = exp2(params.scale_softmax_log2 * s_acc_inner[i_j_idx] - row_max);
                });
            });

            auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
                p_compute,
                ck_tile::sequence<1>{},
                f_sum,
                acc_t{0});
            ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});

            ck_tile::sweep_tile_span(p_spans[I0], [&](auto idx0) {
                constexpr auto i = ck_tile::make_tuple(idx0);
                auto temp_i = exp2(params.scale_softmax_log2 * (m_old[i] - m[i]));
                l(i) = temp_i * l[i] + rowsum_p[i];
                rowsum_p(i) = temp_i;
            });

			ck_tile::block_sync_lds();
			ck_tile::store_tile(scale_st_lds_window, rowsum_p);
			ck_tile::block_sync_lds();
			auto temp_scale = ck_tile::load_tile(scale_lds_window);
			ck_tile::block_sync_lds();

            // l{j}, Oacc{j}
            constexpr auto o_spans = ck_tile::remove_cvref_t<decltype(o_acc[0])>::get_distributed_spans();
            ck_tile::sweep_tile_span(o_spans[I0], [&](auto id0) {
                constexpr auto i = ck_tile::make_tuple(id0);
                ck_tile::sweep_tile_span(o_spans[I1], [&](auto id1) {
                    constexpr auto ij = ck_tile::make_tuple(id0, id1);
                    ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id){
#if 1
                        acc_t o_acc_v = o_acc[n1_id](ij);
                        asm volatile("v_mul_f32 %[v_o_acc], %[v_tmp], %[v_o_acc]\n"
                                    : [v_o_acc] "+v"(o_acc_v)
                                    : [v_tmp] "v"(temp_scale[i]));
                                    // : [v_tmp] "v"(rowsum_p[i]));
                        o_acc[n1_id](ij) = o_acc_v;
#else
                        // o_acc[n1_id](ij) *= temp_i;
                        o_acc[n1_id](ij) *= rowsum_p[i];
#endif
                    });
                });
            });

            auto p_tile = ck_tile::cast_tile<scalar_t>(p_compute);

            ck_tile::static_for<0, n1_loops, 1>{}([&](auto i_n1) {
                auto v_shuffled = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeShuffledVRegBlockDescriptor());
                ck_tile::shuffle_tile(v_shuffled, v_block_tile[i_n1 % 2]);
                ck_tile::store_tile(v_ld_lds_window, v_shuffled);
                // ck_tile::store_tile(v_ld_lds_window, v_block_tile[i_n1 % 2]);

                // auto v_tile = v_ld_lds_window.load();
                // if constexpr(k1_loops > 1)
                // {
                //     ck_tile::static_for<0, k1_loops - 1, 1>{}([&](auto i_k1) {
                //         ck_tile::block_sync_lds();
                //         gemm_1(o_acc[i_n1],
                //                ck_tile::get_slice_tile(
                //                    p_tile, ck_tile::sequence<0, i_k1 * kBlockK1>{},
                //                    ck_tile::sequence<kBlockM, (i_k1 + 1) * kBlockK1>{}),
                //                // v_tiles[i_n1]);
                //                v_ld_lds_window);
                //         ck_tile::block_sync_lds();
                //
                //         ck_tile::shuffle_tile(v_shuffled, v_tiles[i_n1 % 2]);
                //         ck_tile::store_tile(v_ld_lds_window, v_shuffled); // store the prefetch
                //     });
                // }
                // // tail
				ck_tile::block_sync_lds();
                if constexpr (i_n1 < (n1_loops - 2))
                {
                    ck_tile::load_tile(v_block_tile[i_n1 % 2], v_dram_window);
                    ck_tile::move_tile_window(v_dram_window, {kBlockN1, 0});
                }
                {
                    ck_tile::block_sync_lds();
                    gemm_1(o_acc[i_n1],
                           ck_tile::get_slice_tile(p_tile,
                               ck_tile::sequence<0, (k1_loops - 1) * kBlockK1>{},
                               ck_tile::sequence<kBlockM, kBlockN0>{}),
                           v_ld_lds_window);
                    ck_tile::block_sync_lds();
                }
            });

            v_dram_window.set_window_origin({0, 0});
            Policy::template UpdateSubKVDramTileWindow(
                k_dram_window,
                v_dram_window,
                block_indices,
                params.stride_s_k,
                (i_block_n - 1) * kBlockN0,
                params.page_block_size);
        }

        // Epilogue
        auto lse_acc = ck_tile::make_static_distributed_tensor<acc_t>(m.get_tile_distribution());
        constexpr auto lse_acc_spans = decltype(lse_acc)::get_distributed_spans();
        ck_tile::sweep_tile_span(lse_acc_spans[I0], [&](auto idx0) {
            constexpr auto i_idx = ck_tile::make_tuple(idx0);
            lse_acc(i_idx) = m[i_idx] * params.scale_softmax + log(l[i_idx]);
        });

        if (NoSplit)
        {
            const ck_tile::index_t lse_offset = i_batch * params.size_s;
            auto lse_dram_window = Policy::MakeLSEDramTileWindow(
                reinterpret_cast<acc_t*>(params.p_softmax_lse) + lse_offset,
                params.size_s,
                i_m0);
            ck_tile::store_tile(lse_dram_window, lse_acc);
        }
        else
        {
            const ck_tile::index_t split_offset = params.p_num_splits[i_batch];
            const ck_tile::index_t lseacc_offset =
                ((split_offset + i_split) * params.size_h + i_nhead) *
                params.size_s + i_block_m * kBlockM;
            auto lseacc_dram_window = Policy::MakeLSEDramTileWindow(
                reinterpret_cast<acc_t*>(params.p_softmax_lseaccum) + lseacc_offset,
                params.size_s);
            ck_tile::store_tile(lseacc_dram_window, lse_acc);
        }

		ck_tile::store_tile(scale_st_lds_window, l);
		ck_tile::block_sync_lds();
		auto new_l = ck_tile::load_tile(scale_lds_window);
		ck_tile::block_sync_lds();

        __syncthreads();
        constexpr auto o_spans = ck_tile::remove_cvref_t<decltype(o_acc[0])>::get_distributed_spans();;
        ck_tile::sweep_tile_span(o_spans[ck_tile::number<0>{}], [&](auto id0) {
            constexpr auto i = ck_tile::make_tuple(id0);
            const auto tmp   = [&]() {
                    return new_l[i] == 0.f ? 0.f : 1 / new_l[i];
                    // return l[i] == 0.f ? 0.f : 1 / l[i];
            }();
            ck_tile::sweep_tile_span(o_spans[ck_tile::number<1>{}], [&](auto id1) {
                constexpr auto ij = ck_tile::make_tuple(id0, id1);
                ck_tile::static_for<0, n1_loops, 1>{}([&](auto n1_id)
                {
#if 1
                    acc_t o_acc_v = o_acc[n1_id](ij);
                    asm volatile("v_mul_f32 %[v_o_acc], %[v_tmp], %[v_o_acc]\n"
                                 : [v_o_acc] "+v"(o_acc_v)
                                 : [v_tmp] "v"(tmp));
                    o_acc[n1_id](ij) = o_acc_v;
#else
                    o_acc[n1_id](ij) *= tmp;
#endif
                });
            });
        });

        if (NoSplit)
        {
            const ck_tile::index_t o_offset = i_batch * params.stride_b_o;
            auto o_dram_window = Policy::template MakeODramTileWindow<scalar_t>(
                reinterpret_cast<scalar_t*>(params.p_output) + o_offset,
                params.size_s,
                i_m0);
            ck_tile::static_for<0, n1_loops, 1>{}(
                [&](auto n1_id){
                    ck_tile::store_tile(o_dram_window, ck_tile::cast_tile<scalar_t>(o_acc[n1_id]));
                    if constexpr (n1_id < (n1_loops - 1))
                    {
                        ck_tile::move_tile_window(o_dram_window, {0, Traits::kBlockN1});
                    }
                }
            );
        }
        else
        {
            const ck_tile::index_t split_offset = params.p_num_splits[i_batch];
            const ck_tile::index_t oacc_offset =
                (((split_offset + i_split) * params.size_h + i_nhead) *
                params.size_s + i_block_m * kBlockM) * kSizeDV;
            auto o_acc_dram_window = Policy::template MakeODramTileWindow<acc_t>(
                reinterpret_cast<acc_t*>(params.p_output_accum) + oacc_offset,
                params.size_s);
            ck_tile::static_for<0, n1_loops, 1>{}(
                [&](auto n1_id){
                    ck_tile::store_tile(o_acc_dram_window, ck_tile::cast_tile<acc_t>(o_acc[n1_id]));
                    if constexpr (n1_id < (n1_loops - 1))
                    {
                        ck_tile::move_tile_window(o_acc_dram_window, {0, Traits::kBlockN1});
                    }
                }
            );
        }
		__syncthreads();
    }
}


template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
void dispatch_fmla_fwd_splictkv(
    const FlashMlaFwdParams& params)
{
    // assert(params.page_block_size == Traits::kBlockN);
    const uint32_t num_m_block = static_cast<uint32_t>(ck_tile::integer_divide_ceil(params.size_s, Traits::kBlockM));
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
    const dim3 grid {
        num_m_block,
        static_cast<uint32_t>(params.size_h),
        static_cast<uint32_t>(params.num_cu_parts)
    };

	// if constexpr (!Traits::IsBReg)
 //    {
        // auto kernel = &flash_fwd_splitkv_mla_kernel_lds<Traits, scalar_t, acc_t, Is_causal>;
        // // constexpr int64_t smem_size = Traits::kBlockN * Traits::kSizeDV * Traits::kStages * sizeof(scalar_t) + Traits::kBlockM * Traits::kBlockN * sizeof(scalar_t);
        // constexpr int64_t smem_size = Traits::kBlockN * Traits::kSizeDV * sizeof(scalar_t);
        // kernel<<<grid, Traits::kNumThreads, smem_size, stream>>>(params);
        // ck_tile::index_t kBlockPerCu = 1;
        // ck_tile::launch_kernel(stream, ck_tile::make_kernel<Traits::kNumThreads, kBlockPerCu>(kernel{{}}, grids, blocks, 0, kargs));
    // }
    // else
    // {
        constexpr int64_t smem_size = Traits::kBlockN0 * Traits::kSizeDV * sizeof(scalar_t);
        auto kernel = &flash_fwd_splitkv_mla_kernel_non_lds<Traits, scalar_t, acc_t, Is_causal>;
        kernel<<<grid, Traits::kNumThreads, 0, stream>>>(params);
    // }

}

template <typename Traits, int32_t kMaxSplits, typename scalar_t>
__global__ void kn_fmla_fwd_splictkv_combine(
    const FlashMlaFwdParams params)
{
    using Policy  = FlashMlaCombineKernelPolicy<Traits, scalar_t, float>;
    using index_t = int64_t;

    __shared__ float lds_lse_scale[kMaxSplits];

    const int32_t bidx = blockIdx.z;

    const int32_t split_offset = params.p_num_splits[bidx];
    const int32_t num_splits   = params.p_num_splits[bidx + 1] - split_offset;
    assert(num_splits <= kMaxSplits);

    if (num_splits > 1)
    {
        const int32_t lane_id          = ck_tile::get_lane_id();
        const int32_t hidx             = blockIdx.y;
        const int32_t sidx             = blockIdx.x;
        const int32_t hsidx            = hidx * params.size_s + sidx;
        const int32_t size_hs          = params.size_h * params.size_s;
        const index_t offset_lse_accum = split_offset * size_hs + hsidx;
        const index_t offset_lse       = bidx * size_hs + hsidx;

        if (ck_tile::get_warp_id() == 0)
        {
            const float* p_lse_accum = reinterpret_cast<float*>(params.p_softmax_lseaccum) + offset_lse_accum;
            float* p_lse             = reinterpret_cast<float*>(params.p_softmax_lse) + offset_lse;

            constexpr int32_t kNumLsePerThr = ck_tile::integer_divide_ceil(kMaxSplits, ck_tile::get_warp_size());
            float local_lse[kNumLsePerThr];

            // Load thread local LSE and get local max LSE
            float max_lse = -INFINITY;
            #pragma unroll
            for (int32_t i = 0; i < kNumLsePerThr; ++i)
            {
                const int32_t split_idx = i * ck_tile::get_warp_size() + lane_id;
                const float lse = (split_idx < num_splits) ? p_lse_accum[split_idx * size_hs] : -INFINITY;
                local_lse[i] = lse;
                max_lse = ck_tile::max(max_lse, lse);
            }

            // Get global max LSE
            #pragma unroll
            for (int32_t offset = ck_tile::get_warp_size() / 2; offset > 0; offset /= 2)
            {
                max_lse = ck_tile::max(max_lse, __shfl_xor(max_lse, offset));
            }

            // Get sum of LSE
            float sum_lse = 0.f;
            #pragma unroll
            for (int32_t i = 0; i < kNumLsePerThr; ++i)
            {
                sum_lse += expf(local_lse[i] - max_lse);
            }
            #pragma unroll
            for (int32_t offset = ck_tile::get_warp_size() / 2; offset > 0; offset /= 2)
            {
                sum_lse += __shfl_xor(sum_lse, offset);
            }

            // Get global LSE
            float global_lse = ((sum_lse == 0.f) || (sum_lse != sum_lse)) ? INFINITY : (logf(sum_lse) + max_lse);
            if (lane_id == 0)
            {
                *p_lse = global_lse;
            }

            // Write LSE to LDS
            #pragma unroll
            for (int32_t i = 0; i < kNumLsePerThr; ++i)
            {
                const int32_t split_idx = i * ck_tile::get_warp_size() + lane_id;
                if (split_idx < num_splits)
                {
                    lds_lse_scale[split_idx] = expf(local_lse[i] - global_lse);
                }
            }
        }

        __builtin_amdgcn_sched_barrier(0);
        ck_tile::block_sync_lds();

        static_assert(Traits::kSizeDV % Traits::kNumThreadsCombine == 0);

        auto oaccu_window =
            Policy::MakeOaccuTileWindow(params.p_output_accum, hsidx, size_hs, split_offset, num_splits);

        auto reg_out = ck_tile::make_static_distributed_tensor<float>(
            decltype(ck_tile::load_tile(oaccu_window))::get_tile_distribution());
        ck_tile::set_tile(reg_out, 0.f);

        for (int32_t split_idx = 0; split_idx < num_splits; ++split_idx)
        {
            const float lse_scale = lds_lse_scale[split_idx];
            auto oaccu = ck_tile::load_tile(oaccu_window);
            ck_tile::sweep_tile(oaccu, [&](auto idx) {
                reg_out(idx) += lse_scale * oaccu(idx);
                // const auto tile_idx = get_x_indices_from_distributed_indices(oaccu.get_tile_distribution(), idx);
                // if (blockIdx.x == 1 && blockIdx.y == 0 && blockIdx.z == 1) {
                //     printf("split_idx %d tid:%d batch_idx:%d o_acc [%d, %d]: %f scale: %f\n", split_idx, threadIdx.x, blockIdx.z, tile_idx.at(ck_tile::number<0>{}), tile_idx.at(ck_tile::number<1>{}), ck_tile::type_convert<float>(oaccu[idx]), lse_scale);
                // }
            });
            ck_tile::move_tile_window(oaccu_window, {size_hs, 0});
            // ck_tile::move_tile_window(oaccu_window, {1, 0});
        }

        auto dram_out = Policy::MakeOutputTileWindow(params.p_output,
                                                     bidx * params.stride_b_o,
                                                     hidx * params.stride_h_o,
                                                     sidx * params.stride_s_o);
        ck_tile::store_tile(dram_out, ck_tile::cast_tile<scalar_t>(reg_out));
    }
}

template <typename Traits, typename scalar_t>
void dispatch_fmla_fwd_splictkv_combine(
    const FlashMlaFwdParams& params)
{
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();

    const dim3 grid  = dim3(params.size_s, params.size_h, params.size_b);
    const dim3 block = dim3(Traits::kNumThreadsCombine);

    if (params.num_cu_parts <= 1) return;

    if (params.num_cu_parts <= 32)
    {
        kn_fmla_fwd_splictkv_combine<Traits, 32, scalar_t><<<grid, block, 0, stream>>>(params);
    }
    else if (params.num_cu_parts <= 64)
    {
        kn_fmla_fwd_splictkv_combine<Traits, 64, scalar_t><<<grid, block, 0, stream>>>(params);
    }
    else if (params.num_cu_parts <= 96)
    {
        kn_fmla_fwd_splictkv_combine<Traits, 96, scalar_t><<<grid, block, 0, stream>>>(params);
    }
    else if (params.num_cu_parts <= 128)
    {
        kn_fmla_fwd_splictkv_combine<Traits, 128, scalar_t><<<grid, block, 0, stream>>>(params);
    }
    else
    {
        // TORCH_CHECK(false, "fmla_fwd_splictkv_combine cannot support the specified num_cu_parts ",
        //                    toString(params.num_cu_parts), ".");
        assert(false);
    }
}

#define DISPATCH_FMLA_TYPES(TYPE, IS_CAUSAL, NAME, ...) \
    switch ((TYPE))                                     \
    {                                                   \
        case at::ScalarType::BFloat16:                           \
        {                                               \
            using scalar_t = ck_tile::bf16_t;           \
            if ((IS_CAUSAL))                            \
            {                                           \
                constexpr bool Is_causal = true;        \
                __VA_ARGS__;                            \
            }                                           \
            else                                        \
            {                                           \
                constexpr bool Is_causal = false;       \
                __VA_ARGS__;                            \
            }                                           \
            break;                                      \
        }                                               \
        case at::ScalarType::Half:                               \
        {                                               \
            using scalar_t = ck_tile::fp16_t;           \
            if ((IS_CAUSAL))                            \
            {                                           \
                constexpr bool Is_causal = true;        \
                __VA_ARGS__;                            \
            }                                           \
            else                                        \
            {                                           \
                constexpr bool Is_causal = false;       \
                __VA_ARGS__;                            \
            }                                           \
            break;                                      \
        }                                               \
        default:                                        \
            TORCH_CHECK(false, NAME " does't support ", \
                        toString((TYPE)), ".");         \
    }

std::vector<torch::Tensor> flash_mla_fwd_with_kvcache_impl(
    torch::Tensor& query,
    const torch::Tensor& key_cache,
    const torch::Tensor& value_cache,
    const int32_t        head_size_v,
    const torch::Tensor& cache_seqlens,
    const torch::Tensor& block_table,
    const float          softmax_scale,
    const bool           is_causal,
    const torch::Tensor& tile_scheduler_metadata,
    const torch::Tensor& num_splits)
{
    using Traits = FlashMlaKernelTraitsInstance;

    torch::Tensor vcache = value_cache.data_ptr() ? value_cache : key_cache;

    auto opts = query.options();

    const int32_t batch_size = query.size(0);
    const int32_t seqlen_q_ori = query.size(1);
    const int32_t num_heads_q_ori = query.size(2);

    const int32_t head_size = query.size(3);


    const int32_t num_blocks = key_cache.size(0);
    const int32_t page_block_size = key_cache.size(1);
    const int32_t num_heads_k = key_cache.size(2);

    const int32_t num_groups = num_heads_q_ori / num_heads_k;
    const int32_t seqlen_q = seqlen_q_ori * num_groups;
    const int32_t num_heads = num_heads_k;
    const int32_t num_cu_parts = tile_scheduler_metadata.size(0);
    // printf("num_cu_parts %d", num_cu_parts);

    query = query.view({batch_size, seqlen_q_ori, num_heads_k, num_groups, head_size}).transpose(2, 3)
                .reshape({batch_size, seqlen_q, num_heads, head_size});

    // CHECK_SHAPE(query, batch_size, seqlen_q, num_heads, head_size);
    // CHECK_SHAPE(key_cache, num_blocks, page_block_size, num_heads, head_size);

    auto output = torch::zeros({batch_size, seqlen_q, num_heads, head_size_v}, opts);
    auto softmax_lse = torch::zeros({batch_size, num_heads, seqlen_q}, opts.dtype(torch::kFloat32));

    auto softmax_lseaccum = torch::zeros({batch_size + num_cu_parts, num_heads, seqlen_q}, opts.dtype(torch::kFloat32));
    auto output_accum = torch::zeros({batch_size + num_cu_parts, num_heads, seqlen_q, head_size_v}, opts.dtype(torch::kFloat32));

    FlashMlaFwdParams params = {};
    params.p_cu_seqlens_k            = cache_seqlens.data_ptr<int32_t>();
    params.p_block_table             = block_table.data_ptr<int32_t>();
    params.p_tile_scheduler_metadata = tile_scheduler_metadata.data_ptr<int32_t>();
    params.p_num_splits              = num_splits.data_ptr<int32_t>();

    params.p_query            = query.data_ptr();
    params.p_key              = key_cache.data_ptr();
    params.p_value            = vcache.data_ptr();

#ifdef ZZDebug
    auto debug_m_inner = torch::zeros({2, Traits::kBlockM}, opts);
    auto debug_v_inner = torch::zeros({Traits::kBlockN1, Traits::kBlockK1}, opts);
    // auto debug_v_inner = torch::zeros({Traits::kBlockN, head_size_v}, opts);
    auto debug_p_inner = torch::zeros({Traits::kBlockM, Traits::kBlockN0}, opts);
    auto debug_o_inner = torch::zeros({Traits::kBlockM, Traits::kBlockN1}, opts);

    params.p_debug_m          = debug_m_inner.data_ptr();
    params.p_debug_value      = debug_v_inner.data_ptr();
    params.p_debug_p          = debug_p_inner.data_ptr();
    params.p_debug_output     = debug_o_inner.data_ptr();
#endif

    params.p_output           = output.data_ptr();
    params.p_softmax_lse      = softmax_lse.data_ptr();
    params.p_softmax_lseaccum = softmax_lseaccum.data_ptr();
    params.p_output_accum     = output_accum.data_ptr();

    params.size_b                   = batch_size;
    params.size_s                   = seqlen_q;
    params.size_h                   = num_heads;
    params.hq_hk_ratio              = num_heads / num_heads_k;
    params.num_groups               = num_groups;
    params.num_cu_parts             = tile_scheduler_metadata.size(0);
    params.block_table_batch_stride = block_table.stride(0);
    params.total_seqlen_kv          = num_blocks * page_block_size;
    params.page_block_size          = page_block_size;
    params.scale_softmax            = softmax_scale;
    params.scale_softmax_log2       = float(softmax_scale * M_LOG2E);
    params.is_causal                = is_causal;

    params.stride_b_q = query.stride(0);
    params.stride_s_q = query.stride(1);
    params.stride_h_q = query.stride(2);
    params.stride_b_k = key_cache.stride(0);
    params.stride_s_k = key_cache.stride(1);
    params.stride_h_k = key_cache.stride(2);
    params.stride_b_v = vcache.stride(0);
    params.stride_s_v = vcache.stride(1);
    params.stride_h_v = vcache.stride(2);
    params.stride_b_o = output.stride(0);
    params.stride_s_o = output.stride(1);
    params.stride_h_o = output.stride(2);

	using acc_t = float;

    // dispatch_fmla_fwd_splictkv<Traits, ck_tile::fp16_t, float, true>(params);
    dispatch_fmla_fwd_splictkv<Traits, ck_tile::fp16_t, float, false>(params);
    dispatch_fmla_fwd_splictkv_combine<Traits, ck_tile::fp16_t>(params);
    DISPATCH_FMLA_TYPES(
        query.scalar_type(),
        is_causal,
        "fmla_fwd",
        [&](){
            // dispatch_fmla_fwd_splictkv<Traits, scalar_t, acc_t, Is_causal>(params);
            // dispatch_fmla_fwd_splictkv_combine<Traits, scalar_t>(params);
        }();
    );
    output = output.view({batch_size, seqlen_q_ori, num_groups, num_heads_k, head_size_v}).transpose(2, 3)
            .reshape({batch_size, seqlen_q_ori, num_heads_q_ori, head_size_v});
    softmax_lse = softmax_lse.view({batch_size, num_heads_k, seqlen_q_ori, num_groups}).transpose(2, 3)
            .reshape({batch_size, num_heads_q_ori, seqlen_q_ori});
#ifdef ZZDebug
    return {output, softmax_lse, debug_m_inner, debug_p_inner, debug_v_inner, debug_o_inner};
#else
    return {output, softmax_lse};
#endif
}
