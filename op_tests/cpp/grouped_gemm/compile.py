# SPDX-License-Identifier: MIT
# Copyright (C) 2018-2025, Advanced Micro Devices, Inc. All rights reserved.
import sys
import os
import argparse

# !!!!!!!!!!!!!!!! never import aiter
# from aiter.jit import core
this_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, f"{this_dir}/../../../aiter/")
from jit.core import compile_ops


@compile_ops("libm_grouped_flatmm", fc_name="compile_m_grouped_flatmm")
def compile_m_grouped_flatmm(): ...


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="compile",
        description="compile C++ instance with torch excluded",
    )

    args = parser.parse_args()

    compile_m_grouped_flatmm()
