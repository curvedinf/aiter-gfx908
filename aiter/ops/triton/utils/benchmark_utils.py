import os
import json
import torch

# Base directory where configs are located
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../"))


def get_model_configs(config_path='./utils/model_configs.json', models="llama3,mistral_7B"):
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

    if models=="all":
        models = [model for model in configs]
    else:
        models = models.replace(" ", "").split(',')

    for model in models:
        delimiter = "_" if "_" in model else "-"
        model_specs = model.split(delimiter)
        model_family = model_specs[0] 
        
        if model_family in configs:
            model_size = model_specs[1] if len(model_specs) > 1 else None
            # Check if model filtering is required
            if model_size is None: # Include all models in the family
                # Include all models in the family
                for model_size, model_configs in configs[model_family].items():
                    filtered_configs[f"{model_family}-{model_size}"] = model_configs
            else:
                if model_size in configs[model_family]:
                    filtered_configs[f"{model_family}-{model_size}"] = configs[model_family][model_size]

    if not filtered_configs:
        print(f"Warning: No models selected with the provided model names: {models}")

    return filtered_configs


def get_available_models(config_file='utils/model_configs.json'):
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

    models = [f"{family}-{model}" for family in configs for model in configs[family]]

    return models


def mha_input_helper(Z, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, is_varlen=False, layout="thd"):
    torch.manual_seed(20)
    assert layout in ["thd"], f"mha only supports thd layout. Invalid layout: {layout}"

    # Random sequence lengths. Using N_CTX * Z as kind of maximum possible sum of individual seqs
    if is_varlen:
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
    return q, k, v, cu_seqlens_q, cu_seqlens_k, sm_scale