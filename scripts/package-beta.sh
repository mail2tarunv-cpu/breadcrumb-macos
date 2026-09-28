#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="/Applications/Breadcrumb.app"
DIST_DIR="$ROOT_DIR/dist"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Breadcrumb is not installed at $APP_PATH"
  echo "Run: zsh scripts/install-local.sh"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown")
ARCHIVE="$DIST_DIR/Breadcrumb-$VERSION-beta.zip"
CHECKSUM="$ARCHIVE.sha256"

mkdir -p "$DIST_DIR"
touch "$DIST_DIR/.metadata_never_index"
rm -f "$ARCHIVE" "$CHECKSUM"

echo "→ Verifying installed app before packaging"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "→ Packaging Breadcrumb $VERSION ($BUILD)"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE"

echo "→ Writing SHA-256 checksum"
shasum -a 256 "$ARCHIVE" > "$CHECKSUM"

echo
echo "Created:"
echo "  $ARCHIVE"
echo "  $CHECKSUM"
echo
echo "Important:"
echo "  This package uses the app's current development signing identity."
echo "  For broad external beta distribution, configure Developer ID signing"
echo "  and Apple notarization before sending it to testers."
