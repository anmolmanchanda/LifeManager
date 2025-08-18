#!/bin/bash

# Modern macOS App Builder for LifeManager SwiftUI App
# Uses xcodebuild to create proper .app bundle with all fixes included

set -e

echo "🚀 Building LifeManager macOS App (Fixed Version)"

# Clean any previous builds
echo "🧹 Cleaning previous builds..."
rm -rf /Applications/LifeManager.app
rm -rf LifeManager.app
rm -rf DerivedData
rm -rf .build

# Build using xcodebuild with proper configuration
echo "📦 Building with xcodebuild..."
xcodebuild \
    -scheme LifeManager \
    -configuration Release \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath ./DerivedData \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Look for the built app bundle
echo "📁 Locating built app bundle..."
APP_BUNDLE_PATH=""

# Check multiple possible locations
SEARCH_PATHS=(
    "./DerivedData/Build/Products/Release/LifeManager.app"
    "./DerivedData/Build/Products/Release-macosx/LifeManager.app"
    "./build/Release/LifeManager.app"
)

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        APP_BUNDLE_PATH="$path"
        echo "✅ Found app bundle at: $APP_BUNDLE_PATH"
        break
    fi
done

if [ -z "$APP_BUNDLE_PATH" ]; then
    echo "❌ Could not find LifeManager.app bundle"
    echo "Searching for any .app bundles..."
    find ./DerivedData -name "*.app" -type d 2>/dev/null | head -5
    exit 1
fi

# Copy to current directory
echo "📋 Copying app bundle to current directory..."
cp -r "$APP_BUNDLE_PATH" ./LifeManager.app

# Verify the executable exists and is current
EXECUTABLE_PATH="./LifeManager.app/Contents/MacOS/LifeManager"
if [ -f "$EXECUTABLE_PATH" ]; then
    echo "✅ Executable found: $EXECUTABLE_PATH"
    echo "📅 Executable timestamp: $(stat -f "%Sm" "$EXECUTABLE_PATH")"
    echo "🔍 Executable size: $(stat -f "%z bytes" "$EXECUTABLE_PATH")"
else
    echo "❌ Executable not found at expected location"
    find ./LifeManager.app -type f -executable 2>/dev/null
    exit 1
fi

# Install to Applications
echo "📲 Installing to /Applications..."
cp -r ./LifeManager.app /Applications/

# Verify installation
if [ -f "/Applications/LifeManager.app/Contents/MacOS/LifeManager" ]; then
    echo "✅ Successfully installed LifeManager.app"
    echo "📅 Installed executable timestamp: $(stat -f "%Sm" "/Applications/LifeManager.app/Contents/MacOS/LifeManager")"
    echo ""
    echo "🎉 Build and installation complete!"
    echo "   Your latest changes are now in the installed app."
    echo ""
    echo "🔧 To verify your fixes are included:"
    echo "   1. Open LifeManager.app"
    echo "   2. Check brain dump review UI (should be wider)"
    echo "   3. Check time entry colors (should be blue from start)"
    echo "   4. Check thinking animation (should be faster)"
    echo "   5. Check clear all button (should delete resources too)"
else
    echo "❌ Installation failed"
    exit 1
fi