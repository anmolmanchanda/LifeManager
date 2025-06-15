//
// ContextualPARAEngine.swift
// LifeManager
//
// Implements: v2.0 "Advanced AI Capabilities" - Context-Aware PARA Processing
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ⏳ IN PROGRESS as of June 14, 2025
// Future: v2.5 Advanced Personalization, Machine Learning Integration
//

import Foundation

/// Advanced context-aware PARA processing engine with self-improving capabilities
/// Implements active context memory, feedback loops, and semantic embeddings
class ContextualPARAEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let llmService = LLMService.shared
    private let supabaseService = SupabaseService.shared
    private let embeddingsService = EmbeddingsService.shared
    
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
    @Published var userCorrections: [UserCorrection] = []
    @Published var personalRules: [PersonalPARARule] = []
    
    // MARK: - Processing State
    
    @Published var isProcessing = false
    @Published var processingStage: ProcessingStage = .idle
    @Published var clarificationQuestions: [ClarificationQuestion] = []
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadContextMemory()
            await loadPersonalRules()
        }
    }
    
    // MARK: - Initialization Methods
    
    private func loadContextMemory() async {
        // Load context from database - placeholder implementation
        print("📝 CONTEXTUAL: Loading context memory from database")
        // In production, this would load from ContextMemoryService
    }
    
    private func loadPersonalRules() async {
        // Load personal rules from database - placeholder implementation
        print("📝 CONTEXTUAL: Loading personal rules from database")
        // In production, this would load from PersonalRulesService
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
        
        // Load active context window (last 100 items)
        let recentItems = await loadRecentItems(limit: ContextConfig.slidingWindowSize)
        
        // Load daily/weekly summaries
        let dailySummaries = await loadDailySummaries(days: ContextConfig.dailySummaryDays)
        let weeklySummaries = await loadWeeklySummaries(weeks: ContextConfig.weeklySummaryWeeks)
        
        // Load all PARA items for embeddings comparison
        let allPARAItems = await loadAllPARAItems()
        
        // Load personal rules and corrections
        let personalRules = await loadPersonalRulesForContext()
        let recentCorrections = await loadRecentCorrections(days: 30)
        
        return ProcessingContext(
            recentItems: recentItems,
            dailySummaries: dailySummaries,
            weeklySummaries: weeklySummaries,
            monthlySummaries: [], // Empty for now
            contextStats: ContextStats(
                totalItems: recentItems.count,
                averageConfidence: 0.8,
                topCategories: [],
                recentPatterns: []
            ),
            timestamp: Date()
        )
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
        var confidence: Float = 0.5
        
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
        
        let correction = UserCorrection(
            id: UUID(),
            originalItem: originalItem,
            correctedClassification: correctedClassification,
            userFeedback: userFeedback,
            timestamp: Date(),
            context: CorrectionContext(
                recentCorrections: [],
                activeRules: [],
                timestamp: Date()
            )
        )
        
        // Store correction
        userCorrections.append(correction)
        await persistUserCorrection(correction)
        
        // Extract and update personal rules
        let newRule = await extractPersonalRule(from: correction)
        if let rule = newRule {
            personalRules.append(rule)
            await persistPersonalRule(rule)
        }
        
        // Update context memory
        await refreshContextMemory()
    }
    
    // MARK: - Clarification Questions
    
    /// Generate clarification questions for ambiguous items
    private func generateClarificationQuestions(
        for items: [ContextualPARAItem]
    ) async -> [ClarificationQuestion] {
        
        var questions: [ClarificationQuestion] = []
        
        for item in items {
            if item.confidence < Float(ContextConfig.confidenceThreshold) {
                let question = await generateClarificationQuestion(for: item)
                questions.append(question)
            }
        }
        
        return questions
    }
    
    private func generateClarificationQuestion(for item: ContextualPARAItem) async -> ClarificationQuestion {
        
        let uncertainties = identifyUncertainties(in: item)
        
        return ClarificationQuestion(
            item: item,
            question: buildClarificationQuestion(uncertainties: uncertainties),
            options: generateClarificationOptions(uncertainties: uncertainties),
            reasoning: "Classification confidence below threshold (\(item.confidence))"
        )
    }
    
    // MARK: - Context Memory Management
    
    /// Update active context memory with new items
    private func updateContextMemory(with items: [ContextualPARAItem]) async {
        
        // Add to sliding window
        let newPARAItems = items.map { $0.toPARAItem() }
        activeContextWindow.append(contentsOf: newPARAItems)
        
        // Maintain window size
        if activeContextWindow.count > ContextConfig.slidingWindowSize {
            activeContextWindow.removeFirst(activeContextWindow.count - ContextConfig.slidingWindowSize)
        }
        
        // Update daily summary
        await updateDailySummary(with: newPARAItems)
        
        // Persist to database
        await persistContextMemory()
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
    
    private func getPersonalRules(from context: ProcessingContext) -> [PersonalPARARule] {
        // For now, return empty array since ProcessingContext doesn't have personalRules
        // In production, this would be loaded from PersonalRulesService
        return []
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
    
    private func persistUserCorrection(_ correction: UserCorrection) async {
        // Placeholder implementation - would persist to database
        print("📝 CONTEXTUAL: Persisting user correction: \(correction.id)")
    }
    
    private func extractPersonalRule(from correction: UserCorrection) async -> PersonalPARARule? {
        // Placeholder implementation - would extract patterns from correction
        return nil
    }
    
    private func persistPersonalRule(_ rule: PersonalPARARule) async {
        // Placeholder implementation - would persist to database
        print("📝 CONTEXTUAL: Persisting personal rule: \(rule.id)")
    }
    
    private func refreshContextMemory() async {
        // Placeholder implementation - would refresh context from database
        print("📝 CONTEXTUAL: Refreshing context memory")
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
                label: "Project",
                classification: PARAClassification(
                    category: .project,
                    subcategory: nil,
                    suggestedProject: nil,
                    suggestedArea: nil,
                    priority: .medium,
                    dueDate: nil,
                    tags: [],
                    workPersonal: .personal,
                    confidence: 0.8,
                    reasoning: "User selected project"
                ),
                explanation: "This is a project with specific outcomes"
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
    
    private func loadRecentCorrections(days: Int) async -> [UserCorrection] {
        // Placeholder implementation - would load from database
        print("📝 CONTEXTUAL: Loading recent corrections for \(days) days")
        return []
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
}

// MARK: - Supporting Data Structures

// ProcessingContext is defined in ContextMemoryService.swift

struct AtomicItem {
    let content: String
    let type: ContentType
    let contextualHints: [String]
    let confidence: Float
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
    let item: ContextualPARAItem
    let question: String
    let options: [ClarificationOption]
    let reasoning: String
}

struct ClarificationOption {
    let label: String
    let classification: PARAClassification
    let explanation: String
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

// DailySummary and WeeklySummary are defined in ContextMemoryService.swift

enum ProcessingStage {
    case idle, preparingContext, splittingInput, analyzingItems, applyingCorrections, generatingClarifications, updatingContext
}

struct ContextualProcessingResult {
    let processedItems: [ContextualPARAItem]
    let clarificationQuestions: [ClarificationQuestion]
    let contextUsed: ProcessingContext
    let confidence: Float
    let suggestions: [MetaSuggestion]
}

// MARK: - Extensions

extension PARAClassification {
    var hasStrongIndicators: Bool {
        // Implementation to detect strong classification indicators
        return confidence > 0.8
    }
}