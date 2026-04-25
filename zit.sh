#!/bin/bash
set -euo pipefail

LOG_FILE="/workspace/zit-background.log"

(
  set -euo pipefail

  COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
  MODELS_DIR="$COMFY_ROOT/models"
  HEALTH_URL="http://127.0.0.1:8188"

  source <(curl -fsSL "https://raw.githubusercontent.com/samh-ai/AI-Rebels-config/main/registry.sh")

  download_hf_file() {
    local url="$1"
    local dest_dir="$2"
    local filename
    filename="$(basename "$url")"
    mkdir -p "$dest_dir"
    echo "Downloading: $url"
    curl -fL -H "Authorization: Bearer $HF_TOKEN" -o "$dest_dir/$filename" "$url"
  }

  echo "-------------------------------------------------------"
  echo "BACKGROUND WATCHER STARTED: Z-IMAGE-TURBO CONFIG (HF)"
  echo "-------------------------------------------------------"

  echo "Waiting for ComfyUI root to exist..."
  for i in $(seq 1 300); do
    if [ -d "$COMFY_ROOT" ]; then
      break
    fi
    sleep 2
  done

  if [ ! -d "$COMFY_ROOT" ]; then
    echo "Timed out waiting for ComfyUI root: $COMFY_ROOT"
    exit 1
  fi

  echo "Waiting for ComfyUI server on 8188..."
  for i in $(seq 1 600); do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  if ! curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Timed out waiting for ComfyUI server: $HEALTH_URL"
    exit 1
  fi

  echo "ComfyUI is live. Starting model download..."

  download_hf_file "${HF_MODELS[qwen_3_4b.safetensors]}" "$MODELS_DIR/text_encoders"

  download_hf_file "${HF_MODELS[ae.safetensors]}" "$MODELS_DIR/vae"

  download_hf_file "${HF_MODELS[z_image_turbo_bf16.safetensors]}" "$MODELS_DIR/diffusion_models"

  echo "-------------------------------------------------------"
  echo "DOWNLOAD COMPLETE - Z-IMAGE-TURBO INSTALLED"
  echo "-------------------------------------------------------"
) >> /proc/1/fd/1 2>> /proc/1/fd/2 &

echo "zit.sh: background watcher started, main boot can continue"
echo "zit.sh: tail -f $LOG_FILE"
exit 0