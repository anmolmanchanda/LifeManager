import Foundation
import SwiftUI

// MARK: - Intelligent Rescheduling Models
// Missing model definitions for the intelligent rescheduling system

/// Represents a potential rescheduling scenario
struct ReschedulingScenario: Identifiable, Codable {
    let id = UUID()
    let taskId: UUID
    let originalDate: Date
    let proposedDate: Date
    let scenarioType: ScenarioType
    let impact: ReschedulingImpact
    let confidence: Double
    let reasoning: String
    let affectedTasks: [UUID]
    let bufferAvailable: Bool
    let conflictCount: Int
    
    var proposedTime: Date {
        return proposedDate
    }
    
    enum ScenarioType: String, Codable, CaseIterable {
        case immediate = "immediate"
        case nextAvailableSlot = "next_available_slot"
        case optimalTime = "optimal_time"
        case afterDependencies = "after_dependencies"
        case parkingLot = "parking_lot"
        case userPreferred = "user_preferred"
    }
}

/// Constraints for rescheduling decisions
struct ReschedulingConstraints: Codable {
    let respectDependencies: Bool
    let maintainBuffers: Bool
    let avoidOvertime: Bool
    let priorityThreshold: Double
    let maxDaysToDefer: Int
    let allowWeekends: Bool
    let respectFocusBlocks: Bool
    let conflictResolution: ConflictResolutionStrategy
    
    enum ConflictResolutionStrategy: String, Codable {
        case bumpLowerPriority = "bump_lower_priority"
        case compress = "compress"
        case extend = "extend"
        case askUser = "ask_user"
    }
    
    static var `default`: ReschedulingConstraints {
        return ReschedulingConstraints(
            respectDependencies: true,
            maintainBuffers: true,
            avoidOvertime: true,
            priorityThreshold: 0.7,
            maxDaysToDefer: 7,
            allowWeekends: false,
            respectFocusBlocks: true,
            conflictResolution: .bumpLowerPriority
        )
    }
}

/// AI-powered rescheduling decision
struct AIReschedulingDecision: Codable {
    let id = UUID()
    let taskId: UUID
    let decision: DecisionType
    let confidence: Double
    let selectedScenario: ReschedulingScenario?
    let reasoning: String
    let alternativeOptions: [ReschedulingScenario]
    let requiresUserInput: Bool
    let suggestedUserPrompt: String?
    let learningInsights: [String]
    let timestamp: Date
    
    enum DecisionType: String, Codable {
        case automatic = "automatic"
        case semiAutomatic = "semi_automatic"
        case userRequired = "user_required"
        case deferred = "deferred"
        case failed = "failed"
    }
}

/// Result of scenario analysis
struct ScenarioAnalysisResult: Codable {
    let bestScenario: ReschedulingScenario?
    let allScenarios: [ReschedulingScenario]
    let scores: [UUID: ScenarioScore] // Scenario ID to Score mapping
    let analysis: String
    let confidence: Double
    let risks: [ReschedulingRisk]
    let recommendations: [String]
}

/// Score for a rescheduling scenario
struct ScenarioScore: Codable {
    let scenarioId: UUID
    let totalScore: Double
    let components: ScoreComponents
    let viability: ScenarioViability
    
    // Computed property for compatibility
    var overallScore: Double {
        return totalScore
    }
    
    struct ScoreComponents: Codable {
        let timePreferenceScore: Double
        let priorityAlignmentScore: Double
        let dependencyScore: Double
        let bufferScore: Double
        let conflictScore: Double
        let userPatternScore: Double
    }
    
    enum ScenarioViability: String, Codable {
        case excellent = "excellent"
        case good = "good"
        case acceptable = "acceptable"
        case poor = "poor"
        case unviable = "unviable"
    }
}

