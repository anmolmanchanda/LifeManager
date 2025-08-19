//
// RelationshipDetectionServiceTests.swift
// LifeManagerTests
//
// Comprehensive unit tests for RelationshipDetectionService
// Testing relationship detection, graph building, and dependency analysis
//

import XCTest
@testable import LifeManager

@MainActor
final class RelationshipDetectionServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: RelationshipDetectionService!
    private var testItems: [EnhancedBrainDumpItem]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = RelationshipDetectionService.shared
        testItems = createTestItemsWithRelationships()
    }
    
    override func tearDown() async throws {
        sut = nil
        testItems = nil
        try await super.tearDown()
    }
    
    // MARK: - Relationship Detection Tests
    
    func testDetectRelationships_FindsMultipleTypes() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let relationships = await sut.detectRelationships(among: items)
        
        // Assert
        XCTAssertFalse(relationships.isEmpty, "Should detect relationships")
        let types = Set(relationships.map { $0.relationshipType })
        XCTAssertGreaterThan(types.count, 1, "Should detect multiple relationship types")
    }
    
    func testDetectRelationships_AssignsConfidenceScores() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let relationships = await sut.detectRelationships(among: items)
        
        // Assert
        for relationship in relationships {
            XCTAssertGreaterThan(relationship.confidence, 0, "Should have positive confidence")
            XCTAssertLessThanOrEqual(relationship.confidence, 1, "Confidence should not exceed 1")
        }
    }
    
    func testDetectRelationships_ProvidesEvidence() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let relationships = await sut.detectRelationships(among: items)
        
        // Assert
        for relationship in relationships {
            XCTAssertFalse(relationship.evidence.isEmpty, "Should provide evidence")
            XCTAssertFalse(relationship.description.isEmpty, "Should have description")
        }
    }
    
    // MARK: - Semantic Relationship Tests
    
    func testDetectSemanticRelationships_UsesSimilarityScores() async throws {
        // Arrange
        let similarItems = createSimilarItems()
        
        // Act
        let relationships = await sut.detectRelationships(among: similarItems)
        let semanticRelationships = relationships.filter { 
            $0.metadata.detectionMethod == .semantic
        }
        
        // Assert
        XCTAssertFalse(semanticRelationships.isEmpty, "Should detect semantic relationships")
        for relationship in semanticRelationships {
            XCTAssertGreaterThan(relationship.strength, 0.5, "Semantic relationships should have reasonable strength")
        }
    }
    
    // MARK: - Temporal Relationship Tests
    
    func testDetectTemporalRelationships_FindsSequences() async throws {
        // Arrange
        let timedItems = createItemsWithDueDates()
        
        // Act
        let relationships = await sut.detectRelationships(among: timedItems)
        let temporalRelationships = relationships.filter {
            $0.relationshipType == .sequence || $0.relationshipType == .temporal
        }
        
        // Assert
        XCTAssertFalse(temporalRelationships.isEmpty, "Should detect temporal relationships")
    }
    
    // MARK: - Keyword Relationship Tests
    
    func testDetectKeywordRelationships_FindsDependencies() async throws {
        // Arrange
        let itemsWithDependencies = createItemsWithKeywordDependencies()
        
        // Act
        let relationships = await sut.detectRelationships(among: itemsWithDependencies)
        let dependencyRelationships = relationships.filter {
            $0.relationshipType == .dependency || $0.relationshipType == .prerequisite
        }
        
        // Assert
        XCTAssertFalse(dependencyRelationships.isEmpty, "Should detect dependency keywords")
        for relationship in dependencyRelationships {
            XCTAssertTrue(
                relationship.evidence.contains { $0.contains("keyword") },
                "Should indicate keyword detection"
            )
        }
    }
    
    func testDetectKeywordRelationships_FindsConflicts() async throws {
        // Arrange
        let conflictingItems = createConflictingItems()
        
        // Act
        let relationships = await sut.detectRelationships(among: conflictingItems)
        let conflicts = relationships.filter { $0.relationshipType == .conflict }
        
        // Assert
        XCTAssertFalse(conflicts.isEmpty, "Should detect conflicts")
    }
    
    // MARK: - Category Relationship Tests
    
    func testDetectCategoryRelationships_GroupsSameProject() async throws {
        // Arrange
        let projectItems = createItemsInSameProject()
        
        // Act
        let relationships = await sut.detectRelationships(among: projectItems)
        let collaborations = relationships.filter { $0.relationshipType == .collaboration }
        
        // Assert
        XCTAssertFalse(collaborations.isEmpty, "Should detect collaborations in same project")
    }
    
    // MARK: - Graph Building Tests
    
    func testBuildRelationshipGraph_CreatesCompleteGraph() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let graph = await sut.buildRelationshipGraph(for: items)
        
        // Assert
        XCTAssertEqual(graph.nodes.count, items.count, "Should have node for each item")
        XCTAssertFalse(graph.edges.isEmpty, "Should have edges (relationships)")
        XCTAssertNotNil(graph.clusters, "Should identify clusters")
        XCTAssertNotNil(graph.criticalPaths, "Should find critical paths")
        XCTAssertNotNil(graph.conflicts, "Should analyze conflicts")
    }
    
    func testBuildRelationshipGraph_CalculatesCentrality() async throws {
        // Arrange
        let items = createHubAndSpokeItems()
        
        // Act
        let graph = await sut.buildRelationshipGraph(for: items)
        
        // Assert
        let hubNode = graph.nodes.first { $0.title.contains("Hub") }
        let spokeNodes = graph.nodes.filter { $0.title.contains("Spoke") }
        
        if let hub = hubNode, !spokeNodes.isEmpty {
            let avgSpokeCentrality = spokeNodes.map { $0.centrality }.reduce(0, +) / Double(spokeNodes.count)
            XCTAssertGreaterThan(hub.centrality, avgSpokeCentrality, "Hub should have higher centrality")
        }
    }
    
    // MARK: - Critical Path Tests
    
    func testFindCriticalPaths_IdentifiesDependencyChains() async throws {
        // Arrange
        let chainedItems = createDependencyChain()
        
        // Act
        let graph = await sut.buildRelationshipGraph(for: chainedItems)
        
        // Assert
        XCTAssertFalse(graph.criticalPaths.isEmpty, "Should find critical paths")
        for path in graph.criticalPaths {
            XCTAssertGreaterThan(path.itemSequence.count, 1, "Path should have multiple items")
            XCTAssertGreaterThan(path.importance, 0, "Path should have importance score")
        }
    }
    
    // MARK: - Cluster Analysis Tests
    
    func testIdentifyClusters_GroupsRelatedItems() async throws {
        // Arrange
        let clusteredItems = createClusteredItems()
        
        // Act
        let graph = await sut.buildRelationshipGraph(for: clusteredItems)
        
        // Assert
        XCTAssertFalse(graph.clusters.isEmpty, "Should identify clusters")
        for cluster in graph.clusters {
            XCTAssertGreaterThan(cluster.memberIds.count, 1, "Clusters should have multiple members")
            XCTAssertGreaterThan(cluster.cohesion, 0, "Clusters should have cohesion score")
        }
    }
    
    // MARK: - Conflict Analysis Tests
    
    func testAnalyzeConflicts_DetectsAndCategorizes() async throws {
        // Arrange
        let conflictingItems = createConflictingItems()
        
        // Act
        let graph = await sut.buildRelationshipGraph(for: conflictingItems)
        
        // Assert
        XCTAssertFalse(graph.conflicts.isEmpty, "Should detect conflicts")
        for conflict in graph.conflicts {
            XCTAssertGreaterThan(conflict.conflictingItems.count, 1, "Conflicts should involve multiple items")
            XCTAssertNotNil(conflict.conflictType, "Should categorize conflict type")
            XCTAssertNotNil(conflict.severity, "Should assess severity")
            XCTAssertFalse(conflict.resolution.isEmpty, "Should suggest resolution")
        }
    }
    
    // MARK: - Dependency Analysis Tests
    
    func testFindDependencies_IdentifiesBlockers() async throws {
        // Arrange
        let dependentItem = createDependentItem()
        let allItems = testItems + [dependentItem]
        
        // Act
        let analysis = await sut.findDependencies(for: dependentItem, among: allItems)
        
        // Assert
        if !analysis.dependencies.isEmpty {
            XCTAssertTrue(analysis.isBlocked, "Item with dependencies should be blocked")
            XCTAssertFalse(analysis.canStart, "Blocked item cannot start")
        } else {
            XCTAssertFalse(analysis.isBlocked, "Item without dependencies should not be blocked")
            XCTAssertTrue(analysis.canStart, "Unblocked item can start")
        }
    }
    
    // MARK: - Bidirectional Relationship Tests
    
    func testBidirectionalRelationships_MarkedCorrectly() async throws {
        // Arrange
        let items = testItems
        
        // Act
        let relationships = await sut.detectRelationships(among: items)
        
        // Assert
        for relationship in relationships {
            switch relationship.relationshipType {
            case .similarity, .collaboration, .conflict:
                XCTAssertTrue(relationship.bidirectional, "\(relationship.relationshipType) should be bidirectional")
            case .dependency, .prerequisite, .hierarchy:
                XCTAssertFalse(relationship.bidirectional, "\(relationship.relationshipType) should be directional")
            default:
                break
            }
        }
    }
    
    // MARK: - Deduplication Tests
    
    func testDeduplication_RemovesDuplicateRelationships() async throws {
        // Arrange
        let items = Array(testItems.prefix(3))
        
        // Act
        let relationships = await sut.detectRelationships(among: items)
        
        // Assert
        var uniquePairs = Set<String>()
        for relationship in relationships {
            let key = "\(relationship.sourceItemId)-\(relationship.targetItemId)-\(relationship.relationshipType)"
            XCTAssertFalse(uniquePairs.contains(key), "Should not have duplicate relationships")
            uniquePairs.insert(key)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_LargeGraphBuilding() throws {
        // Arrange
        let largeItemSet = createTestItemsWithRelationships(count: 50)
        
        // Measure
        self.measure {
            let expectation = self.expectation(description: "Large graph")
            
            Task {
                _ = await sut.buildRelationshipGraph(for: largeItemSet)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestItemsWithRelationships(count: Int = 10) -> [EnhancedBrainDumpItem] {
        return (0..<count).map { index in
            createTestItem(
                title: "Item \(index)",
                content: index > 0 ? "This depends on Item \(index - 1)" : "Root item",
                dueDate: index > 0 ? Date().addingTimeInterval(Double(index) * 86400) : nil
            )
        }
    }
    
    private func createSimilarItems() -> [EnhancedBrainDumpItem] {
        let baseContent = "Project management and planning tasks"
        return (0..<3).map { index in
            createTestItem(
                title: "Similar Item \(index)",
                content: "\(baseContent) variation \(index)"
            )
        }
    }
    
    private func createItemsWithDueDates() -> [EnhancedBrainDumpItem] {
        return (0..<5).map { index in
            createTestItem(
                title: "Timed Task \(index)",
                content: "Task with deadline",
                dueDate: Date().addingTimeInterval(Double(index) * 86400)
            )
        }
    }
    
    private func createItemsWithKeywordDependencies() -> [EnhancedBrainDumpItem] {
        return [
            createTestItem(title: "Task A", content: "First task to complete"),
            createTestItem(title: "Task B", content: "This task depends on Task A"),
            createTestItem(title: "Task C", content: "Must be done after Task B is complete"),
            createTestItem(title: "Task D", content: "Requires Task A and Task C")
        ]
    }
    
    private func createConflictingItems() -> [EnhancedBrainDumpItem] {
        return [
            createTestItem(title: "Option A", content: "Use React for frontend"),
            createTestItem(title: "Option B", content: "This conflicts with Option A - use Vue instead"),
            createTestItem(title: "Decision", content: "Choose between Option A or Option B")
        ]
    }
    
    private func createItemsInSameProject() -> [EnhancedBrainDumpItem] {
        return (0..<4).map { index in
            var item = createTestItem(
                title: "Project Alpha - Task \(index)",
                content: "Working on Project Alpha"
            )
            item.suggestedProject = "Project Alpha"
            return item
        }
    }
    
    private func createHubAndSpokeItems() -> [EnhancedBrainDumpItem] {
        var items: [EnhancedBrainDumpItem] = []
        
        // Hub item
        items.append(createTestItem(
            title: "Hub Task",
            content: "Central task that connects to Spoke 1, Spoke 2, Spoke 3"
        ))
        
        // Spoke items
        for i in 1...3 {
            items.append(createTestItem(
                title: "Spoke \(i)",
                content: "Connected to Hub Task"
            ))
        }
        
        return items
    }
    
    private func createDependencyChain() -> [EnhancedBrainDumpItem] {
        return [
            createTestItem(title: "Start", content: "Initial task"),
            createTestItem(title: "Step 1", content: "Depends on Start"),
            createTestItem(title: "Step 2", content: "Depends on Step 1"),
            createTestItem(title: "Step 3", content: "Depends on Step 2"),
            createTestItem(title: "End", content: "Depends on Step 3")
        ]
    }
    
    private func createClusteredItems() -> [EnhancedBrainDumpItem] {
        return [
            // Cluster 1
            createTestItem(title: "Frontend Task 1", content: "React component development"),
            createTestItem(title: "Frontend Task 2", content: "CSS styling updates"),
            createTestItem(title: "Frontend Task 3", content: "UI testing"),
            
            // Cluster 2
            createTestItem(title: "Backend Task 1", content: "API endpoint development"),
            createTestItem(title: "Backend Task 2", content: "Database schema updates"),
            
            // Outlier
            createTestItem(title: "Documentation", content: "Update README file")
        ]
    }
    
    private func createDependentItem() -> EnhancedBrainDumpItem {
        return createTestItem(
            title: "Dependent Task",
            content: "This task depends on Item 0 and requires Item 1"
        )
    }
    
    private func createTestItem(
        title: String = "Test Item",
        content: String = "Test content",
        dueDate: Date? = nil
    ) -> EnhancedBrainDumpItem {
        return EnhancedBrainDumpItem(
            id: UUID(),
            title: title,
            content: content,
            contentType: .task,
            paraCategory: .project,
            suggestedArea: nil,
            suggestedProject: nil,
            workPersonal: .work,
            priority: .medium,
            dueDate: dueDate != nil ? ISO8601DateFormatter().string(from: dueDate!) : nil,
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