# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 MANDATORY: ENTERPRISE DEVELOPMENT STANDARDS

**CRITICAL REQUIREMENT**: Before making ANY changes to this codebase, you MUST read and follow the [DEVELOPMENT_STANDARDS.md](./DEVELOPMENT_STANDARDS.md) document. This repository operates under enterprise-grade development practices with ZERO TOLERANCE for:

- Code loss or accidental deletions
- Direct commits to main/dev branches  
- Unreviewed changes to production code
- Missing tests or documentation
- Non-compliant commit messages

**EVERY CHANGE MUST:**
1. **Create a feature branch** from dev
2. **Follow naming convention**: `feature/JIRA-XXX-description`
3. **Include comprehensive tests** (90% coverage minimum)
4. **Update documentation** for any public APIs
5. **Pass all quality gates** before merge
6. **Use conventional commit format**

**NEVER:**
- Make direct changes to main or dev branches
- Commit without running tests first
- Skip code review processes  
- Leave code in broken state
- Remove or modify large amounts of code without explicit approval

See [DEVELOPMENT_STANDARDS.md](./DEVELOPMENT_STANDARDS.md) for complete guidelines.

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

# Test intelligent automation system
python3 test_intelligent_automation.py

# Test AI learning and orchestration
python3 test_ai_learning_orchestration.py
```

### Intelligent Automation Commands
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

## Architecture Overview

### Core Design Pattern
- **MVVM Architecture**: Strict separation between Views, ViewModels, and Models
- **Service-Oriented**: Business logic encapsulated in dedicated service classes
- **Real-time Sync**: Supabase real-time subscriptions for live data updates
- **AI-Powered**: LLM integration for natural language processing and PARA categorization
- **Intelligent Automation**: Comprehensive AI learning and cross-service orchestration
- **Production Monitoring**: Real-time performance monitoring and automatic optimization

### Key Components

#### Services Layer (`Sources/LifeManager/Services/`)

**Core AI & LLM Services:**
- **LLMServiceCoordinator**: Unified coordinator for all LLM operations (289 lines)
  - **LLMConfigurationService**: API key management and provider configuration
  - **LLMPromptService**: Template management and prompt generation  
  - **LLMCommunicationService**: Direct API communication with providers
  - **LLMProcessingService**: High-level AI processing workflows
- **EmbeddingsService**: OpenAI embeddings with memory management and caching (929 lines)
- **ContextMemoryService**: Active context memory with sliding window management
- **ContextualPARAEngine**: AI-powered PARA categorization engine
- **PersonalRulesService**: User preference and rule management

**Intelligent Automation Services:**
- **AutomationOrchestrator** (1,000+ lines): Central coordination hub for all automation services
- **AILearningEngine** (1,200+ lines): Advanced AI pattern recognition and continuous learning
- **IntelligentReschedulingService**: AI-powered task rescheduling with confidence scoring
- **AdvancedNotificationService** (871 lines): Multi-channel escalation system (SMS, email, webhook)
- **TaskDependencyService** (900+ lines): Comprehensive dependency validation and cascade analysis
- **ExternalCalendarIntegrationService** (562 lines): EventKit calendar integration with conflict detection
- **PerformanceMonitoringService** (1,000+ lines): System monitoring and automatic optimization

**Core Infrastructure Services:**
- **SupabaseService**: Database operations and authentication (492 lines)
- **CalendarOrchestrationService**: Intelligent scheduling with buffer management
- **TogglService**: Time tracking integration (614 lines)
- **NotificationService**: Smart notifications and decision modals

#### User Interface Layer (`Sources/LifeManager/Views/`)

**Intelligent Automation UI:**
- **AutomationDashboardView** (1,100+ lines): Comprehensive monitoring and control interface
- **EnhancedFocusView** (1,200+ lines): AI-powered focus view with intelligent prioritization
- **Real-time Status Monitoring**: Live system health and performance indicators
- **AI Confidence Displays**: Visual representation of AI decision confidence
- **Interactive Controls**: Service management, optimization triggers, and user feedback
- **Learning Insights Interface**: Real-time display of AI insights and patterns

**Core Application Views:**
- **MainView**: Primary application interface with navigation
- **TaskView**: Task management with PARA methodology integration
- **CalendarView**: Calendar interface with intelligent scheduling
- **SettingsView**: Configuration and automation control settings
  - User working hours and focus block integration
  - Task dependency validation and conflict prevention
  - 24-hour undo/override functionality with full audit trail
  - Multi-factor scoring: time preferences, priority alignment, calendar conflicts
- **PriorityIntelligenceEngine**: ML-based priority assessment with context awareness (642 lines)
  - Real-time priority scoring using multiple factors
  - Pattern recognition for task importance
  - Integration with rescheduling decisions
- **ProactiveNotificationEngine**: Comprehensive notification system (901 lines)
  - 10 notification types: reminders, summaries, contextual alerts, achievements
  - Customizable thresholds and user preference integration
  - Proactive nudges for stagnant tasks (3-day default)
  - Daily/weekly/monthly summary notifications

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
- **IntelligentSchedulingModels**: Task dependencies, scheduling patterns, priority intelligence (591 lines)

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

### Intelligent Task Automation Architecture (`v2.0`)

The intelligent automation system implements a comprehensive "hands-off" task management experience:

#### 1. Smart Auto-Rescheduling
```swift
// Automatic overdue task processing every 5 minutes
private let monitoringInterval: TimeInterval = 300

