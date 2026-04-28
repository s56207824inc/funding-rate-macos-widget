#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="FundingRateWidget"
APP_PATH="$HOME/Applications/${APP_NAME}.app"

cd "$ROOT_DIR"

xcodebuild \
  -project FundingRateWidget.xcodeproj \
  -scheme FundingRateWidget \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  clean build

BUILD_SETTINGS="$(xcodebuild \
  -project FundingRateWidget.xcodeproj \
  -scheme FundingRateWidget \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  -showBuildSettings)"

TARGET_BUILD_DIR="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F' = ' '/TARGET_BUILD_DIR/ {print $2; exit}')"
FULL_APP_PATH="${TARGET_BUILD_DIR}/${APP_NAME}.app"

mkdir -p "$HOME/Applications"
rm -rf "$APP_PATH"
cp -R "$FULL_APP_PATH" "$APP_PATH"

echo "Installed to $APP_PATH"
