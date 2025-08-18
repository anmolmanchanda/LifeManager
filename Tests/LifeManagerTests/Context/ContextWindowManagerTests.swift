//
// ContextWindowManagerTests.swift
// LifeManagerTests
//
// Unit tests for ContextWindowManager
//

import XCTest
@testable import LifeManager

final class ContextWindowManagerTests: XCTestCase {
    
    var sut: ContextWindowManager!
    
    override func setUp() {
        super.setUp()
        sut = ContextWindowManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Window Management Tests
    
    func testAddItems_AddsToActiveWindow() async {
        // Given
        let items = createPARAItems(count: 5)
        
        // When
        await sut.addItems(items)
        
        // Then
        XCTAssertEqual(sut.activeWindow.count, 5)
        XCTAssertEqual(sut.currentWindowStats.totalItems, 5)
    }
    
    func testAddItems_MaintainsWindowSizeLimit() async {
        // Given
        sut.windowSize = 10
        let items = createPARAItems(count: 15)
        
        // When
        await sut.addItems(items)
        
        // Then
        XCTAssertEqual(sut.activeWindow.count, 10)
        XCTAssertEqual(sut.currentWindowStats.totalItems, 10)
        // Should keep most recent items
        XCTAssertEqual(sut.activeWindow.first?.content, "Item 5")
    }
    
    func testRemoveOldItems_RemovesItemsOlderThanThreshold() async {
        // Given
        let oldDate = Date().addingTimeInterval(-86400 * 8) // 8 days old
        let recentDate = Date().addingTimeInterval(-3600) // 1 hour old
        
        let oldItems = createPARAItems(count: 3, date: oldDate)
        let recentItems = createPARAItems(count: 2, date: recentDate)
        
        await sut.addItems(oldItems + recentItems)
        
        // When
        sut.removeOldItems(olderThan: 7)
        
        // Then
        XCTAssertEqual(sut.activeWindow.count, 2)
        XCTAssertTrue(sut.activeWindow.allSatisfy { $0.createdAt > oldDate })
    }
    
    func testClearWindow_RemovesAllItems() {
        // Given
        sut.activeWindow = createContextItems(count: 10)
        sut.currentWindowStats.totalItems = 10
        
        // When
        sut.clearWindow()
        
        // Then
        XCTAssertTrue(sut.activeWindow.isEmpty)
        XCTAssertEqual(sut.currentWindowStats.totalItems, 0)
    }
    
    // MARK: - Window Size Adjustment Tests
    
    func testAdjustWindowSize_LowActivity_DecreasesSize() {
        // Given
        sut.windowSize = 150
        
        // When
        sut.adjustWindowSize(basedOn: .low)
        
        // Then
        XCTAssertEqual(sut.windowSize, 50)
    }
    
    func testAdjustWindowSize_HighActivity_IncreasesSize() {
        // Given
        sut.windowSize = 100
        
        // When
        sut.adjustWindowSize(basedOn: .high)
        
        // Then
        XCTAssertEqual(sut.windowSize, 200)
    }
    
    func testAdjustWindowSize_MediumActivity_SetsModerateSize() {
        // Given
        sut.windowSize = 50
        
        // When
        sut.adjustWindowSize(basedOn: .medium)
        
        // Then
        XCTAssertEqual(sut.windowSize, 100)
    }
    
    func testAdjustWindowSize_TrimsExcessItems() {
        // Given
        sut.activeWindow = createContextItems(count: 150)
        sut.windowSize = 150
        
        // When
        sut.adjustWindowSize(basedOn: .low) // Will set to 50
        
        // Then
        XCTAssertEqual(sut.activeWindow.count, 50)
        XCTAssertEqual(sut.windowSize, 50)
    }
    
    // MARK: - Statistics Tests
    
    func testUpdateStatistics_CalculatesCorrectly() async {
        // Given
        let items = [
            createPARAItem(category: .project),
            createPARAItem(category: .project),
            createPARAItem(category: .area),
            createPARAItem(category: .resource),
            createPARAItem(category: .archive)
        ]
        await sut.addItems(items)
        
        // When
        let stats = sut.currentWindowStats
        
        // Then
        XCTAssertEqual(stats.totalItems, 5)
        XCTAssertEqual(stats.categoryCounts[.project], 2)
        XCTAssertEqual(stats.categoryCounts[.area], 1)
        XCTAssertEqual(stats.categoryCounts[.resource], 1)
        XCTAssertEqual(stats.categoryCounts[.archive], 1)
    }
    
    func testGetRelevantContext_FiltersCorrectly() {
        // Given
        sut.activeWindow = [
            createContextItem(category: .project, content: "Build app feature"),
            createContextItem(category: .task, content: "Review code"),
            createContextItem(category: .area, content: "Health tracking"),
            createContextItem(category: .resource, content: "API documentation")
        ]
        
        // When
        let projectContext = sut.getRelevantContext(for: .project)
        let taskContext = sut.getRelevantContext(for: .task)
        
        // Then
        XCTAssertEqual(projectContext.count, 1)
        XCTAssertEqual(projectContext.first?.content, "Build app feature")
        XCTAssertEqual(taskContext.count, 1)
        XCTAssertEqual(taskContext.first?.content, "Review code")
    }
    
    func testGetRelevantContext_LimitsResults() {
        // Given
        sut.activeWindow = createContextItems(count: 20, category: .task)
        
        // When
        let context = sut.getRelevantContext(for: .task, limit: 5)
        
        // Then
        XCTAssertEqual(context.count, 5)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess_MaintainsDataIntegrity() async {
        // Given
        let iterations = 100
        
        // When - Concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask {
                    let items = self.createPARAItems(count: 1, prefix: "Writer\(i)")
                    await self.sut.addItems(items)
                }
            }
            
            // Readers
            for _ in 0..<iterations {
                group.addTask {
                    _ = self.sut.getRelevantContext(for: .task)
                    _ = self.sut.currentWindowStats
                }
            }
        }
        
