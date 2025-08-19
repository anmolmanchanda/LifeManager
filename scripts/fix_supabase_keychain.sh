#!/bin/bash

echo "Fixing Supabase Keychain Issues"
echo "================================"
echo ""

# Kill the app first
echo "Stopping LifeManager..."
killall LifeManager 2>/dev/null
sleep 2

# Clear problematic keychain entries
echo "Clearing Supabase keychain entries..."
security delete-generic-password -s "supabase.auth.token" 2>/dev/null
security delete-generic-password -s "io.supabase" 2>/dev/null
security delete-generic-password -s "com.lifemanager" 2>/dev/null
security delete-internet-password -s "supabase.co" 2>/dev/null

echo "Keychain entries cleared"
echo ""

# Reset app preferences
echo "Resetting app preferences..."
defaults delete com.lifemanager.app 2>/dev/null
defaults delete LifeManager 2>/dev/null

echo ""
echo "Fix applied!"
echo ""
echo "To prevent this issue:"
echo "1. Use development mode authentication"
echo "2. Or disable Supabase keychain storage"
echo ""
echo "Restart the app with development mode:"
echo "  ./run_dev_mode.sh"