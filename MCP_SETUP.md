# MCP Servers Configuration Guide

All 8 MCP servers have been configured for your LifeManager project. Here's the complete setup:

## Configured MCP Servers

### 1. **Sequential Thinking MCP** ✅
- **Package**: `@modelcontextprotocol/server-sequential-thinking`
- **Purpose**: Provides structured thinking and reasoning capabilities
- **Status**: Ready to use

### 2. **Taskmaster AI MCP** ✅
- **Package**: `@astrotask/mcp`
- **Purpose**: Advanced task management and AI assistance
- **Status**: Ready to use

### 3. **Context7** ✅
- **Package**: `@upstash/context7-mcp`
- **Purpose**: Context management and retrieval
- **Status**: Ready to use

### 4. **Filesystem** ✅
- **Package**: `@modelcontextprotocol/server-filesystem`
- **Path**: `/Users/Shared/LifeManager`
- **Purpose**: File system operations
- **Status**: Ready to use

### 5. **Memory Cache** ✅
- **Package**: `@sylphlab/tools-memory-mcp`
- **Purpose**: Memory management and caching
- **Status**: Ready to use

### 6. **Postgres** ✅
- **Package**: `@modelcontextprotocol/server-postgres`
- **Connection**: Connected to your Supabase database
- **Purpose**: Database operations
- **Status**: Ready to use

### 7. **Apidog** ⚠️
- **Package**: `apidog-mcp-server`
- **Purpose**: API documentation and testing
- **Status**: Needs project/doc ID configuration

### 8. **Batch Processor (Firecrawl)** ⚠️
- **Package**: `firecrawl-mcp`
- **Purpose**: Web scraping and content processing
- **Status**: Needs FIRECRAWL_API_KEY

### 9. **Brave Search** ⚠️
- **Package**: `@modelcontextprotocol/server-brave-search`
- **Purpose**: Web search capabilities
- **Status**: Needs BRAVE_API_KEY

### 10. **Browser MCP** ✅
- **Package**: `@browsermcp/mcp`
- **Purpose**: Browser automation and interaction
- **Status**: Ready to use

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

Create a `.env` file in your project root:

```bash
# MCP Server API Keys
BRAVE_API_KEY=your_brave_api_key_here
FIRECRAWL_API_KEY=your_firecrawl_api_key_here
APIDOG_PROJECT_ID=your_project_id_here
```

## Testing MCP Servers

Run `claude mcp` to see the status of all servers. Green checkmarks indicate working servers.

## Current Status

- **Working**: 7/10 servers (Sequential Thinking, Taskmaster AI, Context7, Filesystem, Memory Cache, Postgres, Browser MCP)
- **Needs API Keys**: 3/10 servers (Brave Search, Batch Processor, Apidog)