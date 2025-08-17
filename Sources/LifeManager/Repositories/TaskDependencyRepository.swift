//
// TaskDependencyRepository.swift
// LifeManager
//
// Repository for task dependency data operations
// Part of Priority 4: Task Dependency Management
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation

/// Repository for task dependency data operations
class TaskDependencyRepository {
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - CRUD Operations
    
    /// Create a new task dependency
    func createDependency(_ dependency: TaskDependency) async throws -> TaskDependency {
        logger.debug("TASK_DEPENDENCY_REPO: Creating dependency record")
        
        let record = TaskDependencyRecord(from: dependency)
        let savedRecord: TaskDependencyRecord = try await supabaseService.insert(record, into: "task_dependencies")
        
        return savedRecord.toTaskDependency()
    }
    
    /// Get all dependencies for a task
    func getDependencies(for taskId: UUID) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Fetching dependencies for task \(taskId)")
        
        let query = "dependent_task_id.eq.\(taskId.uuidString)"
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: query
        )
        
        return records.map { $0.toTaskDependency() }
    }
    
    /// Get all tasks that depend on a given task
    func getDependents(for taskId: UUID) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Fetching dependents for task \(taskId)")
        
        let query = "depends_on_task_id.eq.\(taskId.uuidString)"
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: query
        )
        
        return records.map { $0.toTaskDependency() }
    }
    
    /// Get all dependencies for multiple tasks
    func getDependencies(for taskIds: [UUID]) async throws -> [UUID: [TaskDependency]] {
        logger.debug("TASK_DEPENDENCY_REPO: Fetching dependencies for \(taskIds.count) tasks")
        
        let taskIdStrings = taskIds.map { $0.uuidString }
        let query = "dependent_task_id.in.(\(taskIdStrings.joined(separator: ",")))"
        
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: query
        )
        
        var result: [UUID: [TaskDependency]] = [:]
        
        for record in records {
            let dependency = record.toTaskDependency()
            if result[record.dependent_task_id] == nil {
                result[record.dependent_task_id] = []
            }
            result[record.dependent_task_id]?.append(dependency)
        }
        
        return result
    }
    
    /// Update dependency completion status
    func updateDependencyCompletion(dependencyId: UUID, isCompleted: Bool) async throws {
        logger.debug("TASK_DEPENDENCY_REPO: Updating dependency completion \(dependencyId)")
        
        // Fetch the current record
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: "id.eq.\(dependencyId.uuidString)"
        )
        
        guard let record = records.first else {
            throw DependencyError.taskNotFound
        }
        
        // Update the record
        var updatedRecord = record
        updatedRecord.is_completed = isCompleted
        updatedRecord.updated_at = ISO8601DateFormatter().string(from: Date())
        
        try await supabaseService.update(
            updatedRecord,
            in: "task_dependencies",
            matching: "id",
            value: dependencyId.uuidString
        )
    }
    
    /// Delete a dependency
    func deleteDependency(_ dependencyId: UUID) async throws {
        logger.debug("TASK_DEPENDENCY_REPO: Deleting dependency \(dependencyId)")
        
        try await supabaseService.delete(
            from: "task_dependencies",
            id: dependencyId.uuidString,
            column: "id"
        )
    }
    
    /// Get all dependencies in the system (for admin/analysis purposes)
    func getAllDependencies() async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Fetching all dependencies")
        
        let records: [TaskDependencyRecord] = try await supabaseService.fetch(
            TaskDependencyRecord.self,
            from: "task_dependencies"
        )
        
        return records.map { $0.toTaskDependency() }
    }
    
    // MARK: - Specialized Queries
    
    /// Check if a specific dependency exists
    func dependencyExists(
        dependentTaskId: UUID,
        dependsOnTaskId: UUID
    ) async throws -> Bool {
        logger.debug("TASK_DEPENDENCY_REPO: Checking if dependency exists")
        
        let query = "dependent_task_id.eq.\(dependentTaskId.uuidString),depends_on_task_id.eq.\(dependsOnTaskId.uuidString)"
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: query
        )
        
        return !records.isEmpty
    }
    
    /// Get incomplete dependencies for a task
    func getIncompleteDependencies(for taskId: UUID) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Fetching incomplete dependencies for task \(taskId)")
        
        let query = "dependent_task_id.eq.\(taskId.uuidString),is_completed.eq.false"
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: query
        )
        
        return records.map { $0.toTaskDependency() }
    }
    
    /// Get dependencies by type
    func getDependencies(
        for taskId: UUID,
        type: DependencyType
    ) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Fetching \(type.rawValue) dependencies for task \(taskId)")
        
        let query = "dependent_task_id.eq.\(taskId.uuidString),dependency_type.eq.\(type.rawValue)"
        let records: [TaskDependencyRecord] = try await supabaseService.fetchWithQuery(
            TaskDependencyRecord.self,
            from: "task_dependencies",
            query: query
        )
        
        return records.map { $0.toTaskDependency() }
    }
    
    /// Get tasks that can be started (have no incomplete dependencies)
    func getStartableTasks(from taskIds: [UUID]) async throws -> [UUID] {
        logger.debug("TASK_DEPENDENCY_REPO: Finding startable tasks from \(taskIds.count) candidates")
        
        var startableTasks: [UUID] = []
        
        for taskId in taskIds {
            let incompleteDeps = try await getIncompleteDependencies(for: taskId)
            if incompleteDeps.isEmpty {
                startableTasks.append(taskId)
            }
        }
        
        return startableTasks
    }
    
    /// Get dependency chain for a task (all upstream dependencies)
    func getDependencyChain(for taskId: UUID) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Building dependency chain for task \(taskId)")
        
        var chain: [TaskDependency] = []
        var processedTasks = Set<UUID>()
        var tasksToProcess = [taskId]
        
        while !tasksToProcess.isEmpty {
            let currentTaskId = tasksToProcess.removeFirst()
            
            if processedTasks.contains(currentTaskId) {
                continue // Avoid cycles
            }
            
            processedTasks.insert(currentTaskId)
            
            let dependencies = try await getDependencies(for: currentTaskId)
            chain.append(contentsOf: dependencies)
            
            // Add dependency tasks to process queue
            for dependency in dependencies {
                if !processedTasks.contains(dependency.taskId) {
                    tasksToProcess.append(dependency.taskId)
                }
            }
        }
        
        return chain
    }
    
    /// Get dependent chain for a task (all downstream dependencies)
    func getDependentChain(for taskId: UUID) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Building dependent chain for task \(taskId)")
        
        var chain: [TaskDependency] = []
        var processedTasks = Set<UUID>()
        var tasksToProcess = [taskId]
        
        while !tasksToProcess.isEmpty {
            let currentTaskId = tasksToProcess.removeFirst()
            
            if processedTasks.contains(currentTaskId) {
                continue // Avoid cycles
            }
            
            processedTasks.insert(currentTaskId)
            
            let dependents = try await getDependents(for: currentTaskId)
            chain.append(contentsOf: dependents)
            
            // Add dependent tasks to process queue
            for dependent in dependents {
                if !processedTasks.contains(dependent.dependentTaskId) {
                    tasksToProcess.append(dependent.dependentTaskId)
                }
            }
        }
        
        return chain
    }
    
    // MARK: - Batch Operations
    
    /// Create multiple dependencies at once
    func createDependencies(_ dependencies: [TaskDependency]) async throws -> [TaskDependency] {
        logger.debug("TASK_DEPENDENCY_REPO: Creating \(dependencies.count) dependencies")
        
        let records = dependencies.map { TaskDependencyRecord(from: $0) }
        let savedRecords: [TaskDependencyRecord] = try await supabaseService.insertBatch(records, into: "task_dependencies")
        
        return savedRecords.map { $0.toTaskDependency() }
    }
    
    /// Delete all dependencies for a task
    func deleteAllDependencies(for taskId: UUID) async throws {
        logger.debug("TASK_DEPENDENCY_REPO: Deleting all dependencies for task \(taskId)")
        
        // Delete where task is dependent
        let dependentQuery = "dependent_task_id.eq.\(taskId.uuidString)"
        try await supabaseService.deleteWithQuery(
            from: "task_dependencies",
            query: dependentQuery
        )
        
        // Delete where task is dependency
        let dependsOnQuery = "depends_on_task_id.eq.\(taskId.uuidString)"
        try await supabaseService.deleteWithQuery(
            from: "task_dependencies",
            query: dependsOnQuery
        )
    }
    
    /// Update multiple dependency completion statuses
    func updateDependencyCompletions(_ updates: [(UUID, Bool)]) async throws {
        logger.debug("TASK_DEPENDENCY_REPO: Updating \(updates.count) dependency completions")
        
        for (dependencyId, isCompleted) in updates {
            try await updateDependencyCompletion(dependencyId: dependencyId, isCompleted: isCompleted)
        }
    }
    
    // MARK: - Analytics
    
    /// Get dependency statistics for a user
    func getDependencyStatistics() async throws -> DependencyStatistics {
        logger.debug("TASK_DEPENDENCY_REPO: Calculating dependency statistics")
        
        let allDependencies = try await getAllDependencies()
        let completedDependencies = allDependencies.filter { $0.isCompleted }
        
        let dependencyTypes = Dictionary(grouping: allDependencies) { $0.dependencyType }
        
        return DependencyStatistics(
            totalDependencies: allDependencies.count,
            completedDependencies: completedDependencies.count,
            pendingDependencies: allDependencies.count - completedDependencies.count,
            dependenciesByType: dependencyTypes.mapValues { $0.count },
            averageDependenciesPerTask: 0 // Would calculate from task count
        )
    }
    
    /// Find circular dependencies in the system
    func findCircularDependencies() async throws -> [[UUID]] {
        logger.debug("TASK_DEPENDENCY_REPO: Searching for circular dependencies")
        
        let allDependencies = try await getAllDependencies()
        var adjacencyList: [UUID: Set<UUID>] = [:]
        
        // Build adjacency list
        for dependency in allDependencies {
            if adjacencyList[dependency.dependentTaskId] == nil {
                adjacencyList[dependency.dependentTaskId] = Set<UUID>()
            }
            adjacencyList[dependency.dependentTaskId]?.insert(dependency.taskId)
        }
        
        // Find cycles using DFS
        var cycles: [[UUID]] = []
        var visited = Set<UUID>()
        var recursionStack = Set<UUID>()
        var currentPath: [UUID] = []
        
        func findCyclesDFS(node: UUID) {
            visited.insert(node)
            recursionStack.insert(node)
            currentPath.append(node)
            
            if let neighbors = adjacencyList[node] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        findCyclesDFS(node: neighbor)
                    } else if recursionStack.contains(neighbor) {
                        // Found cycle
                        if let cycleStart = currentPath.firstIndex(of: neighbor) {
                            let cycle = Array(currentPath[cycleStart...])
                            cycles.append(cycle)
                        }
                    }
                }
            }
            
            recursionStack.remove(node)
            currentPath.removeLast()
        }
        
        for node in adjacencyList.keys {
            if !visited.contains(node) {
                findCyclesDFS(node: node)
            }
        }
        
        return cycles
    }
}

// MARK: - Supporting Types

/// Dependency statistics
struct DependencyStatistics {
    let totalDependencies: Int
    let completedDependencies: Int
    let pendingDependencies: Int
    let dependenciesByType: [DependencyType: Int]
    let averageDependenciesPerTask: Double
}

// Note: TaskDependencyRecord extensions are defined in TaskDependencyService.swift