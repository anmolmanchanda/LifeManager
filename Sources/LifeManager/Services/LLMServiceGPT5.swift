import Foundation

/// Enhanced LLM Service with GPT-5, O3, and O4-mini-high support
/// Implements the latest August 2025 AI capabilities
class LLMServiceGPT5: ObservableObject {
    
    static let shared = LLMServiceGPT5()
    private let logger = Logger.shared
    
    // MARK: - Model Definitions (August 2025)
    
    enum LatestModel: String {
        // GPT-5 Family (Released August 7, 2025)
        case gpt5 = "gpt-5"                    // Default unified adaptive model
        case gpt5Pro = "gpt-5-pro"             // Extended reasoning for complex tasks
        case gpt5Mini = "gpt-5-mini"           // Fast, efficient for routine queries
        case gpt5Thinking = "gpt-5-thinking"   // Built-in chain-of-thought reasoning
        
        // O-Series (Released April 16, 2025, updated through August)
        case o3 = "o3"                         // Latest reasoning model with image thinking
        case o3Pro = "o3-pro"                  // Available June 10, 2025
        case o4Mini = "o4-mini"                // Fast, cost-efficient reasoning
        case o4MiniHigh = "o4-mini-high"       // Extended processing for reliability
        
        // Legacy models for compatibility
        case gpt4o = "gpt-4o-2024-08-06"       // Structured outputs support
        case o1Preview = "o1-preview"          // Previous generation reasoning
        
        var supportsThinking: Bool {
            switch self {
            case .gpt5, .gpt5Pro, .gpt5Thinking, .o3, .o3Pro, .o4Mini, .o4MiniHigh:
                return true
            default:
                return false
            }
        }
        
        var supportsImages: Bool {
            switch self {
            case .gpt5, .gpt5Pro, .gpt5Mini, .o3, .o3Pro, .o4Mini, .o4MiniHigh:
                return true
            default:
                return false
            }
        }
        
        var supportsDeveloperRole: Bool {
            // O-series uses developer role instead of system
            switch self {
            case .o3, .o3Pro, .o4Mini, .o4MiniHigh:
                return true
            default:
                return false
            }
        }
    }
    
    enum ReasoningEffort: String {
        case minimal = "minimal"   // Fastest response
        case low = "low"          // Quick thinking
        case medium = "medium"    // Default balanced
        case high = "high"        // Deep reasoning
        case maximum = "maximum"  // GPT-5 Pro extended reasoning
    }
    
    // MARK: - GPT-5 Advanced Processing
    
