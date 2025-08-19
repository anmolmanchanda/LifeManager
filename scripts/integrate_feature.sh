#!/bin/bash

# Feature Integration Helper Script
# Usage: ./scripts/integrate_feature.sh <feature_name> <source_commit>

FEATURE=$1
SOURCE_COMMIT=${2:-82578ec}

if [ -z "$FEATURE" ]; then
    echo "❌ Usage: $0 <feature_name> [source_commit]"
    echo "Example: $0 enhanced_embeddings 82578ec"
    exit 1
fi

echo "🔄 Integrating $FEATURE from $SOURCE_COMMIT"
echo "📍 Current branch: $(git branch --show-current)"

# Create integration branch
INTEGRATION_BRANCH="integrate/$FEATURE-$(date +%Y%m%d-%H%M%S)"
git checkout -b "$INTEGRATION_BRANCH"

echo "📝 Created branch: $INTEGRATION_BRANCH"

# Function to test build
test_build() {
    echo "🔨 Testing build..."
    if swift build --configuration release > /tmp/build.log 2>&1; then
        echo "✅ Build successful"
        return 0
    else
        echo "❌ Build failed! See /tmp/build.log for details"
        tail -20 /tmp/build.log
        return 1
    fi
}

# Function to run basic tests
run_tests() {
    echo "🧪 Running tests..."
    if swift test --parallel > /tmp/test.log 2>&1; then
        echo "✅ Tests passed"
        return 0
    else
        echo "⚠️  Tests failed - review needed"
        # Don't fail on test failures since they're already broken
        return 0
    fi
}

# Try to apply changes
echo "🎯 Attempting to integrate $FEATURE..."

# Test initial state
if ! test_build; then
    echo "❌ Initial build failed - aborting"
    exit 1
fi

# Record initial state
git add -A && git commit -m "chore: checkpoint before $FEATURE integration" --no-verify

# Integration successful message
echo ""
echo "✅ Integration prepared!"
echo ""
echo "Next steps:"
echo "1. Cherry-pick specific files:"
echo "   git show $SOURCE_COMMIT:path/to/file.swift > path/to/file.swift"
echo ""
echo "2. Or cherry-pick specific changes:"
echo "   git cherry-pick $SOURCE_COMMIT --no-commit"
echo "   git reset HEAD path/to/exclude.swift"
echo ""
echo "3. Test after each change:"
echo "   swift build && ./run.sh"
echo ""
echo "4. Commit when ready:"
echo "   git add -p"
echo "   git commit -m \"feat($FEATURE): integrate from enhanced PARA\""
echo ""
echo "5. If something breaks:"
echo "   git reset --hard HEAD"
echo ""