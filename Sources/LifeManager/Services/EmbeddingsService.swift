//
// EmbeddingsService.swift
// LifeManager
//
// Implements: v2.0 "Contextual Embeddings Search" - Semantic PARA Matching
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ⏳ IN PROGRESS as of June 14, 2025
// Future: v2.5 Advanced Semantic Analysis, Custom Embeddings
//

import Foundation

/// Service for generating and managing text embeddings for semantic similarity
/// Enables contextual PARA matching based on meaning rather than keywords
class EmbeddingsService: ObservableObject {
    
    static let shared = EmbeddingsService()
    
    // MARK: - Configuration
    
    private struct EmbeddingsConfig {
        static let openAIEmbeddingsURL = "https://api.openai.com/v1/embeddings"
        static let embeddingModel = "text-embedding-3-small" // Cost-effective, good performance
        static let maxTokens = 8192
        static let cacheExpirationDays = 30
        static let batchSize = 100
    }
    
    // MARK: - Cache Management
    
    private var embeddingsCache: [String: CachedEmbedding] = [:]
    private let cacheQueue = DispatchQueue(label: "embeddings.cache", qos: .utility)
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await loadEmbeddingsCache()
        }
    }
    
    // MARK: - Public Methods
    
    /// Get embedding for text content with caching
    func getEmbedding(for text: String) async -> [Float]? {
        let normalizedText = normalizeText(text)
        let cacheKey = generateCacheKey(for: normalizedText)
        
        // Check cache first
        if let cachedEmbedding = await getCachedEmbedding(for: cacheKey) {
            return cachedEmbedding.embedding
        }
        
        // Generate new embedding
        guard let embedding = await generateEmbedding(for: normalizedText) else {
            return nil
        }
        
        // Cache the result
        await cacheEmbedding(embedding, for: cacheKey, text: normalizedText)
        
        return embedding
    }
    
    /// Get embeddings for multiple texts in batch
    func getBatchEmbeddings(for texts: [String]) async -> [String: [Float]] {
        var results: [String: [Float]] = [:]
        
        // Process in batches to respect API limits
        let batches = texts.chunked(into: EmbeddingsConfig.batchSize)
        
        for batch in batches {
            let batchResults = await processBatch(batch)
            results.merge(batchResults) { _, new in new }
        }
        
        return results
    }
    
    /// Calculate cosine similarity between two embeddings
    func calculateSimilarity(embedding1: [Float], embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else { return 0.0 }
        
        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    /// Find most similar items from a collection
    func findMostSimilar(
        to queryEmbedding: [Float],
        in embeddings: [String: [Float]],
        threshold: Float = 0.7,
        limit: Int = 10
    ) -> [(key: String, similarity: Float)] {
        
        var similarities: [(String, Float)] = []
        
        for (key, embedding) in embeddings {
            let similarity = calculateSimilarity(embedding1: queryEmbedding, embedding2: embedding)
            if similarity >= threshold {
                similarities.append((key, similarity))
            }
        }
        
        return similarities
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { (key: $0.0, similarity: $0.1) }
    }
    
    /// Update embeddings for all PARA items
    func updatePARAEmbeddings() async {
        print("🔧 EMBEDDINGS: Starting PARA embeddings update...")
        
        do {
            // Get all PARA items
            let allItems = try await loadAllPARAItems()
            
            // Generate embeddings for items that don't have them
            var updatedCount = 0
            
            for item in allItems {
                let cacheKey = generateCacheKey(for: item.content)
                
                if await getCachedEmbedding(for: cacheKey) == nil {
                    if let embedding = await generateEmbedding(for: item.content) {
                        await cacheEmbedding(embedding, for: cacheKey, text: item.content)
                        updatedCount += 1
                    }
                }
            }
            
            print("🔧 EMBEDDINGS: ✅ Updated \(updatedCount) embeddings for PARA items")
            
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to update PARA embeddings: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate embedding using OpenAI API
    private func generateEmbedding(for text: String) async -> [Float]? {
        guard !text.isEmpty else { return nil }
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        guard !apiKey.isEmpty else {
            print("🔧 EMBEDDINGS: ❌ No OpenAI API key found")
            return nil
        }
        
        let requestBody = EmbeddingRequest(
            input: text,
            model: EmbeddingsConfig.embeddingModel
        )
        
        guard let requestData = try? JSONEncoder().encode(requestBody) else {
            print("🔧 EMBEDDINGS: ❌ Failed to encode request")
            return nil
        }
        
        var request = URLRequest(url: URL(string: EmbeddingsConfig.openAIEmbeddingsURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔧 EMBEDDINGS: ❌ Invalid response type")
                return nil
            }
            
            guard httpResponse.statusCode == 200 else {
                print("🔧 EMBEDDINGS: ❌ API error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("🔧 EMBEDDINGS: Error details: \(errorData)")
                }
                return nil
            }
            
            let embeddingResponse = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
            
            guard let firstEmbedding = embeddingResponse.data.first else {
                print("🔧 EMBEDDINGS: ❌ No embedding data in response")
                return nil
            }
            
            print("🔧 EMBEDDINGS: ✅ Generated embedding with \(firstEmbedding.embedding.count) dimensions")
            return firstEmbedding.embedding
            
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to generate embedding: \(error)")
            return nil
        }
    }
    
    /// Process batch of texts for embeddings
    private func processBatch(_ texts: [String]) async -> [String: [Float]] {
        var results: [String: [Float]] = [:]
        
        for text in texts {
            if let embedding = await getEmbedding(for: text) {
                results[text] = embedding
            }
        }
        
        return results
    }
    
    /// Normalize text for consistent embedding generation
    private func normalizeText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    /// Generate cache key for text
    private func generateCacheKey(for text: String) -> String {
        return text.data(using: .utf8)?.base64EncodedString() ?? text
    }
    
    // MARK: - Cache Management
    
    /// Get cached embedding
    private func getCachedEmbedding(for key: String) async -> CachedEmbedding? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async {
                let cached = self.embeddingsCache[key]
                
                // Check if cache is expired
                if let cached = cached {
                    let daysSinceCreation = Calendar.current.dateComponents([.day], from: cached.createdAt, to: Date()).day ?? 0
                    if daysSinceCreation > EmbeddingsConfig.cacheExpirationDays {
                        self.embeddingsCache.removeValue(forKey: key)
                        continuation.resume(returning: nil)
                        return
                    }
                }
                
                continuation.resume(returning: cached)
            }
        }
    }
    
    /// Cache embedding
    private func cacheEmbedding(_ embedding: [Float], for key: String, text: String) async {
        let cachedEmbedding = CachedEmbedding(
            embedding: embedding,
            text: text,
            createdAt: Date()
        )
        
        await withCheckedContinuation { continuation in
            cacheQueue.async {
                self.embeddingsCache[key] = cachedEmbedding
                continuation.resume()
            }
        }
        
        // Persist to database
        await persistEmbeddingToDatabase(key: key, embedding: cachedEmbedding)
    }
    
    /// Load embeddings cache from database
    private func loadEmbeddingsCache() async {
        do {
            let cachedEmbeddings = try await supabaseService.client
                .from("embeddings_cache")
                .select()
                .execute()
            
            // Process cached embeddings
            // Implementation depends on Supabase response format
            print("🔧 EMBEDDINGS: ✅ Loaded embeddings cache from database")
            
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to load embeddings cache: \(error)")
        }
    }
    
    /// Persist embedding to database
    private func persistEmbeddingToDatabase(key: String, embedding: CachedEmbedding) async {
        do {
            let embeddingRecord = EmbeddingRecord(
                cache_key: key,
                embedding: embedding.embedding,
                text: embedding.text,
                created_at: embedding.createdAt
            )
            
            try await supabaseService.client
                .from("embeddings_cache")
                .upsert(embeddingRecord)
                .execute()
            
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to persist embedding: \(error)")
        }
    }
    
    /// Load all PARA items for embedding generation
    private func loadAllPARAItems() async throws -> [PARAItem] {
        // This would integrate with your existing PARA data loading
        // For now, return empty array
        return []
    }
}

// MARK: - Data Structures

struct EmbeddingRequest: Codable {
    let input: String
    let model: String
}

struct EmbeddingResponse: Codable {
    let data: [EmbeddingData]
    let model: String
    let usage: EmbeddingUsage
}

struct EmbeddingData: Codable {
    let embedding: [Float]
    let index: Int
    let object: String
}

struct EmbeddingUsage: Codable {
    let prompt_tokens: Int
    let total_tokens: Int
}

struct CachedEmbedding {
    let embedding: [Float]
    let text: String
    let createdAt: Date
}

struct EmbeddingRecord: Codable {
    let cache_key: String
    let embedding: [Float]
    let text: String
    let created_at: Date
}

// PARAItem is defined in CoreModels.swift

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}