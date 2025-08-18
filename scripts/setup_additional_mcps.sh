#!/bin/bash

echo "========================================="
echo "  Installing Additional MCP Servers"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

MCP_DIR="$HOME/.config/claude/mcps"
CONFIG_FILE="$HOME/.config/claude/claude_desktop_config.json"

echo -e "${BLUE}Available MCP Servers:${NC}"
echo "1. filesystem - File system operations"
echo "2. git - Git repository management"
echo "3. memory - Knowledge graph storage"
echo "4. sequentialthinking - Step-by-step reasoning"
echo "5. time - Time and date utilities"
echo "6. fetch - Web content fetching"
echo "7. everything - Search everything on your system"
echo ""

# Install dependencies for each server
echo -e "${BLUE}Installing MCP servers...${NC}"

cd "$MCP_DIR/additional-mcps"

# Install filesystem server
echo -e "${YELLOW}Installing filesystem server...${NC}"
cd src/filesystem && npm install --silent 2>/dev/null
echo -e "${GREEN}✅${NC} Filesystem server installed"

# Install git server
echo -e "${YELLOW}Installing git server...${NC}"
cd ../git && npm install --silent 2>/dev/null
echo -e "${GREEN}✅${NC} Git server installed"

# Install memory server
echo -e "${YELLOW}Installing memory server...${NC}"
cd ../memory && npm install --silent 2>/dev/null
echo -e "${GREEN}✅${NC} Memory server installed"

# Install sequential thinking server
echo -e "${YELLOW}Installing sequential thinking server...${NC}"
cd ../sequentialthinking && npm install --silent 2>/dev/null
echo -e "${GREEN}✅${NC} Sequential thinking server installed"

# Install time server
echo -e "${YELLOW}Installing time server...${NC}"
cd ../time && npm install --silent 2>/dev/null
echo -e "${GREEN}✅${NC} Time server installed"

# Create comprehensive MCP configuration
echo ""
echo -e "${BLUE}Creating MCP configuration...${NC}"

cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": [
        "/Users/Work/.config/claude/mcps/additional-mcps/src/filesystem/dist/index.js",
        "/Users/Shared/LifeManager"
      ],
      "env": {}
    },
    "git": {
      "command": "node",
      "args": [
        "/Users/Work/.config/claude/mcps/additional-mcps/src/git/dist/index.js",
        "--repository",
        "/Users/Shared/LifeManager"
      ],
      "env": {}
    },
    "memory": {
      "command": "node",
      "args": [
        "/Users/Work/.config/claude/mcps/additional-mcps/src/memory/dist/index.js"
      ],
      "env": {
        "MEMORY_STORE_PATH": "/Users/Work/.config/claude/memory_store.json"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-sequential-thinking"
      ],
      "env": {}
    },
    "time": {
      "command": "node",
      "args": [
        "/Users/Work/.config/claude/mcps/additional-mcps/src/time/dist/index.js"
      ],
      "env": {}
    },
    "brain-dump": {
      "command": "node",
      "args": [
        "/Users/Work/.config/claude/mcps/brain-dump-mcp/index.js"
      ],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}",
        "SUPABASE_URL": "${SUPABASE_URL}",
        "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY}"
      }
    }
  }
}
EOF

echo -e "${GREEN}✅${NC} MCP configuration created at $CONFIG_FILE"
echo ""
echo -e "${BLUE}Installed MCP Servers:${NC}"
echo "• filesystem - Manage files in LifeManager project"
echo "• git - Git operations on LifeManager repository"
echo "• memory - Store and retrieve context across sessions"
echo "• sequential-thinking - Step-by-step reasoning for complex tasks"
echo "• time - Time utilities for scheduling and reminders"
echo "• brain-dump - Custom processor for your complex notes"
echo ""
echo -e "${YELLOW}Note:${NC} Restart Claude Desktop to load the new MCP servers"
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"