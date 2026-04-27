---
description: "Pre-PR checklist for Go: format, vet, lint, and test across all packages before submitting."
---

# Go Preflight Checklist

Run these before creating any PR or reporting a Go task complete.

## 1. Format

```bash
# Lists any files that would be reformatted — empty output = clean
gofmt -l .
# Fix: gofmt -w .
```

If the repo configures `goimports`: also `goimports -l .` (then `-w .` to fix).

## 2. Vet — Go's built-in static analyzer

```bash
go vet ./...
```

`go vet` catches several classes of bug that `go build` doesn't — shadowed errors, unreachable code, struct-tag typos. Never skip.

## 3. Lint (if configured)

```bash
golangci-lint run ./...
```

If `golangci-lint` isn't installed, ask once before suggesting to install it — don't silently skip linting in a repo that has a `.golangci.yml`.

## 4. Build

```bash
go build ./...
```

This also catches generics mistakes `go vet` misses.

## 5. Tests

```bash
go test ./...                           # full
go test -run TestName ./path/to/pkg     # focused
go test -race ./...                     # race detector — run before PR if concurrent code changed
```

For benchmarks, use `go test -bench=. -run=^$ ./...` — only when performance work is in scope.

## 6. Module hygiene

```bash
go mod tidy              # prunes unused deps, adds missing ones
git diff --exit-code go.mod go.sum   # fails if tidy changed anything
```

If `go mod tidy` produced changes, commit them.

## Done?

Report completion only after format, vet, lint (if configured), build, and tests pass cleanly. Do not suppress lint diagnostics with `//nolint` without a comment explaining why.
