---
name: upload-to-registry
description: Add one GitHub, Hugging Face, or CivitAI URL to the appropriate section of this repository's registry.sh file.
---

# Add to registry

Read `registry.sh` before making a change. The user's description of the item
takes priority; otherwise inspect the supplied URL to determine its type.

Classify ComfyUI extension repositories as `CUSTOM_NODES`. Classify model files
(LoRA, VAE, CLIP vision, GGUF, text encoder, diffusion model, or checkpoint) as
`HF_MODELS`. If the category remains unclear after inspection, ask the user.

For a custom node, derive the key from the final GitHub path component in
lowercase, removing a `ComfyUI-` prefix. For a model, use its filename as the
key. For CivitAI links without a known filename, ask for the intended filename.

Check for an existing key first; do not create duplicates. Add exactly one
entry at the end of the matching section, preserving the file's existing
format. Report the added line and section.
