---
name: hf-upload
description: Prepare a Hugging Face CLI upload command for a model stored in a RunPod ComfyUI installation, targeting the skhaai/airebels repository.
---

# Hugging Face upload

Prepare an `hf upload` command that sends the requested file to
`skhaai/airebels` under `models/<filename>`.

Infer the local source folder from the model type when possible:

- checkpoint: `models/checkpoints`
- LoRA: `models/loras`
- VAE: `models/vae`
- ControlNet: `models/controlnet`
- upscaler: `models/upscale_models`
- embedding: `models/embeddings`
- CLIP: `models/clip`

The RunPod ComfyUI base directory is `/workspace/runpod-slim/ComfyUI`. If the
type or source path is unclear, ask the user instead of guessing. Return the
ready-to-run command and, when relevant, remind the user that `hf auth login`
needs a Hugging Face write token.
