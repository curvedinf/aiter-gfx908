import os
import json
import torch

# Base directory where configs are located
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../"))


def get_model_configs(config_path='./utils/model_configs.json', model_families=["llama3"], model="all"):
    """
    Load model names from the configuration file.

    Args:
        config_path (str): User-provided path to the configuration JSON file.
        model_families (list): List of model family names to retrieve.

    Returns:
        dict: A dictionary of available models and their configurations for the specified families.
    """
    # Resolve config path relative to ./perf-kernels/
    config_path = os.path.join(BASE_DIR, config_path)

    with open(config_path, 'r') as f:
        configs = json.load(f)

    # Extract models and their configurations for the specified families
    filtered_configs = {}

    for family in model_families:
        if family in configs:
            # Check if model filtering is required
            if model == "all":
                # Include all models in the family
                for model_size, model_configs in configs[family].items():
                    filtered_configs[f"{family}-{model_size}"] = model_configs
            else:
                # Parse the model string (e.g., llama3_8B or llama3-8B)
                delimiter = "_" if "_" in model else "-"
                model_parts = model.split(delimiter)

                # Check if the family and size match
                if len(model_parts) == 2 and model_parts[0] == family:
                    model_size = model_parts[1]
                    if model_size in configs[family]:
                        filtered_configs[f"{family}-{model_size}"] = configs[family][model_size]

    if not filtered_configs:
        print(f"Warning: No models selected for families: {model_families} with filter: '{model}'")

    return filtered_configs


def get_available_models(config_file='utils/model_configs.json', model_families=["llama3"]):
    """
    Load model names from the configuration file.

    Args:
        config_file (str): Path to the configuration JSON file.
        model_families (list): List of model family names to retrieve.

    Returns:
        list: A list of available models for the specified families.
    """
    # Resolve config path relative to ./perf-kernels/
    config_path = os.path.join(BASE_DIR, config_file)

    with open(config_path, 'r') as f:
        configs = json.load(f)

    models = [f"{family}-{model}" for family in model_families if family in configs for model in configs[family]]

    return models


# Flash Attention Benchmark Utils

class MetaData():
    cu_seqlens_q = None
    cu_seqlens_k = None
    max_seqlens_q = 0
    max_seqlens_k = 0
    bias = None
    alibi_slopes = None
    causal = False
    persistent = None
    num_contexts = 0
    varlen = False
    int8 = False
    layout = None
    dropout_p, return_encoded_softmax = 0.0, False

    def __init__(self, sm_scale=1.0):
        self.sm_scale = sm_scale

    def set_varlen_params(self, cu_seqlens_q, cu_seqlens_k):
        self.varlen = True
        self.layout = 'thd'
        self.cu_seqlens_q = cu_seqlens_q
        self.cu_seqlens_k = cu_seqlens_k
        # Without "varlen", there should still be one sequence.
        assert len(cu_seqlens_q) >= 2
        assert len(cu_seqlens_q) == len(cu_seqlens_k)
        self.num_contexts = len(cu_seqlens_q) - 1
        for i in range(0, self.num_contexts):
            self.max_seqlens_q = max(cu_seqlens_q[i + 1].item() - cu_seqlens_q[i].item(), self.max_seqlens_q)
            self.max_seqlens_k = max(cu_seqlens_k[i + 1].item() - cu_seqlens_k[i].item(), self.max_seqlens_k)

    def set_persistent(self, persistent):
        self.persistent = persistent

    def set_int8_params(self, q_descale, k_descale, v_descale, p_scale, p_descale):
        self.int8 = True
        self.q_descale = q_descale
        self.k_descale = k_descale
        self.v_descale = v_descale
        self.p_scale = p_scale
        self.p_descale = p_descale
        self.use_p_scale = (p_scale is not None) and (p_descale is not None) and (v_descale is not None)
        self.int8_kv = (q_descale is None) and (k_descale is not None) and (v_descale is not None)

    def need_bias(self, bias, batch, nheads, seqlen_q, seqlen_k):
        assert bias.is_cuda
        assert bias.dim() == 4
        assert bias.shape[0] == 1
        assert bias.shape[2:] == (seqlen_q, seqlen_k)
        self.bias = bias

    def need_alibi(self, alibi_slopes, batch, nheads):
        assert alibi_slopes.is_cuda
        assert alibi_slopes.dim() == 2
        assert alibi_slopes.shape[0] == batch
        assert alibi_slopes.shape[1] == nheads
        self.alibi_slopes = alibi_slopes

    def need_causal(self):
        self.causal = True

    def need_dropout(self, dropout_p, return_encoded_softmax):
        self.dropout_p = dropout_p
        self.return_encoded_softmax = return_encoded_softmax

    def check_args(self, q, k, v, o):
        assert q.dim() == k.dim() and q.dim() == v.dim()

        batch, nheads_q, nheads_k, head_size = get_shape_from_layout(q, k, self)
        if self.varlen:
            assert q.dim() == 3
            assert self.cu_seqlens_q is not None
            assert self.cu_seqlens_k is not None
            assert len(self.cu_seqlens_q) == len(self.cu_seqlens_k)
            # TODO: Remove once bias is supported with varlen
            assert self.bias is None
            # TODO:Remove once dropout is supported with varlen
            assert self.dropout_p == 0.0
            assert not self.return_encoded_softmax
        else:
            assert q.dim() == 4
            assert self.max_seqlens_q > 0 and self.max_seqlens_k > 0
            assert self.cu_seqlens_q is None and self.cu_seqlens_k is None
        assert k.shape == v.shape
        assert q.shape[-1] == k.shape[-1] and q.shape[-1] == v.shape[-1]
        # TODO: Change assert if we support qkl f8 and v f16
        if self.int8:
            if self.int8_kv:
                assert v.dtype == k.dtype and k.dtype == torch.int8
                assert q.dtype != k.dtype
                assert (self.v_descale is not None) and (self.k_descale is not None)
            else:
                assert q.dtype == k.dtype and q.dtype == v.dtype and q.dtype == torch.int8
                assert (self.q_descale is not None) and (self.k_descale is not None) and (self.v_descale is not None)
                if self.use_p_scale:
                    assert (self.p_scale is not None) and (self.p_descale is not None)
        else:
            assert q.dtype == k.dtype and q.dtype == v.dtype
        assert head_size <= 256
        assert o.shape == q.shape
        assert (nheads_q % nheads_k) == 0
        assert self.layout is not None
        assert self.layout == 'thd' or not self.varlen


