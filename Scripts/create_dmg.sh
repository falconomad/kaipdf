#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="KaiPDF"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
STAGING_DIR="$DIST_DIR/dmg-staging"
RW_DMG="$DIST_DIR/$APP_NAME-rw.dmg"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "App bundle missing. Run Scripts/build_app.sh first."
  exit 1
fi

rm -rf "$STAGING_DIR"
rm -f "$DMG_PATH" "$RW_DMG"
mkdir -p "$STAGING_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" | awk '/\/dev\// {print $1; exit}')
VOLUME_PATH="/Volumes/$APP_NAME"

osascript <<APPLESCRIPT
 tell application "Finder"
   tell disk "$APP_NAME"
     open
     set current view of container window to icon view
     set toolbar visible of container window to false
     set statusbar visible of container window to false
     set bounds of container window to {120, 120, 760, 500}
     set theViewOptions to the icon view options of container window
     set arrangement of theViewOptions to not arranged
     set icon size of theViewOptions to 128
     set text size of theViewOptions to 14
     try
       set position of item "$APP_NAME.app" of container window to {170, 190}
     end try
     try
       set position of item "Applications" of container window to {470, 190}
     end try
     close
     open
     update without registering applications
     delay 2
   end tell
 end tell
APPLESCRIPT

hdiutil detach "$DEVICE" >/dev/null

hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" >/dev/null

rm -f "$RW_DMG"
rm -rf "$STAGING_DIR"

echo "Created DMG: $DMG_PATH"
