//
// LLMConfigurationService.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - LLM Configuration Management
// Extracted from LLMService as part of Phase 2B decomposition
// Manages API keys, provider settings, and LLM configuration
//

import Foundation

/// Manages LLM provider configuration and API key loading
/// Handles secure API key management and provider selection logic
/// Extracted from LLMService for better separation of concerns
class LLMConfigurationService: ObservableObject {
    
    static let shared = LLMConfigurationService()
    
    // MARK: - Configuration
    
    private struct APIConfig {
        static var openAIKey: String {
            // Try multiple sources for API key
            if let configKey = loadFromConfigFile() {
                return configKey
            }
            
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
                return envKey
            }
            
            // Fallback placeholder - set OPENAI_API_KEY environment variable
            return "your-openai-api-key-here"
        }
        
        static let claudeKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let claudeBaseURL = "https://api.anthropic.com/v1"
        
        private static func loadFromConfigFile() -> String? {
            let logger = Logger.shared
            
            // Try to load from config file in various locations
            let configPaths = [
                // Current working directory
                "config.txt",
                "api_key.txt",
                // App bundle directory
                Bundle.main.bundlePath + "/config.txt",
                Bundle.main.bundlePath + "/api_key.txt",
                // User home directory
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".lifemanager_config").path,
                // Documents directory
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("config.txt").path ?? "",
                // Application Support directory
                FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("LifeManager/config.txt").path ?? ""
            ]
            
