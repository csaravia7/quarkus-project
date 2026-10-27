#!/usr/bin/env bash
set -euo pipefail

bash .devcontainer/install-oneagent.sh || echo ">> AVISO: falló la instalación de OneAgent; se continúa con el resto del setup." >&2

echo ">> Precargando dependencias Maven (api-quarkus)..."
(cd api-quarkus && mvn -B -q -DskipTests package)

echo ">> Instalando dependencias npm (frontend-node)..."
(cd frontend-node && npm install --no-audit --no-fund)

chmod +x scripts/*.sh
echo ">> Listo. Ejecuta: ./scripts/start-dev.sh"
