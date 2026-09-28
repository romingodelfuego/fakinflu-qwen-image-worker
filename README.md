# Déploiement de l'endpoint Qwen-Image 2.1 (RunPod Serverless, SANS volume)

Objectif : un endpoint `worker-comfyui` **autonome** (modèles bakés dans l'image, pas de network
volume), qui exécute les workflows `comfyui/*_api.json`. Le résultat (PNG) revient **dans la réponse
du job** → écrit sur ton laptop par `pipeline/comfy_runpod.py` (`make test`).

> **Prérequis** : Qwen-Image 2.1 est natif à partir de **ComfyUI 0.37.0** (PR Comfy-Org/ComfyUI#16400).
> Le worker doit embarquer un ComfyUI ≥ 0.37.0 (bon `WORKER_TAG`, ou bloc « mise à jour » du Dockerfile).

## Coûts (prix serverless réels du compte, $/h)

| GPU (≥24 Go requis) | VRAM | Serverless $/h |
|---|---|---|
| RTX 3090 / RTX A5000 / L4 | 24 Go | **0.69** ← le moins cher qui tient |
| RTX 4090 | 24 Go | 1.10 (plus rapide) |
| RTX A6000 | 48 Go | 1.22 |
| RTX 5090 | 32 Go | 1.58 |

Réglages coût-optimaux : **min workers 0**, **idle timeout ~5 s**, **FlashBoot on**, **pas de network
volume** (modèles bakés → 0 $ de stockage permanent), sortie base64 (pas de S3). À 0.69 $/h, une
génération ~40 s à chaud ≈ **~0,8 ct** ; le poste de coût réel = les cold starts → enchaîne les gens
en rafale tant que le worker est chaud.

## Comment le résultat arrive sur ton laptop

Rien de spécial à configurer : le handler `worker-comfyui` renvoie l'image en base64 dans la réponse.
`make test` la décode et l'écrit dans `data/out/`. Pas de volume, pas de S3, pas de port à ouvrir.
(Options serverless côté RunPod : réponse base64 par défaut ; un bucket S3 n'est utile que pour des
sorties lourdes/vidéo — inutile ici.)

## Build de l'image (modèles bakés)

Le build télécharge ~20 Go de poids → il se fait **côté RunPod ou sur une machine avec Docker**, pas
depuis ce chat.

**Voie recommandée — Import Git Repository (RunPod build pour toi)**
1. Pousser `comfyui/serverless/` (Dockerfile + download_models.sh) dans un repo GitHub.
2. Console RunPod → **Serverless → New Endpoint → Import Git Repository** → ce repo.
   - Build args : `WORKER_TAG=<tag ComfyUI ≥0.37.0>`, `WITH_PE=1` si tu veux l'enhancer.
   - RunPod build l'image (télécharge les modèles au build — plusieurs minutes).
3. GPU **≥ 24 Go** (RTX 4090 / L40S / A6000), container disk ≥ 30 Go, **min workers 0**, FlashBoot on.
4. Récupérer l'**Endpoint ID** → `fakinflu/.env` (`RUNPOD_FAKINFLU_ENDPOINT_ID`).

**Voie alternative — build local + push (si tu as Docker + un registre)**
```bash
cd comfyui/serverless
docker build --build-arg WORKER_TAG=<tag> --build-arg WITH_PE=0 -t <toncompte>/fakinflu-qwen21:v1 .
docker push <toncompte>/fakinflu-qwen21:v1
# puis créer l'endpoint serverless sur cette image (console RunPod ou API)
```

## Vérifier / lancer

```bash
cd fakinflu
make check                 # endpoint joignable, aucun credit
make test                  # edition reference_1 -> data/out/edit.png (sur ton laptop)
make test ENHANCE=1        # idem avec prompt-enhancer (si image buildee WITH_PE=1)
```

1er appel = cold start (chargement des modèles bakés, quelques minutes) ; ensuite quelques dizaines
de secondes. Réponse worker : `{"output":{"images":[{"filename","type":"base64","data":"..."}]}}`.

## Avant de builder : preflight (0 crédit)

Valide le graphe sur la **même image** avant de dépenser en build/run :
```bash
make local-up WORKER_TAG=<le tag choisi>   # meme image, ComfyUI local :8188
make preflight                              # nodes + modeles OK ? (les modeles ne sont checkes
make local-down                             #   que si tu les montes en local — sinon nodes seuls)
```

## Pièges

- **`✗ endpoint HTTP 404`** : mauvais `RUNPOD_FAKINFLU_ENDPOINT_ID`.
- **node `TextEncodeQwenImage21`/`QwenImage21Cache` inconnu** : ComfyUI < 0.37.0 → change `WORKER_TAG`.
- **node `TextGenerate` inconnu** (seulement `ENHANCE=1`) : enhancer indispo sur ce build → reste en
  prompt direct, ou installe le pack, ou exporte le template officiel en API.
- **OOM au chargement** : GPU < 24 Go pour les poids int8 → prends un GPU plus gros.
