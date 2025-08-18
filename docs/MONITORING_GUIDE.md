# Production Monitoring Guide

## Quick Start

### 1. Start 24-Hour Test
```bash
# Terminal 1: Launch production monitoring
./scripts/production_monitor.sh
```

### 2. Real-Time Monitoring
```bash
# Terminal 2: Watch metrics in real-time
./scripts/monitor_realtime.sh

# Alternative: Raw JSON monitoring
tail -f ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq -r '[.timestamp, .window_size, .memory_mb] | @csv'
```

### 3. Analyze Results
```bash
# After test completes (or periodically during)
python3 scripts/analyze_metrics.py
```

## Expected Patterns vs Red Flags

| Time Period | Expected Behavior | Red Flags |
|------------|------------------|-----------|
| **Morning (6-9am)** | Window: 100-150<br>Memory: Stable<br>Cache warming up | Window stuck at max (200)<br>Memory growing rapidly<br>No cache hits |
| **Work Hours (9am-5pm)** | Window: 120-180<br>Memory: 200-400MB<br>Cache hits >60% | Cache hits <30%<br>Frequent resizing (>1/min)<br>Memory >500MB |
| **Evening (5-9pm)** | Window: 80-120<br>Memory decreasing<br>Moderate activity | Memory not releasing<br>Window thrashing<br>Crashes |
| **Night (9pm-6am)** | Window: 50-80<br>Memory: <200MB<br>Minimal activity | Any crashes or hangs<br>Window at max<br>Memory leaks |

## Key Metrics to Monitor

### 1. Window Size Dynamics
- **Healthy**: Varies throughout day (50-200 range)
- **Concerning**: Stuck at one value for >2 hours
- **Critical**: Always at min (50) or max (200)

### 2. Memory Usage
- **Healthy**: 150-400MB with daily variation
- **Concerning**: Steady growth without release
- **Critical**: >500MB or out of memory errors

### 3. Cache Performance
- **Healthy**: >60% hit rate after warm-up
- **Concerning**: 30-60% hit rate
- **Critical**: <30% hit rate or no hits

### 4. Adjustment Frequency
- **Healthy**: 10-20 adjustments per day
- **Concerning**: >50 adjustments per day
- **Critical**: Constant thrashing or no adjustments

## Real-Time Monitoring Commands

### Watch Window Adjustments
```bash
tail -f ~/Library/Logs/LifeManager/app.log | \
  grep "Context Window Adjusted"
```

### Monitor Memory Usage
```bash
while true; do
  ps aux | grep LifeManager | grep -v grep | awk '{print $6/1024 " MB"}'
  sleep 60
done
```

### Track Cache Efficiency
```bash
tail -f ~/Library/Logs/LifeManager/app.log | \
  grep -E "Cache (hit|miss)" | \
  awk '{hits[$3]++} END {for(i in hits) print i, hits[i]}'
```

## Troubleshooting

### High Memory Usage
1. Check window size: `defaults read com.lifemanager.app context_window_adjustments`
2. Look for leaks: `leaks LifeManager`
3. Review recent adjustments in logs

### Poor Cache Performance
1. Check cache size configuration
2. Review embedding generation frequency
3. Analyze access patterns

### Window Stuck
1. Check activity patterns
2. Review predictive sizing logic
3. Verify time/date calculations

### Application Crashes
1. Check crash logs: `~/Library/Logs/DiagnosticReports/`
2. Review last operations before crash
3. Test with features disabled

## Performance Baselines

After successful 24-hour test, you should see:

| Metric | Target | Acceptable Range |
|--------|--------|-----------------|
| Avg Window Size | 100-120 | 80-140 |
| Window Std Dev | >30 | 20-50 |
| Memory Savings | 50-150MB | 30-200MB |
| Cache Hit Rate | >60% | 50-80% |
| Build Time | <40s | 30-50s |
| Response Time | <100ms | 50-200ms |

## Data Analysis

### Generate Summary Report
```bash
# Full analysis
python3 scripts/analyze_metrics.py ~/Library/Logs/LifeManager/24hr_metrics_*.json

# Quick stats with jq
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq '[.[] | .window_size] | {min: min, max: max, avg: (add/length)}'
```

### Export for Visualization
```bash
# Convert to CSV for Excel/Sheets
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq -r '.[] | [.timestamp, .window_size, .memory_mb, .cache_hits] | @csv' \
  > metrics_export.csv
```

### Pattern Detection
```bash
# Find peak usage times
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | \
  jq -r '.[] | "\(.timestamp | split("T")[1] | split(":")[0]):00 \(.window_size)"' | \
  sort | uniq -c | sort -rn | head -10
```

## Action Items Based on Results

### If Window Sizing Issues:
- [ ] Adjust thresholds in ContextConfig
- [ ] Tune predictive patterns
- [ ] Review activity detection logic

### If Memory Issues:
- [ ] Implement more aggressive cleanup
- [ ] Reduce cache sizes
- [ ] Add memory pressure handling

### If Cache Issues:
- [ ] Increase cache capacity
- [ ] Implement smarter eviction
- [ ] Add cache preloading

### If Performance Issues:
- [ ] Profile hot paths
- [ ] Optimize database queries
- [ ] Review async operations

## Success Criteria

The test is successful if:
1. No crashes during 24-hour period
2. Memory usage stays within bounds
3. Window sizing shows daily patterns
4. Cache hit rate exceeds 60%
5. No red flags in automated analysis

## Next Steps After Success

1. Document observed patterns
2. Update predictive models with real data
3. Fine-tune thresholds based on results
4. Prepare for LLM processor integration
5. Plan production rollout

---

Remember: The goal is adaptive performance, not perfect metrics. Some variation is expected and healthy!