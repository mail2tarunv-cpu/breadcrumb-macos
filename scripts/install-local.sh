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

LOGIN_KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

IDENTITIES="$(
  security find-identity -v -p codesigning "$LOGIN_KEYCHAIN" 2>/dev/null \
    || security find-identity -v -p codesigning 2>/dev/null \
    || true
)"
IDENTITY_LINE="$(echo "$IDENTITIES" | grep -E '[0-9A-F]{40}' | head -n 1 || true)"

if [[ -z "$IDENTITY_LINE" ]]; then
  echo
  echo "Xcode shows a development certificate, but macOS Keychain is not exposing"
  echo "a usable code-signing identity with its private key."
  echo
  echo "Detected identities:"
  echo "$IDENTITIES"
  echo
  echo "The login Keychain was checked explicitly:"
  echo "  $LOGIN_KEYCHAIN"
  echo
  echo "Certificates visible in the login Keychain:"
  security find-certificate -a "$LOGIN_KEYCHAIN" 2>/dev/null \
    | grep -E 'alis|labl|subj' \
    | head -n 40 \
    || true
  echo
  echo "Since you confirmed the private key exists, the remaining likely causes are:"
  echo "  • the certificate is not currently trusted/valid for code signing"
  echo "  • the login Keychain is locked or excluded from the active search list"
  echo "  • the certificate/private-key ACL is preventing codesign access"
  echo
  echo "Run these two commands and send me the output:"
  echo "  security list-keychains -d user"
  echo "  security find-identity -v -p codesigning ~/Library/Keychains/login.keychain-db"
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
