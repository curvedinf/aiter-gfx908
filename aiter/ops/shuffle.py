# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

import torch


def shuffle_weight(x: torch.Tensor, layout=(16, 16)) -> torch.Tensor:
    # Hardcode BLOCK_K and BLOCK_N
    IN, IK = layout
    BK = IK*2
    K = 16//x.element_size()
    BN = IN
    assert (x.shape[-2] %
            BN == 0), f'{x.shape[-2]} % {BN} == {x.shape[-2] % BN }'
    assert (x.shape[-1] %
            BK == 0), f'{x.shape[-1]} % {BK} == {x.shape[-1] % BK }'

    x_ = x
    x_ = x_.view(-1,
                 x.shape[-2]//BN, BN,
                 x.shape[-1]//BK, BK//K, K)
    x_ = x_.permute(0, 1, 3, 4, 2, 5)
    x_ = x_.contiguous()
    x_ = x_.view(*x.shape)
    return x_

def rearrange_4bit_elements(tensor):
    """
    GPU-optimized version for rearranging 4-bit segments within 32-bit integers
    [e0, e1, e2, e3, e4, e5, e6, e7] -> [e0, e2, e4, e6, e1, e3, e5, e7]
    """
    t_ = tensor.view(dtype=torch.int32)
 
    return (
        ((t_ & 0xF0000000) << 0) |   # e0 (bits 28-31)
        ((t_ & 0x00F00000) << 4) |   # e2 -> position 24-27
        ((t_ & 0x0000F000) << 8) |   # e4 -> position 20-23
        ((t_ & 0x000000F0) << 12) |  # e6 -> position 16-19
        ((t_ & 0x0F000000) >> 12) |  # e1 -> position 12-15
        ((t_ & 0x000F0000) >> 8) |   # e3 -> position 8-11
        ((t_ & 0x00000F00) >> 4) |   # e5 -> position 4-7
        (t_ & 0x0000000F)            # e7 (bits 0-3)
    ).view(dtype=torch.uint32)