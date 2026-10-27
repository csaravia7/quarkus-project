#!/usr/bin/env bash
# Levanta ambos microservicios en modo desarrollo (hot reload)
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/oneagent-env.sh

trap 'kill 0' EXIT

(cd api-quarkus && LD_PRELOAD="${DT_AGENT_LIB:-}" mvn -B quarkus:dev -Dquarkus.console.enabled=false) &
(cd frontend-node && LD_PRELOAD="${DT_AGENT_LIB:-}" API_BASE_URL=http://localhost:8080 npm run dev) &

wait
