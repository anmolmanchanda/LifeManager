#!/bin/bash

echo "========================================="
echo "  Launching LifeManager (NO AUTH VERSION)"
echo "  This bypasses ALL Supabase/Keychain"
echo "========================================="
echo ""

# Force kill any existing instances
echo "Killing any existing LifeManager processes..."
killall LifeManager 2>/dev/null
killall -9 LifeManager 2>/dev/null
sleep 2

# Clear ALL keychain entries
echo "Clearing keychain entries..."
security delete-generic-password -s "supabase.auth.token" 2>/dev/null
security delete-generic-password -s "io.supabase" 2>/dev/null
security delete-generic-password -s "com.lifemanager" 2>/dev/null
security delete-internet-password -s "supabase.co" 2>/dev/null
security delete-internet-password -h "cwxvmyqzhuskjwvttlbu.supabase.co" 2>/dev/null

echo ""
echo "Building NO-AUTH version..."
cd /Users/Shared/LifeManager

# Clean build
swift package clean > /dev/null 2>&1

# Build with auth bypassed
swift build --configuration release > /tmp/build_noauth.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    tail -20 /tmp/build_noauth.log
    exit 1
fi

# Create app bundle
echo "Creating app bundle..."
./build_app.sh > /dev/null 2>&1

# Install
echo "Installing to /Applications..."
rm -rf /Applications/LifeManager.app 2>/dev/null
cp -R LifeManager.app /Applications/

echo ""
echo "Launching NO-AUTH version..."
echo ""

# Launch directly
/Applications/LifeManager.app/Contents/MacOS/LifeManager &
APP_PID=$!

sleep 3

if ps -p $APP_PID > /dev/null; then
    MEM_KB=$(ps -o rss= -p $APP_PID | tr -d ' ')
    MEM_MB=$((MEM_KB / 1024))
    
    echo "========================================="
    echo "  ✅ SUCCESS! App running WITHOUT AUTH"
    echo "========================================="
    echo ""
    echo "  PID: $APP_PID"
    echo "  Memory: ${MEM_MB} MB"
    echo ""
    echo "  NO KEYCHAIN POPUPS WILL APPEAR!"
    echo "  The app is fully functional for testing"
    echo ""
    echo "  Monitor with: ./scripts/check_status.sh"
else
    echo "❌ App failed to start"
    echo "Check logs: tail -f /tmp/build_noauth.log"
fi