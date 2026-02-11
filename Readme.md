# KaiPDF (Native macOS, Offline)

KaiPDF is a local-first macOS desktop app built with Swift + SwiftUI.

- No cloud services
- No uploads
- All processing on-device

## Features

### V1 (native PDF tools via PDFKit)
- Merge PDFs
- Split PDF into single-page PDFs
- Reorder pages (manual order input)
- Compress PDF (Ghostscript, local binary)

### V2 (offline conversion engine)
- Word (`.doc`, `.docx`) -> PDF (LibreOffice headless)
- PDF -> Word (`.docx`) (LibreOffice headless)

### V3 (batch processing)
- Queue jobs for merge/split/compress/convert
- Run queue sequentially
- Status tracking and logs

## Requirements

- macOS 13+
- Swift 6 toolchain
- Optional for conversions: LibreOffice
- Optional for compression: Ghostscript

Install optional tools:

```bash
brew install --cask libreoffice
brew install ghostscript
```

## Run in development

```bash
swift run
```

## Build app bundle (.app)

```bash
./Scripts/build_app.sh
```

Output:

- `dist/KaiPDF.app`

## Branding and app icon

1. Add a `1024x1024` PNG to `Resources/Branding/AppIcon-1024.png`
2. Generate `icns`:

```bash
./Scripts/make_icon.sh
```

3. Build app bundle:

```bash
./Scripts/build_app.sh
```

## Create DMG installer

```bash
./Scripts/create_dmg.sh
```

Output:

- `dist/KaiPDF.dmg`

## Auto push after each module

Install git post-commit hook (pushes current branch after every commit):

```bash
./Scripts/install_auto_push_hook.sh
```

Commit a completed module and push in one command:

```bash
./Scripts/commit_module.sh "feat(module): your message"
```

## Production signing and notarization (for distribution)

Unsigned DMGs can trigger Gatekeeper warnings. For public distribution, sign + notarize.

### 1. Sign app

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: YOUR_NAME (TEAMID)" \
  dist/KaiPDF.app
```

### 2. Rebuild DMG

```bash
./Scripts/create_dmg.sh
```

### 3. Submit DMG for notarization

```bash
xcrun notarytool submit dist/KaiPDF.dmg \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "APP_SPECIFIC_PASSWORD" \
  --wait
```

### 4. Staple ticket

```bash
xcrun stapler staple dist/KaiPDF.dmg
```

### 5. Verify

```bash
spctl -a -t open --context context:primary-signature -v dist/KaiPDF.dmg
```

Or run in one step:

```bash
export DEV_ID_APP_CERT="Developer ID Application: YOUR_NAME (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_PASSWORD="APP_SPECIFIC_PASSWORD"
./Scripts/sign_and_notarize.sh
```

## Notes

- PDF->Word quality depends on the PDF structure and LibreOffice import support.
- For scanned PDFs, add OCR in a later version (Tesseract + OCRmyPDF workflow).
- No external API calls are used by this project.
