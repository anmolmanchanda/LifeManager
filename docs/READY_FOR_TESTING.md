# v1.9.4 Production Ready - Testing Guide

## Current State
The system has been successfully enhanced with selective features from the Enhanced PARA implementation while maintaining stability and performance.

## Integrated Features

### 1. Dynamic Context Memory
- Automatically adjusts window size (50-200 items) based on activity
- Predictive sizing using time-of-day and day-of-week patterns
- Memory savings of 50-150MB through intelligent management
- Performance metrics tracking with JSON Lines format

### 2. Enhanced Embeddings
- Domain-specific similarity thresholds (0.55, 0.70, 0.85)
- PARA category weighting (Projects: 1.2x, Archive: 0.7x)
- Improved semantic matching for better categorization

### 3. Production Monitoring
- 24-hour automated monitoring script
- Real-time metrics collection (memory, cache hits, window adjustments)
- Performance tracking with detailed logging
- Predictive optimizations based on usage patterns

## How to Test

### Quick Test (5 minutes)
```bash
# Run validation script
./scripts/quick_validation.sh
```

### Standard Test (1 hour)
```bash
# Enable enhanced features
export ENABLE_ENHANCED_PARA=1

# Build and run
./build_and_install.sh
./run.sh

# In another terminal, monitor
./monitor_logs.sh -f | grep -E "CONTEXT_MEMORY|EMBEDDINGS"
```

### Full Production Test (24 hours)
```bash
# Launch monitoring script
./scripts/production_monitor.sh

# This will:
# - Run app for 24 hours
# - Collect metrics every 5 minutes
# - Generate hourly reports
# - Save results to JSON file
```

## Key Metrics to Observe

1. **Build Performance**: Should be under 40 seconds
2. **Memory Usage**: Should show 50-150MB savings vs baseline
3. **Window Adjustments**: Should occur based on activity levels
4. **Cache Hit Rate**: Target > 60% after warm-up
5. **Processing Time**: Target < 100ms for most operations

## Feature Flags

Control features via environment variables:
```bash
# Enable all enhancements
export ENABLE_ENHANCED_PARA=1
export ENABLE_ENHANCED_EMBEDDINGS=1

# Run with enhancements
./run.sh

# Run baseline for comparison
unset ENABLE_ENHANCED_PARA
unset ENABLE_ENHANCED_EMBEDDINGS
./run.sh
```

## What to Look For

### Success Indicators
- Smooth app performance with no crashes
- Memory usage decreases during low activity
- Context window adjusts appropriately
- Build times remain under 40s

### Potential Issues
- If memory grows unbounded: Check window adjustment logs
- If build fails: Run `git tag` and reset to `pre-llm-integration`
- If app crashes: Check logs in `~/Library/Logs/LifeManager/`

## Data Collection

After testing, analyze results:
```bash
# View metrics (requires jq)
cat ~/Library/Logs/LifeManager/24hr_metrics_*.json | jq '.'

# Check window adjustments
defaults read com.lifemanager.app context_window_adjustments

# Review performance logs
grep "Performance" ~/Library/Logs/LifeManager/app.log
```

## Next Steps

After successful 24-hour test:
1. Review collected metrics
2. Document any issues or edge cases
3. Prepare for LLM Brain Dump Processor integration
4. Consider merging to main development branch

## Rollback if Needed

If issues arise:
```bash
# Reset to stable checkpoint
git reset --hard pre-llm-integration
swift build --configuration release
```

## Support

- Logs: `~/Library/Logs/LifeManager/`
- Metrics: `~/Library/Logs/LifeManager/24hr_metrics_*.json`
- Configuration: Feature flags in environment

---

Version: v1.9.4-production-ready
Branch: feature/enhanced-para-integration
Date: January 17, 2025