// AI-powered slot optimization with user preferences
let optimalSlot = await findOptimalReschedulingSlot(
    for: taskWithDeps,
    priorityIntelligence: priorityIntelligence
)

// Multi-factor scoring system
var score = calculateSlotScore(
    timePreferences: userPreferences.focusBlocks,
    priorityAlignment: priorityIntelligence.overallScore,
    calendarConflicts: conflictCheck,
    bufferAvailability: bufferCheck
)
```

#### 2. Undo/Override System
```swift
// 24-hour undo window for AI decisions
let undoableAction = UndoableReschedulingAction(
    taskId: task.id,
    originalDueDate: task.dueDate,
    newDueDate: rescheduledDate,
    expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date())
)

// User override with custom reasoning
await intelligentRescheduling.overrideRescheduling(
    taskId: task.id,
    newDueDate: userSelectedDate,
    reason: "User prefers different timing"
)
```

#### 3. Dependency-Aware Scheduling
```swift
// Validate dependencies before rescheduling
let dependencyCheck = taskWithDeps.canBeRescheduled(to: newDate)
guard dependencyCheck.canReschedule else {
    logger.debug("Slot rejected: \(dependencyCheck.reason)")
    continue
}
```

#### 4. Proactive Notification Engine
```swift
// 10 notification types with customizable thresholds
enum NotificationType {
    case overdueReminder, gentleNudge, dailySummary, weeklySummary,
         monthlyReport, reschedulingAlert, bufferWarning,
         contextualSuggestion, achievementCelebration, planningReminder
}

