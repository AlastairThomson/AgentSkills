---
description: "Opinionated iOS/macOS app template conventions: Swinject DI, Swift Testing (never XCTest), FileSystemSynchronizedRootGroup file management, Backups/ folder for deletes. Install per-project only for repos that follow this template — not a universal Swift guide."
---

# iOS App Template Conventions

> **Scope.** This skill encodes one specific iOS/macOS app template's conventions. Install it into a repo's `.claude/skills/` **only** when the project genuinely follows these rules. For general Swift/Xcode guidance, use `xcode-preflight` and `swift-testing` — those are intentionally convention-agnostic.

This template mandates: Swinject DI, Swift Testing (not XCTest), `FileSystemSynchronizedRootGroup`-based file management, and a `Backups/` folder for deletions. All four are project policies, not universal Swift best practice.

## File management — do NOT add files manually

Projects using this template use `FileSystemSynchronizedRootGroup`. New files are detected automatically by Xcode when placed in the correct directory. **Never** manually add file references to the `.xcodeproj`. Just create the file in the right folder.

```bash
# Right: just create the file
Write tool → Sources/MyFeature/NewView.swift

# Wrong: don't run addFileToXcodeProject or edit .xcodeproj manually
```

## Deleting files — move to Backups, don't delete

Never delete Swift source files outright. Move them to a `Backups/` folder in the project root:

```bash
mkdir -p Backups
mv Sources/OldFeature/DeprecatedView.swift Backups/
```

This preserves history and makes recovery easy without needing git archaeology.

## Dependency injection — always Swinject

All projects use the Swinject framework for DI. Never use:
- Singletons (`shared` pattern)
- Environment values for service injection in tests
- Direct initialiser injection that bypasses the container

```swift
// Register
container.register(AuthService.self) { _ in
    AuthServiceImpl()
}

// Resolve
let authService = container.resolve(AuthService.self)!
```

## Testing — always Swift Testing, never XCTest

New test files use `import Testing`, `@Test`, `#expect`. Do not write new `XCTestCase` subclasses.

## Build commands

```bash
# Build for testing (use this to verify compilation)
xcodebuild \
  -project <Name>.xcodeproj \
  -scheme <Name> \
  -configuration Debug \
  build-for-testing

# Run a single test
xcodebuild \
  -project <Name>.xcodeproj \
  -scheme <Name> \
  -destination "platform=macOS" \
  -only-testing:<Target>/<Suite>/<Method> \
  test-without-building

# Run a test suite
xcodebuild \
  -project <Name>.xcodeproj \
  -scheme <Name> \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:<Target>/<Suite> \
  test
```

## iOS Simulator destinations

```bash
# List available simulators
xcrun simctl list devices available

# Common destination strings
"platform=iOS Simulator,name=iPhone 16"
"platform=iOS Simulator,name=iPad Pro 13-inch (M4)"
"platform=macOS"
"platform=visionOS Simulator,name=Apple Vision Pro"
```
