#!/bin/bash
# Registry of custom nodes and model download links.
# Sourced by setup scripts — do not execute directly.

# Custom nodes — key: short name, value: git clone URL
declare -A CUSTOM_NODES
CUSTOM_NODES[seedvr2]="https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler"
CUSTOM_NODES[rgthree]="https://github.com/rgthree/rgthree-comfy"
CUSTOM_NODES[lanpaint]="https://github.com/scraed/LanPaint"

# HF models — key: filename, value: full download URL
declare -A HF_MODELS

# Models
HF_MODELS[seedvr2_ema_7b_fp16.safetensors]="https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_7b_fp16.safetensors"
HF_MODELS[z_image_turbo_bf16.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
HF_MODELS[big_lust_v1.6.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/big_lust_v1.6.safetensors"
HF_MODELS[flux-2-klein-9b-fp8.safetensors]="https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors"


# LoRAs
HF_MODELS[Flux2-Klein-9B-consistency-V2.safetensors]="https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/resolve/main/Flux2-Klein-9B-consistency-V2.safetensors"
HF_MODELS[Klein-consistency.safetensors]="https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/resolve/main/Klein-consistency.safetensors"
HF_MODELS[bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors]="https://huggingface.co/Alissonerdx/BFS-Best-Face-Swap/resolve/main/bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors"

# Text Encoders
HF_MODELS[qwen_3_4b.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
HF_MODELS[qwen_3_8b_fp8mixed.safetensors]="https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors"
# VAE
HF_MODELS[ema_vae_fp16.safetensors]="https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors"
HF_MODELS[ae.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
HF_MODELS[flux2-vae.safetensors]="https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"
