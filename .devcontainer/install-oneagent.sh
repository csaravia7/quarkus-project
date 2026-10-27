#!/usr/bin/env bash
# Instala Dynatrace OneAgent en modo application-only (PaaS): el Codespace es un contenedor y no admite full-stack.
# Los procesos se instrumentan al arrancar con LD_PRELOAD (ver scripts/oneagent-env.sh).
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

DT_HOME=/opt/dynatrace/oneagent
if [[ -f "$DT_HOME/agent/lib64/liboneagentproc.so" ]]; then
  echo ">> OneAgent (application-only) ya está instalado en $DT_HOME."
  exit 0
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
INSTALLER="$WORKDIR/Dynatrace-OneAgent-PaaS.sh"

echo ">> Descargando OneAgent PaaS (Java + Node.js) desde ${DT_ENV_URL}, arch=${ARCH}..."
# El token va por stdin para que no aparezca en la lista de procesos
printf 'Authorization: Api-Token %s\n' "$DT_API_TOKEN" | curl -fsSL -H @- -o "$INSTALLER" \
  "${DT_ENV_URL}/api/v1/deployment/installer/agent/unix/paas-sh/latest?arch=${ARCH}&flavor=default&include=java&include=nodejs"

echo ">> Instalando en $DT_HOME..."
sudo mkdir -p "$DT_HOME"
sudo sh "$INSTALLER" "$DT_HOME"
# Los procesos de la app (usuario vscode / node, uid 1000) deben poder escribir logs y runtime del agente
sudo chown -R "$(id -u):$(id -g)" "$DT_HOME"

if [[ ! -f "$DT_HOME/agent/lib64/liboneagentproc.so" ]]; then
  echo ">> No se encontró liboneagentproc.so tras la instalación." >&2
  exit 1
fi
echo ">> OneAgent application-only listo. Los servicios se instrumentan al iniciarlos con scripts/start-*.sh"
