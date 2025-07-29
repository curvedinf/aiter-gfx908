import torch
import torch.nn.functional as F
import triton
import pytest
from aiter.ops.triton.ff_a16w16 import ff_a16w16_gated, ff_a16w16_nogate
from op_tests.triton_tests.test_gemm_a16w16 import get_x_vals
from op_tests.triton_tests.utils.types import str_to_torch_dtype


def generate_ff_a16w16_inputs(batch, intermediate_dim, hidden_dim, dtype, layout="TN", output=True):
    if isinstance(dtype, str):
        dtype = str_to_torch_dtype[dtype]

    # TN is default layout
    if layout[0] == "T":
        x = torch.randn((batch, hidden_dim), dtype=dtype).cuda()
    else:
        x = torch.randn((hidden_dim, batch), dtype=dtype).cuda().T

    if layout[1] == "T":
        w1 = torch.randn((hidden_dim, intermediate_dim * 2), dtype=dtype).cuda().T
        w2 = torch.randn((intermediate_dim, hidden_dim), dtype=dtype).cuda().T
    else:
        w1 = torch.randn((intermediate_dim * 2, hidden_dim), dtype=dtype).cuda()
        w2 = torch.randn((hidden_dim, intermediate_dim), dtype=dtype).cuda()

    w1 = w1 / (intermediate_dim**0.5)  # scale down output variance
    w2 = w2 / (hidden_dim**0.5)

    y = None
    if output:
        y = torch.empty((batch, hidden_dim), dtype=dtype).cuda()
        out_dtype = (None,)
    else:
        out_dtype = dtype

    return x, w1, w2, out_dtype, y


@pytest.mark.parametrize(
    "activation", ["geglu", "swiglu", "reglu"]
)
@pytest.mark.parametrize("batch, hidden_dim, intermediate_dim", get_x_vals())
@pytest.mark.parametrize("dtype", [torch.float16, torch.bfloat16])
@pytest.mark.parametrize("output", [True, False])
def test_ff_a16w16_gated(batch: int, hidden_dim: int, intermediate_dim: int, dtype, output, activation):
    x, w1, w2, out_dtype, y = generate_ff_a16w16_inputs(
        batch, hidden_dim, intermediate_dim, dtype, output=output
    )
    print(x.shape, w1.shape, w2.shape)
    torch_out = F.linear(x, w1, bias=None)
    if activation == "geglu":
        gating = F.gelu(torch_out[:, :intermediate_dim], approximate="tanh")
    elif activation == "swiglu":
        gating = F.silu(torch_out[:, :intermediate_dim])
    elif activation == "reglu":
        gating = F.relu(torch_out[:, :intermediate_dim])
    else:
        raise Exception(f"Unsupported activation: {activation}")
    torch_y = torch_out[:, intermediate_dim:]
    torch_intermediate = gating * torch_y
    torch_out = F.linear(torch_intermediate, w2, bias=None)

    if output:
        triton_out = ff_a16w16_gated(
            x,
            w1,
            w2,
            out_dtype,
            y,
            activation=activation,
        )
    else:
        triton_out = ff_a16w16_gated(
            x,
            w1,
            w2,
            out_dtype,
            activation=activation,
        )

    """
    Note: There's a small distinction between Triton and Torch's implementations of silu
    (due to tl.sigmoid() vs torch.sigmoid()). The gated outputs can differ by as much as 3%.
    """
    triton.testing.assert_close(triton_out, torch_out, atol=1e-1, rtol=1e-1)
