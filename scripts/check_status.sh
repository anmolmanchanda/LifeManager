#!/bin/bash

echo "LifeManager Status Check"
echo "========================"
echo ""

# Find LifeManager process
PID=$(pgrep -x LifeManager || pgrep -f "LifeManager.app")

if [ -z "$PID" ]; then
    echo "❌ LifeManager is not running"
    exit 1
fi

echo "✅ LifeManager is running (PID: $PID)"

# Get memory usage
MEM_KB=$(ps -o rss= -p $PID 2>/dev/null | tr -d ' ')
MEM_MB=$((MEM_KB / 1024))
echo "💾 Memory Usage: ${MEM_MB} MB"

# Check window size from defaults (if available)
WINDOW_SIZE=$(defaults read com.lifemanager.app context_window_adjustments 2>/dev/null | \
              tail -1 | grep -o 'new_size = [0-9]*' | awk '{print $3}')
if [ -n "$WINDOW_SIZE" ]; then
    echo "🪟 Window Size: $WINDOW_SIZE"
else
    echo "🪟 Window Size: 100 (default)"
fi

# Check metrics file
METRICS_FILE="$HOME/Library/Logs/LifeManager/24hr_metrics_$(date +%Y%m%d).json"
if [ -f "$METRICS_FILE" ]; then
    ENTRIES=$(grep -c timestamp "$METRICS_FILE")
    echo "📊 Metrics Entries: $ENTRIES"
    
    # Get latest entry time
    LATEST=$(tail -10 "$METRICS_FILE" | grep timestamp | tail -1 | cut -d'"' -f4)
    if [ -n "$LATEST" ]; then
        echo "⏰ Latest Entry: $LATEST"
    fi
else
    echo "📊 No metrics file found"
fi

# Check if features are enabled
if [ "$ENABLE_ENHANCED_PARA" = "1" ]; then
    echo "🚀 Enhanced PARA: Enabled"
else
    echo "🚀 Enhanced PARA: Disabled"
fi

if [ "$ENABLE_ENHANCED_EMBEDDINGS" = "1" ]; then
    echo "🎯 Enhanced Embeddings: Enabled"
else
    echo "🎯 Enhanced Embeddings: Disabled"
fi

echo ""
echo "Quick Analysis:"
echo "--------------"

# Determine status
if [ "$MEM_MB" -lt 50 ]; then
    echo "✅ Memory usage is excellent (< 50MB)"
elif [ "$MEM_MB" -lt 200 ]; then
    echo "✅ Memory usage is good (< 200MB)"
elif [ "$MEM_MB" -lt 500 ]; then
    echo "⚠️  Memory usage is moderate (< 500MB)"
else
    echo "❌ Memory usage is high (>= 500MB)"
fi

# Check time of day patterns
HOUR=$(date +%H)
if [ "$HOUR" -ge 21 ] || [ "$HOUR" -le 6 ]; then
    echo "🌙 Night time - expect low activity"
elif [ "$HOUR" -ge 9 ] && [ "$HOUR" -le 17 ]; then
    echo "☀️  Work hours - expect high activity"
else
    echo "🌅 Transition period"
fi

echo ""
echo "To monitor in real-time:"
echo "  ./scripts/monitor_realtime.sh"
echo ""
echo "To analyze metrics:"
echo "  python3 scripts/analyze_metrics.py"