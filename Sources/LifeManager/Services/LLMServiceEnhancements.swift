import Foundation

// Extensions to LLMService for o1 reasoning and structured outputs
extension LLMService {
    
    // MARK: - O1 Reasoning Support
    
    /// Perform reasoning with OpenAI o1 model
    func performO1Reasoning(
        systemPrompt: String,
        userPrompt: String,
        reasoningEffort: String = "medium", // "low", "medium", "high"
        responseFormat: ResponseFormat = .json
    ) async throws -> String {
        
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        // Build the request body for o1
        let requestBody: [String: Any] = [
            "model": "o1-preview", // or "o1" when available
            "messages": [
                ["role": "developer", "content": systemPrompt], // o1 uses developer role
                ["role": "user", "content": userPrompt]
            ],
            "reasoning_effort": reasoningEffort,
            "temperature": 0.7,
            "response_format": ["type": responseFormat.rawValue]
        ]
        
        let response = try await makeOpenAIRequest(endpoint: endpoint, body: requestBody)
        
        guard let content = extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        
        // Log reasoning tokens used
        if let usage = response["usage"] as? [String: Any],
           let reasoningTokens = usage["reasoning_tokens"] as? Int {
            Logger.shared.debug("O1_REASONING: Used \(reasoningTokens) reasoning tokens")
        }
        
        return content
    }
    
    // MARK: - Structured Outputs Support
    
