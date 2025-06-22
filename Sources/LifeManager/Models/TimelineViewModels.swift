import Foundation
import SwiftUI

// MARK: - Timeline View Models

/// Timeline View: Goal-centric historical and forward-looking view
/// Visualizes progress, dependencies, and long-term goal achievement with AI insights

// MARK: - Goal & Timeline Core

/// Extended Project model that serves as a Goal in the Timeline View
struct Goal: Identifiable, Codable {
    let id: UUID
    let projectId: UUID // Links to existing Project
    let name: String
    let description: String?
    let vision: String? // Long-term vision statement
    let status: GoalStatus
    let priority: GoalPriority
    let category: GoalCategory
    let workPersonal: WorkPersonalType
    
    // Timeline-specific properties
    let startDate: Date?
    let targetDate: Date?
    let completedDate: Date?
    let estimatedDuration: Int? // Days
    let actualDuration: Int? // Days (calculated)
    
    // Progress tracking
    let milestones: [Milestone]
    let progressPercentage: Double // 0.0 - 1.0
    let currentPhase: String?
    
    // AI insights
    let riskLevel: RiskLevel
    let onTrackScore: Double // 0.0 - 1.0
    let velocityTrend: VelocityTrend
    let predictedCompletionDate: Date?
    
    // Relationships
    let dependsOnGoals: [UUID] // Other goals this depends on
    let blocksGoals: [UUID] // Goals that depend on this one
    let areaId: UUID?
    
    // Metadata
    let createdAt: Date
    let updatedAt: Date
    let archivedAt: Date?
    
    init(
        projectId: UUID,
        name: String,
        description: String? = nil,
        vision: String? = nil,
        status: GoalStatus = .planning,
        priority: GoalPriority = .medium,
        category: GoalCategory = .project,
        workPersonal: WorkPersonalType = .personal,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        estimatedDuration: Int? = nil,
        areaId: UUID? = nil
    ) {
        self.id = UUID()
        self.projectId = projectId
        self.name = name
        self.description = description
        self.vision = vision
        self.status = status
        self.priority = priority
        self.category = category
        self.workPersonal = workPersonal
        self.startDate = startDate
        self.targetDate = targetDate
        self.completedDate = nil
        self.estimatedDuration = estimatedDuration
        self.actualDuration = nil
        self.milestones = []
        self.progressPercentage = 0.0
        self.currentPhase = nil
        self.riskLevel = .low
        self.onTrackScore = 1.0
        self.velocityTrend = .stable
        self.predictedCompletionDate = targetDate
        self.dependsOnGoals = []
        self.blocksGoals = []
        self.areaId = areaId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.archivedAt = nil
    }
}

/// Milestone within a goal's timeline
struct Milestone: Identifiable, Codable, Hashable {
    let id = UUID()
    let goalId: UUID
    let name: String
    let description: String?
    let targetDate: Date?
    let completedDate: Date?
    let status: MilestoneStatus
    let type: MilestoneType
    let progress: Double // 0.0 - 1.0
    let estimatedEffort: Int? // Hours
    let actualEffort: Int? // Hours
    let dependencies: [UUID] // Other milestone IDs this depends on
    let tasksCount: Int // Number of tasks associated
    let completedTasksCount: Int // Number of completed tasks
    let createdAt: Date
    let updatedAt: Date
    
    init(
        goalId: UUID,
        name: String,
        description: String? = nil,
        targetDate: Date? = nil,
        type: MilestoneType = .checkpoint,
        estimatedEffort: Int? = nil
    ) {
        self.goalId = goalId
        self.name = name
        self.description = description
        self.targetDate = targetDate
        self.completedDate = nil
        self.status = .planned
        self.type = type
        self.progress = 0.0
        self.estimatedEffort = estimatedEffort
        self.actualEffort = nil
        self.dependencies = []
        self.tasksCount = 0
        self.completedTasksCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isOverdue: Bool {
        guard let target = targetDate else { return false }
        return status != .completed && Date() > target
    }
    
    var completionRate: Double {
        guard tasksCount > 0 else { return 0.0 }
        return Double(completedTasksCount) / Double(tasksCount)
    }
}

// MARK: - Timeline Events & History

/// Timeline event represents any significant occurrence in goal progress
struct TimelineEvent: Identifiable, Codable {
    let id = UUID()
    let goalId: UUID
    let type: TimelineEventType
    let title: String
    let description: String?
    let date: Date
    let impact: EventImpact
    let relatedItemId: UUID? // Task, milestone, or other item ID
    let relatedItemType: String? // "task", "milestone", "note", etc.
    let metadata: [String: AnyCodableValue]
    let createdBy: EventCreator
    let createdAt: Date
    
