#!/bin/bash
set -euo pipefail

LOG_FILE="/workspace/krea2-latest-background.log"
# If the log file can't be created (e.g. /workspace not mounted yet), fall back
# to /dev/null so tee never kills the watcher.
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/dev/null"

(
  set -euo pipefail

  COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
  CUSTOM_NODES_DIR="$COMFY_ROOT/custom_nodes"
  RGTHREE_NODE_DIR="$CUSTOM_NODES_DIR/rgthree-comfy"
  RES4LYF_NODE_DIR="$CUSTOM_NODES_DIR/RES4LYF"
  KREA2EDIT_NODE_DIR="$CUSTOM_NODES_DIR/comfyui-krea2edit"
  MODELS_DIR="$COMFY_ROOT/models"
  TMP_DIR="/workspace/hf-downloads"
  HEALTH_URL="http://127.0.0.1:8188"

  source <(curl -fsSL "https://raw.githubusercontent.com/samh-ai/AI-Rebels-config/main/registry.sh")

  export HF_HUB_ENABLE_HF_TRANSFER=1
  export HF_XET_HIGH_PERFORMANCE=1
  export HF_HUB_DOWNLOAD_TIMEOUT=60

  download_hf_file() {
    local url="$1"
    local dest_dir="$2"
    local repo repo_path filename dl_tmp
    repo="$(echo "$url" | sed -E 's#https://huggingface.co/([^/]+/[^/]+)/.*#\1#')"
    repo_path="$(echo "$url" | sed -E 's#https://huggingface.co/[^/]+/[^/]+/resolve/[^/]+/##')"
    filename="$(basename "$url")"
    dl_tmp="$TMP_DIR/$filename"
    mkdir -p "$dest_dir" "$dl_tmp"
    echo "Downloading: $url"
    hf download "$repo" "$repo_path" --local-dir "$dl_tmp"
    mv -f "$dl_tmp/$repo_path" "$dest_dir/$filename"
    echo "Finished: $filename"
  }

  echo "-------------------------------------------------------"
  echo "BACKGROUND WATCHER STARTED: KREA2 LATEST CONFIG"
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

  echo "ComfyUI is live at $(git -C "$COMFY_ROOT" describe --tags 2>/dev/null || echo unknown)."
  echo "No core update needed (image bakes a current ComfyUI). Installing custom node(s) and downloading models..."

  # RunPod runs ComfyUI from system python on the cuda12.8 image and from .venv-cu128
  # on older ones. Follow whichever interpreter is actually serving 8188 so node
  # requirements and the restart at the end land in the same environment.
  COMFY_PY="$(readlink -f "/proc/$(pgrep -f 'main\.py' | head -1)/exe" 2>/dev/null || true)"
  if [ ! -x "$COMFY_PY" ]; then
    COMFY_PY="$COMFY_ROOT/.venv-cu128/bin/python"
  fi
  echo "Using interpreter: $COMFY_PY"

  if ! command -v hf >/dev/null 2>&1; then
    "$COMFY_PY" -m pip install -q -U "huggingface_hub[hf_transfer]"
  fi

  # A pod missing a node is unusable and has to be redeployed, so fail fast and loud
  # rather than spending 20 more minutes downloading models nobody will use.
  # CLONE_TIMEOUT caps the stall: a bad host once hung a clone for 12 minutes before
  # erroring out. Shallow + HTTP/1.1 keep the transfer small and avoid the HTTP/2
  # "curl 92 stream not closed cleanly" failure that killed it.
  CLONE_TIMEOUT=240
  if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout $CLONE_TIMEOUT"
  else
    TIMEOUT_CMD=""
  fi

  die() {
    echo "======================================================="
    echo "SETUP FAILED: $1"
    echo "Nothing further will run. Redeploy the pod."
    echo "Failed after $((SECONDS / 60))m$((SECONDS % 60))s."
    echo "======================================================="
    exit 1
  }

  clone_node() {
    local name="$1" url="$2" dest="$3"
    if [ -d "$dest" ]; then
      echo "$name already present, skipping clone."
      return 0
    fi
    local attempt
    for attempt in 1 2; do
      echo "Cloning $name (attempt $attempt/2, ${CLONE_TIMEOUT}s timeout)..."
      if $TIMEOUT_CMD git -c http.version=HTTP/1.1 clone --depth 1 --quiet "$url" "$dest"; then
        echo "Cloned $name."
        return 0
      fi
      echo "Clone of $name failed or timed out (attempt $attempt/2)."
      rm -rf "$dest"
    done
    die "could not clone $name after 2 attempts"
  }

  install_node_reqs() {
    local name="$1" dir="$2"
    if [ -f "$dir/requirements.txt" ]; then
      "$COMFY_PY" -m pip install -q -r "$dir/requirements.txt"
      echo "$name requirements installed."
    fi
  }

  # Newer ComfyUI 403s cross-site browser requests (Sec-Fetch-Site check),
  # which breaks access through the RunPod proxy. --enable-cors-header disables that middleware.
  ARGS_FILE="/workspace/runpod-slim/comfyui_args.txt"
  if [ -f "$ARGS_FILE" ] && ! grep -q "enable-cors-header" "$ARGS_FILE"; then
    echo "--enable-cors-header" >> "$ARGS_FILE"
  fi

  # --- custom node installs ---
  clone_node "rgthree" "${CUSTOM_NODES[rgthree]}" "$RGTHREE_NODE_DIR"
  install_node_reqs "rgthree" "$RGTHREE_NODE_DIR"
  clone_node "res4lyf" "${CUSTOM_NODES[res4lyf]}" "$RES4LYF_NODE_DIR"
  install_node_reqs "res4lyf" "$RES4LYF_NODE_DIR"
  clone_node "krea2edit" "${CUSTOM_NODES[krea2edit]}" "$KREA2EDIT_NODE_DIR"
  install_node_reqs "krea2edit" "$KREA2EDIT_NODE_DIR"
  # --- end custom node installs ---

  # ComfyUI 0.30.0 renamed comfy/logging.py -> comfy/internal_logging.py.
  # Flag any custom node still importing the old path so a failed import is
  # obvious in the log instead of showing up as a missing node in the UI.
  if grep -rn "comfy\.logging\|from comfy import logging" "$CUSTOM_NODES_DIR" 2>/dev/null; then
    echo "WARNING: custom node(s) above import comfy.logging, removed in ComfyUI 0.30.0."
  else
    echo "No custom node references to the removed comfy.logging module."
  fi

  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"

  # parallel downloads
  download_hf_file "${HF_MODELS[darkBeastINT8Convrot2_darkBeastKREA2FP8.safetensors]}" "$MODELS_DIR/diffusion_models" &
  download_hf_file "${HF_MODELS[krea2_turbo_fp8_scaled.safetensors]}" "$MODELS_DIR/diffusion_models" &
  download_hf_file "${HF_MODELS[qwen3vl_4b_fp8_scaled.safetensors]}" "$MODELS_DIR/text_encoders" &
  download_hf_file "${HF_MODELS[qwen_image_vae.safetensors]}" "$MODELS_DIR/vae" &
  download_hf_file "${HF_MODELS[realism_engine_krea2_v2.safetensors]}" "$MODELS_DIR/loras" &
  download_hf_file "${HF_MODELS[snofs_krea_v1_1.safetensors]}" "$MODELS_DIR/loras" &
  download_hf_file "${HF_MODELS[krea2_identity_edit_v1_2.safetensors]}" "$MODELS_DIR/loras" &
  wait || die "one or more model downloads failed"

  rm -rf "$TMP_DIR"

  echo "Downloads complete. Restarting ComfyUI to load custom node(s)..."
  pkill -f "main.py" || true
  sleep 3
  cd "$COMFY_ROOT" && "$COMFY_PY" main.py --listen 0.0.0.0 --port 8188 --enable-cors-header >> /proc/1/fd/1 2>> /proc/1/fd/2 &

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
  echo "DOWNLOAD COMPLETE - KREA2 LATEST INSTALLED"
  echo "Total elapsed: $((SECONDS / 60))m$((SECONDS % 60))s"
  echo "-------------------------------------------------------"

) 2>&1 | tee -a "$LOG_FILE" >> /proc/1/fd/1 &

echo "krea2-latest.sh: background watcher started, main boot can continue"
echo "krea2-latest.sh: tail -f $LOG_FILE"
exit 0
