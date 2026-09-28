#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.brand-assets"
SOURCE_B64="$ROOT_DIR/BrandAssets/Canonical/tucuatro-favicon-512.png.base64"
SOURCE_PNG="$WORK_DIR/tucuatro-favicon-512.png"
APP_ICON="$ROOT_DIR/ios/TuCuatroChordsApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
MARK="$ROOT_DIR/ios/TuCuatroChordsApp/Assets.xcassets/TuCuatroMark.imageset/TuCuatroMark.png"

mkdir -p "$WORK_DIR"

python3 - "$SOURCE_B64" "$SOURCE_PNG" <<'PY'
import base64
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
dst.write_bytes(base64.b64decode(src.read_text().strip()))
PY

xcrun swift "$ROOT_DIR/scripts/render_brand_assets.swift" "$SOURCE_PNG" "$APP_ICON" "$MARK"

if sips -g hasAlpha "$APP_ICON" | grep -q "hasAlpha: yes"; then
    echo "Generated app icon unexpectedly contains alpha." >&2
    exit 1
fi

if ! sips -g pixelWidth -g pixelHeight "$APP_ICON" | grep -q "1024"; then
    echo "Generated app icon is not 1024x1024." >&2
    exit 1
fi

echo "TuCuatro Chords production brand assets are ready."
