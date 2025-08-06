// SPDX-License-Identifier: MIT
// Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

#include "rocm_ops.hpp"
#include "ck_mla.h"

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m)
{
    CK_MLA_FWD_PYBIND;
}
