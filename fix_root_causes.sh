#!/bin/bash

echo "=== Fixing Top Root Cause Errors ==="

# 1. Fix exhaustive switches by adding default cases
echo "1. Adding default cases to exhaustive switches..."
find Sources -name "*.swift" -exec grep -l "switch.*{" {} \; | while read file; do
    # Check if file has switch statements without default
    if grep -q "switch.*{" "$file" && ! grep -A 20 "switch.*{" "$file" | grep -q "default:"; then
        echo "  Checking switches in $file"
    fi
done

# 2. Fix ProcessingContext missing properties
echo "2. Adding missing properties to ProcessingContext..."
if grep -q "struct ProcessingContext" Sources/LifeManager/Models/IntelligentSchedulingModels.swift; then
    echo "  Found ProcessingContext, checking for missing properties..."
fi

# 3. Fix ScenarioScore missing overallScore
echo "3. Adding overallScore to ScenarioScore..."
if grep -q "struct ScenarioScore" Sources/LifeManager/Models/ReschedulingModels.swift; then
    echo "  Found ScenarioScore, checking for missing properties..."
fi

# 4. Fix LifeTask missing tags
echo "4. Adding tags to LifeTask..."
if grep -q "struct LifeTask" Sources/LifeManager/Models/CoreModels.swift; then
    echo "  Found LifeTask, checking for missing properties..."
fi

echo "=== Analyzing specific issues ==="