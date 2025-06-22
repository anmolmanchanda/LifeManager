import Foundation
import SwiftUI

// MARK: - Intelligent Scheduling Data Models
// Phase 1: Foundation Enhancement for Smart Auto-Rescheduling & Proactive Notifications

/// Enhanced task dependency tracking
struct TaskDependency: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let dependsOnTaskId: UUID
    let dependencyType: DependencyType
    let isBlocking: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case dependsOnTaskId = "depends_on_task_id"
        case dependencyType = "dependency_type"
        case isBlocking = "is_blocking"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        dependsOnTaskId: UUID,
        dependencyType: DependencyType = .sequential,
        isBlocking: Bool = true,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.taskId = taskId
        self.dependsOnTaskId = dependsOnTaskId
        self.dependencyType = dependencyType
        self.isBlocking = isBlocking
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Task dependency types
enum DependencyType: String, CaseIterable, Codable {
    case sequential = "sequential"      // Must complete first task before starting second
    case resource = "resource"          // Shared resource or person requirement
    case milestone = "milestone"        // Project milestone dependency
    case preference = "preference"      // Preferred ordering (non-blocking)
    
    var displayName: String {
        switch self {
        case .sequential: return "Sequential"
        case .resource: return "Resource"
        case .milestone: return "Milestone"
        case .preference: return "Preference"
        }
    }
}

/// User scheduling patterns learned from behavior
struct SchedulingPattern: Codable, Identifiable {
    let id: UUID
    let userId: String
    let patternType: SchedulingPatternType
    let preferredTimeOfDay: SchedulingTimeSlot?
    let preferredDayOfWeek: [Int]? // 1=Sunday, 2=Monday, etc.
    let taskType: ContentType?
    let workPersonal: WorkPersonalType?
    let priority: TaskPriority?
    let confidence: Double
    let usageCount: Int
    let lastUsed: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case patternType = "pattern_type"
        case preferredTimeOfDay = "preferred_time_of_day"
        case preferredDayOfWeek = "preferred_day_of_week"
        case taskType = "task_type"
        case workPersonal = "work_personal"
        case priority
        case confidence
        case usageCount = "usage_count"
        case lastUsed = "last_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: String,
        patternType: SchedulingPatternType,
        preferredTimeOfDay: SchedulingTimeSlot? = nil,
        preferredDayOfWeek: [Int]? = nil,
        taskType: ContentType? = nil,
        workPersonal: WorkPersonalType? = nil,
        priority: TaskPriority? = nil,
        confidence: Double = 0.5,
        usageCount: Int = 1,
        lastUsed: String = ISO8601DateFormatter().string(from: Date()),
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.userId = userId
        self.patternType = patternType
        self.preferredTimeOfDay = preferredTimeOfDay
        self.preferredDayOfWeek = preferredDayOfWeek
        self.taskType = taskType
        self.workPersonal = workPersonal
        self.priority = priority
        self.confidence = confidence
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Types of scheduling patterns
enum SchedulingPatternType: String, CaseIterable, Codable {
    case timeOfDay = "time_of_day"          // User prefers certain times for certain tasks
    case dayOfWeek = "day_of_week"          // User prefers certain days
    case taskDuration = "task_duration"     // User prefers certain durations for time blocks
    case priority = "priority"              // User schedules high priority tasks at certain times
    case workPersonal = "work_personal"     // User separates work and personal at certain times
    case energy = "energy"                  // User has high/low energy periods
    case bufferPreference = "buffer_preference" // User prefers certain buffer amounts
    
    var displayName: String {
        switch self {
        case .timeOfDay: return "Time of Day"
        case .dayOfWeek: return "Day of Week"
        case .taskDuration: return "Task Duration"
        case .priority: return "Priority"
        case .workPersonal: return "Work/Personal"
        case .energy: return "Energy Level"
        case .bufferPreference: return "Buffer Preference"
        }
    }
}

/// Time slot for scheduling patterns
struct SchedulingTimeSlot: Codable, Equatable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let startTime = Calendar.current.date(from: DateComponents(hour: startHour, minute: startMinute)) ?? Date()
        let endTime = Calendar.current.date(from: DateComponents(hour: endHour, minute: endMinute)) ?? Date()
        
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var durationMinutes: Int {
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        return endMinutes - startMinutes
    }
    
    init(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }
    
    /// Common time slots for scheduling
    static let morningFocus = SchedulingTimeSlot(startHour: 9, startMinute: 0, endHour: 11, endMinute: 0)
    static let afternoonFocus = SchedulingTimeSlot(startHour: 13, startMinute: 0, endHour: 15, endMinute: 0)
    static let eveningReview = SchedulingTimeSlot(startHour: 17, startMinute: 0, endHour: 18, endMinute: 0)
    static let lateEvening = SchedulingTimeSlot(startHour: 19, startMinute: 0, endHour: 21, endMinute: 0)
}

