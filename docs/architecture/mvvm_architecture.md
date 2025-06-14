# LifeManager MVVM Architecture Guide

## Overview

LifeManager follows a strict **MVVM (Model-View-ViewModel)** pattern with modular, production-ready SwiftUI architecture. This document outlines the architectural principles, file organization, and best practices used throughout the application.

## Architecture Principles

### 1. Strict MVVM Separation
- **Models**: Pure data structures with no business logic
- **Views**: SwiftUI views focused solely on UI presentation
- **ViewModels**: Business logic, state management, and data coordination
- **Services**: External API integration and business operations
- **Repositories**: Data access layer with clean abstractions

### 2. Modular File Organization
```
Sources/LifeManager/
├── App/                    # App lifecycle and configuration
├── Models/                 # Data models and enums
├── Views/                  # SwiftUI views (small, composable)
│   ├── Calendar/          # Calendar-specific views
│   ├── Components/        # Reusable UI components
│   └── Shared/           # Shared UI elements
├── ViewModels/            # Business logic and state management
├── Services/              # External integrations (Toggl, LLM, etc.)
├── Repositories/          # Data access layer
├── Utils/                 # Helper functions and extensions
└── Resources/             # Assets and configuration files
```

### 3. Component Size Guidelines
- **Maximum 400 lines per file** - Split larger files immediately
- **Single responsibility** - Each file has one clear purpose
- **Composable views** - Break complex UI into small, reusable components
- **No code duplication** - Use extensions, helpers, and protocols

## Core Components

### Models (`/Models`)

#### Data Models
```swift
// Example: Task.swift
struct LifeTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let status: TaskStatus
    // ... other properties
}
```

#### Enums
```swift
// Example: TaskStatus.swift
enum TaskStatus: String, CaseIterable, Codable {
    case inbox = "inbox"
    case todo = "todo"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}
```

### Views (`/Views`)

#### View Structure
- **Small, focused components** (50-150 lines typical)
- **Single UI responsibility**
- **No business logic** - delegate to ViewModels
- **Composable and reusable**

```swift
// Example: TaskRow.swift
struct TaskRow: View {
    let task: LifeTask
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        // UI implementation only
    }
}
```

#### Calendar Views Hierarchy
```
CalendarView.swift              # Main calendar container
├── CalendarHeaderView.swift    # Navigation and view mode controls
├── CalendarMainView.swift      # Content area coordinator
│   ├── CalendarDayView.swift   # Day view implementation
│   ├── CalendarWeekView.swift  # Week view implementation
│   └── CalendarMonthView.swift # Month view implementation
└── CalendarParkingLot.swift    # Task parking lot sidebar
```

### ViewModels (`/ViewModels`)

#### ViewModel Responsibilities
- **State management** using `@Published` properties
- **Business logic** and data transformation
- **Service coordination** (API calls, data processing)
- **UI state** (loading, error handling)

```swift
// Example: CalendarViewModel.swift
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var selectedDate = Date()
    @Published var viewMode: CalendarViewMode = .day
    
    private let togglService: TogglService
    private let taskRepository: TaskRepository
    
    // Business logic methods
    func loadEventsForCurrentPeriod() async { }
    func scheduleTask(_ task: LifeTask, at date: Date) async { }
}
```

### Services (`/Services`)

#### Service Layer Pattern
- **External API integration** (Toggl, OpenAI, Supabase)
- **Business operations** (scheduling, notifications)
- **Protocol-based** for testability
- **Error handling** and retry logic

```swift
// Example: TogglService.swift
protocol TogglServiceProtocol {
    func fetchTimeEntries(startDate: Date, endDate: Date) async throws -> [TogglTimeEntry]
}

class TogglService: TogglServiceProtocol {
    // Implementation with rate limiting, caching, error handling
}
```

### Repositories (`/Repositories`)

#### Data Access Layer
- **Database abstraction** over Supabase
- **CRUD operations** with type safety
- **Query optimization** and caching
- **Real-time subscriptions**

```swift
// Example: TaskRepository.swift
class TaskRepository {
    private let supabaseService: SupabaseService
    
    func fetchTasks() async throws -> [LifeTask] { }
    func createTask(_ task: LifeTask) async throws -> LifeTask { }
    func updateTask(_ task: LifeTask) async throws -> LifeTask { }
}
```

