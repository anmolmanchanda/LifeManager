import XCTest
import Foundation
@testable import LifeManager

class ContextMemoryServiceTests: XCTestCase {
    var contextMemoryService: ContextMemoryService!
    var mockRepository: MockPARARepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPARARepository()
        contextMemoryService = ContextMemoryService(repository: mockRepository)
    }
    
    override func tearDown() {
        contextMemoryService = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Context Window Management Tests
    
    func testAddToContext_WithinLimit() async throws {
        // Given
        let items = createTestItems(count: 50)
        
        // When
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // Then
        let contextItems = await contextMemoryService.getRecentContext()
        XCTAssertEqual(contextItems.count, 50)
        XCTAssertEqual(contextItems.first?.title, items.last?.title) // Most recent first
    }
    
    func testAddToContext_ExceedsLimit() async throws {
        // Given
        let items = createTestItems(count: 150)
        
        // When
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // Then
        let contextItems = await contextMemoryService.getRecentContext()
        XCTAssertEqual(contextItems.count, 100) // Should be limited to window size
        XCTAssertEqual(contextItems.first?.title, items.last?.title) // Most recent first
        XCTAssertEqual(contextItems.last?.title, items[items.count - 100].title) // Oldest in window
    }
    
    func testGetRecentContext_EmptyContext() async throws {
        // When
        let contextItems = await contextMemoryService.getRecentContext()
        
        // Then
        XCTAssertEqual(contextItems.count, 0)
    }
    
    func testGetRecentContext_WithLimit() async throws {
        // Given
        let items = createTestItems(count: 50)
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let contextItems = await contextMemoryService.getRecentContext(limit: 10)
        
        // Then
        XCTAssertEqual(contextItems.count, 10)
        XCTAssertEqual(contextItems.first?.title, items.last?.title) // Most recent first
    }
    
    // MARK: - Summary Generation Tests
    
    func testGenerateDailySummary_Success() async throws {
        // Given
        let today = Date()
        let items = createTestItemsForDate(date: today, count: 10)
        
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let summary = await contextMemoryService.generateDailySummary(for: today)
        
        // Then
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.date, Calendar.current.startOfDay(for: today))
        XCTAssertEqual(summary?.itemCount, 10)
        XCTAssertFalse(summary?.summary.isEmpty ?? true)
        XCTAssertGreaterThan(summary?.categories.count ?? 0, 0)
    }
    
    func testGenerateDailySummary_NoItems() async throws {
        // Given
        let today = Date()
        
        // When
        let summary = await contextMemoryService.generateDailySummary(for: today)
        
        // Then
        XCTAssertNil(summary)
    }
    
    func testGenerateWeeklySummary_Success() async throws {
        // Given
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start
        
        // Create daily summaries for the week
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: startOfWeek)!
            let items = createTestItemsForDate(date: date, count: 5)
            
            for item in items {
                await contextMemoryService.addToContext(item)
            }
            
            _ = await contextMemoryService.generateDailySummary(for: date)
        }
        
        // When
        let summary = await contextMemoryService.generateWeeklySummary(for: startOfWeek)
        
        // Then
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.weekStart, startOfWeek)
        XCTAssertEqual(summary?.totalItems, 35) // 7 days * 5 items
        XCTAssertFalse(summary?.summary.isEmpty ?? true)
        XCTAssertGreaterThan(summary?.topCategories.count ?? 0, 0)
    }
    
    func testGenerateWeeklySummary_NoDailySummaries() async throws {
        // Given
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start
        
        // When
        let summary = await contextMemoryService.generateWeeklySummary(for: startOfWeek)
        
        // Then
        XCTAssertNil(summary)
    }
    
    func testGenerateMonthlySummary_Success() async throws {
        // Given
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())!.start
        
        // Create weekly summaries for the month
        for i in 0..<4 {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: i, to: startOfMonth)!
            
            // Create daily summaries for each week
            for j in 0..<7 {
                let date = Calendar.current.date(byAdding: .day, value: j, to: weekStart)!
                let items = createTestItemsForDate(date: date, count: 3)
                
                for item in items {
                    await contextMemoryService.addToContext(item)
                }
                
                _ = await contextMemoryService.generateDailySummary(for: date)
            }
            
            _ = await contextMemoryService.generateWeeklySummary(for: weekStart)
        }
        
        // When
        let summary = await contextMemoryService.generateMonthlySummary(for: startOfMonth)
        
        // Then
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.monthStart, startOfMonth)
        XCTAssertEqual(summary?.totalItems, 84) // 4 weeks * 7 days * 3 items
        XCTAssertFalse(summary?.summary.isEmpty ?? true)
        XCTAssertGreaterThan(summary?.achievements.count ?? 0, 0)
    }
    
    // MARK: - Context Pattern Analysis Tests
    
    func testAnalyzeContextPatterns_Success() async throws {
        // Given
        let items = createDiverseTestItems()
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let patterns = await contextMemoryService.analyzeContextPatterns()
        
        // Then
        XCTAssertNotNil(patterns)
        XCTAssertGreaterThan(patterns?.frequentCategories.count ?? 0, 0)
        XCTAssertGreaterThan(patterns?.commonTags.count ?? 0, 0)
        XCTAssertGreaterThan(patterns?.workPersonalRatio.work, 0)
        XCTAssertGreaterThan(patterns?.priorityDistribution.count, 0)
    }
    
    func testAnalyzeContextPatterns_EmptyContext() async throws {
        // When
        let patterns = await contextMemoryService.analyzeContextPatterns()
        
        // Then
        XCTAssertNil(patterns)
    }
    
    // MARK: - Context Retrieval Tests
    
    func testGetContextForTimeRange_Success() async throws {
        // Given
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let twoDaysAgo = now.addingTimeInterval(-48 * 60 * 60)
        
        let recentItems = createTestItemsForDate(date: now, count: 5)
        let oldItems = createTestItemsForDate(date: twoDaysAgo, count: 3)
        
        for item in recentItems + oldItems {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let contextItems = await contextMemoryService.getContextForTimeRange(from: oneDayAgo, to: now)
        
        // Then
        XCTAssertEqual(contextItems.count, 5) // Only recent items
        XCTAssertTrue(contextItems.allSatisfy { $0.createdAt >= oneDayAgo })
    }
    
    func testGetContextForTimeRange_NoItemsInRange() async throws {
        // Given
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let twoDaysAgo = now.addingTimeInterval(-48 * 60 * 60)
        let threeDaysAgo = now.addingTimeInterval(-72 * 60 * 60)
        
        let oldItems = createTestItemsForDate(date: threeDaysAgo, count: 3)
        for item in oldItems {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let contextItems = await contextMemoryService.getContextForTimeRange(from: twoDaysAgo, to: oneDayAgo)
        
        // Then
        XCTAssertEqual(contextItems.count, 0)
    }
    
    // MARK: - Context Search Tests
    
    func testSearchContext_ByTitle() async throws {
        // Given
        let items = [
            createTestItem(title: "Project Alpha Meeting", content: "Discussed project timeline"),
            createTestItem(title: "Beta Testing Results", content: "Found several bugs"),
            createTestItem(title: "Alpha Release Planning", content: "Planning the alpha release")
        ]
        
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let results = await contextMemoryService.searchContext(query: "Alpha")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.title.contains("Alpha") })
    }
    
    func testSearchContext_ByContent() async throws {
        // Given
        let items = [
            createTestItem(title: "Meeting Notes", content: "Discussed project timeline and milestones"),
            createTestItem(title: "Bug Report", content: "Found critical bug in authentication"),
            createTestItem(title: "Planning Session", content: "Timeline for next quarter")
        ]
        
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let results = await contextMemoryService.searchContext(query: "timeline")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.content.lowercased().contains("timeline") })
    }
    
    func testSearchContext_NoResults() async throws {
        // Given
        let items = createTestItems(count: 5)
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let results = await contextMemoryService.searchContext(query: "nonexistent")
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_AddToContext() {
        let items = createTestItems(count: 1000)
        
        measure {
            Task {
                for item in items {
                    await contextMemoryService.addToContext(item)
                }
            }
        }
    }
    
    func testPerformance_GetRecentContext() async throws {
        // Given
        let items = createTestItems(count: 100)
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When/Then
        measure {
            Task {
                _ = await contextMemoryService.getRecentContext()
            }
        }
    }
    
    func testPerformance_SearchContext() async throws {
        // Given
        let items = createTestItems(count: 100)
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When/Then
        measure {
            Task {
                _ = await contextMemoryService.searchContext(query: "test")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testAddToContext_DuplicateItems() async throws {
        // Given
        let item = createTestItem(title: "Duplicate Item", content: "Same content")
        
        // When
        await contextMemoryService.addToContext(item)
        await contextMemoryService.addToContext(item)
        
        // Then
        let contextItems = await contextMemoryService.getRecentContext()
        XCTAssertEqual(contextItems.count, 2) // Should allow duplicates
    }
    
    func testSearchContext_EmptyQuery() async throws {
        // Given
        let items = createTestItems(count: 5)
        for item in items {
            await contextMemoryService.addToContext(item)
        }
        
        // When
        let results = await contextMemoryService.searchContext(query: "")
        
        // Then
        XCTAssertEqual(results.count, 0) // Empty query should return no results
    }
    
    func testGetContextForTimeRange_InvalidRange() async throws {
        // Given
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        // When - Invalid range (from > to)
        let contextItems = await contextMemoryService.getContextForTimeRange(from: now, to: oneDayAgo)
        
        // Then
        XCTAssertEqual(contextItems.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestItems(count: Int) -> [PARAItem] {
        return (0..<count).map { i in
            createTestItem(title: "Test Item \(i)", content: "Content for item \(i)")
        }
    }
    
    private func createTestItemsForDate(date: Date, count: Int) -> [PARAItem] {
        return (0..<count).map { i in
            PARAItem(
                id: UUID(),
                title: "Item \(i) for \(DateFormatter.shortDate.string(from: date))",
                content: "Content for item \(i) on \(DateFormatter.shortDate.string(from: date))",
                contentType: ContentType.allCases.randomElement()!,
                paraCategory: PARACategory.allCases.randomElement()!,
                workPersonal: WorkPersonal.allCases.randomElement()!,
                priority: Priority.allCases.randomElement()!,
                createdAt: date
            )
        }
    }
    
    private func createTestItem(title: String, content: String) -> PARAItem {
        return PARAItem(
            id: UUID(),
            title: title,
            content: content,
            contentType: .task,
            paraCategory: .project,
            workPersonal: .work,
            priority: .medium,
            createdAt: Date()
        )
    }
    
    private func createDiverseTestItems() -> [PARAItem] {
        return [
            PARAItem(id: UUID(), title: "Work Task", content: "Complete project", contentType: .task, paraCategory: .project, workPersonal: .work, priority: .high, createdAt: Date()),
            PARAItem(id: UUID(), title: "Personal Note", content: "Remember to call mom", contentType: .journal, paraCategory: .area, workPersonal: .personal, priority: .low, createdAt: Date()),
            PARAItem(id: UUID(), title: "Financial Entry", content: "Paid rent", contentType: .financial, paraCategory: .area, workPersonal: .personal, priority: .medium, createdAt: Date()),
            PARAItem(id: UUID(), title: "Knowledge Entry", content: "Swift best practices", contentType: .knowledge, paraCategory: .resource, workPersonal: .work, priority: .medium, createdAt: Date()),
            PARAItem(id: UUID(), title: "Therapy Note", content: "Session notes", contentType: .therapy, paraCategory: .area, workPersonal: .personal, priority: .high, createdAt: Date())
        ]
    }
}

// MARK: - Mock Repository

class MockPARARepository: PARARepositoryProtocol {
    private var items: [PARAItem] = []
    private var dailySummaries: [DailySummary] = []
    private var weeklySummaries: [WeeklySummary] = []
    private var monthlySummaries: [MonthlySummary] = []
    
    func save(_ item: PARAItem) async throws {
        items.append(item)
    }
    
    func fetch(id: UUID) async throws -> PARAItem? {
        return items.first { $0.id == id }
    }
    
    func fetchAll() async throws -> [PARAItem] {
        return items
    }
    
    func update(_ item: PARAItem) async throws {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    
    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }
    
    func search(query: String) async throws -> [PARAItem] {
        return items.filter { item in
            item.title.lowercased().contains(query.lowercased()) ||
            item.content.lowercased().contains(query.lowercased())
        }
    }
    
    func fetchItems(from startDate: Date, to endDate: Date) async throws -> [PARAItem] {
        return items.filter { item in
            item.createdAt >= startDate && item.createdAt <= endDate
        }
    }
    
    // Summary methods
    func saveDailySummary(_ summary: DailySummary) async throws {
        dailySummaries.append(summary)
    }
    
    func fetchDailySummary(for date: Date) async throws -> DailySummary? {
        let targetDate = Calendar.current.startOfDay(for: date)
        return dailySummaries.first { Calendar.current.startOfDay(for: $0.date) == targetDate }
    }
    
    func saveWeeklySummary(_ summary: WeeklySummary) async throws {
        weeklySummaries.append(summary)
    }
    
    func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary? {
        return weeklySummaries.first { $0.weekStart == weekStart }
    }
    
    func saveMonthlySummary(_ summary: MonthlySummary) async throws {
        monthlySummaries.append(summary)
    }
    
    func fetchMonthlySummary(for monthStart: Date) async throws -> MonthlySummary? {
        return monthlySummaries.first { $0.monthStart == monthStart }
    }
    
    func fetchDailySummaries(from startDate: Date, to endDate: Date) async throws -> [DailySummary] {
        return dailySummaries.filter { summary in
            summary.date >= startDate && summary.date <= endDate
        }
    }
    
    func fetchWeeklySummaries(from startDate: Date, to endDate: Date) async throws -> [WeeklySummary] {
        return weeklySummaries.filter { summary in
            summary.weekStart >= startDate && summary.weekStart <= endDate
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
} 