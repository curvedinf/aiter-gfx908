import pytest
import torch
import triton
import aiter

from aiter.ops.triton.moe_op_mxfp4 import fused_moe_mxfp4
from op_tests.op_benchmarks.triton.utils.common import (
    str_to_torch_dtype,
    torch_to_tl_dtype,
)
from op_tests.op_benchmarks.triton.utils.moe import generate_moe_alignment

from .utils.fused_moe_ref import torch_moe
from aiter import ActivationType
from aiter.ops.triton.quant import dynamic_mxfp4_quant

DEBUG_MODE = False


def alloc_rand(shape, device, dtype, requires_grad=True):
    if dtype.itemsize == 1:
        tmp = 2 ** -(torch.randint(4, 8, shape, device=device, dtype=torch.float16))
        return tmp.to(dtype).requires_grad_(requires_grad)
    return torch.randn(shape, device=device, dtype=dtype, requires_grad=requires_grad)

def ck_moe_stage1(
    hidden_states,
    w1,  # [E, inter_dim*2, model_dim]
    w2,  # [E, model_dim, inter_dim]
    sorted_token_ids,  # [max_num_tokens_padded]
    sorted_expert_ids,  # [max_num_m_blocks]
    num_valid_ids,  # [1]
    w1_scale,
    a1_scale,
    dtype,
    topk,
    block_size=32,
    Activation=ActivationType.Gelu,
    sorted_weights=None,  # [max_num_tokens_padded]
):
    token_num = hidden_states.shape[0]
    D = w2.shape[-1]
    # max_num_tokens_padded = sorted_expert_ids.shape[0]*block_size
    if Activation == ActivationType.Silu:
        act_op = 1
    else:
        act_op = 0

    if w1.dtype is torch.uint32:
        D = D * 8

    out = torch.empty((token_num, topk, D), dtype=dtype)

    aiter.ck_moe_stage1(
        hidden_states,
        w1,
        w2,
        sorted_token_ids,
        sorted_expert_ids,
        num_valid_ids,
        out,
        topk,
        w1_scale,
        a1_scale,
        block_size,
        sorted_weights,
        act_op,
        3,
    )

    return out

