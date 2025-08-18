//
// TaskRepository.swift - PRIORITY 3: SOFT DELETE ENABLED
// This patch enables the existing 95% complete soft delete infrastructure
//

// MARK: - Enable Soft Delete in deleteTask Method (Lines 254-265)
// Replace the current deleteTask implementation:

/// Delete task (now uses soft delete - ENABLED)
func deleteTask(id: UUID) async throws {
    // FIXED: Use soft delete instead of hard delete
    try await softDeleteTask(id: id)
    Logger.shared.info("TASK_REPOSITORY: Soft deleted task: \(id)")
}

// MARK: - Enable fetchRecentlyDeletedTasks Method (Lines 267-282)
// Replace the current commented implementation:

/// Fetch recently deleted tasks (ENABLED)
func fetchRecentlyDeletedTasks() async throws -> [LifeTask] {
    let response: [LifeTask] = try await supabaseService.client
        .from(SupabaseService.TableName.tasks.rawValue)
        .select()
        .not("deleted_at", operator: .is, value: "null")  // Only deleted tasks
        .order("deleted_at", ascending: false)
        .execute()
        .value
    
    Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) recently deleted tasks")
    return response
}

// MARK: - Update fetchAllTasks to Exclude Soft Deleted (Line ~160)
// Ensure fetchAllTasks excludes soft deleted tasks:

/// Fetch all tasks (excludes soft deleted)
func fetchAllTasks() async throws -> [LifeTask] {
    let response: [LifeTask] = try await supabaseService.client
        .from(SupabaseService.TableName.tasks.rawValue)
        .select()
        .is("deleted_at", value: "null")  // IMPORTANT: Only non-deleted tasks
        .order("created_at", ascending: false)
        .execute()
        .value
    
    Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) active tasks")
    return response
}

// MARK: - Add Cleanup Method for Expired Tasks
// Add this new method to TaskRepository:

/// Cleanup tasks that are eligible for permanent deletion (24+ hours old)
func cleanupExpiredDeletedTasks() async throws -> Int {
    let recentlyDeleted = try await fetchRecentlyDeletedTasks()
    
    // Filter tasks that can be permanently deleted (24+ hours old)
    let eligibleForDeletion = recentlyDeleted.filter { task in
        task.canBePermanentlyDeleted
    }
    
    // Permanently delete eligible tasks
    for task in eligibleForDeletion {
        try await permanentlyDeleteTask(id: task.id)
        Logger.shared.info("TASK_REPOSITORY: Permanently deleted expired task: \(task.title)")
    }
    
    Logger.shared.info("TASK_REPOSITORY: Cleaned up \(eligibleForDeletion.count) expired tasks")
    return eligibleForDeletion.count
}

/*
INTEGRATION INSTRUCTIONS:

In TaskRepository.swift, make these changes:

1. Lines 254-265: Replace deleteTask() method with the soft delete version above
2. Lines 267-282: Replace fetchRecentlyDeletedTasks() with the enabled version above  
3. Update fetchAllTasks() to exclude soft deleted tasks (add .is("deleted_at", value: "null"))
4. Add the cleanupExpiredDeletedTasks() method
5. In ContentModels.swift line 119: Fix typo "canBePermalentlyDeleted" → "canBePermanentlyDeleted"

The database functions (soft_delete_task, restore_deleted_task, permanently_delete_task) already exist and work.
The TaskRetentionService.swift already exists and will automatically start the cleanup timer.

This enables the complete 24-hour retention system with zero database migration required.
*/