    init(
        goalId: UUID,
        type: TimelineEventType,
        title: String,
        description: String? = nil,
        date: Date = Date(),
        impact: EventImpact = .neutral,
        relatedItemId: UUID? = nil,
        relatedItemType: String? = nil,
        metadata: [String: AnyCodableValue] = [:],
        createdBy: EventCreator = .system
    ) {
        self.goalId = goalId
        self.type = type
        self.title = title
        self.description = description
        self.date = date
        self.impact = impact
        self.relatedItemId = relatedItemId
        self.relatedItemType = relatedItemType
        self.metadata = metadata
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

/// Version history for timeline items (goals, milestones, tasks)
struct TimelineVersionHistory: Identifiable, Codable {
    let id = UUID()
    let itemId: UUID
    let itemType: String // "goal", "milestone", "task"
    let changeType: VersionChangeType
    let fieldName: String?
    let oldValue: AnyCodableValue?
    let newValue: AnyCodableValue?
    let changeReason: String?
    let changedBy: EventCreator
    let timestamp: Date
    let canRevert: Bool
    
    init(
        itemId: UUID,
        itemType: String,
        changeType: VersionChangeType,
        fieldName: String? = nil,
        oldValue: AnyCodableValue? = nil,
        newValue: AnyCodableValue? = nil,
        changeReason: String? = nil,
        changedBy: EventCreator = .user,
        canRevert: Bool = true
    ) {
        self.itemId = itemId
        self.itemType = itemType
        self.changeType = changeType
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
        self.changeReason = changeReason
        self.changedBy = changedBy
        self.timestamp = Date()
        self.canRevert = canRevert
    }
}

// MARK: - Ripple Effects & Dependencies

/// Represents the impact of changes on goal dependencies
struct RippleEffect: Identifiable, Codable {
    let id = UUID()
    let sourceGoalId: UUID
    let affectedGoalId: UUID
    let changeType: RippleChangeType
    let severity: RippleSeverity
    let description: String
    let suggestedActions: [RippleAction]
    let autoResolvable: Bool
    let confidence: Double // AI confidence in analysis
    let detectedAt: Date
    let resolvedAt: Date?
    let userDismissed: Bool
    
    init(
        sourceGoalId: UUID,
        affectedGoalId: UUID,
        changeType: RippleChangeType,
        severity: RippleSeverity,
        description: String,
        suggestedActions: [RippleAction] = [],
        autoResolvable: Bool = false,
        confidence: Double = 0.8
    ) {
        self.sourceGoalId = sourceGoalId
        self.affectedGoalId = affectedGoalId
        self.changeType = changeType
        self.severity = severity
        self.description = description
        self.suggestedActions = suggestedActions
        self.autoResolvable = autoResolvable
        self.confidence = confidence
        self.detectedAt = Date()
        self.resolvedAt = nil
        self.userDismissed = false
    }
}

struct RippleAction: Identifiable, Codable {
    let id = UUID()
    let type: RippleActionType
    let title: String
    let description: String
    let estimatedImpact: String
    let autoExecutable: Bool
    
    init(
        type: RippleActionType,
        title: String,
        description: String,
        estimatedImpact: String,
        autoExecutable: Bool = false
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.estimatedImpact = estimatedImpact
        self.autoExecutable = autoExecutable
    }
}

// MARK: - AI Insights & Pattern Recognition

/// AI-generated insights about goal progress and patterns
struct TimelineInsight: Identifiable, Codable {
    let id = UUID()
    let goalId: UUID?
    let type: InsightType
    let category: TimelineInsightCategory
    let title: String
    let description: String
    let insight: String
    let confidence: Double
    let actionable: Bool
    let suggestedActions: [String]
    let supportingData: [String: AnyCodableValue]
    let createdAt: Date
    let relevantUntil: Date?
    let userFeedback: InsightFeedback?
    
    init(
        goalId: UUID? = nil,
        type: InsightType,
        category: TimelineInsightCategory,
        title: String,
        description: String,
        insight: String,
        confidence: Double,
        actionable: Bool = false,
        suggestedActions: [String] = [],
        supportingData: [String: AnyCodableValue] = [:]
    ) {
        self.goalId = goalId
        self.type = type
        self.category = category
        self.title = title
        self.description = description
        self.insight = insight
        self.confidence = confidence
        self.actionable = actionable
        self.suggestedActions = suggestedActions
        self.supportingData = supportingData
        self.createdAt = Date()
        self.relevantUntil = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        self.userFeedback = nil
    }
}

struct InsightFeedback: Codable {
    let helpful: Bool
    let implemented: Bool
    let comments: String?
    let feedbackDate: Date
    
    init(helpful: Bool, implemented: Bool = false, comments: String? = nil) {
        self.helpful = helpful
        self.implemented = implemented
        self.comments = comments
        self.feedbackDate = Date()
    }
}

// MARK: - Timeline Navigation & Display

/// Configuration for timeline display and navigation
struct TimelineViewConfig: Codable {
    let selectedGoalId: UUID?
    let timeRange: TimeRange
    let viewMode: TimelineViewMode
    let showCompletedGoals: Bool
    let showArchivedGoals: Bool
    let groupBy: TimelineGrouping
    let sortBy: TimelineSorting
    let colorScheme: TimelineColorScheme
    let showRippleEffects: Bool
    let showAIInsights: Bool
    let compactMode: Bool
    
    static let `default` = TimelineViewConfig(
        selectedGoalId: nil,
        timeRange: .sixMonths,
        viewMode: .timeline,
        showCompletedGoals: true,
        showArchivedGoals: false,
        groupBy: .category,
        sortBy: .priority,
        colorScheme: .priority,
        showRippleEffects: true,
        showAIInsights: true,
        compactMode: false
    )
}

/// Progress summary for a specific time period
struct ProgressSummary: Identifiable, Codable {
    let id = UUID()
    let period: String // "This Week", "This Month", etc.
    let startDate: Date
    let endDate: Date
    let goalsInProgress: Int
    let goalsCompleted: Int
    let milestonesCompleted: Int
    let tasksCompleted: Int
    let totalTimeSpent: Int // Minutes
    let averageVelocity: Double
    let achievementHighlights: [String]
    let challenges: [String]
    let nextMilestones: [Milestone]
    let generatedAt: Date
    
    init(
        period: String,
        startDate: Date,
        endDate: Date,
        goalsInProgress: Int = 0,
        goalsCompleted: Int = 0,
        milestonesCompleted: Int = 0,
        tasksCompleted: Int = 0,
        totalTimeSpent: Int = 0
    ) {
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.goalsInProgress = goalsInProgress
        self.goalsCompleted = goalsCompleted
        self.milestonesCompleted = milestonesCompleted
        self.tasksCompleted = tasksCompleted
        self.totalTimeSpent = totalTimeSpent
        self.averageVelocity = 0.0
        self.achievementHighlights = []
        self.challenges = []
        self.nextMilestones = []
        self.generatedAt = Date()
    }
    
    var completionRate: Double {
        let total = goalsInProgress + goalsCompleted
        guard total > 0 else { return 0.0 }
        return Double(goalsCompleted) / Double(total)
    }
}

// MARK: - Enums

enum GoalStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .archived: return "Archived"
        }
    }
    
