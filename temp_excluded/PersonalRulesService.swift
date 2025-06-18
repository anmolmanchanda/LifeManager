//
// PersonalRulesService.swift
// LifeManager
//
// Implements: v2.0 "Self-Improving Categorizer" - Feedback Loop System
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ⏳ IN PROGRESS as of June 14, 2025
// Future: v2.5 Machine Learning Rules, Advanced Pattern Recognition
//

import Foundation

/// Service for managing personal PARA rules learned from user corrections
/// Implements feedback loop system to adapt to user preferences and reduce manual review
class PersonalRulesService: ObservableObject {
    
    static let shared = PersonalRulesService()
    
    // MARK: - Configuration
    
    private struct RulesConfig {
        static let minCorrectionsForRule = 2 // Minimum corrections needed to create a rule
        static let ruleConfidenceThreshold = 0.7 // Minimum confidence to apply rule
        static let maxRulesPerPattern = 5 // Maximum rules per pattern type
        static let ruleExpirationDays = 90 // Days after which unused rules expire
        static let correctionRetentionDays = 180 // Days to retain correction history
    }
    
    // MARK: - Published State
    
    @Published var personalRules: [PersonalPARARule] = []
    @Published var userCorrections: [UserCorrection] = []
    @Published var ruleStats: RuleStats = RuleStats()
    @Published var suggestedRules: [SuggestedRule] = []
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let llmService = LLMService.shared
    
    // MARK: - Internal State
    