            logger.info("LLM CONFIG: Searching for config file in paths")
            for path in configPaths {
                logger.debug("LLM CONFIG: Checking: \(path)")
                if let content = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
                   !content.isEmpty {
                    logger.success("LLM CONFIG: Found config file at: \(path)")
                    logger.debug("LLM CONFIG: Raw content length: \(content.count)")
                    
                    // Extract API key from config file format
                    if content.contains("OPENAI_API_KEY=") {
                        let lines = content.components(separatedBy: .newlines)
                        for line in lines {
                            if line.hasPrefix("OPENAI_API_KEY=") {
                                let apiKey = String(line.dropFirst("OPENAI_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                                if !apiKey.isEmpty && !apiKey.contains("YOUR_API_KEY_HERE") {
                                    logger.success("LLM CONFIG: Extracted API key, length: \(apiKey.count)")
                                    return apiKey
                                }
                            }
                        }
                        logger.warning("LLM CONFIG: Found OPENAI_API_KEY= but no valid key")
                    } else {
                        // Assume entire file content is the API key (for simple format)
                        if !content.contains("YOUR_API_KEY_HERE") && content.hasPrefix("sk-") {
                            logger.success("LLM CONFIG: Using entire file as API key")
                            return content
                        }
                    }
                }
            }
            
            logger.warning("LLM CONFIG: No valid API key found in any config file")
            logger.info("LLM CONFIG: To fix this:")
            logger.info("LLM CONFIG: 1. Copy config.txt.template to config.txt")
            logger.info("LLM CONFIG: 2. Edit config.txt and add your OpenAI API key")
            logger.info("LLM CONFIG: 3. The config.txt file is automatically ignored by git")
            return nil
        }
    }
    
    /// Available LLM providers
    enum LLMProvider: String, CaseIterable {
        case openAI = "openai"
        case claude = "claude"
        
        var displayName: String {
            switch self {
            case .openAI: return "OpenAI"
            case .claude: return "Claude"
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .openAI: return !LLMConfigurationService.shared.getOpenAIKey().isEmpty && LLMConfigurationService.shared.getOpenAIKey() != "your-openai-api-key-here"
            case .claude: return !LLMConfigurationService.shared.getClaudeKey().isEmpty
            }
        }
    }
    
    // MARK: - Published State
    
    @Published var preferredProvider: LLMProvider = .openAI
    @Published var isConfigured: Bool = false
    
    // MARK: - Dependencies
    
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    private init() {
        checkConfiguration()
    }
    
    // MARK: - API Key Management
    
    /// Get OpenAI API key
    func getOpenAIKey() -> String {
        return APIConfig.openAIKey
    }
    
    /// Get Claude API key
    func getClaudeKey() -> String {
        return APIConfig.claudeKey
    }
    
    /// Get base URL for OpenAI API
    func getOpenAIBaseURL() -> String {
        return APIConfig.openAIBaseURL
    }
    
    /// Get base URL for Claude API
    func getClaudeBaseURL() -> String {
        return APIConfig.claudeBaseURL
    }
    
    /// Check if API keys are properly configured
    func checkConfiguration() {
        let openAIConfigured = LLMProvider.openAI.isAvailable
        let claudeConfigured = LLMProvider.claude.isAvailable
        
        isConfigured = openAIConfigured || claudeConfigured
        
        if !isConfigured {
            logger.warning("🔧 CONFIG: No LLM providers configured")
            logger.info("🔧 CONFIG: Available providers - OpenAI: \(openAIConfigured), Claude: \(claudeConfigured)")
        } else {
            logger.success("🔧 CONFIG: LLM providers configured successfully")
        }
    }
    
    /// Get the best available provider
    func getBestAvailableProvider() -> LLMProvider? {
        // Prefer the user's preferred provider if available
        if preferredProvider.isAvailable {
            return preferredProvider
        }
        
        // Fall back to any available provider
        return LLMProvider.allCases.first { $0.isAvailable }
    }
    
    /// Set preferred provider
    func setPreferredProvider(_ provider: LLMProvider) {
        guard provider.isAvailable else {
            logger.warning("🔧 CONFIG: Cannot set preferred provider to \(provider.displayName) - not configured")
            return
        }
        
        preferredProvider = provider
        logger.info("🔧 CONFIG: Preferred provider set to \(provider.displayName)")
    }
    
    /// Validate API key format
    func validateAPIKey(_ key: String, for provider: LLMProvider) -> Bool {
        switch provider {
        case .openAI:
            return key.hasPrefix("sk-") && key.count > 20
        case .claude:
            return key.hasPrefix("sk-") && key.count > 20 // Claude uses similar format
        }
    }
    
    /// Get provider configuration summary
    func getConfigurationSummary() -> ConfigurationSummary {
        let openAIStatus = LLMProvider.openAI.isAvailable ? "Configured" : "Not configured"
        let claudeStatus = LLMProvider.claude.isAvailable ? "Configured" : "Not configured"
        
        return ConfigurationSummary(
            openAIStatus: openAIStatus,
            claudeStatus: claudeStatus,
            preferredProvider: preferredProvider.displayName,
            isConfigured: isConfigured,
            availableProviders: LLMProvider.allCases.filter { $0.isAvailable }.map { $0.displayName }
        )
    }
    
    /// Refresh configuration (useful after config file changes)
    func refreshConfiguration() {
        logger.info("🔧 CONFIG: Refreshing LLM configuration")
        checkConfiguration()
    }
    
    /// Get model configuration for provider
    func getModelConfiguration(for provider: LLMProvider) -> ModelConfiguration {
        switch provider {
        case .openAI:
            return ModelConfiguration(
                provider: provider,
                model: "gpt-4",
                maxTokens: 4096,
                temperature: 0.7,
                baseURL: getOpenAIBaseURL()
            )
        case .claude:
            return ModelConfiguration(
                provider: provider,
                model: "claude-3-sonnet-20240229",
                maxTokens: 4096,
                temperature: 0.7,
                baseURL: getClaudeBaseURL()
            )
        }
    }
    
    /// Test provider connectivity
    func testProvider(_ provider: LLMProvider) async -> Bool {
        guard provider.isAvailable else {
            logger.warning("🔧 CONFIG: Cannot test \(provider.displayName) - not configured")
            return false
        }
        
        logger.info("🔧 CONFIG: Testing \(provider.displayName) connectivity...")
        
        // This would be implemented with actual API test calls
        // For now, just validate configuration
        switch provider {
        case .openAI:
            let key = getOpenAIKey()
            let isValid = validateAPIKey(key, for: provider)
            logger.info("🔧 CONFIG: OpenAI key validation: \(isValid)")
            return isValid
        case .claude:
            let key = getClaudeKey()
            let isValid = validateAPIKey(key, for: provider)
            logger.info("🔧 CONFIG: Claude key validation: \(isValid)")
            return isValid
        }
    }
}

// MARK: - Supporting Types

struct ConfigurationSummary {
    let openAIStatus: String
    let claudeStatus: String
    let preferredProvider: String
    let isConfigured: Bool
    let availableProviders: [String]
}

struct ModelConfiguration {
    let provider: LLMConfigurationService.LLMProvider
    let model: String
    let maxTokens: Int
    let temperature: Double
    let baseURL: String
}