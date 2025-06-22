import Foundation
import SwiftUI

/// Priority Intelligence Engine
/// Phase 2: Smart Auto-Rescheduling Implementation
/// Provides ML-powered task priority assessment beyond keyword matching
@MainActor
class PriorityIntelligenceEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let contextMemory = ContextMemoryService.shared
    private let personalRules = PersonalRulesService.shared
    private let llmService = LLMServiceCoordinator.shared
    private let logger = Logger.shared
    
    // MARK: - Configuration
    
    private let cacheExpirationHours = 24
    private let batchProcessingSize = 10
    private let minimumConfidenceThreshold = 0.6
    
    // MARK: - Published State
    
    @Published var isProcessing = false
    @Published var processingProgress = 0.0
    @Published var cachedIntelligenceCount = 0
    @Published var averageConfidence = 0.0
    
    // MARK: - Private Properties
    
    private var intelligenceCache: [UUID: PriorityIntelligence] = [:]
    private let cacheQueue = DispatchQueue(label: "priority.intelligence.cache", qos: .utility)
    private var lastCacheCleanup = Date()
    
    // MARK: - Initialization
    
    init() {
        logger.info("PRIORITY_INTELLIGENCE: Engine initialized")
        
        // Start periodic cache cleanup
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.cleanupExpiredIntelligence()
            }
        }
    }
    
    // MARK: - Priority Intelligence Calculation
    
    /// Calculate comprehensive priority intelligence for a task
    func calculatePriorityIntelligence(for task: LifeTask, forceRecalculation: Bool = false) async -> PriorityIntelligence {
        
        // Check cache first unless force recalculation is requested
        if !forceRecalculation, let cached = await getCachedIntelligence(for: task.id) {
            logger.debug("PRIORITY_INTELLIGENCE: Using cached intelligence for task: \(task.title)")
            return cached
        }
        
        logger.debug("PRIORITY_INTELLIGENCE: Calculating new priority intelligence for: \(task.title)")
        
        await MainActor.run {
            isProcessing = true
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        do {
            // Get contextual information
            let context = await contextMemory.getCurrentContext()
            let userRules = await personalRules.getApplicableRules(for: task)
            let projectContext = await getProjectContext(for: task)
            
            // Calculate component scores
            let urgencyScore = calculateUrgencyScore(for: task, context: context)
            let importanceScore = await calculateImportanceScore(for: task, projectContext: projectContext)
            let contextScore = calculateContextScore(for: task, context: context)
            let userPatternScore = calculateUserPatternScore(for: task, rules: userRules)
            let intelligenceScore = await calculateLLMIntelligenceScore(for: task, context: context)
            
            // Generate reasoning
            let reasoningFactors = generateComprehensiveReasoning(
                task: task,
                urgency: urgencyScore,
                importance: importanceScore,
                context: contextScore,
                userPattern: userPatternScore,
                intelligence: intelligenceScore
            )
            
            // Calculate overall confidence
            let confidence = calculateOverallConfidence(
                urgency: urgencyScore,
                importance: importanceScore,
                context: contextScore,
                userPattern: userPatternScore,
                intelligence: intelligenceScore
            )
            
            // Create priority intelligence object
            let priorityIntelligence = PriorityIntelligence(
                taskId: task.id,
                intelligenceScore: intelligenceScore,
                urgencyScore: urgencyScore,
                importanceScore: importanceScore,
                contextScore: contextScore,
                userPatternScore: userPatternScore,
                reasoningFactors: reasoningFactors,
                confidence: confidence
            )
            
            // Cache the result
            await cacheIntelligence(priorityIntelligence)
            
            logger.success("PRIORITY_INTELLIGENCE: Calculated priority intelligence - Overall: \(String(format: "%.2f", priorityIntelligence.overallScore))")
            
            return priorityIntelligence
            
        } catch {
            logger.error("PRIORITY_INTELLIGENCE: Failed to calculate priority intelligence: \(error)")
            
            // Return fallback intelligence
            return createFallbackIntelligence(for: task)
        }
    }
    
    /// Batch calculate priority intelligence for multiple tasks
    func batchCalculatePriorityIntelligence(for tasks: [LifeTask]) async -> [UUID: PriorityIntelligence] {
        logger.info("PRIORITY_INTELLIGENCE: Starting batch calculation for \(tasks.count) tasks")
        
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
                processingProgress = 0.0
            }
        }
        
        var results: [UUID: PriorityIntelligence] = [:]
        let totalTasks = tasks.count
        
        // Process in batches to avoid overwhelming the system
        for (index, task) in tasks.enumerated() {
            let intelligence = await calculatePriorityIntelligence(for: task)
            results[task.id] = intelligence
            
            // Update progress
            await MainActor.run {
                processingProgress = Double(index + 1) / Double(totalTasks)
            }
            
            // Small delay to prevent overwhelming the LLM service
            if index % batchProcessingSize == 0 && index > 0 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            }
        }
        
        logger.success("PRIORITY_INTELLIGENCE: Completed batch calculation for \(totalTasks) tasks")
        
        return results
    }
    
    // MARK: - Component Score Calculations
    
    /// Calculate urgency score based on deadlines and overdue status
    private func calculateUrgencyScore(for task: LifeTask, context: ProcessingContext) -> Double {
        var score = 0.3 // Base urgency score
        
        // Overdue factor - exponential increase with time overdue
        if task.isOverdue {
            let overdueHours = task.overdueByHours
            let overdueBoost = min(0.5, log(overdueHours + 1) / 10.0) // Logarithmic scaling
            score += overdueBoost
            logger.debug("PRIORITY_INTELLIGENCE: Overdue boost: \(String(format: "%.2f", overdueBoost)) for \(String(format: "%.1f", overdueHours)) hours overdue")
        }
        
        // Due date proximity
        if let dueDateString = task.dueDate,
           let dueDate = ISO8601DateFormatter().date(from: dueDateString) {
            let hoursUntilDue = dueDate.timeIntervalSinceNow / 3600
            
            if hoursUntilDue > 0 && hoursUntilDue <= 24 {
                score += 0.3 // Due within 24 hours
            } else if hoursUntilDue > 24 && hoursUntilDue <= 72 {
                score += 0.2 // Due within 3 days
            } else if hoursUntilDue > 72 && hoursUntilDue <= 168 {
                score += 0.1 // Due within a week
            }
        }
        
        // Task priority factor
        switch task.priority {
        case .urgent:
            score += 0.3
        case .high:
            score += 0.2
        case .medium:
            score += 0.1
        case .low:
            break
        }
        
        // Stagnant task penalty (tasks sitting in inbox too long)
        if task.isStagnant {
            score += 0.2
        }
        
        return min(1.0, score)
    }
    
    /// Calculate importance score based on project context and impact
    private func calculateImportanceScore(for task: LifeTask, projectContext: ProjectContext?) async -> Double {
        var score = 0.4 // Base importance score
        
        // Project context importance
        if let projectContext = projectContext {
            score += projectContext.importanceBoost
            
            // Project deadline proximity
            if projectContext.isNearDeadline {
                score += 0.2
            }
            
            // Project criticality
            if projectContext.isCritical {
                score += 0.3
            }
        }
        
        // Area context importance
        if task.areaId != nil {
            score += 0.1 // Tasks assigned to areas are more important than orphaned tasks
        }
        
        // Focus flag importance
        if task.isFocus {
            score += 0.25
        }
        
        // Work vs personal context
        let currentHour = Calendar.current.component(.hour, from: Date())
        if task.workPersonal == .work && (currentHour >= 9 && currentHour <= 17) {
            score += 0.1 // Work tasks during work hours
        } else if task.workPersonal == .personal && (currentHour < 9 || currentHour > 17) {
            score += 0.1 // Personal tasks outside work hours
        }
        
        // Content analysis for importance keywords
        let importanceKeywords = [
            "critical", "urgent", "important", "deadline", "client", "meeting",
            "presentation", "review", "decision", "approval", "launch", "release"
        ]
        
        let taskContent = "\(task.title) \(task.description ?? "")".lowercased()
        let keywordMatches = importanceKeywords.filter { taskContent.contains($0) }
        let keywordBoost = min(0.2, Double(keywordMatches.count) * 0.05)
        score += keywordBoost
        
        return min(1.0, score)
    }
    
    /// Calculate context score based on current situation
    private func calculateContextScore(for task: LifeTask, context: ProcessingContext) -> Double {
        var score = 0.5 // Neutral context score
        
        // Time of day alignment
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Morning boost for focus tasks
        if task.isFocus && (currentHour >= 9 && currentHour <= 11) {
            score += 0.3
        }
        
        // Work hours alignment
        if task.workPersonal == .work && (currentHour >= 9 && currentHour <= 17) {
            score += 0.2
        }
        
        // Calendar load consideration
        // If user has light calendar load, boost all task scores
        // This would integrate with calendar data when available
        
        // Recent activity patterns
        if context.recentActivityItems.count < 5 {
            score += 0.1 // User hasn't been very active, might be good time for tasks
        }
        
        // Weekend vs weekday context
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        if task.workPersonal == .personal && isWeekend {
            score += 0.15
        } else if task.workPersonal == .work && !isWeekend {
            score += 0.15
        }
        
        return min(1.0, score)
    }
    
    /// Calculate user pattern score based on learned behaviors
    private func calculateUserPatternScore(for task: LifeTask, rules: [PersonalPARARule]) -> Double {
        var score = 0.5 // Neutral pattern score
        
        // Apply learned user rules
        for rule in rules {
            switch rule.ruleType {
            case .contextual:
                score += 0.1
            case .keyword, .phrase:
                score += 0.05
            case .categoryOverride:
                score += 0.15
            }
        }
        
        // Historical correction patterns
        let correctionBoost = min(0.2, Double(rules.count) * 0.02)
        score += correctionBoost
        
        return min(1.0, score)
    }
    
    /// Use LLM for advanced semantic analysis
    private func calculateLLMIntelligenceScore(for task: LifeTask, context: ProcessingContext) async -> Double {
        
        do {
            let prompt = """
            Analyze this task for intelligent priority assessment. Consider semantic meaning, context, and potential impact.
            
            Task: "\(task.title)"
            Description: "\(task.description ?? "None")"
            Priority: \(task.priority.displayName)
            Type: \(task.workPersonal.displayName)
            Is Focus Task: \(task.isFocus ? "Yes" : "No")
            Is Overdue: \(task.isOverdue ? "Yes (\(String(format: "%.1f", task.overdueByHours)) hours)" : "No")
            
            Recent User Activity Context:
            \(context.recentActivityItems.prefix(3).map { "- \($0.title)" }.joined(separator: "\n"))
            
            Analyze the task for:
            1. Semantic importance beyond keywords
            2. Urgency indicators in the content
            3. Potential impact of delay
            4. Resource/energy requirements
            5. Dependencies or blocking factors
            
            Provide an intelligence score from 0.0 to 1.0, where:
            - 0.0-0.3: Low intelligence priority
            - 0.4-0.6: Medium intelligence priority  
            - 0.7-0.9: High intelligence priority
            - 0.9-1.0: Critical intelligence priority
            
            Return ONLY the numerical score (e.g., 0.75).
            """
            
            let response = try await llmService.processText(prompt)
            
            // Parse the numerical response
            let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
            if let score = Double(cleanedResponse) {
                let clampedScore = max(0.0, min(1.0, score))
                logger.debug("PRIORITY_INTELLIGENCE: LLM intelligence score: \(String(format: "%.2f", clampedScore))")
                return clampedScore
            }
            
            // Try to extract number from response
            let numbers = cleanedResponse.components(separatedBy: .whitespaces)
                .compactMap { Double($0) }
                .filter { $0 >= 0.0 && $0 <= 1.0 }
            
            if let firstValidNumber = numbers.first {
                logger.debug("PRIORITY_INTELLIGENCE: Extracted LLM score: \(String(format: "%.2f", firstValidNumber))")
                return firstValidNumber
            }
            
            // Fallback to medium score
            logger.warning("PRIORITY_INTELLIGENCE: Could not parse LLM response: '\(cleanedResponse)', using fallback")
            return 0.5
            
        } catch {
            logger.warning("PRIORITY_INTELLIGENCE: LLM intelligence scoring failed: \(error)")
            return 0.5 // Fallback score
        }
    }
    
    // MARK: - Supporting Methods
    
    /// Get project context for importance calculation
    private func getProjectContext(for task: LifeTask) async -> ProjectContext? {
        guard let projectId = task.projectId else {
            return nil
        }
        
        // This would fetch project details from the database
        // For now, return a basic context
        return ProjectContext(
            projectId: projectId,
            importanceBoost: 0.2,
            isNearDeadline: false,
            isCritical: false
        )
    }
    
    /// Generate comprehensive reasoning for the priority assessment
    private func generateComprehensiveReasoning(
        task: LifeTask,
        urgency: Double,
        importance: Double,
        context: Double,
        userPattern: Double,
        intelligence: Double
    ) -> [String] {
        
        var reasoning: [String] = []
        
        // Urgency reasoning
        if urgency > 0.8 {
            if task.isOverdue {
                reasoning.append("Task is significantly overdue (\(String(format: "%.1f", task.overdueByHours)) hours)")
            } else {
                reasoning.append("High urgency due to approaching deadline and priority level")
            }
        } else if urgency > 0.6 {
            reasoning.append("Moderate urgency based on timing and priority")
        }
        
        // Importance reasoning
        if importance > 0.8 {
            if task.isFocus {
                reasoning.append("Marked as focus task with high project importance")
            } else {
                reasoning.append("High importance based on project context and content analysis")
            }
        } else if importance > 0.6 {
            reasoning.append("Moderate importance with good project/area alignment")
        }
        
        // Context reasoning
        if context > 0.7 {
            reasoning.append("Current context is favorable for this task")
        } else if context < 0.4 {
            reasoning.append("Current context is less optimal for this task")
        }
        
        // User pattern reasoning
        if userPattern > 0.7 {
            reasoning.append("Matches your established scheduling patterns")
        } else if userPattern > 0.5 {
            reasoning.append("Aligns with some of your preferences")
        }
        
        // Intelligence reasoning
        if intelligence > 0.8 {
            reasoning.append("AI analysis indicates high strategic value")
        } else if intelligence > 0.6 {
            reasoning.append("AI analysis shows good task characteristics")
        } else if intelligence < 0.4 {
            reasoning.append("AI analysis suggests this could be lower priority")
        }
        
        // Overall assessment
        let overallScore = (urgency + importance + context + userPattern + intelligence) / 5.0
        if overallScore > 0.8 {
            reasoning.append("Overall assessment: High priority task requiring prompt attention")
        } else if overallScore > 0.6 {
            reasoning.append("Overall assessment: Moderate priority task with good scheduling potential")
        } else {
            reasoning.append("Overall assessment: Standard priority task suitable for flexible scheduling")
        }
        
        return reasoning
    }
    
    /// Calculate overall confidence in the priority assessment
    private func calculateOverallConfidence(
        urgency: Double,
        importance: Double,
        context: Double,
        userPattern: Double,
        intelligence: Double
    ) -> Double {
        
        // Base confidence
        var confidence = 0.7
        
        // Higher confidence when scores are more extreme (either high or low)
        let scores = [urgency, importance, context, userPattern, intelligence]
        let extremeScores = scores.filter { $0 > 0.8 || $0 < 0.2 }
        let extremeBoost = Double(extremeScores.count) * 0.05
        confidence += extremeBoost
        
        // Lower confidence when scores are very spread out (inconsistent)
        let average = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - average, 2) }.reduce(0, +) / Double(scores.count)
        let consistencyPenalty = variance * 0.3
        confidence -= consistencyPenalty
        
        // Higher confidence when we have good user pattern data
        if userPattern > 0.6 {
            confidence += 0.1
        }
        
        return max(0.3, min(1.0, confidence))
    }
    
    /// Create fallback intelligence when calculation fails
    private func createFallbackIntelligence(for task: LifeTask) -> PriorityIntelligence {
        let baseScore = task.priority.priorityScore / 5.0 // Convert 2-5 scale to 0.4-1.0
        
        return PriorityIntelligence(
            taskId: task.id,
            intelligenceScore: baseScore,
            urgencyScore: task.isOverdue ? 0.8 : baseScore,
            importanceScore: task.isFocus ? 0.8 : baseScore,
            contextScore: 0.5,
            userPatternScore: 0.5,
            reasoningFactors: ["Fallback assessment based on basic task properties"],
            confidence: 0.4
        )
    }
    
    // MARK: - Cache Management
    
    /// Cache priority intelligence result
    private func cacheIntelligence(_ intelligence: PriorityIntelligence) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async {
                self.intelligenceCache[intelligence.taskId] = intelligence
                continuation.resume()
            }
        }
        
        await MainActor.run {
            cachedIntelligenceCount = intelligenceCache.count
            updateAverageConfidence()
        }
    }
    
    /// Get cached priority intelligence
    private func getCachedIntelligence(for taskId: UUID) async -> PriorityIntelligence? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async {
                let cached = self.intelligenceCache[taskId]
                
                // Check if expired
                if let intelligence = cached, intelligence.isExpired {
                    self.intelligenceCache.removeValue(forKey: taskId)
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: cached)
                }
            }
        }
    }
    
    /// Clean up expired intelligence entries
    private func cleanupExpiredIntelligence() async {
        let now = Date()
        guard now.timeIntervalSince(lastCacheCleanup) > 3600 else { return } // Only cleanup once per hour
        
        await withCheckedContinuation { continuation in
            cacheQueue.async {
                let beforeCount = self.intelligenceCache.count
                self.intelligenceCache = self.intelligenceCache.filter { !$0.value.isExpired }
                let afterCount = self.intelligenceCache.count
                
                self.lastCacheCleanup = now
                
                if beforeCount != afterCount {
                    self.logger.debug("PRIORITY_INTELLIGENCE: Cleaned up \(beforeCount - afterCount) expired intelligence entries")
                }
                
                continuation.resume()
            }
        }
        
        await MainActor.run {
            cachedIntelligenceCount = intelligenceCache.count
            updateAverageConfidence()
        }
    }
    
    /// Update average confidence metric
    private func updateAverageConfidence() {
        guard !intelligenceCache.isEmpty else {
            averageConfidence = 0.0
            return
        }
        
        let totalConfidence = intelligenceCache.values.reduce(0.0) { $0 + $1.confidence }
        averageConfidence = totalConfidence / Double(intelligenceCache.count)
    }
    
    // MARK: - Public API
    
    /// Get priority intelligence for multiple tasks efficiently
    func getPriorityIntelligence(for taskIds: [UUID]) async -> [UUID: PriorityIntelligence] {
        var results: [UUID: PriorityIntelligence] = [:]
        
        for taskId in taskIds {
            if let cached = await getCachedIntelligence(for: taskId) {
                results[taskId] = cached
            }
        }
        
        return results
    }
    
    /// Clear all cached intelligence (useful for testing or data reset)
    func clearCache() async {
        await withCheckedContinuation { continuation in
            cacheQueue.async {
                self.intelligenceCache.removeAll()
                continuation.resume()
            }
        }
        
        await MainActor.run {
            cachedIntelligenceCount = 0
            averageConfidence = 0.0
        }
        
        logger.info("PRIORITY_INTELLIGENCE: Cache cleared")
    }
}

// MARK: - Supporting Data Structures

/// Project context for importance calculation
struct ProjectContext {
    let projectId: UUID
    let importanceBoost: Double
    let isNearDeadline: Bool
    let isCritical: Bool
}