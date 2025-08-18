#!/bin/bash

echo "========================================="
echo "  LLM v2 Progressive Rollout"
echo "========================================="
echo ""

# Parse arguments
ROLLOUT_PERCENT=${1:-10}
MONITOR_DURATION=${2:-7200}  # Default 2 hours

echo "Configuration:"
echo "  Rollout Percentage: ${ROLLOUT_PERCENT}%"
echo "  Monitor Duration: ${MONITOR_DURATION} seconds"
echo ""

# Kill existing app
killall LifeManager 2>/dev/null
sleep 2

# Set environment for rollout
export ENABLE_LLM_PROCESSOR_V2=1
export ROLLOUT_PERCENTAGE=$ROLLOUT_PERCENT
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1

echo "Building with LLM v2 at ${ROLLOUT_PERCENT}% rollout..."
cd /Users/Shared/LifeManager

# Build
swift build --configuration release > /tmp/rollout_build.log 2>&1

if [ $? -ne 0 ]; then
    echo "Build failed! Check /tmp/rollout_build.log"
    tail -20 /tmp/rollout_build.log
    exit 1
fi

# Create app bundle
./build_app.sh > /dev/null 2>&1

# Install
rm -rf /Applications/LifeManager.app 2>/dev/null
cp -R LifeManager.app /Applications/

# Launch with monitoring
echo ""
echo "Launching with LLM v2 (${ROLLOUT_PERCENT}% rollout)..."
ENABLE_LLM_PROCESSOR_V2=1 \
ROLLOUT_PERCENTAGE=$ROLLOUT_PERCENT \
ENABLE_ENHANCED_PARA=1 \
ENABLE_ENHANCED_EMBEDDINGS=1 \
/Applications/LifeManager.app/Contents/MacOS/LifeManager &

APP_PID=$!
sleep 5

if ! ps -p $APP_PID > /dev/null; then
    echo "App failed to start!"
    exit 1
fi

echo "App running with PID: $APP_PID"
echo ""

# Create metrics file
METRICS_FILE="$HOME/Library/Logs/LifeManager/llm_rollout_${ROLLOUT_PERCENT}_$(date +%Y%m%d_%H%M).json"
echo "[" > "$METRICS_FILE"

echo "Starting monitoring for $(($MONITOR_DURATION / 60)) minutes..."
echo "Metrics: $METRICS_FILE"
echo ""

# Monitor loop
START_TIME=$(date +%s)
END_TIME=$((START_TIME + MONITOR_DURATION))
FIRST_ENTRY=true

while [ $(date +%s) -lt $END_TIME ]; do
    if ps -p $APP_PID > /dev/null; then
        # Collect metrics
        MEM_KB=$(ps -o rss= -p $APP_PID 2>/dev/null | tr -d ' ')
        MEM_MB=$((MEM_KB / 1024))
        
        # Check logs for LLM activity
        LLM_V1_COUNT=$(grep -c "LLM_BRIDGE.*legacy processor" ~/Library/Logs/LifeManager/app.log 2>/dev/null || echo 0)
        LLM_V2_COUNT=$(grep -c "LLM_BRIDGE.*enhanced processor" ~/Library/Logs/LifeManager/app.log 2>/dev/null || echo 0)
        
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        
        if [ "$FIRST_ENTRY" = false ]; then
            echo "," >> "$METRICS_FILE"
        fi
        FIRST_ENTRY=false
        
        cat >> "$METRICS_FILE" << EOF
  {
    "timestamp": "$TIMESTAMP",
    "rollout_percentage": $ROLLOUT_PERCENT,
    "memory_mb": $MEM_MB,
    "llm_v1_calls": $LLM_V1_COUNT,
    "llm_v2_calls": $LLM_V2_COUNT,
    "pid": $APP_PID
  }
EOF
        
        # Report every 10 minutes
        if [ $(($(date +%s) % 600)) -eq 0 ]; then
            echo "Status Update:"
            echo "  Memory: ${MEM_MB} MB"
            echo "  LLM v1 calls: $LLM_V1_COUNT"
            echo "  LLM v2 calls: $LLM_V2_COUNT"
            echo ""
        fi
        
        sleep 60  # Check every minute
    else
        echo "App crashed! Check logs."
        break
    fi
done

echo "]" >> "$METRICS_FILE"

# Final report
echo ""
echo "========================================="
echo "  Rollout Test Complete"
echo "========================================="
echo ""

if ps -p $APP_PID > /dev/null; then
    echo "Status: SUCCESS"
    MEM_KB=$(ps -o rss= -p $APP_PID 2>/dev/null | tr -d ' ')
    MEM_MB=$((MEM_KB / 1024))
    echo "Final Memory: ${MEM_MB} MB"
else
    echo "Status: FAILED (app crashed)"
fi

LLM_V1_FINAL=$(grep -c "LLM_BRIDGE.*legacy processor" ~/Library/Logs/LifeManager/app.log 2>/dev/null || echo 0)
LLM_V2_FINAL=$(grep -c "LLM_BRIDGE.*enhanced processor" ~/Library/Logs/LifeManager/app.log 2>/dev/null || echo 0)

echo "LLM Usage:"
echo "  v1 (legacy): $LLM_V1_FINAL calls"
echo "  v2 (enhanced): $LLM_V2_FINAL calls"

if [ $LLM_V2_FINAL -gt 0 ]; then
    V2_PERCENT=$((LLM_V2_FINAL * 100 / (LLM_V1_FINAL + LLM_V2_FINAL)))
    echo "  Actual v2 usage: ${V2_PERCENT}%"
fi

echo ""
echo "Metrics saved to: $METRICS_FILE"
echo ""

# Recommendation
if ps -p $APP_PID > /dev/null && [ $MEM_MB -lt 500 ]; then
    echo "Recommendation: SAFE to increase rollout"
    echo "Next step: ./scripts/progressive_rollout.sh 50"
else
    echo "Recommendation: Investigate issues before increasing rollout"
fi