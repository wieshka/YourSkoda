#!/bin/zsh
# Builds the arm64 .app (via build_app.sh) and packages it into a signed,
# (optionally notarized) drag-to-Applications .dmg ready for a GitHub Release asset.
#
# Usage:
#   ./scripts/make_dmg.sh [version]
#
# If [version] is omitted, it's derived from `git describe --tags` (falls back to "dev").
#
# Respects CODESIGN_IDENTITY (see build_app.sh) for signing both the .app inside
# the image and the .dmg itself. With no identity set, everything is ad-hoc signed
# and notarization is skipped (Apple only notarizes Developer ID signed software).
#
# Notarization uses a Keychain-stored notarytool credential profile rather than
# passing an Apple ID password or API key around. One-time setup on this machine:
#
#   xcrun notarytool store-credentials "yourskoda-notary" \
#     --apple-id "you@example.com" \
#     --team-id "TEAMID" \
#     --password "app-specific-password"   # generate at appleid.apple.com
#
# (Or use --key/--key-id/--issuer for an App Store Connect API key instead of
# an Apple ID + app-specific password.) Then export NOTARY_PROFILE with that
# profile name (defaults to "yourskoda-notary" below) before running this script.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="yourSkoda"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-yourskoda-notary}"

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
  # The app inside is already signed + timestamped by build_app.sh, which is
  # what Gatekeeper actually evaluates on launch. Signing the .dmg itself is a
  # nice-to-have (verifies the disk image wasn't tampered with in transit), so
  # retry the timestamp server a couple of times, then fall back to a
  # non-timestamped signature rather than failing the whole release.
  signed=0
  for attempt in 1 2 3; do
    if codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "$FINAL_DMG"; then
      signed=1
      break
    fi
    echo "==> DMG timestamp signing attempt $attempt failed, retrying in 5s..."
    sleep 5
  done
  if [[ "$signed" -eq 0 ]]; then
    echo "==> Timestamp service unavailable after retries; signing DMG without a timestamp."
    codesign --force --sign "$CODESIGN_IDENTITY" "$FINAL_DMG"
  fi
  echo "==> Verifying DMG signature..."
  codesign --verify --verbose=2 "$FINAL_DMG"

  echo "==> Submitting DMG to Apple notary service (profile: $NOTARY_PROFILE) ..."
  if xcrun notarytool submit "$FINAL_DMG" --keychain-profile "$NOTARY_PROFILE" --wait; then
    echo "==> Stapling notarization ticket..."
    xcrun stapler staple "$FINAL_DMG"

    echo "==> Verifying Gatekeeper acceptance..."
    spctl --assess --type open --context context:primary-signature -v "$FINAL_DMG"
  else
    echo "==> Notarization failed or no credential profile named '$NOTARY_PROFILE' in Keychain."
    echo "    Continuing with a signed-but-not-notarized .dmg (see script header for one-time setup)."
    echo "    Downloads will show a Gatekeeper block until notarized."
  fi
else
  echo "==> Skipping DMG code signing (ad-hoc identity; DMG itself is left unsigned)."
fi

shasum -a 256 "$FINAL_DMG" > "$FINAL_DMG.sha256"

echo "==> Release asset ready:"
echo "    $FINAL_DMG"
echo "    $FINAL_DMG.sha256"
