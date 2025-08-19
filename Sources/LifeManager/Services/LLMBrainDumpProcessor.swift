//
// LLMBrainDumpProcessor.swift
// LifeManager
//
// Implements: v2.0 "Intelligence Expansion" - Enhanced Brain Dump Processing
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Processing Pipeline
// Status: ✅ RESTORED June 18, 2025 - Phase 1C AI Pipeline Integration
// Future: v2.5 Multi-Modal Processing, Advanced Context Analysis
//
// RESTORED from temp_excluded/ during Phase 1C AI pipeline integration.
// Enhanced with ContextualPARAEngine, ContextMemoryService, and PersonalRulesService
// for comprehensive, context-aware, self-improving brain dump processing.
//

import Foundation

/// Comprehensive LLM-powered brain dump processor for LifeManager
/// Intelligently parses any unstructured text and organizes into PARA categories
/// Enhanced with advanced AI services for context-aware, self-improving processing
class LLMBrainDumpProcessor {
    private let llmService: LLMService
    private let blobRepository: BlobRepository
    private let taskRepository: TaskRepository
    private let paraRepository: PARARepository
    // private let resourceRepository: ResourceRepository  // TODO: Implement ResourceRepository
    // private let journalRepository: JournalRepository  // TODO: Implement JournalRepository
    private let embeddingsService: EmbeddingsService
    
    // MARK: - Advanced AI Services Integration
    private let contextualEngine: ContextualPARAEngine
    private let contextMemoryService: ContextMemoryService
    private let personalRulesService: PersonalRulesService
    
    // MARK: - Enhanced Services
    private let contentTypeHandler = BrainDumpContentTypeHandler.shared
    private let embeddingsGenerator = BrainDumpEmbeddingsService.shared
    
    init() {
        self.llmService = LLMServiceCoordinator.shared
        self.blobRepository = BlobRepository()
        self.taskRepository = TaskRepository()
        self.paraRepository = PARARepository()
        // self.resourceRepository = ResourceRepository()  // TODO: Implement ResourceRepository
        // self.journalRepository = JournalRepository()    // TODO: Implement JournalRepository
        self.embeddingsService = EmbeddingsService.shared
        
        // Initialize advanced AI services
        self.contextualEngine = ContextualPARAEngine()
        self.contextMemoryService = ContextMemoryService.shared
        self.personalRulesService = PersonalRulesService.shared
    }
    
    /// Main processing method enhanced with advanced AI services
    func processBrainDump(_ input: String) async throws -> BrainDumpResult {
        Logger.shared.brainDumpProgress("🧠 Starting enhanced brain dump processing...")
        
        // Step 1: Prepare processing context using ContextMemoryService
        let processingContext = await contextMemoryService.getCurrentContext()
        Logger.shared.brainDumpProgress("📝 Loaded context: \(processingContext.recentItems.count) recent items")
        
        // Step 2: Use ContextualPARAEngine for advanced processing
        do {
            let contextualResult = try await contextualEngine.processContextualBrainDump(
                input: input,
                userContext: UserContext(
                    currentFocus: await getCurrentUserFocus(),
                    timeOfDay: Date(),
                    workMode: determineWorkMode(),
                    recentActivities: getRecentActivities(from: processingContext)
                )
            )
            
            // Step 3: Apply personal rules and learn from patterns
            let enhancedItems = await applyPersonalRulesAndLearning(contextualResult.processedItems)
            
            // Step 4: Build comprehensive result with AI insights
            let result = BrainDumpResult(
                originalInput: input,
                analysisResult: convertToEnhancedAnalysis(contextualResult),
                suggestedItems: enhancedItems,
                confidence: Double(contextualResult.confidence),
                requiresReview: contextualResult.confidence < 0.8 || !contextualResult.clarificationQuestions.isEmpty,
                processingMetadata: ProcessingMetadata(
                    processingTime: Date(),
                    aiServicesUsed: ["ContextualPARAEngine", "ContextMemoryService", "PersonalRulesService"],
                    contextItemsConsidered: processingContext.recentItems.count,
                    rulesApplied: personalRulesService.personalRules.filter { $0.isActive }.count
                ),
                clarificationQuestions: contextualResult.clarificationQuestions.map { $0.question },
                optimizationSuggestions: contextualResult.suggestions.map { $0.description },
                contextualInsights: ContextualInsights(
                    recentPatterns: extractRecentPatterns(from: processingContext),
                    suggestedWorkflows: contextualResult.suggestions.map { $0.description },
                    productivityTips: generateProductivityTips(from: contextualResult)
                )
            )
            
            // Step 5: Update context memory with processing results
            await updateContextWithResults(result)
            
            Logger.shared.success("🧠 Enhanced brain dump processing complete - \(result.suggestedItems.count) items processed")
            return result
            
        } catch {
            Logger.shared.error("🧠 Enhanced processing failed, falling back to basic LLM: \(error)")
            return try await processBrainDumpFallback(input)
        }
    }
    
