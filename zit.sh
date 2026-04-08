#!/bin/bash
set -e

COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
MODELS_DIR="$COMFY_ROOT/models"

echo "-------------------------------------------------------"
echo "STARTING MODULAR DOWNLOAD: Z-IMAGE-TURBO CONFIG"
echo "COMFY_ROOT=$COMFY_ROOT"
echo "MODELS_DIR=$MODELS_DIR"
echo "-------------------------------------------------------"

mkdir -p "$MODELS_DIR/text_encoders"
mkdir -p "$MODELS_DIR/vae"
mkdir -p "$MODELS_DIR/diffusion_models"

if [ ! -f "$MODELS_DIR/text_encoders/qwen_3_4b.safetensors" ]; then
  echo "Downloading Qwen Text Encoder (7.5GB)..."
  wget -c --show-progress -O "$MODELS_DIR/text_encoders/qwen_3_4b.safetensors" \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
else
  echo "Qwen Text Encoder already exists, skipping."
fi

if [ ! -f "$MODELS_DIR/vae/ae.safetensors" ]; then
  echo "Downloading VAE (320MB)..."
  wget -c --show-progress -O "$MODELS_DIR/vae/ae.safetensors" \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
else
  echo "VAE already exists, skipping."
fi

if [ ! -f "$MODELS_DIR/diffusion_models/z_image_turbo_bf16.safetensors" ]; then
  echo "Downloading Diffusion Model (11.5GB)..."
  wget -c --show-progress -O "$MODELS_DIR/diffusion_models/z_image_turbo_bf16.safetensors" \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
else
  echo "Diffusion Model already exists, skipping."
fi

echo "-------------------------------------------------------"
echo "DOWNLOAD COMPLETE"
echo "-------------------------------------------------------"