# fakinflu — worker RunPod pour Qwen-Image 2.1 (edition par references).
# IMAGE AUTONOME : modeles BAKES dans l'image (PAS de network volume).
# Le worker renvoie le PNG dans la reponse du job -> il arrive sur ton laptop
# via pipeline/comfy_runpod.py (make test). Aucun stockage a gerer cote RunPod.
#
# Base : worker-comfyui officiel (ComfyUI + SDK serverless, protocole
#   {"input":{"workflow":<api>,"images":[{"name","image"}]}} ).
# IMPORTANT : Qwen-Image 2.1 exige ComfyUI >= 0.37.0 (support natif, PR
#   Comfy-Org/ComfyUI#16400). Choisis un WORKER_TAG dont le ComfyUI est >= 0.37.0 ;
#   sinon decommente le bloc "mise a jour ComfyUI" ci-dessous.
# Contrepartie : image de ~20 Go (les poids int8 sont dedans) et build long.

ARG WORKER_TAG=5.11.0-base
FROM runpod/worker-comfyui:${WORKER_TAG}

# --- (optionnel) forcer un ComfyUI recent si le tag est trop ancien ---------
# RUN cd /comfyui && git fetch --all --tags && git checkout v0.37.0 && \
#     pip install --no-cache-dir -r requirements.txt

# --- BAKE des modeles dans l'image ------------------------------------------
# WITH_PE=1 pour inclure aussi le prompt-enhancer (4e modele) -> build arg ci-dessous.
ARG WITH_PE=0
COPY download_models.sh /tmp/download_models.sh
RUN MODELS_DIR=/comfyui/models WITH_PE=${WITH_PE} bash /tmp/download_models.sh

# Le handler par defaut du worker-comfyui suffit : il renvoie les images
# (base64) dans la reponse du job. Rien d'autre a ajouter.
