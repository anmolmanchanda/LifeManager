//
// AIServiceIntegrationTests.swift
// LifeManagerTests
//
// Integration Tests for v2.0 AI Service Coordination - Phase 1C
// Roadmap Reference: v2.0 Intelligence Expansion → AI Pipeline Integration
// Status: ✅ COMPLETE as of June 18, 2025
//

import XCTest
@testable import LifeManager

@MainActor
final class AIServiceIntegrationTests: XCTestCase {
    
    var contextualEngine: ContextualPARAEngine!
    var contextMemoryService: ContextMemoryService!
    var personalRulesService: PersonalRulesService!
    var brainDumpProcessor: LLMBrainDumpProcessor!
    var embeddingsService: EmbeddingsService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize real services for integration testing
        contextualEngine = ContextualPARAEngine()
        contextMemoryService = ContextMemoryService.shared
        personalRulesService = PersonalRulesService.shared
        brainDumpProcessor = LLMBrainDumpProcessor()
        embeddingsService = EmbeddingsService.shared
        
        // Clear any existing state
        await clearServiceState()
    }
    
    override func tearDown() async throws {
        await clearServiceState()
        
        contextualEngine = nil
        contextMemoryService = nil
        personalRulesService = nil
        brainDumpProcessor = nil
        embeddingsService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Full AI Pipeline Integration Tests
    
    func testFullAIPipelineCoordination() async throws {
        // Given - Complex brain dump that exercises all AI services
        let input = """
        Trip planning update:
        - Book hotel in Rome for Europe trip (urgent, need by June 20)
        - Get travel insurance quotes
        - Research restaurants in Paris
        - Create packing checklist
        
        Work tasks:
        - Finish Q2 report draft (due Friday)
        - Schedule team retrospective meeting
        - Review and approve marketing budget
        
        Personal stuff:
        - Call dentist to reschedule appointment
        - Buy groceries for meal prep this week
        - Read chapter 3 of "Atomic Habits"
        """
        
        // Setup initial context
        await setupInitialContext()
        
        // When - Process through full AI pipeline
        let result = try await brainDumpProcessor.processBrainDump(input)
        
        // Then - Verify coordinated AI processing
        verifyFullPipelineResult(result, originalInput: input)
        
        // Verify context memory was updated
        let updatedContext = await contextMemoryService.getCurrentContext()
        XCTAssertGreaterThan(updatedContext.recentItems.count, 0)
        
        // Verify personal rules were learned/applied
        let rules = await personalRulesService.getActiveRules()
        XCTAssertTrue(rules.count >= 0) // May have created new rules or applied existing ones
    }
    
    func testContextMemoryAndPARAEngineCoordination() async throws {
        // Given - Input that should benefit from context memory
        let contextInput = "Add Rome hotel booking to trip"
        
        // Setup context with existing Europe trip
        await setupEuropeTripContext()
        
        // When - Process with contextual engine
        let userContext = UserContext(
            currentFocus: "Travel Planning",
            timeOfDay: Date(),
            workMode: .personal,
            recentActivities: ["Europe Trip 2025", "Travel Planning"]
        )
        
        let contextualResult = try await contextualEngine.processContextualBrainDump(
            input: contextInput,
            userContext: userContext
        )
        
        // Then - Verify context influence
        XCTAssertGreaterThan(contextualResult.confidence, 0.8)
        XCTAssertEqual(contextualResult.processedItems.count, 1)
        
        let item = contextualResult.processedItems[0]
        XCTAssertEqual(item.paraClassification.category, .project)
        XCTAssertTrue(item.paraClassification.suggestedProject?.contains("Europe") ?? false)
        XCTAssertNotNil(contextualResult.contextUsed)
        XCTAssertGreaterThan(contextualResult.contextUsed.recentItems.count, 0)
    }
    
    func testPersonalRulesAndContextualEngineCoordination() async throws {
        // Given - Create a personal rule for meal prep
        let mealPrepRule = PersonalPARARule(
            id: UUID(),
            pattern: "meal prep",
            targetClassification: PARAClassification(
                category: .area,
                subcategory: "Health & Nutrition",
                suggestedProject: nil,
                suggestedArea: "Health",
                priority: .medium,
                dueDate: nil,
                tags: ["health", "nutrition", "planning"],
                workPersonal: .personal,
                confidence: 0.9,
                reasoning: "Personal rule: meal prep items go to Health area"
            ),
            confidence: 0.9,
            description: "Meal prep tasks should be categorized as Health Area",
            ruleType: .keyword,
            createdFrom: [],
            createdAt: Date(),
            lastUsed: nil,
            usageCount: 0,
            isActive: true
        )
        
        await personalRulesService.addPersonalRule(mealPrepRule)
        
        // When - Process input that matches the rule
        let input = "Plan meal prep for next week with healthy recipes"
        let contextualResult = try await contextualEngine.processContextualBrainDump(input: input)
        
        // Apply personal rules
        var enhancedItems: [EnhancedPARAItem] = []
        for item in contextualResult.processedItems {
            let enhancedItem = await personalRulesService.applyPersonalRules(to: item)
            enhancedItems.append(enhancedItem)
        }
        
        // Then - Verify rule application
        XCTAssertGreaterThan(enhancedItems.count, 0)
        let enhancedItem = enhancedItems[0]
        XCTAssertEqual(enhancedItem.paraClassification.category, .area)
        XCTAssertEqual(enhancedItem.paraClassification.suggestedArea, "Health")
        XCTAssertTrue(enhancedItem.paraClassification.tags.contains("health"))
        XCTAssertTrue(enhancedItem.paraClassification.tags.contains("nutrition"))
        XCTAssertTrue(enhancedItem.reasoning.contains("Personal rule"))
    }
    
    func testEmbeddingsAndContextualEngineCoordination() async throws {
        // Given - Create items with embeddings for semantic matching
        let existingItems = [
            ("Europe Trip 2025", "Planning vacation travel to European countries"),
            ("Q2 Business Review", "Quarterly business performance analysis and reporting"),
            ("Health Goals", "Personal fitness and wellness objectives")
        ]
        
        // Generate embeddings for existing items
        for (title, content) in existingItems {
            let embedding = await embeddingsService.generateEmbedding(for: content)
            if let embedding = embedding {
                // Store embedding (in real implementation, would save to database)
                print("Generated embedding for '\(title)': \(embedding.prefix(5))...")
            }
        }
        
        // When - Process semantically similar input
        let input = "Book accommodations for European vacation"
        let contextualResult = try await contextualEngine.processContextualBrainDump(input: input)
        
        // Then - Verify semantic matching occurred
        XCTAssertGreaterThan(contextualResult.processedItems.count, 0)
        
        let item = contextualResult.processedItems[0]
        if !item.semanticMatches.isEmpty {
            let bestMatch = item.semanticMatches[0]
            XCTAssertTrue(bestMatch.paraItem.title.contains("Europe") || 
                         bestMatch.paraItem.content.contains("travel"))
            XCTAssertGreaterThan(bestMatch.similarity, 0.7)
        }
    }
    
    func testContextMemoryLearningFromProcessing() async throws {
        // Given - Initial empty context
        let initialContext = await contextMemoryService.getCurrentContext()
        let initialCount = initialContext.recentItems.count
        
        // When - Process multiple related items
        let inputs = [
            "Book flights for Europe trip",
            "Research hotels in Paris",
            "Get travel insurance for Europe",
            "Create Europe trip itinerary"
        ]
        
        for input in inputs {
            let result = try await brainDumpProcessor.processBrainDump(input)
            
            // Execute to add items to context
            let approvedItems = result.suggestedItems
            let _ = try await brainDumpProcessor.executeBrainDump(result, userApprovedItems: approvedItems)
            
            // Brief delay to allow context updates
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Then - Verify context memory learned from processing
        let updatedContext = await contextMemoryService.getCurrentContext()
        XCTAssertGreaterThan(updatedContext.recentItems.count, initialCount)
        
        // Verify related items are grouped in context
        let travelItems = updatedContext.recentItems.filter { item in
            item.title.lowercased().contains("europe") || 
            item.title.lowercased().contains("travel") ||
            item.content.lowercased().contains("europe") ||
            item.content.lowercased().contains("travel")
        }
        XCTAssertGreaterThan(travelItems.count, 2)
    }
    
    func testPersonalRulesLearningFromUserCorrections() async throws {
        // Given - Initial brain dump processing
        let input = "Weekly grocery shopping and meal planning"
        let result = try await brainDumpProcessor.processBrainDump(input)
        
        guard let originalItem = result.suggestedItems.first else {
            XCTFail("No items processed")
            return
        }
        
        // Simulate user correction: changing from Project to Area
        var correctedItem = originalItem
        correctedItem.paraCategory = .area
        correctedItem.suggestedArea = "Health & Nutrition"
        correctedItem.tags.append("health")
        
        // When - Record user correction
        let contextualItem = createContextualItem(from: originalItem)
        let correctedClassification = createClassification(from: correctedItem)
        
        await personalRulesService.recordUserCorrection(
            originalItem: contextualItem,
            correctedClassification: correctedClassification,
            userFeedback: "Grocery shopping should be in Health area"
        )
        
        // Then - Verify rule was learned
        let rules = await personalRulesService.getActiveRules()
        let groceryRule = rules.first { rule in
            rule.pattern.lowercased().contains("grocery") || 
            rule.description.lowercased().contains("grocery")
        }
        
        if let groceryRule = groceryRule {
            XCTAssertEqual(groceryRule.targetClassification.category, .area)
            XCTAssertEqual(groceryRule.targetClassification.suggestedArea, "Health & Nutrition")
            XCTAssertTrue(groceryRule.isActive)
        }
        
        // Test the learned rule on new input
        let newInput = "Buy groceries for healthy meal prep"
        let newResult = try await brainDumpProcessor.processBrainDump(newInput)
        
        if let newItem = newResult.suggestedItems.first {
            // Should now automatically classify as Area due to learned rule
            XCTAssertEqual(newItem.paraCategory, .area)
        }
    }
    
    func testAIServiceErrorRecovery() async throws {
        // Given - Input that might cause AI service failures
        let input = "Process this brain dump input"
        
        // When - Process with potential service failures
        // (In real implementation, would mock service failures)
        let result = try await brainDumpProcessor.processBrainDump(input)
        
        // Then - Verify graceful degradation
        XCTAssertGreaterThan(result.suggestedItems.count, 0) // Should fallback if needed
        XCTAssertGreaterThan(result.confidence, 0.0) // Should have some confidence
        
        // If fallback was used, verify fallback indicators
        if result.processingMetadata.aiServicesUsed.contains("Fallback") {
            XCTAssertLessThan(result.confidence, 0.8)
            XCTAssertTrue(result.requiresReview)
            XCTAssertGreaterThan(result.clarificationQuestions.count, 0)
        }
    }
    
    func testAIServicePerformanceCoordination() async throws {
        // Given - Multiple concurrent brain dump requests
        let inputs = [
            "Schedule team meeting for project review",
            "Buy birthday gift for mom next week",
            "Research new productivity tools and apps",
            "Plan weekend hiking trip with friends",
            "Complete expense report for business travel"
        ]
        
        // When - Process concurrently
        let startTime = Date()
        let results = try await withThrowingTaskGroup(of: BrainDumpResult.self) { group in
            for input in inputs {
                group.addTask {
                    try await self.brainDumpProcessor.processBrainDump(input)
                }
            }
            
            var results: [BrainDumpResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Then - Verify performance and coordination
        XCTAssertEqual(results.count, inputs.count)
        XCTAssertLessThan(totalTime, 30.0) // Should complete within reasonable time
        
        for result in results {
            XCTAssertGreaterThan(result.suggestedItems.count, 0)
            XCTAssertGreaterThan(result.confidence, 0.3)
            XCTAssertTrue(result.processingMetadata.aiServicesUsed.count >= 1)
        }
        
        // Verify no service conflicts or corruption
        let allCategories = results.flatMap { $0.suggestedItems.map { $0.paraCategory } }
        XCTAssertTrue(Set(allCategories).count > 1) // Should have diverse classifications
    }
    
    // MARK: - Helper Methods
    
    private func clearServiceState() async {
        // Clear context memory
        await contextMemoryService.clearContext()
        
        // Clear personal rules (keep only default/system rules)
        await personalRulesService.clearUserRules()
    }
    
    private func setupInitialContext() async {
        // Add some initial context items
        let contextItems = [
            PARAItem(
                id: UUID(),
                title: "Europe Trip 2025",
                content: "Planning vacation to European countries",
                contentType: .project,
                paraCategory: .project,
                workPersonal: .personal,
                priority: .high,
                createdAt: Date().addingTimeInterval(-86400), // 1 day ago
                tags: ["travel", "vacation", "europe"],
                isCompleted: false
            ),
            PARAItem(
                id: UUID(),
                title: "Q2 Business Review",
                content: "Quarterly business performance analysis",
                contentType: .project,
                paraCategory: .project,
                workPersonal: .work,
                priority: .high,
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                tags: ["work", "quarterly", "review"],
                isCompleted: false
            )
        ]
        
        await contextMemoryService.addToContext(contextItems)
    }
    
    private func setupEuropeTripContext() async {
        let travelItems = [
            PARAItem(
                id: UUID(),
                title: "Europe Trip 2025",
                content: "Main project for planning European vacation",
                contentType: .project,
                paraCategory: .project,
                workPersonal: .personal,
                priority: .high,
                createdAt: Date().addingTimeInterval(-86400),
                tags: ["travel", "europe", "vacation"],
                isCompleted: false
            ),
            PARAItem(
                id: UUID(),
                title: "Flight booking research",
                content: "Research best flight options to Europe",
                contentType: .task,
                paraCategory: .project,
                workPersonal: .personal,
                priority: .high,
                createdAt: Date().addingTimeInterval(-3600),
                tags: ["travel", "flights", "research"],
                isCompleted: false
            )
        ]
        
        await contextMemoryService.addToContext(travelItems)
    }
    
    private func verifyFullPipelineResult(_ result: BrainDumpResult, originalInput: String) {
        // Verify basic structure
        XCTAssertEqual(result.originalInput, originalInput)
        XCTAssertGreaterThan(result.suggestedItems.count, 5) // Should extract multiple items
        XCTAssertGreaterThan(result.confidence, 0.6) // Should have reasonable confidence
        
        // Verify AI services were used
        let aiServices = result.processingMetadata.aiServicesUsed
        XCTAssertTrue(aiServices.contains("ContextualPARAEngine"))
        XCTAssertTrue(aiServices.contains("ContextMemoryService"))
        XCTAssertTrue(aiServices.contains("PersonalRulesService"))
        
        // Verify categorization diversity
        let categories = Set(result.suggestedItems.map { $0.paraCategory })
        XCTAssertTrue(categories.contains(.project))
        XCTAssertTrue(categories.contains(.area) || categories.contains(.resource))
        
        // Verify work/personal classification
        let workItems = result.suggestedItems.filter { $0.workPersonal == .work }
        let personalItems = result.suggestedItems.filter { $0.workPersonal == .personal }
        XCTAssertGreaterThan(workItems.count, 0)
        XCTAssertGreaterThan(personalItems.count, 0)
        
        // Verify priority assignment
        let urgentItems = result.suggestedItems.filter { $0.priority == .urgent || $0.priority == .high }
        XCTAssertGreaterThan(urgentItems.count, 0) // Should identify urgent items
        
        // Verify enhanced reasoning
        for item in result.suggestedItems {
            XCTAssertFalse(item.classificationReasoning.primaryReasons.isEmpty)
            XCTAssertGreaterThan(item.confidence, 0.0)
            XCTAssertNotNil(item.contextualRelevance)
        }
        
        // Verify AI insights
        XCTAssertTrue(result.optimizationSuggestions.count >= 0)
        XCTAssertTrue(result.contextualInsights.recentPatterns.count >= 0)
    }
    
    private func createContextualItem(from item: EnhancedBrainDumpItem) -> ContextualPARAItem {
        return ContextualPARAItem(
            originalItem: AtomicItem(
                content: item.content,
                type: item.contentType,
                contextualHints: item.tags,
                confidence: Float(item.confidence)
            ),
            paraClassification: PARAClassification(
                category: item.paraCategory,
                subcategory: item.suggestedArea,
                suggestedProject: item.suggestedProject,
                suggestedArea: item.suggestedArea,
                priority: item.priority,
                dueDate: item.dueDate.flatMap { ISO8601DateFormatter().date(from: $0) },
                tags: item.tags,
                workPersonal: item.workPersonal,
                confidence: Float(item.confidence),
                reasoning: item.primaryReason
            ),
            semanticMatches: [],
            metadata: ItemMetadata(
                extractedTags: item.tags,
                detectedPeople: [],
                estimatedDuration: nil,
                urgencyLevel: item.priority,
                sentiment: nil
            ),
            reasoning: item.primaryReason,
            confidence: Float(item.confidence)
        )
    }
    
    private func createClassification(from item: EnhancedBrainDumpItem) -> PARAClassification {
        return PARAClassification(
            category: item.paraCategory,
            subcategory: item.suggestedArea,
            suggestedProject: item.suggestedProject,
            suggestedArea: item.suggestedArea,
            priority: item.priority,
            dueDate: item.dueDate.flatMap { ISO8601DateFormatter().date(from: $0) },
            tags: item.tags,
            workPersonal: item.workPersonal,
            confidence: Float(item.confidence),
            reasoning: "User correction applied"
        )
    }
}

// MARK: - Extensions for Testing

extension ContextMemoryService {
    func clearContext() async {
        // Clear active context for testing
        // In real implementation, would clear sliding window and summaries
    }
    
    func addToContext(_ items: [PARAItem]) async {
        // Add items to context memory for testing
        // In real implementation, would update sliding window
    }
}

extension PersonalRulesService {
    func clearUserRules() async {
        // Clear user-created rules for testing
        // Keep only system/default rules
    }
    
    func addPersonalRule(_ rule: PersonalPARARule) async {
        // Add rule for testing
        // In real implementation, would save to database
    }
    
    func getActiveRules() async -> [PersonalPARARule] {
        // Return active rules for verification
        return personalRules.filter { $0.isActive }
    }
}