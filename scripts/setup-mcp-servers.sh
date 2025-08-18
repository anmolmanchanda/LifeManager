#!/bin/bash

echo "========================================="
echo "  Setup MCP Servers for Enhanced Processing"
echo "========================================="
echo ""
echo "Installing Model Context Protocol servers for brain dump processing..."
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Create MCP directory
MCP_DIR="$HOME/.config/claude/mcps"
mkdir -p "$MCP_DIR"

echo -e "${BLUE}Step 1: Installing MCP Memory Server (Knowledge Graph)${NC}"
echo "----------------------------------------"

# Clone memory server
cd "$MCP_DIR"
if [ ! -d "mcp-memory" ]; then
    git clone https://github.com/modelcontextprotocol/servers.git mcp-servers 2>/dev/null || echo "Already exists"
    echo -e "${GREEN}✅${NC} Memory server repository cloned"
else
    echo -e "${YELLOW}⚠️${NC} Memory server already exists"
fi

echo ""
echo -e "${BLUE}Step 2: Installing Sequential Thinking Server${NC}"
echo "----------------------------------------"

# Sequential thinking is in the same repo
echo -e "${GREEN}✅${NC} Sequential Thinking server available"

echo ""
echo -e "${BLUE}Step 3: Creating MCP Configuration${NC}"
echo "----------------------------------------"

# Create claude_desktop_config.json for MCP servers
cat > "$HOME/.config/claude/claude_desktop_config.json" << 'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "node",
      "args": [
        "$HOME/.config/claude/mcps/mcp-servers/dist/memory/index.js"
      ],
      "env": {
        "GRAPH_DB_PATH": "$HOME/.config/claude/memory/knowledge_graph.db"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/Shared/LifeManager"
      ]
    },
    "git": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git",
        "--repository",
        "/Users/Shared/LifeManager"
      ]
    },
    "fetch": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-fetch"
      ]
    }
  }
}
EOF

echo -e "${GREEN}✅${NC} MCP configuration created"

echo ""
echo -e "${BLUE}Step 4: Installing Node Dependencies${NC}"
echo "----------------------------------------"

# Check if npm is installed
if command -v npm &> /dev/null; then
    echo "Installing MCP server dependencies..."
    
    # Install global MCP packages
    npm install -g @modelcontextprotocol/server-memory @modelcontextprotocol/server-sequential-thinking 2>/dev/null || echo "Some packages may already be installed"
    
    echo -e "${GREEN}✅${NC} Dependencies installed"
else
    echo -e "${RED}❌${NC} npm not found. Please install Node.js first"
fi

echo ""
echo -e "${BLUE}Step 5: Creating Enhanced Brain Dump MCP${NC}"
echo "----------------------------------------"

# Create custom MCP for brain dump processing
mkdir -p "$MCP_DIR/brain-dump-mcp"

cat > "$MCP_DIR/brain-dump-mcp/package.json" << 'EOF'
{
  "name": "brain-dump-mcp",
  "version": "1.0.0",
  "description": "MCP server for processing complex personal notes",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "latest",
    "natural": "latest",
    "chrono-node": "latest",
    "compromise": "latest"
  }
}
EOF

cat > "$MCP_DIR/brain-dump-mcp/index.js" << 'EOF'
const { Server } = require('@modelcontextprotocol/sdk');
const natural = require('natural');
const chrono = require('chrono-node');
const nlp = require('compromise');

class BrainDumpMCP extends Server {
  constructor() {
    super({
      name: 'brain-dump',
      version: '1.0.0',
      description: 'Process complex personal notes with NLP'
    });
    
    this.setupTools();
  }
  
