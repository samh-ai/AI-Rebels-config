#!/bin/bash

COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
MODELS_DIR="$COMFY_ROOT/models"

echo "-------------------------------------------------------"
echo "STARTING MODULAR DOWNLOAD: Z-IMAGE-TURBO CONFIG"
echo "-------------------------------------------------------"

mkdir -p "$MODELS_DIR/text_encoders"
mkdir -p "$MODELS_DIR/vae"
mkdir -p "$MODELS_DIR/diffusion_models"

echo "Downloading Qwen Text Encoder (7.5GB)..."
wget -c --show-progress -O "$MODELS_DIR/text_encoders/qwen_3_4b.safetensors" \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"

echo "Downloading VAE (320MB)..."
wget -c --show-progress -O "$MODELS_DIR/vae/ae.safetensors" \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"

echo "Downloading Diffusion Model (11.5GB)..."
wget -c --show-progress -O "$MODELS_DIR/diffusion_models/z_image_turbo_bf16.safetensors" \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"

echo "-------------------------------------------------------"
echo "DOWNLOAD COMPLETE - COMFYUI WILL NOW INITIALIZE"
echo "-------------------------------------------------------"