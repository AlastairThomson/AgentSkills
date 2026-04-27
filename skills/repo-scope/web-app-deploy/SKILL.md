---
description: "Deploy a web / server app to its hosting target: Fly.io, Render, Railway, Vercel, Netlify, Heroku, DigitalOcean App Platform, or a bare-metal host via SSH. Covers Node / Python / Ruby / Go / JVM / PHP / .NET backends and static frontends. For native GUI apps use `native-app-deploy`; for container images use `container-app-deploy`."
---

# Web App Deploy

Deploys a web or server application to its hosting target. The host is detected from config files; commands then run via that host's CLI.

## Step 0 — Preflight

Before deploying, make sure the build passes. Run `/preflight` (or the language-specific sibling directly) and fix any failures. Deploying a broken build to shared infrastructure is the most common "avoidable outage" pattern.

## Step 1 — Detect host

| Marker | Host | CLI |
|---|---|---|
| `fly.toml` | Fly.io | `flyctl` (or `fly`) |
| `render.yaml` or dashboard-linked | Render | `render` CLI or Git push |
| `railway.json` / `railway.toml` | Railway | `railway` |
| `vercel.json` or `.vercel/` | Vercel | `vercel` |
| `netlify.toml` or `.netlify/` | Netlify | `netlify` |
| `Procfile` without other markers | Heroku | `heroku` |
| `.do/app.yaml` | DigitalOcean App Platform | `doctl apps` |
| `wrangler.toml` | Cloudflare Workers/Pages | `wrangler` |
| None of the above, but user has a host in mind | bare-metal / custom | `ssh` / `rsync` / `scp` |

Verify the CLI is authenticated (`flyctl auth whoami`, `vercel whoami`, etc.) before any deploy command — not after a failure.

## Step 2 — Build

Language-appropriate production build:

```bash
# Node / TypeScript
npm ci && npm run build

# Python (if the app needs a wheel or bundled deps)
pip install -r requirements.txt -t ./build/
# or: poetry build; uv build

# Go
go build -o bin/app ./cmd/app

# JVM
./gradlew bootJar         # Spring Boot
./gradlew shadowJar       # Ktor / generic fat-jar

# Rust
cargo build --release --bin <app-name>

# Ruby / Rails — no build artifact; deploy relies on `bundle install` on host

# .NET
dotnet publish -c Release -o ./publish

# PHP — deploy source + composer install on host; no build artifact
```

## Step 3 — Deploy

### Fly.io

```bash
flyctl deploy --remote-only              # builds on Fly infra
flyctl status
flyctl logs -n 50
```

For multi-service apps: `flyctl deploy -c fly.api.toml` per service.

### Render

Most Render services deploy on Git push to the connected branch. Manual trigger:

```bash
render services deploy --service-id <id>
```

### Railway

```bash
railway up
railway logs --deployment
```

### Vercel / Netlify (frontends or SSR Node apps)

```bash
vercel --prod                 # Vercel
netlify deploy --prod         # Netlify
```

### Heroku

```bash
git push heroku main
heroku logs --tail --num 100
```

### Cloudflare Workers / Pages

```bash
wrangler deploy                       # Workers
wrangler pages deploy ./dist         # Pages
```

### Bare-metal SSH (generic)

```bash
# Upload build artifact
rsync -az --delete ./dist/ deploy@host:/srv/app/

# Restart service (systemd)
ssh deploy@host 'sudo systemctl restart app.service'

# Or: zero-downtime via symlink swap
ssh deploy@host "\
  ln -sfn /srv/releases/$(date +%Y%m%d%H%M) /srv/app.current && \
  sudo systemctl reload app.service"
```

Never edit files directly on a production host. All changes flow from the build artifact.

## Step 4 — Verify

Every deploy ends with a smoke test:

```bash
# HTTP health check — fail the deploy if 2xx/3xx not returned
curl -fsS -o /dev/null -w "%{http_code}\n" https://<host>/healthz

# Log tail (for ~30s) to catch startup errors
<host-cli> logs --tail
```

Do not claim "done" until the health check returns success and no error-level logs appear within 30 seconds of deploy.

## Step 5 — Rollback plan

Before deploying, know the rollback command:

| Host | Rollback |
|---|---|
| Fly.io | `flyctl releases` → `flyctl deploy --image <previous-image>` |
| Render | Dashboard → Deploys → redeploy previous |
| Railway | `railway rollback` |
| Vercel | `vercel rollback <deployment-url>` |
| Heroku | `heroku releases` → `heroku releases:rollback v<N>` |
| SSH symlink deploy | `ln -sfn /srv/releases/<previous> /srv/app.current && systemctl reload` |

If rollback is not possible (e.g. forward-only migrations), stop and confirm with the user **before** shipping.

## Critical rules

- **Never deploy to production without the user's explicit go-ahead** in the current conversation. A previous approval does not count.
- **Never skip the health check.** A silent "deploy succeeded" return code does not mean the app is serving.
- **Never edit live files on a host.** All changes go through the build + deploy pipeline.
- **Database migrations** are a separate concern. If the deploy requires a migration, run it **before** switching traffic. If you don't know whether it's forward-only, ask.
- **Secrets** live in the host's secret store (Fly secrets, Render env vars, `systemd` EnvironmentFile). Never commit them, never pass them on the command line where they'd enter shell history.
