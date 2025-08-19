import Foundation
import SwiftUI

// MARK: - Focus View Models

/// Focus View: Dynamic "Today" List with AI-powered prioritization and contextual awareness
/// Implements the core data structures for delivering effortless daily productivity focus

// MARK: - Today List & Dynamic Prioritization

/// Represents the AI-curated "Today" list with smart prioritization
struct FocusSession: Identifiable, Codable {
    let id = UUID()
    let date: String // ISO8601 date string for the focus session
    let items: [FocusItem]
    let totalEstimatedTime: Int // Total minutes
    let aiRecommendations: [AIRecommendation]
    let sessionStats: FocusSessionStats
    let createdAt: Date
    let updatedAt: Date
    
    init(
        date: String,
        items: [FocusItem] = [],
        totalEstimatedTime: Int = 0,
        aiRecommendations: [AIRecommendation] = [],
        sessionStats: FocusSessionStats = FocusSessionStats()
    ) {
        self.date = date
        self.items = items
        self.totalEstimatedTime = totalEstimatedTime
        self.aiRecommendations = aiRecommendations
        self.sessionStats = sessionStats
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Individual item in the focus session (task, event, or reminder)
struct FocusItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let sourceId: UUID // ID of the original task/event
    let sourceType: FocusItemType
    let title: String
    let description: String?
    let estimatedDuration: Int? // Minutes
    let priority: FocusPriority
    let urgency: UrgencyLevel
    let aiReason: String // Why this item is included today
    let dueDate: Date?
    let workPersonal: WorkPersonalType
    let projectId: UUID?
    let areaId: UUID?
    let status: FocusItemStatus
    let completedAt: Date?
    let contextTags: [String] // AI-generated context tags
    
    // Focus-specific metadata
    let energyLevel: EnergyLevel // Energy required to complete
    let complexity: ComplexityLevel // Cognitive complexity
    let canBeDoneOffline: Bool
    let estimatedFocusBlocks: Int // How many focus blocks this takes
    
    init(
        sourceId: UUID,
        sourceType: FocusItemType,
        title: String,
        description: String? = nil,
        estimatedDuration: Int? = nil,
        priority: FocusPriority = .medium,
        urgency: UrgencyLevel = .medium,
        aiReason: String,
        dueDate: Date? = nil,
        workPersonal: WorkPersonalType = .personal,
        projectId: UUID? = nil,
        areaId: UUID? = nil,
        status: FocusItemStatus = .pending,
        energyLevel: EnergyLevel = .medium,
        complexity: ComplexityLevel = .medium,
        canBeDoneOffline: Bool = true,
        estimatedFocusBlocks: Int = 1
    ) {
        self.sourceId = sourceId
        self.sourceType = sourceType
        self.title = title
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.priority = priority
        self.urgency = urgency
        self.aiReason = aiReason
        self.dueDate = dueDate
        self.workPersonal = workPersonal
        self.projectId = projectId
        self.areaId = areaId
        self.status = status
        self.completedAt = nil
        self.contextTags = []
        self.energyLevel = energyLevel
        self.complexity = complexity
        self.canBeDoneOffline = canBeDoneOffline
        self.estimatedFocusBlocks = estimatedFocusBlocks
    }
}

// MARK: - Enums

enum FocusItemType: String, Codable, CaseIterable {
    case task = "task"
    case event = "event"
    case reminder = "reminder"
    case habit = "habit"
    case milestone = "milestone"
    
    var displayName: String {
        switch self {
        case .task: return "Task"
        case .event: return "Event"
        case .reminder: return "Reminder"
        case .habit: return "Habit"
        case .milestone: return "Milestone"
        }
    }
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .event: return "calendar"
        case .reminder: return "bell"
        case .habit: return "repeat.circle"
        case .milestone: return "flag"
        }
    }
}

enum FocusPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high" 
    case medium = "medium"
    case low = "low"
    case someday = "someday"
    
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .someday: return "Someday"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        case .someday: return .gray
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        case .someday: return 4
        }
    }
}

enum UrgencyLevel: String, Codable, CaseIterable {
    case urgent = "urgent"
    case soonDue = "soon_due"
    case medium = "medium"
    case flexible = "flexible"
    case noDeadline = "no_deadline"
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .soonDue: return "Due Soon"
        case .medium: return "Medium"
        case .flexible: return "Flexible"
        case .noDeadline: return "No Deadline"
        }
    }
}

enum FocusItemStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case deferred = "deferred"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .deferred: return "Deferred"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle.fill"
        case .deferred: return "clock.arrow.circlepath"
        case .cancelled: return "xmark.circle"
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium" 
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "High Energy"
        case .medium: return "Medium Energy"
        case .low: return "Low Energy"
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "bolt.fill"
        case .medium: return "bolt"
        case .low: return "bolt.slash"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

