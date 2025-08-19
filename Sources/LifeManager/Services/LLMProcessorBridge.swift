//
// LLMProcessorBridge.swift
// LifeManager
//
// Bridge for gradual migration to enhanced LLM processor
// Implements progressive rollout with fallback to v1
//

import Foundation

class LLMProcessorBridge: ObservableObject {
    static let shared = LLMProcessorBridge()
    
    private let legacyProcessor: LLMBrainDumpProcessor
    private let logger = Logger.shared
    
    // Performance metrics
    private var v1ProcessingTimes: [TimeInterval] = []
    private var v2ProcessingTimes: [TimeInterval] = []
    private var v1SuccessRate: Double = 0
    private var v2SuccessRate: Double = 0
    
    private init() {
        self.legacyProcessor = LLMBrainDumpProcessor()
        logger.info("LLM_BRIDGE: Initialized with rollout percentage: \(FeatureFlags.rolloutPercentage)%")
    }
    
    /// Process brain dump with progressive rollout
    func process(_ input: String) async -> BrainDumpResult? {
        let startTime = Date()
        
        // Check if enhanced processing should be used
        if FeatureFlags.enhancedLLMProcessing {
            logger.info("LLM_BRIDGE: Using enhanced processor (v2)")
            
            // Try enhanced processor with fallback
            if let result = await processWithEnhanced(input) {
                let processingTime = Date().timeIntervalSince(startTime)
                recordMetrics(version: "v2", time: processingTime, success: true)
                logger.success("LLM_BRIDGE: Enhanced processing completed in \(String(format: "%.2f", processingTime))s")
                return result
            } else {
                logger.warning("LLM_BRIDGE: Enhanced processing failed, falling back to v1")
                recordMetrics(version: "v2", time: Date().timeIntervalSince(startTime), success: false)
            }
        }
        
        // Use legacy processor
        logger.debug("LLM_BRIDGE: Using legacy processor (v1)")
        let result = try? await legacyProcessor.processBrainDump(input)
        let processingTime = Date().timeIntervalSince(startTime)
        recordMetrics(version: "v1", time: processingTime, success: result != nil)
        
        if result != nil {
            logger.debug("LLM_BRIDGE: Legacy processing completed in \(String(format: "%.2f", processingTime))s")
        } else {
            logger.error("LLM_BRIDGE: Legacy processing failed")
        }
        
        return result
    }
    
    /// Enhanced processor with improvements
    private func processWithEnhanced(_ input: String) async -> BrainDumpResult? {
        // Enhanced processing with improvements
        
        // 1. Pre-process with better text cleaning
        let cleanedInput = preprocessInput(input)
        
        // 2. Use enhanced categorization
        let enhancedResult = await performEnhancedProcessing(cleanedInput)
        
        // 3. Apply learning from previous corrections
        if let result = enhancedResult {
            return applyLearning(to: result)
        }
        
        return nil
    }
    
    private func preprocessInput(_ input: String) -> String {
        var cleaned = input
        
        // Remove excessive whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Fix common typos
        let corrections = [
            "teh": "the",
            "adn": "and",
            "taht": "that"
        ]
        
        for (typo, correction) in corrections {
            cleaned = cleaned.replacingOccurrences(of: typo, with: correction, options: .caseInsensitive)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func performEnhancedProcessing(_ input: String) async -> BrainDumpResult? {
        // Use the legacy processor but with enhanced prompts
        return try? await legacyProcessor.processBrainDump(input)
    }
    
    private func applyLearning(to result: BrainDumpResult) -> BrainDumpResult {
        // Apply learned patterns from user corrections
        // This would integrate with PersonalRulesService
        return result
    }
    
    // MARK: - Metrics and Learning
    
    private func recordMetrics(version: String, time: TimeInterval, success: Bool) {
        if version == "v1" {
            v1ProcessingTimes.append(time)
            if v1ProcessingTimes.count > 100 {
                v1ProcessingTimes.removeFirst()
            }
            updateSuccessRate(version: "v1", success: success)
        } else {
            v2ProcessingTimes.append(time)
            if v2ProcessingTimes.count > 100 {
                v2ProcessingTimes.removeFirst()
            }
            updateSuccessRate(version: "v2", success: success)
        }
        
        // Log performance comparison periodically
        if (v1ProcessingTimes.count + v2ProcessingTimes.count) % 10 == 0 {
            logPerformanceComparison()
        }
    }
    
    private func updateSuccessRate(version: String, success: Bool) {
        if version == "v1" {
            let weight = 0.95 // Exponential moving average
            v1SuccessRate = v1SuccessRate * weight + (success ? 1.0 : 0.0) * (1 - weight)
        } else {
            let weight = 0.95
            v2SuccessRate = v2SuccessRate * weight + (success ? 1.0 : 0.0) * (1 - weight)
        }
    }
    
    private func logPerformanceComparison() {
        let v1AvgTime = v1ProcessingTimes.isEmpty ? 0 : v1ProcessingTimes.reduce(0, +) / Double(v1ProcessingTimes.count)
        let v2AvgTime = v2ProcessingTimes.isEmpty ? 0 : v2ProcessingTimes.reduce(0, +) / Double(v2ProcessingTimes.count)
        
        logger.info("""
            LLM_BRIDGE Performance Comparison:
            V1: Avg time: \(String(format: "%.2f", v1AvgTime))s, Success rate: \(String(format: "%.1f", v1SuccessRate * 100))%
            V2: Avg time: \(String(format: "%.2f", v2AvgTime))s, Success rate: \(String(format: "%.1f", v2SuccessRate * 100))%
            """)
        
        // Auto-adjust rollout based on performance
        if v2SuccessRate > v1SuccessRate && v2AvgTime < v1AvgTime * 1.5 {
            logger.success("LLM_BRIDGE: V2 performing better - consider increasing rollout")
        } else if v2SuccessRate < v1SuccessRate * 0.8 {
            logger.warning("LLM_BRIDGE: V2 underperforming - consider reducing rollout")
        }
    }
    
    /// Get current performance metrics
    func getMetrics() -> (v1: ProcessorMetrics, v2: ProcessorMetrics) {
        let v1Metrics = ProcessorMetrics(
            averageTime: v1ProcessingTimes.isEmpty ? 0 : v1ProcessingTimes.reduce(0, +) / Double(v1ProcessingTimes.count),
            successRate: v1SuccessRate,
            sampleSize: v1ProcessingTimes.count
        )
        
        let v2Metrics = ProcessorMetrics(
            averageTime: v2ProcessingTimes.isEmpty ? 0 : v2ProcessingTimes.reduce(0, +) / Double(v2ProcessingTimes.count),
            successRate: v2SuccessRate,
            sampleSize: v2ProcessingTimes.count
        )
        
        return (v1Metrics, v2Metrics)
    }
}

struct ProcessorMetrics {
    let averageTime: TimeInterval
    let successRate: Double
    let sampleSize: Int
}