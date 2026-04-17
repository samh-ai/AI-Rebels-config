#!/bin/bash
set -euo pipefail

LOG_FILE="/workspace/seedvr-background.log"

(
  set -euo pipefail

  COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
  CUSTOM_NODES_DIR="$COMFY_ROOT/custom_nodes"
  SEEDVR_NODE_DIR="$CUSTOM_NODES_DIR/ComfyUI-SeedVR2_VideoUpscaler"
  SEEDVR_MODELS_DIR="$COMFY_ROOT/models/SEEDVR2"
  HEALTH_URL="http://127.0.0.1:8188"

  echo "-------------------------------------------------------"
  echo "BACKGROUND WATCHER STARTED: SEEDVR2 CONFIG"
  echo "-------------------------------------------------------"

  echo "Waiting for ComfyUI root to exist..."
  for i in $(seq 1 300); do
    if [ -d "$COMFY_ROOT" ]; then break; fi
    sleep 2
  done

  if [ ! -d "$COMFY_ROOT" ]; then
    echo "Timed out waiting for ComfyUI root: $COMFY_ROOT"
    exit 1
  fi

  echo "Waiting for ComfyUI server on 8188..."
  for i in $(seq 1 600); do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then break; fi
    sleep 2
  done

  if ! curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Timed out waiting for ComfyUI server: $HEALTH_URL"
    exit 1
  fi

  echo "ComfyUI is live. Installing custom node and downloading models..."

  export HF_HUB_ENABLE_HF_TRANSFER=1
  export HF_XET_HIGH_PERFORMANCE=1
  export HF_HUB_DOWNLOAD_TIMEOUT=60

  if ! command -v hf >/dev/null 2>&1; then
    pip install -U "huggingface_hub[hf_transfer]"
  fi

  # Install custom node
  if [ ! -d "$SEEDVR_NODE_DIR" ]; then
    echo "Cloning ComfyUI-SeedVR2_VideoUpscaler..."
    git clone https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler "$SEEDVR_NODE_DIR"
  else
    echo "Custom node already present, skipping clone."
  fi

  if [ -f "$SEEDVR_NODE_DIR/requirements.txt" ]; then
    echo "Installing requirements..."
    pip install -q -r "$SEEDVR_NODE_DIR/requirements.txt"
  fi

  # Download models
  mkdir -p "$SEEDVR_MODELS_DIR"

  echo "Downloading seedvr2_ema_7b_fp16.safetensors..."
  hf download "numz/SeedVR2_comfyUI" "seedvr2_ema_7b_fp16.safetensors" \
    --local-dir "$SEEDVR_MODELS_DIR"

  echo "Downloading ema_vae_fp16.safetensors..."
  hf download "numz/SeedVR2_comfyUI" "ema_vae_fp16.safetensors" \
    --local-dir "$SEEDVR_MODELS_DIR"

  echo "Downloads complete. Restarting ComfyUI to load node..."
  pkill -f "python main.py" || true
  sleep 3
  cd /workspace/runpod-slim/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 >> /proc/1/fd/1 2>> /proc/1/fd/2 &

  echo "Waiting for ComfyUI to come back online..."
  for i in $(seq 1 300); do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then break; fi
    sleep 2
  done

  if ! curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Timed out waiting for ComfyUI to restart."
    exit 1
  fi

  echo "-------------------------------------------------------"
  echo "DOWNLOAD COMPLETE - SEEDVR2 INSTALLED"
  echo "-------------------------------------------------------"

) >> /proc/1/fd/1 2>> /proc/1/fd/2 &

echo "seedvr.sh: background watcher started, main boot can continue"
echo "seedvr.sh: tail -f $LOG_FILE"
exit 0
