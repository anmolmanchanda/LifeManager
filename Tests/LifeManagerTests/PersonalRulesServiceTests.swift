import XCTest
import Foundation
@testable import LifeManager

class PersonalRulesServiceTests: XCTestCase {
    var personalRulesService: PersonalRulesService!
    var mockRepository: MockPersonalRulesRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPersonalRulesRepository()
        personalRulesService = PersonalRulesService(repository: mockRepository)
    }
    
    override func tearDown() {
        personalRulesService = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Rule Creation Tests
    
    func testCreateRuleFromCorrections_Success() async throws {
        // Given
        let corrections = [
            createTestCorrection(originalCategory: .area, correctedCategory: .project, pattern: "meeting"),
            createTestCorrection(originalCategory: .area, correctedCategory: .project, pattern: "meeting agenda"),
            createTestCorrection(originalCategory: .area, correctedCategory: .project, pattern: "team meeting")
        ]
        
        // When
        let rule = await personalRulesService.createRuleFromCorrections(corrections)
        
        // Then
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.pattern, "meeting")
        XCTAssertEqual(rule?.action.type, .changeCategory)
        XCTAssertEqual(rule?.action.newCategory, .project)
        XCTAssertEqual(rule?.confidence, 1.0) // All corrections agree
        XCTAssertEqual(rule?.correctionCount, 3)
    }
    
    func testCreateRuleFromCorrections_InsufficientCorrections() async throws {
        // Given
        let corrections = [
            createTestCorrection(originalCategory: .area, correctedCategory: .project, pattern: "meeting")
        ]
        
        // When
        let rule = await personalRulesService.createRuleFromCorrections(corrections)
        
        // Then
        XCTAssertNil(rule) // Should require minimum 2 corrections
    }
    
    func testCreateRuleFromCorrections_ConflictingCorrections() async throws {
        // Given
        let corrections = [
            createTestCorrection(originalCategory: .area, correctedCategory: .project, pattern: "meeting"),
            createTestCorrection(originalCategory: .area, correctedCategory: .resource, pattern: "meeting"),
            createTestCorrection(originalCategory: .area, correctedCategory: .project, pattern: "meeting")
        ]
        
        // When
        let rule = await personalRulesService.createRuleFromCorrections(corrections)
        
        // Then
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.pattern, "meeting")
        XCTAssertEqual(rule?.action.newCategory, .project) // Majority wins
        XCTAssertLessThan(rule?.confidence ?? 1.0, 1.0) // Reduced confidence due to conflict
    }
    
    func testCreateRuleFromCorrections_PriorityChange() async throws {
        // Given
        let corrections = [
            createTestPriorityCorrection(originalPriority: .low, correctedPriority: .high, pattern: "urgent"),
            createTestPriorityCorrection(originalPriority: .medium, correctedPriority: .high, pattern: "urgent task")
        ]
        
        // When
        let rule = await personalRulesService.createRuleFromCorrections(corrections)
        
        // Then
        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.pattern, "urgent")
        XCTAssertEqual(rule?.action.type, .changePriority)
        XCTAssertEqual(rule?.action.newPriority, .high)
    }
    
    // MARK: - Rule Application Tests
    
    func testApplyRules_CategoryChange() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "meeting",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        let item = PARAItem(
            id: UUID(),
            title: "Team meeting notes",
            content: "Discussion about project timeline",
            contentType: .journal,
            paraCategory: .area,
            workPersonal: .work,
            priority: .medium,
            createdAt: Date()
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertEqual(updatedItem.paraCategory, .project)
        XCTAssertEqual(updatedItem.title, item.title) // Other properties unchanged
        XCTAssertEqual(updatedItem.priority, item.priority)
    }
    
    func testApplyRules_PriorityChange() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "urgent",
            action: PersonalRuleAction(type: .changePriority, newPriority: .high),
            confidence: 0.95,
            correctionCount: 5,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        let item = PARAItem(
            id: UUID(),
            title: "Urgent bug fix needed",
            content: "Critical issue in production",
            contentType: .task,
            paraCategory: .project,
            workPersonal: .work,
            priority: .low,
            createdAt: Date()
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertEqual(updatedItem.priority, .high)
        XCTAssertEqual(updatedItem.paraCategory, item.paraCategory) // Other properties unchanged
    }
    
    func testApplyRules_AddTags() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "client",
            action: PersonalRuleAction(type: .addTags, newTags: ["client-work", "external"]),
            confidence: 0.85,
            correctionCount: 4,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        let item = PARAItem(
            id: UUID(),
            title: "Client meeting preparation",
            content: "Prepare slides for client presentation",
            contentType: .task,
            paraCategory: .project,
            workPersonal: .work,
            priority: .medium,
            createdAt: Date(),
            tags: ["presentation"]
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertTrue(updatedItem.tags.contains("client-work"))
        XCTAssertTrue(updatedItem.tags.contains("external"))
        XCTAssertTrue(updatedItem.tags.contains("presentation")) // Original tag preserved
        XCTAssertEqual(updatedItem.tags.count, 3)
    }
    
    func testApplyRules_NoMatchingRules() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "meeting",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        let item = PARAItem(
            id: UUID(),
            title: "Shopping list",
            content: "Buy groceries for the week",
            contentType: .journal,
            paraCategory: .area,
            workPersonal: .personal,
            priority: .low,
            createdAt: Date()
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertEqual(updatedItem.paraCategory, item.paraCategory) // No changes
        XCTAssertEqual(updatedItem.priority, item.priority)
        XCTAssertEqual(updatedItem.tags, item.tags)
    }
    
    func testApplyRules_MultipleMatchingRules() async throws {
        // Given
        let categoryRule = PersonalRule(
            id: UUID(),
            pattern: "meeting",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        let priorityRule = PersonalRule(
            id: UUID(),
            pattern: "urgent",
            action: PersonalRuleAction(type: .changePriority, newPriority: .high),
            confidence: 0.95,
            correctionCount: 5,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(categoryRule)
        await personalRulesService.addRule(priorityRule)
        
        let item = PARAItem(
            id: UUID(),
            title: "Urgent meeting with client",
            content: "Critical discussion needed",
            contentType: .task,
            paraCategory: .area,
            workPersonal: .work,
            priority: .low,
            createdAt: Date()
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertEqual(updatedItem.paraCategory, .project) // Category rule applied
        XCTAssertEqual(updatedItem.priority, .high) // Priority rule applied
    }
    
    // MARK: - Rule Management Tests
    
    func testAddRule_Success() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "test",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.8,
            correctionCount: 2,
            createdAt: Date(),
            lastUsed: nil
        )
        
        // When
        await personalRulesService.addRule(rule)
        
        // Then
        let rules = await personalRulesService.getAllRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.id, rule.id)
    }
    
    func testUpdateRule_Success() async throws {
        // Given
        let originalRule = PersonalRule(
            id: UUID(),
            pattern: "test",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.8,
            correctionCount: 2,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(originalRule)
        
        let updatedRule = PersonalRule(
            id: originalRule.id,
            pattern: "test",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .area),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: originalRule.createdAt,
            lastUsed: Date()
        )
        
        // When
        await personalRulesService.updateRule(updatedRule)
        
        // Then
        let rules = await personalRulesService.getAllRules()
        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.action.newCategory, .area)
        XCTAssertEqual(rules.first?.confidence, 0.9)
        XCTAssertNotNil(rules.first?.lastUsed)
    }
    
    func testDeleteRule_Success() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "test",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.8,
            correctionCount: 2,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        // When
        await personalRulesService.deleteRule(id: rule.id)
        
        // Then
        let rules = await personalRulesService.getAllRules()
        XCTAssertEqual(rules.count, 0)
    }
    
    // MARK: - Rule Validation Tests
    
    func testValidateRule_ValidRule() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "meeting",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.8,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        // When
        let isValid = await personalRulesService.validateRule(rule)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateRule_EmptyPattern() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.8,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        // When
        let isValid = await personalRulesService.validateRule(rule)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testValidateRule_LowConfidence() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "test",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.3, // Below threshold
            correctionCount: 2,
            createdAt: Date(),
            lastUsed: nil
        )
        
        // When
        let isValid = await personalRulesService.validateRule(rule)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Rule Cleanup Tests
    
    func testCleanupExpiredRules_Success() async throws {
        // Given
        let now = Date()
        let expiredDate = now.addingTimeInterval(-100 * 24 * 60 * 60) // 100 days ago
        let recentDate = now.addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        let expiredRule = PersonalRule(
            id: UUID(),
            pattern: "expired",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.8,
            correctionCount: 2,
            createdAt: expiredDate,
            lastUsed: expiredDate
        )
        
        let activeRule = PersonalRule(
            id: UUID(),
            pattern: "active",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .area),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: recentDate,
            lastUsed: recentDate
        )
        
        await personalRulesService.addRule(expiredRule)
        await personalRulesService.addRule(activeRule)
        
        // When
        let cleanedCount = await personalRulesService.cleanupExpiredRules()
        
        // Then
        XCTAssertEqual(cleanedCount, 1)
        
        let remainingRules = await personalRulesService.getAllRules()
        XCTAssertEqual(remainingRules.count, 1)
        XCTAssertEqual(remainingRules.first?.pattern, "active")
    }
    
    func testCleanupExpiredRules_NoExpiredRules() async throws {
        // Given
        let recentDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        let activeRule = PersonalRule(
            id: UUID(),
            pattern: "active",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .area),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: recentDate,
            lastUsed: recentDate
        )
        
        await personalRulesService.addRule(activeRule)
        
        // When
        let cleanedCount = await personalRulesService.cleanupExpiredRules()
        
        // Then
        XCTAssertEqual(cleanedCount, 0)
        
        let remainingRules = await personalRulesService.getAllRules()
        XCTAssertEqual(remainingRules.count, 1)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ApplyRules() async throws {
        // Given
        let rules = (0..<100).map { i in
            PersonalRule(
                id: UUID(),
                pattern: "pattern\(i)",
                action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
                confidence: 0.8,
                correctionCount: 2,
                createdAt: Date(),
                lastUsed: nil
            )
        }
        
        for rule in rules {
            await personalRulesService.addRule(rule)
        }
        
        let item = PARAItem(
            id: UUID(),
            title: "Test item with pattern50",
            content: "Content",
            contentType: .task,
            paraCategory: .area,
            workPersonal: .work,
            priority: .medium,
            createdAt: Date()
        )
        
        // When/Then
        measure {
            Task {
                _ = await personalRulesService.applyRules(to: item)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testApplyRules_CaseInsensitiveMatching() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "MEETING",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        let item = PARAItem(
            id: UUID(),
            title: "team meeting notes",
            content: "Discussion",
            contentType: .journal,
            paraCategory: .area,
            workPersonal: .work,
            priority: .medium,
            createdAt: Date()
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertEqual(updatedItem.paraCategory, .project)
    }
    
    func testApplyRules_PartialWordMatching() async throws {
        // Given
        let rule = PersonalRule(
            id: UUID(),
            pattern: "meet",
            action: PersonalRuleAction(type: .changeCategory, newCategory: .project),
            confidence: 0.9,
            correctionCount: 3,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await personalRulesService.addRule(rule)
        
        let item = PARAItem(
            id: UUID(),
            title: "Team meeting scheduled",
            content: "Discussion",
            contentType: .journal,
            paraCategory: .area,
            workPersonal: .work,
            priority: .medium,
            createdAt: Date()
        )
        
        // When
        let updatedItem = await personalRulesService.applyRules(to: item)
        
        // Then
        XCTAssertEqual(updatedItem.paraCategory, .project)
    }
    
    // MARK: - Helper Methods
    
    private func createTestCorrection(originalCategory: PARACategory, correctedCategory: PARACategory, pattern: String) -> UserCorrection {
        return UserCorrection(
            id: UUID(),
            originalItem: PARAItem(
                id: UUID(),
                title: "Test item with \(pattern)",
                content: "Content",
                contentType: .task,
                paraCategory: originalCategory,
                workPersonal: .work,
                priority: .medium,
                createdAt: Date()
            ),
            correctedCategory: correctedCategory,
            correctedPriority: nil,
            correctedTags: nil,
            correctedWorkPersonal: nil,
            createdAt: Date()
        )
    }
    
    private func createTestPriorityCorrection(originalPriority: TaskPriority, correctedPriority: TaskPriority, pattern: String) -> UserCorrection {
        return UserCorrection(
            id: UUID(),
            originalItem: PARAItem(
                id: UUID(),
                title: "Test item with \(pattern)",
                content: "Content",
                contentType: .task,
                paraCategory: .project,
                workPersonal: .work,
                priority: originalPriority,
                createdAt: Date()
            ),
            correctedCategory: nil,
            correctedPriority: correctedPriority,
            correctedTags: nil,
            correctedWorkPersonal: nil,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Repository

class MockPersonalRulesRepository: PersonalRulesRepositoryProtocol {
    private var rules: [PersonalRule] = []
    private var corrections: [UserCorrection] = []
    
    func saveRule(_ rule: PersonalRule) async throws {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }
    
    func fetchRule(id: UUID) async throws -> PersonalRule? {
        return rules.first { $0.id == id }
    }
    
    func fetchAllRules() async throws -> [PersonalRule] {
        return rules
    }
    
    func deleteRule(id: UUID) async throws {
        rules.removeAll { $0.id == id }
    }
    
    func fetchRulesLastUsedBefore(_ date: Date) async throws -> [PersonalRule] {
        return rules.filter { rule in
            if let lastUsed = rule.lastUsed {
                return lastUsed < date
            } else {
                return rule.createdAt < date
            }
        }
    }
    
    func saveCorrection(_ correction: UserCorrection) async throws {
        corrections.append(correction)
    }
    
    func fetchCorrections(matching pattern: String) async throws -> [UserCorrection] {
        return corrections.filter { correction in
            correction.originalItem.title.lowercased().contains(pattern.lowercased()) ||
            correction.originalItem.content.lowercased().contains(pattern.lowercased())
        }
    }
    
    func fetchAllCorrections() async throws -> [UserCorrection] {
        return corrections
    }
} 