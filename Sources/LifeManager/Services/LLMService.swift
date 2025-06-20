//
// LLMService.swift
// LifeManager
//
// LEGACY COMPATIBILITY: This file provides backward compatibility
// The original LLMService has been decomposed into modular services:
// - LLMConfigurationService: API key and provider management
// - LLMPromptService: Prompt templates and generation
// - LLMCommunicationService: Direct API communication
// - LLMProcessingService: Response parsing and categorization
// - LLMServiceCoordinator: Unified coordination layer
//
// New code should use LLMServiceCoordinator.shared instead
//

import Foundation

/// Legacy compatibility alias for LLMServiceCoordinator
/// @deprecated Use LLMServiceCoordinator.shared instead
typealias LLMService = LLMServiceCoordinator