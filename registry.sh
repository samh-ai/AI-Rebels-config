#!/bin/bash
# Registry of custom nodes and model download links.
# Sourced by setup scripts — do not execute directly.

# Custom nodes — key: short name, value: git clone URL
declare -A CUSTOM_NODES
CUSTOM_NODES[seedvr2]="https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler"
CUSTOM_NODES[rgthree]="https://github.com/rgthree/rgthree-comfy"
CUSTOM_NODES[lanpaint]="https://github.com/scraed/LanPaint"
CUSTOM_NODES[videohelper]="https://github.com/kosinkadink/ComfyUI-VideoHelperSuite"
CUSTOM_NODES[frameinterp]="https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"

# HF models — key: filename, value: full download URL
declare -A HF_MODELS

# Diffusion Models
HF_MODELS[wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors]="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"
HF_MODELS[wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors]="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
HF_MODELS[z_image_turbo_bf16.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
HF_MODELS[flux-2-klein-9b-fp8.safetensors]="https://huggingface.co/black-forest-labs/FLUX.2-klein-9b-fp8/resolve/main/flux-2-klein-9b-fp8.safetensors"
HF_MODELS[seedvr2_ema_7b_fp16.safetensors]="https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_7b_fp16.safetensors"

# Checkpoints
HF_MODELS[big_lust_v1.6.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/big_lust_v1.6.safetensors"

# GGUFs


# LoRAs
HF_MODELS[Wan22_I2V_VBVR_HIGH_rank_64_fp16.safetensors]="https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/VBVR/Wan22_I2V_VBVR_HIGH_rank_64_fp16.safetensors"
HF_MODELS[wan2.2_i2v_A14b_high_noise_lora_rank64_lightx2v_4step_1022.safetensors]="https://huggingface.co/lightx2v/Wan2.2-Distill-Loras/resolve/main/wan2.2_i2v_A14b_high_noise_lora_rank64_lightx2v_4step_1022.safetensors"
HF_MODELS[wan2.2_i2v_A14b_low_noise_lora_rank64_lightx2v_4step_1022.safetensors]="https://huggingface.co/lightx2v/Wan2.2-Distill-Loras/resolve/main/wan2.2_i2v_A14b_low_noise_lora_rank64_lightx2v_4step_1022.safetensors"
HF_MODELS[Flux2-Klein-9B-consistency-V2.safetensors]="https://huggingface.co/dx8152/Flux2-Klein-9B-Consistency/resolve/main/Flux2-Klein-9B-consistency-V2.safetensors"
HF_MODELS[bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors]="https://huggingface.co/Alissonerdx/BFS-Best-Face-Swap/resolve/main/bfs_head_v1_flux-klein_9b_step3500_rank128.safetensors"
HF_MODELS[wan2.2_i2v_high_ulitmate_pussy_asshole.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/wan2.2_i2v_high_ulitmate_pussy_asshole.safetensors"
HF_MODELS[wan2.2_i2v_low_ulitmate_pussy_asshole.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/wan2.2_i2v_low_ulitmate_pussy_asshole.safetensors"
HF_MODELS[Mystic-XXX-ZIT-V6.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/Mystic-XXX-ZIT-V6.safetensors"
HF_MODELS[Z-Detail-Slider.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/Z-Detail-Slider.safetensors"
HF_MODELS[zimage-igbaddie_pruned.safetensors]="https://huggingface.co/skhaai/airebels/resolve/main/models/zimage-igbaddie_pruned.safetensors"

# Text Encoders
HF_MODELS[umt5_xxl_fp8_e4m3fn_scaled.safetensors]="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
HF_MODELS[qwen_3_4b.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
HF_MODELS[qwen_3_8b_fp8mixed.safetensors]="https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/resolve/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors"

# VAE
HF_MODELS[wan_2.1_vae.safetensors]="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
HF_MODELS[ema_vae_fp16.safetensors]="https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors"
HF_MODELS[ae.safetensors]="https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
HF_MODELS[flux2-vae.safetensors]="https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"

# Clip Vision
HF_MODELS[clip_vision_h.safetensors]="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"