import Foundation
import SwiftUI
import Combine

/// Focus View Service
/// Delivers effortless daily productivity focus with AI-powered prioritization
/// Integrates with existing intelligent automation services for seamless UX
@MainActor
class FocusViewService: ObservableObject {
    
    static let shared = FocusViewService()
    
    // MARK: - Dependencies
    
    private let taskRepository = TaskRepository()
    private let projectRepository = ProjectRepository()
    private let areaRepository = AreaRepository()
    private let contextMemory = ContextMemoryService.shared
    private let personalRules = PersonalRulesService.shared
    private let intelligentRescheduling = IntelligentReschedulingService.shared
    private let priorityEngine = PriorityIntelligenceEngine.shared
    private let proactiveNotifications = ProactiveNotificationEngine.shared
    private let llmService = LLMServiceCoordinator.shared
    private let logger = Logger.shared
    
    // MARK: - Published State
    
    @Published var currentFocusSession: FocusSession?
    @Published var todaysFocusItems: [FocusItem] = []
    @Published var filteredFocusItems: [FocusItem] = []
    @Published var activeFocusFilters: Set<FocusFilter> = []
    @Published var availableFilters: [FocusFilter] = FocusFilter.defaultFilters
    @Published var currentMoodAssessment: DailyMoodAssessment?
    @Published var aiRecommendations: [AIRecommendation] = []
    @Published var isLoading = false
    @Published var sessionStats = FocusSessionStats()
    @Published var selectedFocusItems: Set<UUID> = []
    
    // MARK: - Configuration
    
