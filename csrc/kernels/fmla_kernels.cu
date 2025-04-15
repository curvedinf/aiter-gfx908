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
#define DEBUG_TID 128

// =====================================================================================================================
// Definitions and helper structures
//

template <int32_t kSizeD_,
          int32_t kSizeDV_,
          int32_t kBlockM_,
          int32_t kBlockN_,
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
    static constexpr int32_t kBlockM                 = kBlockM_;
    static constexpr int32_t kBlockN                 = kBlockN_;
    static constexpr int32_t kFixedOverheadNumBlocks = 5;
    static constexpr int32_t kMaxBatchSize           = 4096;

    static constexpr int32_t kKPerStep = 64;

    static_assert(kSizeD % 64 == 0);
    static_assert(kSizeDV % 64 == 0);
    static_assert(kSizeD >= kSizeDV);

    using Gemm0BlockWarps = ck_tile::sequence<2, 2, 1>;
    using Gemm1BlockWarps = ck_tile::sequence<2, 2, 1>;
    // using Gemm0WarpTile = ck_tile::sequence<16, 16, ck_tile::min(32, kBlockN)>;
    // using Gemm1WarpTile = ck_tile::sequence<16, 16, 32>;
    using Gemm0WarpTile = ck_tile::sequence<32, 32, 16>;
    using Gemm1WarpTile = ck_tile::sequence<32, 32, 16>;

    static constexpr int32_t kNumGemm0Warps = kNumWarps_;
    static constexpr int32_t kNumGemm1Warps = kNumWarps_;
    static constexpr int32_t kBlockSize = kNumWarps * warpSize;

    static constexpr int32_t kStages = 2;
    static constexpr int32_t kPageSize = 16;

    static constexpr bool TransposeC = true;
    // static constexpr bool IsBReg = kBlockN * kSizeD * kStages * 2 >= 64 * 1024;
    static constexpr bool IsBReg = true;
    static constexpr bool GemmPVLds = false;
};

// using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<576, 512, 64, 16, 4>;
using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<192, 128, 64, 64, 4>;
// using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<576, 512, 64, 64, 4>;

