// SPDX-License-Identifier: MIT
// Copyright (c) 2018-2025, Advanced Micro Devices, Inc. All rights reserved.

#pragma once

#include "ck_tile/core.hpp"
#include "ck_tile/ops/gemm/warp/warp_gemm.hpp"

namespace aiter {

// Default policy for BlockGemmARegBRegCRegV2
// Default policy class should not be templated, put template on member functions instead
struct BlockGemmARegBRegCRegV2DefaultPolicy
{
    template <typename Problem>
    CK_TILE_HOST_DEVICE static constexpr auto GetWarpGemmMWarpNWarp()
    {
        using namespace ck_tile;

        if constexpr(std::is_same_v<typename Problem::ADataType, half_t> &&
                     std::is_same_v<typename Problem::BDataType, half_t> &&
                     std::is_same_v<typename Problem::CDataType, float>)
        {
            return make_tuple(WarpGemmMfmaF16F16F32M32N32K8TransposedCDistribution{}, 4, 1);
        }
        else if constexpr(std::is_same_v<typename Problem::ADataType, bf16_t> &&
                          std::is_same_v<typename Problem::BDataType, bf16_t> &&
                          std::is_same_v<typename Problem::CDataType, float>)
        {
            return make_tuple(WarpGemmMfmaBf16Bf16F32M32N32K8TransposedCDistribution{}, 4, 1);
        }
    }
};

} // namespace aiter
