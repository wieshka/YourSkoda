#!/bin/zsh
# Builds the arm64 .app (via build_app.sh) and packages it into a signed,
# drag-to-Applications .dmg ready for a GitHub Release asset.
#
# Usage:
#   ./scripts/make_dmg.sh [version]
#
# If [version] is omitted, it's derived from `git describe --tags` (falls back to "dev").
#
# Respects CODESIGN_IDENTITY (see build_app.sh) for signing both the .app inside
# the image and the .dmg itself. With no identity set, everything is ad-hoc signed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="yourSkoda"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(git describe --tags --always 2>/dev/null || echo dev)"
fi
VERSION="${VERSION#v}"

echo "==> Packaging ${APP_NAME} v${VERSION} (arm64) as .dmg"
"$ROOT_DIR/scripts/build_app.sh"

APP_BUNDLE="$ROOT_DIR/build/${APP_NAME}.app"
DIST_DIR="$ROOT_DIR/build/dist"
STAGING_DIR="$ROOT_DIR/build/dmg-staging"
DMG_NAME="${APP_NAME}-${VERSION}-macos-arm64.dmg"
VOL_NAME="${APP_NAME} ${VERSION}"

rm -rf "$DIST_DIR" "$STAGING_DIR"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

echo "==> Assembling DMG contents..."
ditto "$APP_BUNDLE" "$STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$STAGING_DIR/Applications"

RAW_DMG="$ROOT_DIR/build/${APP_NAME}-raw.dmg"
rm -f "$RAW_DMG"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$RAW_DMG"

FINAL_DMG="$DIST_DIR/$DMG_NAME"
mv "$RAW_DMG" "$FINAL_DMG"

if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
  echo "==> Code signing DMG with identity: $CODESIGN_IDENTITY ..."
  codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "$FINAL_DMG"
  echo "==> Verifying DMG signature..."
  codesign --verify --verbose=2 "$FINAL_DMG"
else
  echo "==> Skipping DMG code signing (ad-hoc identity; DMG itself is left unsigned)."
fi

shasum -a 256 "$FINAL_DMG" > "$FINAL_DMG.sha256"

echo "==> Release asset ready:"
echo "    $FINAL_DMG"
echo "    $FINAL_DMG.sha256"
