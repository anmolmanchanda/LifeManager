//
// Phase2ReschedulingModels.swift
// LifeManager
//
// Phase 2: Smart Auto-Rescheduling Implementation Models
// Supports advanced AI decision-making for complex rescheduling scenarios
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation

// MARK: - Rescheduling Scenarios

/// Represents a potential rescheduling scenario with detailed analysis
struct ReschedulingScenario: Hashable, Identifiable {
    let id = UUID()
    let description: String
    let proposedTime: Date
    let duration: Int // minutes
    let likelihood: Double // 0.0-1.0
    let feasibility: Double // 0.0-1.0
    let requiredResources: [String]
    let affectedDependencies: [UUID]
    let complexityFactors: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReschedulingScenario, rhs: ReschedulingScenario) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Constraints for rescheduling decisions
struct ReschedulingConstraints {
    let hardDeadline: Date
    let availableTimeSlots: [AvailabilitySlot]
    let resourceLimitations: [String]
    let dependencyRequirements: [DependencyRequirement]
    let userPreferences: UserSchedulingPreferences
}

/// Dependency requirement for scheduling
struct DependencyRequirement {
    let taskId: UUID
    let description: String
    let mustCompleteBefore: Date?
    let canStartAfter: Date?
}

// MARK: - Scenario Analysis

/// Result of analyzing multiple rescheduling scenarios
struct ScenarioAnalysisResult {
    let scenarioScores: [ReschedulingScenario: ScenarioScore]
    let overallAnalysis: String
    let recommendedScenario: ReschedulingScenario?
    let complexityLevel: ComplexityLevel
}

/// Detailed score breakdown for a scenario
struct ScenarioScore {
    let overallScore: Double
    let timeCompatibility: Double
    let resourceAvailability: Double
    let projectImpact: Double
    let riskFactor: Double
    let aiConfidence: Double
}

/// Complexity level for decision making
enum ComplexityLevel: String, CaseIterable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
}

// MARK: - AI Decision Making

/// AI-generated rescheduling decision with confidence metrics
struct AIReschedulingDecision {
    let selectedScenario: ReschedulingScenario?
    let confidence: Double
    let reasoning: String
    let modifications: String?
    let riskLevel: RiskLevel
    let requiresUserInput: Bool
}

/// Risk level assessment for scenarios
enum RiskLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"  
    case high = "high"
}

// MARK: - Final Decision

/// Final rescheduling decision after AI analysis
struct ReschedulingDecision {
    let action: ReschedulingAction
    let selectedScenario: ReschedulingScenario?
    let confidence: Double
    let reasoning: String
    let automaticExecution: Bool
    let userNotificationSent: Bool
    let timestamp: Date
}

/// Possible rescheduling actions
enum ReschedulingAction: String, CaseIterable {
    case automaticReschedule = "automatic_reschedule"
    case requestUserInput = "request_user_input"
    case failed = "failed"
    case deferred = "deferred"
}

// MARK: - Learning Data

/// Data structure for learning from rescheduling decisions
struct ReschedulingLearningData {
    let taskCharacteristics: TaskCharacteristics
    let scenarios: [ReschedulingScenario]
    let decision: ReschedulingDecision
    let timestamp: Date
    let userContext: ProcessingContext
}

/// Task characteristics for learning patterns
struct TaskCharacteristics {
    let priority: TaskPriority
    let workPersonal: WorkPersonalType
    let estimatedDuration: Int
    let hasProject: Bool
    let isFocus: Bool
    let overdueHours: Double
}

// MARK: - Enhanced Rescheduling Types

/// Enhanced rescheduling reason with AI optimization
enum ReschedulingReason: String, CaseIterable {
    case overdue = "overdue"
    case conflictDetected = "conflict_detected"
    case bufferViolation = "buffer_violation"
    case userRequest = "user_request"
    case aiOptimization = "ai_optimization"
    case dependencyChange = "dependency_change"
    case externalCalendarConflict = "external_calendar_conflict"
    
