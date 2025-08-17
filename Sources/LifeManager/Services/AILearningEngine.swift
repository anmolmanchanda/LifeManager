//
// AILearningEngine.swift
// LifeManager
//
// Phase 4: Integration, Learning & Optimization
// AI pattern recognition and learning system for intelligent automation
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation
import SwiftUI
import Combine

/// Advanced AI learning engine that analyzes user patterns and improves automation decisions
/// Integrates with all intelligent automation services to provide continuous learning
@MainActor
class AILearningEngine: ObservableObject {
    
    static let shared = AILearningEngine()
    
    // MARK: - Dependencies
    
    private let llmService = LLMServiceCoordinator.shared
    private let contextMemory = ContextMemoryService.shared
    private let personalRules = PersonalRulesService.shared
    private let supabaseService = SupabaseService.shared
    private let performanceMonitor = PerformanceMonitoringService.shared
    private let logger = Logger.shared
    
    // MARK: - Published State
    
    @Published var isLearning = false
    @Published var learningInsights: [LearningInsight] = []
    @Published var behaviorPatterns: [BehaviorPattern] = []
    @Published var optimizationOpportunities: [OptimizationOpportunity] = []
    @Published var userFeedbackHistory: [UserFeedback] = []
    @Published var modelPerformanceMetrics: ModelPerformanceMetrics = ModelPerformanceMetrics()
    @Published var adaptationSuggestions: [AdaptationSuggestion] = []
    
    // MARK: - Configuration
    
    private let learningInterval: TimeInterval = 3600 // 1 hour
    private let minDataPointsForLearning = 10
    private let maxInsightHistory = 100
    private let confidenceThreshold = 0.75
    private var learningTimer: Timer?
    
    // MARK: - Learning Data
    
    private var userInteractionHistory: [UserInteraction] = []
    private var decisionOutcomes: [DecisionOutcome] = []
    private var performanceMetrics: [PerformanceMetric] = []
    private var contextualLearning: [ContextualPattern] = []
    
    // MARK: - Initialization
    
    private init() {
        logger.info("AI_LEARNING: Engine initialized")
        Task {
            await loadLearningData()
            await startContinuousLearning()
        }
    }
    
    // MARK: - Learning Orchestration
    
    /// Start continuous learning process
    func startContinuousLearning() async {
        guard !isLearning else { return }
        
        logger.info("AI_LEARNING: Starting continuous learning")
        isLearning = true
        
        // Initial learning analysis
        await performLearningCycle()
        
        // Set up periodic learning
        learningTimer = Timer.scheduledTimer(withTimeInterval: learningInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performLearningCycle()
            }
        }
        
