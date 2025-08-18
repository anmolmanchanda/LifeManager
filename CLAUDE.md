# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CRITICAL: COMMIT MESSAGE REQUIREMENTS

**ABSOLUTELY FORBIDDEN IN COMMITS:**
- Never use "Claude" or "Anthropic" in commit messages
- Never use emojis in commit messages  
- Never reference AI assistance in commits
- Keep commits professional and technical only
- Use conventional commit format without decorations

## Code Organization Standards

### File Size Limits
- **MAXIMUM 500 lines per file** for services and view models
- **MAXIMUM 300 lines per file** for views and UI components
- **MAXIMUM 200 lines per file** for utility classes
- Files exceeding these limits MUST be refactored

### Service Architecture Rules
- **Single Responsibility**: Each service handles ONE concern only
- **Dependency Injection**: Use protocols for testability
- **Clear Naming**: ServiceNameService.swift pattern
- **Separate Concerns**: Data, Business Logic, and UI must be separated

### When to Refactor
- File exceeds line limits
- Service has more than 5 public methods
- Class has more than 3 dependencies
- Cyclomatic complexity exceeds 10

## Development Commands

### Building and Running
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

### Testing
```bash
# Run all Swift tests
swift test

# Run tests in parallel
swift test --parallel

# Run specific test files
swift test --filter LifeManagerTests
swift test --filter EmbeddingsServiceTests
```

### Monitoring and Debugging
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

### Python Test Scripts
```bash
# Test LLM integration
python3 test_llm_integration.py

# Test embeddings integration
python3 test_embeddings_integration.py

# Test contextual PARA processing
python3 test_contextual_para_processing.py

# Comprehensive feature testing
python3 test_comprehensive_features.py
```

## Architecture Overview

### Core Design Pattern
- **MVVM Architecture**: Strict separation between Views, ViewModels, and Models
- **Service-Oriented**: Business logic encapsulated in dedicated service classes
- **Real-time Sync**: Supabase real-time subscriptions for live data updates
- **AI-Powered**: LLM integration for natural language processing and PARA categorization
- **Clean Architecture**: Refactored services follow Single Responsibility Principle

### Key Components

#### Services Layer (`Sources/LifeManager/Services/`)

**AI Services:**
- **LLMService**: OpenAI/Claude API integration for AI processing (1,693 lines)
- **EmbeddingsService**: OpenAI embeddings for semantic search and similarity
- **EnhancedBrainDumpProcessor**: Complex note processing with o1 reasoning (709 lines)
- **ContextualPARAEngine**: AI-powered PARA categorization engine

**Context Memory System (Refactored from 987 lines to 6 focused services):**
- **ActivityPatternService**: User behavior tracking (195 lines)
- **ContextWindowManager**: Sliding window management (219 lines)
- **SummaryGenerationService**: Daily/weekly/monthly summaries (261 lines)
- **ContextPersistenceService**: Database operations (206 lines)
- **ContextQueryService**: Search and queries (227 lines)
- **ContextMemoryCoordinator**: Facade coordinator (186 lines)

**Data & Integration Services:**
- **SupabaseService**: Database operations and authentication (492 lines)
- **CalendarOrchestrationService**: Intelligent scheduling with buffer management
- **TogglService**: Time tracking integration (614 lines)
- **PersonalRulesService**: User preference and rule management
- **NotificationService**: Smart notifications and decision modals

#### ViewModels (`Sources/LifeManager/ViewModels/`)
- **MainViewModel**: Central app state and navigation coordinator (3,125 lines)
- **CalendarViewModel**: Calendar-specific state management
- **ContextualPARAViewModel**: PARA methodology implementation

#### Models (`Sources/LifeManager/Models/`)
- **CoreModels**: User, Task, Project, Area, Resource, Archive entities
- **PARAModels**: PARA framework-specific data structures
- **ContentModels**: Blob and content type definitions
- **ContextualPARAModels**: AI-enhanced PARA categorization models
- **CalendarModels**: Event, scheduling, and calendar-related models

### Database Architecture
- **PostgreSQL + Supabase**: 18+ core tables with real-time subscriptions
- **Migration System**: Structured schema evolution in `supabase/migrations/`
- **PARA Framework**: Projects, Areas, Resources, Archives with full audit trail
- **Embeddings Support**: Vector storage for semantic search capabilities

### Configuration System
- **API Keys**: Template-based setup with `config.txt.template`
- **Environment Variables**: OPENAI_API_KEY, SUPABASE_URL, CLAUDE_API_KEY
- **Development Mode**: Built-in dev account (`dev@lifemanager.local`)

## Key Development Patterns

### Service Architecture
Services follow consistent patterns across the codebase:

1. **Singleton Pattern**: Most services use `static let shared` for global access
2. **Dependency Injection**: Services reference other services via shared instances
3. **Observable Objects**: All services extend `ObservableObject` for SwiftUI integration
4. **Async/Await**: Modern concurrency patterns for database and API operations

Example service structure:
```swift
class MyService: ObservableObject {
    static let shared = MyService()
    
    // Dependencies
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // Published state
    @Published var isProcessing = false
    @Published var data: [DataType] = []
    
    private init() {
        // Initialize service
    }
    
    // Public methods with error handling
    func performOperation() async throws -> Result {
        // Implementation with logging
    }
}
```

### Error Handling
- Comprehensive error handling throughout all services
- User-friendly error messages with actionable guidance
- Detailed logging with structured levels (DEBUG, INFO, WARN, ERROR, SUCCESS, PROGRESS)
- Custom error types for domain-specific failures

