---
description: "Pre-PR checklist for Python: format, lint, type-check, and test before submitting. Handles plain venvs, Poetry, uv, and tox — detects which and adapts."
---

# Python Preflight Checklist

Run these in order before creating any PR or reporting a Python task complete.

## 0. Detect the runner

```bash
if [ -f pyproject.toml ] && grep -q '^\[tool.poetry' pyproject.toml; then RUN="poetry run"; \
elif [ -f uv.lock ] || (command -v uv >/dev/null && [ -f pyproject.toml ]); then RUN="uv run"; \
elif [ -f tox.ini ]; then RUN="tox -e py"; \
else RUN=""; fi
```

Prefix every command below with `$RUN` (or bare when `$RUN` is empty). If `tox.ini` is present and the contributor workflow is tox-based, `tox` alone covers format/lint/test.

## 1. Format check

```bash
$RUN ruff format --check .   # or: $RUN black --check .
# Fix: $RUN ruff format .   (or $RUN black .)
```

## 2. Lint — warnings as errors

```bash
$RUN ruff check .            # or: $RUN flake8 .
```

Fix every diagnostic. Common culprits: unused imports after refactoring, shadowed builtins, implicit string concatenation in lists.

## 3. Type check (when mypy or pyright is configured)

```bash
test -f mypy.ini -o -f pyproject.toml && grep -q '^\[tool.mypy' pyproject.toml && $RUN mypy . --strict
# Or for pyright:
test -f pyrightconfig.json && $RUN pyright
```

Skip if neither is configured — don't introduce type-checking in a preflight run.

## 4. Tests

```bash
$RUN pytest                          # full suite
$RUN pytest path/to/test_foo.py      # focused run
$RUN pytest -k 'pattern'             # matches test names
```

If the project uses `pytest-xdist`: `$RUN pytest -n auto` for parallelism. If it uses `tox`: `tox` runs the matrix.

## 5. Optional: dependency audit

```bash
$RUN pip-audit 2>&1 | tail -5        # if pip-audit installed
```

Only run if the PR touches `requirements.txt` / `pyproject.toml` dependencies.

## Done?

Report completion only after format, lint, type-check (if configured), and tests pass cleanly. Do not suppress warnings with `# noqa` / `# type: ignore` without a comment explaining why.
