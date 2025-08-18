//
// ContextQueryServiceTests.swift
// LifeManagerTests
//
// Unit tests for ContextQueryService
//

import XCTest
@testable import LifeManager

final class ContextQueryServiceTests: XCTestCase {
    
    var sut: ContextQueryService!
    
    override func setUp() {
        super.setUp()
        sut = ContextQueryService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Query Tests
    
    func testSearchItems_WithMatchingContent_ReturnsResults() async {
        // Given
        let items = [
            createContextItem(content: "Swift programming tutorial"),
            createContextItem(content: "JavaScript basics"),
            createContextItem(content: "Swift UI components"),
            createContextItem(content: "Python data science")
        ]
        await sut.setContextItems(items)
        
        // When
        let results = await sut.searchItems(query: "Swift")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.content.contains("Swift") })
    }
    
    func testSearchItems_CaseInsensitive() async {
        // Given
        let items = [
            createContextItem(content: "IMPORTANT task"),
            createContextItem(content: "important meeting"),
            createContextItem(content: "Regular work")
        ]
        await sut.setContextItems(items)
        
        // When
        let results = await sut.searchItems(query: "Important")
        
        // Then
        XCTAssertEqual(results.count, 2)
    }
    
    func testSearchItems_WithNoMatches_ReturnsEmpty() async {
        // Given
        let items = createContextItems(count: 10)
        await sut.setContextItems(items)
        
        // When
        let results = await sut.searchItems(query: "NonExistent")
        
        // Then
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Filter Tests
    
    func testFilterByCategory_ReturnsCorrectItems() async {
        // Given
        let items = [
            createContextItem(category: .project),
            createContextItem(category: .task),
            createContextItem(category: .project),
            createContextItem(category: .area),
            createContextItem(category: .task)
        ]
        await sut.setContextItems(items)
        
        // When
        let projects = await sut.filterByCategory(.project)
        let tasks = await sut.filterByCategory(.task)
        
        // Then
        XCTAssertEqual(projects.count, 2)
        XCTAssertEqual(tasks.count, 2)
        XCTAssertTrue(projects.allSatisfy { $0.category == .project })
        XCTAssertTrue(tasks.allSatisfy { $0.category == .task })
    }
    
    func testFilterByDateRange() async {
        // Given
        let now = Date()
        let items = [
            createContextItem(date: now.addingTimeInterval(-86400 * 7)), // 1 week ago
            createContextItem(date: now.addingTimeInterval(-86400 * 3)), // 3 days ago
            createContextItem(date: now.addingTimeInterval(-3600)),       // 1 hour ago
            createContextItem(date: now)
        ]
        await sut.setContextItems(items)
        
        // When
        let startDate = now.addingTimeInterval(-86400 * 5) // 5 days ago
        let endDate = now
        let results = await sut.filterByDateRange(start: startDate, end: endDate)
        
        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { 
            $0.timestamp >= startDate && $0.timestamp <= endDate 
        })
    }
    
    func testFilterByWorkPersonal() async {
        // Given
        let items = [
            createContextItem(workPersonal: .work),
            createContextItem(workPersonal: .personal),
            createContextItem(workPersonal: .work),
            createContextItem(workPersonal: .personal),
            createContextItem(workPersonal: .personal)
        ]
        await sut.setContextItems(items)
        
        // When
        let workItems = await sut.filterByWorkPersonal(.work)
        let personalItems = await sut.filterByWorkPersonal(.personal)
        
        // Then
        XCTAssertEqual(workItems.count, 2)
        XCTAssertEqual(personalItems.count, 3)
    }
    
    // MARK: - Complex Query Tests
    
    func testComplexQuery_CombinesMultipleFilters() async {
        // Given
        let now = Date()
        let items = [
            createContextItem(category: .task, workPersonal: .work, 
                            content: "Review code", date: now),
            createContextItem(category: .task, workPersonal: .personal, 
                            content: "Exercise", date: now),
            createContextItem(category: .project, workPersonal: .work, 
                            content: "App development", date: now),
            createContextItem(category: .task, workPersonal: .work, 
                            content: "Deploy update", date: now.addingTimeInterval(-86400 * 10))
        ]
        await sut.setContextItems(items)
        
        // When
        let query = ContextQuery(
            text: nil,
            category: .task,
            workPersonal: .work,
            dateRange: (now.addingTimeInterval(-86400), now.addingTimeInterval(86400))
        )
        let results = await sut.executeQuery(query)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Review code")
    }
    
    // MARK: - Sorting Tests
    
    func testSortByDate_NewestFirst() async {
        // Given
        let dates = [
            Date().addingTimeInterval(-3600),
            Date(),
            Date().addingTimeInterval(-7200)
        ]
        let items = dates.map { createContextItem(date: $0) }
        await sut.setContextItems(items)
        
        // When
        let sorted = await sut.getAllItems(sortedBy: .dateDescending)
        
        // Then
        XCTAssertEqual(sorted.count, 3)
        XCTAssertTrue(sorted[0].timestamp > sorted[1].timestamp)
        XCTAssertTrue(sorted[1].timestamp > sorted[2].timestamp)
    }
    
    func testSortByPriority() async {
        // Given
        let items = [
            createContextItem(priority: .low),
            createContextItem(priority: .critical),
            createContextItem(priority: .medium),
            createContextItem(priority: .high)
        ]
        await sut.setContextItems(items)
        
        // When
        let sorted = await sut.getAllItems(sortedBy: .priority)
        
        // Then
        XCTAssertEqual(sorted[0].metadata["priority"] as? String, Priority.critical.rawValue)
        XCTAssertEqual(sorted[1].metadata["priority"] as? String, Priority.high.rawValue)
        XCTAssertEqual(sorted[2].metadata["priority"] as? String, Priority.medium.rawValue)
        XCTAssertEqual(sorted[3].metadata["priority"] as? String, Priority.low.rawValue)
    }
    
    // MARK: - Pagination Tests
    
    func testPagination_ReturnsCorrectPage() async {
        // Given
        let items = createContextItems(count: 25)
        await sut.setContextItems(items)
        
        // When
        let page1 = await sut.getItems(page: 1, pageSize: 10)
        let page2 = await sut.getItems(page: 2, pageSize: 10)
        let page3 = await sut.getItems(page: 3, pageSize: 10)
        
        // Then
        XCTAssertEqual(page1.count, 10)
        XCTAssertEqual(page2.count, 10)
        XCTAssertEqual(page3.count, 5)
    }
    
    // MARK: - Aggregation Tests
    
    func testGetStatistics() async {
        // Given
        let items = [
            createContextItem(category: .project),
            createContextItem(category: .project),
            createContextItem(category: .task),
            createContextItem(category: .task),
            createContextItem(category: .task),
            createContextItem(category: .area),
            createContextItem(category: .resource)
        ]
        await sut.setContextItems(items)
        
        // When
        let stats = await sut.getStatistics()
        
        // Then
        XCTAssertEqual(stats.totalCount, 7)
        XCTAssertEqual(stats.categoryCounts[.project], 2)
        XCTAssertEqual(stats.categoryCounts[.task], 3)
        XCTAssertEqual(stats.categoryCounts[.area], 1)
        XCTAssertEqual(stats.categoryCounts[.resource], 1)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentQueries() async {
        // Given
        let items = createContextItems(count: 100)
        await sut.setContextItems(items)
        
        // When - Concurrent queries
        await withTaskGroup(of: [ContextItem].self) { group in
            for i in 0..<20 {
                group.addTask {
                    await self.sut.searchItems(query: "Item \(i)")
                }
            }
            
            // Then - All complete without issues
            var resultCount = 0
            for await _ in group {
                resultCount += 1
            }
            XCTAssertEqual(resultCount, 20)
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyQuery_ReturnsAll() async {
        // Given
        let items = createContextItems(count: 5)
        await sut.setContextItems(items)
        
        // When
        let results = await sut.searchItems(query: "")
        
        // Then
        XCTAssertEqual(results.count, 5)
    }
    
    func testInvalidDateRange_ReturnsEmpty() async {
        // Given
        let items = createContextItems(count: 5)
        await sut.setContextItems(items)
        
        // When
        let futureStart = Date().addingTimeInterval(86400)
        let futureEnd = Date().addingTimeInterval(86400 * 2)
        let results = await sut.filterByDateRange(start: futureStart, end: futureEnd)
        
        // Then
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createContextItem(
        category: PARACategory = .task,
        workPersonal: WorkPersonalType = .personal,
        priority: Priority = .medium,
        content: String = "Test item",
        date: Date = Date()
    ) -> ContextItem {
        return ContextItem(
            id: UUID(),
            content: content,
            timestamp: date,
            category: category,
            workPersonal: workPersonal,
            metadata: ["priority": priority.rawValue],
            embeddings: nil
        )
    }
    
    private func createContextItems(count: Int) -> [ContextItem] {
        return (0..<count).map { i in
            createContextItem(content: "Item \(i)")
        }
    }
}

// MARK: - Performance Tests

extension ContextQueryServiceTests {
    
    func testPerformance_SearchLargeDataset() {
        // Given
        let items = createContextItems(count: 10000)
        let expectation = self.expectation(description: "Setup")
        
        Task {
            await sut.setContextItems(items)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // When & Then
        measure {
            let searchExpectation = self.expectation(description: "Search")
            
            Task {
                _ = await sut.searchItems(query: "Item 500")
                searchExpectation.fulfill()
            }
            
            wait(for: [searchExpectation], timeout: 1.0)
        }
    }
    
    func testPerformance_ComplexQuery() {
        // Given
        let items = createContextItems(count: 5000)
        let expectation = self.expectation(description: "Setup")
        
        Task {
            await sut.setContextItems(items)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        // When & Then
        measure {
            let queryExpectation = self.expectation(description: "Query")
            
            Task {
                let query = ContextQuery(
                    text: "Item",
                    category: .task,
                    workPersonal: .personal,
                    dateRange: nil
                )
                _ = await sut.executeQuery(query)
                queryExpectation.fulfill()
            }
            
            wait(for: [queryExpectation], timeout: 1.0)
        }
    }
}