
import torch
import triton
import triton.language as tl

@triton.jit
def _fused_concat_zeros(
    x1_ptr,
    x2_ptr,
    out_cat_ptr,
    out_zeros_ptr,
    stride_in_x1_m,
    stride_in_x1_h,
    stride_in_x1_n,
    stride_in_x2_m,
    stride_in_x2_h,
    stride_in_x2_n,
    stride_in_cat_m,
    stride_in_cat_h,
    stride_in_cat_n,
    stride_in_zeros_m,
    stride_in_zeros_h,
    stride_in_zeros_n,
    BLOCK_SIZE_D1: tl.constexpr,
    BLOCK_SIZE_D2: tl.constexpr,
):
    stride_x1_m = tl.cast(stride_in_x1_m, tl.int64)
    stride_x1_h = tl.cast(stride_in_x1_h, tl.int64)
    stride_x1_n = tl.cast(stride_in_x1_n, tl.int64)
    stride_x2_m = tl.cast(stride_in_x2_m, tl.int64)
    stride_x2_h = tl.cast(stride_in_x2_h, tl.int64)
    stride_x2_n = tl.cast(stride_in_x2_n, tl.int64)
    stride_cat_m = tl.cast(stride_in_cat_m, tl.int64)
    stride_cat_h = tl.cast(stride_in_cat_h, tl.int64)
    stride_cat_n = tl.cast(stride_in_cat_n, tl.int64)
    stride_zeros_m = tl.cast(stride_in_zeros_m, tl.int64)
    stride_zeros_h = tl.cast(stride_in_zeros_h, tl.int64)
    stride_zeros_n = tl.cast(stride_in_zeros_n, tl.int64)

    pid_m = tl.program_id(0)
    pid_h = tl.program_id(1)
    tl.assume(pid_m >= 0)
    tl.assume(pid_h >= 0)

    n1_offs = tl.arange(0, BLOCK_SIZE_D1)
    n2_offs = tl.arange(0, BLOCK_SIZE_D2)
    
    x1 = tl.load(x1_ptr + pid_m * stride_x1_m + pid_h * stride_x1_h + n1_offs * stride_x1_n).to(out_cat_ptr.type.element_ty)
    x2 = tl.load(x2_ptr + pid_m * stride_x2_m + pid_h * stride_x2_h + n2_offs * stride_x2_n).to(out_cat_ptr.type.element_ty)
    tl.store(out_cat_ptr + pid_m * stride_cat_m + pid_h * stride_cat_h + n1_offs * stride_cat_n, x1)
    tl.store(out_cat_ptr + pid_m * stride_cat_m + pid_h * stride_cat_h + (BLOCK_SIZE_D1 + n2_offs) * stride_cat_n, x2)

    z = tl.zeros_like(x1)
    tl.store(out_zeros_ptr + pid_m * stride_zeros_m + pid_h * stride_zeros_h + n1_offs * stride_zeros_n, z)

def fused_concat_zeros(
    x1: torch.Tensor,
    x2: torch.Tensor,
):
    """
    Perform concat on x1 and x2 and aloocate zeros like x1

    Key parameters:
    - x1: Matrix X with shape (M, H, D1).
    - x2: Matrix W with shape (M, H, D2).

    QH must be multiple of KH

    Returns:
    - out_cat: The output matrix with shape (M, H, D1 + D2).
    - out_zeros: The output matrix with shape (M, H, D1).
    """
    M, H, D1 = x1.shape
    M2, H2, D2 = x2.shape

    assert H == H2, "dimension error"
    assert M == M2, "dimension error"
    assert triton.next_power_of_2(D1) == D1, "head dimension should be power of 2"
    assert triton.next_power_of_2(D2) == D2, "head dimension should be power of 2"

    out_cat = torch.empty((M, H, D1 + D2), dtype = x1.dtype, device = x1.device)
    out_zero = torch.empty((M, H, D1), dtype = x1.dtype, device = x1.device)
    
    grid = (M, H, )

    _fused_concat_zeros[grid](
        x1,
        x2,
        out_cat,
        out_zero,
        *x1.stride(),
        *x2.stride(),
        *out_cat.stride(),
        *out_zero.stride(),
        BLOCK_SIZE_D1=D1,
        BLOCK_SIZE_D2=D2,
    )

    return out_cat, out_zero