    var color: Color {
        switch self {
        case .planning: return .orange
        case .active: return .blue
        case .onHold: return .yellow
        case .completed: return .green
        case .cancelled: return .red
        case .archived: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .planning: return "lightbulb"
        case .active: return "play.circle"
        case .onHold: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .archived: return "archivebox"
        }
    }
}

enum GoalPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case project = "project"
    case habit = "habit"
    case learning = "learning"
    case health = "health"
    case career = "career"
    case relationship = "relationship"
    case financial = "financial"
    case creative = "creative"
    case travel = "travel"
    case personal = "personal"
    
    var displayName: String {
        switch self {
        case .project: return "Project"
        case .habit: return "Habit"
        case .learning: return "Learning"
        case .health: return "Health"
        case .career: return "Career"
        case .relationship: return "Relationship"
        case .financial: return "Financial"
        case .creative: return "Creative"
        case .travel: return "Travel"
        case .personal: return "Personal"
        }
    }
    
    var icon: String {
        switch self {
        case .project: return "folder"
        case .habit: return "repeat.circle"
        case .learning: return "book"
        case .health: return "heart"
        case .career: return "briefcase"
        case .relationship: return "person.2"
        case .financial: return "dollarsign.circle"
        case .creative: return "paintbrush"
        case .travel: return "airplane"
        case .personal: return "person"
        }
    }
    
    var color: Color {
        switch self {
        case .project: return .blue
        case .habit: return .green
        case .learning: return .purple
        case .health: return .red
        case .career: return .orange
        case .relationship: return .pink
        case .financial: return .mint
        case .creative: return .yellow
        case .travel: return .cyan
        case .personal: return .indigo
        }
    }
}

