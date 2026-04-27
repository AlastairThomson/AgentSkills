---
description: "Pre-PR checklist for Java + Kotlin (JVM): compile, lint, test, and full build. Detects Maven vs Gradle from pom.xml / build.gradle[.kts] and adapts."
---

# JVM Preflight Checklist

Run these before creating any PR or reporting a Java / Kotlin task complete. Works for pure-Java, pure-Kotlin, and mixed Java+Kotlin projects.

## 0. Detect build tool

```bash
if [ -f pom.xml ]; then BUILD=maven; \
elif [ -f gradlew ]; then BUILD=gradle-wrapper; \
elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then BUILD=gradle; \
else echo "No Maven/Gradle build file — ask the user"; exit 1; fi
```

Always prefer `./gradlew` over the system `gradle` — it locks the Gradle version.

## Maven

```bash
# 1. Compile (fast failure)
mvn compile -q

# 2. Lint (if configured)
mvn checkstyle:check -q   # skip silently if Checkstyle isn't set up

# 3. Tests
mvn test -q               # full suite
mvn test -q -Dtest=ClassName#method   # focused run

# 4. Full verify (skips integration tests if your profile sets that flag)
mvn verify -DskipIntegrationTests
```

## Gradle (with wrapper)

```bash
# 1. Compile both Java and Kotlin
./gradlew compileJava compileKotlin

# 2. Lint / static analysis
./gradlew ktlintCheck detekt spotlessCheck 2>/dev/null || true
# (Each command is a no-op if that plugin isn't applied — `|| true` keeps the pipeline going.)

# 3. Tests
./gradlew test                                    # full
./gradlew test --tests 'com.example.FooTest.method'  # focused

# 4. All checks (lint + tests + whatever else is wired up)
./gradlew check
```

Android projects: also run `./gradlew lint` (the Android Lint task) and `./gradlew assembleDebug` for a realistic build.

## Multi-module Gradle

```bash
# Build a single module only
./gradlew :module-name:build

# Test one module
./gradlew :module-name:test --tests '*.FooTest'
```

## Kotlin-specific notes

- `detekt` catches Kotlin smells that `ktlint` misses — run both when the project configures them.
- For pure-Kotlin libraries, `./gradlew apiCheck` (if using Kotlin's binary-compat plugin) is part of preflight.

## Done?

Report completion only after compile, lint, and tests pass cleanly. Do not suppress warnings with `@Suppress` / `@SuppressWarnings` without a comment explaining why.
