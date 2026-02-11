#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="KaiPDF"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ICON_PATH="$ROOT_DIR/Resources/Branding/AppIcon.icns"

mkdir -p "$DIST_DIR"

swift build -c release --package-path "$ROOT_DIR"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>KaiPDF</string>
  <key>CFBundleExecutable</key>
  <string>KaiPDF</string>
  <key>CFBundleIdentifier</key>
  <string>com.kaipdf.desktop</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>KaiPDF</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cp "$BUILD_DIR/KaiPDF" "$APP_BUNDLE/Contents/MacOS/KaiPDF"
chmod +x "$APP_BUNDLE/Contents/MacOS/KaiPDF"

if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "Built app bundle: $APP_BUNDLE"
