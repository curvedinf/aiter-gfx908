// SPDX-License-Identifier: MIT
// Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

#include <torch/python.h>
#include <c10/cuda/CUDAGuard.h>
#include <ck_tile/core.hpp>
#include <ck_tile/core/tensor/tile_scatter_gather.hpp>
#include <ck_tile/host.hpp>
#include <ck_tile/ops/fmha.hpp>
#include <ck_tile/ops/gemm.hpp>
#include "block_gemm_areg_bsmem_creg.hpp"
#include "fmla_a16w16_qh16_m16x4_n16x1_coex0_mask1.hpp"

// =====================================================================================================================
// Utils
//
// #define ZZDebug
#define enable_inline
#define FMLA_FWD_FAST_EXP2 1
#define DEBUG_ONE_KERNEL 0
#define HEADV 512

CK_TILE_DEVICE bool IsDebugThreadBlock(const int x = 0, const int y = 0, const int z = 0)
{
    return blockIdx.x == x && blockIdx.y == y && blockIdx.z == z;
}

// Returns count of warps which don't contain any idle thread.
template <int32_t NumWarps, int32_t M, int32_t N>
CK_TILE_HOST_DEVICE static constexpr auto GetMaxNumWarpsForTile()
{
    static_assert((NumWarps > 0) && ((NumWarps & (NumWarps - 1)) == 0)); // NumWarps should be power of 2
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

// =====================================================================================================================
// Definitions and helper structures
//

/// TODO: combine it with decode trait.
template <int32_t kSizeD_,
          int32_t kSizeDV_,
          int32_t kBlockM_,
          int32_t kBlockN0_,
          int32_t kBlockN1_,
          int32_t kNumWarps_,
          bool    kEnableXQA_,
          bool    kKVLoadOnce_>
struct FlashMlaPrefillKernelTrait
{
    static constexpr int32_t kSizeD                     = kSizeD_;    // hidden dimension size of query and key
    static constexpr int32_t kSizeDV                    = kSizeDV_;   // hidden dimension size of value
    static constexpr int32_t kSizeNope                  = 512;  //tmp force 512
    static constexpr int32_t kSizeRope                  = kSizeD - kSizeNope;
    static constexpr int32_t kNumWarps                  = kNumWarps_;
    static constexpr int32_t kPageBlockSize             = 16;
    static constexpr int32_t kNumThreads                = kNumWarps * ck_tile::get_warp_size();
    static constexpr int32_t kWaveOccupancy             = 1;
    static constexpr int32_t kNumWarpsSoftmax           = 4;
    static constexpr int32_t kNumThreadsSoftmax         = kNumWarpsSoftmax * ck_tile::get_warp_size();
    static constexpr int32_t kNumWarpsCombine           = 4;
    static constexpr int32_t kNumThreadsCombine         = kNumWarpsCombine * ck_tile::get_warp_size();
    static constexpr int32_t kBlockM                    = kBlockM_;
    static constexpr int32_t kBlockN0                   = kBlockN0_;
    static constexpr int32_t kBlockK0                   = kKVLoadOnce_ ? kSizeD : 32;
    static constexpr int32_t kBlockN1                   = kBlockN1_;
    static constexpr int32_t kBlockK1                   = ck_tile::min(16, kBlockN0);
    static constexpr int32_t kFixedOverheadNumBlocks    = 5;
    static constexpr int32_t kMaxBatchSize              = 4096;
    static constexpr int32_t kCuReuse                   = 2;
    static constexpr int32_t kMaxSplits                 = 128;
    static constexpr int32_t kKNumRepeat                = kSizeNope / kMaxSplits;
    static constexpr bool    kPadHeadDimQ               = false;
    static constexpr bool    kPadHeadDimV               = false;
    static constexpr bool    kPadSeqLenQ                = true;
    static constexpr bool    kPadSeqLenK                = true;
    static constexpr bool    kEnableXQA                 = kEnableXQA_;
    static constexpr bool    kKVLoadOnce                = kKVLoadOnce_;

    static constexpr int32_t kNumPrefetchK  = kKVLoadOnce_ ? 2 : 1;
    static constexpr int32_t kNumPrefetchV  = 1;
    static constexpr int32_t kNumPrefetchKV = ck_tile::max(kNumPrefetchK, kNumPrefetchV);

    using QKWarpTile = std::conditional_t<kKVLoadOnce, ck_tile::sequence<16, 16, 32>,
                                                       ck_tile::sequence<16, 16, 16>>;
    using KVWarpTile = ck_tile::sequence<16, 16, 16>;

    static_assert(kSizeD % 64 == 0);
    static_assert(kSizeDV % 64 == 0);
    static_assert(kSizeD >= kSizeDV);
};

template<typename Traits_, typename scalar_t, typename acc_t>
struct FlashMlaPrefillPolicy
{
public:
    using Traits = Traits_;
    using InOutType = scalar_t;
    using AccType   = acc_t;

    CK_TILE_HOST_DEVICE static constexpr int32_t GetAlignmentQ()
    {
        constexpr int32_t kBlockSize = Traits::kNumThreads;
        constexpr int32_t kMPerBlock = Traits::kBlockM;
        constexpr int32_t kKPerBlock = Traits::kBlockK0;

        constexpr int32_t MaxVectorSize = 16 / sizeof(scalar_t);

        // this should align with MakeQDramTileDistribution()
        constexpr int32_t ElemPerThread = (kMPerBlock * kKPerBlock) / kBlockSize;
        static_assert(0 < ElemPerThread);
        return ck_tile::min(ElemPerThread, MaxVectorSize);
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetAlignmentK()
    {
        constexpr int32_t kBlockSize = Traits::kNumThreads;
        constexpr int32_t kNPerBlock = Traits::kBlockN0;
        constexpr int32_t kKPerBlock = Traits::kBlockK0;

        constexpr int32_t MaxVectorSize = 16 / sizeof(scalar_t);
        constexpr int32_t ElemPerThread = (kNPerBlock * kKPerBlock) / kBlockSize;

        return ck_tile::min(MaxVectorSize, ElemPerThread);
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetAlignmentV()
    {
        // Assuming Value is row-major just like Key.
        constexpr int32_t kBlockSize   = Traits::kNumThreads;
        constexpr int32_t kNPerBlock   = Traits::kBlockN1;
        constexpr int32_t kKPerBlock   = Traits::kBlockK1;
        constexpr int32_t total_pixels = kNPerBlock * kKPerBlock / kBlockSize;
        constexpr int32_t kMaxVecLoad =
            ck_tile::min(total_pixels, static_cast<int32_t>(16 / sizeof(scalar_t)));
        constexpr int32_t kMinVecLoad = 4 / sizeof(scalar_t);

        constexpr int32_t kVecLoad =
            ((total_pixels / kMaxVecLoad) >= kMinVecLoad)
                ? kMaxVecLoad
                : (total_pixels / kMinVecLoad);

        return kVecLoad;
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetAlignmentOacc()
    {
        int32_t result = 1;

        if constexpr (Traits::kPadHeadDimV == false)
        {
            constexpr int32_t kBlockSize = Traits::kNumThreads;
            constexpr int32_t kMPerBlock = Traits::kBlockM;
            constexpr int32_t kNPerBlock = Traits::kBlockN1;

            constexpr int32_t M1 = kBlockSize / ck_tile::get_warp_size();
            constexpr int32_t M2 = ck_tile::min(kMPerBlock / M1, ck_tile::get_warp_size());
            constexpr int32_t N0 = ck_tile::get_warp_size() / M2;
            constexpr int32_t N1 = kNPerBlock / N0;

            // Each thread cannot handle more than 16 bytes
            result = ck_tile::min(N1, static_cast<int32_t>(16 / sizeof(scalar_t)));
        }

        return result;
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetAlignmentO()
    {
        int32_t result = 1;

        if constexpr (Traits::kPadHeadDimV == false)
        {
            constexpr int32_t kBlockSize = Traits::kNumThreads;
            constexpr int32_t kMPerBlock = Traits::kBlockM;
            constexpr int32_t kNPerBlock = Traits::kBlockN1;

            constexpr int32_t M1 = kBlockSize / ck_tile::get_warp_size();
            constexpr int32_t M2 = ck_tile::min(kMPerBlock / M1, ck_tile::get_warp_size());
            constexpr int32_t N0 = ck_tile::get_warp_size() / M2;
            constexpr int32_t N1 = kNPerBlock / N0;

            // Each thread cannot handle more than 16 bytes
            result = ck_tile::min(N1, static_cast<int32_t>(16 / sizeof(acc_t)));
        }

        return result;
    }

    CK_TILE_HOST_DEVICE static constexpr auto GetAlignmentLse()
    {
        return GetVectorSizeForTile<Traits::kNumWarps,
                                    Traits::kMaxSplits,
                                    Traits::kBlockM,
                                    acc_t>();
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeKLdsBlockDescriptor()
    {
        constexpr int32_t kNPerBlock = Traits::kBlockN0;
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

    CK_TILE_HOST_DEVICE static constexpr auto GetKNopeSingleRepeatSize()
    {
        return (Traits::kSizeRope * 2 + 8) * sizeof(scalar_t); // 2 = lane group 8 = padsize
    }

    template <bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto GetSingleKElementSpaceSize()
    {
        constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN0;
        constexpr ck_tile::index_t kKPerBlock = IsLoadOnceRope ? Traits::kSizeRope : Traits::kMaxSplits;
        constexpr ck_tile::index_t kRepeatK = IsLoadOnceRope ? 1 : Traits::kKNumRepeat;
        constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
        constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

        constexpr ck_tile::index_t kKPack  = 16 / sizeof(scalar_t);
        constexpr ck_tile::index_t KVector = 4  / sizeof(scalar_t);
        constexpr ck_tile::index_t kPad    = kKPack;

        static_assert(warpSize * KVector >= kKPerBlock &&
                      warpSize * KVector % kKPerBlock == 0);
        constexpr ck_tile::index_t LanesPerK  = kKPerBlock / KVector;
        constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK;
        constexpr ck_tile::index_t NumIssues  = kNPerBlock / (LaneGroups * NumWarps);

        return NumIssues * NumWarps * kRepeatK * (warpSize * KVector + kPad);
    }

    template <bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto GetSingleKSpaceSize()
    {
        return GetSingleKElementSpaceSize<IsLoadOnceRope>() * sizeof(scalar_t);
    }

    template <bool IsLoadOnceRope = false,
              ck_tile::index_t IBuf = 0>
    CK_TILE_HOST_DEVICE static constexpr auto
        MakeKLdsStoreBlockDescriptor(ck_tile::number<IBuf> = ck_tile::number<0>{})
    {
        // K is always k-major, we use async-copy to load into LDS
        constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN0;
        constexpr ck_tile::index_t kKPerBlock = IsLoadOnceRope ? Traits::kSizeRope : Traits::kMaxSplits;
        constexpr ck_tile::index_t kRepeatK = IsLoadOnceRope ? 1 : Traits::kKNumRepeat;
        constexpr ck_tile::index_t kBlockSize = Traits::kNumThreads;
        constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
        constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

        constexpr ck_tile::index_t kKPack  = 16 / sizeof(scalar_t);
        constexpr ck_tile::index_t KVector = 4  / sizeof(scalar_t);
        constexpr ck_tile::index_t kPad = 
            kKPack; // for async-copy, this pad is between warps. Optimize this for lds_read speed

        static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
        constexpr ck_tile::index_t LanesPerK =
            kKPerBlock / KVector; // 
        constexpr ck_tile::index_t LaneGroups =
            warpSize /
            LanesPerK; // how many groups (within a wave), they may load different N, but same K
        constexpr ck_tile::index_t NumIssues = kNPerBlock / (LaneGroups * NumWarps);
        static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));

        if constexpr(IsLoadOnceRope)
        {
            constexpr auto k_lds_block_desc_0 = make_naive_tensor_descriptor_with_offset(
                ck_tile::make_tuple(ck_tile::number<NumIssues>{},  // n0
                           ck_tile::number<LaneGroups>{}, // n1
                           ck_tile::number<NumWarps>{},   // n2
                           ck_tile::number<LanesPerK>{},  // k0
                           ck_tile::number<KVector>{}),   // k1
                ck_tile::make_tuple(ck_tile::number<NumWarps * (warpSize * KVector + kPad)>{},
                           ck_tile::number<kKPerBlock>{},
                           ck_tile::number<warpSize * KVector + kPad>{},
                           ck_tile::number<KVector>{},
                           ck_tile::number<1>{}),
                ck_tile::number<IBuf * GetSingleKElementSpaceSize<true>()>{},
                ck_tile::number<KVector>{},
                ck_tile::number<1>{});

            // TODO this layout is hard coded, and will be used in async copy buffer view load
            // in LDS the real layout is (bufs, N0, N2, N1*K0*K1)
            constexpr auto k_lds_block_desc_issues_warps_lanes = ck_tile::transform_tensor_descriptor(
                k_lds_block_desc_0,
                ck_tile::make_tuple(make_pass_through_transform(ck_tile::number<NumIssues>{}),
                           ck_tile::make_pass_through_transform(ck_tile::number<NumWarps>{}),
                           ck_tile::make_merge_transform(ck_tile::make_tuple(
                               ck_tile::number<LaneGroups>{},
                               ck_tile::number<LanesPerK>{}, 
                               ck_tile::number<KVector>{}))),
                ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<2>{}, ck_tile::sequence<1, 3, 4>{}),
                ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}, ck_tile::sequence<2>{}));

            return k_lds_block_desc_issues_warps_lanes;
        }
        else
        {
            constexpr auto k_lds_block_desc_0 = make_naive_tensor_descriptor_with_offset(
                ck_tile::make_tuple(ck_tile::number<NumIssues>{},  // n0
                           ck_tile::number<LaneGroups>{}, // n1
                           ck_tile::number<NumWarps>{},   // n2
                           ck_tile::number<kRepeatK>{},  // krepeatK
                           ck_tile::number<LanesPerK>{},  // k0
                           ck_tile::number<KVector>{}),   // k1
                ck_tile::make_tuple(ck_tile::number<NumWarps* kRepeatK * (warpSize * KVector + kPad)>{},
                           ck_tile::number<(warpSize * KVector + kPad) / LaneGroups>{},
                           ck_tile::number<(warpSize * KVector + kPad) * kRepeatK>{},
                           ck_tile::number<(warpSize * KVector + kPad) / LaneGroups>{},
                           ck_tile::number<KVector>{},
                           ck_tile::number<1>{}),
                ck_tile::number<IBuf * GetSingleKElementSpaceSize<false>()>{},
                ck_tile::number<KVector>{},
                ck_tile::number<1>{});

            // TODO this layout is hard coded, and will be used in async copy buffer view load
            // in LDS the real layout is (bufs, N0, N2, N1*K0*K1)
            constexpr auto k_lds_block_desc_issues_warps_lanes = ck_tile::transform_tensor_descriptor(
                k_lds_block_desc_0,
                ck_tile::make_tuple(make_pass_through_transform(ck_tile::number<NumIssues>{}),
                           ck_tile::make_pass_through_transform(ck_tile::number<NumWarps>{}),
                           ck_tile::make_merge_transform(ck_tile::make_tuple(
                               ck_tile::number<LaneGroups>{},
                               ck_tile::number<kRepeatK>{},
                               ck_tile::number<LanesPerK>{}, 
                               ck_tile::number<KVector>{}))),
                ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<2>{}, ck_tile::sequence<1, 3, 4, 5>{}),
                ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}, ck_tile::sequence<2>{}));

            return k_lds_block_desc_issues_warps_lanes;
        }
    }

    template <bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto MakeKLdsLoadBlockDescriptor()
    {
        // K is always k-major, we use async-copy to load into LDS
        constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN0;
        constexpr ck_tile::index_t kKPerBlock = IsLoadOnceRope ? Traits::kSizeRope : Traits::kMaxSplits;
        constexpr ck_tile::index_t kRepeatK = IsLoadOnceRope ? 1 : Traits::kKNumRepeat;
        constexpr ck_tile::index_t kBlockSize = Traits::kNumThreads;
        constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
        constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

        constexpr ck_tile::index_t kKPack  = 16 / sizeof(scalar_t);
        constexpr ck_tile::index_t KVector = 4 / sizeof(scalar_t);
        constexpr ck_tile::index_t kPad    = kKPack; // for async-copy, this pad is between warps

        static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
        constexpr ck_tile::index_t LanesPerK  = kKPerBlock / KVector; // within a wave
        constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK; // within a wave
        constexpr ck_tile::index_t NumIssues  = kNPerBlock / (LaneGroups * NumWarps);
        static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));
        // constexpr ck_tile::index_t SingleKSize = NumIssues * NumWarps * (warpSize * KVector + kPad);
        // constexpr ck_tile::index_t SingleVSize =
        // MakeVLdsBlockDescriptor<Problem>().get_element_space_size();
        constexpr ck_tile::index_t BufferSize =
            GetSingleKElementSpaceSize<IsLoadOnceRope>();

        if constexpr(IsLoadOnceRope)
        {
            constexpr auto k_lds_block_desc_0 =
                ck_tile::make_naive_tensor_descriptor(ck_tile::make_tuple(ck_tile::number<Traits::kNumPrefetchK>{},    // num_buffers
                                                        ck_tile::number<NumIssues>{},          // n0
                                                        ck_tile::number<NumWarps>{},           // n2
                                                        ck_tile::number<LaneGroups>{},         // n1
                                                        ck_tile::number<kKPerBlock / kKPack>{}, // k0
                                                        ck_tile::number<kKPack>{}),             // k1
                                             ck_tile::make_tuple(ck_tile::number<BufferSize>{},
                                                        ck_tile::number<NumWarps*(warpSize * KVector + kPad)>{},
                                                        ck_tile::number<(warpSize * KVector + kPad)>{},
                                                        ck_tile::number<kKPerBlock>{},
                                                        ck_tile::number<kKPack>{},
                                                        ck_tile::number<1>{}),
                                             ck_tile::number<kKPack>{},
                                             ck_tile::number<1>{});

            constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
                k_lds_block_desc_0,
                ck_tile::make_tuple(
                    ck_tile::make_merge_transform(ck_tile::make_tuple(ck_tile::number<Traits::kNumPrefetchK>{},
                                                    ck_tile::number<NumIssues>{},
                                                    ck_tile::number<LaneGroups>{},
                                                    ck_tile::number<NumWarps>{})),
                    ck_tile::make_merge_transform(ck_tile::make_tuple(
                                                  ck_tile::number<kKPerBlock / kKPack>{}, 
                                                  ck_tile::number<kKPack>{}))),
                ck_tile::make_tuple(ck_tile::sequence<0, 1, 3, 2>{}, ck_tile::sequence<4, 5>{}),
                ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
            return k_lds_block_desc;
        }
        else
        {
            constexpr auto k_lds_block_desc_0 =
                ck_tile::make_naive_tensor_descriptor(ck_tile::make_tuple(ck_tile::number<Traits::kNumPrefetchK>{},    // num_buffers
                                                        ck_tile::number<NumIssues>{},          // n0
                                                        ck_tile::number<NumWarps>{},           // n2
                                                        ck_tile::number<LaneGroups>{},         // n1
                                                        ck_tile::number<kRepeatK>{}, 
                                                        ck_tile::number<kKPerBlock / kKPack>{}, // k0
                                                        ck_tile::number<kKPack>{}),             // k1
                                                     ck_tile::make_tuple(ck_tile::number<BufferSize>{},
                                                        ck_tile::number<NumWarps*(warpSize * KVector + kPad) * kRepeatK>{},
                                                        ck_tile::number<(warpSize * KVector + kPad) * kRepeatK>{},
                                                        ck_tile::number<(warpSize * KVector + kPad) / LaneGroups>{},
                                                        // ck_tile::number<Traits::kSizeD>{}, 
                                                        ck_tile::number<(warpSize * KVector + kPad) / LaneGroups>{},
                                                        ck_tile::number<kKPack>{},
                                                        ck_tile::number<1>{}),
                                             ck_tile::number<kKPack>{},
                                             ck_tile::number<1>{});

            constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
                k_lds_block_desc_0,
                ck_tile::make_tuple(
                    ck_tile::make_merge_transform(ck_tile::make_tuple(ck_tile::number<Traits::kNumPrefetchK>{},
                                                    ck_tile::number<NumIssues>{},
                                                    ck_tile::number<LaneGroups>{},
                                                    ck_tile::number<NumWarps>{})),
                    ck_tile::make_merge_transform(ck_tile::make_tuple(
                                                  ck_tile::number<kRepeatK>{}, 
                                                  ck_tile::number<kKPerBlock / kKPack>{}, 
                                                  ck_tile::number<kKPack>{}))),
                ck_tile::make_tuple(ck_tile::sequence<0, 1, 3, 2>{}, ck_tile::sequence<4, 5, 6>{}),
                ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));
            return k_lds_block_desc;
        }
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
        constexpr int32_t BufferSize = Traits::kKVLoadOnce ? GetSmemSizeSingleV() : GetSmemSizeSingleKV();

        constexpr auto v_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<Traits::kNumPrefetchV>{},
                       ck_tile::number<kKPerBlock / kKPack>{},
                       ck_tile::number<kNPerBlock / NPerRow>{},
                       ck_tile::number<NPerRow>{},
                       ck_tile::number<kKPack>{}),
            ck_tile::make_tuple(ck_tile::number<BufferSize>{},
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
                    ck_tile::number<Traits::kNumPrefetchV>{}, ck_tile::number<kNPerBlock / NPerRow>{}, ck_tile::number<NPerRow>{})),
                ck_tile::make_merge_transform(ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<0, 2, 3>{}, ck_tile::sequence<1, 4>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return v_lds_block_desc;
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeVLdsStoreBlockDescriptor()
    {
        constexpr ck_tile::index_t kNPerBlock = 512;
        constexpr ck_tile::index_t kKPerBlock = 16;

        constexpr ck_tile::index_t kKPack  = 16 / sizeof(scalar_t);

        constexpr auto v_lds_block_desc_0 = make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kNPerBlock>{}, ck_tile::number<kKPack>{}),
            ck_tile::make_tuple(ck_tile::number<(kNPerBlock + 1) * kKPack>{}, ck_tile::number<kKPack>{}, ck_tile::number<1>{}),
            ck_tile::number<8>{},
            ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = transform_tensor_descriptor(
            v_lds_block_desc_0,
            ck_tile::make_tuple(
                make_pass_through_transform(ck_tile::number<kNPerBlock>{}),
                make_merge_transform(ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc;
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeVLdsLoadBlockDescriptor()
    {
        constexpr ck_tile::index_t kNPerBlock = 512;
        constexpr ck_tile::index_t kKPerBlock = 16;
        constexpr ck_tile::index_t kBlockSize = Traits::kNumThreads;
        constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
        constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

        constexpr ck_tile::index_t kKPack  = 16 / sizeof(scalar_t);
        constexpr ck_tile::index_t KVector = 8 / sizeof(scalar_t); // 4
        constexpr ck_tile::index_t kPad    = kKPack; // for async-copy, this pad is between warps

        static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
        constexpr ck_tile::index_t LanesPerK  = kKPerBlock / KVector; // 16 / 4 = 4
        constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK; // 64 / 4 = 16
        constexpr ck_tile::index_t NumIssues  = kNPerBlock / (LaneGroups * NumWarps); // 1
        static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));

        constexpr auto v_lds_block_desc_0 =
            ck_tile::make_naive_tensor_descriptor(
                ck_tile::make_tuple(ck_tile::number<NumIssues>{},          // n0
                                    ck_tile::number<NumWarps>{},           // n2
                                    ck_tile::number<LaneGroups>{},         // n1
                                    ck_tile::number<kKPerBlock / kKPack>{}, // k0
                                    ck_tile::number<kKPack>{}),             // k1
                ck_tile::make_tuple(ck_tile::number<NumWarps*(warpSize * KVector + kPad)>{},
                                    ck_tile::number<(warpSize * KVector + kPad)>{},
                                    ck_tile::number<kKPerBlock>{},
                                    ck_tile::number<kKPack>{},
                                    ck_tile::number<1>{}),
                ck_tile::number<kKPack>{},
                ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
            v_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_merge_transform(
                    ck_tile::make_tuple(ck_tile::number<NumIssues>{},
                                        ck_tile::number<LaneGroups>{},
                                        ck_tile::number<NumWarps>{})),
                ck_tile::make_merge_transform(
                    ck_tile::make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, 
                                        ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<0, 2, 1>{}, ck_tile::sequence<3, 4>{}),
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

    CK_TILE_HOST_DEVICE static constexpr int32_t GetSmemSizeSingleV()
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

        return (kKPerBlock / kKPack) * (kNPerBlock / NPerRow) * (PixelsPerRow + kKPack) * sizeof(scalar_t);
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetSmemSizeK()
    {
        return Traits::kKVLoadOnce ?  
            (GetSingleKElementSpaceSize<true>() + GetSingleKElementSpaceSize<false>()) * sizeof(scalar_t) :
            Traits::kNumPrefetchKV * GetSmemSizeSingleKV();
    }

    CK_TILE_HOST_DEVICE static constexpr int32_t GetSmemSize()
    {
        return Traits::kKVLoadOnce ?  
            Traits::kNumPrefetchK * GetSmemSizeK() + Traits::kNumPrefetchV * GetSmemSizeSingleV() :
            Traits::kNumPrefetchKV * GetSmemSizeSingleKV();
    }

    template<bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto GetQKBlockGemm()
    {
        constexpr int32_t kWarpGemmM = Traits::QKWarpTile::at(ck_tile::number<0>{});
        static_assert((kWarpGemmM == 4) || (kWarpGemmM == 16) || (kWarpGemmM == 32));

        constexpr int32_t ColWarps = Traits::kBlockM / kWarpGemmM;
        constexpr int32_t RowWarps = Traits::kNumWarps / ColWarps;
        static_assert((Traits::kNumWarps >= ColWarps) && ((Traits::kNumWarps % ColWarps) == 0));

        constexpr int32_t BlockTileK = !Traits::kKVLoadOnce ? Traits::kBlockK0 :
                                       IsLoadOnceRope ? Traits::kSizeRope : Traits::kSizeNope;
        using BlockTile     = ck_tile::sequence<Traits::kBlockM, Traits::kBlockN0, BlockTileK>;
        using BlockWarps    = ck_tile::sequence<ColWarps, RowWarps, 1>;
        using TileGemmShape = ck_tile::TileGemmShape<BlockTile, BlockWarps, typename Traits::QKWarpTile>;

        using GemmProblem = ck_tile::BlockGemmProblem<scalar_t, scalar_t, acc_t, Traits::kNumThreads, TileGemmShape>;

        constexpr auto warp_gemm = []()
        {
            if constexpr (std::is_same_v<scalar_t, ck_tile::fp16_t> && std::is_same_v<acc_t, float>)
            {
                if constexpr(kWarpGemmM == 32)
                    return ck_tile::WarpGemmMfmaF16F16F32M32N32K16SwizzleBTransposedCDistribution{};
                else if constexpr(kWarpGemmM == 16 && Traits::kKVLoadOnce)
                    return ck_tile::WarpGemmMfmaF16F16F32M16N16K32TransposedCDistribution{};
                else if constexpr(kWarpGemmM == 16)
                    return ck_tile::WarpGemmMfmaF16F16F32M16N16K16TransposedCDistribution{};
                else // kWarpGemmM == 4
                    return ck_tile::WarpGemmMfmaF16F16F32M4N64K16{};
            }
            else if constexpr (std::is_same_v<scalar_t, ck_tile::bf16_t> && std::is_same_v<acc_t, float>)
            {
                if constexpr (kWarpGemmM == 32)
                    return ck_tile::WarpGemmMfmaBf16Bf16F32M32N32K16SwizzleBTransposedCDistribution{};
                else if constexpr(kWarpGemmM == 16 && Traits::kKVLoadOnce)
                    return ck_tile::WarpGemmMfmaBf16Bf16F32M16N16K32TransposedCDistribution{};
                else if constexpr (kWarpGemmM == 16)
                    return ck_tile::WarpGemmMfmaBf16Bf16F32M16N16K16TransposedCDistribution{};
                else // kWarpGemmM == 4
                    return ck_tile::WarpGemmMfmaBf16Bf16F32M4N64K16{};
            }
        }();

        using BlockGemmPolicy =
            ck_tile::BlockGemmARegBSmemCRegV2CustomPolicy<scalar_t, scalar_t, acc_t, BlockWarps, decltype(warp_gemm)>;

        return ck_tile::BlockGemmARegBSmemCRegV2<GemmProblem, BlockGemmPolicy>{};
    }

    CK_TILE_HOST_DEVICE static constexpr auto GetKVBlockGemm()
    {
        constexpr int32_t kWarpGemmM = Traits::KVWarpTile::at(ck_tile::number<0>{});
        static_assert((kWarpGemmM == 4) || (kWarpGemmM == 16) || (kWarpGemmM == 32));

        constexpr int32_t ColWarps = Traits::kBlockM / kWarpGemmM;
        constexpr int32_t RowWarps = Traits::kNumWarps / ColWarps;
        static_assert((Traits::kNumWarps >= ColWarps) && ((Traits::kNumWarps % ColWarps) == 0));

        using BlockTile     = ck_tile::sequence<Traits::kBlockM, Traits::kBlockN1, Traits::kBlockK1>;
        using BlockWarps    = ck_tile::sequence<ColWarps, RowWarps, 1>;
        using TileGemmShape = ck_tile::TileGemmShape<BlockTile, BlockWarps, typename Traits::KVWarpTile>;

        using GemmProblem = ck_tile::BlockGemmProblem<scalar_t, scalar_t, acc_t, Traits::kNumThreads, TileGemmShape>;

        auto warp_gemm = []()
        {
            if constexpr(std::is_same_v<scalar_t, ck_tile::fp8_t> && std::is_same_v<acc_t, float>)
            {
                return ck_tile::WarpGemmMfmaFp8Fp8F32M32N32K16SwizzleBTransposedCDistribution<>{};
            }
            else
            {
                return ck_tile::WarpGemmMfmaDispatcher<
                    scalar_t, scalar_t, acc_t,
                    Traits::KVWarpTile::at(ck_tile::number<0>{}),
                    Traits::KVWarpTile::at(ck_tile::number<1>{}),
                    Traits::KVWarpTile::at(ck_tile::number<2>{}),
                    true>{};
            }
        }();

        using WarpGemm = ck_tile::remove_cvref_t<decltype(warp_gemm)>;

        using BlockGemmPolicy =
            BlockGemmARegBSmemCRegPolicy<scalar_t, scalar_t, acc_t, BlockWarps, WarpGemm>;

        return BlockGemmARegBSmemCReg<GemmProblem, BlockGemmPolicy>{};
    }

    template<bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto MakeQRegTileDistribution()
    {
        using BlockGemm = ck_tile::remove_cvref_t<decltype(GetQKBlockGemm<IsLoadOnceRope>())>;

        constexpr int32_t BlockTileK = !Traits::kKVLoadOnce ? Traits::kBlockK0 :
                                       IsLoadOnceRope ? Traits::kSizeRope : Traits::kSizeNope;
        return BlockGemm::template MakeABlockTileDistribution<
            Traits::kBlockM,
            BlockTileK>();
    }

    template<bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto MakeKDramTileDistribution()
    {
        if constexpr (!Traits::kKVLoadOnce)
        {
            constexpr int32_t kBlockSize = Traits::kNumThreads;
            constexpr int32_t kNPerBlock = Traits::kBlockN0;
            constexpr int32_t kKPerBlock = Traits::kBlockK0;

            constexpr int32_t MaxVectorSize = 16 / sizeof(scalar_t);
            constexpr int32_t ElemPerThread = (kNPerBlock * kKPerBlock) / kBlockSize;

            constexpr int32_t K1 = ck_tile::min(MaxVectorSize, ElemPerThread);
            constexpr int32_t K0 = kKPerBlock / K1;
            constexpr int32_t N2 = ck_tile::get_warp_size() / K0;
            constexpr int32_t N1 = kBlockSize / ck_tile::get_warp_size();
            constexpr int32_t N0 = kNPerBlock / (N2 * N1);

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
            // TODO: add distribution calculate
            // return ck_tile::make_static_tile_distribution(
            //     ck_tile::tile_distribution_encoding<
            //         ck_tile::sequence<>,
            //         ck_tile::tuple<ck_tile::sequence<1, 1, 8, 2>, ck_tile::sequence<9, 4, 8, 2>>,
            //         ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
            //         ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
            //         ck_tile::sequence<1, 1, 2, 2>,
            //         ck_tile::sequence<0, 3, 0, 3>>{});
            constexpr int32_t kBlockSize = Traits::kNumThreads;
            constexpr int32_t kNPerBlock = Traits::kBlockN0;
            constexpr ck_tile::index_t kKPerBlock = IsLoadOnceRope ? Traits::kSizeRope : Traits::kMaxSplits;
            constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
            constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

            constexpr ck_tile::index_t KVector = 4 / sizeof(scalar_t);

            static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
            constexpr ck_tile::index_t LanesPerK  = kKPerBlock / KVector; // within a wave
            constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK; // within a wave
            constexpr ck_tile::index_t NumIssues  = kNPerBlock / (LaneGroups * NumWarps);
            static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));

            constexpr ck_tile::index_t N0 = NumIssues;
            constexpr ck_tile::index_t N1 = LaneGroups;
            constexpr ck_tile::index_t N2 = NumWarps;
            constexpr ck_tile::index_t K0 = LanesPerK;
            constexpr ck_tile::index_t K1 = KVector;

            return ck_tile::make_static_tile_distribution(
                ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                           ck_tile::tuple<ck_tile::sequence<N0, N1, N2>, ck_tile::sequence<K0, K1>>,
                                           ck_tile::tuple<ck_tile::sequence<1>, ck_tile::sequence<1, 2>>,
                                           ck_tile::tuple<ck_tile::sequence<2>, ck_tile::sequence<1, 0>>,
                                           ck_tile::sequence<1, 2>,
                                           ck_tile::sequence<0, 1>>{});
        }
    }

    template<bool IsLoadOnceRope = false>
    CK_TILE_HOST_DEVICE static constexpr auto GetNumRepeatOfKDramTileDistribution()
    {
        using KDstrEncode = typename decltype(MakeKDramTileDistribution<IsLoadOnceRope>())::DstrEncode;
        return KDstrEncode::hs_lengthss_[ck_tile::number<0>{}][ck_tile::number<0>{}];
    }

    CK_TILE_HOST_DEVICE static constexpr auto GetVTileDistributionStride()
    {
        using VDstrEncode = typename decltype(MakeVTileDistribution())::DstrEncode;

        constexpr ck_tile::index_t VKVectors = VDstrEncode::hs_lengthss_[ck_tile::number<0>{}][ck_tile::number<3>{}];
        // constexpr ck_tile::index_t VNVectors = VDstrEncode::hs_lengthss_[ck_tile::number<1>{}][ck_tile::number<3>{}];
        constexpr ck_tile::index_t VKRepeats = VKVectors / 2;
        return VKRepeats;
    }


    CK_TILE_HOST_DEVICE static constexpr auto MakeVTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                    // ck_tile::sequence<1, 1, 8, 2>,
                    // ck_tile::sequence<8, 4, 8, 2>,
                ck_tile::tuple<ck_tile::sequence<1, 1, 4, 4>, ck_tile::sequence<1, 4, 16, 2>>,
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<0, 3, 0, 3>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeVTTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                ck_tile::tuple<
                    // ck_tile::sequence<8, 4, 8, 2>,
                    // ck_tile::sequence<1, 1, 8, 2>>,
                    ck_tile::sequence<1, 4, 16, 2>,
                    ck_tile::sequence<1, 1, 4, 4>>,
                ck_tile::tuple<ck_tile::sequence<2, 1>, ck_tile::sequence<2, 1>>,
                ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                // ck_tile::sequence<2, 2, 1, 1>,
                // ck_tile::sequence<0, 3, 0, 3>>{});
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<0, 3, 0, 3>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeVDramTileDistribution()
    {
        // Assuming layout of V is always row-major
        constexpr int32_t kBlockSize = Traits::kNumThreads;
        constexpr int32_t kNPerBlock = Traits::kBlockN1;
        constexpr int32_t kKPerBlock = Traits::kBlockK1;

        constexpr int32_t N1 = GetAlignmentV();
        constexpr int32_t N0 = kNPerBlock / N1; // P

        constexpr int32_t ElemPerThread = kNPerBlock * kKPerBlock / kBlockSize;
        static_assert(ElemPerThread % N1 == 0);
        constexpr int32_t K3     = ElemPerThread / N1;
        constexpr int32_t kKPack = 16 / sizeof(scalar_t);
        static_assert(kKPack % K3 == 0);
        constexpr int32_t K2 = kKPack / K3;

        if constexpr(ck_tile::get_warp_size() % (K2 * N0) == 0)
        {
            constexpr int32_t K1 = ck_tile::get_warp_size() / (K2 * N0);
            constexpr int32_t K0 = kBlockSize / ck_tile::get_warp_size();
            static_assert(kKPerBlock == K0 * K1 * K2 * K3);
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
            constexpr int32_t K1   = (K2 * N0) / ck_tile::get_warp_size();
            constexpr int32_t K2_m = K2 / K1;
            constexpr int32_t K0   = kBlockSize / ck_tile::get_warp_size() / K1;
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

    CK_TILE_HOST_DEVICE static constexpr auto GetNumRepeatOfVDramTileDistribution()
    {
        using VDstrEncode = typename decltype(MakeVDramTileDistribution())::DstrEncode;
        return VDstrEncode::hs_lengthss_[ck_tile::number<1>{}][ck_tile::number<3>{}];
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeShuffledVRegBlockDescriptor()
    {
        // Only called when V is row-major
        constexpr int32_t kBlockSize = Traits::kNumThreads;
        constexpr int32_t kNPerBlock = Traits::kBlockN1;
        constexpr int32_t kKPerBlock = Traits::kBlockK1;

        constexpr int32_t N1 = GetAlignmentV();
        constexpr int32_t N0 = kNPerBlock / N1;

        constexpr int32_t ElemPerThread = kNPerBlock * kKPerBlock / kBlockSize;
        static_assert(ElemPerThread % N1 == 0);
        constexpr int32_t K3     = ElemPerThread / N1;
        constexpr int32_t kKPack = 16 / sizeof(scalar_t);
        static_assert(kKPack % K3 == 0);
        constexpr int32_t K2 = kKPack / K3;

        if constexpr(ck_tile::get_warp_size() % (K2 * N0) == 0)
        {
            constexpr int32_t K1 = ck_tile::get_warp_size() / (K2 * N0);
            constexpr int32_t K0 = kBlockSize / ck_tile::get_warp_size();
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
            constexpr int32_t K1   = (K2 * N0) / ck_tile::get_warp_size();
            constexpr int32_t K2_m = K2 / K1;
            constexpr int32_t K0   = kBlockSize / ck_tile::get_warp_size() / K1;
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

#ifdef ZZDebug
    CK_TILE_DEVICE static auto MakeKRopeLdsDebugTileWindow(scalar_t* k_lds_ptr)
    {
        auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            k_lds_ptr, MakeKLdsLoadBlockDescriptor<true>());

        return ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<64>{}), 
            {0, 0},
                                // ck_tile::number<Traits::kSizeD>{}), {0, 0},
            MakeKDramTileDistribution<true>());
            // debug_k_dis);
    }
    CK_TILE_DEVICE static auto MakeKLdsDebugTileWindow(scalar_t* k_lds_ptr)
    {
        auto k_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            k_lds_ptr, MakeKLdsLoadBlockDescriptor<false>());

        auto debug_k_dis = ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                ck_tile::tuple<ck_tile::sequence<1, 2, 8, 1>, ck_tile::sequence<8, 1, 8, 8>>,
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<0, 3, 0, 3>>{});

        return ck_tile::make_tile_window(k_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{},
                                ck_tile::number<512>{}), 
            {0, 0},
                                // ck_tile::number<Traits::kSizeD>{}), {0, 0},
            // MakeKDramTileDistribution());
            debug_k_dis);
    }
    CK_TILE_DEVICE static auto MakeVLdsDebugTileWindow(scalar_t* k_lds_ptr)
    {
        auto v_lds = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
            k_lds_ptr, MakeVLdsLoadBlockDescriptor());

        return ck_tile::make_tile_window(v_lds,
            ck_tile::make_tuple(ck_tile::number<Traits::kSizeDV>{},
                                ck_tile::number<Traits::kBlockN0>{}), 
            {0, 0},
                                // ck_tile::number<Traits::kSizeD>{}), {0, 0},
            MakeVTTileDistribution());
            // debug_k_dis);
    }
