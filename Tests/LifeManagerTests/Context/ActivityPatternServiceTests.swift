//
// ActivityPatternServiceTests.swift
// LifeManagerTests
//
// Unit tests for ActivityPatternService
//

import XCTest
@testable import LifeManager

final class ActivityPatternServiceTests: XCTestCase {
    
    var sut: ActivityPatternService!
    
    override func setUp() {
        super.setUp()
        sut = ActivityPatternService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Pattern Detection Tests
    
    func testUpdatePatterns_WithEmptyItems_SetsLowActivity() async {
        // Given
        let items: [ContextItem] = []
        
        // When
        await sut.updatePatterns(with: items)
        
        // Then
        XCTAssertEqual(sut.currentActivityLevel, .low)
        XCTAssertTrue(sut.peakHours.isEmpty)
        XCTAssertEqual(sut.dailyAverage, 0.0)
    }
    
    func testUpdatePatterns_WithMorningItems_IdentifiesPeakHours() async {
        // Given
        let calendar = Calendar.current
        let items = createItemsForHours([8, 9, 10, 11], count: 10)
        
        // When
        await sut.updatePatterns(with: items)
        
        // Then
        XCTAssertTrue(sut.peakHours.contains(8))
        XCTAssertTrue(sut.peakHours.contains(9))
        XCTAssertTrue(sut.peakHours.contains(10))
        XCTAssertTrue(sut.peakHours.contains(11))
    }
    
    func testUpdatePatterns_WithHighActivity_SetsHighLevel() async {
        // Given
        let items = createItemsForHours(Array(0..<24), count: 50)
        
        // When
        await sut.updatePatterns(with: items)
        
        // Then
        XCTAssertEqual(sut.currentActivityLevel, .high)
        XCTAssertGreaterThan(sut.dailyAverage, 40)
    }
    
    func testAnalyzeHourlyDistribution_IdentifiesCorrectPeaks() {
        // Given
        let items = createItemsWithDistribution([
            8: 15,   // Morning peak
            9: 20,
            10: 18,
            14: 25,  // Afternoon peak
            15: 22,
            20: 10   // Evening activity
        ])
        
        // When
        let distribution = sut.analyzeHourlyDistribution(items)
        
        // Then
        XCTAssertEqual(distribution[14], 25)
        XCTAssertEqual(distribution[9], 20)
        XCTAssertTrue(distribution[14]! > distribution[20]!)
    }
    
    // MARK: - Window Size Prediction Tests
    
    func testPredictOptimalWindowSize_LowActivity_ReturnsMinimum() {
        // Given
        sut.currentActivityLevel = .low
        sut.dailyAverage = 5.0
        
        // When
        let size = sut.predictOptimalWindowSize()
        
        // Then
        XCTAssertEqual(size, 50)
    }
    
    func testPredictOptimalWindowSize_HighActivity_ReturnsMaximum() {
        // Given
        sut.currentActivityLevel = .high
        sut.dailyAverage = 150.0
        
        // When
        let size = sut.predictOptimalWindowSize()
        
        // Then
        XCTAssertEqual(size, 200)
    }
    
    func testPredictOptimalWindowSize_MediumActivity_ReturnsProportional() {
        // Given
        sut.currentActivityLevel = .medium
        sut.dailyAverage = 75.0
        
        // When
        let size = sut.predictOptimalWindowSize()
        
        // Then
        XCTAssertGreaterThan(size, 50)
        XCTAssertLessThan(size, 200)
        XCTAssertEqual(size, 100) // Expected for medium activity
    }
    
    // MARK: - Performance Metrics Tests
    
    func testGetPerformanceMetrics_ReturnsCorrectMetrics() {
        // Given
        sut.currentActivityLevel = .high
        sut.dailyAverage = 120.0
        sut.peakHours = [9, 10, 14, 15]
        
        // When
        let metrics = sut.getPerformanceMetrics()
        
        // Then
        XCTAssertEqual(metrics["activityLevel"], "high")
        XCTAssertEqual(metrics["dailyAverage"], "120.0")
        XCTAssertEqual(metrics["peakHoursCount"], "4")
        XCTAssertNotNil(metrics["suggestedWindowSize"])
    }
    
    // MARK: - Edge Cases
    
    func testUpdatePatterns_WithFutureItems_HandlesGracefully() async {
        // Given
        let futureDate = Date().addingTimeInterval(86400 * 30) // 30 days future
        let items = [createContextItem(date: futureDate)]
        
        // When
        await sut.updatePatterns(with: items)
        
        // Then
        XCTAssertEqual(sut.currentActivityLevel, .low)
        XCTAssertEqual(sut.dailyAverage, 0.0)
    }
    
    func testConcurrentUpdates_MaintainsDataIntegrity() async {
        // Given
        let items1 = createItemsForHours([8, 9], count: 10)
        let items2 = createItemsForHours([14, 15], count: 10)
        
        // When - Concurrent updates
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.sut.updatePatterns(with: items1)
            }
            group.addTask {
                await self.sut.updatePatterns(with: items2)
            }
        }
        
        // Then
        XCTAssertNotNil(sut.currentActivityLevel)
        XCTAssertGreaterThanOrEqual(sut.dailyAverage, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createItemsForHours(_ hours: [Int], count: Int) -> [ContextItem] {
        var items: [ContextItem] = []
        let calendar = Calendar.current
        
        for hour in hours {
            for i in 0..<count {
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = hour
                components.minute = i % 60
                
                if let date = calendar.date(from: components) {
                    items.append(createContextItem(date: date))
                }
            }
        }
        
        return items
    }
    
    private func createItemsWithDistribution(_ distribution: [Int: Int]) -> [ContextItem] {
        var items: [ContextItem] = []
        let calendar = Calendar.current
        
        for (hour, count) in distribution {
            for i in 0..<count {
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = hour
                components.minute = i % 60
                
                if let date = calendar.date(from: components) {
                    items.append(createContextItem(date: date))
                }
            }
        }
        
        return items
    }
    
    private func createContextItem(date: Date = Date()) -> ContextItem {
        return ContextItem(
            id: UUID(),
            content: "Test item",
            timestamp: date,
            category: .task,
            workPersonal: .personal,
            metadata: [:],
            embeddings: nil
        )
    }
}

// MARK: - Performance Tests

extension ActivityPatternServiceTests {
    
    func testPerformance_UpdatePatternsWithLargeDataset() {
        // Given
        let items = createItemsForHours(Array(0..<24), count: 100) // 2400 items
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Pattern update")
            
            Task {
                await sut.updatePatterns(with: items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testPerformance_PredictOptimalWindowSize() {
        // Given
        sut.currentActivityLevel = .high
        sut.dailyAverage = 100.0
        
        // When & Then
        measure {
            _ = sut.predictOptimalWindowSize()
        }
    }
}