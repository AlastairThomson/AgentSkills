---
description: "Pre-PR checklist for C / C++ (CMake, Make, Meson): format, static analysis, compile, and test. Detects the build system from CMakeLists.txt / Makefile / meson.build and adapts."
---

# C / C++ Preflight Checklist

Run these before creating any PR or reporting a C or C++ task complete.

## 0. Detect build system

```bash
if [ -f CMakeLists.txt ]; then BUILD=cmake; \
elif [ -f meson.build ]; then BUILD=meson; \
elif [ -f Makefile ] || [ -f GNUmakefile ]; then BUILD=make; \
else echo "No CMake/Meson/Makefile found — ask the user"; exit 1; fi
```

## 1. Format check (clang-format)

```bash
# Dry-run over every tracked C/C++ source
clang-format --dry-run --Werror $(git ls-files '*.c' '*.cpp' '*.cc' '*.cxx' '*.h' '*.hpp')
# Fix: clang-format -i <files>
```

Only runs if a `.clang-format` file exists at repo root (clang-format picks it up automatically). Skip silently if no config.

## 2. Static analysis (clang-tidy)

```bash
# Requires a compile_commands.json — generate it via your build system:
#   CMake:  cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
#   Meson:  meson setup build && ln -sf build/compile_commands.json .
#   Make:   use Bear — `bear -- make`
clang-tidy $(git ls-files '*.c' '*.cpp' '*.cc' '*.cxx') -p build --quiet
```

Only runs if a `.clang-tidy` file exists. Keep the check list short — clang-tidy is slow.

## 3. Configure + Build

### CMake

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -Wno-dev
cmake --build build --parallel
```

For warnings-as-errors, ensure the top-level `CMakeLists.txt` sets `-Werror` (GCC/Clang) or `/WX` (MSVC) in the target's compile options.

### Meson

```bash
meson setup build --werror
meson compile -C build
```

### Make

```bash
make -j          # warnings-as-errors must be configured in the Makefile itself
```

## 4. Tests

### CMake + CTest

```bash
(cd build && ctest --output-on-failure -j$(nproc 2>/dev/null || echo 4))
# Focused: (cd build && ctest -R 'TestNamePattern' --output-on-failure)
```

### Meson

```bash
meson test -C build
# Focused: meson test -C build 'test-name'
```

### Direct GoogleTest / Catch2 binary

```bash
./build/test_binary --gtest_filter='SuiteName.TestName'    # GoogleTest
./build/test_binary '[tag]'                                # Catch2
```

## 5. Optional: sanitizer builds

For memory-heavy changes, add a second build with sanitizers enabled:

```bash
cmake -S . -B build-asan -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_C_FLAGS='-fsanitize=address,undefined' \
      -DCMAKE_CXX_FLAGS='-fsanitize=address,undefined'
cmake --build build-asan --parallel
(cd build-asan && ctest --output-on-failure)
```

## Done?

Report completion only after format, configure, build (warnings-as-errors), and tests pass. Do not suppress compiler warnings with `#pragma GCC diagnostic ignored` without a comment explaining why.