#endif

#ifdef enable_inline
    CK_TILE_HOST_DEVICE static constexpr auto MakeKInlineLdsBlockDescriptor()
    {
        // K is always k-major, we use async-copy to load into LDS
        constexpr ck_tile::index_t kNPerBlock = Traits::kBlockN0;
        constexpr ck_tile::index_t kKPerBlock = 64;
        constexpr ck_tile::index_t kRepeatK = 9;
        constexpr ck_tile::index_t kBlockSize = Traits::kNumThreads;
        constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
        constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

        constexpr ck_tile::index_t KVector = 4  / sizeof(scalar_t);
        constexpr ck_tile::index_t kPad = kKPerBlock;

        static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
        constexpr ck_tile::index_t LanesPerK = kKPerBlock / KVector;   // 64 / 2 = 32
        constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK;  // 64 / 32 = 2
        constexpr ck_tile::index_t NumIssues = kNPerBlock / (LaneGroups * NumWarps);
        static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));

		constexpr auto k_lds_block_desc_0 = make_naive_tensor_descriptor(
			ck_tile::make_tuple(ck_tile::number<NumIssues>{},  // n0
					   ck_tile::number<NumWarps>{},   // n2
					   ck_tile::number<LaneGroups>{}, // n1
					   ck_tile::number<kRepeatK>{},  // krepeatK
					   ck_tile::number<LanesPerK>{},  // k0
					   ck_tile::number<KVector>{}),   // k1
			ck_tile::make_tuple(ck_tile::number<(2 * kKPerBlock) * kRepeatK * LaneGroups * NumWarps>{},
					   ck_tile::number<(2 * kKPerBlock) * kRepeatK * LaneGroups>{},
					   ck_tile::number<(2 * kKPerBlock) * kRepeatK>{},
					   ck_tile::number<2 * kKPerBlock>{},
					   ck_tile::number<KVector>{},
					   ck_tile::number<1>{}),
			ck_tile::number<KVector>{},
			ck_tile::number<1>{});

		// TODO this layout is hard coded, and will be used in async copy buffer view load
		// in LDS the real layout is (bufs, N0, N2, N1*K0*K1)
		constexpr auto k_lds_block_desc_issues_warps_lanes = ck_tile::transform_tensor_descriptor(
			k_lds_block_desc_0,
			ck_tile::make_tuple(make_pass_through_transform(ck_tile::number<NumIssues>{}),
					   ck_tile::make_pass_through_transform(ck_tile::number<NumWarps>{}),
					   ck_tile::make_merge_transform(ck_tile::make_tuple(
						   ck_tile::number<LaneGroups>{},
						   ck_tile::number<kRepeatK>{},
						   ck_tile::number<LanesPerK>{}, 
						   ck_tile::number<KVector>{}))),
			ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}, ck_tile::sequence<2, 3, 4, 5>{}),
			ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}, ck_tile::sequence<2>{}));

		return k_lds_block_desc_issues_warps_lanes;
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeKInlineLoadLdsBlockDescriptor()
    {
        constexpr int32_t kNPerBlock = Traits::kBlockN0;
        constexpr int32_t kKPerBlock = Traits::kSizeD;
        constexpr int32_t kKPack     = 4 / sizeof(scalar_t);
        constexpr int32_t kKPackPerRepeat = 32;
        constexpr int32_t kKPacks = kKPerBlock / (kKPack * kKPackPerRepeat);

        constexpr auto k_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<kNPerBlock>{},
                                ck_tile::number<kKPacks>{},
                                ck_tile::number<kKPackPerRepeat>{},
                                ck_tile::number<kKPack>{}),
            // ck_tile::make_tuple(ck_tile::number<kKPerBlock * 2>{},
            //                     ck_tile::number<kKPackPerRepeat * kKPack * 2>{},
            //                     ck_tile::number<kKPack>{},
            //                     ck_tile::number<1>{}),
            ck_tile::make_tuple(ck_tile::number<kKPerBlock * 1>{},
                                ck_tile::number<kKPackPerRepeat * kKPack * 1>{},
                                ck_tile::number<kKPack>{},
                                ck_tile::number<1>{}),
            ck_tile::number<kKPack>{},
            ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
            k_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_pass_through_transform(ck_tile::number<kNPerBlock>{}),
                ck_tile::make_merge_transform(make_tuple(ck_tile::number<kKPacks>{}, 
                                                         ck_tile::number<kKPackPerRepeat>{},
                                                         ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2, 3>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc;
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeKAllInlineDramTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                ck_tile::tuple<ck_tile::sequence<2, 1, 8, 1>,
                               ck_tile::sequence<9, 4, 8, 2>>,
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<0, 3, 0, 3>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeKInlineDramTileDistribution()
    {
        // return ck_tile::make_static_tile_distribution(
        //     ck_tile::tile_distribution_encoding<
        //         ck_tile::sequence<>,
        //         ck_tile::tuple<ck_tile::sequence<2, 1, 8, 1>,
        //                        ck_tile::sequence<9, 4, 8, 2>>,
        //         ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
        //         ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
        //         ck_tile::sequence<1, 1, 2, 2>,
        //         ck_tile::sequence<0, 3, 0, 3>>{});
        constexpr int32_t kBlockSize = Traits::kNumThreads;
        constexpr int32_t kNPerBlock = Traits::kBlockN0;
        constexpr ck_tile::index_t kKPerBlock = 64;
        constexpr ck_tile::index_t NumWarps   = Traits::kNumWarps;
        constexpr ck_tile::index_t warpSize   = ck_tile::get_warp_size();

        constexpr ck_tile::index_t KVector = 4 / sizeof(scalar_t);

        static_assert(warpSize * KVector >= kKPerBlock && warpSize * KVector % kKPerBlock == 0);
        constexpr ck_tile::index_t LanesPerK  = kKPerBlock / KVector; // within a wave
        constexpr ck_tile::index_t LaneGroups = warpSize / LanesPerK; // within a wave
        constexpr ck_tile::index_t NumIssues  = kNPerBlock / (LaneGroups * NumWarps);
        static_assert(NumIssues == kNPerBlock * kKPerBlock / (kBlockSize * KVector));

        constexpr ck_tile::index_t N0 = NumIssues;
        constexpr ck_tile::index_t N1 = LaneGroups;
        constexpr ck_tile::index_t N2 = NumWarps;
        constexpr ck_tile::index_t K0 = LanesPerK;
        constexpr ck_tile::index_t K1 = KVector;

        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<ck_tile::sequence<1>,
                                       ck_tile::tuple<ck_tile::sequence<N0, N1, N2>, ck_tile::sequence<K0, K1>>,
                                       ck_tile::tuple<ck_tile::sequence<1>, ck_tile::sequence<1, 2>>,
                                       ck_tile::tuple<ck_tile::sequence<2>, ck_tile::sequence<1, 0>>,
                                       ck_tile::sequence<1, 2>,
                                       ck_tile::sequence<0, 1>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeOInlineCTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                    // ck_tile::sequence<1, 1, 8, 2>,
                    // ck_tile::sequence<8, 4, 8, 2>,
                ck_tile::tuple<ck_tile::sequence<1, 4, 1,  4>,
                               ck_tile::sequence<1, 1, 64, 4>>, // 4 * 16 * 2
                ck_tile::tuple<ck_tile::sequence<2, 1>, ck_tile::sequence<2, 1>>,
                ck_tile::tuple<ck_tile::sequence<1, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<1, 3, 0, 3>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeOInlineCShuffleTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                ck_tile::tuple<ck_tile::sequence<1, 4, 1, 4>,
                               ck_tile::sequence<1, 1, 64, 4>>, // 4 * 16 * 2
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<1, 3, 0, 3>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeOLdsStoreBlockDescriptor()
    {
        constexpr int32_t kNPerBlock = 32;
        constexpr int32_t kKPerBlock = 256;
        constexpr int32_t kKPack     = 32 / sizeof(acc_t);

        constexpr auto k_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<kNPerBlock>{},
                                ck_tile::number<kKPerBlock / kKPack>{},
                                ck_tile::number<kKPack>{}),
            ck_tile::make_tuple(ck_tile::number<kKPerBlock + kKPack>{},
                                ck_tile::number<kKPack>{},
                                ck_tile::number<1>{}),
            ck_tile::number<8>{},
            ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
            k_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_pass_through_transform(ck_tile::number<kNPerBlock>{}),
                ck_tile::make_merge_transform(make_tuple(ck_tile::number<kKPerBlock / kKPack>{}, ck_tile::number<kKPack>{}))),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1, 2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc;
    }


    CK_TILE_HOST_DEVICE static constexpr auto MakeOLdsLoadBlockDescriptor()
    {
        constexpr int32_t kNPerBlock = 32;
        constexpr int32_t kKPerBlock = 64;
        constexpr int32_t kNRpeat = 4;
        constexpr int32_t kKPack     = 32 / sizeof(scalar_t);

        constexpr auto k_lds_block_desc_0 = ck_tile::make_naive_tensor_descriptor(
            ck_tile::make_tuple(ck_tile::number<kNPerBlock>{},
                                ck_tile::number<kNRpeat>{},
                                ck_tile::number<kKPerBlock>{}),
            ck_tile::make_tuple(ck_tile::number<(kNRpeat * kNPerBlock) + kKPack>{},
                                ck_tile::number<kNPerBlock>{},
                                ck_tile::number<1>{}),
            ck_tile::number<8>{},
            ck_tile::number<1>{});

        constexpr auto k_lds_block_desc = ck_tile::transform_tensor_descriptor(
            k_lds_block_desc_0,
            ck_tile::make_tuple(
                ck_tile::make_merge_transform(make_tuple(ck_tile::number<kNPerBlock>{},
                                                         ck_tile::number<kNRpeat>{})),
                ck_tile::make_pass_through_transform(ck_tile::number<kKPerBlock>{})),
            ck_tile::make_tuple(ck_tile::sequence<0, 1>{}, ck_tile::sequence<2>{}),
            ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

        return k_lds_block_desc;
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeOInlineCopyOutSplitDramTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                    // ck_tile::sequence<1, 1, 8, 2>,
                    // ck_tile::sequence<8, 4, 8, 2>,
                ck_tile::tuple<ck_tile::sequence<4, 4, 4, 1>,
                               ck_tile::sequence<1, 1, 16, 2>>, // 4 * 16 * 2
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<1, 3, 0, 3>>{});
    }

    CK_TILE_HOST_DEVICE static constexpr auto MakeOInlineCopyOutDramTileDistribution()
    {
        return ck_tile::make_static_tile_distribution(
            ck_tile::tile_distribution_encoding<
                ck_tile::sequence<>,
                    // ck_tile::sequence<1, 1, 8, 2>,
                    // ck_tile::sequence<8, 4, 8, 2>,
                ck_tile::tuple<ck_tile::sequence<4, 4, 4, 1>,
                               ck_tile::sequence<1, 1, 16, 4>>, // 4 * 16 * 2
                ck_tile::tuple<ck_tile::sequence<1, 2>, ck_tile::sequence<1, 2>>,
                ck_tile::tuple<ck_tile::sequence<0, 1>, ck_tile::sequence<2, 2>>,
                ck_tile::sequence<1, 1, 2, 2>,
                ck_tile::sequence<1, 3, 0, 3>>{});
    }

#endif
};

