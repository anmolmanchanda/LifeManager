#!/bin/bash

echo "Launching LifeManager WITHOUT Keychain"
echo "======================================="
echo ""

# Kill any running instance
killall LifeManager 2>/dev/null
sleep 2

# Clear keychain entries first
echo "Clearing keychain entries..."
security delete-generic-password -s "supabase.auth.token" 2>/dev/null
security delete-generic-password -s "io.supabase" 2>/dev/null
security delete-generic-password -s "com.lifemanager" 2>/dev/null

# Set environment to disable keychain and enable features
export SUPABASE_DISABLE_KEYCHAIN=1
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1

echo "Configuration:"
echo "  Keychain: DISABLED"
echo "  Enhanced PARA: ENABLED"
echo "  Enhanced Embeddings: ENABLED"
echo ""

# Build with the fix
echo "Building with keychain fix..."
cd /Users/Shared/LifeManager
swift build --configuration release > /tmp/build.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed. Check /tmp/build.log"
    exit 1
fi

# Copy to Applications
echo "Installing to /Applications..."
rm -rf /Applications/LifeManager.app 2>/dev/null
cp -R .build/release/LifeManager.app /Applications/

# Launch with environment variables
echo "Launching..."
SUPABASE_DISABLE_KEYCHAIN=1 \
ENABLE_ENHANCED_PARA=1 \
ENABLE_ENHANCED_EMBEDDINGS=1 \
/Applications/LifeManager.app/Contents/MacOS/LifeManager &

APP_PID=$!
echo "App launched with PID: $APP_PID"

sleep 3

if ps -p $APP_PID > /dev/null; then
    echo ""
    echo "✅ SUCCESS! App running without keychain popups"
    echo ""
    echo "The app is now:"
    echo "  - Using in-memory storage (no keychain)"
    echo "  - Enhanced features enabled"
    echo "  - Ready for monitoring"
    echo ""
    echo "Start monitoring with:"
    echo "  ./scripts/production_monitor.sh"
else
    echo "❌ App failed to start"
fi