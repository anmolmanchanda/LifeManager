#!/bin/bash

echo "Launching LifeManager with Enhanced Features"
echo "==========================================="
echo ""

# Kill existing instance
echo "Stopping existing LifeManager..."
killall LifeManager 2>/dev/null
sleep 2

# Set environment variables
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1

echo "Environment configured:"
echo "  ENABLE_ENHANCED_PARA=1"
echo "  ENABLE_ENHANCED_EMBEDDINGS=1"
echo ""

# Launch directly from command line to preserve environment
echo "Launching enhanced LifeManager..."
/Applications/LifeManager.app/Contents/MacOS/LifeManager &
APP_PID=$!

echo "LifeManager launched with PID: $APP_PID"
echo ""

# Wait a moment for app to initialize
sleep 3

# Verify it's running
if ps -p $APP_PID > /dev/null; then
    MEM_KB=$(ps -o rss= -p $APP_PID | tr -d ' ')
    MEM_MB=$((MEM_KB / 1024))
    echo "✅ App running successfully"
    echo "   PID: $APP_PID"
    echo "   Memory: ${MEM_MB} MB"
    echo ""
    echo "Enhanced features are active!"
    echo ""
    echo "To monitor:"
    echo "  ./scripts/monitor_realtime.sh"
    echo ""
    echo "To check status:"
    echo "  ./scripts/check_status.sh"
else
    echo "❌ App failed to start"
    echo "Check logs for errors"
fi