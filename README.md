# LifeManager - AI-Powered Life Organization System

**Transform chaos into clarity with intelligent task management and knowledge organization**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green.svg)](./ARCHITECTURE.md)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

## 🚀 Overview

LifeManager is a native macOS application that combines advanced AI capabilities with the PARA methodology (Projects, Areas, Resources, Archives) to transform how you capture, organize, and act on information. Built with SwiftUI and powered by OpenAI's latest models, it's your intelligent second brain that understands context, learns your patterns, and helps you stay organized effortlessly.

### 🎯 Core Philosophy

- **Zero Friction Capture**: Brain dump anything - the AI figures out what it is
- **Intelligent Organization**: Automatic PARA categorization with context awareness
- **Adaptive Intelligence**: Learns your patterns and improves over time
- **Privacy First**: Your data stays local with optional cloud sync
- **Professional Grade**: Enterprise-quality code with comprehensive testing

## ✨ Key Features

### 🧠 Advanced Brain Dump Processing
- **Complex Note Understanding**: Handles medical data, schedules, rules, goals, and mixed content
- **Multi-Format Support**: Tasks, notes, journal entries, financial records, contacts, appointments
- **Intelligent Extraction**: Automatically identifies and extracts actionable items
- **Confidence Scoring**: AI provides confidence levels for automated decisions

### 📊 PARA Methodology Implementation
- **Projects**: Active initiatives with defined outcomes
- **Areas**: Ongoing responsibilities to maintain
- **Resources**: Reference materials for future use
- **Archives**: Completed or inactive items

### 🤖 AI-Powered Features
- **OpenAI GPT-4 & o1 Integration**: Advanced reasoning and understanding
- **Embeddings & Semantic Search**: Find related content intelligently
- **Contextual Processing**: Considers your history and patterns
- **Smart Scheduling**: AI-assisted calendar management with buffer optimization

### 💾 Robust Data Management
- **Supabase Integration**: Real-time sync across devices
- **10+ Specialized Tables**: Health logs, medications, goals, schedules, and more
- **Row-Level Security**: Your data is always protected
- **Offline Support**: Full functionality without internet

## 🏗️ Architecture

### Clean Architecture Principles
```
Sources/LifeManager/
├── Services/
│   ├── Context/                    # Refactored context memory system
│   │   ├── ActivityPatternService  # User behavior tracking (195 lines)
│   │   ├── ContextWindowManager    # Sliding window management (219 lines)
│   │   ├── SummaryGenerationService # Daily/weekly/monthly summaries (261 lines)
│   │   ├── ContextPersistenceService # Database operations (206 lines)
│   │   ├── ContextQueryService     # Search and queries (227 lines)
│   │   └── ContextMemoryCoordinator # Facade coordinator (186 lines)
│   ├── AI/
│   │   ├── LLMService              # OpenAI integration
│   │   ├── EmbeddingsService       # Semantic search
│   │   └── EnhancedBrainDumpProcessor # Complex note processing
│   └── Data/
│       ├── SupabaseService         # Database operations
│       └── CalendarService         # Calendar integration
├── ViewModels/                     # MVVM architecture
│   ├── MainViewModel               # Central app state
│   └── ContextualPARAViewModel    # PARA methodology logic
├── Views/                          # SwiftUI interfaces
└── Models/                         # Data models
```

### Code Quality Standards
- **Maximum 500 lines** per service file
- **Single Responsibility** principle enforced
- **Comprehensive Testing** with >80% coverage target
- **Performance Monitoring** built into all services
- **Structured Logging** with multiple severity levels

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- OpenAI API key
- Supabase account (for sync features)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/LifeManager.git
cd LifeManager
```

2. **Configure API keys**
```bash
cp config.txt.template config.txt
# Edit config.txt with your API keys:
# OPENAI_API_KEY=your-key-here
# SUPABASE_URL=your-url-here
# SUPABASE_ANON_KEY=your-key-here
```

3. **Build and install**
```bash
# Quick install to /Applications
./build_and_install.sh

