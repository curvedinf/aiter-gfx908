import triton
import triton.language as tl
import torch
# @triton.jit
# def mul(x, y):
#     return x * y

@triton.jit
def kernel(C, A, B, M, N, K,
          stride_cm, stride_cn,
          stride_am, stride_ak,
          stride_bk, stride_bn,
          BLOCK_M: tl.constexpr,
          BLOCK_N: tl.constexpr,
          BLOCK_K: tl.constexpr):
  pid_m = tl.program_id(0)
  pid_n = tl.program_id(1)
  
  offs_am = (pid_m * BLOCK_M + tl.arange(0, BLOCK_M)) % M
  offs_bn = (pid_n * BLOCK_N + tl.arange(0, BLOCK_N)) % N
  offs_k = tl.arange(0, BLOCK_K)
  a_ptrs = A + (offs_am[:, None] * stride_am + offs_k[None, :] * stride_ak)
  b_ptrs = B + (offs_k[:, None] * stride_bk + offs_bn[None, :] * stride_bn)

  accumulator = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.float32)
  for k in range(0, tl.cdiv(K, BLOCK_K)):
      # Load the next block of A and B, generate a mask by checking the K dimension.
      # If it is out of bounds, set it to 0.
      a = tl.load(a_ptrs, mask=offs_k[None, :] < K - k * BLOCK_K, other=0.0)
      b = tl.load(b_ptrs, mask=offs_k[:, None] < K - k * BLOCK_K, other=0.0)
      # We accumulate along the K dimension.
      accumulator = tl.dot(a, b, accumulator)
      # Advance the ptrs to the next K block.
      a_ptrs += BLOCK_K * stride_ak
      b_ptrs += BLOCK_K * stride_bk
      
#   tl.device_print(accumulator)
#   c = mul(accumulator, accumulator)
  # Write back the block of the output matrix C with masks.
  offs_cm = pid_m * BLOCK_M + tl.arange(0, BLOCK_M)
  offs_cn = pid_n * BLOCK_N + tl.arange(0, BLOCK_N)
  c_ptrs = C + stride_cm * offs_cm[:, None] + stride_cn * offs_cn[None, :]
  c_mask = (offs_cm[:, None] < M) & (offs_cn[None, :] < N)
  tl.store(c_ptrs, accumulator.to(tl.float16), mask=c_mask)

if __name__ == "__main__":
  C= torch.empty(16, 16, dtype=torch.float16, device="cuda")
  A= torch.ones(16, 16, dtype=torch.float16, device="cuda")
  B= torch.ones(16, 16, dtype=torch.float16, device="cuda")
  kernel[(1,1,1)](C, A, B, 16, 16, 16, 16, 1, 16, 1, 16, 1, 16, 16, 16)
  print(C)