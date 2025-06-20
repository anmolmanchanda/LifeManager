//
// LLMCommunicationService.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - LLM Communication Layer
// Extracted from LLMService as part of Phase 2B decomposition
// Handles direct API communication with OpenAI, Claude, and other LLM providers
//

import Foundation

/// Manages direct communication with LLM providers
/// Handles HTTP requests, response parsing, and provider-specific protocols
/// Extracted from LLMService for better separation of concerns
class LLMCommunicationService: ObservableObject {
    
    static let shared = LLMCommunicationService()
    
    // MARK: - Dependencies
    
    private let configService = LLMConfigurationService.shared
    private let logger = Logger.shared
    
    // MARK: - State
    
    @Published var isProcessing = false
    @Published var lastRequestTime: Date?
    @Published var totalRequestsToday = 0
    
    // MARK: - Rate Limiting
    
    private var requestCount = 0
    private var lastResetDate = Date()
    private let maxRequestsPerDay = 1000 // Adjust based on API limits
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Core Communication Methods
    
    /// Make LLM request using best available provider
    func callLLM(prompt: String) async throws -> String {
        guard let provider = configService.getBestAvailableProvider() else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await callLLM(prompt: prompt, provider: provider)
    }
    
    /// Make LLM request with specific provider
    func callLLM(prompt: String, provider: LLMConfigurationService.LLMProvider) async throws -> String {
        // Check rate limits
        try checkRateLimit()
        
        await MainActor.run {
            isProcessing = true
            lastRequestTime = Date()
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        do {
            let response: String
            
            switch provider {
            case .openAI:
                response = try await callOpenAI(prompt: prompt)
            case .claude:
                response = try await callClaude(prompt: prompt)
            }
            
            // Update request counting
            await MainActor.run {
                incrementRequestCount()
            }
            
            logger.success("🤖 LLM: Request completed successfully with \(provider.displayName)")
            return response
            
        } catch {
            logger.error("🤖 LLM: Request failed with \(provider.displayName): \(error)")
            throw error
        }
    }
    
    // MARK: - OpenAI Communication
    
    private func callOpenAI(prompt: String) async throws -> String {
        let apiKey = configService.getOpenAIKey()
        guard !apiKey.isEmpty && apiKey != "your-openai-api-key-here" else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        let url = URL(string: "\(configService.getOpenAIBaseURL())/chat/completions")!
        
        return try await performOpenAIRequest(url: url, prompt: prompt)
    }
    
    private func performOpenAIRequest(url: URL, prompt: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configService.getOpenAIKey())", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 4000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("🤖 OPENAI: Making request to \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMCommunicationError.invalidResponse
        }
        
        logger.info("🤖 OPENAI: Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("🤖 OPENAI: API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw LLMCommunicationError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMCommunicationError.invalidResponse
        }
        
        logger.success("🤖 OPENAI: Response received, length: \(content.count)")
        return content
    }
    
    // MARK: - Claude Communication
    
    private func callClaude(prompt: String) async throws -> String {
        let apiKey = configService.getClaudeKey()
        guard !apiKey.isEmpty else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        let url = URL(string: "\(configService.getClaudeBaseURL())/messages")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": "claude-3-sonnet-20240229",
            "max_tokens": 4000,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        logger.info("🤖 CLAUDE: Making request to \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMCommunicationError.invalidResponse
        }
        
        logger.info("🤖 CLAUDE: Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("🤖 CLAUDE: API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw LLMCommunicationError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw LLMCommunicationError.invalidResponse
        }
        
        logger.success("🤖 CLAUDE: Response received, length: \(text.count)")
        return text
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit() throws {
        let now = Date()
        let calendar = Calendar.current
        
        // Reset daily counter if it's a new day
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            totalRequestsToday = 0
            lastResetDate = now
        }
        
        guard totalRequestsToday < maxRequestsPerDay else {
            throw LLMCommunicationError.rateLimitExceeded
        }
    }
    
    private func incrementRequestCount() {
        totalRequestsToday += 1
        requestCount += 1
    }
    
    // MARK: - Request Management
    
    /// Test connectivity to a specific provider
    func testConnectivity(provider: LLMConfigurationService.LLMProvider) async -> Bool {
        do {
            let testPrompt = "Respond with 'OK' if you can read this message."
            let response = try await callLLM(prompt: testPrompt, provider: provider)
            return response.contains("OK") || response.contains("ok")
        } catch {
            logger.error("🤖 TEST: Connectivity test failed for \(provider.displayName): \(error)")
            return false
        }
    }
    
    /// Get request statistics
    func getRequestStatistics() -> RequestStatistics {
        return RequestStatistics(
            totalRequestsToday: totalRequestsToday,
            totalRequestsSession: requestCount,
            lastRequestTime: lastRequestTime,
            isProcessing: isProcessing,
            remainingRequestsToday: max(0, maxRequestsPerDay - totalRequestsToday)
        )
    }
    
    /// Reset request counters (for testing or admin purposes)
    func resetCounters() {
        totalRequestsToday = 0
        requestCount = 0
        lastResetDate = Date()
        logger.info("🤖 STATS: Request counters reset")
    }
    
    // MARK: - Streaming Support (Future)
    
    /// Stream LLM response (placeholder for future streaming implementation)
    func streamLLM(prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await callLLM(prompt: prompt)
                    // For now, just yield the complete response
                    // Future implementation would yield chunks as they arrive
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Batch Processing
    
    /// Process multiple prompts in batch with rate limiting
    func batchProcess(prompts: [String], provider: LLMConfigurationService.LLMProvider? = nil) async throws -> [String] {
        let selectedProvider = provider ?? configService.getBestAvailableProvider()
        guard let selectedProvider = selectedProvider else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        var responses: [String] = []
        
        for (index, prompt) in prompts.enumerated() {
            logger.info("🤖 BATCH: Processing prompt \(index + 1)/\(prompts.count)")
            
            do {
                let response = try await callLLM(prompt: prompt, provider: selectedProvider)
                responses.append(response)
                
                // Add delay between requests to respect rate limits
                if index < prompts.count - 1 {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                }
            } catch {
                logger.error("🤖 BATCH: Failed to process prompt \(index + 1): \(error)")
                throw error
            }
        }
        
        return responses
    }
}

// MARK: - Supporting Types

struct RequestStatistics {
    let totalRequestsToday: Int
    let totalRequestsSession: Int
    let lastRequestTime: Date?
    let isProcessing: Bool
    let remainingRequestsToday: Int
}

// MARK: - Communication Error Types

enum LLMCommunicationError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(Int, String)
    case rateLimitExceeded
    case networkError(Error)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "LLM API key not configured. Please set up your OpenAI or Claude API key."
        case .invalidResponse:
            return "Received invalid response from LLM provider."
        case .apiError(let code, let message):
            return "LLM API error (\(code)): \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let message):
            return "Failed to parse LLM response: \(message)"
        }
    }
}