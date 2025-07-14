#include "mha_common.h"
#include "py_itfs_common.h"
#include <ATen/cuda/CUDAContext.h>
#include <torch/all.h>

#include "ck_tile/core.hpp"
#include "ck_tile/core/utility/functional.hpp"
#include "ck_tile/ops/common.hpp"
#include "ck_tile/ops/fmha/block/block_attention_bias_enum.hpp"
#include "ck_tile/ops/fmha/block/block_dropout.hpp"
#include "ck_tile/ops/fmha/block/variants.hpp"
#include "ck_tile/ops/fmha/pipeline/block_fmha_pipeline_qx_ks_vs_custom_policy.hpp"
#include "ck_tile/ops/reduce/block/block_reduce.hpp"

#include "block_gemm_areg_breg_creg_v2.hpp"
#include "block_gemm_areg_breg_creg_v2_custom_policy.hpp"
#include "block_gemm_areg_bsmem_creg_v2.hpp"
#include "block_gemm_areg_bsmem_creg_v2_custom_policy.hpp"

#include <string>
#include <type_traits>
#include <utility>
#include <variant>

#include "fmha_fwd.hpp"
#include "mask.hpp"

#define ASM_MARKER(marker)               \
    __builtin_amdgcn_sched_barrier(0);   \
    asm volatile("; [POYENC] " #marker); \
    __builtin_amdgcn_sched_barrier(0);

namespace aiter {

struct BlockFmhaPipelineQRKSVSDefaultPolicy
    : ck_tile::BlockFmhaPipelineQXKSVSCustomPolicy</* QLoadOnce = */ true,
                                                   /* AsyncCopy = */ false,
                                                   /* NumPrefetchK = */ 1,
                                                   /* NumPrefetchV = */ 1>
{
    using BasePolicy = ck_tile::BlockFmhaPipelineQXKSVSCustomPolicy</* QLoadOnce = */ true,
                                                                    /* AsyncCopy = */ false,
                                                                    /* NumPrefetchK = */ 1,
                                                                    /* NumPrefetchV = */ 1>;

    static constexpr ck_tile::index_t NumWarpPerGroup = 4;
    static constexpr ck_tile::index_t NumThreadPerWarpGroup =
        NumWarpPerGroup * ck_tile::get_warp_size();

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto MakeKDramTileDistribution()
    {
        using namespace ck_tile;

        constexpr index_t NumWarpGroups = Problem::kBlockSize / NumThreadPerWarpGroup;
        static_assert(NumWarpGroups == 2);

        using KDataType = remove_cvref_t<typename Problem::KDataType>;

        constexpr index_t kBlockSize = Problem::kBlockSize;
        constexpr index_t kNPerBlock = Problem::BlockFmhaShape::kN0;
        constexpr index_t kKPerBlock = Problem::BlockFmhaShape::kK0;

        constexpr index_t MaxVectorSize = 16 / sizeof(KDataType);
        constexpr index_t ElemPerThread = (kNPerBlock * kKPerBlock) / kBlockSize;

        constexpr index_t KPerThread     = ck_tile::min(MaxVectorSize, ElemPerThread);
        constexpr index_t KThreads       = kKPerBlock / KPerThread;
        constexpr index_t NThreadPerWarp = get_warp_size() / KThreads;
        constexpr index_t NumWarps       = kBlockSize / get_warp_size();

        constexpr index_t NPerThread = kNPerBlock / (NumWarps * NThreadPerWarp);

        return make_static_tile_distribution(
            tile_distribution_encoding<sequence<1>,
                                       tuple<sequence<NumWarps, NPerThread, NThreadPerWarp>,
                                             sequence<KThreads, KPerThread>>,
                                       tuple<sequence<1>, sequence<1, 2>>,
                                       tuple<sequence<0>, sequence<2, 0>>,
                                       sequence<1, 2>,
                                       sequence<1, 1>>{});
    }

    template <typename Problem>
    CK_TILE_DEVICE static constexpr auto MakeVDramTileDistribution()
    {
        using namespace ck_tile;

        constexpr index_t NumWarpGroups = Problem::kBlockSize / NumThreadPerWarpGroup;
        static_assert(NumWarpGroups == 2);

        using VLayout = remove_cvref_t<typename Problem::BlockFmhaShape::VLayout>;

        // make distribution for a single warp-group and duplicate content in all groups
        constexpr index_t kBlockSize = Problem::kBlockSize;
        constexpr index_t kNPerBlock = Problem::BlockFmhaShape::kN1;
        constexpr index_t kKPerBlock = Problem::BlockFmhaShape::kK1;

        static_assert(std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor>);

        constexpr index_t NPerThread = GetAlignmentV<Problem>();
        constexpr index_t NThreads   = kNPerBlock / NPerThread; // P

        constexpr index_t total_pixels = kNPerBlock * kKPerBlock / kBlockSize;
        static_assert(total_pixels % NPerThread == 0); // TODO: this is not always true?
        constexpr index_t KPerThread = total_pixels / NPerThread;
        constexpr index_t kKPack     = GetSmemKPackV<Problem>();
        static_assert(kKPack % KPerThread == 0);
        constexpr index_t K2 =
            kKPack / KPerThread; // TODO: this dimention could be outside single wave
        if constexpr(get_warp_size() % (K2 * NThreads) == 0)
        {
            constexpr index_t K1       = get_warp_size() / (K2 * NThreads);
            constexpr index_t NumWarps = kBlockSize / get_warp_size();
            static_assert(kKPerBlock == NumWarps * K1 * K2 * KPerThread);
            // 2 warp-groups share the same data
            return make_static_tile_distribution(
                tile_distribution_encoding<
                    sequence<1>,
                    tuple<sequence<NThreads, NPerThread>, sequence<NumWarps, K1, K2, KPerThread>>,
                    tuple<sequence<2>, sequence<2, 1, 2>>,
                    tuple<sequence<0>, sequence<1, 0, 2>>,
                    sequence<2, 1>,
                    sequence<3, 1>>{});
        }
        else
        {
            constexpr index_t K1   = (K2 * NThreads) / get_warp_size();
            constexpr index_t K2_m = K2 / K1;
            constexpr index_t K0   = kBlockSize / get_warp_size() / K1;
            static_assert(kKPerBlock == K0 * K1 * K2_m * KPerThread);
            // 2 warp-groups share the same data
            return make_static_tile_distribution(
                tile_distribution_encoding<
                    sequence<1>,
                    tuple<sequence<NThreads, NPerThread>, sequence<K0, K1, K2_m, KPerThread>>,
                    tuple<sequence<2, 2>, sequence<1, 2>>,
                    tuple<sequence<0, 1>, sequence<0, 2>>,
                    sequence<2, 1>,
                    sequence<3, 1>>{});
        }
    }

    // this function should match the MakeVDramTileDistribution()
    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto MakeShuffledVRegBlockDescriptor()
    {
        using namespace ck_tile;

        constexpr index_t NumWarpGroups = Problem::kBlockSize / NumThreadPerWarpGroup;
        static_assert(NumWarpGroups == 2);

        // This descriptor only used when V layout is seqlen * hdim
        using VLayout = remove_cvref_t<typename Problem::BlockFmhaShape::VLayout>;
        static_assert(std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor>);

        constexpr index_t kBlockSize = Problem::kBlockSize;
        constexpr index_t kNPerBlock = Problem::BlockFmhaShape::kN1;
        constexpr index_t kKPerBlock = Problem::BlockFmhaShape::kK1;

        constexpr index_t NPerThread = GetAlignmentV<Problem>();
        constexpr index_t NThreads   = kNPerBlock / NPerThread;

        constexpr index_t total_pixels = kNPerBlock * kKPerBlock / kBlockSize;
        static_assert(total_pixels % NPerThread == 0); // TODO: this is not always true?
        constexpr index_t KPerThread = total_pixels / NPerThread;
        constexpr index_t kKPack     = GetSmemKPackV<Problem>();
        static_assert(kKPack % KPerThread == 0);
        constexpr index_t K2 =
            kKPack / KPerThread; // TODO: this dimention could be outside single wave
        if constexpr(get_warp_size() % (K2 * NThreads) == 0)
        {
            constexpr index_t K1       = get_warp_size() / (K2 * NThreads);
            constexpr index_t NumWarps = kBlockSize / get_warp_size();
            // 2 warp-groups share the same data
            return make_static_tile_distribution(
                tile_distribution_encoding<
                    sequence<1>,
                    tuple<sequence<NThreads, NPerThread>, sequence<NumWarps, K1, K2, KPerThread>>,
                    tuple<sequence<2>, sequence<2, 1, 2>>,
                    tuple<sequence<0>, sequence<1, 0, 2>>,
                    sequence<1, 2>,
                    sequence<1, 3>>{});
        }
        else
        {
            constexpr index_t K1   = (K2 * NThreads) / get_warp_size();
            constexpr index_t K2_m = K2 / K1;
            constexpr index_t K0   = kBlockSize / get_warp_size() / K1;
            static_assert(kKPerBlock == K0 * K1 * K2_m * KPerThread);
            // 2 warp-groups share the same data
            return make_static_tile_distribution(
                tile_distribution_encoding<
                    sequence<1>,
                    tuple<sequence<NThreads, NPerThread>, sequence<K0, K1, K2_m, KPerThread>>,
                    tuple<sequence<2, 2>, sequence<1, 2>>,
                    tuple<sequence<0, 1>, sequence<0, 2>>,
                    sequence<1, 2>,
                    sequence<1, 3>>{});
        }
    }

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto MakeKRegTileDistribution()
    {
        using namespace ck_tile;

        using BlockGemm = remove_cvref_t<decltype(GetQKBlockGemm<Problem>())>;

        return BlockGemm::MakeBBlockTileDistribution();
    }

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto MakeVRegTileDistribution()
    {
        using namespace ck_tile;

        using BlockGemm = remove_cvref_t<decltype(GetKVBlockGemm<Problem>())>;

        return BlockGemm::MakeBBlockTileDistribution();
    }

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto GetQKBlockGemm()
    {
        using namespace ck_tile;

        using GemmProblem =
            BlockGemmProblem<typename Problem::QDataType,
                             typename Problem::KDataType,
                             typename Problem::SaccDataType,
                             Problem::kNumGemm0Warps * get_warp_size(),
                             TileGemmShape<sequence<Problem::BlockFmhaShape::kM0,
                                                    Problem::BlockFmhaShape::kN0,
                                                    Problem::BlockFmhaShape::kK0>,
                                           typename Problem::BlockFmhaShape::Gemm0BlockWarps,
                                           typename Problem::BlockFmhaShape::Gemm0WarpTile>>;

        constexpr auto warp_gemm = []() {
            constexpr index_t WarpGemmM = Problem::BlockFmhaShape::Gemm0WarpTile::at(number<0>{});
            static_assert(WarpGemmM == 4 || WarpGemmM == 16 || WarpGemmM == 32);

            if constexpr(std::is_same_v<typename Problem::QDataType, half_t> &&
                         std::is_same_v<typename Problem::KDataType, half_t> &&
                         std::is_same_v<typename Problem::SaccDataType, float>)
            {
                if constexpr(WarpGemmM == 32)
                    return WarpGemmMfmaF16F16F32M32N32K16SwizzleBTransposedCDistribution{};
                else if constexpr(WarpGemmM == 16)
                    return WarpGemmMfmaF16F16F32M16N16K16TransposedCDistribution{};
                else // WarpGemmM == 4
                    return WarpGemmMfmaF16F16F32M4N64K16{};
            }
            else if constexpr(std::is_same_v<typename Problem::QDataType, bf16_t> &&
                              std::is_same_v<typename Problem::KDataType, bf16_t> &&
                              std::is_same_v<typename Problem::SaccDataType, float>)
            {
                if constexpr(WarpGemmM == 32)
                    return WarpGemmMfmaBf16Bf16F32M32N32K16SwizzleBTransposedCDistribution{};
                else if constexpr(WarpGemmM == 16)
                    return WarpGemmMfmaBf16Bf16F32M16N16K16TransposedCDistribution{};
                else // WarpGemmM == 4
                    return WarpGemmMfmaBf16Bf16F32M4N64K16{};
            }
        }();

        using BlockGemmPolicy = aiter::BlockGemmARegBRegCRegV2CustomPolicy<
            typename Problem::QDataType,
            typename Problem::KDataType,
            typename Problem::SaccDataType,
            typename Problem::BlockFmhaShape::Gemm0BlockWarps,
            decltype(warp_gemm)>;

        return aiter::BlockGemmARegBRegCRegV2<GemmProblem, BlockGemmPolicy>{};
    }

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto GetKVBlockGemm()
    {
        using namespace ck_tile;

        using GemmProblem =
            BlockGemmProblem<typename Problem::PDataType,
                             typename Problem::VDataType,
                             typename Problem::OaccDataType,
                             Problem::kNumGemm1Warps * get_warp_size(),
                             TileGemmShape<sequence<Problem::BlockFmhaShape::kM0,
                                                    Problem::BlockFmhaShape::kN1,
                                                    Problem::BlockFmhaShape::kK1>,
                                           typename Problem::BlockFmhaShape::Gemm1BlockWarps,
                                           typename Problem::BlockFmhaShape::Gemm1WarpTile>>;

        auto warp_gemm = [&]() {
            if constexpr(std::is_same_v<typename Problem::KDataType, fp8_t> &&
                         std::is_same_v<typename Problem::VDataType, fp8_t> &&
                         std::is_same_v<typename Problem::OaccDataType, float>)
            {
                return WarpGemmMfmaFp8Fp8F32M32N32K16SwizzleBTransposedCDistribution<>{};
                // return
                // WarpGemmImpl<WarpGemmAtrributeMfmaTransposedCDistribution_SwizzleB<
                //         WarpGemmAttributeMfmaImpl_f32_32x32x16_f8_base<typename
                //         Problem::PDataType, typename Problem::VDataType>>>{};
            }
            else
            {
                return WarpGemmMfmaDispatcher<
                    typename Problem::PDataType,
                    typename Problem::VDataType,
                    typename Problem::OaccDataType,
                    Problem::BlockFmhaShape::Gemm1WarpTile::at(number<0>{}),
                    Problem::BlockFmhaShape::Gemm1WarpTile::at(number<1>{}),
                    Problem::BlockFmhaShape::Gemm1WarpTile::at(number<2>{}),
                    true>{};
            }
        }();

        using WarpGemm = remove_cvref_t<decltype(warp_gemm)>;

        using BlockGemmPolicy = aiter::BlockGemmARegBRegCRegV2CustomPolicy<
            typename Problem::PDataType,
            typename Problem::VDataType,
            typename Problem::OaccDataType,
            typename Problem::BlockFmhaShape::Gemm1BlockWarps,
            WarpGemm>;
        return aiter::BlockGemmARegBRegCRegV2<GemmProblem, BlockGemmPolicy>{};
    }

    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr ck_tile::index_t GetSmemSize()
    {
        return 4 * GetSmemSizeKV<Problem>();
    }
};

// This pipeline is qkv all located in LDS
template <typename Problem_, typename Policy_ = BlockFmhaPipelineQRKSVSDefaultPolicy>
struct BlockFmhaPipelineQRKSVS
{
    using Problem               = ck_tile::remove_cvref_t<Problem_>;
    using Policy                = ck_tile::remove_cvref_t<Policy_>;
    using QDataType             = ck_tile::remove_cvref_t<typename Problem::QDataType>;
    using KDataType             = ck_tile::remove_cvref_t<typename Problem::KDataType>;
    using VDataType             = ck_tile::remove_cvref_t<typename Problem::VDataType>;
    using SaccDataType          = ck_tile::remove_cvref_t<typename Problem::SaccDataType>;
    using SMPLComputeDataType   = ck_tile::remove_cvref_t<typename Problem::SMPLComputeDataType>;
    using BiasDataType          = ck_tile::remove_cvref_t<typename Problem::BiasDataType>;
    using RandValOutputDataType = ck_tile::remove_cvref_t<typename Problem::RandValOutputDataType>;
    using LSEDataType           = ck_tile::remove_cvref_t<typename Problem::LSEDataType>;
    using PDataType             = ck_tile::remove_cvref_t<typename Problem::PDataType>;
    using OaccDataType          = ck_tile::remove_cvref_t<typename Problem::OaccDataType>;
    using ODataType             = ck_tile::remove_cvref_t<typename Problem::ODataType>;
    using FmhaMask              = ck_tile::remove_cvref_t<typename Problem::FmhaMask>;

    static_assert(std::is_same_v<SaccDataType, SMPLComputeDataType>,
                  "we will the same dist tensor 'sp_compute' for both gemm0 & softmax");

    using BlockFmhaShape             = ck_tile::remove_cvref_t<typename Problem::BlockFmhaShape>;
    using VLayout                    = ck_tile::remove_cvref_t<typename BlockFmhaShape::VLayout>;
    static constexpr bool kQLoadOnce = true; // if q_tile load whole block length (hdim) at once
    static_assert(kQLoadOnce == Policy::QLoadOnce);

    static constexpr ck_tile::index_t kBlockSize = Problem::kBlockSize;

    static constexpr ck_tile::index_t kM0           = BlockFmhaShape::kM0;
    static constexpr ck_tile::index_t kN0           = BlockFmhaShape::kN0;
    static constexpr ck_tile::index_t kK0           = BlockFmhaShape::kK0;
    static constexpr ck_tile::index_t kN1           = BlockFmhaShape::kN1;
    static constexpr ck_tile::index_t kK1           = BlockFmhaShape::kK1;
    static constexpr ck_tile::index_t kQKHeaddim    = BlockFmhaShape::kQKHeaddim;
    static constexpr ck_tile::index_t kSubQKHeaddim = BlockFmhaShape::kSubQKHeaddim;

    static_assert(kSubQKHeaddim <= 256, "hdim bigger than 256 is not suitable for this pipeline!");

    static constexpr bool kIsGroupMode      = Problem::kIsGroupMode;
    static constexpr bool kPadSeqLenQ       = Problem::kPadSeqLenQ;
    static constexpr bool kPadSeqLenK       = Problem::kPadSeqLenK;
    static constexpr bool kPadHeadDimQ      = Problem::kPadHeadDimQ;
    static constexpr bool kPadHeadDimV      = Problem::kPadHeadDimV;
    static constexpr bool kHasLogitsSoftCap = Problem::kHasLogitsSoftCap;
    static constexpr auto BiasEnum          = Problem::BiasEnum;
    static constexpr bool kStoreLSE         = Problem::kStoreLSE;
    static constexpr bool kHasDropout       = Problem::kHasDropout;

    static_assert(!kHasLogitsSoftCap &&
                  Problem::BiasEnum == ck_tile::BlockAttentionBiasEnum::NO_BIAS && !kHasDropout);

    static_assert(CK_TILE_FMHA_FWD_FAST_EXP2);

    // last dimension vector length used to create tensor view(and decide buffer_load vector length)
    // ... together with tensor distribution. tensor dist should able to overwrite this
    static constexpr ck_tile::index_t kAlignmentQ =
        kPadHeadDimQ ? 1 : Policy::template GetAlignmentQ<Problem>();
    static constexpr ck_tile::index_t kAlignmentK =
        kPadHeadDimQ ? 1 : Policy::template GetAlignmentK<Problem>();
    static constexpr ck_tile::index_t kAlignmentV = []() {
        if constexpr(std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor>)
            return kPadHeadDimV ? 1 : Policy::template GetAlignmentV<Problem>();
        else
            return kPadSeqLenK ? 1 : Policy::template GetAlignmentV<Problem>();
    }();

    static constexpr ck_tile::index_t kAlignmentO =
        kPadHeadDimV ? 1 : Policy::template GetAlignmentO<Problem>();
    static constexpr ck_tile::index_t kAlignmentBias =
        kPadSeqLenK ? 1 : Policy::template GetAlignmentBias<Problem>();

    static constexpr ck_tile::index_t kBlockPerCu = []() {
        if constexpr(Problem::kBlockPerCu != -1)
            return Problem::kBlockPerCu;
        else
        {
            if constexpr(kQKHeaddim <= 32)
            {
                return 2;
            }
            else if constexpr(kQKHeaddim <= 64)
            {
                return 3;
            }
            else if constexpr(kQKHeaddim <= 128)
            {
                if constexpr(BiasEnum == ck_tile::BlockAttentionBiasEnum::ELEMENTWISE_BIAS)
                    return 1;
                else
                    return 1;
            }
            else if constexpr(kQKHeaddim <= 256)
            {
                return 1;
            }
            else
            {
                return 1;
            }
        }
    }();

    static constexpr const char* name = "qr";

    using DropoutType =
        std::conditional_t<kHasDropout, ck_tile::BlockDropout, ck_tile::NullBlockDropout>;

    CK_TILE_HOST_DEVICE static constexpr ck_tile::index_t GetSmemSize()
    {
        // create another LDS buffer for p
        return ck_tile::max(kM0 * kN1 * sizeof(PDataType),
                            Policy::template GetSmemSize<Problem>() +
                                kM0 * kN0 * sizeof(PDataType));
    }

    // for debug only
    template <ck_tile::index_t MPerBlock, ck_tile::index_t NPerBlock>
    CK_TILE_DEVICE static constexpr auto MakeSimpleLdsDesc()
    {
        using namespace ck_tile;
        constexpr auto lds_block_desc =
            make_naive_tensor_descriptor(make_tuple(number<MPerBlock>{}, number<NPerBlock>{}),
                                         make_tuple(number<NPerBlock>{}, number<1>{}),
                                         number<1>{},
                                         number<1>{});

        return lds_block_desc;
    }

    // for debug only
    template <ck_tile::index_t MPerBlock>
    CK_TILE_DEVICE static constexpr auto MakeSimpleLdsDesc1D()
    {
        using namespace ck_tile;
        constexpr auto lds_block_desc = make_naive_tensor_descriptor(
            make_tuple(number<MPerBlock>{}), make_tuple(number<1>{}), number<1>{}, number<1>{});

        return lds_block_desc;
    }

    template <typename DataType, typename Descriptor>
    CK_TILE_DEVICE static constexpr auto make_lds_tile_window(void* base, const Descriptor& desc)
    {
        using namespace ck_tile;

        auto tensor_view =
            make_tensor_view<address_space_enum::lds>(reinterpret_cast<DataType*>(base), desc);
        return make_tile_window(tensor_view, desc.get_lengths(), {0, 0});
    }

#define WARP_ID 0
#define LANE_ID 0

#define ENABLE_DEBUG_STMTS 1
#if ENABLE_DEBUG_STMTS
#define DEBUG_STMTS \
    if(get_block_1d_id() == 0 && get_warp_id() == WARP_ID && get_lane_id() == LANE_ID)
#else
#define DEBUG_STMTS if constexpr(false)
#endif

#define ENABLE_DEBUG_ASM_MAKER 1
#if ENABLE_DEBUG_ASM_MAKER
#define ASM_MARKER(desc)                   \
    do                                     \
    {                                      \
        __builtin_amdgcn_sched_barrier(0); \
        asm volatile("; [POYENC] " desc);  \
        __builtin_amdgcn_sched_barrier(0); \
    } while(false)
#else
#define ASM_MARKER(desc) \
    do                   \
    {                    \
    } while(false)
#endif

#define ENABLE_TRACE 0
#define ENABLE_TENSOR_DUMP 0

    CK_TILE_DEVICE static constexpr void schedule_main_loop_gemm0() {}

    CK_TILE_DEVICE static constexpr void schedule_main_loop_gemm1() {}

    // vmcnt=0~63, lgkmcnt=0~15, expcnt=0~7
    template <uint16_t Vmcnt, uint8_t Lgkmcnt, uint8_t Expcnt = 7>
    CK_TILE_DEVICE static constexpr void s_waitcnt()
    {
        // vmcnt use bits {[15:14],[3:0]}
        // expcnt use bits [6:4]
        // lgkmcnt use bits [11:8]
        __builtin_amdgcn_s_waitcnt((((0b110000 & Vmcnt) << (14 - 4)) | (0b1111 & Vmcnt)) |
                                   ((0b111 & Expcnt) << 4) | ((0b1111 & Lgkmcnt) << 8));
    }

    template <uint16_t Vmcnt>
    CK_TILE_DEVICE static constexpr void s_waitcnt_vmcnt()
    {
        s_waitcnt<Vmcnt, 15>();
    }

    template <uint8_t Lgkmcnt>
    CK_TILE_DEVICE static constexpr void s_waitcnt_lgkmcnt()
    {
        s_waitcnt<63, Lgkmcnt>();
    }

    template <typename QDramBlockWindowTmp,
              typename KDramBlockWindowTmp,
              typename VDramBlockWindowTmp,
              typename BiasDramBlockWindowTmp,
              typename RandValDramBlockWindowTmp,
              typename LSEDramBlockWindowTmp,
              typename QElementFunction,
              typename KElementFunction,
              typename VElementFunction,
              typename BiasElementFunction,
              typename LSEElementFunction,
              typename SAccElementFunction,
              typename PComputeElementFunction,
              typename OAccElementFunction,
              typename PositionEncoding>
    CK_TILE_DEVICE auto
    operator()(const QDramBlockWindowTmp& q_dram_block_window_tmp, // M0*K0 tile
               const QElementFunction& q_element_func,
               const KDramBlockWindowTmp& k_dram_block_window_tmp, // N0*K0 tile
               const KElementFunction& k_element_func,
               const VDramBlockWindowTmp& v_dram_block_window_tmp, // N1*K1 tile
               const VElementFunction& v_element_func,
               const BiasDramBlockWindowTmp& bias_dram_block_window_tmp, // M0*N0 tile
               const BiasElementFunction& bias_element_func,
               RandValDramBlockWindowTmp& randval_dram_block_window_tmp,
               LSEDramBlockWindowTmp& lse_dram_window_tmp, // M0*1 tile
               const LSEElementFunction& lse_element_func,
               const SAccElementFunction& s_acc_element_func,
               const PComputeElementFunction& p_compute_element_func,
               const OAccElementFunction& o_acc_element_func,
               FmhaMask mask,
               PositionEncoding position_encoding,
               float scale_s,
               void* smem_ptr,
               DropoutType& dropout) const
    {
        using namespace ck_tile;

        static_assert(
            std::is_same_v<QDataType, remove_cvref_t<typename QDramBlockWindowTmp::DataType>> &&
                std::is_same_v<KDataType, remove_cvref_t<typename KDramBlockWindowTmp::DataType>> &&
                std::is_same_v<VDataType, remove_cvref_t<typename VDramBlockWindowTmp::DataType>>,
            "wrong!");

        static_assert(kM0 == QDramBlockWindowTmp{}.get_window_lengths()[number<0>{}] &&
                          kN0 == KDramBlockWindowTmp{}.get_window_lengths()[number<0>{}] &&
                          kK0 == KDramBlockWindowTmp{}.get_window_lengths()[number<1>{}] &&
                          kN1 == VDramBlockWindowTmp{}.get_window_lengths()[number<0>{}] &&
                          kK1 == VDramBlockWindowTmp{}.get_window_lengths()[number<1>{}] &&
                          kM0 == BiasDramBlockWindowTmp{}.get_window_lengths()[number<0>{}] &&
                          kN0 == BiasDramBlockWindowTmp{}.get_window_lengths()[number<1>{}],
                      "wrong!");

        static_assert(sizeof(SaccDataType) * kM0 * kN0 <= GetSmemSize());
        auto s_lds = make_tensor_view<address_space_enum::lds>(
            reinterpret_cast<SaccDataType*>(static_cast<char*>(smem_ptr)),
            MakeSimpleLdsDesc<kM0, kN0>());
        [[maybe_unused]] auto s_lds_window =
            make_tile_window(s_lds, make_tuple(number<kM0>{}, number<kN0>{}), {0, 0});

        auto p_lds = make_tensor_view<address_space_enum::lds>(
            reinterpret_cast<PDataType*>(static_cast<char*>(smem_ptr) +
                                         Policy::template GetSmemSize<Problem>()),
            MakeSimpleLdsDesc<kM0, kN0>());
        [[maybe_unused]] auto p_lds_window =
            make_tile_window(p_lds, make_tuple(number<kM0>{}, number<kN0>{}), {0, 0});

        auto o_lds = make_tensor_view<address_space_enum::lds>(
            reinterpret_cast<PDataType*>(static_cast<char*>(smem_ptr)),
            MakeSimpleLdsDesc<kM0, kN1>());
        [[maybe_unused]] auto o_lds_window =
            make_tile_window(o_lds, make_tuple(number<kM0>{}, number<kN1>{}), {0, 0});

        auto m_lds = make_tensor_view<address_space_enum::lds>(
            reinterpret_cast<SMPLComputeDataType*>(static_cast<char*>(smem_ptr) +
                                                   Policy::template GetSmemSize<Problem>()),
            MakeSimpleLdsDesc1D<kM0>());
        [[maybe_unused]] auto m_lds_window =
            make_tile_window(m_lds, make_tuple(number<kM0>{}), {0});

        const index_t warp_group_id = get_warp_id() / 4;

        // Block GEMM
        constexpr auto gemm_0 = Policy::template GetQKBlockGemm<Problem>();
        constexpr auto gemm_1 = Policy::template GetKVBlockGemm<Problem>();

        auto q_dram_window = make_tile_window(q_dram_block_window_tmp,
                                              Policy::template MakeQRegTileDistribution<Problem>());

        // reduction function for softmax
        const auto f_max = [](auto e0, auto e1) { return max(e0, e1); };
        const auto f_sum = [](auto e0, auto e1) { return e0 + e1; };

        statically_indexed_array<decltype(make_lds_tile_window<KDataType>(
                                     nullptr, Policy::template MakeKLdsBlockDescriptor<Problem>())),
                                 2>
            k_lds_window;
        statically_indexed_array<decltype(make_lds_tile_window<VDataType>(
                                     nullptr, Policy::template MakeVLdsBlockDescriptor<Problem>())),
                                 2>
            v_lds_window;

        decltype(make_static_distributed_tensor<QDataType>(
            Policy::template MakeQRegTileDistribution<Problem>())) q_tile;

        union kv_tile_type
        {
            CK_TILE_DEVICE kv_tile_type() {}

            decltype(load_tile(
                make_tile_window(k_lds_window(number<0>{}),
                                 Policy::template MakeKRegTileDistribution<Problem>()))) k_tile;

            decltype(load_tile(
                make_tile_window(v_lds_window(number<0>{}),
                                 Policy::template MakeVRegTileDistribution<Problem>()))) v_tile;
        } kv_tile;

        struct sp_compute_type
        {
            CK_TILE_DEVICE sp_compute_type() {}

            decltype(gemm_0.MakeCBlockTile()) sp_compute;
            decltype(cast_tile<PDataType>(
                tile_elementwise_in(p_compute_element_func, sp_compute))) p;
        };
        statically_indexed_array<sp_compute_type, 2> sp;

        decltype(gemm_1.MakeCBlockTile()) o_acc;

        decltype(block_tile_reduce<SMPLComputeDataType>(
            sp(number<0>{}).sp_compute, sequence<1>{}, f_max, SMPLComputeDataType{0})) m;
        decltype(m) m_local;
        decltype(m) l;

        // initialize k_lds_window and v_lds_window
        static_for<0, 2, 1>{}([&](auto idx) {
            k_lds_window(idx) = make_lds_tile_window<KDataType>(
                static_cast<char*>(smem_ptr) +
                    (2 * idx) * Policy::template GetSmemSizeKV<Problem>(),
                Policy::template MakeKLdsBlockDescriptor<Problem>());
        });
        static_for<0, 2, 1>{}([&](auto idx) {
            v_lds_window(idx) = make_lds_tile_window<VDataType>(
                static_cast<char*>(smem_ptr) +
                    (2 * idx + 1) * Policy::template GetSmemSizeKV<Problem>(),
                Policy::template MakeVLdsBlockDescriptor<Problem>());
        });

        {
            auto origin_q      = load_tile(q_dram_window);
            auto transformed_q = tile_elementwise_in(q_element_func, origin_q);

            q_tile = transformed_q;
        }

        clear_tile(o_acc);
        set_tile(m, -numeric<SMPLComputeDataType>::infinity());
        clear_tile(l);

        const auto q_origin = q_dram_window.get_window_origin();
        const auto [seqlen_k_start, seqlen_k_end] =
            mask.GetTileRangeAlongX(q_origin.at(number<0>{}), number<kM0>{}, number<kN0>{});

        const auto num_total_loop = integer_divide_ceil(seqlen_k_end - seqlen_k_start, kN0);
        index_t kv_token_start    = seqlen_k_start;

        // check early exit if no work to do
        if constexpr(FmhaMask::IsMasking || kPadSeqLenK)
        {
            if(num_total_loop <= 0)
            {
                if constexpr(kStoreLSE)
                {
                    auto lse =
                        make_static_distributed_tensor<LSEDataType>(m.get_tile_distribution());

                    set_tile(lse, -numeric<SMPLComputeDataType>::infinity());

                    store_tile(lse_dram_window_tmp, tile_elementwise_in(lse_element_func, lse));
                }

                // Note: here occ are all cleard, return it
                // Note: q loaded but no fence, ignore it.
                return o_acc;
            }
        }

        auto k_dram_block_window =
            make_tile_window(k_dram_block_window_tmp.get_bottom_tensor_view(),
                             k_dram_block_window_tmp.get_window_lengths(),
                             {seqlen_k_start, 0});

        const auto bias_origin = bias_dram_block_window_tmp.get_window_origin();
        auto bias_dram_window =
            make_tile_window(bias_dram_block_window_tmp.get_bottom_tensor_view(),
                             bias_dram_block_window_tmp.get_window_lengths(),
                             {bias_origin.at(number<0>{}), seqlen_k_start}, // M/N
                             Policy::template MakeBiasDramTileDistribution<decltype(gemm_0)>());

        auto randval_dram_window = dropout.template MakeRandvalDramWindow<decltype(gemm_0)>(
            randval_dram_block_window_tmp, seqlen_k_start);

        auto v_dram_window =
            make_tile_window(v_dram_block_window_tmp.get_bottom_tensor_view(),
                             v_dram_block_window_tmp.get_window_lengths(),
                             {0, seqlen_k_start}, // TODO: hdim split?
                             Policy::template MakeVDramTileDistribution<Problem>());

        // prefetch K tile
        index_t i_total_loops      = 0;
        constexpr index_t k0_loops = kQKHeaddim / kK0;
        constexpr index_t k1_loops = kN0 / kK1;
        static_assert(1 == k0_loops);
        static_assert(1 == k1_loops);
        static_assert(kN0 == kK1);

        constexpr index_t NumWarpGroups = Problem::kBlockSize / Policy::NumThreadPerWarpGroup;
        static_assert(NumWarpGroups == 2);

        [[maybe_unused]] auto print_dist_tensor = [&](const auto& dist_tensor, const char* name) {
            printf("[POYENC] %s (size=%d): %5.2f",
                   name,
                   decltype(dist_tensor.thread_buf_)::size(),
                   ck_tile::type_convert<float>(dist_tensor.thread_buf_[0]));
            static_for<1, decltype(dist_tensor.thread_buf_)::size(), 1>{}([&](auto i) {
                printf(", %5.2f", ck_tile::type_convert<float>(dist_tensor.thread_buf_[i]));
            });
            printf("\n");
        };

        [[maybe_unused]] auto print_lds = [&](auto lds_tile_window, const char* name) {
            const auto num_rows = lds_tile_window.get_window_lengths().at(number<0>{});
            const auto num_cols = lds_tile_window.get_window_lengths().at(number<1>{});

            auto desc = lds_tile_window.get_bottom_tensor_view().desc_;
            auto data = lds_tile_window.get_bottom_tensor_view().buf_.p_data_;

            if constexpr(true || num_rows < num_cols)
            {
                for(int row = 0; row < num_rows; ++row)
                {
                    int offset = desc.calculate_offset(make_tuple(row, 0));
                    printf("[DEVICE] %s[%3d] = %5.2f",
                           name,
                           row,
                           ck_tile::type_convert<float>(data[offset]));
                    for(int col = 1; col < num_cols; ++col)
                    {
                        printf(", ");
                        offset = desc.calculate_offset(make_tuple(row, col));
                        printf("%5.2f", ck_tile::type_convert<float>(data[offset]));
                    }
                    printf("\n");
                }
            }
            else
            {
                for(int col = 0; col < num_cols; ++col)
                {
                    int offset = desc.calculate_offset(make_tuple(0, col));
                    printf("[DEVICE] %s[%3d] = %5.2f",
                           name,
                           col,
                           ck_tile::type_convert<float>(data[offset]));
                    for(int row = 1; row < num_rows; ++row)
                    {
                        printf(", ");
                        offset = desc.calculate_offset(make_tuple(row, col));
                        printf("%5.2f", ck_tile::type_convert<float>(data[offset]));
                    }
                    printf("\n");
                }
            }
        };

        [[maybe_unused]] auto print_lds_1d = [&](auto lds_tile_window, const char* name) {
            const auto num_elems = lds_tile_window.get_window_lengths().at(number<0>{});

            auto desc = lds_tile_window.get_bottom_tensor_view().desc_;
            auto data = lds_tile_window.get_bottom_tensor_view().buf_.p_data_;

            int offset = desc.calculate_offset(make_tuple(0));
            printf("[DEVICE] %s = %5.2f", name, ck_tile::type_convert<float>(data[offset]));
            for(int e = 1; e < num_elems; ++e)
            {
                printf(", ");
                offset = desc.calculate_offset(make_tuple(e));
                printf("%5.2f", ck_tile::type_convert<float>(data[offset]));
            }
            printf("\n");
        };

        auto K_mem_load = [&](auto k_lds_write_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS
            {
                auto origin = k_dram_block_window.get_window_origin();
                printf("[POYENC] \tK_mem_load, write_idx = %d, origin = %d\n",
                       k_lds_write_idx.value,
                       origin.at(number<0>{}));
            }
#endif
            auto k_dram_window = make_tile_window(
                k_dram_block_window, Policy::template MakeKDramTileDistribution<Problem>());
            auto k_block_tile = load_tile(k_dram_window); // global read i

            __builtin_amdgcn_sched_barrier(0);

            store_tile(k_lds_window(k_lds_write_idx),
                       tile_elementwise_in(k_element_func, k_block_tile));

            /// FIXME: use the future-predicting method to move the window
            // move K tile windows
            move_tile_window(k_dram_block_window, {kN0, 0});

            s_waitcnt_lgkmcnt<0>();
        };

        auto K_lds_load = [&](auto k_lds_read_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] \tK_lds_load, read_idx = %d\n", k_lds_read_idx.value); }
#endif
            auto k_lds_window_for_load = make_tile_window(
                k_lds_window(k_lds_read_idx), Policy::template MakeKRegTileDistribution<Problem>());

            kv_tile.k_tile = load_tile(k_lds_window_for_load);
        };

        auto V_mem_load = [&](auto v_lds_write_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS
            {
                auto origin = v_dram_window.get_window_origin();
                printf("[POYENC] \tV_mem_load, write_idx: %d, origin = %d\n",
                       v_lds_write_idx.value,
                       origin.at(number<1>{}));
            }
#endif
            const auto v_tile = load_tile(v_dram_window);
            __builtin_amdgcn_sched_barrier(0);

            if constexpr(std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor>)
            {
                auto v_shuffle_tmp = make_static_distributed_tensor<VDataType>(
                    Policy::template MakeShuffledVRegBlockDescriptor<Problem>());
                shuffle_tile(v_shuffle_tmp, v_tile);
                __builtin_amdgcn_sched_barrier(0);
                store_tile(
                    v_lds_window(v_lds_write_idx),
                    tile_elementwise_in(v_element_func, v_shuffle_tmp)); // store the prefetch
            }
            else
            {
                __builtin_amdgcn_sched_barrier(0);
                store_tile(v_lds_window(v_lds_write_idx),
                           tile_elementwise_in(v_element_func, v_tile)); // store the prefetch
            }

            /// FIXME: use the future-predicting method to move the window
            move_tile_window(v_dram_window, {0, kK1});

            s_waitcnt_lgkmcnt<0>();
        };

        auto V_lds_load = [&](auto v_lds_read_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] \tV_lds_load, read_idx = %d\n", v_lds_read_idx.value); }
#endif
            auto v_lds_window_for_load = make_tile_window(
                v_lds_window(v_lds_read_idx), Policy::template MakeVRegTileDistribution<Problem>());

            kv_tile.v_tile = load_tile(v_lds_window_for_load);
        };

        static const auto get_validated_m = [](SMPLComputeDataType raw_m) {
            /// NOTICE: bias might be materialized mask including -inf values, need
            /// consideration
            if constexpr(BiasEnum == BlockAttentionBiasEnum::ELEMENTWISE_BIAS ||
                         FmhaMask::IsMasking)
            {
                return raw_m == -numeric<SMPLComputeDataType>::infinity()
                           ? type_convert<SMPLComputeDataType>(0.f)
                           : raw_m;
            }
            else
            {
                return raw_m;
            }
        };

        decltype(m) m_old;

        auto fmha_alu0 = [&](auto sp_reg_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] \tfmha_alu0, sp_reg_idx = %d\n", sp_reg_idx.value); }
#endif
            // sp_compute{j} = sp_compute{j} * scale_s
            tile_elementwise_inout([&](auto& logits) { logits = logits * scale_s; },
                                   sp(sp_reg_idx).sp_compute);

            m_local = block_tile_reduce<SMPLComputeDataType>(
                sp(sp_reg_idx).sp_compute,
                sequence<1>{},
                f_max,
                -numeric<SMPLComputeDataType>::infinity()); // m_local = rowmax(S{j})
            block_tile_reduce_sync(m_local, f_max, bool_constant<false>{});

            m_old = m; // m{j-1}
            tile_elementwise_inout([](auto& e0, auto e1, auto e2) { e0 = max(e1, e2); },
                                   m,
                                   m_old,
                                   m_local); // m{j}
            constexpr auto p_spans =
                std::decay_t<decltype(sp(sp_reg_idx).sp_compute)>::get_distributed_spans();
            sweep_tile_span(p_spans[number<0>{}], [&](auto idx0) {
                constexpr auto i_idx = make_tuple(idx0);
                auto row_max         = get_validated_m(m[i_idx]);

                sweep_tile_span(p_spans[number<1>{}], [&](auto idx1) {
                    constexpr auto i_j_idx = make_tuple(idx0, idx1);
                    sp(sp_reg_idx).sp_compute(i_j_idx) =
                        ck_tile::exp2(sp(sp_reg_idx).sp_compute[i_j_idx] - row_max);
                });
            });

            sp(sp_reg_idx).p = cast_tile<PDataType>(
                tile_elementwise_in(p_compute_element_func, sp(sp_reg_idx).sp_compute));
        };

        decltype(block_tile_reduce<SMPLComputeDataType>(
            sp(number<0>{}).sp_compute, sequence<1>{}, f_sum, SMPLComputeDataType{0})) rowsum_p;

        auto fmha_alu1 = [&](auto sp_reg_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] \tfmha_alu1, sp_reg_idx = %d\n", sp_reg_idx.value); }
#endif
            rowsum_p = block_tile_reduce<SMPLComputeDataType>(
                sp(sp_reg_idx).sp_compute,
                sequence<1>{},
                f_sum,
                SMPLComputeDataType{0}); // rowsum(Pcompute{j})

            block_tile_reduce_sync(rowsum_p, f_sum, bool_constant<false>{});
            // l{j}, Oacc{j}
            constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
            sweep_tile_span(o_spans[number<0>{}], [&](auto idx0) {
                constexpr auto i_idx = make_tuple(idx0);
                const auto tmp       = [&]() {
                    auto row_max = get_validated_m(m[i_idx]);
                    return ck_tile::exp2(m_old[i_idx] - row_max);
                }();

                l(i_idx) = tmp * l[i_idx] + rowsum_p[i_idx];
            });
        };

        auto gemm = [&](auto sp_reg_idx, auto gemm_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS
            {
                printf("[POYENC] \tgemm, gemm_idx = %d, sp_reg_idx = %d\n",
                       gemm_idx.value,
                       sp_reg_idx.value);
            }
#endif
            if constexpr(gemm_idx == 0)
            {
                clear_tile(sp(sp_reg_idx).sp_compute); // initialize C
                gemm_0(sp(sp_reg_idx).sp_compute,
                       get_slice_tile(q_tile,
                                      sequence<0, (k0_loops - 1) * kK0>{},
                                      sequence<kM0, k0_loops * kK0>{}),
                       get_slice_tile(kv_tile.k_tile,
                                      sequence<0, (k0_loops - 1) * kK0>{},
                                      sequence<kN0, k0_loops * kK0>{}));
            }
            else
            {
                gemm_1(o_acc,
                       get_slice_tile(sp(sp_reg_idx).p,
                                      sequence<0, (k1_loops - 1) * kK1>{},
                                      sequence<kM0, k1_loops * kK1>{}),
                       get_slice_tile(kv_tile.v_tile,
                                      sequence<0, (k1_loops - 1) * kK1>{},
                                      sequence<kN1, k1_loops * kK1>{}));
            }
        };

        auto cl_calc = [&](auto sp_reg_idx, auto gemm_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS
            {
                printf("[POYENC] \tcl_calc, gemm_idx = %d, sp_reg_idx = %d\n",
                       gemm_idx.value,
                       sp_reg_idx.value);
            }
#endif
            if constexpr(gemm_idx == 0)
            {
                clear_tile(sp(sp_reg_idx).sp_compute); // initialize C
                gemm_0(sp(sp_reg_idx).sp_compute,
                       get_slice_tile(q_tile,
                                      sequence<0, (k0_loops - 1) * kK0>{},
                                      sequence<kM0, k0_loops * kK0>{}),
                       get_slice_tile(kv_tile.k_tile,
                                      sequence<0, (k0_loops - 1) * kK0>{},
                                      sequence<kN0, k0_loops * kK0>{}));
            }
            else
            {
                gemm_1(o_acc,
                       get_slice_tile(sp(sp_reg_idx).p,
                                      sequence<0, (k1_loops - 1) * kK1>{},
                                      sequence<kM0, k1_loops * kK1>{}),
                       get_slice_tile(kv_tile.v_tile,
                                      sequence<0, (k1_loops - 1) * kK1>{},
                                      sequence<kN1, k1_loops * kK1>{}));
                fmha_alu0(number<1>{} - sp_reg_idx);
            }
        };

        auto fmha_alu_D_upd = [&] {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] \tfmha_alu_D_upd\n"); }
