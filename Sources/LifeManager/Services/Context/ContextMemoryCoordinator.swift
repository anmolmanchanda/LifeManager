//
// ContextMemoryCoordinator.swift
// LifeManager
//
// Facade service that coordinates all context memory services
// Provides a simplified API for the rest of the application
//

import Foundation
import Combine

/// Coordinator service that manages all context memory operations
/// Acts as a facade to simplify interaction with multiple context services
class ContextMemoryCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ContextMemoryCoordinator()
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var contextStats: ContextStats = ContextStats()
    
    // MARK: - Services
    private let windowManager = ContextWindowManager()
    private let activityService = ActivityPatternService()
    private let summaryService = SummaryGenerationService()
    private let persistenceService = ContextPersistenceService()
    private let queryService = ContextQueryService()
    private let logger = Logger.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        setupBindings()
        Task {
            await loadStoredContext()
        }
    }
    
    // MARK: - Public API
    
    /// Add items to context and update all services
    func addToContext(_ items: [PARAItem]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Add to window
        await windowManager.addItems(items)
        
        // Update patterns
        let contextItems = windowManager.getCurrentWindow()
        await activityService.updatePatterns(with: contextItems)
        
        // Update summaries
        await summaryService.updateSummaries(with: contextItems)
        
        // Adjust window size based on activity
        windowManager.adjustWindowSize(basedOn: activityService.getActivityLevel())
        
        // Persist changes
        try? await persistenceService.saveContextWindow(contextItems)
        
        // Update stats
        updateContextStats()
        
        logger.info("COORDINATOR: Added \(items.count) items to context")
    }
    
    /// Get current context for processing
    func getCurrentContext() -> ProcessingContext {
        return ProcessingContext(
            recentItems: windowManager.getRecentItems(count: 50),
            dailySummaries: summaryService.dailySummaries,
            weeklySummaries: summaryService.weeklySummaries,
            monthlySummaries: summaryService.monthlySummaries,
            contextStats: contextStats,
            timestamp: Date()
        )
    }
    
    /// Get formatted summary for timeframe
    func getContextSummary(timeframe: ContextTimeframe) async -> String {
        return await summaryService.getFormattedSummary(for: timeframe)
    }
    
    /// Search context with query
    func searchContext(query: String, limit: Int = 10) -> [ContextItem] {
        let items = windowManager.getCurrentWindow()
        return queryService.searchContext(items, query: query, limit: limit)
    }
    
    /// Get active projects and areas
    func getActiveItems() -> (projects: [String], areas: [String]) {
        let items = windowManager.getCurrentWindow()
        return (
            projects: queryService.getActiveProjects(items),
            areas: queryService.getActiveAreas(items)
        )
    }
    
    /// Get context patterns
    func getContextPatterns() -> ContextPatterns {
        let items = windowManager.getCurrentWindow()
        return queryService.getContextPatterns(items)
    }
    
    /// Clean up old data
    func performMaintenance() async {
        // Clean old summaries
        summaryService.cleanupOldSummaries()
        
        // Prune old window items
        windowManager.pruneOldItems(olderThan: 30)
        
        // Clean database
        try? await persistenceService.cleanupOldData(olderThan: 90)
        
        logger.info("COORDINATOR: Completed maintenance tasks")
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind window manager updates
        windowManager.$itemCount
            .sink { [weak self] _ in
                self?.updateContextStats()
            }
            .store(in: &cancellables)
        
        // Bind activity pattern updates
        activityService.$currentActivityLevel
            .sink { [weak self] level in
                self?.windowManager.adjustWindowSize(basedOn: level)
            }
            .store(in: &cancellables)
    }
    
    private func loadStoredContext() async {
        do {
            // Load context window
            let items = try await persistenceService.loadContextWindow()
            for item in items {
                // Convert ContextItem to PARAItem for windowManager
                // Note: This requires a proper conversion method in production
            }
            
            // Load summaries
            if let dailies = try? await persistenceService.loadDailySummaries() {
                await MainActor.run {
                    summaryService.dailySummaries = dailies
                }
            }
            
            // Load activity patterns
            if let patterns = try? await persistenceService.loadActivityPatterns() {
                await MainActor.run {
                    activityService.patterns = patterns
                }
            }
            
            logger.info("COORDINATOR: Loaded stored context successfully")
            
        } catch {
            logger.error("COORDINATOR: Failed to load stored context: \(error)")
        }
    }
    
    private func updateContextStats() {
        let items = windowManager.getCurrentWindow()
        let stats = queryService.getStatistics(items)
        
        contextStats = ContextStats(
            projectsActive: queryService.getActiveProjects(items),
            areasActive: queryService.getActiveAreas(items),
            tasksCompleted: stats.completedCount,
            resourcesAdded: stats.categoryCounts[.resource] ?? 0,
            topTags: queryService.getCommonTags(items, limit: 5),
            totalItems: stats.totalItems
        )
    }
}

// MARK: - Context Timeframe

enum ContextTimeframe {
    case day
    case week
    case month
    case all
}