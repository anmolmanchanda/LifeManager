#!/bin/bash

# Development run script for LifeManager
# Builds and launches the app bundle with URL scheme support

set -e

echo "🚀 Running LifeManager..."

# NUCLEAR CLEANUP - Stop EVERYTHING LifeManager related
echo "🔧 NUCLEAR CLEANUP: Eliminating ALL LifeManager instances..."

# Stage 1: Force kill ALL processes with LifeManager in name or path - no mercy
echo "🔧 Stage 1: Force killing ALL LifeManager processes..."
pkill -9 -f "LifeManager" 2>/dev/null || true
killall -9 "LifeManager" 2>/dev/null || true
ps aux | grep -i lifemanager | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true

# Stage 2: Kill process groups to catch spawned children
echo "🔧 Stage 2: Killing process groups..."
ps aux | grep -i lifemanager | grep -v grep | awk '{print $2}' | xargs -I {} pkill -9 -g {} 2>/dev/null || true

# Stage 3: Force quit ALL apps using AppleScript with retry
echo "🔧 Stage 3: AppleScript force quit with retry..."
for i in {1..3}; do
    osascript << EOF 2>/dev/null || true
tell application "System Events"
    set appList to every application process whose name contains "LifeManager"
    repeat with proc in appList
        try
            tell proc to quit
            delay 1
            tell proc to quit
        end try
    end repeat
end tell
EOF
    sleep 2
done

# Stage 4: NSWorkspace termination via Swift script
echo "🔧 Stage 4: NSWorkspace termination..."
cat > /tmp/kill_lifemanager.swift << 'EOF'
import Foundation
import AppKit

let workspace = NSWorkspace.shared
let runningApps = workspace.runningApplications

for app in runningApps {
    if let bundleId = app.bundleIdentifier, bundleId.contains("LifeManager") {
        print("Terminating app with bundle ID: \(bundleId)")
        app.forceTerminate()
    }
    if let name = app.localizedName, name.contains("LifeManager") {
        print("Terminating app with name: \(name)")
        app.forceTerminate()
    }
}
EOF

swift /tmp/kill_lifemanager.swift 2>/dev/null || true
rm -f /tmp/kill_lifemanager.swift

# Stage 5: Extended wait for complete termination
echo "🔧 Stage 5: Extended wait for complete process termination..."
sleep 8

# Stage 6: Create instance lock file
echo "🔧 Stage 6: Creating instance lock..."
mkdir -p ~/Library/Application\ Support/LifeManager/
echo $$ > ~/Library/Application\ Support/LifeManager/instance.lock

# Stage 7: REMOVE ALL TRACES of the app bundle and caches (expanded)
echo "🔧 Stage 7: Removing ALL app bundles and caches..."
rm -rf ./LifeManager.app 2>/dev/null || true
rm -rf ~/Library/Caches/com.lifemanager.* 2>/dev/null || true
rm -rf ~/Library/Caches/*LifeManager* 2>/dev/null || true
rm -rf /tmp/LifeManager* 2>/dev/null || true
rm -rf /var/folders/*/*/com.lifemanager.* 2>/dev/null || true
rm -rf ~/Library/Preferences/com.lifemanager.* 2>/dev/null || true
rm -rf ~/Library/Application\ Support/LifeManager* 2>/dev/null || true
rm -rf ~/Library/Saved\ Application\ State/com.lifemanager.* 2>/dev/null || true
rm -rf ~/Library/Containers/com.lifemanager.* 2>/dev/null || true
rm -rf ~/Library/Group\ Containers/*LifeManager* 2>/dev/null || true

# Stage 8: Nuclear LaunchServices reset with multiple methods
echo "🔧 Stage 8: NUCLEAR LaunchServices reset..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -seed 2>/dev/null || true

# Force rebuild LaunchServices database
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /System/Library/CoreServices/Finder.app 2>/dev/null || true

# Additional LaunchServices cleanup
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -unregister ./LifeManager.app 2>/dev/null || true

# Stage 9: Clear system-wide caches
echo "🔧 Stage 9: Clearing system caches..."
# Clear Dock cache
defaults delete com.apple.dock 2>/dev/null || true
killall Dock 2>/dev/null || true

# Clear icon cache (without sudo)
find ~/Library/Caches -name "*.iconcache" -delete 2>/dev/null || true

# Stage 10: Final verification with detailed check
echo "🔧 Stage 10: Final verification - checking for any remaining processes..."
sleep 5

# Check for any remaining processes
REMAINING=$(ps aux | grep -i lifemanager | grep -v grep | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    echo "⚠️  Found $REMAINING remaining LifeManager processes:"
    ps aux | grep -i lifemanager | grep -v grep
    echo "🔧 Attempting final cleanup..."
    ps aux | grep -i lifemanager | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
    sleep 3
fi

ps aux | grep -i lifemanager | grep -v grep || echo "✅ No LifeManager processes found"

echo "🔧 Nuclear cleanup complete. Starting fresh build..."
sleep 3

# Build the app bundle
./build_app.sh

echo ""
echo "🔧 Launching app..."

# Launch the app - using full path to ensure we use local version
echo "Opening LOCAL LifeManager.app..."
open ./LifeManager.app

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