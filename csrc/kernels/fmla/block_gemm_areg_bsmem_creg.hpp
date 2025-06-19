// SPDX-License-Identifier: MIT
// Copyright (c) 2018-2025, Advanced Micro Devices, Inc. All rights reserved.

#pragma once

#include <ck_tile/core.hpp>

// This Block GEMM policy inherits from ck_tile's BlockGemmARegBSmemCRegV2CustomPolicy
template <typename AType_,
          typename BType_,
          typename CType_,
          typename BlockWarps_,
          typename WarpGemm_>
struct BlockGemmARegBSmemCRegPolicy
{
    using AType = ck_tile::remove_cvref_t<AType_>;
    using BType = ck_tile::remove_cvref_t<BType_>;
    using CType = ck_tile::remove_cvref_t<CType_>;

    using BlockWarps = ck_tile::remove_cvref_t<BlockWarps_>;

    static constexpr int32_t kMWarps = BlockWarps::at(ck_tile::number<0>{});
    static constexpr int32_t kNWarps = BlockWarps::at(ck_tile::number<1>{});
    static constexpr int32_t kKWarps = BlockWarps::at(ck_tile::number<2>{});

    using WarpGemm = ck_tile::remove_cvref_t<WarpGemm_>;

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto GetWarpGemmMWarpNWarp()
    {
        return ck_tile::make_tuple(WarpGemm{}, kMWarps, kNWarps);
    }
};

// This Block GEMM inherits from ck_tile's BlockGemmARegBSmemCRegV2
// A is block distributed tensor
// B is block window on shared memory
// C is block distributed tensor
template <typename Problem_, typename Policy_>
struct BlockGemmARegBSmemCReg
{
    using Problem        = ck_tile::remove_cvref_t<Problem_>;
    using Policy         = ck_tile::remove_cvref_t<Policy_>;
    using ADataType      = ck_tile::remove_cvref_t<typename Problem::ADataType>;
    using BDataType      = ck_tile::remove_cvref_t<typename Problem::BDataType>;
    using CDataType      = ck_tile::remove_cvref_t<typename Problem::CDataType>;
    using BlockGemmShape = ck_tile::remove_cvref_t<typename Problem::BlockGemmShape>;

    static constexpr int32_t kBlockSize = Problem::kBlockSize;

    // C += A * B
    template <typename CBlockTensor, typename ABlockTensorTmp, typename BBlockWindowTmp>
    CK_TILE_DEVICE void operator()(CBlockTensor& c_block_tensor,
                                   const ABlockTensorTmp& a_block_tensor_tmp,
                                   const BBlockWindowTmp& b_block_window_tmp) const
    {
        static_assert(
            std::is_same_v<ADataType, ck_tile::remove_cv_t<typename ABlockTensorTmp::DataType>> &&
                std::is_same_v<BDataType, ck_tile::remove_cv_t<typename BBlockWindowTmp::DataType>> &&
                std::is_same_v<CDataType, ck_tile::remove_cv_t<typename CBlockTensor::DataType>>,
            "wrong!");

        constexpr int32_t MPerBlock = ABlockTensorTmp{}.get_lengths()[ck_tile::number<0>{}];
        constexpr int32_t NPerBlock = BBlockWindowTmp{}.get_window_lengths()[ck_tile::number<0>{}];
        constexpr int32_t KPerBlock = ABlockTensorTmp{}.get_lengths()[ck_tile::number<1>{}];

        static_assert(MPerBlock == BlockGemmShape::kM && NPerBlock == BlockGemmShape::kN &&
                          KPerBlock == BlockGemmShape::kK,
                      "wrong!");

        constexpr auto config = Policy::template GetWarpGemmMWarpNWarp<Problem>();

        using WG = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = config.template at<1>();
        constexpr int32_t NWarp = config.template at<2>();

        constexpr int32_t MIterPerWarp = MPerBlock / (MWarp * WG::kM);
        constexpr int32_t NIterPerWarp = NPerBlock / (NWarp * WG::kN);
        constexpr int32_t KIterPerWarp = KPerBlock / WG::kK;

        constexpr int32_t NPerBlockPerIter = NPerBlock / NIterPerWarp;
        constexpr int32_t KPerBlockPerIter = KPerBlock / KIterPerWarp;

        const int32_t iNWarp = ck_tile::get_warp_id() % NWarp;

        constexpr auto c_block_outer_dstr_encoding = ck_tile::tile_distribution_encoding<
            ck_tile::sequence<>,
            ck_tile::tuple<ck_tile::sequence<MIterPerWarp, MWarp>, ck_tile::sequence<NIterPerWarp, NWarp>>,
            ck_tile::tuple<ck_tile::sequence<1, 2>>,
            ck_tile::tuple<ck_tile::sequence<1, 1>>,
            ck_tile::sequence<1, 2>,
            ck_tile::sequence<0, 0>>{};

        constexpr auto c_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
            c_block_outer_dstr_encoding, typename WG::CWarpDstrEncoding{});

