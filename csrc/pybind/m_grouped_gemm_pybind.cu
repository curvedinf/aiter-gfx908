// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
#include "rocm_ops.hpp"
#include "m_grouped_flatmm_ck.h"

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m)
{
    M_GROUPED_FLATMM_PYBIND;
}
