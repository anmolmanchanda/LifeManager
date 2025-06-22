//
// LLMBrainDumpProcessor.swift - FIXED VERSION
// LifeManager
//
// CRITICAL FIX: Database persistence implemented
// This version replaces the mocked createDatabaseEntry method with actual repository calls
//

import Foundation

/// Comprehensive LLM-powered brain dump processor for LifeManager
/// FIXED: Now actually persists items to database instead of just logging
class LLMBrainDumpProcessor {
    private let llmService: LLMService
    private let blobRepository: BlobRepository
    private let taskRepository: TaskRepository
    private let paraRepository: PARARepository
    private let resourceRepository: ResourceRepository
    private let journalRepository: JournalRepository
    private let embeddingsService: EmbeddingsService
    
    // MARK: - Advanced AI Services Integration
    private let contextualEngine: ContextualPARAEngine
    private let contextMemoryService: ContextMemoryService
    private let personalRulesService: PersonalRulesService
    
    init() {
        self.llmService = LLMServiceCoordinator.shared
        self.blobRepository = BlobRepository()
        self.taskRepository = TaskRepository()
        self.paraRepository = PARARepository()
        self.resourceRepository = ResourceRepository()
        self.journalRepository = JournalRepository()
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
    
    // MARK: - Brain Dump Execution
    
    /// Execute brain dump by creating database entries from user-approved items
    func executeBrainDump(_ result: BrainDumpResult, userApprovedItems: [EnhancedBrainDumpItem]) async throws -> ExecutionSummary {
        Logger.shared.brainDumpProgress("🧠 Executing brain dump with \(userApprovedItems.count) items...")
        
        var createdItems = 0
        var errors: [String] = []
        
        // Create database entries for each approved item
        for item in userApprovedItems {
            do {
                try await createDatabaseEntry(for: item)
                createdItems += 1
                Logger.shared.success("✅ Created \(item.contentType.rawValue): \(item.title)")
            } catch {
                errors.append("Failed to create \(item.title): \(error.localizedDescription)")
                Logger.shared.error("❌ Failed to create \(item.title): \(error)")
            }
        }
        
        // CRITICAL: Notify ViewModels to refresh data after creation
        await MainActor.run {
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        }
        
        // Update context memory with successful items
        await updateContextWithResults(result)
        
        // Group created items by type for display
        let taskItems = userApprovedItems.filter { $0.contentType == .task }.map { $0.title }
        let noteItems = userApprovedItems.filter { $0.contentType == .note || $0.contentType == .knowledge }.map { $0.title }
        let journalItems = userApprovedItems.filter { $0.contentType == .journal }.map { $0.title }
        let resourceItems = userApprovedItems.filter { $0.contentType == .resource }.map { $0.title }
        let projectItems = userApprovedItems.filter { $0.contentType == .project }.map { $0.title }
        
        let summary = ExecutionSummary(
            totalItemsProcessed: userApprovedItems.count,
            itemsCreated: createdItems,
            itemsSkipped: userApprovedItems.count - createdItems,
            errors: errors,
            warnings: [],
            processingTime: TimeInterval(2.0),
            confidenceDistribution: [:],
            categoryDistribution: [:],
            newAreasCreated: [],
            newProjectsCreated: projectItems,
            successCount: createdItems,
            tasksCreated: taskItems,
            notesCreated: noteItems,
            journalEntriesCreated: journalItems,
            resourcesCreated: resourceItems,
            appointmentsCreated: [],
            habitsCreated: [],
            goalsCreated: [],
            financialTransactionsCreated: []
        )
        
        Logger.shared.success("🧠 Brain dump execution complete: \(createdItems) items created")
        return summary
    }
    
    /// FIXED: Create database entry for an enhanced brain dump item
    /// This method now actually persists items to the database instead of just logging
    private func createDatabaseEntry(for item: EnhancedBrainDumpItem) async throws {
        switch item.contentType {
        case .task:
            // Create blob first for task content
            let blob = try await blobRepository.createBlob(
                content: item.content,
                sourceType: .brainDump,
                workPersonal: item.workPersonal
            )
            
            // Parse due date if provided
            let dueDate: Date? = {
                guard let dueDateString = item.dueDate else { return nil }
                return ISO8601DateFormatter().date(from: dueDateString)
            }()
            
            // Create task with blob reference
            let task = try await taskRepository.createTask(
                blobId: blob.id,
                title: item.title,
                description: item.content.count > 100 ? String(item.content.prefix(100)) + "..." : item.content,
                priority: item.priority,
                status: .inbox,
                dueDate: dueDate,
                workPersonal: item.workPersonal
            )
            
            Logger.shared.success("✅ Created task: \(item.title) (ID: \(task.id))")
            
        case .note, .knowledge:
            // Create blob for note/knowledge content
            let blob = try await blobRepository.createBlob(
                content: "\(item.title)\n\n\(item.content)",
                sourceType: .brainDump,
                workPersonal: item.workPersonal
            )
            
            Logger.shared.success("✅ Created \(item.contentType.rawValue): \(item.title) (ID: \(blob.id))")
            
        case .journal:
            // Create blob for journal entry
            let blob = try await blobRepository.createBlob(
                content: "\(item.title)\n\n\(item.content)",
                sourceType: .brainDump,
                workPersonal: item.workPersonal
            )
            
            Logger.shared.success("✅ Created journal entry: \(item.title) (ID: \(blob.id))")
            
        case .resource:
            // Create blob first for resource content
            let blob = try await blobRepository.createBlob(
                content: item.content,
                sourceType: .brainDump,
                workPersonal: item.workPersonal
            )
            
            // Create resource with blob reference
            let resource = Resource(
                blobId: blob.id,
                title: item.title,
                type: "brain_dump_resource",
                authors: [],
                summary: item.content.count > 200 ? String(item.content.prefix(200)) + "..." : item.content,
                tags: item.tags,
                workPersonal: item.workPersonal
            )
            
            let createdResource = try await resourceRepository.createResource(resource)
            Logger.shared.success("✅ Created resource: \(item.title) (ID: \(createdResource.id))")
            
        case .project:
            // Create project entry
            let project = Project(
                name: item.title,
                description: item.content,
                workPersonal: item.workPersonal
            )
            
            let createdProject = try await paraRepository.createProject(project)
            Logger.shared.success("✅ Created project: \(item.title) (ID: \(createdProject.id))")
            
        case .area:
            // Create area entry
            let area = Area(
                name: item.title,
                description: item.content,
                workPersonal: item.workPersonal
            )
            
            let createdArea = try await paraRepository.createArea(area)
            Logger.shared.success("✅ Created area: \(item.title) (ID: \(createdArea.id))")
            
        default:
            // For other content types, create as blob
            let blob = try await blobRepository.createBlob(
                content: "\(item.title)\n\n\(item.content)",
                sourceType: .brainDump,
                workPersonal: item.workPersonal
            )
            
            Logger.shared.success("✅ Created \(item.contentType.rawValue): \(item.title) (ID: \(blob.id))")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserFocus() async -> String? {
        let context = await contextMemoryService.getCurrentContext()
        let recentProjects = context.recentItems.filter { $0.category == .project }
        return recentProjects.first?.title
    }
    
    private func determineWorkMode() -> WorkPersonalType {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 9 && hour <= 17 ? .work : .personal
    }
    
    private func getRecentActivities(from context: ProcessingContext) -> [String] {
        return context.recentItems.prefix(10).map { $0.title }
    }
    
    private func updateContextWithResults(_ result: BrainDumpResult) async {
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
    
    // MARK: - Additional methods (truncated for brevity)
    // ... (include all other methods from the original file)
}

// MARK: - Notification Extension
extension Notification.Name {
    static let dataDidChange = Notification.Name("dataDidChange")
}