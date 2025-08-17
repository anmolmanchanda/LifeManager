# LifeManager Development Patterns

## Service Architecture
Services follow consistent patterns across the codebase:

1. **Singleton Pattern**: Most services use `static let shared` for global access
2. **Dependency Injection**: Services reference other services via shared instances
3. **Observable Objects**: All services extend `ObservableObject` for SwiftUI integration
4. **Async/Await**: Modern concurrency patterns for database and API operations
5. **Intelligent Automation**: AI-powered decision making with user control and transparency

### Example Service Structure
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

## Error Handling
- Comprehensive error handling throughout all services
- User-friendly error messages with actionable guidance
- Detailed logging with structured levels (DEBUG, INFO, WARN, ERROR, SUCCESS, PROGRESS)
- Custom error types for domain-specific failures

## Database Integration Patterns
SupabaseService provides generic CRUD operations:
```swift
// Generic insert with automatic JSON handling
func insert<T: Codable>(_ record: T, into table: String) async throws -> T

// Generic fetch with type safety
func fetch<T: Codable>(_ type: T.Type, from table: String) async throws -> [T]

// Filtered queries with work/personal separation
func fetchByWorkPersonal<T: Codable>(_ type: T.Type, from table: String, workPersonal: WorkPersonalType) async throws -> [T]
```

## AI Integration

### Modular LLM Service Architecture
The LLM service has been decomposed into focused, coordinated services:

- **LLMServiceCoordinator**: Central coordinator maintaining backward compatibility
- **LLMConfigurationService**: API key management and provider selection
- **LLMPromptService**: Template management and prompt generation
- **LLMCommunicationService**: Direct API communication with rate limiting
- **LLMProcessingService**: High-level AI workflows and result parsing

### AI Processing Features
- **Natural Language Processing**: Brain dump text → structured PARA items
- **Task Extraction**: Automatic detection of actionable items with priorities
- **Content Categorization**: Intelligent classification into Projects/Areas/Resources/Archives
- **Embeddings**: Semantic similarity with memory management and caching
- **Context Memory**: Active sliding window with summarized history

### Memory Management for AI Services
Production-ready memory management patterns implemented across all AI services:

**EmbeddingsService**: Complete LRU caching with 100MB limits and automatic cleanup
**ContextMemoryService**: 50MB memory bounds with LRU context window management  
**PersonalRulesService**: Rule and correction caching with configurable retention policies

```swift
// Memory bounds with automatic cleanup (example from ContextMemoryService)
private var maxMemoryUsage: Int = 50_000_000 // 50MB limit
private var lastMemoryCleanup: Date = Date()
private let memoryCleanupInterval: TimeInterval = 3600 // 1 hour

// LRU cache management with MainActor safety
private func performMemoryCleanup() async {
    await MainActor.run {
        // Sort by last accessed time (most recent first)
        activeContextWindow.sort { $0.lastAccessed > $1.lastAccessed }
        // Keep only the most recent items
        activeContextWindow = Array(activeContextWindow.prefix(currentWindowSize))
    }
}
```

## Real-time Features
- **Live Data Updates**: Supabase real-time subscriptions across all views
- **Calendar Synchronization**: Real-time event updates and conflict resolution
- **Cross-View Consistency**: Changes propagate immediately across all UI components

## Logging System
Production-ready structured logging system with comprehensive coverage:

1. **Centralized Logger**: `Logger.shared` for structured logging across all services
2. **Categorical Logging**: `LifeLogger` for specific domains (calendar, database, UI)
3. **Performance Tracking**: `PerformanceTimer` for operation timing
4. **File-based Logging**: Persistent logs in `~/Library/Application Support/LifeManager/Logs/`

### Logging Standards
Debug prints have been systematically replaced with proper Logger calls across the codebase:
- **Context-aware logging**: Each service uses appropriate categories (e.g., "EMBEDDINGS:", "CONTEXT_MEMORY:", "PERSONAL_RULES:")
- **Proper log levels**: Categorized by severity and purpose rather than generic info  
- **Consistent formatting**: Structured messages for easy parsing and monitoring
- **Production-ready**: All major services and ViewModels use Logger.shared with proper dependencies

### Example Logging Patterns
```swift
// Service initialization
Logger.shared.info("SERVICE_NAME: Service initialized")

// Successful operations
Logger.shared.success("SERVICE_NAME: Operation completed successfully")

// Errors with context
Logger.shared.error("SERVICE_NAME: Failed to process data: \(error)")

// Performance tracking
Logger.shared.debug("SERVICE_NAME: Processing \(count) items took \(duration)ms")
```

## Development Standards
- **Production Quality**: Minimal technical debt (8 non-critical TODOs, all feature enhancements)
- **Comprehensive Logging**: Structured logging with Logger.shared across all services
- **Test Coverage**: Unit tests for all core functionality
- **Documentation**: Inline documentation with roadmap traceability
- **Memory Management**: Production-ready bounds and cleanup in all AI services
- **Service Architecture**: Modular design with backward compatibility maintained
- **Code Quality Linting**: Automated checks prevent debug prints and enforce standards

### Code Quality Enforcement
```bash
# Run lint checks manually
./lint_check.sh

# Install pre-commit hook (optional)
cp pre-commit-hook.template .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

The linting system automatically checks for:
- Debug print statements (prevents regression)
- NSLog statements (enforces Logger usage)
- Missing Logger dependencies in services
- TODO count monitoring

## UI Development Patterns
- **MVVM Separation**: Keep business logic in ViewModels and Services
- **State Management**: Use `@Published` properties for reactive UI updates
- **Navigation**: Centralize navigation state in MainViewModel
- **Error Display**: Show user-friendly error messages with actionable guidance

## Authentication & User Experience (v2.0)

### System Integration Improvements
- **No System Password Prompts**: Eliminated permission dialogs on app launch
  - Implementation: Conditionally compiled `startLogMonitoring()` with `#if DEBUG`
  - File: `Sources/LifeManager/ViewModels/MainViewModel.swift:57`

- **No Documents Folder Access**: All data stored in secure app container
  - Implementation: Changed from `documentDirectory` to `applicationSupportDirectory`
  - File: `Sources/LifeManager/Services/Logger.swift:applicationSupportPath`

### Production UI Cleanup
- **Clean Production Interface**: Development artifacts conditionally compiled
  - Implementation: `#if DEBUG` guards around development controls
  - File: `Sources/LifeManager/Views/AuthenticationView.swift:82-186`

- **Persistent Sessions**: Users stay logged in across app restarts
  - Implementation: Proper Supabase session management with keychain storage

### Authentication Architecture
```swift
// Production: Clean, no system prompts
#if DEBUG
startLogMonitoring() // Only in development builds
#endif

// Secure app container storage (no Documents folder access)
let applicationSupportPath = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

// Conditional UI: Development controls only in debug builds
#if DEBUG
VStack {
    // Development authentication bypass
    // Testing controls and debugging tools
}
#endif
```