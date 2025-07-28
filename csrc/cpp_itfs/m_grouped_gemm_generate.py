# SPDX-License-Identifier: MIT
# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.
# generate kernel instances to speed up compilation

import argparse
from pathlib import Path
from typing import Optional

GEN_DIR = ""  # in Cmake, have to generate files in same folder

AITER_API_FILENAME = "m_grouped_flatmm_ck.cpp"

AITER_CPP_API = """
#include "m_grouped_flatmm_ck.h"

namespace aiter {{
m_grouped_flatmm_args make_args(int* M_indices_,
                                int group_count_,
                                int Max_M_,
                                int N_,
                                int K_,
                                const void* a_ptr_,
                                int stride_A_,
                                const void* b_shuffle_ptr_,
                                int stride_B_,
                                void* c_ptr_,
                                int stride_C_,
                                int k_batch_)
{{
    return m_grouped_flatmm_args(M_indices_,
                                group_count_,
                                Max_M_,
                                N_,
                                K_,
                                a_ptr_,
                                stride_A_,
                                b_shuffle_ptr_,
                                stride_B_,
                                c_ptr_,
                                stride_C_,
                                k_batch_);
}}

void m_grouped_flatmm_ck(
    ck_stream_config&& s,
    int* M_indices,
    int group_count,
    int Max_M,
    int N,
    int K,
    const void* a_ptr,
    const void* b_shuffle_ptr,
    void* c_ptr
    )
{{
    m_grouped_flatmm_args args = make_args(M_indices,
                                            group_count,
                                            Max_M,
                                            N,
                                            K,
                                            a_ptr,
                                            K,
                                            b_shuffle_ptr,
                                            K,
                                            c_ptr,
                                            N,
                                            1 // K_batch
                                        );
    grouped_flatmm<{ADataType}, {BDataType}, {AccDataType}, {CDatatype}, row_major, col_major, row_major>(args, s);
}}
}}
"""


def write_blobs(output_dir: Optional[str], receipt) -> None:
    if output_dir is None:
        output_dir = Path(__file__).parent
    else:
        output_dir = Path(output_dir) / GEN_DIR

    output_dir.mkdir(parents=True, exist_ok=True)

    api = AITER_CPP_API.format(
        ADataType="bf16",
        BDataType="bf16",
        AccDataType="float",
        CDatatype="bf16",
    )
    (output_dir / AITER_API_FILENAME).write_text(api)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="generate",
        description="gen API for CK grouped flatmm kernel",
    )
    parser.add_argument(
        "-o",
        "--output_dir",
        required=False,
        help="write all the blobs into a directory",
    )

    args = parser.parse_args()

    write_blobs(args.output_dir, int(0))
