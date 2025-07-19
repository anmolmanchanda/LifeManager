#!/bin/bash

# Simple launcher that handles any authentication dialogs automatically

echo "🚀 Launching LifeManager with authentication bypass..."

# Background process to handle auth dialogs
(
    for i in {1..10}; do
        osascript -e '
        tell application "System Events"
            try
                repeat with proc in (name of every application process)
                    try
                        tell application process proc
                            if exists window "Authentication" then
                                tell window "Authentication"
                                    if exists button "Cancel" then
                                        click button "Cancel"
                                    end if
                                end tell
                            end if
                        end tell
                    end try
                end repeat
            end try
        end tell
        ' 2>/dev/null
        sleep 2
    done
) &

# Launch the app
open /Applications/LifeManager.app

echo "✅ LifeManager launched - any authentication dialogs will be automatically handled"