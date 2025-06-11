#include "binary_operator.cuh"

torch::Tensor aiter_add(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::AddOp, false>(input, other);
}

// inp interface
torch::Tensor aiter_add_(torch::Tensor &input, torch::Tensor &other)
{
  return binary_operation<aiter::AddOp, true>(input, other);
}
