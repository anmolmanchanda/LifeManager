#\!/bin/bash

echo "🧪 Testing MCP Configuration..."
echo ""

# Check if MCP config file exists
CONFIG_FILE="$HOME/.config/claude/mcp.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ MCP config file exists at: $CONFIG_FILE"
else
    echo "❌ MCP config file not found at: $CONFIG_FILE"
    exit 1
fi

# Validate JSON syntax
if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "✅ MCP config file has valid JSON syntax"
else
    echo "❌ MCP config file has invalid JSON syntax"
    exit 1
fi

# Count configured servers
SERVER_COUNT=$(python3 -c "import json; data=json.load(open('$CONFIG_FILE')); print(len(data['mcpServers']))")
echo "✅ MCP config contains $SERVER_COUNT servers"

# Check installed packages
echo ""
echo "📦 Checking installed packages:"
PACKAGES=(
    "@modelcontextprotocol/server-sequential-thinking"
    "@modelcontextprotocol/server-postgres"
    "@modelcontextprotocol/server-brave-search"
    "@modelcontextprotocol/server-filesystem"
    "@astrotask/mcp"
    "@upstash/context7-mcp"
    "apidog-mcp-server"
    "firecrawl-mcp"
    "@sylphlab/tools-memory-mcp"
    "@browsermcp/mcp"
)

for package in "${PACKAGES[@]}"; do
    if npm list -g --depth=0 | grep -q "$package"; then
        echo "✅ $package"
    else
        echo "❌ $package"
    fi
done

echo ""
echo "🎯 To use MCPs with Claude Code:"
echo "claude --mcp-config $CONFIG_FILE"
echo ""
echo "🔧 To configure API keys:"
echo "./setup-env-mcp.sh"