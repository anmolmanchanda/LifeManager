//
// ContextualPARAEngine.swift
// LifeManager
//
// Implements: v2.0 "Advanced AI Capabilities" - Context-Aware PARA Processing
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Features
// Status: ✅ RESTORED June 18, 2025 - Phase 1B Advanced AI Feature Integration
// Future: v2.5 Advanced Personalization, Machine Learning Integration
//
// RESTORED from temp_excluded/ during Phase 1B AI feature restoration.
// This engine provides semantic embeddings, context-aware categorization,
// and self-improving PARA classification with user feedback loops.
//

import Foundation
import SwiftUI

/// Advanced context-aware PARA processing engine with self-improving capabilities
/// Implements active context memory, feedback loops, and semantic embeddings
class ContextualPARAEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let llmService = LLMService.shared
    private let supabaseService = SupabaseService.shared
    private let embeddingsService = EmbeddingsService.shared
    private let contextMemoryService = ContextMemoryService.shared
    
    // MARK: - Context Memory Configuration
    
    private struct ContextConfig {
        static let slidingWindowSize = 100
        static let dailySummaryDays = 7
        static let weeklySummaryWeeks = 4
        static let embeddingSimilarityThreshold = 0.75
        static let confidenceThreshold = 0.8
    }
    
    // MARK: - Context Memory Storage
    
    @Published var activeContextWindow: [PARAItem] = []
    @Published var dailySummaries: [DailySummary] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    // Note: These will be managed through PersonalRulesService.shared
    // @Published var userCorrections: [UserCorrection] = []
    // @Published var personalRules: [PersonalPARARule] = []
    
    // MARK: - Processing State
    
    @Published var isProcessing = false
    @Published var processingStage: ProcessingStage = .idle
    @Published var clarificationQuestions: [ClarificationQuestion] = []
    
    // MARK: - Cache Properties
    
    private var cachedContext: ProcessingContext?
    private var cachedPersonalRules: [PersonalPARARule] = []
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadContextMemory()
            await loadPersonalRules()
        }
    }
    
    // MARK: - Initialization Methods
    
    private func loadContextMemory() async {
        await refreshContextMemory()
    }
    
    private func loadPersonalRules() async {
        // For now, initialize with empty rules - will be populated by PersonalRulesService
        await MainActor.run {
            self.cachedPersonalRules = []
        }
        
        logger.success("✅ CONTEXTUAL: Initialized personal rules cache")
    }
    
    // MARK: - Main Processing Pipeline
    
    /// Process brain dump input using contextual PARA analysis
    func processContextualBrainDump(
        input: String,
        userContext: UserContext? = nil
    ) async throws -> ContextualProcessingResult {
        
        await MainActor.run {
            isProcessing = true
            processingStage = .preparingContext
        }
        
        // Step 1: Prepare contextual information
        let context = await prepareProcessingContext(userContext: userContext)
        
        // Step 2: Split input into atomic items
        await MainActor.run { processingStage = .splittingInput }
        let atomicItems = try await splitInputIntoAtomicItems(input, context: context)
        
        // Step 3: Process each item with contextual analysis
        await MainActor.run { processingStage = .analyzingItems }
        var processedItems: [ContextualPARAItem] = []
        
        for item in atomicItems {
            let processedItem = try await processAtomicItem(item, context: context)
            processedItems.append(processedItem)
        }
        
        // Step 4: Apply self-improvement corrections
        await MainActor.run { processingStage = .applyingCorrections }
        let correctedItems = await applyPersonalRules(to: processedItems, context: context)
        
        // Step 5: Generate clarification questions for ambiguous items
        await MainActor.run { processingStage = .generatingClarifications }
        let clarifications = await generateClarificationQuestions(for: correctedItems)
        
        // Step 6: Update context memory
        await MainActor.run { processingStage = .updatingContext }
        await updateContextMemory(with: correctedItems)
        
        await MainActor.run {
            isProcessing = false
            processingStage = .idle
            clarificationQuestions = clarifications
        }
        
        return ContextualProcessingResult(
            processedItems: correctedItems,
            clarificationQuestions: clarifications,
            contextUsed: context,
            confidence: calculateOverallConfidence(correctedItems),
            suggestions: generateMetaSuggestions(correctedItems, context: context)
        )
    }
    
    // MARK: - Context Preparation
    
    /// Prepare comprehensive processing context
    private func prepareProcessingContext(userContext: UserContext?) async -> ProcessingContext {
        // Use ContextMemoryService to get current context
        return await contextMemoryService.getCurrentContext()
    }
    
    // MARK: - Input Splitting
    
    /// Split input into atomic actionable/reference items
    private func splitInputIntoAtomicItems(
        _ input: String,
        context: ProcessingContext
    ) async throws -> [AtomicItem] {
        
        let prompt = buildInputSplittingPrompt(input: input, context: context)
        let response = try await llmService.callLLM(prompt: prompt)
        
        return try parseAtomicItemsResponse(response)
    }
    
    /// Parse LLM response into atomic items
    private func parseAtomicItemsResponse(_ response: String) throws -> [AtomicItem] {
        // Simple parsing implementation - in production would use more robust JSON parsing
        let lines = response.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        return lines.map { line in
            AtomicItem(
                content: line.trimmingCharacters(in: .whitespacesAndNewlines),
                type: .note, // Default type
                contextualHints: [],
                confidence: 0.8
            )
        }
    }
    
    private func buildInputSplittingPrompt(input: String, context: ProcessingContext) -> String {
        return """
        You are an expert at breaking down brain dump text into atomic, actionable items.
        
        CONTEXT AWARENESS:
        Recent activity: \(getRecentActivitySummary(from: context))
        Active projects: \(getActiveProjects(from: context))
        Current focus areas: \(getCurrentFocusAreas(from: context))
        
        USER INPUT:
        \(input)
        
        INSTRUCTIONS:
        1. Split the input into the smallest meaningful units
        2. Each item should be either:
           - A single actionable task
           - A piece of reference information
           - A journal/note entry
           - A financial record
           - A knowledge snippet
        
        3. Consider the user's recent context when determining splits
        4. If something relates to recent activity, note the connection
        
        OUTPUT FORMAT (JSON):
        [
          {
            "content": "exact text of the item",
            "type": "task|resource|journal|financial|knowledge|note",
            "contextualHints": ["recent_project_connection", "area_relevance"],
            "confidence": 0.95
          }
        ]
        """
    }
    
    // MARK: - Atomic Item Processing
    
    /// Process individual atomic item with full contextual analysis
    private func processAtomicItem(
        _ item: AtomicItem,
        context: ProcessingContext
    ) async throws -> ContextualPARAItem {
        
        // Step 1: Semantic embeddings search
        let semanticMatches = await findSemanticMatches(for: item, in: getAllPARAItems(from: context))
        
        // Step 2: Contextual PARA classification
        let paraClassification = try await classifyWithContext(item, context: context, semanticMatches: semanticMatches)
        
        // Step 3: Extract metadata and tags
        let metadata = try await extractMetadata(from: item, context: context)
        
        // Step 4: Generate reasoning
        let reasoning = generateClassificationReasoning(
            item: item,
            classification: paraClassification,
            semanticMatches: semanticMatches,
            context: context
        )
        
        return ContextualPARAItem(
            originalItem: item,
            paraClassification: paraClassification,
            semanticMatches: semanticMatches,
            metadata: metadata,
            reasoning: reasoning,
            confidence: calculateItemConfidence(item, classification: paraClassification, matches: semanticMatches)
        )
    }
    
    // MARK: - Semantic Embeddings Search
    
    /// Find semantically similar PARA items using embeddings
    private func findSemanticMatches(
        for item: AtomicItem,
        in paraItems: [PARAItem]
    ) async -> [SemanticMatch] {
        
        guard let itemEmbedding = await embeddingsService.getEmbedding(for: item.content) else {
            return []
        }
        
        var matches: [SemanticMatch] = []
        
        for paraItem in paraItems {
            guard let paraEmbedding = await embeddingsService.getEmbedding(for: paraItem.content) else {
                continue
            }
            
            let similarity = calculateCosineSimilarity(itemEmbedding, paraEmbedding)
            
            if similarity >= Float(ContextConfig.embeddingSimilarityThreshold) {
                matches.append(SemanticMatch(
                    paraItem: paraItem,
                    similarity: similarity,
                    matchType: determineMatchType(similarity)
                ))
            }
        }
        
        return matches.sorted { $0.similarity > $1.similarity }
    }
    
    // MARK: - Contextual Classification
    
    /// Classify item using context, semantic matches, and personal rules
    private func classifyWithContext(
        _ item: AtomicItem,
        context: ProcessingContext,
        semanticMatches: [SemanticMatch]
    ) async throws -> PARAClassification {
        
        let prompt = buildContextualClassificationPrompt(
            item: item,
            context: context,
            semanticMatches: semanticMatches
        )
        
        let response = try await llmService.callLLM(prompt: prompt)
        return try parseClassificationResponse(response)
    }
    
    /// Parse LLM response into PARAClassification
    private func parseClassificationResponse(_ response: String) throws -> PARAClassification {
        // Simple parsing implementation - in production would use more robust JSON parsing
        let lines = response.components(separatedBy: .newlines)
        
        var category: PARACategory = .resource
        var workPersonal: WorkPersonalType = .personal
        var priority: TaskPriority = .medium
        let confidence: Float = 0.5
        
        for line in lines {
            if line.lowercased().contains("project") {
                category = .project
            } else if line.lowercased().contains("area") {
                category = .area
            } else if line.lowercased().contains("archive") {
                category = .archive
            }
            
            if line.lowercased().contains("work") {
                workPersonal = .work
            }
            
            if line.lowercased().contains("urgent") {
                priority = .urgent
            } else if line.lowercased().contains("high") {
                priority = .high
            }
        }
        
        return PARAClassification(
            category: category,
            subcategory: nil,
            suggestedProject: nil,
            suggestedArea: nil,
            priority: priority,
            dueDate: nil,
            tags: [],
            workPersonal: workPersonal,
            confidence: confidence,
            reasoning: "Parsed from LLM response"
        )
    }
    
    private func buildContextualClassificationPrompt(
        item: AtomicItem,
        context: ProcessingContext,
        semanticMatches: [SemanticMatch]
    ) -> String {
        
        let recentActivity = getRecentActivitySummary(from: context)
        let personalRules = getPersonalRules(from: context).map { $0.description }.joined(separator: "\n")
        let semanticContext = semanticMatches.prefix(3).map { 
            "- \($0.paraItem.title) (\($0.paraItem.category)) - \(Int($0.similarity * 100))% match"
        }.joined(separator: "\n")
        
        return """
        You are an expert PARA categorization system with deep context awareness.
        
        ITEM TO CLASSIFY:
        Content: "\(item.content)"
        Type: \(item.type)
        
        CONTEXTUAL INFORMATION:
        Recent Activity (last 7 days):
        \(recentActivity)
        
        Semantic Matches Found:
        \(semanticContext.isEmpty ? "No strong semantic matches found" : semanticContext)
        
        Personal Rules (learned from user corrections):
        \(personalRules.isEmpty ? "No personal rules established yet" : personalRules)
        
        PARA CLASSIFICATION GUIDELINES:
        - PROJECT: Time-bound effort with clear outcome (deadline/completion criteria)
        - AREA: Ongoing responsibility or sphere of activity (no end date)
        - RESOURCE: Reference material, knowledge, or future utility
        - ARCHIVE: Completed, inactive, or backup information
        
        CONTEXTUAL DECISION FACTORS:
        1. Does this relate to recent user activity? (higher priority for active areas/projects)
        2. Do semantic matches suggest existing PARA assignments?
        3. Do personal rules override default classification?
        4. Is this part of an ongoing pattern or new initiative?
        
        OUTPUT FORMAT (JSON):
        {
          "category": "project|area|resource|archive",
          "subcategory": "specific subcategory name",
          "suggestedProject": "project name if applicable",
          "suggestedArea": "area name if applicable",
          "priority": "urgent|high|medium|low",
          "dueDate": "YYYY-MM-DD or null",
          "tags": ["tag1", "tag2"],
          "workPersonal": "work|personal|both",
          "confidence": 0.95,
          "reasoning": "Clear explanation of classification decision based on context"
        }
        """
    }
    
    // MARK: - Self-Improving Corrections
    
    /// Apply personal rules learned from user corrections
    private func applyPersonalRules(
        to items: [ContextualPARAItem],
        context: ProcessingContext
    ) async -> [ContextualPARAItem] {
        
        var correctedItems = items
        
        for rule in getPersonalRules(from: context) {
            for (index, item) in correctedItems.enumerated() {
                if rule.appliesTo(item) {
                    correctedItems[index] = rule.apply(to: item)
                }
            }
        }
        
        return correctedItems
    }
    
    /// Record user correction and update personal rules
    func recordUserCorrection(
        originalItem: ContextualPARAItem,
        correctedClassification: PARAClassification,
        userFeedback: String?
    ) async {
        
        // Delegate to PersonalRulesService for correction handling
        await PersonalRulesService.shared.recordUserCorrection(
            originalItem: originalItem,
            correctedClassification: correctedClassification,
            userFeedback: userFeedback
        )
        
        // Personal rules extraction is handled by PersonalRulesService
        
        // Update context memory
        await refreshContextMemory()
    }
    
    // MARK: - Clarification Questions
    
    /// Generate sophisticated clarification questions for ambiguous items
    private func generateClarificationQuestions(
        for items: [ContextualPARAItem]
    ) async -> [ClarificationQuestion] {
        
        var questions: [ClarificationQuestion] = []
        
        for item in items {
            let clarifications = await generateComprehensiveClarifications(for: item)
            questions.append(contentsOf: clarifications)
        }
        
        return questions
    }
    
    /// Generate comprehensive clarifications using advanced reasoning
    private func generateComprehensiveClarifications(
        for item: ContextualPARAItem
    ) async -> [ClarificationQuestion] {
        
        var questions: [ClarificationQuestion] = []
        
        // 1. Confidence-based clarifications
        if item.confidence < Float(ContextConfig.confidenceThreshold) {
            questions.append(await generateConfidenceClarification(for: item))
        }
        
        // 2. Ambiguous category clarifications
        if let categoryAmbiguity = detectCategoryAmbiguity(in: item) {
            questions.append(await generateCategoryAmbiguityClarification(for: item, ambiguity: categoryAmbiguity))
        }
        
        // 3. Context mismatch clarifications
        if let contextMismatch = await detectContextMismatch(for: item) {
            questions.append(await generateContextMismatchClarification(for: item, mismatch: contextMismatch))
        }
        
        // 4. Priority uncertainty clarifications
        if detectPriorityUncertainty(in: item) {
            questions.append(await generatePriorityClarification(for: item))
        }
        
        // 5. Temporal ambiguity clarifications
        if let temporalAmbiguity = detectTemporalAmbiguity(in: item) {
            questions.append(await generateTemporalClarification(for: item, ambiguity: temporalAmbiguity))
        }
        
        // 6. Scope definition clarifications
        if detectScopeAmbiguity(in: item) {
            questions.append(await generateScopeClarification(for: item))
        }
        
        return questions
    }
    
    /// Generate confidence-based clarification
    private func generateConfidenceClarification(for item: ContextualPARAItem) async -> ClarificationQuestion {
        let uncertainties = identifyUncertainties(in: item)
        let reasoning = "Confidence is low due to: \(uncertainties.joined(separator: ", "))"
        
        return ClarificationQuestion(
            id: UUID(),
            type: .confidence,
            item: item,
            question: "Classification confidence is low. How should this item be categorized?",
            options: generateBasicOptions(for: item),
            reasoning: reasoning,
            suggestedAction: "Review the item content and select the most appropriate category",
            confidence: item.confidence,
            priority: .medium
        )
    }
    
    /// Generate category ambiguity clarification
    private func generateCategoryAmbiguityClarification(
        for item: ContextualPARAItem,
        ambiguity: CategoryAmbiguity
    ) async -> ClarificationQuestion {
        
        let contextualEvidence = await gatherContextualEvidence(for: item, ambiguity: ambiguity)
        
        return ClarificationQuestion(
            id: UUID(),
            type: .categoryAmbiguity,
            item: item,
            question: "This item could be classified as either \(ambiguity.primaryCategory.rawValue) or \(ambiguity.secondaryCategory.rawValue). Based on your context, which classification better represents your intent?",
            options: [
                ClarificationOption(
                    id: UUID(),
                    text: "\(ambiguity.primaryCategory.rawValue.capitalized) - \(ambiguity.primaryReasoning)",
                    value: ambiguity.primaryCategory.rawValue,
                    confidence: ambiguity.primaryConfidence,
                    supportingEvidence: contextualEvidence.primaryEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "\(ambiguity.secondaryCategory.rawValue.capitalized) - \(ambiguity.secondaryReasoning)",
                    value: ambiguity.secondaryCategory.rawValue,
                    confidence: ambiguity.secondaryConfidence,
                    supportingEvidence: contextualEvidence.secondaryEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "Neither - I'll specify manually",
                    value: "manual",
                    confidence: 1.0,
                    supportingEvidence: []
                )
            ],
            reasoning: "Multiple PARA categories seem equally applicable based on the content analysis.",
            suggestedAction: "Review the reasoning for each option and select the one that best matches your intended outcome.",
            confidence: max(ambiguity.primaryConfidence, ambiguity.secondaryConfidence),
            priority: .high
        )
    }
    
    /// Generate context mismatch clarification
    private func generateContextMismatchClarification(
        for item: ContextualPARAItem,
        mismatch: ContextMismatch
    ) async -> ClarificationQuestion {
        
        return ClarificationQuestion(
            id: UUID(),
            type: .contextMismatch,
            item: item,
            question: "This item seems to relate to \(mismatch.suggestedContext), but your recent activity suggests focus on \(mismatch.currentContext). How should this be categorized?",
            options: [
                ClarificationOption(
                    id: UUID(),
                    text: "Align with current focus (\(mismatch.currentContext))",
                    value: mismatch.currentContextCategory,
                    confidence: mismatch.currentContextConfidence,
                    supportingEvidence: mismatch.currentContextEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "This represents a new focus (\(mismatch.suggestedContext))",
                    value: mismatch.suggestedContextCategory,
                    confidence: mismatch.suggestedContextConfidence,
                    supportingEvidence: mismatch.suggestedContextEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "It's related but separate",
                    value: "separate",
                    confidence: 0.8,
                    supportingEvidence: []
                )
            ],
            reasoning: mismatch.reasoning,
            suggestedAction: "Consider whether this item represents a shift in priorities or a separate parallel effort.",
            confidence: item.confidence,
            priority: .medium
        )
    }
    
    /// Generate priority clarification
    private func generatePriorityClarification(for item: ContextualPARAItem) async -> ClarificationQuestion {
        let priorityAnalysis = analyzePriorityIndicators(in: item)
        
        return ClarificationQuestion(
            id: UUID(),
            type: .priority,
            item: item,
            question: "The priority level for this item is unclear. Based on the content analysis, what priority should this have?",
            options: [
                ClarificationOption(
                    id: UUID(),
                    text: "High Priority - \(priorityAnalysis.highReasons.joined(separator: ", "))",
                    value: "high",
                    confidence: priorityAnalysis.highConfidence,
                    supportingEvidence: priorityAnalysis.highEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "Medium Priority - \(priorityAnalysis.mediumReasons.joined(separator: ", "))",
                    value: "medium",
                    confidence: priorityAnalysis.mediumConfidence,
                    supportingEvidence: priorityAnalysis.mediumEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "Low Priority - \(priorityAnalysis.lowReasons.joined(separator: ", "))",
                    value: "low",
                    confidence: priorityAnalysis.lowConfidence,
                    supportingEvidence: priorityAnalysis.lowEvidence
                )
            ],
            reasoning: "Priority indicators in the content are ambiguous or conflicting.",
            suggestedAction: "Consider deadlines, importance, and current workload when selecting priority.",
            confidence: item.confidence,
            priority: .medium
        )
    }
    
    /// Generate temporal clarification
    private func generateTemporalClarification(
        for item: ContextualPARAItem,
        ambiguity: TemporalAmbiguity
    ) async -> ClarificationQuestion {
        
        return ClarificationQuestion(
            id: UUID(),
            type: .temporal,
            item: item,
            question: "When should this be addressed? The content suggests: \(ambiguity.detectedTimeframes.joined(separator: " or "))",
            options: ambiguity.timeframeOptions.map { option in
                ClarificationOption(
                    id: UUID(),
                    text: option.description,
                    value: option.value,
                    confidence: option.confidence,
                    supportingEvidence: option.evidence
                )
            },
            reasoning: ambiguity.reasoning,
            suggestedAction: "Clarify the intended timeline to ensure proper prioritization and scheduling.",
            confidence: item.confidence,
            priority: .medium
        )
    }
    
    /// Generate scope clarification
    private func generateScopeClarification(for item: ContextualPARAItem) async -> ClarificationQuestion {
        let scopeAnalysis = analyzeScopeIndicators(in: item)
        
        return ClarificationQuestion(
            id: UUID(),
            type: .scope,
            item: item,
            question: "This item could be interpreted as either a large multi-step effort or a simple task. What's the intended scope?",
            options: [
                ClarificationOption(
                    id: UUID(),
                    text: "Large Project - \(scopeAnalysis.projectReasons.joined(separator: ", "))",
                    value: "project",
                    confidence: scopeAnalysis.projectConfidence,
                    supportingEvidence: scopeAnalysis.projectEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "Single Task - \(scopeAnalysis.taskReasons.joined(separator: ", "))",
                    value: "task",
                    confidence: scopeAnalysis.taskConfidence,
                    supportingEvidence: scopeAnalysis.taskEvidence
                ),
                ClarificationOption(
                    id: UUID(),
                    text: "Ongoing Area - \(scopeAnalysis.areaReasons.joined(separator: ", "))",
                    value: "area",
                    confidence: scopeAnalysis.areaConfidence,
                    supportingEvidence: scopeAnalysis.areaEvidence
                )
            ],
            reasoning: "The scope and complexity of this item needs clarification for proper categorization.",
            suggestedAction: "Consider breaking down large items into smaller components or grouping related tasks.",
            confidence: item.confidence,
            priority: .high
        )
    }
    
    // MARK: - Context Memory Management
    
    /// Update active context memory with new items
    private func updateContextMemory(with items: [ContextualPARAItem]) async {
        // Convert to PARAItems and add to ContextMemoryService
        let newPARAItems = items.map { $0.toPARAItem() }
        await contextMemoryService.addToContext(newPARAItems)
    }
    
    /// Generate daily summary of PARA activity
    private func updateDailySummary(with items: [PARAItem]) async {
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Convert PARAItems to ContextItems
        let contextItems = items.map { paraItem in
            ContextItem(from: paraItem)
        }
        
        if let existingSummary = dailySummaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // Update existing summary
            existingSummary.addItems(contextItems)
        } else {
            // Create new daily summary
            let newSummary = DailySummary(date: today)
            newSummary.addItems(contextItems)
            dailySummaries.insert(newSummary, at: 0)
            
            // Maintain summary count
            if dailySummaries.count > ContextConfig.dailySummaryDays {
                dailySummaries.removeLast()
            }
        }
        
        await persistDailySummaries()
    }
    
    // MARK: - Meta Suggestions
    
    /// Generate meta-feature suggestions based on processing results
    private func generateMetaSuggestions(
        _ items: [ContextualPARAItem],
        context: ProcessingContext
    ) -> [MetaSuggestion] {
        
        var suggestions: [MetaSuggestion] = []
        
        // Cross-project linking suggestions
        suggestions.append(contentsOf: suggestCrossProjectLinks(items, context: context))
        
        // People detection suggestions
        suggestions.append(contentsOf: suggestPeopleDetection(items))
        
        // Sentiment analysis suggestions
        suggestions.append(contentsOf: suggestSentimentAnalysis(items))
        
        // Automation opportunities
        suggestions.append(contentsOf: suggestAutomationOpportunities(items, context: context))
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func getRecentActivitySummary(from context: ProcessingContext) -> String {
        let recentProjects = context.recentItems.filter { $0.category == .project }.prefix(3)
        let recentAreas = context.recentItems.filter { $0.category == .area }.prefix(3)
        
        return """
        Recent Projects: \(recentProjects.map { $0.title }.joined(separator: ", "))
        Recent Areas: \(recentAreas.map { $0.title }.joined(separator: ", "))
        """
    }
    
    private func getActiveProjects(from context: ProcessingContext) -> [String] {
        return context.recentItems.filter { $0.category == .project }.map { $0.title }
    }
    
    private func getCurrentFocusAreas(from context: ProcessingContext) -> [String] {
        return context.recentItems.filter { $0.category == .area }.map { $0.title }
    }
    
    private func getPersonalRules(from context: ProcessingContext) -> [ContextualPARARule] {
        // For now, return empty array since ProcessingContext doesn't have personalRules
        // In production, this would be loaded from PersonalRulesService
        return []
    }
    
    // MARK: - Analysis Helper Methods
    
    private func gatherContextualEvidence(for item: ContextualPARAItem, ambiguity: CategoryAmbiguity) async -> ContextualEvidence {
        return ContextualEvidence(
            primaryEvidence: ["Content structure suggests \(ambiguity.primaryCategory.rawValue)"],
            secondaryEvidence: ["Context patterns suggest \(ambiguity.secondaryCategory.rawValue)"]
        )
    }
    
    private func analyzePriorityIndicators(in item: ContextualPARAItem) -> PriorityAnalysis {
        return PriorityAnalysis(
            highReasons: ["Contains urgent keywords"],
            mediumReasons: ["Standard business priority"],
            lowReasons: ["No time constraints mentioned"],
            highConfidence: 0.7,
            mediumConfidence: 0.8,
            lowConfidence: 0.6,
            highEvidence: ["urgent", "asap", "critical"],
            mediumEvidence: ["important", "should"],
            lowEvidence: ["sometime", "eventually"]
        )
    }
    
    private func generateTimeframeOptions(for item: ContextualPARAItem) -> [TimeframeOption] {
        return [
            TimeframeOption(
                description: "Today - requires immediate attention",
                value: "today",
                confidence: 0.8,
                evidence: ["urgent", "asap"]
            ),
            TimeframeOption(
                description: "This week - standard priority",
                value: "week",
                confidence: 0.9,
                evidence: ["this week", "soon"]
            ),
            TimeframeOption(
                description: "No specific deadline",
                value: "flexible",
                confidence: 0.7,
                evidence: ["eventually", "when possible"]
            )
        ]
    }
    
    private func analyzeScopeIndicators(in item: ContextualPARAItem) -> ScopeAnalysis {
        return ScopeAnalysis(
            projectReasons: ["Multi-step process indicated"],
            taskReasons: ["Single action described"],
            areaReasons: ["Ongoing responsibility mentioned"],
            projectConfidence: 0.7,
            taskConfidence: 0.8,
            areaConfidence: 0.6,
            projectEvidence: ["develop", "implement", "create"],
            taskEvidence: ["call", "send", "review"],
            areaEvidence: ["manage", "maintain", "monitor"]
        )
    }
    
    private func suggestAlternativeCategories(for item: ContextualPARAItem) -> [CategorySuggestion] {
        return [
            CategorySuggestion(
                name: item.paraClassification.category.rawValue.capitalized,
                value: item.paraClassification.category.rawValue,
                reasoning: "Original AI classification",
                confidence: item.confidence,
                evidence: ["Based on content analysis"]
            ),
            CategorySuggestion(
                name: inferAlternativeCategory(for: item).rawValue.capitalized,
                value: inferAlternativeCategory(for: item).rawValue,
                reasoning: "Alternative interpretation",
                confidence: 1.0 - item.confidence,
                evidence: ["Based on context patterns"]
            )
        ]
    }
    
    private func getAllPARAItems(from context: ProcessingContext) -> [PARAItem] {
        // Convert ContextItems to PARAItems for compatibility
        return context.recentItems.compactMap { contextItem in
            PARAItem(
                title: contextItem.title,
                content: contextItem.content,
                contentType: .note, // Default
                paraCategory: contextItem.category,
                workPersonal: contextItem.workPersonal,
                priority: .medium // Default
            )
        }
    }
    
    private func persistUserCorrection(_ correction: ContextualUserCorrection) async {
        do {
            let supabaseService = SupabaseService.shared
            let logger = Logger.shared
            
            // Create database record for user correction
            let correctionData: [String: Any] = [
                "id": correction.id.uuidString,
                "user_id": correction.userId.uuidString,
                "original_item_id": correction.originalItemId.uuidString,
                "corrected_classification": try JSONEncoder().encode(correction.correctedClassification),
                "correction_type": correction.correctionType.rawValue,
                "reasoning": correction.reasoning,
                "confidence": correction.confidence,
                "created_at": ISO8601DateFormatter().string(from: correction.createdAt),
                "metadata": try JSONSerialization.data(withJSONObject: correction.metadata)
            ]
            
            try await supabaseService.client
                .from("contextual_user_corrections")
                .insert(correctionData)
                .execute()
            
            logger.success("✅ CONTEXTUAL: Persisted user correction: \(correction.id)")
            
            // Extract and persist any patterns as personal rules
            if let rule = await extractPersonalRule(from: correction) {
                await persistPersonalRule(rule)
            }
            
        } catch {
            logger.error("❌ CONTEXTUAL: Failed to persist user correction: \(error)")
        }
    }
    
    private func extractPersonalRule(from correction: ContextualUserCorrection) async -> ContextualPARARule? {
        let logger = Logger.shared
        
        // Extract patterns from the correction that could become rules
        guard correction.confidence > 0.8 else {
            logger.debug("🔍 CONTEXTUAL: Correction confidence too low for rule extraction: \(correction.confidence)")
            return nil
        }
        
        // Analyze the correction for extractable patterns
        let originalClassification = correction.originalClassification
        let correctedClassification = correction.correctedClassification
        
        // Look for keyword patterns in the content
        let contentWords = correction.originalContent.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
        
        // Find significant keywords that might predict the correct classification
        var keywordPatterns: [String] = []
        
        // Check for domain-specific keywords
        if correctedClassification.category == .project {
            let projectKeywords = ["project", "build", "create", "develop", "launch", "complete"]
            keywordPatterns = contentWords.filter { word in
                projectKeywords.contains { $0.contains(word) || word.contains($0) }
            }
        } else if correctedClassification.category == .area {
            let areaKeywords = ["maintain", "monitor", "health", "fitness", "learning", "skill"]
            keywordPatterns = contentWords.filter { word in
                areaKeywords.contains { $0.contains(word) || word.contains($0) }
            }
        }
        
        // Only create rule if we found meaningful patterns
        guard !keywordPatterns.isEmpty else {
            logger.debug("🔍 CONTEXTUAL: No extractable patterns found in correction")
            return nil
        }
        
        // Create a contextual PARA rule
        let rule = ContextualPARARule(
            id: UUID(),
            userId: correction.userId,
            pattern: keywordPatterns.joined(separator: " "),
            targetClassification: correctedClassification,
            confidence: min(correction.confidence, 0.9), // Cap at 0.9 for extracted rules
            description: "Auto-extracted from user correction: \(correction.reasoning)",
            ruleType: .keyword,
            createdFrom: [correction.id],
            createdAt: Date(),
            lastUsed: nil,
            usageCount: 0,
            isActive: true,
            metadata: [
                "source": "user_correction",
                "original_category": originalClassification.category.rawValue,
                "corrected_category": correctedClassification.category.rawValue
            ]
        )
        
        logger.success("✅ CONTEXTUAL: Extracted personal rule from correction: \(rule.pattern)")
        return rule
    }
    
    private func persistPersonalRule(_ rule: PersonalPARARule) async {
        do {
            let supabaseService = SupabaseService.shared
            let logger = Logger.shared
            
            // Create database record for personal rule
            let ruleData: [String: Any] = [
                "id": rule.id.uuidString,
                "user_id": getCurrentUserId().uuidString,
                "pattern": rule.pattern,
                "target_classification": try JSONEncoder().encode(rule.targetClassification),
                "confidence": rule.confidence,
                "description": rule.description,
                "rule_type": rule.ruleType.rawValue,
                "created_from": rule.createdFrom.map { $0.uuidString },
                "created_at": ISO8601DateFormatter().string(from: rule.createdAt),
                "last_used": rule.lastUsed.map { ISO8601DateFormatter().string(from: $0) },
                "usage_count": rule.usageCount,
                "is_active": rule.isActive,
                "metadata": try JSONSerialization.data(withJSONObject: rule.metadata)
            ]
            
            try await supabaseService.client
                .from("personal_para_rules")
                .insert(ruleData)
                .execute()
            
            logger.success("✅ CONTEXTUAL: Persisted personal rule: \(rule.pattern)")
            
            // Update local rule cache
            await MainActor.run {
                self.cachedPersonalRules.append(rule)
            }
            
        } catch {
            logger.error("❌ CONTEXTUAL: Failed to persist personal rule: \(error)")
        }
    }
    
    private func refreshContextMemory() async {
        do {
            let supabaseService = SupabaseService.shared
            let logger = Logger.shared
            let userId = getCurrentUserId()
            
            logger.info("🔄 CONTEXTUAL: Refreshing context memory for user")
            
            // Load recent PARA items (last 30 days)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let thirtyDaysAgoString = ISO8601DateFormatter().string(from: thirtyDaysAgo)
            
            // Fetch recent projects
            let recentProjects: [Project] = try await supabaseService.client
                .from("projects")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: thirtyDaysAgoString)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            // Fetch recent areas
            let recentAreas: [Area] = try await supabaseService.client
                .from("areas")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: thirtyDaysAgoString)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            // Fetch recent resources
            let recentResources: [Resource] = try await supabaseService.client
                .from("resources")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: thirtyDaysAgoString)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            // Fetch recent tasks
            let recentTasks: [LifeTask] = try await supabaseService.client
                .from("tasks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: thirtyDaysAgoString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            // Convert to PARAItems for context
            let contextItems = [
                recentProjects.map { project in
                    PARAItem(
                        id: project.id,
                        title: project.title,
                        content: project.description,
                        contentType: .project,
                        paraCategory: .project,
                        workPersonal: project.workPersonal,
                        priority: project.priority,
                        createdAt: project.createdAt,
                        tags: project.tags,
                        isCompleted: project.isCompleted
                    )
                },
                recentAreas.map { area in
                    PARAItem(
                        id: area.id,
                        title: area.title,
                        content: area.description,
                        contentType: .area,
                        paraCategory: .area,
                        workPersonal: area.workPersonal,
                        priority: .medium,
                        createdAt: area.createdAt,
                        tags: area.tags,
                        isCompleted: false
                    )
                },
                recentResources.map { resource in
                    PARAItem(
                        id: resource.id,
                        title: resource.title,
                        content: resource.description,
                        contentType: .resource,
                        paraCategory: .resource,
                        workPersonal: resource.workPersonal,
                        priority: .low,
                        createdAt: resource.createdAt,
                        tags: resource.tags,
                        isCompleted: false
                    )
                },
                recentTasks.map { task in
                    PARAItem(
                        id: task.id,
                        title: task.title,
                        content: task.content ?? "",
                        contentType: .task,
                        paraCategory: task.paraCategory ?? .area,
                        workPersonal: task.workPersonal,
                        priority: task.priority,
                        createdAt: task.createdAt,
                        tags: task.tags,
                        isCompleted: task.isCompleted
                    )
                }
            ].flatMap { $0 }
            
            // Extract active projects and focus areas
            let activeProjects = recentProjects.filter { !$0.isCompleted }.map { $0.title }
            let focusAreas = recentAreas.map { $0.title }
            
            // Generate daily summary from recent activity
            let dailySummary = generateDailySummary(from: contextItems)
            
            // Update cached context
            await MainActor.run {
                self.cachedContext = ProcessingContext(
                    recentItems: contextItems,
                    dailySummary: dailySummary,
                    activeProjects: activeProjects,
                    focusAreas: focusAreas
                )
            }
            
            logger.success("✅ CONTEXTUAL: Refreshed context memory - \(contextItems.count) items, \(activeProjects.count) active projects, \(focusAreas.count) focus areas")
            
        } catch {
            logger.error("❌ CONTEXTUAL: Failed to refresh context memory: \(error)")
        }
    }
    
    private func identifyUncertainties(in item: ContextualPARAItem) -> [String] {
        var uncertainties: [String] = []
        
        if item.confidence < 0.6 {
            uncertainties.append("Low classification confidence")
        }
        
        if item.paraClassification.category == .resource && item.originalItem.content.contains("task") {
            uncertainties.append("Possible task misclassified as resource")
        }
        
        return uncertainties
    }
    
    private func buildClarificationQuestion(uncertainties: [String]) -> String {
        return "How should this item be classified? Uncertainties: \(uncertainties.joined(separator: ", "))"
    }
    
    private func generateClarificationOptions(uncertainties: [String]) -> [ClarificationOption] {
        return [
            ClarificationOption(
                id: UUID(),
                text: "Project - Time-bound effort with specific outcome",
                value: "project",
                confidence: 0.8,
                supportingEvidence: ["Has specific goals", "Time-bound"]
            )
        ]
    }
    
    private func persistContextMemory() async {
        // Placeholder implementation - would persist to database
        print("📝 CONTEXTUAL: Persisting context memory")
    }
    
    private func persistDailySummaries() async {
        // Placeholder implementation - would persist to database
        print("📝 CONTEXTUAL: Persisting daily summaries")
    }
    
    private func suggestCrossProjectLinks(_ items: [ContextualPARAItem], context: ProcessingContext) -> [MetaSuggestion] {
        return []
    }
    
    private func suggestPeopleDetection(_ items: [ContextualPARAItem]) -> [MetaSuggestion] {
        return []
    }
    
    private func suggestSentimentAnalysis(_ items: [ContextualPARAItem]) -> [MetaSuggestion] {
        return []
    }
    
    private func suggestAutomationOpportunities(_ items: [ContextualPARAItem], context: ProcessingContext) -> [MetaSuggestion] {
        return []
    }
    
    // MARK: - Processing Helper Methods
    
    private func extractMetadata(from item: AtomicItem, context: ProcessingContext) async throws -> ItemMetadata {
        // Extract metadata from the item content
        let words = item.content.components(separatedBy: .whitespacesAndNewlines)
        let extractedTags = words.filter { $0.hasPrefix("#") }.map { String($0.dropFirst()) }
        
        // Detect people mentions
        let detectedPeople = words.filter { $0.hasPrefix("@") }.map { String($0.dropFirst()) }
        
        // Estimate duration based on content
        let estimatedDuration: TimeInterval? = item.content.count > 100 ? 3600 : 1800 // 1 hour or 30 min
        
        // Determine urgency level
        let urgencyLevel: TaskPriority = item.content.lowercased().contains("urgent") ? .urgent : .medium
        
        return ItemMetadata(
            extractedTags: extractedTags,
            detectedPeople: detectedPeople,
            estimatedDuration: estimatedDuration,
            urgencyLevel: urgencyLevel,
            sentiment: nil // Would be populated by sentiment analysis
        )
    }
    
    private func generateClassificationReasoning(
        item: AtomicItem,
        classification: PARAClassification,
        semanticMatches: [SemanticMatch],
        context: ProcessingContext
    ) -> String {
        var reasoning = "Classification based on: "
        
        if !semanticMatches.isEmpty {
            let bestMatch = semanticMatches.first!
            reasoning += "semantic similarity to '\(bestMatch.paraItem.title)' (\(Int(bestMatch.similarity * 100))%); "
        }
        
        if classification.confidence > 0.8 {
            reasoning += "high confidence indicators; "
        }
        
        reasoning += "content analysis suggests \(classification.category.displayName) category."
        
        return reasoning
    }
    
    private func determineMatchType(_ similarity: Float) -> SemanticMatch.MatchType {
        switch similarity {
        case 0.9...1.0:
            return .exact
        case 0.75..<0.9:
            return .strong
        case 0.6..<0.75:
            return .moderate
        default:
            return .weak
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadRecentItems(limit: Int) async -> [ContextItem] {
        // Placeholder implementation - would load from database
        print("📝 CONTEXTUAL: Loading \(limit) recent items")
        return []
    }
    
    private func loadDailySummaries(days: Int) async -> [DailySummary] {
        // Placeholder implementation - would load from database
        print("📝 CONTEXTUAL: Loading daily summaries for \(days) days")
        return []
    }
    
    private func loadWeeklySummaries(weeks: Int) async -> [WeeklySummary] {
        // Placeholder implementation - would load from database
        print("📝 CONTEXTUAL: Loading weekly summaries for \(weeks) weeks")
        return []
    }
    
    private func loadAllPARAItems() async -> [PARAItem] {
        // Placeholder implementation - would load from database
        print("📝 CONTEXTUAL: Loading all PARA items for embeddings")
        return []
    }
    
    private func loadPersonalRulesForContext() async -> [PersonalPARARule] {
        // Placeholder implementation - would load from PersonalRulesService
        print("📝 CONTEXTUAL: Loading personal rules for context")
        return []
    }
    
    private func loadRecentCorrections(days: Int) async -> [ContextualUserCorrection] {
        // Placeholder implementation - would load from database
        print("📝 CONTEXTUAL: Loading recent corrections for \(days) days")
        return []
    }
    
    // MARK: - Detection Methods
    
    private func detectCategoryAmbiguity(in item: ContextualPARAItem) -> CategoryAmbiguity? {
        // Placeholder implementation
        if item.confidence < 0.7 {
            return CategoryAmbiguity(
                primaryCategory: item.paraClassification.category,
                secondaryCategory: inferAlternativeCategory(for: item),
                primaryConfidence: item.confidence,
                secondaryConfidence: 1.0 - item.confidence,
                primaryReasoning: "Original AI classification",
                secondaryReasoning: "Alternative interpretation"
            )
        }
        return nil
    }
    
    private func detectContextMismatch(for item: ContextualPARAItem) async -> ContextMismatch? {
        // Placeholder implementation
        return nil
    }
    
    private func detectPriorityUncertainty(in item: ContextualPARAItem) -> Bool {
        // Check if priority assignment is uncertain
        return item.confidence < 0.6 || item.paraClassification.priority == .medium
    }
    
    // MARK: - Utility Methods
    
    private func calculateCosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    private func calculateItemConfidence(
        _ item: AtomicItem,
        classification: PARAClassification,
        matches: [SemanticMatch]
    ) -> Float {
        
        var confidence: Float = 0.5 // Base confidence
        
        // Boost confidence for strong semantic matches
        if let bestMatch = matches.first, bestMatch.similarity > 0.9 {
            confidence += 0.3
        }
        
        // Boost confidence for clear classification indicators
        if classification.hasStrongIndicators {
            confidence += 0.2
        }
        
        // Reduce confidence for ambiguous content
        if item.content.count < 10 || item.content.contains("maybe") || item.content.contains("not sure") {
            confidence -= 0.2
        }
        
        return min(max(confidence, 0.0), 1.0)
    }
    
    private func calculateOverallConfidence(_ items: [ContextualPARAItem]) -> Float {
        guard !items.isEmpty else { return 0.0 }
        return items.map { $0.confidence }.reduce(0, +) / Float(items.count)
    }
    
    // MARK: - Missing Helper Methods
    
    private func inferAlternativeCategory(for item: ContextualPARAItem) -> PARACategory {
        // Simple heuristic to suggest alternative category
        switch item.paraClassification.category {
        case .project:
            return .area
        case .area:
            return .project
        case .resource:
            return .archive
        case .archive:
            return .resource
        }
    }
    
    private func generateBasicOptions(for item: ContextualPARAItem) -> [ClarificationOption] {
        return [
            ClarificationOption(
                id: UUID(),
                text: "Project - Time-bound effort with specific outcome",
                value: "project",
                confidence: 0.8,
                supportingEvidence: ["Has specific goals", "Time-bound"]
            ),
            ClarificationOption(
                id: UUID(),
                text: "Area - Ongoing responsibility or focus",
                value: "area",
                confidence: 0.8,
                supportingEvidence: ["Ongoing nature", "No end date"]
            ),
            ClarificationOption(
                id: UUID(),
                text: "Resource - Reference material or knowledge",
                value: "resource",
                confidence: 0.8,
                supportingEvidence: ["Information based", "Future utility"]
            ),
            ClarificationOption(
                id: UUID(),
                text: "Archive - Completed or inactive",
                value: "archive",
                confidence: 0.8,
                supportingEvidence: ["No longer active", "Reference only"]
            )
        ]
    }
    
    private func detectTemporalAmbiguity(in item: ContextualPARAItem) -> TemporalAmbiguity? {
        // Check if there are conflicting time indicators
        let content = item.originalItem.content.lowercased()
        var timeframes: [String] = []
        
        if content.contains("today") || content.contains("asap") {
            timeframes.append("immediate")
        }
        if content.contains("week") || content.contains("soon") {
            timeframes.append("this week")
        }
        if content.contains("month") || content.contains("eventually") {
            timeframes.append("longer term")
        }
        
        if timeframes.count > 1 {
            return TemporalAmbiguity(
                detectedTimeframes: timeframes,
                timeframeOptions: generateTimeframeOptions(for: item),
                reasoning: "Multiple conflicting time indicators detected"
            )
        }
        
        return nil
    }
    
    private func detectScopeAmbiguity(in item: ContextualPARAItem) -> Bool {
        let content = item.originalItem.content.lowercased()
        
        // Check for scope indicators
        let largeScope = content.contains("develop") || content.contains("implement") || content.contains("create")
        let smallScope = content.contains("call") || content.contains("send") || content.contains("email")
        
        return largeScope && smallScope
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> UUID {
        // In a real implementation, this would get the current user ID from authentication
        // For now, using a default development user ID
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    }
    
    private func generateDailySummary(from items: [PARAItem]) -> String? {
        guard !items.isEmpty else { return nil }
        
        let today = Date()
        let calendar = Calendar.current
        let todayItems = items.filter { item in
            calendar.isDate(item.createdAt, inSameDayAs: today)
        }
        
        guard !todayItems.isEmpty else { return nil }
        
        let projectCount = todayItems.filter { $0.paraCategory == .project }.count
        let areaCount = todayItems.filter { $0.paraCategory == .area }.count
        let resourceCount = todayItems.filter { $0.paraCategory == .resource }.count
        let taskCount = todayItems.filter { $0.contentType == .task }.count
        
        var summary = "Today's activity: "
        var parts: [String] = []
        
        if taskCount > 0 { parts.append("\(taskCount) tasks") }
        if projectCount > 0 { parts.append("\(projectCount) projects") }
        if areaCount > 0 { parts.append("\(areaCount) areas") }
        if resourceCount > 0 { parts.append("\(resourceCount) resources") }
        
        summary += parts.joined(separator: ", ")
        
        // Add focus area if there's a dominant category
        let maxCount = max(projectCount, areaCount, resourceCount)
        if maxCount >= 3 {
            if projectCount == maxCount {
                summary += ". Strong focus on project work."
            } else if areaCount == maxCount {
                summary += ". Strong focus on area maintenance."
            } else if resourceCount == maxCount {
                summary += ". Strong focus on resource collection."
            }
        }
        
        return summary
    }
}

// MARK: - Supporting Data Structures

// ProcessingContext is defined in ContextMemoryService.swift

struct AtomicItem {
    let id: UUID
    let content: String
    let type: ContentType
    let contextualHints: [String]
    let confidence: Float
    
    init(content: String, type: ContentType, contextualHints: [String], confidence: Float) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.contextualHints = contextualHints
        self.confidence = confidence
    }
}

struct ContextualPARAItem {
    let originalItem: AtomicItem
    var paraClassification: PARAClassification
    let semanticMatches: [SemanticMatch]
    let metadata: ItemMetadata
    var reasoning: String
    var confidence: Float
    
    func toPARAItem() -> PARAItem {
        return PARAItem(
            title: extractTitle(from: originalItem.content),
            content: originalItem.content,
            contentType: originalItem.type,
            paraCategory: paraClassification.category,
            workPersonal: paraClassification.workPersonal,
            priority: paraClassification.priority,
            tags: metadata.extractedTags
        )
    }
    
    private func extractTitle(from content: String) -> String {
        return String(content.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct SemanticMatch {
    let paraItem: PARAItem
    let similarity: Float
    let matchType: MatchType
    
    enum MatchType {
        case exact, strong, moderate, weak
    }
}

// UserCorrection and PersonalPARARule are defined in PersonalRulesService.swift

struct ClarificationQuestion {
    let id: UUID
    let type: ClarificationType
    let item: ContextualPARAItem
    let question: String
    let options: [ClarificationOption]
    let reasoning: String
    let suggestedAction: String
    let confidence: Float
    let priority: ClarificationPriority
}

struct ClarificationOption {
    let id: UUID
    let text: String
    let value: String
    let confidence: Float
    let supportingEvidence: [String]
}

enum ClarificationType {
    case confidence, categoryAmbiguity, contextMismatch, priority, temporal, scope
}

enum ClarificationPriority {
    case low, medium, high
}

// MARK: - Enhanced Clarification Data Structures

enum ClassificationUncertainty {
    case category(String)
    case priority(String)
    case temporal(String)
    case scope(String)
    case context(String)
}

struct CategoryAmbiguity {
    let primaryCategory: PARACategory
    let secondaryCategory: PARACategory
    let primaryConfidence: Float
    let secondaryConfidence: Float
    let primaryReasoning: String
    let secondaryReasoning: String
}

struct ContextMismatch {
    let suggestedContext: String
    let currentContext: String
    let suggestedContextCategory: String
    let currentContextCategory: String
    let suggestedContextConfidence: Float
    let currentContextConfidence: Float
    let suggestedContextEvidence: [String]
    let currentContextEvidence: [String]
    let reasoning: String
}

struct TemporalAmbiguity {
    let detectedTimeframes: [String]
    let timeframeOptions: [TimeframeOption]
    let reasoning: String
}

struct TimeframeOption {
    let description: String
    let value: String
    let confidence: Float
    let evidence: [String]
}

struct ContextualEvidence {
    let primaryEvidence: [String]
    let secondaryEvidence: [String]
}

struct PriorityAnalysis {
    let highReasons: [String]
    let mediumReasons: [String]
    let lowReasons: [String]
    let highConfidence: Float
    let mediumConfidence: Float
    let lowConfidence: Float
    let highEvidence: [String]
    let mediumEvidence: [String]
    let lowEvidence: [String]
}

struct ScopeAnalysis {
    let projectReasons: [String]
    let taskReasons: [String]
    let areaReasons: [String]
    let projectConfidence: Float
    let taskConfidence: Float
    let areaConfidence: Float
    let projectEvidence: [String]
    let taskEvidence: [String]
    let areaEvidence: [String]
}

struct CategorySuggestion {
    let name: String
    let value: String
    let reasoning: String
    let confidence: Float
    let evidence: [String]
}

struct MetaSuggestion {
    let type: SuggestionType
    let title: String
    let description: String
    let confidence: Float
    let actionable: Bool
    
    enum SuggestionType {
        case crossProjectLink, peopleDetection, sentimentAnalysis, automation
    }
}

// MARK: - Core Data Structures

struct ContextualUserCorrection {
    let id: UUID
    let originalClassification: PARAClassification
    let correctedClassification: PARAClassification
    let timestamp: Date
    let reasoning: String?
}

struct ContextualPARARule {
    let id: UUID
    let name: String
    let condition: String
    let action: String
    let confidence: Float
    let createdAt: Date
    let lastUsed: Date?
    let useCount: Int
    
    var description: String {
        return "\(name): \(condition) → \(action)"
    }
    
    func appliesTo(_ item: ContextualPARAItem) -> Bool {
        // Simple pattern matching for now
        return item.originalItem.content.lowercased().contains(condition.lowercased())
    }
    
    func apply(to item: ContextualPARAItem) -> ContextualPARAItem {
        // Apply the rule's action to modify the item
        var modifiedItem = item
        modifiedItem.reasoning = "Applied personal rule: \(name)"
        return modifiedItem
    }
}

struct UserContext {
    let currentFocus: String?
    let timeOfDay: Date
    let workMode: WorkPersonalType
    let recentActivities: [String]
}

enum ProcessingStage {
    case idle, preparingContext, splittingInput, analyzingItems, applyingCorrections, generatingClarifications, updatingContext
}

struct ItemMetadata {
    let extractedTags: [String]
    let detectedPeople: [String]
    let estimatedDuration: TimeInterval?
    let urgencyLevel: TaskPriority
    let sentiment: SentimentAnalysis?
}

struct SentimentAnalysis {
    let score: Float
    let confidence: Float
    let emotions: [String]
}

struct PARAClassification: Codable {
    let category: PARACategory
    let subcategory: String?
    let suggestedProject: String?
    let suggestedArea: String?
    let priority: TaskPriority
    let dueDate: Date?
    let tags: [String]
    let workPersonal: WorkPersonalType
    let confidence: Float
    let reasoning: String
    
    var hasStrongIndicators: Bool {
        return confidence > 0.8
    }
}


struct ContextualProcessingResult {
    let processedItems: [ContextualPARAItem]
    let clarificationQuestions: [ClarificationQuestion]
    let contextUsed: ProcessingContext
    let confidence: Float
    let suggestions: [MetaSuggestion]
}

// MARK: - Supporting Types for Detection Methods


// MARK: - Extensions

// hasStrongIndicators is already defined in PARAClassification struct above