def torch_dynamic_mxfp4_quant(
    x: torch.Tensor, scaling_mode: str = "even"
) -> tuple[torch.Tensor, torch.Tensor]:
    """
    Quantize a tensor to MX FP4 format based of AMD Quark Spec.

    Math equivalent:
        blockscale_e8m0 = 2^(floor(log2(rounding(max_abs(x_block)))-max_exp))
        x_block_fp4 = x_block / blockscale_e8m0
        where max_exp = 2 for fp4_e2m1.

    Args:
        x: The input tensor, typically fp16 or bf16.
        scaling_mode: The method to calculate MX block scaling.
            - "even" (default): `even_round`.
    Returns:
        A tuple of (x_fp4, blockscale_e8m0).
    """
    # Create padded x. Needed because mxfp4 works with block of 32 elements
    MXFP4_QUANT_BLOCK_SIZE = 32
    x_shape = x.shape
    if x.shape[-1] % MXFP4_QUANT_BLOCK_SIZE != 0:
        shape = list(x_shape)
        shape = shape[:-1] + [
            ((shape[-1] - 1 + MXFP4_QUANT_BLOCK_SIZE) // MXFP4_QUANT_BLOCK_SIZE)
            * MXFP4_QUANT_BLOCK_SIZE
        ]
        shape = tuple(shape)
        x_padded = torch.zeros((shape), device=x.device, dtype=x.dtype)
        x_padded[..., : x.shape[-1]] = x
    else:
        x_padded = x

    # Calculate scale
    x_padded = x_padded.reshape(
        -1, x_padded.shape[-1] // MXFP4_QUANT_BLOCK_SIZE, MXFP4_QUANT_BLOCK_SIZE
    ).to(torch.float32)
    # print(f"x_padded.shape={x_padded.shape}")
    amax, _ = torch.max(torch.abs(x_padded), dim=-1)
    amax = amax.view(torch.int32)
    amax = (amax + 0x200000) & 0xFF800000
    amax = amax.view(torch.float32)
    scale_e8m0_unbiased = torch.log2(amax).floor() - 2
    scale_e8m0_unbiased = torch.clamp(scale_e8m0_unbiased, min=-127, max=127)
    quant_scale = torch.exp2(-scale_e8m0_unbiased)

    # Compute quantized x
    qx = x_padded * quant_scale.unsqueeze(-1)

    # blockscale_e8m0
    bs_e8m0 = scale_e8m0_unbiased.to(torch.uint8) + 127

    # Convert to mxfp4 format
    #
    # Note: This code is adapted from Triton Bench numerics mxfp4 code
    #
    # Note: MXFP4  S:1-bit, E:2-bit, M:1-bit
    #   Zeros: S000 -> +/-0
    #   Denormal Numbers: S001 -> +/- 0.5
    #   Normal Numbers:
    #           S010 -> +/- 1.0
    #           S011 -> +/- 1.5
    #           S100 -> +/- 2.0
    #           S101 -> +/- 3.0
    #           S110 -> +/- 4.0
    #           S111 -> +/- 6.0
    # Convert quantized fp32 tensor to int32 before converting to mxfp4 format
    qx = qx.view(torch.int32)

    # Extract sign, exponents and mantissa fields from int32
    s = qx & 0x80000000
    e = (qx >> 23) & 0xFF
    m = qx & 0x7FFFFF

    E8_BIAS = 127
    E2_BIAS = 1

    # Denormal numbers
    # If exponent is less than 127, then it's a denormal number
    # See above, for denormal number mantissa is always 1 and we set bit 1 of mantissa
    adjusted_exponents = E8_BIAS - e - 1
    m = torch.where(e < E8_BIAS, (0x400000 | (m >> 1)) >> adjusted_exponents, m)

    # For normal numbers, bias is changed from 127 to 1, and for subnormals, we keep exponent as 0.
    # Note: E8_BIAS - E2_BIAS = 126, so for normals we subtract that.
    e = torch.where(e > E8_BIAS - E2_BIAS, e, E8_BIAS - E2_BIAS) - (E8_BIAS - E2_BIAS)

    # Combine sign, exponent, and mantissa, while saturating
    # rounding nearest with tie breaking up by adding +1 to one bit right of the LSB, then shift right
    combined_val = (((e << 2) | (m >> 21)) + 1) >> 1
    e2m1_tmp = torch.where(combined_val < 0x7, combined_val, 0x7)
    e2m1_value = (((s >> 28) & 0xF) | e2m1_tmp).to(torch.uint8)

    # Pack 2 4-bit values into 8-bit
    x_mxfp4 = e2m1_value[..., ::2] | (e2m1_value[..., 1::2] << 4)

    # Recover last dimension's shape
    x_mxfp4 = torch.flatten(x_mxfp4, -2, -1)

    # Remove padded values
    if x.shape[-1] % MXFP4_QUANT_BLOCK_SIZE != 0:
        x_mxfp4 = x_mxfp4[..., : x.shape[-1] // 2]

    # Reshape back to original
    mxfp4_shape = list(x_shape)
    mxfp4_shape = tuple(mxfp4_shape[:-1] + [mxfp4_shape[-1] // 2])
    x_mxfp4 = x_mxfp4.reshape(mxfp4_shape)

    return x_mxfp4, bs_e8m0

@pytest.mark.parametrize(
    "M, N, K, E, top_k",
    [
        # # fp8 x mxfp4
        (1000, 704, 800, 3, 1),
        (1000, 704, 800, 8, 2),

    ],
)
@pytest.mark.parametrize(
    "a_dtype_str, b_dtype_str",
    [
        # Hardware native OCP
        ("mxfp4_e2m1", "mxfp4_e2m1"),
        # Software emulation that upcasts mxfp4 to fp16
    ],
)
@pytest.mark.parametrize("routed_weight", [True])
@pytest.mark.parametrize("swizzle_mx_scale", [True])
def test_fused_moe(
    M: int,
    N: int,
    K: int,
    top_k: int,
    E: int,
    a_dtype_str: str,
    b_dtype_str: str,
    routed_weight: bool,
    swizzle_mx_scale: bool,
):
    global _SKIP
    if triton.runtime.driver.active.get_current_target().arch not in ("gfx950"):
        pytest.skip("MXFP4 not supported on this architecture")

    is_a_mixed_input = a_dtype_str.startswith("mx")
    is_b_mixed_input = b_dtype_str.startswith("mx")
    a_dtype = str_to_torch_dtype[a_dtype_str]
    c_dtype = torch.bfloat16 if is_a_mixed_input else a_dtype
    fp16_dtype = torch.float16 if a_dtype_str == "fp16" else torch.bfloat16
    a_tri = alloc_rand((M, K), dtype=fp16_dtype, device="cuda", requires_grad=False)
    b_tri = alloc_rand((E, N, K), dtype=fp16_dtype, device="cuda", requires_grad=False)
    c_tri = torch.zeros(
        (M, top_k, N), dtype=c_dtype, device="cuda", requires_grad=False
    )
    a_scale = torch.tensor([1.00], dtype=torch.float32, device="cuda")
    b_scale = torch.tensor([1.00] * E, dtype=torch.float32, device="cuda")
    # Reference inputs
    a_ref, b_ref, c_ref = a_tri.clone(), b_tri.clone(), c_tri.clone()
    # Try fixed config for now
    config = {
        "BLOCK_SIZE_M": 128,
        "BLOCK_SIZE_N": 128,
        "BLOCK_SIZE_K": 128,
        "GROUP_SIZE_M": 4,
        "num_warps": 8,
        "num_stages": 2,
        "waves_per_eu": 0,
        "matrix_instr_nonkdim": 16,
        "kpack": 1,
    }
    # Simulated moe_align_block_size()
    topk_weights, topk_ids, sorted_token_ids, expert_ids, num_tokens_post_padded = (
        generate_moe_alignment(M, E, top_k, config["BLOCK_SIZE_M"])
    )
    # Downcast a tensor to mxfp4 and upcast back for reference
    if is_a_mixed_input:
        # swizzle_axis = 0 if swizzle_mx_scale else None  # TODO Add Swizzle support
        a_tri, a_mx_scales = torch_dynamic_mxfp4_quant(a_tri)

        # TODO Add Upcast support
        a_ref = a_tri
        # a_ref = torch_upcast_from_mxfp(
        #    a_tri, a_mx_scales, fp16_dtype, axis=1, swizzle_axis=swizzle_axisv
        # )
    else:
        a_ref = a_ref.to(fp16_dtype)
        a_mx_scales = None
    # Downcast b tensor to mxfp4 and upcast back for reference
    if is_b_mixed_input:
        # swizzle_axis = 1 if swizzle_mx_scale else None  # TODO Add Swizzle support
        b_tri, b_mx_scales = torch_dynamic_mxfp4_quant(b_tri)
        b_mx_scales = b_mx_scales.view(E, N, -1)
        print(f"{b_mx_scales.shape=}")
        # print(b_mx_scales.shape)
        # TODO Add Upcast support
        b_ref = b_tri
        # b_ref = torch_upcast_from_mxfp(
        #    b_tri, b_mx_scales, fp16_dtype, axis=2, swizzle_axis=swizzle_axis
        # )
        # ######################## stage 1 start ###########
    # out1_ck = torch.empty((M, top_k, N), dtype=fp16_dtype)
    # out1_ck = ck_moe_stage1(
    #     a_tri,
    #     b_tri,
    #     b_tri,
    #     sorted_token_ids,
    #     expert_ids,
    #     num_tokens_post_padded,
    #     b_mx_scales,
    #     a_mx_scales,
    #     fp16_dtype,
    #     top_k,
    #     128,
    #     ActivationType.Gelu,
    #     sorted_weights=topk_weights,
    # )

    # if qType == aiter.QuantType.per_Token:
    #     out1_ck = out1_ck.view(token, -1)
    # a2_qt, a2_scale = torch_quant(out1_ck.view(token, -1), quant_dtype=AQDType)
    # a2_qt = a2_qt.view(M, topk, -1)
    # out2_ck, us = run_perftest(
    #     ck_moe_stage2,
    #     a2_qt,
    #     w1_qt_aiter,
    #     w2_qt_aiter,
    #     sorted_ids,
    #     sorted_expert_ids,
    #     num_valid_ids,
    #     w2_scale,
    #     a2_scale,
    #     dtype,
    #     topk,
    #     BLOCK_SIZE_M,
    #     sorted_weights if not doweight_stage1 else None,
    # )
    # Triton
    fused_moe_mxfp4(
        a_tri,
        b_tri,
        c_tri,
        a_scale,
        b_scale,
        a_mx_scales,
        b_mx_scales,
        topk_weights,
        topk_ids,
        sorted_token_ids,
        expert_ids,
        num_tokens_post_padded,
        routed_weight,
        top_k,
        swizzle_mx_scale,
        swizzle_mx_scale,
        config,
        torch_to_tl_dtype[c_tri.dtype],
    )
    # Torch
    b_zp = None
    group_size = 0
    # a_scale and b_scale not used actually
    c_ref = torch_moe(
        a_ref,
        b_ref,
        c_ref,
        a_scale,
        b_scale,
        b_zp,
        group_size,
        topk_ids,
        topk_weights,
        routed_weight,
        sorted_token_ids,
        expert_ids,
        num_tokens_post_padded,
        dtype=torch.float16,
        fp8_w8a8=False,
        int8_w8a16=False,
        int4_w4a16=False,
        gelu=False,
    )

    torch.testing.assert_close(c_tri.to(fp16_dtype), c_ref.to(fp16_dtype))
