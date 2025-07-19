#!/bin/bash

echo "🚀 Clean Build LifeManager v2.2.0 with Database Fixes"
echo "===================================================="

# Kill any existing processes
pkill -f LifeManager || true
sleep 2

# Clean all caches
echo "🧹 Cleaning build cache..."
swift package clean
rm -rf .build/
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/DerivedData/LifeManager-*

# Resolve dependencies once
echo "📦 Resolving dependencies..."
swift package resolve

# Build with optimizations
echo "🔨 Building optimized release..."
if swift build --configuration release -Xswiftc -O -Xswiftc -whole-module-optimization -j 12; then
    echo "✅ Build completed successfully"
    
    # Create app bundle
    echo "📱 Creating app bundle..."
    if [ -f ".build/release/LifeManager" ]; then
        # Update the executable in existing app bundle
        if [ -d "/Applications/LifeManager.app" ]; then
            cp ".build/release/LifeManager" "/Applications/LifeManager.app/Contents/MacOS/LifeManager"
            chmod +x "/Applications/LifeManager.app/Contents/MacOS/LifeManager"
            echo "✅ Updated app executable"
        else
            echo "❌ App bundle not found in /Applications/"
            exit 1
        fi
        
        # Launch the app
        echo "🚀 Launching LifeManager..."
        open /Applications/LifeManager.app
        
        echo "🎉 Success! LifeManager v2.2.0 is now running with:"
        echo "  ✅ Single-user database architecture (no user_id errors)"
        echo "  ✅ Enhanced Focus View in sidebar"
        echo "  ✅ Intelligent Timeline View in sidebar"
        echo "  ✅ Automation Dashboard in sidebar"
        echo ""
        echo "🔍 Monitor logs with:"
        echo "  tail -f ~/Documents/LifeManager/Logs/lifemanager-*.log"
        
    else
        echo "❌ Build executable not found"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi