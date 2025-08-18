//
// SummaryGenerationServiceTests.swift
// LifeManagerTests
//
// Unit tests for SummaryGenerationService
//

import XCTest
@testable import LifeManager

final class SummaryGenerationServiceTests: XCTestCase {
    
    var sut: SummaryGenerationService!
    
    override func setUp() {
        super.setUp()
        sut = SummaryGenerationService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Summary Generation Tests
    
    func testGenerateSummary_WithEmptyItems_ReturnsEmptySummary() async {
        // Given
        let items: [ContextItem] = []
        
        // When
        let summary = await sut.generateSummary(for: items)
        
        // Then
        XCTAssertEqual(summary.itemCount, 0)
        XCTAssertTrue(summary.highlights.isEmpty)
        XCTAssertTrue(summary.categorySummaries.isEmpty)
    }
    
    func testGenerateSummary_WithVariousCategories_GroupsCorrectly() async {
        // Given
        let items = [
            createContextItem(category: .project, content: "App development"),
            createContextItem(category: .project, content: "Website redesign"),
            createContextItem(category: .task, content: "Review code"),
            createContextItem(category: .task, content: "Write tests"),
            createContextItem(category: .task, content: "Deploy update"),
            createContextItem(category: .area, content: "Health"),
            createContextItem(category: .resource, content: "Documentation")
        ]
        
        // When
        let summary = await sut.generateSummary(for: items)
        
        // Then
        XCTAssertEqual(summary.itemCount, 7)
        XCTAssertEqual(summary.categorySummaries[.project]?.count, 2)
        XCTAssertEqual(summary.categorySummaries[.task]?.count, 3)
        XCTAssertEqual(summary.categorySummaries[.area]?.count, 1)
        XCTAssertEqual(summary.categorySummaries[.resource]?.count, 1)
    }
    
    func testGenerateSummary_ExtractsHighlights() async {
        // Given
        let items = [
            createContextItem(priority: .critical, content: "Critical bug fix"),
            createContextItem(priority: .high, content: "Important feature"),
            createContextItem(priority: .medium, content: "Regular task"),
            createContextItem(priority: .low, content: "Minor update")
        ]
        
        // When
        let summary = await sut.generateSummary(for: items)
        
        // Then
        XCTAssertFalse(summary.highlights.isEmpty)
        XCTAssertTrue(summary.highlights.contains { $0.contains("Critical") })
        XCTAssertTrue(summary.highlights.contains { $0.contains("Important") })
    }
    
    func testGenerateSummary_CalculatesTimeRange() async {
        // Given
        let now = Date()
        let items = [
            createContextItem(date: now.addingTimeInterval(-7200)), // 2 hours ago
            createContextItem(date: now.addingTimeInterval(-3600)), // 1 hour ago
            createContextItem(date: now)
        ]
        
        // When
        let summary = await sut.generateSummary(for: items)
        
        // Then
        XCTAssertNotNil(summary.timeRange)
        XCTAssertEqual(summary.timeRange?.start.timeIntervalSince1970,
                      now.addingTimeInterval(-7200).timeIntervalSince1970,
                      accuracy: 1.0)
    }
    
    // MARK: - Periodic Summary Tests
    
    func testGeneratePeriodicSummary_Daily() async {
        // Given
        let items = createItemsOverDays(7)
        
        // When
        let summary = await sut.generatePeriodicSummary(
            for: items,
            period: .daily
        )
        
        // Then
        XCTAssertEqual(summary.period, .daily)
        XCTAssertNotNil(summary.insights)
        XCTAssertGreaterThan(summary.insights.count, 0)
    }
    
    func testGeneratePeriodicSummary_Weekly() async {
        // Given
        let items = createItemsOverDays(30)
        
        // When
        let summary = await sut.generatePeriodicSummary(
            for: items,
            period: .weekly
        )
        
        // Then
        XCTAssertEqual(summary.period, .weekly)
        XCTAssertTrue(summary.trends.count > 0)
    }
    
    // MARK: - Compression Tests
    
    func testCompressItems_ReducesSize() async {
        // Given
        let items = createContextItems(count: 100)
        
        // When
        let compressed = await sut.compressItems(items, targetSize: 10)
        
        // Then
        XCTAssertLessThanOrEqual(compressed.count, 10)
        XCTAssertGreaterThan(compressed.count, 0)
    }
    
    func testCompressItems_PreservesImportantItems() async {
        // Given
        let items = [
            createContextItem(priority: .critical, content: "Must keep"),
            createContextItem(priority: .low, content: "Can drop 1"),
            createContextItem(priority: .low, content: "Can drop 2"),
            createContextItem(priority: .high, content: "Should keep"),
            createContextItem(priority: .low, content: "Can drop 3")
        ]
        
        // When
        let compressed = await sut.compressItems(items, targetSize: 2)
        
        // Then
        XCTAssertEqual(compressed.count, 2)
        XCTAssertTrue(compressed.contains { $0.content == "Must keep" })
        XCTAssertTrue(compressed.contains { $0.content == "Should keep" })
    }
    
    // MARK: - Insights Generation Tests
    
    func testGenerateInsights_IdentifiesPatterns() async {
        // Given
        let items = [
            createContextItem(category: .task, content: "Meeting at 9am"),
            createContextItem(category: .task, content: "Meeting at 10am"),
            createContextItem(category: .task, content: "Meeting at 2pm"),
            createContextItem(category: .project, content: "Development work")
        ]
        
        // When
        let insights = await sut.generateInsights(from: items)
        
        // Then
        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(insights.contains { $0.contains("meeting") || $0.contains("Meeting") })
    }
    
    func testGenerateInsights_WithEmptyItems_ReturnsEmptyInsights() async {
        // Given
        let items: [ContextItem] = []
        
        // When
        let insights = await sut.generateInsights(from: items)
        
        // Then
        XCTAssertTrue(insights.isEmpty)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentSummaryGeneration() async {
        // Given
        let itemSets = (0..<10).map { _ in
            createContextItems(count: 50)
        }
        
        // When - Concurrent summary generation
        await withTaskGroup(of: ContextSummary.self) { group in
            for items in itemSets {
                group.addTask {
                    await self.sut.generateSummary(for: items)
                }
            }
            
            // Then - All complete without issues
            var summaryCount = 0
            for await summary in group {
                XCTAssertGreaterThan(summary.itemCount, 0)
                summaryCount += 1
            }
            XCTAssertEqual(summaryCount, 10)
        }
    }
    
    // MARK: - Edge Cases
    
    func testCompressItems_WithTargetLargerThanInput() async {
        // Given
        let items = createContextItems(count: 5)
        
        // When
        let compressed = await sut.compressItems(items, targetSize: 10)
        
        // Then
        XCTAssertEqual(compressed.count, 5)
    }
    
    func testCompressItems_WithZeroTarget() async {
        // Given
        let items = createContextItems(count: 10)
        
        // When
        let compressed = await sut.compressItems(items, targetSize: 0)
        
        // Then
        XCTAssertEqual(compressed.count, 1) // Should keep at least one
    }
    
    // MARK: - Helper Methods
    
    private func createContextItem(
        category: PARACategory = .task,
        priority: Priority = .medium,
        content: String = "Test item",
        date: Date = Date()
    ) -> ContextItem {
        return ContextItem(
            id: UUID(),
            content: content,
            timestamp: date,
            category: category,
            workPersonal: .personal,
            metadata: ["priority": priority.rawValue],
            embeddings: nil
        )
    }
    
    private func createContextItems(count: Int) -> [ContextItem] {
        return (0..<count).map { i in
            createContextItem(content: "Item \(i)")
        }
    }
    
    private func createItemsOverDays(_ days: Int) -> [ContextItem] {
        var items: [ContextItem] = []
        for day in 0..<days {
            let date = Date().addingTimeInterval(-Double(day * 86400))
            for hour in [9, 14, 16] {
                items.append(createContextItem(
                    date: date.addingTimeInterval(Double(hour * 3600))
                ))
            }
        }
        return items
    }
}

// MARK: - Performance Tests

extension SummaryGenerationServiceTests {
    
    func testPerformance_GenerateSummaryLargeDataset() {
        // Given
        let items = createContextItems(count: 1000)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Generate summary")
            
            Task {
                _ = await sut.generateSummary(for: items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testPerformance_CompressLargeDataset() {
        // Given
        let items = createContextItems(count: 500)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Compress items")
            
            Task {
                _ = await sut.compressItems(items, targetSize: 50)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
}