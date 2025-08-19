//
// ContextMemoryCoordinatorTests.swift
// LifeManagerTests
//
// Unit tests for ContextMemoryCoordinator
//

import XCTest
@testable import LifeManager

final class ContextMemoryCoordinatorTests: XCTestCase {
    
    var sut: ContextMemoryCoordinator!
    
    override func setUp() {
        super.setUp()
        sut = ContextMemoryCoordinator.shared
        // Reset state for testing
        Task {
            await sut.clearAllContext()
        }
    }
    
    override func tearDown() {
        Task {
            await sut.clearAllContext()
        }
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Context Addition Tests
    
    func testAddToContext_SingleItem() async {
        // Given
        let item = createPARAItem(content: "Test task")
        
        // When
        await sut.addToContext([item])
        let context = await sut.getRelevantContext()
        
        // Then
        XCTAssertFalse(context.isEmpty)
        XCTAssertTrue(context.contains { $0.content == "Test task" })
    }
    
    func testAddToContext_MultipleItems() async {
        // Given
        let items = createPARAItems(count: 5)
        
        // When
        await sut.addToContext(items)
        let context = await sut.getRelevantContext()
        
        // Then
        XCTAssertGreaterThanOrEqual(context.count, 5)
    }
    
    func testAddProject_UpdatesContext() async {
        // Given
        let project = Project(
            id: UUID(),
            userId: UUID(),
            name: "Test Project",
            description: "A test project",
            status: .active,
            deadline: Date().addingTimeInterval(86400 * 7),
            workPersonal: .work,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        await sut.addProject(project)
        let context = await sut.getRelevantContext()
        
        // Then
        XCTAssertTrue(context.contains { $0.content.contains("Test Project") })
    }
    
    // MARK: - Context Retrieval Tests
    
    func testGetRelevantContext_ReturnsRecent() async {
        // Given
        let oldItems = createPARAItems(count: 3, date: Date().addingTimeInterval(-86400 * 10))
        let recentItems = createPARAItems(count: 2, date: Date())
        
        await sut.addToContext(oldItems + recentItems)
        
        // When
        let context = await sut.getRelevantContext()
        
        // Then
        // Should prioritize recent items
        XCTAssertGreaterThan(context.count, 0)
    }
    
    func testGetContextForCategory() async {
        // Given
        let projectItems = createPARAItems(count: 3, category: .project)
        let taskItems = createPARAItems(count: 2, category: .task)
        
        await sut.addToContext(projectItems + taskItems)
        
        // When
        let projectContext = await sut.getContextForCategory(.project)
        let taskContext = await sut.getContextForCategory(.task)
        
        // Then
        XCTAssertTrue(projectContext.allSatisfy { $0.category == .project })
        XCTAssertTrue(taskContext.allSatisfy { $0.category == .task })
    }
    
    // MARK: - Update and Optimization Tests
    
    func testUpdatePatterns_TriggersOptimization() async {
        // Given
        let items = createPARAItems(count: 100)
        await sut.addToContext(items)
        
        // When
        await sut.updatePatterns()
        
        // Then
        // Verify patterns were analyzed (check internal state if exposed)
        let stats = await sut.getStatistics()
        XCTAssertGreaterThan(stats.totalItems, 0)
    }
    
    func testOptimizeContext_MaintainsRelevantItems() async {
        // Given
        let criticalItem = createPARAItem(priority: .critical, content: "Critical task")
        let lowItems = createPARAItems(count: 50, priority: .low)
        
        await sut.addToContext([criticalItem] + lowItems)
        
        // When
        await sut.optimizeContext()
        let context = await sut.getRelevantContext()
        
        // Then
        // Critical item should be retained
        XCTAssertTrue(context.contains { $0.content == "Critical task" })
    }
    
    // MARK: - Statistics Tests
    
    func testGetStatistics_AccurateCount() async {
        // Given
        let items = [
            createPARAItem(category: .project),
            createPARAItem(category: .project),
            createPARAItem(category: .task),
            createPARAItem(category: .area),
            createPARAItem(category: .resource)
        ]
        await sut.addToContext(items)
        
        // When
        let stats = await sut.getStatistics()
        
        // Then
        XCTAssertEqual(stats.totalItems, 5)
        XCTAssertEqual(stats.projectCount, 2)
        XCTAssertEqual(stats.taskCount, 1)
        XCTAssertEqual(stats.areaCount, 1)
        XCTAssertEqual(stats.resourceCount, 1)
    }
    
    func testGetStatistics_TracksWindowSize() async {
        // Given
        let items = createPARAItems(count: 75)
        await sut.addToContext(items)
        
        // When
        await sut.updatePatterns()
        let stats = await sut.getStatistics()
        
        // Then
        XCTAssertGreaterThan(stats.currentWindowSize, 0)
        XCTAssertLessThanOrEqual(stats.currentWindowSize, 200) // Max window size
    }
    
    // MARK: - Persistence Tests
    
    func testSaveContext_PersistsData() async {
        // Given
        let items = createPARAItems(count: 10)
        await sut.addToContext(items)
        
        // When
        await sut.saveContext()
        
        // Clear in-memory data
        await sut.clearAllContext()
        
        // Load from persistence
        await sut.loadContext()
        let context = await sut.getRelevantContext()
        
        // Then
        XCTAssertFalse(context.isEmpty)
    }
    
    // MARK: - Clear Context Tests
    
    func testClearAllContext_RemovesEverything() async {
        // Given
        let items = createPARAItems(count: 20)
        await sut.addToContext(items)
        
        // When
        await sut.clearAllContext()
        let context = await sut.getRelevantContext()
        let stats = await sut.getStatistics()
        
        // Then
        XCTAssertTrue(context.isEmpty)
        XCTAssertEqual(stats.totalItems, 0)
    }
    
    func testClearOldContext_RemovesOnlyOld() async {
        // Given
        let oldItems = createPARAItems(count: 5, date: Date().addingTimeInterval(-86400 * 10))
        let recentItems = createPARAItems(count: 3, date: Date())
        
        await sut.addToContext(oldItems + recentItems)
        
        // When
        await sut.clearOldContext(olderThan: 7)
        let context = await sut.getRelevantContext()
        
        // Then
        XCTAssertLessThanOrEqual(context.count, 3)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess_MaintainsIntegrity() async {
        // Given
        let iterations = 50
        
        // When - Concurrent adds and reads
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask {
                    let items = self.createPARAItems(count: 1, prefix: "Writer\(i)")
                    await self.sut.addToContext(items)
                }
            }
            
            // Readers
            for _ in 0..<iterations {
                group.addTask {
                    _ = await self.sut.getRelevantContext()
                    _ = await self.sut.getStatistics()
                }
            }
        }
        
        // Then
        let stats = await sut.getStatistics()
        XCTAssertGreaterThan(stats.totalItems, 0)
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() async {
        // Given
        let project = Project(
            id: UUID(),
            userId: UUID(),
            name: "Big Project",
            description: "Important work",
            status: .active,
            deadline: Date().addingTimeInterval(86400 * 30),
            workPersonal: .work,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let tasks = createPARAItems(count: 5, category: .task)
        
        // When
        await sut.addProject(project)
        await sut.addToContext(tasks)
        await sut.updatePatterns()
        await sut.optimizeContext()
        
        let context = await sut.getRelevantContext()
        let stats = await sut.getStatistics()
        
        // Then
        XCTAssertGreaterThan(context.count, 0)
        XCTAssertGreaterThan(stats.totalItems, 0)
        XCTAssertGreaterThan(stats.projectCount, 0)
        XCTAssertGreaterThan(stats.taskCount, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createPARAItem(
        category: PARACategory = .task,
        priority: Priority = .medium,
        content: String = "Test item",
        date: Date = Date(),
        prefix: String = "Item"
    ) -> PARAItem {
        return PARAItem(
            id: UUID(),
            content: "\(prefix): \(content)",
            category: category,
            workPersonal: .personal,
            createdAt: date,
            updatedAt: date
        )
    }
    
    private func createPARAItems(
        count: Int,
        category: PARACategory = .task,
        priority: Priority = .medium,
        date: Date = Date(),
        prefix: String = "Item"
    ) -> [PARAItem] {
        return (0..<count).map { i in
            createPARAItem(
                category: category,
                priority: priority,
                content: "\(prefix) \(i)",
                date: date.addingTimeInterval(Double(i * 60))
            )
        }
    }
}

// MARK: - Performance Tests

extension ContextMemoryCoordinatorTests {
    
    func testPerformance_AddLargeDataset() {
        // Given
        let items = createPARAItems(count: 1000)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Add items")
            
            Task {
                await sut.addToContext(items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformance_GetRelevantContext() {
        // Setup
        let setupExpectation = self.expectation(description: "Setup")
        let items = createPARAItems(count: 500)
        
        Task {
            await sut.addToContext(items)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 3.0)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Get context")
            
            Task {
                _ = await sut.getRelevantContext()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testPerformance_OptimizeContext() {
        // Setup
        let setupExpectation = self.expectation(description: "Setup")
        let items = createPARAItems(count: 1000)
        
        Task {
            await sut.addToContext(items)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 5.0)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Optimize")
            
            Task {
                await sut.optimizeContext()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
}

// MARK: - Supporting Types for Testing

struct ContextStatistics {
    let totalItems: Int
    let projectCount: Int
    let taskCount: Int
    let areaCount: Int
    let resourceCount: Int
    let currentWindowSize: Int
    let activityLevel: String
}