    var displayName: String {
        switch self {
        case .overdue: return "Overdue Task"
        case .conflictDetected: return "Schedule Conflict"
        case .bufferViolation: return "Buffer Violation"
        case .userRequest: return "User Request"
        case .aiOptimization: return "AI Optimization"
        case .dependencyChange: return "Dependency Change"
        case .externalCalendarConflict: return "External Calendar Conflict"
        }
    }
}

/// Enhanced priority intelligence with AI reasoning
struct PriorityIntelligence {
    let taskId: UUID
    let intelligenceScore: Double
    let urgencyScore: Double
    let importanceScore: Double
    let contextScore: Double
    let userPatternScore: Double
    let reasoningFactors: [String]
    
    var overallScore: Double {
        return (intelligenceScore + urgencyScore + importanceScore + contextScore + userPatternScore) / 5.0
    }
}

// MARK: - Task Dependencies

/// Task with its dependency information for intelligent scheduling
struct TaskWithDependencies {
    let task: LifeTask
    let dependencies: [TaskDependency]
    let dependents: [TaskDependency]
    
    var canStart: Bool {
        return dependencies.allSatisfy { $0.isCompleted }
    }
    
    func canBeRescheduled(to date: Date) -> (canReschedule: Bool, reason: String?) {
        // Check if rescheduling would violate any dependencies
        for dependency in dependencies {
            if !dependency.isCompleted && date < dependency.mustCompleteBy {
                return (false, "Dependency '\(dependency.title)' must be completed first")
            }
        }
        
        for dependent in dependents {
            if dependent.scheduledDate < date {
                return (false, "Dependent task '\(dependent.title)' would be affected")
            }
        }
        
        return (true, nil)
    }
}

/// Task dependency with scheduling constraints
struct TaskDependency {
    let id: UUID
    let title: String
    let taskId: UUID
    let dependentTaskId: UUID
    let dependencyType: DependencyType
    let isCompleted: Bool
    let scheduledDate: Date
    let mustCompleteBy: Date
}

/// Types of task dependencies
enum DependencyType: String, CaseIterable {
    case finishToStart = "finish_to_start"
    case startToStart = "start_to_start"
    case finishToFinish = "finish_to_finish"
    case startToFinish = "start_to_finish"
    
    var displayName: String {
        switch self {
        case .finishToStart: return "Finish-to-Start"
        case .startToStart: return "Start-to-Start"
        case .finishToFinish: return "Finish-to-Finish"
        case .startToFinish: return "Start-to-Finish"
        }
    }
}

// MARK: - Rescheduling History

/// Enhanced rescheduling history entry with Phase 2 data
struct ReschedulingHistoryEntry: Identifiable {
    let id = UUID()
    let taskId: UUID
    let taskTitle: String
    let action: ReschedulingHistoryAction
    let originalDueDate: String?
    let newDueDate: String?
    let reasoning: String
    let confidence: Double
    let timestamp: Date
    let undoAction: UndoAction?
}

/// Rescheduling history actions
enum ReschedulingHistoryAction: String, CaseIterable {
    case autoRescheduled = "auto_rescheduled"
    case userOverride = "user_override"
    case undone = "undone"
    case aiOptimized = "ai_optimized"
    case conflictResolved = "conflict_resolved"
    
    var displayName: String {
        switch self {
        case .autoRescheduled: return "Auto-Rescheduled"
        case .userOverride: return "User Override"
        case .undone: return "Undone"
        case .aiOptimized: return "AI Optimized"
        case .conflictResolved: return "Conflict Resolved"
        }
    }
}

/// Undo action types
enum UndoAction: String, CaseIterable {
    case undoToOriginal = "undo_to_original"
    case rescheduleAgain = "reschedule_again"
    case parkTask = "park_task"
}

// MARK: - Undoable Actions

/// Enhanced undoable rescheduling action with expiration
struct UndoableReschedulingAction: Identifiable {
    let id = UUID()
    let taskId: UUID
    let taskTitle: String
    let originalDueDate: String?
    let newDueDate: String
    let reschedulingReason: String
    let confidence: Double
    let timestamp: Date
    let expiresAt: Date
    