    // MARK: - Advanced AI Integration Methods
    
    private func getCurrentUserFocus() async -> String? {
        // Analyze recent activity to determine current focus
        let context = await contextMemoryService.getCurrentContext()
        let recentProjects = context.recentItems.filter { $0.category == .project }
        return recentProjects.first?.title
    }
    
    private func determineWorkMode() -> WorkPersonalType {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Business hours heuristic
        if hour >= 9 && hour <= 17 {
            return .work
        } else {
            return .personal
        }
    }
    
    private func getRecentActivities(from context: ProcessingContext) -> [String] {
        return context.recentItems.prefix(10).map { $0.title }
    }
    
    private func applyPersonalRulesAndLearning(_ items: [ContextualPARAItem]) async -> [EnhancedBrainDumpItem] {
        var enhancedItems: [EnhancedBrainDumpItem] = []
        
        for item in items {
            // Apply personal rules to enhance classification
            let enhancedItem = await personalRulesService.applyPersonalRules(to: item)
            
            // Convert to EnhancedBrainDumpItem with AI insights
            let brainDumpItem = EnhancedBrainDumpItem(
                id: UUID(),
                title: String(enhancedItem.originalItem.content.prefix(50)),
                content: enhancedItem.originalItem.content,
                contentType: enhancedItem.originalItem.type,
                paraCategory: enhancedItem.paraClassification.category,
                suggestedArea: enhancedItem.paraClassification.suggestedArea,
                suggestedProject: enhancedItem.paraClassification.suggestedProject,
                workPersonal: enhancedItem.paraClassification.workPersonal,
                priority: enhancedItem.paraClassification.priority,
                dueDate: enhancedItem.paraClassification.dueDate?.ISO8601Format(),
                tags: enhancedItem.paraClassification.tags,
                confidence: Double(enhancedItem.confidence),
                metadata: ["reasoning": enhancedItem.reasoning],
                
                // Enhanced reasoning from AI services
                classificationReasoning: ClassificationReasoning(
                    primaryReasons: [enhancedItem.reasoning],
                    supportingEvidence: enhancedItem.paraClassification.tags,
                    counterEvidence: [],
                    confidenceFactors: ["AI confidence: \(enhancedItem.confidence)"],
                    alternativeOptions: [],
                    contextualInfluence: "Context-aware processing applied"
                ),
                alternativeClassifications: [],
                contextualRelevance: ContextualRelevance(
                    recentActivityAlignment: Double(enhancedItem.confidence),
                    existingProjectsAlignment: [],
                    areaFocusAlignment: [],
                    workPersonalBalance: 0.5,
                    priorityConsistency: Double(enhancedItem.confidence)
                ),
                semanticSimilarity: enhancedItem.semanticMatches.map { match in
                    SemanticSimilarity(
                        targetItem: match.paraItem.title,
                        similarity: Double(match.similarity),
                        relevanceType: .contentSimilarity,
                        explanation: "Semantic match found"
                    )
                },
                uncertaintyFactors: [],
                suggestedActions: [],
                estimatedEffort: EffortEstimate(
                    timeRequired: 3600, // 1 hour default
                    complexity: .medium,
                    confidence: Double(enhancedItem.confidence)
                ),
                timelineAnalysis: TimelineAnalysis(
                    suggestedScheduling: Date(),
                    deadlineAnalysis: enhancedItem.paraClassification.dueDate,
                    bufferTime: 1800 // 30 minutes
                )
            )
            
            enhancedItems.append(brainDumpItem)
        }
        
        return enhancedItems
    }
    
