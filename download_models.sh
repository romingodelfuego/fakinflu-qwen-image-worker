#!/usr/bin/env bash
# Telecharge les modeles Qwen-Image 2.1 dans un arbre ComfyUI/models.
# Usage :
#   MODELS_DIR=/runpod-volume/ComfyUI/models ./download_models.sh        # 3 modeles (sans enhancer)
#   WITH_PE=1 MODELS_DIR=/workspace/ComfyUI/models ./download_models.sh  # + modele PE (enhancer)
#
# A lancer :
#   - sur un POD attache au network volume (recommande), ou
#   - au build de l'image (voir Dockerfile).
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-/runpod-volume/ComfyUI/models}"
BASE="https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main"
DL="curl -L --fail --retry 3 -C -"   # reprise si coupure

mkdir -p "$MODELS_DIR"/{diffusion_models,text_encoders,vae}

echo ">> diffusion_models"
$DL -o "$MODELS_DIR/diffusion_models/qwen_image_2.1_int8_convrot.safetensors" \
   "$BASE/diffusion_models/qwen_image_2.1_int8_convrot.safetensors"

echo ">> text_encoders (qwen3vl 8b)"
$DL -o "$MODELS_DIR/text_encoders/qwen3vl_8b_int8_convrot.safetensors" \
   "$BASE/text_encoders/qwen3vl_8b_int8_convrot.safetensors"

echo ">> vae"
$DL -o "$MODELS_DIR/vae/qwen_image_2.1_vae_bf16.safetensors" \
   "$BASE/vae/qwen_image_2.1_vae_bf16.safetensors"

if [ "${WITH_PE:-0}" = "1" ]; then
  echo ">> text_encoders (PE qwen3.5 9b — prompt enhancer)"
  $DL -o "$MODELS_DIR/text_encoders/qwen3.5_9b_qwen_image_2.1_pe_i2i.int8_convrot.safetensors" \
     "$BASE/text_encoders/qwen3.5_9b_qwen_image_2.1_pe_i2i.int8_convrot.safetensors"
fi

echo ">> OK. Contenu :"
find "$MODELS_DIR" -maxdepth 2 -type f -printf '   %p  (%s octets)\n'