template <typename Traits, typename scalar_t, typename acc_t>
struct FlashMlaKernelPolicy
{
public:
    constexpr static auto q_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeD);
    constexpr static auto k_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockN, Traits::kSizeD);
    constexpr static auto lse_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockM);
    constexpr static auto o_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockM, Traits::kSizeDV);
    constexpr static auto I0 = ck_tile::number<0>{};
    constexpr static auto I1 = ck_tile::number<1>{};
    constexpr static auto kPackSize = 16 / sizeof(scalar_t);

    CK_TILE_DEVICE static constexpr auto MakeQDramBlockDistribution()
    {
        if constexpr (!Traits::IsBReg)
        {
			return ck_tile::remove_cvref_t<decltype(GetQKBlockGemm())>::template MakeABlockTileDistribution<
				Traits::kBlockM,
				Traits::kSizeD>();
        }
        else
        {
			return ck_tile::make_static_tile_distribution(
                ck_tile::remove_cvref_t<decltype(GetQKBlockGemm())>::MakeABlockDistributionEncode());
        }
    }

    CK_TILE_DEVICE static constexpr auto MakeKLdsBlockDescriptor()
    {
        constexpr auto kSizeInner = [&] {
            if constexpr (!Traits::IsBReg)
                return Traits::kSizeD;
            else
                return Traits::kSizeDV;
        }();

        constexpr auto k_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(Traits::kStages * Traits::kBlockN,
                                kSizeInner / kPackSize,
                                kPackSize),
			//TODO: check this
            // ck_tile::make_tuple((Traits::kSizeD / kPackSize + 1) * kPackSize,
            ck_tile::make_tuple(kSizeInner,
                                kPackSize,
                                1),
            ck_tile::number<kPackSize>{},
            I1);
        constexpr auto k_lds_block_desc_merge = ck_tile::transform_tensor_descriptor(
            k_lds_block_desc,
            ck_tile::make_tuple(
                    ck_tile::make_pass_through_transform(ck_tile::number<Traits::kStages * Traits::kBlockN>{}),
                    ck_tile::make_merge_transform(
                        ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV / kPackSize>{},
                        kPackSize))),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc_merge;
    }

    CK_TILE_DEVICE static constexpr auto MakeVLdsBlockDescriptor()
    {
        constexpr auto kStride = [&] {
            if constexpr (!Traits::IsBReg)
                return Traits::kSizeD;
            else
                return Traits::kSizeDV;
        }();

        constexpr auto v_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(Traits::kStages * Traits::kBlockN,
                                Traits::kSizeDV / kPackSize,
                                kPackSize),
			//TODO: check this
            // ck_tile::make_tuple((kStride / kPackSize + 1) * kPackSize,
            ck_tile::make_tuple(kStride,
                                kPackSize,
                                1),
            ck_tile::number<kPackSize>{},
            I1);

        constexpr auto v_lds_block_desc_transpose = ck_tile::transform_tensor_descriptor(
            v_lds_block_desc,
            ck_tile::make_tuple(
                    ck_tile::make_pass_through_transform(ck_tile::number<Traits::kStages * Traits::kBlockN>{}),
                    ck_tile::make_merge_transform(
                        ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV / kPackSize>{},
                        kPackSize))),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0>{}));
        return v_lds_block_desc_transpose;
    }

    CK_TILE_DEVICE static constexpr auto MakePShuffleLdsDescriptor()
    {
        constexpr auto p_lds_block_desc = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(Traits::kBlockM,
                                Traits::kBlockN,
                                kPackSize),
            ck_tile::make_tuple(Traits::kBlockN / kPackSize * kPackSize,
                                kPackSize,
                                1),
            ck_tile::number<kPackSize>{},
            I1);

        constexpr auto p_lds_block_desc_merge = ck_tile::transform_tensor_descriptor(
            p_lds_block_desc,
            ck_tile::make_tuple(
                    ck_tile::make_pass_through_transform(ck_tile::number<Traits::kBlockM>{}),
                    ck_tile::make_merge_transform(
                        ck_tile::make_tuple(ck_tile::number<Traits::kBlockN / kPackSize>{},
                        kPackSize))),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
        return p_lds_block_desc_merge;
    }

    CK_TILE_DEVICE static constexpr auto MakeVLds2RegBlockDistribution()
    {
        constexpr auto config = decltype(GetPVBlockGemm())::Policy::template GetWarpGemmMWarpNWarp<GemmPVProblem>();
        using WarpGemm        = ck_tile::remove_cvref_t<decltype(config.template at<0>())>;

        constexpr int32_t MWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<0>{});
        constexpr int32_t NWarp = Traits::Gemm1BlockWarps::at(ck_tile::number<1>{});

        constexpr int32_t kNPerBlock = Traits::kSizeDV;
        constexpr int32_t kKPerBlock = Traits::kBlockN;

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
    using GemmQKProblem = ck_tile::BlockGemmProblem<
        scalar_t,
        scalar_t,
        acc_t,
        Traits::kNumGemm0Warps * ck_tile::get_warp_size(), 
        ck_tile::TileGemmShape<ck_tile::sequence<Traits::kBlockM,
                                                 Traits::kBlockN,
                                                 Traits::kKPerStep>,
            typename Traits::Gemm0BlockWarps,
            typename Traits::Gemm0WarpTile>>;

    using GemmPVProblem = ck_tile::BlockGemmProblem<
        scalar_t,
        scalar_t,
        acc_t,
        Traits::kNumGemm1Warps * ck_tile::get_warp_size(),
        ck_tile::TileGemmShape<ck_tile::sequence<Traits::kBlockM,
                                                 Traits::kSizeDV,
                                                 Traits::kBlockN>,
            typename Traits::Gemm1BlockWarps,
            typename Traits::Gemm1WarpTile>>;

    CK_TILE_DEVICE static constexpr auto GetQKBlockGemm()
    {
		if constexpr (!Traits::IsBReg)
        {
            constexpr auto warp_gemm = []() {
                constexpr int32_t WarpGemmM = Traits::Gemm0WarpTile::at(ck_tile::number<0>{});
                if constexpr(std::is_same_v<scalar_t, ck_tile::half_t> && 
                             std::is_same_v<acc_t, float>)
                {
                    if constexpr(WarpGemmM == 32)
                        return ck_tile::WarpGemmMfmaF16F16F32M32N32K16SwizzleBTransposedCDistribution{};
                    else if constexpr(WarpGemmM == 16)
                        return ck_tile::WarpGemmMfmaF16F16F32M16N16K16TransposedCDistribution{};
                    else
                        return ck_tile::WarpGemmMfmaF16F16F32M4N64K16{};
                }
                else if constexpr(std::is_same_v<scalar_t, ck_tile::bf16_t> &&
                                  std::is_same_v<acc_t, float>)
                {
                    if constexpr(WarpGemmM == 32)
                        return ck_tile::WarpGemmMfmaBf16Bf16F32M32N32K16SwizzleBTransposedCDistribution{};
                    else if constexpr(WarpGemmM == 16)
                        return ck_tile::WarpGemmMfmaBf16Bf16F32M16N16K16TransposedCDistribution{};
                    else
                        return ck_tile::WarpGemmMfmaBf16Bf16F32M4N64K16{};
                }
            }();

            using BlockGemmPolicy = ck_tile::BlockGemmARegBSmemCRegV2CustomPolicy<
                scalar_t,
                scalar_t,
                acc_t,
                typename Traits::Gemm0BlockWarps,
                decltype(warp_gemm)>;

            if constexpr(1 < Traits::kNumGemm0Warps)
                return ck_tile::BlockGemmARegBSmemCRegV2<GemmQKProblem, BlockGemmPolicy>{};
            else
                return ck_tile::BlockGemmARegBSmemCRegOneWarpV1<GemmQKProblem, BlockGemmPolicy>{};
        }
        else
        {
            constexpr auto warp_gemm = ck_tile::WarpGemmMfmaDispatcher<
                scalar_t,
                scalar_t,
                acc_t,
                Traits::Gemm0WarpTile::at(ck_tile::number<0>{}),
                Traits::Gemm0WarpTile::at(ck_tile::number<1>{}),
                Traits::Gemm0WarpTile::at(ck_tile::number<2>{}),
                Traits::TransposeC>{};

            using BlockGemmPolicy = ck_tile::BlockGemmARegBRegCRegV1CustomPolicy<
                scalar_t,
                scalar_t,
                acc_t,
                typename Traits::Gemm0BlockWarps,
                decltype(warp_gemm)>;

            return ck_tile::BlockGemmARegBRegCRegV1<GemmQKProblem, BlockGemmPolicy>{};
        }
    }

    CK_TILE_DEVICE static constexpr auto GetPVBlockGemm()
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
            return ck_tile::BlockGemmARegBSmemCRegV2<GemmPVProblem, BlockGemmPolicy>{};
        }
        else
        {
            using BlockGemmPolicy =
                ck_tile::BlockGemmARegBRegCRegV1CustomPolicy<scalar_t,
                                                     scalar_t,
                                                     acc_t,
                                                     typename Traits::Gemm1BlockWarps,
                                                     decltype(warp_gemm)>;
            return ck_tile::BlockGemmARegBRegCRegV1<GemmPVProblem, BlockGemmPolicy>{};
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
            q_dram_window_lengths,
            ck_tile::sequence<true, false>{});

        return ck_tile::make_tile_window(
			q_dram_padding,
			q_dram_window_lengths,
			{0, 0},
            MakeQDramBlockDistribution());
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
            ck_tile::integer_divide_ceil(total_seqlen_kv, Traits::kBlockN) *
                Traits::kBlockN;

        auto k_dram_padding = ck_tile::pad_tensor_view(
            k_dram_naive,
            // ck_tile::make_tuple(ck_tile::number<Traits::kBlockN>{}, ck_tile::number<Traits::kSizeD>{}),
            ck_tile::make_tuple(seqlen_k_padding, ck_tile::number<Traits::kSizeD>{}),
            ck_tile::sequence<kPadSeqLenK_, false>{});

        auto tail_block_lengths = ck_tile::make_tuple(seqlen_k_end % Traits::kBlockN, Traits::kSizeD);
        // auto k_dram_window = ck_tile::make_tile_window(
        //     k_dram_padding, k_dram_window_lengths, {0, 0});
        auto k_dram_window = ck_tile::make_tile_window(
            k_dram_padding, tail_block_lengths, {0, 0});

        return ck_tile::make_tile_window(
            k_dram_window.get_bottom_tensor_view(),
            k_dram_window.get_window_lengths(),
            {seqlen_k_begin, 0});
    }

    template<typename KDramBlockWindowType>
    CK_TILE_DEVICE static auto MakeKDramTileWindowPaged(
        const KDramBlockWindowType k_dram_block_window,
        const int32_t* block_indices,
        const int32_t stride_s_k,
        const int32_t cur_seqlen_k_idx,
        const int32_t page_block_size)
    {
        auto k_dist = MakeKDramTileDistribution();

		auto k_coord = k_dist.calculate_index();
		using KDstrEncode = typename decltype(k_dist)::DstrEncode;
		constexpr ck_tile::index_t NRepeat = KDstrEncode::hs_lengthss_[I0][I0];
		ck_tile::statically_indexed_array<ck_tile::index_t, NRepeat> k_offsets;

		ck_tile::static_for<0, NRepeat, 1>{}([&](auto n0) {
            int32_t seqlen_k_idx_per_repeat = cur_seqlen_k_idx + k_coord[0] + Traits::kBlockN / NRepeat * n0.value;
            int32_t page_idx = seqlen_k_idx_per_repeat / page_block_size;
            int32_t seq_idx = seqlen_k_idx_per_repeat % page_block_size;
			k_offsets[n0] = (block_indices[page_idx] * page_block_size + seq_idx) * stride_s_k;
		});

        return ck_tile::make_tile_scatter_gather(
            k_dram_block_window.get_bottom_tensor_view(),
            k_dram_block_window.get_window_lengths(),
            k_dram_block_window.get_window_origin(),
            k_dist,
            k_offsets); // K DRAM tile window for
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

        auto k_st_lds_window = ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN>{},
                                ck_tile::number<Traits::kSizeD>{}), {0, 0});
        auto k_ld_lds_window = ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN>{},
                                ck_tile::number<Traits::kSizeD>{}), {0, 0});

        return ck_tile::make_tuple(k_st_lds_window, k_ld_lds_window);
    }

    CK_TILE_DEVICE static auto MakeVLdsTileWindow(scalar_t* v_lds_ptr)
    {
        auto v_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            v_lds_ptr, MakeVLdsBlockDescriptor());

        if constexpr (Traits::GemmPVLds)
            return ck_tile::make_tile_window(v_lds,
                ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV>{},
                                    ck_tile::number<Traits::kBlockN>{}),
                {0, 0});
        else
            return ck_tile::make_tile_window(v_lds,
                ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV>{},
                                    ck_tile::number<Traits::kBlockN>{}),
                {0, 0},
                MakeVLds2RegBlockDistribution());

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

    // TODO: control the speed of k copy
    CK_TILE_DEVICE static constexpr auto MakeKDramTileDistribution()
    {
        if constexpr (!Traits::IsBReg)
        {
            constexpr int32_t RepeatsK = 9;
            constexpr int32_t RepeatsN = 1;

            constexpr int32_t kVectorN = 1; // for continous K copy
            constexpr int32_t VectorKMax = 16 / sizeof(scalar_t);

            constexpr int32_t ThreadsPerKMin = Traits::kSizeD / VectorKMax / RepeatsK;
            constexpr int32_t kThrPerBlockN =
                ck_tile::min(Traits::kBlockN / kVectorN, Traits::kBlockSize / ThreadsPerKMin);
            constexpr int32_t kThrPerBlockK = Traits::kBlockSize / kThrPerBlockN;

            constexpr int32_t kNumWarpN = Traits::kNumWarps;
            constexpr int32_t kNumWarpK = 1;

            constexpr int32_t kThrPerWarpN = kThrPerBlockN / kNumWarpN;
            constexpr int32_t kThrPerWarpK = ck_tile::get_warp_size() / kThrPerWarpN;

            constexpr int32_t kVectorK = Traits::kSizeD / RepeatsK / kThrPerBlockK;

            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<
                    ck_tile::sequence<>,
                    ck_tile::tuple<ck_tile::sequence<RepeatsN, kNumWarpN, kThrPerWarpN, kVectorN>,
                                   ck_tile::sequence<RepeatsK, kNumWarpK, kThrPerWarpK, kVectorK>>,
                    ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                    ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                    ck_tile::sequence<1, 1, 2, 2>,
                    ck_tile::sequence<0, 3, 0, 3>>{});

            // return ck_tile::make_static_tile_distribution(
            //     ck_tile::tile_distribution_encoding<
            //         ck_tile::sequence<>,
            //         ck_tile::tuple<ck_tile::sequence<1, 2, 8, 1>,
            //                        ck_tile::sequence<9, 2, 8, 4>>,
            //         ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
            //         ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
            //         ck_tile::sequence<1, 1, 2, 2>,
            //         ck_tile::sequence<0, 3, 0, 3>>{});
        }
        else
        {
			return ck_tile::make_static_tile_distribution(
                ck_tile::remove_cvref_t<decltype(GetQKBlockGemm())>::MakeBBlockDistributionEncode());
        }
    }

    CK_TILE_DEVICE static constexpr auto MakeVShuffleTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::remove_cvref_t<decltype(GetPVBlockGemm())>::MakeBBlockDistributionEncode());
    }

    CK_TILE_DEVICE static constexpr auto DebugMakeVShuffleTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                ck_tile::tuple<
                        ck_tile::sequence<1, 4, 8, 1>,
                        ck_tile::sequence<1, 1, 8, 8>>,
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<0, 3, 0, 3>>{});
    }
    
    CK_TILE_DEVICE static constexpr auto MakePShuffleTileDistribution()
    {
        if constexpr (!Traits::IsBReg)
        {
			return ck_tile::remove_cvref_t<decltype(GetPVBlockGemm())>::template MakeABlockTileDistribution<
				Traits::kBlockM,
				Traits::kBlockN>();

            // constexpr auto p_encoding = decltype(GetQKBlockGemm().MakeCBlockTile())::get_tile_distribution().get_static_tile_distribution_encoding();
            // constexpr auto N = p_encoding.hs_lengthss_.at(I0);
            // constexpr auto K = p_encoding.hs_lengthss_.at(I1);
            //
            // return ck_tile::make_static_tile_distribution(
            //     ck_tile::tile_distribution_encoding<ck_tile::sequence<K[1]>,
            //            ck_tile::tuple<ck_tile::sequence<N[0], N[1], N[2]>, ck_tile::sequence<K[2], K[3], K[4]>>,
            //            ck_tile::tuple<ck_tile::sequence<1, 0>, ck_tile::sequence<2, 1>>,
            //            ck_tile::tuple<ck_tile::sequence<1, 0>, ck_tile::sequence<1, 2>>,
            //            ck_tile::sequence<1, 2, 2>,
            //            ck_tile::sequence<0, 0, 2>>{});
        }
        else
        {
            return ck_tile::make_static_tile_distribution(
                ck_tile::remove_cvref_t<decltype(GetPVBlockGemm())>::MakeABlockDistributionEncode());
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

// =====================================================================================================================
// Kernel Entries
// template <typename Traits,
//           typename scalar_t,
//           typename acc_t,
//           bool Is_causal>
// __device__ __inline__ void compute_attn_1rowblock_splitkv_mla()
// {
//
// }


template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
__global__ void flash_fwd_splitkv_mla_kernel(
    const FlashMlaFwdParams params)
{
    using Policy  = FlashMlaKernelPolicy<Traits, scalar_t, float>;

    constexpr int32_t kSizeD             = Traits::kSizeD; 
    constexpr int32_t kSizeDV            = Traits::kSizeDV; 
    constexpr int32_t kNumThreads        = Traits::kNumThreads;
    constexpr int32_t kNumThreadsSoftmax = Traits::kNumThreadsSoftmax;
    constexpr int32_t kBlockM            = Traits::kBlockM;
    constexpr int32_t kBlockN            = Traits::kBlockN;

    constexpr int32_t kPackScalar = 16 / sizeof(scalar_t);
    constexpr int32_t kPackAcc = 16 / sizeof(scalar_t);
    constexpr int32_t kKPack = kPackScalar;

    constexpr auto I0 = ck_tile::number<0>{};
    constexpr auto I1 = ck_tile::number<1>{};

    const int32_t i_block_m   = blockIdx.x;
    const int32_t i_nhead     = blockIdx.y;
    const int32_t i_nhead_k   = i_nhead / params.hq_hk_ratio;
    const int32_t i_partition = blockIdx.z;

    const ck_tile::index_t i_m0 = __builtin_amdgcn_readfirstlane(i_block_m * kBlockM);

    const auto f_max = [](auto e0, auto e1) { return max(e0, e1); };
    const auto f_sum = [](auto e0, auto e1) { return e0 + e1; };

    const int32_t tidx = threadIdx.x; 

    auto gemm_0 = Policy::GetQKBlockGemm();

    auto s_acc = gemm_0.MakeCBlockTile();
    using SBlockTileType = decltype(ck_tile::cast_tile<acc_t>(s_acc));
    using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
        SBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
    auto m = MLBlockTileType{};
    auto l = MLBlockTileType{};

    auto gemm_1 = Policy::GetPVBlockGemm();
    auto o_acc = gemm_1.MakeCBlockTile();

#ifdef enable_lds
    extern __shared__ char shared_memory[];
    // __shared__ char shared_memory[kBlockM * kSizeDV * sizeof(scalar_t)];
    scalar_t* kv_lds_ptr = reinterpret_cast<scalar_t*>(shared_memory);
    scalar_t* p_shuffle_ptr = kv_lds_ptr;

    auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
        kv_lds_ptr, Policy::MakeKLdsBlockDescriptor());

    auto k_st_lds_window = ck_tile::make_tile_window(k_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockN>{},
                            ck_tile::number<Traits::kSizeDV>{}), {0, 0});

    auto v_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
        kv_lds_ptr, Policy::MakeVLdsBlockDescriptor());
    auto v_ld_lds_window = ck_tile::make_tile_window(v_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV>{},
                            ck_tile::number<Traits::kBlockN>{}), {0, 0},
        Policy::MakeVShuffleTileDistribution());

    auto p_shuffle_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
        p_shuffle_ptr, Policy::MakePShuffleLdsDescriptor());

    auto p_st_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
                            ck_tile::number<Traits::kBlockN>{}), {0, 0});
    auto p_ld_lds_window = ck_tile::make_tile_window(p_shuffle_lds,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{},
                            ck_tile::number<Traits::kBlockN>{}), {0, 0},
        Policy::MakePShuffleTileDistribution());
