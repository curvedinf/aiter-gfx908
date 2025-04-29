import torch
import triton
import triton.language as tl


def is_cdna4():
    return triton.runtime.driver.active.get_current_target().arch == 'gfx950'

def is_cdna3():
    return triton.runtime.driver.active.get_current_target().arch == 'gfx942'

def get_torch_fp8_type():
    return torch.float8_e4m3fn if is_cdna4() else torch.float8_e4m3fnuz

def get_torch_bf8_type():
    return torch.float8_e5m2 if is_cdna4() else torch.float8_e5m2fnuz

def str_to_torch_type(str):
    arg_to_torch_dtype = {
    'fp16': torch.float16,
    'bf16': torch.bfloat16,
    'fp32': torch.float32,
    "bf8": get_torch_bf8_type(),
    "fp8": get_torch_fp8_type()
    }
    return arg_to_torch_dtype[str]