/// Final rescheduling decision
struct ReschedulingDecision: Codable {
    let id = UUID()
    let taskId: UUID
    let originalDate: Date?
    let newDate: Date?
    let decisionType: DecisionType
    let executed: Bool
    let executedAt: Date?
    let undoableUntil: Date?
    let userFeedback: UserFeedback?
    let automationConfidence: Double
    let reasoning: String
    
    enum DecisionType: String, Codable {
        case reschedule = "reschedule"
        case park = "park"
        case deferAction = "defer"
        case escalate = "escalate"
        case noAction = "no_action"
    }
    
    struct UserFeedback: Codable {
        let approved: Bool
        let reasoning: String?
        let timestamp: Date
    }
}

/// Impact assessment for rescheduling
struct ReschedulingImpact: Codable {
    let severity: ImpactSeverity
    let affectedTaskCount: Int
    let cascadeDepth: Int
    let bufferReduction: Int // in minutes
    let overtimeRisk: Double
    let description: String
    
    enum ImpactSeverity: String, Codable, CaseIterable {
        case minimal = "minimal"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}

/// Risk assessment for rescheduling
struct ReschedulingRisk: Identifiable, Codable {
    let id = UUID()
    let riskType: RiskType
    let probability: Double
    let impact: String
    let mitigation: String?
    
    enum RiskType: String, Codable {
        case dependencyConflict = "dependency_conflict"
        case bufferViolation = "buffer_violation"
        case overtimeRisk = "overtime_risk"
        case cascadeEffect = "cascade_effect"
        case userDisruption = "user_disruption"
    }
}

/// Personal rule for AI learning
struct PersonalRule: Identifiable, Codable {
    let id = UUID()
    let ruleType: RuleType
    let pattern: String
    let action: String
    let confidence: Double
    let frequency: Int
    let lastApplied: Date?
    let isActive: Bool
    let source: RuleSource
    
    enum RuleType: String, Codable {
        case scheduling = "scheduling"
        case prioritization = "prioritization"
        case categorization = "categorization"
        case notification = "notification"
        case automation = "automation"
        case behavioral = "behavioral"
    }
    
    enum RuleSource: String, Codable {
        case userDefined = "user_defined"
        case learned = "learned"
        case suggested = "suggested"
        case system = "system"
    }
}

/// Notification settings for intelligent automation
struct AutomationNotificationSettings: Codable {
    let enableProactive: Bool
    let dailySummaryTime: Date?
    let overdueThreshold: TimeInterval
    let nudgeThreshold: TimeInterval
    let escalationLevels: [EscalationLevel]
    let quietHours: QuietHours?
    
    struct EscalationLevel: Codable {
        let level: Int
        let delayMinutes: Int
        let channels: [NotificationChannel]
    }
    
    struct QuietHours: Codable {
        let enabled: Bool
        let startTime: Date
        let endTime: Date
        let allowCritical: Bool
    }
    
    enum NotificationChannel: String, Codable {
        case app = "app"
        case email = "email"
        case sms = "sms"
        case webhook = "webhook"
    }
    
    init() {
        self.enableProactive = true
        self.dailySummaryTime = nil
        self.overdueThreshold = 3600 // 1 hour
        self.nudgeThreshold = 259200 // 3 days
        self.escalationLevels = []
        self.quietHours = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.enableProactive = try container.decodeIfPresent(Bool.self, forKey: .enableProactive) ?? true
        self.dailySummaryTime = try container.decodeIfPresent(Date.self, forKey: .dailySummaryTime)
        self.overdueThreshold = try container.decodeIfPresent(TimeInterval.self, forKey: .overdueThreshold) ?? 3600
        self.nudgeThreshold = try container.decodeIfPresent(TimeInterval.self, forKey: .nudgeThreshold) ?? 259200
        self.escalationLevels = try container.decodeIfPresent([EscalationLevel].self, forKey: .escalationLevels) ?? []
        self.quietHours = try container.decodeIfPresent(QuietHours.self, forKey: .quietHours)
    }
}