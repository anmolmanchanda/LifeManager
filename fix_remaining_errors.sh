#!/bin/bash

echo "Fixing remaining compilation errors..."

# Fix CGColor system colors (macOS doesn't have these UIKit colors)
echo "Fixing CGColor system colors..."
find Sources -name "*.swift" -exec grep -l "CGColor.system" {} \; | while read file; do
    echo "Processing $file"
    sed -i '' 's/CGColor\.systemBackground/NSColor.controlBackgroundColor.cgColor/g' "$file"
    sed -i '' 's/CGColor\.systemGray6/NSColor.systemGray.cgColor/g' "$file"
    sed -i '' 's/CGColor\.systemGroupedBackground/NSColor.windowBackgroundColor.cgColor/g' "$file"
done

# Fix LLMServiceCoordinator.processText - it should be processMessage
echo "Fixing LLMServiceCoordinator.processText..."
find Sources -name "*.swift" -exec grep -l "\.processText" {} \; | while read file; do
    echo "Processing $file"
    sed -i '' 's/\.processText(/\.processMessage(/g' "$file"
done

echo "Done with automated fixes!"