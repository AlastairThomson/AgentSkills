---
description: "Pre-PR / pre-merge quality gate dispatcher: detects the project's language(s) and delegates to the matching language-specific preflight skill (cargo-preflight, python-preflight, node-preflight, etc.). Use before any PR, after any merge, or at the end of a work session."
---

# Preflight Dispatcher

This skill is a **dispatcher**. It detects the project's toolchain(s) and invokes the matching language-specific preflight skill via the Skill tool. Each language sibling owns its own format/lint/build/test commands; this page only decides which sibling runs.

## Step 1 — Detect toolchain(s)

Inspect the project root. Multiple markers can apply simultaneously (e.g. a Tauri app = Rust + Node); run every applicable sibling.

| Marker file(s) | Sibling to invoke |
|---|---|
| `Cargo.toml` | `cargo-preflight` |
| `*.xcodeproj`, `*.xcworkspace`, `Package.swift`, `Podfile` | `xcode-preflight` (Swift + Objective-C) |
| `tsconfig.json`, or `package.json` + any TypeScript dep | `node-preflight` (TypeScript mode) |
| `package.json` without TypeScript | `node-preflight` (JavaScript mode) |
| `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile` | `python-preflight` |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | `jvm-preflight` (Java + Kotlin) |
| `go.mod` | `go-preflight` |
| `Gemfile`, `*.gemspec`, `Rakefile` | `ruby-preflight` |
| `*.csproj`, `*.sln`, `Directory.Build.props` | `dotnet-preflight` (C# / .NET) |
| `CMakeLists.txt`, `Makefile`, `configure.ac`, `meson.build` | `cmake-preflight` (C / C++) |
| `composer.json` | `php-preflight` |
| `DESCRIPTION` (R), `*.sas` (SAS), `Makefile.PL` / `cpanfile` (Perl), standalone `.sql` files / `.sqlfluff` | `data-script-preflight` |

If none of these markers are present, or the detected sibling isn't installed, use the inline fallback below.

## Step 2 — Invoke the matching sibling(s)

For each detected toolchain, call the sibling via the Skill tool. The sibling page owns the specific commands — pass through the command-line signals the user gave you (e.g. "only the changed crate", "skip slow tests"). When multiple siblings apply, run them sequentially and fail the overall preflight if any one fails.

If a sibling listed above isn't installed in this repo, either install it via `skill-sync` or fall back to the inline guidance below. Don't invent commands for a toolchain that doesn't have a sibling — ask the user instead.

## Step 3 — Pass criteria (applies to every sibling)

- Zero compilation errors
- Zero lint errors — warnings treated as errors unless the sibling says otherwise
- All tests passing (focused tests for the touched area; full suite if shared code changed)
- No new skipped or ignored tests without an explicit, documented reason

If any step fails, fix it before proceeding. Do not suppress warnings (`#[allow]`, `@Suppress`, `// eslint-disable`, `# noqa`, etc.) without a documented reason.

---

## Inline fallback (no sibling installed)

These quick recipes replicate the sibling output for the most common toolchains. Use them only when the sibling isn't available — the siblings are more thorough and current.

### Rust (fallback for `cargo-preflight`)

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo check
cargo test
```

### Swift / Xcode (fallback for `xcode-preflight`)

```bash
xcodebuild -project <ProjectName>.xcodeproj \
           -scheme <SchemeName> \
           -configuration Debug \
           build-for-testing 2>&1 | grep -E "error:|warning:"

xcodebuild -project <ProjectName>.xcodeproj \
           -scheme <SchemeName> \
           -only-testing:<TestTarget>/<TestSuite>/<TestCase> \
           test
```

Project-specific Xcode conventions (Swift Testing vs XCTest, file-management policy, DI container choice) belong in a per-project conventions skill — not here.

### TypeScript / JavaScript (fallback for `node-preflight`)

```bash
npx tsc --noEmit                  # TypeScript only
npm run lint                      # or: npx eslint src/ --max-warnings 0
npm run build
npm test                          # or: npm run test:unit
```

### Python (fallback for `python-preflight`)

```bash
ruff format --check .             # or: black --check .
ruff check .                      # or: flake8 .
mypy . --ignore-missing-imports   # if mypy configured
pytest
```

If using `uv`: prefix commands with `uv run`. If using `tox`: run `tox`.

### Java/Kotlin Maven (fallback for `jvm-preflight`)

```bash
mvn compile -q
mvn checkstyle:check
mvn test
mvn verify -DskipIntegrationTests
```

### Java/Kotlin Gradle (fallback for `jvm-preflight`)

```bash
./gradlew compileKotlin compileJava
./gradlew ktlintCheck
./gradlew detekt
./gradlew test
./gradlew check
```

Android projects: also `./gradlew lint`.

### Go (fallback for `go-preflight`)

```bash
gofmt -l .                        # fails if any file would be reformatted
go vet ./...
golangci-lint run                 # if installed
go test ./...
```

### Ruby (fallback for `ruby-preflight`)

```bash
bundle exec rubocop
bundle exec rspec                 # or: bundle exec rake test
```

### C# / .NET (fallback for `dotnet-preflight`)

```bash
dotnet format --verify-no-changes
dotnet build --nologo
dotnet test --nologo
```

### C / C++ (fallback for `cmake-preflight`)

```bash
cmake -S . -B build
cmake --build build
(cd build && ctest --output-on-failure)
clang-format --dry-run --Werror $(git ls-files '*.c' '*.cpp' '*.h')
```

### PHP (fallback for `php-preflight`)

```bash
composer validate
vendor/bin/phpcs
vendor/bin/phpstan analyse         # or: vendor/bin/psalm
vendor/bin/phpunit
```

### Data-shaped scripts (fallback for `data-script-preflight`)

Best-effort syntax checks — these languages have no PR gate comparable to `cargo check`.

```bash
# SQL
sqlfluff lint --dialect <dialect> .
# R
Rscript -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'
# SAS — requires a SAS install; per-file syntax check
sas -sysin script.sas -nolog -noprint
# Perl
find . -name '*.pl' -o -name '*.pm' | xargs -I{} perl -c {}
perlcritic lib/ script/
```
