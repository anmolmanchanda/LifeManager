# Quick Reference: Monitoring Commands

## Start Testing

### Full 24-Hour Test
```bash
./scripts/production_monitor.sh
```

### Quick Validation (5 min)
```bash
./scripts/quick_validation.sh
```

## Real-Time Monitoring

### Live Dashboard
```bash
./scripts/monitor_realtime.sh
```

### Raw Metrics Stream
```bash
tail -f ~/Library/Logs/LifeManager/24hr_metrics_*.json | jq '.'
```

### Window Adjustments Only
```bash
tail -f ~/Library/Logs/LifeManager/app.log | grep "Context Window Adjusted"
```

### Memory Usage
```bash
while true; do
  ps aux | grep LifeManager | awk '{print $6/1024 " MB"}'
  sleep 60
done
```

## Analysis

### Full Analysis
```bash
python3 scripts/analyze_metrics.py
```

### Quick Stats
```bash
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq '[.[] | .window_size] | {min: min, max: max, avg: (add/length)}'
```

### Hourly Patterns
```bash
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq -r '.[] | "\(.timestamp | split("T")[1] | split(":")[0]):00 \(.window_size)"' | \
  sort | uniq -c
```

### Cache Performance
```bash
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq '{
    total_hits: [.[] | .embeddings_cache_hits] | add,
    total_calcs: [.[] | .similarity_calculations] | add,
    hit_rate: (([.[] | .embeddings_cache_hits] | add) / ([.[] | .similarity_calculations] | add) * 100)
  }'
```

## Export Data

### To CSV
```bash
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq -r '.[] | [.timestamp, .window_size, .memory_mb] | @csv' > metrics.csv
```

### To TSV
```bash
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq -r '.[] | [.timestamp, .window_size, .memory_mb] | @tsv' > metrics.tsv
```

## Troubleshooting

### Check for Crashes
```bash
ls -la ~/Library/Logs/DiagnosticReports/ | grep LifeManager
```

### View UserDefaults
```bash
defaults read com.lifemanager.app context_window_adjustments
```

### Clear Metrics
```bash
rm ~/Library/Logs/LifeManager/24hr_metrics_*.json
```

## Feature Control

### Enable All Features
```bash
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1
./run.sh
```

### Disable Features (Baseline)
```bash
unset ENABLE_ENHANCED_PARA
unset ENABLE_ENHANCED_EMBEDDINGS
./run.sh
```

## Quick Health Check

### One-Liner Status
```bash
echo "Window: $(defaults read com.lifemanager.app context_window_adjustments | tail -1 | grep -o 'new_size = [0-9]*' | awk '{print $3}') | Memory: $(ps aux | grep LifeManager | awk '{print $6/1024}' | head -1) MB"
```

---

Copy any command above to quickly monitor your test!