#endif
            // l{j}, Oacc{j}
            constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();
            sweep_tile_span(o_spans[number<0>{}], [&](auto idx0) {
                constexpr auto i_idx = make_tuple(idx0);
                const auto tmp       = [&]() {
                    auto row_max = get_validated_m(m[i_idx]);
                    return ck_tile::exp2(m_old[i_idx] - row_max);
                }();

                sweep_tile_span(o_spans[number<1>{}], [&](auto idx1) {
                    constexpr auto i_j_idx = make_tuple(idx0, idx1);
                    // FIXME: this use different equation from FA v2 paper,
                    // but produce correc result.
                    // Is the equation wrong?
                    o_acc(i_j_idx) *= tmp;
                });
            });
        };

        auto fmha_mask = [&](auto sp_reg_idx) {
#if ENABLE_TRACE
            DEBUG_STMTS
            {
                printf("[POYENC] \tfmha_mask, sp_reg_idx = %d, kv_token_start: %d\n",
                       sp_reg_idx.value,
                       kv_token_start);
            }
#endif
            if constexpr(kPadSeqLenK || FmhaMask::IsMasking)
            {
                bool need_perpixel_check = mask.IsEdgeTile(
                    q_origin.at(number<0>{}), kv_token_start, number<kM0>{}, number<kN0>{});
                if(need_perpixel_check)
                {
                    set_tile_if(sp(sp_reg_idx).sp_compute,
                                -numeric<SMPLComputeDataType>::infinity(),
                                [&](auto tile_idx) {
                                    const auto row =
                                        q_origin.at(number<0>{}) + tile_idx.at(number<0>{});
                                    const auto col = kv_token_start + tile_idx.at(number<1>{});
                                    return mask.IsOutOfBound(row, col);
                                });
                }
            }
        };

        auto cl_load = [&](auto load_type, auto mem_wr_idx, auto lds_rd_idx) {
            if constexpr(load_type == 0)
            {
                V_mem_load(mem_wr_idx);
                K_lds_load(lds_rd_idx);
            }
            else
            {
                K_mem_load(mem_wr_idx);
                V_lds_load(lds_rd_idx);
            }
        };

        auto core_loop = [&](auto cl_p) {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] core_loop, cl_p = %d\n", cl_p.value); }
