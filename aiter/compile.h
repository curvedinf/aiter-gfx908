#ifndef TT_KERNEL_INCLUDES
#define TT_KERNEL_INCLUDES

#include <hip/hip_runtime.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

void unload_{kernel_name}(void);
void load_{kernel_name}(void);
// tt-linker: {kernel_name}:{full_signature}:{algo_info}
hipError_t{_placeholder} {kernel_name}(hipStream_t stream, {signature});

#endif
