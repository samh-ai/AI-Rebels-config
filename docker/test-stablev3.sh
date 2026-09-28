#!/bin/bash
set -euo pipefail

IMAGE=${1:?Image tag is required}
CONTAINER="airebels-test-${RANDOM}"
VOLUME="${CONTAINER}-workspace"
ROOT=/workspace/runpod-slim/ComfyUI

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
}
trap cleanup EXIT
docker volume create "$VOLUME" >/dev/null

# Exercise the real entrypoint and RunPod startup, with CPU inference selected
# because GitHub's runner has no GPU. Model generation is tested on RunPod.
docker run --rm --entrypoint bash -v "$VOLUME:/workspace" "$IMAGE" -c '
  mkdir -p /workspace/runpod-slim
  printf "%s\n" --cpu --disable-all-custom-nodes > /workspace/runpod-slim/comfyui_args.txt
'

check_startup() {
  docker run -d --name "$CONTAINER" -v "$VOLUME:/workspace" \
    "$IMAGE" >/dev/null
  if ! docker exec -i "$CONTAINER" python3 - <<'PY'
import http.client
import json
import os
import time

def get(path):
    connection = http.client.HTTPConnection("127.0.0.1", 8188, timeout=30)
    try:
        connection.request("GET", path)
        response = connection.getresponse()
        assert response.status == 200, response.status
        return json.loads(response.read())
    finally:
        connection.close()

for attempt in range(120):
    try:
        stats = get("/system_stats")
        break
    except (OSError, http.client.HTTPException):
        time.sleep(2)
else:
    raise RuntimeError("ComfyUI did not start within four minutes")

actual = stats["system"]["comfyui_version"]
expected = os.environ["COMFYUI_VERSION"].removeprefix("v")
assert actual == expected, f"Running ComfyUI {actual}; expected {expected}"
print("Running ComfyUI version:", actual)
nodes = get("/object_info")
required = {"TextEncodeQwenImage21", "QwenImage21Cache"}
missing = required - nodes.keys()
assert not missing, f"Missing Qwen core nodes: {missing}"
print("Qwen Image 2.1 core nodes registered successfully.")
PY
  then
    docker logs "$CONTAINER"
    return 1
  fi

  docker exec -w "$ROOT" "$CONTAINER" bash -c '
    test "$(git describe --tags --exact-match)" = "$COMFYUI_VERSION"
    grep -Fx "COMFYUI_VERSION=$COMFYUI_VERSION" .runpod-bundle-version
    test ! -e stale-core-file.txt
  '
  docker rm -f "$CONTAINER" >/dev/null
}

echo 'Testing a fresh workspace...'
check_startup

# The first start created a real persistent virtual environment. Mark core as
# outdated and add user data to verify migration and preservation on next boot.
docker run --rm --entrypoint bash -v "$VOLUME:/workspace" "$IMAGE" -c '
  cd /workspace/runpod-slim/ComfyUI
  printf "%s\n" COMFYUI_VERSION=old > .runpod-bundle-version
  printf "%s\n" stale > stale-core-file.txt
  printf "%s\n" "__version__ = \"old\"" > comfyui_version.py
  mkdir -p models user custom_nodes/airebels-test-node
  printf "%s\n" preserved > models/airebels-test.txt
  printf "%s\n" preserved > user/airebels-test.txt
  printf "%s\n" preserved > custom_nodes/airebels-test-node/keep.txt
'

echo 'Testing an existing workspace upgrade...'
check_startup
docker run --rm --entrypoint bash -v "$VOLUME:/workspace" "$IMAGE" -c '
  cd /workspace/runpod-slim/ComfyUI
  for path in models/airebels-test.txt user/airebels-test.txt custom_nodes/airebels-test-node/keep.txt; do
    grep -Fx preserved "$path"
  done
'
echo 'Fresh startup, existing workspace migration, and Qwen node checks passed.'
