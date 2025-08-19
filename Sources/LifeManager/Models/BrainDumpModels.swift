//
// BrainDumpModels.swift
// LifeManager
//
// Implements: v2.0 "Intelligence Expansion" - Enhanced Brain Dump Data Models
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Processing Pipeline
// Status: ✅ RESTORED June 18, 2025 - Phase 1C AI Pipeline Integration
// Future: v2.5 Multi-Modal Processing, Advanced Context Analysis
//
// RESTORED from temp_excluded/ during Phase 1C AI pipeline integration.
// Comprehensive data models for enhanced brain dump processing with AI insights.
//

import Foundation

// MARK: - Core Brain Dump Results

struct BrainDumpResult {
    let originalInput: String
    let analysisResult: EnhancedLLMAnalysisResult
    let suggestedItems: [EnhancedBrainDumpItem]
    let confidence: Double
    let requiresReview: Bool
    let processingMetadata: ProcessingMetadata
    let clarificationQuestions: [String]
    let optimizationSuggestions: [String]
    let contextualInsights: ContextualInsights
}

struct EnhancedLLMAnalysisResult {
    let extractedItems: [EnhancedBrainDumpItem]
    let confidence: Double
    let hasAmbiguousItems: Bool
    let reasoning: DetailedReasoning
    let suggestedNewAreas: [String]
    let suggestedNewProjects: [String]
    let patternAnalysis: PatternAnalysis
    let contextualFactors: [ContextualFactor]
    let uncertaintyAnalysis: UncertaintyAnalysis
    let crossItemRelationships: [ItemRelationship]
}

// Protocol for types that can be treated as EnhancedBrainDumpItem
protocol EnhancedBrainDumpItemProtocol {
    var id: UUID { get }
    var title: String { get }
    var content: String { get }
    var contentType: ContentType { get }
    var paraCategory: PARACategory { get }
    var workPersonal: WorkPersonalType { get }
    var priority: TaskPriority { get }
}

struct EnhancedBrainDumpItem: EnhancedBrainDumpItemProtocol {
    let id: UUID
    let title: String
    let content: String
    let contentType: ContentType
    let paraCategory: PARACategory
    let suggestedArea: String?
    let suggestedProject: String?
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let dueDate: String?
    let tags: [String]
    let confidence: Double
    let metadata: [String: Any]
    
    // Enhanced reasoning fields
    let classificationReasoning: ClassificationReasoning
    let alternativeClassifications: [AlternativeClassification]
    let contextualRelevance: ContextualRelevance
    let semanticSimilarity: [SemanticSimilarity]
    let uncertaintyFactors: [UncertaintyFactor]
    let suggestedActions: [SuggestedAction]
    let estimatedEffort: EffortEstimate
    let timelineAnalysis: TimelineAnalysis
}

// MARK: - Processing Metadata & Context

struct ProcessingMetadata {
    let processingTime: Date
    let aiServicesUsed: [String]
    let contextItemsConsidered: Int
    let rulesApplied: Int
}

struct ContextualInsights {
    let recentPatterns: [String]
    let suggestedWorkflows: [String]
    let productivityTips: [String]
}

struct BrainDumpUserContext {
    let currentFocus: String?
    let timeOfDay: Date
    let workMode: WorkPersonalType
    let recentActivities: [String]
}

// MARK: - Enhanced Reasoning Structures

struct DetailedReasoning {
    let primaryFactors: [ReasoningFactor]
    let contextualInfluences: [String]
    let patternMatches: [String]
    let uncertainties: [String]
    let confidenceBreakdown: ConfidenceBreakdown
    let decisionTree: [DecisionNode]
}

struct ReasoningFactor {
    let type: ReasoningType
    let description: String
    let weight: Double
    let confidence: Double
    let evidence: [String]
}

enum ReasoningType {
    case keywordMatch, contextualPattern, semanticSimilarity, historicalPattern, userPreference, temporalIndicator
}

struct ConfidenceBreakdown {
    let overallConfidence: Double
    let categoryConfidence: [String: Double]
    let factorContributions: [String: Double]
}

struct DecisionNode {
    let condition: String
    let outcome: String
    let confidence: Double
    let alternatives: [String]
}

// MARK: - Classification & Analysis

struct ClassificationReasoning {
    let primaryReasons: [String]
    let supportingEvidence: [String]
    let counterEvidence: [String]
    let confidenceFactors: [String]
    let alternativeOptions: [String]
    let contextualInfluence: String
}

struct AlternativeClassification {
    let category: PARACategory
    let probability: Double
    let reasoning: String
    let supportingFactors: [String]
    let implications: [String]
}

struct ContextualRelevance {
    let recentActivityAlignment: Double
    let existingProjectsAlignment: [ProjectAlignment]
    let areaFocusAlignment: [AreaAlignment]
    let workPersonalBalance: Double
    let priorityConsistency: Double
}

struct ProjectAlignment {
    let projectName: String
    let alignmentScore: Double
    let relevantAspects: [String]
    let confidence: Double
}

struct AreaAlignment {
    let areaName: String
    let alignmentScore: Double
    let relevantAspects: [String]
    let confidence: Double
}

// MARK: - Semantic Analysis

struct SemanticSimilarity {
    let targetItem: String
    let similarity: Double
    let relevanceType: RelevanceType
    let explanation: String
}

enum RelevanceType {
    case contentSimilarity, contextualRelevance, semanticRelatedness, goalAlignment
}

// MARK: - Uncertainty & Risk Analysis

