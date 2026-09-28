#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.brand-assets"
SOURCE_B64="$ROOT_DIR/BrandAssets/Canonical/tucuatro-favicon-512.png.base64"
SOURCE_PNG="$WORK_DIR/tucuatro-favicon-512.png"
MASTER_MARK="$WORK_DIR/tucuatro-mark-white.png"
APP_ICON="$ROOT_DIR/ios/TuCuatroChordsApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
MARK_SET="$ROOT_DIR/ios/TuCuatroChordsApp/Assets.xcassets/TuCuatroMark.imageset"
LAUNCH_SET="$ROOT_DIR/ios/TuCuatroChordsApp/Assets.xcassets/LaunchMark.imageset"

mkdir -p "$WORK_DIR" "$MARK_SET" "$LAUNCH_SET"

# Remove legacy single-file assets from the earlier catalog layout so Xcode
# does not surface them as unassigned children beside the 1x/2x/3x set.
rm -f "$MARK_SET/TuCuatroMark.png"

python3 - "$SOURCE_B64" "$SOURCE_PNG" <<'PY'
import base64
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
dst.write_bytes(base64.b64decode(src.read_text().strip()))
PY

xcrun swift "$ROOT_DIR/scripts/render_brand_assets.swift" "$SOURCE_PNG" "$APP_ICON" "$MASTER_MARK"

if sips -g hasAlpha "$APP_ICON" | grep -q "hasAlpha: yes"; then
    echo "Generated app icon unexpectedly contains alpha." >&2
    exit 1
fi

if ! sips -g pixelWidth -g pixelHeight "$APP_ICON" | grep -q "1024"; then
    echo "Generated app icon is not 1024x1024." >&2
    exit 1
fi

# In-app identity mark: same family sizing convention used by Tuner.
sips -z 34 18 "$MASTER_MARK" --out "$MARK_SET/tucuatro-mark-1x.png" >/dev/null
sips -z 68 36 "$MASTER_MARK" --out "$MARK_SET/tucuatro-mark-2x.png" >/dev/null
sips -z 102 54 "$MASTER_MARK" --out "$MARK_SET/tucuatro-mark-3x.png" >/dev/null

# Launch mark: larger dedicated raster set rather than reusing the in-app asset.
sips -z 88 47 "$MASTER_MARK" --out "$LAUNCH_SET/launch-mark-1x.png" >/dev/null
sips -z 176 94 "$MASTER_MARK" --out "$LAUNCH_SET/launch-mark-2x.png" >/dev/null
sips -z 264 141 "$MASTER_MARK" --out "$LAUNCH_SET/launch-mark-3x.png" >/dev/null

echo "TuCuatro Chords production brand assets are ready."
echo "Generated: AppIcon, TuCuatroMark 1x/2x/3x, LaunchMark 1x/2x/3x."
