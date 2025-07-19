#!/bin/bash

echo "🚀 Quick Update LifeManager with Database Fixes"
echo "============================================="

# Kill any running swift processes
pkill -f swift || true
pkill -f LifeManager || true

# Quick build
echo "Building with fixes..."
if swift build --configuration release -Xswiftc -suppress-warnings; then
    echo "✅ Build completed successfully"
    
    # Check if executable exists
    if [ -f ".build/release/LifeManager" ]; then
        # Update the app bundle executable
        echo "Updating app bundle..."
        cp ".build/release/LifeManager" "/Applications/LifeManager.app/Contents/MacOS/LifeManager"
        chmod +x "/Applications/LifeManager.app/Contents/MacOS/LifeManager"
        
        echo "✅ App updated successfully"
        
        # Launch the updated app
        echo "Launching updated LifeManager..."
        open /Applications/LifeManager.app
        
        echo "🎉 Complete! Updated app is now running with database fixes."
        echo ""
        echo "📝 Changes applied:"
        echo "  ✅ Removed user_id database queries (single-user app)"
        echo "  ✅ Added Enhanced Focus View to navigation"
        echo "  ✅ Added Intelligent Timeline View to navigation"
        echo "  ✅ Added Automation Dashboard to navigation"
        echo ""
        echo "🔍 Check logs for verification:"
        echo "  tail -f ~/Documents/LifeManager/Logs/lifemanager-*.log"
        
    else
        echo "❌ Build executable not found"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi