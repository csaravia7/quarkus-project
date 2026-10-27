#!/usr/bin/env bash
set -euo pipefail

bash .devcontainer/install-oneagent.sh

echo ">> Precargando dependencias Maven (api-quarkus)..."
(cd api-quarkus && mvn -B -q -DskipTests package)

echo ">> Instalando dependencias npm (frontend-node)..."
(cd frontend-node && npm install --no-audit --no-fund)

chmod +x scripts/*.sh
echo ">> Listo. Ejecuta: ./scripts/start-dev.sh"
