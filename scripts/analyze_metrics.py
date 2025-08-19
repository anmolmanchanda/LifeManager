#!/usr/bin/env python3
import json
import statistics
from datetime import datetime
import sys
import os

def analyze_24hr_metrics(filepath):
    """Analyze 24-hour metrics from production monitoring"""
    
    # Read JSON array file
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            # Handle both JSON array and JSON Lines format
            if content.strip().startswith('['):
                metrics = json.loads(content)
            else:
                # JSON Lines format
                metrics = []
                for line in content.strip().split('\n'):
                    if line and line not in ['[', ']']:
                        line = line.rstrip(',')
                        try:
                            metrics.append(json.loads(line))
                        except json.JSONDecodeError:
                            continue
    except FileNotFoundError:
        print(f"Error: File {filepath} not found")
        return
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        return
    
    if not metrics:
        print("No metrics data found")
        return
    
    # Extract data
    window_sizes = [m.get('window_size', 100) for m in metrics]
    memory_usage = []
    for m in metrics:
        mem = m.get('memory_mb', 0)
        if isinstance(mem, str):
            # Handle "XXX MB" format
            mem = float(mem.split()[0]) if ' ' in str(mem) else float(mem)
        memory_usage.append(float(mem))
    
    print("24-Hour Analysis Report")
    print("=" * 50)
    
    print(f"\nWindow Size Statistics:")
    print(f"  Average: {statistics.mean(window_sizes):.1f}")
    print(f"  Min: {min(window_sizes)}")
    print(f"  Max: {max(window_sizes)}")
    if len(window_sizes) > 1:
        print(f"  Std Dev: {statistics.stdev(window_sizes):.1f}")
    
    print(f"\nMemory Usage Statistics:")
    if memory_usage:
        print(f"  Average: {statistics.mean(memory_usage):.1f} MB")
        print(f"  Min: {min(memory_usage):.1f} MB")
        print(f"  Max: {max(memory_usage):.1f} MB")
        print(f"  Savings: {max(memory_usage) - min(memory_usage):.1f} MB")
    
    # Detect patterns
    hourly_averages = {}
    for m in metrics:
        try:
            timestamp = m.get('timestamp', '')
            if 'T' in timestamp:
                # ISO format
                hour = datetime.fromisoformat(timestamp.replace('Z', '+00:00')).hour
            else:
                # Try to parse other formats
                hour = datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S').hour
            
            if hour not in hourly_averages:
                hourly_averages[hour] = []
            hourly_averages[hour].append(m.get('window_size', 100))
        except (ValueError, AttributeError):
            continue
    
    if hourly_averages:
        print(f"\nHourly Patterns:")
        for hour in sorted(hourly_averages.keys()):
            avg = statistics.mean(hourly_averages[hour])
            count = len(hourly_averages[hour])
            
            # Determine expected pattern
            if 6 <= hour <= 9:
                expected = "100-150 (morning)"
            elif 9 <= hour <= 17:
                expected = "120-180 (work)"
            elif 17 <= hour <= 21:
                expected = "80-120 (evening)"
            else:
                expected = "50-80 (night)"
            
            status = "OK" if 50 <= avg <= 200 else "CHECK"
            print(f"  {hour:02d}:00 - Avg: {avg:3.0f} | Expected: {expected:20} | {status}")
    
    # Identify optimization opportunities
    print(f"\nOptimization Insights:")
    if len(window_sizes) > 1 and statistics.stdev(window_sizes) > 30:
        print("  OK: High variance in window sizes - predictive sizing is working!")
    elif len(window_sizes) > 1:
        print("  WARNING: Low variance - predictive sizing may need tuning")
    
    # Cache analysis
    cache_hits = sum(m.get('embeddings_cache_hits', 0) for m in metrics)
    total_calcs = sum(m.get('similarity_calculations', 0) for m in metrics)
    if total_calcs > 0:
        hit_rate = (cache_hits / total_calcs) * 100
        print(f"  Cache hit rate: {hit_rate:.1f}%")
        if hit_rate < 60:
            print("  WARNING: Cache hit rate below 60% - consider increasing cache size")
        else:
            print("  OK: Good cache performance")
    
    # Window adjustment frequency
    adjustments = sum(m.get('window_adjustments', 0) for m in metrics)
    if adjustments > 0:
        print(f"  Window adjustments: {adjustments} times")
        if adjustments > len(metrics) * 0.2:
            print("  WARNING: Frequent adjustments - may indicate instability")
    
    # Red flags detection
    print(f"\nRed Flag Detection:")
    red_flags = []
    
    # Check for memory growth
    if memory_usage and len(memory_usage) > 10:
        first_half_avg = statistics.mean(memory_usage[:len(memory_usage)//2])
        second_half_avg = statistics.mean(memory_usage[len(memory_usage)//2:])
        if second_half_avg > first_half_avg * 1.5:
            red_flags.append("Memory leak suspected (50% growth)")
    
    # Check for stuck windows
    if len(set(window_sizes[-10:])) == 1 and len(window_sizes) > 10:
        red_flags.append(f"Window stuck at {window_sizes[-1]} for last 10 readings")
    
    # Check for extreme values during wrong times
    for m in metrics[-20:]:  # Check recent metrics
        try:
            hour = datetime.fromisoformat(m.get('timestamp', '').replace('Z', '+00:00')).hour
            window = m.get('window_size', 100)
            
            if (21 <= hour or hour <= 6) and window >= 180:
                red_flags.append(f"High window ({window}) during night hours")
                break
            elif 9 <= hour <= 17 and window <= 60:
                red_flags.append(f"Low window ({window}) during work hours")
                break
        except:
            continue
    
    if red_flags:
        for flag in red_flags:
            print(f"  WARNING: {flag}")
    else:
        print("  OK: No red flags detected")
    
    # Summary recommendation
    print(f"\nRecommendation:")
    if not red_flags and (not memory_usage or max(memory_usage) < 500):
        print("  System performing well - ready for production")
    elif len(red_flags) <= 1:
        print("  Minor issues detected - review and tune parameters")
    else:
        print("  Multiple issues detected - further investigation needed")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        analyze_24hr_metrics(sys.argv[1])
    else:
        # Try to find today's metrics file
        log_dir = os.path.expanduser("~/Library/Logs/LifeManager")
        today = datetime.now().strftime("%Y%m%d")
        default_file = f"{log_dir}/24hr_metrics_{today}.json"
        
        if os.path.exists(default_file):
            print(f"Analyzing: {default_file}\n")
            analyze_24hr_metrics(default_file)
        else:
            print("Usage: python analyze_metrics.py <metrics_file.json>")
            print(f"Default file not found: {default_file}")