    private func convertToEnhancedAnalysis(_ result: ContextualProcessingResult) -> EnhancedLLMAnalysisResult {
        return EnhancedLLMAnalysisResult(
            extractedItems: [], // Will be populated in applyPersonalRulesAndLearning
            confidence: Double(result.confidence),
            hasAmbiguousItems: !result.clarificationQuestions.isEmpty,
            reasoning: DetailedReasoning(
                primaryFactors: [],
                contextualInfluences: ["Context-aware processing used"],
                patternMatches: [],
                uncertainties: result.clarificationQuestions.map { $0.question },
                confidenceBreakdown: ConfidenceBreakdown(
                    overallConfidence: Double(result.confidence),
                    categoryConfidence: [:],
                    factorContributions: [:]
                ),
                decisionTree: []
            ),
            suggestedNewAreas: [],
            suggestedNewProjects: [],
            patternAnalysis: PatternAnalysis(
                detectedPatterns: [],
                frequencyAnalysis: [:],
                temporalPatterns: []
            ),
            contextualFactors: [],
            uncertaintyAnalysis: UncertaintyAnalysis(
                ambiguousItems: result.clarificationQuestions.map { $0.question },
                confidenceRanges: [:],
                recommendations: result.suggestions.map { $0.description }
            ),
            crossItemRelationships: []
        )
    }
    
