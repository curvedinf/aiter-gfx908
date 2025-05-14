# Initial try with aggregate load (AL)

Target shape
```
M = 32
N = 53248
K = 16384
```

Configs
```
BLOCK_SIZE_M = 32
BLOCK_SIZE_N = 64
BLOCK_SIZE_K = 512
GROUP_SIZE_M = 1
waves_per_eu = 0
kpack = 1
num_warps = 4
num_stages = 2
matrix_instr_nonkdim = 16
aggregated_loads = -1
```

When AL is enabled, the occupancy is LDS usage bound.
Here is how to calculate LDS usage
- tileA + tileB size: 0.5 x BK x (BM + BN)
- scale LDS size: K//32 x (BM + BN)
- LDS usage in total: (tileA size + tileB size) x nS + scale LDS size = (BM + BN) x (0.5 x nS x BK + K//32)

In this config
- Given BM, BN, and K, scale needs 48 KB LDS regardless of BK and nS
- A single tileA+tileB is 24 KB. So the maximum num_stages can be (160 - 48) / 24 = 4
- When nS = 2, there will be at most 24 KB mem transaction in flight per CU.
  This is slightly under-utilizing the L1 bandwidth
- When nS = 3, there will be about 24 x 2 = 48 KB mem requests.
  This is slightly over-utilizing the L1 bandwidth and stalls of buffer_load are expected.

## 2-stage orignal run (2471 GB/s) LDS: 98304

- IR dump: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS2-nW4/orig/`
- att trace: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS2-nW4/att_orig/`

In this version, `vmcnt(0)` is at the top of the loop but `buffer_load` is pushed to the end.
There are two problems
1. There is a large gap after `vmcnt(0)` and before `buffer_load`, therefore, L1 bandwidth is wasted
2. The `buffer_load` and the `vmcnt(0)` in the next iteration are too close, therefore, `vmcnt(0)`
   takes many cycles to wait for `buffer_load` to finish.
   
Since there are less than 24 KB mem request in flight, we never see long issue latency for `buffer_load`.

### hack0 (2720 GB/s) LDS: 98304

- Modified IR: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS2-nW4/hack0.ttgir`
- IR dump: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS2-nW4/hack0/`
- att trace: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS2-nW4/att_hack0/`

The general idea is to hoist `buffer_load` as close to `async_wait` as possible.
So we try to optimize at ttgir level by doing the following
- Hoist pointer increment and buffer index calculation **before** `async_wait`.
- Hoist `buffer_load_to_local` right after `async_wait`.
- Use `TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1`. This reduces the instructions between
  `async_wait` and `buffer_load_to_local`
- **Add token to the two `local_load` for scales, otherwise there will be a `vmcnt(0)` before the `local_load`.**

In this version, `buffer_load` is already very close the `vmcnt(0)` at the beginning of the loop.
However, there is still a very long waiting delay at `vmcnt(0)`. This means the loop does not have
enough compute. Given the kernel only has 24 KB mem requests in flight, it's time to increase
`num_stages`.


## 3-stage original run (2755 GB/s) LDS: 122880

- IR dump: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS3-nW4/orig/`
- att trace: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS3-nW4/att_orig/`

### hack1 (3090 GB/s) LDS: 122880

Add `token %125` for the two `local_load` for scales, otherwise there is a
`vmcnt(0)` before `ds_read_u8`.

- IR dump: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS3-nW4/hack1/`
- att trace: `aiter/study_aggregate_load/AL/BM32-BN64-BK512_nS3-nW4/att_hack1/`

Observations from trace
- One iteration of compute takes about 1100 cycles. Memory op takes about 1400 cycles.
  So the latency of one memory op cannot cover 2 iterations of compute.
  Therefore, `vmcnt(6)` is not waiting at all. And the kernel is doing compute while
  only 24 KB request is in flight.
- Then there are two directions
  - Reduce the cycles for compute.
    - There are waiting cycles for `ds_read`. We can prefetch LR, i.e.
      put `local_load` in the 1st stage.
    - There are a lot of `valu` and `salu` instructions. 
  - Go back to `num_stages=2` and increase tile size

## Larger tile init runtime (2800 GB/s)  LDS: 163840

Configs
```
BLOCK_SIZE_M = 32
BLOCK_SIZE_N = 128   // double the BN size
BLOCK_SIZE_K = 512
GROUP_SIZE_M = 1
waves_per_eu = 2
kpack = 1
num_warps = 4
num_stages = 2
matrix_instr_nonkdim = 16
aggregated_loads = -1
```

Resource usage
- LDS total: 160 KB
- tileA + tileB size: 40 KB
- scale LDS size: 80 KB

IR
- IR: `/app/aiter/study_aggregate_load/AL/BM32-BN128-BK512_nS2-nW4/orig`
- att: `/app/aiter/study_aggregate_load/AL/BM32-BN128-BK512_nS2-nW4/att_orig`

### hack2

Move 