template <typename Traits, typename scalar_t, typename acc_t>
struct FlashMlaCombineKernelPolicy
{
private:
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
        scalar_t* p_output)
    {
        const auto naive_view =
            ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
                p_output,
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
};
constexpr size_t TileSchedulerMetaDataSizeInDw = sizeof(TileSchedulerMetaData) / sizeof(int32_t);

// =====================================================================================================================
// Kernel Functions
//

template <typename Traits>
CK_TILE_DEVICE static auto GetTileIndex(const int32_t num_splits)
{
    const auto f = [](int32_t dividend, int32_t divisor) {
        int32_t quotient = dividend / divisor;
        int32_t modulus  = dividend - quotient * divisor;
        return ck_tile::make_tuple(quotient, modulus);
    };

    const auto [mid, split_id] = f(blockIdx.x, num_splits);
    const int32_t hid          = blockIdx.y;
    const int32_t bid          = blockIdx.z;

    return ck_tile::make_tuple(mid, split_id, hid, bid);
}

// This function get the range of seqlen for the specified `split_idx`. `granularity` is the granularity of group of
// workload which cannot be further subdivded.
// The workload is divided as evenly as possible. When the workload cannot be evenly divided by num_splits, the
// high-ranking splits will get 1 additional `granularity` of tasks.
// E.g. when `num_seqlen` is `28`, `granularity` is `2` and `num_splits` is `3`, the 3 splits will be assigned the
// following tasks:
// split.0: [0, 10  // 10 workloads
// split.1: [10, 20) // 10 workloads
// split.2: [20, 28) //  8 workloads
// split.3: [28, 36) // Note that this may not be what you're expecting. upper_bound may be helpful in this case.
CK_TILE_DEVICE static auto GetSeqlenRange(
    const int32_t num_seqlen,
    const int32_t granularity,
    const int32_t num_splits,
    const int32_t split_idx,
    const int32_t lower_bound,
    const int32_t upper_bound)
{
    const int32_t num_workload = ck_tile::integer_divide_ceil(num_seqlen, granularity);
    const int32_t base_workload = ck_tile::integer_divide_floor(num_workload, num_splits);
    const int32_t addition_threshold = num_workload % num_splits;
    const int32_t start = base_workload * split_idx + ck_tile::min(addition_threshold, split_idx);
    const int32_t count = base_workload + ((split_idx < addition_threshold) ? 1 : 0);
    const int32_t end = start + count;

    return ck_tile::make_tuple(ck_tile::max(lower_bound, start * granularity),
                               ck_tile::min(upper_bound, end * granularity));
}

