import Foundation
import SwiftUI
import UserNotifications

/// Proactive Notification Engine
/// Phase 3: Enhanced Notifications & Proactive Support
/// Provides intelligent, context-aware notifications with personalized timing
@MainActor
class ProactiveNotificationEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let contextMemory = ContextMemoryService.shared
    private let personalRules = PersonalRulesService.shared
    private let llmService = LLMServiceCoordinator.shared
    private let notificationService = NotificationService.shared
    private let advancedNotificationService = AdvancedNotificationService.shared
    private let intelligentRescheduling = IntelligentReschedulingService.shared
    private let logger = Logger.shared
    
    // MARK: - Private Properties
    
    private let taskRepository = TaskRepository()
    private let projectRepository = ProjectRepository()
    private let areaRepository = AreaRepository()
    
    private var proactiveTimer: Timer?
    private var notificationOptimizer = NotificationOptimizer()
    
    // MARK: - Published State
    
    @Published var isActive = false
    @Published var pendingNotifications: [ProactiveNotification] = []
    @Published var notificationStats = NotificationStatistics()
    @Published var userPreferences = [NotificationType: NotificationPreference]()
    
    // MARK: - Configuration
    
    private let proactiveCheckInterval: TimeInterval = 1800 // 30 minutes
    private let gentleNudgeThreshold: TimeInterval = 259200 // 3 days
    private let stagnantTaskThreshold: TimeInterval = 172800 // 2 days
    
    // MARK: - Initialization
    
    init() {
        logger.info("PROACTIVE_NOTIFICATIONS: Engine initialized")
        loadUserPreferences()
        startProactiveEngine()
    }
    
    deinit {
        stopProactiveEngine()
    }
    
    // MARK: - Proactive Engine Management
    
    /// Start the proactive notification engine
    func startProactiveEngine() {
        guard !isActive else { return }
        
        logger.info("PROACTIVE_NOTIFICATIONS: Starting proactive engine")
        isActive = true
        
        // Initial scan
        Task {
            await performProactiveAnalysis()
        }
        
        // Set up periodic analysis
        proactiveTimer = Timer.scheduledTimer(withTimeInterval: proactiveCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performProactiveAnalysis()
            }
        }
        
        // Schedule daily and weekly summaries
        scheduleDailySummaries()
        scheduleWeeklySummaries()
    }
    
    /// Stop the proactive notification engine
    func stopProactiveEngine() {
        logger.info("PROACTIVE_NOTIFICATIONS: Stopping proactive engine")
        isActive = false
        proactiveTimer?.invalidate()
        proactiveTimer = nil
    }
    
    // MARK: - Proactive Analysis
    
    /// Perform comprehensive proactive analysis
    private func performProactiveAnalysis() async {
        logger.debug("PROACTIVE_NOTIFICATIONS: Starting proactive analysis")
        
        do {
            // Get current context
            let context = await contextMemory.getCurrentContext()
            
            // Analyze different types of proactive opportunities
            async let stagnantTaskAnalysis = analyzeStagnantTasks()
            async let overdueAnalysis = analyzeOverdueTasks()
            async let planningOpportunities = analyzePlanningOpportunities(context: context)
            async let achievementOpportunities = analyzeAchievements(context: context)
            async let contextualSuggestions = generateContextualSuggestions(context: context)
            
            // Wait for all analyses to complete
            let (stagnantTasks, overdueTasks, planningOps, achievements, suggestions) = await (
                stagnantTaskAnalysis,
                overdueAnalysis,
                planningOpportunities,
                achievementOpportunities,
                contextualSuggestions
            )
            
            // Generate notifications based on analysis
            var newNotifications: [ProactiveNotification] = []
            newNotifications.append(contentsOf: stagnantTasks)
            newNotifications.append(contentsOf: overdueTasks)
            newNotifications.append(contentsOf: planningOps)
            newNotifications.append(contentsOf: achievements)
            newNotifications.append(contentsOf: suggestions)
            
            // Optimize notification timing and delivery
            let optimizedNotifications = await notificationOptimizer.optimizeNotifications(
                newNotifications,
                userPreferences: userPreferences,
                context: context
            )
            
            // Schedule optimized notifications
            for notification in optimizedNotifications {
                await scheduleProactiveNotification(notification)
            }
            
            logger.success("PROACTIVE_NOTIFICATIONS: Generated \(optimizedNotifications.count) proactive notifications")
            
        } catch {
            logger.error("PROACTIVE_NOTIFICATIONS: Failed proactive analysis: \(error)")
        }
    }
    
    // MARK: - Analysis Methods
    
    /// Analyze tasks that have been stagnant
    private func analyzeStagnantTasks() async -> [ProactiveNotification] {
        var notifications: [ProactiveNotification] = []
        
        do {
            let allTasks = try await taskRepository.fetchAllTasks()
            let stagnantTasks = allTasks.filter { task in
                guard let createdDate = ISO8601DateFormatter().date(from: task.createdAt) else {
                    return false
                }
                let hoursSinceCreation = Date().timeIntervalSince(createdDate) / 3600
                return hoursSinceCreation > 48 && task.status == .inbox && task.dueDate == nil
            }
            
            for task in stagnantTasks.prefix(3) { // Limit to 3 to avoid spam
                let notification = await createStagnantTaskNotification(task)
                notifications.append(notification)
            }
            
        } catch {
            logger.error("PROACTIVE_NOTIFICATIONS: Failed to analyze stagnant tasks: \(error)")
        }
        
        return notifications
    }
    
    /// Analyze overdue tasks for gentle nudges
    private func analyzeOverdueTasks() async -> [ProactiveNotification] {
        var notifications: [ProactiveNotification] = []
        
        do {
            let overdueTasks = try await taskRepository.fetchOverdueTasks()
            
            for task in overdueTasks.prefix(5) { // Limit to prevent notification overload
                // Check if we've already sent a gentle nudge recently
                let recentNudge = pendingNotifications.contains { notification in
                    notification.notificationType == .gentleNudge &&
                    notification.contextData["task_id"]?.description == task.id.uuidString
                }
                
                if !recentNudge {
                    let notification = await createOverdueTaskNotification(task)
                    notifications.append(notification)
                }
            }
            
        } catch {
            logger.error("PROACTIVE_NOTIFICATIONS: Failed to analyze overdue tasks: \(error)")
        }
        
        return notifications
    }
    
    /// Analyze opportunities for planning reminders
    private func analyzePlanningOpportunities(context: ProcessingContext) async -> [ProactiveNotification] {
        var notifications: [ProactiveNotification] = []
        
        // Check if user has unprocessed brain dumps
        if context.recentActivityItems.filter({ !$0.isCompleted }).count > 5 {
            let notification = await createBrainDumpProcessingReminder(context: context)
            notifications.append(notification)
        }
        
        // Check for optimal planning time
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour == 8 || currentHour == 17 { // Morning or end of day
            let notification = await createPlanningTimeReminder(context: context)
            notifications.append(notification)
        }
        
        return notifications
    }
    
    /// Analyze achievements to celebrate
    private func analyzeAchievements(context: ProcessingContext) async -> [ProactiveNotification] {
        var notifications: [ProactiveNotification] = []
        
        do {
            // Check for recently completed high-priority tasks
            let recentlyCompleted = try await taskRepository.fetchRecentlyCompletedTasks(days: 1)
            let highPriorityCompleted = recentlyCompleted.filter { $0.priority == .urgent || $0.priority == .high }
            
            if highPriorityCompleted.count >= 3 {
                let notification = await createAchievementCelebration(tasks: highPriorityCompleted)
                notifications.append(notification)
            }
            
            // Check for project milestones (simplified)
            let completedProjects = try await projectRepository.fetchRecentlyCompletedProjects(days: 7)
            if !completedProjects.isEmpty {
                let notification = await createProjectCompletionCelebration(projects: completedProjects)
                notifications.append(notification)
            }
            
        } catch {
            logger.error("PROACTIVE_NOTIFICATIONS: Failed to analyze achievements: \(error)")
        }
        
        return notifications
    }
    
    /// Generate contextual suggestions based on current situation
    private func generateContextualSuggestions(context: ProcessingContext) async -> [ProactiveNotification] {
        var notifications: [ProactiveNotification] = []
        
        // Buffer analysis suggestion
        let reschedulingStats = await intelligentRescheduling.getReschedulingStatistics()
        if reschedulingStats.conflictResolutions > 3 {
            let notification = await createBufferOptimizationSuggestion(stats: reschedulingStats)
            notifications.append(notification)
        }
        
        // Time block optimization
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 9 && currentHour <= 11 && context.recentActivityItems.isEmpty {
            let notification = await createFocusTimeOpportunity()
            notifications.append(notification)
        }
        
        return notifications
    }
    
    // MARK: - Notification Creation
    
    /// Create stagnant task notification
    private func createStagnantTaskNotification(_ task: LifeTask) async -> ProactiveNotification {
        let daysSinceCreation = task.overdueByHours / 24
        
        let title = "Task Needs Attention"
        let body = "\"\(task.title)\" has been waiting for \(Int(daysSinceCreation)) days. Ready to schedule it?"
        
        let optimalTime = await notificationOptimizer.findOptimalNotificationTime(
            for: .gentleNudge,
            userPreferences: userPreferences
        )
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .gentleNudge,
            title: title,
            body: body,
            contextData: [
                "task_id": .string(task.id.uuidString),
                "task_title": .string(task.title),
                "days_stagnant": .double(daysSinceCreation),
                "action_type": .string("schedule_task")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: optimalTime)
        )
    }
    
    /// Create overdue task notification
    private func createOverdueTaskNotification(_ task: LifeTask) async -> ProactiveNotification {
        let hoursOverdue = task.overdueByHours
        
        let title = "Gentle Reminder"
        let body = "\"\(task.title)\" was due \(Int(hoursOverdue)) hours ago. Would you like me to reschedule it?"
        
        let optimalTime = await notificationOptimizer.findOptimalNotificationTime(
            for: .overdueReminder,
            userPreferences: userPreferences
        )
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .overdueReminder,
            title: title,
            body: body,
            contextData: [
                "task_id": .string(task.id.uuidString),
                "task_title": .string(task.title),
                "hours_overdue": .double(hoursOverdue),
                "action_type": .string("reschedule_task"),
                "can_auto_reschedule": .bool(task.canBeAutomaticallyRescheduled)
            ],
            scheduledFor: ISO8601DateFormatter().string(from: optimalTime)
        )
    }
    
    /// Create brain dump processing reminder
    private func createBrainDumpProcessingReminder(context: ProcessingContext) async -> ProactiveNotification {
        let unprocessedCount = context.recentActivityItems.filter { !$0.isCompleted }.count
        
        let title = "Time to Organize"
        let body = "You have \(unprocessedCount) unprocessed items. Perfect time for a quick brain dump review!"
        
        let optimalTime = await notificationOptimizer.findOptimalNotificationTime(
            for: .planningReminder,
            userPreferences: userPreferences
        )
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .planningReminder,
            title: title,
            body: body,
            contextData: [
                "unprocessed_count": .int(unprocessedCount),
                "action_type": .string("process_brain_dump")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: optimalTime)
        )
    }
    
    /// Create planning time reminder
    private func createPlanningTimeReminder(context: ProcessingContext) async -> ProactiveNotification {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let timeOfDay = currentHour < 12 ? "morning" : "evening"
        
        let title = "Perfect Planning Time"
        let body = "Based on your patterns, this is an ideal \(timeOfDay) for reviewing and organizing your tasks."
        
        // Schedule for immediate delivery since it's context-specific
        let now = Date()
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .planningReminder,
            title: title,
            body: body,
            contextData: [
                "time_of_day": .string(timeOfDay),
                "current_hour": .int(currentHour),
                "action_type": .string("daily_planning")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: now)
        )
    }
    
    /// Create achievement celebration
    private func createAchievementCelebration(tasks: [LifeTask]) async -> ProactiveNotification {
        let taskCount = tasks.count
        let priorityTasks = tasks.filter { $0.priority == .urgent }.count
        
        let title = "Great Progress! 🎉"
        let body = "You completed \(taskCount) high-priority tasks today\(priorityTasks > 0 ? ", including \(priorityTasks) urgent ones" : "")!"
        
        let optimalTime = await notificationOptimizer.findOptimalNotificationTime(
            for: .achievementCelebration,
            userPreferences: userPreferences
        )
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .achievementCelebration,
            title: title,
            body: body,
            contextData: [
                "tasks_completed": .int(taskCount),
                "urgent_tasks": .int(priorityTasks),
                "action_type": .string("celebrate_achievement")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: optimalTime)
        )
    }
    
    /// Create project completion celebration
    private func createProjectCompletionCelebration(projects: [Project]) async -> ProactiveNotification {
        let projectCount = projects.count
        let projectNames = projects.prefix(2).map { $0.name }.joined(separator: ", ")
        
        let title = "Project Success! 🚀"
        let body = "Congratulations on completing \(projectCount == 1 ? "project" : "\(projectCount) projects"): \(projectNames)\(projectCount > 2 ? " and others" : "")!"
        
        let optimalTime = await notificationOptimizer.findOptimalNotificationTime(
            for: .achievementCelebration,
            userPreferences: userPreferences
        )
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .achievementCelebration,
            title: title,
            body: body,
            contextData: [
                "projects_completed": .int(projectCount),
                "project_names": .string(projectNames),
                "action_type": .string("celebrate_project")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: optimalTime)
        )
    }
    
    /// Create buffer optimization suggestion
    private func createBufferOptimizationSuggestion(stats: ReschedulingStatistics) async -> ProactiveNotification {
        let title = "Schedule Optimization Tip"
        let body = "I've rescheduled \(stats.conflictResolutions) tasks today. Consider adding more buffer time to prevent conflicts."
        
        let optimalTime = await notificationOptimizer.findOptimalNotificationTime(
            for: .contextualSuggestion,
            userPreferences: userPreferences
        )
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .contextualSuggestion,
            title: title,
            body: body,
            contextData: [
                "conflicts_resolved": .int(stats.conflictResolutions),
                "success_rate": .double(stats.successRate),
                "action_type": .string("optimize_buffers")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: optimalTime)
        )
    }
    
    /// Create focus time opportunity notification
    private func createFocusTimeOpportunity() async -> ProactiveNotification {
        let title = "Perfect Focus Time 🎯"
        let body = "Your calendar looks clear and this is your peak focus time. Ready for some deep work?"
        
        // Schedule for immediate delivery since it's time-sensitive
        let now = Date()
        
        return ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .contextualSuggestion,
            title: title,
            body: body,
            contextData: [
                "opportunity_type": .string("focus_time"),
                "current_hour": .int(Calendar.current.component(.hour, from: Date())),
                "action_type": .string("start_focus_session")
            ],
            scheduledFor: ISO8601DateFormatter().string(from: now)
        )
    }
    
    // MARK: - Daily and Weekly Summaries
    
    /// Schedule daily summary notifications
    private func scheduleDailySummaries() {
        // Schedule for 6 PM daily
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        Task {
            await scheduleDailySummaryWithTrigger(trigger)
        }
    }
    
    /// Schedule weekly summary notifications
    private func scheduleWeeklySummaries() {
        // Schedule for Sunday at 7 PM
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        Task {
            await scheduleWeeklySummaryWithTrigger(trigger)
        }
    }
    
    /// Create and schedule daily summary
    private func scheduleDailySummaryWithTrigger(_ trigger: UNCalendarNotificationTrigger) async {
        let summary = await generateDailySummary()
        
        let notification = ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .dailySummary,
            title: summary.title,
            body: summary.body,
            contextData: summary.contextData,
            scheduledFor: ISO8601DateFormatter().string(from: Date().addingTimeInterval(300)) // 5 minutes from now for testing
        )
        
        await scheduleProactiveNotification(notification)
    }
    
    /// Create and schedule weekly summary
    private func scheduleWeeklySummaryWithTrigger(_ trigger: UNCalendarNotificationTrigger) async {
        let summary = await generateWeeklySummary()
        
        let notification = ProactiveNotification(
            userId: getCurrentUserId(),
            notificationType: .weeklySummary,
            title: summary.title,
            body: summary.body,
            contextData: summary.contextData,
            scheduledFor: ISO8601DateFormatter().string(from: Date().addingTimeInterval(600)) // 10 minutes from now for testing
        )
        
        await scheduleProactiveNotification(notification)
    }
    
    // MARK: - Summary Generation
    
    /// Generate daily summary
    private func generateDailySummary() async -> NotificationSummary {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
            
            // Get today's completed tasks
            let completedTasks = try await taskRepository.fetchTasksCompletedBetween(start: today, end: tomorrow)
            
            // Get today's activity summary
            let context = await contextMemory.getCurrentContext()
            
            let title = "Day Complete ✅"
            let completedCount = completedTasks.count
            
            var body: String
            if completedCount == 0 {
                body = "No tasks completed today, but tomorrow is a fresh start!"
            } else if completedCount == 1 {
                body = "Completed 1 task today. Great progress!"
            } else {
                body = "Completed \(completedCount) tasks today. Excellent work!"
            }
            
            // Add high-priority completion bonus
            let highPriorityCount = completedTasks.filter { $0.priority == .urgent || $0.priority == .high }.count
            if highPriorityCount > 0 {
                body += " Including \(highPriorityCount) high-priority task\(highPriorityCount == 1 ? "" : "s")."
            }
            
            let contextData: [String: AnyCodableValue] = [
                "completed_tasks": .int(completedCount),
                "high_priority_completed": .int(highPriorityCount),
                "action_type": .string("daily_summary")
            ]
            
            return NotificationSummary(title: title, body: body, contextData: contextData)
            
        } catch {
            logger.error("PROACTIVE_NOTIFICATIONS: Failed to generate daily summary: \(error)")
            return NotificationSummary(
                title: "End of Day",
                body: "Hope you had a productive day!",
                contextData: ["action_type": .string("daily_summary")]
            )
        }
    }
    
    /// Generate weekly summary
    private func generateWeeklySummary() async -> NotificationSummary {
        do {
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            
            // Get week's completed tasks
            let completedTasks = try await taskRepository.fetchTasksCompletedBetween(start: weekAgo, end: now)
            
            // Get completed projects
            let completedProjects = try await projectRepository.fetchProjectsCompletedBetween(start: weekAgo, end: now)
            
            let title = "Week in Review 📊"
            
            var accomplishments: [String] = []
            
            if completedTasks.count > 0 {
                accomplishments.append("\(completedTasks.count) tasks completed")
            }
            
            if completedProjects.count > 0 {
                accomplishments.append("\(completedProjects.count) project\(completedProjects.count == 1 ? "" : "s") finished")
            }
            
            let body: String
            if accomplishments.isEmpty {
                body = "This week was about planning and preparation. Ready to make next week productive!"
            } else {
                body = "Great week! " + accomplishments.joined(separator: ", ") + ". Keep up the momentum!"
            }
            
            let contextData: [String: AnyCodableValue] = [
                "completed_tasks": .int(completedTasks.count),
                "completed_projects": .int(completedProjects.count),
                "action_type": .string("weekly_summary")
            ]
            
            return NotificationSummary(title: title, body: body, contextData: contextData)
            
        } catch {
            logger.error("PROACTIVE_NOTIFICATIONS: Failed to generate weekly summary: \(error)")
            return NotificationSummary(
                title: "Week in Review",
                body: "Hope you had a productive week!",
                contextData: ["action_type": .string("weekly_summary")]
            )
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule a proactive notification
    private func scheduleProactiveNotification(_ notification: ProactiveNotification) async {
        guard let scheduledDate = ISO8601DateFormatter().date(from: notification.scheduledFor) else {
            logger.error("PROACTIVE_NOTIFICATIONS: Invalid scheduled date for notification")
            return
        }
        
        // Check if this is a duplicate notification
        let isDuplicate = pendingNotifications.contains { pending in
            pending.notificationType == notification.notificationType &&
            String(describing: pending.contextData["task_id"]) == String(describing: notification.contextData["task_id"])
        }
        
        if isDuplicate {
            logger.debug("PROACTIVE_NOTIFICATIONS: Skipping duplicate notification")
            return
        }
        
        // Add to pending notifications
        pendingNotifications.append(notification)
        
        // Schedule with system notification service
        let delay = scheduledDate.timeIntervalSinceNow
        if delay > 0 {
            notificationService.sendLocalNotification(
                title: notification.title,
                body: notification.body,
                category: .proactiveNotification,
                delay: delay
            )
            
            logger.info("PROACTIVE_NOTIFICATIONS: Scheduled \(notification.notificationType.displayName) for \(String(format: "%.1f", delay/60)) minutes from now")
        } else {
            // Send immediately if scheduled time has passed
            notificationService.sendLocalNotification(
                title: notification.title,
                body: notification.body,
                category: .proactiveNotification,
                delay: 0
            )
            
            logger.info("PROACTIVE_NOTIFICATIONS: Sent immediate \(notification.notificationType.displayName)")
        }
        
        // Update statistics
        notificationStats.totalSent += 1
        notificationStats.byType[notification.notificationType, default: 0] += 1
    }
    
    // MARK: - User Preferences
    
    /// Load user notification preferences
    private func loadUserPreferences() {
        // Initialize with default preferences
        for notificationType in NotificationType.allCases {
            userPreferences[notificationType] = NotificationPreference(
                userId: getCurrentUserId(),
                notificationType: notificationType,
                isEnabled: true,
                frequency: .asNeeded
            )
        }
        
        // Load saved preferences from UserDefaults or database
        // This would be implemented with actual preference storage
        
        logger.info("PROACTIVE_NOTIFICATIONS: Loaded user preferences")
    }
    
    /// Update user preference for a notification type
    func updateNotificationPreference(_ preference: NotificationPreference) {
        userPreferences[preference.notificationType] = preference
        
        // Save to persistent storage
        // This would be implemented with actual preference storage
        
        logger.info("PROACTIVE_NOTIFICATIONS: Updated preference for \(preference.notificationType.displayName)")
    }
    
    // MARK: - Utility Methods
    
    /// Get current user ID
    private func getCurrentUserId() -> String {
        // This would get the actual current user ID
        return "current_user"
    }
    
    /// Clean up old pending notifications
    func cleanupOldNotifications() {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        
        let beforeCount = pendingNotifications.count
        pendingNotifications = pendingNotifications.filter { notification in
            guard let scheduledDate = ISO8601DateFormatter().date(from: notification.scheduledFor) else {
                return false
            }
            return scheduledDate > oneWeekAgo
        }
        
        let cleanedCount = beforeCount - pendingNotifications.count
        if cleanedCount > 0 {
            logger.debug("PROACTIVE_NOTIFICATIONS: Cleaned up \(cleanedCount) old notifications")
        }
    }
    
    /// Get notification statistics
    func getNotificationStatistics() -> NotificationStatistics {
        return notificationStats
    }
    
    /// Reset notification statistics
    func resetStatistics() {
        notificationStats = NotificationStatistics()
        logger.info("PROACTIVE_NOTIFICATIONS: Statistics reset")
    }
}

// MARK: - Supporting Data Structures

/// Notification summary for daily/weekly reports
struct NotificationSummary {
    let title: String
    let body: String
    let contextData: [String: AnyCodableValue]
}

/// Notification statistics tracking
struct NotificationStatistics {
    var totalSent: Int = 0
    var totalOpened: Int = 0
    var totalActedUpon: Int = 0
    var byType: [NotificationType: Int] = [:]
    var averageResponseTime: TimeInterval = 0
    var lastReset: Date = Date()
    
    var openRate: Double {
        return totalSent > 0 ? Double(totalOpened) / Double(totalSent) : 0.0
    }
    
    var actionRate: Double {
        return totalOpened > 0 ? Double(totalActedUpon) / Double(totalOpened) : 0.0
    }
}

/// Notification optimizer for timing and delivery
class NotificationOptimizer {
    
    /// Optimize notification timing and delivery
    func optimizeNotifications(
        _ notifications: [ProactiveNotification],
        userPreferences: [NotificationType: NotificationPreference],
        context: ProcessingContext
    ) async -> [ProactiveNotification] {
        
        var optimized: [ProactiveNotification] = []
        
        for notification in notifications {
            // Check if notification type is enabled
            guard let preference = userPreferences[notification.notificationType],
                  preference.isEnabled else {
                continue
            }
            
            // Apply frequency limits
            if shouldSkipDueToFrequency(notification, preference: preference) {
                continue
            }
            
            // Optimize timing
            let optimizedNotification = await optimizeNotificationTiming(
                notification,
                preference: preference,
                context: context
            )
            
            optimized.append(optimizedNotification)
        }
        
        return optimized
    }
    
    /// Find optimal notification time based on user patterns
    func findOptimalNotificationTime(
        for type: NotificationType,
        userPreferences: [NotificationType: NotificationPreference]
    ) async -> Date {
        
        guard let preference = userPreferences[type] else {
            return Date().addingTimeInterval(300) // Default 5 minutes from now
        }
        
        // Use preferred timing if available
        if let preferredTime = preference.preferredTiming {
            let calendar = Calendar.current
            let now = Date()
            
            if let scheduledTime = calendar.date(bySettingHour: preferredTime.startHour, minute: preferredTime.startMinute, second: 0, of: now) {
                if scheduledTime > now {
                    return scheduledTime
                } else {
                    // Schedule for tomorrow if preferred time has passed
                    return calendar.date(byAdding: .day, value: 1, to: scheduledTime) ?? now.addingTimeInterval(300)
                }
            }
        }
        
        // Default timing based on notification type
        switch type {
        case .dailySummary:
            return Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        case .planningReminder:
            return Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        case .gentleNudge, .overdueReminder:
            return Date().addingTimeInterval(1800) // 30 minutes from now
        default:
            return Date().addingTimeInterval(300) // 5 minutes from now
        }
    }
    
    /// Check if notification should be skipped due to frequency limits
    private func shouldSkipDueToFrequency(
        _ notification: ProactiveNotification,
        preference: NotificationPreference
    ) -> Bool {
        
        switch preference.frequency {
        case .disabled:
            return true
        case .immediate:
            return false
        case .hourly, .daily, .weekly, .monthly:
            // Would implement frequency checking logic here
            return false
        case .asNeeded:
            return false
        }
    }
    
    /// Optimize notification timing based on context
    private func optimizeNotificationTiming(
        _ notification: ProactiveNotification,
        preference: NotificationPreference,
        context: ProcessingContext
    ) async -> ProactiveNotification {
        
        // Create mutable copy of notification
        var optimized = notification
        
        // Adjust timing based on context and user patterns
        // This would implement sophisticated timing optimization
        
        return optimized
    }
    
    // MARK: - Advanced Notification Integration
    
    /// Send proactive notification using advanced notification system
    private func sendAdvancedProactiveNotification(_ notification: ProactiveNotification) async {
        logger.info("PROACTIVE_NOTIFICATIONS: Sending advanced proactive notification: \\(notification.title)")
        
        // Map to advanced notification context
        let context = NotificationContext(
            category: notification.type.rawValue,
            source: "proactive_engine",
            metadata: [
                "confidence": notification.confidence,
                "priority": notification.priority.rawValue,
                "reasoning": notification.reasoning
            ]
        )
        
        // Create proactive suggestions if applicable
        let suggestions = createProactiveSuggestions(for: notification)
        
        // Determine escalation rules based on notification type and priority
        let escalationRules = getEscalationRules(for: notification)
        
        await advancedNotificationService.sendAdvancedNotification(
            title: notification.title,
            message: notification.message,
            priority: mapToAdvancedPriority(notification.priority),
            category: mapToAdvancedCategory(notification.type),
            context: context,
            escalationRules: escalationRules
        )
        
        // Update statistics
        updateNotificationStatistics(notification)
    }
    
    /// Send critical proactive alert with immediate multi-channel delivery
    func sendCriticalProactiveAlert(
        title: String,
        message: String,
        type: NotificationType,
        reasoning: String
    ) async {
        logger.warning("PROACTIVE_NOTIFICATIONS: Sending critical proactive alert: \\(title)")
        
        let context = NotificationContext(
            category: type.rawValue,
            source: "proactive_engine_critical",
            metadata: [
                "reasoning": reasoning,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        await advancedNotificationService.sendCriticalNotification(
            title: title,
            message: message,
            category: mapToAdvancedCategory(type),
            immediateChannels: [.inApp, .push, .email]
        )
    }
    
    /// Send intelligent suggestion with advanced features
    func sendIntelligentSuggestion(
        title: String,
        message: String,
        suggestions: [String],
        confidence: Double,
        taskId: UUID? = nil,
        projectId: UUID? = nil
    ) async {
        logger.info("PROACTIVE_NOTIFICATIONS: Sending intelligent suggestion: \\(title)")
        
        let context = NotificationContext(
            category: "intelligent_suggestion",
            source: "proactive_engine",
            metadata: [
                "taskId": taskId?.uuidString ?? "",
                "projectId": projectId?.uuidString ?? "",
                "suggestionCount": suggestions.count
            ]
        )
        
        let proactiveSuggestions = suggestions.enumerated().map { index, suggestion in
            ProactiveSuggestion(
                id: UUID(),
                title: "Option \\(index + 1)",
                description: suggestion,
                action: "apply_suggestion_\\(index)",
                confidence: confidence
            )
        }
        
        await advancedNotificationService.sendProactiveSuggestion(
            title: title,
            message: message,
            suggestions: proactiveSuggestions,
            confidence: confidence,
            context: context
        )
    }
    
    /// Create proactive suggestions for a notification
    private func createProactiveSuggestions(for notification: ProactiveNotification) -> [ProactiveSuggestion] {
        var suggestions: [ProactiveSuggestion] = []
        
        switch notification.type {
        case .overdueReminder:
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Reschedule Task",
                description: "Move this task to a better time slot",
                action: "reschedule_task",
                confidence: 0.9
            ))
            
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Break Down Task",
                description: "Split this task into smaller, manageable parts",
                action: "break_down_task",
                confidence: 0.8
            ))
            
        case .stagnantTask:
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Add Context",
                description: "Add more details or context to make progress easier",
                action: "add_context",
                confidence: 0.85
            ))
            
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Change Priority",
                description: "Adjust task priority based on current importance",
                action: "change_priority",
                confidence: 0.7
            ))
            
        case .achievementCelebration:
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Share Achievement",
                description: "Share your progress with team or friends",
                action: "share_achievement",
                confidence: 0.6
            ))
            
        case .workLifeBalance:
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Schedule Break",
                description: "Add a short break to your schedule",
                action: "schedule_break",
                confidence: 0.8
            ))
            
            suggestions.append(ProactiveSuggestion(
                id: UUID(),
                title: "Adjust Schedule",
                description: "Rebalance work and personal tasks",
                action: "adjust_schedule",
                confidence: 0.75
            ))
            
        default:
            break
        }
        
        return suggestions
    }
    
    /// Get escalation rules for different notification types
    private func getEscalationRules(for notification: ProactiveNotification) -> EscalationRules? {
        switch notification.type {
        case .overdueReminder:
            return EscalationRules(
                channels: [.inApp, .push, .email],
                delays: [0, 1800, 3600] // Immediate, 30min, 1hr
            )
            
        case .criticalDeadline:
            return EscalationRules(
                channels: [.inApp, .push, .email, .sms],
                delays: [0, 300, 900] // Immediate, 5min, 15min
            )
            
        case .stagnantTask:
            return EscalationRules(
                channels: [.inApp, .push],
                delays: [0, 7200] // Immediate, 2hrs
            )
            
        case .workLifeBalance:
            return nil // No escalation for balance suggestions
            
        case .achievementCelebration:
            return nil // No escalation for celebrations
            
        default:
            return EscalationRules(
                channels: [.inApp, .push],
                delays: [0, 3600] // Immediate, 1hr
            )
        }
    }
    
    /// Map proactive notification priority to advanced notification priority
    private func mapToAdvancedPriority(_ priority: NotificationPriority) -> AdvancedNotificationService.NotificationPriority {
        switch priority {
        case .low: return .low
        case .medium: return .normal
        case .high: return .high
        case .critical: return .critical
        }
    }
    
    /// Map notification type to advanced notification category
    private func mapToAdvancedCategory(_ type: NotificationType) -> AdvancedNotificationCategory {
        switch type {
        case .overdueReminder, .gentleNudge:
            return .taskReminder
        case .scheduleOptimization, .workLifeBalance:
            return .scheduleChange
        case .conflictResolution:
            return .conflictDetection
        case .achievementCelebration:
            return .achievement
        case .stagnantTask, .procrastinationPattern:
            return .proactiveSuggestion
        default:
            return .systemAlert
        }
    }
    
    /// Update notification statistics with advanced metrics
    private func updateNotificationStatistics(_ notification: ProactiveNotification) {
        notificationStats.totalSent += 1
        notificationStats.lastSentAt = Date()
        
        switch notification.priority {
        case .low:
            notificationStats.lowPrioritySent += 1
        case .medium:
            notificationStats.mediumPrioritySent += 1
        case .high:
            notificationStats.highPrioritySent += 1
        case .critical:
            notificationStats.criticalSent += 1
        }
        
        // Track confidence distribution
        if notification.confidence >= 0.8 {
            notificationStats.highConfidenceSent += 1
        } else if notification.confidence >= 0.6 {
            notificationStats.mediumConfidenceSent += 1
        } else {
            notificationStats.lowConfidenceSent += 1
        }
    }
}

// MARK: - Notification Categories Extension

extension NotificationCategory {
    static let dailySummary = NotificationCategory(rawValue: "DAILY_SUMMARY")!
    static let weeklySummary = NotificationCategory(rawValue: "WEEKLY_SUMMARY")!
}