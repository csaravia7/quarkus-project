# Quarkus API + Node.js Frontend (GitHub Codespaces)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/csaravia7/quarkus-project?quickstart=0)

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

## Dynatrace OneAgent

El Codespace corre dentro de un contenedor, por lo que OneAgent full-stack no es instalable. Se usa **monitoreo application-only (PaaS)**:

1. Al crear el Codespace, `.devcontainer/install-oneagent.sh` descarga el paquete PaaS (Java + Node.js) desde tu ambiente y lo instala en `/opt/dynatrace/oneagent`.
2. `scripts/start-dev.sh` y `scripts/start-docker.sh` cargan `scripts/oneagent-env.sh`, que activa el agente con `LD_PRELOAD` solo en los procesos de la app.

| Modo | Instrumentado |
|---|---|
| `start-dev.sh` | Frontend Node.js y API Quarkus (JVM) |
| `start-docker.sh` | Frontend Node.js (contenedor). La API nativa GraalVM **no** es instrumentable con OneAgent PaaS |

Si no hay credenciales, se omite y todo funciona sin monitoreo.

Define estas variables al crear el Codespace con **Code → Codespaces → ⋯ → New with options** (o con el botón *Open in GitHub Codespaces* de arriba). La pantalla muestra un campo por cada variable; lo que ingreses se guarda como Codespaces secret de tu usuario y queda disponible como variable de entorno:

| Secret | Valor |
|---|---|
| `DT_ENV_URL` | `https://<env-id>.live.dynatrace.com` |
| `DT_API_TOKEN` | Token con scope `InstallerDownload` |

Reinstalar manualmente: `bash .devcontainer/install-oneagent.sh`. Logs del agente: `/opt/dynatrace/oneagent/log/`.

## Endpoints API

- `GET/POST /api/products`, `GET/DELETE /api/products/{id}`
- Health: `/q/health` · Swagger UI: `/q/swagger-ui`

## CI/CD

`.github/workflows/ci.yml` compila/testea ambos servicios y en `main` publica las imágenes en GHCR.
