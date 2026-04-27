---
description: "Build an OCI / Docker container image and push it to a registry (Docker Hub, GHCR, ECR, GCR/Artifact Registry, ACR, Quay, private). Covers Dockerfile and Buildah flows; supports multi-arch builds via buildx. For deploying the image to a runtime (Kubernetes, Fly.io, ECS), use `web-app-deploy` or a platform-specific sibling."
---

# Container App Deploy

Builds and pushes a container image. This skill **does not deploy the image to a runtime** — that is the downstream sibling's job (`web-app-deploy` for most PaaS targets; Kubernetes / ECS / Cloud Run flows are platform-specific and, for now, manual).

## Step 0 — Preflight

Run `/preflight` on the application source before building the image. A broken build inside a container is harder to diagnose than a broken build on your workstation.

## Step 1 — Detect build tool and registry

```bash
# Tool
if command -v docker >/dev/null; then TOOL=docker; \
elif command -v podman >/dev/null; then TOOL=podman; \
elif command -v buildah >/dev/null; then TOOL=buildah; \
else echo "No container tool available — ask the user"; exit 1; fi

# Registry (inferred from the user's tag prefix, or prompted)
# Examples:
#   docker.io/library/...    → Docker Hub
#   ghcr.io/<owner>/...      → GitHub Container Registry
#   <acct>.dkr.ecr.<region>.amazonaws.com/... → AWS ECR
#   <region>-docker.pkg.dev/<project>/... → GCP Artifact Registry
#   <acct>.azurecr.io/...    → Azure Container Registry
#   quay.io/<org>/...        → Quay
```

Authenticate to the registry **before** building — a push that fails after a 5-minute build wastes everyone's time:

```bash
# Docker Hub / GHCR / Quay
echo "$TOKEN" | docker login <registry> -u <user> --password-stdin
# AWS ECR
aws ecr get-login-password --region <region> | docker login --password-stdin <acct>.dkr.ecr.<region>.amazonaws.com
# GCP
gcloud auth configure-docker <region>-docker.pkg.dev
# Azure
az acr login --name <acct>
```

## Step 2 — Build

### Single-arch (fast, local testing)

```bash
$TOOL build \
    -t <registry>/<repo>:<tag> \
    -t <registry>/<repo>:latest \
    -f Dockerfile \
    --label org.opencontainers.image.source=<git-remote-url> \
    --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
    --label org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
    .
```

Always tag with both an immutable tag (commit SHA, semver) **and** a moving tag (`latest`, `main`). Never rely on `latest` alone for production — it makes rollback impossible.

### Multi-arch (production)

```bash
# One-time: create a builder that supports multi-arch
docker buildx create --name multiarch --use 2>/dev/null || docker buildx use multiarch
docker buildx inspect --bootstrap

# Build and push in one step (multi-arch images can't live in a local cache)
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t <registry>/<repo>:<tag> \
    --push \
    .
```

Multi-arch is mandatory if the runtime includes both Intel and ARM hosts (common on AWS Graviton, Apple Silicon dev machines, some Azure VMs).

### Reproducible builds

For deploys that cross an audit boundary (FedRAMP, SOC 2), pin the base image by digest, not tag:

```dockerfile
# Fragile (tag can move)
FROM python:3.12-slim

# Reproducible (digest is immutable)
FROM python:3.12-slim@sha256:abc123...
```

Pair with `--provenance=true --sbom=true` in `docker buildx` to emit an SBOM alongside the image.

## Step 3 — Vulnerability scan (before push)

```bash
# Trivy (most common)
trivy image --exit-code 1 --severity HIGH,CRITICAL <registry>/<repo>:<tag>

# Or grype
grype <registry>/<repo>:<tag> --fail-on high
```

If vulnerabilities are found, stop and report to the user. Do not push a known-vulnerable image to a shared registry without explicit override.

## Step 4 — Push

```bash
# Single-arch
$TOOL push <registry>/<repo>:<tag>
$TOOL push <registry>/<repo>:latest

# Multi-arch — already pushed by buildx --push above
```

## Step 5 — Verify

```bash
# Pull back from the registry to confirm the push worked and the tags resolve
$TOOL pull <registry>/<repo>:<tag>
$TOOL image inspect <registry>/<repo>:<tag> --format '{{.RepoDigests}}'

# Record the immutable digest — downstream deploys should reference this, not the tag
```

Report the digest to the user. If this image is going to a production runtime, the runtime deploy should pin to the digest (`sha256:...`), not the tag — tags are mutable, digests are not.

## Compose / multi-service projects

For `docker-compose.yml` / `compose.yaml` projects:

```bash
# Build every service's image at once
docker compose build

# Tag + push each
for svc in $(docker compose config --services); do
    docker tag "$(basename $PWD)_${svc}" "<registry>/<repo>-${svc}:<tag>"
    docker push "<registry>/<repo>-${svc}:<tag>"
done
```

Or use `docker compose build --push` if the compose file already declares image names under the registry.

## Critical rules

- **Never push `:latest` alone** to production. Always co-tag with an immutable reference (SHA or semver).
- **Never skip the vuln scan** for images that will run in shared infrastructure.
- **Never push a development build** (debugger, dev deps, source maps) with a `:prod` or `:latest` tag — that's how debug symbols leak into production.
- **Secrets never go into the image.** Build-time secrets use `docker buildx --secret id=foo,src=file`; runtime secrets come from the runtime's secret store.
- **Build in CI, not on a developer laptop** for anything shipping to production. Local environments drift; CI is reproducible.