#endif // disable_lds
    

    TileSchedulerMetaData metadata;
    reinterpret_cast<int4*>(&(metadata.data))[0] = reinterpret_cast<int4*>(
        params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4];
    reinterpret_cast<int4*>(&(metadata.data))[1] = reinterpret_cast<int4*>(
        params.p_tile_scheduler_metadata)[i_partition * TileSchedulerMetaDataSizeInInt4 + 1];

    const int32_t begin_batch_idx   = metadata.core.begin_batch_idx;
    const int32_t begin_seqlen_idx  = metadata.core.begin_seqlen_idx;
    const int32_t end_batch_idx     = metadata.core.end_batch_idx;
    const int32_t end_seqlen_idx    = metadata.core.end_seqlen_idx;
    const int32_t begin_n_split_idx = metadata.core.begin_n_split_idx;

    using KBlockTileType = decltype(
        ck_tile::make_static_distributed_tensor<scalar_t>(
            Policy::MakeKDramTileDistribution()));

    KBlockTileType k_block_tiles[2] { KBlockTileType{}, KBlockTileType{} };

    auto v_tile = ck_tile::make_static_distributed_tensor<scalar_t>(Policy::MakeVShuffleTileDistribution());

    for (int32_t i_batch = begin_batch_idx; i_batch <= end_batch_idx; ++i_batch)
    {
        const int32_t i_split     = i_batch == begin_batch_idx ? begin_n_split_idx : 0;
        const int32_t seqlen_k    = params.p_cu_seqlens_k[i_batch];
        const int32_t n_block_min = i_batch == begin_batch_idx ? begin_seqlen_idx / kBlockN : 0;
        const int32_t n_block_max = i_batch == end_batch_idx ? ck_tile::integer_divide_ceil(end_seqlen_idx, kBlockN) : ck_tile::integer_divide_ceil(seqlen_k, kBlockN);

        const bool NoSplit = n_block_min == 0 && n_block_max == ck_tile::integer_divide_ceil(seqlen_k, kBlockN);
        const int32_t split_seqlen_k_begin = i_batch == begin_batch_idx ? begin_seqlen_idx : 0;
        const int32_t split_seqlen_k_end = i_batch == end_batch_idx ? end_seqlen_idx : seqlen_k;

        int32_t i_block_n = n_block_max - 1;

        if (i_batch > begin_batch_idx)
        {
            __syncthreads();
        }

        ck_tile::clear_tile(o_acc);
        ck_tile::clear_tile(m);
        ck_tile::clear_tile(l);

        const int32_t q_offset = i_batch * params.stride_b_q +
                                 i_block_m * kBlockM * params.stride_s_q +
                                 i_nhead * params.stride_h_q;
        auto q_dram_window = Policy::MakeQDramTileWindow(
            reinterpret_cast<scalar_t*>(params.p_query) + q_offset,
            params.size_s,
            params.stride_s_q);
        auto q = load_tile(q_dram_window);

        auto page_batch_offset = params.block_table_batch_stride * i_batch;
        const auto* block_indices = params.p_block_table + page_batch_offset;

        int32_t seqlen_k_begin = 0;
        auto k_dram_block_window = Policy::MakeKDramTileWindow(
            reinterpret_cast<scalar_t*>(params.p_key) +
                params.stride_h_k * i_nhead_k,
            params.total_seqlen_kv,
            params.stride_s_k,
            seqlen_k_begin);

        auto k_dram_window = Policy::template MakeKDramTileWindowPaged(
            k_dram_block_window,
            block_indices,
            params.stride_s_k,
            i_block_n * kBlockN,
            params.page_block_size);

        int32_t tail_offset = block_indices[split_seqlen_k_end / params.page_block_size] * params.page_block_size;
        int32_t tail_begin = (tail_offset + split_seqlen_k_end % params.page_block_size) * Traits::kSizeD;
        int32_t tail_end   = (tail_offset + params.page_block_size) * Traits::kSizeD;
        k_dram_window.template load<KBlockTileType, -1, true, true>(k_block_tiles[0], tail_begin, tail_end);
        // k_dram_window.load(k_block_tiles[0]);

        int32_t k_ld_stage = 0;
        int32_t k_st_stage = 1;

        constexpr int n_masking_steps = !Is_causal ? 1 : ck_tile::integer_divide_ceil(kBlockM, kBlockN) + 1;
        int masking_step = n_masking_steps;

        auto p = ck_tile::make_static_distributed_tensor<scalar_t>(
            Policy::MakePShuffleTileDistribution());

#pragma unroll 1
        for (; i_block_n > n_block_min; --masking_step, --i_block_n)
        {
            __builtin_amdgcn_sched_barrier(0);
            __syncthreads();
			ck_tile::block_sync_lds();
            move_tile_window(k_dram_block_window, {-kBlockN, 0});
            auto k_dram_window = Policy::template MakeKDramTileWindowPaged(
                k_dram_block_window,
                block_indices,
                params.stride_s_k,
                (i_block_n - 1) * kBlockN,
                params.page_block_size);
            k_dram_window.load(k_block_tiles[k_st_stage]);
            k_st_stage ^= 1;
            
#ifdef enable_lds
			// auto v_st_lds_window = ck_tile::make_tile_window(
			// 	k_st_lds_window.get_bottom_tensor_view(),
			// 	k_st_lds_window.get_window_lengths(),
			// 	{0, 0});
   //          ck_tile::store_tile(v_st_lds_window, 
   //                              ck_tile::get_slice_tile(
   //                                  k_block_tiles[k_ld_stage], 
   //                                  ck_tile::sequence<0, kBlockN * 0>{},
   //                                  ck_tile::sequence<kBlockN, kBlockN * (0 + 1)>{}));

            // ck_tile::static_for<0, kSizeDV / kBlockN, 1>{}([&](auto k) {
            //     ck_tile::store_tile(v_st_lds_window, 
            //                         ck_tile::get_slice_tile(
            //                             k_block_tiles[k_ld_stage], 
            //                             ck_tile::sequence<0, kBlockN * k>{},
            //                             ck_tile::sequence<kBlockN, kBlockN * (k + 1)>{}));
            //     ck_tile::move_tile_window(v_st_lds_window, {0, kBlockN});
            // });
#endif

            ck_tile::static_for<0, kSizeDV / kBlockN, 1>{}([&](auto k) {
                ck_tile::clear_tile(s_acc);
                gemm_0(s_acc,
                       q,
                       k_block_tiles[k_ld_stage]);
            }

            if (blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0 && i_block_n == n_block_max - 1)
            {
                auto debug_s_dram = ck_tile::make_naive_tensor_view(
                    reinterpret_cast<scalar_t*>(params.p_debug_p),
                    ck_tile::make_tuple(kBlockM, kBlockN),
                    ck_tile::make_tuple(kBlockN, 1),  // strides
                    ck_tile::number<kBlockN>{},
                    I1);
                auto debug_s_window = ck_tile::make_tile_window(
                    debug_s_dram,
                    ck_tile::make_tuple(kBlockM, kBlockN),
                    {0, 0});
                ck_tile::store_tile(debug_s_window, ck_tile::cast_tile<scalar_t>(s_acc));
            }


//             const bool is_masking_step = masking_step > 0;
//             const bool is_first_masking_step = masking_step == n_masking_steps;
//
//             __syncthreads();
//             // if seq_len == 1, never need to add mask to s
//             constexpr auto sacc_spans = decltype(s_acc)::get_distributed_spans();
//             if (is_masking_step) {
//                 ck_tile::sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
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
//
// #ifdef enable_lds
// 			ck_tile::block_sync_lds();
//             ck_tile::load_tile(v_tile, v_ld_lds_window);
// 			ck_tile::block_sync_lds();
// #endif
//
// 			ck_tile::block_sync_lds();
//             auto m_local = ck_tile::block_tile_reduce<acc_t>(
//                 s_acc,
//                 ck_tile::sequence<1>{},
//                 f_max,
//                 -ck_tile::numeric<acc_t>::infinity());
//             block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});
// 			ck_tile::block_sync_lds();
//
//             const auto m_old = m;
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
// #ifdef enable_lds
// 			ck_tile::block_sync_lds();
//             ck_tile::store_tile(p_st_lds_window, ck_tile::cast_tile<scalar_t>(p_compute));
// 			ck_tile::block_sync_lds();
// #endif
//
//             auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
//                 p_compute, ck_tile::sequence<1>{}, f_sum, acc_t{0});
//             ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});
//
// #ifdef enable_lds
// 			ck_tile::block_sync_lds();
//             ck_tile::load_tile(p, p_ld_lds_window);
// 			ck_tile::block_sync_lds();
// #endif
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
// 			ck_tile::block_sync_lds();
//             gemm_1(o_acc,
//                    p,
//                    v_tile);
            k_ld_stage ^= 1;
        }

        //tail block
//         {
//             __syncthreads();
// 			ck_tile::block_sync_lds();
//             move_tile_window(k_dram_block_window, {-kBlockN, 0});
//             auto k_dram_window = Policy::template MakeKDramTileWindowPaged(
//                 k_dram_block_window,
//                 block_indices,
//                 params.stride_s_k,
//                 (i_block_n - 1) * kBlockN,
//                 params.page_block_size);
//             k_dram_window.load(k_block_tiles[k_st_stage]);
//             k_st_stage ^= 1;
//             
// #ifdef enable_lds
// 			auto v_st_lds_window = ck_tile::make_tile_window(
// 				k_st_lds_window.get_bottom_tensor_view(),
// 				k_st_lds_window.get_window_lengths(),
// 				{0, 0});
//             ck_tile::static_for<0, kSizeDV / kBlockN, 1>{}([&](auto k) {
//                 ck_tile::store_tile(v_st_lds_window, 
//                                     ck_tile::get_slice_tile(
//                                         k_block_tiles[k_ld_stage], 
//                                         ck_tile::sequence<0, kBlockN * k>{},
//                                         ck_tile::sequence<kBlockN, kBlockN * (k + 1)>{}));
//                 ck_tile::move_tile_window(v_st_lds_window, {0, kBlockN});
//             });
// #endif
//
//             ck_tile::clear_tile(s_acc);
//             gemm_0(s_acc,
//                    q,
//                    k_block_tiles[k_ld_stage]);
//
//             const bool is_masking_step = masking_step > 0;
//             const bool is_first_masking_step = masking_step == n_masking_steps;
//
//             __syncthreads();
//             // if seq_len == 1, never need to add mask to s
//             constexpr auto sacc_spans = decltype(s_acc)::get_distributed_spans();
//             if (is_masking_step) {
//                 ck_tile::sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
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
//
// #ifdef enable_lds
// 			ck_tile::block_sync_lds();
//             ck_tile::load_tile(v_tile, v_ld_lds_window);
// 			ck_tile::block_sync_lds();
// #endif
//
// 			ck_tile::block_sync_lds();
//             auto m_local = ck_tile::block_tile_reduce<acc_t>(
//                 s_acc,
//                 ck_tile::sequence<1>{},
//                 f_max,
//                 -ck_tile::numeric<acc_t>::infinity());
//             block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});
// 			ck_tile::block_sync_lds();
//
//             const auto m_old = m;
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
// #ifdef enable_lds
// 			ck_tile::block_sync_lds();
//             ck_tile::store_tile(p_st_lds_window, ck_tile::cast_tile<scalar_t>(p_compute));
// 			ck_tile::block_sync_lds();
// #endif
//
//             auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
//                 p_compute, ck_tile::sequence<1>{}, f_sum, acc_t{0});
//             ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});
//
// #ifdef enable_lds
// 			ck_tile::block_sync_lds();
//             ck_tile::load_tile(p, p_ld_lds_window);
// 			ck_tile::block_sync_lds();
// #endif
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
// 			ck_tile::block_sync_lds();
//             gemm_1(o_acc,
//                    p,
//                    v_tile);
//
//         }

        __builtin_amdgcn_sched_barrier(0);
        ck_tile::block_sync_lds();
        // __builtin_amdgcn_sched_group_barrier(0x008, 1, 0);
        // __builtin_amdgcn_sched_group_barrier(0x008, 8, 0);

        // if ((threadIdx.x == 0 || threadIdx.x == DEBUG_TID) && blockIdx.x == 0 && blockIdx.y == 0 && blockIdx.z == 0)
        //     printf("enter Epilogue \n");

        // Epilogue
        auto lse_acc = ck_tile::make_static_distributed_tensor<acc_t>(m.get_tile_distribution());
        constexpr auto lse_acc_spans = decltype(lse_acc)::get_distributed_spans();
        ck_tile::sweep_tile_span(lse_acc_spans[I0], [&](auto idx0) {
            constexpr auto i_idx = ck_tile::make_tuple(idx0);
            lse_acc(i_idx) = m[i_idx] * params.scale_softmax + log(l[i_idx]);
        });


        if (NoSplit)
        {
            const int32_t lse_offset = i_batch * params.size_s;
            auto lse_dram_window = Policy::MakeLSEDramTileWindow(
                reinterpret_cast<acc_t*>(params.p_softmax_lse) + lse_offset,
                params.size_s,
                i_m0);
            ck_tile::store_tile(lse_dram_window, lse_acc);
        }
        else
        {
            const int32_t split_offset = params.p_num_splits[i_batch];
            const int32_t lseacc_offset =
                ((split_offset + i_split) * params.size_h + i_nhead) *
                params.size_s + i_block_m * kBlockM;
            auto lseacc_dram_window = Policy::MakeLSEDramTileWindow(
                reinterpret_cast<acc_t*>(params.p_softmax_lseaccum) + lseacc_offset,
                params.size_s);
            ck_tile::store_tile(lseacc_dram_window, lse_acc);
        }

        constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
        ck_tile::sweep_tile_span(o_spans[I0], [&](auto idx0) {
            constexpr auto i_idx = ck_tile::make_tuple(idx0);
            const auto tmp = [&]() {
                    return l[i_idx] == 0.f ? 0.f : 1 / l[i_idx];
            }();
            ck_tile::sweep_tile_span(o_spans[I1], [&](auto idx1) {
                constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
                o_acc(i_j_idx) *= tmp;
            });
        });
        if (NoSplit)
        {
            const int32_t o_offset = i_batch * params.stride_b_o;
            auto o_dram_window = Policy::template MakeODramTileWindow<scalar_t>(
                reinterpret_cast<scalar_t*>(params.p_output) + o_offset,
                params.size_s,
                i_m0);
            ck_tile::store_tile(o_dram_window, ck_tile::cast_tile<scalar_t>(o_acc));
        }
        else
        {
            const int32_t split_offset = params.p_num_splits[i_batch];
            const int32_t oacc_offset =
                (((split_offset + i_split) * params.size_h + i_nhead) *
                params.size_s + i_block_m * kBlockM) * kSizeDV;
            auto o_acc_dram_window = Policy::template MakeODramTileWindow<acc_t>(
                reinterpret_cast<acc_t*>(params.p_output_accum) + oacc_offset,
                params.size_s);
            ck_tile::store_tile(o_acc_dram_window, o_acc);
        }
    }
}

