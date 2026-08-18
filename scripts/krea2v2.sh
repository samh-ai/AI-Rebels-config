#!/bin/bash
set -euo pipefail

LOG_FILE="/workspace/krea2v2-background.log"
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

  # HF_HUB_ENABLE_HF_TRANSFER is gone: all Hub transfers go through hf-xet now and the
  # variable is a documented no-op.
  #
  # HF_XET_HIGH_PERFORMANCE is gone because it OOM-killed this pod (documented as needing
  # >=64GB RAM; this pod's cgroup limit was 28GB).
  #
  # HF_HUB_DISABLE_XET=1 disables the xet transport entirely. This is not a tuning choice,
  # it is a workaround for an open, unresolved hf-xet defect: downloads silently stall
  # forever mid-transfer with no error, no timeout, and near-zero CPU - matching what we
  # saw here (two `hf download` processes alive for 30+ minutes, <100MB RSS each, no
  # progress). Reported and reproduced independently in
  # https://github.com/huggingface/xet-core/issues/850 ,
  # https://github.com/huggingface/xet-core/issues/789 , and
  # https://github.com/huggingface/huggingface_hub/issues/4520 (open). In every case the
  # documented fix is HF_HUB_DISABLE_XET=1, which falls back to a plain HTTPS download -
  # slower, but it actually finishes. #789's diagnosis: xet's CDN delivers chunks out of
  # order at scale, collapsing the TCP congestion window until the transfer never recovers.
  export HF_HUB_DISABLE_XET=1
  export HF_HUB_DOWNLOAD_TIMEOUT=60

  # Belt-and-suspenders even with xet disabled: HF_HUB_DOWNLOAD_TIMEOUT only bounds the
  # HTTP read timeout, not the whole `hf download` process, so a stuck download could still
  # hang the script indefinitely otherwise. Same fix as clone_node: wrap in `timeout
  # --kill-after` (plain `timeout N` only sends SIGTERM at N and then waits for the child -
  # if the child ignores it, timeout blocks forever too; measured elsewhere in this script).
  # 3 attempts, since huggingface_hub resumes partial local-dir downloads from where they
  # left off rather than restarting, so a retry after a timeout is cheap, not a full redo.
  DOWNLOAD_TIMEOUT=600
  DOWNLOAD_KILL_GRACE=30
  if command -v timeout >/dev/null 2>&1; then
    DL_TIMEOUT_CMD="timeout --kill-after=$DOWNLOAD_KILL_GRACE $DOWNLOAD_TIMEOUT"
    DOWNLOAD_LIMIT_DESC="${DOWNLOAD_TIMEOUT}s timeout, SIGKILL at $((DOWNLOAD_TIMEOUT + DOWNLOAD_KILL_GRACE))s"
  else
    DL_TIMEOUT_CMD=""
    DOWNLOAD_LIMIT_DESC="NO TIMEOUT - 'timeout' not found on PATH"
  fi

  # Each hf process is an independent client, so peak concurrent bandwidth/memory scales
  # with how many run at once. 2 concurrent keeps that bounded.
  MAX_PARALLEL_DOWNLOADS=2

  download_hf_file() {
    local url="$1"
    local dest_dir="$2"
    local repo repo_path filename dl_tmp attempt rc start
    repo="$(echo "$url" | sed -E 's#https://huggingface.co/([^/]+/[^/]+)/.*#\1#')"
    repo_path="$(echo "$url" | sed -E 's#https://huggingface.co/[^/]+/[^/]+/resolve/[^/]+/##')"
    filename="$(basename "$url")"
    dl_tmp="$TMP_DIR/$filename"
    mkdir -p "$dest_dir" "$dl_tmp"
    for attempt in 1 2 3; do
      echo "Downloading: $url (attempt $attempt/3, $DOWNLOAD_LIMIT_DESC)"
      start=$SECONDS
      rc=0
      $DL_TIMEOUT_CMD hf download "$repo" "$repo_path" --local-dir "$dl_tmp" || rc=$?
      if [ "$rc" -eq 0 ]; then
        mv -f "$dl_tmp/$repo_path" "$dest_dir/$filename"
        echo "Finished: $filename in $((SECONDS - start))s (attempt $attempt/3)."
        return 0
      fi
      case "$rc" in
        124) echo "Download of $filename TIMED OUT after $((SECONDS - start))s (attempt $attempt/3)." ;;
        137) echo "Download of $filename ignored SIGTERM, SIGKILLed after $((SECONDS - start))s (attempt $attempt/3)." ;;
        *)   echo "Download of $filename FAILED, hf exit $rc after $((SECONDS - start))s (attempt $attempt/3)." ;;
      esac
    done
    echo "Download of $filename failed after 3 attempts."
    return 1
  }

  echo "-------------------------------------------------------"
  echo "BACKGROUND WATCHER STARTED: KREA2 V2 CONFIG"
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
  # erroring out. HTTP/1.1 avoids the HTTP/2 "curl 92 stream not closed cleanly" failure.
  #
  # Deliberately NOT a shallow clone. --depth 1 saved nothing here (RES4LYF is ~250MB
  # packed and its bulk is blobs at HEAD, not history) while forcing the server to build
  # a custom pack without reachability bitmaps - a long pre-transfer stall that GitHub
  # documents as more expensive than a full fetch, and the likely trigger for the
  # "fetch-pack: unexpected disconnect while reading sideband packet" on attempt 1.
  CLONE_TIMEOUT=240
  CLONE_KILL_GRACE=30
  if command -v timeout >/dev/null 2>&1; then
    # --kill-after is not optional. Plain `timeout N` only sends SIGTERM at N and then
    # blocks waiting for the child; if the child does not die from SIGTERM it waits
    # forever, so it caps nothing. Measured: `timeout 3` against a SIGTERM-ignoring child
    # returned after 60s, not 3s. That is what left a res4lyf clone silent for 12+ minutes
    # past a 240s "timeout". --kill-after escalates to SIGKILL so the bound is real.
    TIMEOUT_CMD="timeout --kill-after=$CLONE_KILL_GRACE $CLONE_TIMEOUT"
    CLONE_LIMIT_DESC="${CLONE_TIMEOUT}s timeout, SIGKILL at $((CLONE_TIMEOUT + CLONE_KILL_GRACE))s"
  else
    # Never claim a timeout we are not applying - the old code printed "240s timeout"
    # even in this branch, which made an uncapped hang impossible to diagnose from the log.
    TIMEOUT_CMD=""
    CLONE_LIMIT_DESC="NO TIMEOUT - 'timeout' not found on PATH"
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
    local attempt rc start
    for attempt in 1 2; do
      echo "Cloning $name (attempt $attempt/2, $CLONE_LIMIT_DESC)..."
      start=$SECONDS
      rc=0
      $TIMEOUT_CMD git -c http.version=HTTP/1.1 clone --quiet "$url" "$dest" || rc=$?
      if [ "$rc" -eq 0 ]; then
        echo "Cloned $name in $((SECONDS - start))s."
        return 0
      fi
      # Say which failure this was. The old code printed one message for every case, so a
      # timeout and a git error were indistinguishable in the log.
      case "$rc" in
        124) echo "Clone of $name TIMED OUT after $((SECONDS - start))s (attempt $attempt/2)." ;;
        137) echo "Clone of $name ignored SIGTERM, SIGKILLed after $((SECONDS - start))s (attempt $attempt/2)." ;;
        *)   echo "Clone of $name FAILED, git exit $rc after $((SECONDS - start))s (attempt $attempt/2)." ;;
      esac
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

  # run_queue launches entries up to $2 at a time, waiting for a free slot before starting
  # the next one. A prior version of this script put the two ~12GB diffusion models first
  # in a single concurrency-2 queue, which made them the pair that launched together - the
  # opposite of the intent. Fixed by running the two large files through their own
  # concurrency-1 queue (never overlapping each other or anything else), then the small
  # files through concurrency-2.
  run_queue() {
    local -n _queue="$1"
    local max="$2"
    local entry
    for entry in "${_queue[@]}"; do
      while [ "$(jobs -rp | wc -l)" -ge "$max" ]; do
        wait -n || die "a model download failed"
      done
      download_hf_file "${entry%%|*}" "${entry##*|}" &
    done
    wait || die "one or more model downloads failed"
  }

  LARGE_DOWNLOAD_QUEUE=(
    "${HF_MODELS[darkBeastINT8Convrot2_darkBeastKREA2FP8.safetensors]}|$MODELS_DIR/diffusion_models"
    "${HF_MODELS[krea2_turbo_fp8_scaled.safetensors]}|$MODELS_DIR/diffusion_models"
  )
  SMALL_DOWNLOAD_QUEUE=(
    "${HF_MODELS[qwen3vl_4b_fp8_scaled.safetensors]}|$MODELS_DIR/text_encoders"
    "${HF_MODELS[realism_engine_krea2_v2.safetensors]}|$MODELS_DIR/loras"
    "${HF_MODELS[snofs_krea_v1_1.safetensors]}|$MODELS_DIR/loras"
    "${HF_MODELS[krea2_identity_edit_v1_2.safetensors]}|$MODELS_DIR/loras"
    "${HF_MODELS[qwen_image_vae.safetensors]}|$MODELS_DIR/vae"
  )

  echo "Downloading ${#LARGE_DOWNLOAD_QUEUE[@]} large file(s) one at a time..."
  run_queue LARGE_DOWNLOAD_QUEUE 1
  echo "Downloading ${#SMALL_DOWNLOAD_QUEUE[@]} remaining file(s), max $MAX_PARALLEL_DOWNLOADS at a time..."
  run_queue SMALL_DOWNLOAD_QUEUE "$MAX_PARALLEL_DOWNLOADS"

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
  echo "DOWNLOAD COMPLETE - KREA2 V2 INSTALLED"
  echo "Total elapsed: $((SECONDS / 60))m$((SECONDS % 60))s"
  echo "-------------------------------------------------------"

) 2>&1 | tee -a "$LOG_FILE" >> /proc/1/fd/1 &

echo "krea2v2.sh: background watcher started, main boot can continue"
echo "krea2v2.sh: tail -f $LOG_FILE"
exit 0
