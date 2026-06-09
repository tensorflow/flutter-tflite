# macOS SPM Setup for tflite_flutter

This document explains how the macOS Swift Package Manager (SPM) integration works,
what files are involved, and what to do if something breaks.

---

## How it works

Flutter on macOS can link native libraries via either **CocoaPods** or **SPM**.
This plugin supports both. The loading path is chosen automatically at runtime in
`lib/src/bindings/bindings.dart`:

1. **SPM (primary)** — `DynamicLibrary.process()` is tried first. When Xcode links
   `TensorFlowLiteCMac.xcframework` via SPM, the framework is loaded by dyld at
   launch and all TFLite symbols are already in-process.

2. **CocoaPods (fallback)** — If the symbol probe fails, the code falls back to
   `DynamicLibrary.open(...)` using the `.dylib` path that CocoaPods embeds into
   `<App>.app/Contents/resources/`.

---

## File overview

```
macos/
├── libtensorflowlite_c-mac.dylib       # Source binary (arm64 + x86_64 fat dylib)
├── rebuild_xcframework.sh              # Script to rebuild + sign the xcframework
├── tflite_flutter.podspec              # CocoaPods spec (vendors the .dylib above)
└── tflite_flutter/
    ├── Package.swift                   # SPM manifest — points to xcframework below
    ├── Sources/
    │   └── TfliteFlutterPlugin.swift
    └── TensorFlowLiteCMac.xcframework/ # Built from the .dylib by rebuild script
        ├── Info.plist
        ├── _CodeSignature/             # Ad-hoc signature (required by Xcode)
        └── macos-arm64_x86_64/
            └── TensorFlowLiteC.framework/
                ├── Headers/            # TFLite C API headers (from src/tensorflow_lite/)
                ├── Versions/A/TensorFlowLiteC  # The actual dylib binary
                └── ...
```

The xcframework is **not a separate download** — it is built directly from
`libtensorflowlite_c-mac.dylib` (which lives alongside it in `macos/`) using the
script described below.

---

## Rebuilding the xcframework

You need to run this if any of the following are true:

- `TensorFlowLiteCMac.xcframework` is missing from the repo
- You see a codesign build failure: `code object is not signed at all`
- You see a launch crash: `Library not loaded: @rpath/libtensorflowlite_c.dylib`
- You updated `libtensorflowlite_c-mac.dylib` to a newer TFLite version

Run from the **repo root** on a Mac:

```bash
bash macos/rebuild_xcframework.sh
```

The script does the following in order:

1. Deletes any existing `TensorFlowLiteCMac.xcframework`
2. Creates the full `.framework` directory structure inside the xcframework
3. Copies `libtensorflowlite_c-mac.dylib` as the framework binary
4. **Fixes the install name** with `install_name_tool` — changes it from
   `@rpath/libtensorflowlite_c.dylib` to
   `@rpath/TensorFlowLiteC.framework/Versions/A/TensorFlowLiteC`
   (without this, dyld cannot find the library at app launch)
5. Copies the TFLite C API headers from `src/tensorflow_lite/`
6. Writes the required `Info.plist` files
7. Creates the `Versions/` symlinks required by macOS framework layout
8. **Ad-hoc signs** the binary and the bundle with `codesign --force --sign -`
9. Prints the install name and signature for verification

Then commit the result:

```bash
git add macos/tflite_flutter/TensorFlowLiteCMac.xcframework
git commit -m "rebuild: regenerate and sign TensorFlowLiteC macOS xcframework"
```

> **Why ad-hoc signing?** macOS requires all embedded frameworks to be signed.
> An ad-hoc signature (`-`) is accepted for development and App Store distribution —
> Xcode re-signs the framework with the app's real identity during archiving.

---

## Running integration tests

```bash
flutter test integration_test/tflite_linking_test.dart -d macos
```

Expected output — all 6 tests passing:

```
✓ Built build/macos/Build/Products/Debug/<App>.app
+6: All tests passed!
```

The `Failed to foreground app` warning that may appear is harmless — it is a
UI hint from the test runner, not a test failure.

---

## Updating the TFLite binary

If you need to update to a newer TFLite version:

1. Replace `macos/libtensorflowlite_c-mac.dylib` with the new fat binary
   (must contain both `arm64` and `x86_64` slices).
2. Update `CFBundleVersion` and `CFBundleShortVersionString` in
   `rebuild_xcframework.sh` to match the new version if desired.
3. Run `bash macos/rebuild_xcframework.sh` to rebuild the xcframework.
4. Commit both the `.dylib` and `TensorFlowLiteCMac.xcframework`.

---

## Why not use kewlbear/TensorFlowLiteC (like iOS)?

The iOS `Package.swift` points to a remote xcframework from
[kewlbear/TensorFlowLiteC](https://github.com/kewlbear/TensorFlowLiteC).
That xcframework is **iOS-only** — it has no macOS slice despite Swift Package
Index listing macOS as compatible (that reflects `Package.swift` having no platform
restriction, not the binary contents).

The local `TensorFlowLiteCMac.xcframework` approach is the correct
macOS-specific solution.

---

## CocoaPods users

The `tflite_flutter.podspec` vendors `libtensorflowlite_c-mac.dylib` directly.
CocoaPods embeds it at `<App>.app/Contents/resources/libtensorflowlite_c-mac.dylib`,
which is where the Dart fallback path in `bindings.dart` looks for it.

No additional setup is required for CocoaPods users.

---

## Troubleshooting

| Error                                                                    | Cause                             | Fix                                                                        |
| ------------------------------------------------------------------------ | --------------------------------- | -------------------------------------------------------------------------- |
| `code object is not signed at all`                                       | xcframework missing or unsigned   | Run `rebuild_xcframework.sh`                                               |
| `Library not loaded: @rpath/libtensorflowlite_c.dylib`                   | Wrong install name in dylib       | Run `rebuild_xcframework.sh` (includes `install_name_tool` fix)            |
| `no library for this platform was found`                                 | Wrong xcframework (e.g. iOS-only) | Ensure `TensorFlowLiteCMac.xcframework` is the local one, not kewlbear's   |
| `Unable to start the app on the device`                                  | App crashed at launch             | Check crash log — usually one of the above                                 |
| `building for macOS-X, but linking with dylib built for newer version Y` | Deployment target mismatch        | Update `MACOSX_DEPLOYMENT_TARGET` in Xcode to match the dylib's minimum OS |
