---
description: "Pre-PR checklist for data-shaped scripting languages (SQL, R, SAS, Perl): best-effort syntax checks and linters. These languages have no universal PR gate comparable to `cargo check` — this skill runs whatever authoritative checker exists per file type, and flags where human review is still required."
---

# Data-Script Preflight Checklist

**Scope note.** SQL, R, SAS, and Perl don't have a single universal "compile + test" gate the way Rust, Node, or Go do. Coverage varies by dialect and tooling. This skill runs the best checks available per language and is explicit about what it *can't* catch.

Run these before creating any PR or reporting a task complete that touches SQL / R / SAS / Perl files.

## SQL

```bash
# Lint + style (dialect-aware)
sqlfluff lint --dialect <dialect> .
# Fix auto-fixable issues:
sqlfluff fix --dialect <dialect> .
```

Supported dialects include `ansi`, `postgres`, `mysql`, `tsql`, `snowflake`, `bigquery`, `redshift`, `sqlite`. Pick the one the project actually targets. A `.sqlfluff` config file pins this.

**Schema migrations** — if using a migration tool (Flyway, Liquibase, Alembic-with-SQL, `goose`, `dbmate`), also validate the migration set:

```bash
# Flyway
flyway validate
# goose
goose -dir migrations/ sqlite3 ./test.db status
```

**What this doesn't catch:** semantic correctness (does the query return the right rows?). Unit tests for stored procedures and views are project-specific (e.g. `pgTAP` for Postgres, `tSQLt` for MS SQL). If the repo sets up any, run them — the invocation varies by project.

## R

```bash
# Syntax check (parses but doesn't execute)
Rscript -e 'parse(file = commandArgs(trailingOnly = TRUE))' -- path/to/script.R

# Lint
Rscript -e 'lintr::lint_dir()' 2>&1 | tail -20

# Package build check (if the repo is an R package — has DESCRIPTION file)
test -f DESCRIPTION && R CMD check . --no-manual --as-cran

# Tests (testthat)
test -d tests/testthat && Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'
```

If the repo uses `renv` for dependency pinning, prefix commands with `R -e 'renv::load()' -e '...'` or run under a shell with `RENV_PATHS_CACHE` set.

## SAS

```bash
# Requires a SAS install (`sas` on PATH or invoked via a wrapper like SAS Viya CLI).
# Per-file batch syntax check:
for f in *.sas; do
    sas -sysin "$f" -nolog -noprint -SYNTAXCHECK 2>&1 | tail -5
done
```

**What this doesn't catch:** SAS's parser will accept many things that fail at runtime. There is no community-standard SAS linter. If the repo uses `SASUnit` for unit tests, run the provided harness.

If SAS isn't installed locally, this skill can only flag the files for human review. Don't guess.

## Perl

```bash
# Syntax check per file
find . -name '*.pl' -o -name '*.pm' -o -name '*.t' | \
  grep -v '/local/' | xargs -I{} perl -c {} 2>&1 | grep -v 'syntax OK'

# Lint
command -v perlcritic >/dev/null && \
  find . -name '*.pl' -o -name '*.pm' | grep -v '/local/' | xargs perlcritic --quiet

# Tests (Test::More / prove)
command -v prove >/dev/null && prove -lr t/
```

For distributions with `Makefile.PL` or `Dist::Zilla`:

```bash
perl Makefile.PL && make && make test
# or
dzil test
```

## What this skill does NOT do

- Guarantee semantic correctness — the tools above catch syntax and a subset of style/smell issues only.
- Replace code review. Data-shaped code often encodes business logic that only a human with domain context can evaluate.
- Install the underlying tools (`sqlfluff`, `lintr`, `perlcritic`, etc.). If a tool is missing, this skill reports the gap and stops, rather than silently skipping the check.

## Done?

Report completion only after each language's available checks have run cleanly. Where a language has no check available in this environment (e.g. SAS without a local install), name that gap explicitly so the user can triage.
