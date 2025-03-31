import os
import json
import torch
import triton.language as tl

# Base directory where configs are located
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../"))

torch_to_tl_dtype = {torch.float16 : tl.float16, torch.bfloat16 : tl.bfloat16, torch.float32 : tl.float32}

def get_model_configs(config_path='./utils/model_configs.json', models="llama3,mistral_7B"):
    """
    Load model names from the configuration file.

    Args:
        config_path (str): User-provided path to the configuration JSON file.
        models: List of model names to retrieve, with pattern <modelfamily_modelsize>. If modelfamily specified only, retrieves all the modelsizes.

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

    Returns:
        list: A list of available model configs.
    """
    # Resolve config path relative to ./perf-kernels/
    config_path = os.path.join(BASE_DIR, config_file)

    with open(config_path, 'r') as f:
        configs = json.load(f)

    models = [f"{family}-{model}" for family in configs for model in configs[family]]

    return models