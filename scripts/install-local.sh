#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/build"
BUILD_DIR="$BUILD_ROOT/local"
APP_NAME="Breadcrumb"
TEAM_ID="86LW992PDB"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

cd "$ROOT_DIR"

echo "→ Preparing clean non-indexed build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_ROOT"
touch "$BUILD_ROOT/.metadata_never_index"

echo "→ Generating Xcode project"
xcodegen generate

echo "→ Building + signing Breadcrumb with Xcode"
echo "  Team: Tarun V (Personal Team) [$TEAM_ID]"
echo

xcodebuild \
  -project Breadcrumb.xcodeproj \
  -scheme Breadcrumb \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but $APP_PATH was not found."
  exit 1
fi

echo
echo "→ Verifying Xcode signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 \
  | grep -E '^(Identifier|Authority|TeamIdentifier|Runtime Version)=' \
  || true

echo "→ Closing any currently running Breadcrumb copy"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
sleep 0.5

echo "→ Cleaning old Breadcrumb Xcode build products"
setopt local_options null_glob
for old_app in "$HOME"/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/{Debug,Release}/Breadcrumb.app; do
  rm -rf "$old_app"
done

echo "→ Replacing installed development copy"
rm -rf "$INSTALL_PATH"
ditto "$APP_PATH" "$INSTALL_PATH"

echo "→ Verifying installed copy"
codesign --verify --deep --strict --verbose=2 "$INSTALL_PATH"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INSTALL_PATH/Contents/Info.plist" 2>/dev/null || echo "unknown")

echo "→ Installed Breadcrumb $VERSION ($BUILD)"

echo "→ Launching $INSTALL_PATH"
open "$INSTALL_PATH"

echo
echo "Breadcrumb is installed at:"
echo "  $INSTALL_PATH"
echo
echo "Build products stay under a Spotlight-excluded build directory so"
echo "/Applications/Breadcrumb.app remains the canonical searchable copy."
echo
echo "It was signed by Xcode using:"
echo "  Tarun V (Personal Team) [$TEAM_ID]"
echo
echo "If macOS asks for Accessibility access, approve it."
echo "If System Settings opens, enable Breadcrumb under:"
echo "  Privacy & Security → Accessibility"
echo
echo "Then quit Breadcrumb once and reopen it from /Applications."