enum ComplexityLevel: String, Codable, CaseIterable {
    case simple = "simple"
    case medium = "medium"
    case complex = "complex"
    
    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .medium: return "Medium"
        case .complex: return "Complex"
        }
    }
    
    var icon: String {
        switch self {
        case .simple: return "1.circle"
        case .medium: return "2.circle"
        case .complex: return "3.circle"
        }
    }
}

// MARK: - Smart Filters

/// Filter configuration for Focus View
struct FocusFilter: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let description: String
    let criteria: FocusFilterCriteria
    let isDefault: Bool
    let sortOrder: Int
    
    static let defaultFilters: [FocusFilter] = [
        FocusFilter(
            id: UUID(),
            name: "🔥 Urgent & Important",
            icon: "flame",
            description: "Critical tasks that need immediate attention",
            criteria: FocusFilterCriteria(
                priority: [.critical, .high],
                urgency: [.urgent, .soonDue]
            ),
            isDefault: true,
            sortOrder: 0
        ),
        FocusFilter(
            id: UUID(),
            name: "🎯 AI Suggested",
            icon: "brain",
            description: "AI-recommended tasks based on your patterns",
            criteria: FocusFilterCriteria(
                includeAISuggested: true
            ),
            isDefault: true,
            sortOrder: 1
        ),
        FocusFilter(
            id: UUID(),
            name: "⚡ Quick Wins",
            icon: "bolt",
            description: "Tasks that can be completed quickly",
            criteria: FocusFilterCriteria(
                complexity: [.simple],
                maxDuration: 30
            ),
            isDefault: true,
            sortOrder: 2
        ),
        FocusFilter(
            id: UUID(),
            name: "🚀 Deep Work",
            icon: "brain.head.profile",
            description: "Complex tasks requiring focused attention",
            criteria: FocusFilterCriteria(
                energyLevel: [.high],
                complexity: [.complex]
            ),
            isDefault: true,
            sortOrder: 3
        ),
        FocusFilter(
            id: UUID(),
            name: "📋 Low Energy",
            icon: "battery.25",
            description: "Simple tasks for when energy is low",
            criteria: FocusFilterCriteria(
                energyLevel: [.low],
                complexity: [.simple]
            ),
            isDefault: true,
            sortOrder: 4
        )
    ]
}

struct FocusFilterCriteria: Codable, Hashable {
    let priority: [FocusPriority]?
    let urgency: [UrgencyLevel]?
    let energyLevel: [EnergyLevel]?
    let complexity: [ComplexityLevel]?
    let workPersonal: [WorkPersonalType]?
    let sourceType: [FocusItemType]?
    let projectIds: [UUID]?
    let areaIds: [UUID]?
    let maxDuration: Int? // Maximum duration in minutes
    let minDuration: Int? // Minimum duration in minutes
    let canBeDoneOffline: Bool?
    let includeAISuggested: Bool?
    let tags: [String]?
    
    init(
        priority: [FocusPriority]? = nil,
        urgency: [UrgencyLevel]? = nil,
        energyLevel: [EnergyLevel]? = nil,
        complexity: [ComplexityLevel]? = nil,
        workPersonal: [WorkPersonalType]? = nil,
        sourceType: [FocusItemType]? = nil,
        projectIds: [UUID]? = nil,
        areaIds: [UUID]? = nil,
        maxDuration: Int? = nil,
        minDuration: Int? = nil,
        canBeDoneOffline: Bool? = nil,
        includeAISuggested: Bool? = nil,
        tags: [String]? = nil
    ) {
        self.priority = priority
        self.urgency = urgency
        self.energyLevel = energyLevel
        self.complexity = complexity
        self.workPersonal = workPersonal
        self.sourceType = sourceType
        self.projectIds = projectIds
        self.areaIds = areaIds
        self.maxDuration = maxDuration
        self.minDuration = minDuration
        self.canBeDoneOffline = canBeDoneOffline
        self.includeAISuggested = includeAISuggested
        self.tags = tags
    }
    