/// Task rescheduling history for learning
struct ReschedulingEvent: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let originalDate: String
    let newDate: String
    let reason: ReschedulingReason
    let wasAutomatic: Bool
    let userOverrode: Bool
    let overrideReason: String?
    let confidence: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case originalDate = "original_date"
        case newDate = "new_date"
        case reason
        case wasAutomatic = "was_automatic"
        case userOverrode = "user_overrode"
        case overrideReason = "override_reason"
        case confidence
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        originalDate: String,
        newDate: String,
        reason: ReschedulingReason,
        wasAutomatic: Bool = true,
        userOverrode: Bool = false,
        overrideReason: String? = nil,
        confidence: Double = 0.8,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.taskId = taskId
        self.originalDate = originalDate
        self.newDate = newDate
        self.reason = reason
        self.wasAutomatic = wasAutomatic
        self.userOverrode = userOverrode
        self.overrideReason = overrideReason
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

/// Reasons for task rescheduling
enum ReschedulingReason: String, CaseIterable, Codable {
    case overdue = "overdue"
    case conflict = "conflict"
    case dependency = "dependency"
    case userPreference = "user_preference"
    case bufferViolation = "buffer_violation"
    case priorityChange = "priority_change"
    case calendarChange = "calendar_change"
    case automaticOptimization = "automatic_optimization"
    
    var displayName: String {
        switch self {
        case .overdue: return "Task was overdue"
        case .conflict: return "Calendar conflict"
        case .dependency: return "Dependency requirement"
        case .userPreference: return "User preference pattern"
        case .bufferViolation: return "Buffer violation"
        case .priorityChange: return "Priority change"
        case .calendarChange: return "Calendar change"
        case .automaticOptimization: return "Automatic optimization"
        }
    }
}

/// Priority intelligence scoring
struct PriorityIntelligence: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let intelligenceScore: Double  // 0.0 to 1.0
    let urgencyScore: Double      // 0.0 to 1.0
    let importanceScore: Double   // 0.0 to 1.0
    let contextScore: Double      // 0.0 to 1.0
    let userPatternScore: Double  // 0.0 to 1.0
    let reasoningFactors: [String]
    let confidence: Double
    let calculatedAt: String
    let expiresAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case intelligenceScore = "intelligence_score"
        case urgencyScore = "urgency_score"
        case importanceScore = "importance_score"
        case contextScore = "context_score"
        case userPatternScore = "user_pattern_score"
        case reasoningFactors = "reasoning_factors"
        case confidence
        case calculatedAt = "calculated_at"
        case expiresAt = "expires_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        intelligenceScore: Double,
        urgencyScore: Double,
        importanceScore: Double,
        contextScore: Double,
        userPatternScore: Double,
        reasoningFactors: [String] = [],
        confidence: Double = 0.8
    ) {
        self.id = id
        self.taskId = taskId
        self.intelligenceScore = intelligenceScore
        self.urgencyScore = urgencyScore
        self.importanceScore = importanceScore
        self.contextScore = contextScore
        self.userPatternScore = userPatternScore
        self.reasoningFactors = reasoningFactors
        self.confidence = confidence
        self.calculatedAt = ISO8601DateFormatter().string(from: Date())
        
        // Score expires after 24 hours to ensure fresh calculations
        let expirationDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        self.expiresAt = ISO8601DateFormatter().string(from: expirationDate)
    }
    
    /// Overall priority score combining all factors
    var overallScore: Double {
        return (intelligenceScore * 0.3) + 
               (urgencyScore * 0.25) + 
               (importanceScore * 0.25) + 
               (contextScore * 0.1) + 
               (userPatternScore * 0.1)
    }
    
    /// Check if score has expired
    var isExpired: Bool {
        guard let expirationDate = ISO8601DateFormatter().date(from: expiresAt) else {
            return true
        }
        return Date() > expirationDate
    }
}

/// Smart notification preferences
struct NotificationPreference: Codable, Identifiable {
    let id: UUID
    let userId: String
    let notificationType: NotificationType
    let isEnabled: Bool
    let preferredTiming: SchedulingTimeSlot?
    let frequency: NotificationFrequency
    let customSettings: [String: AnyCodableValue]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case notificationType = "notification_type"
        case isEnabled = "is_enabled"
        case preferredTiming = "preferred_timing"
        case frequency
        case customSettings = "custom_settings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: String,
        notificationType: NotificationType,
        isEnabled: Bool = true,
        preferredTiming: SchedulingTimeSlot? = nil,
        frequency: NotificationFrequency = .asNeeded,
        customSettings: [String: AnyCodableValue] = [:],
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.userId = userId
        self.notificationType = notificationType
        self.isEnabled = isEnabled
        self.preferredTiming = preferredTiming
        self.frequency = frequency
        self.customSettings = customSettings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Types of smart notifications
enum NotificationType: String, CaseIterable, Codable {
    case overdueReminder = "overdue_reminder"
    case gentleNudge = "gentle_nudge"
    case dailySummary = "daily_summary"
    case weeklySummary = "weekly_summary"
    case monthlyReport = "monthly_report"
    case reschedulingAlert = "rescheduling_alert"
    case bufferWarning = "buffer_warning"
    case contextualSuggestion = "contextual_suggestion"
    case achievementCelebration = "achievement_celebration"
    case planningReminder = "planning_reminder"
    
