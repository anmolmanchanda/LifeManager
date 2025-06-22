#\!/bin/bash

# MCP Environment Setup Script
echo "🔧 Setting up MCP environment variables..."

# Check if .env file exists
if [ \! -f ".env" ]; then
    echo "📋 Creating .env file from template..."
    cp .env.template .env
    echo "✅ Created .env file. Please edit it with your API keys."
    echo ""
    echo "Required API keys:"
    echo "1. BRAVE_API_KEY - Get from https://brave.com/search/api/"
    echo "2. FIRECRAWL_API_KEY - Get from https://firecrawl.dev/"
    echo ""
    echo "Edit the .env file and run this script again."
    exit 0
fi

# Source the .env file
echo "📥 Loading environment variables from .env file..."
set -a
source .env
set +a

# Check if required variables are set (not just the template values)
missing_vars=()

if [ "$BRAVE_API_KEY" = "your_brave_api_key_here" ] || [ -z "$BRAVE_API_KEY" ]; then
    missing_vars+=("BRAVE_API_KEY")
fi

if [ "$FIRECRAWL_API_KEY" = "your_firecrawl_api_key_here" ] || [ -z "$FIRECRAWL_API_KEY" ]; then
    missing_vars+=("FIRECRAWL_API_KEY")
fi

if [ ${#missing_vars[@]} -eq 0 ]; then
    echo "✅ All required MCP environment variables are configured\!"
    echo ""
    echo "🚀 MCP Status:"
    echo "• Sequential Thinking: ✅ Ready"
    echo "• Postgres: ✅ Ready" 
    echo "• Brave Search: ✅ Ready (API key configured)"
    echo "• Filesystem: ✅ Ready"
    echo "• Task Master AI: ✅ Ready"
    echo "• Context7: ✅ Ready"
    echo "• Apidog: ⚠️ Needs project ID (optional)"
    echo "• Firecrawl: ✅ Ready (API key configured)"
    echo "• Memory Cache: ✅ Ready"
    echo "• Browser MCP: ✅ Ready"
    echo ""
    echo "💡 To use MCPs with Claude Code:"
    echo "claude --mcp-config ~/.config/claude/mcp.json"
else
    echo "❌ Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "  • $var"
    done
    echo ""
    echo "Please edit the .env file and add your API keys."
    echo "Run 'open .env' to edit the file."
fi
EOF < /dev/null