        // constrcut from A-block-tensor from A-Block-tensor-tmp
        // FIXME: need method to check a_block_tensor and a_block_tensor_tmp have equivalent
        // distribution
        auto a_block_tensor = ck_tile::make_static_distributed_tensor<typename ABlockTensorTmp::DataType>(
            MakeABlockTileDistribution());

        a_block_tensor.get_thread_buffer() = a_block_tensor_tmp.get_thread_buffer();

        // construct B-warp-window
        auto b_warp_window_tmp = ck_tile::make_tile_window(
            b_block_window_tmp.get_bottom_tensor_view(),
            ck_tile::make_tuple(ck_tile::number<WG::kN>{}, ck_tile::number<WG::kK>{}),
            b_block_window_tmp.get_window_origin() + ck_tile::multi_index<2>{iNWarp * WG::kN, 0},
            ck_tile::make_static_tile_distribution(typename WG::BWarpDstrEncoding{}));

#if 0 // FIXME: using array will cause register spill
        array<array<decltype(b_warp_window_tmp), KIterPerWarp>, NIterPerWarp> b_warp_windows{
            {b_warp_window_tmp}};

        for(int32_t nIter = 0; nIter < NIterPerWarp; nIter++)
        {
            for(int32_t kIter = 0; kIter < KIterPerWarp; kIter++)
            {
                move_tile_window(b_warp_windows(nIter)(kIter),
                                 {nIter * NPerBlockPerIter, kIter * KPerBlockPerIter});
            }
        }
#else
        ck_tile::statically_indexed_array<
            ck_tile::statically_indexed_array<decltype(b_warp_window_tmp), KIterPerWarp>,
            NIterPerWarp>
            b_warp_windows;

        ck_tile::static_for<0, NIterPerWarp, 1>{}([&](auto nIter) {
            ck_tile::static_for<0, KIterPerWarp, 1>{}([&](auto kIter) {
                b_warp_windows(nIter)(kIter) = b_warp_window_tmp;

                ck_tile::move_tile_window(b_warp_windows(nIter)(kIter),
                                          {nIter * NPerBlockPerIter, kIter * KPerBlockPerIter});
            });
        });
#endif

        // check C-block-distribution
        static_assert(
            std::is_same_v<ck_tile::remove_cvref_t<decltype(c_block_dstr_encode)>,
                           ck_tile::remove_cvref_t<decltype(CBlockTensor::get_tile_distribution()
                                                            .get_static_tile_distribution_encoding())>>,
            "wrong!");

        using AWarpDstr = typename WG::AWarpDstr;
        using CWarpDstr = typename WG::CWarpDstr;

        using AWarpTensor = typename WG::AWarpTensor;
        using CWarpTensor = typename WG::CWarpTensor;

        constexpr auto a_warp_y_lengths =
            ck_tile::to_sequence(AWarpDstr{}.get_ys_to_d_descriptor().get_lengths());
        constexpr auto c_warp_y_lengths =
            ck_tile::to_sequence(CWarpDstr{}.get_ys_to_d_descriptor().get_lengths());

        constexpr auto a_warp_y_index_zeros = ck_tile::uniform_sequence_gen_t<AWarpDstr::NDimY, 0>{};
        constexpr auto c_warp_y_index_zeros = ck_tile::uniform_sequence_gen_t<CWarpDstr::NDimY, 0>{};

