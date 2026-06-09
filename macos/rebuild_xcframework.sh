#!/bin/bash
# rebuild_xcframework.sh
# Reconstructs TensorFlowLiteCMac.xcframework from libtensorflowlite_c-mac.dylib,
# then ad-hoc signs it so Xcode's codesign step accepts it.
#
# Run from the repo root:  bash macos/rebuild_xcframework.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DYLIB="$REPO_ROOT/macos/libtensorflowlite_c-mac.dylib"
XCFW="$REPO_ROOT/macos/tflite_flutter/TensorFlowLiteCMac.xcframework"
FW="$XCFW/macos-arm64_x86_64/TensorFlowLiteC.framework"
HEADERS_SRC="$REPO_ROOT/src/tensorflow_lite"

echo "→ Cleaning old xcframework..."
rm -rf "$XCFW"

echo "→ Creating framework directory structure..."
mkdir -p "$FW/Versions/A/Headers"
mkdir -p "$FW/Versions/A/Resources"
mkdir -p "$XCFW/_CodeSignature"

echo "→ Copying dylib binary..."
cp "$DYLIB" "$FW/Versions/A/TensorFlowLiteC"

echo "→ Fixing install name..."
# The dylib was built with install name @rpath/libtensorflowlite_c.dylib
# but inside an xcframework it must be @rpath/TensorFlowLiteC.framework/Versions/A/TensorFlowLiteC
# otherwise dyld can't find it at launch.
install_name_tool \
  -id "@rpath/TensorFlowLiteC.framework/Versions/A/TensorFlowLiteC" \
  "$FW/Versions/A/TensorFlowLiteC"

echo "→ Verifying install name..."
otool -D "$FW/Versions/A/TensorFlowLiteC" | tail -1

echo "→ Copying TFLite C API headers..."
cp "$HEADERS_SRC/c_api.h"             "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/c_api_experimental.h" "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/c_api_types.h"       "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/common.h"            "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/builtin_ops.h"       "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/delegate.h"          "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/delegate_options.h"  "$FW/Versions/A/Headers/"
cp "$HEADERS_SRC/xnnpack_delegate.h"  "$FW/Versions/A/Headers/"

echo "→ Writing framework Info.plist..."
cat > "$FW/Versions/A/Resources/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>org.tensorflow.TensorFlowLiteC</string>
    <key>CFBundleName</key>
    <string>TensorFlowLiteC</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleVersion</key>
    <string>2.14.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.14.0</string>
    <key>MinimumOSVersion</key>
    <string>10.11</string>
</dict>
</plist>
PLIST

echo "→ Creating Versions symlinks..."
ln -sf A            "$FW/Versions/Current"
ln -sf Versions/A/TensorFlowLiteC "$FW/TensorFlowLiteC"
ln -sf Versions/A/Headers         "$FW/Headers"
ln -sf Versions/A/Resources       "$FW/Resources"

echo "→ Writing xcframework Info.plist..."
cat > "$XCFW/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AvailableLibraries</key>
	<array>
		<dict>
			<key>BinaryPath</key>
			<string>TensorFlowLiteC.framework/Versions/A/TensorFlowLiteC</string>
			<key>LibraryIdentifier</key>
			<string>macos-arm64_x86_64</string>
			<key>LibraryPath</key>
			<string>TensorFlowLiteC.framework</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
				<string>x86_64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>macos</string>
		</dict>
	</array>
	<key>CFBundlePackageType</key>
	<string>XFWK</string>
	<key>XCFrameworkFormatVersion</key>
	<string>1.0</string>
</dict>
</plist>
PLIST

echo "→ Ad-hoc signing the framework binary first (inside Versions/A)..."
codesign --force --sign - "$FW/Versions/A/TensorFlowLiteC"

echo "→ Ad-hoc signing the full framework bundle..."
codesign --force --sign - "$FW"

echo "→ Verifying signature..."
codesign -dv "$FW" 2>&1 | grep -E "Signature|Identifier" || true

echo ""
echo "✓ Done! TensorFlowLiteCMac.xcframework rebuilt and signed."
echo ""
echo "Next steps:"
echo "  git add macos/tflite_flutter/TensorFlowLiteCMac.xcframework"
echo "  git commit -m 'rebuild: regenerate and sign TensorFlowLiteC macOS xcframework'"