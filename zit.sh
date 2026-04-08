#!/bin/bash
set -euo pipefail

LOG_FILE="/workspace/zit-background.log"

(
  set -euo pipefail

  COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
  MODELS_DIR="$COMFY_ROOT/models"
  TMP_DIR="/workspace/hf-downloads"
  HEALTH_URL="http://127.0.0.1:8188"

  download_hf_file() {
    local url="$1"
    local dest_dir="$2"
    local repo_path
    local filename

    repo_path="$(echo "$url" | sed -E 's#https://huggingface.co/[^/]+/[^/]+/resolve/[^/]+/##')"
    filename="$(basename "$url")"

    mkdir -p "$dest_dir"

    echo "Downloading: $url"
    hf download "Comfy-Org/z_image_turbo" "$repo_path" --local-dir "$TMP_DIR"
    mv -f "$TMP_DIR/$repo_path" "$dest_dir/$filename"
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

  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"

  export HF_HUB_ENABLE_HF_TRANSFER=1
  export HF_XET_HIGH_PERFORMANCE=1
  export HF_HUB_DOWNLOAD_TIMEOUT=60

  if ! command -v hf >/dev/null 2>&1; then
    pip install -U "huggingface_hub[hf_transfer]"
  fi

  download_hf_file \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors" \
    "$MODELS_DIR/text_encoders"

  download_hf_file \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors" \
    "$MODELS_DIR/vae"

  download_hf_file \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
    "$MODELS_DIR/diffusion_models"

  rm -rf "$TMP_DIR"

  echo "-------------------------------------------------------"
  echo "DOWNLOAD COMPLETE - Z-IMAGE-TURBO INSTALLED"
  echo "-------------------------------------------------------"
) >> "$LOG_FILE" 2>&1 &

echo "zit.sh: background watcher started, main boot can continue"
echo "zit.sh: tail -f $LOG_FILE"
exit 0