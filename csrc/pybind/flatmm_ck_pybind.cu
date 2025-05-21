// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include "flatmm_ck.h"

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m)
{
    m.def("flatmm_ck", &flatmm_ck, "flatmm_ck", 
        py::arg("XQ"),
        py::arg("WQ"),
        py::arg("x_scale"),
        py::arg("w_scale"),
        py::arg("Out"));
}
