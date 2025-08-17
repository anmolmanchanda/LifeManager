# LifeManager Commands Reference

## Building and Running
```bash
# Build and install app to /Applications
./build_and_install.sh

# Build, install, and launch the app
./run.sh

# Build app bundle only (no installation)
./build_app.sh

# Clean build
swift package clean && swift build --configuration release
```

## Testing
```bash
# Run all Swift tests
swift test

# Run tests in parallel
swift test --parallel

# Run specific test files
swift test --filter LifeManagerTests
swift test --filter EmbeddingsServiceTests
```

## Monitoring and Debugging
```bash
# Monitor app logs in real-time
./monitor_logs.sh -f

# View last 50 log entries with colors
./monitor_logs.sh

# Filter logs by level (DEBUG, INFO, WARN, ERROR, SUCCESS, PROGRESS)
./monitor_logs.sh -l ERROR

# Search logs for specific terms
./monitor_logs.sh -s "BRAIN DUMP"

# Follow logs with filters
./monitor_logs.sh -f -l SUCCESS
```

## Python Test Scripts
```bash
# Test LLM integration
python3 test_llm_integration.py

# Test embeddings integration
python3 test_embeddings_integration.py

# Test contextual PARA processing
python3 test_contextual_para_processing.py

# Comprehensive feature testing
python3 test_comprehensive_features.py

# Test intelligent automation system
python3 test_intelligent_automation.py

# Test AI learning and orchestration
python3 test_ai_learning_orchestration.py
```

## Intelligent Automation Commands
```bash
# Start all automation services
# Services start automatically when app launches

# Monitor automation performance
./monitor_logs.sh -s "AUTOMATION_ORCHESTRATOR"
./monitor_logs.sh -s "AI_LEARNING"
./monitor_logs.sh -s "PERFORMANCE_MONITOR"

# Check automation status
./monitor_logs.sh -s "INTELLIGENT_RESCHEDULING"
./monitor_logs.sh -s "ADVANCED_NOTIFICATIONS"
./monitor_logs.sh -s "TASK_DEPENDENCIES"

# View system health metrics
./monitor_logs.sh -s "SYSTEM_HEALTH"
./monitor_logs.sh -s "OPTIMIZATION"
```

## MCP (Model Context Protocol) Commands
```bash
# Use MCPs with Claude Code
claude --mcp-config ~/.config/claude/mcp.json

# Configure API keys for MCP servers
./setup-env-mcp.sh

# Test MCP configuration
./test-mcp-config.sh

# Setup all MCP servers
./setup-mcps.sh
```

## Git Commands (for Claude Code)
```bash
# When committing changes:
# 1. Check status and changes
git status
git diff
git log --oneline -10

# 2. Add and commit with proper message
git add <files>
git commit -m "type(scope): description

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 3. Create pull requests
gh pr create --title "title" --body "description"
```

## Linting and Code Quality
```bash
# Run lint checks manually
./lint_check.sh

# Install pre-commit hook (optional)
cp pre-commit-hook.template .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```