    /// Extract data with GPT-4 structured outputs
    func extractWithStructuredOutput(
        input: Any,
        schema: String
    ) async throws -> String {
        
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        let systemPrompt = """
        Extract structured data according to the provided JSON schema.
        Ensure all required fields are populated and data types match exactly.
        """
        
        let userPrompt: String
        if let inputString = input as? String {
            userPrompt = inputString
        } else if let inputData = try? JSONSerialization.data(withJSONObject: input),
                  let inputJSON = String(data: inputData, encoding: .utf8) {
            userPrompt = inputJSON
        } else {
            userPrompt = String(describing: input)
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-2024-08-06", // Latest model with structured outputs
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "extraction",
                    "strict": true,
                    "schema": schema
                ]
            ],
            "temperature": 0.3 // Lower temperature for structured extraction
        ]
        
        let response = try await makeOpenAIRequest(endpoint: endpoint, body: requestBody)
        
        guard let content = extractContent(from: response) else {
            throw LLMError.invalidResponse
        }
        
        // Validate JSON structure
        guard let _ = try? JSONSerialization.jsonObject(with: content.data(using: .utf8) ?? Data()) else {
            throw LLMError.invalidJSONResponse
        }
        
        return content
    }
    
    // MARK: - Chain Processing (O1 → GPT-4 structured)
    
    /// Chain o1 reasoning with GPT-4 structured output
    func chainedProcessing(
        initialPrompt: String,
        reasoningEffort: String = "high",
        outputSchema: String
    ) async throws -> String {
        
        // Step 1: Use o1 for deep reasoning
        let reasoningResult = try await performO1Reasoning(
            systemPrompt: "Analyze the input thoroughly and identify all important information.",
            userPrompt: initialPrompt,
            reasoningEffort: reasoningEffort,
            responseFormat: .text // Let o1 reason freely
        )
        
        Logger.shared.debug("CHAINED: O1 reasoning complete")
        
        // Step 2: Use GPT-4 to structure the o1 output
        let structuredResult = try await extractWithStructuredOutput(
            input: reasoningResult,
            schema: outputSchema
        )
        
        Logger.shared.debug("CHAINED: Structured extraction complete")
        
        return structuredResult
    }
    
    // MARK: - Enhanced Embeddings with Metadata
    
    /// Generate embeddings with metadata for better semantic matching
    func generateEnhancedEmbedding(
        text: String,
        metadata: [String: Any]? = nil
    ) async throws -> EnhancedEmbedding {
        
        let endpoint = "https://api.openai.com/v1/embeddings"
        
        // Enrich text with metadata for better embeddings
        var enrichedText = text
        if let metadata = metadata {
            enrichedText += "\nContext: "
            for (key, value) in metadata {
                enrichedText += "\(key): \(value) "
            }
        }
        
        let requestBody: [String: Any] = [
            "model": "text-embedding-3-large", // Latest embedding model
            "input": enrichedText,
            "dimensions": 1536 // Standard dimension
        ]
        
        let response = try await makeOpenAIRequest(endpoint: endpoint, body: requestBody)
        
        guard let data = response["data"] as? [[String: Any]],
              let embedding = data.first?["embedding"] as? [Double] else {
            throw LLMError.embeddingExtractionFailed
        }
        
        return EnhancedEmbedding(
            text: text,
            embedding: embedding.map { Float($0) },
            metadata: metadata,
            model: "text-embedding-3-large"
        )
    }
    
    // MARK: - Batch Processing for Complex Notes
    
    /// Process multiple segments in parallel
    func batchProcessSegments(
        segments: [String],
        processingType: ProcessingType
    ) async throws -> [ProcessedSegment] {
        
        return try await withThrowingTaskGroup(of: ProcessedSegment.self) { group in
            for (index, segment) in segments.enumerated() {
                group.addTask {
                    let result = try await self.processSegment(
                        segment,
                        index: index,
                        type: processingType
                    )
                    return result
                }
            }
            
            var results: [ProcessedSegment] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by original index to maintain order
            return results.sorted { $0.index < $1.index }
        }
    }
    
    private func processSegment(
        _ segment: String,
        index: Int,
        type: ProcessingType
    ) async throws -> ProcessedSegment {
        
        let prompt = buildSegmentPrompt(for: type)
        
        let result = try await performO1Reasoning(
            systemPrompt: prompt,
            userPrompt: segment,
            reasoningEffort: "medium",
            responseFormat: .json
        )
        
        return ProcessedSegment(
            index: index,
            originalText: segment,
            processedData: result,
            type: type
        )
    }
    
    private func buildSegmentPrompt(for type: ProcessingType) -> String {
        switch type {
        case .medical:
            return """
            Extract medical information including:
            - Conditions and diagnoses
            - Symptoms with severity
            - Medications with dosages
            - Appointment details
            - Test results and reports
            """
        case .schedule:
            return """
            Parse schedule information including:
            - Time blocks and durations
            - Recurring patterns
            - Exceptions and special dates
            - Activities and categories
            """
        case .rules:
            return """
            Identify rules and restrictions including:
            - Behavioral restrictions
            - Time-bounded constraints
            - Conditional logic
            - Priorities and enforcement levels
            """
        case .goals:
            return """
            Extract goals and objectives including:
            - Target dates and milestones
            - Progress metrics
            - Dependencies
            - Categories and priorities
            """
        default:
            return "Extract all relevant information and categorize appropriately."
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeOpenAIRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        guard let apiKey = getAPIKey() else {
            throw LLMError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                Logger.shared.error("OpenAI API Error: \(message)")
                throw LLMError.apiError(message)
            }
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
    
    private func getAPIKey() -> String? {
        // Use existing API key loading logic
        return loadAPIKey()
    }
}

// MARK: - Supporting Types

enum ResponseFormat: String {
    case json = "json_object"
    case text = "text"
    case jsonSchema = "json_schema"
}

enum ProcessingType {
    case medical, schedule, rules, goals, financial, general
}

struct EnhancedEmbedding {
    let text: String
    let embedding: [Float]
    let metadata: [String: Any]?
    let model: String
}

struct ProcessedSegment {
    let index: Int
    let originalText: String
    let processedData: String
    let type: ProcessingType
}

// Extended error types - using the LLMError enum from LLMServicePremiumCached.swift
// No extension needed as LLMError is already defined