#endif
            auto gemm0 = number<0>{};
            auto gemm1 = number<1>{};

            auto memV = number<0>{};
            auto memK = number<1>{};

            auto iteration = [&](auto pi) {
#if ENABLE_TRACE
                DEBUG_STMTS { printf("[POYENC] \titeration, pi = %d\n", pi.value); }
#endif
                auto xdl_SP_p01_reg_idx = number<1>{} - pi;
                auto xdl_SP_p23_reg_idx = pi;

                auto K_w0_lds_wr_idx = number<1>{} - pi;
                auto V_w0_lds_wr_idx = pi;
                auto K_w0_lds_rd_idx = pi;
                auto V_w0_lds_rd_idx = pi;

                auto K_w4_lds_wr_idx = number<1>{} - pi;
                auto V_w4_lds_wr_idx = number<1>{} - pi;
                auto K_w4_lds_rd_idx = number<1>{} - pi;
                auto V_w4_lds_rd_idx = pi;

                bool result = true;

                if constexpr(cl_p == 0)
                {
                    __builtin_amdgcn_sched_barrier(0);
// phase0
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase0 Wave0-3\n"); }
#endif
                    ASM_MARKER("phase0 Wave0-3");
                    s_waitcnt_lgkmcnt<0>();
                    __builtin_amdgcn_sched_barrier(0);
                    cl_calc(xdl_SP_p01_reg_idx, gemm0);
                    fmha_alu1(xdl_SP_p23_reg_idx);

                    schedule_main_loop_gemm0();
#if 0 && ENABLE_TENSOR_DUMP
                    // print K1
                    block_sync_lds();
                    DEBUG_STMTS { print_lds(k_lds_window(xdl_SP_p01_reg_idx), "K"); }
#endif
#if 0 && ENABLE_TENSOR_DUMP
                    // print S1
                    block_sync_lds();
                    store_tile(s_lds_window, sp(xdl_SP_p01_reg_idx).sp_compute);
                    block_sync_lds();
                    DEBUG_STMTS { print_lds(s_lds_window, "S"); }
#endif
                    __builtin_amdgcn_sched_barrier(0);
// phase1
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase1 Wave0-3\n"); }
#endif
                    ASM_MARKER("phase1 Wave0-3");
                    s_waitcnt_vmcnt<0>();
                    __builtin_amdgcn_sched_barrier(0);
                    __builtin_amdgcn_s_barrier();
                    cl_load(memK, K_w0_lds_wr_idx, V_w0_lds_rd_idx);
                    fmha_mask(xdl_SP_p01_reg_idx);

                    __builtin_amdgcn_sched_barrier(0);
// phase2
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase2 Wave0-3\n"); }
#endif
                    ASM_MARKER("phase2 Wave0-3");
                    s_waitcnt_lgkmcnt<0>();
                    __builtin_amdgcn_sched_barrier(0);
                    __builtin_amdgcn_s_barrier();
                    cl_calc(xdl_SP_p23_reg_idx, gemm1);
                    fmha_alu_D_upd();

                    schedule_main_loop_gemm1();

                    __builtin_amdgcn_sched_barrier(0);
// phase3
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase3 Wave0-3\n"); }
#endif
                    ASM_MARKER("phase3 Wave0-3");
                    s_waitcnt_vmcnt<0>();
                    __builtin_amdgcn_sched_barrier(0);
                    __builtin_amdgcn_s_barrier();
                    cl_load(memV, V_w0_lds_wr_idx, K_w0_lds_rd_idx);

                    kv_token_start += kN0;
                    if(num_total_loop <= ++i_total_loops)
                    {
                        result = false;
                    }
                }
                else
                {
                    __builtin_amdgcn_sched_barrier(0);
// phase0
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase0 Wave4-7\n"); }
#endif
                    ASM_MARKER("phase0 Wave4-7");
                    cl_load(memV, V_w4_lds_wr_idx, K_w4_lds_rd_idx);

                    __builtin_amdgcn_sched_barrier(0);
// phase1
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase1 Wave4-7\n"); }
#endif
                    ASM_MARKER("phase1 Wave4-7");
                    s_waitcnt<0, 0>();
                    __builtin_amdgcn_sched_barrier(0);
                    __builtin_amdgcn_s_barrier();
                    cl_calc(xdl_SP_p01_reg_idx, gemm0);
                    fmha_alu1(xdl_SP_p23_reg_idx);

                    schedule_main_loop_gemm0();
#if 0
                    // print K1 tile
                    DEBUG_STMTS
                    {
                        printf("[POYENC] K1 tile (size=%d): %5.2f",
                               decltype(k_tile.thread_buf_)::size(),
                               ck_tile::type_convert<float>(k_tile.thread_buf_[0]));
                        static_for<1, decltype(k_tile.thread_buf_)::size(), 1>{}(
                            [&](auto i) {
                                printf(
                                    ", %5.2f",
                                    ck_tile::type_convert<float>(kv_tile.k_tile.thread_buf_[i]));
                            });
                        printf("\n");
                    }
#endif
#if 0 && ENABLE_TENSOR_DUMP
                    // print S1
                    block_sync_lds();
                    store_tile(s_lds_window, sp(xdl_SP_p01_reg_idx).sp_compute);
                    block_sync_lds();
                    DEBUG_STMTS { print_lds(s_lds_window, "S"); }
#endif
                    __builtin_amdgcn_sched_barrier(0);
// phase2
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase2 Wave4-7\n"); }
#endif
                    ASM_MARKER("phase2 Wave4-7");
                    __builtin_amdgcn_s_barrier();
                    cl_load(memK, K_w4_lds_wr_idx, V_w4_lds_rd_idx);
                    fmha_mask(xdl_SP_p01_reg_idx);

                    kv_token_start += kN0;
                    if(num_total_loop <= ++i_total_loops)
                    {
                        result = false;
                    }

                    __builtin_amdgcn_sched_barrier(0);
// phase3
#if ENABLE_TRACE
                    DEBUG_STMTS { printf("[POYENC] phase3 Wave4-7\n"); }
#endif
                    ASM_MARKER("phase3 Wave4-7");
                    s_waitcnt<0, 0>();
                    __builtin_amdgcn_sched_barrier(0);
                    __builtin_amdgcn_s_barrier();
                    cl_calc(xdl_SP_p23_reg_idx, gemm1);
                    fmha_alu_D_upd();

                    schedule_main_loop_gemm1();
                }
                return result;
            };
            return iteration(number<0>{}) && iteration(number<1>{});
        };

        auto fmha_post_process = [&](auto d) {
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] fmha_post_process, d = %d\n", d.value); }
#endif
            auto ps_pi        = number<1>{} - d;
            auto V_lds_rd_idx = ps_pi;

            V_lds_load(V_lds_rd_idx);
            fmha_alu1(ps_pi);

