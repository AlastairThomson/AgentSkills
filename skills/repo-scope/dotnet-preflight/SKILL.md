---
description: "Pre-PR checklist for C# / .NET: format, restore, build with warnings-as-errors, and test the solution before submitting."
---

# .NET Preflight Checklist

Run these before creating any PR or reporting a .NET task complete. Works for .NET 6, 7, 8, and 9; detects the target framework from the `.csproj` / `.sln`.

## 0. Find the solution or project file

```bash
SLN=$(ls *.sln 2>/dev/null | head -1)
TARGET="${SLN:-$(ls *.csproj 2>/dev/null | head -1)}"
test -n "$TARGET" || { echo "No .sln or .csproj found"; exit 1; }
```

Every command below uses `$TARGET`.

## 1. Restore

```bash
dotnet restore "$TARGET" --nologo
```

Run once per preflight; subsequent build/test commands reuse the cache.

## 2. Format check

```bash
dotnet format "$TARGET" --verify-no-changes --severity warn
# Fix: dotnet format "$TARGET"
```

If the repo uses `CSharpier` instead of `dotnet format`: `dotnet csharpier --check .`

## 3. Build with warnings as errors

```bash
dotnet build "$TARGET" --no-restore --nologo -warnaserror
```

If the csproj already sets `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, the flag is redundant but harmless.

## 4. Static analysis (Roslyn analyzers)

Roslyn analyzer warnings surface during `dotnet build`. If the repo has a `.editorconfig` / `Directory.Build.props` that opts into analyzer packages (`Microsoft.CodeAnalysis.NetAnalyzers`, `StyleCop.Analyzers`), the `-warnaserror` flag above already fails the build on them.

## 5. Tests

```bash
dotnet test "$TARGET" --no-build --nologo
# Focused by fully-qualified name:
dotnet test "$TARGET" --no-build --filter 'FullyQualifiedName~Namespace.TestClass.TestMethod'
# Focused by test class:
dotnet test "$TARGET" --no-build --filter 'ClassName=Namespace.TestClass'
```

For xUnit / NUnit / MSTest — same `--filter` syntax works across frameworks.

## 6. Optional: vulnerable packages

```bash
dotnet list "$TARGET" package --vulnerable --include-transitive 2>&1 | tail -10
```

Only run if the PR touches package references.

## Done?

Report completion only after restore, format, build (with warnings-as-errors), and tests pass. Do not suppress analyzer diagnostics with `#pragma warning disable` without a comment explaining why.
