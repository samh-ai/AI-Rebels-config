---
name: boot-script
description: Create or update a ComfyUI RunPod setup script in this repository. Use for new pod scripts and for adding, replacing, or removing registered models or custom nodes.
---

# Boot script

Work only with scripts in `scripts/` and the catalog in `registry.sh`.

## Existing scripts

Read the target script and `registry.sh` before editing. Confirm every requested
model or custom-node key is present in the relevant registry array. If a key is
missing, explain that it must be added to `registry.sh` first.

For a model-only change, modify only the corresponding `download_hf_file` lines:

- Add a line before `wait` for an addition.
- Replace one download line for a swap.
- Remove only that line for a removal.

Preserve the script's setup, node installation, restart, and logging behavior.

## New scripts

Read `registry.sh` and a relevant existing script first. Create the new file in
`scripts/`, using the established RunPod/ComfyUI script structure. Use
`CUSTOM_NODES[...]` and `HF_MODELS[...]` from `registry.sh`; do not hardcode
repository or model URLs in the shell script.

Use the repository's standard ComfyUI location and virtual-environment Python,
keep downloads parallel with one final `wait`, and retain the post-install
ComfyUI restart so newly installed nodes and models are loaded.

When details that affect the file are missing (filename, registry keys, or model
destination folders), ask before writing it. Validate shell syntax after a
change and summarize exactly what changed.
