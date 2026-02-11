#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/KaiPDF.app"
DMG_PATH="$DIST_DIR/KaiPDF.dmg"
ENTITLEMENTS="$ROOT_DIR/Resources/KaiPDF.entitlements"

: "${DEV_ID_APP_CERT:?Set DEV_ID_APP_CERT, e.g. Developer ID Application: Name (TEAMID)}"
: "${APPLE_ID:?Set APPLE_ID}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID}"
: "${APPLE_APP_PASSWORD:?Set APPLE_APP_PASSWORD}"

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT_DIR/Scripts/build_app.sh"
fi

codesign --deep --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$DEV_ID_APP_CERT" \
  "$APP_PATH"

codesign --verify --verbose=2 "$APP_PATH"

"$ROOT_DIR/Scripts/create_dmg.sh"

xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

xcrun stapler staple "$DMG_PATH"

spctl -a -t open --context context:primary-signature -v "$DMG_PATH"

echo "Signed + notarized DMG ready: $DMG_PATH"
