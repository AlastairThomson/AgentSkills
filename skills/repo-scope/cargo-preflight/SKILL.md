---
description: "Pre-PR checklist for Rust: format (cargo fmt), lint (clippy with warnings-as-errors), compile check, and test the workspace before submitting."
---

# Cargo Preflight Checklist

Run these in order before creating any PR or reporting a task complete.

## 1. Format check
```bash
cargo fmt --check
# If it fails: cargo fmt  (then re-check)
```

## 2. Lint — warnings as errors
```bash
cargo clippy -- -D warnings
```
Fix every warning before proceeding. Common culprits:
- Unused imports left behind after refactoring
- `#[allow(dead_code)]` accidentally left on public items
- Missing `#[must_use]` on Result-returning functions

## 3. Compile check (fast)
```bash
cargo check
```

## 4. Tests
```bash
cargo test
```
For a specific crate only:
```bash
cargo test -p <crate-name>
```

## 5. Full workspace build
```bash
cargo build
```
Run this before PRs that cross crate boundaries or touch the top-level binary.

## Crate-level vs workspace

| Want | Command |
|------|---------|
| Fast check, whole workspace | `cargo check` |
| Specific crate | `cargo check -p <crate-name>` |
| All tests | `cargo test` |
| One test by name | `cargo test test_name -- --nocapture` |
| Release build | `cargo build --release` |

## Done?

Only report completion after all four steps pass cleanly. If `cargo clippy` or `cargo test` fail, fix them before notifying.
