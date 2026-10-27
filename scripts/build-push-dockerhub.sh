#!/usr/bin/env bash
# Construye las imágenes (linux/amd64) y las publica en Docker Hub.
#
# Uso:
#   ./scripts/build-push-dockerhub.sh
# Variables opcionales: DOCKERHUB_USER (rasec777), IMAGE_TAG (git sha), DOCKERHUB_TOKEN (login no interactivo)
set -euo pipefail
cd "$(dirname "$0")/.."

DOCKERHUB_USER="${DOCKERHUB_USER:-rasec777}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"

if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
  printf '%s' "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
else
  echo ">> Login en Docker Hub como ${DOCKERHUB_USER} (usa un access token como contraseña)"
  docker login -u "$DOCKERHUB_USER"
fi

# AKS corre en amd64; en Mac ARM se compila con emulación (más lento, sobre todo la imagen nativa)
for svc in api-quarkus frontend-node; do
  image="docker.io/${DOCKERHUB_USER}/${svc}"
  echo ">> Construyendo ${image}:${IMAGE_TAG}"
  docker build --platform linux/amd64 -t "${image}:${IMAGE_TAG}" -t "${image}:latest" "$svc"
  docker push "${image}:${IMAGE_TAG}"
  docker push "${image}:latest"
done

echo ">> Imágenes publicadas con tag ${IMAGE_TAG} y latest:"
echo "   docker.io/${DOCKERHUB_USER}/api-quarkus"
echo "   docker.io/${DOCKERHUB_USER}/frontend-node"
