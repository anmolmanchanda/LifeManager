#!/bin/bash

echo "Launching LifeManager in Development Mode"
echo "========================================="
echo ""

# Kill existing instance
killall LifeManager 2>/dev/null
sleep 2

# Set development mode to bypass authentication
export LIFEMANAGER_DEV_MODE=1
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1
export SUPABASE_DISABLE_KEYCHAIN=1

echo "Configuration:"
echo "  Development Mode: ENABLED"
echo "  Enhanced PARA: ENABLED"
echo "  Enhanced Embeddings: ENABLED"
echo "  Keychain Storage: DISABLED"
echo ""

# Launch with development bypass
echo "Launching..."
/Applications/LifeManager.app/Contents/MacOS/LifeManager --dev-mode &
APP_PID=$!

sleep 3

if ps -p $APP_PID > /dev/null; then
    echo "✅ App running in dev mode (PID: $APP_PID)"
    echo ""
    echo "This bypasses Supabase authentication issues"
    echo "No keychain popups should appear"
else
    echo "❌ Failed to start"
fi