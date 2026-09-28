# fakinflu — worker RunPod pour Qwen-Image 2.1 (edition par references).
# IMAGE AUTONOME : ComfyUI mis a jour en 0.37.0 (support Qwen 2.1) + modeles BAKES.
# Pas de network volume. Le worker renvoie le PNG dans la reponse du job.
#
# POURQUOI cette version : aucun tag worker-comfyui n'embarque ComfyUI >= 0.37.0
# (le plus recent, 5.11.0, epingle 0.34.0, ou les nodes TextEncodeQwenImage21 /
# QwenImage21Cache n'existent pas). On reinstalle donc ComfyUI 0.37.0 avec la
# MEME sequence que l'image de base (comfy-cli + resync du venv de lancement
# /opt/venv + smoke test), puis on bake les modeles.

ARG WORKER_TAG=5.10.0-base
FROM runpod/worker-comfyui:${WORKER_TAG}

# --- Mise a jour de ComfyUI vers une version qui supporte Qwen-Image 2.1 -----
ARG COMFYUI_VERSION=0.37.0
ARG CUDA_VERSION_FOR_COMFY=12.8
# 1) reinstall propre de ComfyUI a la version voulue (comfy-cli, comme la base)
RUN rm -rf /comfyui \
 && /usr/bin/yes | comfy --workspace /comfyui install \
      --version "${COMFYUI_VERSION}" --cuda-version "${CUDA_VERSION_FOR_COMFY}" --nvidia
# 2) resync des deps dans le venv de LANCEMENT /opt/venv (sinon crash au start),
#    exactement comme l'image de base (torch cu128 d'abord, puis requirements,
#    puis pin transformers<5 / huggingface-hub<1)
RUN uv pip install torch==2.11.0 torchvision==0.26.0 torchaudio==2.11.0 \
      --index-url https://download.pytorch.org/whl/cu128 \
 && uv pip install -r /comfyui/requirements.txt \
 && for r in /comfyui/custom_nodes/*/requirements.txt; do \
      [ -f "$r" ] && uv pip install -r "$r" || true; \
    done \
 && uv pip install "transformers>=4.50.3,<5" "huggingface-hub<1.0"
# 3) smoke test : demarre ComfyUI au build -> echoue ICI si 0.37 casse quelque chose
RUN cd /comfyui && timeout 300 python main.py --quick-test-for-ci --cpu

# --- BAKE des modeles Qwen-Image 2.1 ----------------------------------------
# WITH_PE=1 pour inclure aussi le prompt-enhancer (4e modele).
ARG WITH_PE=0
COPY download_models.sh /tmp/download_models.sh
RUN MODELS_DIR=/comfyui/models WITH_PE=${WITH_PE} bash /tmp/download_models.sh

# Le handler par defaut du worker-comfyui suffit : il renvoie les images
# (base64) dans la reponse du job. Rien d'autre a ajouter.
