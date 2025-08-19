//
// EnhancedFallbackProcessingTests.swift
// LifeManagerTests
//
// Integration tests for enhanced fallback processing in LLMBrainDumpProcessor
// Testing comprehensive fallback when API is unavailable
//

import XCTest
@testable import LifeManager

@MainActor
final class EnhancedFallbackProcessingTests: XCTestCase {
    
    // MARK: - Properties
    
    private var processor: LLMBrainDumpProcessor!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        processor = LLMBrainDumpProcessor()
    }
    
    override func tearDown() async throws {
        processor = nil
        try await super.tearDown()
    }
    
    // MARK: - Multi-Strategy Parsing Tests
    
    func testFallbackParsing_HandlesLineBasedInput() async throws {
        // Arrange
        let input = """
        - Complete project documentation
        - Review pull requests
        - Schedule team meeting for tomorrow
        * Update dependencies
        • Fix critical bug in authentication
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertGreaterThanOrEqual(result.suggestedItems.count, 5, "Should parse all list items")
        XCTAssertTrue(result.requiresReview, "Fallback results should require review")
        XCTAssertEqual(result.confidence, 0.6, accuracy: 0.1, "Should have moderate confidence")
    }
    
    func testFallbackParsing_HandlesSentenceBasedInput() async throws {
        // Arrange
        let input = "Need to finish the report by Friday. Meeting with client at 2pm. Remember to call John about the proposal."
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertGreaterThanOrEqual(result.suggestedItems.count, 3, "Should parse sentences")
        for item in result.suggestedItems {
            XCTAssertFalse(item.title.isEmpty, "Each item should have a title")
            XCTAssertFalse(item.content.isEmpty, "Each item should have content")
        }
    }
    
    func testFallbackParsing_HandlesSingleBlock() async throws {
        // Arrange
        let input = "This is a single block of text without clear separators that should be processed as one item"
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertGreaterThanOrEqual(result.suggestedItems.count, 1, "Should create at least one item")
        XCTAssertEqual(result.suggestedItems.first?.content, input, "Should preserve full content")
    }
    
    // MARK: - Content Type Detection Tests
    
    func testFallbackDetection_IdentifiesTasks() async throws {
        // Arrange
        let input = """
        TODO: Complete the presentation
        Task: Review code changes
        Need to update documentation
        Must finish testing by tomorrow
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let taskItems = result.suggestedItems.filter { $0.contentType == .task }
        XCTAssertFalse(taskItems.isEmpty, "Should identify tasks")
    }
    
    func testFallbackDetection_IdentifiesNotes() async throws {
        // Arrange
        let input = """
        Note: Remember the discussion points from meeting
        Idea: Create automated testing framework
        Research: Look into new API endpoints
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let noteItems = result.suggestedItems.filter { 
            $0.contentType == .note || $0.contentType == .resource
        }
        XCTAssertFalse(noteItems.isEmpty, "Should identify notes and ideas")
    }
    
    func testFallbackDetection_IdentifiesAppointments() async throws {
        // Arrange
        let input = """
        Meeting: Team standup tomorrow at 10am
        Appointment: Doctor visit next Tuesday
        Schedule dentist appointment for Friday
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let appointmentItems = result.suggestedItems.filter { $0.contentType == .appointment }
        XCTAssertFalse(appointmentItems.isEmpty, "Should identify appointments")
    }
    
    func testFallbackDetection_IdentifiesFinancial() async throws {
        // Arrange
        let input = """
        Spent $45.50 on groceries
        Bought coffee for $4.75
        Received $500 payment from client
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let financialItems = result.suggestedItems.filter { $0.contentType == .financial }
        XCTAssertFalse(financialItems.isEmpty, "Should identify financial transactions")
    }
    
    // MARK: - Priority Detection Tests
    
    func testFallbackPriority_DetectsUrgent() async throws {
        // Arrange
        let input = """
        URGENT: Fix production bug
        Critical issue with payment system
        ASAP: Send report to CEO
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let urgentItems = result.suggestedItems.filter { $0.priority == .urgent }
        XCTAssertFalse(urgentItems.isEmpty, "Should detect urgent priority")
    }
    
    func testFallbackPriority_DetectsImportant() async throws {
        // Arrange
        let input = """
        Important: Review quarterly goals
        High priority task for next sprint
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let highPriorityItems = result.suggestedItems.filter { $0.priority == .high }
        XCTAssertFalse(highPriorityItems.isEmpty, "Should detect high priority")
    }
    
    // MARK: - Date Extraction Tests
    
    func testFallbackDates_ExtractsRelativeDates() async throws {
        // Arrange
        let input = """
        Meeting tomorrow at 2pm
        Deadline next week
        Review document today
        Submit report on Monday
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let itemsWithDates = result.suggestedItems.filter { $0.dueDate != nil }
        XCTAssertFalse(itemsWithDates.isEmpty, "Should extract dates")
    }
    
    // MARK: - Work/Personal Classification Tests
    
    func testFallbackClassification_DetectsWork() async throws {
        // Arrange
        let input = """
        Client meeting at office
        Update project timeline
        Team collaboration on new feature
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let workItems = result.suggestedItems.filter { $0.workPersonal == .work }
        XCTAssertFalse(workItems.isEmpty, "Should classify as work")
    }
    
    func testFallbackClassification_DetectsPersonal() async throws {
        // Arrange
        let input = """
        Family dinner tonight
        Personal health checkup
        Home improvement project
        Exercise routine
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let personalItems = result.suggestedItems.filter { $0.workPersonal == .personal }
        XCTAssertFalse(personalItems.isEmpty, "Should classify as personal")
    }
    
    // MARK: - Tag Extraction Tests
    
    func testFallbackTags_ExtractsHashtags() async throws {
        // Arrange
        let input = """
        Review code #development #urgent
        Meeting notes #teamwork #planning
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let itemsWithTags = result.suggestedItems.filter { !$0.tags.isEmpty }
        XCTAssertFalse(itemsWithTags.isEmpty, "Should extract hashtags")
        
        if let firstItem = itemsWithTags.first {
            XCTAssertTrue(firstItem.tags.contains("development") || firstItem.tags.contains("teamwork"))
        }
    }
    
    func testFallbackTags_AddsContextualTags() async throws {
        // Arrange
        let input = """
        Urgent: Fix critical bug
        Important review needed
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let itemsWithTags = result.suggestedItems.filter { 
            $0.tags.contains("urgent") || $0.tags.contains("important")
        }
        XCTAssertFalse(itemsWithTags.isEmpty, "Should add contextual tags")
    }
    
    // MARK: - Relationship Detection Tests
    
    func testFallbackRelationships_DetectsBasicSimilarity() async throws {
        // Arrange
        let input = """
        Update user authentication module
        Fix authentication bug in login
        Review authentication documentation
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertFalse(result.analysisResult.crossItemRelationships.isEmpty, "Should detect relationships")
    }
    
    func testFallbackRelationships_DetectsTemporalSequence() async throws {
        // Arrange
        let input = """
        First: Setup development environment
        Then: Install dependencies
        Finally: Run tests
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        let sequenceRelationships = result.analysisResult.crossItemRelationships.filter {
            $0.relationshipType == .sequence
        }
        XCTAssertFalse(sequenceRelationships.isEmpty, "Should detect sequences")
    }
    
    // MARK: - Metadata Generation Tests
    
    func testFallbackMetadata_GeneratesProcessingInfo() async throws {
        // Arrange
        let input = "Test input for metadata"
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertTrue(result.processingMetadata.aiServicesUsed.contains("Enhanced Fallback"))
        XCTAssertTrue(result.processingMetadata.aiServicesUsed.contains("Pattern Matching"))
        XCTAssertGreaterThanOrEqual(result.processingMetadata.rulesApplied, 0)
    }
    
    func testFallbackMetadata_GeneratesClarificationQuestions() async throws {
        // Arrange
        let input = """
        Task without due date
        Another task without priority
        Complex item needing review
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertFalse(result.clarificationQuestions.isEmpty, "Should generate questions")
        XCTAssertTrue(
            result.clarificationQuestions.contains { $0.contains("due date") } ||
            result.clarificationQuestions.contains { $0.contains("API key") },
            "Should ask relevant questions"
        )
    }
    
    func testFallbackMetadata_GeneratesOptimizationSuggestions() async throws {
        // Arrange
        let input = "Simple test input"
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertFalse(result.optimizationSuggestions.isEmpty, "Should provide suggestions")
        XCTAssertTrue(
            result.optimizationSuggestions.contains { $0.contains("API key") },
            "Should suggest API configuration"
        )
    }
    
    // MARK: - Pattern Analysis Tests
    
    func testFallbackPatterns_ExtractsContentPatterns() async throws {
        // Arrange
        let input = """
        Task 1: Review code
        Task 2: Write tests
        Task 3: Deploy changes
        Note: Remember to update docs
        Note: Check with team
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertFalse(result.contextualInsights.recentPatterns.isEmpty, "Should extract patterns")
        XCTAssertTrue(
            result.contextualInsights.recentPatterns.contains { $0.contains("task") },
            "Should identify task pattern"
        )
    }
    
    func testFallbackPatterns_SuggestsWorkflows() async throws {
        // Arrange
        let input = """
        Urgent task 1
        Urgent task 2
        Meeting tomorrow
        Appointment next week
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertFalse(result.contextualInsights.suggestedWorkflows.isEmpty, "Should suggest workflows")
    }
    
    // MARK: - Complex Input Tests
    
    func testFallbackComplex_HandlesMixedFormat() async throws {
        // Arrange
        let input = """
        Project Alpha Updates:
        - TODO: Complete design mockups
        - Meeting with stakeholders tomorrow at 3pm
        - Budget: Spent $1,200 on software licenses
        
        Personal reminders:
        * Call dentist #health
        * Family dinner on Friday #personal
        
        Random thoughts: Need to research new frameworks. Important to maintain work-life balance.
        """
        
        // Act
        let result = try await processor.processBrainDumpFallback(input)
        
        // Assert
        XCTAssertGreaterThanOrEqual(result.suggestedItems.count, 5, "Should parse complex input")
        
        // Check variety of content types
        let contentTypes = Set(result.suggestedItems.map { $0.contentType })
        XCTAssertGreaterThan(contentTypes.count, 1, "Should identify multiple content types")
        
        // Check work/personal classification
        let workItems = result.suggestedItems.filter { $0.workPersonal == .work }
        let personalItems = result.suggestedItems.filter { $0.workPersonal == .personal }
        XCTAssertFalse(workItems.isEmpty, "Should have work items")
        XCTAssertFalse(personalItems.isEmpty, "Should have personal items")
    }
    
    // MARK: - Performance Tests
    
    func testFallbackPerformance_LargeInput() throws {
        // Arrange
        let largeInput = (0..<100).map { "Task \($0): Do something important" }.joined(separator: "\n")
        
        // Measure
        self.measure {
            let expectation = self.expectation(description: "Large input")
            
            Task {
                _ = try? await processor.processBrainDumpFallback(largeInput)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
}