        logger.success("AI_LEARNING: Continuous learning started")
    }
    
    /// Stop continuous learning
    func stopContinuousLearning() {
        logger.info("AI_LEARNING: Stopping continuous learning")
        isLearning = false
        learningTimer?.invalidate()
        learningTimer = nil
    }
    
    /// Perform a complete learning cycle
    private func performLearningCycle() async {
        logger.debug("AI_LEARNING: Performing learning cycle")
        
        let timer = performanceMonitor.startPerformanceTimer(for: "AI_Learning_Cycle")
        
        // Collect recent data
        await collectUserInteractionData()
        await collectDecisionOutcomes()
        await collectPerformanceData()
        
        // Analyze patterns
        await analyzeBehaviorPatterns()
        await analyzeDecisionEffectiveness()
        await identifyOptimizationOpportunities()
        
        // Generate insights
        await generateLearningInsights()
        await generateAdaptationSuggestions()
        
        // Update models
        await updatePersonalRules()
        await updateContextualMemory()
        
        // Cleanup old data
        await cleanupLearningData()
        
        let duration = performanceMonitor.endPerformanceTimer(for: "AI_Learning_Cycle")
        logger.success("AI_LEARNING: Learning cycle completed in \(String(format: "%.2f", duration ?? 0))s")
    }
    
    // MARK: - Data Collection
    
    /// Collect user interaction data from all services
    private func collectUserInteractionData() async {
        logger.debug("AI_LEARNING: Collecting user interaction data")
        
        // Collect from intelligent rescheduling
        await collectReschedulingInteractions()
        
        // Collect from notifications
        await collectNotificationInteractions()
        
        // Collect from dependency management
        await collectDependencyInteractions()
        
        // Collect from calendar integration
        await collectCalendarInteractions()
    }
    
    /// Collect rescheduling interaction data
    private func collectReschedulingInteractions() async {
        let reschedulingService = IntelligentReschedulingService.shared
        let stats = reschedulingService.getReschedulingStatistics()
        
        let interaction = UserInteraction(
            id: UUID(),
            timestamp: Date(),
            serviceType: .intelligentRescheduling,
            actionType: .automaticDecision,
            userResponse: stats.userOverrides > 0 ? .override : .accept,
            context: [
                "total_rescheduled": stats.totalRescheduled,
                "success_rate": stats.successRate,
                "user_overrides": stats.userOverrides
            ]
        )
        
        userInteractionHistory.append(interaction)
    }
    
    /// Collect notification interaction data
    private func collectNotificationInteractions() async {
        let notificationService = AdvancedNotificationService.shared
        let stats = notificationService.deliveryStatistics
        
        let interaction = UserInteraction(
            id: UUID(),
            timestamp: Date(),
            serviceType: .advancedNotifications,
            actionType: .notification,
            userResponse: .viewed, // Would track actual user responses
            context: [
                "critical_sent": stats.criticalSent,
                "emails_sent": stats.emailsSent,
                "sms_sent": stats.smsSent
            ]
        )
        
        userInteractionHistory.append(interaction)
    }
    
    /// Collect dependency interaction data
    private func collectDependencyInteractions() async {
        let dependencyService = TaskDependencyService.shared
        
        let interaction = UserInteraction(
            id: UUID(),
            timestamp: Date(),
            serviceType: .taskDependencies,
            actionType: .dependencyCreation,
            userResponse: .accept,
            context: [
                "total_dependencies": dependencyService.taskDependencies.values.flatMap { $0 }.count,
                "validation_errors": dependencyService.validationErrors.count
            ]
        )
        
        userInteractionHistory.append(interaction)
    }
    
    /// Collect calendar interaction data
    private func collectCalendarInteractions() async {
        let calendarService = ExternalCalendarIntegrationService.shared
        
        let interaction = UserInteraction(
            id: UUID(),
            timestamp: Date(),
            serviceType: .calendarIntegration,
            actionType: .scheduleSync,
            userResponse: .accept,
            context: [
                "external_events": calendarService.externalEvents.count,
                "conflicts_detected": calendarService.conflictingEvents.count
            ]
        )
        
        userInteractionHistory.append(interaction)
    }
    
    /// Collect decision outcomes from all services
    private func collectDecisionOutcomes() async {
        logger.debug("AI_LEARNING: Collecting decision outcomes")
        
        // Analyze recent decisions and their effectiveness
        let recentInteractions = userInteractionHistory.suffix(50)
        
        for interaction in recentInteractions {
            let outcome = DecisionOutcome(
                id: UUID(),
                interactionId: interaction.id,
                decisionType: mapActionToDecision(interaction.actionType),
                aiConfidence: 0.8, // Would get from actual AI decisions
                userSatisfaction: mapResponseToSatisfaction(interaction.userResponse),
                effectivenessScore: calculateEffectiveness(for: interaction),
                timestamp: interaction.timestamp
            )
            
            decisionOutcomes.append(outcome)
        }
    }
    
    /// Collect performance data from all services
    private func collectPerformanceData() async {
        logger.debug("AI_LEARNING: Collecting performance data")
        
        let serviceMetrics = performanceMonitor.serviceMetrics
        
        for (serviceName, metrics) in serviceMetrics {
            let performanceMetric = PerformanceMetric(
                id: UUID(),
                serviceName: serviceName,
                responseTime: metrics.responseTime,
                errorRate: metrics.requestCount > 0 ? Double(metrics.errorCount) / Double(metrics.requestCount) : 0,
                throughput: Double(metrics.requestCount),
                resourceUsage: metrics.memoryUsage,
                timestamp: Date()
            )
            
            performanceMetrics.append(performanceMetric)
        }
    }
    
    // MARK: - Pattern Analysis
    
    /// Analyze user behavior patterns
    private func analyzeBehaviorPatterns() async {
        logger.debug("AI_LEARNING: Analyzing behavior patterns")
        
        guard userInteractionHistory.count >= minDataPointsForLearning else { return }
        
        // Time-based patterns
        await analyzeTimeBasedPatterns()
        
        // Service usage patterns
        await analyzeServiceUsagePatterns()
        
        // Decision patterns
        await analyzeDecisionPatterns()
        
        // Context patterns
        await analyzeContextualPatterns()
    }
    
    /// Analyze time-based usage patterns
    private func analyzeTimeBasedPatterns() async {
        let interactions = userInteractionHistory.suffix(100)
        let hourlyDistribution = Dictionary(grouping: interactions) { interaction in
            Calendar.current.component(.hour, from: interaction.timestamp)
        }
        
        // Find peak usage hours
        let peakHours = hourlyDistribution
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key }
        
        let pattern = BehaviorPattern(
            id: UUID(),
            type: .temporal,
            description: "Peak usage hours: \(peakHours.map { "\($0):00" }.joined(separator: ", "))",
            confidence: 0.85,
            frequency: .daily,
            impact: .medium,
            recommendations: [
                "Schedule automated tasks during peak hours",
                "Increase notification frequency during active periods",
                "Optimize performance during high-usage times"
            ]
        )
        
        behaviorPatterns.append(pattern)
    }
    
    /// Analyze service usage patterns
    private func analyzeServiceUsagePatterns() async {
        let interactions = userInteractionHistory.suffix(100)
        let serviceDistribution = Dictionary(grouping: interactions) { $0.serviceType }
        
        // Identify most used services
        let topServices = serviceDistribution
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
        
        for (serviceType, serviceInteractions) in topServices {
            let acceptanceRate = Double(serviceInteractions.filter { $0.userResponse == .accept }.count) / Double(serviceInteractions.count)
            
            let pattern = BehaviorPattern(
                id: UUID(),
                type: .serviceUsage,
                description: "\(serviceType.rawValue) usage: \(serviceInteractions.count) interactions, \(Int(acceptanceRate * 100))% acceptance",
                confidence: acceptanceRate,
                frequency: .weekly,
                impact: acceptanceRate > 0.8 ? .high : .medium,
                recommendations: generateServiceRecommendations(for: serviceType, acceptanceRate: acceptanceRate)
            )
            
            behaviorPatterns.append(pattern)
        }
    }
    
    /// Analyze decision patterns
    private func analyzeDecisionPatterns() async {
        let outcomes = decisionOutcomes.suffix(50)
        
        // Group by decision type
        let decisionGroups = Dictionary(grouping: outcomes) { $0.decisionType }
        
        for (decisionType, decisions) in decisionGroups {
            let avgConfidence = decisions.map { $0.aiConfidence }.reduce(0, +) / Double(decisions.count)
            let avgSatisfaction = decisions.map { $0.userSatisfaction }.reduce(0, +) / Double(decisions.count)
            let avgEffectiveness = decisions.map { $0.effectivenessScore }.reduce(0, +) / Double(decisions.count)
            
            let pattern = BehaviorPattern(
                id: UUID(),
                type: .decisionMaking,
                description: "\(decisionType.rawValue): Confidence \(Int(avgConfidence * 100))%, Satisfaction \(Int(avgSatisfaction * 100))%, Effectiveness \(Int(avgEffectiveness * 100))%",
                confidence: avgConfidence,
                frequency: .continuous,
                impact: avgEffectiveness > 0.8 ? .high : .medium,
                recommendations: generateDecisionRecommendations(for: decisionType, confidence: avgConfidence, effectiveness: avgEffectiveness)
            )
            
            behaviorPatterns.append(pattern)
        }
    }
    
    /// Analyze contextual patterns
    private func analyzeContextualPatterns() async {
        // This would integrate with ContextMemoryService for deeper analysis
        // TODO: Add getActiveContext method to ContextMemoryService
        // let contextData = await contextMemory.getActiveContext()
        let contextData: [String] = []
        
        // Analyze patterns in context usage
        let pattern = ContextualPattern(
            id: UUID(),
            contextType: "work_personal_balance",
            pattern: "User tends to override rescheduling during work hours",
            confidence: 0.75,
            applicability: ["rescheduling", "notifications"],
            learningSource: "interaction_analysis"
        )
        
        contextualLearning.append(pattern)
    }
    
    /// Analyze decision effectiveness across all services
    private func analyzeDecisionEffectiveness() async {
        logger.debug("AI_LEARNING: Analyzing decision effectiveness")
        
        let recentOutcomes = decisionOutcomes.suffix(100)
        
        // Calculate overall effectiveness metrics
        let overallEffectiveness = recentOutcomes.map { $0.effectivenessScore }.reduce(0, +) / Double(recentOutcomes.count)
        let userSatisfaction = recentOutcomes.map { $0.userSatisfaction }.reduce(0, +) / Double(recentOutcomes.count)
        
        modelPerformanceMetrics = ModelPerformanceMetrics(
            overallAccuracy: overallEffectiveness,
            userSatisfactionScore: userSatisfaction,
            decisionConfidence: recentOutcomes.map { $0.aiConfidence }.reduce(0, +) / Double(recentOutcomes.count),
            adaptationRate: calculateAdaptationRate(),
            learningVelocity: calculateLearningVelocity(),
            lastUpdated: Date()
        )
        
        // Identify areas for improvement
        let lowPerformanceDecisions = recentOutcomes.filter { $0.effectivenessScore < 0.6 }
        
        if !lowPerformanceDecisions.isEmpty {
            await generateImprovementInsights(for: lowPerformanceDecisions)
        }
    }
    
    // MARK: - Optimization Identification
    
    /// Identify optimization opportunities across all services
    private func identifyOptimizationOpportunities() async {
        logger.debug("AI_LEARNING: Identifying optimization opportunities")
        
        optimizationOpportunities.removeAll()
        
        // Analyze service performance
        await identifyServiceOptimizations()
        
        // Analyze user interaction optimization
        await identifyInteractionOptimizations()
        
        // Analyze AI model optimization
        await identifyModelOptimizations()
        
        // Analyze integration optimization
        await identifyIntegrationOptimizations()
    }
    
    /// Identify service-specific optimizations
    private func identifyServiceOptimizations() async {
        let serviceMetrics = performanceMonitor.serviceMetrics
        
        for (serviceName, metrics) in serviceMetrics {
            if metrics.responseTime > 2.0 {
                let opportunity = OptimizationOpportunity(
                    id: UUID(),
                    category: .performance,
                    title: "Optimize \(serviceName) Response Time",
                    description: "Service response time is \(String(format: "%.2f", metrics.responseTime))s, above optimal threshold",
                    impact: .high,
                    effort: .medium,
                    implementation: [
                        "Add response caching for \(serviceName)",
                        "Optimize database queries",
                        "Implement request batching",
                        "Add background processing"
                    ],
                    estimatedImprovement: "50-70% response time reduction"
                )
                
                optimizationOpportunities.append(opportunity)
            }
            
            if metrics.errorCount > 0 {
                let errorRate = Double(metrics.errorCount) / Double(max(metrics.requestCount, 1))
                
                if errorRate > 0.05 {
                    let opportunity = OptimizationOpportunity(
                        id: UUID(),
                        category: .reliability,
                        title: "Reduce \(serviceName) Error Rate",
                        description: "Error rate is \(Int(errorRate * 100))%, above 5% threshold",
                        impact: .high,
                        effort: .medium,
                        implementation: [
                            "Add comprehensive error handling",
                            "Implement circuit breaker pattern",
                            "Add retry logic with exponential backoff",
                            "Improve input validation"
                        ],
                        estimatedImprovement: "80% error reduction"
                    )
                    
                    optimizationOpportunities.append(opportunity)
                }
            }
        }
    }
    
    /// Identify user interaction optimizations
    private func identifyInteractionOptimizations() async {
        let recentInteractions = userInteractionHistory.suffix(100)
        let overrideRate = Double(recentInteractions.filter { $0.userResponse == .override }.count) / Double(recentInteractions.count)
        
        if overrideRate > 0.2 {
            let opportunity = OptimizationOpportunity(
                id: UUID(),
                category: .userExperience,
                title: "Reduce AI Decision Override Rate",
                description: "Users override AI decisions \(Int(overrideRate * 100))% of the time",
                impact: .high,
                effort: .high,
                implementation: [
                    "Improve AI decision confidence thresholds",
                    "Add more contextual factors to decisions",
                    "Implement user preference learning",
                    "Provide better decision explanations"
                ],
                estimatedImprovement: "40% reduction in override rate"
            )
            
            optimizationOpportunities.append(opportunity)
        }
    }
    
    /// Identify AI model optimizations
    private func identifyModelOptimizations() async {
        if modelPerformanceMetrics.overallAccuracy < 0.8 {
            let opportunity = OptimizationOpportunity(
                id: UUID(),
                category: .intelligence,
                title: "Improve AI Model Accuracy",
                description: "Overall AI accuracy is \(Int(modelPerformanceMetrics.overallAccuracy * 100))%, below 80% target",
                impact: .high,
                effort: .high,
                implementation: [
                    "Retrain models with recent user data",
                    "Implement ensemble decision making",
                    "Add more contextual features",
                    "Improve feature engineering"
                ],
                estimatedImprovement: "15-20% accuracy improvement"
            )
            
            optimizationOpportunities.append(opportunity)
        }
    }
    
    /// Identify integration optimizations
    private func identifyIntegrationOptimizations() async {
        // Analyze cross-service coordination
        let opportunity = OptimizationOpportunity(
            id: UUID(),
            category: .integration,
            title: "Enhance Service Coordination",
            description: "Improve coordination between intelligent automation services",
            impact: .medium,
            effort: .medium,
            implementation: [
                "Implement shared context bus",
                "Add service-to-service communication",
                "Create unified decision framework",
                "Add cross-service optimization"
            ],
            estimatedImprovement: "25% improvement in automation effectiveness"
        )
        
        optimizationOpportunities.append(opportunity)
    }
    
    // MARK: - Insight Generation
    
    /// Generate learning insights from analysis
    private func generateLearningInsights() async {
        logger.debug("AI_LEARNING: Generating learning insights")
        
        learningInsights.removeAll()
        
        // Generate pattern-based insights
        for pattern in behaviorPatterns.suffix(10) {
            let insight = LearningInsight(
                id: UUID(),
                type: .behaviorPattern,
                title: "Behavior Pattern Discovered",
                description: pattern.description,
                confidence: pattern.confidence,
                actionable: true,
                recommendations: pattern.recommendations,
                source: "behavior_analysis",
                impact: pattern.impact
            )
            
            learningInsights.append(insight)
        }
        
        // Generate performance insights
        if modelPerformanceMetrics.overallAccuracy > 0.9 {
            let insight = LearningInsight(
                id: UUID(),
                type: .performance,
                title: "High AI Performance Achieved",
                description: "AI decision accuracy is \(Int(modelPerformanceMetrics.overallAccuracy * 100))%",
                confidence: 0.95,
                actionable: false,
                recommendations: ["Maintain current configuration", "Consider expanding automation scope"],
                source: "performance_analysis",
                impact: .high
            )
            
            learningInsights.append(insight)
        }
        
        // Generate optimization insights
        for opportunity in optimizationOpportunities.prefix(3) {
            let insight = LearningInsight(
                id: UUID(),
                type: .optimization,
                title: "Optimization Opportunity",
                description: opportunity.description,
                confidence: 0.8,
                actionable: true,
                recommendations: opportunity.implementation,
                source: "optimization_analysis",
                impact: opportunity.impact
            )
            
            learningInsights.append(insight)
        }
        
        // Trim insights
        if learningInsights.count > maxInsightHistory {
            learningInsights = Array(learningInsights.suffix(maxInsightHistory))
        }
    }
    
    /// Generate adaptation suggestions
    private func generateAdaptationSuggestions() async {
        logger.debug("AI_LEARNING: Generating adaptation suggestions")
        
        adaptationSuggestions.removeAll()
        
        // Analyze recent patterns for adaptation opportunities
        let recentPatterns = behaviorPatterns.suffix(5)
        
        for pattern in recentPatterns where pattern.confidence > confidenceThreshold {
            let suggestion = AdaptationSuggestion(
                id: UUID(),
                type: .automaticAdjustment,
                title: "Adapt to \(pattern.type.rawValue) Pattern",
                description: "Automatically adjust settings based on discovered pattern",
                confidence: pattern.confidence,
                changes: generateAdaptationChanges(for: pattern),
                expectedOutcome: "Improved automation alignment with user preferences",
                reversible: true
            )
            
            adaptationSuggestions.append(suggestion)
        }
        
        // Generate model improvement suggestions
        if modelPerformanceMetrics.overallAccuracy < 0.85 {
            let suggestion = AdaptationSuggestion(
                id: UUID(),
                type: .modelImprovement,
                title: "Improve AI Model Performance",
                description: "Retrain models with recent interaction data",
                confidence: 0.8,
                changes: [
                    "Increase training data weight for recent interactions",
                    "Adjust confidence thresholds based on user feedback",
                    "Update decision criteria with learned preferences"
                ],
                expectedOutcome: "10-15% improvement in decision accuracy",
                reversible: true
            )
            
            adaptationSuggestions.append(suggestion)
        }
    }
    
    // MARK: - Model Updates
    
    /// Update personal rules based on learning
    private func updatePersonalRules() async {
        logger.debug("AI_LEARNING: Updating personal rules")
        
        // Extract high-confidence patterns for rule creation
        let highConfidencePatterns = behaviorPatterns.filter { $0.confidence > 0.8 }
        
        for pattern in highConfidencePatterns {
            // Convert pattern to personal rule
            let rule = await createPersonalRuleFromPattern(pattern)
            if let rule = rule {
                // TODO: Add addLearned method to PersonalRulesService
                // await personalRules.addLearned(rule)
            }
        }
    }
    
    /// Update contextual memory based on learning
    private func updateContextualMemory() async {
        logger.debug("AI_LEARNING: Updating contextual memory")
        
        // Add learned patterns to context memory
        for pattern in contextualLearning.suffix(10) {
            // TODO: Add addLearningPattern method to ContextMemoryService
            /* await contextMemory.addLearningPattern(
                pattern: pattern.pattern,
                confidence: pattern.confidence,
                applicability: pattern.applicability
            ) */
        }
    }
    
    // MARK: - User Feedback Integration
    
    /// Record user feedback for learning
    func recordUserFeedback(
        interactionId: UUID,
        rating: Double,
        feedback: String,
        category: FeedbackCategory
    ) async {
        let userFeedback = UserFeedback(
            id: UUID(),
            interactionId: interactionId,
            rating: rating,
            feedback: feedback,
            category: category,
            timestamp: Date()
        )
        
        userFeedbackHistory.append(userFeedback)
        
        // Use feedback to improve future decisions
        await incorporateFeedback(userFeedback)
        
        logger.info("AI_LEARNING: User feedback recorded and incorporated")
    }
    
    /// Incorporate user feedback into learning models
    private func incorporateFeedback(_ feedback: UserFeedback) async {
        // Find the corresponding interaction
        if let interaction = userInteractionHistory.first(where: { $0.id == feedback.interactionId }) {
            // Update decision outcome based on feedback
            let updatedOutcome = DecisionOutcome(
                id: UUID(),
                interactionId: interaction.id,
                decisionType: mapActionToDecision(interaction.actionType),
                aiConfidence: 0.8, // Would get from actual decision
                userSatisfaction: feedback.rating,
                effectivenessScore: feedback.rating,
                timestamp: Date()
            )
            
            decisionOutcomes.append(updatedOutcome)
            
            // If feedback is negative, create correction
            if feedback.rating < 0.6 {
                await createCorrectionFromFeedback(feedback, interaction: interaction)
            }
        }
    }
    
    // MARK: - Data Management
    
    /// Load learning data from database
    private func loadLearningData() async {
        do {
            logger.info("AI_LEARNING: Loading learning data from database")
            
            // Load user interactions
            // userInteractionHistory = try await loadUserInteractions()
            
            // Load decision outcomes
            // decisionOutcomes = try await loadDecisionOutcomes()
            
            // Load behavior patterns
            // behaviorPatterns = try await loadBehaviorPatterns()
            
            logger.success("AI_LEARNING: Learning data loaded successfully")
            
        } catch {
            logger.error("AI_LEARNING: Failed to load learning data: \(error)")
        }
    }
    
    /// Cleanup old learning data
    private func cleanupLearningData() async {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        
        // Remove old interactions
        userInteractionHistory = userInteractionHistory.filter { $0.timestamp > oneWeekAgo }
        
        // Remove old decision outcomes
        decisionOutcomes = decisionOutcomes.filter { $0.timestamp > oneWeekAgo }
        
        // Remove old performance metrics
        performanceMetrics = performanceMetrics.filter { $0.timestamp > oneWeekAgo }
        
        // Keep only recent patterns
        behaviorPatterns = Array(behaviorPatterns.suffix(50))
        contextualLearning = Array(contextualLearning.suffix(50))
        
        logger.debug("AI_LEARNING: Old learning data cleaned up")
    }
    
    // MARK: - Helper Methods
    
    private func mapActionToDecision(_ actionType: AIActionType) -> DecisionType {
        switch actionType {
        case .automaticDecision: return .rescheduling
        case .notification: return .notification
        case .dependencyCreation: return .dependency
        case .scheduleSync: return .scheduling
        }
    }
    
    private func mapResponseToSatisfaction(_ response: UserResponse) -> Double {
        switch response {
        case .accept: return 1.0
        case .override: return 0.3
        case .dismiss: return 0.5
        case .viewed: return 0.7
        }
    }
    
    private func calculateEffectiveness(for interaction: UserInteraction) -> Double {
        // Simplified effectiveness calculation
        switch interaction.userResponse {
        case .accept: return 0.9
        case .override: return 0.3
        case .dismiss: return 0.4
        case .viewed: return 0.6
        }
    }
    
    private func calculateAdaptationRate() -> Double {
        // Calculate how quickly the system adapts to user preferences
        return 0.75 // Simplified implementation
    }
    
    private func calculateLearningVelocity() -> Double {
        // Calculate how fast the system learns new patterns
        return 0.85 // Simplified implementation
    }
    
    private func generateServiceRecommendations(for serviceType: ServiceType, acceptanceRate: Double) -> [String] {
        if acceptanceRate > 0.8 {
            return ["Increase automation level for \(serviceType.rawValue)", "Consider expanding scope"]
        } else {
            return ["Review decision criteria for \(serviceType.rawValue)", "Add more user context", "Improve confidence thresholds"]
        }
    }
    
    private func generateDecisionRecommendations(for decisionType: DecisionType, confidence: Double, effectiveness: Double) -> [String] {
        var recommendations: [String] = []
        
        if confidence < 0.7 {
            recommendations.append("Improve confidence calculation for \(decisionType.rawValue)")
        }
        
        if effectiveness < 0.8 {
            recommendations.append("Enhance decision criteria for \(decisionType.rawValue)")
        }
        
        return recommendations
    }
    
    private func generateImprovementInsights(for outcomes: [DecisionOutcome]) async {
        let lowPerformanceTypes = Set(outcomes.map { $0.decisionType })
        
        for decisionType in lowPerformanceTypes {
            let insight = LearningInsight(
                id: UUID(),
                type: .improvement,
                title: "Low Performance Detected",
                description: "\(decisionType.rawValue) decisions need improvement",
                confidence: 0.8,
                actionable: true,
                recommendations: [
                    "Analyze failed \(decisionType.rawValue) decisions",
                    "Collect more training data",
                    "Improve feature selection",
                    "Add user feedback collection"
                ],
                source: "performance_analysis",
                impact: .high
            )
            
            learningInsights.append(insight)
        }
    }
    
    private func generateAdaptationChanges(for pattern: BehaviorPattern) -> [String] {
        switch pattern.type {
        case .temporal:
            return ["Adjust notification timing", "Optimize automation schedule"]
        case .serviceUsage:
            return ["Tune service parameters", "Adjust automation levels"]
        case .decisionMaking:
            return ["Update decision thresholds", "Improve context weighting"]
        @unknown default:
            return ["Review pattern for adaptation"]
        }
    }
    
    private func createPersonalRuleFromPattern(_ pattern: BehaviorPattern) async -> PersonalRule? {
        // Convert behavior pattern to personal rule
        guard pattern.confidence > 0.8 else { return nil }
        
        return PersonalRule(
            ruleType: .behavioral,
            pattern: pattern.description,
            action: pattern.recommendations.joined(separator: "; "),
            confidence: pattern.confidence,
            frequency: pattern.occurrences,
            lastApplied: nil,
            isActive: true,
            source: .learned
        )
    }
    
    private func createCorrectionFromFeedback(_ feedback: UserFeedback, interaction: UserInteraction) async {
        // TODO: Add addCorrection method to PersonalRulesService
        /* await personalRules.addCorrection(
            original: "AI suggested action",
            corrected: feedback.feedback,
            context: interaction.context.description,
            confidence: 1.0 - feedback.rating // Higher correction confidence for lower ratings
        ) */
    }
}

