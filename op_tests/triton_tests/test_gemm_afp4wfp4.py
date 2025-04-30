import torch
import triton
import triton.language as tl
import pytest
from aiter.ops.triton.gemm_afp4wfp4 import gemm_afp4wfp4


def generate_gemm_afp4wfp4_inputs(M, N, K):
    # 34 is two packed e2m1 values 0010 which is 1.0.
    x = torch.full((M, K//2), 34, dtype=torch.uint8, device='cuda')
    w = torch.full((N, K//2), 34, dtype=torch.uint8, device='cuda')
    # Scale of 1.0 in e8m0, bias 127.
    x_scales = torch.full((K//32, M), 127, dtype=torch.uint8, device='cuda')
    w_scales = torch.full((K//32, N), 127, dtype=torch.uint8, device='cuda')
    x_scales = x_scales.T
    w_scales = w_scales.T

    return x, w, x_scales, w_scales

def get_x_vals():

    # x_vals = [(1024 * v, 1024 * v, 1024 * v) for v in range(1, 9)]
    # x_vals += [(4864, 4096, 8192), (9728, 8192, 65536), (4864, 8192, 4160)]
    # x_vals += [
    #     (1, 1280, 8192),
    #     (32, 1280, 8192),
    #     (64, 1280, 8192),
    #     (128, 1280, 8192),
    #     (192, 1280, 8192),
    #     (256, 1280, 8192),
    #     (320, 1280, 8192),
    #     (512, 1280, 8192),
    #     (1024, 1280, 8192),
    #     (2048, 1280, 8192),
    #     (4096, 1280, 8192),
    #     (8192, 1280, 8192),
    #     (16384, 1280, 8192),
    #     (1, 8192, 1024),
    #     (32, 8192, 1024),
    #     (64, 8192, 1024),
    #     (128, 8192, 1024),
    #     (192, 8192, 1024),
    #     (256, 8192, 1024),
    #     (320, 8192, 1024),
    #     (512, 8192, 1024),
    #     (1024, 8192, 1024),
    #     (2048, 8192, 1024),
    #     (4096, 8192, 1024),
    #     (8192, 8192, 1024),
    #     (16384, 8192, 1024),
    # ]
    x_vals = [(1024, 1024, 1024)]
    return x_vals

@pytest.mark.parametrize("M, N, K", get_x_vals())
@pytest.mark.parametrize('dtype', [torch.float16, torch.bfloat16])
def test_gemm_a16_w16(M: int, N: int, K: int, dtype):
    x, w, x_scales, w_scales = generate_gemm_afp4wfp4_inputs(M, N, K)

    #torch_out = torch.matmul(x,w)

    triton_out = gemm_afp4wfp4(x, w, x_scales, w_scales, dtype)

    print(f"triton_out = {triton_out[0][0]}")

