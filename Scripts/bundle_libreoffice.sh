#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="$ROOT_DIR/.cache/libreoffice"
TOOLS_DIR="$ROOT_DIR/Resources/Tools"
LO_APP_TARGET="$TOOLS_DIR/LibreOffice.app"

# Current stable URL can be overridden by setting LIBREOFFICE_DMG_URL
DMG_URL="${LIBREOFFICE_DMG_URL:-https://download.documentfoundation.org/libreoffice/stable/25.2.0/mac/aarch64/LibreOffice_25.2.0_MacOS_aarch64.dmg}"
DMG_PATH="$CACHE_DIR/LibreOffice.dmg"

mkdir -p "$CACHE_DIR" "$TOOLS_DIR"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Downloading LibreOffice DMG..."
  curl -L "$DMG_URL" -o "$DMG_PATH"
fi

MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -readonly | awk '/\/Volumes\// {print substr($0, index($0,$3)); exit}')

if [[ -z "$MOUNT_POINT" ]]; then
  echo "Failed to mount DMG"
  exit 1
fi

SRC_APP="$MOUNT_POINT/LibreOffice.app"
if [[ ! -d "$SRC_APP" ]]; then
  echo "LibreOffice.app not found in mounted DMG"
  hdiutil detach "$MOUNT_POINT" >/dev/null || true
  exit 1
fi

rm -rf "$LO_APP_TARGET"
cp -R "$SRC_APP" "$LO_APP_TARGET"

hdiutil detach "$MOUNT_POINT" >/dev/null

echo "Bundled LibreOffice at: $LO_APP_TARGET"
