//
// TaskRepository.swift - SOFT DELETE ENABLED VERSION
// This version activates the existing soft delete infrastructure
//

import Foundation

/// Repository for managing LifeTask data operations
/// FIXED: Soft delete functionality enabled
class TaskRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CRUD Operations
    
    /// Create a new task
    func createTask(
        blobId: UUID? = nil,
        title: String,
        description: String? = nil,
        priority: TaskPriority = .medium,
        status: TaskStatus = .inbox,
        dueDate: Date? = nil,
        estimatedDuration: Int? = nil,
        workPersonal: WorkPersonalType = .personal,
        projectId: UUID? = nil
    ) async throws -> LifeTask {
        let task = LifeTask(
            blobId: blobId,
            title: title,
            description: description,
            priority: priority,
            status: status,
            dueDate: dueDate?.ISO8601Format(),
            estimatedDuration: estimatedDuration,
            workPersonal: workPersonal,
            projectId: projectId
        )
        
        return try await supabaseService.insert(task, into: SupabaseService.TableName.tasks.rawValue)
    }
    
    /// Create task from LifeTask object
    func createTask(_ task: LifeTask) async throws -> LifeTask {
        return try await supabaseService.insert(task, into: SupabaseService.TableName.tasks.rawValue)
    }
    
    /// Fetch all tasks (excludes soft deleted)
    func fetchAllTasks() async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .is("deleted_at", value: "null")  // FIXED: Only non-deleted tasks
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// FIXED: Delete task (now uses soft delete)
    func deleteTask(id: UUID) async throws {
        // FIXED: Use soft delete instead of hard delete
        try await softDeleteTask(id: id)
    }
    
    /// FIXED: Soft delete task implementation (ENABLED)
    func softDeleteTask(id: UUID) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        
        try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .update(["deleted_at": now, "updated_at": now])
            .eq("id", value: id.uuidString)
            .execute()
        
        Logger.shared.info("TASK_REPOSITORY: Soft deleted task: \\(id)")
    }
    
    /// FIXED: Fetch recently deleted tasks (ENABLED)
    func fetchRecentlyDeletedTasks() async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .not("deleted_at", operator: .is, value: "null")  // FIXED: Only deleted tasks
            .order("deleted_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// FIXED: Restore deleted task (ENABLED)
    func restoreDeletedTask(id: UUID) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        
        try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .update(["deleted_at": NSNull(), "updated_at": now])
            .eq("id", value: id.uuidString)
            .execute()
        
        Logger.shared.info("TASK_REPOSITORY: Restored task: \\(id)")
    }
    
    /// FIXED: Permanently delete task (ENABLED)
    func permanentlyDeleteTask(id: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        Logger.shared.info("TASK_REPOSITORY: Permanently deleted task: \\(id)")
    }
    
    /// Cleanup tasks that are eligible for permanent deletion
    func cleanupPermanentlyDeletedTasks() async throws -> Int {
        let eligibleTasks = try await fetchRecentlyDeletedTasks()
            .filter { $0.canBePermanentlyDeleted }
        
        for task in eligibleTasks {
            try await permanentlyDeleteTask(id: task.id)
        }
        
        Logger.shared.info("TASK_REPOSITORY: Cleaned up \\(eligibleTasks.count) permanently deleted tasks")
        return eligibleTasks.count
    }
    
    // MARK: - Other methods (fetch by status, priority, etc.)
    // ... (include all other existing methods)
}