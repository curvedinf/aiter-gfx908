# SPDX-License-Identifier: MIT
# Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

from typing import Tuple, Optional
from torch import Tensor
from ..jit.core import compile_ops


MD_NAME = "module_fmla_fwd"


@compile_ops("module_fmla_fwd")
def flash_mla_fwd_inline_impl(
    q: Tensor,
    k_v_cache: Tensor,
    qo_indptr: Tensor,
    cache_seqlens: Tensor,
    block_table: Tensor,
    kv_last_page_lens: Tensor,
    num_kv_splits_indptr: Tensor,
    max_seqlen_q: int,
    softmax_scale: float,
    split_data: Tensor = None,
    split_lse: Tensor = None,
    query_rope: Optional[Tensor]= None,
    key_rope_cache: Optional[Tensor] = None,
    batch_split_table: Optional[Tensor]= None,
    split_table: Optional[Tensor] = None,
    out: Optional[Tensor] = None,
    num_splits: Optional[int] = 0,
):
    ...

"""
metadata:
kv_indptr: kv seqlen tensor eg: [0, 100, 434, 613]
num_kv_splits_indptr: split table, splits per batch eg: [0, 4, 8, 10]
batch_split_table: split table map to batch idx: [0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2]
split_table: split table map to split idx : [0, 1, 2, 3, 0, 1, 2, 3, 4, 0, 1]
"""
@compile_ops("module_fmla_fwd")
def get_mla_metadata_impl(
    kv_indptr: Tensor,
    num_kv_splits_indptr: Tensor,
    batch_split_table: Tensor,
    split_table: Tensor,
    splits: Tensor,
):
    ...
