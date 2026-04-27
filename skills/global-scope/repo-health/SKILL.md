---
description: "Start-of-session health check: branch state, open PRs, build status, test failures, coverage trend, and leftover worktrees. Auto-detects language. Produces a single status panel."
---

# Repo Health Check

Run at the start of any work session to establish shared situational awareness quickly. Auto-detects the project's language and toolchain.

## Steps — run git checks and build checks in parallel

### 1. Git and PR state

```bash
git fetch --prune
git status
git log --oneline HEAD..origin/$(git rev-parse --abbrev-ref HEAD) 2>/dev/null | wc -l  # commits behind
git log --oneline origin/main..HEAD 2>/dev/null | wc -l                                # commits ahead
git worktree list
gh pr list --state open --json number,title,headRefName,isDraft,mergeable,reviewDecision
```

Flag: conflicted PRs, drafts, PRs open > 7 days, orphan worktrees (branch already merged).

### 2. Detect toolchain(s)

Check for marker files in project root — a project may have multiple (e.g. Tauri = Rust + TypeScript):

| Marker | Toolchain |
|---|---|
| `Cargo.toml` | Rust |
| `*.xcodeproj` / `*.xcworkspace` / `Package.swift` / `*.m` + `*.h` | Swift / Objective-C (Xcode or SPM) |
| `tsconfig.json` or `package.json` + TypeScript dep | TypeScript |
| `package.json` only | JavaScript / Node |
| `pom.xml` | Java/Kotlin (Maven) |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin (Gradle) |
| `pyproject.toml` / `requirements.txt` / `setup.py` / `Pipfile` | Python |
| `go.mod` | Go |
| `Gemfile` / `*.gemspec` / `Rakefile` | Ruby |
| `*.csproj` / `*.sln` / `Directory.Build.props` | C# / .NET |
| `CMakeLists.txt` / `Makefile` / `configure.ac` | C / C++ |
| `composer.json` | PHP |
| `DESCRIPTION` + `.R` / `.Rproj` | R |
| `*.sas` | SAS |
| `Makefile.PL` / `cpanfile` / `MANIFEST` | Perl |
| `.sqlfluff` / `schema.sql` / directory of `*.sql` with no other marker | SQL (standalone) |

### 3. Fast build check (per detected toolchain)

Use the fastest compile/type check available — not a full build:

**Rust:**
```bash
cargo check 2>&1 | tail -3
```

**TypeScript:**
```bash
npx tsc --noEmit 2>&1 | tail -5
```

**Python:**
```bash
ruff check . 2>&1 | tail -5        # or: flake8 . 2>&1 | tail -5
mypy . --ignore-missing-imports 2>&1 | tail -3
```

**Swift:**
```bash
xcodebuild -project *.xcodeproj -scheme <Scheme> -configuration Debug build-for-testing 2>&1 \
  | grep -c "error:" && echo "errors found" || echo "clean"
```

**Java/Kotlin (Gradle):**
```bash
./gradlew compileKotlin compileJava -q 2>&1 | tail -3
```

**Java/Kotlin (Maven):**
```bash
mvn compile -q 2>&1 | tail -3
```

**Go:**
```bash
go build ./... 2>&1 | tail -3
go vet ./... 2>&1 | tail -3
```

**Ruby:**
```bash
ruby -wc $(git ls-files '*.rb' | head -20) 2>&1 | tail -3   # syntax only; no full build for Ruby
bundle exec rake -T 2>/dev/null | head -5                    # available rake tasks (if any)
```

**C# / .NET:**
```bash
dotnet build --nologo -clp:ErrorsOnly 2>&1 | tail -5
```

**C / C++ (CMake):**
```bash
cmake -S . -B build -Wno-dev 2>&1 | tail -3   # configure only, doesn't compile
# (for a fast-as-possible signal; full build is too slow for a health check)
```

**PHP:**
```bash
find . -name '*.php' -not -path './vendor/*' -print0 | xargs -0 -n1 php -l 2>&1 | grep -v "No syntax errors" | head -5
```

**Data-shaped (SQL / R / SAS / Perl):**
```bash
# SQL
command -v sqlfluff >/dev/null && sqlfluff lint --dialect ansi . 2>&1 | tail -5
# R
command -v Rscript >/dev/null && Rscript -e 'pkgbuild::check_build_tools()' 2>&1 | tail -3
# SAS (batch syntax check; requires SAS install)
command -v sas >/dev/null && echo "SAS detected — run manual syntax check per file"
# Perl
find . -name '*.pl' -o -name '*.pm' | head -10 | xargs -I{} perl -c {} 2>&1 | tail -5
```

### 4. Lint check