template <typename Policy, typename scalar_t = typename Policy::InOutType>
CK_TILE_DEVICE static auto MakeQDram(
    const scalar_t* p_data,
    const int32_t   height,
    const int32_t   stride_s)
{
    using Traits = typename Policy::Traits;

    const auto q_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data,
        ck_tile::make_tuple(height, Traits::kSizeD),
        ck_tile::make_tuple(stride_s, 1),
        ck_tile::number<Policy::GetAlignmentQ()>{},
        ck_tile::number<1>{});

    return ck_tile::pad_tensor_view(
        q_dram_naive,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<Traits::kBlockK0>{}),
        ck_tile::sequence<false, Traits::kPadHeadDimQ>{});
}

template <typename Policy, typename scalar_t = typename Policy::InOutType>
CK_TILE_DEVICE static auto MakeKDram(
    const scalar_t* p_data,
    const int32_t   height,
    const int32_t   stride_s)
{
    using Traits = typename Policy::Traits;

    const auto k_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data, // will update this pointer if using paged-kvcache
        ck_tile::make_tuple(height, Traits::kSizeD),
        ck_tile::make_tuple(stride_s, 1),
        ck_tile::number<Policy::GetAlignmentK()>{},
        ck_tile::number<1>{});

    return ck_tile::pad_tensor_view(
        k_dram_naive,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockN0>{}, ck_tile::number<Traits::kBlockK0>{}),
        ck_tile::sequence<true, Traits::kPadHeadDimQ>{});
}

