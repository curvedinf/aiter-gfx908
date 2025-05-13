- `orig_mfma16` --> 3143 tflops
- `hack_mfma16_0.ttgir`: Slice dot into 2 pieces along the K dim. --> 3510 tflops
- `hack_mfma16_1.ttgir`: On top of `hack_mfma16_0.ttgir`, put ops in the right cluster. This version does not enable pingpong yet. It only has sched.barrier but no s.barrier --> 3970 tflops

## 2 slices along k dimension

```llvm

async_load AB(n+1) 2/2
local_load AB(n) 1/2
async_wait AB(n) 2/2  <-- wave03 reaches here first

dot(n) 1/2

s_barrier  <-- wave03 reaches here, wave47 reaches the previous async_wait
               all data in AB(n) 2/2 is ready

async_load AB(n+1) 1/2
local_load AB(n) 2/2
async_wait AB(n+1) 1/2  <-- wave03 reaches here first

dot(n) 2/2

s_barrier  <-- when wave03 reaches here, wave47 reaches the previous async_wait
               all data in AB(n+1) 1/2 is ready
```


# Slice dot into 4 pieces along M and N dimension

```
A = [A0,
     A1]
B = [B0, B1]
C = [C00, C01
     C10, C11]
C00 = A0 * B0
C01 = A0 * B1
C10 = A1 * B0
C11 = A1 * B1
```
     
```llvm
async_wait A0, B0, SA, SB (n)

loop starts

async_load A0, B0 (n+1) [4 buffer_load]
async_load SA, SB (n+1) [2 buffer_load]
local_load A0, B0 (n)
local_load SA0, SB0 (n)
async_wait B1 (n)       [num = 8]

dot C00

s_barrier

async_copy B1 (n+1) [2 buffer_load]
local_load B1 (n)
local_load SB1 (n)
async_wait A1 (n)       [num = 8]

dot C01

s_barrier

async_copy A1 (n+1) [2 buffer_load]
local_load A1 (n)
local_load SA1 (n)
async_wait A0, B0, SA, SB (n+1)  [num = 4]

dot C10
dot C11
```
