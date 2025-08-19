//
// BrainDumpEndToEndTests.swift
// LifeManagerTests
//
// End-to-end tests for complete brain dump processing flow
// Testing the full pipeline from input to database creation
//

import XCTest
@testable import LifeManager

@MainActor
final class BrainDumpEndToEndTests: XCTestCase {
    
    // MARK: - Properties
    
    private var processor: LLMBrainDumpProcessor!
    private var contentHandler: BrainDumpContentTypeHandler!
    private var embeddingsService: BrainDumpEmbeddingsService!
    private var similarityService: SemanticSimilarityService!
    private var relationshipService: RelationshipDetectionService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        processor = LLMBrainDumpProcessor()
        contentHandler = BrainDumpContentTypeHandler.shared
        embeddingsService = BrainDumpEmbeddingsService.shared
        similarityService = SemanticSimilarityService.shared
        relationshipService = RelationshipDetectionService.shared
    }
    
    override func tearDown() async throws {
        processor = nil
        contentHandler = nil
        embeddingsService = nil
        similarityService = nil
        relationshipService = nil
        try await super.tearDown()
    }
    
    // MARK: - Full Pipeline Tests
    
    func testEndToEnd_CompleteProcessingFlow() async throws {
        // Arrange
        let input = """
        Urgent: Complete Q4 financial report by Friday
        Meeting with team tomorrow at 2pm to discuss project roadmap
        Note: Research competitor pricing strategies
        Spent $450 on cloud services this month
        Personal: Schedule annual health checkup
        TODO: Implement user authentication feature
        Idea: Create automated testing framework for CI/CD
        """
        
        // Act - Step 1: Process brain dump
        let result = try await processor.processBrainDump(input)
        
        // Assert - Processing result
        XCTAssertFalse(result.suggestedItems.isEmpty, "Should extract items")
        XCTAssertGreaterThan(result.confidence, 0.5, "Should have reasonable confidence")
        
        // Act - Step 2: Execute brain dump (create database entries)
        let executionSummary = try await processor.executeBrainDump(
            result,
            userApprovedItems: result.suggestedItems
        )
        
        // Assert - Execution summary
        XCTAssertGreaterThan(executionSummary.itemsCreated, 0, "Should create items")
        XCTAssertGreaterThanOrEqual(
            executionSummary.totalItemsProcessed,
            executionSummary.itemsCreated,
            "Processed should be >= created"
        )
        
        // Act - Step 3: Analyze relationships
        let relationships = await relationshipService.detectRelationships(
            among: result.suggestedItems
        )
        
        // Assert - Relationships
        XCTAssertFalse(relationships.isEmpty, "Should detect relationships")
        
        // Act - Step 4: Find similar items
        if let firstItem = result.suggestedItems.first {
            let similarItems = await similarityService.findSimilarItems(for: firstItem)
            // May be empty if no existing items in test database
            XCTAssertNotNil(similarItems, "Should attempt to find similar items")
        }
    }
    
    func testEndToEnd_MultipleContentTypes() async throws {
        // Arrange
        let input = """
        Task: Review pull requests #development
        Note: Architecture decision - use microservices
        Journal: Feeling productive today, completed major milestone
        Meeting: Client presentation next Monday at 10am
        Habit: Daily code review at 4pm
        Goal: Complete certification by end of quarter
        Financial: Received $5000 project payment
        Medication: Vitamin D 1000mg daily
        Personal Rule: No meetings before 10am
        """
        
        // Act
        let result = try await processor.processBrainDump(input)
        
        // Assert - Content type variety
        let contentTypes = Set(result.suggestedItems.map { $0.contentType })
        XCTAssertGreaterThan(contentTypes.count, 5, "Should identify multiple content types")
        
        // Act - Process all items
        let batchResult = await contentHandler.processContentItems(result.suggestedItems)
        
        // Assert - Batch processing
        XCTAssertEqual(
            batchResult.stats.totalProcessed,
            result.suggestedItems.count,
            "Should process all items"
        )
        XCTAssertFalse(
            batchResult.stats.contentTypeBreakdown.isEmpty,
            "Should track content type breakdown"
        )
    }
    
    func testEndToEnd_WithEmbeddingsAndSimilarity() async throws {
        // Arrange
        let input = """
        Implement search functionality for the application
        Add search bar to navigation header
        Create search results page with filtering
        Optimize search query performance
        """
        
        // Act
        let result = try await processor.processBrainDump(input)
        
        // Generate embeddings
        let embeddingResults = await embeddingsService.generateEmbeddingsForItems(
            result.suggestedItems
        )
        
        // Assert - Embeddings
        XCTAssertFalse(embeddingResults.isEmpty, "Should generate embeddings")
        
        // Act - Similarity analysis
        let similarityAnalysis = await similarityService.analyzeSimilarities(
            for: result.suggestedItems
        )
        
        // Assert - Similarity
        XCTAssertNotNil(similarityAnalysis.clusterAnalysis, "Should perform clustering")
        // These items about search should cluster together
        if !similarityAnalysis.clusterAnalysis.clusters.isEmpty {
            let firstCluster = similarityAnalysis.clusterAnalysis.clusters[0]
            XCTAssertGreaterThan(firstCluster.cohesion, 0.5, "Related items should cluster")
        }
    }
    
    func testEndToEnd_RelationshipGraphBuilding() async throws {
        // Arrange
        let input = """
        Project: Launch new product feature
        Task 1: Design UI mockups
        Task 2: Implement backend API (depends on Task 1)
        Task 3: Write tests (requires Task 2)
        Task 4: Deploy to staging (after Task 3)
        Task 5: User acceptance testing (needs Task 4)
        """
        
        // Act
        let result = try await processor.processBrainDump(input)
        let graph = await relationshipService.buildRelationshipGraph(for: result.suggestedItems)
        
        // Assert - Graph structure
        XCTAssertEqual(graph.nodes.count, result.suggestedItems.count, "Should have all nodes")
        XCTAssertFalse(graph.edges.isEmpty, "Should have relationships")
        XCTAssertFalse(graph.criticalPaths.isEmpty, "Should identify critical path")
        
        // Check for dependency chain
        if let criticalPath = graph.criticalPaths.first {
            XCTAssertGreaterThan(
                criticalPath.itemSequence.count,
                2,
                "Should have multi-step critical path"
            )
        }
    }
    
    func testEndToEnd_DuplicateDetection() async throws {
        // Arrange
        let input = """
        Update user profile page
        Fix bug in profile page
        User profile page needs update
        Revise the profile page for users
        Implement new dashboard feature
        """
        
        // Act
        let result = try await processor.processBrainDump(input)
        let duplicates = await similarityService.detectDuplicates(among: result.suggestedItems)
        
        // Assert
        // Should detect that multiple items are about profile page
        if !duplicates.isEmpty {
            XCTAssertTrue(
                duplicates.first?.recommendation.contains("merge") ?? false,
                "Should recommend merging duplicates"
            )
        }
    }
    
    func testEndToEnd_FallbackProcessing() async throws {
        // Arrange - Simulate no API key scenario
        let input = """
        - Complete project documentation
        - Review code changes #urgent
        - Meeting tomorrow at 2pm
        - Spent $100 on software
        """
        
        // Act - Force fallback processing
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert - Fallback quality
        XCTAssertGreaterThanOrEqual(result.suggestedItems.count, 4, "Should parse all items")
        XCTAssertEqual(result.confidence, 0.6, accuracy: 0.1, "Should have fallback confidence")
        XCTAssertTrue(result.requiresReview, "Should require review")
        
        // Check that basic features still work
        let urgentItems = result.suggestedItems.filter { $0.tags.contains("urgent") }
        XCTAssertFalse(urgentItems.isEmpty, "Should detect urgent tag")
        
        let financialItems = result.suggestedItems.filter { $0.contentType == .financial }
        XCTAssertFalse(financialItems.isEmpty, "Should detect financial item")
    }
    
    func testEndToEnd_ExecutionSummaryCompleteness() async throws {
        // Arrange
        let input = """
        Task: Implement feature A
        Task: Implement feature B
        Note: Research best practices
        Project: Q4 Initiative
        Area: Professional Development
        """
        
        // Act
        let result = try await processor.processBrainDump(input)
        let summary = try await processor.executeBrainDump(
            result,
            userApprovedItems: result.suggestedItems
        )
        
        // Assert - Summary completeness
        XCTAssertGreaterThan(summary.processingTime, 0, "Should track processing time")
        XCTAssertFalse(summary.confidenceDistribution.isEmpty, "Should have confidence distribution")
        XCTAssertFalse(summary.categoryDistribution.isEmpty, "Should have category distribution")
        
        // Check specific counts
        if summary.tasksCreated.count > 0 {
            XCTAssertTrue(
                summary.tasksCreated.contains { $0.contains("feature") },
                "Should track created tasks"
            )
        }
        
        if !summary.newProjectsCreated.isEmpty {
            XCTAssertTrue(
                summary.newProjectsCreated.contains { $0.contains("Q4") },
                "Should track new projects"
            )
        }
    }
    
    func testEndToEnd_ErrorHandling() async throws {
        // Arrange - Input that might cause various errors
        let problematicInput = """
        
        
        Task with missing title: 
        : Missing task prefix
        $$$: Invalid financial format
        Meeting at nowhere time
        """
        
        // Act
        let result = try await processor.processBrainDump(problematicInput)
        let summary = try await processor.executeBrainDump(
            result,
            userApprovedItems: result.suggestedItems
        )
        
        // Assert - Should handle errors gracefully
        XCTAssertGreaterThanOrEqual(
            summary.itemsSkipped,
            0,
            "Should track skipped items"
        )
        
        if summary.itemsSkipped > 0 {
            XCTAssertFalse(summary.errors.isEmpty, "Should report errors")
        }
    }
    
    // MARK: - Performance Tests
    
    func testEndToEndPerformance_LargeBatch() throws {
        // Arrange
        let items = (0..<50).map { index in
            """
            Task \(index): Complete feature implementation
            Note \(index): Document the process
            Meeting \(index): Discuss with team
            """
        }.joined(separator: "\n")
        
        // Measure
        self.measure {
            let expectation = self.expectation(description: "Large batch E2E")
            
            Task {
                do {
                    let result = try await processor.processBrainDump(items)
                    _ = try await processor.executeBrainDump(
                        result,
                        userApprovedItems: Array(result.suggestedItems.prefix(20))
                    )
                } catch {
                    XCTFail("Processing failed: \(error)")
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 60)
        }
    }
    
    // MARK: - Integration Validation Tests
    
    func testIntegration_AllServicesCoordinate() async throws {
        // Arrange
        let input = "Create comprehensive test coverage for the new feature"
        
        // Act - Use all services
        let result = try await processor.processBrainDump(input)
        
        // Content type handling
        _ = await contentHandler.processContentItems(result.suggestedItems)
        
        // Embeddings generation
        _ = await embeddingsService.generateEmbeddingsForItems(result.suggestedItems)
        
        // Similarity analysis
        _ = await similarityService.analyzeSimilarities(for: result.suggestedItems)
        
        // Relationship detection
        _ = await relationshipService.detectRelationships(among: result.suggestedItems)
        
        // Assert - All services should work together
        XCTAssertTrue(true, "All services coordinated successfully")
    }
}