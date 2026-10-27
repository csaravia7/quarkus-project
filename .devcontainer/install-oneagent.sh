#!/usr/bin/env bash
# Instala Dynatrace OneAgent (full-stack) directamente en el sistema operativo del Codespace con el instalador Linux.
set -euo pipefail

if [[ -z "${DT_ENV_URL:-}" || -z "${DT_API_TOKEN:-}" ]]; then
  echo ">> AVISO: DT_ENV_URL / DT_API_TOKEN no definidos; se omite OneAgent." >&2
  echo ">> Crea el Codespace con 'New with options' e ingresa las variables, o ejecuta luego: bash .devcontainer/install-oneagent.sh" >&2
  exit 0
fi

DT_ENV_URL="${DT_ENV_URL%/}"
if [[ ! "$DT_ENV_URL" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?(/e/[A-Za-z0-9-]+)?$ ]]; then
  echo ">> DT_ENV_URL inválida: $DT_ENV_URL" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) ARCH=x86 ;;
  aarch64 | arm64) ARCH=arm ;;
  *) echo ">> Arquitectura no soportada: $(uname -m)" >&2; exit 1 ;;
esac

if [[ -x /opt/dynatrace/oneagent/agent/tools/oneagentctl ]]; then
  echo ">> OneAgent ya está instalado."
  exec bash "$(dirname "$0")/start-oneagent.sh"
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
INSTALLER="$WORKDIR/Dynatrace-OneAgent-Linux.sh"

echo ">> Descargando instalador OneAgent (${DT_ENV_URL}, arch=${ARCH})..."
# El token va por stdin para que no aparezca en la lista de procesos
printf 'Authorization: Api-Token %s\n' "$DT_API_TOKEN" | curl -fsSL -H @- -o "$INSTALLER" \
  "${DT_ENV_URL}/api/v1/deployment/installer/agent/unix/default/latest?arch=${ARCH}&flavor=default"

echo ">> Verificando firma del instalador..."
curl -fsSL -o "$WORKDIR/dt-root.cert.pem" https://ca.dynatrace.com/dt-root.cert.pem
( echo 'Content-Type: multipart/signed; protocol="application/x-pkcs7-signature"; micalg="sha-256"; boundary="--SIGNED-INSTALLER"'
  echo; echo; echo '----SIGNED-INSTALLER'; cat "$INSTALLER" ) \
  | openssl cms -verify -CAfile "$WORKDIR/dt-root.cert.pem" >/dev/null

args=(--set-monitoring-mode=fullstack --set-app-log-content-access=true)
[[ -n "${DT_HOST_GROUP:-}" ]] && args+=("--set-host-group=${DT_HOST_GROUP}")

echo ">> Instalando OneAgent en el sistema operativo..."
sudo /bin/sh "$INSTALLER" "${args[@]}"

bash "$(dirname "$0")/start-oneagent.sh"