enum MilestoneStatus: String, Codable, CaseIterable {
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"
    case delayed = "delayed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .delayed: return "Delayed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .planned: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .delayed: return .orange
        case .cancelled: return .red
        }
    }
}

enum MilestoneType: String, Codable, CaseIterable {
    case checkpoint = "checkpoint"
    case deliverable = "deliverable"
    case review = "review"
    case decision = "decision"
    case launch = "launch"
    
    var displayName: String {
        switch self {
        case .checkpoint: return "Checkpoint"
        case .deliverable: return "Deliverable"
        case .review: return "Review"
        case .decision: return "Decision"
        case .launch: return "Launch"
        }
    }
    
    var icon: String {
        switch self {
        case .checkpoint: return "flag"
        case .deliverable: return "shippingbox"
        case .review: return "magnifyingglass"
        case .decision: return "questionmark.diamond"
        case .launch: return "rocket"
        }
    }
}

enum RiskLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum VelocityTrend: String, Codable, CaseIterable {
    case accelerating = "accelerating"
    case stable = "stable"
    case slowing = "slowing"
    case stalled = "stalled"
    
    var displayName: String {
        switch self {
        case .accelerating: return "Accelerating"
        case .stable: return "Stable"
        case .slowing: return "Slowing"
        case .stalled: return "Stalled"
        }
    }
    
    var icon: String {
        switch self {
        case .accelerating: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .slowing: return "arrow.down.right"
        case .stalled: return "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .accelerating: return .green
        case .stable: return .blue
        case .slowing: return .orange
        case .stalled: return .red
        }
    }
}

enum TimelineEventType: String, Codable, CaseIterable {
    case goalCreated = "goal_created"
    case goalCompleted = "goal_completed"
    case milestoneCompleted = "milestone_completed"
    case taskCompleted = "task_completed"
    case deadlineChanged = "deadline_changed"
    case priorityChanged = "priority_changed"
    case statusChanged = "status_changed"
    case noteAdded = "note_added"
    case riskDetected = "risk_detected"
    case achievementUnlocked = "achievement_unlocked"
    
    var displayName: String {
        switch self {
        case .goalCreated: return "Goal Created"
        case .goalCompleted: return "Goal Completed"
        case .milestoneCompleted: return "Milestone Completed"
        case .taskCompleted: return "Task Completed"
        case .deadlineChanged: return "Deadline Changed"
        case .priorityChanged: return "Priority Changed"
        case .statusChanged: return "Status Changed"
        case .noteAdded: return "Note Added"
        case .riskDetected: return "Risk Detected"
        case .achievementUnlocked: return "Achievement Unlocked"
        }
    }
    
    var icon: String {
        switch self {
        case .goalCreated: return "plus.circle"
        case .goalCompleted: return "checkmark.circle.fill"
        case .milestoneCompleted: return "flag.fill"
        case .taskCompleted: return "checkmark.square.fill"
        case .deadlineChanged: return "calendar.badge.exclamationmark"
        case .priorityChanged: return "arrow.up.arrow.down"
        case .statusChanged: return "arrow.triangle.swap"
        case .noteAdded: return "note.text"
        case .riskDetected: return "exclamationmark.triangle.fill"
        case .achievementUnlocked: return "star.circle.fill"
        }
    }
}

enum EventImpact: String, Codable, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        }
    }
}

enum EventCreator: String, Codable, CaseIterable {
    case user = "user"
    case system = "system"
    case ai = "ai"
    case automation = "automation"
    
