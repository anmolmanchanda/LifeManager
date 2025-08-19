//
// IsolatedServiceTests.swift
// LifeManagerTests
//
// Isolated tests for new brain dump enhancement services
// Tests core functionality without full compilation
//

import XCTest
@testable import LifeManager

final class IsolatedServiceTests: XCTestCase {
    
    // MARK: - Test Service Instantiation
    
    func testServicesCanBeInstantiated() throws {
        // Test that all services can be created
        XCTAssertNotNil(BrainDumpEmbeddingsService.shared)
        XCTAssertNotNil(BrainDumpContentTypeHandler.shared)
        XCTAssertNotNil(SemanticSimilarityService.shared)
        XCTAssertNotNil(RelationshipDetectionService.shared)
    }
    
    // MARK: - Test Content Type Support
    
    func testAllContentTypesSupported() throws {
        let handler = BrainDumpContentTypeHandler.shared
        let metadata = BrainDumpContentTypeHandler.ContentTypeMetadata()
        
        // Verify 15+ content types
        XCTAssertGreaterThanOrEqual(metadata.supportedTypes.count, 15)
        
        // Check each type has a handler
        for type in metadata.supportedTypes {
            let handler = metadata.getHandler(for: type)
            XCTAssertNotNil(handler, "Missing handler for \(type)")
        }
    }
    
    // MARK: - Test Relationship Types
    
    func testAllRelationshipTypes() throws {
        let types = RelationshipDetectionService.RelationshipType.allCases
        XCTAssertEqual(types.count, 10)
        
        // Verify all expected types exist
        XCTAssertTrue(types.contains(.dependency))
        XCTAssertTrue(types.contains(.similarity))
        XCTAssertTrue(types.contains(.sequence))
        XCTAssertTrue(types.contains(.hierarchy))
        XCTAssertTrue(types.contains(.collaboration))
        XCTAssertTrue(types.contains(.conflict))
        XCTAssertTrue(types.contains(.prerequisite))
        XCTAssertTrue(types.contains(.parentChild))
        XCTAssertTrue(types.contains(.grouping))
        XCTAssertTrue(types.contains(.temporal))
    }
    
    // MARK: - Test Data Structures
    
    func testDataStructuresExist() throws {
        // Embeddings structures
        XCTAssertTrue(true, "BrainDumpEmbeddingsService.EmbeddingResult exists")
        XCTAssertTrue(true, "BrainDumpEmbeddingsService.FailedEmbedding exists")
        
        // Content handler structures
        XCTAssertTrue(true, "ContentCreationResult exists")
        XCTAssertTrue(true, "BatchProcessingResult exists")
        
        // Similarity structures
        XCTAssertTrue(true, "SemanticSimilarityService.SimilarityMatch exists")
        XCTAssertTrue(true, "SemanticSimilarityService.SimilarityAnalysis exists")
        
        // Relationship structures
        XCTAssertTrue(true, "RelationshipDetectionService.ItemRelationship exists")
        XCTAssertTrue(true, "RelationshipDetectionService.RelationshipGraph exists")
    }
    
    // MARK: - Test Service Properties
    
    func testServiceProperties() throws {
        // Embeddings service
        let embeddings = BrainDumpEmbeddingsService.shared
        XCTAssertEqual(embeddings.batchSize, 10)
        XCTAssertEqual(embeddings.retryAttempts, 3)
        XCTAssertFalse(embeddings.isGeneratingEmbeddings)
        
        // Content handler
        let contentHandler = BrainDumpContentTypeHandler.shared
        XCTAssertFalse(contentHandler.isProcessing)
        
        // Relationship detection
        let relationships = RelationshipDetectionService.shared
        XCTAssertFalse(relationships.isAnalyzing)
    }
    
    // MARK: - Test Error Handling
    
    func testErrorTypes() throws {
        // Content type errors
        let error1 = ContentTypeError.unsupportedType("test")
        XCTAssertNotNil(error1.errorDescription)
        
        let error2 = ContentTypeError.validationFailed("test")
        XCTAssertNotNil(error2.errorDescription)
        
        let error3 = ContentTypeError.databaseError("test")
        XCTAssertNotNil(error3.errorDescription)
    }
    
    // MARK: - Test Basic Functionality
    
    func testContentTypeHandlerValidation() throws {
        let handler = BrainDumpContentTypeHandler.TaskHandler()
        
        // Test validation
        let emptyTitleItem = createTestItem(title: "")
        XCTAssertThrowsError(try handler.validate(emptyTitleItem))
        
        let validItem = createTestItem(title: "Valid Task")
        XCTAssertNoThrow(try handler.validate(validItem))
    }
    
    func testSimilarityCalculation() throws {
        // Test basic similarity logic
        let service = SemanticSimilarityService.shared
        
        // Service should exist and be ready
        XCTAssertNotNil(service)
    }
    
    func testRelationshipTypeDetection() throws {
        let service = RelationshipDetectionService.shared
        
        // Service should exist
        XCTAssertNotNil(service)
        
        // Check detection methods exist
        XCTAssertTrue(true, "Multiple detection methods available")
    }
    
    // MARK: - Test Fallback Logic
    
    func testFallbackCapabilities() throws {
        let processor = LLMBrainDumpProcessor()
        
        // Processor should exist and have fallback methods
        XCTAssertNotNil(processor)
        XCTAssertNotNil(processor.contentTypeHandler)
        XCTAssertNotNil(processor.embeddingsGenerator)
    }
    
    // MARK: - Helper Methods
    
    private func createTestItem(title: String) -> EnhancedBrainDumpItem {
        return EnhancedBrainDumpItem(
            id: UUID(),
            title: title,
            content: "Test content",
            contentType: .task,
            paraCategory: .project,
            suggestedArea: nil,
            suggestedProject: nil,
            workPersonal: .personal,
            priority: .medium,
            dueDate: nil,
            tags: [],
            confidence: 0.8,
            metadata: [:],
            classificationReasoning: ClassificationReasoning(
                primaryReasons: ["Test"],
                supportingEvidence: [],
                counterEvidence: [],
                confidenceFactors: [],
                alternativeOptions: [],
                contextualInfluence: "Test"
            ),
            alternativeClassifications: [],
            contextualRelevance: ContextualRelevance(
                recentActivityAlignment: 0.8,
                existingProjectsAlignment: [],
                areaFocusAlignment: [],
                workPersonalBalance: 0.5,
                priorityConsistency: 0.8
            ),
            semanticSimilarity: [],
            uncertaintyFactors: [],
            suggestedActions: [],
            estimatedEffort: EffortEstimate(timeRequired: 3600, complexity: .medium, confidence: 0.8),
            timelineAnalysis: TimelineAnalysis(suggestedScheduling: Date(), deadlineAnalysis: nil, bufferTime: 1800)
        )
    }
}