from jinja2 import Template
from csrc.cpp_itfs.utils import compile_template_op, AITER_CORE_DIR


MD_NAME = "top_k_renorm_probs"

with open(
    f"{AITER_CORE_DIR}/csrc/cpp_itfs/sampling/top_k_renorm_probs.cpp.jinja",
    "r",
) as f:
    src_template = Template(f.read())


def compile(
    d: int,
    folder: str = None,
):
    return compile_template_op(
        src_template,
        MD_NAME,
        [
            f"{AITER_CORE_DIR}/csrc/cpp_itfs/utils.h",
            f"{AITER_CORE_DIR}/csrc/cpp_itfs/sampling/sampling.cuh",
            f"{AITER_CORE_DIR}/csrc/cpp_itfs/sampling/vec_dtypes.cuh",
        ],
        folder=folder,
        d=d,
    )


def top_k_renorm_probs(
    probs,
    maybe_top_k_arr,
    top_k_val,
):
    import torch
    from csrc.cpp_itfs.torch_utils import torch_to_c_types

    probs = probs.float()
    batch_size = probs.size(0)
    vocab_size = probs.size(1)
    output = torch.empty_like(probs)

    func = compile(vocab_size)
    (
        probs_ptr,
        output_ptr,
        top_k_arr_ptr,
        top_k_val,
        vocab_size,
        batch_size,
        stream,
    ) = torch_to_c_types(
        probs,
        output,
        maybe_top_k_arr,
        top_k_val,
        vocab_size,
        batch_size,
        torch.cuda.current_stream(),
    )
    func(
        probs_ptr,
        output_ptr,
        top_k_arr_ptr,
        batch_size,
        top_k_val,
        stream,
    )
    return output