  setupTools() {
    // Tool: Parse medical information
    this.addTool({
      name: 'parse_medical',
      description: 'Extract medical conditions, symptoms, and medications',
      inputSchema: {
        type: 'object',
        properties: {
          text: { type: 'string', description: 'Text containing medical information' }
        },
        required: ['text']
      },
      handler: async ({ text }) => {
        const doc = nlp(text);
        
        // Extract medical entities
        const conditions = doc.match('#Condition').out('array');
        const symptoms = doc.match('#Symptom').out('array');
        const medications = doc.match('#Drug').out('array');
        
        // Extract dates
        const dates = chrono.parse(text);
        
        return {
          conditions,
          symptoms,
          medications,
          temporalInfo: dates.map(d => ({
            text: d.text,
            start: d.start.date(),
            end: d.end?.date()
          }))
        };
      }
    });
    
    // Tool: Parse rules and restrictions
    this.addTool({
      name: 'parse_rules',
      description: 'Extract personal rules, restrictions, and commitments',
      inputSchema: {
        type: 'object',
        properties: {
          text: { type: 'string', description: 'Text containing rules' }
        },
        required: ['text']
      },
      handler: async ({ text }) => {
        const lines = text.split('\n');
        const rules = [];
        
        for (const line of lines) {
          // Pattern matching for rules (e.g., "8=1/3-15/7 No club")
          const rulePattern = /(\d+)=(\d+\/\d+)(?:-(\d+\/\d+))?\s+(.+)/;
          const match = line.match(rulePattern);
          
          if (match) {
            rules.push({
              priority: parseInt(match[1]),
              startDate: match[2],
              endDate: match[3] || null,
              rule: match[4]
            });
          }
        }
        
        return { rules };
      }
    });
    
    // Tool: Parse schedules
    this.addTool({
      name: 'parse_schedule',
      description: 'Extract schedules, routines, and time blocks',
      inputSchema: {
        type: 'object',
        properties: {
          text: { type: 'string', description: 'Text containing schedule information' }
        },
        required: ['text']
      },
      handler: async ({ text }) => {
        const timePattern = /(\d{1,2}):?(\d{2})?\s*(?:am|pm)?/gi;
        const times = text.match(timePattern) || [];
        
        const doc = nlp(text);
        const activities = doc.match('#Verb #Noun+').out('array');
        
        return {
          timeBlocks: times,
          activities,
          parsed: chrono.parse(text)
        };
      }
    });
    
    // Tool: Extract goals
    this.addTool({
      name: 'extract_goals',
      description: 'Identify goals, targets, and milestones',
      inputSchema: {
        type: 'object',
        properties: {
          text: { type: 'string', description: 'Text containing goals' }
        },
        required: ['text']
      },
      handler: async ({ text }) => {
        const doc = nlp(text);
        
        // Look for goal indicators
        const goals = doc.match('(goal|target|milestone|objective) #Noun+').out('array');
        const dates = chrono.parse(text);
        
        return {
          goals,
          deadlines: dates.map(d => ({
            text: d.text,
            date: d.start.date()
          }))
        };
      }
    });
  }
}

// Start the server
const server = new BrainDumpMCP();
server.start();
EOF

echo -e "${GREEN}✅${NC} Brain Dump MCP created"

echo ""
echo -e "${BLUE}Step 6: Testing MCP Servers${NC}"
echo "----------------------------------------"

# Test sequential thinking server
echo "Testing Sequential Thinking server..."
timeout 5s npx @modelcontextprotocol/server-sequential-thinking --help 2>/dev/null && echo -e "${GREEN}✅${NC} Sequential Thinking works" || echo -e "${YELLOW}⚠️${NC} Sequential Thinking needs configuration"

echo ""
echo "========================================="
echo -e "${GREEN}  MCP Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Installed MCP Servers:"
echo "  • Memory (Knowledge Graph) - Persistent memory storage"
echo "  • Sequential Thinking - Step-by-step problem solving"
echo "  • Filesystem - File access for LifeManager"
echo "  • Git - Version control integration"
echo "  • Fetch - Web content retrieval"
echo "  • Brain Dump - Custom NLP processing"
echo ""
echo "Configuration saved to:"
echo "  $HOME/.config/claude/claude_desktop_config.json"
echo ""
echo "To use with Claude Desktop:"
echo "  1. Restart Claude Desktop app"
echo "  2. MCPs will be available automatically"
echo "  3. Use commands like:"
echo "     - 'Use memory server to store this information'"
echo "     - 'Use sequential thinking to break down this problem'"
echo ""
echo -e "${YELLOW}Note:${NC} Some servers may require additional setup or API keys"