template <typename Policy, typename scalar_t = typename Policy::InOutType>
CK_TILE_DEVICE static auto MakeVDram(
    const scalar_t* p_data,
    const int32_t   length,
    const int32_t   stride_s)
{
    using Traits = typename Policy::Traits;

    // Assuming Value is row-major just like Key.
    const auto v_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data, // will update this pointer if using paged-kvcache
        ck_tile::make_tuple(length, Traits::kSizeDV),
        ck_tile::make_tuple(stride_s, 1),
        ck_tile::number<Policy::GetAlignmentV()>{},
        ck_tile::number<1>{});

    const auto v_dram_transposed = ck_tile::transform_tensor_view(
        v_dram_naive,
        ck_tile::make_tuple(ck_tile::make_pass_through_transform(Traits::kSizeDV),
                            ck_tile::make_pass_through_transform(length)),
        ck_tile::make_tuple(ck_tile::sequence<1>{}, ck_tile::sequence<0>{}),
        ck_tile::make_tuple(ck_tile::sequence<0>{}, ck_tile::sequence<1>{}));

    return ck_tile::pad_tensor_view(
        v_dram_transposed,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockN1>{},
                            ck_tile::number<Traits::kBlockK1>{}),
        ck_tile::sequence<Traits::kPadHeadDimV, Traits::kPadSeqLenK>{});
}

