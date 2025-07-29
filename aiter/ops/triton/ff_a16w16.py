# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

from typing import Optional
import torch
from aiter.ops.triton.gemm_a16w16 import gemm_a16w16
from aiter.ops.triton.gemm_a16w16_gated import gemm_a16w16_gated

activation_mapping = {
    "gelu": "gelu_tanh",
    "silu": "silu_exp2",
    "relu": "relu",
    None: None,
}


def ff_a16w16_nogate(
    x,
    w_up,
    w_down,
    dtype: Optional[float] = torch.bfloat16,
    y: Optional[torch.Tensor] = None,
    config: Optional[dict] = None,
    activation: Optional[str] = None,
):
    """
    Full feed-forward block with gating (e.g swiglu).
    x: torch.Tensor (M, K)
    w_up: torch.Tensor (N, K)
    w_down: torch.Tensor (N, K)
    y: torch.Tensor (M, K)
    activation: One of ("silu", "gelu", "relu")
    """
    # Shape checks
    assert x.shape[1] == w_up.shape[1] == w_down.shape[1], "Incompatible matrix shapes."
    assert w_up.shape[0] == w_down.shape[0] * 2, "Incompatible matrix shapes."
    M, K = x.shape
    N, K = w_up.shape

    if y is None:
        y = torch.empty((M, K), dtype=dtype, device=x.device)

    intermediate = gemm_a16w16(
        x, w_up, dtype=dtype, config=config, activation=activation_mapping[activation]
    )
    y = gemm_a16w16(intermediate, w_down, dtype=dtype, config=config, y=y)

    return y


def ff_a16w16_gated(
    x,
    w_up,
    w_down,
    dtype: Optional[float] = torch.bfloat16,
    intermediate: Optional[torch.Tensor] = None,
    y: Optional[torch.Tensor] = None,
    config: Optional[dict] = None,
    activation: Optional[str] = None,
):
    """
    Full feed-forward block with gating (e.g swiglu).
    x: torch.Tensor (B, hidden_dim)
    w_up: torch.Tensor (intermediate_dim * 2, hidden_dim)
    w_down: torch.Tensor (hidden_dim, intermediate_dim)
    y: torch.Tensor (B, hidden_dim)
    activation: One of ("geglu", "swiglu", "reglu")
    """
    # Shape checks
    assert x.shape[1] == w_up.shape[1] == w_down.shape[0], "Incompatible matrix shapes."
    assert w_up.shape[0] == w_down.shape[1] * 2, "Incompatible matrix shapes."
    batch, hidden_dim = x.shape

    if intermediate is None:
        intermediate = torch.empty((batch, hidden_dim), dtype=dtype, device=x.device)
    intermediate = gemm_a16w16_gated(
        x,
        w_up,
        y=intermediate,
        dtype=dtype,
        config=config,
        activation=activation_mapping[activation],
    )
    if y is None:
        y = torch.empty((batch, hidden_dim), dtype=dtype, device=x.device)
    y = gemm_a16w16(intermediate, w_down, dtype=dtype, config=config, y=y)

    return y
