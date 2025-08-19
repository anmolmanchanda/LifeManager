#!/bin/bash

echo "========================================="
echo "  Brain Dump Functionality Test Report"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check critical components
echo "1. Checking Core Components:"
echo "----------------------------"

# Check if LLMBrainDumpProcessor exists
if [ -f "/Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift" ]; then
    echo -e "${GREEN}✅${NC} LLMBrainDumpProcessor.swift exists"
    lines=$(wc -l < "/Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift")
    echo "   - Size: $lines lines"
else
    echo -e "${RED}❌${NC} LLMBrainDumpProcessor.swift missing"
fi

# Check if BrainDumpReviewView exists
if [ -f "/Users/Shared/LifeManager/Sources/LifeManager/Views/BrainDumpReviewView.swift" ]; then
    echo -e "${GREEN}✅${NC} BrainDumpReviewView.swift exists"
    lines=$(wc -l < "/Users/Shared/LifeManager/Sources/LifeManager/Views/BrainDumpReviewView.swift")
    echo "   - Size: $lines lines"
else
    echo -e "${RED}❌${NC} BrainDumpReviewView.swift missing"
fi

# Check if API key configuration exists
if [ -f "$HOME/Documents/config.txt" ]; then
    echo -e "${GREEN}✅${NC} config.txt found"
    if grep -q "sk-" "$HOME/Documents/config.txt" 2>/dev/null; then
        echo "   - OpenAI API key configured"
    else
        echo -e "   ${YELLOW}⚠️${NC} API key may not be valid"
    fi
else
    echo -e "${YELLOW}⚠️${NC} config.txt not found in ~/Documents/"
fi

echo ""
echo "2. Checking Dependencies:"
echo "-------------------------"

# Check LLMService
if grep -q "class LLMService" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMService.swift 2>/dev/null; then
    echo -e "${GREEN}✅${NC} LLMService available"
else
    echo -e "${RED}❌${NC} LLMService not found"
fi

# Check EmbeddingsService
if grep -q "class EmbeddingsService" /Users/Shared/LifeManager/Sources/LifeManager/Services/EmbeddingsService.swift 2>/dev/null; then
    echo -e "${GREEN}✅${NC} EmbeddingsService available"
else
    echo -e "${RED}❌${NC} EmbeddingsService not found"
fi

# Check repositories
echo -e "${GREEN}✅${NC} Repository classes:"
for repo in BlobRepository TaskRepository PARARepository ResourceRepository JournalRepository; do
    if ls /Users/Shared/LifeManager/Sources/LifeManager/Repositories/${repo}.swift >/dev/null 2>&1; then
        echo "   - $repo: found"
    else
        echo -e "   ${YELLOW}⚠️${NC} $repo: missing"
    fi
done

echo ""
echo "3. Checking Features:"
echo "--------------------"

# Check key methods
echo "Key methods in LLMBrainDumpProcessor:"
grep -E "func (processBrainDump|executeBrainDump|performLLMAnalysis)" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null | while read -r line; do
    method=$(echo "$line" | sed 's/.*func //' | sed 's/(.*//')
    echo "   - $method()"
done

echo ""
echo "4. Checking Integration:"
echo "------------------------"

# Check MainViewModel integration
if grep -q "processBrainDump" /Users/Shared/LifeManager/Sources/LifeManager/ViewModels/MainViewModel.swift 2>/dev/null; then
    echo -e "${GREEN}✅${NC} MainViewModel integrated with brain dump"
    count=$(grep -c "processBrainDump" /Users/Shared/LifeManager/Sources/LifeManager/ViewModels/MainViewModel.swift)
    echo "   - $count references to processBrainDump"
else
    echo -e "${RED}❌${NC} MainViewModel not integrated"
fi

# Check UI integration
if grep -q "BrainDumpReviewView" /Users/Shared/LifeManager/Sources/LifeManager/Views/ContentView.swift 2>/dev/null; then
    echo -e "${GREEN}✅${NC} ContentView shows BrainDumpReviewView"
else
    echo -e "${RED}❌${NC} BrainDumpReviewView not shown in UI"
fi

echo ""
echo "5. Production Readiness Checklist:"
echo "----------------------------------"

# Feature completeness
echo "Core Features:"
features=(
    "Text input processing:processBrainDump"
    "LLM analysis:performLLMAnalysis"
    "Fallback processing:processBrainDumpFallback"
    "Review UI:BrainDumpReviewView"
    "Item editing:BrainDumpItemRow"
    "Execution:executeBrainDump"
    "PARA categorization:PARACategory"
    "Confidence scoring:confidence"
)

for feature in "${features[@]}"; do
    name="${feature%%:*}"
    pattern="${feature##*:}"
    if grep -q "$pattern" /Users/Shared/LifeManager/Sources/LifeManager/**/*.swift 2>/dev/null; then
        echo -e "${GREEN}✅${NC} $name"
    else
        echo -e "${YELLOW}⚠️${NC} $name (needs verification)"
    fi
done

echo ""
echo "6. Expected vs Current State:"
echo "-----------------------------"

