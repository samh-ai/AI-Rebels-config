#!/bin/bash
set -euo pipefail

source /tmp/airebels-registry.sh
: "${COMFYUI_VERSION:?ComfyUI release is required}"
: "${COMFYUI_REPO:?ComfyUI source is required}"

BAKED_DIR=/opt/comfyui-baked
MANIFEST="$BAKED_DIR/.runpod-bundle-version"
CONSTRAINTS=/opt/comfyui-runtime-constraints.txt
SOURCE_DIR=$(mktemp -d)
trap 'rm -rf "$SOURCE_DIR"' EXIT

# Fail if RunPod changes its layout instead of producing an ineffective upgrade.
test -f "$BAKED_DIR/main.py"
test -f "$MANIFEST"
test -f "$CONSTRAINTS"
grep -q 'upgrade_comfyui_if_needed' /start.sh
grep -q '^COMFYUI_VERSION=' "$MANIFEST"

# Keep the Python/CUDA/PyTorch stack supplied by RunPod. Record it so a
# dependency install cannot silently replace the working GPU packages.
python3 - <<'PY' > "$SOURCE_DIR/torch-before.json"
import importlib.metadata
import json
print(json.dumps({name: importlib.metadata.version(name)
                  for name in ("torch", "torchvision", "torchaudio")}))
PY

git clone --depth 1 --branch "$COMFYUI_VERSION" "$COMFYUI_REPO" "$SOURCE_DIR/release"
test "$(git -C "$SOURCE_DIR/release" describe --tags --exact-match)" = "$COMFYUI_VERSION"

# Replace core, including Git metadata, while retaining RunPod's bundled nodes,
# Manager cache and model directories. Runtime startup copies this baked tree.
rsync -a --delete \
  --exclude='/custom_nodes/' --exclude='/user/' --exclude='/models/' \
  --exclude='/.runpod-bundle-version' \
  "$SOURCE_DIR/release/" "$BAKED_DIR/"
rsync -a --exclude='*/' "$SOURCE_DIR/release/custom_nodes/" "$BAKED_DIR/custom_nodes/"

python3 -m pip install --no-cache-dir --constraint "$CONSTRAINTS" \
  --requirement "$BAKED_DIR/requirements.txt"

python3 - "$SOURCE_DIR/torch-before.json" <<'PY'
import importlib.metadata
import json
import sys
with open(sys.argv[1]) as stream:
    before = json.load(stream)
after = {name: importlib.metadata.version(name) for name in before}
assert before == after, f"RunPod PyTorch stack changed: {before} -> {after}"
print("Retained RunPod PyTorch stack:", after)
PY

cd "$BAKED_DIR"
python3 - <<'PY'
import os
from comfyui_version import __version__
assert __version__ == os.environ["COMFYUI_VERSION"].removeprefix("v"), __version__
print("Baked ComfyUI version:", __version__)
PY

# RunPod compares this marker when an existing workspace is attached. Updating
# it is necessary for startup to sync the new core into that workspace.
sed -i "s/^COMFYUI_VERSION=.*/COMFYUI_VERSION=$COMFYUI_VERSION/" "$MANIFEST"
