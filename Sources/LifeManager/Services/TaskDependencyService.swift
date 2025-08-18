//
// TaskDependencyService.swift
// LifeManager
//
// Priority 4: Task Dependency Management
// Comprehensive task dependency system with intelligent scheduling consideration
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive task dependency management service
/// Handles dependency creation, validation, cascade effects, and intelligent scheduling
@MainActor
class TaskDependencyService: ObservableObject {
    
    static let shared = TaskDependencyService()
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let taskRepository = TaskRepository()
    private let intelligentRescheduling = IntelligentReschedulingService.shared
    private let notificationService = NotificationService.shared
    private let advancedNotificationService = AdvancedNotificationService.shared
    private let logger = Logger.shared
    
    // MARK: - Published State
    
    @Published var taskDependencies: [UUID: [TaskDependency]] = [:]
    @Published var dependencyGraph: DependencyGraph = DependencyGraph()
    @Published var isProcessing = false
    @Published var validationErrors: [DependencyValidationError] = []
    @Published var cascadeWarnings: [CascadeWarning] = []
    
    // MARK: - Configuration
    
    private let maxDependencyDepth = 10 // Prevent infinite recursion
    private let cyclicDependencyCheckLimit = 100 // Max tasks to check for cycles
    
    // MARK: - Initialization
    
    private init() {
        logger.info("TASK_DEPENDENCIES: Service initialized")
        Task {
            await loadAllDependencies()
        }
    }
    
    // MARK: - Dependency Management
    
    /// Create a new task dependency
    func createDependency(
        dependentTaskId: UUID,
        dependsOnTaskId: UUID,
        type: DependencyType = .finishToStart
    ) async throws -> TaskDependency {
        
        logger.info("TASK_DEPENDENCIES: Creating dependency - \(dependentTaskId) depends on \(dependsOnTaskId)")
        
        // Validate the dependency
        let validation = await validateDependency(
            dependentTaskId: dependentTaskId,
            dependsOnTaskId: dependsOnTaskId,
            type: type
        )
        
        guard validation.isValid else {
            logger.error("TASK_DEPENDENCIES: Invalid dependency - \(validation.errors.joined(separator: ", "))")
            throw DependencyError.validationFailed(validation.errors)
        }
        
        // Get task details
        guard let dependentTask = try await taskRepository.fetchTask(id: dependentTaskId),
              let dependsOnTask = try await taskRepository.fetchTask(id: dependsOnTaskId) else {
            throw DependencyError.taskNotFound
        }
        
        // Create dependency record
        let dependency = TaskDependency(
            id: UUID(),
            title: "\(dependentTask.title) ← \(dependsOnTask.title)",
            taskId: dependsOnTaskId,
            dependentTaskId: dependentTaskId,
            dependencyType: type,
            isCompleted: dependsOnTask.status == .completed,
            scheduledDate: ISO8601DateFormatter().date(from: dependsOnTask.dueDate ?? "") ?? Date(),
            mustCompleteBy: calculateMustCompleteByDate(
                dependentTask: dependentTask,
                dependsOnTask: dependsOnTask,
                type: type
            )
        )
        
        // Save to database
        try await saveDependency(dependency)
        
        // Update dependency graph
        await updateDependencyGraph()
        
        // Check for cascade effects
        let cascadeEffects = await analyzeCascadeEffects(for: dependentTaskId)
        if !cascadeEffects.isEmpty {
            await notifyOfCascadeEffects(cascadeEffects)
        }
        
        logger.success("TASK_DEPENDENCIES: Dependency created successfully")
        return dependency
    }
    
    /// Remove a task dependency
    func removeDependency(_ dependencyId: UUID) async throws {
        logger.info("TASK_DEPENDENCIES: Removing dependency \(dependencyId)")
        
        // Remove from database
        try await deleteDependency(dependencyId)
        
        // Update dependency graph
        await updateDependencyGraph()
        
        // Check for orphaned tasks that might need rescheduling
        await checkForOrphanedTasks()
        
        logger.success("TASK_DEPENDENCIES: Dependency removed successfully")
    }
    
