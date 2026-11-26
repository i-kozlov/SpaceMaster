#!/bin/bash
# Build the SwiftPM executable and assemble + sign build/SpaceMaster.app.
# Usage: scripts/bundle-app.sh [debug|release]
set -euo pipefail
CONFIG="${1:-debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c "$CONFIG" --product SpaceMaster
BIN="$(swift build -c "$CONFIG" --show-bin-path)"
APP="$ROOT/build/SpaceMaster.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/SpaceMaster" "$APP/Contents/MacOS/SpaceMaster"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# SIGN_IDENTITY: a certificate keeps the app's identity stable across builds, so macOS keeps its permissions.
# Ad-hoc ("-") ties permissions to the code hash, and every build asks again.
codesign --force --sign "${SIGN_IDENTITY:--}" --options runtime --entitlements Resources/SpaceMaster.entitlements "$APP" >/dev/null
# INSTALL=1: replace /Applications/SpaceMaster.app with this build.
if [[ "${INSTALL:-}" == 1 ]]; then
    rm -rf /Applications/SpaceMaster.app
    cp -R "$APP" /Applications/SpaceMaster.app
    APP=/Applications/SpaceMaster.app
fi
echo "$APP"
