#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DofusTabs"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"

echo "-> Compilando en modo release..."
swift build -c release --package-path "$ROOT_DIR"

echo "-> Empaquetando $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "   (sin icono: ejecuta 'swift scripts/generate-icon.swift && iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns' primero)"
fi

# Bundle de recursos que genera SwiftPM (Bundle.module) con los .lproj de
# Localizable.strings — sin esto la app localizada no encuentra sus textos
# fuera de `swift run`.
RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
else
    echo "   ADVERTENCIA: no se encontró $RESOURCE_BUNDLE — la app quedará sin textos localizados."
fi

# InfoPlist.strings por idioma (localiza claves del propio Info.plist, como
# NSAccessibilityUsageDescription, que se piden en el diálogo del sistema).
for lang in en es fr; do
    mkdir -p "$APP_BUNDLE/Contents/Resources/$lang.lproj"
    cp "$ROOT_DIR/Resources/AppBundleLocalization/$lang.lproj/InfoPlist.strings" \
       "$APP_BUNDLE/Contents/Resources/$lang.lproj/InfoPlist.strings"
done

echo "-> Firmando (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "-> Listo: $APP_BUNDLE"
echo "   Ábrelo con: open \"$APP_BUNDLE\""
echo "   La primera vez macOS pedirá permiso de Accesibilidad en Ajustes del Sistema > Privacidad y Seguridad > Accesibilidad."