## Advanced Features Implementation

### 1. Calendar System Architecture

#### Buffer Management
- **SchedulingEngine.swift**: Core scheduling logic with 5min/hour buffer rule
- **BufferCalculator.swift**: Buffer time calculations and validation
- **ConflictResolver.swift**: Automatic rescheduling when conflicts occur

#### Toggl Integration
- **TogglService.swift**: API integration with rate limiting (3-second delays)
- **TogglSyncEngine.swift**: Real-time synchronization between planned and actual time
- **TogglCacheManager.swift**: Intelligent caching to minimize API calls

#### Parking Lot System
- **ParkingLotEngine.swift**: LLM-powered task importance ranking
- **TaskPrioritizer.swift**: AI-driven priority scoring and recommendations
- **OverflowManager.swift**: Intelligent handling of schedule overflow

### 2. Drag & Drop System

#### Implementation
- **DragDropCoordinator.swift**: Centralized drag & drop state management
- **TaskDragPreview.swift**: Custom drag preview with visual feedback
- **DropTargetHandler.swift**: Drop zone management and validation

#### State Management
```swift
// CalendarViewModel.swift
@Published var draggedTask: LifeTask?
@Published var isDragging = false
@Published var dragPosition = CGPoint.zero

func startDragging(_ task: LifeTask) { }
func handleDrop(task: LifeTask, at date: Date) async { }
```

### 3. Context Menu System

#### Implementation Pattern
- **Context menus attached to individual views**
- **Actions delegated to ViewModels**
- **Proper gesture coordination** to prevent conflicts

```swift
// Example: TaskRow context menu
.contextMenu {
    TaskContextMenu(task: task)
        .environmentObject(viewModel)
}
```

## Testing Architecture

### Test Structure
```
Tests/LifeManagerTests/
├── ViewModelTests/        # ViewModel unit tests
├── ServiceTests/          # Service integration tests
├── RepositoryTests/       # Data layer tests
├── UITests/              # SwiftUI view tests
└── MockData/             # Test data and mocks
```

### Testing Patterns
- **Mock services** for external dependencies
- **Test ViewModels** in isolation
- **UI tests** for critical user flows
- **Performance tests** for large data sets

## Performance Considerations

### 1. Memory Management
- **Weak references** in closures and delegates
- **Proper cancellation** of async operations
- **Efficient data structures** for large collections

### 2. UI Performance
- **Lazy loading** for large lists
- **Efficient SwiftUI updates** with proper `@Published` usage
- **Background processing** for heavy operations

### 3. API Optimization
- **Request batching** and caching
- **Rate limiting** compliance
- **Intelligent retry** mechanisms

## Development Guidelines

### 1. File Creation Rules
- **One View per file** - Never combine multiple views
- **One ViewModel per major feature** - Split complex ViewModels
- **Dedicated service files** - Each external integration gets its own service
- **Model files by domain** - Group related models together

### 2. Code Quality Standards
- **Extensive comments** and documentation
- **Protocol-oriented design** where appropriate
- **Type-safe APIs** - avoid stringly-typed interfaces
- **Error handling** at every layer

### 3. Refactoring Triggers
- **File exceeds 400 lines** - Split immediately
- **View becomes complex** - Extract subviews
- **Repeated code patterns** - Create reusable components
- **Business logic in views** - Move to ViewModels

## Migration from Monolithic Architecture

### Before (v1.5 and earlier)
- **Single ContentView.swift** with 6000+ lines
- **Mixed concerns** - UI, business logic, data access all together
- **Difficult testing** and maintenance
- **Poor code reusability**

### After (v1.75+)
- **8 modular calendar components** with clear responsibilities
- **Strict MVVM separation** with dedicated ViewModels
- **Testable architecture** with mock-friendly services
- **Reusable components** across the application

## Best Practices Summary

1. **Keep files small** (under 400 lines)
2. **Single responsibility** per component
3. **No business logic in views** - use ViewModels
4. **Protocol-oriented design** for testability
5. **Extensive documentation** and comments
6. **Modular architecture** with clear boundaries
7. **Type-safe APIs** throughout
8. **Proper error handling** at every layer
9. **Performance-conscious** but maintainable code
10. **Regular refactoring** to maintain quality

This architecture ensures LifeManager remains maintainable, testable, and scalable as it grows in complexity and features. 