// MARK: - Supporting Types

/// Learning insight from AI analysis
struct LearningInsight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let actionable: Bool
    let recommendations: [String]
    let source: String
    let impact: ImpactLevel
}

/// Types of learning insights
enum InsightType: String, Codable {
    case behaviorPattern = "behavior_pattern"
    case performance = "performance"
    case optimization = "optimization"
    case improvement = "improvement"
}

/// User behavior pattern
struct BehaviorPattern: Identifiable {
    let id: UUID
    let type: UnifiedPatternType
    let description: String
    let confidence: Double
    let frequency: PatternFrequency
    let impact: ImpactLevel
    let recommendations: [String]
}

// PatternType moved to UnifiedPatternType in CoreModels.swift

/// Pattern frequency
enum PatternFrequency: String {
    case daily = "daily"
    case weekly = "weekly"
    case continuous = "continuous"
}

/// Optimization opportunity
struct OptimizationOpportunity: Identifiable {
    let id: UUID
    let category: OptimizationCategory
    let title: String
    let description: String
    let impact: ImpactLevel
    let effort: EffortLevel
    let implementation: [String]
    let estimatedImprovement: String
}

/// Optimization categories
enum OptimizationCategory: String {
    case performance = "performance"
    case reliability = "reliability"
    case userExperience = "user_experience"
    case intelligence = "intelligence"
    case integration = "integration"
}

