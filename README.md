# Quarkus Native API + Node.js Frontend

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/csaravia7/quarkus-project?quickstart=0)

Two microservices ready to run on GitHub Codespaces, Docker or Kubernetes (AKS).

| Service | Folder | Port | Stack |
|---|---|---|---|
| API | `api-quarkus/` | 8080 | Java 21, Quarkus 3, GraalVM native executable |
| Frontend | `frontend-node/` | 3000 | Node.js 20, Express |

The frontend serves the UI and proxies `/api/*` to the API.

## Quick start (GitHub Codespaces)

1. Click **Open in GitHub Codespaces** above (or **Code → Codespaces → New with options**).
2. Wait for the setup to finish (Java, Maven, Node.js and Docker are installed automatically).
3. Run one of:

```bash
./scripts/start-dev.sh      # development mode with hot reload
./scripts/start-docker.sh   # containers (native API)
```

4. Open port **3000** in the browser.

## Deploy to Kubernetes (AKS)

**Requirements:** Docker running on your local machine and `kubectl` connected to your cluster.

**1. Build and push the images to Docker Hub** (run locally)

```bash
# Multi-architecture (linux/amd64 + linux/arm64) – runs on any Linux
./scripts/build-push-dockerhub.sh

# linux/amd64 only – faster, enough for x86 nodes
PLATFORMS=linux/amd64 ./scripts/build-push-dockerhub.sh
```

The script asks for a Docker Hub access token and prints the image tag at the end.

**2. Deploy**

```bash
IMAGE_TAG=<tag> ./scripts/deploy-aks.sh   # or IMAGE_TAG=latest
```

Creates the `quarkus-demo` namespace, applies `k8s/` and prints the public URL of the frontend.

**Check status / remove**

```bash
kubectl -n quarkus-demo get pods,svc
kubectl delete -k k8s
```

## Dynatrace monitoring (optional)

To monitor the services inside Codespaces, create the Codespace with **New with options** and fill in:

| Secret | Value |
|---|---|
| `DT_ENV_URL` | `https://<env-id>.live.dynatrace.com` |
| `DT_API_TOKEN` | API token with `InstallerDownload` scope |

OneAgent is installed automatically in application-only mode and attached when you run `start-dev.sh` or `start-docker.sh`. If no values are provided, the project runs without monitoring.

### Instrumenting the native API image

A GraalVM native executable can only be monitored if it is built with the [Dynatrace GraalVM Native Image module](https://docs.dynatrace.com/docs/ingest-from/technology-support/application-software/java/graalvm-native-image). Pass the same variables to the build script and the API is compiled with the `dynatrace-native` Maven profile (the token is passed as a BuildKit secret and is not stored in the image):

```bash
DT_ENV_URL=https://<env-id>.live.dynatrace.com DT_API_TOKEN=<token> \
PLATFORMS=linux/amd64 ./scripts/build-push-dockerhub.sh
```

The runtime module is copied to `/work/dynatrace`, next to the executable. In Kubernetes with the Dynatrace Operator, connection details are applied automatically; otherwise set `DT_TENANT`, `DT_TENANTTOKEN` and `DT_CONNECTION_POINT` on the `api-quarkus` deployment.

## API

| Method | Path | Description |
|---|---|---|
| GET | `/api/products` | List products |
| GET | `/api/products/{id}` | Get a product |
| POST | `/api/products` | Create a product |
| DELETE | `/api/products/{id}` | Delete a product |
| GET | `/q/health` | Health check |
| GET | `/q/swagger-ui` | API documentation |

## Configuration options

| Variable | Script | Default | Description |
|---|---|---|---|
| `PLATFORMS` | `build-push-dockerhub.sh` | `linux/amd64,linux/arm64` | Target architectures |
| `DOCKERHUB_USER` | both | `rasec777` | Docker Hub account |
| `DOCKERHUB_TOKEN` | both | – | Non-interactive login / private repositories |
| `IMAGE_TAG` | both | current git commit | Image tag to build or deploy |
