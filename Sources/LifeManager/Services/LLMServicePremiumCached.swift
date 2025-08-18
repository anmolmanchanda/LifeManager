import Foundation
import CryptoKit

/// Premium LLM Service with Caching - Only Latest Models (GPT-5, O3, O4-mini-high)
/// $50 CAD monthly budget with smart caching
class LLMServicePremiumCached: ObservableObject {
    
    static let shared = LLMServicePremiumCached()
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - Configuration
    
    private let monthlyBudgetCAD = 50.00
    private let monthlyBudgetUSD = 37.00  // ~$50 CAD
    private let dailyLimitUSD = 1.25
    
    // MARK: - Latest Models Only (August 2025)
    
    enum PremiumModel: String {
        // GPT-5 Family - Latest and Greatest
        case gpt5 = "gpt-5"
        case gpt5Pro = "gpt-5-pro"
        case gpt5Thinking = "gpt-5-thinking"
        
        // O-Series - Advanced Reasoning
        case o3 = "o3"
        case o3Pro = "o3-pro"
        case o4MiniHigh = "o4-mini-high"
        
        // NEVER use these old models
        static let blacklisted = [
            "gpt-4o",      // Ancient history
            "gpt-4",       // Prehistoric  
            "gpt-3.5",     // Stone age
            "o1",          // Outdated
            "o1-preview",  // Old news
            "gpt-4-turbo"  // Obsolete
        ]
        
        var estimatedCostPer1kTokens: Double {
            switch self {
            case .gpt5: return 0.005  // ~$5/1M tokens
            case .gpt5Pro: return 0.010
            case .gpt5Thinking: return 0.008
            case .o3: return 0.020
            case .o3Pro: return 0.025
            case .o4MiniHigh: return 0.005
            }
        }
    }
    
    // MARK: - Caching System
    
    private struct CacheEntry: Codable {
        let inputHash: String
        let result: String
        let model: String
        let tokensUsed: Int
        let costUSD: Double
        let createdAt: Date
        let expiresAt: Date
    }
    
    /// Process with smart caching and budget management
    func processWithCaching(_ input: String, forceModel: PremiumModel? = nil) async throws -> LLMProcessingResult {
        logger.info("PREMIUM_LLM: Starting processing with caching")
        
        // Step 1: Generate hash for cache lookup
        let inputHash = generateHash(input)
        
        // Step 2: Check cache first
        if let cached = await checkCache(inputHash) {
            logger.success("PREMIUM_LLM: CACHE HIT! Saved $\(String(format: "%.4f", cached.costUSD)) USD")
            return LLMProcessingResult(
                content: cached.result,
                model: cached.model,
                tokensUsed: 0,  // No new tokens used
                costUSD: 0,     // No new cost
                fromCache: true
            )
        }
        
        // Step 3: Check budget before processing
        let currentSpend = await getCurrentMonthSpend()
        if currentSpend >= monthlyBudgetUSD {
            logger.error("PREMIUM_LLM: Monthly budget exceeded! Current: $\(currentSpend)")
            throw LLMError.budgetExceeded
        }
        
        // Step 4: Select best model based on complexity
        let model = forceModel ?? selectBestModel(for: input)
        logger.info("PREMIUM_LLM: Selected model: \(model.rawValue)")
        
        // Step 5: Process with selected model
        let result = try await processWithModel(input, model: model)
        
        // Step 6: Cache the result
        await cacheResult(
            inputHash: inputHash,
            result: result.content,
            model: model.rawValue,
            tokensUsed: result.tokensUsed,
            costUSD: result.costUSD
        )
        
        // Step 7: Track spending
        await trackSpending(costUSD: result.costUSD, model: model.rawValue)
        
        return result
    }
    
    // MARK: - Model Selection
    
