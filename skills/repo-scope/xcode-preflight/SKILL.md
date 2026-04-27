---
description: "Pre-PR checklist for Swift / Objective-C / Xcode: build-for-testing, warnings, focused test run. Covers both modern FileSystemSynchronizedRootGroup projects and classic group-reference projects."
---

# Xcode Preflight Checklist

Run these before creating any PR or reporting a Swift or Objective-C task complete. The commands below are identical for Swift and Objective-C — both flow through `xcodebuild` and the same warning/error filters.

## 1. Build for testing (catches compilation errors + warnings)

```bash
xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <ProjectName> \
  -configuration Debug \
  build-for-testing \
  2>&1 | grep -E "error:|warning:|BUILD"
```

Fix all errors. Treat warnings seriously — many indicate real bugs.

## 2. Run the specific test(s) you changed

```bash
xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <ProjectName> \
  -destination "platform=macOS" \
  -only-testing:<TestTarget>/<TestSuite>/<TestMethod> \
  test-without-building
```

Only run broader suites when you've touched shared code.

## 3. Prefer focused test runs over whole-suite runs

`xcodebuild` over a whole scheme is slow and often masks which test actually failed. Use `-only-testing:<TestTarget>/<TestSuite>/<TestMethod>` whenever you know what you changed. Run the whole suite only when you've touched shared code or on final pre-PR verification.

## 4. Check for new files — respect the project's file-management style

Xcode projects come in two flavours:

- **`FileSystemSynchronizedRootGroup` (modern)** — files in the group's directory are picked up automatically. You can verify by opening the `.xcodeproj`'s `project.pbxproj` and looking for `PBXFileSystemSynchronizedRootGroup`. If present, **do not** manually add files to the project.
- **Classic Xcode group references** — every file must be added to the `.xcodeproj` explicitly (e.g. via Xcode's File → Add Files, `xcodeproj` gem, or equivalent tooling). Creating a file on disk is not enough.

Detect which applies before adding or deleting source files.

## Objective-C specifics

Mixed Swift/Obj-C targets build through the same `xcodebuild` invocation — no separate step. A few extra checks pay off:

```bash
# Static analysis (Clang) — catches Obj-C memory/logic bugs that the compiler misses
xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <ProjectName> \
  -configuration Debug \
  analyze 2>&1 | grep -E "warning:|error:"
```

If the target uses CocoaPods (`Podfile` present), prefer `.xcworkspace` over `.xcodeproj` in the commands above.

## Done?

Report completion only after build-for-testing passes cleanly and targeted tests pass. If there are warnings in code you changed, fix them. For Objective-C code, `analyze` warnings count too.
