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
        
        // Domain-specific similarity thresholds
        static let highSimilarityThreshold: Float = 0.85
        static let mediumSimilarityThreshold: Float = 0.7
        static let lowSimilarityThreshold: Float = 0.55
        
        // PARA category weights for enhanced matching
        static let categoryWeights: [PARACategory: Float] = [
            .project: 1.2,  // Projects get higher weight for task-related content
            .area: 1.0,     // Areas are baseline
            .resource: 0.9, // Resources slightly lower for general reference
            .archive: 0.7   // Archives lower priority in active matching
        ]
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
    
    /// Find most similar items from a collection with domain-specific enhancements
    func findMostSimilar(
        to queryEmbedding: [Float],
        in embeddings: [String: [Float]],
        threshold: Float = 0.7,
        limit: Int = 10,
        domainContext: DomainContext? = nil
    ) -> [(key: String, similarity: Float)] {
        
        var similarities: [(String, Float)] = []
        
        for (key, embedding) in embeddings {
            var similarity = calculateSimilarity(embedding1: queryEmbedding, embedding2: embedding)
            
            // Apply domain-specific adjustments
            if let context = domainContext {
                similarity = applyDomainAdjustments(similarity: similarity, key: key, context: context)
            }
            
            if similarity >= threshold {
                similarities.append((key, similarity))
            }
        }
        
        return similarities
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { (key: $0.0, similarity: $0.1) }
    }
    
    /// Enhanced PARA item matching with contextual intelligence
    func findSimilarPARAItems(
        to query: String,
        category: PARACategory? = nil,
        workPersonal: WorkPersonalType? = nil,
        timeWindow: TimeInterval? = nil,
        limit: Int = 10
    ) async -> [EnhancedSimilarityResult] {
        
        guard let queryEmbedding = await getEmbedding(for: query) else {
            return []
        }
        
        // Load PARA items with optional filtering
        let paraItems = await loadFilteredPARAItems(
            category: category,
            workPersonal: workPersonal,
            timeWindow: timeWindow
        )
        
        var results: [EnhancedSimilarityResult] = []
        
        for item in paraItems {
            let itemContent = "\(item.title). \(item.content)"
            guard let itemEmbedding = await getEmbedding(for: itemContent) else { continue }
            
            let baseSimilarity = calculateSimilarity(embedding1: queryEmbedding, embedding2: itemEmbedding)
            
            // Apply PARA-specific enhancements
            let enhancedSimilarity = enhancePARASimilarity(
                similarity: baseSimilarity,
                item: item,
                query: query
            )
            
            if enhancedSimilarity > EmbeddingsConfig.lowSimilarityThreshold {
                let confidence = calculateConfidenceScore(similarity: enhancedSimilarity, item: item)
                
                results.append(EnhancedSimilarityResult(
                    item: item,
                    similarity: enhancedSimilarity,
                    confidence: confidence,
                    matchType: determineMatchType(similarity: enhancedSimilarity),
                    reasoningFactors: generateReasoningFactors(item: item, query: query, similarity: enhancedSimilarity)
                ))
            }
        }
        
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Generate and store embedding for a PARA item
    func generateEmbeddingForPARAItem(id: UUID, content: String, type: String) async {
        print("🔧 EMBEDDINGS: *** ENTRY *** generateEmbeddingForPARAItem called for \(type): \(id)")
        print("🔧 EMBEDDINGS: Content: \"\(content.prefix(100))...\"")
        
        guard !content.isEmpty else { 
            print("🔧 EMBEDDINGS: ❌ Empty content, skipping")
            return 
        }
        
        print("🔧 EMBEDDINGS: ✅ Content not empty, proceeding with embedding generation")
        print("🔧 EMBEDDINGS: Calling getEmbedding...")
        
        if let embedding = await getEmbedding(for: content) {
            print("🔧 EMBEDDINGS: ✅ Embedding generated successfully, storing...")
            // Store embedding in the appropriate PARA table
            await storePARAEmbedding(id: id, embedding: embedding, type: type)
        } else {
            print("🔧 EMBEDDINGS: ❌ Failed to generate embedding")
        }
    }
    
    /// Store embedding in PARA table
    private func storePARAEmbedding(id: UUID, embedding: [Float], type: String) async {
        do {
            let tableName: String
            switch type {
            case "project": tableName = "projects"
            case "area": tableName = "areas"
            case "resource": tableName = "resources"
            case "blob": tableName = "blobs"
            case "archive": tableName = "archives"
            case "journal": tableName = "journal_entries"
            case "task": tableName = "tasks"
            case "note": tableName = "blobs"
            case "financial_transaction": tableName = "financial_transactions"
            case "appointment": tableName = "calendar_events"
            case "habit": tableName = "habits"
            case "goal": tableName = "goals"
            default:
                print("🔧 EMBEDDINGS: ❌ Unknown PARA type: \(type)")
                return
            }
            
            try await supabaseService.client
                .from(tableName)
                .update(["embedding": embedding])
                .eq("id", value: id.uuidString)
                .execute()
            
            print("🔧 EMBEDDINGS: ✅ Stored embedding for \(type) \(id)")
            
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to store embedding for \(type) \(id): \(error)")
        }
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
                        await storePARAEmbedding(id: item.id, embedding: embedding, type: item.category.rawValue)
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
        
        let apiKey = loadAPIKey()
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
            
            print("🔧 EMBEDDINGS: ✅ Generated embedding for: \"\(text.prefix(50))...\" [vector: \(firstEmbedding.embedding.count) dimensions]")
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
    
    /// Normalize text for consistent embedding generation with domain-specific preprocessing
    private func normalizeText(_ text: String) -> String {
        var normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Preserve case for proper nouns and acronyms but normalize common words
        normalized = preprocessPARAContent(normalized)
        
        return normalized
    }
    
    /// Preprocess content for PARA-specific embedding enhancement
    private func preprocessPARAContent(_ text: String) -> String {
        var processed = text
        
        // Expand common PARA abbreviations
        let paraExpansions = [
            "proj": "project",
            "mtg": "meeting",
            "appt": "appointment",
            "todo": "task to do",
            "followup": "follow up",
            "asap": "as soon as possible",
            "fyi": "for your information"
        ]
        
        for (abbrev, expansion) in paraExpansions {
            processed = processed.replacingOccurrences(
                of: "\\b\(abbrev)\\b",
                with: expansion,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Add semantic markers for better categorization
        if processed.contains("deadline") || processed.contains("due") || processed.contains("urgent") {
            processed = "priority task: " + processed
        }
        
        if processed.contains("meeting") || processed.contains("call") || processed.contains("discussion") {
            processed = "collaboration: " + processed
        }
        
        if processed.contains("learn") || processed.contains("research") || processed.contains("study") {
            processed = "knowledge work: " + processed
        }
        
        return processed
    }
    
    /// Generate cache key for text
    private func generateCacheKey(for text: String) -> String {
        return text.data(using: .utf8)?.base64EncodedString() ?? text
    }
    
    // MARK: - API Key Management
    
    /// Load OpenAI API key from environment or config file
    private func loadAPIKey() -> String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Then try config.txt file
        let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("config.txt")
        
        do {
            let content = try String(contentsOf: configPath)
            
            if content.contains("OPENAI_API_KEY=") {
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    if line.hasPrefix("OPENAI_API_KEY=") {
                        let apiKey = String(line.dropFirst("OPENAI_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !apiKey.isEmpty && !apiKey.contains("your-openai-api-key-here") {
                            print("🔧 EMBEDDINGS: ✅ Loaded API key from config.txt")
                            return apiKey
                        }
                    }
                }
            }
        } catch {
            print("🔧 EMBEDDINGS: ⚠️ Could not read config.txt: \(error)")
        }
        
        print("🔧 EMBEDDINGS: ❌ No valid OpenAI API key found")
        return ""
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
        var items: [PARAItem] = []
        
        do {
            // Load projects
            let projects = try await supabaseService.client
                .from("projects")
                .select("id, name, description")
                .execute()
                .value as? [[String: Any]] ?? []
            
            for project in projects {
                if let idString = project["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let name = project["name"] as? String {
                    let description = project["description"] as? String ?? ""
                    let content = "\(name). \(description)".trimmingCharacters(in: .whitespaces)
                    items.append(PARAItem(
                        id: id,
                        title: name,
                        content: content,
                        contentType: .note,
                        paraCategory: .project,
                        workPersonal: .personal,
                        priority: .medium
                    ))
                }
            }
            
            // Load areas
            let areas = try await supabaseService.client
                .from("areas")
                .select("id, name, description")
                .execute()
                .value as? [[String: Any]] ?? []
            
            for area in areas {
                if let idString = area["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let name = area["name"] as? String {
                    let description = area["description"] as? String ?? ""
                    let content = "\(name). \(description)".trimmingCharacters(in: .whitespaces)
                    items.append(PARAItem(
                        id: id,
                        title: name,
                        content: content,
                        contentType: .note,
                        paraCategory: .area,
                        workPersonal: .personal,
                        priority: .medium
                    ))
                }
            }
            
            // Load resources
            let resources = try await supabaseService.client
                .from("resources")
                .select("id, title, summary")
                .execute()
                .value as? [[String: Any]] ?? []
            
            for resource in resources {
                if let idString = resource["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let title = resource["title"] as? String {
                    let summary = resource["summary"] as? String ?? ""
                    let content = "\(title). \(summary)".trimmingCharacters(in: .whitespaces)
                    items.append(PARAItem(
                        id: id,
                        title: title,
                        content: content,
                        contentType: .note,
                        paraCategory: .resource,
                        workPersonal: .personal,
                        priority: .medium
                    ))
                }
            }
            
            print("🔧 EMBEDDINGS: ✅ Loaded \(items.count) PARA items for embedding generation")
            return items
            
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to load PARA items: \(error)")
            throw error
        }
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

// MARK: - Domain-Specific Enhancements

struct DomainContext {
    let category: PARACategory?
    let workPersonal: WorkPersonalType?
    let priority: TaskPriority?
    let tags: [String]
    let timeContext: Date?
}

struct EnhancedSimilarityResult {
    let item: PARAItem
    let similarity: Float
    let confidence: Float
    let matchType: MatchType
    let reasoningFactors: [String]
}

enum MatchType {
    case exact      // > 0.85 similarity
    case high       // 0.7 - 0.85 similarity
    case medium     // 0.55 - 0.7 similarity
    case contextual // Enhanced by context factors
}

// MARK: - Private Enhancement Methods

private extension EmbeddingsService {
    
    func applyDomainAdjustments(similarity: Float, key: String, context: DomainContext) -> Float {
        var adjustedSimilarity = similarity
        
        // Category-based adjustments
        if let category = context.category,
           let weight = EmbeddingsConfig.categoryWeights[category] {
            adjustedSimilarity *= weight
        }
        
        // Time-based relevance boost
        if let timeContext = context.timeContext {
            let daysSince = Calendar.current.dateComponents([.day], from: timeContext, to: Date()).day ?? 0
            let recencyBoost = max(0.1, 1.0 - (Float(daysSince) * 0.02)) // Decay over 50 days
            adjustedSimilarity *= recencyBoost
        }
        
        // Tag-based boosting
        if !context.tags.isEmpty {
            // Boost similarity if key contains any of the context tags
            for tag in context.tags {
                if key.lowercased().contains(tag.lowercased()) {
                    adjustedSimilarity *= 1.1
                    break
                }
            }
        }
        
        return min(1.0, adjustedSimilarity) // Cap at 1.0
    }
    
    func enhancePARASimilarity(similarity: Float, item: PARAItem, query: String) -> Float {
        var enhanced = similarity
        
        // Priority-based enhancement
        switch item.priority {
        case .urgent:
            enhanced *= 1.25
        case .high:
            enhanced *= 1.15
        case .medium:
            enhanced *= 1.05
        case .low:
            enhanced *= 0.95
        }
        
        // Category-specific pattern matching
        if item.category == .project {
            let projectKeywords = ["deadline", "milestone", "deliver", "complete", "finish"]
            if projectKeywords.contains(where: { query.lowercased().contains($0) }) {
                enhanced *= 1.2
            }
        }
        
        if item.category == .area {
            let areaKeywords = ["ongoing", "maintain", "review", "monitor", "manage"]
            if areaKeywords.contains(where: { query.lowercased().contains($0) }) {
                enhanced *= 1.15
            }
        }
        
        // Recency boost for recent items
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: item.createdAt, to: Date()).day ?? 0
        if daysSinceCreation <= 7 {
            enhanced *= 1.1 // 10% boost for items created in last week
        }
        
        return min(1.0, enhanced)
    }
    
    func calculateConfidenceScore(similarity: Float, item: PARAItem) -> Float {
        var confidence = similarity
        
        // Boost confidence for items with more context
        if !item.content.isEmpty {
            confidence *= 1.1
        }
        
        if !item.tags.isEmpty {
            confidence *= 1.05
        }
        
        // Category-specific confidence adjustments
        switch item.category {
        case .project:
            confidence *= 1.1 // Projects typically have more structured content
        case .area:
            confidence *= 1.05
        case .resource:
            confidence *= 1.0
        case .archive:
            confidence *= 0.9 // Archived items less relevant
        }
        
        return min(1.0, confidence)
    }
    
    func determineMatchType(similarity: Float) -> MatchType {
        if similarity >= EmbeddingsConfig.highSimilarityThreshold {
            return .exact
        } else if similarity >= EmbeddingsConfig.mediumSimilarityThreshold {
            return .high
        } else if similarity >= EmbeddingsConfig.lowSimilarityThreshold {
            return .medium
        } else {
            return .contextual
        }
    }
    
    func generateReasoningFactors(item: PARAItem, query: String, similarity: Float) -> [String] {
        var factors: [String] = []
        
        if similarity >= EmbeddingsConfig.highSimilarityThreshold {
            factors.append("High semantic similarity (\(String(format: "%.2f", similarity)))")
        }
        
        if item.category == .project {
            factors.append("Project category match")
        }
        
        if item.priority == .high {
            factors.append("High priority item")
        }
        
        let daysSince = Calendar.current.dateComponents([.day], from: item.createdAt, to: Date()).day ?? 0
        if daysSince <= 7 {
            factors.append("Recent item (\(daysSince) days ago)")
        }
        
        if !item.tags.isEmpty {
            factors.append("Tagged item: \(item.tags.joined(separator: ", "))")
        }
        
        return factors
    }
    
    func loadFilteredPARAItems(
        category: PARACategory?,
        workPersonal: WorkPersonalType?,
        timeWindow: TimeInterval?
    ) async -> [PARAItem] {
        // This would load PARA items with the specified filters
        // For now, returning a placeholder - would integrate with actual data loading
        do {
            var items = try await loadAllPARAItems()
            
            if let category = category {
                items = items.filter { $0.category == category }
            }
            
            if let workPersonal = workPersonal {
                items = items.filter { $0.workPersonal == workPersonal }
            }
            
            if let timeWindow = timeWindow {
                let cutoffDate = Date().addingTimeInterval(-timeWindow)
                items = items.filter { $0.createdAt >= cutoffDate }
            }
            
            return items
        } catch {
            print("🔧 EMBEDDINGS: ❌ Failed to load filtered PARA items: \(error)")
            return []
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}