#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved.
"""Regenerate the gfx908 a8w8 CK instance keep-list from a tuned CSV.

Union of (a) kernelIds picked by tuned rows for the given gfx arch and
(b) the default/heuristic kernels resolvable in kernels_list. Write the
result one-id-per-line for AITER_CK_INSTANCE_LIST (see
csrc/ck_gemm_a8w8/a8w8_instance_keep_list.txt for semantics).
"""

import argparse
import os
import sys

import pandas as pd

this_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(this_dir, "..", "csrc", "ck_gemm_a8w8"))
sys.path.insert(0, os.path.join(this_dir, "..", "aiter", "jit", "utils"))

from gemm_a8w8_common import default_kernels_dict, kernels_list  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="aiter/configs/a8w8_tuned_gemm.csv")
    ap.add_argument("--gfx", default="gfx908")
    ap.add_argument(
        "--out", default="csrc/ck_gemm_a8w8/a8w8_instance_keep_list.txt"
    )
    args = ap.parse_args()

    default_names = {k.name for k in default_kernels_dict.values()}
    default_ids = {
        kid for kid, k in kernels_list.items() if k.name in default_names
    }

    tuned_ids = set()
    if os.path.exists(args.csv):
        df = pd.read_csv(args.csv)
        if "gfx" in df.columns:
            df = df[df["gfx"] == args.gfx]
        tuned_ids = {int(x) for x in df["kernelId"].dropna()}

    unknown = (default_ids | tuned_ids) - set(kernels_list)
    if unknown:
        raise SystemExit(f"tuned CSV references unknown kernelIds {sorted(unknown)}")

    ids = sorted(default_ids | tuned_ids)
    with open(args.out, "w") as f:
        f.write(
            "# a8w8 CK instance keep-list (gfx908) -- regenerate with\n"
            f"# scripts/gen_a8w8_instance_list.py --csv {args.csv} --gfx {args.gfx}\n"
            f"# {len(default_ids)} default + {len(tuned_ids - default_ids)} tuned ids\n"
        )
        f.write("\n".join(str(i) for i in ids) + "\n")
    print(f"wrote {len(ids)} ids -> {args.out}")


if __name__ == "__main__":
    main()