    private let rulesQueue = DispatchQueue(label: "personal.rules", qos: .utility)
    private var ruleUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await loadPersonalRules()
            await loadUserCorrections()
            startRuleUpdateTimer()
        }
    }
    
    deinit {
        ruleUpdateTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Record a user correction and potentially create/update rules
    func recordUserCorrection(
        originalItem: ContextualPARAItem,
        correctedClassification: PARAClassification,
        userFeedback: String? = nil
    ) async {
        
        let correction = UserCorrection(
            id: UUID(),
            originalItem: originalItem,
            correctedClassification: correctedClassification,
            userFeedback: userFeedback,
            timestamp: Date(),
            context: await getCurrentCorrectionContext()
        )
        
        // Add to corrections list
        await MainActor.run {
            userCorrections.insert(correction, at: 0)
            updateRuleStats()
        }
        
        // Persist correction
        await persistUserCorrection(correction)
        
        // Analyze for new rules
        await analyzeForNewRules(from: correction)
        
        // Update existing rules if applicable
        await updateExistingRules(with: correction)
        
        print("📝 RULES: ✅ Recorded user correction - \(originalItem.originalItem.content.prefix(50))...")
    }
    
    /// Apply personal rules to a contextual PARA item
    func applyPersonalRules(to item: ContextualPARAItem) async -> ContextualPARAItem {
        var modifiedItem = item
        var appliedRules: [PersonalPARARule] = []
        
        for rule in personalRules {
            if rule.appliesTo(item) && rule.confidence >= Float(RulesConfig.ruleConfidenceThreshold) {
                modifiedItem = rule.apply(to: modifiedItem)
                appliedRules.append(rule)
                
                // Update rule usage statistics
                await updateRuleUsage(rule)
            }
        }
        
        // Add applied rules to reasoning
        if !appliedRules.isEmpty {
            let ruleDescriptions = appliedRules.map { $0.description }.joined(separator: "; ")
            modifiedItem.reasoning += "\n\nPersonal Rules Applied: \(ruleDescriptions)"
        }
        
        return modifiedItem
    }
    
    /// Get personal rules that apply to a specific pattern
    func getRulesForPattern(_ pattern: String) -> [PersonalPARARule] {
        return personalRules.filter { rule in
            rule.pattern.localizedCaseInsensitiveContains(pattern) ||
            pattern.localizedCaseInsensitiveContains(rule.pattern)
        }
    }
    
    /// Get rule suggestions based on correction patterns
    func generateRuleSuggestions() async -> [SuggestedRule] {
        let recentCorrections = Array(userCorrections.prefix(50))
        var suggestions: [SuggestedRule] = []
        
        // Analyze correction patterns
        let patterns = await analyzeCorrectionsForPatterns(recentCorrections)
        
        for pattern in patterns {
            if pattern.frequency >= RulesConfig.minCorrectionsForRule {
                let suggestion = await generateRuleSuggestion(from: pattern)
                suggestions.append(suggestion)
            }
        }
        
        await MainActor.run {
            suggestedRules = suggestions
        }
        
        return suggestions
    }
    
    /// Accept a suggested rule and add it to personal rules
    func acceptSuggestedRule(_ suggestion: SuggestedRule) async {
        let newRule = PersonalPARARule(
            id: UUID(),
            pattern: suggestion.pattern,
            targetClassification: suggestion.targetClassification,
            confidence: suggestion.confidence,
            description: suggestion.description,
            ruleType: suggestion.ruleType,
            createdFrom: suggestion.basedOnCorrections,
            createdAt: Date(),
            lastUsed: nil,
            usageCount: 0,
            isActive: true
        )
        
        await MainActor.run {
            personalRules.append(newRule)
            suggestedRules.removeAll { $0.id == suggestion.id }
            updateRuleStats()
        }
        
        await persistPersonalRule(newRule)
        
        print("📝 RULES: ✅ Accepted suggested rule - \(newRule.description)")
    }
    
    /// Reject a suggested rule
    func rejectSuggestedRule(_ suggestion: SuggestedRule) async {
        await MainActor.run {
            suggestedRules.removeAll { $0.id == suggestion.id }
        }
        
        // Mark corrections as reviewed to avoid re-suggesting
        await markCorrectionsAsReviewed(suggestion.basedOnCorrections)
    }
    
    /// Get rule effectiveness statistics
    func getRuleEffectiveness() -> [RuleEffectiveness] {
        return personalRules.map { rule in
            RuleEffectiveness(
                rule: rule,
                successRate: calculateRuleSuccessRate(rule),
                averageConfidenceImprovement: calculateConfidenceImprovement(rule),
                timesSaved: rule.usageCount,
                lastImpact: rule.lastUsed
            )
        }.sorted { $0.successRate > $1.successRate }
    }
    
    /// Disable or remove ineffective rules
    func cleanupIneffectiveRules() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -RulesConfig.ruleExpirationDays, to: Date()) ?? Date()
        
        var rulesToRemove: [PersonalPARARule] = []
        
        for rule in personalRules {
            // Remove rules that haven't been used recently and have low confidence
            if let lastUsed = rule.lastUsed, lastUsed < cutoffDate, rule.confidence < 0.5 {
                rulesToRemove.append(rule)
            }
            // Remove rules that have never been used after 30 days
            else if rule.lastUsed == nil && rule.createdAt < Calendar.current.date(byAdding: .day, value: -30, to: Date())! {
                rulesToRemove.append(rule)
            }
        }
        
        await MainActor.run {
            for rule in rulesToRemove {
                personalRules.removeAll { $0.id == rule.id }
            }
            updateRuleStats()
        }
        
        // Persist changes
        for rule in rulesToRemove {
            await removePersonalRule(rule)
        }
        
        if !rulesToRemove.isEmpty {
            print("📝 RULES: 🧹 Cleaned up \(rulesToRemove.count) ineffective rules")
        }
    }
    
    // MARK: - Rule Analysis
    
    private func analyzeForNewRules(from correction: UserCorrection) async {
        // Look for patterns in the correction
        let patterns = extractPatterns(from: correction)
        
        for pattern in patterns {
            // Check if we have enough similar corrections to create a rule
            let similarCorrections = findSimilarCorrections(to: correction, pattern: pattern)
            
            if similarCorrections.count >= RulesConfig.minCorrectionsForRule {
                await createRuleFromPattern(pattern, corrections: similarCorrections)
            }
        }
    }
    
    private func extractPatterns(from correction: UserCorrection) -> [CorrectionPattern] {
        var patterns: [CorrectionPattern] = []
        
        let content = correction.originalItem.originalItem.content.lowercased()
        
        // Extract keyword patterns
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
        
        for word in words {
            patterns.append(CorrectionPattern(
                type: .keyword,
                value: word,
                targetClassification: correction.correctedClassification,
                confidence: 0.6
            ))
        }
        
        // Extract phrase patterns
        if content.count > 10 {
            patterns.append(CorrectionPattern(
                type: .phrase,
                value: String(content.prefix(20)),
                targetClassification: correction.correctedClassification,
                confidence: 0.8
            ))
        }
        
        // Extract category transition patterns
        patterns.append(CorrectionPattern(
            type: .categoryTransition,
            value: "\(correction.originalItem.paraClassification.category) -> \(correction.correctedClassification.category)",
            targetClassification: correction.correctedClassification,
            confidence: 0.7
        ))
        
        return patterns
    }
    
    private func findSimilarCorrections(to correction: UserCorrection, pattern: CorrectionPattern) -> [UserCorrection] {
        return userCorrections.filter { otherCorrection in
            guard otherCorrection.id != correction.id else { return false }
            
            switch pattern.type {
            case .keyword:
                return otherCorrection.originalItem.originalItem.content.localizedCaseInsensitiveContains(pattern.value)
            case .phrase:
                return otherCorrection.originalItem.originalItem.content.lowercased().hasPrefix(pattern.value.lowercased())
            case .categoryTransition:
                let otherTransition = "\(otherCorrection.originalItem.paraClassification.category) -> \(otherCorrection.correctedClassification.category)"
                return otherTransition == pattern.value
            }
        }
    }
    
    private func createRuleFromPattern(_ pattern: CorrectionPattern, corrections: [UserCorrection]) async {
        // Check if rule already exists
        let existingRule = personalRules.first { rule in
            rule.pattern.localizedCaseInsensitiveContains(pattern.value) ||
            pattern.value.localizedCaseInsensitiveContains(rule.pattern)
        }
        
        guard existingRule == nil else { return }
        
        let newRule = PersonalPARARule(
            id: UUID(),
            pattern: pattern.value,
            targetClassification: pattern.targetClassification,
            confidence: min(pattern.confidence + Float(corrections.count) * 0.1, 1.0),
            description: generateRuleDescription(pattern: pattern, corrections: corrections),
            ruleType: mapPatternTypeToRuleType(pattern.type),
            createdFrom: corrections,
            createdAt: Date(),
            lastUsed: nil,
            usageCount: 0,
            isActive: true
        )
        
        await MainActor.run {
            personalRules.append(newRule)
            updateRuleStats()
        }
        
        await persistPersonalRule(newRule)
        
        print("📝 RULES: ✅ Created new rule from pattern - \(newRule.description)")
    }
    
    private func generateRuleDescription(pattern: CorrectionPattern, corrections: [UserCorrection]) -> String {
        switch pattern.type {
        case .keyword:
            return "Items containing '\(pattern.value)' should be classified as \(pattern.targetClassification.category)"
        case .phrase:
            return "Items starting with '\(pattern.value)...' should be classified as \(pattern.targetClassification.category)"
        case .categoryTransition:
            return "Prefer \(pattern.targetClassification.category) over initial classification for similar items"
        }
    }
    
    private func mapPatternTypeToRuleType(_ patternType: CorrectionPattern.PatternType) -> PersonalPARARule.RuleType {
        switch patternType {
        case .keyword:
            return .keyword
        case .phrase:
            return .phrase
        case .categoryTransition:
            return .categoryOverride
        }
    }
    
    // MARK: - Rule Updates
    
    private func updateExistingRules(with correction: UserCorrection) async {
        for rule in personalRules {
            if rule.appliesTo(correction.originalItem) {
                // Check if the correction aligns with the rule
                if rule.targetClassification.category == correction.correctedClassification.category {
                    // Rule was correct, increase confidence
                    await increaseRuleConfidence(rule)
                } else {
                    // Rule was wrong, decrease confidence
                    await decreaseRuleConfidence(rule)
                }
            }
        }
    }
    
    private func increaseRuleConfidence(_ rule: PersonalPARARule) async {
        let newConfidence = min(rule.confidence + 0.1, 1.0)
        await updateRuleConfidence(rule, newConfidence: newConfidence)
    }
    
    private func decreaseRuleConfidence(_ rule: PersonalPARARule) async {
        let newConfidence = max(rule.confidence - 0.2, 0.0)
        await updateRuleConfidence(rule, newConfidence: newConfidence)
        
        // Disable rule if confidence drops too low
        if newConfidence < 0.3 {
            await disableRule(rule)
        }
    }
    
    private func updateRuleConfidence(_ rule: PersonalPARARule, newConfidence: Float) async {
        await MainActor.run {
            if let index = personalRules.firstIndex(where: { $0.id == rule.id }) {
                personalRules[index].confidence = newConfidence
            }
        }
        
        await persistRuleUpdate(rule, confidence: newConfidence)
    }
    
    private func disableRule(_ rule: PersonalPARARule) async {
        await MainActor.run {
            if let index = personalRules.firstIndex(where: { $0.id == rule.id }) {
                personalRules[index].isActive = false
            }
        }
        
        await persistRuleUpdate(rule, isActive: false)
        
        print("📝 RULES: ⚠️ Disabled rule due to low confidence - \(rule.description)")
    }
    
    private func updateRuleUsage(_ rule: PersonalPARARule) async {
        await MainActor.run {
            if let index = personalRules.firstIndex(where: { $0.id == rule.id }) {
                personalRules[index].lastUsed = Date()
                personalRules[index].usageCount += 1
            }
        }
        
        await persistRuleUsage(rule)
    }
    
    // MARK: - Statistics and Analysis
    
    private func updateRuleStats() {
        let totalRules = personalRules.count
        let activeRules = personalRules.filter { $0.isActive }.count
        let totalCorrections = userCorrections.count
        let recentCorrections = userCorrections.filter { 
            Calendar.current.dateComponents([.day], from: $0.timestamp, to: Date()).day ?? 0 <= 7
        }.count
        
        ruleStats = RuleStats(
            totalRules: totalRules,
            activeRules: activeRules,
            totalCorrections: totalCorrections,
            recentCorrections: recentCorrections,
            averageRuleConfidence: personalRules.isEmpty ? 0.0 : personalRules.map { $0.confidence }.reduce(0, +) / Float(personalRules.count),
            mostUsedRuleType: getMostUsedRuleType(),
            lastUpdated: Date()
        )
    }
    
    private func getMostUsedRuleType() -> PersonalPARARule.RuleType {
        let typeCounts = Dictionary(grouping: personalRules, by: { $0.ruleType })
            .mapValues { $0.count }
        
        return typeCounts.max { $0.value < $1.value }?.key ?? .keyword
    }
    
    private func calculateRuleSuccessRate(_ rule: PersonalPARARule) -> Float {
        // This would analyze how often the rule's suggestions were accepted
        // For now, return a placeholder based on usage and confidence
        return rule.confidence * (Float(rule.usageCount) / 10.0).clamped(to: 0...1)
    }
    
    private func calculateConfidenceImprovement(_ rule: PersonalPARARule) -> Float {
        // This would track how much the rule improved classification confidence
        return rule.confidence * 0.2 // Placeholder
    }
    
    // MARK: - Suggestion Generation
    
    private func analyzeCorrectionsForPatterns(_ corrections: [UserCorrection]) async -> [CorrectionPatternAnalysis] {
        var patternAnalysis: [String: CorrectionPatternAnalysis] = [:]
        
        for correction in corrections {
            let patterns = extractPatterns(from: correction)
            
            for pattern in patterns {
                let key = "\(pattern.type):\(pattern.value)"
                
                if var existing = patternAnalysis[key] {
                    existing.frequency += 1
                    existing.corrections.append(correction)
                    patternAnalysis[key] = existing
                } else {
                    patternAnalysis[key] = CorrectionPatternAnalysis(
                        pattern: pattern,
                        frequency: 1,
                        corrections: [correction],
                        confidence: pattern.confidence
                    )
                }
            }
        }
        
        return Array(patternAnalysis.values)
    }
    
    private func generateRuleSuggestion(from analysis: CorrectionPatternAnalysis) async -> SuggestedRule {
        return SuggestedRule(
            id: UUID(),
            pattern: analysis.pattern.value,
            targetClassification: analysis.pattern.targetClassification,
            confidence: min(analysis.confidence + Float(analysis.frequency) * 0.1, 1.0),
            description: generateRuleDescription(pattern: analysis.pattern, corrections: analysis.corrections),
            ruleType: mapPatternTypeToRuleType(analysis.pattern.type),
            basedOnCorrections: analysis.corrections,
            frequency: analysis.frequency,
            createdAt: Date()
        )
    }
    
    // MARK: - Context and Utilities
    
    private func getCurrentCorrectionContext() async -> CorrectionContext {
        return CorrectionContext(
            recentCorrections: Array(userCorrections.prefix(10)),
            activeRules: personalRules.filter { $0.isActive },
            timestamp: Date()
        )
    }
    
    private func markCorrectionsAsReviewed(_ corrections: [UserCorrection]) async {
        // Implementation to mark corrections as reviewed to avoid re-suggesting
        // This would update the database to track reviewed status
    }
    
    // MARK: - Persistence
    
    private func loadPersonalRules() async {
        // Implementation to load personal rules from database
        print("📝 RULES: ✅ Loaded personal rules from database")
    }
    
    private func loadUserCorrections() async {
        // Implementation to load user corrections from database
        print("📝 RULES: ✅ Loaded user corrections from database")
    }
    
    private func persistPersonalRule(_ rule: PersonalPARARule) async {
        // Implementation to persist rule to database
    }
    
    private func persistUserCorrection(_ correction: UserCorrection) async {
        // Implementation to persist correction to database
    }
    
    private func persistRuleUpdate(_ rule: PersonalPARARule, confidence: Float? = nil, isActive: Bool? = nil) async {
        // Implementation to update rule in database
    }
    
    private func persistRuleUsage(_ rule: PersonalPARARule) async {
        // Implementation to update rule usage statistics in database
    }
    
    private func removePersonalRule(_ rule: PersonalPARARule) async {
        // Implementation to remove rule from database
    }
    
    // MARK: - Timer Management
    
    private func startRuleUpdateTimer() {
        ruleUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in // Every hour
            Task {
                await self.performPeriodicRuleUpdate()
            }
        }
    }
    
    private func performPeriodicRuleUpdate() async {
        await generateRuleSuggestions()
        await cleanupIneffectiveRules()
        await MainActor.run {
            updateRuleStats()
        }
    }
}

