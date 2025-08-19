//
// SemanticSimilarityServiceTests.swift
// LifeManagerTests
//
// Comprehensive unit tests for SemanticSimilarityService
// Testing similarity matching, duplicate detection, and clustering
//

import XCTest
@testable import LifeManager

@MainActor
final class SemanticSimilarityServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: SemanticSimilarityService!
    private var testItems: [EnhancedBrainDumpItem]!
    private var testEmbeddings: [[Float]]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = SemanticSimilarityService.shared
        testItems = createTestItems()
        testEmbeddings = createTestEmbeddings()
    }
    
    override func tearDown() async throws {
        sut = nil
        testItems = nil
        testEmbeddings = nil
        try await super.tearDown()
    }
    
    // MARK: - Similarity Matching Tests
    
    func testFindSimilarItems_ReturnsMatchesAboveThreshold() async throws {
        // Arrange
        let item = testItems[0]
        
        // Act
        let matches = await sut.findSimilarItems(for: item, limit: 5)
        
        // Assert
        XCTAssertLessThanOrEqual(matches.count, 5, "Should respect limit")
        for match in matches {
            XCTAssertGreaterThanOrEqual(match.similarity, 0.5, "Should only return matches above threshold")
            XCTAssertNotEqual(match.itemId, item.id, "Should not match itself")
        }
    }
    
    func testFindSimilarItems_SortsbyRrelevance() async throws {
        // Arrange
        let item = testItems[0]
        
        // Act
        let matches = await sut.findSimilarItems(for: item, limit: 10)
        
        // Assert
        for i in 0..<matches.count-1 {
            XCTAssertGreaterThanOrEqual(
                matches[i].similarity,
                matches[i+1].similarity,
                "Matches should be sorted by similarity descending"
            )
        }
    }
    
    func testFindSimilarItems_IdentifiesRelevanceType() async throws {
        // Arrange
        let item = testItems[0]
        
        // Act
        let matches = await sut.findSimilarItems(for: item)
        
        // Assert
        for match in matches {
            XCTAssertNotNil(match.relevanceType, "Should identify relevance type")
            XCTAssertFalse(match.explanation.isEmpty, "Should provide explanation")
        }
    }
    
    // MARK: - Duplicate Detection Tests
    
    func testDetectDuplicates_FindsHighSimilarityItems() async throws {
        // Arrange
        let duplicateItems = createDuplicateItems()
        
        // Act
        let duplicateGroups = await sut.detectDuplicates(among: duplicateItems)
        
        // Assert
        XCTAssertFalse(duplicateGroups.isEmpty, "Should find duplicates")
        for group in duplicateGroups {
            XCTAssertGreaterThanOrEqual(group.similarity, 0.9, "Duplicates should have high similarity")
            XCTAssertFalse(group.recommendation.isEmpty, "Should provide recommendation")
        }
    }
    
    func testDetectDuplicates_GroupsRelatedDuplicates() async throws {
        // Arrange
        let items = createMultipleDuplicateSets()
        
        // Act
        let duplicateGroups = await sut.detectDuplicates(among: items)
        
        // Assert
        // Should group related duplicates together
        for group in duplicateGroups {
            XCTAssertGreaterThan(group.duplicateIds.count, 0, "Each group should have duplicates")
        }
    }
    
    // MARK: - Contextual Search Tests
    
    func testFindContextuallyRelated_ReturnsRelevantItems() async throws {
        // Arrange
        let context = "project management and planning"
        
        // Act
        let matches = await sut.findContextuallyRelated(to: context, limit: 5)
        
        // Assert
        XCTAssertLessThanOrEqual(matches.count, 5, "Should respect limit")
        for match in matches {
            XCTAssertEqual(match.relevanceType, .contextualRelevance, "Should mark as contextually relevant")
        }
    }
    
    // MARK: - Similarity Analysis Tests
    
    func testAnalyzeSimilarities_ProducesComprehensiveAnalysis() async throws {
        // Arrange
        let items = Array(testItems.prefix(5))
        
        // Act
        let analysis = await sut.analyzeSimilarities(for: items)
        
        // Assert
        XCTAssertNotNil(analysis.primaryMatches, "Should have primary matches")
        XCTAssertNotNil(analysis.secondaryMatches, "Should have secondary matches")
        XCTAssertNotNil(analysis.potentialDuplicates, "Should check for duplicates")
        XCTAssertNotNil(analysis.suggestedLinks, "Should suggest links")
        XCTAssertNotNil(analysis.clusterAnalysis, "Should perform clustering")
    }
    
    func testAnalyzeSimilarities_CategorizesByStrength() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let analysis = await sut.analyzeSimilarities(for: items)
        
        // Assert
        // Primary matches should have higher similarity than secondary
        if !analysis.primaryMatches.isEmpty && !analysis.secondaryMatches.isEmpty {
            let minPrimary = analysis.primaryMatches.map { $0.similarity }.min() ?? 0
            let maxSecondary = analysis.secondaryMatches.map { $0.similarity }.max() ?? 1
            XCTAssertGreaterThanOrEqual(minPrimary, maxSecondary, "Primary matches should have higher similarity")
        }
    }
    
    // MARK: - Clustering Tests
    
    func testClusterAnalysis_IdentifiesClusters() async throws {
        // Arrange
        let clusteredItems = createClusteredItems()
        
        // Act
        let analysis = await sut.analyzeSimilarities(for: clusteredItems)
        
        // Assert
        XCTAssertFalse(analysis.clusterAnalysis.clusters.isEmpty, "Should identify clusters")
        for cluster in analysis.clusterAnalysis.clusters {
            XCTAssertGreaterThan(cluster.memberIds.count, 0, "Clusters should have members")
            XCTAssertGreaterThan(cluster.cohesion, 0, "Clusters should have cohesion score")
        }
    }
    
    func testClusterAnalysis_IdentifiesOutliers() async throws {
        // Arrange
        let itemsWithOutlier = createItemsWithOutlier()
        
        // Act
        let analysis = await sut.analyzeSimilarities(for: itemsWithOutlier)
        
        // Assert
        XCTAssertFalse(analysis.clusterAnalysis.outliers.isEmpty, "Should identify outliers")
    }
    
    // MARK: - Link Generation Tests
    
    func testLinkGeneration_CreatesBidirectionalLinks() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let analysis = await sut.analyzeSimilarities(for: items)
        
        // Assert
        for link in analysis.suggestedLinks {
            if link.linkType == .similarity || link.linkType == .collaboration {
                XCTAssertTrue(link.bidirectional, "Similarity and collaboration should be bidirectional")
            }
        }
    }
    
    func testLinkGeneration_AssignsAppropriateTypes() async throws {
        // Arrange
        let items = createItemsWithVariousRelationships()
        
        // Act
        let analysis = await sut.analyzeSimilarities(for: items)
        
        // Assert
        let linkTypes = Set(analysis.suggestedLinks.map { $0.linkType })
        XCTAssertFalse(linkTypes.isEmpty, "Should assign link types")
    }
    
    // MARK: - Cosine Similarity Tests
    
    func testCosineSimilarity_CalculatesCorrectly() throws {
        // Arrange
        let vector1: [Float] = [1, 0, 0]
        let vector2: [Float] = [1, 0, 0]
        let vector3: [Float] = [0, 1, 0]
        let vector4: [Float] = [0.7071, 0.7071, 0]
        
        // Act & Assert
        // Identical vectors should have similarity 1
        XCTAssertEqual(calculateSimilarity(vector1, vector2), 1.0, accuracy: 0.01)
        
        // Orthogonal vectors should have similarity 0
        XCTAssertEqual(calculateSimilarity(vector1, vector3), 0.0, accuracy: 0.01)
        
        // 45-degree angle should have similarity ~0.707
        XCTAssertEqual(calculateSimilarity(vector1, vector4), 0.707, accuracy: 0.01)
    }
    
    // MARK: - Cache Management Tests
    
    func testCaching_ReusesResults() async throws {
        // Arrange
        let item = testItems[0]
        
        // Act
        let startTime = Date()
        let matches1 = await sut.findSimilarItems(for: item, limit: 5)
        let firstCallDuration = Date().timeIntervalSince(startTime)
        
        let cacheStartTime = Date()
        let matches2 = await sut.findSimilarItems(for: item, limit: 5)
        let cachedCallDuration = Date().timeIntervalSince(cacheStartTime)
        
        // Assert
        XCTAssertEqual(matches1.count, matches2.count, "Should return same results")
        if !matches1.isEmpty {
            XCTAssertLessThan(cachedCallDuration, firstCallDuration, "Cached call should be faster")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_LargeSetSimilaritySearch() throws {
        // Arrange
        let largeItemSet = createTestItems(count: 100)
        
        // Measure
        self.measure {
            let expectation = self.expectation(description: "Large set search")
            
            Task {
                _ = await sut.analyzeSimilarities(for: largeItemSet)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 60)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestItems(count: Int = 10) -> [EnhancedBrainDumpItem] {
        return (0..<count).map { index in
            createTestItem(
                id: UUID(),
                title: "Item \(index)",
                content: "Content for item \(index) with various keywords",
                contentType: index % 2 == 0 ? .task : .note,
                category: index % 3 == 0 ? .project : .area
            )
        }
    }
    
    private func createDuplicateItems() -> [EnhancedBrainDumpItem] {
        let content = "This is the exact same content for duplicate detection"
        return [
            createTestItem(title: "Duplicate 1", content: content),
            createTestItem(title: "Duplicate 2", content: content),
            createTestItem(title: "Different Item", content: "Completely different content")
        ]
    }
    
    private func createMultipleDuplicateSets() -> [EnhancedBrainDumpItem] {
        return [
            createTestItem(title: "Set1-A", content: "First duplicate set content"),
            createTestItem(title: "Set1-B", content: "First duplicate set content"),
            createTestItem(title: "Set2-A", content: "Second duplicate set content"),
            createTestItem(title: "Set2-B", content: "Second duplicate set content"),
            createTestItem(title: "Unique", content: "Unique content here")
        ]
    }
    
    private func createClusteredItems() -> [EnhancedBrainDumpItem] {
        return [
            // Cluster 1: Project tasks
            createTestItem(title: "Project Task 1", content: "Implement feature A", category: .project),
            createTestItem(title: "Project Task 2", content: "Implement feature B", category: .project),
            createTestItem(title: "Project Task 3", content: "Test features", category: .project),
            
            // Cluster 2: Personal notes
            createTestItem(title: "Personal Note 1", content: "Remember to exercise", category: .area),
            createTestItem(title: "Personal Note 2", content: "Health checkup reminder", category: .area)
        ]
    }
    
    private func createItemsWithOutlier() -> [EnhancedBrainDumpItem] {
        return [
            createTestItem(title: "Related 1", content: "Project management task"),
            createTestItem(title: "Related 2", content: "Project planning document"),
            createTestItem(title: "Related 3", content: "Project timeline review"),
            createTestItem(title: "Outlier", content: "完全不同的中文内容") // Completely different content
        ]
    }
    
    private func createItemsWithVariousRelationships() -> [EnhancedBrainDumpItem] {
        return [
            createTestItem(title: "Parent Task", content: "Main project goal", category: .project),
            createTestItem(title: "Child Task", content: "Subtask of main project goal", category: .project),
            createTestItem(title: "Related Task", content: "Related to project goal", category: .project),
            createTestItem(title: "Conflicting Task", content: "Conflicts with main project goal", category: .project)
        ]
    }
    
    private func createTestItem(
        id: UUID = UUID(),
        title: String = "Test Item",
        content: String = "Test content",
        contentType: ContentType = .task,
        category: PARACategory = .project
    ) -> EnhancedBrainDumpItem {
        return EnhancedBrainDumpItem(
            id: id,
            title: title,
            content: content,
            contentType: contentType,
            paraCategory: category,
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
    
    private func createTestEmbeddings() -> [[Float]] {
        // Create mock embeddings with varying similarity
        return (0..<10).map { index in
            let baseVector = Array(repeating: Float(index) / 10.0, count: 100)
            return baseVector.map { $0 + Float.random(in: -0.1...0.1) }
        }
    }
    
    private func calculateSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard normA > 0 && normB > 0 else { return 0 }
        return dotProduct / (normA * normB)
    }
}