#if 0
            // if num_tool_loops is even, use SP[1]
            //                      odd, use SP[0]
            auto sp_reg_idx = number<0>{};
#if 1
            block_sync_lds();
            store_tile(m_lds_window, m_old);
            block_sync_lds();
            DEBUG_STMTS { print_lds_1d(m_lds_window, "M_OLD"); }

            block_sync_lds();
            store_tile(m_lds_window, m);
            block_sync_lds();
            DEBUG_STMTS { print_lds_1d(m_lds_window, "M"); }

            block_sync_lds();
            store_tile(m_lds_window, rowsum_p);
            block_sync_lds();
            DEBUG_STMTS { print_lds_1d(m_lds_window, "R"); }

            block_sync_lds();
            store_tile(m_lds_window, l);
            block_sync_lds();
            DEBUG_STMTS { print_lds_1d(m_lds_window, "L"); }
#endif
#if 1
            block_sync_lds();
            store_tile(s_lds_window, s(sp_reg_idx));
            block_sync_lds();
            DEBUG_STMTS { print_lds(s_lds_window, "S"); }
#endif

#if 1
            block_sync_lds();
            store_tile(s_lds_window, sp(sp_reg_idx).sp_compute);
            block_sync_lds();
            DEBUG_STMTS { print_lds(s_lds_window, "P_COMPUTE"); }
#endif

#if 1
            auto o_acc_fp16 = cast_tile<PDataType>(o_acc);
            block_sync_lds();
            store_tile(o_lds_window, o_acc_fp16);
            block_sync_lds();

            DEBUG_STMTS { print_lds(o_lds_window, "O_ACC(rescaled)"); }
#endif
#endif
#if 0
        block_sync_lds();
        store_tile(p_lds_window, p(number<1>{}));
        block_sync_lds();
        DEBUG_STMTS { print_lds(p_lds_window, "P1"); }

        block_sync_lds();
        store_tile(p_lds_window, p(number<0>{}));
        block_sync_lds();
        DEBUG_STMTS { print_lds(p_lds_window, "P0"); }
#endif

            auto xdl_SP_p23_reg_idx = ps_pi;
            gemm(xdl_SP_p23_reg_idx, /*gemm_idx=*/number<1>{});
        };

        // pre-stage
        {
            ASM_MARKER("before pre-stage");
#if ENABLE_TRACE
            DEBUG_STMTS { printf("[POYENC] pre-stage\n"); }
#endif
            const auto k_origin = k_dram_block_window.get_window_origin();

            // (1) load K0 to LDS & VGPR
            K_mem_load(number<0>{}); // mem_K0
            __builtin_amdgcn_s_barrier();

#if 0 && ENABLE_TENSOR_DUMP
            // print K0
            block_sync_lds();
            DEBUG_STMTS { print_lds(k_lds_window(number<0>{}), "K"); }
            block_sync_lds();
#endif

            K_lds_load(number<0>{}); // lds_K0

            // (2) prefetch K1 and V0 to LDS in parallel with GEMM0
            if(1 < num_total_loop)
            {
                K_mem_load(number<1>{}); // mem_K1
            }
            V_mem_load(number<0>{}); // mem_V0

// print K0 tile
#if 0
            block_sync_lds();
            DEBUG_STMTS
            {
                printf("[POYENC] K0 tile (size=%d): %5.2f",
                       decltype(k_tile.thread_buf_)::size(),
                       ck_tile::type_convert<float>(k_tile.thread_buf_[0]));
                static_for<1, decltype(k_tile.thread_buf_)::size(), 1>{}([&](auto i) {
                    printf(", %5.2f", ck_tile::type_convert<float>(k_tile.thread_buf_[i]));
                });
                printf("\n");
            }
#endif

            // (3) mfma (Q*K0) + softmax
            __builtin_amdgcn_s_barrier();
            gemm(number<0>{}, /*gemm_idx=*/number<0>{});

#if 0
            // clear s_lds_window
            std::decay_t<decltype(sp(number<0>{}).sp_compute)> dummy;
            clear_tile(dummy);
            block_sync_lds();
            store_tile(s_lds_window, dummy);
            block_sync_lds();
#endif

#if 0 && ENABLE_TENSOR_DUMP
            // print S0
            block_sync_lds();
            store_tile(s_lds_window, sp(number<0>{}).sp_compute);
            block_sync_lds();
            DEBUG_STMTS { print_lds(s_lds_window, "S"); }
#endif
            fmha_mask(number<0>{});
            /// TODO: find better way to map fmha_alu(0,96) call
            fmha_alu0(number<0>{});
            fmha_alu_D_upd();

            kv_token_start += kN0;
            ++i_total_loops;
            if(num_total_loop <= i_total_loops)
            {
                goto label_main_loops_exit;
            }

            if(2 < num_total_loop)
            {
                K_mem_load(number<0>{}); // mem_K2
            }

            ASM_MARKER("end pre-stage");
        }

        if(1 < num_total_loop)
        {
            if(warp_group_id == 0)
            {
                V_mem_load(number<1>{}); // V1
                K_lds_load(number<1>{}); // K1

                // DEBUG_STMTS { print_lds(k_lds_window(number<1>{}), "K1"); }

                asm volatile("s_setprio 0");
                __builtin_amdgcn_s_barrier();
                while(core_loop(number<0>{}))
                    ;
            }
            else
            {
                asm volatile("s_setprio 1");
                __builtin_amdgcn_s_barrier();
                while(core_loop(number<1>{}))
                    ;
            }
        }
    label_main_loops_exit:
        if(num_total_loop % 2)
        {
            goto label_odd64_tail;
        }

        fmha_post_process(number<0>{});
        goto label_write_out;

    label_odd64_tail:
        fmha_post_process(number<1>{});

    label_write_out:
#if 0
        block_sync_lds();
        store_tile(m_lds_window, m_old);
        block_sync_lds();
        DEBUG_STMTS { print_lds_1d(m_lds_window, "M_OLD"); }

        block_sync_lds();
        store_tile(m_lds_window, m);
        block_sync_lds();
        DEBUG_STMTS { print_lds_1d(m_lds_window, "M"); }

        block_sync_lds();
        store_tile(m_lds_window, rowsum_p);
        block_sync_lds();
        DEBUG_STMTS { print_lds_1d(m_lds_window, "R"); }

        block_sync_lds();
        store_tile(m_lds_window, l);
        block_sync_lds();
        DEBUG_STMTS { print_lds_1d(m_lds_window, "L"); }
#endif
#if 0
        auto o_acc_fp16 = cast_tile<PDataType>(o_acc);
        block_sync_lds();
        store_tile(o_lds_window, o_acc_fp16);
        block_sync_lds();

        DEBUG_STMTS { print_lds(o_lds_window, "O_ACC"); }
#endif
        // store lse
        if constexpr(kStoreLSE)
        {
            auto lse = make_static_distributed_tensor<LSEDataType>(m.get_tile_distribution());

            constexpr auto lse_spans = decltype(lse)::get_distributed_spans();
            sweep_tile_span(lse_spans[number<0>{}], [&](auto idx0) {
                constexpr auto i_idx = make_tuple(idx0);
                lse(i_idx)           = m[i_idx] / C_LOG2E + log(l[i_idx]);
            });

            store_tile(lse_dram_window_tmp, tile_elementwise_in(lse_element_func, lse));
        }

        // finally, O
        constexpr auto o_spans = decltype(o_acc)::get_distributed_spans();

        sweep_tile_span(o_spans[number<0>{}], [&](auto idx0) {
            constexpr auto i_idx = make_tuple(idx0);
            const auto tmp       = [&]() {
                if constexpr(FmhaMask::IsMasking)
                {
                    return l[i_idx] == 0.f ? 0.f : 1 / l[i_idx];
                }
                else
                    return 1 / l[i_idx];
            }();
            sweep_tile_span(o_spans[number<1>{}], [&](auto idx1) {
                constexpr auto i_j_idx = make_tuple(idx0, idx1);
                o_acc(i_j_idx) *= tmp;
            });
        });

        o_acc = tile_elementwise_in(o_acc_element_func, o_acc);

        return o_acc;
    }

    template <typename QDramBlockWindowTmp,
              typename KDramBlockWindowTmp,
              typename VDramBlockWindowTmp,
              typename BiasDramBlockWindowTmp,
              typename RandValDramBlockWindowTmp,
              typename LSEDramBlockWindowTmp,
              typename PositionEncoding>
    CK_TILE_HOST_DEVICE auto
    operator()(const QDramBlockWindowTmp& q_dram_block_window_tmp,       // M0*K0 tile
               const KDramBlockWindowTmp& k_dram_block_window_tmp,       // N0*K0 tile
               const VDramBlockWindowTmp& v_dram_block_window_tmp,       // N1*K1 tile
               const BiasDramBlockWindowTmp& bias_dram_block_window_tmp, // M0*N0 tile
               RandValDramBlockWindowTmp& randval_dram_block_window_tmp, // M0*N0 tile
               LSEDramBlockWindowTmp& lse_dram_block_window_tmp,         // M0*1 tile
               FmhaMask mask,
               PositionEncoding position_encoding,
               float scale_s,
               void* smem_ptr,
               DropoutType& dropout) const
    {
        using namespace ck_tile;

        return operator()(q_dram_block_window_tmp,
                          identity{},
                          k_dram_block_window_tmp,
                          identity{},
                          v_dram_block_window_tmp,
                          identity{},
                          bias_dram_block_window_tmp,
                          identity{},
                          randval_dram_block_window_tmp,
                          lse_dram_block_window_tmp,
                          identity{},
                          identity{},
                          identity{},
                          identity{},
                          mask,
                          position_encoding,
                          scale_s,
                          smem_ptr,
                          dropout);
    }
};

template <typename FmhaPipeline_, typename EpiloguePipeline_>
struct FmhaFwdKernel
{
    using FmhaPipeline                            = ck_tile::remove_cvref_t<FmhaPipeline_>;
    using EpiloguePipeline                        = ck_tile::remove_cvref_t<EpiloguePipeline_>;
    static constexpr ck_tile::index_t kBlockSize  = FmhaPipeline::kBlockSize;
    static constexpr ck_tile::index_t kBlockPerCu = FmhaPipeline::kBlockPerCu;
    static_assert(kBlockPerCu > 0);
    static constexpr ck_tile::index_t kBlockPerCuInput = FmhaPipeline::Problem::kBlockPerCu;

    using QDataType    = ck_tile::remove_cvref_t<typename FmhaPipeline::QDataType>;
    using KDataType    = ck_tile::remove_cvref_t<typename FmhaPipeline::KDataType>;
    using VDataType    = ck_tile::remove_cvref_t<typename FmhaPipeline::VDataType>;
    using BiasDataType = ck_tile::remove_cvref_t<typename FmhaPipeline::BiasDataType>;
    using RandValOutputDataType =
        ck_tile::remove_cvref_t<typename FmhaPipeline::RandValOutputDataType>;
    using LSEDataType  = ck_tile::remove_cvref_t<typename FmhaPipeline::LSEDataType>;
    using ODataType    = ck_tile::remove_cvref_t<typename FmhaPipeline::ODataType>;
    using SaccDataType = ck_tile::remove_cvref_t<typename FmhaPipeline::SaccDataType>;

