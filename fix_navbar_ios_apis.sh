#!/bin/bash

echo "Fixing iOS-only navigationBarTitleDisplayMode API usage..."

# Find and replace navigationBarTitleDisplayMode lines - comment them out for macOS
find Sources -name "*.swift" -exec grep -l "navigationBarTitleDisplayMode" {} \; | while read file; do
    echo "Processing $file"
    # Comment out the navigationBarTitleDisplayMode lines with #if os(iOS) guard
    sed -i '' 's/\.navigationBarTitleDisplayMode(.*)$/\#if os(iOS)\n            &\n            #endif/' "$file"
done

echo "Fixing iOS-only navigationBar placement APIs..."

# Fix navigationBarLeading and navigationBarTrailing
find Sources -name "*.swift" -exec grep -l "navigationBarLeading\|navigationBarTrailing" {} \; | while read file; do
    echo "Processing navigationBar placements in $file"
    # Replace with macOS-compatible placements
    sed -i '' 's/placement: \.navigationBarLeading/placement: .automatic/' "$file"
    sed -i '' 's/placement: \.navigationBarTrailing/placement: .automatic/' "$file"
done

echo "Done!"