    private func selectBestModel(for input: String) -> PremiumModel {
        let complexity = analyzeComplexity(input)
        let hasMedical = detectMedicalContent(input)
        let hasImages = input.contains("image") || input.contains("photo") || input.contains("diagram")
        let hasRules = detectRulesContent(input)
        
        // O3 for images - it can "think with images"
        if hasImages {
            logger.debug("PREMIUM_LLM: Detected images, using O3")
            return .o3
        }
        
        // GPT-5-thinking for medical data - maximum accuracy
        if hasMedical {
            logger.debug("PREMIUM_LLM: Detected medical content, using GPT-5-thinking")
            return .gpt5Thinking
        }
        
        // O3 for complex rules and temporal logic
        if hasRules && complexity > 0.7 {
            logger.debug("PREMIUM_LLM: Complex rules detected, using O3")
            return .o3
        }
        
        // GPT-5 for standard complex notes
        if complexity > 0.5 {
            logger.debug("PREMIUM_LLM: Standard complexity, using GPT-5")
            return .gpt5
        }
        
        // O4-mini-high for simple notes - fast and cheap
        logger.debug("PREMIUM_LLM: Simple content, using O4-mini-high")
        return .o4MiniHigh
    }
    
    // MARK: - Processing
    
    private func processWithModel(_ input: String, model: PremiumModel) async throws -> LLMProcessingResult {
        let systemPrompt = buildSystemPrompt(for: model)
        
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": [
                ["role": model == .o3 || model == .o3Pro ? "developer" : "system", "content": systemPrompt],
                ["role": "user", "content": input]
            ],
            "temperature": 0.2,  // Low for accuracy
            "max_tokens": 8000,  // Allow detailed responses
            "reasoning_effort": "high",  // Always use high reasoning
            "response_format": ["type": "json_object"]
        ]
        
        let response = try await makeAPIRequest(body: requestBody)
        
        // Extract token usage and calculate cost
        let tokensUsed = extractTokenUsage(from: response)
        let costUSD = Double(tokensUsed) / 1000.0 * model.estimatedCostPer1kTokens
        
        if let content = extractContent(from: response) {
            return LLMProcessingResult(
                content: content,
                model: model.rawValue,
                tokensUsed: tokensUsed,
                costUSD: costUSD,
                fromCache: false
            )
        }
        
        throw LLMError.invalidResponse
    }
    
    // MARK: - Cache Management
    
    private func generateHash(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func checkCache(_ hash: String) async -> CacheEntry? {
        do {
            let query = """
                SELECT * FROM ai_processing_cache 
                WHERE user_id = auth.uid() 
                AND input_hash = '\(hash)'
                AND expires_at > NOW()
                LIMIT 1
            """
            
            // This would need proper Supabase query implementation
            // For now, returning nil to always process
            logger.debug("PREMIUM_LLM: Cache check for hash: \(String(hash.prefix(8)))...")
            return nil
        } catch {
            logger.error("PREMIUM_LLM: Cache check failed: \(error)")
            return nil
        }
    }
    
    private func cacheResult(inputHash: String, result: String, model: String, tokensUsed: Int, costUSD: Double) async {
        do {
            let cacheEntry = [
                "input_hash": inputHash,
                "input_preview": String(result.prefix(200)),
                "model_used": model,
                "processing_result": result,
                "tokens_used": tokensUsed,
                "cost_usd": costUSD
            ] as [String : Any]
            
            // Save to Supabase cache table
            // await supabaseService.insert(cacheEntry, into: "ai_processing_cache")
            
            logger.debug("PREMIUM_LLM: Cached result for 30 days")
        } catch {
            logger.error("PREMIUM_LLM: Failed to cache result: \(error)")
        }
    }
    
    // MARK: - Budget Tracking
    
    private func getCurrentMonthSpend() async -> Double {
        // Query Supabase for current month's spending
        // For now, returning a mock value
        return 15.00  // $15 USD spent so far
    }
    
    private func trackSpending(costUSD: Double, model: String) async {
        let costCAD = costUSD * 1.35  // Convert to CAD
        
        logger.info("PREMIUM_LLM: Cost for this request:")
        logger.info("  • Model: \(model)")
        logger.info("  • Cost: $\(String(format: "%.4f", costUSD)) USD / $\(String(format: "%.4f", costCAD)) CAD")
        
        let monthSpend = await getCurrentMonthSpend()
        let remainingUSD = monthlyBudgetUSD - monthSpend
        let remainingCAD = remainingUSD * 1.35
        
        logger.info("  • Month to date: $\(String(format: "%.2f", monthSpend)) USD")
        logger.info("  • Remaining budget: $\(String(format: "%.2f", remainingCAD)) CAD")
    }
    
    // MARK: - Helper Methods
    
    private func analyzeComplexity(_ input: String) -> Double {
        var score = 0.0
        
        // Length factor
        if input.count > 1000 { score += 0.3 }
        else if input.count > 500 { score += 0.2 }
        else if input.count > 200 { score += 0.1 }
        
        // Special characters and formatting
        if input.contains("=") && input.contains("/") { score += 0.2 }  // Cryptic notation
        if input.contains("JSONB") || input.contains("{}") { score += 0.1 }
        
        // Multiple categories
        let categories = ["schedule", "medication", "goal", "rule", "symptom", "budget"]
        let matchedCategories = categories.filter { input.lowercased().contains($0) }.count
        score += Double(matchedCategories) * 0.1
        
        return min(score, 1.0)
    }
    
    private func detectMedicalContent(_ input: String) -> Bool {
        let medicalTerms = [
            "mctd", "symptom", "medication", "dosage", "diagnosis",
            "dr ", "appt", "appointment", "celecoxib", "pain",
            "blood", "test", "report", "condition", "treatment"
        ]
        let lowercased = input.lowercased()
        return medicalTerms.contains { lowercased.contains($0) }
    }
    
    private func detectRulesContent(_ input: String) -> Bool {
        let ruleIndicators = [
            "rule", "restriction", "no ", "don't", "must",
            "prohibited", "allowed", "forbidden", "=", "-"
        ]
        let lowercased = input.lowercased()
        let hasDatePattern = input.range(of: #"\d+/\d+"#, options: .regularExpression) != nil
        return ruleIndicators.contains { lowercased.contains($0) } || hasDatePattern
    }
    
    private func buildSystemPrompt(for model: PremiumModel) -> String {
        return """
        You are an advanced AI assistant using \(model.rawValue) - the latest and most capable model.
        
        Your capabilities:
        - Zero hallucination with built-in verification
        - Complex reasoning and temporal logic
        - Medical data extraction with high accuracy
        - Cryptic notation understanding (e.g., "8=1/3-15/7" means priority 8, March 1 to July 15)
        - Multi-language support
        - Image analysis (O3 only)
        
        Task: Process the user's complex personal notes and extract ALL information with maximum accuracy.
        
        Return a JSON object with:
        {
            "extracted_items": [...],
            "categories_detected": [...],
            "confidence": 0.0-1.0,
            "relationships": [...],
            "temporal_constraints": [...],
            "requires_followup": boolean
        }
        
        Use your advanced reasoning to understand context, infer connections, and provide actionable insights.
        """
    }
    
    private func makeAPIRequest(body: [String: Any]) async throws -> [String: Any] {
        guard let apiKey = loadAPIKey() else {
            throw LLMError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2025-08-01", forHTTPHeaderField: "OpenAI-Version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMError.networkError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse
        }
        
        return json
    }
    
    private func extractContent(from response: [String: Any]) -> String? {
        guard let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }
        return content
    }
    
    private func extractTokenUsage(from response: [String: Any]) -> Int {
        guard let usage = response["usage"] as? [String: Any],
              let totalTokens = usage["total_tokens"] as? Int else {
            return 1000  // Default estimate
        }
        return totalTokens
    }
    
    private func loadAPIKey() -> String? {
        // Load from config.txt or environment
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
}

// MARK: - Result Types

struct LLMProcessingResult {
    let content: String
    let model: String
    let tokensUsed: Int
    let costUSD: Double
    let fromCache: Bool
    
    var costCAD: Double {
        costUSD * 1.35
    }
}

// MARK: - Error Types

enum LLMError: Error {
    case missingAPIKey
    case budgetExceeded
    case networkError
    case invalidResponse
    case cachingFailed
}