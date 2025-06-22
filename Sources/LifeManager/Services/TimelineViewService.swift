import Foundation
import SwiftUI
import Combine

/// Timeline View Service
/// Goal-centric historical and forward-looking view with AI-powered insights
/// Manages goals, milestones, ripple effects, and version history for long-term achievement tracking
@MainActor
class TimelineViewService: ObservableObject {
    
    static let shared = TimelineViewService()
    
    // MARK: - Dependencies
    
    private let taskRepository = TaskRepository()
    private let projectRepository = ProjectRepository()
    private let areaRepository = AreaRepository()
    private let contextMemory = ContextMemoryService.shared
    private let intelligentRescheduling = IntelligentReschedulingService.shared
    private let priorityEngine = PriorityIntelligenceEngine.shared
    private let llmService = LLMServiceCoordinator.shared
    private let logger = Logger.shared
    
    // MARK: - Published State
    
    @Published var goals: [Goal] = []
    @Published var selectedGoal: Goal?
    @Published var timelineEvents: [TimelineEvent] = []
    @Published var milestones: [Milestone] = []
    @Published var rippleEffects: [RippleEffect] = []
    @Published var timelineInsights: [TimelineInsight] = []
    @Published var versionHistory: [TimelineVersionHistory] = []
    @Published var progressSummary: ProgressSummary?
    @Published var viewConfig = TimelineViewConfig.default
    @Published var isLoading = false
    
    // MARK: - Private State
    
    private var goalsUpdateTimer: Timer?
    private var rippleAnalysisTimer: Timer?
    private let insightGenerationInterval: TimeInterval = 3600 // 1 hour
    private let rippleAnalysisInterval: TimeInterval = 1800 // 30 minutes
    
    // MARK: - Initialization
    
    private init() {
        logger.info("TIMELINE_VIEW: Service initialized")
        Task {
            await loadInitialData()
            startPeriodicUpdates()
        }
    }
    
    deinit {
        goalsUpdateTimer?.invalidate()
        rippleAnalysisTimer?.invalidate()
    }
    
    // MARK: - Data Loading
    
