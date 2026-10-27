#!/usr/bin/env bash
# Despliega en el cluster AKS actual (contexto de kubectl) las imágenes de Docker Hub aplicando k8s/.
# No crea infraestructura: el cluster debe existir y kubectl debe apuntar a él
# (p. ej. az aks get-credentials -g <rg> -n <cluster>).
#
# Uso:
#   ./scripts/deploy-aks.sh
# Variables opcionales: DOCKERHUB_USER (rasec777), IMAGE_TAG (git sha; usa "latest" si publicaste
#   desde otro commit), DOCKERHUB_TOKEN (solo si los repositorios de Docker Hub son privados)
set -euo pipefail
cd "$(dirname "$0")/.."

DOCKERHUB_USER="${DOCKERHUB_USER:-rasec777}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo latest)}"
NAMESPACE=quarkus-demo

command -v kubectl >/dev/null || { echo ">> Falta 'kubectl' en el PATH" >&2; exit 1; }
CONTEXT="$(kubectl config current-context 2>/dev/null)" || {
  echo ">> kubectl no tiene contexto. Ejecuta: az aks get-credentials -g <rg> -n <cluster>" >&2; exit 1; }
kubectl cluster-info >/dev/null || { echo ">> No hay conexión con el cluster '${CONTEXT}'" >&2; exit 1; }

echo ">> [1/3] Namespace y credenciales de Docker Hub (contexto: ${CONTEXT})"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
  kubectl -n "$NAMESPACE" create secret docker-registry dockerhub \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username="$DOCKERHUB_USER" --docker-password="$DOCKERHUB_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "$NAMESPACE" patch serviceaccount default -p '{"imagePullSecrets":[{"name":"dockerhub"}]}'
fi

echo ">> [2/3] Aplicando k8s/ con docker.io/${DOCKERHUB_USER}/*:${IMAGE_TAG}"
kubectl kustomize k8s \
  | sed -e "s#docker.io/rasec777/\([a-z-]*\):latest#docker.io/${DOCKERHUB_USER}/\1:${IMAGE_TAG}#g" \
  | kubectl apply -f -

# Con "latest" el manifiesto no cambia: se fuerza el reinicio para descargar la imagen nueva
if [[ "$IMAGE_TAG" == "latest" ]]; then
  kubectl -n "$NAMESPACE" rollout restart deployment/api-quarkus deployment/frontend-node
fi

kubectl -n "$NAMESPACE" rollout status deployment/api-quarkus --timeout=180s
kubectl -n "$NAMESPACE" rollout status deployment/frontend-node --timeout=180s

echo ">> [3/3] Esperando IP pública del frontend..."
for _ in $(seq 1 60); do
  IP="$(kubectl -n "$NAMESPACE" get svc frontend-node -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  [[ -n "$IP" ]] && break
  sleep 5
done

kubectl -n "$NAMESPACE" get pods,svc
if [[ -n "${IP:-}" ]]; then
  echo ">> Listo: http://${IP}"
else
  echo ">> La IP aún no está asignada. Revisa: kubectl -n ${NAMESPACE} get svc frontend-node -w"
fi
