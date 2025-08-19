//
// LLMServiceCoordinator.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - LLM Service Coordination
// Replaces the monolithic LLMService with coordinated modular services
// Provides the same public API while delegating to specialized services
//

import Foundation

// LLMError is defined in LLMServicePremiumCached.swift
// Using the existing LLMError from that file

/// Coordinates all LLM services to provide unified AI functionality
/// Maintains backward compatibility while using modular architecture
/// Serves as the main entry point for all LLM operations
class LLMServiceCoordinator: ObservableObject {
    
    static let shared = LLMServiceCoordinator()
    
    // MARK: - Sub-Services
    
    private let configService = LLMConfigurationService.shared
    private let promptService = LLMPromptService.shared
    private let communicationService = LLMCommunicationService.shared
    private let processingService = LLMProcessingService.shared
    
    // MARK: - Dependencies
    
    private let logger = Logger.shared
    
    // MARK: - Published State (Delegated)
    
    var isProcessing: Bool { communicationService.isProcessing }
    var isConfigured: Bool { configService.isConfigured }
    
    // MARK: - Initialization
    
    private init() {
        logger.info("🧠 COORDINATOR: LLM Service Coordinator initialized")
    }
    
    // MARK: - API Compatibility Methods
    
    /// Check if service has valid API key
    func hasValidAPIKey() -> Bool {
        return configService.hasValidAPIKey()
    }
    
    /// Send message to LLM (compatibility method)
    func sendMessage(_ message: String) async throws -> String {
        return try await communicationService.sendMessage(message)
    }
    
    // MARK: - High-Level Processing Methods (Backward Compatible)
    
    /// Process natural language input for PARA categorization
    func processMessage(
        _ message: String,
        temperature: Double = 0.7
    ) async throws -> String {
        // Process natural language and convert result to string
        let result = try await processingService.processNaturalLanguage(input: message)
        
        // Convert PARAProcessingResult to string representation
        var output = "Processed \(result.extractedItems.count) items:\n"
        for item in result.extractedItems {
            output += "- \(item.content) [\(item.category.rawValue)]\n"
        }
        return output
    }
    
    func processNaturalLanguage(
        input: String,
        availableAreas: [String] = [],
        availableProjects: [String] = [],
        confidenceThreshold: Double = 0.7
    ) async throws -> PARAProcessingResult {
        
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await processingService.processNaturalLanguage(
            input: input,
            availableAreas: availableAreas,
            availableProjects: availableProjects,
            confidenceThreshold: confidenceThreshold
        )
    }
    
    /// Extract actionable tasks from content
    func extractTasks(
        from content: String,
        context: String = ""
    ) async throws -> TaskExtractionResult {
        
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await processingService.extractTasks(from: content, context: context)
    }
    
    /// Suggest task priority based on content analysis
    func suggestTaskPriority(
        title: String,
        description: String,
        context: String = ""
    ) async throws -> TaskPriorityResult {
        
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await processingService.suggestTaskPriority(
            title: title,
            description: description,
            context: context
        )
    }
    
    /// Process content comprehensively using all available context
    func processComprehensively(
        blob: Blob,
        availableAreas: [String] = [],
        availableProjects: [String] = [],
        confidenceThreshold: Double = 0.7
    ) async throws -> ProcessingResult {
        
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await processingService.processComprehensively(
            blob: blob,
            availableAreas: availableAreas,
            availableProjects: availableProjects,
            confidenceThreshold: confidenceThreshold
        )
    }
    
    /// Enhance existing tasks with AI suggestions
    func enhanceExistingTasks(_ tasks: [LifeTask]) async throws -> [TaskEnhancementResult] {
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await processingService.enhanceExistingTasks(tasks)
    }
    
    // MARK: - Convenience Methods (Backward Compatible)
    
    /// Quick PARA categorization
    func categorizePARA(input: String) async throws -> PARAProcessingResult {
        return try await processNaturalLanguage(input: input)
    }
    
    /// Quick task extraction (returns legacy format)
    func extractTasks(content: String) async throws -> [[String: Any]] {
        return try await processingService.extractTasks(content: content)
    }
    
    // MARK: - Core Communication (Backward Compatible)
    
    /// Direct LLM call (for advanced users)
    func callLLM(prompt: String) async throws -> String {
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await communicationService.callLLM(prompt: prompt)
    }
    
