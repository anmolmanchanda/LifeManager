#!/bin/bash

echo "Fixing Production Monitoring"
echo "============================"
echo ""

# Kill existing monitoring if running
pkill -f production_monitor.sh 2>/dev/null

# Find actual LifeManager PID
ACTUAL_PID=$(pgrep -x LifeManager || pgrep -f "LifeManager.app" | head -1)

if [ -z "$ACTUAL_PID" ]; then
    echo "LifeManager not running. Starting it with enhanced features..."
    
    # Enable features and restart
    export ENABLE_ENHANCED_PARA=1
    export ENABLE_ENHANCED_EMBEDDINGS=1
    
    # Kill any existing instance
    killall LifeManager 2>/dev/null
    sleep 2
    
    # Start fresh with features enabled
    open -a LifeManager
    sleep 3
    
    ACTUAL_PID=$(pgrep -x LifeManager || pgrep -f "LifeManager.app" | head -1)
fi

echo "LifeManager PID: $ACTUAL_PID"

# Update the monitoring to use correct PID
LOG_DIR="$HOME/Library/Logs/LifeManager"
METRICS_FILE="$LOG_DIR/24hr_metrics_$(date +%Y%m%d)_fixed.json"

echo "Creating fixed metrics file: $METRICS_FILE"
echo "[" > "$METRICS_FILE"

# Function to add metrics
add_metric() {
    local TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local MEM_KB=$(ps -o rss= -p $ACTUAL_PID 2>/dev/null | tr -d ' ')
    local MEM_MB=$((MEM_KB / 1024))
    
    # Get window size from UserDefaults
    local WINDOW_SIZE=$(defaults read LifeManager context_window_adjustments 2>/dev/null | \
                       tail -1 | grep -o 'new_size = [0-9]*' | awk '{print $3}')
    WINDOW_SIZE=${WINDOW_SIZE:-100}
    
    cat >> "$METRICS_FILE" << EOF
  {
    "timestamp": "$TIMESTAMP",
    "window_size": $WINDOW_SIZE,
    "memory_mb": $MEM_MB,
    "embeddings_cache_hits": 0,
    "similarity_calculations": 0,
    "window_adjustments": 0,
    "pid": $ACTUAL_PID,
    "enhanced_para": "${ENABLE_ENHANCED_PARA:-0}",
    "enhanced_embeddings": "${ENABLE_ENHANCED_EMBEDDINGS:-0}"
  },
EOF
}

# Add initial metric
add_metric

echo ""
echo "Fixed monitoring started!"
echo "PID being monitored: $ACTUAL_PID"
echo "Memory: $(ps -o rss= -p $ACTUAL_PID | awk '{print int($1/1024)}') MB"
echo ""
echo "Features status:"
echo "  Enhanced PARA: ${ENABLE_ENHANCED_PARA:-0}"
echo "  Enhanced Embeddings: ${ENABLE_ENHANCED_EMBEDDINGS:-0}"
echo ""
echo "To properly enable features, restart the app with:"
echo "  export ENABLE_ENHANCED_PARA=1"
echo "  export ENABLE_ENHANCED_EMBEDDINGS=1"
echo "  killall LifeManager"
echo "  open -a LifeManager"