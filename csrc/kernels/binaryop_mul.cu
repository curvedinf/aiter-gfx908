#include "binary_operator.cuh"

torch::Tensor aiter_mul(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::MulOp, false>(input, other);
}

torch::Tensor aiter_mul_(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::MulOp, true>(input, other);
}
