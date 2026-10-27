#!/usr/bin/env bash
# Levanta ambos microservicios en modo desarrollo (hot reload)
set -euo pipefail
cd "$(dirname "$0")/.."

trap 'kill 0' EXIT

(cd api-quarkus && mvn -B quarkus:dev -Dquarkus.console.enabled=false) &
(cd frontend-node && API_BASE_URL=http://localhost:8080 npm run dev) &

wait
