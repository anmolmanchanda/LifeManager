# MCP Servers Configuration Guide

All 10 MCP servers have been successfully installed and configured for your LifeManager project. Here's the complete setup:

## Configured MCP Servers

### 1. **Sequential Thinking MCP** ✅
- **Package**: `@modelcontextprotocol/server-sequential-thinking`
- **Purpose**: Provides structured thinking and reasoning capabilities
- **Status**: ✅ Installed and Ready

### 2. **Taskmaster AI MCP** ✅
- **Package**: `@astrotask/mcp`
- **Purpose**: Advanced task management and AI assistance
- **Status**: ✅ Installed and Ready

### 3. **Context7** ✅
- **Package**: `@upstash/context7-mcp`
- **Purpose**: Context management and retrieval
- **Status**: ✅ Installed and Ready

### 4. **Filesystem** ✅
- **Package**: `@modelcontextprotocol/server-filesystem`
- **Path**: `/Users/Shared/LifeManager`
- **Purpose**: File system operations
- **Status**: ✅ Installed and Ready

### 5. **Memory Cache** ✅
- **Package**: `@sylphlab/tools-memory-mcp`
- **Purpose**: Memory management and caching
- **Status**: ✅ Installed and Ready

### 6. **Postgres** ✅
- **Package**: `@modelcontextprotocol/server-postgres`
- **Connection**: Connected to your Supabase database
- **Purpose**: Database operations
- **Status**: ✅ Installed and Ready

### 7. **Apidog** 🔧
- **Package**: `apidog-mcp-server`
- **Purpose**: API documentation and testing
- **Status**: ✅ Installed - Needs project/doc ID configuration

### 8. **Firecrawl (Web Scraping)** 🔧
- **Package**: `firecrawl-mcp`
- **Purpose**: Web scraping and content processing
- **Status**: ✅ Installed - Needs FIRECRAWL_API_KEY

### 9. **Brave Search** 🔧
- **Package**: `@modelcontextprotocol/server-brave-search`
- **Purpose**: Web search capabilities
- **Status**: ✅ Installed - Needs BRAVE_API_KEY

### 10. **Browser MCP** ✅
- **Package**: `@browsermcp/mcp`
- **Purpose**: Browser automation and interaction
- **Status**: ✅ Installed and Ready

## API Keys Required

To fully activate all servers, you'll need these API keys:

1. **Brave Search API Key**
   - Get from: https://brave.com/search/api/
   - Set environment variable: `BRAVE_API_KEY=your_key_here`

2. **Firecrawl API Key**
   - Get from: https://firecrawl.dev/
   - Set environment variable: `FIRECRAWL_API_KEY=your_key_here`

3. **Apidog Configuration**
   - Requires project ID or doc site ID
   - Configure when adding specific API documentation

## Environment Setup

### Quick Setup (Recommended)

1. **Run the automated setup script:**
   ```bash
   ./setup-env-mcp.sh
   ```

2. **Edit the generated `.env` file with your API keys:**
   ```bash
   open .env
   ```

### Manual Setup

Alternatively, create a `.env` file in your project root:

```bash
# MCP Server API Keys
BRAVE_API_KEY=your_brave_api_key_here
FIRECRAWL_API_KEY=your_firecrawl_api_key_here
APIDOG_PROJECT_ID=your_project_id_here

# Anthropic Prompt Caching (for better performance)
ANTHROPIC_CACHE_PROMPT=true
ANTHROPIC_CACHE_TTL=3600
```

## Testing MCP Servers

Run `claude mcp` to see the status of all servers. Green checkmarks indicate working servers.

## Current Status ✅

- **✅ Fully Working**: 7/10 servers (Sequential Thinking, Taskmaster AI, Context7, Filesystem, Memory Cache, Postgres, Browser MCP)
- **🔧 Needs API Keys**: 3/10 servers (Brave Search, Firecrawl, Apidog)
- **📦 Installation**: ✅ All packages installed successfully
- **⚙️ Configuration**: ✅ MCP config file created at `~/.config/claude/mcp.json`

### Summary Status
- **All MCP servers are installed and ready to use**
- **7 servers work immediately without any configuration**
- **3 servers need API keys for full functionality**
- **Run `./setup-env-mcp.sh` to configure API keys**

### To Use MCPs with Claude Code:
```bash
claude --mcp-config ~/.config/claude/mcp.json
```

🎉 **MCP setup is now complete!** All packages are installed and the configuration is ready.