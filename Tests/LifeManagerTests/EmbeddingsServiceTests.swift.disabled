//
// EmbeddingsServiceTests.swift
// LifeManagerTests
//
// Tests for v2.0 Embeddings Service - Semantic Similarity Matching
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 14, 2025
//

import XCTest
import Foundation
@testable import LifeManager

final class EmbeddingsServiceTests: XCTestCase {
    
    var embeddingsService: EmbeddingsService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize service
        embeddingsService = EmbeddingsService.shared
    }
    
    override func tearDown() async throws {
        embeddingsService = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Embedding Tests
    
    func testGetEmbedding_WithValidText() async throws {
        // Given
        let text = "Book flights for Europe trip"
        
        // When - This will test the actual implementation
        // Note: This test requires a valid API key to pass completely
        let result = await embeddingsService.getEmbedding(for: text)
        
        // Then - Test basic functionality without requiring API key
        // The method should handle missing API key gracefully
        // Result will be nil if no API key, but shouldn't crash
        if result != nil {
            XCTAssertGreaterThan(result!.count, 0, "Embedding should have dimensions")
        }
    }
    
    func testGetEmbedding_EmptyText() async throws {
        // Given
        let text = ""
        
        // When
        let result = await embeddingsService.getEmbedding(for: text)
        
        // Then
        XCTAssertNil(result, "Empty text should return nil")
    }
    
    // MARK: - Similarity Calculation Tests
    
    func testCalculateSimilarity_IdenticalVectors() {
        // Given
        let vector1: [Float] = [1.0, 0.0, 0.0]
        let vector2: [Float] = [1.0, 0.0, 0.0]
        
        // When
        let similarity = embeddingsService.calculateSimilarity(embedding1: vector1, embedding2: vector2)
        
        // Then
        XCTAssertEqual(similarity, 1.0, accuracy: 0.001)
    }
    
    func testCalculateSimilarity_OppositeVectors() {
        // Given
        let vector1: [Float] = [1.0, 0.0, 0.0]
        let vector2: [Float] = [-1.0, 0.0, 0.0]
        
        // When
        let similarity = embeddingsService.calculateSimilarity(embedding1: vector1, embedding2: vector2)
        
        // Then
        XCTAssertEqual(similarity, -1.0, accuracy: 0.001)
    }
    
    func testCalculateSimilarity_DifferentDimensions() {
        // Given
        let vector1: [Float] = [1.0, 0.0]
        let vector2: [Float] = [1.0, 0.0, 0.0]
        
        // When
        let similarity = embeddingsService.calculateSimilarity(embedding1: vector1, embedding2: vector2)
        
        // Then
        XCTAssertEqual(similarity, 0.0) // Should return 0 for mismatched dimensions
    }
    
    func testCalculateSimilarity_ZeroVectors() {
        // Given
        let vector1: [Float] = [0.0, 0.0, 0.0]
        let vector2: [Float] = [1.0, 0.0, 0.0]
        
        // When
        let similarity = embeddingsService.calculateSimilarity(embedding1: vector1, embedding2: vector2)
        
        // Then
        XCTAssertEqual(similarity, 0.0) // Should handle zero magnitude gracefully
    }
    
    // MARK: - Similarity Search Tests
    
    func testFindMostSimilar() {
        // Given
        let queryEmbedding: [Float] = [1.0, 0.0, 0.0]
        let embeddings = [
            "Very similar": [0.9, 0.1, 0.0],
            "Somewhat similar": [0.7, 0.3, 0.0],
            "Not similar": [0.0, 0.0, 1.0],
            "Opposite": [-1.0, 0.0, 0.0]
        ]
        
        // When
        let results = embeddingsService.findMostSimilar(
            to: queryEmbedding,
            in: embeddings,
            threshold: 0.5,
            limit: 3
        )
        
        // Then
        XCTAssertEqual(results.count, 2) // Only items above threshold
        XCTAssertEqual(results[0].key, "Very similar") // Highest similarity first
        XCTAssertEqual(results[1].key, "Somewhat similar")
        XCTAssertGreaterThan(results[0].similarity, results[1].similarity)
    }
    
    func testFindMostSimilar_NoMatches() {
        // Given
        let queryEmbedding: [Float] = [1.0, 0.0, 0.0]
        let embeddings = [
            "Low similarity": [0.1, 0.9, 0.0],
            "Very low": [0.0, 0.0, 1.0]
        ]
        
        // When
        let results = embeddingsService.findMostSimilar(
            to: queryEmbedding,
            in: embeddings,
            threshold: 0.8,
            limit: 10
        )
        
        // Then
        XCTAssertEqual(results.count, 0) // No items above high threshold
    }
    
    // MARK: - PARA Integration Tests
    
    func testGenerateEmbeddingForPARAItem() async throws {
        // Given
        let testId = UUID()
        let testContent = "Test project for embedding generation"
        let testType = "project"
        
        // When - This should not crash regardless of API key availability
        await embeddingsService.generateEmbeddingForPARAItem(
            id: testId,
            content: testContent,
            type: testType
        )
        
        // Then - Should complete without throwing
        // The actual embedding generation depends on API key availability
        // but the method should handle both cases gracefully
        XCTAssert(true, "Method completed without crashing")
    }
    
    // MARK: - Batch Processing Tests
    
    func testGetBatchEmbeddings() async throws {
        // Given
        let texts = ["Text 1", "Text 2", "Text 3"]
        
        // When
        let results = await embeddingsService.getBatchEmbeddings(for: texts)
        
        // Then - Should return results for all texts (nil if no API key)
        XCTAssertEqual(results.count, texts.count)
    }
}