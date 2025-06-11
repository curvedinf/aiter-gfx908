# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

from torch import Tensor
from ..jit.core import compile_ops

MD_NAME = "module_aiter_operator"


@compile_ops("module_aiter_add")
def add(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_sub")
def sub(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_mul")
def mul(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_div")
def div(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_add")
def add_(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_sub")
def sub_(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_mul")
def mul_(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_div")
def div_(input: Tensor, other: Tensor) -> Tensor: ...


@compile_ops("module_aiter_operator")
def sigmoid(input: Tensor) -> Tensor: ...


@compile_ops("module_aiter_operator")
def tanh(input: Tensor) -> Tensor: ...
