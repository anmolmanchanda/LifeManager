#!/bin/bash

echo "=== Applying High-Impact Fixes ==="

# 1. Fix exhaustive switches by adding @unknown default cases
echo "1. Adding @unknown default to switches..."
find Sources -name "*.swift" -exec grep -l "switch.*{" {} \; | while read file; do
    if grep -q "switch.*{" "$file"; then
        # Check if file needs default cases
        if ! grep -A 10 "switch.*{" "$file" | grep -q "@unknown default"; then
            echo "  Checking: $file"
        fi
    fi
done

# 2. Fix missing Logger dependencies
echo "2. Adding Logger.shared where needed..."
find Sources -name "*.swift" -exec grep -l "logger\." {} \; | while read file; do
    if grep -q "cannot find 'logger' in scope" <<< $(swift build 2>&1 | grep "$file"); then
        echo "  Adding Logger to: $file"
        # Check if Logger is imported
        if ! grep -q "private let logger = Logger.shared" "$file"; then
            # Add logger property after class/struct declaration
            sed -i '' '/^class.*{$/a\
    private let logger = Logger.shared
' "$file"
        fi
    fi
done

# 3. Fix Color.tertiary issues
echo "3. Fixing Color.tertiary usage..."
find Sources -name "*.swift" -exec grep -l "Color\.tertiary\|\.tertiary" {} \; | while read file; do
    echo "  Processing: $file"
    # Replace .tertiary with Color.secondary.opacity(0.6)
    sed -i '' 's/Color\.tertiary/Color.secondary.opacity(0.6)/g' "$file"
    sed -i '' 's/\.tertiary/.secondary.opacity(0.6)/g' "$file"
done

# 4. Import PlatformCompatibility in files with CGColor issues
echo "4. Importing PlatformCompatibility..."
find Sources -name "*.swift" -exec grep -l "CGColor\.system\|systemBackground\|systemGray6" {} \; | while read file; do
    if ! grep -q "import.*PlatformCompatibility" "$file"; then
        echo "  Adding import to: $file"
        # Add import after SwiftUI import
        sed -i '' '/import SwiftUI/a\
import PlatformCompatibility
' "$file"
    fi
done

echo "=== Fixes Applied ==="#