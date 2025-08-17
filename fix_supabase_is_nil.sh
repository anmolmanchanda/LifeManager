#!/bin/bash

echo "Fixing Supabase .is() method usage with nil values..."

# Find all files with the incorrect .is() usage pattern
find Sources -name "*.swift" -exec grep -l '\.is(".*", value: nil as String?)' {} \; | while read file; do
    echo "Processing $file"
    # Replace .is("column", value: nil as String?) with .is("column", value: nil)
    sed -i '' 's/\.is("\([^"]*\)", value: nil as String?)/.is("\1", value: nil)/' "$file"
done

# Also fix any other variations
find Sources -name "*.swift" -exec grep -l '\.is(".*", value: nil as UUID?)' {} \; | while read file; do
    echo "Processing $file"
    sed -i '' 's/\.is("\([^"]*\)", value: nil as UUID?)/.is("\1", value: nil)/' "$file"
done

echo "Done!"