    private let maxFocusItemsPerDay = 12
    private let aiConfidenceThreshold = 0.6
    private let moodAnalysisInterval: TimeInterval = 3600 // 1 hour
    private var moodAnalysisTimer: Timer?
    private var focusSessionTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        logger.info("FOCUS_VIEW: Service initialized")
        setupFocusSession()
        startMoodAnalysis()
        loadTodaysFocus()
    }
    
    deinit {
        moodAnalysisTimer?.invalidate()
        focusSessionTimer?.invalidate()
    }
    
    // MARK: - Focus Session Management
    
    /// Setup or restore today's focus session
    func setupFocusSession() {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        
        // Try to load existing session for today
        if let existingSession = loadExistingSession(for: String(today)) {
            currentFocusSession = existingSession
            todaysFocusItems = existingSession.items
            sessionStats = existingSession.sessionStats
            logger.info("FOCUS_VIEW: Restored existing session with \(todaysFocusItems.count) items")
        } else {
            // Create new session
            createNewFocusSession(for: String(today))
        }
        
        // Start session monitoring
        startSessionMonitoring()
    }
    
    /// Create a new focus session for the given date
    private func createNewFocusSession(for date: String) {
        logger.info("FOCUS_VIEW: Creating new focus session for \(date)")
        
        Task {
            do {
                let focusItems = await generateTodaysFocusItems()
                let aiRecs = await generateAIRecommendations(for: focusItems)
                
                let session = FocusSession(
                    date: date,
                    items: focusItems,
                    totalEstimatedTime: focusItems.compactMap(\.estimatedDuration).reduce(0, +),
                    aiRecommendations: aiRecs
                )
                
                await MainActor.run {
                    currentFocusSession = session
                    todaysFocusItems = focusItems
                    aiRecommendations = aiRecs
                    applyDefaultFilters()
                }
                
                logger.success("FOCUS_VIEW: Created session with \(focusItems.count) items")
                
            } catch {
                logger.error("FOCUS_VIEW: Failed to create focus session: \(error)")
            }
        }
    }
    
    /// Load existing session from storage
    private func loadExistingSession(for date: String) -> FocusSession? {
        // TODO: Implement session persistence
        // For now, return nil to always create new sessions
        return nil
    }
    
    /// Save current session to storage
    func saveFocusSession() async {
        guard let session = currentFocusSession else { return }
        
        // TODO: Implement session persistence
        logger.debug("FOCUS_VIEW: Session saved for \(session.date)")
    }
    
    // MARK: - Focus Items Generation
    
    /// Generate today's focus items using AI prioritization
    private func generateTodaysFocusItems() async -> [FocusItem] {
        logger.debug("FOCUS_VIEW: Generating today's focus items")
        
        do {
            // Fetch relevant tasks and events
            let overdueTasks = try await taskRepository.fetchOverdueTasks()
            let todayTasks = try await taskRepository.fetchTasksDueToday()
            let upcomingTasks = try await taskRepository.fetchTasksDueSoon(within: 3)
            let focusTasks = try await taskRepository.fetchFocusTasks()
            
            // Combine and deduplicate
            let allCandidateTasks = Array(Set(overdueTasks + todayTasks + upcomingTasks + focusTasks))
            
            // Convert to focus items with AI analysis
            var focusItems: [FocusItem] = []
            
            for task in allCandidateTasks {
                if let focusItem = await convertTaskToFocusItem(task) {
                    focusItems.append(focusItem)
                }
            }
            
            // Sort by AI-computed priority score
            let prioritizedItems = await prioritizeFocusItems(focusItems)
            
            // Limit to reasonable daily capacity
            let finalItems = Array(prioritizedItems.prefix(maxFocusItemsPerDay))
            
            logger.success("FOCUS_VIEW: Generated \(finalItems.count) focus items from \(allCandidateTasks.count) candidates")
            return finalItems
            
        } catch {
            logger.error("FOCUS_VIEW: Failed to generate focus items: \(error)")
            return []
        }
    }
    
    /// Convert a LifeTask to a FocusItem with AI analysis
    private func convertTaskToFocusItem(_ task: LifeTask) async -> FocusItem? {
        do {
            // Calculate AI priority and reasoning
            let priorityIntelligence = await priorityEngine.calculatePriorityIntelligence(for: task)
            let aiReason = await generateAIReasoning(for: task, intelligence: priorityIntelligence ?? createDefaultIntelligence())
            
            // Determine focus priority from task priority and AI analysis
            let focusPriority = mapToFocusPriority(task.priority, aiScore: priorityIntelligence?.intelligenceScore ?? 0.5)
            
            // Determine urgency from due date
            let urgency = calculateUrgencyLevel(for: task)
            
            // Determine energy and complexity requirements
            let energyLevel = await analyzeTaskEnergyRequirement(task)
            let complexity = await analyzeTaskComplexity(task)
            
            // Calculate estimated focus blocks
            let estimatedBlocks = calculateFocusBlocks(duration: task.estimatedDuration ?? 60)
            
            let focusItem = FocusItem(
                sourceId: task.id,
                sourceType: .task,
                title: task.title,
                description: task.description,
                estimatedDuration: task.estimatedDuration,
                priority: focusPriority,
                urgency: urgency,
                aiReason: aiReason,
                dueDate: task.dueDate.flatMap { ISO8601DateFormatter().date(from: $0) },
                workPersonal: task.workPersonal,
                projectId: task.projectId,
                areaId: task.areaId,
                status: mapToFocusStatus(task.status),
                energyLevel: energyLevel,
                complexity: complexity,
                canBeDoneOffline: await analyzeOfflineCapability(task),
                estimatedFocusBlocks: estimatedBlocks
            )
            
            return focusItem
            
        } catch {
            logger.error("FOCUS_VIEW: Failed to convert task to focus item: \(error)")
            return nil
        }
    }
    
    /// Prioritize focus items using AI intelligence
    private func prioritizeFocusItems(_ items: [FocusItem]) async -> [FocusItem] {
        return items.sorted { item1, item2 in
            // Primary sort: Priority level
            if item1.priority.sortOrder != item2.priority.sortOrder {
                return item1.priority.sortOrder < item2.priority.sortOrder
            }
            
            // Secondary sort: Urgency
            if item1.urgency != item2.urgency {
                return item1.urgency.rawValue.count > item2.urgency.rawValue.count // More urgent first
            }
            
            // Tertiary sort: Due date (sooner first)
            if let date1 = item1.dueDate, let date2 = item2.dueDate {
                return date1 < date2
            }
            
            // Final sort: Creation time (newer first)
            return item1.sourceId.uuidString > item2.sourceId.uuidString
        }
    }
    
    // MARK: - AI Analysis Methods
    
    /// Generate AI reasoning for including an item in today's focus
    private func generateAIReasoning(for task: LifeTask, intelligence: PriorityIntelligence) async -> String {
        // Use existing contextual information to generate reasoning
        var reasons: [String] = []
        
        // Due date reasoning
        if let dueDateString = task.dueDate, let dueDate = ISO8601DateFormatter().date(from: dueDateString) {
            let daysDiff = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            
            if daysDiff <= 0 {
                reasons.append("Due today or overdue")
            } else if daysDiff <= 1 {
                reasons.append("Due tomorrow - good to finish early")
            } else if daysDiff <= 3 {
                reasons.append("Due soon, start making progress")
            }
        }
        
        // Priority reasoning
        if intelligence.overallScore > 0.8 {
            reasons.append("High AI priority score")
        }
        
        // Focus task reasoning
        if task.isFocus {
            reasons.append("Marked as focus task")
        }
        
        // Pattern-based reasoning
        if let mood = currentMoodAssessment {
            switch mood.energyLevel {
            case .high:
                if await analyzeTaskComplexity(task) == .complex {
                    reasons.append("Complex task matches your high energy")
                }
            case .low:
                if await analyzeTaskComplexity(task) == .simple {
                    reasons.append("Simple task good for current energy level")
                }
            default:
                break
            }
        }
        
        // Default reasoning
        if reasons.isEmpty {
            reasons.append("Part of your active projects")
        }
        
        return reasons.joined(separator: ", ")
    }
    
    /// Analyze task energy requirement
    private func analyzeTaskEnergyRequirement(_ task: LifeTask) async -> EnergyLevel {
        // Use task complexity and type to determine energy requirement
        let complexity = await analyzeTaskComplexity(task)
        
        switch complexity {
        case .complex:
            return .high
        case .medium:
            return .medium
        case .simple:
            return .low
        }
    }
    
    /// Analyze task cognitive complexity
    private func analyzeTaskComplexity(_ task: LifeTask) async -> ComplexityLevel {
        let content = "\(task.title) \(task.description ?? "")"
        
        // Simple heuristics for complexity analysis
        // In production, this could use LLM analysis
        
        if content.localizedCaseInsensitiveContains("design") ||
           content.localizedCaseInsensitiveContains("architecture") ||
           content.localizedCaseInsensitiveContains("strategy") ||
           content.localizedCaseInsensitiveContains("plan") {
            return .complex
        }
        
        if content.localizedCaseInsensitiveContains("review") ||
           content.localizedCaseInsensitiveContains("update") ||
           content.localizedCaseInsensitiveContains("fix") ||
           content.localizedCaseInsensitiveContains("implement") {
            return .medium
        }
        
        // Simple tasks: organize, call, send, buy, etc.
        return .simple
    }
    
    /// Analyze if task can be done offline
    private func analyzeOfflineCapability(_ task: LifeTask) async -> Bool {
        let content = "\(task.title) \(task.description ?? "")".lowercased()
        
        // Tasks that typically require internet
        let onlineKeywords = ["email", "call", "meeting", "research", "download", "upload", "sync"]
        
        for keyword in onlineKeywords {
            if content.contains(keyword) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Mapping Utilities
    
    private func mapToFocusPriority(_ taskPriority: TaskPriority, aiScore: Double) -> FocusPriority {
        // Combine task priority with AI score for focus priority
        switch taskPriority {
        case .critical:
            return .critical
        case .urgent:
            return .critical
        case .high:
            return aiScore > 0.8 ? .critical : .high
        case .medium:
            return aiScore > 0.7 ? .high : .medium
        case .low:
            return aiScore > 0.6 ? .medium : .low
        }
    }
    
    private func calculateUrgencyLevel(for task: LifeTask) -> UrgencyLevel {
        guard let dueDateString = task.dueDate,
              let dueDate = ISO8601DateFormatter().date(from: dueDateString) else {
            return .noDeadline
        }
        
        let daysDiff = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        
        switch daysDiff {
        case ...0:
            return .urgent
        case 1...2:
            return .soonDue
        case 3...7:
            return .medium
        default:
            return .flexible
        }
    }
    
    private func mapToFocusStatus(_ taskStatus: TaskStatus) -> FocusItemStatus {
        switch taskStatus {
        case .inbox, .todo:
            return .pending
        case .inProgress:
            return .inProgress
        case .done, .completed:
            return .completed
        case .cancelled:
            return .cancelled
        }
    }
    
    private func calculateFocusBlocks(duration: Int) -> Int {
        // Assume 45-minute focus blocks
        let focusBlockSize = 45
        return max(1, (duration + focusBlockSize - 1) / focusBlockSize)
    }
    
    // MARK: - Filtering and Search
    
    /// Apply filters to focus items
    func applyFilters(_ filters: Set<FocusFilter>) {
        activeFocusFilters = filters
        
        if filters.isEmpty {
            filteredFocusItems = todaysFocusItems
        } else {
            filteredFocusItems = todaysFocusItems.filter { item in
                // Item must match ALL active filters (AND logic)
                return filters.allSatisfy { filter in
                    filter.criteria.matches(item)
                }
            }
        }
        
        logger.debug("FOCUS_VIEW: Applied \(filters.count) filters, showing \(filteredFocusItems.count) items")
    }
    
    /// Apply default filters for initial view
    private func applyDefaultFilters() {
        // Start with "AI Suggested" filter if available
        if let aiFilter = availableFilters.first(where: { $0.criteria.includeAISuggested == true }) {
            applyFilters([aiFilter])
        } else {
            applyFilters([])
        }
    }
    
    /// Clear all active filters
    func clearFilters() {
        applyFilters([])
    }
    
    // MARK: - Mood Analysis & AI Recommendations
    
    /// Start automatic mood analysis
    private func startMoodAnalysis() {
        // Perform initial analysis
        Task {
            await performMoodAnalysis()
        }
        
        // Schedule periodic analysis
        moodAnalysisTimer = Timer.scheduledTimer(withTimeInterval: moodAnalysisInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.performMoodAnalysis()
            }
        }
    }
    
    /// Perform AI mood analysis based on recent activity
    private func performMoodAnalysis() async {
        logger.debug("FOCUS_VIEW: Performing mood analysis")
        
        do {
            // Get recent context and activity
            let recentContext = await contextMemory.getRecentContext(hours: 24)
            let completionPatterns = await analyzeRecentCompletionPatterns()
            
            // Generate mood assessment using AI
            let assessment = await generateMoodAssessment(
                context: [recentContext],
                patterns: completionPatterns
            )
            
            await MainActor.run {
                currentMoodAssessment = assessment
            }
            
            logger.success("FOCUS_VIEW: Mood analysis complete - \(assessment.overallMood.displayName)")
            
        } catch {
            logger.error("FOCUS_VIEW: Mood analysis failed: \(error)")
        }
    }
    
    /// Analyze recent task completion patterns for mood insights
    private func analyzeRecentCompletionPatterns() async -> [String: Any] {
        do {
            let recentTasks = try await taskRepository.fetchRecentlyCompletedTasks(days: 3)
            let totalTasks = try await taskRepository.fetchTasksCreatedInLast(days: 3)
            
            let completionRate = totalTasks.count > 0 ? Double(recentTasks.count) / Double(totalTasks.count) : 0.0
            let avgCompletionTime = calculateAverageCompletionTime(recentTasks)
            
            return [
                "completion_rate": completionRate,
                "avg_completion_time": avgCompletionTime,
                "completed_count": recentTasks.count,
                "total_count": totalTasks.count
            ]
            
        } catch {
            logger.error("FOCUS_VIEW: Failed to analyze completion patterns: \(error)")
            return [:]
        }
    }
    
    /// Generate AI mood assessment
    private func generateMoodAssessment(
        context: [Any],
        patterns: [String: Any]
    ) async -> DailyMoodAssessment {
        
        // For now, use heuristic analysis
        // In production, this would use LLM analysis of context and patterns
        
        let completionRate = patterns["completion_rate"] as? Double ?? 0.0
        let completedCount = patterns["completed_count"] as? Int ?? 0
        
        // Determine mood based on productivity patterns
        let mood: MoodLevel
        let energy: EnergyLevel
        let stress: StressLevel
        let focus: FocusCapacity
        
        if completionRate > 0.8 && completedCount > 3 {
            mood = .veryPositive
            energy = .high
            stress = .low
            focus = .excellent
        } else if completionRate > 0.6 && completedCount > 2 {
            mood = .positive
            energy = .medium
            stress = .moderate
            focus = .good
        } else if completionRate > 0.4 {
            mood = .neutral
            energy = .medium
            stress = .moderate
            focus = .average
        } else {
            mood = .negative
            energy = .low
            stress = .high
            focus = .poor
        }
        
        let insights = generateMoodInsights(
            mood: mood,
            energy: energy,
            completionRate: completionRate
        )
        
        let suggestions = generateMoodSuggestions(
            mood: mood,
            energy: energy,
            focus: focus
        )
        
        return DailyMoodAssessment(
            date: ISO8601DateFormatter().string(from: Date()).prefix(10).description,
            overallMood: mood,
            energyLevel: energy,
            stressLevel: stress,
            focusCapacity: focus,
            confidence: 0.7,
            dataSource: .completionPatterns,
            insights: insights,
            suggestedActions: suggestions
        )
    }
    
    /// Generate mood insights
    private func generateMoodInsights(
        mood: MoodLevel,
        energy: EnergyLevel,
        completionRate: Double
    ) -> [MoodInsight] {
        
        var insights: [MoodInsight] = []
        
        if completionRate > 0.8 {
            insights.append(MoodInsight(
                category: .productivity,
                insight: "High completion rate indicates strong productivity today",
                confidence: 0.8,
                actionable: false
            ))
        }
        
        if energy == .high {
            insights.append(MoodInsight(
                category: .recommendations,
                insight: "High energy - good time for complex tasks",
                confidence: 0.7,
                actionable: true
            ))
        }
        
        if mood == .negative || mood == .veryNegative {
            insights.append(MoodInsight(
                category: .wellbeing,
                insight: "Lower mood detected - consider simpler tasks",
                confidence: 0.6,
                actionable: true
            ))
        }
        
        return insights
    }
    
    /// Generate mood-based suggestions
    private func generateMoodSuggestions(
        mood: MoodLevel,
        energy: EnergyLevel,
        focus: FocusCapacity
    ) -> [String] {
        
        var suggestions: [String] = []
        
        switch energy {
        case .high:
            suggestions.append("Tackle complex or creative tasks")
            suggestions.append("Good time for deep work sessions")
        case .medium:
            suggestions.append("Mix of focused and routine tasks")
            suggestions.append("Consider moderate complexity work")
        case .low:
            suggestions.append("Focus on simple, low-effort tasks")
            suggestions.append("Good time for organizing or planning")
        }
        
        if focus == .poor || focus == .veryPoor {
            suggestions.append("Take breaks between tasks")
            suggestions.append("Try shorter focus sessions")
        }
        
        return suggestions
    }
    
    /// Generate AI recommendations for focus optimization
    private func generateAIRecommendations(for items: [FocusItem]) async -> [AIRecommendation] {
        var recommendations: [AIRecommendation] = []
        
        // Time optimization recommendation
        let totalTime = items.compactMap(\.estimatedDuration).reduce(0, +)
        if totalTime > 8 * 60 { // More than 8 hours
            recommendations.append(AIRecommendation(
                type: .timeOptimization,
                title: "Consider reducing today's workload",
                description: "You have \(totalTime/60) hours of estimated work",
                confidence: 0.8,
                reasoning: "Overloaded schedule may lead to incomplete tasks",
                actionable: true,
                relatedItemIds: items.suffix(3).map(\.id)
            ))
        }
        
        // Energy matching recommendation
        if let mood = currentMoodAssessment {
            let highEnergyTasks = items.filter { $0.energyLevel == .high }
            
            if mood.energyLevel == .low && highEnergyTasks.count > 2 {
                recommendations.append(AIRecommendation(
                    type: .energyMatching,
                    title: "Energy mismatch detected",
                    description: "Consider deferring high-energy tasks",
                    confidence: 0.7,
                    reasoning: "Your current energy level is low but you have complex tasks scheduled",
                    actionable: true,
                    relatedItemIds: highEnergyTasks.prefix(2).map(\.id)
                ))
            }
        }
        
        // Task grouping recommendation
        let workTasks = items.filter { $0.workPersonal == .work }
        let personalTasks = items.filter { $0.workPersonal == .personal }
        
        if workTasks.count > 0 && personalTasks.count > 0 {
            recommendations.append(AIRecommendation(
                type: .taskGrouping,
                title: "Consider batching similar tasks",
                description: "Group work and personal tasks to reduce context switching",
                confidence: 0.6,
                reasoning: "Batching similar tasks improves focus and efficiency",
                actionable: true
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Focus Item Actions
    
    /// Complete a focus item
    func completeFocusItem(_ itemId: UUID) async {
        guard let index = todaysFocusItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        var item = todaysFocusItems[index]
        item = FocusItem(
            sourceId: item.sourceId,
            sourceType: item.sourceType,
            title: item.title,
            description: item.description,
            estimatedDuration: item.estimatedDuration,
            priority: item.priority,
            urgency: item.urgency,
            aiReason: item.aiReason,
            dueDate: item.dueDate,
            workPersonal: item.workPersonal,
            projectId: item.projectId,
            areaId: item.areaId,
            status: .completed,
            energyLevel: item.energyLevel,
            complexity: item.complexity,
            canBeDoneOffline: item.canBeDoneOffline,
            estimatedFocusBlocks: item.estimatedFocusBlocks
        )
        
        todaysFocusItems[index] = item
        
        // Update underlying task
        await updateSourceTask(item.sourceId, status: .completed)
        
        // Update session stats
        sessionStats.completedItems += 1
        sessionStats.totalTimeSpent += item.estimatedDuration ?? 30
        
        // Check for achievements
        await checkForAchievements()
        
        // Refresh filtered items
        applyFilters(activeFocusFilters)
        
        logger.success("FOCUS_VIEW: Completed item: \(item.title)")
    }
    
    /// Defer a focus item to tomorrow
    func deferFocusItem(_ itemId: UUID) async {
        guard let index = todaysFocusItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        let item = todaysFocusItems[index]
        
        // Remove from today's list
        todaysFocusItems.remove(at: index)
        
        // Update session stats
        sessionStats.deferredItems += 1
        
        // Reschedule underlying task to tomorrow
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        await rescheduleSourceTask(item.sourceId, to: tomorrow)
        
        // Refresh filtered items
        applyFilters(activeFocusFilters)
        
        logger.info("FOCUS_VIEW: Deferred item to tomorrow: \(item.title)")
    }
    
    /// Perform batch action on selected items
    func performBatchAction(_ action: BatchActionType) async {
        let selectedItems = todaysFocusItems.filter { selectedFocusItems.contains($0.id) }
        
        for item in selectedItems {
            switch action {
            case .complete:
                await completeFocusItem(item.id)
            case .defer:
                await deferFocusItem(item.id)
            case .increasePriority:
                await adjustItemPriority(item.id, increase: true)
            case .decreasePriority:
                await adjustItemPriority(item.id, increase: false)
            case .delete:
                await removeFocusItem(item.id)
            case .reschedule:
                // This would open a reschedule dialog
                break
            }
        }
        
        // Clear selection
        selectedFocusItems.removeAll()
        
        logger.info("FOCUS_VIEW: Performed batch action \(action) on \(selectedItems.count) items")
    }
    
    // MARK: - Session Monitoring
    
    /// Start monitoring focus session for real-time updates
    private func startSessionMonitoring() {
        focusSessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.updateSessionStats()
                await self.checkForNewRecommendations()
            }
        }
    }
    
    /// Update session statistics
    private func updateSessionStats() async {
        sessionStats.totalItems = todaysFocusItems.count
        sessionStats.focusScore = calculateFocusScore()
        
        await saveFocusSession()
    }
    
    /// Calculate focus score based on completion patterns
    private func calculateFocusScore() -> Double {
        guard sessionStats.totalItems > 0 else { return 0.0 }
        
        let completionRate = sessionStats.completionRate
        let timeEfficiency = calculateTimeEfficiency()
        
        return (completionRate * 0.6) + (timeEfficiency * 0.4)
    }
    
    /// Calculate time efficiency
    private func calculateTimeEfficiency() -> Double {
        // Simple efficiency calculation
        // In production, this would consider actual vs estimated time
        return min(1.0, Double(sessionStats.completedItems) / max(1.0, Double(sessionStats.totalItems)))
    }
    
    /// Check for new AI recommendations
    private func checkForNewRecommendations() async {
        let newRecommendations = await generateAIRecommendations(for: todaysFocusItems)
        
        // Only add truly new recommendations
        let existingTypes = Set(aiRecommendations.map(\.type))
        let newUniqueRecs = newRecommendations.filter { !existingTypes.contains($0.type) }
        
        if !newUniqueRecs.isEmpty {
            aiRecommendations.append(contentsOf: newUniqueRecs)
            logger.info("FOCUS_VIEW: Added \(newUniqueRecs.count) new recommendations")
        }
    }
    
    /// Check for achievements and create celebration banners
    private func checkForAchievements() async {
        var newBadges: [AchievementBadge] = []
        
        // Completion streak achievement
        if sessionStats.completedItems > 0 && sessionStats.completedItems % 5 == 0 {
            newBadges.append(AchievementBadge(
                type: .completion,
                title: "Focus Master",
                description: "Completed \(sessionStats.completedItems) tasks today!",
                icon: "star.circle.fill"
            ))
        }
        
        // Efficiency achievement
        if sessionStats.completionRate >= 0.9 && sessionStats.totalItems >= 5 {
            newBadges.append(AchievementBadge(
                type: .efficiency,
                title: "Efficiency Expert",
                description: "90%+ completion rate with 5+ tasks!",
                icon: "bolt.circle.fill"
            ))
        }
        
        sessionStats.achievementBadges.append(contentsOf: newBadges)
        
        if !newBadges.isEmpty {
            // Trigger celebration notification
            await proactiveNotifications.sendAchievementNotification(newBadges.first!.title)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSourceTask(_ taskId: UUID, status: TaskStatus) async {
        do {
            guard let task = try await taskRepository.fetchTask(id: taskId) else { return }
            
            let updatedTask = LifeTask(
                id: task.id,
                blobId: task.blobId,
                title: task.title,
                description: task.description,
                priority: task.priority,
                status: status,
                dueDate: task.dueDate,
                estimatedDuration: task.estimatedDuration,
                workPersonal: task.workPersonal,
                projectId: task.projectId,
                areaId: task.areaId,
                resourceId: task.resourceId,
                isFocus: task.isFocus,
                isArchived: task.isArchived,
                createdAt: task.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                completedAt: status == .completed ? ISO8601DateFormatter().string(from: Date()) : task.completedAt,
                archivedAt: task.archivedAt,
                deletedAt: task.deletedAt
            )
            
            _ = try await taskRepository.updateTask(updatedTask)
            logger.debug("FOCUS_VIEW: Updated source task status: \(taskId)")
            
        } catch {
            logger.error("FOCUS_VIEW: Failed to update source task: \(error)")
        }
    }
    
    private func rescheduleSourceTask(_ taskId: UUID, to date: Date) async {
        do {
            guard let task = try await taskRepository.fetchTask(id: taskId) else { return }
            
            let newDueDateString = ISO8601DateFormatter().string(from: date)
            let updatedTask = LifeTask(
                id: task.id,
                blobId: task.blobId,
                title: task.title,
                description: task.description,
                priority: task.priority,
                status: task.status,
                dueDate: newDueDateString,
                estimatedDuration: task.estimatedDuration,
                workPersonal: task.workPersonal,
                projectId: task.projectId,
                areaId: task.areaId,
                resourceId: task.resourceId,
                isFocus: task.isFocus,
                isArchived: task.isArchived,
                createdAt: task.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                completedAt: task.completedAt,
                archivedAt: task.archivedAt,
                deletedAt: task.deletedAt
            )
            
            _ = try await taskRepository.updateTask(updatedTask)
            logger.debug("FOCUS_VIEW: Rescheduled source task: \(taskId)")
            
        } catch {
            logger.error("FOCUS_VIEW: Failed to reschedule source task: \(error)")
        }
    }
    
    private func adjustItemPriority(_ itemId: UUID, increase: Bool) async {
        // Implementation for priority adjustment
        logger.debug("FOCUS_VIEW: Priority adjustment not yet implemented")
    }
    
    private func removeFocusItem(_ itemId: UUID) async {
        todaysFocusItems.removeAll { $0.id == itemId }
        applyFilters(activeFocusFilters)
        logger.debug("FOCUS_VIEW: Removed focus item: \(itemId)")
    }
    
    private func calculateAverageCompletionTime(_ tasks: [LifeTask]) -> Double {
        let completedTasks = tasks.compactMap { task -> Double? in
            guard let completedString = task.completedAt,
                  let created = ISO8601DateFormatter().date(from: task.createdAt),
                  let completed = ISO8601DateFormatter().date(from: completedString) else {
                return nil
            }
            return completed.timeIntervalSince(created) / 3600 // Hours
        }
        
        guard !completedTasks.isEmpty else { return 0.0 }
        return completedTasks.reduce(0, +) / Double(completedTasks.count)
    }
    
    // MARK: - Public Interface Methods
    
    /// Load today's focus items
    func loadTodaysFocus() {
        Task {
            isLoading = true
            await setupFocusSession()
            isLoading = false
        }
    }
    
    /// Refresh focus session with latest data
    func refreshFocusSession() {
        Task {
            isLoading = true
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            createNewFocusSession(for: String(today))
            isLoading = false
        }
    }
    
    /// Get focus items matching a specific filter
    func getFocusItems(matching filter: FocusFilter) -> [FocusItem] {
        return todaysFocusItems.filter { filter.criteria.matches($0) }
    }
    
    /// Toggle selection of focus item
    func toggleItemSelection(_ itemId: UUID) {
        if selectedFocusItems.contains(itemId) {
            selectedFocusItems.remove(itemId)
        } else {
            selectedFocusItems.insert(itemId)
        }
    }
    
    /// Clear all selections
    func clearSelection() {
        selectedFocusItems.removeAll()
    }
    
    /// Create default priority intelligence when none is available
    private func createDefaultIntelligence() -> PriorityIntelligence {
        return PriorityIntelligence(
            taskId: UUID(),
            intelligenceScore: 0.5,
            urgencyScore: 0.5,
            importanceScore: 0.5,
            contextScore: 0.5,
            userPatternScore: 0.5,
            reasoningFactors: ["default"],
            confidence: 0.5
        )
    }
}