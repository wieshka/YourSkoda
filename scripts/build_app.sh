#!/bin/zsh
# Builds a release .app bundle for yourSkoda and (optionally) drops it into /Applications.
#
# Code signing identity:
#   By default this ad-hoc signs the app (identifier-only, no real identity) which is
#   fine for local development. To produce a properly signed build (e.g. on the
#   self-hosted release runner), export CODESIGN_IDENTITY first:
#
#     export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
#     ./scripts/build_app.sh
#
# Find the exact identity string with:
#     security find-identity -v -p codesigning
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="yourSkoda"
BUNDLE_ID="com.yourskoda.app"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
BUILD_DIR="$ROOT_DIR/.build/apple/Products/Release"
APP_BUNDLE="$ROOT_DIR/build/${APP_NAME}.app"

echo "==> Building release binary (arm64)..."
swift build -c release --arch arm64

BIN_PATH="$ROOT_DIR/.build/arm64-apple-macosx/release/YourSkoda"
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

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  echo "==> Code signing (ad-hoc)..."
  codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE"
else
  echo "==> Code signing with identity: $CODESIGN_IDENTITY ..."
  # --options runtime (hardened runtime) + --timestamp are required for a
  # Developer ID signature Gatekeeper will accept.
  codesign --force --deep --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" --identifier "$BUNDLE_ID" "$APP_BUNDLE"
  echo "==> Verifying signature..."
  codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
fi

echo "==> Done: $APP_BUNDLE"

if [[ "${1:-}" == "--install" ]]; then
  echo "==> Installing to /Applications ..."
  rm -rf "/Applications/${APP_NAME}.app"
  cp -R "$APP_BUNDLE" "/Applications/${APP_NAME}.app"
  echo "==> Installed to /Applications/${APP_NAME}.app"
fi
