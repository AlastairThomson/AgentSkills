---
description: "Deploy dispatcher: detects the project's deployment target(s) — native GUI app, web/server app, container image — and delegates via the Skill tool to the matching sibling (`native-app-deploy`, `web-app-deploy`, `container-app-deploy`). Use whenever the user says 'deploy', 'ship', 'release', 'install', or asks to put a build somewhere."
---

# Deploy Dispatcher

This skill is a **dispatcher**. It detects what kind of deployment the project needs and invokes the matching sibling via the Skill tool. Each sibling owns its own commands.

## Step 1 — Detect deploy target(s)

A project may have multiple markers (e.g. a React frontend packaged as an Electron app with a Dockerised backend — three targets, three siblings). Invoke every sibling whose markers match.

| Marker(s) | Sibling to invoke |
|---|---|
| `tauri.conf.json`, `src-tauri/` | `native-app-deploy` (Tauri macOS) |
| `*.xcodeproj`, `*.xcworkspace`, `Package.swift`, `Podfile` | `native-app-deploy` (iOS / macOS via Xcode) |
| `package.json` with `"electron"` dep, or `forge.config.*`, or `electron-builder.*` | `native-app-deploy` (Electron desktop) |
| `build.gradle` / `build.gradle.kts` + Android Gradle Plugin | `native-app-deploy` (Android via Gradle) |
| `Dockerfile` / `Containerfile` / `compose.yaml` / `docker-compose.yml` | `container-app-deploy` |
| `fly.toml`, `render.yaml`, `railway.json`, `vercel.json`, `netlify.toml`, `Procfile`, `.do/app.yaml` | `web-app-deploy` |
| `package.json` with Express/Fastify/Next/Nest/Koa dep, OR `pyproject.toml` with Flask/FastAPI/Django/Starlette dep, OR `Gemfile` with Rails/Sinatra dep, OR `go.mod` with a web framework (`gin`, `echo`, `fiber`), OR `*.csproj` with ASP.NET | `web-app-deploy` |

If no marker matches, ask the user what kind of deploy they want (don't guess).

## Step 2 — Invoke the matching sibling(s)

For each detected target, call the sibling via the Skill tool. Pass through any user-specified signals (build configuration, target environment, version/tag). When multiple siblings apply, run them in the order the user specifies — if they don't specify, ask. A container-then-web deploy (build image, then release) is common; running them in the wrong order wastes time.

## Step 3 — Confirm before shipping

For any deploy that affects **shared or production state** (App Store, Play Console, production host, public registry), stop after the build and show the artifact/target to the user. Wait for explicit go-ahead before pushing. Local installs (`~/Applications`, iOS Simulator, Android emulator) may proceed without prompting.

## When no sibling fits

If the user's deploy target is none of the above (e.g. bare-metal SSH + systemd, Heroku, AWS Lambda, Cloudflare Workers, a Kubernetes cluster with Helm), fall back to the sibling whose shape is closest (`web-app-deploy` covers most bare-metal and PaaS cases) and follow its "generic SSH" / "custom target" section. If even that doesn't fit, ask the user for the exact commands — don't invent a recipe.
