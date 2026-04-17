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
  # Define destination dirs here, NOT at the top level
  HEALTH_URL="http://127.0.0.1:8188"

  # 1. Wait for ComfyUI root directory to exist (volume may not be mounted yet)
  for i in $(seq 1 300); do
    if [ -d "$COMFY_ROOT" ]; then break; fi
    sleep 2
  done

  # 2. Wait for ComfyUI server on 8188 (safety check — ensures all folders exist)
  for i in $(seq 1 600); do
    if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then break; fi
    sleep 2
  done

  # 3. Do all work here (clone nodes, pip install, download models, etc.)

) >> /proc/1/fd/1 2>> /proc/1/fd/2 &

echo "<name>.sh: background watcher started, main boot can continue"
echo "<name>.sh: tail -f $LOG_FILE"
exit 0
```

### Rules

- **Everything goes inside the subshell** — no synchronous work before the `( ... ) &`
- **Always wait for COMFY_ROOT** first — the `/workspace` volume may not be mounted instantly
- **Always wait for 8188** — safety check that ComfyUI is fully installed and folders exist
- **Variables are defined inside the subshell** — not at the top of the script
- **Custom nodes go in** `$COMFY_ROOT/custom_nodes/<node-name>/`
- **Tool-specific models go in their own subfolder** e.g. `$COMFY_ROOT/models/SEEDVR2/` — not the generic `models/` root
- **Use `hf download` for HuggingFace files** with `HF_HUB_ENABLE_HF_TRANSFER=1` for speed
- **Note in the final echo** if a ComfyUI restart is needed (e.g. after custom node install)