struct UncertaintyFactor {
    let type: UncertaintyType
    let description: String
    let impact: UncertaintyImpact
    let mitigation: String
}

enum UncertaintyType {
    case ambiguousWording, conflictingContext, insufficientInformation, multipleInterpretations
}

enum UncertaintyImpact {
    case low, medium, high
}

struct UncertaintyAnalysis {
    let ambiguousItems: [String]
    let confidenceRanges: [String: ClosedRange<Double>]
    let recommendations: [String]
}

// MARK: - Actionability & Execution

struct SuggestedAction {
    let type: BrainDumpActionType
    let description: String
    let priority: TaskPriority
    let estimatedTime: TimeInterval
    let dependencies: [String]
}

enum BrainDumpActionType {
    case immediate, scheduled, delegated, deferred, clarificationNeeded
}

struct EffortEstimate {
    let timeRequired: TimeInterval // in seconds
    let complexity: BrainDumpComplexityLevel
    let confidence: Double
}

enum BrainDumpComplexityLevel {
    case trivial, low, medium, high, expert
}

struct TimelineAnalysis {
    let suggestedScheduling: Date
    let deadlineAnalysis: Date?
    let bufferTime: TimeInterval
}

// MARK: - Pattern Analysis

struct PatternAnalysis {
    let detectedPatterns: [Pattern]
    let frequencyAnalysis: [String: Int]
    let temporalPatterns: [TemporalPattern]
}

struct Pattern {
    let type: UnifiedPatternType
    let description: String
    let frequency: Int
    let confidence: Double
    let examples: [String]
}

// PatternType moved to UnifiedPatternType in CoreModels.swift

struct TemporalPattern {
    let timeframe: TemporalTimeframe
    let pattern: String
    let frequency: Int
    let significance: Double
}

enum TemporalTimeframe {
    case hourly, daily, weekly, monthly, seasonal
}

// MARK: - Contextual Factors

struct ContextualFactor {
    let type: ContextualFactorType
    let description: String
    let influence: InfluenceLevel
    let evidence: [String]
}

enum ContextualFactorType {
    case recentActivity, calendarEvents, seasonalTrends, workloadStatus, focusAreas
}

enum InfluenceLevel {
    case minimal, moderate, significant, critical
}

// MARK: - Item Relationships

struct ItemRelationship {
    let sourceItemId: UUID
    let targetItemId: UUID
    let relationshipType: RelationshipType
    let strength: Double
    let description: String
}

enum RelationshipType {
    case dependency, similarity, sequence, grouping, conflict
}

// MARK: - Legacy Support

/// Simplified brain dump item for backward compatibility
struct BrainDumpItem {
    let id: UUID
    let title: String
    let content: String
    let contentType: ContentType
    let paraCategory: PARACategory
    let suggestedArea: String?
    let suggestedProject: String?
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let dueDate: String?
    let tags: [String]
    let confidence: Double
    let metadata: [String: String]
}

/// Execution summary for completed brain dump processing
struct ExecutionSummary {
    let totalItemsProcessed: Int
    let itemsCreated: Int
    let itemsSkipped: Int
    let errors: [String]
    let warnings: [String]
    let processingTime: TimeInterval
    let confidenceDistribution: [String: Int]
    let categoryDistribution: [PARACategory: Int]
    let newAreasCreated: [String]
    let newProjectsCreated: [String]
    
    // Additional properties for UI display
    let successCount: Int
    let tasksCreated: [String]
    let notesCreated: [String]
    let journalEntriesCreated: [String]
    let resourcesCreated: [String]
    let appointmentsCreated: [String]
    let habitsCreated: [String]
    let goalsCreated: [String]
    let financialTransactionsCreated: [String]
}

// MARK: - Extensions for Convenience

extension EnhancedBrainDumpItem {
    /// Convert to simple BrainDumpItem for backward compatibility
    func toBrainDumpItem() -> BrainDumpItem {
        return BrainDumpItem(
            id: id,
            title: title,
            content: content,
            contentType: contentType,
            paraCategory: paraCategory,
            suggestedArea: suggestedArea,
            suggestedProject: suggestedProject,
            workPersonal: workPersonal,
            priority: priority,
            dueDate: dueDate,
            tags: tags,
            confidence: confidence,
            metadata: metadata.compactMapValues { $0 as? String }
        )
    }
    
    /// Check if item has high confidence
    var hasHighConfidence: Bool {
        return confidence >= 0.8
    }
    
    /// Check if item needs review
    var needsReview: Bool {
        return confidence < 0.7 || !uncertaintyFactors.isEmpty
    }
    
    /// Get primary classification reason
    var primaryReason: String {
        return classificationReasoning.primaryReasons.first ?? "Unknown"
    }
}

extension BrainDumpResult {
    /// Get items that need user review
    var itemsNeedingReview: [EnhancedBrainDumpItem] {
        return suggestedItems.filter { $0.needsReview }
    }
    
    /// Get high confidence items
    var highConfidenceItems: [EnhancedBrainDumpItem] {
        return suggestedItems.filter { $0.hasHighConfidence }
    }
    
    /// Get items by category
    func items(for category: PARACategory) -> [EnhancedBrainDumpItem] {
        return suggestedItems.filter { $0.paraCategory == category }
    }
    
    /// Overall processing quality score
    var qualityScore: Double {
        let avgConfidence = suggestedItems.map { $0.confidence }.reduce(0, +) / Double(max(suggestedItems.count, 1))
        let clarificationPenalty = Double(clarificationQuestions.count) * 0.1
        return max(0, avgConfidence - clarificationPenalty)
    }
}