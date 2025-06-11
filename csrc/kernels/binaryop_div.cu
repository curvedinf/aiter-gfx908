#include "binary_operator.cuh"

torch::Tensor aiter_div(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::DivOp, false>(input, other);
}

torch::Tensor aiter_div_(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::DivOp, true>(input, other);
}