// template <typename Traits, typename scalar_t, typename acc_t, bool Is_causal>
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
//     auto gemm_0 = Policy::GetQKBlockGemm();
//
//     auto s_acc = gemm_0.MakeCBlockTile();
//     using SBlockTileType = decltype(ck_tile::cast_tile<acc_t>(s_acc));
//     using MLBlockTileType = decltype(ck_tile::block_tile_reduce<acc_t>(
//         SBlockTileType{}, ck_tile::sequence<1>{}, f_max, acc_t{0}));
//     auto m = MLBlockTileType{};
//     auto l = MLBlockTileType{};
//
//     auto gemm_1 = Policy::GetPVBlockGemm();
//     auto o_acc = gemm_1.MakeCBlockTile();
//
//     scalar_t* kv_lds_ptr = reinterpret_cast<scalar_t*>(shared_ptr);
//     scalar_t* p_shuffle_ptr = kv_lds_ptr + Traits::kBlockN * Traits::kSizeDV * Traits::kStages;
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
//         // auto k_page_block_navigator = Policy::MakeKPageBlockNavigator(
//         //     params.p_key,
//         //     params.p_block_table,
//         //     params.page_block_size,
//         //     params.stride_b_k,
//         //     params.stride_s_k,
//         //     params.block_table_batch_stride * i_batch,
//         //     params.stride_h_k * i_nhead_k,
//         //     split_seqlen_k_end);
//         //
//         // constexpr static auto k_dram_window_lengths = ck_tile::make_tuple(Traits::kBlockN, Traits::kSizeD);
//         //
//         // auto [i_page_block_k_tail, k_dram_window_tail] = k_page_block_navigator.make_tile_window(
//         //     k_dram_window_lengths, {(n_block_max - 1) * kBlockN, 0}, Policy::MakeKDramTileDistribution());
//
//
//         auto page_batch_offset = params.block_table_batch_stride * i_batch;
//         const auto* block_indices = params.p_block_table + page_batch_offset;
//         int32_t seqlen_k_begin = 0;
//         auto k_dram_block_window = Policy::MakeKDramTileWindow(
//             reinterpret_cast<scalar_t*>(params.p_key) +
//                 params.stride_h_k * i_nhead_k,
//             params.total_seqlen_kv,
//             params.stride_s_k,
//             seqlen_k_begin);
//         auto k_dram_window = Policy::template MakeKDramTileWindowPaged(
//             k_dram_block_window,
//             block_indices,
//             params.stride_s_k,
//             i_block_n * kBlockN,
//             params.page_block_size);
//
//         int32_t tail_offset = block_indices[split_seqlen_k_end / params.page_block_size] * params.page_block_size;
//         int32_t tail_begin = (tail_offset + split_seqlen_k_end % params.page_block_size) * Traits::kSizeD;
//         int32_t tail_end   = (tail_offset + params.page_block_size) * Traits::kSizeD;
//         auto k_block_tile = k_dram_window.template load<-1, true, true>(tail_begin, tail_end);
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
//         int32_t st_stage = 0;
//         int32_t ld_stage = 0;
//
//         // auto k_block_tile = ck_tile::load_tile(k_dram_window_tail);
//         ck_tile::store_tile(k_st_lds_window, k_block_tile);
//
//         // auto [i_page_block_k, k_dram_window] = k_page_block_navigator.make_tile_window(
//         //     k_dram_window_lengths, {(n_block_max - 2) * kBlockN, 0}, Policy::MakeKDramTileDistribution());
//
//         ck_tile::move_tile_window(k_st_lds_window, {kBlockN, 0});
//         ++st_stage;
//
//         constexpr int n_masking_steps = !Is_causal ? 1 : ck_tile::integer_divide_ceil(kBlockM, kBlockN) + 1;
//         int masking_step = n_masking_steps;
//
//
// #pragma unroll 1
//         for (; i_block_n > n_block_min; --masking_step, --i_block_n)
//         {
//
// 			ck_tile::clear_tile(s_acc);
//             ck_tile::block_sync_lds();
//             move_tile_window(k_dram_block_window, {-kBlockN, 0});
//             auto k_dram_window = Policy::template MakeKDramTileWindowPaged(
//                 k_dram_block_window,
//                 block_indices,
//                 params.stride_s_k,
//                 (i_block_n - 1) * kBlockN,
//                 params.page_block_size);
//             auto k_block_tile = k_dram_window.load();
//
//             gemm_0(s_acc,
//                    q,
//                    k_ld_lds_window);
//
//             store_tile(k_st_lds_window, k_block_tile);
//             // i_page_block_k = k_page_block_navigator.move_tile_window(i_page_block_k, k_dram_window, {-kBlockN, 0});
//             ck_tile::move_tile_window(k_st_lds_window,
//                 {move_lds_length[static_cast<int32_t>(++st_stage % Traits::kStages == 0)], 0});
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
//             block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});
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
//             ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});
//
//             l{j}, Oacc{j}
//             if constexpr (Traits::TransposeC)
//             {
//                 constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
//                 ck_tile::sweep_tile_span(o_spans[I0], [&](auto idx0) {
//                     constexpr auto i_idx = ck_tile::make_tuple(idx0);
//                     const auto tmp = exp2(params.scale_softmax_log2 * m_old[i_idx] - params.scale_softmax_log2 * m[i_idx]);
//                     l(i_idx) = tmp * l[i_idx] + rowsum_p[i_idx];
//                     ck_tile::sweep_tile_span(o_spans[I1], [&](auto idx1) {
//                         constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                         o_acc(i_j_idx) = o_acc[i_j_idx] * tmp;
//                     });
//                 });
//             }
//             else
//             {
//                 constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
//                 ck_tile::sweep_tile_span(o_spans[I1], [&](auto idx1) {
//                     constexpr auto j_idx = ck_tile::make_tuple(idx1);
//                     const auto tmp = exp2(params.scale_softmax_log2 * m_old[j_idx] - params.scale_softmax_log2 * m[j_idx]);
//                     l(j_idx) = tmp * l[j_idx] + rowsum_p[j_idx];
//                     ck_tile::sweep_tile_span(o_spans[I1], [&](auto idx0) {
//                         constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//                     });
//                 });
//             }
//
//             if constexpr (Traits::GemmPVLds)
//             {
//                 gemm_1(o_acc,
//                        ck_tile::load_tile(p_ld_lds_window),
//                        v_ld_lds_window);
//             }
//             else
//             {
//                 auto p = ck_tile::cast_tile<scalar_t>(p_compute);
//                 auto p_gemm_in = ck_tile::make_static_distributed_tensor<scalar_t>(
//                     Policy::MakePShuffleTileDistribution(),
//                     p.get_thread_buffer());
//                 auto v_tile = ck_tile::load_tile(v_ld_lds_window);
//
//                 __syncthreads();
//                 gemm_1(o_acc,
//                        p_gemm_in,
//                        v_tile);
//             }
//             auto ld_stage_offset = static_cast<int32_t>(++ld_stage % Traits::kStages == 0);
//             move_tile_window(k_ld_lds_window, {move_lds_length[ld_stage_offset], 0});
//             move_tile_window(v_ld_lds_window, {0, move_lds_length[ld_stage_offset]});
//         }
//
//         // tail block
//    //      {
// 			// ck_tile::clear_tile(s_acc);
//    //          ck_tile::block_sync_lds();
//    //          gemm_0(s_acc,
//    //                 q,
//    //                 k_ld_lds_window);
// 			//
//    //          const bool is_masking_step = masking_step > 0;
//    //          const bool is_first_masking_step = masking_step == n_masking_steps;
// 			//
//    //          // if seq_len == 1, never need to add mask to s
//    //          if (is_masking_step) {
//    //              constexpr auto sacc_spans = decltype(s_acc)::get_distributed_spans();
//    //              sweep_tile_span(sacc_spans[I0], [&](auto idx0) {
//    //                  // constexpr auto i_idx = ck_tile::make_tuple(idx0);
//    //                  sweep_tile_span(sacc_spans[I1], [&](auto idx1) {
//    //                      constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//    //                      const auto tile_idx = get_x_indices_from_distributed_indices(
//    //                          s_acc.get_tile_distribution(), make_tuple(idx0, idx1));
//    //                      auto row_id = tile_idx.at(ck_tile::number<0>{});
//    //                      auto col_id = tile_idx.at(ck_tile::number<1>{});
//    //                      if constexpr (!Is_causal)
//    //                      {
//    //                          if (col_id >= int(seqlen_k - i_block_n * kBlockN))
//    //                              s_acc(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//    //                      }
//    //                      else
//    //                      {
//    //                          int32_t col_limit_right = seqlen_k - 1 - i_block_n * kBlockN -
//    //                              (params.size_s - 1 - (i_block_m * kBlockM + row_id)) / params.num_groups;
//    //                          if (col_id > col_limit_right)
//    //                              s_acc(i_j_idx) = -ck_tile::numeric<acc_t>::infinity();
//    //                      }
//    //                  });
//    //              });
//    //          }
// 			//
//    //          auto m_local = ck_tile::block_tile_reduce<acc_t>(
//    //              s_acc,
//    //              ck_tile::sequence<1>{},
//    //              f_max,
//    //              -ck_tile::numeric<acc_t>::infinity());
//    //          ck_tile::block_tile_reduce_sync(m_local, f_max, ck_tile::bool_constant<false>{});
// 			//
//    //          const auto m_old = m;
// 			//
//    //          ck_tile::tile_elementwise_inout(
//    //              [](auto& e0, auto e1, auto e2) { e0 = max(e1, e2); }, m, m_old, m_local);
// 			//
//    //          auto p_compute = ck_tile::make_static_distributed_tensor<acc_t>(
//    //              s_acc.get_tile_distribution());
// 			//
//    //          constexpr auto p_spans = decltype(p_compute)::get_distributed_spans();
//    //          sweep_tile_span(p_spans[I0], [&](auto idx0) {
//    //              constexpr auto i_idx = ck_tile::make_tuple(idx0);
//    //              auto row_max = params.scale_softmax_log2 * m[i_idx];
//    //              sweep_tile_span(p_spans[I1], [&](auto idx1) {
//    //                  constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//    //                  p_compute(i_j_idx) = exp2(params.scale_softmax_log2 * s_acc[i_j_idx] - row_max);
//    //              });
//    //          });
// 			//
//    //          ck_tile::store_tile(p_st_lds_window, ck_tile::cast_tile<scalar_t>(p_compute));
//    //          auto rowsum_p = ck_tile::block_tile_reduce<acc_t>(
//    //              p_compute, ck_tile::sequence<1>{}, f_sum, acc_t{0});
//    //          ck_tile::block_tile_reduce_sync(rowsum_p, f_sum, ck_tile::bool_constant<false>{});
// 			//
//    //          // l{j}, Oacc{j}
//    //          constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
//    //          sweep_tile_span(o_spans[I0], [&](auto idx0) {
//    //              constexpr auto i_idx = ck_tile::make_tuple(idx0);
//    //              const auto tmp = exp2(params.scale_softmax_log2 * m_old[i_idx] - params.scale_softmax_log2 * m[i_idx]);
//    //              l(i_idx) = tmp * l[i_idx] + rowsum_p[i_idx];
//    //              sweep_tile_span(o_spans[I1], [&](auto idx1) {
//    //                  constexpr auto i_j_idx = ck_tile::make_tuple(idx0, idx1);
//    //                  o_acc(i_j_idx) *= tmp;
//    //              });
//    //          });
// 			//
// 			//
//    //          if constexpr (Traits::GemmPVLds)
//    //          {
//    //              // auto p = ck_tile::cast_tile<scalar_t>(p_compute);
//    //              // gemm_1(o_acc,
//    //              //        p,
//    //              //        v_ld_lds_window);
//    //              gemm_1(o_acc,
//    //                     ck_tile::load_tile(p_ld_lds_window),
//    //                     v_ld_lds_window);
//    //          }
//    //          else
//    //          {
//    //              auto p = ck_tile::cast_tile<scalar_t>(p_compute);
//    //              auto p_gemm_in = ck_tile::make_static_distributed_tensor<scalar_t>(
//    //                  Policy::MakePShuffleTileDistribution(),
//    //                  p.get_thread_buffer());
//    //              auto v_tile = ck_tile::load_tile(v_ld_lds_window);
// 			//
//    //              __syncthreads();
//    //              gemm_1(o_acc,
//    //                     p_gemm_in,
//    //                     v_tile);
//    //          }
//    //          auto ld_stage_offset = static_cast<int32_t>(++ld_stage % Traits::kStages == 0);
//    //          move_tile_window(k_ld_lds_window, {move_lds_length[ld_stage_offset], 0});
//    //          move_tile_window(v_ld_lds_window, {0, move_lds_length[ld_stage_offset]});
//    //      }
//
//         // Epilogue
//         auto lse_acc = ck_tile::make_static_distributed_tensor<acc_t>(m.get_tile_distribution());
//         constexpr auto lse_acc_spans = decltype(lse_acc)::get_distributed_spans();
//         ck_tile::sweep_tile_span(lse_acc_spans[I0], [&](auto idx0) {
//             constexpr auto i_idx = ck_tile::make_tuple(idx0);
//             lse_acc(i_idx) = m[i_idx] * params.scale_softmax + log(l[i_idx]);
//         });
//
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
//     }
// }



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

	if constexpr (!Traits::IsBReg)
    {
        // auto kernel = &flash_fwd_splitkv_mla_kernel_lds<Traits, scalar_t, acc_t, Is_causal>;
        // constexpr int64_t smem_size = Traits::kBlockN * Traits::kSizeDV * Traits::kStages * sizeof(scalar_t) + Traits::kBlockM * Traits::kBlockN * sizeof(scalar_t);
        // kernel<<<grid, Traits::kNumThreads, smem_size, stream>>>(params);
    }
    else
    {
        constexpr int64_t smem_size = Traits::kBlockN * Traits::kSizeDV * sizeof(scalar_t);
        auto kernel = &flash_fwd_splitkv_mla_kernel<Traits, scalar_t, acc_t, Is_causal>;
        kernel<<<grid, Traits::kNumThreads, smem_size, stream>>>(params);
    }

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
            });
            ck_tile::move_tile_window(oaccu_window, {size_hs, 0});
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

    query = query.view({batch_size, seqlen_q_ori, num_heads_k, num_groups, head_size}).transpose(2, 3)
                .reshape({batch_size, seqlen_q, num_heads, head_size});

    // CHECK_SHAPE(query, batch_size, seqlen_q, num_heads, head_size);
    // CHECK_SHAPE(key_cache, num_blocks, page_block_size, num_heads, head_size);

    auto output = torch::zeros({batch_size, seqlen_q, num_heads, head_size_v}, opts);
    auto softmax_lse = torch::zeros({batch_size, num_heads, seqlen_q}, opts.dtype(torch::kFloat32));

    auto softmax_lseaccum = torch::zeros({batch_size + num_cu_parts, num_heads, seqlen_q}, opts.dtype(torch::kFloat32));
    auto output_accum = torch::zeros({batch_size + num_cu_parts, num_heads, seqlen_q, head_size_v}, opts.dtype(torch::kFloat32));

    auto debug_m_inner = torch::zeros({2, Traits::kBlockM}, opts);
    auto debug_v_inner = torch::zeros({head_size_v, Traits::kBlockN}, opts);
    auto debug_p_inner = torch::zeros({Traits::kBlockM, Traits::kBlockN}, opts);
    auto debug_o_inner = torch::zeros({Traits::kBlockM, Traits::kSizeDV}, opts.dtype(torch::kFloat32));

    FlashMlaFwdParams params = {};
    params.p_cu_seqlens_k            = cache_seqlens.data_ptr<int32_t>();
    params.p_block_table             = block_table.data_ptr<int32_t>();
    params.p_tile_scheduler_metadata = tile_scheduler_metadata.data_ptr<int32_t>();
    params.p_num_splits              = num_splits.data_ptr<int32_t>();

    params.p_query            = query.data_ptr();
    params.p_key              = key_cache.data_ptr();
    params.p_value            = vcache.data_ptr();

    params.p_debug_m          = debug_m_inner.data_ptr();
    params.p_debug_value      = debug_v_inner.data_ptr();
    params.p_debug_p          = debug_p_inner.data_ptr();
    params.p_debug_output     = debug_o_inner.data_ptr();

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

    dispatch_fmla_fwd_splictkv<Traits, ck_tile::fp16_t, float, true>(params);
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
    return {output, softmax_lse, debug_m_inner, debug_p_inner, debug_v_inner, debug_o_inner};
}
