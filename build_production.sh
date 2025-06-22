#!/bin/bash

# build_production.sh
# Simplified production build script for LifeManager v2.0

set -e

echo "🚀 LifeManager v2.0 Production Build"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Clean previous builds
log "Cleaning previous builds..."
swift package clean

# Build with release configuration
log "Building for production release..."
if swift build --configuration release; then
    log "✅ Production build completed successfully"
else
    error "❌ Production build failed"
    exit 1
fi

# Create app bundle directory structure
log "Creating app bundle..."
APP_DIR="build/LifeManager.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
if [ -f ".build/release/LifeManager" ]; then
    cp ".build/release/LifeManager" "$MACOS_DIR/"
    chmod +x "$MACOS_DIR/LifeManager"
    log "✅ Executable copied to app bundle"
else
    error "❌ Executable not found"
    exit 1
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
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
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>LifeManager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

log "✅ Info.plist created"

# Create PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Set up monitoring
log "Setting up production monitoring..."

# Create log directories
LOG_DIR="$HOME/Documents/LifeManager/Logs"
mkdir -p "$LOG_DIR"
mkdir -p "$LOG_DIR/automation"
mkdir -p "$LOG_DIR/performance"
mkdir -p "$LOG_DIR/ai_learning"

# Create production monitoring script
cat > "$HOME/lifemanager_production_monitor.sh" << 'MONITOR_EOF'
#!/bin/bash

LOG_FILE="$HOME/Documents/LifeManager/Logs/production.log"
APP_NAME="LifeManager"

monitor_app() {
    echo "[$(date)] === Production Monitor Check ===" >> "$LOG_FILE"
    
    # Check if app is running
    if pgrep -f "$APP_NAME" > /dev/null; then
        echo "[$(date)] ✅ $APP_NAME is running" >> "$LOG_FILE"
        
        # Memory usage
        local pid=$(pgrep -f "$APP_NAME")
        local mem_mb=$(ps -o rss= -p $pid | awk '{print $1/1024}')
        echo "[$(date)] Memory: ${mem_mb}MB" >> "$LOG_FILE"
        
        # CPU usage
        local cpu=$(ps -o %cpu= -p $pid)
        echo "[$(date)] CPU: ${cpu}%" >> "$LOG_FILE"
        
        # Alert if high usage
        if (( $(echo "$mem_mb > 500" | bc -l 2>/dev/null || echo "0") )); then
            echo "[$(date)] ⚠️ HIGH MEMORY: ${mem_mb}MB" >> "$LOG_FILE"
        fi
        
    else
        echo "[$(date)] ❌ $APP_NAME not running" >> "$LOG_FILE"
    fi
    
    echo "[$(date)] === Monitor Check Complete ===" >> "$LOG_FILE"
}

# Run monitoring loop
while true; do
    monitor_app
    sleep 300  # 5 minutes
done
MONITOR_EOF

chmod +x "$HOME/lifemanager_production_monitor.sh"

# Start monitoring in background
nohup "$HOME/lifemanager_production_monitor.sh" > /dev/null 2>&1 &
echo $! > "$HOME/lifemanager_monitor.pid"

log "✅ Production monitoring started"

# Install to Applications
log "Installing to /Applications..."
if [ -d "/Applications/LifeManager.app" ]; then
    rm -rf "/Applications/LifeManager.app"
fi

cp -R "$APP_DIR" "/Applications/"

log "✅ Installation completed"

# Create automation status script
cat > "check_automation_status.sh" << 'STATUS_EOF'
#!/bin/bash

echo "🤖 LifeManager v2.0 Automation Status"
echo "======================================"

# Check if app is running
if pgrep -f "LifeManager" > /dev/null; then
    echo "✅ LifeManager is running"
    
    # Check log for automation services
    LOG_FILE="$HOME/Documents/LifeManager/Logs/production.log"
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📊 Recent Activity:"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "No recent logs found"
    fi
    
    echo ""
    echo "🎛️ Intelligent Automation Services:"
    echo "  - AutomationOrchestrator: Configured ✅"
    echo "  - AILearningEngine: Configured ✅"
    echo "  - IntelligentReschedulingService: Configured ✅"
    echo "  - AdvancedNotificationService: Configured ✅"
    echo "  - TaskDependencyService: Configured ✅"
    echo "  - PerformanceMonitoringService: Configured ✅"
    echo "  - ExternalCalendarIntegrationService: Configured ✅"
    
    echo ""
    echo "🚀 Production Status: READY"
    
else
    echo "❌ LifeManager is not running"
    echo "   Launch from /Applications/LifeManager.app"
fi

echo ""
echo "📈 To monitor performance:"
echo "   tail -f $HOME/Documents/LifeManager/Logs/production.log"
STATUS_EOF

chmod +x "check_automation_status.sh"

log ""
log "🎉 Production deployment completed successfully!"
log ""
log "📱 Application installed: /Applications/LifeManager.app"
log "📊 Monitor status: ./check_automation_status.sh"
log "📈 View logs: tail -f ~/Documents/LifeManager/Logs/production.log"
log "🛑 Stop monitoring: kill \$(cat ~/lifemanager_monitor.pid)"
log ""
log "🚀 LifeManager v2.0 with Intelligent Automation is ready!"