    using VLayout = ck_tile::remove_cvref_t<typename FmhaPipeline::VLayout>;

    static constexpr bool kIsGroupMode      = FmhaPipeline::kIsGroupMode;
    static constexpr bool kPadSeqLenQ       = FmhaPipeline::kPadSeqLenQ;
    static constexpr bool kPadSeqLenK       = FmhaPipeline::kPadSeqLenK;
    static constexpr bool kPadHeadDimQ      = FmhaPipeline::kPadHeadDimQ;
    static constexpr bool kPadHeadDimV      = FmhaPipeline::kPadHeadDimV;
    static constexpr bool kHasLogitsSoftCap = FmhaPipeline::kHasLogitsSoftCap;
    static constexpr auto BiasEnum          = FmhaPipeline::BiasEnum;
    static constexpr bool kStoreLSE         = FmhaPipeline::kStoreLSE;
    static constexpr bool kHasDropout       = FmhaPipeline::kHasDropout;
    static constexpr bool kDoFp8StaticQuant = FmhaPipeline::Problem::kDoFp8StaticQuant;
    static constexpr bool kSkipMinSeqlenQ   = FmhaPipeline::Problem::kSkipMinSeqlenQ;

    using FmhaMask                 = ck_tile::remove_cvref_t<typename FmhaPipeline::FmhaMask>;
    static constexpr bool kHasMask = FmhaMask::IsMasking;

    static constexpr bool kUseAsyncCopy = FmhaPipeline::Policy::AsyncCopy;

    // clang-format off
    template <typename T> struct t2s;
    template <> struct t2s<float> { static constexpr const char * name = "fp32"; };
    template <> struct t2s<ck_tile::fp16_t> { static constexpr const char * name = "fp16"; };
    template <> struct t2s<ck_tile::bf16_t> { static constexpr const char * name = "bf16"; };
    template <> struct t2s<ck_tile::fp8_t> { static constexpr const char * name = "fp8"; };
    template <> struct t2s<ck_tile::bf8_t> { static constexpr const char * name = "bf8"; };
    // clang-format on

    CK_TILE_HOST static std::string GetName()
    {
        using namespace ck_tile;

        // sync with generate.py
        // clang-format off
        using bfs = typename FmhaPipeline::BlockFmhaShape;
        using g0br = typename bfs::Gemm0BlockWarps;
        using g1br = typename bfs::Gemm1BlockWarps;
        using g0wt = typename bfs::Gemm0WarpTile;
        using g1wt = typename bfs::Gemm1WarpTile;
        #define _SS_  std::string
        #define _TS_  std::to_string
        auto pn = [&] () {
            std::string n;
            if (kPadSeqLenQ) n += "s";
            if (kPadSeqLenK) n += "sk";
            if (kPadHeadDimQ) n += "d";
            if (kPadHeadDimV) n += "dv";
            return n.empty() ? n : std::string("p") + n; }();
        return
            _SS_("fmha_fwd_d") + _TS_(bfs::kQKHeaddim) + "_" + _SS_(t2s<QDataType>::name) +
            "_" + (kIsGroupMode ? "group" : "batch") + "_"
            "b" + _TS_(bfs::kM0) + "x" + _TS_(bfs::kN0) + "x" + _TS_(bfs::kK0) + "x" +
                    _TS_(bfs::kN1) + "x" + _TS_(bfs::kK1) + "x" + _TS_(bfs::kQKHeaddim) + "_" +
            "r" + _TS_(g0br::at(ck_tile::number<0>{})) + "x" + _TS_(g0br::at(ck_tile::number<1>{})) + "x" + _TS_(g0br::at(ck_tile::number<2>{})) + "_" +
            "r" + _TS_(g1br::at(ck_tile::number<0>{})) + "x" + _TS_(g1br::at(ck_tile::number<1>{})) + "x" + _TS_(g1br::at(ck_tile::number<2>{})) + "_" +
            "w" + _TS_(g0wt::at(ck_tile::number<0>{})) + "x" + _TS_(g0wt::at(ck_tile::number<1>{})) + "x" + _TS_(g0wt::at(ck_tile::number<2>{})) + "_" +
            "w" + _TS_(g1wt::at(ck_tile::number<0>{})) + "x" + _TS_(g1wt::at(ck_tile::number<1>{})) + "x" + _TS_(g1wt::at(ck_tile::number<2>{})) + "_" +
            (kBlockPerCuInput == -1 ? "" : ("o" + _TS_(kBlockPerCu) + "_")) + _SS_(FmhaPipeline::name) + "_" +
            "v" + (std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor> ? "r" : "c") + (pn.empty() ? "_npad" : "_" + pn) +
            (kHasLogitsSoftCap ? "_logits" : "_nlogits" ) + (BiasEnum == BlockAttentionBiasEnum::NO_BIAS ? _SS_("_nbias") : (_SS_("_") + BlockAttentionBiasEnumToStr<BiasEnum>::name)) +
            (kHasMask ? "_" + _SS_(FmhaMask::name) : "_nmask") + (kStoreLSE ? "_lse" : "_nlse" ) + (kHasDropout ? "_dropout" : "_ndropout" ) + (kDoFp8StaticQuant ? "_squant" : "_nsquant" );
        #undef _SS_
        #undef _TS_
        // clang-format on
    }

    template <ck_tile::index_t I> // to avoid duplicated base class prblem, introduce an template
                                  // arg
    struct FmhaFwdEmptyKargs
    {
    };

    // kargs use aggregate initializer, so no constructor will provided
    // use inheritance to minimize karg size
    // user need to use MakeKargs() function to create kargs.
    struct FmhaFwdCommonKargs
    {
        const void* q_ptr;
        const void* k_ptr;
        const void* v_ptr;
        void* o_ptr;

        ck_tile::index_t seqlen_q;
        ck_tile::index_t seqlen_k;
        ck_tile::index_t hdim_q;
        ck_tile::index_t hdim_v;

        ck_tile::index_t num_head_q;
        // for MQA/GQA, nhead could be different. This parameter is nhead_q / nhead_k
        // if this param is larger than 1, indicate MQA/GQA case
        ck_tile::index_t nhead_ratio_qk;
        float scale_s;

        ck_tile::index_t stride_q;
        ck_tile::index_t stride_k;
        ck_tile::index_t stride_v;
        ck_tile::index_t stride_o;

        ck_tile::index_t nhead_stride_q;
        ck_tile::index_t nhead_stride_k;
        ck_tile::index_t nhead_stride_v;
        ck_tile::index_t nhead_stride_o;
    };

    struct FmhaFwdLogitsSoftCapKargs
    {
        FmhaFwdLogitsSoftCapKargs() = default;

        void init_logits_soft_cap(float logits_soft_cap_)
        {
            if(0 < logits_soft_cap_)
            {
                logits_soft_cap     = logits_soft_cap_;
                logits_soft_cap_rcp = 1.f / logits_soft_cap;
            }
            else
            {
                logits_soft_cap     = 0.f;
                logits_soft_cap_rcp = 0.f;
            }
        }

        float logits_soft_cap;
        float logits_soft_cap_rcp;
    };

    struct FmhaFwdCommonBiasKargs
    {
        const void* bias_ptr               = nullptr;
        ck_tile::index_t stride_bias       = 0;
        ck_tile::index_t nhead_stride_bias = 0;
    };

    struct FmhaFwdBatchModeBiasKargs : FmhaFwdCommonBiasKargs
    {
        ck_tile::index_t batch_stride_bias = 0;
    };

    struct FmhaFwdAlibiKargs
    {
        // alibi is batch*nhead*1, no matter in batch/group mode, they are the same
        const void* alibi_slope_ptr;
        ck_tile::index_t alibi_slope_stride; // stride in batch, or 0 for all batch share same slope
    };

    struct FmhaFwdMaskKargs
    {
        // ck_tile::index_t window_size_left, window_size_right;
        ck_tile::index_t window_size_left, window_size_right;
        ck_tile::GenericAttentionMaskEnum mask_type;
    };

    struct FmhaFwdFp8StaticQuantKargs
    {
        float scale_p;
        float scale_o;
    };

    struct FmhaFwdCommonLSEKargs
    {
        void* lse_ptr                     = nullptr;
        ck_tile::index_t nhead_stride_lse = 0;
        ck_tile::index_t batch_stride_lse = 0;
    };

    struct FmhaFwdDropoutSeedOffset
    {
        template <typename T>
        union ValueOrPointer
        {
            T val;
            const T* ptr;
        };

        ValueOrPointer<uint64_t> drop_seed;
        ValueOrPointer<uint64_t> drop_offset;
        bool is_drop_seed_offset_from_host;
    };

    struct FmhaFwdCommonDropoutKargs : FmhaFwdDropoutSeedOffset
    {
        void init_dropout(float p_drop, uint64_t seed, uint64_t offset)
        {
            float p_undrop = 1.0 - p_drop;
            p_undrop_in_uint8_t =
                uint8_t(std::floor(p_undrop * std::numeric_limits<uint8_t>::max()));
            rp_undrop = 1.0 / p_undrop;

            this->drop_seed.val                 = seed;
            this->drop_offset.val               = offset;
            this->is_drop_seed_offset_from_host = true;
        }

        void init_dropout(float p_drop, const uint64_t* seed_ptr, const uint64_t* offset_ptr)
        {
            float p_undrop = 1.0 - p_drop;
            p_undrop_in_uint8_t =
                uint8_t(std::floor(p_undrop * std::numeric_limits<uint8_t>::max()));
            rp_undrop = 1.0 / p_undrop;

            this->drop_seed.ptr                 = seed_ptr;
            this->drop_offset.ptr               = offset_ptr;
            this->is_drop_seed_offset_from_host = false;
        }

        float rp_undrop             = 1;
        uint8_t p_undrop_in_uint8_t = std::numeric_limits<uint8_t>::max();
        bool is_store_randval       = false;
        void* rand_val_ptr          = nullptr;

        ck_tile::index_t stride_randval       = 0;
        ck_tile::index_t nhead_stride_randval = 0;
    };

    struct FmhaFwdBatchModeDropoutKargs : FmhaFwdCommonDropoutKargs
    {
        ck_tile::index_t batch_stride_randval = 0;
    };

    struct FmhaFwdSkipMinSeqlenQKargs
    {
        ck_tile::index_t min_seqlen_q = 0;
    };

    struct FmhaFwdBatchModeKargs
        : FmhaFwdCommonKargs,
          std::conditional_t<BiasEnum == ck_tile::BlockAttentionBiasEnum::ELEMENTWISE_BIAS,
                             FmhaFwdBatchModeBiasKargs,
                             std::conditional_t<BiasEnum == ck_tile::BlockAttentionBiasEnum::ALIBI,
                                                FmhaFwdAlibiKargs,
                                                FmhaFwdEmptyKargs<0>>>,
          std::conditional_t<kHasMask, FmhaFwdMaskKargs, FmhaFwdEmptyKargs<1>>,
          std::conditional_t<kStoreLSE, FmhaFwdCommonLSEKargs, FmhaFwdEmptyKargs<2>>,
          std::conditional_t<kDoFp8StaticQuant, FmhaFwdFp8StaticQuantKargs, FmhaFwdEmptyKargs<3>>,
          std::conditional_t<kHasDropout, FmhaFwdBatchModeDropoutKargs, FmhaFwdEmptyKargs<4>>,
          std::conditional_t<kHasLogitsSoftCap, FmhaFwdLogitsSoftCapKargs, FmhaFwdEmptyKargs<5>>
    {
        ck_tile::index_t batch_stride_q;
        ck_tile::index_t batch_stride_k;
        ck_tile::index_t batch_stride_v;
        ck_tile::index_t batch_stride_o;
    };

    struct FmhaFwdGroupModeKargs
        : FmhaFwdCommonKargs,
          std::conditional_t<BiasEnum == ck_tile::BlockAttentionBiasEnum::ELEMENTWISE_BIAS,
                             FmhaFwdCommonBiasKargs,
                             std::conditional_t<BiasEnum == ck_tile::BlockAttentionBiasEnum::ALIBI,
                                                FmhaFwdAlibiKargs,
                                                FmhaFwdEmptyKargs<0>>>,
          std::conditional_t<kHasMask, FmhaFwdMaskKargs, FmhaFwdEmptyKargs<1>>,
          std::conditional_t<kStoreLSE, FmhaFwdCommonLSEKargs, FmhaFwdEmptyKargs<2>>,
          std::conditional_t<kDoFp8StaticQuant, FmhaFwdFp8StaticQuantKargs, FmhaFwdEmptyKargs<3>>,
          std::conditional_t<kHasDropout, FmhaFwdCommonDropoutKargs, FmhaFwdEmptyKargs<4>>,
          std::conditional_t<kHasLogitsSoftCap, FmhaFwdLogitsSoftCapKargs, FmhaFwdEmptyKargs<5>>,
          std::conditional_t<kSkipMinSeqlenQ, FmhaFwdSkipMinSeqlenQKargs, FmhaFwdEmptyKargs<6>>
    {
        const int32_t* seqstart_q_ptr;
        const int32_t* seqstart_k_ptr;
        const int32_t* seqlen_k_ptr;
    };

    using Kargs = std::conditional_t<kIsGroupMode, FmhaFwdGroupModeKargs, FmhaFwdBatchModeKargs>;

    struct BlockIndices
    {
        ck_tile::index_t batch_idx;
        ck_tile::index_t qo_head_idx;
        ck_tile::index_t kv_head_idx;
    };

    template <bool Cond = !kIsGroupMode>
    CK_TILE_HOST static constexpr std::enable_if_t<Cond, Kargs>
    MakeKargsImpl(const void* q_ptr,
                  const void* k_ptr,
                  const void* v_ptr,
                  const void* bias_ptr,
                  void* rand_val_ptr,
                  void* lse_ptr,
                  void* o_ptr,
                  ck_tile::index_t seqlen_q,
                  ck_tile::index_t seqlen_k,
                  ck_tile::index_t hdim_q,
                  ck_tile::index_t hdim_v,
                  ck_tile::index_t num_head_q,
                  ck_tile::index_t nhead_ratio_qk,
                  float scale_s,
                  float scale_p,
                  float scale_o,
                  float logits_soft_cap,
                  ck_tile::index_t stride_q,
                  ck_tile::index_t stride_k,
                  ck_tile::index_t stride_v,
                  ck_tile::index_t stride_bias,
                  ck_tile::index_t stride_randval,
                  ck_tile::index_t stride_o,
                  ck_tile::index_t nhead_stride_q,
                  ck_tile::index_t nhead_stride_k,
                  ck_tile::index_t nhead_stride_v,
                  ck_tile::index_t nhead_stride_bias,
                  ck_tile::index_t nhead_stride_randval,
                  ck_tile::index_t nhead_stride_lse,
                  ck_tile::index_t nhead_stride_o,
                  ck_tile::index_t batch_stride_q,
                  ck_tile::index_t batch_stride_k,
                  ck_tile::index_t batch_stride_v,
                  ck_tile::index_t batch_stride_bias,
                  ck_tile::index_t batch_stride_randval,
                  ck_tile::index_t batch_stride_lse,
                  ck_tile::index_t batch_stride_o,
                  ck_tile::index_t window_size_left,
                  ck_tile::index_t window_size_right,
                  ck_tile::index_t mask_type,
                  float p_drop,
                  bool s_randval,
                  std::variant<std::pair<uint64_t, uint64_t>, std::pair<const void*, const void*>>
                      drop_seed_offset)
    {
        Kargs kargs{{q_ptr,
                     k_ptr,
                     v_ptr,
                     o_ptr,
                     seqlen_q,
                     seqlen_k,
                     hdim_q,
                     hdim_v,
                     num_head_q,
                     nhead_ratio_qk,
                     static_cast<float>(scale_s * ck_tile::log2e_v<>),
                     stride_q,
                     stride_k,
                     stride_v,
                     stride_o,
                     nhead_stride_q,
                     nhead_stride_k,
                     nhead_stride_v,
                     nhead_stride_o}, // args for common karg
                    {},               // placeholder for bias
                    {},               // placeholder for mask
                    {},               // placeholder for lse
                    {},               // placeholder for fp8_static_quant args
                    {},               // placeholder for dropout
                    {},               // placeholder for logits_soft_cap
                    batch_stride_q,
                    batch_stride_k,
                    batch_stride_v,
                    batch_stride_o};

        if constexpr(BiasEnum == ck_tile::BlockAttentionBiasEnum::ELEMENTWISE_BIAS)
        {
            kargs.bias_ptr          = bias_ptr;
            kargs.stride_bias       = stride_bias;
            kargs.nhead_stride_bias = nhead_stride_bias;
            kargs.batch_stride_bias = batch_stride_bias;
        }
        else if constexpr(BiasEnum == ck_tile::BlockAttentionBiasEnum::ALIBI)
        {
            kargs.alibi_slope_ptr    = bias_ptr;
            kargs.alibi_slope_stride = stride_bias;
        }
        if constexpr(kHasMask)
        {
            kargs.window_size_left  = window_size_left;
            kargs.window_size_right = window_size_right;
            kargs.mask_type         = static_cast<ck_tile::GenericAttentionMaskEnum>(mask_type);
        }
        if constexpr(kStoreLSE)
        {
            kargs.lse_ptr          = lse_ptr;
            kargs.nhead_stride_lse = nhead_stride_lse;
            kargs.batch_stride_lse = batch_stride_lse;
        }
        if constexpr(kDoFp8StaticQuant)
        {
            kargs.scale_p = scale_p;
            kargs.scale_o = scale_o;
        }
        if constexpr(kHasDropout)
        {
            if(drop_seed_offset.index() == 0) // seed & offset come from host
            {
                const auto& [seed, offset] = std::get<0>(drop_seed_offset);
                kargs.init_dropout(p_drop, seed, offset);
            }
            else // seed & offset come from device
            {
                const auto& [seed_ptr, offset_ptr] = std::get<1>(drop_seed_offset);
                kargs.init_dropout(p_drop,
                                   reinterpret_cast<const uint64_t*>(seed_ptr),
                                   reinterpret_cast<const uint64_t*>(offset_ptr));
            }

            kargs.rand_val_ptr         = rand_val_ptr;
            kargs.stride_randval       = stride_randval;
            kargs.nhead_stride_randval = nhead_stride_randval;
            kargs.batch_stride_randval = batch_stride_randval;
            kargs.is_store_randval     = s_randval;
        }
        if constexpr(kHasLogitsSoftCap)
        {
            kargs.init_logits_soft_cap(logits_soft_cap);
        }

        return kargs;
    }