template <typename Policy, typename Lengths, typename scalar_t>
CK_TILE_DEVICE static auto MakeLseAccDram(
    scalar_t* p_data,
    const Lengths&  window_lengths,
    const int32_t   size_s)
{
    using Traits = typename Policy::Traits;

    const auto lse_acc_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data,
        ck_tile::make_tuple(size_s),
        ck_tile::make_tuple(1),
        ck_tile::number<1>{},
        ck_tile::number<1>{});

    return ck_tile::pad_tensor_view(
        lse_acc_dram_naive,
        window_lengths,
        ck_tile::sequence<Traits::kPadSeqLenQ>{});
}

template <typename Policy, typename scalar_t>
CK_TILE_DEVICE static auto MakeOutAccDram(
    scalar_t* p_data,
    const int32_t   size_s,
    const int32_t   stride_s)
{
    using Traits = typename Policy::Traits;

    const auto o_acc_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data,
        ck_tile::make_tuple(size_s, Traits::kSizeDV),
        ck_tile::make_tuple(stride_s, 1),
        ck_tile::number<Policy::GetAlignmentOacc()>{},
        ck_tile::number<1>{});

    return ck_tile::pad_tensor_view(
        o_acc_dram_naive,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<Traits::kBlockN1>{}),
        ck_tile::sequence<Traits::kPadSeqLenQ, Traits::kPadHeadDimV>{});
}

template <typename Policy, typename Lengths, typename scalar_t>
CK_TILE_DEVICE static auto MakeLseDram(
    scalar_t* p_data,
    const Lengths&  window_lenghts,
    const int32_t   size_s)
{
    using Traits = typename Policy::Traits;

    const auto lse_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data,
        ck_tile::make_tuple(size_s),
        ck_tile::make_tuple(1),
        ck_tile::number<Policy::GetAlignmentLse()>{},
        ck_tile::number<1>{});

    return ck_tile::pad_tensor_view(
        lse_dram_naive, window_lenghts, ck_tile::sequence<Traits::kPadSeqLenQ>{});
}

template <typename Policy, typename scalar_t>
CK_TILE_DEVICE static auto MakeOutDram(
    scalar_t* p_data,
    const int32_t   size_s,
    const int32_t   stride_s)
{
    using Traits = typename Policy::Traits;

    const auto o_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
        p_data,
        ck_tile::make_tuple(size_s, Traits::kSizeDV),
        ck_tile::make_tuple(stride_s, 1),
        ck_tile::number<Policy::GetAlignmentO()>{},
        ck_tile::number<1>{});

    return ck_tile::pad_tensor_view(
        o_dram_naive,
        ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<Traits::kBlockN1>{}),
        ck_tile::sequence<Traits::kPadSeqLenQ, Traits::kPadHeadDimV>{});
}

template <bool IsMasking, typename acc_t>
CK_TILE_DEVICE static auto GetValidatedMax(acc_t raw_m)
{
    if constexpr (IsMasking)
    {
        return (raw_m == -ck_tile::numeric<acc_t>::infinity()) ? ck_tile::type_convert<acc_t>(0.f) : raw_m;
    }
    else
    {
        return raw_m;
    }
}

struct __attribute__((packed)) ORegs
{
};


struct __attribute__((packed)) OShuffleRegs
{
};

// =====================================================================================================================
// Kernel Entry
//

//bool kIsCausal = True, bool kDoSplit
template <typename Traits, typename scalar_t, typename acc_t, typename out_t/* , bool kDoSplit */>
__launch_bounds__(Traits::kNumThreads, Traits::kWaveOccupancy)
__global__ void kn_fmla_fwd_splictkv_prefill_inline(
    const ck_tile::FlashMlaPrefillFwdParams params)
{
    using Policy = FlashMlaPrefillPolicy<Traits, scalar_t, acc_t>;
    // const auto q_dram = MakeQDram<Policy>(params.p_query, params.size_s,  params.stride_s_q);
    // constexpr auto q_nope_dram_window_lengths =
    //     ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<Traits::kSizeNope>{});
    // constexpr auto q_rope_dram_window_lengths =
    //     ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<Traits::kSizeRope>{});
    // const auto q_nope_dram_window = ck_tile::make_tile_window(
    //     q_dram,
    //     q_nope_dram_window_lengths,
    //     {mid, 0});
    // const auto q_rope_dram_window = ck_tile::make_tile_window(
    //     q_dram,
    //     q_rope_dram_window_lengths,
    //     {mid, Traits::kSizeNope});
    __shared__ uint8_t smem[65500];
    auto o_lds_ptr   = reinterpret_cast<acc_t*>(smem);

    const int32_t mid = __builtin_amdgcn_readfirstlane(blockIdx.x * Traits::kBlockM);

    // std::array<ck_tile::fp32x4_t, 1> o_copy_out_regs {
    //     __builtin_bit_cast(ck_tile::fp32x4_t, std::array<float, 4>{v0, v1, v2, v3})
    // };


    // ck_tile::fp32x4_t o_lds_st_regs = __builtin_bit_cast(ck_tile::fp32x4_t, o_shuffle_regs);

		//
		//
		//
  //   const auto o_acc_dram_naive = ck_tile::make_naive_tensor_view<ck_tile::address_space_enum::global>(
  //       params.p_output,
  //       ck_tile::make_tuple(params.size_s, Traits::kSizeDV),
  //       ck_tile::make_tuple(params.stride_s_o, 1),
  //       ck_tile::number<8>{},
  //       ck_tile::number<1>{});
		//
  //   const auto occ_dram = ck_tile::pad_tensor_view(
  //       o_acc_dram_naive,
  //       ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<Traits::kBlockN1>{}),
  //       ck_tile::sequence<Traits::kPadSeqLenQ, Traits::kPadHeadDimV>{});
		//
  //   constexpr auto out_dram_window_lengths =
  //       ck_tile::make_tuple(ck_tile::number<Traits::kBlockM>{}, ck_tile::number<128>{});
		//
  //   const auto out_dram_windows = ck_tile::generate_tuple(
		// [&](auto i_buf) {
  //           ck_tile::make_tile_window(occ_dram, out_dram_window_lengths, {mid, i_buf * 128});
  //       },
  //       ck_tile::number<4>{});
		//
  //   auto o_lds_ptr = reinterpret_cast<acc_t*>(smem);
  //   auto o_ld_lds_view = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
  //       o_lds_ptr, Policy::template MakeOLdsLoadBlockDescriptor());
  //   auto o_ld_lds_windows = ck_tile::generate_tuple(
		// [&](auto i_buf) {
  //           ck_tile::make_tile_window(
  //               o_ld_lds_view,
  //               ck_tile::make_tuple(ck_tile::number<64>{}, ck_tile::number<64>{}),
  //               {i_buf * 64, 0},
  //               Policy::MakeOInlineCopyOutDramTileDistribution());
  //       },
  //       ck_tile::number<2>{});
		//
  //   auto o_st_lds_view = ck_tile::make_tensor_view<ck_tile::address_space_enum::lds>(
  //       o_lds_ptr, Policy::template MakeOLdsStoreBlockDescriptor());
  //   auto o_st_lds_windows = ck_tile::generate_tuple(
		// [&](auto i_buf) {
  //           ck_tile::make_tile_window(
  //               o_st_lds_view,
  //               ck_tile::make_tuple(ck_tile::number<16>{}, ck_tile::number<256>{}),
  //               {i_buf * 16, 0});
  //       },
  //       ck_tile::number<2>{});
		//
  //   auto o_inner_tensor1 = ck_tile::make_static_distributed_tensor<acc_t>(
  //       Policy::MakeOInlineCTileDistribution());
  //   auto o_reg1 = o_inner_tensor1.get_thread_buffer().get();
  //   register int v400 asm("v40") = o_reg1[0];
  //   register int v410 asm("v41") = o_reg1[1];
  //   register int v420 asm("v42") = o_reg1[2];
  //   register int v430 asm("v43") = o_reg1[3];
  //   register int v440 asm("v44") = o_reg1[4];
  //   register int v450 asm("v45") = o_reg1[5];
  //   register int v460 asm("v46") = o_reg1[6];
  //   register int v470 asm("v47") = o_reg1[7];
  //   register int v480 asm("v48") = o_reg1[8];
  //   register int v490 asm("v49") = o_reg1[9];
  //   register int v500 asm("v50") = o_reg1[10];
  //   register int v510 asm("v51") = o_reg1[11];
  //   register int v520 asm("v52") = o_reg1[12];
  //   register int v530 asm("v53") = o_reg1[13];
  //   register int v540 asm("v54") = o_reg1[14];
  //   register int v550 asm("v55") = o_reg1[15];
		//
		//
  //   auto o_inner_tensor2 = ck_tile::make_static_distributed_tensor<acc_t>(
  //       Policy::MakeOInlineCTileDistribution());
  //   auto o_reg2 = o_inner_tensor2.get_thread_buffer().get();
  //   register int v560 asm("v56") = o_reg2[0];
  //   register int v570 asm("v57") = o_reg2[1];
  //   register int v580 asm("v58") = o_reg2[2];
  //   register int v590 asm("v59") = o_reg2[3];
  //   register int v600 asm("v60") = o_reg2[4];
  //   register int v610 asm("v61") = o_reg2[5];
  //   register int v620 asm("v62") = o_reg2[6];
  //   register int v630 asm("v63") = o_reg2[7];
  //   register int v640 asm("v64") = o_reg2[8];
  //   register int v650 asm("v65") = o_reg2[9];
  //   register int v660 asm("v66") = o_reg2[10];
  //   register int v670 asm("v67") = o_reg2[11];
  //   register int v680 asm("v68") = o_reg2[12];
  //   register int v690 asm("v69") = o_reg2[13];
  //   register int v700 asm("v70") = o_reg2[14];
  //   register int v710 asm("v71") = o_reg2[15];
		//
  //   auto o_copyout_tensor = ck_tile::make_static_distributed_tensor<acc_t>(
  //       Policy::MakeOInlineCopyOutDramTileDistribution());
  //   auto o_reg3 = o_copyout_tensor.get_thread_buffer().get();
		//
  //   auto o_split_tensor1 = ck_tile::make_static_distributed_tensor<acc_t>(
  //       Policy::MakeOInlineCopyOutSplitDramTileDistribution());
  //   auto o_reg10 = o_split_tensor1.get_thread_buffer().get();
  //   register int v40 asm("v40") = o_reg10[0];
  //   register int v41 asm("v41") = o_reg10[1];
  //   register int v42 asm("v42") = o_reg10[2];
  //   register int v43 asm("v43") = o_reg10[3];
  //   register int v44 asm("v44") = o_reg10[4];
  //   register int v45 asm("v45") = o_reg10[5];
  //   register int v46 asm("v46") = o_reg10[6];
  //   register int v47 asm("v47") = o_reg10[7];
  //   register int v48 asm("v48") = o_reg10[8];
  //   register int v49 asm("v49") = o_reg10[9];
  //   register int v50 asm("v50") = o_reg10[10];
  //   register int v51 asm("v51") = o_reg10[11];
  //   register int v52 asm("v52") = o_reg10[12];
  //   register int v53 asm("v53") = o_reg10[13];
  //   register int v54 asm("v54") = o_reg10[14];
  //   register int v55 asm("v55") = o_reg10[15];
		//
		//
  //   auto o_split_tensor2 = ck_tile::make_static_distributed_tensor<acc_t>(
  //       Policy::MakeOInlineCTileDistribution());
  //   auto o_reg20 = o_split_tensor2.get_thread_buffer().get();
  //   register int v56 asm("v56") = o_reg20[0];
  //   register int v57 asm("v57") = o_reg20[1];
  //   register int v58 asm("v58") = o_reg20[2];
  //   register int v59 asm("v59") = o_reg20[3];
  //   register int v60 asm("v60") = o_reg20[4];
  //   register int v61 asm("v61") = o_reg20[5];
  //   register int v62 asm("v62") = o_reg20[6];
  //   register int v63 asm("v63") = o_reg20[7];
  //   register int v64 asm("v64") = o_reg20[8];
  //   register int v65 asm("v65") = o_reg20[9];
  //   register int v66 asm("v66") = o_reg20[10];
  //   register int v67 asm("v67") = o_reg20[11];
  //   register int v68 asm("v68") = o_reg20[12];
  //   register int v69 asm("v69") = o_reg20[13];
  //   register int v70 asm("v70") = o_reg20[14];
  //   register int v71 asm("v71") = o_reg20[15];

    // allocate LDS
    // float scalar = params.scale_softmax;
    int size_h          = __builtin_amdgcn_readfirstlane(params.size_h);
    int num_splits      = __builtin_amdgcn_readfirstlane(params.num_splits);
    int stride_q_b      = __builtin_amdgcn_readfirstlane(params.stride_b_q);
    int page_block_size = __builtin_amdgcn_readfirstlane(params.page_block_size);


    ck_tile::Fmla_gfx9_a16w16_qh16_m16x4_n16x1_coex0_mask1_total fmla_inline{};

    fmla_inline(
        params,
        // q_ptr,
        // kv_ptr,
        // o_ptr,
        // lse_ptr,
        // kv_indices,
        // o_regs,
        params.p_seqlens_k,
        params.scale_softmax,
        __builtin_amdgcn_readfirstlane(16),
        __builtin_amdgcn_readfirstlane(1),
        __builtin_amdgcn_readfirstlane(55296),
        __builtin_amdgcn_readfirstlane(2 * 576),
        __builtin_amdgcn_readfirstlane(0),
        params.p_qo_indptr,
        smem);

    // printf("%f", o_regs[0]);

    // // o_shuffle_regs[0] = o_regs[0];
    // // o_shuffle_regs[1] = o_regs[4];
    // // o_shuffle_regs[2] = o_regs[8];
    // // o_shuffle_regs[0] = o_regs[12];
    // o_lds_ptr[0] = o_shuffle_regs[0];
    // o_lds_ptr[1] = o_shuffle_regs[1];
    //
    // auto p_output = reinterpret_cast<float*>(params.p_output);
    // o_regs[0] = o_lds_ptr[0];
    // o_regs[1] = o_lds_ptr[1];
    //
    // 
    // p_output[0] = o_regs[0];
    // p_output[1] = o_regs[1];




}

