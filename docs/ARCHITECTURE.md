# LifeManager Architecture Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Principles](#architecture-principles)
3. [Layer Architecture](#layer-architecture)
4. [Service Architecture](#service-architecture)
5. [Data Flow](#data-flow)
6. [Database Schema](#database-schema)
7. [AI Integration](#ai-integration)
8. [Performance Optimization](#performance-optimization)
9. [Security Architecture](#security-architecture)

## System Overview

LifeManager is built using a **layered MVVM architecture** with clear separation of concerns and dependency injection patterns. The system is designed for scalability, maintainability, and testability.

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface Layer                  │
│                     (SwiftUI Views)                      │
├─────────────────────────────────────────────────────────┤
│                    ViewModel Layer                       │
│              (MainViewModel, PARAViewModel)              │
├─────────────────────────────────────────────────────────┤
│                     Service Layer                        │
│     (Business Logic, AI Processing, Data Access)        │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                          │
│           (Supabase, Local Storage, Cache)              │
└─────────────────────────────────────────────────────────┘
```

## Architecture Principles

### 1. Single Responsibility Principle (SRP)
Each service handles ONE specific domain:
- `LLMService` → AI/LLM operations only
- `SupabaseService` → Database operations only
- `CalendarService` → Calendar management only

### 2. Dependency Injection
Services use singleton pattern with clear dependencies:
```swift
class ServiceA {
    static let shared = ServiceA()
    private let dependencyB = ServiceB.shared
    private let dependencyC = ServiceC.shared
}
```

### 3. Observable Pattern
All services extend `ObservableObject` for reactive UI updates:
```swift
class MyService: ObservableObject {
    @Published var state: State = .idle
    @Published var data: [DataType] = []
}
```

### 4. Clean Code Standards
- **File Size Limits**: Max 500 lines for services
- **Method Complexity**: Cyclomatic complexity < 10
- **Clear Naming**: Descriptive, self-documenting code

## Layer Architecture

### 1. Presentation Layer (Views)
```
Views/
├── ContentView.swift          # Main app interface
├── BrainDumpView.swift       # Brain dump input interface
├── PARAItemsView.swift       # PARA items display
├── CalendarView.swift        # Calendar integration
└── SettingsView.swift        # App configuration
```

**Responsibilities:**
- UI rendering and user interaction
- Data binding to ViewModels
- Navigation management
- No business logic

### 2. ViewModel Layer
```
ViewModels/
├── MainViewModel.swift              # Central app state (3,125 lines - needs refactoring)
├── ContextualPARAViewModel.swift   # PARA methodology logic
└── CalendarViewModel.swift         # Calendar-specific state
```

**Responsibilities:**
- UI state management
- Business logic orchestration
- Service coordination
- Data transformation for views

### 3. Service Layer

#### Context Memory System (Refactored)
```
Services/Context/
├── ActivityPatternService.swift      # 195 lines - User behavior tracking
├── ContextWindowManager.swift        # 219 lines - Sliding window management
├── SummaryGenerationService.swift    # 261 lines - Summary generation
├── ContextPersistenceService.swift   # 206 lines - Database operations
├── ContextQueryService.swift         # 227 lines - Search capabilities
└── ContextMemoryCoordinator.swift    # 186 lines - Facade coordinator
```

#### AI Services
```
Services/AI/
├── LLMService.swift                  # 1,693 lines - OpenAI integration
├── EmbeddingsService.swift           # Vector embeddings for semantic search
├── EnhancedBrainDumpProcessor.swift # 709 lines - Complex note processing
└── ContextualPARAEngine.swift       # PARA categorization engine
```

#### Data Services
```
Services/Data/
├── SupabaseService.swift            # 492 lines - Database operations
├── CalendarOrchestrationService.swift # Smart scheduling
└── PersonalRulesService.swift      # User preferences
```

### 4. Model Layer
```
Models/
├── CoreModels.swift         # User, Task, Project entities
├── PARAModels.swift        # PARA framework models
├── ContextModels.swift     # Context memory types
├── CalendarModels.swift    # Calendar-related models
└── ContentModels.swift     # Content type definitions
```

## Service Architecture

### Context Memory System Architecture

The refactored context memory system follows the **Facade Pattern**:

```
                ContextMemoryCoordinator (Facade)
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
ActivityPatternService  ContextWindowManager  SummaryGenerationService
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                 ┌──────────┴──────────┐
         ContextPersistenceService  ContextQueryService
```

**Benefits:**
- Clear separation of concerns
- Independent testing of each service
- Easy to extend or modify individual components
- Reduced coupling between services

### Service Communication Pattern

Services communicate through:
1. **Direct Dependencies** for tightly coupled operations
2. **Combine Publishers** for reactive updates
3. **Async/Await** for asynchronous operations
4. **Notifications** for loosely coupled events

Example:
```swift
class ContextMemoryCoordinator {
    private let windowManager = ContextWindowManager()
    private let activityService = ActivityPatternService()
    
    func addToContext(_ items: [PARAItem]) async {
        await windowManager.addItems(items)
        await activityService.updatePatterns(with: items)
    }
}
```

## Data Flow

### Brain Dump Processing Flow

```
User Input → BrainDumpView
    ↓
MainViewModel.processBrainDump()
    ↓
EnhancedBrainDumpProcessor.processComplexNotes()
    ↓
┌─────────────────┬─────────────────┬─────────────────┐
│   Segmentation  │  O1 Reasoning   │  GPT-4 Extract  │
└─────────────────┴─────────────────┴─────────────────┘
    ↓
StructuredBrainDumpData
    ↓
┌─────────────────┬─────────────────┬─────────────────┐
│  Save to DB     │ Update Context  │  Generate UI    │
└─────────────────┴─────────────────┴─────────────────┘
```

### Real-time Sync Flow

```
Local Change → SupabaseService
    ↓
Supabase Database
    ↓
Real-time Subscription
    ↓
Other Devices → UI Update
```

## Database Schema

### Core Tables
```sql
-- Users and authentication
users (id, email, created_at, work_personal_default)

-- PARA methodology tables
projects (id, user_id, title, description, status, deadline)
areas (id, user_id, title, description, priority)
resources (id, user_id, title, content, tags)
archives (id, user_id, original_type, original_id, archived_at)

-- Task management
tasks (id, user_id, project_id, title, priority, due_date, completed)

-- Content storage
blobs (id, user_id, content, type, metadata, created_at)
```

### Enhanced Brain Dump Tables
```sql
-- Health and medical
health_logs (id, condition, symptoms[], severity, medications[])
medication_tracking (id, name, dosage, frequency, time_of_day[])

-- Personal organization
personal_rules (id, rule_text, category, start_date, end_date)
goals (id, title, target_date, progress, milestones)
schedules (id, title, time_blocks, recurrence_pattern)

-- Contacts and appointments
contacts (id, name, relationship, phone, email)
appointments (id, title, date, type, location)

-- Financial tracking
financial_entries (id, description, amount, category, date)

-- Context memory
context_window (id, title, content, category, timestamp)
daily_summaries (id, date, projects[], tasks_completed, items)
activity_patterns (id, patterns, peak_hours[], updated_at)
```

## AI Integration

### LLM Service Architecture

```
LLMService
├── Model Selection
│   ├── GPT-4 Turbo (general processing)
│   ├── GPT-4o (fast responses)
│   └── o1-preview (complex reasoning)
├── Prompt Management
│   ├── System prompts
│   ├── User context injection
│   └── Response parsing
└── Cost Optimization
    ├── Token counting
    ├── Model fallback
    └── Caching strategy
```

### Embeddings Architecture

```
EmbeddingsService
├── Vector Generation
│   └── OpenAI text-embedding-3-large
├── Similarity Search
│   ├── Cosine similarity
│   └── Threshold filtering
└── Caching Layer
    ├── In-memory cache
    └── Database persistence
```

## Performance Optimization

### 1. Context Window Management
- **Adaptive Sizing**: 50-200 items based on activity
- **Sliding Window**: FIFO with age-based pruning
- **Memory Footprint**: ~1KB per item + overhead

### 2. Database Optimization
- **Batch Operations**: Insert/update multiple records
- **Indexed Queries**: Strategic index placement
- **Connection Pooling**: Reuse database connections

### 3. AI Processing Optimization
- **Model Selection**: Use appropriate model for task complexity
- **Token Management**: Optimize prompt length
- **Parallel Processing**: Concurrent API calls where possible

### 4. Caching Strategy
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Memory     │ --> │   Disk      │ --> │  Database   │
│   Cache     │     │   Cache     │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
   (< 1ms)            (< 10ms)            (< 100ms)
```

## Security Architecture

### 1. Authentication & Authorization
- **Supabase Auth**: JWT-based authentication
- **Row Level Security**: Database-enforced access control
- **API Key Management**: Secure storage in Keychain

### 2. Data Protection
- **Encryption at Rest**: Database encryption
- **Encryption in Transit**: TLS/SSL for all connections
- **Local Storage**: FileVault encryption on macOS

### 3. Privacy Considerations
- **Data Minimization**: Only collect necessary data
- **User Control**: Full data export/deletion capabilities
- **Audit Logging**: Track all data access and modifications

## Testing Architecture

### Unit Testing Strategy
```
Tests/
├── Services/          # Service layer tests
│   ├── ContextMemoryTests/
│   ├── LLMServiceTests/
│   └── SupabaseServiceTests/
├── ViewModels/        # ViewModel tests
└── Models/           # Model validation tests
```

### Integration Testing
- **API Integration**: Mock servers for external services
- **Database Integration**: Test database for CI/CD
- **End-to-End**: User journey testing

### Performance Testing
- **Load Testing**: Simulate high-volume operations
- **Memory Profiling**: Identify leaks and optimize usage
- **Response Time**: Measure and optimize critical paths

## Deployment Architecture

### Local Development
```bash
# Development server
swift run --configuration debug

# Local testing
swift test --parallel
```

### Production Build
```bash
# Optimized release build
swift build --configuration release

# Code signing and notarization
./build_and_install.sh
```

### Monitoring & Observability
- **Structured Logging**: Multiple severity levels
- **Performance Metrics**: Response times, memory usage
- **Error Tracking**: Comprehensive error reporting
- **User Analytics**: Anonymous usage statistics

## Future Architecture Considerations

### Scalability Plans
1. **Microservices Migration**: Split monolith into services
2. **API Gateway**: Centralized API management
3. **Message Queue**: Async processing with RabbitMQ/Kafka
4. **Horizontal Scaling**: Multi-instance deployment

### Technology Considerations
1. **SwiftUI → UIKit**: For complex UI requirements
2. **CoreData Integration**: Local caching layer
3. **CloudKit Sync**: Apple ecosystem integration
4. **Watch/iOS Apps**: Companion applications

---

This architecture provides a solid foundation for building a scalable, maintainable, and performant life management system while maintaining code quality and user experience standards.