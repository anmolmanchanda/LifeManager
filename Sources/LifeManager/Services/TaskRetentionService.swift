import Foundation

/// Service for managing task retention and automatic cleanup of deleted tasks
/// Handles 24-hour retention period for deleted tasks with automatic cleanup
class TaskRetentionService: ObservableObject {
    
    static let shared = TaskRetentionService()
    
    // MARK: - Configuration
    
    private struct RetentionConfig {
        static let retentionPeriodHours: Double = 24.0
        static let cleanupIntervalSeconds: TimeInterval = 3600 // 1 hour
        static let batchSize = 50 // Max tasks to cleanup per batch
    }
    
    // MARK: - Published State
    
    @Published var cleanupStats: CleanupStats = CleanupStats()
    @Published var isCleanupInProgress = false
    
    // MARK: - Dependencies
    
    private let taskRepository = TaskRepository()
    private let logger = Logger.shared
    
    // MARK: - Internal State
    
    private var cleanupTimer: Timer?
    private let cleanupQueue = DispatchQueue(label: "task.retention.cleanup", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        startCleanupTimer()
        logger.info("TASK_RETENTION: Service initialized")
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Start automatic cleanup timer
    func startCleanupTimer() {
        cleanupTimer?.invalidate()
        
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: RetentionConfig.cleanupIntervalSeconds, repeats: true) { _ in
            Task {
                await self.performAutomaticCleanup()
            }
        }
        
        logger.info("TASK_RETENTION: Cleanup timer started (interval: \(RetentionConfig.cleanupIntervalSeconds)s)")
    }
    
    /// Stop automatic cleanup timer
    func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        logger.info("TASK_RETENTION: Cleanup timer stopped")
    }
    
    /// Manually trigger cleanup (for testing)
    func triggerManualCleanup() async {
        await performAutomaticCleanup()
    }
    
    /// Get tasks eligible for permanent deletion
    func getTasksEligibleForDeletion() async throws -> [LifeTask] {
        let deletedTasks = try await taskRepository.fetchRecentlyDeletedTasks()
        return deletedTasks.filter { $0.canBePermanentlyDeleted }
    }
    
    /// Restore a deleted task (within 24-hour window)
    func restoreTask(id: UUID) async throws {
        try await taskRepository.restoreDeletedTask(id: id)
        logger.success("TASK_RETENTION: Restored task: \(id)")
        
        // Update stats
        await MainActor.run {
            cleanupStats.totalTasksRestored += 1
        }
    }
    
    // MARK: - Private Methods
    
    private func performAutomaticCleanup() async {
        await MainActor.run {
            isCleanupInProgress = true
        }
        
        do {
            let eligibleTasks = try await getTasksEligibleForDeletion()
            
            if eligibleTasks.isEmpty {
                logger.info("TASK_RETENTION: No tasks eligible for cleanup")
                return
            }
            
            logger.info("TASK_RETENTION: Starting cleanup of \(eligibleTasks.count) tasks")
            
            var deletedCount = 0
            var errorCount = 0
            
            // Process in batches to avoid overwhelming database
            for batch in eligibleTasks.chunked(into: RetentionConfig.batchSize) {
                for task in batch {
                    do {
                        try await taskRepository.permanentlyDeleteTask(id: task.id)
                        deletedCount += 1
                        logger.debug("TASK_RETENTION: Permanently deleted task: \(task.title)")
                    } catch {
                        errorCount += 1
                        logger.error("TASK_RETENTION: Failed to delete task \(task.id): \(error)")
                    }
                }
                
                // Small delay between batches
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Update statistics
            await MainActor.run {
                cleanupStats.totalTasksDeleted += deletedCount
                cleanupStats.totalCleanupRuns += 1
                cleanupStats.lastCleanupDate = Date()
                cleanupStats.lastCleanupDeletedCount = deletedCount
                cleanupStats.lastCleanupErrorCount = errorCount
            }
            
            logger.success("TASK_RETENTION: Cleanup completed - deleted: \(deletedCount), errors: \(errorCount)")
            
        } catch {
            logger.error("TASK_RETENTION: Cleanup failed: \(error)")
            await MainActor.run {
                cleanupStats.totalCleanupRuns += 1
                cleanupStats.lastCleanupErrorCount += 1
            }
        }
        
        await MainActor.run {
            isCleanupInProgress = false
        }
    }
}

// MARK: - Supporting Types

struct CleanupStats: Codable {
    var totalTasksDeleted: Int = 0
    var totalTasksRestored: Int = 0
    var totalCleanupRuns: Int = 0
    var lastCleanupDate: Date?
    var lastCleanupDeletedCount: Int = 0
    var lastCleanupErrorCount: Int = 0
    
    var successRate: Double {
        guard totalCleanupRuns > 0 else { return 0 }
        let successfulRuns = totalCleanupRuns - (lastCleanupErrorCount > 0 ? 1 : 0)
        return Double(successfulRuns) / Double(totalCleanupRuns)
    }
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}