#!/bin/zsh
# Builds a release .app bundle for yourSkoda and (optionally) drops it into /Applications.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="yourSkoda"
BUNDLE_ID="com.yourskoda.app"
BUILD_DIR="$ROOT_DIR/.build/apple/Products/Release"
APP_BUNDLE="$ROOT_DIR/build/${APP_NAME}.app"

echo "==> Building release binary..."
swift build -c release

BIN_PATH="$ROOT_DIR/.build/release/YourSkoda"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Release binary not found at $BIN_PATH" >&2
  exit 1
fi

echo "==> Assembling app bundle at $APP_BUNDLE ..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/YourSkoda"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Code signing (ad-hoc)..."
codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"

if [[ "${1:-}" == "--install" ]]; then
  echo "==> Installing to /Applications ..."
  rm -rf "/Applications/${APP_NAME}.app"
  cp -R "$APP_BUNDLE" "/Applications/${APP_NAME}.app"
  echo "==> Installed to /Applications/${APP_NAME}.app"
fi