template <typename Traits, int32_t kMaxSplits, typename out_t, typename in_t>
__global__ void kn_fmla_fwd_splictkv_prefill_combine(
    const ck_tile::FlashMlaPrefillFwdParams params)
{
    using Policy  = FlashMlaCombineKernelPolicy<Traits, out_t, in_t>;
    using index_t = int64_t;

    __shared__ in_t lds_lse_scale[kMaxSplits];

    const int32_t bidx = blockIdx.z;

    const int32_t num_splits   = params.num_splits;
    const int32_t split_offset = bidx * params.num_splits;
    assert((num_splits > 1) && (num_splits <= kMaxSplits));

    const int32_t lane_id          = ck_tile::get_lane_id();
    const int32_t hidx             = blockIdx.y;
    const int32_t sidx             = blockIdx.x;
    const int32_t hsidx            = hidx * params.size_s + sidx;
    const int32_t shidx            = hidx + sidx * params.size_h;
    const int32_t size_hs          = params.size_h * params.size_s;
    const index_t offset_lse_accum = split_offset * size_hs + hsidx; // offset to split 0
    const index_t offset_lse       = bidx * size_hs + hsidx;

    if (ck_tile::get_warp_id() == 0)
    {
        const in_t* p_lse_accum = reinterpret_cast<in_t*>(params.p_softmax_lseaccum) + offset_lse_accum;
        in_t* p_lse             = reinterpret_cast<in_t*>(params.p_softmax_lse) + offset_lse;

        constexpr int32_t kNumLsePerThr = ck_tile::integer_divide_ceil(kMaxSplits, ck_tile::get_warp_size());
        in_t local_lse[kNumLsePerThr];

        // Load thread local LSE and get local max LSE
        in_t max_lse = -ck_tile::numeric<in_t>::infinity();
        #pragma unroll
        for (int32_t i = 0; i < kNumLsePerThr; ++i)
        {
            const int32_t split_idx = i * ck_tile::get_warp_size() + lane_id;
            const in_t lse =
                (split_idx < num_splits) ? p_lse_accum[split_idx * size_hs] : -ck_tile::numeric<in_t>::infinity();
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
        in_t sum_lse = 0.f;
        #pragma unroll
        for (int32_t i = 0; i < kNumLsePerThr; ++i)
        {
            static_assert(0, "have not figured out if need exp2 here");
            sum_lse += ck_tile::exp(local_lse[i] - max_lse);
        }
        #pragma unroll
        for (int32_t offset = ck_tile::get_warp_size() / 2; offset > 0; offset /= 2)
        {
            sum_lse += __shfl_xor(sum_lse, offset);
        }

        // Get global LSE
        const auto [global_lse, output_lse] = [&]() {
            if ((sum_lse == 0.f) || (sum_lse != sum_lse))
            {
                return ck_tile::make_tuple(ck_tile::numeric<in_t>::infinity(), -ck_tile::numeric<in_t>::infinity());
            }
            else
            {
                const in_t lse = ck_tile::log(sum_lse) + max_lse;
                return ck_tile::make_tuple(lse, lse);
            }
        } ();

        if (lane_id == 0)
        {
            *p_lse = output_lse;
        }

        // Write LSE to LDS
        #pragma unroll
        for (int32_t i = 0; i < kNumLsePerThr; ++i)
        {
            const int32_t split_idx = i * ck_tile::get_warp_size() + lane_id;
            if (split_idx < num_splits)
            {
                lds_lse_scale[split_idx] = ck_tile::exp(local_lse[i] - global_lse);
            }
        }
    }

    __builtin_amdgcn_sched_barrier(0);
    ck_tile::block_sync_lds();

    static_assert(Traits::kSizeDV % Traits::kNumThreadsCombine == 0);

    auto oaccu_window =
        Policy::MakeOaccuTileWindow(params.p_output_accum, shidx, size_hs, split_offset, num_splits);

    auto reg_out = ck_tile::make_static_distributed_tensor<in_t>(
        decltype(ck_tile::load_tile(oaccu_window))::get_tile_distribution());
    ck_tile::set_tile(reg_out, 0.f);

    for (int32_t split_idx = 0; split_idx < num_splits; ++split_idx)
    {
        const in_t lse_scale = lds_lse_scale[split_idx];
        auto oaccu = ck_tile::load_tile(oaccu_window);
        ck_tile::sweep_tile(oaccu, [&](auto idx) {
            reg_out(idx) += lse_scale * oaccu(idx);
        });
        ck_tile::move_tile_window(oaccu_window, {size_hs, 0});
    }

    auto dram_out = Policy::MakeOutputTileWindow(
        static_cast<out_t*>(params.p_output) +
        bidx * params.stride_b_o + hidx * params.stride_h_o + sidx * params.stride_s_o);
    ck_tile::store_tile(dram_out, ck_tile::cast_tile<out_t>(reg_out));
}

// =====================================================================================================================
// Dispatch
//

template <typename Traits, typename scalar_t, typename acc_t, typename out_t>
void dispatch_fmla_fwd_splictkv_prefill_inline(
    const ck_tile::FlashMlaPrefillFwdParams& params)
{
    int sub_Q = 64;
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
    const int32_t num_blk   = ck_tile::integer_divide_ceil(params.size_s, sub_Q);
    const dim3    grid_attn = dim3(num_blk, params.size_b, 1);
    const dim3    grid_comb = dim3(params.size_s, params.size_h, params.size_b);

    auto kn_attn = &kn_fmla_fwd_splictkv_prefill_inline<Traits, scalar_t, acc_t, out_t>;
    kn_attn<<<grid_attn, Traits::kNumThreads, 0, stream>>>(params);
}

// =====================================================================================================================
// Interfaces
//
int num_splits_heuristic(int batch_nhead_mblocks, int num_SMs, int num_n_blocks, int max_splits)
{
    int32_t result = 1;

    if (batch_nhead_mblocks < 0.8f * num_SMs)
    {
        max_splits = std::min(max_splits, std::min(num_SMs, num_n_blocks));
        float max_efficiency = 0.f;
        std::vector<float> efficiency;
        efficiency.reserve(max_splits);

        // Some splits are not eligible. For example, if we have 64 blocks and choose 11 splits,
        // we'll have 6 * 10 + 4 blocks. If we choose 12 splits, we'll have 6 * 11 + (-2) blocks
        // (i.e. it's 11 splits anyway).
        // So we check if the number of blocks per split is the same as the previous num_splits.
        auto is_split_eligible = [&num_n_blocks](int num_splits) {
            return (num_splits == 1) ||
                (ck_tile::integer_divide_ceil(num_n_blocks, num_splits) !=
                 ck_tile::integer_divide_ceil(num_n_blocks, num_splits - 1));
        };

        for(int num_splits = 1; num_splits <= max_splits; num_splits++)
        {
            if(!is_split_eligible(num_splits))
            {
                efficiency.push_back(0.f);
            }
            else
            {
                float n_waves = float(batch_nhead_mblocks * num_splits) / num_SMs;
                float eff     = n_waves / ceil(n_waves);
                if(eff > max_efficiency)
                {
                    max_efficiency = eff;
                }
                efficiency.push_back(eff);
            }
        }

        for(int num_splits = 1; num_splits <= max_splits; num_splits++)
        {
            if(!is_split_eligible(num_splits))
            {
                continue;
            }

            if(efficiency[num_splits - 1] >= 0.85 * max_efficiency)
            {
                result = num_splits;
                break;
            }
        }
    }

    return result;
}

template <typename Traits>
int32_t calculate_num_splits(
    const int32_t size_b,
    const int32_t size_h,
    const int32_t size_s)
{
    hipDevice_t dev;
    hipDeviceProp_t dev_prop;
    ck_tile::hip_check_error(hipGetDevice(&dev));
    ck_tile::hip_check_error(hipGetDeviceProperties(&dev_prop, dev));
    const int32_t cu_count = dev_prop.multiProcessorCount;

    const int32_t num_m_blocks = ck_tile::integer_divide_ceil(size_s, Traits::kBlockM);
    const int32_t num_n_blocks = ck_tile::integer_divide_ceil(Traits::kSizeDV, Traits::kBlockN1);

    return num_splits_heuristic(size_b * size_h * num_m_blocks, cu_count * Traits::kCuReuse, num_n_blocks, 128);
}

std::vector<torch::Tensor> flash_mla_fwd_prefill_with_kvcache_impl(
    torch::Tensor&       query,
    const torch::Tensor& key_cache,
    const torch::Tensor& value_cache,
    const int32_t        head_size_v,
    const torch::Tensor& qo_indptr,
    const torch::Tensor& cache_seqlens,
    const torch::Tensor& block_table,
    const float          softmax_scale,
    const bool           is_causal
    )
{
    constexpr bool kEnablePackQkRatio = true;
    constexpr bool kKVLoadOnce        = false;
    //                                        dqk  dv   m0  n0  n1  #warp
    // using Traits = std::conditional_t<kKVLoadOnce, FlashMlaPrefillKernelTrait<576, 512, 64, 16, 512, 4, kEnablePackQkRatio, true>,
    //                                                FlashMlaPrefillKernelTrait<576, 512, 64, 64, 256, 4, kEnablePackQkRatio, false>>;
    using Traits = FlashMlaPrefillKernelTrait<576, HEADV, 64, 16, HEADV, 4, kEnablePackQkRatio, true>;

    constexpr bool kForceOutAcc = false;
    using acc_t                 = float;

    torch::Tensor vcache = value_cache.data_ptr() ? value_cache : key_cache;

    auto opts = query.options();
    static_assert(std::is_same_v<acc_t, float>);
    auto opts_acc = opts.dtype(torch::kFloat32);

    const int32_t batch_size = query.size(0);
    const int32_t seqlen_q_ori = query.size(1);
    const int32_t num_heads_q_ori = query.size(2);
    int32_t seqlen_q = seqlen_q_ori;
    int32_t num_heads_q = num_heads_q_ori;

    const int32_t head_size = query.size(3);
    TORCH_CHECK((head_size == 576) && (head_size_v == HEADV), "Only support QK head dim 576 and V head dim HEADV!");

    const int32_t num_blocks = key_cache.size(0);
    const int32_t page_block_size = key_cache.size(1);
    const int32_t num_heads_k = key_cache.size(2);

    TORCH_CHECK(num_heads_q % num_heads_k == 0,
                "Number of heads in key/value must divide number of heads in query");

    const int32_t hq_hk_ratio = num_heads_q / num_heads_k;
    int32_t mask_y_ratio      = 1;

    if constexpr(Traits::kEnableXQA)
    {
        seqlen_q     = seqlen_q_ori * hq_hk_ratio;
        num_heads_q  = num_heads_k;
        mask_y_ratio = hq_hk_ratio;
        if(num_heads_k == 1)
        {
            query = query.reshape({batch_size, seqlen_q, num_heads_q, head_size});
        }
        else
        {
            query = query.view({batch_size, seqlen_q_ori, num_heads_q, hq_hk_ratio, head_size})
                        .transpose(2, 3)
                        .reshape({batch_size, seqlen_q, num_heads_q, head_size});
        }
    }

#ifndef enable_inline
    const int32_t num_splits = calculate_num_splits<Traits>(batch_size, num_heads_q, seqlen_q);
#else
    const int32_t num_splits = 1;
#endif
    const bool    do_splits = num_splits > 1;

    // Combine shader, which only exists when num_splits > 1, will conduct type convert by default and force.
    // Thus, kForceOutAcc doesn't work in this case.
#ifndef enable_inline
    auto output = torch::empty({batch_size, seqlen_q, num_heads_q, head_size_v},
                               (kForceOutAcc && !do_splits) ? opts_acc : opts);
    auto softmax_lse = torch::empty({batch_size, num_heads_q, seqlen_q}, opts_acc);
#else
    auto output = torch::empty({batch_size * seqlen_q, num_splits, num_heads_q, head_size_v}, num_splits == 1? opts : opts_acc);
    auto softmax_lse = torch::empty({batch_size * seqlen_q, num_splits, num_heads_q, 1}, opts_acc);
#endif

    ck_tile::FlashMlaPrefillFwdParams params = {};

    params.num_splits    = num_splits;
    params.p_qo_indptr   = qo_indptr.data_ptr<int32_t>();
    params.p_seqlens_k   = cache_seqlens.data_ptr<int32_t>();
    params.p_block_table = block_table.data_ptr<int32_t>();

    params.p_query            = query.data_ptr();
    params.p_key              = key_cache.data_ptr();
    params.p_value            = vcache.data_ptr();
    params.p_output           = output.data_ptr();
    params.p_softmax_lse      = softmax_lse.data_ptr();

#ifdef ZZDebug
    auto debug_m_inner = torch::zeros({2, Traits::kBlockM}, opts);
    auto debug_v_inner = torch::zeros({Traits::kBlockN0, Traits::kSizeD}, opts);
    // auto debug_v_inner = torch::zeros({Traits::kBlockN, head_size_v}, opts);
    auto debug_p_inner = torch::zeros({Traits::kBlockM, Traits::kBlockN0}, opts);
    auto debug_o_inner = torch::zeros({Traits::kBlockM, Traits::kSizeD}, opts);
    auto debug_q_inner = torch::zeros({Traits::kBlockM, Traits::kSizeD}, opts);

    params.p_debug_m          = debug_m_inner.data_ptr();
    params.p_debug_value      = debug_v_inner.data_ptr();
    params.p_debug_p          = debug_p_inner.data_ptr();
    params.p_debug_output     = debug_o_inner.data_ptr();
    params.p_debug_q          = debug_q_inner.data_ptr();
#endif

    params.size_b                   = batch_size;
    params.size_s                   = seqlen_q;
    params.size_h                   = num_heads_q;
    params.hq_hk_ratio              = num_heads_q / num_heads_k;
    params.block_table_batch_stride = block_table.stride(0);
    params.num_page_blocks          = num_blocks;
    params.page_block_size          = page_block_size;
    params.scale_softmax            = softmax_scale;

    params.mask_y_ratio = mask_y_ratio;

    params.stride_b_q = query.stride(0);
    params.stride_s_q = query.stride(1);
    params.stride_h_q = query.stride(2);
    params.stride_b_k = key_cache.stride(0);
    params.stride_s_k = key_cache.stride(1); // size_hk * size_d
    params.stride_h_k = key_cache.stride(2);
    params.stride_b_v = vcache.stride(0);
    params.stride_s_v = vcache.stride(1);    // size_hk * size_d
    params.stride_h_v = vcache.stride(2);
    params.stride_b_o = output.stride(0);
    params.stride_s_o = output.stride(1);
    params.stride_h_o = output.stride(2);


#ifndef enable_inline
    if(params.num_splits > 1)
    {
        auto output_accum =
            torch::empty({batch_size, params.num_splits, seqlen_q, num_heads_q, head_size_v}, opts_acc);
        auto softmax_lseaccum =
            torch::empty({batch_size, params.num_splits, num_heads_q, seqlen_q}, opts_acc);
        params.p_softmax_lseaccum = softmax_lseaccum.data_ptr();
        params.p_output_accum     = output_accum.data_ptr();
        params.stride_b_oacc      = output_accum.stride(0);
        params.stride_h_oacc      = output_accum.stride(3);
        params.stride_sp_oacc     = output_accum.stride(1);
        params.stride_s_oacc      = output_accum.stride(2);
        params.stride_b_lseacc    = softmax_lseaccum.stride(0);
        params.stride_h_lseacc    = softmax_lseaccum.stride(2);
        params.stride_sp_lseacc   = softmax_lseaccum.stride(1);
    }
    // dispatch_fmla_fwd_splictkv_prefill<Traits, ck_tile::bf16_t, float, ck_tile::bf16_t, true>(params);
#else
    dispatch_fmla_fwd_splictkv_prefill_inline<Traits, ck_tile::bf16_t, float, ck_tile::bf16_t>(params);
    return {output, softmax_lse};
#endif

    // DISPATCH_FMLA_TYPES(
    //     query.scalar_type(),
    //     is_causal,
    //     "fmla_fwd",
    //     [&](){
    //         dispatch_fmla_fwd_splictkv_prefill<Traits, scalar_t, acc_t, out_t, Is_causal>(params);
    //     }();
    // );
    // assert(is_causal == true);
    // assert(query.scalar_type() == at::ScalarType::BFloat16);
    // using scalar_t = ck_tile::bf16_t;
    // using out_t = std::conditional_t<kForceOutAcc, acc_t, scalar_t>;
    // dispatch_fmla_fwd_splictkv_prefill<Traits, scalar_t, acc_t, out_t, true>(params);

    if constexpr(Traits::kEnableXQA)
    {
        // post process for out and softmax_lse
        if(num_heads_k == 1)
        {
            output = output.reshape({batch_size, seqlen_q_ori, num_heads_q_ori, head_size_v});
        }
        else
        {
            output = output.view({batch_size, seqlen_q_ori, hq_hk_ratio, num_heads_q, head_size_v})
                         .transpose(2, 3)
                         .reshape({batch_size, seqlen_q_ori, num_heads_q_ori, head_size_v});
        }
        softmax_lse = softmax_lse.view({batch_size, num_heads_q, seqlen_q_ori, hq_hk_ratio})
                          .transpose(2, 3)
                          .reshape({batch_size, num_heads_q_ori, seqlen_q_ori});
    }

#ifdef ZZDebug
    return {output.to(opts), softmax_lse, debug_m_inner, debug_p_inner, debug_v_inner, debug_o_inner, debug_q_inner};
#else 
    return {output, softmax_lse};
#endif
}
