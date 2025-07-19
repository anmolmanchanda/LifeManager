#!/bin/bash

echo "🚀 Starting LifeManager with automatic authentication handling..."

# Function to handle authentication dialogs
handle_auth_dialog() {
    osascript <<EOF
tell application "System Events"
    try
        repeat 30 times
            -- Check for authentication dialog
            if exists window "Authentication" of application process "CoreServicesUIAgent" then
                tell window "Authentication" of application process "CoreServicesUIAgent"
                    log "🔧 Found authentication dialog"
                    
                    -- Try to click Cancel to dismiss
                    if exists button "Cancel" then
                        click button "Cancel"
                        log "🔧 Dismissed authentication dialog"
                        exit repeat
                    end if
                    
                    -- Alternative: Try to find "Don't Allow" or similar
                    if exists button "Don't Allow" then
                        click button "Don't Allow"
                        log "🔧 Clicked Don't Allow"
                        exit repeat
                    end if
                end tell
            end if
            
            -- Check for keychain access dialogs
            repeat with proc in (name of every application process)
                try
                    tell application process proc
                        if exists window "Keychain Access" then
                            tell window "Keychain Access"
                                if exists button "Deny" then
                                    click button "Deny"
                                    log "🔧 Denied keychain access for " & proc
                                end if
                                if exists button "Cancel" then
                                    click button "Cancel"
                                    log "🔧 Cancelled keychain access for " & proc
                                end if
                            end tell
                        end if
                    end tell
                end try
            end repeat
            
            delay 1
        end repeat
    on error
        -- Ignore errors and continue
    end try
end tell
EOF
}

# Start the authentication dialog handler in background
handle_auth_dialog &
AUTH_HANDLER_PID=$!

echo "🔧 Started authentication dialog handler (PID: $AUTH_HANDLER_PID)"

# Launch the app
echo "🚀 Launching LifeManager..."
open /Applications/LifeManager.app

# Wait a moment for the app to start
sleep 3

echo "✅ LifeManager launched with authentication handling active"
echo "🔧 Authentication dialog handler will run for 30 seconds"
echo "🔧 If you see any password dialogs, they should be automatically dismissed"

# Wait for the auth handler to complete
wait $AUTH_HANDLER_PID

echo "🔧 Authentication dialog handler finished"