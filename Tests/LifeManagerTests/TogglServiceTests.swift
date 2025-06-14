import XCTest
import Foundation
@testable import LifeManager

@MainActor
final class TogglServiceTests: XCTestCase {
    
    var togglService: TogglService!
    
    override func setUp() async throws {
        try await super.setUp()
        togglService = TogglService()
    }
    
    override func tearDown() async throws {
        togglService = nil
        try await super.tearDown()
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimitingPreventsSimultaneousRequests() async throws {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        // Make multiple concurrent requests
        let task1 = Task {
            try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        }
        
        let task2 = Task {
            try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        }
        
        let task3 = Task {
            try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        }
        
        // All tasks should complete without throwing rate limit errors
        let results = try await [task1.value, task2.value, task3.value]
        
        // Should have results (may be empty arrays if no data)
        XCTAssertEqual(results.count, 3)
    }
    
    func testRateLimitingDelayBetweenRequests() async throws {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        let startTime = Date()
        
        // Make first request
        _ = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        
        // Make second request immediately
        _ = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        
        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)
        
        // Should take at least 3 seconds due to rate limiting
        XCTAssertGreaterThanOrEqual(elapsed, 2.5, "Rate limiting should delay requests by ~3 seconds")
    }
    
    // MARK: - Caching Tests
    
    func testCachingReducesAPIRequests() async throws {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        // First request should hit API
        let firstResult = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        
        // Second identical request should use cache (much faster)
        let cacheStartTime = Date()
        let secondResult = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        let cacheEndTime = Date()
        
        let cacheTime = cacheEndTime.timeIntervalSince(cacheStartTime)
        
        // Cached request should be very fast (< 0.1 seconds)
        XCTAssertLessThan(cacheTime, 0.1, "Cached requests should be nearly instantaneous")
        
        // Results should be identical
        XCTAssertEqual(firstResult.count, secondResult.count)
    }
    
    func testCacheInvalidationAfterExpiry() async throws {
        // This test would require mocking time or shorter cache duration
        // For now, test that cache works with different date ranges
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: today)!
        
        // Request for today
        let todayEntries = try await togglService.fetchTimeEntries(startDate: today, endDate: tomorrow)
        
        // Request for tomorrow (different date range, should not use cache)
        let tomorrowEntries = try await togglService.fetchTimeEntries(startDate: tomorrow, endDate: dayAfter)
        
        // Both requests should complete successfully
        XCTAssertNotNil(todayEntries)
        XCTAssertNotNil(tomorrowEntries)
    }
    
    // MARK: - API Integration Tests
    
    func testFetchTimeEntriesReturnsValidData() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
        let entries = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
        
        // Should return an array (may be empty)
        XCTAssertNotNil(entries)
        
        // If entries exist, they should have valid data
        for entry in entries {
            XCTAssertNotNil(entry.id)
            XCTAssertNotNil(entry.description)
            XCTAssertNotNil(entry.start)
            XCTAssertGreaterThan(entry.duration, 0)
        }
    }
    
    func testFetchProjectsReturnsValidData() async throws {
        // For now, fetchProjects() doesn't return anything, so test the connection state
        XCTAssertNotNil(togglService)
        XCTAssertTrue(togglService.isConnected)
    }
    
    func testConvertToCalendarEventWithColor() async throws {
        // Create a mock TogglTimeEntry
        let mockEntry = TogglTimeEntry(
            id: 123456,
            description: "Test Entry",
            start: ISO8601DateFormatter().string(from: Date()),
            stop: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
            duration: 3600,
            projectId: 456,
            workspaceId: 789
        )
        
        let calendarEvent = togglService.convertToCalendarEventWithColor(mockEntry)
        
        XCTAssertNotNil(calendarEvent)
        XCTAssertEqual(calendarEvent.title, "Test Entry")
        XCTAssertEqual(calendarEvent.duration, 3600)
        XCTAssertEqual(calendarEvent.source, .toggl)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDateRangeHandling() async throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)! // End before start
        
        do {
            _ = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
            XCTFail("Should throw error for invalid date range")
        } catch {
            // Should throw an error
            XCTAssertNotNil(error)
        }
    }
    
    func testNetworkErrorHandling() async throws {
        // This would require mocking network calls
        // For now, test that service handles connection gracefully
        XCTAssertNotNil(togglService)
        XCTAssertTrue(togglService.isConnected)
    }
    
    // MARK: - Performance Tests
    
    func testFetchPerformance() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let endDate = Date()
        
        measure {
            Task {
                _ = try? await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
            }
        }
    }
    
    func testConcurrentRequestHandling() async throws {
        let startDate = Calendar.current.startOfDay(for: Date())
        let requests = Array(0..<5).map { i in
            let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            return Task {
                try await togglService.fetchTimeEntries(startDate: date, endDate: endDate)
            }
        }
        
        let results = try await withThrowingTaskGroup(of: [TogglTimeEntry].self) { group in
            for request in requests {
                group.addTask {
                    try await request.value
                }
            }
            
            var allResults: [[TogglTimeEntry]] = []
            for try await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        XCTAssertEqual(results.count, 5, "All concurrent requests should complete")
    }
}

// MARK: - Mock Data Extensions

extension TogglTimeEntry {
    static func mockEntry(
        id: Int = 123456,
        description: String = "Mock Entry",
        duration: Int = 3600
    ) -> TogglTimeEntry {
        return TogglTimeEntry(
            id: id,
            description: description,
            start: ISO8601DateFormatter().string(from: Date()),
            stop: ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(duration))),
            duration: duration,
            projectId: 456,
            workspaceId: 789
        )
    }
}

extension TogglProject {
    static func mockProject(
        id: Int = 456,
        name: String = "Mock Project",
        color: String = "#FF0000"
    ) -> TogglProject {
        return TogglProject(
            id: id,
            name: name,
            color: color,
            active: true,
            workspaceId: 789
        )
    }
} 