    /// Process complex notes with GPT-5's unified adaptive system
    func processWithGPT5(
        _ input: String,
        useThinking: Bool = true,
        reasoningEffort: ReasoningEffort = .high,
        includeWebSearch: Bool = true
    ) async throws -> GPT5Result {
        
        logger.info("GPT5: Starting processing with thinking=\(useThinking), effort=\(reasoningEffort.rawValue)")
        
        let model = useThinking ? LatestModel.gpt5Thinking : LatestModel.gpt5
        
        let systemPrompt = """
        You are an expert life management assistant using GPT-5's advanced capabilities.
        
        Your task is to process complex personal notes with maximum accuracy:
        1. Extract ALL medical information (conditions, symptoms, medications)
        2. Parse date-bounded rules and restrictions with temporal logic
        3. Identify goals with milestones and dependencies
        4. Understand schedules and routines with recurrence patterns
        5. Detect financial items and budgets
        6. Recognize emotional states and therapy notes
        7. Extract relationships and contacts
        
        Use your built-in thinking to:
        - Decode cryptic notation (e.g., "8=1/3 16:07-15/7" means priority 8, March 1 to July 15)
        - Infer implicit connections between items
        - Identify temporal dependencies
        - Suggest PARA categorization (Projects, Areas, Resources, Archives)
        
        GPT-5 specific capabilities to leverage:
        - 45% less hallucination than GPT-4o with web search
        - 80% less hallucination than O1 when thinking
        - Real-time routing between fast and thinking modes
        - Unified adaptive processing for optimal results
        """
        
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": input]
            ],
            "reasoning_effort": reasoningEffort.rawValue,
            "temperature": 0.3, // Lower for accuracy
            "max_tokens": 4000,
            "response_format": ["type": "json_object"],
            "tools": includeWebSearch ? [
                [
                    "type": "web_search",
                    "enabled": true
                ]
            ] : nil
        ].compactMapValues { $0 }
        
        let response = try await makeOpenAIRequest(endpoint: "https://api.openai.com/v1/chat/completions", body: requestBody)
        
        // Extract thinking process if available
        var thinkingTokens = 0
        var thinkingContent = ""
        
        if let usage = response["usage"] as? [String: Any] {
            thinkingTokens = usage["reasoning_tokens"] as? Int ?? 0
            logger.debug("GPT5: Used \(thinkingTokens) thinking tokens")
        }
        
        if let choices = response["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any] {
            
            // GPT-5 may include thinking in a separate field
            if let thinking = message["thinking"] as? String {
                thinkingContent = thinking
            }
            
            if let content = message["content"] as? String {
                return GPT5Result(
                    model: model.rawValue,
                    content: content,
                    thinkingProcess: thinkingContent,
                    thinkingTokens: thinkingTokens,
                    confidence: calculateConfidence(from: response)
                )
            }
        }
        
        throw LLMError.invalidResponse
    }
    
    // MARK: - O3/O4 Advanced Reasoning with Image Support
    
    /// Process with O3 or O4-mini-high for maximum reasoning capability
    func processWithO3(
        _ input: String,
        images: [Data]? = nil,
        useO4MiniHigh: Bool = false
    ) async throws -> O3Result {
        
        let model = useO4MiniHigh ? LatestModel.o4MiniHigh : LatestModel.o3
        logger.info("O3: Processing with \(model.rawValue), images: \(images?.count ?? 0)")
        
        // O3/O4 can "think with images" - first in the series
        var messages: [[String: Any]] = []
        
        // O-series uses developer role
        let developerPrompt = """
        Analyze the provided content comprehensively. If images are included, analyze them during your reasoning phase.
        
        O3/O4 specific capabilities:
        - Think with images during chain-of-thought
        - 20% fewer errors than O1 on real-world tasks
        - Excel at programming, consulting, and creative ideation
        - Can use all ChatGPT tools: web search, Python, image analysis
        
        For complex personal notes:
        1. Identify all data types (medical, schedules, rules, goals)
        2. Extract temporal constraints and dependencies
        3. Parse cryptic notation and abbreviations
        4. Link related items across categories
        5. Suggest optimal organization structure
        """
        
        messages.append(["role": "developer", "content": developerPrompt])
        
        // Add user message with optional images
        var userMessage: [String: Any] = ["role": "user"]
        
        if let images = images, !images.isEmpty {
            // O3 supports multiple images in content
            var content: [[String: Any]] = [
                ["type": "text", "text": input]
            ]
            
            for imageData in images {
                let base64Image = imageData.base64EncodedString()
                content.append([
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)",
                        "detail": "high"
                    ]
                ])
            }
            
            userMessage["content"] = content
        } else {
            userMessage["content"] = input
        }
        
        messages.append(userMessage)
        
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "messages": messages,
            "max_tokens": 4000,
            "temperature": 0.2,
            "tools": [
                ["type": "web_search", "enabled": true],
                ["type": "code_interpreter", "enabled": true]
            ]
        ]
        
        let response = try await makeOpenAIRequest(endpoint: "https://api.openai.com/v1/chat/completions", body: requestBody)
        
        if let choices = response["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            // Extract tool usage if any
            let toolCalls = message["tool_calls"] as? [[String: Any]] ?? []
            
            return O3Result(
                model: model.rawValue,
                content: content,
                toolsUsed: toolCalls.compactMap { $0["type"] as? String },
                imagesAnalyzed: images?.count ?? 0
            )
        }
        
        throw LLMError.invalidResponse
    }
    
    // MARK: - Hybrid Processing: Combine Multiple Models
    
    /// Use multiple models for maximum accuracy
    func hybridProcessing(_ input: String) async throws -> HybridResult {
        logger.info("HYBRID: Starting multi-model processing")
        
        // Step 1: Quick analysis with GPT-5-mini
        let quickAnalysis = try await processQuickAnalysis(input)
        
        // Step 2: Deep reasoning with O3 if complex
        var deepReasoning: O3Result?
        if quickAnalysis.complexity > 0.7 {
            deepReasoning = try await processWithO3(input)
        }
        
        // Step 3: Final synthesis with GPT-5-thinking
        let synthesis = try await synthesizeResults(
            input: input,
            quickAnalysis: quickAnalysis,
            deepReasoning: deepReasoning
        )
        
        return HybridResult(
            quickAnalysis: quickAnalysis,
            deepReasoning: deepReasoning,
            finalSynthesis: synthesis,
            modelsUsed: ["gpt-5-mini", deepReasoning != nil ? "o3" : nil, "gpt-5-thinking"].compactMap { $0 }
        )
    }
    
    // MARK: - Helper Methods
    
    private func processQuickAnalysis(_ input: String) async throws -> QuickAnalysis {
        let response = try await processWithGPT5(
            input,
            useThinking: false,
            reasoningEffort: .minimal
        )
        
        // Parse the JSON response to determine complexity
        if let data = response.content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            let complexity = json["complexity_score"] as? Double ?? 0.5
            let categories = json["detected_categories"] as? [String] ?? []
            
            return QuickAnalysis(
                complexity: complexity,
                detectedCategories: categories,
                requiresDeepAnalysis: complexity > 0.7
            )
        }
        
        return QuickAnalysis(complexity: 0.5, detectedCategories: [], requiresDeepAnalysis: false)
    }
    
    private func synthesizeResults(
        input: String,
        quickAnalysis: QuickAnalysis,
        deepReasoning: O3Result?
    ) async throws -> GPT5Result {
        
        var synthesisPrompt = """
        Synthesize the analysis results into a final structured output.
        
        Input: \(input)
        
        Quick Analysis detected: \(quickAnalysis.detectedCategories.joined(separator: ", "))
        Complexity: \(quickAnalysis.complexity)
        """
        
        if let deepReasoning = deepReasoning {
            synthesisPrompt += "\n\nDeep Reasoning Results:\n\(deepReasoning.content)"
        }
        
        return try await processWithGPT5(
            synthesisPrompt,
            useThinking: true,
            reasoningEffort: .high
        )
    }
    
    private func calculateConfidence(from response: [String: Any]) -> Double {
        // GPT-5 provides confidence metrics in the response
        if let metadata = response["metadata"] as? [String: Any],
           let confidence = metadata["confidence_score"] as? Double {
            return confidence
        }
        
        // Fallback calculation based on token usage
        if let usage = response["usage"] as? [String: Any],
           let thinkingTokens = usage["reasoning_tokens"] as? Int {
            // More thinking generally means higher confidence
            return min(0.7 + (Double(thinkingTokens) / 10000.0), 0.95)
        }
        
        return 0.75 // Default confidence
    }
    
    private func makeOpenAIRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        guard let apiKey = loadAPIKey() else {
            throw LLMError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2025-08-01", forHTTPHeaderField: "OpenAI-Version") // GPT-5 API version
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                logger.error("GPT5 API Error: \(message)")
                throw LLMError.networkError
            }
            throw LLMError.networkError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse
        }
        
        return json
    }
    
    private func loadAPIKey() -> String? {
        // Load from config.txt or environment
        if let configPath = Bundle.main.path(forResource: "config", ofType: "txt"),
           let config = try? String(contentsOfFile: configPath) {
            for line in config.components(separatedBy: .newlines) {
                if line.hasPrefix("OPENAI_API_KEY=") {
                    return String(line.dropFirst("OPENAI_API_KEY=".count))
                }
            }
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
}

// MARK: - Result Types

struct GPT5Result {
    let model: String
    let content: String
    let thinkingProcess: String
    let thinkingTokens: Int
    let confidence: Double
}

struct O3Result {
    let model: String
    let content: String
    let toolsUsed: [String]
    let imagesAnalyzed: Int
}

struct QuickAnalysis {
    let complexity: Double
    let detectedCategories: [String]
    let requiresDeepAnalysis: Bool
}

struct HybridResult {
    let quickAnalysis: QuickAnalysis
    let deepReasoning: O3Result?
    let finalSynthesis: GPT5Result
    let modelsUsed: [String]
}