    private func extractRecentPatterns(from context: ProcessingContext) -> [String] {
        let recentCategories = context.recentItems.map { $0.category.rawValue }
        let categoryFrequency = Dictionary(grouping: recentCategories, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return categoryFrequency.prefix(3).map { "Recent focus on \($0.key)" }
    }
    
    private func generateProductivityTips(from result: ContextualProcessingResult) -> [String] {
        var tips: [String] = []
        
        if result.confidence < 0.7 {
            tips.append("Consider providing more specific details for better categorization")
        }
        
        if !result.clarificationQuestions.isEmpty {
            tips.append("Answering clarification questions will improve future processing")
        }
        
        return tips
    }
    
    private func updateContextWithResults(_ result: BrainDumpResult) async {
        // Add processed items to context memory
        let paraItems = result.suggestedItems.map { item in
            PARAItem(
                id: item.id,
                title: item.title,
                content: item.content,
                contentType: item.contentType,
                paraCategory: item.paraCategory,
                workPersonal: item.workPersonal,
                priority: item.priority,
                createdAt: Date(),
                tags: item.tags,
                isCompleted: false
            )
        }
        
        await contextMemoryService.addToContext(paraItems)
    }
    
    // MARK: - Brain Dump Execution
    
    /// Execute brain dump by creating database entries from user-approved items
    func executeBrainDump(_ result: BrainDumpResult, userApprovedItems: [EnhancedBrainDumpItem]) async throws -> ExecutionSummary {
        Logger.shared.brainDumpProgress("🧠 Executing brain dump with \(userApprovedItems.count) items...")
        
        let startTime = Date()
        
        // Process all items using the content type handler
        let batchResult = await contentTypeHandler.processContentItems(userApprovedItems)
        
        // Generate embeddings for all approved items
        await embeddingsGenerator.generateEmbeddingsForItems(userApprovedItems)
        
        var createdItems = batchResult.successfulCreations.count
        var errors = batchResult.errors.map { "Failed to create \($0.itemTitle): \($0.error.localizedDescription)" }
        
        // Update context memory with successful items
        await updateContextWithResults(result)
        
        // Group created items by type for display
        let taskItems = batchResult.successfulCreations.filter { $0.type == .task }.map { $0.title }
        let noteItems = batchResult.successfulCreations.filter { $0.type == .note || $0.type == .knowledge }.map { $0.title }
        let journalItems = batchResult.successfulCreations.filter { $0.type == .journal }.map { $0.title }
        let resourceItems = batchResult.successfulCreations.filter { $0.type == .resource }.map { $0.title }
        let appointmentItems = batchResult.successfulCreations.filter { $0.type == .appointment }.map { $0.title }
        let habitItems = batchResult.successfulCreations.filter { $0.type == .habit }.map { $0.title }
        let goalItems = batchResult.successfulCreations.filter { $0.type == .goal }.map { $0.title }
        let financialItems = batchResult.successfulCreations.filter { $0.type == .financial }.map { $0.title }
        
        // Build confidence and category distributions
        var confidenceDistribution: [String: Int] = [:]
        var categoryDistribution: [PARACategory: Int] = [:]
        
        for item in userApprovedItems {
            let confidenceLevel = item.confidence >= 0.8 ? "high" : item.confidence >= 0.5 ? "medium" : "low"
            confidenceDistribution[confidenceLevel, default: 0] += 1
            categoryDistribution[item.paraCategory, default: 0] += 1
        }
        
        let summary = ExecutionSummary(
            totalItemsProcessed: userApprovedItems.count,
            itemsCreated: createdItems,
            itemsSkipped: userApprovedItems.count - createdItems,
            errors: errors,
            warnings: batchResult.errors.map { "Warning: \($0.itemTitle) may need review" },
            processingTime: Date().timeIntervalSince(startTime),
            confidenceDistribution: confidenceDistribution,
            categoryDistribution: categoryDistribution,
            newAreasCreated: batchResult.successfulCreations.filter { $0.type == .area }.map { $0.title },
            newProjectsCreated: batchResult.successfulCreations.filter { $0.type == .project }.map { $0.title },
            successCount: createdItems,
            tasksCreated: taskItems,
            notesCreated: noteItems,
            journalEntriesCreated: journalItems,
            resourcesCreated: resourceItems,
            appointmentsCreated: appointmentItems,
            habitsCreated: habitItems,
            goalsCreated: goalItems,
            financialTransactionsCreated: financialItems
        )
        
        Logger.shared.success("🧠 Brain dump execution complete: \(createdItems) items created")
        return summary
    }
    
    /// Create database entry for an enhanced brain dump item - DEPRECATED: Use contentTypeHandler instead
    @available(*, deprecated, message: "Use contentTypeHandler.processContentItem instead")
    private func createDatabaseEntry(for item: EnhancedBrainDumpItem) async throws {
        switch item.contentType {
        case .task:
            // Create blob first for task content
            let blob = try await blobRepository.createBlob(
                content: item.content,
                sourceType: .note,
                workPersonal: item.workPersonal
            )
            
            // Create task with blob reference
            let task = try await taskRepository.createTask(
                blobId: blob.id,
                title: item.title,
                description: item.content,
                priority: item.priority,
                status: .inbox,
                dueDate: item.dueDate != nil ? ISO8601DateFormatter().date(from: item.dueDate!) : nil,
                workPersonal: item.workPersonal,
                projectId: item.suggestedProject != nil ? UUID(uuidString: item.suggestedProject!) : nil
            )
            
            Logger.shared.success("✅ Created task: \(item.title) [ID: \(task.id)]")
            
        case .note, .knowledge:
            // Create blob for note/knowledge content
            let blob = try await blobRepository.createBlob(
                content: item.content,
                sourceType: .note,
                workPersonal: item.workPersonal
            )
            
            Logger.shared.success("✅ Created \(item.contentType.rawValue): \(item.title) [ID: \(blob.id)]")
            
        case .journal:
            // TODO: Implement journal creation when JournalRepository is available
            Logger.shared.warning("⚠️ Journal creation not yet implemented: \(item.title)")
            
        case .resource:
            // TODO: Implement resource creation when ResourceRepository is available
            Logger.shared.warning("⚠️ Resource creation not yet implemented: \(item.title)")
            
        case .project:
            // Create project via PARA repository
            let project = Project(
                name: item.title,
                description: item.content,
                workPersonal: item.workPersonal
            )
            let createdProject = try await paraRepository.createProject(project)
            
            Logger.shared.success("✅ Created project: \(item.title) [ID: \(createdProject.id)]")
            
        case .area:
            // Create area via PARA repository
            let area = Area(
                name: item.title,
                description: item.content,
                workPersonal: item.workPersonal
            )
            let createdArea = try await paraRepository.createArea(area)
            
            Logger.shared.success("✅ Created area: \(item.title) [ID: \(createdArea.id)]")
            
        default:
            // For other content types, create as blob
            let blob = try await blobRepository.createBlob(
                content: item.content,
                sourceType: .note,
                workPersonal: item.workPersonal
            )
            
            Logger.shared.success("✅ Created \(item.contentType.rawValue): \(item.title) [ID: \(blob.id)]")
        }
        
        // Send notification that data was created so UI refreshes
        NotificationCenter.default.post(name: .dataDidChange, object: nil)
    }
    
    // MARK: - Fallback Processing
    
    private func processBrainDumpFallback(_ input: String) async throws -> BrainDumpResult {
        Logger.shared.brainDumpProgress("Using fallback processing")
        
        // Simple rule-based parsing for common patterns
        let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var suggestedItems: [EnhancedBrainDumpItem] = []
        
        for sentence in sentences {
            let item = createFallbackItem(from: sentence)
            suggestedItems.append(item)
        }
        
        // If no sentences found, create a single note
        if suggestedItems.isEmpty {
            let item = createFallbackItem(from: input)
            suggestedItems.append(item)
        }
        
        return BrainDumpResult(
            originalInput: input,
            analysisResult: EnhancedLLMAnalysisResult(
                extractedItems: suggestedItems,
                confidence: 0.5,
                hasAmbiguousItems: true,
                reasoning: DetailedReasoning(
                    primaryFactors: [],
                    contextualInfluences: ["Fallback processing used"],
                    patternMatches: [],
                    uncertainties: ["No LLM analysis available"],
                    confidenceBreakdown: ConfidenceBreakdown(
                        overallConfidence: 0.5,
                        categoryConfidence: [:],
                        factorContributions: [:]
                    ),
                    decisionTree: []
                ),
                suggestedNewAreas: [],
                suggestedNewProjects: [],
                patternAnalysis: PatternAnalysis(
                    detectedPatterns: [],
                    frequencyAnalysis: [:],
                    temporalPatterns: []
                ),
                contextualFactors: [],
                uncertaintyAnalysis: UncertaintyAnalysis(
                    ambiguousItems: ["Fallback processing used"],
                    confidenceRanges: [:],
                    recommendations: ["Consider configuring API key for better results"]
                ),
                crossItemRelationships: []
            ),
            suggestedItems: suggestedItems,
            confidence: 0.5,
            requiresReview: true,
            processingMetadata: ProcessingMetadata(
                processingTime: Date(),
                aiServicesUsed: ["Fallback"],
                contextItemsConsidered: 0,
                rulesApplied: 0
            ),
            clarificationQuestions: ["Would you like to configure an API key for better processing?"],
            optimizationSuggestions: ["Configure OpenAI API key for advanced AI processing"],
            contextualInsights: ContextualInsights(
                recentPatterns: [],
                suggestedWorkflows: [],
                productivityTips: ["Set up API key for enhanced features"]
            )
        )
    }
    
    private func createFallbackItem(from text: String) -> EnhancedBrainDumpItem {
        // Simple heuristics for fallback processing
        let lowercaseText = text.lowercased()
        
        let contentType: ContentType = lowercaseText.contains("note") ? .note : .task
        let category: PARACategory = lowercaseText.contains("project") ? .project : .resource
        let priority: TaskPriority = lowercaseText.contains("urgent") ? .urgent : .medium
        
        return EnhancedBrainDumpItem(
            id: UUID(),
            title: String(text.prefix(50)),
            content: text,
            contentType: contentType,
            paraCategory: category,
            suggestedArea: nil,
            suggestedProject: nil,
            workPersonal: .personal,
            priority: priority,
            dueDate: nil,
            tags: [],
            confidence: 0.3,
            metadata: ["source": "fallback"],
            classificationReasoning: ClassificationReasoning(
                primaryReasons: ["Fallback processing"],
                supportingEvidence: [],
                counterEvidence: [],
                confidenceFactors: ["Simple heuristics used"],
                alternativeOptions: [],
                contextualInfluence: "No context available"
            ),
            alternativeClassifications: [],
            contextualRelevance: ContextualRelevance(
                recentActivityAlignment: 0.3,
                existingProjectsAlignment: [],
                areaFocusAlignment: [],
                workPersonalBalance: 0.5,
                priorityConsistency: 0.3
            ),
            semanticSimilarity: [],
            uncertaintyFactors: [],
            suggestedActions: [],
            estimatedEffort: EffortEstimate(
                timeRequired: 1800,
                complexity: .low,
                confidence: 0.3
            ),
            timelineAnalysis: TimelineAnalysis(
                suggestedScheduling: Date(),
                deadlineAnalysis: nil,
                bufferTime: 900
            )
        )
    }
}

// MARK: - Notification Extension for Data Changes
extension Notification.Name {
    static let dataDidChange = Notification.Name("dataDidChange")
}