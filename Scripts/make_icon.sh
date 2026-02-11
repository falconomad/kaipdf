#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_PNG="${1:-$ROOT_DIR/Resources/Branding/AppIcon-1024.png}"
OUT_ICNS="$ROOT_DIR/Resources/Branding/AppIcon.icns"
ICONSET_DIR="$ROOT_DIR/Resources/Branding/AppIcon.iconset"

if [[ ! -f "$SRC_PNG" ]]; then
  echo "Missing source PNG: $SRC_PNG"
  echo "Provide a 1024x1024 PNG."
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

sips -z 16 16     "$SRC_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$SRC_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$SRC_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$SRC_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$SRC_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$SRC_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$SRC_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$SRC_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$SRC_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$SRC_PNG" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$OUT_ICNS"
rm -rf "$ICONSET_DIR"

echo "Created icon: $OUT_ICNS"