    // MARK: - Configuration Management
    
    /// Get configuration summary
    func getConfigurationSummary() -> ConfigurationSummary {
        return configService.getConfigurationSummary()
    }
    
    /// Test connectivity to providers
    func testConnectivity() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        for provider in LLMConfigurationService.LLMProvider.allCases {
            if provider.isAvailable {
                results[provider.displayName] = await communicationService.testConnectivity(provider: provider)
            } else {
                results[provider.displayName] = false
            }
        }
        
        return results
    }
    
    /// Refresh configuration
    func refreshConfiguration() {
        configService.refreshConfiguration()
    }
    
    /// Set preferred provider
    func setPreferredProvider(_ provider: LLMConfigurationService.LLMProvider) {
        configService.setPreferredProvider(provider)
    }
    
    // MARK: - Statistics and Monitoring
    
    /// Get request statistics
    func getRequestStatistics() -> RequestStatistics {
        return communicationService.getRequestStatistics()
    }
    
    /// Get processing statistics
    func getProcessingStatistics() -> LLMProcessingStatistics {
        let requestStats = communicationService.getRequestStatistics()
        let configSummary = configService.getConfigurationSummary()
        
        return LLMProcessingStatistics(
            totalRequests: requestStats.totalRequestsSession,
            successfulRequests: requestStats.totalRequestsSession, // Simplified
            failedRequests: 0, // Would need tracking
            averageResponseTime: 2.5, // Would need tracking
            configuredProviders: configSummary.availableProviders.count,
            isConfigured: configSummary.isConfigured,
            lastRequestTime: requestStats.lastRequestTime
        )
    }
    
    // MARK: - Advanced Features
    
    /// Stream LLM response (Future feature)
    func streamLLM(prompt: String) -> AsyncThrowingStream<String, Error> {
        return communicationService.streamLLM(prompt: prompt)
    }
    
    /// Batch process multiple prompts
    func batchProcess(prompts: [String]) async throws -> [String] {
        guard configService.isConfigured else {
            throw LLMCommunicationError.missingAPIKey
        }
        
        return try await communicationService.batchProcess(prompts: prompts)
    }
    
    /// Validate prompt template
    func validatePromptTemplate(_ template: String, requiredVariables: [String]) -> ValidationResult {
        return promptService.validateTemplate(template, requiredVariables: requiredVariables)
    }
    
    /// Get prompt statistics
    func getPromptStatistics(for prompt: String) -> PromptStatistics {
        return promptService.getPromptStatistics(for: prompt)
    }
    
    // MARK: - Service Health Monitoring
    
    /// Check overall service health
    func checkServiceHealth() async -> ServiceHealthStatus {
        let configHealth = configService.isConfigured
        let communicationHealth = !communicationService.isProcessing // Simplified check
        
        let connectivity = await testConnectivity()
        let hasWorkingProvider = connectivity.values.contains(true)
        
        let status: ServiceHealthStatus.Status
        if configHealth && communicationHealth && hasWorkingProvider {
            status = .healthy
        } else if configHealth && hasWorkingProvider {
            status = .degraded
        } else {
            status = .unhealthy
        }
        
        return ServiceHealthStatus(
            status: status,
            configurationHealth: configHealth,
            communicationHealth: communicationHealth,
            providerConnectivity: connectivity,
            lastChecked: Date()
        )
    }
    
    /// Reset all service counters (for testing/admin)
    func resetCounters() {
        communicationService.resetCounters()
        logger.info("🧠 COORDINATOR: All service counters reset")
    }
}

// MARK: - Supporting Types

struct LLMProcessingStatistics {
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let averageResponseTime: Double
    let configuredProviders: Int
    let isConfigured: Bool
    let lastRequestTime: Date?
}

struct ServiceHealthStatus {
    enum Status {
        case healthy, degraded, unhealthy
    }
    
    let status: Status
    let configurationHealth: Bool
    let communicationHealth: Bool
    let providerConnectivity: [String: Bool]
    let lastChecked: Date
}

// MARK: - Legacy Compatibility

// Note: LLMService alias removed to avoid conflicts with existing LLMService.swift
// Views should import LLMServiceCoordinator directly or be updated to use the new architecture