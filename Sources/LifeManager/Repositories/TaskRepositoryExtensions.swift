import Foundation

/// Extensions to TaskRepository for Focus View and Timeline View support
extension TaskRepository {
    
    // MARK: - Focus View Support Methods
    
    /// Fetch tasks due soon (within specified number of days)
    func fetchTasksDueSoon(days: Int = 3) async throws -> [LifeTask] {
        let calendar = Calendar.current
        let now = Date()
        let future = calendar.date(byAdding: .day, value: days, to: now) ?? Date()
        
        let isoFormatter = ISO8601DateFormatter()
        let nowString = isoFormatter.string(from: now)
        let futureString = isoFormatter.string(from: future)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .in("status", values: [TaskStatus.todo.rawValue, TaskStatus.inProgress.rawValue])
            .gte("due_date", value: nowString)
            .lte("due_date", value: futureString)
            .order("due_date", ascending: true)
            .order("priority", ascending: false)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks due in next \(days) days")
        return response
    }
    
    /// Fetch tasks created within the last specified number of days
    func fetchTasksCreatedInLast(days: Int) async throws -> [LifeTask] {
        let calendar = Calendar.current
        let now = Date()
        let pastDate = calendar.date(byAdding: .day, value: -days, to: now) ?? Date()
        
        let isoFormatter = ISO8601DateFormatter()
        let pastDateString = isoFormatter.string(from: pastDate)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .gte("created_at", value: pastDateString)
            .is("deleted_at", value: nil as String?)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks created in last \(days) days")
        return response
    }
    
    /// Fetch tasks for a specific project (alias for existing method)
    func fetchTasksForProject(_ projectId: UUID) async throws -> [LifeTask] {
        return try await fetchTasks(projectId: projectId)
    }
    
    /// Fetch tasks with focus flag set to true
    func fetchFocusTasksOnly() async throws -> [LifeTask] {
        return try await fetchFocusTasks()
    }
    
    // MARK: - Timeline View Support Methods
    
    /// Fetch tasks by multiple statuses
    func fetchTasks(statuses: [TaskStatus]) async throws -> [LifeTask] {
        let statusValues = statuses.map { $0.rawValue }
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .in("status", values: statusValues)
            .is("deleted_at", value: nil as String?)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks with statuses: \(statuses)")
        return response
    }
    
    /// Fetch tasks with due dates in a specific range
    func fetchTasksWithDueDateRange(from startDate: Date, to endDate: Date) async throws -> [LifeTask] {
        let isoFormatter = ISO8601DateFormatter()
        let startDateString = isoFormatter.string(from: startDate)
        let endDateString = isoFormatter.string(from: endDate)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .gte("due_date", value: startDateString)
            .lte("due_date", value: endDateString)
            .is("deleted_at", value: nil as String?)
            .order("due_date", ascending: true)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks with due dates in range")
        return response
    }
    
