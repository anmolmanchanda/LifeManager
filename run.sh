#!/bin/bash

# Development run script for LifeManager
# Builds and launches the app bundle with URL scheme support

set -e

echo "🚀 Running LifeManager..."

# Build the app bundle
./build_app.sh

echo ""
echo "🔧 Launching app..."

# Launch the app
echo "Opening LifeManager.app..."
open LifeManager.app

echo ""
echo "🧪 Testing URL scheme registration..."
echo "Waiting 3 seconds for app to fully launch..."
sleep 3

# Test URL scheme
echo "Testing: lifemanager://auth/callback?code=test123"
open "lifemanager://auth/callback?code=test123"

echo ""
echo "✅ App launched and URL scheme tested!"
echo ""
echo "📧 For magic link testing:"
echo "1. Request magic link in app"
echo "2. Check email and click magic link"
echo "3. Should redirect to app automatically"
echo ""
echo "🐛 Debug logs: Check Console.app for '🔗 URL HANDLER:' messages"
echo "🔧 Manual test: open 'lifemanager://auth/callback?code=YOUR_CODE'" 