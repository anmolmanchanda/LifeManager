#!/bin/bash

# Build and Install LifeManager App to Applications
echo "🔨 Building LifeManager..."

# Clean previous build
swift package clean
rm -rf .build

# Build the app
swift build --configuration release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Create app bundle structure
    APP_NAME="LifeManager.app"
    APP_PATH="/Applications/$APP_NAME"
    
    # Remove existing app if it exists
    if [ -d "$APP_PATH" ]; then
        echo "🗑️  Removing existing app..."
        rm -rf "$APP_PATH"
    fi
    
    # Create app bundle
    echo "📦 Creating app bundle..."
    mkdir -p "$APP_PATH/Contents/MacOS"
    mkdir -p "$APP_PATH/Contents/Resources"
    
    # Copy binary
    cp .build/release/LifeManager "$APP_PATH/Contents/MacOS/"
    
    # Create Info.plist
    cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>LifeManager</string>
    <key>CFBundleExecutable</key>
    <string>LifeManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.lifemanager.app</string>
    <key>CFBundleName</key>
    <string>LifeManager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF
    
    echo "✅ App installed to /Applications/LifeManager.app"
    echo "🚀 You can now launch LifeManager from Launchpad or Applications folder"
    
    # Refresh Launchpad database
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_PATH"
    
else
    echo "❌ Build failed!"
    exit 1
fi 