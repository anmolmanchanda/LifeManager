//
// FeatureFlags.swift
// LifeManager
//
// Feature flag system for controlled rollout of enhanced features
// Allows runtime control via environment variables or build configurations
//

import Foundation

/// Central feature flag management for v2.0 features
struct FeatureFlags {
    
    // MARK: - Core Features
    
    /// Enhanced PARA processing with dynamic context windows
    static var enhancedPARAProcessing: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_ENHANCED_PARA"] == "1"
        #else
        return false // Disabled in production until fully tested
        #endif
    }
    
    /// Intelligent task rescheduling with AI decision making
    static var intelligentRescheduling: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_RESCHEDULING"] == "1"
        #else
        return false
        #endif
    }
    
    /// Advanced analytics and visualization
    static var advancedAnalytics: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_ANALYTICS"] == "1"
        #else
        return false
        #endif
    }
    
    /// Enhanced embeddings with domain-specific weighting
    static var enhancedEmbeddings: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_ENHANCED_EMBEDDINGS"] == "1"
        #else
        return false
        #endif
    }
    
    /// Proactive notification engine
    static var proactiveNotifications: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_PROACTIVE_NOTIFS"] == "1"
        #else
        return false
        #endif
    }
    
    /// Enhanced LLM Brain Dump Processor v2
    static var enhancedLLMProcessing: Bool {
        #if DEBUG
        let enabled = ProcessInfo.processInfo.environment["ENABLE_LLM_PROCESSOR_V2"] == "1"
        if enabled && shouldEnableFeature() {
            return true
        }
        return false
        #else
        return false
        #endif
    }
    
    // MARK: - Progressive Rollout
    
    /// Rollout percentage for gradual feature deployment
    static var rolloutPercentage: Int {
        guard let percentStr = ProcessInfo.processInfo.environment["ROLLOUT_PERCENTAGE"],
              let percent = Int(percentStr) else {
            return 100 // Default to full rollout if specified
        }
        return min(100, max(0, percent))
    }
    
    /// Determine if feature should be enabled based on rollout percentage
    static func shouldEnableFeature() -> Bool {
        let random = Int.random(in: 0..<100)
        return random < rolloutPercentage
    }
    
    // MARK: - Calendar Integration Features
    
    /// Calendar orchestration with advanced scheduling
    static var calendarOrchestration: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_CALENDAR_ORCHESTRATION"] == "1"
        #else
        return true // Calendar features are stable in production
        #endif
    }
    
    /// Buffer management for preventing overbooking
    static var bufferManagement: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_BUFFER_MANAGEMENT"] == "1"
        #else
        return true // Buffer management is stable in production
        #endif
    }
    
    /// Conflict detection for calendar events
    static var conflictDetection: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["ENABLE_CONFLICT_DETECTION"] == "1"
        #else
        return true // Conflict detection is stable in production
        #endif
    }
    
    // MARK: - Experimental Features
    
    /// MCP integration with 9 servers
    static var mcpIntegration: Bool {
        return ProcessInfo.processInfo.environment["ENABLE_MCP"] == "1"
    }
    
    /// Timeline view service
    static var timelineView: Bool {
        return ProcessInfo.processInfo.environment["ENABLE_TIMELINE"] == "1"
    }
    
    // MARK: - Helper Methods
    
    /// Check if any v2.0 features are enabled
    static var anyV2FeaturesEnabled: Bool {
        return enhancedPARAProcessing ||
               intelligentRescheduling ||
               advancedAnalytics ||
               enhancedEmbeddings ||
               proactiveNotifications
    }
    
    /// Get list of enabled features for logging
    static var enabledFeatures: [String] {
        var features: [String] = []
        
        if enhancedPARAProcessing { features.append("Enhanced PARA") }
        if intelligentRescheduling { features.append("Intelligent Rescheduling") }
        if advancedAnalytics { features.append("Advanced Analytics") }
        if enhancedEmbeddings { features.append("Enhanced Embeddings") }
        if proactiveNotifications { features.append("Proactive Notifications") }
        if enhancedLLMProcessing { features.append("Enhanced LLM Processor (v2)") }
        if calendarOrchestration { features.append("Calendar Orchestration") }
        if bufferManagement { features.append("Buffer Management") }
        if conflictDetection { features.append("Conflict Detection") }
        if mcpIntegration { features.append("MCP Integration") }
        if timelineView { features.append("Timeline View") }
        
        if rolloutPercentage < 100 {
            features.append("Rollout: \(rolloutPercentage)%")
        }
        
        return features
    }
    
    /// Log current feature flag state
    static func logFeatureStatus() {
        if enabledFeatures.isEmpty {
            Logger.shared.info("FEATURES: All v2.0 features disabled (stable mode)")
        } else {
            Logger.shared.info("FEATURES: Enabled - \(enabledFeatures.joined(separator: ", "))")
        }
    }
    
    // MARK: - Configuration
    
    /// Enable features for testing (DEBUG only)
    #if DEBUG
    static func enableForTesting(_ features: Set<Feature>) {
        // This would typically update UserDefaults or a configuration file
        // For now, features are controlled via environment variables
        Logger.shared.debug("FEATURES: Test configuration requested for: \(features)")
    }
    #endif
    
    enum Feature: String {
        case enhancedPARA = "ENABLE_ENHANCED_PARA"
        case intelligentRescheduling = "ENABLE_RESCHEDULING"
        case advancedAnalytics = "ENABLE_ANALYTICS"
        case enhancedEmbeddings = "ENABLE_ENHANCED_EMBEDDINGS"
        case proactiveNotifications = "ENABLE_PROACTIVE_NOTIFS"
        case mcpIntegration = "ENABLE_MCP"
        case timelineView = "ENABLE_TIMELINE"
    }
}

// MARK: - Usage Examples

/*
 // In service code:
 if FeatureFlags.enhancedPARAProcessing {
     // Use new enhanced processing logic
     return processWithEnhancedContext()
 } else {
     // Fall back to stable v1.9 logic
     return processWithBasicContext()
 }
 
 // Enable features for testing:
 export ENABLE_ENHANCED_PARA=1
 export ENABLE_ANALYTICS=1
 ./run.sh
 
 // Check feature status:
 FeatureFlags.logFeatureStatus()
 */