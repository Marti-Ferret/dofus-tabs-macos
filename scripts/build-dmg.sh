#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DofusTabs"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"
DMG_OUTPUT="$ROOT_DIR/.build/${APP_NAME}-macos.dmg"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "-> No existe $APP_BUNDLE todavía, compilando primero..."
    "$ROOT_DIR/scripts/build-app.sh"
fi

echo "-> Generando $APP_NAME-macos.dmg..."
rm -f "$DMG_OUTPUT"

create-dmg \
    --volname "Dofus Tabs" \
    --volicon "$ROOT_DIR/Resources/AppIcon.icns" \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "$APP_NAME.app" 130 170 \
    --app-drop-link 410 170 \
    --hide-extension "$APP_NAME.app" \
    --no-internet-enable \
    "$DMG_OUTPUT" \
    "$APP_BUNDLE"

echo "-> Listo: $DMG_OUTPUT"
