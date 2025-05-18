# M128-N106496-K16384

Initial config
```
BLOCK_SIZE_M = 128
BLOCK_SIZE_N = 128
BLOCK_SIZE_K = 512
GROUP_SIZE_M = 1
waves_per_eu = 2
kpack = 1
num_warps = 4
num_stages = 2
matrix_instr_nonkdim = 16
aggregated_loads = 1
```

Notes
- `BLOCK_M` is chosen to be M to avoid re-loading B tensor
- Chose `BLOCK_N` as large but make sure we have enough wgs/tgs
  - workgroup (wg) = threadgroup (tg)
- `BLOCK_K` does not matter, `BLOCK_K` + `num_stages` matters
- mfma16 is more efficient than mfma32
- Disable `aggregated_load` to save LDS for pipeline

Command
```bash
AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 rocprof --stats python op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 128 106496 16384 --metric bandwidth
```

Initial bandwidth: 3.1 TB/s

## `num_warps=8` pingpong


### clusterization

```
wave0-3                            wave4-7
async_wait A,B,SA,SB[buf0]

async_load A,B,SA,SB[buf1]         local_load A,B,SA,SB[buf1]

s_barrier

local_load A,B,SA,SB[buf0]
dot

```

This version moves `buffer_load` up and separate `buffer_load` and non-mem.
- bandwidth: 3.2 TB/s
- ttgir hack: `/app/aiter/skinny_M128/hack0.ttgir`
- IR_dump: `/app/aiter/skinny_M128/hack0/`
- att: `/app/aiter/skinny_M128/att_hack0/`

### Enable pingpong

- bandwidth: 3.68 TB/s
- ttgir hack: `/app/aiter/skinny_M128/hack1.ttgir`
- IR_dump: `/app/aiter/skinny_M128/hack1/`
- att: `/app/aiter/skinny_M128/att_hack1/`

### prefetch all `ds_read`

- bandwidth: 3.68 TB/s
- ttgir hack: `/app/aiter/skinny_M128/hack2.ttgir`
- IR_dump: `/app/aiter/skinny_M128/hack2/`
- att: `/app/aiter/skinny_M128/att_hack2/`

### move `buffer_load` closer to `async_wait`

- bandwidth: 3.78 TB/s
- ttgir hack: `/app/aiter/skinny_M128/hack3.ttgir`
- IR_dump: `/app/aiter/skinny_M128/hack3/`
- att: `/app/aiter/skinny_M128/att_hack3/`


## `num_wave=8` pingpong version 2

The previous version has a dependency issue. Check [this comment](https://github.com/ROCm/triton-internal/issues/822#issuecomment-2888470782) for more detail.

This new design should address the problem

```
wave0-3                            wave4-7
----------------------
async_wait A,SA[buf0]

async_copy A,SA[buf1]
                                 -------------------------
s_barrier                          async_wait A,SA[buf0]

local_load A,SA[buf0]              async_copy A,SA[buf1]
async_wait B,SB[buf0]              s_barrier

async_copy B,SB[buf1]              local_load A,SA[buf0]

s_barrier                          async_wait B,SB[buf0]

local_load B,SB[buf0]              async_load B,SB[buf1]
dot

--------------------

async_wait A,SA[buf1]              s_barrier

async_copy A,SA[buf0]              local_load B,SB[buf0]
                                   dot
                                 --------------------------

s_barrier                          async_wait A,SA[buf1]

local_load A,SA[buf1]              async_copy A,SA[buf0]
async_wait B,SB[buf1]              s_barrier

async_copy B,SB[buf0]              local_load A,SA[buf1]

s_barrier                          async_wait B,SB[buf1]

local_load B,SB[buf1]              async_load B,SB[buf0]
dot
```

- bandwidth: 3.77 TB/s
- ttgir hack: `/app/aiter/skinny_M128/hack5.ttgir`
- IR_dump: `/app/aiter/skinny_M128/hack5/`
- att: `/app/aiter/skinny_M128/att_hack5/`
