# Embedded Tooling

This folder is copied into `KaiPDF.app/Contents/Resources/Tools` during build.

To bundle the offline conversion engine for end users:

```bash
./Scripts/bundle_libreoffice.sh
```

Expected embedded path:

- `Resources/Tools/LibreOffice.app/Contents/MacOS/soffice`