def get_shape_from_layout(q, k, metadata):
    if metadata.layout == 'thd':
        nheads_q, nheads_k = q.shape[1], k.shape[1]
        head_size = q.shape[-1]
        batch = metadata.num_contexts
    elif metadata.layout == 'bhsd':
        batch, nheads_q, _, head_size = q.shape
        nheads_k = k.shape[1]
    elif metadata.layout == 'bshd':
        batch, _, nheads_q, head_size = q.shape
        nheads_k = k.shape[2]
    else:
        assert False, "Got unsupported layout."
    return batch, nheads_q, nheads_k, head_size



def mha_input_helper(Z, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, equal_seqlens=False):
    torch.manual_seed(20)

    # Random sequence lengths. Using N_CTX * Z as kind of max of sum of individual seqs
    if not equal_seqlens:
        max_seqlens_q = N_CTX_Q
        max_seqlens_k = N_CTX_K
        if N_CTX_Q == N_CTX_K:
            seqlens_q = torch.randint(1, max_seqlens_q + 1, (Z, ), dtype=torch.int32)
            seqlens_k = seqlens_q
        else:
            seqlens_q = torch.randint(1, max_seqlens_q + 1, (Z, ), dtype=torch.int32)
            seqlens_k = torch.randint(1, max_seqlens_k + 1, (Z, ), dtype=torch.int32)
    else:
        seqlens_q = torch.full((Z, ), N_CTX_Q)
        seqlens_k = torch.full((Z, ), N_CTX_K)

    # Calculate cumulative sequence lengths
    cu_seqlens_q = torch.cat([torch.tensor([0], dtype=torch.int32), seqlens_q.cumsum(dim=0, dtype=torch.int32)])
    cu_seqlens_k = torch.cat([torch.tensor([0], dtype=torch.int32), seqlens_k.cumsum(dim=0, dtype=torch.int32)])
    cu_seqlens_q = cu_seqlens_q.to(device="cuda")
    cu_seqlens_k = cu_seqlens_k.to(device="cuda")

    # Initialize q, k, v with variable lengths
    total_q = cu_seqlens_q[-1].item()
    total_k = cu_seqlens_k[-1].item()
    q = torch.randn((total_q, HQ, D_HEAD), dtype=dtype, device="cuda").normal_(mean=0., std=0.5).requires_grad_()
    k = torch.randn((total_k, HK, D_HEAD), dtype=dtype, device="cuda").normal_(mean=0., std=0.5).requires_grad_()
    v = torch.randn((total_k, HK, D_HEAD), dtype=dtype, device="cuda").normal_(mean=0., std=0.5).requires_grad_()
    sm_scale = D_HEAD**-0.5
    input_metadata = MetaData(sm_scale=sm_scale)
    input_metadata.set_varlen_params(cu_seqlens_q, cu_seqlens_k)
    return q, k, v, input_metadata