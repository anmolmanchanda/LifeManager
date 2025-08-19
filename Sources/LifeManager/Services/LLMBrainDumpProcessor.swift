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
    
    // MARK: - Comprehensive Fallback Processing
    
    private func processBrainDumpFallback(_ input: String) async throws -> BrainDumpResult {
        Logger.shared.brainDumpProgress("Using comprehensive fallback processing")
        
        // Enhanced parsing with multiple strategies
        let items = await performEnhancedFallbackParsing(input)
        
        // Apply pattern-based categorization
        let categorizedItems = applyCategorization(to: items)
        
        // Detect basic relationships
        let relationships = detectBasicRelationships(among: categorizedItems)
        
        // Generate basic embeddings if possible
        await generateBasicEmbeddings(for: categorizedItems)
        
        // Build comprehensive result even without LLM
        let analysisResult = buildFallbackAnalysisResult(
            items: categorizedItems,
            relationships: relationships
        )
        
        return BrainDumpResult(
            originalInput: input,
            analysisResult: analysisResult,
            suggestedItems: categorizedItems,
            confidence: 0.6,
            requiresReview: true,
            processingMetadata: ProcessingMetadata(
                processingTime: Date(),
                aiServicesUsed: ["Enhanced Fallback", "Pattern Matching", "Rule-Based"],
                contextItemsConsidered: 0,
                rulesApplied: relationships.count
            ),
            clarificationQuestions: generateFallbackQuestions(for: categorizedItems),
            optimizationSuggestions: [
                "Configure OpenAI API key for advanced AI processing",
                "Review and refine detected items for accuracy",
                "Consider breaking complex items into smaller tasks"
            ],
            contextualInsights: ContextualInsights(
                recentPatterns: extractPatterns(from: categorizedItems),
                suggestedWorkflows: suggestWorkflows(for: categorizedItems),
                productivityTips: generateProductivityTips(from: categorizedItems)
            )
        )
    }
    
    // MARK: - Enhanced Fallback Methods
    
    private func performEnhancedFallbackParsing(_ input: String) async -> [EnhancedBrainDumpItem] {
        var items: [EnhancedBrainDumpItem] = []
        
        // Strategy 1: Line-based parsing
        let lines = input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            if let item = parseLineItem(line) {
                items.append(item)
            }
        }
        
        // Strategy 2: Sentence-based parsing if no lines found
        if items.isEmpty {
            let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            for sentence in sentences {
                items.append(createFallbackItem(from: sentence))
            }
        }
        
        // Strategy 3: Create single item if nothing else worked
        if items.isEmpty {
            items.append(createFallbackItem(from: input))
        }
        
        return items
    }
    
    private func parseLineItem(_ line: String) -> EnhancedBrainDumpItem? {
        // Check for list markers
        let listMarkers = ["- ", "* ", "• ", "→ ", "1. ", "2. ", "3. ", "4. ", "5. "]
        var cleanedLine = line
        
        for marker in listMarkers {
            if line.hasPrefix(marker) {
                cleanedLine = String(line.dropFirst(marker.count))
                break
            }
        }
        
        // Check for special prefixes
        if cleanedLine.lowercased().hasPrefix("todo:") || cleanedLine.lowercased().hasPrefix("task:") {
            return createTaskItem(from: String(cleanedLine.dropFirst(5)))
        } else if cleanedLine.lowercased().hasPrefix("note:") {
            return createNoteItem(from: String(cleanedLine.dropFirst(5)))
        } else if cleanedLine.lowercased().hasPrefix("idea:") {
            return createResourceItem(from: String(cleanedLine.dropFirst(5)))
        } else if cleanedLine.lowercased().hasPrefix("meeting:") || cleanedLine.lowercased().hasPrefix("appointment:") {
            return createAppointmentItem(from: cleanedLine)
        } else if cleanedLine.contains("$") || cleanedLine.lowercased().contains("spent") || cleanedLine.lowercased().contains("bought") {
            return createFinancialItem(from: cleanedLine)
        } else if !cleanedLine.isEmpty {
            return createFallbackItem(from: cleanedLine)
        }
        
        return nil
    }
    
    private func createTaskItem(from text: String) -> EnhancedBrainDumpItem {
        let priority = detectPriority(from: text)
        let dueDate = extractDate(from: text)
        
        return createEnhancedItem(
            title: String(text.prefix(50)),
            content: text,
            contentType: .task,
            category: .project,
            priority: priority,
            dueDate: dueDate,
            confidence: 0.7
        )
    }
    
    private func createNoteItem(from text: String) -> EnhancedBrainDumpItem {
        return createEnhancedItem(
            title: String(text.prefix(50)),
            content: text,
            contentType: .note,
            category: .resource,
            priority: .low,
            confidence: 0.6
        )
    }
    
    private func createResourceItem(from text: String) -> EnhancedBrainDumpItem {
        return createEnhancedItem(
            title: String(text.prefix(50)),
            content: text,
            contentType: .resource,
            category: .resource,
            priority: .medium,
            confidence: 0.6
        )
    }
    
    private func createAppointmentItem(from text: String) -> EnhancedBrainDumpItem {
        let date = extractDate(from: text) ?? ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400))
        
        return createEnhancedItem(
            title: String(text.prefix(50)),
            content: text,
            contentType: .appointment,
            category: .area,
            priority: .high,
            dueDate: date,
            confidence: 0.65
        )
    }
    
    private func createFinancialItem(from text: String) -> EnhancedBrainDumpItem {
        return createEnhancedItem(
            title: String(text.prefix(50)),
            content: text,
            contentType: .financial,
            category: .area,
            priority: .medium,
            confidence: 0.6
        )
    }
    
    private func createEnhancedItem(
        title: String,
        content: String,
        contentType: ContentType,
        category: PARACategory,
        priority: TaskPriority,
        dueDate: String? = nil,
        confidence: Double
    ) -> EnhancedBrainDumpItem {
        return EnhancedBrainDumpItem(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content,
            contentType: contentType,
            paraCategory: category,
            suggestedArea: nil,
            suggestedProject: nil,
            workPersonal: detectWorkPersonal(from: content),
            priority: priority,
            dueDate: dueDate,
            tags: extractTags(from: content),
            confidence: confidence,
            metadata: ["source": "enhanced_fallback"],
            classificationReasoning: ClassificationReasoning(
                primaryReasons: ["Pattern-based detection"],
                supportingEvidence: ["Keyword matching"],
                counterEvidence: [],
                confidenceFactors: ["Rule-based processing"],
                alternativeOptions: [],
                contextualInfluence: "Fallback processing"
            ),
            alternativeClassifications: [],
            contextualRelevance: ContextualRelevance(
                recentActivityAlignment: 0.5,
                existingProjectsAlignment: [],
                areaFocusAlignment: [],
                workPersonalBalance: 0.5,
                priorityConsistency: confidence
            ),
            semanticSimilarity: [],
            uncertaintyFactors: [],
            suggestedActions: [],
            estimatedEffort: EffortEstimate(
                timeRequired: 3600,
                complexity: .medium,
                confidence: confidence
            ),
            timelineAnalysis: TimelineAnalysis(
                suggestedScheduling: Date(),
                deadlineAnalysis: dueDate != nil ? ISO8601DateFormatter().date(from: dueDate!) : nil,
                bufferTime: 1800
            )
        )
    }
    
    private func detectPriority(from text: String) -> TaskPriority {
        let lowercased = text.lowercased()
        if lowercased.contains("urgent") || lowercased.contains("asap") || lowercased.contains("critical") {
            return .urgent
        } else if lowercased.contains("important") || lowercased.contains("high priority") {
            return .high
        } else if lowercased.contains("low priority") || lowercased.contains("someday") {
            return .low
        }
        return .medium
    }
    
    private func detectWorkPersonal(from text: String) -> WorkPersonalType {
        let lowercased = text.lowercased()
        let workKeywords = ["work", "office", "client", "meeting", "project", "deadline", "team"]
        let personalKeywords = ["personal", "home", "family", "hobby", "health", "exercise"]
        
        let workScore = workKeywords.filter { lowercased.contains($0) }.count
        let personalScore = personalKeywords.filter { lowercased.contains($0) }.count
        
        return workScore > personalScore ? .work : .personal
    }
    
    private func extractTags(from text: String) -> [String] {
        var tags: [String] = []
        
        // Extract hashtags
        let words = text.components(separatedBy: .whitespaces)
        for word in words {
            if word.hasPrefix("#") && word.count > 1 {
                tags.append(String(word.dropFirst()))
            }
        }
        
        // Add content-based tags
        let lowercased = text.lowercased()
        if lowercased.contains("urgent") { tags.append("urgent") }
        if lowercased.contains("important") { tags.append("important") }
        if lowercased.contains("review") { tags.append("needs-review") }
        
        return tags
    }
    
    private func extractDate(from text: String) -> String? {
        // Simple date detection patterns
        let patterns = [
            "tomorrow": Date().addingTimeInterval(86400),
            "next week": Date().addingTimeInterval(604800),
            "today": Date(),
            "monday": nextWeekday(1),
            "tuesday": nextWeekday(2),
            "wednesday": nextWeekday(3),
            "thursday": nextWeekday(4),
            "friday": nextWeekday(5)
        ]
        
        let lowercased = text.lowercased()
        for (pattern, date) in patterns {
            if lowercased.contains(pattern) {
                return ISO8601DateFormatter().string(from: date)
            }
        }
        
        return nil
    }
    
    private func nextWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysUntilWeekday = (weekday - todayWeekday + 7) % 7
        let daysToAdd = daysUntilWeekday == 0 ? 7 : daysUntilWeekday
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    private func applyCategorization(to items: [EnhancedBrainDumpItem]) -> [EnhancedBrainDumpItem] {
        return items.map { item in
            var categorized = item
            
            // Apply smarter categorization based on content
            if item.contentType == .task && item.priority == .urgent {
                categorized.paraCategory = .project
            } else if item.contentType == .note || item.contentType == .knowledge {
                categorized.paraCategory = .resource
            } else if item.contentType == .appointment || item.contentType == .habit {
                categorized.paraCategory = .area
            }
            
            return categorized
        }
    }
    
    private func detectBasicRelationships(among items: [EnhancedBrainDumpItem]) -> [ItemRelationship] {
        var relationships: [ItemRelationship] = []
        
        for i in 0..<items.count {
            for j in i+1..<items.count {
                // Check for similar content
                let similarity = calculateBasicSimilarity(items[i].content, items[j].content)
                if similarity > 0.5 {
                    relationships.append(ItemRelationship(
                        sourceItemId: items[i].id,
                        targetItemId: items[j].id,
                        relationshipType: .similarity,
                        strength: Double(similarity),
                        description: "Similar content detected"
                    ))
                }
                
                // Check for temporal relationships
                if let date1 = items[i].dueDate, let date2 = items[j].dueDate {
                    if date1 < date2 {
                        relationships.append(ItemRelationship(
                            sourceItemId: items[i].id,
                            targetItemId: items[j].id,
                            relationshipType: .sequence,
                            strength: 0.6,
                            description: "Temporal sequence"
                        ))
                    }
                }
            }
        }
        
        return relationships
    }
    
    private func calculateBasicSimilarity(_ text1: String, _ text2: String) -> Float {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        guard !words1.isEmpty && !words2.isEmpty else { return 0 }
        
        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count
        
        return Float(intersection) / Float(union)
    }
    
    private func generateBasicEmbeddings(for items: [EnhancedBrainDumpItem]) async {
        // Try to generate embeddings even in fallback mode if service is available
        if embeddingsService.hasValidAPIKey() {
            _ = await embeddingsGenerator.generateEmbeddingsForItems(items)
        }
    }
    
    private func buildFallbackAnalysisResult(
        items: [EnhancedBrainDumpItem],
        relationships: [ItemRelationship]
    ) -> EnhancedLLMAnalysisResult {
        let categoryDistribution = Dictionary(grouping: items) { $0.paraCategory }
        let patternFrequency = Dictionary(grouping: items) { $0.contentType }
            .mapValues { $0.count }
        
        return EnhancedLLMAnalysisResult(
            extractedItems: items,
            confidence: 0.6,
            hasAmbiguousItems: true,
            reasoning: DetailedReasoning(
                primaryFactors: [
                    ReasoningFactor(
                        type: .keywordMatch,
                        description: "Pattern-based detection",
                        weight: 0.8,
                        confidence: 0.6,
                        evidence: ["Keyword matching", "Rule-based parsing"]
                    )
                ],
                contextualInfluences: ["Enhanced fallback processing"],
                patternMatches: items.map { "Detected \($0.contentType.rawValue)" },
                uncertainties: ["No LLM validation available"],
                confidenceBreakdown: ConfidenceBreakdown(
                    overallConfidence: 0.6,
                    categoryConfidence: categoryDistribution.mapValues { Double($0.count) / Double(items.count) },
                    factorContributions: ["pattern": 0.4, "keyword": 0.3, "structure": 0.3]
                ),
                decisionTree: []
            ),
            suggestedNewAreas: [],
            suggestedNewProjects: [],
            patternAnalysis: PatternAnalysis(
                detectedPatterns: [
                    Pattern(
                        type: .recurring,
                        description: "Content type distribution",
                        frequency: items.count,
                        confidence: 0.6,
                        examples: items.prefix(3).map { $0.title }
                    )
                ],
                frequencyAnalysis: patternFrequency.mapValues { $0 },
                temporalPatterns: []
            ),
            contextualFactors: [],
            uncertaintyAnalysis: UncertaintyAnalysis(
                ambiguousItems: items.filter { $0.confidence < 0.7 }.map { $0.title },
                confidenceRanges: ["overall": 0.5...0.7],
                recommendations: [
                    "Review extracted items for accuracy",
                    "Configure API key for improved processing"
                ]
            ),
            crossItemRelationships: relationships
        )
    }
    
    private func generateFallbackQuestions(for items: [EnhancedBrainDumpItem]) -> [String] {
        var questions: [String] = []
        
        if items.contains(where: { $0.contentType == .task && $0.dueDate == nil }) {
            questions.append("Would you like to set due dates for the detected tasks?")
        }
        
        if items.contains(where: { $0.confidence < 0.7 }) {
            questions.append("Should we review items with low confidence scores?")
        }
        
        if items.count > 5 {
            questions.append("Would you like to group related items into projects?")
        }
        
        questions.append("Would you like to configure an API key for better processing?")
        
        return questions
    }
    
    private func extractPatterns(from items: [EnhancedBrainDumpItem]) -> [String] {
        var patterns: [String] = []
        
        let typeGroups = Dictionary(grouping: items) { $0.contentType }
        for (type, group) in typeGroups where group.count > 1 {
            patterns.append("Multiple \(type.rawValue) items detected (\(group.count))")
        }
        
        let priorityGroups = Dictionary(grouping: items.filter { $0.contentType == .task }) { $0.priority }
        if let urgentCount = priorityGroups[.urgent]?.count, urgentCount > 0 {
            patterns.append("\(urgentCount) urgent task(s) detected")
        }
        
        return patterns
    }
    
    private func suggestWorkflows(for items: [EnhancedBrainDumpItem]) -> [String] {
        var workflows: [String] = []
        
        if items.contains(where: { $0.contentType == .task }) {
            workflows.append("Process tasks by priority")
        }
        
        if items.contains(where: { $0.contentType == .appointment }) {
            workflows.append("Schedule appointments in calendar")
        }
        
        if items.count > 10 {
            workflows.append("Break down into smaller batches")
        }
        
        return workflows
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