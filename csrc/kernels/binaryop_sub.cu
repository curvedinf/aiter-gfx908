#include "binary_operator.cuh"

torch::Tensor aiter_sub(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::SubOp, false>(input, other);
}

torch::Tensor aiter_sub_(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::SubOp, true>(input, other);
}
