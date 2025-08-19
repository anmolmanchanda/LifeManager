#!/usr/bin/env swift

//
// test_activity_patterns.swift
// Test script to verify dynamic window sizing behavior
//

import Foundation

// Simulate different activity patterns
struct ActivityTest {
    let description: String
    let hourlyRate: Int
    let expectedWindowSize: Int
    let duration: String
}

let testPatterns = [
    ActivityTest(
        description: "Low Activity (Night/Weekend)",
        hourlyRate: 5,
        expectedWindowSize: 50,
        duration: "8 hours"
    ),
    ActivityTest(
        description: "Medium Activity (Normal Work)",
        hourlyRate: 15,
        expectedWindowSize: 100,
        duration: "8 hours"
    ),
    ActivityTest(
        description: "High Activity (Busy Day)",
        hourlyRate: 35,
        expectedWindowSize: 200,
        duration: "4 hours"
    ),
    ActivityTest(
        description: "Burst Activity (Meeting Notes)",
        hourlyRate: 50,
        expectedWindowSize: 200,
        duration: "1 hour"
    )
]

print("""
🧪 Activity Pattern Test Scenarios
==================================

These patterns simulate different user activity levels
to verify the context window dynamically adjusts:

""")

for (index, test) in testPatterns.enumerated() {
    print("""
    \(index + 1). \(test.description)
       - Hourly Item Rate: \(test.hourlyRate) items/hour
       - Expected Window: \(test.expectedWindowSize) items
       - Test Duration: \(test.duration)
       - Memory Impact: ~\((test.expectedWindowSize * 1024) / 1000)KB
    
    """)
}

print("""
📊 Expected Behavior:
--------------------
1. Window starts at default (100 items)
2. After 14+ days of data:
   - < 10 items/day → shrink to 50
   - 10-30 items/day → adjust proportionally
   - > 30 items/day → expand to 200
3. Trend adjustments:
   - 20% increase in activity → expand by 10
   - 20% decrease in activity → contract by 10

🔍 Monitor with:
./monitor_logs.sh -f -s "CONTEXT_MEMORY"

Or directly:
tail -f ~/Library/Containers/LifeManager/Data/Library/Application\\ Support/LifeManager/Logs/app.log | grep -E "Window|Activity|Trend"

""")

// Generate test data for manual testing
print("""
📝 Manual Test Commands:
-----------------------
# Enable enhanced features
export ENABLE_ENHANCED_PARA=1

# Run the app
./build_and_install.sh

# In another terminal, monitor adjustments
./monitor_logs.sh -f | grep -E "CONTEXT_MEMORY.*Adjusted"

""")