    // std::variant<> can't take in a list initializer, overload for backward compatibility
    template <bool Cond = !kIsGroupMode>
    CK_TILE_HOST static constexpr std::enable_if_t<Cond, Kargs>
    MakeKargs(const void* q_ptr,
              const void* k_ptr,
              const void* v_ptr,
              const void* bias_ptr,
              void* rand_val_ptr,
              void* lse_ptr,
              void* o_ptr,
              ck_tile::index_t seqlen_q,
              ck_tile::index_t seqlen_k,
              ck_tile::index_t hdim_q,
              ck_tile::index_t hdim_v,
              ck_tile::index_t num_head_q,
              ck_tile::index_t nhead_ratio_qk,
              float scale_s,
              float scale_p,
              float scale_o,
              float logits_soft_cap,
              ck_tile::index_t stride_q,
              ck_tile::index_t stride_k,
              ck_tile::index_t stride_v,
              ck_tile::index_t stride_bias,
              ck_tile::index_t stride_randval,
              ck_tile::index_t stride_o,
              ck_tile::index_t nhead_stride_q,
              ck_tile::index_t nhead_stride_k,
              ck_tile::index_t nhead_stride_v,
              ck_tile::index_t nhead_stride_bias,
              ck_tile::index_t nhead_stride_randval,
              ck_tile::index_t nhead_stride_lse,
              ck_tile::index_t nhead_stride_o,
              ck_tile::index_t batch_stride_q,
              ck_tile::index_t batch_stride_k,
              ck_tile::index_t batch_stride_v,
              ck_tile::index_t batch_stride_bias,
              ck_tile::index_t batch_stride_randval,
              ck_tile::index_t batch_stride_lse,
              ck_tile::index_t batch_stride_o,
              ck_tile::index_t window_size_left,
              ck_tile::index_t window_size_right,
              ck_tile::index_t mask_type,
              float p_drop,
              bool s_randval,
              const std::tuple<uint64_t, uint64_t>& drop_seed_offset)
    {
        return MakeKargsImpl(
            q_ptr,
            k_ptr,
            v_ptr,
            bias_ptr,
            rand_val_ptr,
            lse_ptr,
            o_ptr,
            seqlen_q,
            seqlen_k,
            hdim_q,
            hdim_v,
            num_head_q,
            nhead_ratio_qk,
            scale_s,
            scale_p,
            scale_o,
            logits_soft_cap,
            stride_q,
            stride_k,
            stride_v,
            stride_bias,
            stride_randval,
            stride_o,
            nhead_stride_q,
            nhead_stride_k,
            nhead_stride_v,
            nhead_stride_bias,
            nhead_stride_randval,
            nhead_stride_lse,
            nhead_stride_o,
            batch_stride_q,
            batch_stride_k,
            batch_stride_v,
            batch_stride_bias,
            batch_stride_randval,
            batch_stride_lse,
            batch_stride_o,
            window_size_left,
            window_size_right,
            mask_type,
            p_drop,
            s_randval,
            std::make_pair(std::get<0>(drop_seed_offset), std::get<1>(drop_seed_offset)));
    }

    // std::variant<> can't take in a list initializer, overload for backward compatibility
    template <bool Cond = !kIsGroupMode>
    CK_TILE_HOST static constexpr std::enable_if_t<Cond, Kargs>
    MakeKargs(const void* q_ptr,
              const void* k_ptr,
              const void* v_ptr,
              const void* bias_ptr,
              void* rand_val_ptr,
              void* lse_ptr,
              void* o_ptr,
              ck_tile::index_t seqlen_q,
              ck_tile::index_t seqlen_k,
              ck_tile::index_t hdim_q,
              ck_tile::index_t hdim_v,
              ck_tile::index_t num_head_q,
              ck_tile::index_t nhead_ratio_qk,
              float scale_s,
              float scale_p,
              float scale_o,
              float logits_soft_cap,
              ck_tile::index_t stride_q,
              ck_tile::index_t stride_k,
              ck_tile::index_t stride_v,
              ck_tile::index_t stride_bias,
              ck_tile::index_t stride_randval,
              ck_tile::index_t stride_o,
              ck_tile::index_t nhead_stride_q,
              ck_tile::index_t nhead_stride_k,
              ck_tile::index_t nhead_stride_v,
              ck_tile::index_t nhead_stride_bias,
              ck_tile::index_t nhead_stride_randval,
              ck_tile::index_t nhead_stride_lse,
              ck_tile::index_t nhead_stride_o,
              ck_tile::index_t batch_stride_q,
              ck_tile::index_t batch_stride_k,
              ck_tile::index_t batch_stride_v,
              ck_tile::index_t batch_stride_bias,
              ck_tile::index_t batch_stride_randval,
              ck_tile::index_t batch_stride_lse,
              ck_tile::index_t batch_stride_o,
              ck_tile::index_t window_size_left,
              ck_tile::index_t window_size_right,
              ck_tile::index_t mask_type,
              float p_drop,
              bool s_randval,
              const std::tuple<const void*, const void*>& drop_seed_offset)
    {
        return MakeKargsImpl(
            q_ptr,
            k_ptr,
            v_ptr,
            bias_ptr,
            rand_val_ptr,
            lse_ptr,
            o_ptr,
            seqlen_q,
            seqlen_k,
            hdim_q,
            hdim_v,
            num_head_q,
            nhead_ratio_qk,
            scale_s,
            scale_p,
            scale_o,
            logits_soft_cap,
            stride_q,
            stride_k,
            stride_v,
            stride_bias,
            stride_randval,
            stride_o,
            nhead_stride_q,
            nhead_stride_k,
            nhead_stride_v,
            nhead_stride_bias,
            nhead_stride_randval,
            nhead_stride_lse,
            nhead_stride_o,
            batch_stride_q,
            batch_stride_k,
            batch_stride_v,
            batch_stride_bias,
            batch_stride_randval,
            batch_stride_lse,
            batch_stride_o,
            window_size_left,
            window_size_right,
            mask_type,
            p_drop,
            s_randval,
            std::make_pair(std::get<0>(drop_seed_offset), std::get<1>(drop_seed_offset)));
    }

    template <bool Cond = kIsGroupMode>
    CK_TILE_HOST static constexpr std::enable_if_t<Cond, Kargs>
    MakeKargsImpl(const void* q_ptr,
                  const void* k_ptr,
                  const void* v_ptr,
                  const void* bias_ptr,
                  void* rand_val_ptr,
                  void* lse_ptr,
                  void* o_ptr,
                  const void* seqstart_q_ptr,
                  const void* seqstart_k_ptr,
                  const void* seqlen_k_ptr,
                  ck_tile::index_t hdim_q,
                  ck_tile::index_t hdim_v,
                  ck_tile::index_t num_head_q,
                  ck_tile::index_t nhead_ratio_qk,
                  float scale_s,
                  float scale_p,
                  float scale_o,
                  float logits_soft_cap,
                  ck_tile::index_t stride_q,
                  ck_tile::index_t stride_k,
                  ck_tile::index_t stride_v,
                  ck_tile::index_t stride_bias,
                  ck_tile::index_t stride_randval,
                  ck_tile::index_t stride_o,
                  ck_tile::index_t nhead_stride_q,
                  ck_tile::index_t nhead_stride_k,
                  ck_tile::index_t nhead_stride_v,
                  ck_tile::index_t nhead_stride_bias,
                  ck_tile::index_t nhead_stride_randval,
                  ck_tile::index_t nhead_stride_lse,
                  ck_tile::index_t nhead_stride_o,
                  ck_tile::index_t window_size_left,
                  ck_tile::index_t window_size_right,
                  ck_tile::index_t mask_type,
                  ck_tile::index_t min_seqlen_q,
                  float p_drop,
                  bool s_randval,
                  std::variant<std::pair<uint64_t, uint64_t>, std::pair<const void*, const void*>>
                      drop_seed_offset)
    {
        Kargs kargs{{q_ptr,
                     k_ptr,
                     v_ptr,
                     o_ptr,
                     -1, // seqlen will be updated by another pointer
                     -1, //
                     hdim_q,
                     hdim_v,
                     num_head_q,
                     nhead_ratio_qk,
                     static_cast<float>(scale_s * ck_tile::log2e_v<>),
                     stride_q,
                     stride_k,
                     stride_v,
                     stride_o,
                     nhead_stride_q,
                     nhead_stride_k,
                     nhead_stride_v,
                     nhead_stride_o}, // args for common karg
                    {},               // placeholder for bias
                    {},               // placeholder for mask
                    {},               // placeholder for lse
                    {},               // placeholder for fp8_static_quant args
                    {},               // placeholder for dropout
                    {},               // placeholder for logits_soft_cap
                    {},               // placeholder for min_seqlen_q
                    reinterpret_cast<const int32_t*>(seqstart_q_ptr),
                    reinterpret_cast<const int32_t*>(seqstart_k_ptr),
                    reinterpret_cast<const int32_t*>(seqlen_k_ptr)};

        if constexpr(BiasEnum == ck_tile::BlockAttentionBiasEnum::ELEMENTWISE_BIAS)
        {
            kargs.bias_ptr          = bias_ptr;
            kargs.stride_bias       = stride_bias;
            kargs.nhead_stride_bias = nhead_stride_bias;
        }
        else if constexpr(BiasEnum == ck_tile::BlockAttentionBiasEnum::ALIBI)
        {
            kargs.alibi_slope_ptr    = bias_ptr;
            kargs.alibi_slope_stride = stride_bias;
        }
        if constexpr(kHasMask)
        {
            kargs.window_size_left  = window_size_left;
            kargs.window_size_right = window_size_right;
            kargs.mask_type         = static_cast<ck_tile::GenericAttentionMaskEnum>(mask_type);
        }
        if constexpr(kStoreLSE)
        {
            kargs.lse_ptr          = lse_ptr;
            kargs.nhead_stride_lse = nhead_stride_lse;
        }
        if constexpr(kDoFp8StaticQuant)
        {
            kargs.scale_p = scale_p;
            kargs.scale_o = scale_o;
        }
        if constexpr(kHasDropout)
        {
            if(drop_seed_offset.index() == 0) // seed & offset come from host
            {
                const auto& [seed, offset] = std::get<0>(drop_seed_offset);
                kargs.init_dropout(p_drop, seed, offset);
            }
            else // seed & offset come from device
            {
                const auto& [seed_ptr, offset_ptr] = std::get<1>(drop_seed_offset);
                kargs.init_dropout(p_drop,
                                   reinterpret_cast<const uint64_t*>(seed_ptr),
                                   reinterpret_cast<const uint64_t*>(offset_ptr));
            }

            kargs.rand_val_ptr         = rand_val_ptr;
            kargs.stride_randval       = stride_randval;
            kargs.nhead_stride_randval = nhead_stride_randval;
            kargs.is_store_randval     = s_randval;
        }
        if constexpr(kHasLogitsSoftCap)
        {
            kargs.init_logits_soft_cap(logits_soft_cap);
        }
        if constexpr(kSkipMinSeqlenQ)
        {
            kargs.min_seqlen_q = min_seqlen_q;
        }

        return kargs;
    }

    // std::variant<> can't take in a list initializer, overload for backward compatibility
    template <bool Cond = kIsGroupMode>
    CK_TILE_HOST static constexpr std::enable_if_t<Cond, Kargs>
    MakeKargs(const void* q_ptr,
              const void* k_ptr,
              const void* v_ptr,
              const void* bias_ptr,
              void* rand_val_ptr,
              void* lse_ptr,
              void* o_ptr,
              const void* seqstart_q_ptr,
              const void* seqstart_k_ptr,
              const void* seqlen_k_ptr,
              ck_tile::index_t hdim_q,
              ck_tile::index_t hdim_v,
              ck_tile::index_t num_head_q,
              ck_tile::index_t nhead_ratio_qk,
              float scale_s,
              float scale_p,
              float scale_o,
              float logits_soft_cap,
              ck_tile::index_t stride_q,
              ck_tile::index_t stride_k,
              ck_tile::index_t stride_v,
              ck_tile::index_t stride_bias,
              ck_tile::index_t stride_randval,
              ck_tile::index_t stride_o,
              ck_tile::index_t nhead_stride_q,
              ck_tile::index_t nhead_stride_k,
              ck_tile::index_t nhead_stride_v,
              ck_tile::index_t nhead_stride_bias,
              ck_tile::index_t nhead_stride_randval,
              ck_tile::index_t nhead_stride_lse,
              ck_tile::index_t nhead_stride_o,
              ck_tile::index_t window_size_left,
              ck_tile::index_t window_size_right,
              ck_tile::index_t mask_type,
              float p_drop,
              bool s_randval,
              const std::tuple<uint64_t, uint64_t>& drop_seed_offset)
    {
        return MakeKargsImpl(
            q_ptr,
            k_ptr,
            v_ptr,
            bias_ptr,
            rand_val_ptr,
            lse_ptr,
            o_ptr,
            seqstart_q_ptr,
            seqstart_k_ptr,
            seqlen_k_ptr,
            hdim_q,
            hdim_v,
            num_head_q,
            nhead_ratio_qk,
            scale_s,
            scale_p,
            scale_o,
            logits_soft_cap,
            stride_q,
            stride_k,
            stride_v,
            stride_bias,
            stride_randval,
            stride_o,
            nhead_stride_q,
            nhead_stride_k,
            nhead_stride_v,
            nhead_stride_bias,
            nhead_stride_randval,
            nhead_stride_lse,
            nhead_stride_o,
            window_size_left,
            window_size_right,
            mask_type,
            p_drop,
            s_randval,
            std::make_pair(std::get<0>(drop_seed_offset), std::get<1>(drop_seed_offset)));
    }

