#!/usr/bin/env bash
# Compila la API como ejecutable nativo Linux usando el builder Mandrel en contenedor (no requiere GraalVM local)
set -euo pipefail
cd "$(dirname "$0")/../api-quarkus"
./mvnw -B package -Dnative -Dquarkus.native.container-build=true "$@"
ls -lh target/*-runner