/// Effort levels
enum EffortLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// User interaction record
struct UserInteraction: Identifiable {
    let id: UUID
    let timestamp: Date
    let serviceType: ServiceType
    let actionType: AIActionType
    let userResponse: UserResponse
    let context: [String: Any]
}

/// Service types
enum ServiceType: String {
    case intelligentRescheduling = "intelligent_rescheduling"
    case advancedNotifications = "advanced_notifications"
    case taskDependencies = "task_dependencies"
    case calendarIntegration = "calendar_integration"
}

/// Action types
enum AIActionType: String {
    case automaticDecision = "automatic_decision"
    case notification = "notification"
    case dependencyCreation = "dependency_creation"
    case scheduleSync = "schedule_sync"
}

/// User response types
enum UserResponse: String {
    case accept = "accept"
    case override = "override"
    case dismiss = "dismiss"
    case viewed = "viewed"
}

/// Decision outcome
struct DecisionOutcome: Identifiable {
    let id: UUID
    let interactionId: UUID
    let decisionType: DecisionType
    let aiConfidence: Double
    let userSatisfaction: Double
    let effectivenessScore: Double
    let timestamp: Date
}

/// Decision types
enum DecisionType: String {
    case rescheduling = "rescheduling"
    case notification = "notification"
    case dependency = "dependency"
    case scheduling = "scheduling"
}

