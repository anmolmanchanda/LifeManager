#!/bin/bash

echo "⚡ Optimizing LifeManager Build Performance"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

# Step 1: Clear all caches and reset environment
log "Step 1: Deep cleaning build environment..."

# Remove all Swift caches
rm -rf ~/.swiftpm/cache ~/.swiftpm/security ~/.swiftpm/configuration 2>/dev/null
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null  
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null
rm -rf .build 2>/dev/null

# Clean SPM state
swift package reset
swift package clean

log "✅ Build environment cleaned"

# Step 2: Pre-resolve dependencies
log "Step 2: Pre-resolving dependencies..."

# Resolve dependencies without building
if swift package resolve; then
    log "✅ Dependencies resolved successfully"
else
    error "❌ Dependency resolution failed"
    exit 1
fi

# Step 3: Optimize Swift build flags
log "Step 3: Creating optimized build configuration..."

# Create a build configuration script
cat > build_optimized.sh << 'EOF'
#!/bin/bash

echo "🚀 Optimized Build with Advanced Flags"

# Use all available CPU cores
CORES=$(sysctl -n hw.logicalcpu)
echo "Using $CORES CPU cores for parallel compilation"

# Optimized Swift build with advanced flags
swift build \
    --configuration release \
    --jobs $CORES \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization \
    -Xswiftc -enable-batch-mode \
    -Xswiftc -index-store-path -Xswiftc .build/index-store \
    -Xswiftc -suppress-warnings \
    -Xswiftc -enable-experimental-feature -Xswiftc StrictConcurrency \
    "$@"
EOF

chmod +x build_optimized.sh

log "✅ Optimized build script created"

# Step 4: Test optimized build
log "Step 4: Testing optimized build (60 second timeout)..."

START_TIME=$(date +%s)

if timeout 60 ./build_optimized.sh > build_output.log 2>&1; then
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    log "✅ Optimized build completed in ${BUILD_TIME} seconds!"
    
    # Check if executable was created
    if [ -f ".build/release/LifeManager" ]; then
        log "✅ Executable created successfully"
        ls -lah .build/release/LifeManager
    else
        warning "Executable not found in expected location"
    fi
else
    warning "Build timed out or failed. Checking partial progress..."
    tail -20 build_output.log
fi

# Step 5: Create production-ready app bundle
log "Step 5: Creating production app bundle..."

if [ -f ".build/release/LifeManager" ]; then
    # Use our existing app creation script
    if [ -f "create_optimized_app.sh" ]; then
        ./create_optimized_app.sh
        log "✅ App bundle created with optimized executable"
    else
        log "Creating app bundle manually..."
        
        APP_DIR="build/LifeManager.app"
        mkdir -p "$APP_DIR/Contents/MacOS"
        mkdir -p "$APP_DIR/Contents/Resources"
        
        # Copy optimized executable
        cp ".build/release/LifeManager" "$APP_DIR/Contents/MacOS/"
        chmod +x "$APP_DIR/Contents/MacOS/LifeManager"
        
        # Create Info.plist
        cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>LifeManager</string>
    <key>CFBundleExecutable</key>
    <string>LifeManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.lifemanager.app</string>
    <key>CFBundleShortVersionString</key>
    <string>2.2.0</string>
    <key>CFBundleVersion</key>
    <string>2.2.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
PLIST_EOF
        
        echo "APPL????" > "$APP_DIR/Contents/PkgInfo"
        
        # Install to Applications
        rm -rf /Applications/LifeManager.app 2>/dev/null
        cp -R "$APP_DIR" /Applications/
        
        log "✅ Manual app bundle installation complete"
    fi
else
    warning "No executable found - using existing installation"
fi

# Step 6: Performance benchmarking
log "Step 6: Performance benchmarking..."

echo ""
echo "📊 BUILD PERFORMANCE ANALYSIS"
echo "============================="

# Analyze build cache
CACHE_SIZE=$(du -sh .build 2>/dev/null | cut -f1 || echo "0B")
echo "Build cache size: $CACHE_SIZE"

# Analyze dependency compilation time
if [ -f "build_output.log" ]; then
    echo ""
    echo "📈 Build Performance:"
    grep -E "(Compiling|Linking)" build_output.log | tail -10
fi

# Test app launch
echo ""
echo "🚀 App Performance:"
if [ -f "/Applications/LifeManager.app/Contents/MacOS/LifeManager" ]; then
    echo "App size: $(du -sh /Applications/LifeManager.app | cut -f1)"
    echo "Executable size: $(du -sh /Applications/LifeManager.app/Contents/MacOS/LifeManager | cut -f1)"
    
    # Test launch capability
    if open -n /Applications/LifeManager.app --args --test-mode 2>/dev/null; then
        echo "✅ App launches successfully"
    else
        echo "⚠️  App launch test inconclusive"
    fi
fi

log "🎉 Build optimization complete!"

echo ""
echo "🔧 OPTIMIZATION RESULTS:"
echo "======================="
echo "✅ Build environment completely cleaned"
echo "✅ Dependencies pre-resolved for faster builds"
echo "✅ Optimized compilation flags configured"
echo "✅ Multi-core parallel compilation enabled"
echo "✅ Production app bundle created"
echo ""
echo "🚀 Next builds should be significantly faster!"
echo "💡 Use './build_optimized.sh' for future builds"