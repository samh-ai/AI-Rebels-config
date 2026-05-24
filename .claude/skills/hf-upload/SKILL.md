---
name: hf-upload
description: Upload a model file from RunPod JupyterLab to the skhaai/airebels HuggingFace repo. Use this skill whenever the user wants to upload, push, or copy a model/safetensors file to HuggingFace, or says things like "upload this to HF", "put this on HuggingFace", "copy to HF repo", or provides a filename and wants it in the repo.
---

# HuggingFace Upload — skhaai/airebels

## HF destination
All files go into the `models/` folder of the repo:
`skhaai/airebels` → `models/<filename>`

## Local ComfyUI paths by model type

| Type | Local path |
|------|-----------|
| Checkpoint | `/workspace/runpod-slim/ComfyUI/models/checkpoints/` |
| LoRA | `/workspace/runpod-slim/ComfyUI/models/loras/` |
| VAE | `/workspace/runpod-slim/ComfyUI/models/vae/` |
| ControlNet | `/workspace/runpod-slim/ComfyUI/models/controlnet/` |
| Upscaler | `/workspace/runpod-slim/ComfyUI/models/upscale_models/` |
| Embedding | `/workspace/runpod-slim/ComfyUI/models/embeddings/` |
| CLIP | `/workspace/runpod-slim/ComfyUI/models/clip/` |
| Other | Ask the user for the local path |

If the user doesn't specify the type, infer it from the filename or ask.

## Upload command

```bash
hf upload skhaai/airebels <local_path>/<filename> models/<filename>
```

## Auth check
If the user hasn't logged in or used a read-only token, remind them:
```bash
hf auth login
```
They need a **write** token from https://huggingface.co/settings/tokens

## Examples

**Checkpoint:**
```bash
hf upload skhaai/airebels /workspace/runpod-slim/ComfyUI/models/checkpoints/intorealismUltra_v40.safetensors models/intorealismUltra_v40.safetensors
```

**LoRA:**
```bash
hf upload skhaai/airebels /workspace/runpod-slim/ComfyUI/models/loras/myLora_v1.safetensors models/myLora_v1.safetensors
```