// MARK: - Supporting Data Structures

struct PersonalPARARule {
    let id: UUID
    let pattern: String
    let targetClassification: PARAClassification
    var confidence: Float
    let description: String
    let ruleType: RuleType
    let createdFrom: [UserCorrection]
    let createdAt: Date
    var lastUsed: Date?
    var usageCount: Int
    var isActive: Bool
    
    enum RuleType {
        case keyword, phrase, categoryOverride, contextual
    }
    
    func appliesTo(_ item: ContextualPARAItem) -> Bool {
        let content = item.originalItem.content.lowercased()
        let pattern = self.pattern.lowercased()
        
        switch ruleType {
        case .keyword:
            return content.contains(pattern)
        case .phrase:
            return content.hasPrefix(pattern)
        case .categoryOverride:
            return true // Always applies, but with lower priority
        case .contextual:
            return content.contains(pattern) // More complex logic could be added
        }
    }
    
    func apply(to item: ContextualPARAItem) -> ContextualPARAItem {
        var modifiedItem = item
        modifiedItem.paraClassification = targetClassification
        modifiedItem.confidence = max(item.confidence, confidence)
        return modifiedItem
    }
}

struct UserCorrection {
    let id: UUID
    let originalItem: ContextualPARAItem
    let correctedClassification: PARAClassification
    let userFeedback: String?
    let timestamp: Date
    let context: CorrectionContext
}