    /// Fetch tasks by area ID
    func fetchTasksForArea(_ areaId: UUID) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("area_id", value: areaId.uuidString)
            .is("deleted_at", value: nil as String?)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks for area \(areaId)")
        return response
    }
    
    /// Fetch tasks by resource ID
    func fetchTasksForResource(_ resourceId: UUID) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("resource_id", value: resourceId.uuidString)
            .is("deleted_at", value: nil as String?)
            .order("priority", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks for resource \(resourceId)")
        return response
    }
    
    // MARK: - Focus Session Analytics
    
    /// Get task completion velocity (average tasks completed per day)
    func getTaskCompletionVelocity(days: Int = 30) async throws -> Double {
        let completedTasks = try await fetchRecentlyCompletedTasks(days: days)
        return Double(completedTasks.count) / Double(days)
    }
    
    /// Get average task duration for completed tasks
    func getAverageTaskDuration() async throws -> Double {
        let completedTasks = try await fetchTasks(status: .completed)
        let durations = completedTasks.compactMap { $0.estimatedDuration }
        
        guard !durations.isEmpty else { return 0.0 }
        return Double(durations.reduce(0, +)) / Double(durations.count)
    }
    
    /// Get task completion pattern by time of day
    func getCompletionPatternByTimeOfDay() async throws -> [Int: Int] {
        let completedTasks = try await fetchTasks(status: .completed)
        var patterns: [Int: Int] = [:]
        
        let calendar = Calendar.current
        
        for task in completedTasks {
            guard let completedAtString = task.completedAt,
                  let completedDate = ISO8601DateFormatter().date(from: completedAtString) else {
                continue
            }
            
            let hour = calendar.component(.hour, from: completedDate)
            patterns[hour, default: 0] += 1
        }
        
        return patterns
    }
    
    /// Update task due date
    func updateTaskDueDate(id: UUID, dueDate: Date?) async throws -> LifeTask {
        guard let task = try await fetchTask(id: id) else {
            throw SupabaseError.notFound
        }
        
        let dueDateString = dueDate?.ISO8601Format()
        
        let updatedTask = LifeTask(
            id: task.id,
            blobId: task.blobId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: dueDateString,
            estimatedDuration: task.estimatedDuration,
            workPersonal: task.workPersonal,
            projectId: task.projectId,
            areaId: task.areaId,
            resourceId: task.resourceId,
            isFocus: task.isFocus,
            isArchived: task.isArchived,
            createdAt: task.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            completedAt: task.completedAt,
            archivedAt: task.archivedAt,
            deletedAt: task.deletedAt
        )
        
        return try await updateTask(updatedTask)
    }
    
    /// Batch update task statuses
    func batchUpdateTaskStatuses(taskIds: [UUID], status: TaskStatus) async throws -> [LifeTask] {
        var updatedTasks: [LifeTask] = []
        
        for taskId in taskIds {
            do {
                let updatedTask = try await updateTaskStatus(id: taskId, status: status)
                updatedTasks.append(updatedTask)
            } catch {
                Logger.shared.error("TASK_REPOSITORY: Failed to update task \(taskId): \(error)")
            }
        }
        
        Logger.shared.info("TASK_REPOSITORY: Batch updated \(updatedTasks.count) of \(taskIds.count) tasks to \(status)")
        return updatedTasks
    }
    
    /// Batch update task priorities
    func batchUpdateTaskPriorities(taskIds: [UUID], priority: TaskPriority) async throws -> [LifeTask] {
        var updatedTasks: [LifeTask] = []
        
        for taskId in taskIds {
            do {
                let updatedTask = try await updateTaskPriority(id: taskId, priority: priority)
                updatedTasks.append(updatedTask)
            } catch {
                Logger.shared.error("TASK_REPOSITORY: Failed to update priority for task \(taskId): \(error)")
            }
        }
        
        Logger.shared.info("TASK_REPOSITORY: Batch updated priority for \(updatedTasks.count) of \(taskIds.count) tasks to \(priority)")
        return updatedTasks
    }
    
    /// Batch defer tasks to a specific date
    func batchDeferTasks(taskIds: [UUID], to deferDate: Date) async throws -> [LifeTask] {
        var updatedTasks: [LifeTask] = []
        
        for taskId in taskIds {
            do {
                let updatedTask = try await updateTaskDueDate(id: taskId, dueDate: deferDate)
                updatedTasks.append(updatedTask)
            } catch {
                Logger.shared.error("TASK_REPOSITORY: Failed to defer task \(taskId): \(error)")
            }
        }
        
        Logger.shared.info("TASK_REPOSITORY: Batch deferred \(updatedTasks.count) of \(taskIds.count) tasks to \(deferDate)")
        return updatedTasks
    }
    
    // MARK: - Additional Query Methods
    
    /// Fetch projects (delegates to ProjectRepository)
    func fetchProjects() async throws -> [Project] {
        let projectRepository = ProjectRepository()
        return try await projectRepository.fetchAllProjects()
    }
    
    // MARK: - Intelligent Automation Support Methods
    
    /// Fetch stagnant tasks (tasks in inbox for more than specified hours without due date)
    func fetchStagnantTasks(hours: Int = 72) async throws -> [LifeTask] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()
        let cutoffString = isoFormatter.string(from: cutoffDate)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("status", value: TaskStatus.inbox.rawValue)
            .is("due_date", value: nil)
            .lt("created_at", value: cutoffString)
            .is("deleted_at", value: nil as String?)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) stagnant tasks older than \(hours) hours")
        return response
    }
    
    /// Fetch tasks by multiple tags
    func fetchTasksByTags(_ tags: [String]) async throws -> [LifeTask] {
        // Note: This assumes tags are stored as a JSON array in the tags column
        // Implementation may need adjustment based on actual schema
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .is("deleted_at", value: nil as String?)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Filter by tags in memory (could be optimized with PostgreSQL JSON queries)
        let filteredTasks = response.filter { task in
            return tags.allSatisfy { tag in
                task.tags?.contains(tag) ?? false
            }
        }
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(filteredTasks.count) tasks matching tags: \(tags)")
        return filteredTasks
    }
    
    /// Fetch tasks with specific estimated durations
    func fetchTasksByDurationRange(min: Int? = nil, max: Int? = nil) async throws -> [LifeTask] {
        var query = supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .is("deleted_at", value: nil as String?)
        
        if let min = min {
            query = query.gte("estimated_duration", value: min)
        }
        
        if let max = max {
            query = query.lte("estimated_duration", value: max)
        }
        
        let response: [LifeTask] = try await query
            .order("estimated_duration", ascending: true)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks with duration range \(min ?? 0)-\(max ?? Int.max)")
        return response
    }
    
    /// Fetch tasks that haven't been updated in specified days (for staleness detection)
    func fetchStaleTasksOlderThan(days: Int) async throws -> [LifeTask] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()
        let cutoffString = isoFormatter.string(from: cutoffDate)
        
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .in("status", values: [TaskStatus.todo.rawValue, TaskStatus.inProgress.rawValue])
            .lt("updated_at", value: cutoffString)
            .is("deleted_at", value: nil as String?)
            .order("updated_at", ascending: true)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) stale tasks older than \(days) days")
        return response
    }
    
    /// Fetch tasks by priority and work/personal filter (for intelligence scoring)
    func fetchTasksWithPriorityAndType(
        priority: TaskPriority,
        workPersonal: WorkPersonalType
    ) async throws -> [LifeTask] {
        let response: [LifeTask] = try await supabaseService.client
            .from(SupabaseService.TableName.tasks.rawValue)
            .select()
            .eq("priority", value: priority.rawValue)
            .eq("work_personal", value: workPersonal.rawValue)
            .is("deleted_at", value: nil as String?)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        Logger.shared.debug("TASK_REPOSITORY: Fetched \(response.count) tasks with priority \(priority) and type \(workPersonal)")
        return response
    }
}