    // std::variant<> can't take in a list initializer, overload for backward compatibility
    template <bool Cond = kIsGroupMode>
    CK_TILE_HOST static constexpr std::enable_if_t<Cond, Kargs>
    MakeKargs(const void* q_ptr,
              const void* k_ptr,
              const void* v_ptr,
              const void* bias_ptr,
              void* rand_val_ptr,
              void* lse_ptr,
              void* o_ptr,
              const void* seqstart_q_ptr,
              const void* seqstart_k_ptr,
              const void* seqlen_k_ptr,
              ck_tile::index_t hdim_q,
              ck_tile::index_t hdim_v,
              ck_tile::index_t num_head_q,
              ck_tile::index_t nhead_ratio_qk,
              float scale_s,
              float scale_p,
              float scale_o,
              float logits_soft_cap,
              ck_tile::index_t stride_q,
              ck_tile::index_t stride_k,
              ck_tile::index_t stride_v,
              ck_tile::index_t stride_bias,
              ck_tile::index_t stride_randval,
              ck_tile::index_t stride_o,
              ck_tile::index_t nhead_stride_q,
              ck_tile::index_t nhead_stride_k,
              ck_tile::index_t nhead_stride_v,
              ck_tile::index_t nhead_stride_bias,
              ck_tile::index_t nhead_stride_randval,
              ck_tile::index_t nhead_stride_lse,
              ck_tile::index_t nhead_stride_o,
              ck_tile::index_t window_size_left,
              ck_tile::index_t window_size_right,
              ck_tile::index_t mask_type,
              float p_drop,
              bool s_randval,
              const std::tuple<const void*, const void*>& drop_seed_offset)
    {
        return MakeKargsImpl(
            q_ptr,
            k_ptr,
            v_ptr,
            bias_ptr,
            rand_val_ptr,
            lse_ptr,
            o_ptr,
            seqstart_q_ptr,
            seqstart_k_ptr,
            seqlen_k_ptr,
            hdim_q,
            hdim_v,
            num_head_q,
            nhead_ratio_qk,
            scale_s,
            scale_p,
            scale_o,
            logits_soft_cap,
            stride_q,
            stride_k,
            stride_v,
            stride_bias,
            stride_randval,
            stride_o,
            nhead_stride_q,
            nhead_stride_k,
            nhead_stride_v,
            nhead_stride_bias,
            nhead_stride_randval,
            nhead_stride_lse,
            nhead_stride_o,
            window_size_left,
            window_size_right,
            mask_type,
            p_drop,
            s_randval,
            std::make_pair(std::get<0>(drop_seed_offset), std::get<1>(drop_seed_offset)));
    }

    CK_TILE_HOST static constexpr auto GridSize(ck_tile::index_t batch_size_,
                                                ck_tile::index_t nhead_,
                                                ck_tile::index_t seqlen_q_,
                                                ck_tile::index_t hdim_v_,
                                                bool has_padded_seqlen_k = false)
    {
        // has_padded_seqlen_k is determined by checking (seqlen_k_ptr != nullptr)
        if(has_padded_seqlen_k)
        {
            // TODO: this may need tuning
            return dim3(nhead_,
                        batch_size_,
                        ck_tile::integer_divide_ceil(seqlen_q_, FmhaPipeline::kM0) *
                            ck_tile::integer_divide_ceil(hdim_v_, FmhaPipeline::kN1));
        }
        else
        {
            // TODO: this may need tuning
            return dim3(ck_tile::integer_divide_ceil(seqlen_q_, FmhaPipeline::kM0) *
                            ck_tile::integer_divide_ceil(hdim_v_, FmhaPipeline::kN1),
                        nhead_,
                        batch_size_);
        }
    }

    CK_TILE_DEVICE static constexpr auto GetTileIndex(const Kargs& kargs)
    {
        using namespace ck_tile;

        bool has_padded_seqlen_k = false;

        if constexpr(kIsGroupMode)
            has_padded_seqlen_k = (kargs.seqlen_k_ptr != nullptr);

        if(has_padded_seqlen_k)
        {
            // const index_t num_tile_m0 = seqlen_q / kM0;
            const index_t num_tile_n1 =
                ck_tile::integer_divide_ceil(kargs.hdim_v, FmhaPipeline::kN1);

            const index_t i_block = blockIdx.z;
            const index_t i_nhead = blockIdx.x;
            const index_t i_batch = blockIdx.y;

            const auto f = [](index_t dividend, index_t divisor) {
                index_t quotient = dividend / divisor;
                index_t modulus  = dividend - quotient * divisor;
                return ck_tile::make_tuple(quotient, modulus);
            };

            const auto [i_tile_m, i_tile_n] = f(i_block, num_tile_n1);

            if constexpr(kHasMask)
            {
                // assume that num_tile_n1 is always 1
                return ck_tile::make_tuple(gridDim.z - 1 - i_tile_m, i_tile_n, i_nhead, i_batch);
            }
            else
            {
                return ck_tile::make_tuple(i_tile_m, i_tile_n, i_nhead, i_batch);
            }
        }
        else
        {
            // const index_t num_tile_m0 = seqlen_q / kM0;
            const index_t num_tile_n1 =
                ck_tile::integer_divide_ceil(kargs.hdim_v, FmhaPipeline::kN1);

            const index_t i_block = blockIdx.x;
            const index_t i_nhead = blockIdx.y;
            const index_t i_batch = blockIdx.z;

            const auto f = [](index_t dividend, index_t divisor) {
                index_t quotient = dividend / divisor;
                index_t modulus  = dividend - quotient * divisor;
                return ck_tile::make_tuple(quotient, modulus);
            };

            const auto [i_tile_m, i_tile_n] = f(i_block, num_tile_n1);

            if constexpr(kHasMask)
            {
                // assume that num_tile_n1 is always 1
                return ck_tile::make_tuple(gridDim.x - 1 - i_tile_m, i_tile_n, i_nhead, i_batch);
            }
            else
            {
                return ck_tile::make_tuple(i_tile_m, i_tile_n, i_nhead, i_batch);
            }
        }
    }

    CK_TILE_HOST static constexpr auto BlockSize() { return dim3(kBlockSize); }

    CK_TILE_HOST_DEVICE static constexpr ck_tile::index_t GetSmemSize()
    {
        return ck_tile::max(FmhaPipeline::GetSmemSize(), EpiloguePipeline::GetSmemSize());
    }

    CK_TILE_DEVICE void operator()(Kargs kargs) const
    {
        using namespace ck_tile;

        // allocate LDS
        __shared__ char smem_ptr[GetSmemSize()];

        // divide problem
        const auto [i_tile_m, i_tile_n, i_nhead, i_batch] = GetTileIndex(kargs);

        const index_t i_m0 = __builtin_amdgcn_readfirstlane(i_tile_m * FmhaPipeline::kM0);
        const index_t i_n1 = __builtin_amdgcn_readfirstlane(i_tile_n * FmhaPipeline::kN1);

        long_index_t batch_offset_q       = 0;
        long_index_t batch_offset_k       = 0;
        long_index_t batch_offset_v       = 0;
        long_index_t batch_offset_bias    = 0;
        long_index_t batch_offset_randval = 0;
        long_index_t batch_offset_lse     = 0;
        long_index_t batch_offset_o       = 0;

        if constexpr(kIsGroupMode)
        {
            // get starting offset for each batch
            const long_index_t query_start = kargs.seqstart_q_ptr[i_batch];
            const long_index_t key_start   = kargs.seqstart_k_ptr[i_batch];

            batch_offset_q = query_start * kargs.stride_q;
            batch_offset_k = key_start * kargs.stride_k;
            if constexpr(std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor>)
            {
                batch_offset_v = key_start * kargs.stride_v;
            }
            else
            {
                batch_offset_v = key_start;
            }
            if constexpr(BiasEnum == BlockAttentionBiasEnum::ELEMENTWISE_BIAS)
            {
                batch_offset_bias = query_start * kargs.stride_bias;
            }
            if constexpr(kStoreLSE)
            {
                batch_offset_lse = query_start;
            }
            if constexpr(kHasDropout)
            {
                batch_offset_randval = query_start * kargs.stride_randval;
            }
            batch_offset_o = query_start * kargs.stride_o;

            // get real # queries & # keys under group mode
            const auto adjusted_seqstart_q_ptr = kargs.seqstart_q_ptr + i_batch;
            kargs.seqlen_q = adjusted_seqstart_q_ptr[1] - adjusted_seqstart_q_ptr[0];

            if constexpr(kSkipMinSeqlenQ)
            {
                if(kargs.seqlen_q <= kargs.min_seqlen_q)
                {
                    return;
                }
            }

            // # of required blocks is different in each groups, terminate unnecessary blocks
            // earlier
            if(kargs.seqlen_q <= i_m0)
            {
                return;
            }

            if(kargs.seqlen_k_ptr != nullptr)
            {
                kargs.seqlen_k = kargs.seqlen_k_ptr[i_batch];
            }
            else
            {
                const auto adjusted_seqstart_k_ptr = kargs.seqstart_k_ptr + i_batch;
                kargs.seqlen_k = adjusted_seqstart_k_ptr[1] - adjusted_seqstart_k_ptr[0];
            }
        }
        else
        {
            batch_offset_q = static_cast<long_index_t>(i_batch) * kargs.batch_stride_q;
            batch_offset_k = static_cast<long_index_t>(i_batch) * kargs.batch_stride_k;
            batch_offset_v = static_cast<long_index_t>(i_batch) * kargs.batch_stride_v;
            if constexpr(BiasEnum == BlockAttentionBiasEnum::ELEMENTWISE_BIAS)
            {
                batch_offset_bias = static_cast<long_index_t>(i_batch) * kargs.batch_stride_bias;
            }
            if constexpr(kStoreLSE)
            {
                batch_offset_lse = static_cast<long_index_t>(i_batch) * kargs.batch_stride_lse;
            }
            if constexpr(kHasDropout)
            {
                batch_offset_randval =
                    static_cast<long_index_t>(i_batch) * kargs.batch_stride_randval;
            }
            batch_offset_o = static_cast<long_index_t>(i_batch) * kargs.batch_stride_o;
        }

        // for simplicity, batch stride we just modify the pointer
        const QDataType* q_ptr = reinterpret_cast<const QDataType*>(kargs.q_ptr) +
                                 static_cast<long_index_t>(i_nhead) * kargs.nhead_stride_q +
                                 batch_offset_q;
        const KDataType* k_ptr =
            reinterpret_cast<const KDataType*>(kargs.k_ptr) +
            static_cast<long_index_t>(i_nhead / kargs.nhead_ratio_qk) * kargs.nhead_stride_k +
            batch_offset_k;
        const VDataType* v_ptr =
            reinterpret_cast<const VDataType*>(kargs.v_ptr) +
            static_cast<long_index_t>(i_nhead / kargs.nhead_ratio_qk) * kargs.nhead_stride_v +
            batch_offset_v;
        ODataType* o_ptr = reinterpret_cast<ODataType*>(kargs.o_ptr) +
                           static_cast<long_index_t>(i_nhead) * kargs.nhead_stride_o +
                           batch_offset_o;

        // Q/K/V DRAM and DRAM window
        const auto q_dram = [&]() {
            const auto q_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                q_ptr,
                make_tuple(kargs.seqlen_q, kargs.hdim_q),
                make_tuple(kargs.stride_q, 1),
                number<FmhaPipeline::kAlignmentQ>{},
                number<1>{});
            if constexpr(FmhaPipeline::kQLoadOnce)
            {
                return pad_tensor_view(
                    q_dram_naive,
                    make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kSubQKHeaddim>{}),
                    sequence<kPadSeqLenQ, kPadHeadDimQ>{});
            }
            else
            {
                return pad_tensor_view(
                    q_dram_naive,
                    make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kK0>{}),
                    sequence<kPadSeqLenQ, kPadHeadDimQ>{});
            }
        }();
        const auto k_dram = [&]() {
            const auto k_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                k_ptr,
                make_tuple(kargs.seqlen_k, kargs.hdim_q),
                make_tuple(kargs.stride_k, 1),
                number<FmhaPipeline::kAlignmentK>{},
                number<1>{});

            constexpr bool kPadSeqLenK_ = kUseAsyncCopy ? kPadSeqLenK : false;
            return pad_tensor_view(
                k_dram_naive,
                make_tuple(number<FmhaPipeline::kN0>{}, number<FmhaPipeline::kK0>{}),
                sequence<kPadSeqLenK_, kPadHeadDimQ>{});
        }();
        const auto v_dram = [&]() {
            if constexpr(std::is_same_v<VLayout, ck_tile::tensor_layout::gemm::RowMajor>)
            {
                const auto v_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                    v_ptr,
                    make_tuple(kargs.seqlen_k, kargs.hdim_v),
                    make_tuple(kargs.stride_v, 1),
                    number<FmhaPipeline::kAlignmentV>{},
                    number<1>{});

                const auto v_dram_transposed =
                    transform_tensor_view(v_dram_naive,
                                          make_tuple(make_pass_through_transform(kargs.hdim_v),
                                                     make_pass_through_transform(kargs.seqlen_k)),
                                          make_tuple(sequence<1>{}, sequence<0>{}),
                                          make_tuple(sequence<0>{}, sequence<1>{}));

                constexpr bool kPadSeqLenK_ = kUseAsyncCopy ? kPadSeqLenK : false;
                return pad_tensor_view(
                    v_dram_transposed,
                    make_tuple(number<FmhaPipeline::kN1>{}, number<FmhaPipeline::kK1>{}),
                    sequence<kPadHeadDimV, kPadSeqLenK_>{});
            }
            else
            {
                const auto v_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                    v_ptr,
                    make_tuple(kargs.hdim_v, kargs.seqlen_k),
                    make_tuple(kargs.stride_v, 1),
                    number<FmhaPipeline::kAlignmentV>{},
                    number<1>{});

                constexpr bool kPadHeadDimV_ = kUseAsyncCopy ? kPadHeadDimV : false;
                return pad_tensor_view(
                    v_dram_naive,
                    make_tuple(number<FmhaPipeline::kN1>{}, number<FmhaPipeline::kK1>{}),
                    sequence<kPadHeadDimV_, kPadSeqLenK>{});
            }
        }();

        auto q_dram_window = make_tile_window(
            q_dram,
            [&]() {
                if constexpr(FmhaPipeline::kQLoadOnce)
                    return make_tuple(number<FmhaPipeline::kM0>{},
                                      number<FmhaPipeline::kSubQKHeaddim>{});
                else
                    return make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kK0>{});
            }(),
            {i_m0, 0});

        auto k_dram_window = make_tile_window(
            k_dram, make_tuple(number<FmhaPipeline::kN0>{}, number<FmhaPipeline::kK0>{}), {0, 0});

        auto v_dram_window =
            make_tile_window(v_dram,
                             make_tuple(number<FmhaPipeline::kN1>{}, number<FmhaPipeline::kK1>{}),
                             {i_n1, 0});
        /// FIXME: Before C++20, capturing structured binding variables are not supported. Remove
        /// following copy capture of the 'i_nhead' if in C++20
        const auto bias_dram_window = [&, i_nhead_ = i_nhead]() {
            constexpr auto bias_dram_window_lengths =
                make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kN0>{});
            if constexpr(BiasEnum == BlockAttentionBiasEnum::ELEMENTWISE_BIAS)
            {
                const BiasDataType* bias_ptr =
                    reinterpret_cast<const BiasDataType*>(kargs.bias_ptr) +
                    static_cast<long_index_t>(i_nhead_) * kargs.nhead_stride_bias +
                    batch_offset_bias;

                const auto bias_dram = [&]() {
                    const auto bias_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                        bias_ptr,
                        make_tuple(kargs.seqlen_q, kargs.seqlen_k),
                        make_tuple(kargs.stride_bias, 1),
                        number<FmhaPipeline::kAlignmentBias>{},
                        number<1>{});

                    return pad_tensor_view(bias_dram_naive,
                                           bias_dram_window_lengths,
                                           sequence<kPadSeqLenQ, kPadSeqLenK>{});
                }();

                return make_tile_window(bias_dram, bias_dram_window_lengths, {i_m0, 0});
            }
            else
            {
                return make_null_tile_window(bias_dram_window_lengths);
            }
        }();

        // lse
        auto lse_dram_window = [&, i_nhead_ = i_nhead]() {
            constexpr auto lse_dram_window_lengths = make_tuple(number<FmhaPipeline::kM0>{});
            if constexpr(kStoreLSE)
            {
                LSEDataType* lse_ptr =
                    reinterpret_cast<LSEDataType*>(kargs.lse_ptr) +
                    static_cast<long_index_t>(i_nhead_) * kargs.nhead_stride_lse + batch_offset_lse;

                const auto lse_dram = [&]() {
                    const auto lse_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                        lse_ptr,
                        make_tuple(kargs.seqlen_q),
                        make_tuple(1),
                        number<1>{},
                        number<1>{});

                    return pad_tensor_view(
                        lse_dram_naive, lse_dram_window_lengths, sequence<kPadSeqLenQ>{});
                }();

                return make_tile_window(lse_dram, lse_dram_window_lengths, {i_m0});
            }
            else
            {
                return make_null_tile_window(lse_dram_window_lengths);
            }
        }();

        auto dropout = [&, i_nhead_ = i_nhead, i_batch_ = i_batch]() {
            if constexpr(kHasDropout)
            {
                return BlockDropout{i_batch_,
                                    i_nhead_,
                                    kargs.num_head_q,
                                    kargs.is_drop_seed_offset_from_host ? kargs.drop_seed.val
                                                                        : *kargs.drop_seed.ptr,
                                    kargs.is_drop_seed_offset_from_host ? kargs.drop_offset.val
                                                                        : *kargs.drop_offset.ptr,
                                    kargs.rp_undrop,
                                    kargs.p_undrop_in_uint8_t,
                                    kargs.is_store_randval};
            }
            else
            {
                return NullBlockDropout{};
            };
        }();

        auto randval_dram_window = [&, i_nhead_ = i_nhead]() {
            constexpr auto randval_dram_window_lengths =
                make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kN0>{});
            if constexpr(kHasDropout)
            {
                RandValOutputDataType* rand_val_ptr =
                    reinterpret_cast<RandValOutputDataType*>(kargs.rand_val_ptr) +
                    static_cast<long_index_t>(i_nhead_) * kargs.nhead_stride_randval +
                    batch_offset_randval;

                const auto randval_dram = [&]() {
                    const auto randval_dram_naive =
                        make_naive_tensor_view<address_space_enum::global>(
                            rand_val_ptr,
                            make_tuple(kargs.seqlen_q, kargs.seqlen_k),
                            make_tuple(kargs.stride_randval, 1),
                            number<1>{},
                            number<1>{});

                    return pad_tensor_view(randval_dram_naive,
                                           randval_dram_window_lengths,
                                           sequence<kPadSeqLenQ, kPadSeqLenK>{});
                }();

                return make_tile_window(randval_dram, randval_dram_window_lengths, {i_m0, 0});
            }
            else
            {
                return make_null_tile_window(randval_dram_window_lengths);
            }
        }();

        FmhaMask mask = [&]() {
            if constexpr(kHasMask)
                return ck_tile::make_generic_attention_mask_from_lr_window<FmhaMask>(
                    kargs.window_size_left,
                    kargs.window_size_right,
                    kargs.seqlen_q,
                    kargs.seqlen_k,
                    kargs.mask_type == GenericAttentionMaskEnum::MASK_FROM_TOP_LEFT);
            else
                return FmhaMask{kargs.seqlen_q, kargs.seqlen_k};
        }();

        // WA i_batch capture structure binding before c++20
        auto position_encoding = [&, i_batch_ = i_batch, i_nhead_ = i_nhead]() {
            if constexpr(BiasEnum == BlockAttentionBiasEnum::ALIBI)
            {
                // data loading, shared by entire wg
                // TODO: how to use s_read?
                SaccDataType slope =
                    *(reinterpret_cast<const SaccDataType*>(kargs.alibi_slope_ptr) +
                      i_batch_ * kargs.alibi_slope_stride + i_nhead_);
                slope *= ck_tile::log2e_v<>;
                if constexpr(kHasMask)
                {
                    return make_alibi_from_lr_mask<SaccDataType, true>(slope,
                                                                       kargs.window_size_left,
                                                                       kargs.window_size_right,
                                                                       kargs.seqlen_q,
                                                                       kargs.seqlen_k,
                                                                       kargs.mask_type);
                }
                else
                {
                    return Alibi<SaccDataType, true>{
                        slope, kargs.seqlen_q, kargs.seqlen_k, AlibiMode::FROM_BOTTOM_RIGHT};
                }
            }
            else
            {
                return EmptyPositionEncoding<SaccDataType>{};
            }
        }();

        auto o_acc_tile = [&]() {
            if constexpr(kDoFp8StaticQuant)
            {
                return FmhaPipeline{}(
                    q_dram_window,
                    identity{}, // q_element_func
                    k_dram_window,
                    identity{}, // k_element_func
                    v_dram_window,
                    identity{}, // v_element_func
                    bias_dram_window,
                    identity{}, // bias_element_func
                    randval_dram_window,
                    lse_dram_window,
                    identity{},                                          // lse_element_func
                    identity{},                                          // s_acc_element_func
                    scales{kargs.scale_p},                               // p_compute_element_func
                    composes(saturates<fp8_t>{}, scales{kargs.scale_o}), // o_acc_element_func
                    mask,
                    position_encoding,
                    kargs.scale_s,
                    smem_ptr,
                    dropout);
            }
            else
            {
                return FmhaPipeline{}(q_dram_window,
                                      k_dram_window,
                                      v_dram_window,
                                      bias_dram_window,
                                      randval_dram_window,
                                      lse_dram_window,
                                      mask,
                                      position_encoding,
                                      kargs.scale_s,
                                      smem_ptr,
                                      dropout);
            }
        }();

        // O DRAM and O DRAM window
        auto o_dram = [&]() {
            const auto o_dram_naive = make_naive_tensor_view<address_space_enum::global>(
                o_ptr,
                make_tuple(kargs.seqlen_q, kargs.hdim_v),
                make_tuple(kargs.stride_o, 1),
                number<FmhaPipeline::kAlignmentO>{},
                number<1>{});

            return pad_tensor_view(
                o_dram_naive,
                make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kN1>{}),
                sequence<kPadSeqLenQ, kPadHeadDimV>{});
        }();

        auto o_dram_window =
            make_tile_window(o_dram,
                             make_tuple(number<FmhaPipeline::kM0>{}, number<FmhaPipeline::kN1>{}),
                             {i_m0, i_n1});

        EpiloguePipeline{}(o_dram_window, o_acc_tile);
    }
};

