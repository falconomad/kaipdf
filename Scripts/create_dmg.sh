#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="KaiPDF"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
TMP_DMG="$DIST_DIR/$APP_NAME-temp.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "App bundle missing. Run Scripts/build_app.sh first."
  exit 1
fi

rm -f "$DMG_PATH" "$TMP_DMG"

hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"

echo "Created DMG: $DMG_PATH"