        // Then
        XCTAssertLessThanOrEqual(sut.activeWindow.count, sut.windowSize)
        XCTAssertGreaterThan(sut.activeWindow.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testAddItems_WithEmptyArray_HandlesGracefully() async {
        // Given
        let items: [PARAItem] = []
        
        // When
        await sut.addItems(items)
        
        // Then
        XCTAssertTrue(sut.activeWindow.isEmpty)
        XCTAssertEqual(sut.currentWindowStats.totalItems, 0)
    }
    
    func testWindowSize_NeverExceedsMaximum() {
        // Given
        sut.windowSize = 300
        
        // When
        sut.adjustWindowSize(basedOn: .high)
        
        // Then
        XCTAssertEqual(sut.windowSize, 200) // Maximum limit
    }
    
    func testWindowSize_NeverBelowMinimum() {
        // Given
        sut.windowSize = 10
        
        // When
        sut.adjustWindowSize(basedOn: .low)
        
        // Then
        XCTAssertEqual(sut.windowSize, 50) // Minimum limit
    }
    
    // MARK: - Helper Methods
    
    private func createPARAItems(count: Int, date: Date = Date(), prefix: String = "Item") -> [PARAItem] {
        return (0..<count).map { i in
            createPARAItem(
                content: "\(prefix) \(i)",
                date: date.addingTimeInterval(Double(i * 60))
            )
        }
    }
    
    private func createPARAItem(
        category: PARACategory = .task,
        content: String = "Test item",
        date: Date = Date()
    ) -> PARAItem {
        return PARAItem(
            id: UUID(),
            content: content,
            category: category,
            workPersonal: .personal,
            createdAt: date,
            updatedAt: date
        )
    }
    
    private func createContextItems(
        count: Int,
        category: PARACategory = .task
    ) -> [ContextItem] {
        return (0..<count).map { i in
            createContextItem(
                category: category,
                content: "Context \(i)"
            )
        }
    }
    
    private func createContextItem(
        category: PARACategory = .task,
        content: String = "Test context"
    ) -> ContextItem {
        return ContextItem(
            id: UUID(),
            content: content,
            timestamp: Date(),
            category: category,
            workPersonal: .personal,
            metadata: [:],
            embeddings: nil
        )
    }
}

// MARK: - Performance Tests

extension ContextWindowManagerTests {
    
    func testPerformance_AddLargeNumberOfItems() {
        // Given
        let items = createPARAItems(count: 1000)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Add items")
            
            Task {
                await sut.addItems(items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testPerformance_GetRelevantContextFromLargeWindow() {
        // Given
        sut.windowSize = 200
        sut.activeWindow = createContextItems(count: 200)
        
        // When & Then
        measure {
            _ = sut.getRelevantContext(for: .task, limit: 50)
        }
    }
}