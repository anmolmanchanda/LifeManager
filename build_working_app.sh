#!/bin/bash

echo "🚀 Building LifeManager App Bundle"
echo "=================================="

# 1. Build the executable in release mode
echo "🔨 Building executable..."
swift build -c release --product LifeManager

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# 2. Find the built executable
echo "🔍 Looking for executable..."
EXECUTABLE_PATH=""

# Try multiple possible locations
if [ -f ".build/release/LifeManager" ]; then
    EXECUTABLE_PATH=".build/release/LifeManager"
elif [ -f ".build/arm64-apple-macosx/release/LifeManager" ]; then
    EXECUTABLE_PATH=".build/arm64-apple-macosx/release/LifeManager"
else
    # Search for it
    FOUND_PATH=$(find .build -name "LifeManager" -type f -perm +111 | grep -v ".dSYM" | grep -v ".build/checkouts" | head -1)
    if [ -n "$FOUND_PATH" ]; then
        EXECUTABLE_PATH="$FOUND_PATH"
    fi
fi

if [ -z "$EXECUTABLE_PATH" ] || [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "❌ Could not find executable!"
    echo "Let's see what was built:"
    find .build -name "*LifeManager*" -type f
    exit 1
fi

echo "✅ Found executable at: $EXECUTABLE_PATH"

# 3. Create app bundle
APP_NAME="LifeManager.app"
APP_PATH="/Applications/$APP_NAME"

echo "📦 Creating app bundle..."

# Remove existing app if it exists
if [ -d "$APP_PATH" ]; then
    echo "🗑️  Removing existing app..."
    rm -rf "$APP_PATH"
fi

# Create app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
cp "$EXECUTABLE_PATH" "$APP_PATH/Contents/MacOS/LifeManager"
chmod +x "$APP_PATH/Contents/MacOS/LifeManager"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
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
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
EOF

echo "✅ App bundle created at: $APP_PATH"

# 4. Test run the app directly first
echo ""
echo "🧪 Testing executable directly..."
echo "Running: $EXECUTABLE_PATH"
echo "(Press Ctrl+C to stop)"
echo ""

# Run the executable
"$EXECUTABLE_PATH"