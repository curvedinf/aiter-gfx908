# SPDX-License-Identifier: MIT
# Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
import triton
import triton.language as tl

@triton.jit
def remap_xcd(pid, GRID_MN, NUM_XCDS=8, CHUNK_SIZE=2):
    # Number of PIDs per XCD
    pids_per_xcd = (GRID_MN + NUM_XCDS - 1) // NUM_XCDS
    # Calculate number of tall XCDs
    tall_xcds = GRID_MN % NUM_XCDS
    tall_xcds = NUM_XCDS if tall_xcds == 0 else tall_xcds
    # Compute current XCD and local PID
    xcd = pid % NUM_XCDS
    local_pid = pid // NUM_XCDS
    # Calculate chunk index and position within chunk
    chunk_idx = local_pid // CHUNK_SIZE
    pos_in_chunk = local_pid % CHUNK_SIZE
    # Calculate new PID
    if xcd < tall_xcds:
        new_pid = chunk_idx * NUM_XCDS * CHUNK_SIZE + xcd * CHUNK_SIZE + pos_in_chunk
    else:
        new_pid = (
            tall_xcds * pids_per_xcd * CHUNK_SIZE
            + (xcd - tall_xcds) * (pids_per_xcd - 1) * CHUNK_SIZE
            + chunk_idx * NUM_XCDS * CHUNK_SIZE
            + pos_in_chunk
        )
    return new_pid

@triton.jit
def pid_grid(pid, num_pid_m, num_pid_n, GROUP_SIZE_M: tl.constexpr = 1):
    if GROUP_SIZE_M == 1:
        pid_m = pid % num_pid_m
        pid_n = pid // num_pid_m
    else:
        num_pid_in_group = GROUP_SIZE_M * num_pid_n
        group_id = pid // num_pid_in_group
        first_pid_m = group_id * GROUP_SIZE_M
        group_size_m = min(num_pid_m - first_pid_m, GROUP_SIZE_M)
        pid_m = first_pid_m + (pid % group_size_m)
        pid_n = (pid % num_pid_in_group) // group_size_m

    return pid_m, pid_n
