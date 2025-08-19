//
// StubModels.swift
// LifeManager
//
// Temporary stub models for missing dependencies
// These will be replaced with proper implementations in Phase 2
//

import Foundation

// MARK: - Missing Analytics Models

enum TrendDirection: String, Codable, CaseIterable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    case unknown = "unknown"
}

struct TrendData: Codable {
    let direction: TrendDirection
    let magnitude: Float
    let confidence: Float
    let dataPoints: Int
}

// MARK: - Missing Calendar Models (already defined in CalendarOrchestrationService)
// BufferStatus is already defined in CalendarOrchestrationService.swift

// MARK: - Missing Rule Models for Tests

struct StubPersonalRule: Codable {
    let id: UUID
    let pattern: String
    let action: PersonalRuleAction
    let confidence: Float
    let correctionCount: Int
    let createdAt: Date
    let lastUsed: Date?
}

struct PersonalRuleAction: Codable {
    enum ActionType: String, Codable {
        case changeCategory
        case changePriority
        case addTags
        case changeWorkPersonal
    }
    
    let type: ActionType
    let newCategory: PARACategory?
    let newPriority: TaskPriority?
    let newTags: [String]?
    let newWorkPersonal: WorkPersonalType?
}

// MARK: - Placeholder for future enhancements

struct AIInsight: Codable {
    let id: UUID
    let type: String
    let confidence: Float
    let recommendation: String
    let timestamp: Date
}

struct StubPatternAnalysis: Codable {
    let patterns: [String: Float]
    let confidence: Float
    let sampleSize: Int
}