        // hot loop:
        ck_tile::static_for<0, KIterPerWarp, 1>{}([&](auto kIter) {
            ck_tile::static_for<0, NIterPerWarp, 1>{}([&](auto nIter) {
                // read B warp tensor from B Block window
                const auto b_warp_tensor = load_tile(b_warp_windows(nIter)(kIter));

                ck_tile::static_for<0, MIterPerWarp, 1>{}([&](auto mIter) {
                    // read A warp tensor from A block tensor
                    AWarpTensor a_warp_tensor;

                    a_warp_tensor.get_thread_buffer() = a_block_tensor.get_y_sliced_thread_data(
                        ck_tile::merge_sequences(ck_tile::sequence<mIter, kIter>{}, a_warp_y_index_zeros),
                        ck_tile::merge_sequences(ck_tile::sequence<1, 1>{}, a_warp_y_lengths));

                    // read C warp tensor from C block tensor
                    CWarpTensor c_warp_tensor;

                    c_warp_tensor.get_thread_buffer() = c_block_tensor.get_y_sliced_thread_data(
                        ck_tile::merge_sequences(ck_tile::sequence<mIter, nIter>{}, c_warp_y_index_zeros),
                        ck_tile::merge_sequences(ck_tile::sequence<1, 1>{}, c_warp_y_lengths));

                    // warp GEMM
                    WG{}(c_warp_tensor, a_warp_tensor, b_warp_tensor);
                    // WG{}(c_warp_tensor, a_warp_tensor, b_warp_tensor_array[nIter]);

                    // write C warp tensor into C block tensor
                    c_block_tensor.set_y_sliced_thread_data(
                        ck_tile::merge_sequences(ck_tile::sequence<mIter, nIter>{}, c_warp_y_index_zeros),
                        ck_tile::merge_sequences(ck_tile::sequence<1, 1>{}, c_warp_y_lengths),
                        c_warp_tensor.get_thread_buffer());
                });
            });
        });
    }

    template <int32_t MPerBlock = BlockGemmShape::kM, int32_t KPerBlock = BlockGemmShape::kK>
    CK_TILE_DEVICE static constexpr auto MakeABlockTileDistribution()
    {
        constexpr auto config = Policy::template GetWarpGemmMWarpNWarp<Problem>();

        using WG = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = config.template at<1>();
        constexpr int32_t NWarp = config.template at<2>();

        constexpr int32_t MIterPerWarp = MPerBlock / (MWarp * WG::kM);
        constexpr int32_t KIterPerWarp = KPerBlock / WG::kK;

        constexpr auto a_block_outer_dstr_encoding =
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<NWarp>,
                ck_tile::tuple<ck_tile::sequence<MIterPerWarp, MWarp>, ck_tile::sequence<KIterPerWarp>>,
                ck_tile::tuple<ck_tile::sequence<1, 0>>,
                ck_tile::tuple<ck_tile::sequence<1, 0>>,
                ck_tile::sequence<1, 2>,
                ck_tile::sequence<0, 0>>{};

        constexpr auto a_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
            a_block_outer_dstr_encoding, typename WG::AWarpDstrEncoding{});

        return ck_tile::make_static_tile_distribution(a_block_dstr_encode);
    }

    CK_TILE_DEVICE static constexpr auto MakeCBlockTile()
    {
        constexpr int32_t MPerBlock = BlockGemmShape::kM;
        constexpr int32_t NPerBlock = BlockGemmShape::kN;

        constexpr auto config = Policy::template GetWarpGemmMWarpNWarp<Problem>();

        using WG = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = config.template at<1>();
        constexpr int32_t NWarp = config.template at<2>();

        constexpr int32_t MIterPerWarp = MPerBlock / (MWarp * WG::kM);
        constexpr int32_t NIterPerWarp = NPerBlock / (NWarp * WG::kN);
        // constexpr int32_t KIterPerWarp = KPerBlock / WG::kK;

        constexpr auto c_block_outer_dstr_encoding = ck_tile::tile_distribution_encoding<
            ck_tile::sequence<>,
            ck_tile::tuple<ck_tile::sequence<MIterPerWarp, MWarp>, ck_tile::sequence<NIterPerWarp, NWarp>>,
            ck_tile::tuple<ck_tile::sequence<1, 2>>,
            ck_tile::tuple<ck_tile::sequence<1, 1>>,
            ck_tile::sequence<1, 2>,
            ck_tile::sequence<0, 0>>{};

        constexpr auto c_block_dstr_encode = ck_tile::detail::make_embed_tile_distribution_encoding(
            c_block_outer_dstr_encoding, typename WG::CWarpDstrEncoding{});
        constexpr auto c_block_dstr = ck_tile::make_static_tile_distribution(c_block_dstr_encode);
        auto c_block_tensor         = ck_tile::make_static_distributed_tensor<CDataType>(c_block_dstr);
        return c_block_tensor;
    }

    // C = A * B
    template <typename ABlockTensorTmp, typename BBlockWindowTmp>
    CK_TILE_DEVICE auto operator()(const ABlockTensorTmp& a_block_tensor_tmp,
                                   const BBlockWindowTmp& b_block_window_tmp) const
    {
        auto c_block_tensor = MakeCBlockTile();
        operator()(c_block_tensor, a_block_tensor_tmp, b_block_window_tmp);
        return c_block_tensor;
    }
};
