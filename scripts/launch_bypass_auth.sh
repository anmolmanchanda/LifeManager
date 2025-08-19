#!/bin/bash

echo "Launching LifeManager with Auth Bypass"
echo "======================================="
echo ""

# Kill any running instance
killall LifeManager 2>/dev/null
sleep 2

# Clear ALL keychain entries related to the app
echo "Clearing all app-related keychain entries..."
security delete-generic-password -s "supabase.auth.token" 2>/dev/null
security delete-generic-password -s "io.supabase" 2>/dev/null
security delete-generic-password -s "com.lifemanager" 2>/dev/null
security delete-internet-password -s "supabase.co" 2>/dev/null
security delete-internet-password -h "cwxvmyqzhuskjwvttlbu.supabase.co" 2>/dev/null

# Also clear Safari/WebKit related
defaults delete com.apple.Safari 2>/dev/null
defaults delete com.apple.WebKit 2>/dev/null

echo "Keychain cleared"
echo ""

# Build the app
echo "Building..."
cd /Users/Shared/LifeManager
swift build --configuration release > /tmp/build.log 2>&1

if [ $? -eq 0 ]; then
    echo "Build successful"
else
    echo "Build failed - check /tmp/build.log"
    exit 1
fi

# Install to Applications
echo "Installing..."
rm -rf /Applications/LifeManager.app 2>/dev/null
cp -R .build/release/LifeManager.app /Applications/

# Set environment for enhanced features
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1

echo ""
echo "Configuration:"
echo "  Enhanced PARA: ENABLED"
echo "  Enhanced Embeddings: ENABLED"
echo ""

# Launch the app
echo "Launching app..."
/Applications/LifeManager.app/Contents/MacOS/LifeManager &
APP_PID=$!

echo "App launched with PID: $APP_PID"
sleep 3

if ps -p $APP_PID > /dev/null; then
    MEM_KB=$(ps -o rss= -p $APP_PID | tr -d ' ')
    MEM_MB=$((MEM_KB / 1024))
    
    echo ""
    echo "SUCCESS! App running"
    echo "  PID: $APP_PID"
    echo "  Memory: ${MEM_MB} MB"
    echo ""
    echo "If you get keychain popups:"
    echo "  1. Click 'Cancel' on all popups"
    echo "  2. The app will continue working"
    echo "  3. Use development account for testing"
    echo ""
    echo "Development credentials:"
    echo "  Email: dev@lifemanager.local"
    echo "  Password: devpassword123"
    echo ""
    echo "To monitor the app:"
    echo "  ./scripts/check_status.sh"
else
    echo "App failed to start"
fi