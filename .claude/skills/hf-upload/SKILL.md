---
name: hf-upload
description: Upload a model file from RunPod JupyterLab to the skhaai/airebels HuggingFace repo. Use this skill whenever the user wants to upload, push, or copy a model/safetensors file to HuggingFace, or says things like "upload this to HF", "put this on HuggingFace", "copy to HF repo", "give me the HF upload code", or provides a filename and wants it in the repo.
---

# HuggingFace Upload — skhaai/airebels

## HF destination
All files go into the `models/` folder of the repo:
`skhaai/airebels` → `models/<filename>`

## Local ComfyUI paths by model type

| Type | Local path |
|------|-----------|
| Checkpoint | `/workspace/runpod-slim/ComfyUI/models/checkpoints/` |
| Diffusion Model | `/workspace/runpod-slim/ComfyUI/models/diffusion_models/` |
| LoRA | `/workspace/runpod-slim/ComfyUI/models/loras/` |
| VAE | `/workspace/runpod-slim/ComfyUI/models/vae/` |
| ControlNet | `/workspace/runpod-slim/ComfyUI/models/controlnet/` |
| Upscaler | `/workspace/runpod-slim/ComfyUI/models/upscale_models/` |
| Embedding | `/workspace/runpod-slim/ComfyUI/models/embeddings/` |
| CLIP | `/workspace/runpod-slim/ComfyUI/models/clip/` |
| Other | Ask the user for the local path |

If the user doesn't specify the type, infer it from the filename or ask.

## Output: ALWAYS give the full sequence

The RunPod pod sets an `HF_TOKEN` env var holding a **read-only** token, and it
overrides any token saved by `hf auth login`. Uploads 403 every time unless it is
cleared. So every answer from this skill must give these three commands, in this
order, each in its own `bash` block — never the upload command alone:

**1. Clear the read-only pod token:**
```bash
unset HF_TOKEN
```

**2. Log in with a write token** (paste a **write** token from https://huggingface.co/settings/tokens when prompted):
```bash
hf auth login --force
```

**3. Upload:**
```bash
hf upload skhaai/airebels <local_path>/<filename> models/<filename>
```

Rules:
- Quote both paths whenever the filename contains spaces.
- Mention once that `unset HF_TOKEN` only lasts for that terminal; a new terminal or pod restart brings the read token back (the permanent fix is changing `HF_TOKEN` in the RunPod pod template).

## Examples

**Checkpoint:**
```bash
unset HF_TOKEN
```
```bash
hf auth login --force
```
```bash
hf upload skhaai/airebels /workspace/runpod-slim/ComfyUI/models/checkpoints/intorealismUltra_v40.safetensors models/intorealismUltra_v40.safetensors
```

**Diffusion model with spaces in the name:**
```bash
unset HF_TOKEN
```
```bash
hf auth login --force
```
```bash
hf upload skhaai/airebels "/workspace/runpod-slim/ComfyUI/models/diffusion_models/My Model V4.safetensors" "models/My Model V4.safetensors"
```
