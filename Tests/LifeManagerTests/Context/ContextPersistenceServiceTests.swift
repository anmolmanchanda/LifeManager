//
// ContextPersistenceServiceTests.swift
// LifeManagerTests
//
// Unit tests for ContextPersistenceService
//

import XCTest
@testable import LifeManager

final class ContextPersistenceServiceTests: XCTestCase {
    
    var sut: ContextPersistenceService!
    var testDirectory: URL!
    
    override func setUp() {
        super.setUp()
        
        // Create test directory
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("ContextPersistenceTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        sut = ContextPersistenceService(directory: testDirectory)
    }
    
    override func tearDown() {
        // Clean up test directory
        try? FileManager.default.removeItem(at: testDirectory)
        
        sut = nil
        testDirectory = nil
        super.tearDown()
    }
    
    // MARK: - Save Tests
    
    func testSaveContext_CreatesFile() async throws {
        // Given
        let items = createContextItems(count: 5)
        
        // When
        try await sut.saveContext(items)
        
        // Then
        let files = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
        XCTAssertFalse(files.isEmpty)
        XCTAssertTrue(files.contains { $0.lastPathComponent.hasPrefix("context_") })
    }
    
    func testSaveContext_PreservesData() async throws {
        // Given
        let items = [
            createContextItem(content: "Task 1", category: .task),
            createContextItem(content: "Project A", category: .project),
            createContextItem(content: "Resource X", category: .resource)
        ]
        
        // When
        try await sut.saveContext(items)
        let loaded = try await sut.loadLatestContext()
        
        // Then
        XCTAssertEqual(loaded.count, 3)
        XCTAssertTrue(loaded.contains { $0.content == "Task 1" })
        XCTAssertTrue(loaded.contains { $0.content == "Project A" })
        XCTAssertTrue(loaded.contains { $0.content == "Resource X" })
    }
    
    func testSaveContext_HandlesLargeDataset() async throws {
        // Given
        let items = createContextItems(count: 1000)
        
        // When
        try await sut.saveContext(items)
        let loaded = try await sut.loadLatestContext()
        
        // Then
        XCTAssertEqual(loaded.count, 1000)
    }
    
    // MARK: - Load Tests
    
    func testLoadLatestContext_ReturnsNewest() async throws {
        // Given
        let items1 = createContextItems(count: 3, prefix: "First")
        let items2 = createContextItems(count: 3, prefix: "Second")
        let items3 = createContextItems(count: 3, prefix: "Latest")
        
        // When
        try await sut.saveContext(items1)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        try await sut.saveContext(items2)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        try await sut.saveContext(items3)
        
        let loaded = try await sut.loadLatestContext()
        
        // Then
        XCTAssertEqual(loaded.count, 3)
        XCTAssertTrue(loaded.allSatisfy { $0.content.contains("Latest") })
    }
    
    func testLoadLatestContext_EmptyDirectory_ReturnsEmpty() async throws {
        // When
        let loaded = try await sut.loadLatestContext()
        
        // Then
        XCTAssertTrue(loaded.isEmpty)
    }
    
    func testLoadContext_ByDate() async throws {
        // Given
        let date = Date()
        let items = createContextItems(count: 5)
        
        // When
        try await sut.saveContext(items, date: date)
        let loaded = try await sut.loadContext(from: date)
        
        // Then
        XCTAssertEqual(loaded.count, 5)
    }
    
    // MARK: - Snapshot Tests
    
    func testCreateSnapshot_SavesWithMetadata() async throws {
        // Given
        let items = createContextItems(count: 10)
        let metadata = SnapshotMetadata(
            version: "1.0.0",
            itemCount: 10,
            categories: [.task: 5, .project: 3, .area: 2],
            timestamp: Date()
        )
        
        // When
        let snapshotId = try await sut.createSnapshot(items, metadata: metadata)
        
        // Then
        XCTAssertNotNil(snapshotId)
        
        let snapshots = try await sut.listSnapshots()
        XCTAssertTrue(snapshots.contains { $0.id == snapshotId })
    }
    
    func testRestoreSnapshot() async throws {
        // Given
        let originalItems = createContextItems(count: 5, prefix: "Original")
        let snapshotId = try await sut.createSnapshot(originalItems, metadata: nil)
        
        // Modify current context
        let newItems = createContextItems(count: 3, prefix: "New")
        try await sut.saveContext(newItems)
        
        // When
        try await sut.restoreSnapshot(snapshotId)
        let restored = try await sut.loadLatestContext()
        
        // Then
        XCTAssertEqual(restored.count, 5)
        XCTAssertTrue(restored.allSatisfy { $0.content.contains("Original") })
    }
    
    func testListSnapshots_ReturnsSortedByDate() async throws {
        // Given
        _ = try await sut.createSnapshot(createContextItems(count: 1), metadata: nil)
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await sut.createSnapshot(createContextItems(count: 2), metadata: nil)
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await sut.createSnapshot(createContextItems(count: 3), metadata: nil)
        
        // When
        let snapshots = try await sut.listSnapshots()
        
        // Then
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertTrue(snapshots[0].timestamp > snapshots[1].timestamp)
        XCTAssertTrue(snapshots[1].timestamp > snapshots[2].timestamp)
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanupOldFiles_RemovesOldFiles() async throws {
        // Given
        let oldDate = Date().addingTimeInterval(-86400 * 10) // 10 days old
        let recentDate = Date()
        
        try await sut.saveContext(createContextItems(count: 3), date: oldDate)
        try await sut.saveContext(createContextItems(count: 3), date: recentDate)
        
        // When
        try await sut.cleanupOldFiles(olderThan: 7)
        
        // Then
        let files = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1) // Only recent file should remain
    }
    
    func testClearAllData_RemovesEverything() async throws {
        // Given
        try await sut.saveContext(createContextItems(count: 5))
        _ = try await sut.createSnapshot(createContextItems(count: 3), metadata: nil)
        
        // When
        try await sut.clearAllData()
        
        // Then
        let files = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
        XCTAssertTrue(files.isEmpty)
    }
    
    // MARK: - Export/Import Tests
    
    func testExportToJSON() async throws {
        // Given
        let items = [
            createContextItem(content: "Task A", category: .task),
            createContextItem(content: "Project B", category: .project)
        ]
        try await sut.saveContext(items)
        
        // When
        let jsonData = try await sut.exportToJSON()
        
        // Then
        XCTAssertNotNil(jsonData)
        
        let decoded = try JSONDecoder().decode([ContextItem].self, from: jsonData)
        XCTAssertEqual(decoded.count, 2)
    }
    
    func testImportFromJSON() async throws {
        // Given
        let items = createContextItems(count: 5)
        let jsonData = try JSONEncoder().encode(items)
        
        // When
        try await sut.importFromJSON(jsonData)
        let loaded = try await sut.loadLatestContext()
        
        // Then
        XCTAssertEqual(loaded.count, 5)
    }
    
    // MARK: - Compression Tests
    
    func testSaveWithCompression() async throws {
        // Given
        let items = createContextItems(count: 100)
        
        // When
        try await sut.saveContext(items, compressed: true)
        
        // Then
        let files = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
        let compressedFile = files.first { $0.pathExtension == "gz" }
        XCTAssertNotNil(compressedFile)
        
        // Verify can load compressed data
        let loaded = try await sut.loadLatestContext()
        XCTAssertEqual(loaded.count, 100)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveToInvalidPath_ThrowsError() async {
        // Given
        let invalidService = ContextPersistenceService(directory: URL(fileURLWithPath: "/invalid/path"))
        let items = createContextItems(count: 5)
        
        // When/Then
        do {
            try await invalidService.saveContext(items)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testLoadCorruptedFile_HandlesGracefully() async throws {
        // Given
        let corruptedData = "Not valid JSON".data(using: .utf8)!
        let fileURL = testDirectory.appendingPathComponent("context_corrupted.json")
        try corruptedData.write(to: fileURL)
        
        // When
        let loaded = try await sut.loadLatestContext()
        
        // Then
        XCTAssertTrue(loaded.isEmpty) // Should return empty instead of crashing
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentSaveAndLoad() async throws {
        // Given
        let iterations = 20
        
        // When
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask {
                    let items = self.createContextItems(count: 5, prefix: "Write\(i)")
                    try? await self.sut.saveContext(items)
                }
            }
            
            // Readers
            for _ in 0..<iterations {
                group.addTask {
                    _ = try? await self.sut.loadLatestContext()
                }
            }
        }
        
        // Then - Should complete without crashes
        let finalItems = try await sut.loadLatestContext()
        XCTAssertGreaterThan(finalItems.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createContextItem(
        content: String = "Test item",
        category: PARACategory = .task
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
    
    private func createContextItems(
        count: Int,
        prefix: String = "Item"
    ) -> [ContextItem] {
        return (0..<count).map { i in
            createContextItem(content: "\(prefix) \(i)")
        }
    }
}

// MARK: - Performance Tests

extension ContextPersistenceServiceTests {
    
    func testPerformance_SaveLargeContext() throws {
        // Given
        let items = createContextItems(count: 5000)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Save")
            
            Task {
                try await sut.saveContext(items)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformance_LoadLargeContext() throws {
        // Setup
        let items = createContextItems(count: 5000)
        let setupExpectation = self.expectation(description: "Setup")
        
        Task {
            try await sut.saveContext(items)
            setupExpectation.fulfill()
        }
        
        wait(for: [setupExpectation], timeout: 5.0)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Load")
            
            Task {
                _ = try await sut.loadLatestContext()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testPerformance_CreateSnapshot() throws {
        // Given
        let items = createContextItems(count: 1000)
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Snapshot")
            
            Task {
                _ = try await sut.createSnapshot(items, metadata: nil)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
}

// MARK: - Supporting Types

struct SnapshotMetadata: Codable {
    let version: String
    let itemCount: Int
    let categories: [PARACategory: Int]
    let timestamp: Date
}

struct SnapshotInfo {
    let id: String
    let timestamp: Date
    let itemCount: Int
    let sizeInBytes: Int64
}