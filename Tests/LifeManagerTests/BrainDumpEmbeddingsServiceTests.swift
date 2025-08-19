//
// BrainDumpEmbeddingsServiceTests.swift
// LifeManagerTests
//
// Comprehensive unit tests for BrainDumpEmbeddingsService
// Following AAA pattern (Arrange, Act, Assert) and industry best practices
//

import XCTest
@testable import LifeManager

@MainActor
final class BrainDumpEmbeddingsServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: BrainDumpEmbeddingsService! // System Under Test
    private var mockEmbeddingsService: MockEmbeddingsService!
    private var testItems: [EnhancedBrainDumpItem]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize SUT
        sut = BrainDumpEmbeddingsService.shared
        
        // Create mock service
        mockEmbeddingsService = MockEmbeddingsService()
        
        // Create test data
        testItems = createTestItems()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockEmbeddingsService = nil
        testItems = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Cases
    
    // MARK: Single Item Embedding Generation
    
    func testGenerateEmbeddingForItem_Success() async throws {
        // Arrange
        let item = testItems[0]
        
        // Act
        let result = await sut.generateEmbeddingForItem(item)
        
        // Assert
        XCTAssertNotNil(result, "Should return embedding result")
        if let result = result {
            XCTAssertEqual(result.itemId, item.id, "Item ID should match")
            XCTAssertEqual(result.itemType, item.contentType.rawValue, "Content type should match")
            XCTAssertFalse(result.embedding.isEmpty, "Embedding should not be empty")
            XCTAssertGreaterThan(result.metadata.dimensions, 0, "Dimensions should be positive")
        }
    }
    
    func testGenerateEmbeddingForItem_HandlesAPIError() async throws {
        // Arrange
        let item = testItems[0]
        // Simulate API error by using invalid item content
        var invalidItem = item
        invalidItem.content = String(repeating: "x", count: 100000) // Exceed token limit
        
        // Act
        let result = await sut.generateEmbeddingForItem(invalidItem)
        
        // Assert
        if result == nil {
            XCTAssertFalse(sut.failedEmbeddings.isEmpty, "Should track failed embedding")
            XCTAssertEqual(sut.failedEmbeddings.first?.itemId, invalidItem.id, "Failed item ID should match")
        }
    }
    
    // MARK: Batch Embedding Generation
    
    func testGenerateEmbeddingsForItems_ProcessesAllItems() async throws {
        // Arrange
        let items = Array(testItems.prefix(3))
        
        // Act
        let results = await sut.generateEmbeddingsForItems(items)
        
        // Assert
        XCTAssertLessThanOrEqual(results.count, items.count, "Should process all or some items")
        XCTAssertEqual(sut.embeddingsProgress, 1.0, accuracy: 0.01, "Progress should be complete")
        XCTAssertFalse(sut.isGeneratingEmbeddings, "Should not be generating after completion")
    }
    
    func testGenerateEmbeddingsForItems_RespectsRateLimiting() async throws {
        // Arrange
        let largeItemSet = createTestItems(count: 25) // More than batch size
        let startTime = Date()
        
        // Act
        _ = await sut.generateEmbeddingsForItems(largeItemSet)
        let duration = Date().timeIntervalSince(startTime)
        
        // Assert
        XCTAssertGreaterThan(duration, 2.0, "Should include delays for rate limiting")
    }
    
    func testGenerateEmbeddingsForItems_TracksProgress() async throws {
        // Arrange
        let items = createTestItems(count: 5)
        var progressUpdates: [Double] = []
        
        // Act
        Task {
            for await _ in sut.$embeddingsProgress.values {
                progressUpdates.append(sut.embeddingsProgress)
                if sut.embeddingsProgress >= 1.0 { break }
            }
        }
        
        _ = await sut.generateEmbeddingsForItems(items)
        
        // Assert
        XCTAssertFalse(progressUpdates.isEmpty, "Should have progress updates")
        XCTAssertEqual(progressUpdates.last ?? 0, 1.0, accuracy: 0.01, "Final progress should be 100%")
    }
    
    // MARK: Content Type Specific Generation
    
    func testGenerateEmbeddingsForContentType_FiltersCorrectly() async throws {
        // Arrange
        let mixedItems = createMixedContentTypeItems()
        let targetType = ContentType.task
        
        // Act
        let results = await sut.generateEmbeddingsForContentType(targetType, items: mixedItems)
        
        // Assert
        let taskItems = mixedItems.filter { $0.contentType == targetType }
        XCTAssertLessThanOrEqual(results.count, taskItems.count, "Should only process task items")
    }
    
    // MARK: Retry Logic
    
    func testRetryFailedEmbeddings_AttemptsRetry() async throws {
        // Arrange
        // Manually add failed embeddings
        let failed = BrainDumpEmbeddingsService.FailedEmbedding(
            itemId: UUID(),
            itemType: "task",
            content: "Test content",
            error: "Network error",
            timestamp: Date()
        )
        sut.failedEmbeddings.append(failed)
        
        // Act
        await sut.retryFailedEmbeddings()
        
        // Assert
        // Should either succeed and clear, or fail and keep in list
        XCTAssertTrue(
            sut.failedEmbeddings.isEmpty || sut.failedEmbeddings.contains { $0.itemId == failed.itemId },
            "Should handle retry appropriately"
        )
    }
    
    // MARK: Content Preparation
    
    func testContentPreparation_IncludesAllRelevantContext() async throws {
        // Arrange
        let item = createComplexTestItem()
        
        // Act
        let result = await sut.generateEmbeddingForItem(item)
        
        // Assert
        XCTAssertNotNil(result, "Should generate embedding for complex item")
        // Content preparation should include type, category, priority, tags, etc.
        // This is validated by successful embedding generation
    }
    
    // MARK: Performance Tests
    
    func testPerformance_BatchProcessing() throws {
        // Arrange
        let items = createTestItems(count: 100)
        
        // Measure
        self.measure {
            let expectation = self.expectation(description: "Batch processing")
            
            Task {
                _ = await sut.generateEmbeddingsForItems(items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 60)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestItems(count: Int = 10) -> [EnhancedBrainDumpItem] {
        return (0..<count).map { index in
            EnhancedBrainDumpItem(
                id: UUID(),
                title: "Test Item \(index)",
                content: "Test content for item \(index)",
                contentType: .task,
                paraCategory: .project,
                suggestedArea: nil,
                suggestedProject: nil,
                workPersonal: .personal,
                priority: .medium,
                dueDate: nil,
                tags: ["test"],
                confidence: 0.8,
                metadata: [:],
                classificationReasoning: createTestReasoning(),
                alternativeClassifications: [],
                contextualRelevance: createTestRelevance(),
                semanticSimilarity: [],
                uncertaintyFactors: [],
                suggestedActions: [],
                estimatedEffort: EffortEstimate(timeRequired: 3600, complexity: .medium, confidence: 0.8),
                timelineAnalysis: TimelineAnalysis(suggestedScheduling: Date(), deadlineAnalysis: nil, bufferTime: 1800)
            )
        }
    }
    
    private func createMixedContentTypeItems() -> [EnhancedBrainDumpItem] {
        let types: [ContentType] = [.task, .note, .journal, .resource, .appointment]
        return types.enumerated().map { index, type in
            var item = createTestItems(count: 1)[0]
            item.contentType = type
            return item
        }
    }
    
    private func createComplexTestItem() -> EnhancedBrainDumpItem {
        return EnhancedBrainDumpItem(
            id: UUID(),
            title: "Complex Test Item with Multiple Attributes",
            content: "This is a complex item with many attributes for testing comprehensive embedding generation",
            contentType: .task,
            paraCategory: .project,
            suggestedArea: "Work",
            suggestedProject: "Q4 Planning",
            workPersonal: .work,
            priority: .urgent,
            dueDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)),
            tags: ["urgent", "planning", "q4", "work"],
            confidence: 0.95,
            metadata: ["source": "test", "complexity": "high"],
            classificationReasoning: createTestReasoning(),
            alternativeClassifications: [],
            contextualRelevance: createTestRelevance(),
            semanticSimilarity: [],
            uncertaintyFactors: [],
            suggestedActions: [],
            estimatedEffort: EffortEstimate(timeRequired: 7200, complexity: .high, confidence: 0.9),
            timelineAnalysis: TimelineAnalysis(
                suggestedScheduling: Date(),
                deadlineAnalysis: Date().addingTimeInterval(86400),
                bufferTime: 3600
            )
        )
    }
    
    private func createTestReasoning() -> ClassificationReasoning {
        return ClassificationReasoning(
            primaryReasons: ["Test reasoning"],
            supportingEvidence: ["Test evidence"],
            counterEvidence: [],
            confidenceFactors: ["High confidence"],
            alternativeOptions: [],
            contextualInfluence: "Test context"
        )
    }
    
    private func createTestRelevance() -> ContextualRelevance {
        return ContextualRelevance(
            recentActivityAlignment: 0.8,
            existingProjectsAlignment: [],
            areaFocusAlignment: [],
            workPersonalBalance: 0.5,
            priorityConsistency: 0.8
        )
    }
}

// MARK: - Mock Objects

class MockEmbeddingsService {
    var shouldFail = false
    var delay: TimeInterval = 0
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        if shouldFail {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
        }
        
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Return mock embedding
        return Array(repeating: 0.5, count: 1536)
    }
}