### Database Integration Patterns
SupabaseService provides generic CRUD operations:
```swift
// Generic insert with automatic JSON handling
func insert<T: Codable>(_ record: T, into table: String) async throws -> T

// Generic fetch with type safety
func fetch<T: Codable>(_ type: T.Type, from table: String) async throws -> [T]

// Filtered queries with work/personal separation
func fetchByWorkPersonal<T: Codable>(_ type: T.Type, from table: String, workPersonal: WorkPersonalType) async throws -> [T]
```

### AI Integration
- **Natural Language Processing**: Brain dump text → structured PARA items
- **Task Extraction**: Automatic detection of actionable items with priorities
- **Content Categorization**: Intelligent classification into Projects/Areas/Resources/Archives
- **Embeddings**: Semantic similarity for contextual PARA placement

### Real-time Features
- **Live Data Updates**: Supabase real-time subscriptions across all views
- **Calendar Synchronization**: Real-time event updates and conflict resolution
- **Cross-View Consistency**: Changes propagate immediately across all UI components

### Logging System
Comprehensive logging with multiple approaches:

1. **Centralized Logger**: `Logger.shared` for structured logging
2. **Categorical Logging**: `LifeLogger` for specific domains (calendar, database, UI)
3. **Performance Tracking**: `PerformanceTimer` for operation timing
4. **File-based Logging**: Persistent logs in `~/Documents/LifeManager/Logs/`

Log levels and usage:
- **DEBUG**: Development information, API responses
- **INFO**: General application flow
- **WARN**: Recoverable errors, fallback usage
- **ERROR**: Serious errors requiring attention
- **SUCCESS**: Completed operations, achievements
- **PROGRESS**: Long-running operation updates

### Development Standards
- **Production Quality**: No TODOs or placeholders in shipped code
- **Comprehensive Logging**: Detailed logging for debugging and monitoring
- **Test Coverage**: Unit tests for all core functionality
- **Documentation**: Inline documentation with roadmap traceability

## Testing Strategy
- **Unit Tests**: Core services and business logic (see `Tests/LifeManagerTests/`)
- **Integration Tests**: LLM processing, database operations, calendar features
- **Manual Testing**: UI interactions, drag & drop, real-time updates
- **API Monitoring**: Direct OpenAI API testing with usage tracking

## Common Development Tasks

### Adding New PARA Item Types
1. Update `ContentModels.swift` with new enum values
2. Create database migration in `supabase/migrations/`
3. Update LLM prompts in `prompts/templates/`
4. Add UI support in relevant view components
5. Update tests to cover new functionality

### Integrating New LLM Providers
1. Extend `LLMService.swift` with new provider configuration
2. Add API client implementation following existing patterns
3. Update prompt templates for provider-specific formatting
4. Add comprehensive error handling and logging
5. Create tests for new provider integration

### Adding New Services
When creating new services, follow the established patterns:

1. **Service Structure**:
   ```swift
   class NewService: ObservableObject {
       static let shared = NewService()
       
       // Dependencies
       private let supabaseService = SupabaseService.shared
       private let logger = Logger.shared
       
       // Published state
       @Published var isLoading = false
       @Published var data: [DataType] = []
       
       private init() {
           // Initialization
       }
   }
   ```

2. **Error Handling**: Create custom error types and provide meaningful messages
3. **Logging**: Use appropriate log levels and categories
4. **Testing**: Add unit tests in `Tests/LifeManagerTests/`
5. **Documentation**: Add inline documentation explaining purpose and usage

### Adding Calendar Features
1. Update `CalendarModels.swift` for new data structures
2. Implement business logic in `CalendarOrchestrationService.swift`
3. Add UI components in `Views/Calendar/` directory
4. Update `CalendarViewModel.swift` for state management
5. Test drag & drop and scheduling functionality

### Database Schema Changes
1. Create migration file in `supabase/migrations/`
2. Update corresponding model in `Sources/LifeManager/Models/`
3. Update repository methods if needed
4. Test migration in development environment
5. Update any affected services or views

### API Integration Patterns
When adding new API integrations:

1. **Configuration**: Add API keys to `config.txt.template`
2. **Service Layer**: Create dedicated service following singleton pattern
3. **Error Handling**: Implement comprehensive error handling with user-friendly messages
4. **Caching**: Consider caching strategies for expensive operations
5. **Testing**: Add integration tests and monitoring scripts

### UI Development Patterns
- **MVVM Separation**: Keep business logic in ViewModels and Services
- **State Management**: Use `@Published` properties for reactive UI updates
- **Navigation**: Centralize navigation state in MainViewModel
- **Error Display**: Show user-friendly error messages with actionable guidance

## Platform Requirements
- **macOS**: 13.0+ (Ventura or later)
- **Swift**: 5.9+
- **Dependencies**: Supabase Swift SDK (2.0.0+)
- **APIs**: OpenAI API key required, Claude API key optional

## Configuration Management
- **Template System**: Use `config.txt.template` for setup instructions
- **Environment Variables**: Support for OPENAI_API_KEY, SUPABASE_URL, CLAUDE_API_KEY
- **Multi-path Loading**: API keys loaded from multiple potential locations
- **Security**: Config files automatically ignored by git

## Debugging and Monitoring
- **Real-time Monitoring**: `./monitor_logs.sh -f` for live log following
- **Filtered Logging**: Use level and search filters for targeted debugging
- **Performance Tracking**: Built-in timing for database and API operations
- **Error Tracking**: Comprehensive error logging with context information

This architecture provides a solid foundation for building and extending LifeManager's functionality while maintaining code quality, testability, and user experience.