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
HF_MODELS[seedvr2_ema_7b_fp16.safetensors]="https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_7b_fp16.safetensors"
HF_MODELS[ema_vae_fp16.safetensors]="https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors"
HF_MODELS[qwen_3_4b.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
HF_MODELS[ae.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
HF_MODELS[z_image_turbo_bf16.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
HF_MODELS[big_lust_v1.6.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/big_lust_v1.6.safetensors"
