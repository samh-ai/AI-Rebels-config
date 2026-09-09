---
name: jupyter-download-command
description: Turn a Hugging Face or CivitAI model URL into one ready-to-run wget command for the correct RunPod ComfyUI model folder.
---

# Jupyter download command

Inspect the supplied URL or its metadata to determine the real filename and
model type. Do not invent a generic filename. Use `/workspace/runpod-slim/ComfyUI/models/`
as the base destination and select the matching subfolder:

- diffusion model or UNet: `diffusion_models`
- checkpoint: `checkpoints`
- LoRA or LyCORIS: `loras`
- VAE: `vae`
- text encoder: `text_encoders`
- CLIP vision: `clip_vision`
- embedding: `embeddings`
- ControlNet: `controlnet`
- upscaler: `upscale_models`

Return one plain `wget` command in a Bash code block, using an absolute path
with `-O`. Never combine `-P` with `-O`. For a gated Hugging Face file, include
an authorization-header placeholder. For CivitAI, use a `YOUR_CIVITAI_TOKEN`
placeholder when its download URL requires a token. If the type is genuinely
ambiguous, add one short Bash comment stating the chosen folder.
