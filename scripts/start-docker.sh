#!/usr/bin/env bash
# Construye y levanta ambos microservicios como contenedores
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/oneagent-env.sh

files=(-f docker-compose.yml)
[[ -n "${DT_AGENT_LIB:-}" ]] && files+=(-f docker-compose.oneagent.yml)
docker compose "${files[@]}" up --build
