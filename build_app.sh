#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="RuSwitcher"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
# Universal-сборка кладёт продукт сюда (а не в .build/release)
BUILD_DIR="$PROJECT_DIR/.build/apple/Products/Release"

echo "=== Building $APP_NAME ==="

# 1. Собираем release — universal (arm64 + x86_64), чтобы работало и на Intel-маках
echo "→ swift build -c release --arch arm64 --arch x86_64 (universal)..."
cd "$PROJECT_DIR"
swift build -c release --arch arm64 --arch x86_64

# 2. Создаём .app bundle
echo "→ Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Копируем бинарник
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 3a. Самопроверка: бинарь обязан быть universal (arm64 + x86_64), иначе Intel-маки не запустят
ARCHS=$(lipo -archs "$APP_BUNDLE/Contents/MacOS/$APP_NAME")
if [[ "$ARCHS" != *"arm64"* || "$ARCHS" != *"x86_64"* ]]; then
    echo "ERROR: бинарь не universal (получено: $ARCHS)"; exit 1
fi
echo "→ Universal OK: $ARCHS"

# 4. Копируем Info.plist (версия берётся напрямую из файла в репо)
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# 5. Копируем иконку
cp "$PROJECT_DIR/RuSwitcher.icns" "$APP_BUNDLE/Contents/Resources/RuSwitcher.icns"

# 6. Создаём PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# 7. Подписываем Developer ID (разрешения macOS привязаны к подписи —
#    при одинаковой подписи разрешения сохраняются между обновлениями)
SIGN_ID="Developer ID Application: Rashid Nasibulin (9GEWCZ59HK)"
echo "→ Code signing with Developer ID..."
codesign --force --deep --sign "$SIGN_ID" \
    --options runtime \
    --entitlements "$PROJECT_DIR/RuSwitcher.entitlements" \
    "$APP_BUNDLE"

echo ""
echo "=== Done! ==="
echo "App bundle: $APP_BUNDLE"
echo "Signed with: $SIGN_ID"
echo ""
echo "To install:"
echo "  cp -R $APP_BUNDLE /Applications/"
