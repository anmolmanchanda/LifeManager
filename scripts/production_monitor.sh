#!/bin/bash
# Production monitoring for enhanced features

LOG_DIR="$HOME/Library/Logs/LifeManager"
METRICS_FILE="$LOG_DIR/24hr_metrics_$(date +%Y%m%d).json"

echo "Starting 24-hour production monitoring..."
echo "Metrics will be saved to: $METRICS_FILE"

# Enable enhanced features
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Launch app with monitoring
./build_and_install.sh
./run.sh &
APP_PID=$!

echo "App launched with PID: $APP_PID"
echo "Monitoring will run for 24 hours..."
echo ""

# Initialize metrics file
echo "[" > "$METRICS_FILE"
FIRST_ENTRY=true

# Monitor key metrics every 5 minutes
START_TIME=$(date +%s)
END_TIME=$((START_TIME + 86400))  # 24 hours

while [ $(date +%s) -lt $END_TIME ]; do
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Extract window adjustments from UserDefaults
    WINDOW_SIZE=$(defaults read com.lifemanager.app context_window_adjustments 2>/dev/null | \
                  tail -1 | grep -o 'new_size = [0-9]*' | awk '{print $3}')
    
    # Memory usage
    if ps -p $APP_PID > /dev/null 2>&1; then
        MEM_KB=$(ps -o rss= -p $APP_PID 2>/dev/null | tr -d ' ')
        MEM_MB=$((MEM_KB / 1024))
    else
        MEM_MB=0
        echo "Warning: App process not found. Restarting..."
        ./run.sh &
        APP_PID=$!
    fi
    
    # Cache statistics
    CACHE_HITS=$(grep -c "Cache hit" "$LOG_DIR/app.log" 2>/dev/null || echo 0)
    SIMILARITY_CALCS=$(grep -c "Similarity:" "$LOG_DIR/app.log" 2>/dev/null || echo 0)
    WINDOW_ADJUSTMENTS=$(grep -c "Context Window Adjusted" "$LOG_DIR/app.log" 2>/dev/null || echo 0)
    
    # Add comma if not first entry
    if [ "$FIRST_ENTRY" = false ]; then
        echo "," >> "$METRICS_FILE"
    fi
    FIRST_ENTRY=false
    
    # Log metrics in JSON format
    cat >> "$METRICS_FILE" << EOF
  {
    "timestamp": "$TIMESTAMP",
    "window_size": ${WINDOW_SIZE:-100},
    "memory_mb": $MEM_MB,
    "embeddings_cache_hits": $CACHE_HITS,
    "similarity_calculations": $SIMILARITY_CALCS,
    "window_adjustments": $WINDOW_ADJUSTMENTS
  }
EOF
    
    # Report every hour
    CURRENT_MIN=$(date +%M)
    if [[ "$CURRENT_MIN" == "00" ]] || [[ "$CURRENT_MIN" == "01" ]]; then
        echo "Hourly Report - $(date '+%Y-%m-%d %H:%M')"
        echo "  Window Size: ${WINDOW_SIZE:-100} items"
        echo "  Memory Usage: ${MEM_MB} MB"
        echo "  Cache Hits: $CACHE_HITS"
        echo "  Window Adjustments: $WINDOW_ADJUSTMENTS"
        echo "  ---"
    fi
    
    sleep 300  # 5 minutes
done

# Close JSON array
echo "" >> "$METRICS_FILE"
echo "]" >> "$METRICS_FILE"

# Generate summary report
echo ""
echo "========================================"
echo "24-Hour Monitoring Complete"
echo "========================================"
echo "Metrics saved to: $METRICS_FILE"
echo ""
echo "Summary Statistics:"
echo "  Total Cache Hits: $CACHE_HITS"
echo "  Total Similarity Calculations: $SIMILARITY_CALCS"
echo "  Total Window Adjustments: $WINDOW_ADJUSTMENTS"
echo "  Final Memory Usage: ${MEM_MB} MB"
echo "  Final Window Size: ${WINDOW_SIZE:-100}"
echo ""
echo "To analyze results:"
echo "  cat $METRICS_FILE | jq '.[] | select(.memory_mb > 200)'"
echo "  cat $METRICS_FILE | jq '[.[] | .window_size] | add/length'"
echo ""

# Kill app if still running
if ps -p $APP_PID > /dev/null 2>&1; then
    kill $APP_PID
fi