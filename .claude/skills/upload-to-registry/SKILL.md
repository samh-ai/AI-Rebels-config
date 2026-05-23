---
name: upload-to-registry
description: Add a URL to registry.sh in the correct category. Use when the user provides a URL (GitHub, HuggingFace, or CivitAI) and wants it added to the registry. Triggers on phrases like "add this to the registry", "register this model", "add this node", "put this in the registry", or when a bare URL is provided alongside any of those intents.
model: haiku
---

# upload-to-registry

Add a single URL to `registry.sh` in the correct section.

## Step 1: Read the registry

Read `registry.sh` from the repo root. Identify the existing sections and entries.

## Step 2: Classify the URL

**The user's description always takes priority.** If the user says "this is a LoRA" or "add this node", treat that as ground truth — skip research and go straight to Step 3.

Otherwise, **fetch the URL** (or its page, for GitHub/HuggingFace/CivitAI) to understand what it actually is before classifying. Do not assume based on domain alone — a GitHub URL is not automatically a custom node; it could be a model repo, a tool, or something else entirely.

Use what you learn from the page to map to one of the registry categories:

| Category | Array | What it looks like |
|----------|-------|--------------------|
| Custom Node | `CUSTOM_NODES` | A ComfyUI extension/node repo (GitHub), meant to be `git clone`d into `custom_nodes/` |
| LoRAs | `HF_MODELS` | A LoRA/LyCORIS weight file (`.safetensors`/`.pt`) used to steer a base model |
| VAE | `HF_MODELS` | A standalone VAE encoder/decoder |
| Clip Vision | `HF_MODELS` | A CLIP vision encoder |
| GGUFs | `HF_MODELS` | A quantized model file (`.gguf`) |
| Text Encoders | `HF_MODELS` | A text encoder (T5, UMT5, Qwen, CLIP-L/G, etc.) |
| Diffusion Models | `HF_MODELS` | A standalone diffusion backbone (not a bundled checkpoint) |
| Checkpoints | `HF_MODELS` | A full bundled model checkpoint (safetensors or bin) |

If after researching you are still unsure, **ask the user** which category to use — do not guess.

## Step 3: Derive the key

- **CUSTOM_NODES**: use the last path segment of the GitHub URL, lowercased, stripped of `ComfyUI-` or `comfyui-` prefix if present. Example: `https://github.com/foo/ComfyUI-Bar` → key `bar`.
- **HF_MODELS**: use the bare filename (the last path segment of the URL, preserving original casing). For CivitAI URLs where the filename isn't obvious, ask the user for the intended filename.

## Step 4: Check for duplicates

If the key already exists in `registry.sh`, tell the user and stop — do not add a duplicate.

## Step 5: Insert the entry

Edit `registry.sh` to insert exactly one new line under the correct section comment. Preserve the existing format:

- `CUSTOM_NODES` entries: `CUSTOM_NODES[key]="url"`
- `HF_MODELS` entries: `HF_MODELS[filename]="url"`

Place the new line at the **end** of its section, immediately before the next blank line or section comment.

After editing, show the user the single line that was added and which section it went into.