    var displayName: String {
        switch self {
        case .user: return "User"
        case .system: return "System"
        case .ai: return "AI"
        case .automation: return "Automation"
        }
    }
}

enum VersionChangeType: String, Codable, CaseIterable {
    case created = "created"
    case updated = "updated"
    case deleted = "deleted"
    case restored = "restored"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .updated: return "Updated"
        case .deleted: return "Deleted"
        case .restored: return "Restored"
        case .archived: return "Archived"
        }
    }
}

enum RippleChangeType: String, Codable, CaseIterable {
    case delayImpact = "delay_impact"
    case resourceConflict = "resource_conflict"
    case dependencyBlocked = "dependency_blocked"
    case priorityShift = "priority_shift"
    case scopeChange = "scope_change"
    
    var displayName: String {
        switch self {
        case .delayImpact: return "Delay Impact"
        case .resourceConflict: return "Resource Conflict"
        case .dependencyBlocked: return "Dependency Blocked"
        case .priorityShift: return "Priority Shift"
        case .scopeChange: return "Scope Change"
        }
    }
}

enum RippleSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum RippleActionType: String, Codable, CaseIterable {
    case reschedule = "reschedule"
    case reprioritize = "reprioritize"
    case reallocateResources = "reallocate_resources"
    case adjustScope = "adjust_scope"
    case addBuffer = "add_buffer"
    case escalate = "escalate"
    
    var displayName: String {
        switch self {
        case .reschedule: return "Reschedule"
        case .reprioritize: return "Reprioritize"
        case .reallocateResources: return "Reallocate Resources"
        case .adjustScope: return "Adjust Scope"
        case .addBuffer: return "Add Buffer"
        case .escalate: return "Escalate"
        }
    }
}

enum TimelineInsightCategory: String, Codable, CaseIterable {
    case progress = "progress"
    case patterns = "patterns"
    case risks = "risks"
    case opportunities = "opportunities"
    case predictions = "predictions"
    
    var displayName: String {
        switch self {
        case .progress: return "Progress"
        case .patterns: return "Patterns"
        case .risks: return "Risks"
        case .opportunities: return "Opportunities"
        case .predictions: return "Predictions"
        }
    }
}

enum TimeRange: String, Codable, CaseIterable {
    case oneMonth = "one_month"
    case threeMonths = "three_months"
    case sixMonths = "six_months"
    case oneYear = "one_year"
    case allTime = "all_time"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .allTime: return "All Time"
        case .custom: return "Custom"
        }
    }
}

enum TimelineViewMode: String, Codable, CaseIterable {
    case timeline = "timeline"
    case gantt = "gantt"
    case calendar = "calendar"
    case list = "list"
    
    var displayName: String {
        switch self {
        case .timeline: return "Timeline"
        case .gantt: return "Gantt"
        case .calendar: return "Calendar"
        case .list: return "List"
        }
    }
    
    var icon: String {
        switch self {
        case .timeline: return "timeline.selection"
        case .gantt: return "chart.bar.horizontal"
        case .calendar: return "calendar"
        case .list: return "list.bullet"
        }
    }
}

enum TimelineGrouping: String, Codable, CaseIterable {
    case none = "none"
    case category = "category"
    case priority = "priority"
    case status = "status"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .category: return "Category"
        case .priority: return "Priority"
        case .status: return "Status"
        case .area: return "Area"
        }
    }
}

enum TimelineSorting: String, Codable, CaseIterable {
    case priority = "priority"
    case dueDate = "due_date"
    case progress = "progress"
    case name = "name"
    case createdDate = "created_date"
    case lastActivity = "last_activity"
    
    var displayName: String {
        switch self {
        case .priority: return "Priority"
        case .dueDate: return "Due Date"
        case .progress: return "Progress"
        case .name: return "Name"
        case .createdDate: return "Created Date"
        case .lastActivity: return "Last Activity"
        }
    }
}

enum TimelineColorScheme: String, Codable, CaseIterable {
    case priority = "priority"
    case category = "category"
    case status = "status"
    case progress = "progress"
    
    var displayName: String {
        switch self {
        case .priority: return "Priority"
        case .category: return "Category"
        case .status: return "Status"
        case .progress: return "Progress"
        }
    }
}