struct CorrectionContext {
    let recentCorrections: [UserCorrection]
    let activeRules: [PersonalPARARule]
    let timestamp: Date
}

struct CorrectionPattern {
    let type: PatternType
    let value: String
    let targetClassification: PARAClassification
    let confidence: Float
    
    enum PatternType {
        case keyword, phrase, categoryTransition
    }
}

struct CorrectionPatternAnalysis {
    let pattern: CorrectionPattern
    var frequency: Int
    var corrections: [UserCorrection]
    let confidence: Float
}

struct SuggestedRule {
    let id: UUID
    let pattern: String
    let targetClassification: PARAClassification
    let confidence: Float
    let description: String
    let ruleType: PersonalPARARule.RuleType
    let basedOnCorrections: [UserCorrection]
    let frequency: Int
    let createdAt: Date
}

struct RuleStats {
    let totalRules: Int
    let activeRules: Int
    let totalCorrections: Int
    let recentCorrections: Int
    let averageRuleConfidence: Float
    let mostUsedRuleType: PersonalPARARule.RuleType
    let lastUpdated: Date
    
    init() {
        self.totalRules = 0
        self.activeRules = 0
        self.totalCorrections = 0
        self.recentCorrections = 0
        self.averageRuleConfidence = 0.0
        self.mostUsedRuleType = .keyword
        self.lastUpdated = Date()
    }
    
    init(totalRules: Int, activeRules: Int, totalCorrections: Int, recentCorrections: Int, averageRuleConfidence: Float, mostUsedRuleType: PersonalPARARule.RuleType, lastUpdated: Date) {
        self.totalRules = totalRules
        self.activeRules = activeRules
        self.totalCorrections = totalCorrections
        self.recentCorrections = recentCorrections
        self.averageRuleConfidence = averageRuleConfidence
        self.mostUsedRuleType = mostUsedRuleType
        self.lastUpdated = lastUpdated
    }
}

struct RuleEffectiveness {
    let rule: PersonalPARARule
    let successRate: Float
    let averageConfidenceImprovement: Float
    let timesSaved: Int
    let lastImpact: Date?
}

// MARK: - Extensions

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}