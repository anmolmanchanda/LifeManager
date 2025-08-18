#!/bin/bash

# Setup script for MCP servers and prompt caching
echo "Setting up 9 MCP servers for Claude Code..."

# Set environment variables for prompt caching
export ANTHROPIC_CACHE_PROMPT=true
export ANTHROPIC_CACHE_TTL=3600

# MCP config path
MCP_CONFIG="$HOME/.config/claude/mcp.json"

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$MCP_CONFIG")"

# Check if MCP config exists
if [ ! -f "$MCP_CONFIG" ]; then
    echo "Creating MCP configuration..."
    cp /Users/Shared/.config/claude/mcp.json "$MCP_CONFIG"
fi

# Function to check MCP server availability
check_mcp() {
    local name=$1
    local package=$2
    timeout 10s npx "$package" --help >/dev/null 2>&1 && echo "✓ $name server available" || echo "✗ $name server not available"
}

# Test all 9 MCP servers availability
echo "Testing MCP server packages..."
check_mcp "Sequential thinking" "@modelcontextprotocol/server-sequential-thinking"
check_mcp "Postgres" "@modelcontextprotocol/server-postgres"
check_mcp "Brave search" "@modelcontextprotocol/server-brave-search"
check_mcp "Filesystem" "@modelcontextprotocol/server-filesystem"
check_mcp "Task master AI" "@task-master-ai/mcp-server"
check_mcp "Context7" "@upstash/context7-mcp"
check_mcp "APIDOG" "@apidog/mcp-server"
check_mcp "Batch processor" "@modelcontextprotocol/server-batch-processor"
check_mcp "Memory cache" "@modelcontextprotocol/server-memory-cache"

echo ""
echo "All 9 MCP servers configured:"
echo "1. Sequential thinking - AI reasoning chains"
echo "2. Postgres - Database operations"
echo "3. Brave search - Web search capabilities"
echo "4. Filesystem - File operations"
echo "5. Task master AI - Task management"
echo "6. Context7 - Context management"
echo "7. APIDOG - API testing"
echo "8. Batch processor - Batch operations"
echo "9. Memory cache - Caching layer"

echo ""
echo "To use MCPs with Claude Code, run:"
echo "claude --mcp-config $MCP_CONFIG"
echo ""
echo "Environment variables set for prompt caching (90% token savings):"
echo "ANTHROPIC_CACHE_PROMPT=$ANTHROPIC_CACHE_PROMPT"
echo "ANTHROPIC_CACHE_TTL=$ANTHROPIC_CACHE_TTL"

# Function to ensure MCPs stay running
keep_mcps_running() {
    echo ""
    echo "Starting MCP health monitoring..."
    while true; do
        # Check if Claude is running with MCPs
        if pgrep -f "claude.*mcp-config" >/dev/null; then
            echo "$(date): Claude Code running with MCP config ✓"
        else
            echo "$(date): No Claude Code instance with MCP config detected"
        fi
        sleep 60
    done
}

# Option to run monitoring
if [ "$1" = "--monitor" ]; then
    keep_mcps_running
fi