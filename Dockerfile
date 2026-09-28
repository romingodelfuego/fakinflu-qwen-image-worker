# fakinflu — worker RunPod pour Qwen-Image 2.1 (edition par references).
#
# Base : worker-comfyui officiel (ComfyUI + SDK serverless, protocole
#   {"input":{"workflow":<api>,"images":[{"name","image"}]}} ).
# IMPORTANT : Qwen-Image 2.1 exige ComfyUI >= 0.37.0 (support natif, PR
#   Comfy-Org/ComfyUI#16400). Choisis un tag worker-comfyui dont le ComfyUI
#   est >= 0.37.0 ; sinon on met ComfyUI a jour ci-dessous.
#
# Deux strategies pour les modeles :
#   A) NETWORK VOLUME (recommande) : NE bake PAS les modeles. Deploie ce worker
#      en pointant un volume reseau contenant /ComfyUI/models (voir README).
#      -> commente la section "BAKE" plus bas.
#   B) IMAGE AUTONOME : decommente la section "BAKE" (image de +20 Go).

ARG WORKER_TAG=5.11.0-base
FROM runpod/worker-comfyui:${WORKER_TAG}

# --- (optionnel) forcer un ComfyUI recent si le tag est trop ancien ---------
# RUN cd /comfyui && git fetch --all && git checkout v0.37.0 && \
#     pip install --no-cache-dir -r requirements.txt

# --- BAKE (strategie B seulement) -------------------------------------------
# COPY download_models.sh /tmp/download_models.sh
# RUN MODELS_DIR=/comfyui/models WITH_PE=0 bash /tmp/download_models.sh
#   # WITH_PE=1 pour inclure le prompt-enhancer

# Le handler par defaut du worker-comfyui suffit (il renvoie les images).
