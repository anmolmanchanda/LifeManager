# LifeManager Architecture

## Overview

LifeManager is a macOS productivity application built with SwiftUI and the PARA methodology, featuring AI-powered natural language processing for task management.

## Architecture Pattern

The application follows **MVVM (Model-View-ViewModel)** architecture with service-oriented design:

```
┌─────────────────────────────────────────────────────┐
│                    Views (SwiftUI)                   │
├─────────────────────────────────────────────────────┤
│                ViewModels (ObservableObject)         │
├─────────────────────────────────────────────────────┤
│                  Services (Singleton)                │
├─────────────────────────────────────────────────────┤
│              Models (Codable Structs)                │
├─────────────────────────────────────────────────────┤
│            Database (Supabase/PostgreSQL)            │
└─────────────────────────────────────────────────────┘
```

## Core Components

### 1. Views Layer (`Sources/LifeManager/Views/`)
- **ContentView**: Main application interface
- **BrainDumpReviewView**: AI processing review interface
- **Calendar Views**: Calendar integration components
- **PARA Views**: Projects, Areas, Resources, Archives views
- **Settings Views**: Application configuration

### 2. ViewModels Layer (`Sources/LifeManager/ViewModels/`)
Refactored into focused ViewModels following single responsibility:
- **MainViewModel**: Central navigation and app state (needs further refactoring)
- **BrainDump/BrainDumpViewModel**: Brain dump processing
- **Calendar/CalendarViewModel**: Calendar state management
- **PARA/PARADataViewModel**: PARA data management
- **Settings/SettingsViewModel**: Settings and preferences

### 3. Services Layer (`Sources/LifeManager/Services/`)

#### Core Services
- **SupabaseService**: Database operations and real-time sync
- **LLMService**: OpenAI/Claude API integration
- **Logger**: Centralized logging system

#### Context Services (Refactored)
- **Context/ActivityPatternService**: User behavior tracking
- **Context/ContextWindowManager**: Sliding window management
- **Context/SummaryGenerationService**: Daily/weekly/monthly summaries
- **Context/ContextPersistenceService**: Database operations
- **Context/ContextQueryService**: Search and queries
- **Context/ContextMemoryCoordinator**: Service orchestration

#### AI Services
- **EmbeddingsService**: OpenAI embeddings for semantic search
- **ContextualPARAEngine**: AI-powered PARA categorization
- **PersonalRulesService**: User preference learning
- **LLMBrainDumpProcessor**: Natural language processing

#### Other Services
- **CalendarOrchestrationService**: Calendar integration
- **TogglService**: Time tracking integration
- **NotificationService**: Smart notifications

### 4. Models Layer (`Sources/LifeManager/Models/`)
- **CoreModels**: User, Task, Project entities
- **PARAModels**: PARA framework structures
- **ContentModels**: Blob and content types
- **CalendarModels**: Event and scheduling models
- **BrainDumpModels**: AI processing models

## Data Flow

1. **User Input** → View → ViewModel → Service
2. **Service Processing** → Database/API → Service
3. **State Updates** → Service → ViewModel → View
4. **Real-time Sync** → Supabase → Service → ViewModel

## Key Design Patterns

### Singleton Services
```swift
class ServiceName: ObservableObject {
    static let shared = ServiceName()
    private init() { }
}
```

### Observable State Management
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var state: State
}
```

### Async/Await Concurrency
```swift
func processData() async throws -> Result {
    // Modern Swift concurrency
}
```

## Database Schema

18+ PostgreSQL tables with real-time subscriptions:
- Core PARA tables: `projects`, `areas`, `resources`, `archives`
- Content tables: `blobs`, `tasks`, `items`
- Context tables: `context_items`, `summaries`, `patterns`
- System tables: `users`, `settings`, `audit_log`

## AI Integration

### LLM Processing Pipeline
1. Natural language input
2. Context retrieval
3. LLM processing (GPT-4/Claude)
4. PARA categorization
5. Personal rules application
6. Database persistence

### Embeddings System
- OpenAI text-embedding-3-large model
- Semantic similarity search
- Context-aware categorization

## Performance Considerations

- **Window Management**: Adaptive 50-200 item context window
- **Batch Processing**: Parallel processing for multiple items
- **Caching**: Strategic caching for expensive operations
- **Real-time Updates**: Efficient subscription management

## Security

- API keys stored in config files (git-ignored)
- Row-level security in database
- Secure authentication flow
- No hardcoded credentials

## Testing Strategy

- Unit tests for services and models
- Integration tests for API interactions
- UI tests for critical workflows
- Performance benchmarks for AI operations

## Technical Debt

Current areas needing refactoring:
- MainViewModel (3,125 lines) - violates single responsibility
- ContentView (3,200+ lines) - needs component extraction
- Improve test coverage (currently ~30%)

## Future Architecture Improvements

1. Further decompose MainViewModel
2. Implement dependency injection
3. Add comprehensive error handling
4. Improve test coverage to 80%+
5. Add performance monitoring
6. Implement feature flags system