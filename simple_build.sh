#\!/bin/bash

echo "🔨 Simple LifeManager Build"

# Clean everything first
rm -rf .build
swift package clean

# Simple build command
swift build --configuration release

if [ $? -eq 0 ]; then
    echo "✅ Build successful\!"
    echo "🚀 Running the app..."
    ./.build/release/LifeManager
else
    echo "❌ Build failed\!"
    exit 1
fi
EOF < /dev/null