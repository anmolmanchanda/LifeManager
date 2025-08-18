#!/bin/bash

# Build script for LifeManager macOS App Bundle
# This creates a proper .app bundle with URL scheme registration

set -e

echo "🚀 Building LifeManager macOS App..."

# Build the Swift Package
echo "📦 Building Swift Package..."
swift build -c release

# Create app bundle structure
APP_NAME="LifeManager"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📁 Creating app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
echo "🔧 Copying executable..."
cp ".build/release/LifeManager" "${MACOS_DIR}/"

# Create Info.plist with URL scheme registration
echo "📝 Creating Info.plist with URL scheme registration..."
cat > "${CONTENTS_DIR}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>LifeManager</string>
    <key>CFBundleDisplayName</key>
    <string>LifeManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.anmolmanchanda.lifemanager</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>LifeManager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>lifemanager</string>
            </array>
            <key>CFBundleURLName</key>
            <string>com.anmolmanchanda.lifemanager</string>
            <key>CFBundleURLIconFile</key>
            <string></string>
        </dict>
    </array>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Anmol Manchanda. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSRequiresIPhoneOS</key>
    <false/>
</dict>
</plist>
EOF

# Make executable runnable
chmod +x "${MACOS_DIR}/LifeManager"

echo "✅ App bundle created successfully: ${APP_BUNDLE}"
echo ""
echo "🔧 To register URL schemes and test:"
echo "1. Run: open ${APP_BUNDLE}"
echo "2. When prompted, allow the app to run"
echo "3. Test URL scheme: open 'lifemanager://auth/callback?code=test'"
echo ""
echo "📧 For magic link testing:"
echo "1. Start the app"
echo "2. Request magic link in app"
echo "3. Click magic link from email"
echo "4. Should redirect to app automatically"
echo ""
echo "🐛 Debug: Check Console.app for URL handling logs with prefix '🔗 URL HANDLER:'" 