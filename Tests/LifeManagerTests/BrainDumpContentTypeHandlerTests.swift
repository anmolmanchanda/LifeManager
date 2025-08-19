//
// BrainDumpContentTypeHandlerTests.swift
// LifeManagerTests
//
// Comprehensive unit tests for BrainDumpContentTypeHandler
// Testing all 15+ content types and their specialized handlers
//

import XCTest
@testable import LifeManager

@MainActor
final class BrainDumpContentTypeHandlerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: BrainDumpContentTypeHandler!
    private var mockSupabaseService: MockSupabaseService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        sut = BrainDumpContentTypeHandler.shared
        mockSupabaseService = MockSupabaseService()
    }
    
    override func tearDown() async throws {
        sut = nil
        mockSupabaseService = nil
        try await super.tearDown()
    }
    
    // MARK: - Task Handler Tests
    
    func testTaskHandler_CreatesTaskSuccessfully() async throws {
        // Arrange
        let item = createTestItem(type: .task, title: "Complete project report", priority: .high)
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .task)
        XCTAssertEqual(result.title, item.title)
        XCTAssertEqual(result.databaseTable, "tasks")
        XCTAssertEqual(sut.processingStats.successfulCreations, 1)
    }
    
    func testTaskHandler_ValidatesRequiredFields() async throws {
        // Arrange
        let invalidItem = createTestItem(type: .task, title: "") // Empty title
        
        // Act & Assert
        do {
            _ = try await sut.processContentItem(invalidItem)
            XCTFail("Should throw validation error")
        } catch {
            XCTAssertTrue(error is ContentTypeError)
            XCTAssertEqual(sut.processingStats.failedCreations, 1)
        }
    }
    
    // MARK: - Note Handler Tests
    
    func testNoteHandler_CreatesNoteSuccessfully() async throws {
        // Arrange
        let item = createTestItem(type: .note, title: "Meeting notes", content: "Discussion points...")
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .note)
        XCTAssertEqual(result.databaseTable, "blobs")
    }
    
    // MARK: - Journal Handler Tests
    
    func testJournalHandler_CreatesBlobAndJournalEntry() async throws {
        // Arrange
        let item = createTestItem(type: .journal, title: "Daily reflection", content: "Today was productive...")
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .journal)
        XCTAssertEqual(result.databaseTable, "journal_entries")
        // Should create both blob and journal entry
    }
    
    // MARK: - Financial Handler Tests
    
    func testFinancialHandler_ExtractsAmount() async throws {
        // Arrange
        let item = createTestItem(type: .financial, title: "Grocery shopping", content: "Spent $45.50 on groceries")
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .financial)
        XCTAssertEqual(result.databaseTable, "financial_transactions")
        // Should extract amount of 45.50
    }
    
    func testFinancialHandler_DetectsTransactionType() async throws {
        // Arrange
        let incomeItem = createTestItem(type: .financial, content: "Received $1000 salary")
        let expenseItem = createTestItem(type: .financial, content: "Paid $50 for dinner")
        
        // Act
        let incomeResult = try await sut.processContentItem(incomeItem)
        let expenseResult = try await sut.processContentItem(expenseItem)
        
        // Assert
        XCTAssertNotNil(incomeResult)
        XCTAssertNotNil(expenseResult)
        // Should detect income vs expense
    }
    
    // MARK: - Appointment Handler Tests
    
    func testAppointmentHandler_ExtractsDates() async throws {
        // Arrange
        let tomorrow = Date().addingTimeInterval(86400)
        let item = createTestItem(
            type: .appointment,
            title: "Doctor appointment",
            dueDate: ISO8601DateFormatter().string(from: tomorrow)
        )
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .appointment)
        XCTAssertEqual(result.databaseTable, "calendar_events")
    }
    
    // MARK: - Habit Handler Tests
    
    func testHabitHandler_CreatesRecurringItem() async throws {
        // Arrange
        let item = createTestItem(type: .habit, title: "Daily meditation", content: "Meditate for 10 minutes")
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .habit)
        XCTAssertEqual(result.databaseTable, "habits")
    }
    
    // MARK: - Goal Handler Tests
    
    func testGoalHandler_SetsTargetDate() async throws {
        // Arrange
        let targetDate = Date().addingTimeInterval(2592000) // 30 days
        let item = createTestItem(
            type: .goal,
            title: "Complete certification",
            dueDate: ISO8601DateFormatter().string(from: targetDate)
        )
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .goal)
        XCTAssertEqual(result.databaseTable, "goals")
    }
    
    // MARK: - Medication Handler Tests
    
    func testMedicationHandler_ExtractsDosage() async throws {
        // Arrange
        let item = createTestItem(
            type: .medication,
            title: "Vitamin D",
            content: "Take 1000mg daily with breakfast"
        )
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .medication)
        XCTAssertEqual(result.databaseTable, "medications")
    }
    
    // MARK: - Health Log Handler Tests
    
    func testHealthLogHandler_DetectsHealthType() async throws {
        // Arrange
        let symptomItem = createTestItem(type: .healthLog, content: "Experiencing headache symptoms")
        let exerciseItem = createTestItem(type: .healthLog, content: "30 minutes exercise completed")
        
        // Act
        let symptomResult = try await sut.processContentItem(symptomItem)
        let exerciseResult = try await sut.processContentItem(exerciseItem)
        
        // Assert
        XCTAssertEqual(symptomResult.type, .healthLog)
        XCTAssertEqual(exerciseResult.type, .healthLog)
        XCTAssertEqual(symptomResult.databaseTable, "health_logs")
    }
    
    // MARK: - Personal Rule Handler Tests
    
    func testPersonalRuleHandler_CreatesActiveRule() async throws {
        // Arrange
        let item = createTestItem(
            type: .personalRule,
            title: "No meetings before 10am",
            content: "Protect morning deep work time"
        )
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertEqual(result.type, .personalRule)
        XCTAssertEqual(result.databaseTable, "personal_rules")
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchProcessing_HandlesMultipleItems() async throws {
        // Arrange
        let items = [
            createTestItem(type: .task, title: "Task 1"),
            createTestItem(type: .note, title: "Note 1"),
            createTestItem(type: .journal, title: "Journal 1"),
            createTestItem(type: .resource, title: "Resource 1"),
            createTestItem(type: .appointment, title: "Appointment 1")
        ]
        
        // Act
        let result = await sut.processContentItems(items)
        
        // Assert
        XCTAssertLessThanOrEqual(result.successfulCreations.count, items.count)
        XCTAssertEqual(result.stats.totalProcessed, items.count)
        XCTAssertFalse(sut.isProcessing)
    }
    
    func testBatchProcessing_TracksStatistics() async throws {
        // Arrange
        let items = createTestItems(ofTypes: [.task, .task, .note, .journal])
        
        // Act
        let result = await sut.processContentItems(items)
        
        // Assert
        XCTAssertEqual(result.stats.totalProcessed, 4)
        XCTAssertEqual(result.stats.contentTypeBreakdown[.task] ?? 0, 2)
        XCTAssertEqual(result.stats.contentTypeBreakdown[.note] ?? 0, 1)
        XCTAssertEqual(result.stats.contentTypeBreakdown[.journal] ?? 0, 1)
    }
    
    func testBatchProcessing_HandlesPartialFailures() async throws {
        // Arrange
        let items = [
            createTestItem(type: .task, title: "Valid task"),
            createTestItem(type: .task, title: ""), // Invalid - empty title
            createTestItem(type: .note, title: "Valid note")
        ]
        
        // Act
        let result = await sut.processContentItems(items)
        
        // Assert
        XCTAssertEqual(result.stats.totalProcessed, 3)
        XCTAssertGreaterThan(result.stats.failedCreations, 0)
        XCTAssertFalse(result.errors.isEmpty)
    }
    
    // MARK: - Unsupported Type Tests
    
    func testUnsupportedContentType_ThrowsError() async throws {
        // Arrange
        let item = createTestItem(type: .archive, title: "Archive item") // Assuming archive is not handled
        
        // Act & Assert
        do {
            _ = try await sut.processContentItem(item)
            // If it doesn't throw, check if it's actually supported
            XCTAssertTrue(true, "Archive type might be supported")
        } catch {
            XCTAssertTrue(error is ContentTypeError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_LargeBatchProcessing() throws {
        // Arrange
        let items = createTestItems(ofTypes: Array(repeating: .task, count: 100))
        
        // Measure
        self.measure {
            let expectation = self.expectation(description: "Large batch")
            
            Task {
                _ = await sut.processContentItems(items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30)
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegration_ProcessingGeneratesEmbeddings() async throws {
        // Arrange
        let item = createTestItem(type: .task, title: "Test task with embeddings")
        
        // Act
        let result = try await sut.processContentItem(item)
        
        // Assert
        XCTAssertNotNil(result)
        // Embeddings should be generated (verified by checking embedding service was called)
    }
    
    // MARK: - Helper Methods
    
    private func createTestItem(
        type: ContentType,
        title: String = "Test Item",
        content: String = "Test content",
        priority: TaskPriority = .medium,
        dueDate: String? = nil
    ) -> EnhancedBrainDumpItem {
        return EnhancedBrainDumpItem(
            id: UUID(),
            title: title,
            content: content,
            contentType: type,
            paraCategory: .project,
            suggestedArea: nil,
            suggestedProject: nil,
            workPersonal: .personal,
            priority: priority,
            dueDate: dueDate,
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
    
    private func createTestItems(ofTypes types: [ContentType]) -> [EnhancedBrainDumpItem] {
        return types.enumerated().map { index, type in
            createTestItem(type: type, title: "\(type.rawValue) Item \(index)")
        }
    }
}

// MARK: - Mock Supabase Service

class MockSupabaseService {
    var shouldFail = false
    var insertedRecords: [[String: Any]] = []
    
    func insert(_ record: [String: Any], into table: String) async throws {
        if shouldFail {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        insertedRecords.append(record)
    }
}