    /// Load initial timeline data
    func loadInitialData() async {
        isLoading = true
        
        do {
            // Load projects and convert to goals
            await loadGoals()
            
            // Load timeline events and milestones
            if let firstGoal = goals.first {
                await selectGoal(firstGoal)
            }
            
            // Generate initial insights
            await generateTimelineInsights()
            
            // Create progress summary
            await updateProgressSummary()
            
            logger.success("TIMELINE_VIEW: Initial data loaded with \(goals.count) goals")
            
        } catch {
            logger.error("TIMELINE_VIEW: Failed to load initial data: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load goals from projects
    private func loadGoals() async {
        do {
            let projects = try await projectRepository.fetchProjects()
            var loadedGoals: [Goal] = []
            
            for project in projects {
                let goal = await convertProjectToGoal(project)
                loadedGoals.append(goal)
            }
            
            // Sort goals by priority and status
            loadedGoals.sort { goal1, goal2 in
                if goal1.priority.sortOrder != goal2.priority.sortOrder {
                    return goal1.priority.sortOrder < goal2.priority.sortOrder
                }
                return goal1.status.rawValue < goal2.status.rawValue
            }
            
            goals = loadedGoals
            logger.debug("TIMELINE_VIEW: Loaded \(loadedGoals.count) goals")
            
        } catch {
            logger.error("TIMELINE_VIEW: Failed to load goals: \(error)")
        }
    }
    
    /// Convert a Project to a Goal with timeline-specific enhancements
    private func convertProjectToGoal(_ project: Project) async -> Goal {
        // Calculate progress based on associated tasks
        let progress = await calculateProjectProgress(project.id)
        
        // Determine goal category from project properties
        let category = inferGoalCategory(from: project)
        
        // Calculate risk level and velocity
        let riskLevel = await calculateGoalRisk(for: project)
        let velocityTrend = await calculateVelocityTrend(for: project)
        
        // Get milestones for this goal
        let goalMilestones = await loadMilestonesForProject(project.id)
        
        // Calculate predicted completion date
        let predictedCompletion = await predictCompletionDate(for: project, progress: progress)
        
        return Goal(
            projectId: project.id,
            name: project.name,
            description: project.description,
            vision: await extractProjectVision(project),
            status: mapProjectStatusToGoal(project.status),
            priority: mapProjectPriorityToGoal(project.status, project: project),
            category: category,
            workPersonal: project.workPersonal,
            startDate: ISO8601DateFormatter().date(from: project.createdAt),
            targetDate: project.dueDate.flatMap { ISO8601DateFormatter().date(from: $0) },
            estimatedDuration: await calculateEstimatedDuration(for: project),
            areaId: project.areaId
        )
    }
    
    /// Select a goal and load its detailed data
    func selectGoal(_ goal: Goal) async {
        selectedGoal = goal
        
        await loadTimelineEvents(for: goal)
        await loadMilestones(for: goal)
        await detectRippleEffects(for: goal)
        await loadVersionHistory(for: goal)
        
        logger.debug("TIMELINE_VIEW: Selected goal: \(goal.name)")
    }
    
    /// Load timeline events for a specific goal
    private func loadTimelineEvents(for goal: Goal) async {
        var events: [TimelineEvent] = []
        
        do {
            // Load task completion events
            let projectTasks = try await taskRepository.fetchTasksForProject(goal.projectId)
            
            for task in projectTasks {
                if task.status == .completed, let completedAtString = task.completedAt {
                    let event = TimelineEvent(
                        goalId: goal.id,
                        type: .taskCompleted,
                        title: "Completed: \(task.title)",
                        description: task.description,
                        date: ISO8601DateFormatter().date(from: completedAtString) ?? Date(),
                        impact: .positive,
                        relatedItemId: task.id,
                        relatedItemType: "task",
                        createdBy: .user
                    )
                    events.append(event)
                }
            }
            
            // Add milestone events
            for milestone in milestones.filter({ $0.goalId == goal.id }) {
                if milestone.status == .completed, let completedDate = milestone.completedDate {
                    let event = TimelineEvent(
                        goalId: goal.id,
                        type: .milestoneCompleted,
                        title: "Milestone: \(milestone.name)",
                        description: milestone.description,
                        date: completedDate,
                        impact: .positive,
                        relatedItemId: milestone.id,
                        relatedItemType: "milestone",
                        createdBy: .system
                    )
                    events.append(event)
                }
            }
            
            // Sort events by date
            events.sort { $0.date < $1.date }
            timelineEvents = events
            
            logger.debug("TIMELINE_VIEW: Loaded \(events.count) timeline events for goal")
            
        } catch {
            logger.error("TIMELINE_VIEW: Failed to load timeline events: \(error)")
        }
    }
    
    /// Load milestones for a specific goal
    private func loadMilestones(for goal: Goal) async {
        let goalMilestones = await loadMilestonesForProject(goal.projectId)
        milestones = goalMilestones.filter { $0.goalId == goal.id }
        
        logger.debug("TIMELINE_VIEW: Loaded \(milestones.count) milestones for goal")
    }
    
    /// Load milestones for a project
    private func loadMilestonesForProject(_ projectId: UUID) async -> [Milestone] {
        // For now, generate default milestones based on project tasks
        // In production, these would be stored and managed separately
        
        do {
            let projectTasks = try await taskRepository.fetchTasksForProject(projectId)
            var milestones: [Milestone] = []
            
            // Create milestone for every 5 completed tasks
            let completedTasks = projectTasks.filter { $0.status == .completed }
            if completedTasks.count >= 5 {
                let milestone = Milestone(
                    goalId: UUID(), // Will be updated when goal is created
                    name: "First 5 Tasks Complete",
                    description: "Completed initial set of project tasks",
                    type: .checkpoint,
                    estimatedEffort: 10
                )
                milestones.append(milestone)
            }
            
            // Create milestone for project halfway point
            if projectTasks.count > 0 {
                let progress = Double(completedTasks.count) / Double(projectTasks.count)
                if progress >= 0.5 {
                    let milestone = Milestone(
                        goalId: UUID(),
                        name: "Halfway Point",
                        description: "Reached 50% completion",
                        type: .checkpoint,
                        estimatedEffort: 20
                    )
                    milestones.append(milestone)
                }
            }
            
            return milestones
            
        } catch {
            logger.error("TIMELINE_VIEW: Failed to load milestones for project: \(error)")
            return []
        }
    }
    
    // MARK: - Ripple Effect Analysis
    
    /// Detect ripple effects for a goal
    private func detectRippleEffects(for goal: Goal) async {
        var effects: [RippleEffect] = []
        
        // Analyze dependency impacts
        effects.append(contentsOf: await analyzeDependencyImpacts(for: goal))
        
        // Analyze resource conflicts
        effects.append(contentsOf: await analyzeResourceConflicts(for: goal))
        
        // Analyze timeline delays
        effects.append(contentsOf: await analyzeTimelineDelays(for: goal))
        
        rippleEffects = effects
        logger.debug("TIMELINE_VIEW: Detected \(effects.count) ripple effects for goal")
    }
    
    /// Analyze dependency impacts
    private func analyzeDependencyImpacts(for goal: Goal) async -> [RippleEffect] {
        var effects: [RippleEffect] = []
        
        // Check if this goal's delays affect dependent goals
        if goal.status == .active {
            // Simulate dependency analysis
            // In production, this would check actual goal dependencies
            
            if let targetDate = goal.targetDate, targetDate < Date() {
                // Goal is overdue, might affect dependent goals
                let effect = RippleEffect(
                    sourceGoalId: goal.id,
                    affectedGoalId: UUID(), // Would be actual dependent goal
                    changeType: .delayImpact,
                    severity: .medium,
                    description: "Delay in \(goal.name) may affect dependent goals",
                    suggestedActions: [
                        RippleAction(
                            type: .reschedule,
                            title: "Reschedule Dependent Goals",
                            description: "Adjust timelines for goals that depend on this one",
                            estimatedImpact: "2-3 days delay",
                            autoExecutable: true
                        )
                    ],
                    autoResolvable: true,
                    confidence: 0.7
                )
                effects.append(effect)
            }
        }
        
        return effects
    }
    
    /// Analyze resource conflicts
    private func analyzeResourceConflicts(for goal: Goal) async -> [RippleEffect] {
        var effects: [RippleEffect] = []
        
        // Check for overlapping resource usage
        // This would analyze if multiple goals are competing for the same resources
        
        if goal.priority == .high {
            let effect = RippleEffect(
                sourceGoalId: goal.id,
                affectedGoalId: UUID(), // Would be conflicting goal
                changeType: .resourceConflict,
                severity: .low,
                description: "High priority goal may require resource reallocation",
                suggestedActions: [
                    RippleAction(
                        type: .reprioritize,
                        title: "Adjust Goal Priorities",
                        description: "Lower priority of competing goals",
                        estimatedImpact: "1-2 weeks delay for other goals",
                        autoExecutable: false
                    )
                ],
                autoResolvable: false,
                confidence: 0.6
            )
            effects.append(effect)
        }
        
        return effects
    }
    
    /// Analyze timeline delays
    private func analyzeTimelineDelays(for goal: Goal) async -> [RippleEffect] {
        var effects: [RippleEffect] = []
        
        // Analyze if goal delays create cascade effects
        if let targetDate = goal.targetDate, 
           let predictedDate = goal.predictedCompletionDate,
           predictedDate > targetDate {
            
            let delayDays = Calendar.current.dateComponents([.day], from: targetDate, to: predictedDate).day ?? 0
            
            if delayDays > 7 {
                let effect = RippleEffect(
                    sourceGoalId: goal.id,
                    affectedGoalId: goal.id, // Self-impact
                    changeType: .delayImpact,
                    severity: .high,
                    description: "Goal is \(delayDays) days behind schedule",
                    suggestedActions: [
                        RippleAction(
                            type: .adjustScope,
                            title: "Reduce Goal Scope",
                            description: "Focus on core deliverables to meet deadline",
                            estimatedImpact: "May reduce final outcome quality",
                            autoExecutable: false
                        ),
                        RippleAction(
                            type: .addBuffer,
                            title: "Add Buffer Time",
                            description: "Extend deadline with buffer for completion",
                            estimatedImpact: "Extends timeline by \(delayDays) days",
                            autoExecutable: true
                        )
                    ],
                    autoResolvable: false,
                    confidence: 0.8
                )
                effects.append(effect)
            }
        }
        
        return effects
    }
    
    // MARK: - AI Insights Generation
    
    /// Generate AI insights for timeline analysis
    func generateTimelineInsights() async {
        var insights: [TimelineInsight] = []
        
        // Progress insights
        insights.append(contentsOf: await generateProgressInsights())
        
        // Pattern insights
        insights.append(contentsOf: await generatePatternInsights())
        
        // Risk insights
        insights.append(contentsOf: await generateRiskInsights())
        
        // Opportunity insights
        insights.append(contentsOf: await generateOpportunityInsights())
        
        // Prediction insights
        insights.append(contentsOf: await generatePredictionInsights())
        
        timelineInsights = insights
        logger.success("TIMELINE_VIEW: Generated \(insights.count) AI insights")
    }
    
    /// Generate progress-related insights
    private func generateProgressInsights() async -> [TimelineInsight] {
        var insights: [TimelineInsight] = []
        
        let activeGoals = goals.filter { $0.status == .active }
        let onTrackGoals = activeGoals.filter { $0.onTrackScore > 0.7 }
        
        if !activeGoals.isEmpty {
            let onTrackPercentage = Double(onTrackGoals.count) / Double(activeGoals.count) * 100
            
            let insight = TimelineInsight(
                type: .progress,
                category: .progress,
                title: "Goal Progress Status",
                description: "Overall goal achievement tracking",
                insight: "\(Int(onTrackPercentage))% of your active goals are on track for completion",
                confidence: 0.9,
                actionable: false,
                suggestedActions: onTrackPercentage < 70 ? ["Review and adjust struggling goals", "Consider reducing scope for at-risk goals"] : []
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Generate pattern-related insights
    private func generatePatternInsights() async -> [TimelineInsight] {
        var insights: [TimelineInsight] = []
        
        // Analyze completion patterns
        let completedGoals = goals.filter { $0.status == .completed }
        
        if completedGoals.count >= 3 {
            // Calculate average completion time vs estimated
            let completionAccuracy = calculateCompletionAccuracy(completedGoals)
            
            let insight = TimelineInsight(
                type: .patterns,
                category: .patterns,
                title: "Completion Pattern Analysis",
                description: "Historical goal completion accuracy",
                insight: completionAccuracy > 0 ? 
                    "You typically complete goals \(Int(abs(completionAccuracy)))% \(completionAccuracy > 0 ? "faster" : "slower") than estimated" :
                    "Your goal completion timing is very accurate",
                confidence: 0.8,
                actionable: true,
                suggestedActions: completionAccuracy < -20 ? 
                    ["Consider more realistic time estimates", "Add buffer time to future goals"] :
                    ["Continue current estimation approach"]
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Generate risk-related insights
    private func generateRiskInsights() async -> [TimelineInsight] {
        var insights: [TimelineInsight] = []
        
        let highRiskGoals = goals.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
        
        if !highRiskGoals.isEmpty {
            let insight = TimelineInsight(
                goalId: highRiskGoals.first?.id,
                type: .risks,
                category: .risks,
                title: "High Risk Goals Detected",
                description: "Goals requiring immediate attention",
                insight: "\(highRiskGoals.count) goal(s) are at high risk of missing deadlines",
                confidence: 0.85,
                actionable: true,
                suggestedActions: [
                    "Review resource allocation for at-risk goals",
                    "Consider scope reduction or deadline extension",
                    "Increase monitoring frequency for these goals"
                ]
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Generate opportunity-related insights
    private func generateOpportunityInsights() async -> [TimelineInsight] {
        var insights: [TimelineInsight] = []
        
        let acceleratingGoals = goals.filter { $0.velocityTrend == .accelerating }
        
        if !acceleratingGoals.isEmpty {
            let insight = TimelineInsight(
                type: .opportunities,
                category: .opportunities,
                title: "Acceleration Opportunities",
                description: "Goals with positive momentum",
                insight: "\(acceleratingGoals.count) goal(s) are accelerating and may finish early",
                confidence: 0.7,
                actionable: true,
                suggestedActions: [
                    "Consider expanding scope for accelerating goals",
                    "Reallocate resources from slower goals",
                    "Plan follow-up goals to maintain momentum"
                ]
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Generate prediction-related insights
    private func generatePredictionInsights() async -> [TimelineInsight] {
        var insights: [TimelineInsight] = []
        
        // Predict which goals will complete this month
        let thisMonthCompletions = goals.filter { goal in
            guard let predicted = goal.predictedCompletionDate else { return false }
            let endOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.end ?? Date()
            return predicted <= endOfMonth && goal.status == .active
        }
        
        if !thisMonthCompletions.isEmpty {
            let insight = TimelineInsight(
                type: .predictions,
                category: .predictions,
                title: "This Month's Predictions",
                description: "Goals likely to complete soon",
                insight: "Predicted to complete \(thisMonthCompletions.count) goal(s) this month",
                confidence: 0.75,
                actionable: true,
                suggestedActions: [
                    "Focus on completion for near-finish goals",
                    "Prepare celebration or review activities",
                    "Plan next phase or follow-up goals"
                ]
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    // MARK: - Progress Summary
    
    /// Update progress summary for current time period
    func updateProgressSummary() async {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        do {
            // Get tasks completed this week
            let weeklyTasks = try await taskRepository.fetchTasksCompletedBetween(start: weekStart, end: weekEnd)
            
            // Get goals data
            let activeGoals = goals.filter { $0.status == .active }
            let completedThisWeek = goals.filter { goal in
                guard let completed = goal.completedDate else { return false }
                return completed >= weekStart && completed <= weekEnd
            }
            
            // Get milestones completed this week
            let weeklyMilestones = milestones.filter { milestone in
                guard let completed = milestone.completedDate else { return false }
                return completed >= weekStart && completed <= weekEnd
            }
            
            // Calculate total time spent (estimate)
            let totalTime = weeklyTasks.compactMap(\.estimatedDuration).reduce(0, +)
            
            // Generate highlights and challenges
            let highlights = generateAchievementHighlights(
                completedGoals: completedThisWeek,
                completedMilestones: weeklyMilestones,
                completedTasks: weeklyTasks
            )
            
            let challenges = identifyChallenges(activeGoals: activeGoals)
            
            // Get next milestones
            let upcomingMilestones = getUpcomingMilestones()
            
            progressSummary = ProgressSummary(
                period: "This Week",
                startDate: weekStart,
                endDate: weekEnd,
                goalsInProgress: activeGoals.count,
                goalsCompleted: completedThisWeek.count,
                milestonesCompleted: weeklyMilestones.count,
                tasksCompleted: weeklyTasks.count,
                totalTimeSpent: totalTime
            )
            
            logger.debug("TIMELINE_VIEW: Updated progress summary")
            
        } catch {
            logger.error("TIMELINE_VIEW: Failed to update progress summary: \(error)")
        }
    }
    
    // MARK: - Version History & Undo/Restore
    
    /// Load version history for a goal
    private func loadVersionHistory(for goal: Goal) async {
        // For now, create sample version history
        // In production, this would be tracked automatically
        
        var history: [TimelineVersionHistory] = []
        
        // Simulate some version history entries
        history.append(TimelineVersionHistory(
            itemId: goal.id,
            itemType: "goal",
            changeType: .created,
            changeReason: "Goal created from project",
            changedBy: .system
        ))
        
        if goal.status != .planning {
            history.append(TimelineVersionHistory(
                itemId: goal.id,
                itemType: "goal",
                changeType: .updated,
                fieldName: "status",
                oldValue: AnyCodableValue("planning"),
                newValue: AnyCodableValue(goal.status.rawValue),
                changeReason: "Status updated to active",
                changedBy: .user
            ))
        }
        
        versionHistory = history
        logger.debug("TIMELINE_VIEW: Loaded \(history.count) version history entries")
    }
    
    /// Restore a goal to a previous version
    func restoreGoalVersion(_ historyEntry: TimelineVersionHistory) async -> Bool {
        logger.info("TIMELINE_VIEW: Restoring goal version for entry \(historyEntry.id)")
        
        // TODO: Implement actual version restoration
        // This would involve:
        // 1. Loading the previous state
        // 2. Applying the reverse change
        // 3. Updating the goal and related data
        // 4. Creating a new history entry for the restoration
        
        return true
    }
    
    // MARK: - Goal Management Actions
    
    /// Create a new milestone for a goal
    func createMilestone(for goalId: UUID, name: String, description: String?, targetDate: Date?) async -> Bool {
        let milestone = Milestone(
            goalId: goalId,
            name: name,
            description: description,
            targetDate: targetDate,
            type: .checkpoint
        )
        
        milestones.append(milestone)
        
        // Record timeline event
        let event = TimelineEvent(
            goalId: goalId,
            type: .noteAdded,
            title: "Milestone Created: \(name)",
            description: description,
            impact: .positive,
            relatedItemId: milestone.id,
            relatedItemType: "milestone",
            createdBy: .user
        )
        timelineEvents.append(event)
        
        logger.success("TIMELINE_VIEW: Created milestone: \(name)")
        return true
    }
    
    /// Complete a milestone
    func completeMilestone(_ milestoneId: UUID) async -> Bool {
        guard let index = milestones.firstIndex(where: { $0.id == milestoneId }) else {
            return false
        }
        
        var milestone = milestones[index]
        // Create new milestone with updated status
        // (Since Milestone is a struct, we need to replace it)
        
        // Update milestone completion
        // This would require making Milestone properties mutable or creating a new instance
        
        // Record timeline event
        let event = TimelineEvent(
            goalId: milestone.goalId,
            type: .milestoneCompleted,
            title: "Completed: \(milestone.name)",
            description: milestone.description,
            impact: .positive,
            relatedItemId: milestone.id,
            relatedItemType: "milestone",
            createdBy: .user
        )
        timelineEvents.append(event)
        
        logger.success("TIMELINE_VIEW: Completed milestone: \(milestone.name)")
        return true
    }
    
    /// Update goal status
    func updateGoalStatus(_ goalId: UUID, newStatus: GoalStatus) async -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else {
            return false
        }
        
        let oldStatus = goals[index].status
        
        // Update goal status
        // This would require updating the underlying project status
        
        // Record version history
        let historyEntry = TimelineVersionHistory(
            itemId: goalId,
            itemType: "goal",
            changeType: .updated,
            fieldName: "status",
            oldValue: AnyCodableValue(oldStatus.rawValue),
            newValue: AnyCodableValue(newStatus.rawValue),
            changeReason: "Status updated by user",
            changedBy: .user
        )
        versionHistory.append(historyEntry)
        
        // Record timeline event
        let event = TimelineEvent(
            goalId: goalId,
            type: .statusChanged,
            title: "Status changed to \(newStatus.displayName)",
            impact: newStatus == .completed ? .positive : .neutral,
            createdBy: .user
        )
        timelineEvents.append(event)
        
        logger.success("TIMELINE_VIEW: Updated goal status to \(newStatus.displayName)")
        return true
    }
    
    // MARK: - Periodic Updates
    
    /// Start periodic updates for timeline data
    private func startPeriodicUpdates() {
        // Update goals every 5 minutes
        goalsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { @MainActor in
                await self.loadGoals()
                await self.updateProgressSummary()
            }
        }
        
        // Analyze ripple effects every 30 minutes
        rippleAnalysisTimer = Timer.scheduledTimer(withTimeInterval: rippleAnalysisInterval, repeats: true) { _ in
            Task { @MainActor in
                if let selectedGoal = self.selectedGoal {
                    await self.detectRippleEffects(for: selectedGoal)
                }
                await self.generateTimelineInsights()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateProjectProgress(_ projectId: UUID) async -> Double {
        do {
            let tasks = try await taskRepository.fetchTasksForProject(projectId)
            guard !tasks.isEmpty else { return 0.0 }
            
            let completedTasks = tasks.filter { $0.status == .completed }
            return Double(completedTasks.count) / Double(tasks.count)
            
        } catch {
            logger.error("TIMELINE_VIEW: Failed to calculate project progress: \(error)")
            return 0.0
        }
    }
    
    private func inferGoalCategory(from project: Project) -> GoalCategory {
        let name = project.name.lowercased()
        
        if name.contains("health") || name.contains("fitness") {
            return .health
        } else if name.contains("career") || name.contains("work") {
            return .career
        } else if name.contains("learn") || name.contains("study") {
            return .learning
        } else if name.contains("creative") || name.contains("art") {
            return .creative
        } else {
            return .project
        }
    }
    
    private func calculateGoalRisk(for project: Project) async -> RiskLevel {
        guard let dueDate = project.dueDate,
              let targetDate = ISO8601DateFormatter().date(from: dueDate) else {
            return .low
        }
        
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        let progress = await calculateProjectProgress(project.id)
        
        // Risk calculation based on time vs progress
        if daysUntilDue <= 0 && progress < 1.0 {
            return .critical
        } else if daysUntilDue <= 7 && progress < 0.7 {
            return .high
        } else if daysUntilDue <= 14 && progress < 0.5 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func calculateVelocityTrend(for project: Project) async -> VelocityTrend {
        // For now, return stable
        // In production, this would analyze recent completion velocity
        return .stable
    }
    
    private func extractProjectVision(_ project: Project) async -> String? {
        // For now, return nil
        // In production, this could extract vision from project description using LLM
        return project.description
    }
    
    private func mapProjectStatusToGoal(_ status: ProjectStatus) -> GoalStatus {
        switch status {
        case .planning:
            return .planning
        case .active:
            return .active
        case .onHold:
            return .onHold
        case .completed:
            return .completed
        case .cancelled:
            return .cancelled
        }
    }
    
    private func mapProjectPriorityToGoal(_ status: ProjectStatus, project: Project) -> GoalPriority {
        // Map project priority to goal priority
        // For now, use medium as default since Project doesn't have priority
        return .medium
    }
    
    private func calculateEstimatedDuration(for project: Project) async -> Int? {
        do {
            let tasks = try await taskRepository.fetchTasksForProject(project.id)
            let totalHours = tasks.compactMap(\.estimatedDuration).reduce(0, +) / 60
            return totalHours > 0 ? totalHours / 8 : nil // Convert to days
            
        } catch {
            return nil
        }
    }
    
    private func predictCompletionDate(for project: Project, progress: Double) async -> Date? {
        guard let targetDate = project.dueDate,
              let target = ISO8601DateFormatter().date(from: targetDate) else {
            return nil
        }
        
        // Simple prediction based on current progress and remaining time
        if progress > 0 {
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
            let estimatedTotalDays = Double(daysRemaining) / (1.0 - progress)
            return Calendar.current.date(byAdding: .day, value: Int(estimatedTotalDays), to: Date())
        }
        
        return target
    }
    
    private func calculateCompletionAccuracy(_ completedGoals: [Goal]) -> Double {
        var accuracySum = 0.0
        var count = 0
        
        for goal in completedGoals {
            guard let targetDate = goal.targetDate,
                  let completedDate = goal.completedDate else { continue }
            
            let targetDays = Calendar.current.dateComponents([.day], from: goal.startDate ?? Date(), to: targetDate).day ?? 1
            let actualDays = Calendar.current.dateComponents([.day], from: goal.startDate ?? Date(), to: completedDate).day ?? 1
            
            let accuracy = (Double(targetDays) - Double(actualDays)) / Double(targetDays) * 100
            accuracySum += accuracy
            count += 1
        }
        
        return count > 0 ? accuracySum / Double(count) : 0.0
    }
    
    private func generateAchievementHighlights(
        completedGoals: [Goal],
        completedMilestones: [Milestone],
        completedTasks: [LifeTask]
    ) -> [String] {
        
        var highlights: [String] = []
        
        if !completedGoals.isEmpty {
            highlights.append("Completed \(completedGoals.count) goal(s)")
        }
        
        if !completedMilestones.isEmpty {
            highlights.append("Reached \(completedMilestones.count) milestone(s)")
        }
        
        if completedTasks.count > 10 {
            highlights.append("High productivity: \(completedTasks.count) tasks completed")
        }
        
        return highlights
    }
    
    private func identifyChallenges(activeGoals: [Goal]) -> [String] {
        var challenges: [String] = []
        
        let overdueGoals = activeGoals.filter { goal in
            guard let targetDate = goal.targetDate else { return false }
            return targetDate < Date()
        }
        
        if !overdueGoals.isEmpty {
            challenges.append("\(overdueGoals.count) goal(s) are overdue")
        }
        
        let highRiskGoals = activeGoals.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
        if !highRiskGoals.isEmpty {
            challenges.append("\(highRiskGoals.count) goal(s) at high risk")
        }
        
        return challenges
    }
    
    private func getUpcomingMilestones() -> [Milestone] {
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        return milestones.filter { milestone in
            guard let targetDate = milestone.targetDate else { return false }
            return targetDate <= nextMonth && milestone.status != .completed
        }.sorted { $0.targetDate! < $1.targetDate! }
    }
    
    // MARK: - Public Interface
    
    /// Refresh all timeline data
    func refreshTimeline() {
        Task {
            await loadInitialData()
        }
    }
    
    /// Get goals filtered by status
    func getGoals(status: GoalStatus) -> [Goal] {
        return goals.filter { $0.status == status }
    }
    
    /// Get ripple effects by severity
    func getRippleEffects(severity: RippleSeverity) -> [RippleEffect] {
        return rippleEffects.filter { $0.severity == severity }
    }
    
    /// Get insights by category
    func getInsights(category: TimelineInsightCategory) -> [TimelineInsight] {
        return timelineInsights.filter { $0.category == category }
    }
}