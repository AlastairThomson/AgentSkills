---
description: "Pre-PR checklist for Node.js (TypeScript + JavaScript): type-check, lint, build, and test. Detects the package manager (npm / pnpm / yarn) from lockfiles and uses it."
---

# Node Preflight Checklist

Run these before creating any PR or reporting a Node / TypeScript / JavaScript task complete.

## 0. Detect package manager

```bash
if [ -f pnpm-lock.yaml ]; then PM=pnpm; \
elif [ -f yarn.lock ]; then PM=yarn; \
else PM=npm; fi
```

Use `$PM run <script>` consistently. Mixing managers in one repo is a common source of weird failures.

## 1. Type check (TypeScript only)

Skip this step for pure-JavaScript repos (no `tsconfig.json`, no TS deps).

```bash
# Prefer a repo-defined script if one exists
$PM run typecheck 2>/dev/null || npx tsc --noEmit
```

For monorepos (`pnpm` workspaces, Yarn workspaces, Nx, Turbo): run the workspace-wide command (e.g. `pnpm -r run typecheck`, `nx run-many -t typecheck`).

## 2. Lint — warnings as errors

```bash
$PM run lint 2>/dev/null || npx eslint . --max-warnings 0
```

If the repo uses Biome instead of ESLint: `npx biome check .`

## 3. Build

```bash
$PM run build
```

Omit only if the repo is a library with no bundle step (e.g. a plain `tsc` library, `tsup`, or a pure `package.json` with no `build` script).

## 4. Tests

```bash
$PM test                        # or: $PM run test
```

Framework-specific focused runs:
- Jest / Vitest: `$PM test -- -t 'test name pattern'` or `$PM test path/to/file.test.ts`
- Mocha: `$PM test -- --grep 'pattern'`
- Playwright (E2E): `$PM run test:e2e` — only when explicitly in scope

For watch-mode frameworks, always use the non-watch CLI variant in preflight (`vitest run`, `jest --watchAll=false`).

## 5. Optional: dependency audit

```bash
$PM audit --production 2>&1 | tail -10
```

Only run if the PR touches `package.json` dependencies.

## Done?

Report completion only after typecheck, lint, build, and tests pass. Do not suppress warnings with `// eslint-disable-next-line` / `// @ts-ignore` without a comment explaining why. Prefer `// @ts-expect-error` over `@ts-ignore` — it fails when the error goes away.
