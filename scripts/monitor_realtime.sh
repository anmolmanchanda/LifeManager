#!/bin/bash
# Real-time monitoring during 24-hour test

LOG_DIR="$HOME/Library/Logs/LifeManager"
METRICS_FILE="$LOG_DIR/24hr_metrics_$(date +%Y%m%d).json"

echo "Real-Time Monitoring Dashboard"
echo "=============================="
echo "Monitoring: $METRICS_FILE"
echo ""
echo "Time                    | Window | Memory (MB) | Cache Hits | Status"
echo "------------------------|--------|-------------|------------|--------"

# Monitor in real-time
tail -f "$METRICS_FILE" 2>/dev/null | while read line; do
    # Skip empty lines and array brackets
    if [[ -z "$line" ]] || [[ "$line" == "[" ]] || [[ "$line" == "]" ]]; then
        continue
    fi
    
    # Remove trailing comma if present
    line="${line%,}"
    
    # Parse JSON line
    if echo "$line" | jq -e . >/dev/null 2>&1; then
        TIMESTAMP=$(echo "$line" | jq -r '.timestamp' | cut -d'T' -f2 | cut -d'Z' -f1)
        WINDOW=$(echo "$line" | jq -r '.window_size')
        MEMORY=$(echo "$line" | jq -r '.memory_mb')
        CACHE_HITS=$(echo "$line" | jq -r '.embeddings_cache_hits // 0')
        
        # Determine status based on patterns
        HOUR=$(date +%H)
        STATUS="OK"
        
        # Check for red flags
        if [ "$WINDOW" -eq 200 ] && [ "$HOUR" -ge 21 -o "$HOUR" -le 6 ]; then
            STATUS="WARNING: Max window at night"
        elif [ "$MEMORY" -gt 500 ]; then
            STATUS="WARNING: High memory"
        elif [ "$WINDOW" -eq 50 ] && [ "$HOUR" -ge 9 -a "$HOUR" -le 17 ]; then
            STATUS="WARNING: Min window during work"
        fi
        
        # Color coding for status
        if [[ "$STATUS" == "OK" ]]; then
            printf "%s | %6d | %11d | %10d | ✅ %s\n" "$TIMESTAMP" "$WINDOW" "$MEMORY" "$CACHE_HITS" "$STATUS"
        else
            printf "%s | %6d | %11d | %10d | ⚠️  %s\n" "$TIMESTAMP" "$WINDOW" "$MEMORY" "$CACHE_HITS" "$STATUS"
        fi
    fi
done