    /// Get all dependencies for a task
    func getDependencies(for taskId: UUID) async -> TaskDependencyInfo {
        let dependencies = taskDependencies[taskId] ?? []
        let dependents = await getDependentTasks(for: taskId)
        
        return TaskDependencyInfo(
            taskId: taskId,
            dependencies: dependencies,
            dependents: dependents,
            canStart: dependencies.allSatisfy { $0.isCompleted },
            blockedBy: dependencies.filter { !$0.isCompleted }.map { $0.title },
            criticalPath: await calculateCriticalPath(for: taskId)
        )
    }
    
    /// Validate a proposed dependency
    func validateDependency(
        dependentTaskId: UUID,
        dependsOnTaskId: UUID,
        type: DependencyType
    ) async -> DependencyValidation {
        
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check for self-dependency
        if dependentTaskId == dependsOnTaskId {
            errors.append("A task cannot depend on itself")
        }
        
        // Check for circular dependencies
        if await wouldCreateCircularDependency(
            dependentTaskId: dependentTaskId,
            dependsOnTaskId: dependsOnTaskId
        ) {
            errors.append("This would create a circular dependency")
        }
        
        // Check for duplicate dependencies
        if await isDuplicateDependency(
            dependentTaskId: dependentTaskId,
            dependsOnTaskId: dependsOnTaskId
        ) {
            errors.append("This dependency already exists")
        }
        
        // Check dependency depth
        let depth = await calculateDependencyDepth(for: dependsOnTaskId)
        if depth >= maxDependencyDepth {
            warnings.append("Dependency chain is getting very deep (\(depth) levels)")
        }
        
        // Check for timing conflicts
        let timingIssues = await checkTimingConflicts(
            dependentTaskId: dependentTaskId,
            dependsOnTaskId: dependsOnTaskId,
            type: type
        )
        warnings.append(contentsOf: timingIssues)
        
        return DependencyValidation(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Dependency Analysis
    
    /// Analyze cascade effects of adding/removing a dependency
    func analyzeCascadeEffects(for taskId: UUID) async -> [CascadeEffect] {
        logger.debug("TASK_DEPENDENCIES: Analyzing cascade effects for task \(taskId)")
        
        var effects: [CascadeEffect] = []
        var visitedTasks = Set<UUID>()
        
        // Analyze downstream effects
        await analyzeCascadeRecursive(
            taskId: taskId,
            visitedTasks: &visitedTasks,
            effects: &effects,
            depth: 0
        )
        
        return effects
    }
    
    /// Calculate critical path for a task
    func calculateCriticalPath(for taskId: UUID) async -> CriticalPath {
        logger.debug("TASK_DEPENDENCIES: Calculating critical path for task \(taskId)")
        
        // Get all paths to task completion
        let paths = await findAllPaths(to: taskId)
        
        // Calculate duration for each path
        var pathDurations: [(path: [UUID], duration: TimeInterval)] = []
        
        for path in paths {
            var totalDuration: TimeInterval = 0
            
            for taskId in path {
                if let task = try? await taskRepository.fetchTask(id: taskId) {
                    totalDuration += TimeInterval(task.estimatedDuration ?? 60) * 60
                }
            }
            
            pathDurations.append((path: path, duration: totalDuration))
        }
        
        // Find the longest path (critical path)
        let criticalPath = pathDurations.max { $0.duration < $1.duration }
        
        return CriticalPath(
            taskIds: criticalPath?.path ?? [taskId],
            totalDuration: criticalPath?.duration ?? 0,
            bottleneckTasks: await identifyBottlenecks(in: criticalPath?.path ?? [])
        )
    }
    
    /// Check if a task can be started based on dependencies
    func canStartTask(_ taskId: UUID) async -> (canStart: Bool, blockedBy: [String]) {
        let dependencies = taskDependencies[taskId] ?? []
        let incompleteDepedencies = dependencies.filter { !$0.isCompleted }
        
        return (
            canStart: incompleteDepedencies.isEmpty,
            blockedBy: incompleteDepedencies.map { $0.title }
        )
    }
    
    /// Get suggested order for task completion
    func getSuggestedTaskOrder(for taskIds: [UUID]) async -> [UUID] {
        logger.debug("TASK_DEPENDENCIES: Calculating suggested task order")
        
        // Topological sort considering dependencies
        var sorted: [UUID] = []
        var visited = Set<UUID>()
        var visiting = Set<UUID>()
        
        func visit(_ taskId: UUID) async {
            if visited.contains(taskId) { return }
            if visiting.contains(taskId) {
                // Cycle detected, skip this task
                return
            }
            
            visiting.insert(taskId)
            
            // Visit dependencies first
            let deps = taskDependencies[taskId] ?? []
            for dep in deps {
                await visit(dep.taskId)
            }
            
            visiting.remove(taskId)
            visited.insert(taskId)
            sorted.append(taskId)
        }
        
        for taskId in taskIds {
            await visit(taskId)
        }
        
        return sorted
    }
    
    // MARK: - Intelligent Scheduling Integration
    
    /// Update task schedules based on dependency changes
    func updateDependentTaskSchedules(for taskId: UUID) async {
        logger.info("TASK_DEPENDENCIES: Updating dependent task schedules for \(taskId)")
        
        let dependents = await getDependentTasks(for: taskId)
        
        for dependent in dependents {
            // Check if dependent task needs rescheduling
            let constraintViolation = await checkSchedulingConstraints(
                taskId: dependent.dependentTaskId,
                afterTaskId: taskId,
                type: dependent.dependencyType
            )
            
            if constraintViolation {
                // Request intelligent rescheduling
                await requestIntelligentRescheduling(
                    taskId: dependent.dependentTaskId,
                    reason: "Dependency constraint violation"
                )
            }
        }
    }
    
    /// Handle task completion and update dependencies
    func handleTaskCompletion(_ taskId: UUID) async {
        logger.info("TASK_DEPENDENCIES: Handling task completion for \(taskId)")
        
        // Update all dependencies where this task is the dependency
        let dependents = await getDependentTasks(for: taskId)
        
        for dependent in dependents {
            // Update dependency completion status
            await updateDependencyCompletion(dependencyId: dependent.id, isCompleted: true)
            
            // Check if dependent task can now start
            let canStart = await canStartTask(dependent.dependentTaskId)
            if canStart.canStart {
                // Notify that task is now unblocked
                await notifyTaskUnblocked(dependent.dependentTaskId)
            }
        }
        
        // Update dependency graph
        await updateDependencyGraph()
    }
    
    // MARK: - Private Helper Methods
    
    /// Check if adding a dependency would create a circular reference
    private func wouldCreateCircularDependency(
        dependentTaskId: UUID,
        dependsOnTaskId: UUID
    ) async -> Bool {
        
        var visited = Set<UUID>()
        var path = [UUID]()
        
        func hasPath(from: UUID, to: UUID) async -> Bool {
            if from == to { return true }
            if visited.contains(from) { return false }
            
            visited.insert(from)
            path.append(from)
            
            let dependencies = taskDependencies[from] ?? []
            for dep in dependencies {
                if await hasPath(from: dep.taskId, to: to) {
                    return true
                }
            }
            
            path.removeLast()
            return false
        }
        
        return await hasPath(from: dependsOnTaskId, to: dependentTaskId)
    }
    
    /// Calculate dependency depth for a task
    private func calculateDependencyDepth(for taskId: UUID) async -> Int {
        var maxDepth = 0
        var visited = Set<UUID>()
        
        func calculateDepth(_ id: UUID, currentDepth: Int) async {
            if visited.contains(id) { return }
            visited.insert(id)
            
            maxDepth = max(maxDepth, currentDepth)
            
            let dependencies = taskDependencies[id] ?? []
            for dep in dependencies {
                await calculateDepth(dep.taskId, currentDepth: currentDepth + 1)
            }
        }
        
        await calculateDepth(taskId, currentDepth: 0)
        return maxDepth
    }
    
    /// Check for timing conflicts between dependent tasks
    private func checkTimingConflicts(
        dependentTaskId: UUID,
        dependsOnTaskId: UUID,
        type: DependencyType
    ) async -> [String] {
        
        var warnings: [String] = []
        
        guard let dependentTask = try? await taskRepository.fetchTask(id: dependentTaskId),
              let dependsOnTask = try? await taskRepository.fetchTask(id: dependsOnTaskId) else {
            return warnings
        }
        
        // Check if dependent task is scheduled before dependency
        if let depDueDate = dependentTask.dueDate,
           let baseDueDate = dependsOnTask.dueDate,
           let depDate = ISO8601DateFormatter().date(from: depDueDate),
           let baseDate = ISO8601DateFormatter().date(from: baseDueDate) {
            
            switch type {
            case .finishToStart:
                if depDate <= baseDate {
                    warnings.append("Dependent task is scheduled before or at the same time as its dependency")
                }
            case .startToStart:
                if depDate < baseDate {
                    warnings.append("Dependent task starts before its dependency")
                }
            case .finishToFinish:
                // Calculate estimated finish times
                let depFinish = depDate.addingTimeInterval(TimeInterval((dependentTask.estimatedDuration ?? 60) * 60))
                let baseFinish = baseDate.addingTimeInterval(TimeInterval((dependsOnTask.estimatedDuration ?? 60) * 60))
                if depFinish < baseFinish {
                    warnings.append("Dependent task finishes before its dependency")
                }
            case .startToFinish:
                let baseFinish = baseDate.addingTimeInterval(TimeInterval((dependsOnTask.estimatedDuration ?? 60) * 60))
                if depDate < baseFinish {
                    warnings.append("Dependent task starts before dependency finishes")
                }
            case .sequential:
                // Sequential dependencies - check order
                if depDate < baseDate {
                    warnings.append("Sequential task is scheduled before its predecessor")
                }
            case .resource:
                // Resource dependencies - no specific date validation needed
                break
            case .milestone:
                // Milestone dependencies - check milestone completion
                if depDate < baseDate {
                    warnings.append("Task scheduled before milestone completion")
                }
            }
        }
        
        return warnings
    }
    
    /// Analyze cascade effects recursively
    private func analyzeCascadeRecursive(
        taskId: UUID,
        visitedTasks: inout Set<UUID>,
        effects: inout [CascadeEffect],
        depth: Int
    ) async {
        
        if visitedTasks.contains(taskId) || depth > maxDependencyDepth {
            return
        }
        
        visitedTasks.insert(taskId)
        
        let dependents = await getDependentTasks(for: taskId)
        
        for dependent in dependents {
            let effect = CascadeEffect(
                affectedTaskId: dependent.dependentTaskId,
                impactType: .scheduleChange,
                severity: depth == 0 ? .high : .medium,
                description: "Task depends on modified task (depth: \(depth + 1))"
            )
            effects.append(effect)
            
            await analyzeCascadeRecursive(
                taskId: dependent.dependentTaskId,
                visitedTasks: &visitedTasks,
                effects: &effects,
                depth: depth + 1
            )
        }
    }
    
    /// Update the dependency graph
    private func updateDependencyGraph() async {
        logger.debug("TASK_DEPENDENCIES: Updating dependency graph")
        
        // Build adjacency list representation
        var adjacencyList: [UUID: Set<UUID>] = [:]
        
        for (taskId, dependencies) in taskDependencies {
            adjacencyList[taskId] = Set(dependencies.map { $0.taskId })
        }
        
        dependencyGraph = DependencyGraph(adjacencyList: adjacencyList)
    }
    
    /// Send notification about cascade effects
    private func notifyOfCascadeEffects(_ effects: [CascadeEffect]) async {
        let highSeverityCount = effects.filter { $0.severity == .high }.count
        let totalCount = effects.count
        
        let title = "Dependency Change Impact"
        let message = "\(totalCount) tasks affected (\(highSeverityCount) high priority)"
        
        await advancedNotificationService.sendAdvancedNotification(
            title: title,
            message: message,
            priority: highSeverityCount > 0 ? .high : .normal,
            category: .scheduleChange,
            context: NotificationContext(
                category: "dependency_cascade",
                source: "task_dependencies",
                metadata: ["affectedTasks": totalCount]
            )
        )
    }
    
    /// Request intelligent rescheduling for a task
    private func requestIntelligentRescheduling(taskId: UUID, reason: String) async {
        logger.info("TASK_DEPENDENCIES: Requesting intelligent rescheduling for \(taskId) - \(reason)")
        
        // This would integrate with IntelligentReschedulingService
        // For now, send a notification
        await advancedNotificationService.sendAdvancedNotification(
            title: "Task Needs Rescheduling",
            message: reason,
            priority: .high,
            category: .scheduleChange,
            context: NotificationContext(
                category: "dependency_reschedule",
                source: "task_dependencies",
                metadata: ["taskId": taskId.uuidString]
            )
        )
    }
    
    /// Notify when a task becomes unblocked
    private func notifyTaskUnblocked(_ taskId: UUID) async {
        guard let task = try? await taskRepository.fetchTask(id: taskId) else { return }
        
        let title = "Task Unblocked"
        let message = "'\(task.title)' can now be started - all dependencies completed"
        
        await advancedNotificationService.sendProactiveSuggestion(
            title: title,
            message: message,
            suggestions: [
                ProactiveSuggestion(
                    id: UUID(),
                    title: "Start Now",
                    description: "Begin working on this task immediately",
                    action: "start_task",
                    confidence: 0.9
                ),
                ProactiveSuggestion(
                    id: UUID(),
                    title: "Schedule for Later",
                    description: "Add to calendar for optimal time",
                    action: "schedule_task",
                    confidence: 0.8
                )
            ],
            confidence: 0.9,
            context: NotificationContext(
                category: "task_unblocked",
                source: "task_dependencies",
                metadata: ["taskId": taskId.uuidString]
            )
        )
    }
    
    // MARK: - Database Operations
    
    /// Load all dependencies from database
    private func loadAllDependencies() async {
        do {
            logger.info("TASK_DEPENDENCIES: Loading all dependencies from database")
            
            // Load from task_dependencies table
            let dependencies: [TaskDependencyRecord] = try await supabaseService.fetch(
                TaskDependencyRecord.self,
                from: "task_dependencies"
            )
            
            // Group by task ID
            taskDependencies.removeAll()
            for record in dependencies {
                let dependency = record.toTaskDependency()
                if taskDependencies[record.dependent_task_id] == nil {
                    taskDependencies[record.dependent_task_id] = []
                }
                taskDependencies[record.dependent_task_id]?.append(dependency)
            }
            
            await updateDependencyGraph()
            
            logger.success("TASK_DEPENDENCIES: Loaded \(dependencies.count) dependencies")
            
        } catch {
            logger.error("TASK_DEPENDENCIES: Failed to load dependencies: \(error)")
        }
    }
    
    /// Save dependency to database
    private func saveDependency(_ dependency: TaskDependency) async throws {
        let record = TaskDependencyRecord(from: dependency)
        _ = try await supabaseService.insert(record, into: "task_dependencies")
        
        // Update local cache
        if taskDependencies[dependency.dependentTaskId] == nil {
            taskDependencies[dependency.dependentTaskId] = []
        }
        taskDependencies[dependency.dependentTaskId]?.append(dependency)
    }
    
    /// Delete dependency from database
    private func deleteDependency(_ dependencyId: UUID) async throws {
        try await supabaseService.delete(
            from: "task_dependencies",
            id: dependencyId.uuidString,
            column: "id"
        )
        
        // Update local cache
        for (taskId, deps) in taskDependencies {
            taskDependencies[taskId] = deps.filter { $0.id != dependencyId }
        }
    }
    
    /// Get tasks that depend on a given task
    private func getDependentTasks(for taskId: UUID) async -> [TaskDependency] {
        var dependents: [TaskDependency] = []
        
        for (_, dependencies) in taskDependencies {
            for dep in dependencies where dep.taskId == taskId {
                dependents.append(dep)
            }
        }
        
        return dependents
    }
    
    /// Update dependency completion status
    private func updateDependencyCompletion(dependencyId: UUID, isCompleted: Bool) async {
        // Update in database
        do {
            let updates = ["is_completed": isCompleted]
            try await supabaseService.update(
                table: "task_dependencies",
                id: dependencyId.uuidString,
                updates: updates
            )
            
            // Update local cache
            for (taskId, deps) in taskDependencies {
                if let index = deps.firstIndex(where: { $0.id == dependencyId }) {
                    var updatedDeps = deps
                    var updatedDep = updatedDeps[index]
                    updatedDep = TaskDependency(
                        id: updatedDep.id,
                        title: updatedDep.title,
                        taskId: updatedDep.taskId,
                        dependentTaskId: updatedDep.dependentTaskId,
                        dependencyType: updatedDep.dependencyType,
                        isCompleted: isCompleted,
                        scheduledDate: updatedDep.scheduledDate,
                        mustCompleteBy: updatedDep.mustCompleteBy
                    )
                    updatedDeps[index] = updatedDep
                    taskDependencies[taskId] = updatedDeps
                }
            }
            
        } catch {
            logger.error("TASK_DEPENDENCIES: Failed to update dependency completion: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate must-complete-by date based on dependency type
    private func calculateMustCompleteByDate(
        dependentTask: LifeTask,
        dependsOnTask: LifeTask,
        type: DependencyType
    ) -> Date {
        
        let dependentDueDate = ISO8601DateFormatter().date(from: dependentTask.dueDate ?? "") ?? Date()
        let buffer: TimeInterval = 3600 // 1 hour buffer
        
        switch type {
        case .finishToStart:
            // Must complete before dependent task starts
            return dependentDueDate.addingTimeInterval(-buffer)
            
        case .startToStart:
            // Must start before dependent task starts
            return dependentDueDate
            
        case .finishToFinish:
            // Must finish when dependent task finishes
            let dependentDuration = TimeInterval((dependentTask.estimatedDuration ?? 60) * 60)
            return dependentDueDate.addingTimeInterval(dependentDuration)
            
        case .startToFinish:
            // Must start before dependent task finishes
            let dependentDuration = TimeInterval((dependentTask.estimatedDuration ?? 60) * 60)
            return dependentDueDate.addingTimeInterval(dependentDuration).addingTimeInterval(-buffer)
        case .sequential:
            // Must complete before next sequential task
            return dependentDueDate.addingTimeInterval(-buffer)
        case .resource:
            // Resource dependencies don't have strict timing
            return dependentDueDate
        case .milestone:
            // Must complete before milestone
            return dependentDueDate.addingTimeInterval(-buffer)
        }
    }
    
    /// Check if dependency already exists
    private func isDuplicateDependency(
        dependentTaskId: UUID,
        dependsOnTaskId: UUID
    ) async -> Bool {
        let dependencies = taskDependencies[dependentTaskId] ?? []
        return dependencies.contains { $0.taskId == dependsOnTaskId }
    }
    
    /// Find all paths to a task
    private func findAllPaths(to taskId: UUID) async -> [[UUID]] {
        var allPaths: [[UUID]] = []
        var currentPath: [UUID] = []
        
        func findPaths(current: UUID) {
            currentPath.append(current)
            
            let dependencies = taskDependencies[current] ?? []
            if dependencies.isEmpty {
                // Leaf node - add path
                allPaths.append(currentPath)
            } else {
                for dep in dependencies {
                    findPaths(current: dep.taskId)
                }
            }
            
            currentPath.removeLast()
        }
        
        findPaths(current: taskId)
        return allPaths
    }
    
    /// Identify bottleneck tasks in a path
    private func identifyBottlenecks(in taskIds: [UUID]) async -> [UUID] {
        var bottlenecks: [UUID] = []
        
        for taskId in taskIds {
            let dependents = await getDependentTasks(for: taskId)
            if dependents.count > 2 {
                // Task has multiple dependents - potential bottleneck
                bottlenecks.append(taskId)
            }
        }
        
        return bottlenecks
    }
    
    /// Check for orphaned tasks after dependency removal
    private func checkForOrphanedTasks() async {
        // Find tasks with no dependencies that might have been blocked
        for (taskId, deps) in taskDependencies where deps.isEmpty {
            if let task = try? await taskRepository.fetchTask(id: taskId),
               task.status == .todo {
                // Task might have been waiting on removed dependency
                await notifyTaskUnblocked(taskId)
            }
        }
    }
    
    /// Check scheduling constraints between tasks
    private func checkSchedulingConstraints(
        taskId: UUID,
        afterTaskId: UUID,
        type: DependencyType
    ) async -> Bool {
        
        guard let task = try? await taskRepository.fetchTask(id: taskId),
              let afterTask = try? await taskRepository.fetchTask(id: afterTaskId),
              let taskDate = ISO8601DateFormatter().date(from: task.dueDate ?? ""),
              let afterTaskDate = ISO8601DateFormatter().date(from: afterTask.dueDate ?? "") else {
            return false
        }
        
        switch type {
        case .finishToStart:
            let afterTaskFinish = afterTaskDate.addingTimeInterval(TimeInterval((afterTask.estimatedDuration ?? 60) * 60))
            return taskDate < afterTaskFinish
            
        case .startToStart:
            return taskDate < afterTaskDate
            
        case .finishToFinish:
            let taskFinish = taskDate.addingTimeInterval(TimeInterval((task.estimatedDuration ?? 60) * 60))
            let afterTaskFinish = afterTaskDate.addingTimeInterval(TimeInterval((afterTask.estimatedDuration ?? 60) * 60))
            return taskFinish < afterTaskFinish
            
        case .startToFinish:
            let afterTaskFinish = afterTaskDate.addingTimeInterval(TimeInterval((afterTask.estimatedDuration ?? 60) * 60))
            return taskDate < afterTaskFinish
        case .sequential:
            // Sequential tasks must happen in order
            return taskDate < afterTaskDate
        case .resource:
            // Resource constraints don't affect scheduling directly
            return true
        case .milestone:
            // Task must be after milestone completion
            return taskDate < afterTaskDate
        }
    }
}

// MARK: - Supporting Types

/// Dependency validation result
struct DependencyValidation {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

/// Dependency validation error
struct DependencyValidationError: Identifiable {
    let id = UUID()
    let taskId: UUID
    let error: String
    let timestamp: Date = Date()
}

/// Cascade warning for dependency changes
struct CascadeWarning: Identifiable {
    let id = UUID()
    let affectedTasks: [UUID]
    let warning: String
    let severity: CascadeSeverity
}

/// Cascade effect from dependency changes
struct CascadeEffect {
    let affectedTaskId: UUID
    let impactType: ImpactType
    let severity: CascadeSeverity
    let description: String
}

/// Impact type for cascade effects
enum ImpactType: String {
    case scheduleChange = "schedule_change"
    case blocked = "blocked"
    case unblocked = "unblocked"
    case criticalPathChange = "critical_path_change"
}

/// Cascade severity levels
enum CascadeSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Task dependency information
struct TaskDependencyInfo {
    let taskId: UUID
    let dependencies: [TaskDependency]
    let dependents: [TaskDependency]
    let canStart: Bool
    let blockedBy: [String]
    let criticalPath: CriticalPath
}

/// Critical path information
struct CriticalPath {
    let taskIds: [UUID]
    let totalDuration: TimeInterval
    let bottleneckTasks: [UUID]
}

/// Dependency graph representation
struct DependencyGraph {
    let adjacencyList: [UUID: Set<UUID>]
    
    init(adjacencyList: [UUID: Set<UUID>] = [:]) {
        self.adjacencyList = adjacencyList
    }
    
    func hasCycle() -> Bool {
        var visited = Set<UUID>()
        var recursionStack = Set<UUID>()
        
        func hasCycleDFS(node: UUID) -> Bool {
            visited.insert(node)
            recursionStack.insert(node)
            
            if let neighbors = adjacencyList[node] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        if hasCycleDFS(node: neighbor) {
                            return true
                        }
                    } else if recursionStack.contains(neighbor) {
                        return true
                    }
                }
            }
            
            recursionStack.remove(node)
            return false
        }
        
        for node in adjacencyList.keys {
            if !visited.contains(node) {
                if hasCycleDFS(node: node) {
                    return true
                }
            }
        }
        
        return false
    }
}

/// Database record for task dependencies
struct TaskDependencyRecord: Codable {
    let id: UUID
    let dependent_task_id: UUID
    let depends_on_task_id: UUID
    let dependency_type: String
    var is_completed: Bool
    let created_at: String
    var updated_at: String
    
    init(from dependency: TaskDependency) {
        self.id = dependency.id
        self.dependent_task_id = dependency.dependentTaskId
        self.depends_on_task_id = dependency.taskId
        self.dependency_type = dependency.dependencyType.rawValue
        self.is_completed = dependency.isCompleted
        self.created_at = ISO8601DateFormatter().string(from: Date())
        self.updated_at = ISO8601DateFormatter().string(from: Date())
    }
    
    func toTaskDependency() -> TaskDependency {
        return TaskDependency(
            id: id,
            title: "Dependency",
            taskId: depends_on_task_id,
            dependentTaskId: dependent_task_id,
            dependencyType: DependencyType(rawValue: dependency_type) ?? .finishToStart,
            isCompleted: is_completed,
            scheduledDate: Date(),
            mustCompleteBy: Date()
        )
    }
}

/// Dependency error types
enum DependencyError: LocalizedError {
    case validationFailed([String])
    case taskNotFound
    case circularDependency
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Dependency validation failed: \(errors.joined(separator: ", "))"
        case .taskNotFound:
            return "One or more tasks not found"
        case .circularDependency:
            return "This would create a circular dependency"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}