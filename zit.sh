#!/bin/bash
set -euo pipefail

COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
MODELS_DIR="$COMFY_ROOT/models"
TMP_DIR="/workspace/hf-downloads"

echo "-------------------------------------------------------"
echo "STARTING MODULAR DOWNLOAD: Z-IMAGE-TURBO CONFIG (HF)"
echo "-------------------------------------------------------"

mkdir -p "$MODELS_DIR/text_encoders" "$MODELS_DIR/vae" "$MODELS_DIR/diffusion_models"
mkdir -p "$TMP_DIR"

export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_XET_HIGH_PERFORMANCE=1
export HF_HUB_DOWNLOAD_TIMEOUT=60

if ! command -v hf >/dev/null 2>&1; then
  pip install -U "huggingface_hub[hf_transfer]"
fi

echo "Downloading files from HF..."
hf download Comfy-Org/z_image_turbo \
  "split_files/text_encoders/qwen_3_4b.safetensors" \
  "split_files/vae/ae.safetensors" \
  "split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
  --local-dir "$TMP_DIR"

mv -f "$TMP_DIR/split_files/text_encoders/qwen_3_4b.safetensors" \
      "$MODELS_DIR/text_encoders/qwen_3_4b.safetensors"

mv -f "$TMP_DIR/split_files/vae/ae.safetensors" \
      "$MODELS_DIR/vae/ae.safetensors"

mv -f "$TMP_DIR/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
      "$MODELS_DIR/diffusion_models/z_image_turbo_bf16.safetensors"

rm -rf "$TMP_DIR"

echo "-------------------------------------------------------"
echo "DOWNLOAD COMPLETE - COMFYUI WILL NOW INITIALIZE"
echo "-------------------------------------------------------"