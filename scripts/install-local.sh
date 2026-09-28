#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/local"
APP_NAME="Breadcrumb"
BUNDLE_ID="com.tarun.breadcrumb"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

cd "$ROOT_DIR"

echo "→ Generating Xcode project"
xcodegen generate

echo "→ Building Breadcrumb"
xcodebuild \
  -project Breadcrumb.xcodeproj \
  -scheme Breadcrumb \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but $APP_PATH was not found."
  exit 1
fi

echo "→ Applying local ad-hoc signature"
codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_PATH"

echo "→ Replacing installed development copy"
rm -rf "$INSTALL_PATH"
ditto "$APP_PATH" "$INSTALL_PATH"

echo "→ Resetting stale Accessibility permission for the development build"
tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true

echo "→ Launching $INSTALL_PATH"
open "$INSTALL_PATH"

echo
echo "Breadcrumb is installed at:"
echo "  $INSTALL_PATH"
echo
echo "When Breadcrumb asks for Window Awareness, approve Accessibility access."
echo "If macOS opens Privacy & Security, enable Breadcrumb in Accessibility, then quit and reopen Breadcrumb."
