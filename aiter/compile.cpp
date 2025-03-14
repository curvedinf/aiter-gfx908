/* clang-format off */
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <hip/hip_runtime.h>

// helpers to check for cuda errors
#define CUDA_CHECK(ans) {{\
    gpuAssert((ans), __FILE__, __LINE__);\
  }}\

static inline void gpuAssert(hipError_t code, const char *file, int line) {{
  if (code != hipSuccess) {{
    const char *prefix = "Triton Error [CUDA]: ";
    const char *str;
    hipDrvGetErrorString(code, &str);
    char err[1024] = {{0}};
    strcat(err, prefix);
    strcat(err, str);
    printf("%s\\n", err);
    exit(code);
  }}
}}

// globals
#define HSACO_NAME {kernel_name}_hsaco
hipModule_t {kernel_name}_mod = NULL;
hipFunction_t {kernel_name}_func = NULL;
unsigned char HSACO_NAME[{bin_size}] = {{ {bin_data} }};


void unload_{kernel_name}(void) {{
    CUDA_CHECK(hipModuleUnload({kernel_name}_mod));
}}

// TODO: some code duplication with `runtime/backend/cuda.c`
void load_{kernel_name}() {{
    int dev = 0;
    void *bin = (void *)&HSACO_NAME;
    int shared = {shared};
    CUDA_CHECK(hipModuleLoadData(&{kernel_name}_mod, bin));
    CUDA_CHECK(hipModuleGetFunction(&{kernel_name}_func, {kernel_name}_mod, "{triton_kernel_name}"));
    // set dynamic shared memory if necessary
    int shared_optin;
    CUDA_CHECK(hipDeviceGetAttribute(&shared_optin, hipDeviceAttributeSharedMemPerBlockOptin, dev));
    if (shared > 49152 && shared_optin > 49152) {{
      CUDA_CHECK(hipFuncSetCacheConfig({kernel_name}_func, hipFuncCachePreferShared));
      CUDA_CHECK(hipFuncSetAttribute(reinterpret_cast<const void*>({kernel_name}_func), hipFuncAttributeMaxDynamicSharedMemorySize, shared_optin))
    }}
}}

/*
{kernel_docstring}
*/
hipError_t {kernel_name}(hipStream_t stream, {signature}) {{
    if ({kernel_name}_func == NULL)
       load_{kernel_name}();
    unsigned int gX = {gridX};
    unsigned int gY = {gridY};
    unsigned int gZ = {gridZ};
    hipDeviceptr_t global_scratch = 0;
    void *args[{num_args}] = {{ {arg_pointers} }};
    // TODO: shared memory
    if(gX * gY * gZ > 0)
      return hipModuleLaunchKernel({kernel_name}_func, gX, gY, gZ, {num_warps} * 32, 1, 1, {shared}, stream, args, NULL);
}}