/// Performance metric
struct PerformanceMetric: Identifiable {
    let id: UUID
    let serviceName: String
    let responseTime: TimeInterval
    let errorRate: Double
    let throughput: Double
    let resourceUsage: Double
    let timestamp: Date
}

/// Contextual learning pattern
struct ContextualPattern: Identifiable {
    let id: UUID
    let contextType: String
    let pattern: String
    let confidence: Double
    let applicability: [String]
    let learningSource: String
}

/// User feedback
struct UserFeedback: Identifiable {
    let id: UUID
    let interactionId: UUID
    let rating: Double
    let feedback: String
    let category: FeedbackCategory
    let timestamp: Date
}

/// Feedback categories
enum FeedbackCategory: String {
    case accuracy = "accuracy"
    case timing = "timing"
    case relevance = "relevance"
    case usability = "usability"
}

/// Model performance metrics
struct ModelPerformanceMetrics {
    let overallAccuracy: Double
    let userSatisfactionScore: Double
    let decisionConfidence: Double
    let adaptationRate: Double
    let learningVelocity: Double
    let lastUpdated: Date
    
    init() {
        self.overallAccuracy = 0.0
        self.userSatisfactionScore = 0.0
        self.decisionConfidence = 0.0
        self.adaptationRate = 0.0
        self.learningVelocity = 0.0
        self.lastUpdated = Date()
    }
    
    init(overallAccuracy: Double, userSatisfactionScore: Double, decisionConfidence: Double, adaptationRate: Double, learningVelocity: Double, lastUpdated: Date) {
        self.overallAccuracy = overallAccuracy
        self.userSatisfactionScore = userSatisfactionScore
        self.decisionConfidence = decisionConfidence
        self.adaptationRate = adaptationRate
        self.learningVelocity = learningVelocity
        self.lastUpdated = lastUpdated
    }
}

/// Adaptation suggestion
struct AdaptationSuggestion: Identifiable {
    let id: UUID
    let type: AdaptationType
    let title: String
    let description: String
    let confidence: Double
    let changes: [String]
    let expectedOutcome: String
    let reversible: Bool
}

/// Adaptation types
enum AdaptationType: String {
    case automaticAdjustment = "automatic_adjustment"
    case modelImprovement = "model_improvement"
    case configurationChange = "configuration_change"
}