**Rust:** `cargo clippy -- -D warnings 2>&1 | grep "^error" | head -5`
**TypeScript/JS:** `npm run lint 2>&1 | tail -5`
**Python:** `ruff check . 2>&1 | tail -5`
**Swift / Objective-C:** included in build-for-testing output above
**Kotlin:** `./gradlew ktlintCheck detekt -q 2>&1 | tail -5`
**Java:** `mvn checkstyle:check -q 2>&1 | tail -5`
**Go:** `command -v golangci-lint >/dev/null && golangci-lint run 2>&1 | tail -5`
**Ruby:** `command -v rubocop >/dev/null && bundle exec rubocop --fail-level=error 2>&1 | tail -5`
**C#:** `dotnet format --verify-no-changes 2>&1 | tail -5`
**C/C++:** `command -v clang-tidy >/dev/null && git ls-files '*.c' '*.cpp' '*.h' | head -20 | xargs clang-tidy --quiet 2>&1 | tail -5`
**PHP:** `command -v vendor/bin/phpcs >/dev/null && vendor/bin/phpcs --report=summary 2>&1 | tail -5`
**Perl:** `command -v perlcritic >/dev/null && find . -name '*.pl' -o -name '*.pm' | head -10 | xargs perlcritic --quiet 2>&1 | tail -5`

### 5. Test pulse

Run the fastest test subset — not the full suite. Goal is to detect broken tests quickly:

**Rust:** `cargo test --workspace 2>&1 | grep "^test result"`
**TypeScript/JS:** `npm test -- --passWithNoTests 2>&1 | tail -8`
**Python:** `pytest -q --tb=no 2>&1 | tail -5`
**Swift / Objective-C:** focused run on the most recently changed test suite
**Java/Kotlin:** `./gradlew test -q 2>&1 | tail -5` or `mvn test -q 2>&1 | tail -5`
**Go:** `go test -short ./... 2>&1 | tail -5`
**Ruby:** `command -v rspec >/dev/null && bundle exec rspec --fail-fast --format progress 2>&1 | tail -5`
**C#:** `dotnet test --nologo --verbosity quiet 2>&1 | tail -5`
**C/C++:** `(cd build && ctest --output-on-failure -j4) 2>&1 | tail -5`
**PHP:** `command -v vendor/bin/phpunit >/dev/null && vendor/bin/phpunit --stop-on-failure 2>&1 | tail -5`
**R:** `command -v Rscript >/dev/null && Rscript -e 'if (file.exists("tests/testthat")) testthat::test_dir("tests/testthat", stop_on_failure = TRUE)' 2>&1 | tail -5`
**Perl:** `command -v prove >/dev/null && prove -l --failures --quiet 2>&1 | tail -5`

### 6. Coverage trend (if available)

Check for a recent coverage report without running a new one:

**Rust:** `ls -la lcov.info 2>/dev/null && cargo llvm-cov report 2>/dev/null | grep "^TOTAL"`
**Python:** `ls -la .coverage 2>/dev/null && coverage report 2>/dev/null | tail -3`
**TypeScript:** `ls -la coverage/lcov.info 2>/dev/null && cat coverage/coverage-summary.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin)['total']; print(f\"Lines: {d['lines']['pct']}%\")"`
**Xcode:** `ls -la TestResults.xcresult 2>/dev/null | head -1`

Skip if no report exists — don't run a full coverage pass for health check.

### 7. Recent activity

```bash
git log --oneline -8
```

---

## Output format

Print a single status panel. Adapt to the number of detected toolchains:

```
╭─ Repo Health ──────────────────────────────────────────────────╮
│ Branch:    feature/<current-branch>                            │
│            N ahead of main · 0 behind · clean working tree    │
│                                                                │
│ Rust       build ✅  clippy ✅  tests ✅ N pass                │
│ TypeScript build ✅  lint   ✅  tests ✅ N pass                │
│                                                                │
│ Coverage:  X% adjusted (last measured Nh ago)                 │
│                                                                │
│ Open PRs:  N                                                   │
│   #NNN  <branch>                  ✅ mergeable                 │
│   #NNN  <branch>                  ⚠️  conflicts                │
│                                                                │
│ Worktrees: N orphan (<name> · branch already merged)          │
╰────────────────────────────────────────────────────────────────╯
```

Use ✅ / ⚠️ / ❌ for quick scanning. One row per detected toolchain.

---

## After the panel

State the top 1–3 items needing attention before new work starts. If everything is green, say so and ask what to work on.

**Do not start any other work until the user has seen the health check.** This is the foundation for any session — surprises discovered mid-sprint are much more expensive than surprises surfaced at the start.
