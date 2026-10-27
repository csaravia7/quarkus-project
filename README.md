# Quarkus API + Node.js Frontend (GitHub Codespaces)

| Servicio | Carpeta | Puerto | Tecnología |
|---|---|---|---|
| API | `api-quarkus/` | 8080 | Java 21 + Quarkus 3, **ejecutable nativo GraalVM (Mandrel)** |
| Frontend | `frontend-node/` | 3000 | Node 20 + Express |

El frontend sirve la UI y hace de proxy server-side de `/api/*` hacia Quarkus (`API_BASE_URL`), así no hay problemas de CORS ni con los puertos privados de Codespaces.

## Arranque en Codespaces

1. Sube el repo a GitHub → **Code → Codespaces → Create codespace**.
2. El devcontainer instala Java 21, Maven, Node 20 y Docker, y precarga dependencias.
3. Ejecuta uno de:
   - Modo dev (hot reload): `./scripts/start-dev.sh` (o tarea VS Code **Start all**)
   - Contenedores (API nativa): `./scripts/start-docker.sh`
   - Solo compilar el binario nativo: `./scripts/build-native.sh`
4. Se abre automáticamente el puerto 3000 (frontend).

## API nativa (GraalVM)

- `api-quarkus/Dockerfile`: build multi-stage con Mandrel → imagen `ubi9-quarkus-micro-image` sin JVM.
- `api-quarkus/Dockerfile.jvm`: alternativa en modo JVM.
- `mvn quarkus:dev` siempre corre en JVM (hot reload); el nativo es para build/deploy.
- Tests contra el binario nativo: `./mvnw verify -Dnative -Dquarkus.native.container-build=true`.
- Verificación: el log de arranque muestra `... native (powered by Quarkus ...)`.

## Endpoints API

- `GET/POST /api/products`, `GET/DELETE /api/products/{id}`
- Health: `/q/health` · Swagger UI: `/q/swagger-ui`

## CI/CD

`.github/workflows/ci.yml` compila/testea ambos servicios y en `main` publica las imágenes en GHCR.
