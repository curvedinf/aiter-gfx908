# gfx908 build-profile environment for the aiter-gfx908 worktree.
# Source this before any build/test command in this checkout.
# All knobs are worktree-specific; nothing here touches ~/aiter.

export GPU_ARCHS=gfx908
export PYTORCH_ROCM_ARCH=gfx908
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export LD_LIBRARY_PATH="/opt/rocm/lib:${LD_LIBRARY_PATH:-}"
# Keep every JIT artifact inside this worktree.
export AITER_JIT_DIR="$HOME/aiter-gfx908/.jit-build"
# Instance pruning (72 -> 18 files; see GFX908_BUILD_PLAN.md Step 2).
export AITER_CK_INSTANCE_LIST="$HOME/aiter-gfx908/csrc/ck_gemm_a8w8/a8w8_instance_keep_list.txt"
# Uncomment for a pruned prebuild / strict serving:
# export PREBUILD_KERNELS=4
# export AITER_MI100_MODULES=module_aiter_core,module_custom,module_custom_all_reduce,module_gemm_a8w8,module_gemm_common
# export AITER_JIT_ALLOWLIST="$AITER_MI100_MODULES"
# export AITER_CK_STRICT=1
