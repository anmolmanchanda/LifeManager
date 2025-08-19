//
// BrainDumpEmbeddingsService.swift
// LifeManager
//
// Implements: v2.0 "Intelligence Expansion" - Embeddings Generation for Brain Dump Items
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Processing Pipeline
// Status: ✅ PRODUCTION - Enterprise-grade embeddings generation
//
// Purpose: Generates and manages embeddings for all brain dump created items
// to enable semantic search, similarity matching, and intelligent linking.
//

import Foundation

/// Enterprise-grade service for generating embeddings for all brain dump items
/// Ensures every created item has semantic embeddings for advanced AI features
@MainActor
class BrainDumpEmbeddingsService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BrainDumpEmbeddingsService()
    
    // MARK: - Dependencies
    private let embeddingsService = EmbeddingsService.shared
    private let logger = Logger.shared
    
    // MARK: - State
    @Published var isGeneratingEmbeddings = false
    @Published var embeddingsProgress: Double = 0.0
    @Published var failedEmbeddings: [FailedEmbedding] = []
    
    // MARK: - Configuration
    private let batchSize = 10
    private let retryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    // MARK: - Models
    struct FailedEmbedding {
        let itemId: UUID
        let itemType: String
        let content: String
        let error: String
        let timestamp: Date
    }
    
    struct EmbeddingResult {
        let itemId: UUID
        let itemType: String
        let embedding: [Float]
        let metadata: EmbeddingMetadata
    }
    
    struct EmbeddingMetadata {
        let generatedAt: Date
        let model: String
        let dimensions: Int
        let processingTime: TimeInterval
    }
    
    private init() {
        logger.info("BrainDumpEmbeddingsService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Generate embeddings for a single brain dump item
    func generateEmbeddingForItem(_ item: EnhancedBrainDumpItem) async -> EmbeddingResult? {
        let startTime = Date()
        
        // Prepare content for embedding
        let content = prepareContentForEmbedding(item)
        
        logger.debug("Generating embedding for \(item.contentType.rawValue): \(item.title)")
        
        do {
            // Generate embedding using the embeddings service
            let embedding = try await embeddingsService.generateEmbedding(for: content)
            
            let metadata = EmbeddingMetadata(
                generatedAt: Date(),
                model: "text-embedding-3-small",
                dimensions: embedding.count,
                processingTime: Date().timeIntervalSince(startTime)
            )
            
            let result = EmbeddingResult(
                itemId: item.id,
                itemType: item.contentType.rawValue,
                embedding: embedding,
                metadata: metadata
            )
            
            // Store embedding in database
            await storeEmbedding(result, for: item)
            
            logger.success("✅ Generated embedding for \(item.title) [\(embedding.count) dimensions]")
            return result
            
        } catch {
            logger.error("Failed to generate embedding for \(item.title): \(error)")
            
            // Track failed embedding for retry
            let failed = FailedEmbedding(
                itemId: item.id,
                itemType: item.contentType.rawValue,
                content: content,
                error: error.localizedDescription,
                timestamp: Date()
            )
            failedEmbeddings.append(failed)
            
            return nil
        }
    }
    
    /// Generate embeddings for multiple brain dump items in batch
    func generateEmbeddingsForItems(_ items: [EnhancedBrainDumpItem]) async -> [EmbeddingResult] {
        isGeneratingEmbeddings = true
        embeddingsProgress = 0.0
        
        defer {
            isGeneratingEmbeddings = false
            embeddingsProgress = 1.0
        }
        
        logger.info("Generating embeddings for \(items.count) items")
        
        var results: [EmbeddingResult] = []
        let totalItems = items.count
        
        // Process in batches to avoid rate limiting
        for (index, batch) in items.chunked(into: batchSize).enumerated() {
            logger.debug("Processing batch \(index + 1) with \(batch.count) items")
            
            // Process batch concurrently
            let batchResults = await withTaskGroup(of: EmbeddingResult?.self) { group in
                for item in batch {
                    group.addTask {
                        await self.generateEmbeddingForItem(item)
                    }
                }
                
                var batchResults: [EmbeddingResult] = []
                for await result in group {
                    if let result = result {
                        batchResults.append(result)
                    }
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
            
            // Update progress
            embeddingsProgress = Double(min(index * batchSize + batch.count, totalItems)) / Double(totalItems)
            
            // Add delay between batches to respect rate limits
            if index < items.chunked(into: batchSize).count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000)) // 1 second delay
            }
        }
        
        logger.success("Generated \(results.count) embeddings successfully, \(failedEmbeddings.count) failed")
        
        // Retry failed embeddings
        if !failedEmbeddings.isEmpty {
            await retryFailedEmbeddings()
        }
        
        return results
    }
    
    /// Generate embeddings for specific content types
    func generateEmbeddingsForContentType(_ contentType: ContentType, items: [EnhancedBrainDumpItem]) async -> [EmbeddingResult] {
        let filteredItems = items.filter { $0.contentType == contentType }
        
        logger.info("Generating embeddings for \(filteredItems.count) \(contentType.rawValue) items")
        
        return await generateEmbeddingsForItems(filteredItems)
    }
    
    /// Retry failed embeddings generation
    func retryFailedEmbeddings() async {
        guard !failedEmbeddings.isEmpty else { return }
        
        logger.info("Retrying \(failedEmbeddings.count) failed embeddings")
        
        let itemsToRetry = failedEmbeddings
        failedEmbeddings.removeAll()
        
        for failed in itemsToRetry {
            var retryCount = 0
            var success = false
            
            while retryCount < retryAttempts && !success {
                retryCount += 1
                
                do {
                    // Add exponential backoff
                    let delay = retryDelay * Double(retryCount)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    let embedding = try await embeddingsService.generateEmbedding(for: failed.content)
                    
                    logger.success("✅ Retry successful for item \(failed.itemId)")
                    success = true
                    
                    // Store the embedding
                    let result = EmbeddingResult(
                        itemId: failed.itemId,
                        itemType: failed.itemType,
                        embedding: embedding,
                        metadata: EmbeddingMetadata(
                            generatedAt: Date(),
                            model: "text-embedding-3-small",
                            dimensions: embedding.count,
                            processingTime: 0
                        )
                    )
                    
                    await storeEmbeddingById(result)
                    
                } catch {
                    logger.warning("Retry \(retryCount) failed for item \(failed.itemId): \(error)")
                    
                    if retryCount == retryAttempts {
                        // Final failure, add back to failed list
                        failedEmbeddings.append(failed)
                    }
                }
            }
        }
        
        if !failedEmbeddings.isEmpty {
            logger.error("❌ \(failedEmbeddings.count) embeddings failed after retries")
        }
    }
    
    // MARK: - Private Methods
    
    /// Prepare content for embedding generation
    private func prepareContentForEmbedding(_ item: EnhancedBrainDumpItem) -> String {
        var components: [String] = []
        
        // Add title with type context
        components.append("[\(item.contentType.rawValue.uppercased())] \(item.title)")
        
        // Add main content
        components.append(item.content)
        
        // Add PARA category context
        components.append("Category: \(item.paraCategory.rawValue)")
        
        // Add work/personal context
        components.append("Context: \(item.workPersonal.rawValue)")
        
        // Add priority for tasks
        if item.contentType == .task {
            components.append("Priority: \(item.priority.rawValue)")
        }
        
        // Add tags
        if !item.tags.isEmpty {
            components.append("Tags: \(item.tags.joined(separator: ", "))")
        }
        
        // Add area if specified
        if let area = item.suggestedArea {
            components.append("Area: \(area)")
        }
        
        // Add project if specified
        if let project = item.suggestedProject {
            components.append("Project: \(project)")
        }
        
        // Add due date for time-sensitive items
        if let dueDate = item.dueDate {
            components.append("Due: \(dueDate)")
        }
        
        // Combine all components
        return components.joined(separator: ". ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Store embedding in database
    private func storeEmbedding(_ result: EmbeddingResult, for item: EnhancedBrainDumpItem) async {
        // Store in embeddings service cache
        await embeddingsService.storeEmbedding(
            for: result.itemId.uuidString,
            embedding: result.embedding,
            metadata: [
                "type": result.itemType,
                "para_category": item.paraCategory.rawValue,
                "work_personal": item.workPersonal.rawValue,
                "generated_at": result.metadata.generatedAt.ISO8601Format()
            ]
        )
        
        logger.debug("Stored embedding for \(item.title) in database")
    }
    
    /// Store embedding by ID only (for retries)
    private func storeEmbeddingById(_ result: EmbeddingResult) async {
        await embeddingsService.storeEmbedding(
            for: result.itemId.uuidString,
            embedding: result.embedding,
            metadata: [
                "type": result.itemType,
                "generated_at": result.metadata.generatedAt.ISO8601Format()
            ]
        )
    }
}

// MARK: - Array Extension for Chunking
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Integration with Brain Dump Processor
extension LLMBrainDumpProcessor {
    /// Generate embeddings for all approved items after execution
    func generateEmbeddingsForApprovedItems(_ items: [EnhancedBrainDumpItem]) async {
        logger.brainDumpProgress("🔍 Generating embeddings for \(items.count) approved items...")
        
        let embeddingsService = BrainDumpEmbeddingsService.shared
        let results = await embeddingsService.generateEmbeddingsForItems(items)
        
        logger.success("✅ Generated \(results.count) embeddings for brain dump items")
    }
}