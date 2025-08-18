# LifeManager Common Development Tasks

## Adding New PARA Item Types
1. Update `ContentModels.swift` with new enum values
2. Create database migration in `supabase/migrations/`
3. Update LLM prompts in `prompts/templates/`
4. Add UI support in relevant view components
5. Update tests to cover new functionality

## Integrating New LLM Providers
With the new modular LLM architecture:
1. Add provider configuration to `LLMConfigurationService.swift`
2. Implement communication logic in `LLMCommunicationService.swift`
3. Update prompt templates in `LLMPromptService.swift`
4. Add processing workflows in `LLMProcessingService.swift`
5. Test integration through `LLMServiceCoordinator.swift`
6. Add comprehensive error handling and logging
7. Create tests for new provider integration

**Note**: Legacy code can continue using `LLMService` type alias, but new development should use `LLMServiceCoordinator.shared` directly.

## Adding New Services
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

## Adding Calendar Features
1. Update `CalendarModels.swift` for new data structures
2. Implement business logic in `CalendarOrchestrationService.swift`
3. Add UI components in `Views/Calendar/` directory
4. Update `CalendarViewModel.swift` for state management
5. Test drag & drop and scheduling functionality

## Database Schema Changes
1. Create migration file in `supabase/migrations/`
2. Update corresponding model in `Sources/LifeManager/Models/`
3. Update repository methods if needed
4. Test migration in development environment
5. Update any affected services or views

## API Integration Patterns
When adding new API integrations:

1. **Configuration**: Add API keys to `config.txt.template`
2. **Service Layer**: Create dedicated service following singleton pattern
3. **Error Handling**: Implement comprehensive error handling with user-friendly messages
4. **Caching**: Consider caching strategies for expensive operations
5. **Testing**: Add integration tests and monitoring scripts

## Intelligent Task Automation Architecture

### Smart Auto-Rescheduling
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

### Undo/Override System
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

### Dependency-Aware Scheduling
```swift
// Validate dependencies before rescheduling
let dependencyCheck = taskWithDeps.canBeRescheduled(to: newDate)
guard dependencyCheck.canReschedule else {
    logger.debug("Slot rejected: \(dependencyCheck.reason)")
    continue
}
```

### Proactive Notification Engine
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
- **Production Logging**: Logs stored in secure Application Support directory (no Documents access)