    /// Check if a focus item matches this filter criteria
    func matches(_ item: FocusItem) -> Bool {
        if let priorities = priority, !priorities.contains(item.priority) {
            return false
        }
        
        if let urgencies = urgency, !urgencies.contains(item.urgency) {
            return false
        }
        
        if let energyLevels = energyLevel, !energyLevels.contains(item.energyLevel) {
            return false
        }
        
        if let complexities = complexity, !complexities.contains(item.complexity) {
            return false
        }
        
        if let workPersonals = workPersonal, !workPersonals.contains(item.workPersonal) {
            return false
        }
        
        if let sourceTypes = sourceType, !sourceTypes.contains(item.sourceType) {
            return false
        }
        
        if let maxDur = maxDuration, let itemDuration = item.estimatedDuration, itemDuration > maxDur {
            return false
        }
        
        if let minDur = minDuration, let itemDuration = item.estimatedDuration, itemDuration < minDur {
            return false
        }
        
        if let offlineReq = canBeDoneOffline, item.canBeDoneOffline != offlineReq {
            return false
        }
        
        if let projectIdsFilter = projectIds, let itemProjectId = item.projectId {
            if !projectIdsFilter.contains(itemProjectId) {
                return false
            }
        }
        
        if let areaIdsFilter = areaIds, let itemAreaId = item.areaId {
            if !areaIdsFilter.contains(itemAreaId) {
                return false
            }
        }
        
        return true
    }
}

// MARK: - AI Recommendations & Contextual Suggestions

/// AI-generated recommendation for focus optimization
struct AIRecommendation: Identifiable, Codable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let confidence: Double // 0.0 - 1.0
    let reasoning: String
    let actionable: Bool
    let relatedItemIds: [UUID] // Focus items this recommendation relates to
    let createdAt: Date
    let dismissedAt: Date?
    
    init(
        type: RecommendationType,
        title: String,
        description: String,
        confidence: Double,
        reasoning: String,
        actionable: Bool = true,
        relatedItemIds: [UUID] = []
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.reasoning = reasoning
        self.actionable = actionable
        self.relatedItemIds = relatedItemIds
        self.createdAt = Date()
        self.dismissedAt = nil
    }
}

enum RecommendationType: String, Codable, CaseIterable {
    case timeOptimization = "time_optimization"
    case energyMatching = "energy_matching"
    case priorityAdjustment = "priority_adjustment"
    case taskGrouping = "task_grouping"
    case contextSwitching = "context_switching"
    case deferSuggestion = "defer_suggestion"
    case habitReminder = "habit_reminder"
    case achievementCelebration = "achievement_celebration"
    
    var displayName: String {
        switch self {
        case .timeOptimization: return "Time Optimization"
        case .energyMatching: return "Energy Matching"
        case .priorityAdjustment: return "Priority Adjustment"
        case .taskGrouping: return "Task Grouping"
        case .contextSwitching: return "Context Switching"
        case .deferSuggestion: return "Defer Suggestion"
        case .habitReminder: return "Habit Reminder"
        case .achievementCelebration: return "Achievement"
        }
    }
    
    var icon: String {
        switch self {
        case .timeOptimization: return "clock.badge.checkmark"
        case .energyMatching: return "bolt.heart"
        case .priorityAdjustment: return "arrow.up.arrow.down"
        case .taskGrouping: return "rectangle.3.group"
        case .contextSwitching: return "arrow.triangle.swap"
        case .deferSuggestion: return "clock.arrow.circlepath"
        case .habitReminder: return "repeat.circle"
        case .achievementCelebration: return "star.circle.fill"
        }
    }
}

// MARK: - Mood & Energy Tracking (AI-Extracted)

/// Daily mood and energy assessment (AI-generated, no manual input)
struct DailyMoodAssessment: Identifiable, Codable {
    let id = UUID()
    let date: String // ISO8601 date string
    let overallMood: MoodLevel
    let energyLevel: EnergyLevel
    let stressLevel: StressLevel
    let focusCapacity: FocusCapacity
    let confidence: Double // AI confidence in assessment
    let dataSource: MoodDataSource
    let insights: [MoodInsight]
    let suggestedActions: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        date: String,
        overallMood: MoodLevel,
        energyLevel: EnergyLevel,
        stressLevel: StressLevel,
        focusCapacity: FocusCapacity,
        confidence: Double,
        dataSource: MoodDataSource,
        insights: [MoodInsight] = [],
        suggestedActions: [String] = []
    ) {
        self.date = date
        self.overallMood = overallMood
        self.energyLevel = energyLevel
        self.stressLevel = stressLevel
        self.focusCapacity = focusCapacity
        self.confidence = confidence
        self.dataSource = dataSource
        self.insights = insights
        self.suggestedActions = suggestedActions
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum MoodLevel: String, Codable, CaseIterable {
    case veryPositive = "very_positive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case veryNegative = "very_negative"
    
    var displayName: String {
        switch self {
        case .veryPositive: return "Very Positive"
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        case .veryNegative: return "Very Negative"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryPositive: return "😊"
        case .positive: return "🙂"
        case .neutral: return "😐"
        case .negative: return "🙁"
        case .veryNegative: return "😞"
        }
    }
    
    var color: Color {
        switch self {
        case .veryPositive: return .green
        case .positive: return .mint
        case .neutral: return .gray
        case .negative: return .orange
        case .veryNegative: return .red
        }
    }
}

enum StressLevel: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
}