    var displayName: String {
        switch self {
        case .overdueReminder: return "Overdue Reminders"
        case .gentleNudge: return "Gentle Nudges"
        case .dailySummary: return "Daily Summary"
        case .weeklySummary: return "Weekly Summary"
        case .monthlyReport: return "Monthly Report"
        case .reschedulingAlert: return "Rescheduling Alerts"
        case .bufferWarning: return "Buffer Warnings"
        case .contextualSuggestion: return "Contextual Suggestions"
        case .achievementCelebration: return "Achievement Celebrations"
        case .planningReminder: return "Planning Reminders"
        }
    }
}

/// Notification frequency settings
enum NotificationFrequency: String, CaseIterable, Codable {
    case immediate = "immediate"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case asNeeded = "as_needed"
    case disabled = "disabled"
    
    var displayName: String {
        switch self {
        case .immediate: return "Immediate"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .asNeeded: return "As Needed"
        case .disabled: return "Disabled"
        }
    }
}

/// Proactive notification tracking
struct ProactiveNotification: Codable, Identifiable {
    let id: UUID
    let userId: String
    let notificationType: NotificationType
    let title: String
    let body: String
    let contextData: [String: AnyCodableValue]
    let scheduledFor: String
    let sentAt: String?
    let wasOpened: Bool
    let wasActedUpon: Bool
    let userResponse: String?
    let effectiveness: Double?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case notificationType = "notification_type"
        case title
        case body
        case contextData = "context_data"
        case scheduledFor = "scheduled_for"
        case sentAt = "sent_at"
        case wasOpened = "was_opened"
        case wasActedUpon = "was_acted_upon"
        case userResponse = "user_response"
        case effectiveness
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: String,
        notificationType: NotificationType,
        title: String,
        body: String,
        contextData: [String: AnyCodableValue] = [:],
        scheduledFor: String,
        sentAt: String? = nil,
        wasOpened: Bool = false,
        wasActedUpon: Bool = false,
        userResponse: String? = nil,
        effectiveness: Double? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.userId = userId
        self.notificationType = notificationType
        self.title = title
        self.body = body
        self.contextData = contextData
        self.scheduledFor = scheduledFor
        self.sentAt = sentAt
        self.wasOpened = wasOpened
        self.wasActedUpon = wasActedUpon
        self.userResponse = userResponse
        self.effectiveness = effectiveness
        self.createdAt = createdAt
    }
}

// MARK: - Enhanced Calendar Event with Intelligence

/// Enhanced calendar event with intelligent scheduling capabilities
extension CalendarEvent {
    
    /// Additional properties for intelligent scheduling
    var priorityIntelligence: PriorityIntelligence? {
        // This would be loaded from the database when needed
        return nil
    }
    
    var reschedulingHistory: [ReschedulingEvent] {
        // This would be loaded from the database when needed
        return []
    }
    
    var dependencies: [TaskDependency] {
        // This would be loaded from the database when needed
        return []
    }
    
    var isOverdue: Bool {
        return Date() > endDate && type == .task
    }
    
    var overdueByMinutes: Int {
        guard isOverdue else { return 0 }
        return Int(Date().timeIntervalSince(endDate) / 60)
    }
    
    var canBeAutomaticallyRescheduled: Bool {
        return !isLocked && type == .task && !isCompleted
    }
    
    var isCompleted: Bool {
        // This would check the actual task status from the database
        return false
    }
}

// MARK: - Extensions for LifeTask with Intelligence

extension LifeTask {
    
    /// Get priority intelligence score
    var priorityIntelligence: PriorityIntelligence? {
        // This would be loaded from database when needed
        return nil
    }
    
    /// Get task dependencies
    var dependencies: [TaskDependency] {
        // This would be loaded from database when needed
        return []
    }
    
    /// Get rescheduling history
    var reschedulingHistory: [ReschedulingEvent] {
        // This would be loaded from database when needed
        return []
    }
    
    /// Check if task is overdue
    var isOverdue: Bool {
        guard let dueDateString = dueDate,
              let dueDate = ISO8601DateFormatter().date(from: dueDateString) else {
            return false
        }
        return Date() > dueDate && status != .completed && status != .cancelled
    }
    
    /// Calculate how overdue the task is in hours
    var overdueByHours: Double {
        guard let dueDateString = dueDate,
              let dueDate = ISO8601DateFormatter().date(from: dueDateString),
              isOverdue else {
            return 0
        }
        return Date().timeIntervalSince(dueDate) / 3600
    }
    
    /// Check if task can be automatically rescheduled
    var canBeAutomaticallyRescheduled: Bool {
        return status == .todo || status == .inProgress
    }
    
    /// Check if task is stagnant (created but not scheduled or started)
    var isStagnant: Bool {
        guard let createdDate = ISO8601DateFormatter().date(from: createdAt) else {
            return false
        }
        let hoursOld = Date().timeIntervalSince(createdDate) / 3600
        return hoursOld > 72 && status == .inbox && dueDate == nil // 3 days without scheduling
    }
}