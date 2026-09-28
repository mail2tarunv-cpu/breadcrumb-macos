#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/local"
APP_NAME="Breadcrumb"
BUNDLE_ID="com.tarun.breadcrumb"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

cd "$ROOT_DIR"

echo "→ Looking for a valid macOS code-signing identity"

IDENTITIES="$(security find-identity -v -p codesigning 2>/dev/null || true)"
IDENTITY_LINE="$(echo "$IDENTITIES" | grep -E '[0-9A-F]{40}' | head -n 1 || true)"

if [[ -z "$IDENTITY_LINE" ]]; then
  echo
  echo "Xcode shows a development certificate, but macOS Keychain is not exposing"
  echo "a usable code-signing identity with its private key."
  echo
  echo "Detected identities:"
  echo "$IDENTITIES"
  echo
  echo "This usually means the certificate exists in Xcode/Apple's account,"
  echo "but its PRIVATE KEY is missing from the login Keychain."
  echo
  echo "Open Keychain Access → login → My Certificates."
  echo "Find your Apple Development certificate and expand it."
  echo "You must see a private key directly underneath it."
  echo
  echo "If there is no private key:"
  echo "  1. Xcode → Settings → Accounts → Manage Certificates…"
  echo "  2. Remove the unusable development certificate for this Mac"
  echo "  3. Click + → Apple Development to create a fresh one on this Mac"
  echo "  4. Quit/reopen Xcode"
  echo "  5. Run this installer again"
  exit 2
fi

SIGNING_IDENTITY="$(echo "$IDENTITY_LINE" | awk '{print $2}')"
SIGNING_NAME="$(echo "$IDENTITY_LINE" | sed -E 's/^[[:space:]]*[0-9]+\) [0-9A-F]+ "(.*)"$/\1/')"

echo "✓ Found valid signing identity"
echo "  Name: $SIGNING_NAME"
echo "  SHA-1: $SIGNING_IDENTITY"
echo

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

echo "→ Signing Breadcrumb with Apple Development certificate"
codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp=none \
  --sign "$SIGNING_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  "$APP_PATH"

echo "→ Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 \
  | grep -E '^(Identifier|Authority|TeamIdentifier|Runtime Version)=' \
  || true

echo "→ Closing any currently running Breadcrumb copy"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
sleep 0.5

echo "→ Replacing installed development copy"
rm -rf "$INSTALL_PATH"
ditto "$APP_PATH" "$INSTALL_PATH"

echo "→ Verifying installed copy"
codesign --verify --deep --strict --verbose=2 "$INSTALL_PATH"

echo "→ Launching $INSTALL_PATH"
open "$INSTALL_PATH"

echo
echo "Breadcrumb is installed at:"
echo "  $INSTALL_PATH"
echo
echo "The app is now signed with:"
echo "  $SIGNING_NAME"
echo
echo "Approve Accessibility when macOS asks."
echo "If System Settings opens, enable Breadcrumb under:"
echo "  Privacy & Security → Accessibility"
echo
echo "After enabling it, quit Breadcrumb once and reopen it from /Applications."