namespace torch_itfs {
namespace {
struct host_args
{
    ck_tile::index_t batch;
    ck_tile::index_t seqlen_q;
    ck_tile::index_t seqlen_k;
    ck_tile::index_t hdim_q;
    ck_tile::index_t hdim_v;
    ck_tile::index_t nhead_q;
    ck_tile::index_t nhead_k;

    float scale_s;

    ck_tile::index_t window_size_left;
    ck_tile::index_t window_size_right;
    ck_tile::index_t mask_type;

    const void* q_ptr;
    ck_tile::index_t stride_q;
    ck_tile::index_t nhead_stride_q;
    ck_tile::index_t batch_stride_q;

    const void* k_ptr;
    ck_tile::index_t stride_k;
    ck_tile::index_t nhead_stride_k;
    ck_tile::index_t batch_stride_k;

    const void* v_ptr;
    ck_tile::index_t stride_v;
    ck_tile::index_t nhead_stride_v;
    ck_tile::index_t batch_stride_v;

    void* o_ptr;
    ck_tile::index_t stride_o;
    ck_tile::index_t nhead_stride_o;
    ck_tile::index_t batch_stride_o;
};

//////////////////////////////////////////////////////////////////////////////////////
template <typename DataType, bool IsMasking>
struct get_kernel
{
    using fmha_dtype = DataType;
    //                                        M0   N0  K0   N1   K1
    using fmha_block_tile = ck_tile::sequence<256, 32, 128, 128, 32, 128>;

    using fmha_warp_gemm_shape = ck_tile::sequence<32, 32, 16>;

    using fmha_block_warps = ck_tile::sequence<8, 1, 1>;

    using fmha_shape = ck_tile::TileFmhaShape<fmha_block_tile,
                                              fmha_block_warps,
                                              fmha_warp_gemm_shape,
                                              fmha_block_warps,
                                              fmha_warp_gemm_shape,
                                              true // IsVLayoutRowMajor
                                              >;

    using fmha_traits = ck_tile::TileFmhaTraits<true,  // kPadSeqLenQ
                                                true,  // kPadSeqLenK
                                                false, // kPadHeadDimQ
                                                false, // kPadHeadDimV
                                                false, // kHasLogitsSoftCap
                                                ck_tile::BlockAttentionBiasEnum::NO_BIAS,
                                                false, // kHasBiasGrad
                                                false, // kStoreLSE
                                                false, // kHasDropout
                                                false, // kDoFp8StaticQuant
                                                -1,    // kBlockPerCu
                                                false  // kSkipMinSeqlenQ
                                                >;

    using fmha_variant =
        ck_tile::ComposedAttention<false * ck_tile::LOGITS_SOFT_CAP, // VARIANT_CODE
                                   CK_TILE_FMHA_FWD_FAST_EXP2        // UseExp2
                                   >; // placeholder type, we are not using this

    using fmha_mask = ck_tile::SimplifiedGenericAttentionMask<IsMasking>;

    using fmha_problem = ck_tile::BlockFmhaPipelineProblem<
        typename FmhaFwdTypeConfig<fmha_dtype>::QDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::KDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::VDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::SaccDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::SMPLComputeDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::BiasDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::RandValOutputDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::LSEDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::PDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::OaccDataType,
        typename FmhaFwdTypeConfig<fmha_dtype>::ODataType,
        fmha_shape,
        false, // kIsGroupMode
        fmha_variant,
        fmha_mask,
        fmha_traits>;

    using fmha_pipeline = aiter::BlockFmhaPipelineQRKSVS<fmha_problem>;

    using fmha_epilogue = ck_tile::Default2DEpilogue<
        ck_tile::Default2DEpilogueProblem<typename FmhaFwdTypeConfig<fmha_dtype>::OaccDataType,
                                          typename FmhaFwdTypeConfig<fmha_dtype>::ODataType,
                                          true, // kPadM
                                          true  // kPadM
                                          >>;

    using type = aiter::FmhaFwdKernel<fmha_pipeline, fmha_epilogue>;
};

template <typename DataType, bool IsMasking>
using get_kernel_t = typename get_kernel<DataType, IsMasking>::type;

template <typename Kernel>
void launch(const host_args& args)
{
    auto kargs = Kernel::MakeKargsImpl(args.q_ptr,
                                       args.k_ptr,
                                       args.v_ptr,
                                       nullptr, // bias_ptr
                                       nullptr, // rand_val_ptr
                                       nullptr, // lse_ptr
                                       args.o_ptr,
                                       args.seqlen_q,
                                       args.seqlen_k,
                                       args.hdim_q,
                                       args.hdim_v,
                                       args.nhead_q,
                                       args.nhead_q / args.nhead_k,
                                       args.scale_s,
                                       1.0f, // scale_p
                                       1.0f, // scale_o
                                       0.0f, // logits_soft_cap
                                       args.stride_q,
                                       args.stride_k,
                                       args.stride_v,
                                       0, // stride_bias
                                       0, // stride_randval
                                       args.stride_o,
                                       args.nhead_stride_q,
                                       args.nhead_stride_k,
                                       args.nhead_stride_v,
                                       0, // nhead_stride_bias
                                       0, // nhead_stride_randval
                                       0, // nhead_stride_lse
                                       args.nhead_stride_o,
                                       args.batch_stride_q,
                                       args.batch_stride_k,
                                       args.batch_stride_v,
                                       0, // batch_stride_bias
                                       0, // batch_stride_randval
                                       0, // batch_stride_lse
                                       args.batch_stride_o,
                                       args.window_size_left,
                                       args.window_size_right,
                                       args.mask_type,
                                       0.0f,                      // p_drop
                                       false,                     // s_randval
                                       std::make_pair(0UL, 0UL)); // drop_seed_offset

    dim3 grids = Kernel::GridSize(args.batch, args.nhead_q, args.seqlen_q, args.hdim_v, false);
    constexpr dim3 blocks                  = Kernel::BlockSize();
    constexpr ck_tile::index_t kBlockPerCu = Kernel::kBlockPerCu;

    auto stream = at::cuda::getCurrentHIPStream().stream();
    ck_tile::stream_config stream_config{stream};

    [[maybe_unused]] const float time = ck_tile::launch_kernel(
        stream_config,
        ck_tile::make_kernel<blocks.x, kBlockPerCu>(Kernel{}, grids, blocks, 0, kargs));
}
} // namespace
//////////////////////////////////////////////////////////////////////////////////////

std::vector<at::Tensor> fmha_v3_fwd_ck(const at::Tensor& q, // [b, sq, hq, d]
                                       const at::Tensor& k, // [b, sk, hk, d]
                                       const at::Tensor& v, // [b, sk, hk, d_v]
                                       float softmax_scale,
                                       bool is_causal,
                                       int window_size_left,
                                       int window_size_right,
                                       bool return_softmax_lse)
{
    auto q_dtype = q.dtype();
    TORCH_CHECK(q_dtype == at::ScalarType::Half || q_dtype == at::ScalarType::BFloat16,
                "FlashAttention only support fp16 and bf16 data type");

    TORCH_CHECK(k.dtype() == q_dtype, "query and key must have the same dtype");
    TORCH_CHECK(v.dtype() == q_dtype, "query and value must have the same dtype");

    CHECK_DEVICE(q);
    CHECK_DEVICE(k);
    CHECK_DEVICE(v);

    TORCH_CHECK(q.stride(-1) == 1, "Input tensor must have contiguous last dimension");
    TORCH_CHECK(k.stride(-1) == 1, "Input tensor must have contiguous last dimension");
    TORCH_CHECK(v.stride(-1) == 1, "Input tensor must have contiguous last dimension");

    const auto sizes = q.sizes();

    const int batch_size  = sizes[0];
    int seqlen_q          = sizes[1];
    int num_heads         = sizes[2];
    const int head_size_q = sizes[3];
    const int head_size_v = v.sizes()[3];
    const int seqlen_k    = k.size(1);
    const int num_heads_k = k.size(2);
    TORCH_CHECK(batch_size > 0, "batch size must be positive");
    TORCH_CHECK(head_size_q <= 256, "CK only supports head dimension at most 256");
    TORCH_CHECK(head_size_v <= 256, "CK only supports head dimension at most 256");
    TORCH_CHECK(head_size_q % 8 == 0,
                "query, key, value, and out_ must have a head_size_q that is a multiple of 8");
    TORCH_CHECK(head_size_v % 8 == 0,
                "query, key, value, and out_ must have a head_size_q that is a multiple of 8");
    TORCH_CHECK(
        num_heads % num_heads_k == 0,
        "ck_tile::number of heads in key/value must divide ck_tile::number of heads in query");

    CHECK_SHAPE(q, batch_size, seqlen_q, num_heads, head_size_q);
    CHECK_SHAPE(k, batch_size, seqlen_k, num_heads_k, head_size_q);
    CHECK_SHAPE(v, batch_size, seqlen_k, num_heads_k, head_size_v);

    if(window_size_left >= seqlen_k)
    {
        window_size_left = -1;
    }
    if(window_size_right >= seqlen_k)
    {
        window_size_right = -1;
    }

    mask_info mask;
    if(is_causal)
    {
        // Causal is the special case where window_size_right == 0 and window_size_left < 0.
        window_size_right         = 0;
        std::string mask_identify = "b:" + std::to_string(window_size_left) + "," + "0";
        mask                      = mask_info::decode(mask_identify, seqlen_q, seqlen_k); // casual
    }
    else if(window_size_left == -1 && window_size_right == -1)
    {
        mask = mask_info::decode("0", seqlen_q, seqlen_k); // no mask
    }
    else
    {
        // Local is the more general case where window_size_right >= 0 or window_size_left >= 0.
        std::string mask_identify =
            "b:" + std::to_string(window_size_left) + "," + std::to_string(window_size_right);
        mask = mask_info::decode(mask_identify, seqlen_q, seqlen_k); // local
    }

    host_args args;

    args.batch    = batch_size;
    args.seqlen_q = seqlen_q;
    args.seqlen_k = seqlen_k;
    args.hdim_q   = head_size_q;
    args.hdim_v   = head_size_v;
    args.nhead_q  = num_heads;
    args.nhead_k  = num_heads_k;

    args.scale_s = softmax_scale;

    args.window_size_left  = mask.left;
    args.window_size_right = mask.right;
    args.mask_type         = static_cast<ck_tile::index_t>(mask.type);

    args.q_ptr          = q.data_ptr();
    args.batch_stride_q = q.stride(0);
    args.stride_q       = q.stride(1);
    args.nhead_stride_q = q.stride(2);

    args.k_ptr          = k.data_ptr();
    args.batch_stride_k = k.stride(0);
    args.stride_k       = k.stride(1);
    args.nhead_stride_k = k.stride(2);

    args.v_ptr          = v.data_ptr();
    args.batch_stride_v = v.stride(0);
    args.stride_v       = v.stride(1);
    args.nhead_stride_v = v.stride(2);

    auto opts = q.options();
    at::Tensor out =
        torch::empty({batch_size, seqlen_q, num_heads, head_size_v}, opts.dtype(q_dtype));

    args.o_ptr          = out.data_ptr();
    args.batch_stride_o = out.stride(0);
    args.stride_o       = out.stride(1);
    args.nhead_stride_o = out.stride(2);

    // TODO: compile fp16/bf16, masking=true/false kernels separately
    if(q_dtype == at::ScalarType::Half)
    {
        if(mask.type == mask_enum::no_mask)
        {
            launch<get_kernel_t<FmhaFwdFp16, false>>(args);
        }
        else
        {
            launch<get_kernel_t<FmhaFwdFp16, true>>(args);
        }
    }
    else if(q_dtype == at::ScalarType::BFloat16)
    {
        if(mask.type == mask_enum::no_mask)
        {
            launch<get_kernel_t<FmhaFwdBf16, false>>(args);
        }
        else
        {
            launch<get_kernel_t<FmhaFwdBf16, true>>(args);
        }
    }

    return {out};
}

} // namespace torch_itfs
} // namespace aiter
