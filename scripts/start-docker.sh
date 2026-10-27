#!/usr/bin/env bash
# Construye y levanta ambos microservicios como contenedores
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up --build