enum FocusCapacity: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case average = "average"
    case poor = "poor"
    case veryPoor = "very_poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .average: return "Average"
        case .poor: return "Poor"
        case .veryPoor: return "Very Poor"
        }
    }
}

enum MoodDataSource: String, Codable, CaseIterable {
    case brainDumpAnalysis = "brain_dump_analysis"
    case completionPatterns = "completion_patterns"
    case activityAnalysis = "activity_analysis"
    case languageAnalysis = "language_analysis"
    case temporalPatterns = "temporal_patterns"
    
    var displayName: String {
        switch self {
        case .brainDumpAnalysis: return "Brain Dump Analysis"
        case .completionPatterns: return "Task Completion Patterns"
        case .activityAnalysis: return "Activity Analysis"
        case .languageAnalysis: return "Language Analysis"
        case .temporalPatterns: return "Temporal Patterns"
        }
    }
}

struct MoodInsight: Identifiable, Codable {
    let id = UUID()
    let category: InsightCategory
    let insight: String
    let confidence: Double
    let actionable: Bool
    
    init(category: InsightCategory, insight: String, confidence: Double, actionable: Bool = false) {
        self.category = category
        self.insight = insight
        self.confidence = confidence
        self.actionable = actionable
    }
}

enum InsightCategory: String, Codable, CaseIterable {
    case productivity = "productivity"
    case wellbeing = "wellbeing"
    case patterns = "patterns"
    case recommendations = "recommendations"
    
    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .wellbeing: return "Wellbeing"
        case .patterns: return "Patterns"
        case .recommendations: return "Recommendations"
        }
    }
}

// MARK: - Session Statistics & Batch Actions

struct FocusSessionStats: Codable {
    var totalItems: Int = 0
    var completedItems: Int = 0
    var deferredItems: Int = 0
    var totalTimeSpent: Int = 0 // Minutes
    var focusScore: Double = 0.0 // 0.0 - 1.0
    var achievementBadges: [AchievementBadge] = []
    
    var completionRate: Double {
        guard totalItems > 0 else { return 0.0 }
        return Double(completedItems) / Double(totalItems)
    }
    
    var averageItemDuration: Double {
        guard completedItems > 0 else { return 0.0 }
        return Double(totalTimeSpent) / Double(completedItems)
    }
}

struct AchievementBadge: Identifiable, Codable {
    let id = UUID()
    let type: AchievementType
    let title: String
    let description: String
    let icon: String
    let earnedAt: Date
    
    init(type: AchievementType, title: String, description: String, icon: String) {
        self.type = type
        self.title = title
        self.description = description
        self.icon = icon
        self.earnedAt = Date()
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case streak = "streak"
    case efficiency = "efficiency"
    case focus = "focus"
    case variety = "variety"
    case completion = "completion"
    
    var displayName: String {
        switch self {
        case .streak: return "Streak"
        case .efficiency: return "Efficiency"
        case .focus: return "Focus"
        case .variety: return "Variety"
        case .completion: return "Completion"
        }
    }
}

// MARK: - Batch Actions

struct BatchAction: Identifiable {
    let id = UUID()
    let type: BatchActionType
    let name: String
    let icon: String
    let description: String
    let requiresConfirmation: Bool
    
    static let availableActions: [BatchAction] = [
        BatchAction(
            type: .complete,
            name: "Mark Complete",
            icon: "checkmark.circle.fill",
            description: "Mark selected items as completed",
            requiresConfirmation: false
        ),
        BatchAction(
            type: .defer,
            name: "Defer to Tomorrow",
            icon: "clock.arrow.circlepath",
            description: "Move selected items to tomorrow's focus list",
            requiresConfirmation: false
        ),
        BatchAction(
            type: .increasePriority,
            name: "Increase Priority",
            icon: "arrow.up.circle",
            description: "Increase priority of selected items",
            requiresConfirmation: false
        ),
        BatchAction(
            type: .decreasePriority,
            name: "Decrease Priority",
            icon: "arrow.down.circle",
            description: "Decrease priority of selected items",
            requiresConfirmation: false
        ),
        BatchAction(
            type: .delete,
            name: "Remove",
            icon: "trash",
            description: "Remove selected items from today's focus",
            requiresConfirmation: true
        ),
        BatchAction(
            type: .reschedule,
            name: "Reschedule",
            icon: "calendar.badge.plus",
            description: "Reschedule selected items to a specific time",
            requiresConfirmation: false
        )
    ]
}

enum BatchActionType: String, CaseIterable {
    case complete = "complete"
    case `defer` = "defer"
    case increasePriority = "increase_priority"
    case decreasePriority = "decrease_priority"
    case delete = "delete"
    case reschedule = "reschedule"
}