#!/bin/bash

# LifeManager - Build, Install and Run Script
echo "🚀 LifeManager - Building and Installing to Applications..."

# Run the build and install script
./build_and_install.sh

if [ $? -eq 0 ]; then
    echo "🎯 Launching LifeManager from Applications..."
    open "/Applications/LifeManager.app"
else
    echo "❌ Failed to build and install LifeManager"
    exit 1
fi 