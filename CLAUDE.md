# AI Rebels Config

## Shell Script Pattern for Pod Setup Scripts

All setup scripts (e.g. `zit.sh`, `seedvr.sh`) follow the same pattern. **Do not deviate from this.**

### How it works

`boot.sh` runs the setup script before `exec /start.sh`. Because `exec` replaces the process, nothing can run after ComfyUI starts — so the only way to do post-boot work is to spawn a background process before returning.

### The pattern

```bash
#!/bin/bash
set -euo pipefail

LOG_FILE="/workspace/<name>-background.log"

(
  set -euo pipefail

  COMFY_ROOT="/workspace/runpod-slim/ComfyUI"
  CUSTOM_NODES_DIR="$COMFY_ROOT/custom_nodes"
  <NODE>_NODE_DIR="$CUSTOM_NODES_DIR/<node-folder-name>"
  # Define all destination model dirs here, NOT at the top level
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
  }

  echo "-------------------------------------------------------"
  echo "BACKGROUND WATCHER STARTED: <NAME> CONFIG"
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

  if ! command -v hf >/dev/null 2>&1; then
    pip install -U "huggingface_hub[hf_transfer]"
  fi

  # Install custom node
  if [ ! -d "$<NODE>_NODE_DIR" ]; then
    echo "Cloning <node-name>..."
    git clone "${CUSTOM_NODES[<key>]}" "$<NODE>_NODE_DIR"
  else
    echo "Custom node already present, skipping clone."
  fi

  if [ -f "$<NODE>_NODE_DIR/requirements.txt" ]; then
    echo "Installing requirements..."
    pip install -q -r "$<NODE>_NODE_DIR/requirements.txt"
  fi

  # Download models (parallel)
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"

  download_hf_file "${HF_MODELS[<filename1>]}" "$<DEST_DIR>" &
  download_hf_file "${HF_MODELS[<filename2>]}" "$<DEST_DIR>" &
  wait

  rm -rf "$TMP_DIR"

  echo "Downloads complete. Restarting ComfyUI to load node..."
  pkill -f "python main.py" || true
  sleep 3
  cd /workspace/runpod-slim/ComfyUI && .venv-cu128/bin/python main.py --listen 0.0.0.0 --port 8188 >> /proc/1/fd/1 2>> /proc/1/fd/2 &

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
  echo "DOWNLOAD COMPLETE - <NAME> INSTALLED"
  echo "-------------------------------------------------------"

) >> /proc/1/fd/1 2>> /proc/1/fd/2 &

echo "<name>.sh: background watcher started, main boot can continue"
echo "<name>.sh: tail -f $LOG_FILE"
exit 0
```

### Rules

- **Everything goes inside the subshell** — no synchronous work before the `( ... ) &`
- **Always wait for COMFY_ROOT** first, with a timeout check after the loop — the `/workspace` volume may not be mounted instantly
- **Always wait for 8188** — safety check that ComfyUI is fully installed and folders exist; also check with timeout after the loop
- **Variables are defined inside the subshell** — not at the top of the script
- **Always source registry.sh** at the top of the subshell: `source <(curl -fsSL "https://raw.githubusercontent.com/samh-ai/AI-Rebels-config/main/registry.sh")`
- **Always set HF env vars** inside the subshell: `HF_HUB_ENABLE_HF_TRANSFER=1`, `HF_XET_HIGH_PERFORMANCE=1`, `HF_HUB_DOWNLOAD_TIMEOUT=60`
- **Always include the `download_hf_file()` helper** — copy it verbatim from an existing script; do not inline raw `hf download` calls
- **Always check `hf` is installed** before downloading: `if ! command -v hf >/dev/null 2>&1; then pip install -U "huggingface_hub[hf_transfer]"; fi`
- **Custom nodes go in** `$COMFY_ROOT/custom_nodes/<node-name>/`; skip clone if already present
- **Model destination dirs** — use standard ComfyUI layout:
  - Diffusion models: `$COMFY_ROOT/models/diffusion_models/`
  - Checkpoints: `$COMFY_ROOT/models/checkpoints/`
  - LoRAs: `$COMFY_ROOT/models/loras/`
  - Text encoders: `$COMFY_ROOT/models/text_encoders/`
  - VAE: `$COMFY_ROOT/models/vae/`
  - Tool-specific models: `$COMFY_ROOT/models/<TOOLNAME>/`
- **Use `TMP_DIR="/workspace/hf-downloads"`** — clean it before and after all downloads; each call uses its own subdir `$TMP_DIR/$filename` internally so parallel jobs don't collide
- **Always run downloads in parallel** — background every `download_hf_file` call with `&` and add a single `wait` after the last one before proceeding
- **Never hardcode URLs or git repos in .sh files** — add them to `registry.sh` and reference by key
- **If a custom node is installed, always restart ComfyUI** after all downloads finish — kill the process, relaunch it, wait for 8188 to come back, then print the final ready message
- **ComfyUI is a raw process** — there is no supervisor, so it must be relaunched manually with `.venv-cu128/bin/python main.py --listen 0.0.0.0 --port 8188` from `/workspace/runpod-slim/ComfyUI`. Do NOT use `python` — it is not on PATH, only the venv python is available
- **SageAttention 2.x is NOT on PyPI** — `pip install sageattention==2.2.0` will fail. Must build from source: clone `https://github.com/thu-ml/SageAttention.git`, then `pip install <dir> --no-build-isolation` using the venv pip. Set `EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32` before building to speed up CUDA kernel compilation
