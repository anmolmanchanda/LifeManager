//
// ContextualPARAViewModel.swift
// LifeManager
//
// Implements: v2.0 "Advanced AI Capabilities" - Contextual PARA UI Integration
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ⏳ IN PROGRESS as of June 14, 2025
// Future: v2.5 Advanced UI Features, Real-time Suggestions
//

import Foundation
import SwiftUI

/// ViewModel for contextual PARA processing with advanced AI capabilities
/// Integrates context memory, embeddings, and personal rules for intelligent categorization
@MainActor
class ContextualPARAViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isProcessing = false
    @Published var processingStage: ProcessingStage = .idle
    @Published var processingProgress: Float = 0.0
    
    // Processing Results
    @Published var processedItems: [ContextualPARAItem] = []
    @Published var clarificationQuestions: [ClarificationQuestion] = []
    @Published var metaSuggestions: [MetaSuggestion] = []
    @Published var processingConfidence: Float = 0.0
    
    // Context Information
    @Published var contextSummary: String = ""
    @Published var activeProjects: [String] = []
    @Published var activeAreas: [String] = []
    @Published var contextPatterns: ContextPatterns?
    
    // Personal Rules
    @Published var personalRules: [PersonalPARARule] = []
    @Published var suggestedRules: [SuggestedRule] = []
    @Published var ruleStats: RuleStats = RuleStats()
    
    // Error Handling
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // UI State
    @Published var selectedItems: Set<String> = [] // Using content hash for selection
    @Published var showingClarifications = false
    @Published var showingMetaSuggestions = false
    @Published var showingPersonalRules = false
    
    // MARK: - Dependencies
    
    private let contextualEngine = ContextualPARAEngine()
    private let contextMemoryService = ContextMemoryService.shared
    private let personalRulesService = PersonalRulesService.shared
    private let embeddingsService = EmbeddingsService.shared
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Process brain dump input with contextual analysis
    func processContextualBrainDump(_ input: String) async {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter some content to process")
            return
        }
        
        isProcessing = true
        processingProgress = 0.0
        errorMessage = nil
        
        do {
            // Update progress as we go through stages
            updateProgress(0.1, stage: .preparingContext)
            
            let result = try await contextualEngine.processContextualBrainDump(
                input: input,
                userContext: createUserContext()
            )
            
            updateProgress(1.0, stage: .idle)
            
            // Update UI with results
            processedItems = result.processedItems
            clarificationQuestions = result.clarificationQuestions
            metaSuggestions = result.suggestions
            processingConfidence = result.confidence
            
            // Show clarifications if needed
            if !clarificationQuestions.isEmpty {
                showingClarifications = true
            }
            
            // Show meta suggestions if available
            if !metaSuggestions.isEmpty {
                showingMetaSuggestions = true
            }
            
            print("🧠 CONTEXTUAL: ✅ Processed \(processedItems.count) items with \(Int(processingConfidence * 100))% confidence")
            
        } catch {
            showError("Failed to process input: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    /// Apply user correction to an item
    func applyUserCorrection(
        to item: ContextualPARAItem,
        correctedClassification: PARAClassification,
        userFeedback: String? = nil
    ) async {
        
        do {
            // Record the correction
            await personalRulesService.recordUserCorrection(
                originalItem: item,
                correctedClassification: correctedClassification,
                userFeedback: userFeedback
            )
            
            // Update the item in our list
            if let index = processedItems.firstIndex(where: { $0.originalItem.content == item.originalItem.content }) {
                var updatedItem = processedItems[index]
                updatedItem.paraClassification = correctedClassification
                processedItems[index] = updatedItem
            }
            
            // Refresh personal rules
            await refreshPersonalRules()
            
            print("📝 CONTEXTUAL: ✅ Applied user correction and updated rules")
            
        } catch {
            showError("Failed to apply correction: \(error.localizedDescription)")
        }
    }
    
    /// Answer clarification question
    func answerClarificationQuestion(
        _ question: ClarificationQuestion,
        selectedOption: ClarificationOption
    ) async {
        
        // Apply the selected classification
        await applyUserCorrection(
            to: question.item,
            correctedClassification: selectedOption.classification,
            userFeedback: "Clarification: \(selectedOption.explanation)"
        )
        
        // Remove the question from the list
        clarificationQuestions.removeAll { $0.item.originalItem.content == question.item.originalItem.content }
        
        // Hide clarifications view if no more questions
        if clarificationQuestions.isEmpty {
            showingClarifications = false
        }
    }
    
    /// Accept a suggested personal rule
    func acceptSuggestedRule(_ rule: SuggestedRule) async {
        await personalRulesService.acceptSuggestedRule(rule)
        await refreshPersonalRules()
    }
    
    /// Reject a suggested personal rule
    func rejectSuggestedRule(_ rule: SuggestedRule) async {
        await personalRulesService.rejectSuggestedRule(rule)
        await refreshPersonalRules()
    }
    
    /// Get context summary for display
    func getContextSummary(timeframe: ContextTimeframe = .week) async {
        contextSummary = await contextMemoryService.getContextSummary(for: timeframe)
    }
    
    /// Refresh all data
    func refreshData() async {
        await loadInitialData()
    }
    
    /// Clear processing results
    func clearResults() {
        processedItems.removeAll()
        clarificationQuestions.removeAll()
        metaSuggestions.removeAll()
        processingConfidence = 0.0
        selectedItems.removeAll()
        showingClarifications = false
        showingMetaSuggestions = false
    }
    
    /// Export processed items to PARA system
    func exportToPARASystem() async {
        let selectedItemsToExport = processedItems.filter { item in
            selectedItems.contains(String(item.originalItem.content.hashValue)) || selectedItems.isEmpty
        }
        
        guard !selectedItemsToExport.isEmpty else {
            showError("No items selected for export")
            return
        }
        
        do {
            // Convert to PARA items and add to context memory
            let paraItems = selectedItemsToExport.map { $0.toPARAItem() }
            await contextMemoryService.addToContext(paraItems)
            
            // Update embeddings for new items
            await embeddingsService.updatePARAEmbeddings()
            
            print("🧠 CONTEXTUAL: ✅ Exported \(paraItems.count) items to PARA system")
            
            // Clear exported items
            processedItems.removeAll { item in
                selectedItemsToExport.contains { $0.originalItem.content == item.originalItem.content }
            }
            
        } catch {
            showError("Failed to export items: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe contextual engine state
        contextualEngine.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isProcessing)
        
        contextualEngine.$processingStage
            .receive(on: DispatchQueue.main)
            .assign(to: &$processingStage)
        
        // Observe personal rules service
        personalRulesService.$personalRules
            .receive(on: DispatchQueue.main)
            .assign(to: &$personalRules)
        
        personalRulesService.$suggestedRules
            .receive(on: DispatchQueue.main)
            .assign(to: &$suggestedRules)
        
        personalRulesService.$ruleStats
            .receive(on: DispatchQueue.main)
            .assign(to: &$ruleStats)
    }
    
    private func loadInitialData() async {
        // Load context information
        let activeItems = contextMemoryService.getActiveItems()
        activeProjects = activeItems.projects
        activeAreas = activeItems.areas
        
        // Load context patterns
        contextPatterns = contextMemoryService.getContextPatterns()
        
        // Load context summary
        await getContextSummary()
        
        // Refresh personal rules
        await refreshPersonalRules()
    }
    
    private func refreshPersonalRules() async {
        await personalRulesService.generateRuleSuggestions()
    }
    
    private func createUserContext() -> UserContext {
        return UserContext(
            activeProjects: activeProjects,
            activeAreas: activeAreas,
            contextPatterns: contextPatterns,
            timestamp: Date()
        )
    }
    
    private func updateProgress(_ progress: Float, stage: ProcessingStage) {
        processingProgress = progress
        processingStage = stage
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Supporting Data Structures

struct UserContext {
    let activeProjects: [String]
    let activeAreas: [String]
    let contextPatterns: ContextPatterns?
    let timestamp: Date
}

// MARK: - UI Helper Extensions

extension ContextualPARAViewModel {
    
    /// Get processing stage description for UI
    var processingStageDescription: String {
        switch processingStage {
        case .idle:
            return "Ready"
        case .preparingContext:
            return "Analyzing context..."
        case .splittingInput:
            return "Breaking down input..."
        case .analyzingItems:
            return "Classifying items..."
        case .applyingCorrections:
            return "Applying personal rules..."
        case .generatingClarifications:
            return "Generating questions..."
        case .updatingContext:
            return "Updating memory..."
        }
    }
    
    /// Get confidence color for UI
    var confidenceColor: Color {
        switch processingConfidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    /// Get items that need clarification
    var itemsNeedingClarification: [ContextualPARAItem] {
        return processedItems.filter { $0.confidence < 0.8 }
    }
    
    /// Get high confidence items
    var highConfidenceItems: [ContextualPARAItem] {
        return processedItems.filter { $0.confidence >= 0.8 }
    }
    
    /// Get rule effectiveness summary
    var ruleEffectivenessSummary: String {
        let effectiveness = personalRulesService.getRuleEffectiveness()
        let averageSuccess = effectiveness.isEmpty ? 0.0 : effectiveness.map { $0.successRate }.reduce(0, +) / Float(effectiveness.count)
        return "Average rule success rate: \(Int(averageSuccess * 100))%"
    }
}

// MARK: - Content Type Extensions

// ContentType extensions are defined in CoreModels.swift

// MARK: - PARA Category Extensions

extension PARACategory {
    // displayName and icon are defined in CoreModels.swift
    
    // color property would be defined in CoreModels.swift if needed
}

// MARK: - Missing Type Definitions
// Note: ContentType is defined in CoreModels.swift

struct PARAClassification {
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
    
    // hasStrongIndicators would be defined in the main PARAClassification struct
}

struct ItemMetadata {
    let extractedTags: [String]
    let detectedPeople: [String]
    let estimatedDuration: TimeInterval?
    let urgencyLevel: TaskPriority
    let sentiment: SentimentAnalysis?
}

struct SentimentAnalysis {
    let score: Float // -1.0 to 1.0
    let confidence: Float
    let emotions: [String]
} 