# Or build and run directly
./run.sh
```

### Database Setup

Apply the enhanced brain dump tables migration:
```bash
./apply_migration_tables.sh
# Follow instructions to apply via Supabase dashboard
```

## 🧪 Testing

### Run Tests
```bash
# All tests
swift test

# Specific test suite
swift test --filter LifeManagerTests

# With coverage
swift test --enable-code-coverage
```

### Test Brain Dump Processing
```bash
# Test enhanced processor
./scripts/test_enhanced_brain_dump.sh

# Test complex scenarios
./scripts/test_complex_brain_dump.sh
```

## 📊 Performance & Monitoring

### Real-time Monitoring
```bash
# Monitor logs with color coding
./monitor_logs.sh -f

# Filter by severity
./monitor_logs.sh -l ERROR

# Search specific features
./monitor_logs.sh -s "BRAIN DUMP"
```

### Performance Metrics
- **Processing Speed**: <2s for typical brain dump
- **Memory Usage**: ~50MB baseline, scales with context
- **Context Window**: Adaptive 50-200 items
- **Database Sync**: Real-time with <100ms latency

## 🔧 Development

### Building from Source
```bash
# Clean build
swift package clean
swift build --configuration release

# Development build with debugging
swift build --configuration debug
```

### Code Organization Rules
- Services: Max 500 lines
- Views: Max 300 lines  
- Utilities: Max 200 lines
- Mandatory refactoring when limits exceeded

### Commit Standards
```bash
# Use conventional commits
git commit -m "feat: add calendar integration"
git commit -m "fix: resolve memory leak in context window"
git commit -m "refactor: split ContextMemoryService into focused services"

# NEVER include:
# - AI assistant references
# - Emojis in commit messages
# - Marketing language
```

## 🤝 MCP Servers Integration

LifeManager includes Model Context Protocol (MCP) servers for enhanced capabilities:

- **filesystem**: File system operations
- **git**: Repository management
- **memory**: Knowledge graph storage
- **sequential-thinking**: Step-by-step reasoning
- **time**: Time utilities
- **brain-dump**: Custom complex note processor

Setup MCP servers:
```bash
./setup_additional_mcps.sh
```

## 📈 Roadmap

### v2.0 - Intelligence Expansion (Current)
- ✅ Enhanced brain dump processing
- ✅ Context memory system refactoring
- ✅ Database migration for complex data types
- 🚧 Advanced AI decision engine
- 🚧 Learning system implementation

### v2.5 - Automation & Integration
- Calendar bi-directional sync
- Email integration
- Voice input support
- Mobile companion app

### v3.0 - Predictive Intelligence
- Proactive task suggestions
- Pattern-based automation
- Collaborative features
- API for third-party integrations

## 📚 Documentation

- [Architecture Guide](./ARCHITECTURE.md) - Technical deep dive
- [API Documentation](./docs/api/README.md) - Service interfaces
- [User Guide](./docs/guides/user_guide.md) - Feature walkthroughs
- [Development Guide](./CLAUDE.md) - Coding standards and practices

## 🛠️ Troubleshooting

### Common Issues

**Build fails with Swift version error**
```bash
# Check Swift version
swift --version
# Update Xcode if needed
```

**Database connection issues**
```bash
# Verify Supabase credentials
curl -X GET "YOUR_SUPABASE_URL/rest/v1/" \
  -H "apikey: YOUR_ANON_KEY"
```

**High memory usage**
```bash
# Adjust context window size in settings
# Default: 100 items, Range: 50-200
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Development Process
1. Fork the repository
2. Create a feature branch
3. Follow code standards in CLAUDE.md
4. Write tests for new features
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for GPT-4 and embedding models
- Supabase for real-time database infrastructure
- The PARA Method by Tiago Forte
- Swift community for excellent packages

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/LifeManager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/LifeManager/discussions)
- **Email**: support@lifemanager.app

---

**Built with ❤️ for people who think in chaos but need to live in order**