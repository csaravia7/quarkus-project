#!/usr/bin/env bash
# Construye imágenes Linux multi-arquitectura (amd64 + arm64) y las publica en Docker Hub.
# Las imágenes corren en cualquier distro Linux (Ubuntu, RHEL, Debian...) y en AKS/EKS/GKE/OpenShift.
#
# Uso:
#   ./scripts/build-push-dockerhub.sh
# Variables opcionales: DOCKERHUB_USER (rasec777), IMAGE_TAG (git sha), DOCKERHUB_TOKEN (login no interactivo),
#   PLATFORMS (linux/amd64,linux/arm64)
set -euo pipefail
cd "$(dirname "$0")/.."

DOCKERHUB_USER="${DOCKERHUB_USER:-rasec777}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
BUILDER=quarkus-multiarch

if ! docker info >/dev/null 2>&1; then
  echo ">> No hay daemon de Docker disponible. Ejecuta este script en tu máquina local (o en el Codespace)" >&2
  echo "   con Docker Desktop / Colima iniciado. Azure Cloud Shell no tiene Docker." >&2
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "   Mac Apple Silicon (recomendado, emula amd64 con Rosetta):" >&2
    echo "     colima start --vm-type vz --vz-rosetta --cpu 4 --memory 8" >&2
  fi
  exit 1
fi

docker buildx version >/dev/null 2>&1 || { echo ">> Falta 'docker buildx' (necesario para multi-arquitectura)" >&2; exit 1; }

# El driver docker-container permite publicar imágenes multi-plataforma; no cambia el builder por defecto
if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  docker buildx create --name "$BUILDER" --driver docker-container >/dev/null
fi
docker buildx inspect "$BUILDER" --bootstrap >/dev/null

echo ">> Plataformas: ${PLATFORMS}. La arquitectura distinta a la de esta máquina se compila con emulación (la API nativa puede tardar bastante)."

if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
  printf '%s' "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
else
  echo ">> Login en Docker Hub como ${DOCKERHUB_USER} (usa un access token como contraseña)"
  docker login -u "$DOCKERHUB_USER"
fi

for svc in api-quarkus frontend-node; do
  image="docker.io/${DOCKERHUB_USER}/${svc}"
  echo ">> Construyendo y publicando ${image}:${IMAGE_TAG} (${PLATFORMS})"
  docker buildx build --builder "$BUILDER" --platform "$PLATFORMS" \
    -t "${image}:${IMAGE_TAG}" -t "${image}:latest" --push "$svc"
done

echo ">> Imágenes publicadas con tag ${IMAGE_TAG} y latest (${PLATFORMS}):"
echo "   docker.io/${DOCKERHUB_USER}/api-quarkus"
echo "   docker.io/${DOCKERHUB_USER}/frontend-node"
echo ">> Verificar: docker buildx imagetools inspect docker.io/${DOCKERHUB_USER}/api-quarkus:${IMAGE_TAG}"