    var canUndo: Bool {
        return Date() < expiresAt
    }
    
    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
}

// MARK: - User Scheduling Preferences

/// Enhanced user scheduling preferences for Phase 2
struct UserSchedulingPreferences {
    let workingHours: WorkingHoursPreference
    let focusBlocks: [FocusBlock]
    let reschedulingSettings: ReschedulingSettings
    let notificationSettings: NotificationSettings
}

/// Working hours preference
struct WorkingHoursPreference {
    let startHour: Int
    let endHour: Int
    let workDays: [Int] // 1 = Sunday, 2 = Monday, etc.
    let timeZone: TimeZone
    
    static let `default` = WorkingHoursPreference(
        startHour: 9,
        endHour: 17,
        workDays: [2, 3, 4, 5, 6], // Monday-Friday
        timeZone: TimeZone.current
    )
}

/// Focus block for concentrated work
struct FocusBlock {
    let name: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let priority: FocusBlockPriority
    let applicableDays: [Int] // 1 = Sunday, 2 = Monday, etc.
}

/// Focus block priority levels
enum FocusBlockPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Rescheduling behavior settings
struct ReschedulingSettings {
    let allowAutomaticRescheduling: Bool
    let maxReschedulingAttempts: Int
    let confidenceThreshold: Double
    let requireConfirmationBelow: Double
    let bufferPreference: Int // minutes
    let cascadeLimit: Int
    
    static let `default` = ReschedulingSettings(
        allowAutomaticRescheduling: true,
        maxReschedulingAttempts: 3,
        confidenceThreshold: 0.7,
        requireConfirmationBelow: 0.6,
        bufferPreference: 15,
        cascadeLimit: 5
    )
}

/// Notification settings for rescheduling
struct NotificationSettings {
    let notifyOnAutoReschedule: Bool
    let notifyOnConflicts: Bool
    let notifyOnLowConfidence: Bool
    let dailySummary: Bool
    let escalationEnabled: Bool
    
    static let `default` = NotificationSettings(
        notifyOnAutoReschedule: true,
        notifyOnConflicts: true,
        notifyOnLowConfidence: true,
        dailySummary: true,
        escalationEnabled: false
    )
}

// MARK: - Rescheduling Events

/// Enhanced rescheduling event with Phase 2 metadata
struct ReschedulingEvent: Identifiable {
    let id = UUID()
    let taskId: UUID
    let originalDate: String
    let newDate: String
    let reason: ReschedulingReason
    let wasAutomatic: Bool
    let confidence: Double
    let timestamp: Date = Date()
    let metadata: [String: Any]?
    
    init(taskId: UUID, originalDate: String, newDate: String, reason: ReschedulingReason, wasAutomatic: Bool, confidence: Double, metadata: [String: Any]? = nil) {
        self.taskId = taskId
        self.originalDate = originalDate
        self.newDate = newDate
        self.reason = reason
        self.wasAutomatic = wasAutomatic
        self.confidence = confidence
        self.metadata = metadata
    }
}

// MARK: - Default Extensions

extension TaskPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

extension WorkPersonalType {
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        }
    }
}

// MARK: - Helper Extensions

extension LifeTask {
    /// Calculate how many hours the task is overdue
    var overdueByHours: Double {
        guard let dueDateString = dueDate,
              let dueDate = ISO8601DateFormatter().date(from: dueDateString) else {
            return 0.0
        }
        
        let now = Date()
        if now > dueDate {
            return now.timeIntervalSince(dueDate) / 3600.0
        }
        
        return 0.0
    }
    
    /// Check if task is overdue
    var isOverdue: Bool {
        return overdueByHours > 0
    }
    
    /// Check if task can be automatically rescheduled
    var canBeAutomaticallyRescheduled: Bool {
        // Basic rules for automatic rescheduling eligibility
        return !isArchived && status != .completed && status != .archived
    }
}