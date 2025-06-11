import Foundation

/// Repository for managing LifeTask data operations
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
    
    /// Fetch all tasks
    func fetchAllTasks() async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch task by ID
    func fetchTask(id: UUID) async throws -> LifeTask? {
        return try await supabaseService.fetchById(LifeTask.self, from: SupabaseService.TableName.tasks.rawValue, id: id)
    }
    
    /// Fetch tasks by status
    func fetchTasks(status: TaskStatus) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("status", value: status.rawValue)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch tasks by priority
    func fetchTasks(priority: TaskPriority) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("priority", value: priority.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch tasks by work/personal filter
    func fetchTasks(workPersonal: WorkPersonalType) async throws -> [LifeTask] {
        return try await supabaseService.fetchByWorkPersonal(
            LifeTask.self,
            from: SupabaseService.TableName.tasks.rawValue,
            workPersonal: workPersonal
        )
    }
    
    /// Fetch tasks by project
    func fetchTasks(projectId: UUID) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch inbox tasks (status = inbox)
    func fetchInboxTasks() async throws -> [LifeTask] {
        return try await fetchTasks(status: .inbox)
    }
    
    /// Fetch active tasks (todo + in_progress)
    func fetchActiveTasks() async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .in("status", values: [TaskStatus.todo.rawValue, TaskStatus.inProgress.rawValue])
            .order("priority", ascending: false)
            .order("due_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch overdue tasks
    func fetchOverdueTasks() async throws -> [LifeTask] {
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        let nowString = isoFormatter.string(from: now)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .in("status", values: [TaskStatus.todo.rawValue, TaskStatus.inProgress.rawValue])
            .lt("due_date", value: nowString)
            .order("due_date", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch tasks due today
    func fetchTasksDueToday() async throws -> [LifeTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let isoFormatter = ISO8601DateFormatter()
        let todayString = isoFormatter.string(from: today)
        let tomorrowString = isoFormatter.string(from: tomorrow)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .in("status", values: [TaskStatus.todo.rawValue, TaskStatus.inProgress.rawValue])
            .gte("due_date", value: todayString)
            .lt("due_date", value: tomorrowString)
            .order("priority", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Update task
    func updateTask(_ task: LifeTask) async throws -> LifeTask {
        return try await supabaseService.update(
            task,
            in: SupabaseService.TableName.tasks.rawValue,
            matching: "id",
            value: task.id.uuidString
        )
    }
    
    /// Update task status
    func updateTaskStatus(id: UUID, status: TaskStatus) async throws -> LifeTask {
        guard let task = try await fetchTask(id: id) else {
            throw SupabaseError.notFound
        }
        
        let completedAt = (status == .completed) ? ISO8601DateFormatter().string(from: Date()) : nil
        
        let updatedTask = LifeTask(
            id: task.id,
            blobId: task.blobId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: status,
            dueDate: task.dueDate,
            estimatedDuration: task.estimatedDuration,
            workPersonal: task.workPersonal,
            projectId: task.projectId,
            createdAt: task.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            completedAt: completedAt
        )
        
        return try await updateTask(updatedTask)
    }
    
    /// Update task priority
    func updateTaskPriority(id: UUID, priority: TaskPriority) async throws -> LifeTask {
        guard let task = try await fetchTask(id: id) else {
            throw SupabaseError.notFound
        }
        
        let updatedTask = LifeTask(
            id: task.id,
            blobId: task.blobId,
            title: task.title,
            description: task.description,
            priority: priority,
            status: task.status,
            dueDate: task.dueDate,
            estimatedDuration: task.estimatedDuration,
            workPersonal: task.workPersonal,
            projectId: task.projectId,
            createdAt: task.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            completedAt: task.completedAt
        )
        
        return try await updateTask(updatedTask)
    }
    
    /// Soft delete task (move to recently deleted for 24 hours)
    func softDeleteTask(id: UUID) async throws {
        try await supabaseService.client
            .rpc("soft_delete_task", params: ["task_id": id.uuidString])
            .execute()
    }
    
    /// Restore a soft deleted task
    func restoreDeletedTask(id: UUID) async throws {
        try await supabaseService.client
            .rpc("restore_deleted_task", params: ["task_id": id.uuidString])
            .execute()
    }
    
    /// Permanently delete task immediately
    func permanentlyDeleteTask(id: UUID) async throws {
        try await supabaseService.client
            .rpc("permanently_delete_task", params: ["task_id": id.uuidString])
            .execute()
    }
    
    /// Delete task (temporarily using hard delete until migration is applied)
    func deleteTask(id: UUID) async throws {
        // TODO: Switch back to soft delete after migration is applied
        // try await softDeleteTask(id: id)
        
        // Temporarily use hard delete until database migration is applied
        try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Fetch recently deleted tasks
    func fetchRecentlyDeletedTasks() async throws -> [LifeTask] {
        // TODO: Implement after migration is applied
        // let response: [LifeTask] = try await supabaseService.client
        //     .from(SupabaseService.TableName.tasks.rawValue)
        //     .select()
        //     .not("deleted_at", operator: .is, value: "null")
        //     .order("deleted_at", ascending: false)
        //     .execute()
        //     .value
        // 
        // return response
        
        // Temporarily return empty array until database migration is applied
        return []
    }
    
    /// Clean up permanently deleted tasks (called manually or via scheduled job)
    func cleanupPermanentlyDeletedTasks() async throws {
        try await supabaseService.client
            .rpc("cleanup_permanently_deleted_tasks")
            .execute()
    }
    
    // MARK: - Tag Operations
    
    /// Assign tag to task
    func assignTag(taskId: UUID, tagId: UUID) async throws -> TaskTag {
        let taskTag = TaskTag(taskId: taskId, tagId: tagId)
        return try await supabaseService.insert(taskTag, into: SupabaseService.TableName.taskTags.rawValue)
    }
    
    /// Fetch task tags
    func fetchTaskTags(taskId: UUID) async throws -> [TaskTag] {
        let response: [TaskTag] = try await supabaseService.client
            .from(SupabaseService.TableName.taskTags.rawValue)
            .select()
            .eq("task_id", value: taskId.uuidString)
            .execute()
            .value
        
        return response
    }
    
    /// Remove tag from task
    func removeTag(taskId: UUID, tagId: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.taskTags.rawValue)
            .delete()
            .eq("task_id", value: taskId.uuidString)
            .eq("tag_id", value: tagId.uuidString)
            .execute()
    }
    
    // MARK: - Search Operations
    
    /// Search tasks by title and description
    func searchTasks(query: String) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Search tasks with filters
    func searchTasks(
        query: String,
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        workPersonal: WorkPersonalType? = nil,
        projectId: UUID? = nil
    ) async throws -> [LifeTask] {
        var queryBuilder = supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
        
        if let status = status {
            queryBuilder = queryBuilder.eq("status", value: status.rawValue)
        }
        
        if let priority = priority {
            queryBuilder = queryBuilder.eq("priority", value: priority.rawValue)
        }
        
        if let workPersonal = workPersonal {
            queryBuilder = queryBuilder.eq("work_personal", value: workPersonal.rawValue)
        }
        
        if let projectId = projectId {
            queryBuilder = queryBuilder.eq("project_id", value: projectId.uuidString)
        }
        
        let response: [LifeTask] = try await queryBuilder
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Analytics and Reporting
    
    /// Get task count by status
    func getTaskCountByStatus() async throws -> [String: Int] {
        let tasks = try await fetchAllTasks()
        var counts: [String: Int] = [:]
        
        for task in tasks {
            let status = task.status.rawValue
            counts[status, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get task count by priority
    func getTaskCountByPriority() async throws -> [String: Int] {
        let tasks = try await fetchAllTasks()
        var counts: [String: Int] = [:]
        
        for task in tasks {
            let priority = task.priority.rawValue
            counts[priority, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get completed tasks for a date range
    func getCompletedTasks(from startDate: Date, to endDate: Date) async throws -> [LifeTask] {
        let isoFormatter = ISO8601DateFormatter()
        let startDateString = isoFormatter.string(from: startDate)
        let endDateString = isoFormatter.string(from: endDate)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("status", value: TaskStatus.completed.rawValue)
            .gte("completed_at", value: startDateString)
            .lte("completed_at", value: endDateString)
            .order("completed_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Get productivity metrics
    func getProductivityMetrics(days: Int = 30) async throws -> (completed: Int, total: Int, percentage: Double) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? Date()
        
        let isoFormatter = ISO8601DateFormatter()
        let startDateString = isoFormatter.string(from: startDate)
        
        let allTasks: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .gte("created_at", value: startDateString)
            .execute()
            .value
        
        let completedTasks = allTasks.filter { $0.status == .completed }
        let total = allTasks.count
        let completed = completedTasks.count
        let percentage = total > 0 ? Double(completed) / Double(total) * 100 : 0
        
        return (completed: completed, total: total, percentage: percentage)
    }
    
    /// Fetch focus tasks
    func fetchFocusTasks() async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("is_focus", value: true)
            .eq("is_archived", value: false)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
} 