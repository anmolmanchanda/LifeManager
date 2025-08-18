#!/bin/bash

# LifeManager Log Monitor
# Real-time log monitoring with filtering and search capabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
LOG_DIR="$HOME/Documents/LifeManager/Logs"
LINES=50
FOLLOW=false
FILTER=""
LEVEL=""

# Function to show usage
show_usage() {
    echo "LifeManager Log Monitor"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --follow          Follow log file (like tail -f)"
    echo "  -n, --lines NUM       Show last NUM lines (default: 50)"
    echo "  -l, --level LEVEL     Filter by log level (DEBUG, INFO, WARN, ERROR, SUCCESS, PROGRESS)"
    echo "  -s, --search TERM     Search for specific term"
    echo "  -d, --dir PATH        Custom log directory path"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    Show last 50 log entries"
    echo "  $0 -f                 Follow logs in real-time"
    echo "  $0 -l ERROR           Show only ERROR level logs"
    echo "  $0 -s 'BRAIN DUMP'    Search for brain dump related logs"
    echo "  $0 -f -l SUCCESS      Follow only SUCCESS logs"
    echo ""
}

# Function to colorize log levels
colorize_logs() {
    sed -E \
        -e "s/\[([0-9-]+ [0-9:.]+)\]/${CYAN}[\1]${NC}/g" \
        -e "s/🔧 DEBUG/${BLUE}🔧 DEBUG${NC}/g" \
        -e "s/ℹ️ INFO/${CYAN}ℹ️ INFO${NC}/g" \
        -e "s/⚠️ WARN/${YELLOW}⚠️ WARN${NC}/g" \
        -e "s/❌ ERROR/${RED}❌ ERROR${NC}/g" \
        -e "s/✅ SUCCESS/${GREEN}✅ SUCCESS${NC}/g" \
        -e "s/⏳ PROGRESS/${PURPLE}⏳ PROGRESS${NC}/g" \
        -e "s/BRAIN DUMP/${GREEN}BRAIN DUMP${NC}/g" \
        -e "s/LLM/${BLUE}LLM${NC}/g" \
        -e "s/API/${YELLOW}API${NC}/g"
}

# Function to get the latest log file
get_latest_log_file() {
    if [ ! -d "$LOG_DIR" ]; then
        echo "Log directory not found: $LOG_DIR"
        echo "Make sure LifeManager has been run at least once to create logs."
        exit 1
    fi
    
    local latest_log=$(find "$LOG_DIR" -name "lifemanager-*.log" -type f -exec ls -t {} + | head -n1)
    
    if [ -z "$latest_log" ]; then
        echo "No log files found in $LOG_DIR"
        echo "Make sure LifeManager has been run at least once to create logs."
        exit 1
    fi
    
    echo "$latest_log"
}

# Function to apply filters
apply_filters() {
    local content="$1"
    
    # Apply level filter
    if [ -n "$LEVEL" ]; then
        content=$(echo "$content" | grep "$LEVEL" || true)
    fi
    
    # Apply search filter
    if [ -n "$FILTER" ]; then
        content=$(echo "$content" | grep -i "$FILTER" || true)
    fi
    
    echo "$content"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -l|--level)
            LEVEL="$2"
            shift 2
            ;;
        -s|--search)
            FILTER="$2"
            shift 2
            ;;
        -d|--dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Get the latest log file
LOG_FILE=$(get_latest_log_file)

echo -e "${GREEN}📋 LifeManager Log Monitor${NC}"
echo -e "${CYAN}📁 Log file: $LOG_FILE${NC}"
echo -e "${CYAN}📊 Showing last $LINES lines${NC}"

if [ -n "$LEVEL" ]; then
    echo -e "${YELLOW}🔍 Filtering by level: $LEVEL${NC}"
fi

if [ -n "$FILTER" ]; then
    echo -e "${YELLOW}🔍 Searching for: $FILTER${NC}"
fi

echo ""
echo -e "${PURPLE}==================== LOGS ====================${NC}"

# Show logs
if [ "$FOLLOW" = true ]; then
    echo -e "${GREEN}👀 Following logs in real-time (Ctrl+C to stop)...${NC}"
    echo ""
    
    if [ -n "$LEVEL" ] || [ -n "$FILTER" ]; then
        # For filtered following, we need to use a different approach
        tail -f "$LOG_FILE" | while read line; do
            filtered=$(apply_filters "$line")
            if [ -n "$filtered" ]; then
                echo "$filtered" | colorize_logs
            fi
        done
    else
        # Simple following without filters
        tail -f "$LOG_FILE" | colorize_logs
    fi
else
    # Show last N lines
    content=$(tail -n "$LINES" "$LOG_FILE")
    filtered_content=$(apply_filters "$content")
    
    if [ -z "$filtered_content" ]; then
        echo -e "${YELLOW}No matching log entries found.${NC}"
    else
        echo "$filtered_content" | colorize_logs
    fi
fi

echo ""
echo -e "${PURPLE}===============================================${NC}"

# Show summary if not following
if [ "$FOLLOW" = false ]; then
    echo ""
    echo -e "${CYAN}📈 Log Summary:${NC}"
    
    # Count different log levels in the shown content
    if [ -n "$filtered_content" ]; then
        debug_count=$(echo "$filtered_content" | grep -c "DEBUG" || echo "0")
        info_count=$(echo "$filtered_content" | grep -c "INFO" || echo "0")
        warn_count=$(echo "$filtered_content" | grep -c "WARN" || echo "0")
        error_count=$(echo "$filtered_content" | grep -c "ERROR" || echo "0")
        success_count=$(echo "$filtered_content" | grep -c "SUCCESS" || echo "0")
        progress_count=$(echo "$filtered_content" | grep -c "PROGRESS" || echo "0")
        
        echo -e "  ${BLUE}🔧 DEBUG: $debug_count${NC}"
        echo -e "  ${CYAN}ℹ️ INFO: $info_count${NC}"
        echo -e "  ${YELLOW}⚠️ WARN: $warn_count${NC}"
        echo -e "  ${RED}❌ ERROR: $error_count${NC}"
        echo -e "  ${GREEN}✅ SUCCESS: $success_count${NC}"
        echo -e "  ${PURPLE}⏳ PROGRESS: $progress_count${NC}"
        
        # Show brain dump specific stats
        brain_dump_count=$(echo "$filtered_content" | grep -c "BRAIN DUMP" || echo "0")
        if [ "$brain_dump_count" -gt 0 ]; then
            echo ""
            echo -e "  ${GREEN}🧠 BRAIN DUMP entries: $brain_dump_count${NC}"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}💡 Tips:${NC}"
    echo -e "  • Use ${YELLOW}-f${NC} to follow logs in real-time"
    echo -e "  • Use ${YELLOW}-l ERROR${NC} to see only errors"
    echo -e "  • Use ${YELLOW}-s 'BRAIN DUMP'${NC} to track brain dump processing"
    echo -e "  • Use ${YELLOW}-h${NC} for more options"
fi 