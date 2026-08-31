#!/bin/zsh
# Builds the arm64 .app and packages it into a versioned .zip ready for a GitHub Release asset.
#
# Usage:
#   ./scripts/package_release.sh [version]
#
# If [version] is omitted, it's derived from `git describe --tags` (falls back to "dev").
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(git describe --tags --always 2>/dev/null || echo dev)"
fi
VERSION="${VERSION#v}"

echo "==> Packaging yourSkoda v${VERSION} (arm64)"
"$ROOT_DIR/scripts/build_app.sh"

APP_BUNDLE="$ROOT_DIR/build/yourSkoda.app"
DIST_DIR="$ROOT_DIR/build/dist"
ZIP_NAME="yourSkoda-${VERSION}-macos-arm64.zip"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ditto (not zip -r) preserves the app bundle's resource forks/metadata correctly.
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$DIST_DIR/$ZIP_NAME"

shasum -a 256 "$DIST_DIR/$ZIP_NAME" > "$DIST_DIR/$ZIP_NAME.sha256"

echo "==> Release asset ready:"
echo "    $DIST_DIR/$ZIP_NAME"
echo "    $DIST_DIR/$ZIP_NAME.sha256"
