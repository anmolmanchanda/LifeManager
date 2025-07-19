//
// TimelineModels.swift
// LifeManager
//
// Timeline View Models: Goal-centric models for Timeline View
// Recreated from deleted TimelineViewModels.swift
//

import Foundation
import SwiftUI

// MARK: - Timeline Core Models

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
}

/// Goal milestone/checkpoint
struct Milestone: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let name: String
    let description: String?
    let dueDate: Date?
    let targetDate: Date? // Legacy alias for dueDate
    let completedDate: Date?
    let isCompleted: Bool
    let isBlocked: Bool
    let priority: GoalPriority
    let progressPercentage: Double? // 0.0 - 1.0
    let orderIndex: Int
    let dependencies: [UUID] // Other milestone IDs
    let createdAt: Date
    let updatedAt: Date
}

/// Progress summary for Timeline header
struct ProgressSummary: Codable {
    let activeGoalsCount: Int
    let completionRate: Double // 0.0 - 1.0
    let atRiskGoalsCount: Int
    let upcomingMilestonesCount: Int
}

/// Timeline AI insight for Timeline View
struct TimelineInsight: Identifiable, Codable {
    let id: UUID
    let category: InsightCategory
    let priority: TimelineInsightPriority
    let title: String
    let summary: String
    let description: String
    let details: [String]
    let hasActionableRecommendations: Bool
    let createdAt: Date
}

/// Priority level for Timeline insights
enum TimelineInsightPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Enums

enum GoalStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case active = "active"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    case archived = "archived"
}

enum GoalPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        case .urgent: return "Urgent"
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
    
    var displayName: String {
        switch self {
        case .project: return "Project"
        case .habit: return "Habit"
        case .learning: return "Learning"
        case .health: return "Health"
        case .career: return "Career"
        case .relationship: return "Relationship"
        }
    }
}

enum RiskLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum VelocityTrend: String, Codable, CaseIterable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}