// Context-aware scheduling
private let gentleNudgeThreshold: TimeInterval = 259200 // 3 days
private let proactiveCheckInterval: TimeInterval = 1800 // 30 minutes
```

### Service Architecture
Services follow consistent patterns across the codebase:

1. **Singleton Pattern**: Most services use `static let shared` for global access
2. **Dependency Injection**: Services reference other services via shared instances
3. **Observable Objects**: All services extend `ObservableObject` for SwiftUI integration
4. **Async/Await**: Modern concurrency patterns for database and API operations
5. **Intelligent Automation**: AI-powered decision making with user control and transparency

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

#### Modular LLM Service Architecture
The LLM service has been decomposed into focused, coordinated services:

- **LLMServiceCoordinator**: Central coordinator maintaining backward compatibility
- **LLMConfigurationService**: API key management and provider selection
- **LLMPromptService**: Template management and prompt generation
- **LLMCommunicationService**: Direct API communication with rate limiting
- **LLMProcessingService**: High-level AI workflows and result parsing

#### AI Processing Features
- **Natural Language Processing**: Brain dump text → structured PARA items
- **Task Extraction**: Automatic detection of actionable items with priorities
- **Content Categorization**: Intelligent classification into Projects/Areas/Resources/Archives
- **Embeddings**: Semantic similarity with memory management and caching
- **Context Memory**: Active sliding window with summarized history

#### Memory Management for AI Services
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

### Real-time Features
- **Live Data Updates**: Supabase real-time subscriptions across all views
- **Calendar Synchronization**: Real-time event updates and conflict resolution
- **Cross-View Consistency**: Changes propagate immediately across all UI components

### Logging System
Production-ready structured logging system with comprehensive coverage:

1. **Centralized Logger**: `Logger.shared` for structured logging across all services
2. **Categorical Logging**: `LifeLogger` for specific domains (calendar, database, UI)
3. **Performance Tracking**: `PerformanceTimer` for operation timing
4. **File-based Logging**: Persistent logs in `~/Documents/LifeManager/Logs/`

#### Logging Standards (Phase 3 Implementation)
Debug prints have been systematically replaced with proper Logger calls across the codebase:
- **Context-aware logging**: Each service uses appropriate categories (e.g., "EMBEDDINGS:", "CONTEXT_MEMORY:", "PERSONAL_RULES:")
- **Proper log levels**: Categorized by severity and purpose rather than generic info  
- **Consistent formatting**: Structured messages for easy parsing and monitoring
- **Production-ready**: All major services and ViewModels use Logger.shared with proper dependencies

Log levels and usage:
- **DEBUG**: Development information, API responses, detailed flow tracking
- **INFO**: General application flow, service initialization, normal operations
- **WARNING**: Recoverable errors, fallback usage, configuration issues
- **ERROR**: Serious errors requiring attention, API failures, critical issues
- **SUCCESS**: Completed operations, achievements, successful API calls
- **PROGRESS**: Long-running operation updates, batch processing status

#### Example Logging Patterns
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

### Development Standards
- **Production Quality**: Minimal technical debt (8 non-critical TODOs, all feature enhancements)
- **Comprehensive Logging**: Structured logging with Logger.shared across all services
- **Test Coverage**: Unit tests for all core functionality
- **Documentation**: Inline documentation with roadmap traceability
- **Memory Management**: Production-ready bounds and cleanup in all AI services
- **Service Architecture**: Modular design with backward compatibility maintained
- **Code Quality Linting**: Automated checks prevent debug prints and enforce standards

#### Code Quality Enforcement
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
With the new modular LLM architecture:
1. Add provider configuration to `LLMConfigurationService.swift`
2. Implement communication logic in `LLMCommunicationService.swift`
3. Update prompt templates in `LLMPromptService.swift`
4. Add processing workflows in `LLMProcessingService.swift`
5. Test integration through `LLMServiceCoordinator.swift`
6. Add comprehensive error handling and logging
7. Create tests for new provider integration

**Note**: Legacy code can continue using `LLMService` type alias, but new development should use `LLMServiceCoordinator.shared` directly.

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

## Authentication & User Experience (v2.0)

### **🎯 Seamless Authentication Experience**
LifeManager v2.0 delivers a production-ready authentication experience with zero friction:

#### **System Integration Improvements**
- **✅ No System Password Prompts**: Eliminated permission dialogs on app launch
  - **Implementation**: Conditionally compiled `startLogMonitoring()` with `#if DEBUG`
  - **File**: `Sources/LifeManager/ViewModels/MainViewModel.swift:57`
  - **Impact**: App launches silently without macOS authentication dialogs

- **✅ No Documents Folder Access**: All data stored in secure app container
  - **Implementation**: Changed from `documentDirectory` to `applicationSupportDirectory`
  - **File**: `Sources/LifeManager/Services/Logger.swift:applicationSupportPath`
  - **Impact**: No permission requests for user Documents folder

#### **Production UI Cleanup**
- **✅ Clean Production Interface**: Development artifacts conditionally compiled
  - **Implementation**: `#if DEBUG` guards around development controls
  - **File**: `Sources/LifeManager/Views/AuthenticationView.swift:82-186`
  - **Impact**: Professional UI experience for production users

- **✅ Persistent Sessions**: Users stay logged in across app restarts
  - **Implementation**: Proper Supabase session management with keychain storage
  - **Impact**: Seamless user experience without repeated authentication

#### **Development vs Production Modes**
- **✅ Conditional Development Features**: Debug tools only in development builds
  - **Production Mode**: `isDevelopmentMode = false` for clean experience
  - **Development Mode**: Full debugging tools and bypass options available
  - **Build-time Compilation**: Production builds automatically exclude debug features

### **Authentication Architecture**
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

## Debugging and Monitoring
- **Real-time Monitoring**: `./monitor_logs.sh -f` for live log following
- **Filtered Logging**: Use level and search filters for targeted debugging
- **Performance Tracking**: Built-in timing for database and API operations
- **Error Tracking**: Comprehensive error logging with context information
- **Production Logging**: Logs stored in secure Application Support directory (no Documents access)

This architecture provides a solid foundation for building and extending LifeManager's functionality while maintaining code quality, testability, and user experience. The v2.0 authentication improvements deliver enterprise-grade user experience with zero friction and professional polish.