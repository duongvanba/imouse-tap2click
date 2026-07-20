#!/bin/zsh
set -e
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
swift build -c release
APP_DIR="Imouse Clicker.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp .build/arm64-apple-macosx/release/ImouTap2Click "$APP_DIR/Contents/MacOS/Imouse Clicker"
cp Sources/ImouTap2Click/Resources/mouse.png "$APP_DIR/Contents/Resources/mouse.png"
cp Sources/ImouTap2Click/Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Imouse Clicker</string>
<key>CFBundleDisplayName</key><string>Imouse Clicker</string>
<key>CFBundleExecutable</key><string>Imouse Clicker</string>
<key>CFBundleIdentifier</key><string>com.imou.imouse-clicker</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSUIElement</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIconFiles</key><array><string>AppIcon</string></array>
</dict></plist>
PLIST
codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
