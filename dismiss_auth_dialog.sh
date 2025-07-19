#!/bin/bash

# Script to automatically dismiss macOS authentication dialogs
# This script uses AppleScript to handle system authentication prompts

echo "🔧 Starting auth dialog monitor..."

# Function to dismiss authentication dialogs
dismiss_auth_dialog() {
    osascript <<EOF
tell application "System Events"
    try
        -- Look for authentication dialog
        if exists window "Authentication" of application process "CoreServicesUIAgent" then
            tell window "Authentication" of application process "CoreServicesUIAgent"
                -- Try to click Cancel button
                if exists button "Cancel" then
                    click button "Cancel"
                    log "🔧 Clicked Cancel on authentication dialog"
                end if
            end tell
        end if
        
        -- Look for other potential auth dialogs
        repeat with theApp in (name of every application process)
            try
                tell application process theApp
                    if exists window "Authentication" then
                        tell window "Authentication"
                            if exists button "Cancel" then
                                click button "Cancel"
                                log "🔧 Dismissed auth dialog for " & theApp
                            end if
                        end tell
                    end if
                end tell
            end try
        end repeat
    on error
        -- Ignore errors and continue
    end try
end tell
EOF
}

# Function to auto-fill with user password (if available)
auto_fill_password() {
    # Get current user
    CURRENT_USER=$(whoami)
    
    osascript <<EOF
tell application "System Events"
    try
        -- Look for authentication dialog
        if exists window "Authentication" of application process "CoreServicesUIAgent" then
            tell window "Authentication" of application process "CoreServicesUIAgent"
                -- Check if password field exists
                if exists text field 2 then
                    -- Focus on password field and attempt auto-fill
                    set focused of text field 2 to true
                    -- Note: We cannot actually retrieve the user's password
                    -- This would require the user to provide it
                    log "🔧 Found password field but cannot auto-fill for security reasons"
                    
                    -- Alternative: Click Cancel instead
                    if exists button "Cancel" then
                        click button "Cancel"
                        log "🔧 Clicked Cancel instead of attempting to fill password"
                    end if
                end if
            end tell
        end if
    on error
        -- Ignore errors
    end try
end tell
EOF
}

# Monitor for authentication dialogs every 2 seconds
while true; do
    # First try to dismiss any existing dialogs
    dismiss_auth_dialog
    
    # Sleep for 2 seconds before checking again
    sleep 2
done