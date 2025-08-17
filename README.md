# LifeManager

**AI-Powered Personal Knowledge Management & Productivity System**

*Intelligent task management with automated organization and real-time synchronization.*

[![Version](https://img.shields.io/badge/version-v2.0.1-blue.svg)](https://github.com/anmolmanchanda/LifeManager)
[![Build Status](https://img.shields.io/badge/build-in_progress-yellow.svg)](https://github.com/anmolmanchanda/LifeManager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)

## Overview

LifeManager is a macOS application that combines natural language processing with the PARA methodology (Projects, Areas, Resources, Archives) to transform unstructured input into organized, actionable productivity systems. The application learns from user patterns and automatically categorizes, prioritizes, and schedules tasks with minimal manual intervention.

## System Requirements

- **Platform**: macOS 13.0+ (Ventura or later)
- **Swift**: 5.9+
- **Xcode**: 15.0+ (for development)
- **Dependencies**: Supabase Swift SDK 2.0+
- **Database**: PostgreSQL with Supabase
- **API Keys**: OpenAI API key required

## Quick Start

### Installation

1. Clone the repository:
```bash
git clone https://github.com/anmolmanchanda/LifeManager.git
cd LifeManager
```

2. Install dependencies:
```bash
swift package resolve
```

3. Configure API keys:
```bash
cp config.txt.template config.txt
# Edit config.txt with your OpenAI API key
```

4. Build and run:
```bash
./build_and_install.sh
# Or for development:
./run.sh
```

## Architecture

### Core Components

#### Service Layer
- **19 Core Services**: Modular, single-responsibility services
- **7 Intelligent Automation Services**: AI-powered task management
- **3 AI Processing Services**: Natural language understanding and categorization
- **Real-time Sync**: Supabase real-time subscriptions for live updates

#### Data Models
- **PARA Framework**: Projects, Areas, Resources, Archives with full audit trail
- **Task Management**: Priority-based task system with dependency tracking
- **Context Memory**: Sliding window memory management for AI processing
- **Timeline Models**: Goal-centric planning with milestone tracking

#### User Interface
- **15+ SwiftUI Views**: Native macOS interface components
- **MVVM Architecture**: Clean separation of concerns
- **Real-time Updates**: Observable objects with Combine framework
- **Gesture Support**: Drag & drop, swipe actions, keyboard shortcuts

### Key Features

#### Intelligent Processing
- Natural language to structured data conversion
- Automatic PARA categorization
- Priority and deadline inference
- Semantic similarity matching with embeddings
- Personal rule learning and pattern recognition

#### Task Automation
- Automatic rescheduling of overdue tasks
- Dependency-aware scheduling
- Buffer time management
- Conflict detection and resolution
- Multi-factor optimization scoring

#### Proactive Assistance
- Context-aware notifications
- Daily/weekly/monthly summaries
- Stagnant task detection
- Achievement tracking
- Focus session management

## Development

### Building from Source

```bash
# Clean build
swift package clean
swift build --configuration release

# Run tests
swift test --parallel

# Build application bundle
./build_app.sh
```

### Development Commands

```bash
# Monitor logs in real-time
./monitor_logs.sh -f

# Filter logs by level
./monitor_logs.sh -l ERROR

# Run specific tests
swift test --filter LifeManagerTests
```

### Project Structure

```
LifeManager/
├── Sources/
│   └── LifeManager/
│       ├── Models/          # Data models and structures
│       ├── Services/        # Business logic and AI services
│       ├── Views/           # SwiftUI user interface
│       ├── ViewModels/      # View state management
│       └── Repositories/    # Data access layer
├── Tests/                   # Unit and integration tests
├── docs/                    # Documentation
└── supabase/               # Database migrations
```

### Contributing

Please read [DEVELOPMENT_STANDARDS.md](DEVELOPMENT_STANDARDS.md) for our development guidelines:

1. Create feature branch from dev: `feature/JIRA-XXX-description`
2. Follow Swift style guide and naming conventions
3. Maintain 90% test coverage minimum
4. Update documentation for public APIs
5. Pass all quality gates before merge

## Configuration

### Environment Variables

- `OPENAI_API_KEY`: Required for AI processing
- `SUPABASE_URL`: Database connection URL
- `SUPABASE_ANON_KEY`: Database anonymous key

### Database Setup

1. Create Supabase project at [supabase.com](https://supabase.com)
2. Run migrations from `supabase/migrations/`
3. Configure connection in `config.txt`

## Testing

```bash
# Run all tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Test specific components
python3 test_llm_integration.py
python3 test_embeddings_integration.py
python3 test_intelligent_automation.py
```

## Troubleshooting

### Common Issues

1. **Build Errors**: Run `swift package update` to resolve dependency issues
2. **API Errors**: Verify OpenAI API key is valid and has sufficient credits
3. **Database Connection**: Check Supabase URL and keys in configuration
4. **Permission Issues**: Ensure app has necessary macOS permissions

### Debug Mode

Enable detailed logging:
```bash
./monitor_logs.sh -f -l DEBUG
```

## Performance

- **AI Response Time**: <100ms average
- **Database Queries**: Optimized with indexes
- **Memory Management**: Automatic cleanup with 50MB limits
- **Caching**: LRU cache for embeddings and API responses

## Security

- **Local-First**: All processing happens on device
- **Encrypted Storage**: Sensitive data encrypted at rest
- **API Key Management**: Secure keychain storage
- **Audit Trail**: Complete history of all operations

## License

MIT License - See [LICENSE](LICENSE) file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/anmolmanchanda/LifeManager/issues)
- **Documentation**: [docs/](docs/) directory
- **Logs**: `~/Library/Application Support/LifeManager/Logs/`

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and updates.

### Latest: v2.0.1 (2025-08-17)
- Fixed compilation infrastructure issues
- Enhanced development standards
- Improved type system compatibility
- Reduced build errors by 440+

### v2.0.0 (2025-06-22)
- Complete architecture overhaul
- Timeline and Focus view implementations
- Intelligent automation services
- Production-ready release