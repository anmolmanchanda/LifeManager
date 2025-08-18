#!/bin/bash

# LifeManager Code Quality Lint Check
# Prevents debug prints and other code quality issues

echo "🔍 Running LifeManager code quality checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any issues found
ISSUES_FOUND=0

# Check 1: Debug print statements
echo "Checking for debug print statements..."
DEBUG_PRINTS=$(find Sources/ -name "*.swift" -exec grep -l "print(" {} \; 2>/dev/null | grep -v Logger.swift)

if [ ! -z "$DEBUG_PRINTS" ]; then
    echo -e "${RED}❌ Debug print statements found in:${NC}"
    echo "$DEBUG_PRINTS"
    echo -e "${YELLOW}Use Logger.shared instead of print() statements${NC}"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✅ No debug print statements found${NC}"
fi

# Check 2: NSLog statements  
echo "Checking for NSLog statements..."
NSLOG_STATEMENTS=$(find Sources/ -name "*.swift" -exec grep -l "NSLog(" {} \; 2>/dev/null)

if [ ! -z "$NSLOG_STATEMENTS" ]; then
    echo -e "${RED}❌ NSLog statements found in:${NC}"
    echo "$NSLOG_STATEMENTS"
    echo -e "${YELLOW}Use Logger.shared instead of NSLog statements${NC}"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✅ No NSLog statements found${NC}"
fi

# Check 3: TODO comments (warning only)
echo "Checking for TODO comments..."
TODO_COUNT=$(find Sources/ -name "*.swift" -exec grep -c "TODO" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')

if [ "$TODO_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found $TODO_COUNT TODO comments${NC}"
    echo -e "${YELLOW}Consider addressing these when possible${NC}"
else
    echo -e "${GREEN}✅ No TODO comments found${NC}"
fi

# Check 4: Proper Logger imports
echo "Checking for Logger imports..."
SERVICES_WITHOUT_LOGGER=$(find Sources/ -name "*.swift" -path "*/Services/*" -exec sh -c 'if grep -q "Logger.shared" "$1" && ! grep -q "private let logger = Logger.shared\|let logger = Logger.shared" "$1"; then echo "$1"; fi' _ {} \;)

if [ ! -z "$SERVICES_WITHOUT_LOGGER" ]; then
    echo -e "${YELLOW}⚠️  Services using Logger.shared without dependency:${NC}"
    echo "$SERVICES_WITHOUT_LOGGER"
    echo -e "${YELLOW}Consider adding 'private let logger = Logger.shared' dependency${NC}"
else
    echo -e "${GREEN}✅ Logger dependencies properly declared${NC}"
fi

# Final result
echo ""
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 All code quality checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Code quality issues found. Please fix before committing.${NC}"
    exit 1
fi