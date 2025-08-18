# ContextMemoryService Refactoring Plan

## Current Issues (987 lines - TOO LARGE!)
❌ **Single Responsibility Principle Violation**: Service handles 10+ different responsibilities
❌ **High Coupling**: Too many dependencies and interconnected concerns
❌ **Difficult to Test**: Large surface area makes unit testing complex
❌ **Poor Maintainability**: Changes risk breaking unrelated functionality
❌ **Performance Issues**: Too many operations in one service

## Proposed Architecture - Split into 5 Focused Services

### 1. **ContextWindowManager** (~200 lines)
**Responsibility**: Manage the sliding window of active context items
```swift
class ContextWindowManager: ObservableObject {
    @Published var activeWindow: [ContextItem] = []
    private var windowSize: Int
    
    func addItems(_ items: [PARAItem])
    func removeOldest(_ count: Int)
    func getCurrentWindow() -> [ContextItem]
    func adjustWindowSize(basedOn activity: ActivityLevel)
}
```

### 2. **ActivityPatternService** (~180 lines)
**Responsibility**: Track and analyze user activity patterns
```swift
class ActivityPatternService: ObservableObject {
    @Published var currentActivityLevel: ActivityLevel
    @Published var peakHours: [Int]
    @Published var dailyAverage: Double
    
    func updatePatterns(with items: [ContextItem])
    func getActivityLevel() -> ActivityLevel
    func predictOptimalWindowSize() -> Int
    func getWorkPersonalRatio() -> Double
}
```

### 3. **SummaryGenerationService** (~250 lines)
**Responsibility**: Generate and manage daily/weekly/monthly summaries
```swift
class SummaryGenerationService: ObservableObject {
    @Published var dailySummaries: [DailySummary]
    @Published var weeklySummaries: [WeeklySummary]
    @Published var monthlySummaries: [MonthlySummary]
    
    func generateDailySummary(for date: Date) async -> DailySummary
    func generateWeeklySummary(for week: Date) async -> WeeklySummary
    func generateMonthlySummary(for month: Date) async -> MonthlySummary
    func cleanupOldSummaries()
}
```

### 4. **ContextPersistenceService** (~150 lines)
**Responsibility**: Handle all database operations for context data
```swift
class ContextPersistenceService {
    private let supabaseService = SupabaseService.shared
    
    func saveContextWindow(_ items: [ContextItem]) async
    func loadContextWindow() async throws -> [ContextItem]
    func saveSummaries(_ summaries: Summaries) async
    func loadSummaries() async throws -> Summaries
}
```

### 5. **ContextQueryService** (~150 lines)
**Responsibility**: Search and query context data
```swift
class ContextQueryService {
    func searchContext(query: String, limit: Int) -> [ContextItem]
    func getFrequentItems(category: PARACategory) -> [String]
    func getCommonTags() -> [String]
    func getContextPatterns() -> ContextPatterns
    func getActiveProjects() -> [String]
}
```

### 6. **ContextMemoryCoordinator** (~100 lines)
**Responsibility**: Coordinate between all context services (Facade pattern)
```swift
class ContextMemoryCoordinator: ObservableObject {
    private let windowManager = ContextWindowManager()
    private let activityService = ActivityPatternService()
    private let summaryService = SummaryGenerationService()
    private let persistenceService = ContextPersistenceService()
    private let queryService = ContextQueryService()
    
    // Simplified public API that delegates to appropriate services
    func addToContext(_ items: [PARAItem]) async
    func getContextSummary(timeframe: ContextTimeframe) async -> String
    func searchContext(query: String) -> [ContextItem]
}
```

## Benefits of Refactoring

### ✅ **Single Responsibility**
Each service has one clear purpose

### ✅ **Testability**
Smaller units are easier to test in isolation

### ✅ **Maintainability**
Changes to one concern don't affect others

### ✅ **Performance**
Can optimize each service independently

### ✅ **Reusability**
Services can be used independently by other parts of the app

### ✅ **Clear Dependencies**
Each service declares what it needs explicitly

## Migration Strategy

### Phase 1: Create New Services (Week 1)
1. Create empty service classes with interfaces
2. Add dependency injection support
3. Write unit tests for each service

### Phase 2: Move Logic (Week 2)
1. Move methods to appropriate services
2. Keep ContextMemoryService as coordinator temporarily
3. Update all references gradually

### Phase 3: Cleanup (Week 3)
1. Remove old ContextMemoryService
2. Update all ViewModels to use new services
3. Run full test suite

## Code Quality Metrics

### Before Refactoring:
- Lines of Code: 987
- Cyclomatic Complexity: ~45
- Dependencies: 5+
- Test Coverage: Difficult

### After Refactoring:
- Largest Service: ~250 lines
- Cyclomatic Complexity: <10 per service
- Dependencies: 1-2 per service
- Test Coverage: >80% achievable

## Implementation Priority

1. **HIGH**: Split ActivityPatternService (impacts performance)
2. **HIGH**: Split ContextPersistenceService (data integrity)
3. **MEDIUM**: Split SummaryGenerationService (CPU intensive)
4. **MEDIUM**: Split ContextWindowManager (core functionality)
5. **LOW**: Split ContextQueryService (read-only operations)

## Notes

- Each service should be in its own file
- Use protocols for dependency injection
- Consider using Combine for reactive updates between services
- Add comprehensive logging to each service
- Document public APIs clearly
- Consider using async/await throughout