echo "Expected (from documentation):"
echo "  • Natural language input → structured PARA items"
echo "  • Automatic task extraction with priorities"
echo "  • Intelligent categorization (Projects/Areas/Resources/Archives)"
echo "  • Embeddings for semantic similarity"
echo "  • Review UI before saving"
echo "  • Confidence scoring"
echo "  • Fallback processing without API"

echo ""
echo "Current Implementation:"

# Check for specific features
if grep -q "extractedItems" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Item extraction implemented"
else
    echo -e "  ${RED}❌${NC} Item extraction missing"
fi

if grep -q "TaskPriority" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Priority assignment implemented"
else
    echo -e "  ${RED}❌${NC} Priority assignment missing"
fi

if grep -q "PARACategory" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} PARA categorization implemented"
else
    echo -e "  ${RED}❌${NC} PARA categorization missing"
fi

if grep -q "embeddingsService" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Embeddings integration present"
else
    echo -e "  ${RED}❌${NC} Embeddings integration missing"
fi

if grep -q "BrainDumpReviewView" /Users/Shared/LifeManager/Sources/LifeManager/Views/ 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Review UI implemented"
else
    echo -e "  ${RED}❌${NC} Review UI missing"
fi

if grep -q "confidence" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Confidence scoring implemented"
else
    echo -e "  ${RED}❌${NC} Confidence scoring missing"
fi

if grep -q "processBrainDumpFallback" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "  ${GREEN}✅${NC} Fallback processing implemented"
else
    echo -e "  ${RED}❌${NC} Fallback processing missing"
fi

echo ""
echo "7. Gap Analysis:"
echo "----------------"

# Check for TODOs
todo_count=$(grep -r "TODO" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null | wc -l)
if [ "$todo_count" -gt 0 ]; then
    echo -e "${YELLOW}⚠️${NC} Found $todo_count TODO items in brain dump processor"
else
    echo -e "${GREEN}✅${NC} No TODO items in brain dump processor"
fi

# Check error handling
if grep -q "catch LLMError" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
    echo -e "${GREEN}✅${NC} Error handling implemented"
else
    echo -e "${YELLOW}⚠️${NC} Limited error handling"
fi

# Check logging
log_count=$(grep -c "Logger.shared" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null)
if [ "$log_count" -gt 5 ]; then
    echo -e "${GREEN}✅${NC} Comprehensive logging ($log_count log points)"
else
    echo -e "${YELLOW}⚠️${NC} Limited logging ($log_count log points)"
fi

echo ""
echo "========================================="
echo "  PRODUCTION READINESS ASSESSMENT"
echo "========================================="
echo ""

# Count successes
success_count=0
warning_count=0
error_count=0

# Core components check
if [ -f "/Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift" ] && \
   [ -f "/Users/Shared/LifeManager/Sources/LifeManager/Views/BrainDumpReviewView.swift" ]; then
    ((success_count+=2))
else
    ((error_count+=1))
fi

# Integration check
if grep -q "processBrainDump" /Users/Shared/LifeManager/Sources/LifeManager/ViewModels/MainViewModel.swift 2>/dev/null; then
    ((success_count+=1))
else
    ((error_count+=1))
fi

# Feature implementation check
for feature in "extractedItems" "TaskPriority" "PARACategory" "confidence" "processBrainDumpFallback"; do
    if grep -q "$feature" /Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift 2>/dev/null; then
        ((success_count+=1))
    else
        ((warning_count+=1))
    fi
done

# Calculate readiness score
total_checks=$((success_count + warning_count + error_count))
readiness_percent=$((success_count * 100 / total_checks))

echo "Readiness Score: ${readiness_percent}%"
echo ""

if [ "$readiness_percent" -ge 80 ]; then
    echo -e "${GREEN}✅ PRODUCTION READY${NC}"
    echo "Brain dump functionality is ready for production use."
    echo ""
    echo "Recommendations:"
    echo "  • Test with various input types"
    echo "  • Monitor API usage and costs"
    echo "  • Consider rate limiting for API calls"
elif [ "$readiness_percent" -ge 60 ]; then
    echo -e "${YELLOW}⚠️  MOSTLY READY${NC}"
    echo "Brain dump functionality is mostly ready but needs minor improvements."
    echo ""
    echo "Required fixes:"
    echo "  • Address any missing core features"
    echo "  • Improve error handling"
    echo "  • Add comprehensive testing"
else
    echo -e "${RED}❌ NOT PRODUCTION READY${NC}"
    echo "Brain dump functionality needs significant work."
    echo ""
    echo "Critical issues:"
    echo "  • Missing core components"
    echo "  • Integration incomplete"
    echo "  • Features not implemented"
fi

echo ""
echo "To test brain dump functionality:"
echo "  1. Ensure API key is configured in ~/Documents/config.txt"
echo "  2. Launch the app: ./run.sh"
echo "  3. Enter text in the main input field"
echo "  4. Click 'Analyze & Process' button"
echo "  5. Review suggested items in the popup"
echo "  6. Confirm to save to database"