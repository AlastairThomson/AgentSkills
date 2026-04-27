---
description: "Deploy a native GUI app to its target: ~/Applications (macOS via Tauri, Electron, or Xcode), iOS Simulator, physical iOS device, TestFlight, Android debug via adb, or Google Play Console (.aab upload). Auto-detects project type. For web/server apps use `web-app-deploy`; for container images use `container-app-deploy`."
---

# Native App Deploy

Builds and installs a native GUI app (desktop or mobile) for the current project. Auto-detects the project type from markers in the working directory. For web backends / SaaS apps, use `web-app-deploy` instead; for container images, use `container-app-deploy`.

## Step 1 — Detect project type

| Marker | Project type |
|---|---|
| `tauri.conf.json` or `src-tauri/` | **Tauri** (Rust + WebView) |
| `*.xcodeproj` / `*.xcworkspace` + iOS deployment target | **iOS / iPadOS / visionOS** |
| `*.xcodeproj` / `*.xcworkspace` + macOS deployment target | **macOS (Xcode)** |
| `package.json` with `"electron"` dep | **Electron** |
| `build.gradle` / `build.gradle.kts` with Android plugin | **Android** |

For Tauri projects with a separate sidecar binary (e.g. a background daemon), check whether any Rust crate other than `src-tauri` changed — if so, rebuild the sidecar first (see Tauri section).

---

## Tauri (Rust + WebView → macOS .app)

### When to rebuild a sidecar binary

If the Tauri app depends on a sidecar binary (separate Rust crate shipped inside the bundle) and that crate's sources changed, rebuild the sidecar first. `cargo tauri build` does **not** rebuild sidecars automatically.

```bash
# Step 1a: Rebuild sidecar (skip if only src-tauri / frontend changed)
cargo build --release --package <sidecar-crate-name>
# Tauri expects the sidecar at the target-triple-suffixed path:
cp target/release/<sidecar-bin> target/release/<sidecar-bin>-$(rustc -vV | sed -n 's/host: //p')

# Step 1b: Build the Tauri bundle (run from the crate that owns tauri.conf.json)
cd <path-to-src-tauri-crate>
cargo tauri build
```

The `.app` lands at:
```
target/release/bundle/macos/<AppName>.app
```

### Deploy to ~/Applications

**Always delete before copying** — plain `cp -r` over an existing bundle silently leaves stale dylibs and resources.

```bash
rm -rf ~/Applications/<AppName>.app
cp -r target/release/bundle/macos/<AppName>.app ~/Applications/<AppName>.app
open ~/Applications/<AppName>.app
```

Deploy to `~/Applications` (not `/Applications`) — the app is single-user.

### Dev mode (no install needed)

```bash
cd crates/src-tauri
cargo tauri dev   # hot-reloads frontend, rebuilds Rust on change
```

---

## iOS / iPadOS / visionOS (Xcode)

### Build for simulator

```bash
# Discover available simulators
xcrun simctl list devices available --json | python3 -c \
  "import json,sys; devs=json.load(sys.stdin)['devices']; \
   [print(k,v[0]['name'],v[0]['udid']) for k,vs in devs.items() for v in [vs[:1]] if v]"

xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <SchemeName> \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

### Install and launch on simulator

```bash
UDID=$(xcrun simctl list devices available | grep "iPhone 16" | head -1 \
       | grep -oE '[A-F0-9-]{36}')

xcrun simctl boot "$UDID" 2>/dev/null || true

# Build to a DerivedData folder, then install
xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <SchemeName> \
  -configuration Debug \
  -destination "id=$UDID" \
  -derivedDataPath /tmp/build-<ProjectName> \
  build

APP_PATH=$(find /tmp/build-<ProjectName> -name "*.app" | head -1)
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" <bundle-identifier>
open -a Simulator
```

### Install on physical device (requires signing)

```bash
xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <SchemeName> \
  -configuration Debug \
  -destination 'platform=iOS,name=<DeviceName>' \
  build
# Xcode handles codesigning automatically when a team is configured
```

### Archive for TestFlight / App Store

```bash
# Archive
xcodebuild archive \
  -project <ProjectName>.xcodeproj \
  -scheme <SchemeName> \
  -configuration Release \
  -archivePath /tmp/<ProjectName>.xcarchive

# Export IPA (requires ExportOptions.plist with method = app-store or ad-hoc)
xcodebuild -exportArchive \
  -archivePath /tmp/<ProjectName>.xcarchive \
  -exportPath /tmp/<ProjectName>-ipa \
  -exportOptionsPlist ExportOptions.plist

# Upload to App Store Connect (requires API key or Apple ID)
xcrun altool --upload-app \
  --file /tmp/<ProjectName>-ipa/<AppName>.ipa \
  --apiKey <key-id> --apiIssuer <issuer-id>
# Modern alternative:
xcrun notarytool submit /tmp/<ProjectName>-ipa/<AppName>.ipa \
  --apple-id <email> --team-id <team> --wait
```

---

## macOS app (Xcode, not Tauri)

```bash
# Build release
xcodebuild \
  -project <ProjectName>.xcodeproj \
  -scheme <SchemeName> \
  -configuration Release \
  build

# Or archive for distribution
xcodebuild archive \
  -project <ProjectName>.xcodeproj \
  -scheme <SchemeName> \
  -configuration Release \
  -archivePath /tmp/<ProjectName>.xcarchive

xcodebuild -exportArchive \
  -archivePath /tmp/<ProjectName>.xcarchive \
  -exportPath /tmp/<ProjectName>-app \
  -exportOptionsPlist ExportOptions.plist
```

### Deploy to ~/Applications

```bash
APP_PATH=$(find /tmp/<ProjectName>-app -name "*.app" | head -1)
rm -rf ~/Applications/<AppName>.app
cp -r "$APP_PATH" ~/Applications/<AppName>.app
open ~/Applications/<AppName>.app
```

---

## Android (Gradle)

### Debug build — install on connected device / emulator

```bash
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Or build + install in one step:
./gradlew installDebug
```

### Release build

```bash
./gradlew assembleRelease
# APK: app/build/outputs/apk/release/app-release.apk
# AAB: ./gradlew bundleRelease → app/build/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to Google Play Console for production releases.

---

## Electron (Node.js)

```bash
# Install deps
npm ci

# Package for current platform
npm run make        # electron-forge
# or:
npx electron-builder --mac   # electron-builder

# Output lands in: out/ (forge) or dist/ (builder)
```

### Deploy to ~/Applications (macOS)

```bash
rm -rf ~/Applications/<AppName>.app
cp -r out/<AppName>-darwin-arm64/<AppName>.app ~/Applications/<AppName>.app
open ~/Applications/<AppName>.app
```

---

## Deploy targets at a glance

| Platform | Deploy destination |
|---|---|
| Tauri / Electron / Xcode macOS | `~/Applications/<AppName>.app` |
| iOS / iPadOS Simulator | `xcrun simctl install <udid> <app>` |
| iOS / iPadOS Physical | Xcode automatic install via USB |
| iOS App Store | App Store Connect via `xcrun altool` / `notarytool` |
| Android Debug | `adb install` / `./gradlew installDebug` |
| Android Production | Google Play Console (upload `.aab`) |

## Critical rules

- **Always `rm -rf` before `cp -r`** when replacing a `.app` bundle — stale files survive silent overwrites.
- **Sidecar binaries** in Tauri projects must be manually rebuilt and copied before `cargo tauri build` when their source changes.
- **Never deploy to `/Applications`** — use `~/Applications` for single-user personal apps.
- **iOS signing** — physical device and App Store builds require a valid Apple Developer team set in Xcode project settings.
