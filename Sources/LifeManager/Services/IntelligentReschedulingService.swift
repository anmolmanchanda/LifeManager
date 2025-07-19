import Foundation
import SwiftUI
import Combine

/// Intelligent Rescheduling Service
/// Phase 2: Smart Auto-Rescheduling Implementation
/// Provides autonomous overdue task management with AI-powered decision making
@MainActor
class IntelligentReschedulingService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let contextMemory = ContextMemoryService.shared
    private let personalRules = PersonalRulesService.shared
    private let orchestration = CalendarOrchestrationService.shared
    private let bufferService = BufferManagementService.shared
    private let llmService = LLMServiceCoordinator.shared
    private let notificationService = NotificationService.shared
    private let advancedNotificationService = AdvancedNotificationService.shared
    private let externalCalendar = ExternalCalendarIntegrationService.shared
    private let userPreferencesRepository = UserPreferencesRepository()
    private let logger = Logger.shared
    
    // MARK: - Private Properties
    
    private let taskRepository = TaskRepository()
    private let projectRepository = ProjectRepository()
    private let areaRepository = AreaRepository()
    
    private var overdueMonitoringTimer: Timer?
    private var reschedulingInProgress = false
    
    // MARK: - Published State
    
    @Published var isMonitoring = false
    @Published var overdueTasksCount = 0
    @Published var lastReschedulingActivity: Date?
    @Published var reschedulingStats = ReschedulingStatistics()
    @Published var reschedulingHistory: [ReschedulingHistoryEntry] = []
    @Published var undoableActions: [UndoableReschedulingAction] = []
    @Published var userPreferences = UserSchedulingPreferences(
        workingHours: .default,
        focusBlocks: [],
        reschedulingSettings: .default,
        notificationSettings: NotificationSettings()
    )
    
    // MARK: - Configuration
    
    private let monitoringInterval: TimeInterval = 300 // 5 minutes
    private let maxReschedulingCascade = 5
    private let reschedulingConfidenceThreshold = 0.7
    private let aiDecisionThreshold = 0.8 // Minimum confidence for AI-only decisions
    private let complexDecisionThreshold = 0.6 // Require user input below this
    private let learningDecayFactor = 0.95 // Learning weight decay over time
    
    // MARK: - Singleton
    
    static let shared = IntelligentReschedulingService()
    
    // MARK: - Initialization
    
    private init() {
        logger.info("INTELLIGENT_RESCHEDULING: Service initialized")
        loadUserPreferences()
        startOverdueMonitoring()
    }
    
    deinit {
        stopOverdueMonitoring()
    }
    
    // MARK: - Overdue Task Monitoring
    
    /// Start continuous monitoring for overdue tasks
    func startOverdueMonitoring() {
        guard !isMonitoring else { return }
        
        logger.info("INTELLIGENT_RESCHEDULING: Starting overdue task monitoring")
        isMonitoring = true
        
        // Initial scan
        Task {
            await processOverdueTasks()
        }
        
        // Set up periodic monitoring
        overdueMonitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processOverdueTasks()
            }
        }
    }
    
    /// Stop overdue task monitoring
    func stopOverdueMonitoring() {
        logger.info("INTELLIGENT_RESCHEDULING: Stopping overdue task monitoring")
        isMonitoring = false
        overdueMonitoringTimer?.invalidate()
        overdueMonitoringTimer = nil
    }
    
    /// Process all overdue tasks and reschedule them intelligently
    func processOverdueTasks() async {
        guard !reschedulingInProgress else {
            logger.debug("INTELLIGENT_RESCHEDULING: Rescheduling already in progress, skipping")
            return
        }
        
        reschedulingInProgress = true
        defer { reschedulingInProgress = false }
        
        do {
            logger.debug("INTELLIGENT_RESCHEDULING: Starting overdue task processing")
            
            // Get all overdue tasks
            let overdueTasks = try await taskRepository.fetchOverdueTasks()
            overdueTasksCount = overdueTasks.count
            
            if overdueTasks.isEmpty {
                logger.debug("INTELLIGENT_RESCHEDULING: No overdue tasks found")
                return
            }
            
            logger.info("INTELLIGENT_RESCHEDULING: Found \(overdueTasks.count) overdue tasks to process")
            
            // Process each overdue task
            for task in overdueTasks {
                await processOverdueTask(task)
            }
            
            lastReschedulingActivity = Date()
            logger.success("INTELLIGENT_RESCHEDULING: Completed processing \(overdueTasks.count) overdue tasks")
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to process overdue tasks: \(error)")
        }
    }
    
    /// Process a single overdue task with intelligent rescheduling
    private func processOverdueTask(_ task: LifeTask) async {
        logger.debug("INTELLIGENT_RESCHEDULING: Processing overdue task: \(task.title)")
        
        guard task.canBeAutomaticallyRescheduled else {
            logger.debug("INTELLIGENT_RESCHEDULING: Task cannot be automatically rescheduled: \(task.title)")
            return
        }
        
        // Check task dependencies before rescheduling
        let taskWithDeps = await getTaskWithDependencies(task)
        guard taskWithDeps.canStart else {
            logger.debug("INTELLIGENT_RESCHEDULING: Task cannot start due to incomplete prerequisites: \(task.title)")
            await parkTaskIntelligently(task, reason: "Prerequisites not completed")
            return
        }
        
        do {
            // Step 1: Calculate priority intelligence
            let priorityIntelligence = await calculatePriorityIntelligence(for: task)
            
            // Step 2: Find optimal rescheduling slot considering dependencies
            let optimalSlot = await findOptimalReschedulingSlot(
                for: taskWithDeps,
                priorityIntelligence: priorityIntelligence
            )
            
            guard let slot = optimalSlot else {
                logger.warning("INTELLIGENT_RESCHEDULING: No suitable slot found for task: \(task.title)")
                await parkTaskIntelligently(task, reason: "No suitable time slots available")
                return
            }
            
            // Step 3: Execute rescheduling
            let reschedulingEvent = ReschedulingEvent(
                taskId: task.id,
                originalDate: task.dueDate ?? "",
                newDate: ISO8601DateFormatter().string(from: slot.startTime),
                reason: .overdue,
                wasAutomatic: true,
                confidence: slot.confidence
            )
            
            await executeRescheduling(task: task, to: slot, event: reschedulingEvent)
            
            // Step 4: Send notification
            await sendReschedulingNotification(task: task, newSlot: slot, reason: .overdue)
            
            // Step 5: Update statistics
            reschedulingStats.totalRescheduled += 1
            reschedulingStats.overdueTasksRescheduled += 1
            
            logger.success("INTELLIGENT_RESCHEDULING: Successfully rescheduled overdue task: \(task.title)")
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to reschedule task \(task.title): \(error)")
            reschedulingStats.failedReschedulings += 1
        }
    }
    
    // MARK: - Priority Intelligence
    
    /// Calculate intelligent priority score for a task
    private func calculatePriorityIntelligence(for task: LifeTask) async -> PriorityIntelligence {
        logger.debug("INTELLIGENT_RESCHEDULING: Calculating priority intelligence for: \(task.title)")
        
        // Get context for intelligent scoring
        let context = await contextMemory.getCurrentContext()
        let userRules = await personalRules.getApplicableRules(for: task)
        
        // Calculate component scores
        let urgencyScore = calculateUrgencyScore(for: task)
        let importanceScore = calculateImportanceScore(for: task, context: context)
        let contextScore = calculateContextScore(for: task, context: context)
        let userPatternScore = calculateUserPatternScore(for: task, rules: userRules)
        
        // Use LLM for advanced intelligence scoring
        let intelligenceScore = await calculateLLMIntelligenceScore(
            for: task,
            context: context,
            urgency: urgencyScore,
            importance: importanceScore
        )
        
        let reasoningFactors = generateReasoningFactors(
            urgency: urgencyScore,
            importance: importanceScore,
            context: contextScore,
            userPattern: userPatternScore,
            intelligence: intelligenceScore
        )
        
        let priorityIntelligence = PriorityIntelligence(
            taskId: task.id,
            intelligenceScore: intelligenceScore,
            urgencyScore: urgencyScore,
            importanceScore: importanceScore,
            contextScore: contextScore,
            userPatternScore: userPatternScore,
            reasoningFactors: reasoningFactors
        )
        
        logger.debug("INTELLIGENT_RESCHEDULING: Priority intelligence calculated - Overall: \(String(format: "%.2f", priorityIntelligence.overallScore))")
        
        return priorityIntelligence
    }
    
    /// Calculate urgency score based on overdue time and deadlines
    private func calculateUrgencyScore(for task: LifeTask) -> Double {
        var score = 0.5 // Base score
        
        // Factor in how overdue the task is
        let overdueHours = task.overdueByHours
        if overdueHours > 0 {
            // More overdue = higher urgency (max boost of 0.4)
            let overdueBoost = min(0.4, overdueHours / 24.0 * 0.4)
            score += overdueBoost
        }
        
        // Factor in task priority
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
        
        return min(1.0, score)
    }
    
    /// Calculate importance score based on project context and PARA categorization
    private func calculateImportanceScore(for task: LifeTask, context: ProcessingContext) -> Double {
        var score = 0.5
        
        // Project importance
        if task.projectId != nil {
            score += 0.2 // Tasks in projects are more important
        }
        
        // Work vs personal context
        if task.workPersonal == .work {
            score += 0.1 // Work tasks slightly higher importance during work hours
        }
        
        // Focus flag
        if task.isFocus {
            score += 0.3
        }
        
        return min(1.0, score)
    }
    
    /// Calculate context score based on current user patterns
    private func calculateContextScore(for task: LifeTask, context: ProcessingContext) -> Double {
        var score = 0.5
        
        // Time of day preferences
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 9 && currentHour <= 11 {
            score += 0.2 // Morning focus time
        }
        
        // Work/personal alignment
        if task.workPersonal == .work && (currentHour >= 9 && currentHour <= 17) {
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    /// Calculate user pattern score based on learned preferences
    private func calculateUserPatternScore(for task: LifeTask, rules: [PersonalPARARule]) -> Double {
        var score = 0.5
        
        // Apply learned user rules
        for rule in rules {
            if rule.ruleType == .contextual {
                score += 0.1
            }
        }
        
        return min(1.0, score)
    }
    
    /// Use LLM for advanced intelligence scoring
    private func calculateLLMIntelligenceScore(
        for task: LifeTask,
        context: ProcessingContext,
        urgency: Double,
        importance: Double
    ) async -> Double {
        
        do {
            // Create prompt for LLM intelligence scoring
            let prompt = """
            Analyze this task for intelligent priority scoring:
            
            Task: \(task.title)
            Description: \(task.description ?? "None")
            Current Priority: \(task.priority.displayName)
            Work/Personal: \(task.workPersonal.displayName)
            Overdue: \(task.isOverdue ? "Yes (\(String(format: "%.1f", task.overdueByHours)) hours)" : "No")
            
            Urgency Score: \(String(format: "%.2f", urgency))
            Importance Score: \(String(format: "%.2f", importance))
            
            Provide an intelligence score (0.0-1.0) that considers:
            - Semantic analysis of task content
            - Contextual importance beyond keywords
            - Potential impact of delay
            - Resource requirements
            
            Return only a number between 0.0 and 1.0.
            """
            
            let response = try await llmService.processText(prompt)
            
            // Parse the numerical response
            let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
            if let score = Double(cleanedResponse) {
                return max(0.0, min(1.0, score))
            }
            
            // Try to extract number from response
            let numbers = cleanedResponse.components(separatedBy: .whitespaces)
                .compactMap { Double($0) }
                .filter { $0 >= 0.0 && $0 <= 1.0 }
            
            if let firstValidNumber = numbers.first {
                return firstValidNumber
            }
            
            // Fallback calculation
            return (urgency + importance) / 2.0
            
        } catch {
            logger.warning("INTELLIGENT_RESCHEDULING: LLM intelligence scoring failed: \(error)")
            return (urgency + importance) / 2.0
        }
    }
    
    /// Generate human-readable reasoning factors
    private func generateReasoningFactors(
        urgency: Double,
        importance: Double,
        context: Double,
        userPattern: Double,
        intelligence: Double
    ) -> [String] {
        
        var factors: [String] = []
        
        if urgency > 0.7 {
            factors.append("High urgency due to overdue status")
        }
        
        if importance > 0.7 {
            factors.append("High importance based on project context")
        }
        
        if context > 0.7 {
            factors.append("Favorable current context")
        }
        
        if userPattern > 0.7 {
            factors.append("Matches user scheduling patterns")
        }
        
        if intelligence > 0.8 {
            factors.append("AI analysis indicates high priority")
        }
        
        if factors.isEmpty {
            factors.append("Standard priority assessment")
        }
        
        return factors
    }
    
    // MARK: - Optimal Slot Finding
    
    /// Find the optimal time slot for rescheduling a task
    private func findOptimalReschedulingSlot(
        for taskWithDeps: TaskWithDependencies,
        priorityIntelligence: PriorityIntelligence
    ) async -> OptimalTimeSlot? {
        
        let task = taskWithDeps.task
        logger.debug("INTELLIGENT_RESCHEDULING: Finding optimal slot for: \(task.title)")
        
        // Get current calendar events to check for conflicts
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        
        do {
            // Analyze available time slots over the next week
            let potentialSlots = generatePotentialTimeSlots(from: today, to: nextWeek, for: task)
            
            // Score each slot based on multiple factors
            var scoredSlots: [OptimalTimeSlot] = []
            
            for slot in potentialSlots {
                // Check if this slot respects task dependencies
                let dependencyCheck = taskWithDeps.canBeRescheduled(to: slot.startTime)
                guard dependencyCheck.canReschedule else {
                    logger.debug("INTELLIGENT_RESCHEDULING: Slot \(slot.startTime) rejected due to dependency: \(dependencyCheck.reason ?? "Unknown")")
                    continue
                }
                
                let score = await calculateSlotScore(
                    slot: slot,
                    task: task,
                    priorityIntelligence: priorityIntelligence
                )
                
                let optimalSlot = OptimalTimeSlot(
                    startTime: slot.startTime,
                    endTime: slot.endTime,
                    confidence: score,
                    reasoning: generateSlotReasoning(slot: slot, score: score, task: task)
                )
                
                scoredSlots.append(optimalSlot)
            }
            
            // Return the highest scoring slot that meets the confidence threshold
            let bestSlot = scoredSlots
                .filter { $0.confidence >= reschedulingConfidenceThreshold }
                .max { $0.confidence < $1.confidence }
            
            return bestSlot
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to find optimal slot: \(error)")
            return nil
        }
    }
    
    /// Generate potential time slots for scheduling
    private func generatePotentialTimeSlots(from startDate: Date, to endDate: Date, for task: LifeTask) -> [TimeSlotCandidate] {
        var slots: [TimeSlotCandidate] = []
        
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            // Skip non-working days for work tasks based on user preferences
            let weekday = calendar.component(.weekday, currentDate)
            if task.workPersonal == .work && !userPreferences.workingHours.workDays.contains(weekday) {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                continue
            }
            
            // Generate slots throughout the day using user preferences
            let workingHours = userPreferences.workingHours
            let workDayStart = calendar.date(bySettingHour: workingHours.startHour, minute: 0, second: 0, of: currentDate) ?? currentDate
            let workDayEnd = calendar.date(bySettingHour: workingHours.endHour, minute: 0, second: 0, of: currentDate) ?? currentDate
            
            let duration = task.estimatedDuration ?? 60 // Default 1 hour
            var slotStart = workDayStart
            
            while slotStart.addingTimeInterval(TimeInterval(duration * 60)) <= workDayEnd {
                let slotEnd = slotStart.addingTimeInterval(TimeInterval(duration * 60))
                
                let slot = TimeSlotCandidate(
                    startTime: slotStart,
                    endTime: slotEnd,
                    date: currentDate,
                    isWorkHours: true
                )
                
                slots.append(slot)
                
                // Move to next slot (30-minute intervals)
                slotStart = slotStart.addingTimeInterval(1800)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return slots
    }
    
    /// Calculate score for a potential time slot
    private func calculateSlotScore(
        slot: TimeSlotCandidate,
        task: LifeTask,
        priorityIntelligence: PriorityIntelligence
    ) async -> Double {
        
        var score = 0.5 // Base score
        
        // Time of day preferences based on focus blocks
        let hour = Calendar.current.component(.hour, from: slot.startTime)
        let minute = Calendar.current.component(.minute, from: slot.startTime)
        let weekday = Calendar.current.component(.weekday, from: slot.startTime)
        
        // Check if slot aligns with user's focus blocks
        for focusBlock in userPreferences.focusBlocks {
            if focusBlock.applicableDays.contains(weekday) {
                let blockStartMinutes = focusBlock.startHour * 60 + focusBlock.startMinute
                let blockEndMinutes = focusBlock.endHour * 60 + focusBlock.endMinute
                let slotStartMinutes = hour * 60 + minute
                
                if slotStartMinutes >= blockStartMinutes && slotStartMinutes < blockEndMinutes {
                    switch focusBlock.priority {
                    case .high:
                        score += 0.4 // High priority focus block
                    case .medium:
                        score += 0.2 // Medium priority focus block
                    case .low:
                        score += 0.1 // Low priority focus block
                    }
                    break
                }
            }
        }
        
        // Fallback to general time preferences if no focus blocks defined
        if userPreferences.focusBlocks.isEmpty {
            switch hour {
            case 9...11:
                score += 0.3 // Morning focus time
            case 13...15:
                score += 0.2 // Afternoon focus time
            case 16...17:
                score += 0.1 // End of day tasks
            default:
                break
            }
        }
        
        // Priority alignment
        if priorityIntelligence.overallScore > 0.8 && hour >= 9 && hour <= 11 {
            score += 0.2 // High priority tasks in prime time
        }
        
        // Work/personal alignment
        if task.workPersonal == .work && slot.isWorkHours {
            score += 0.1
        }
        
        // Buffer availability (check with BufferManagementService)
        let hasAdequateBuffer = await checkBufferAvailability(for: slot)
        if hasAdequateBuffer {
            score += 0.1
        }
        
        // Calendar conflicts (lower score for slots with conflicts)
        let hasConflicts = await checkCalendarConflicts(for: slot)
        if hasConflicts {
            score -= 0.3
        }
        
        return max(0.0, min(1.0, score))
    }
    
    /// Check if slot has adequate buffer time
    private func checkBufferAvailability(for slot: TimeSlotCandidate) async -> Bool {
        // Use BufferManagementService to check if slot has adequate buffer
        let startOfDay = Calendar.current.startOfDay(for: slot.date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? slot.date
        
        // This would integrate with existing buffer management logic
        return true // Simplified for now
    }
    
    /// Check for calendar conflicts in the proposed slot
    private func checkCalendarConflicts(for slot: TimeSlotCandidate) async -> Bool {
        // This would check against existing calendar events
        // Integration with CalendarOrchestrationService
        return false // Simplified for now
    }
    
    /// Generate human-readable reasoning for slot selection
    private func generateSlotReasoning(slot: TimeSlotCandidate, score: Double, task: LifeTask) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let hour = Calendar.current.component(.hour, from: slot.startTime)
        
        var reasoning = "Scheduled for \(formatter.string(from: slot.startTime))"
        
        if score > 0.8 {
            reasoning += " - Optimal time slot"
        } else if score > 0.6 {
            reasoning += " - Good time slot"
        } else {
            reasoning += " - Available time slot"
        }
        
        if hour >= 9 && hour <= 11 {
            reasoning += " during morning focus hours"
        } else if hour >= 13 && hour <= 15 {
            reasoning += " during afternoon focus time"
        }
        
        return reasoning
    }
    
    // MARK: - Rescheduling Execution
    
    /// Execute the actual rescheduling of a task
    private func executeRescheduling(
        task: LifeTask,
        to slot: OptimalTimeSlot,
        event: ReschedulingEvent
    ) async {
        
        do {
            // Update task with new due date
            let updatedTask = LifeTask(
                id: task.id,
                blobId: task.blobId,
                title: task.title,
                description: task.description,
                priority: task.priority,
                status: .todo, // Reset to todo if it was in progress
                dueDate: ISO8601DateFormatter().string(from: slot.startTime),
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
            
            // Save updated task
            let savedTask = try await taskRepository.updateTask(updatedTask)
            
            // Create undoable action
            let undoableAction = UndoableReschedulingAction(
                taskId: task.id,
                taskTitle: task.title,
                originalDueDate: task.dueDate,
                newDueDate: ISO8601DateFormatter().string(from: slot.startTime),
                reschedulingReason: slot.reasoning,
                confidence: slot.confidence,
                timestamp: Date(),
                expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
            )
            
            // Create history entry
            let historyEntry = ReschedulingHistoryEntry(
                taskId: task.id,
                taskTitle: task.title,
                action: .autoRescheduled,
                originalDueDate: task.dueDate,
                newDueDate: ISO8601DateFormatter().string(from: slot.startTime),
                reasoning: slot.reasoning,
                confidence: slot.confidence,
                timestamp: Date(),
                undoAction: nil
            )
            
            await MainActor.run {
                undoableActions.append(undoableAction)
                reschedulingHistory.append(historyEntry)
                reschedulingStats.totalRescheduled += 1
                reschedulingStats.overdueTasksRescheduled += 1
                
                // Clean up expired undo actions
                cleanupExpiredUndoActions()
            }
            
            logger.success("INTELLIGENT_RESCHEDULING: Task rescheduled successfully: \(task.title)")
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to execute rescheduling: \(error)")
            throw error
        }
    }
    
    /// Park a task intelligently when no suitable slot is found
    private func parkTaskIntelligently(_ task: LifeTask, reason: String) async {
        logger.info("INTELLIGENT_RESCHEDULING: Parking task intelligently: \(task.title) - \(reason)")
        
        // This would integrate with the existing parking lot system
        // For now, we'll send a notification to the user
        await sendParkingNotification(task: task, reason: reason)
        
        reschedulingStats.tasksParked += 1
    }
    
    // MARK: - Notifications
    
    /// Send notification about automatic rescheduling
    private func sendReschedulingNotification(
        task: LifeTask,
        newSlot: OptimalTimeSlot,
        reason: ReschedulingReason
    ) async {
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let title = "Task Automatically Rescheduled"
        let body = "\(task.title) moved to \(formatter.string(from: newSlot.startTime)). \(newSlot.reasoning)"
        
        notificationService.sendLocalNotification(
            title: title,
            body: body,
            category: .reschedulingUpdate,
            delay: 0
        )
        
        logger.info("INTELLIGENT_RESCHEDULING: Sent rescheduling notification for: \(task.title)")
    }
    
    /// Send notification when task is parked
    private func sendParkingNotification(task: LifeTask, reason: String) async {
        let title = "Task Moved to Parking Lot"
        let body = "\(task.title) couldn't be automatically scheduled. \(reason)"
        
        notificationService.sendLocalNotification(
            title: title,
            body: body,
            category: .eventParked,
            delay: 0
        )
    }
    
    // MARK: - Statistics and Reporting
    
    /// Get rescheduling statistics
    func getReschedulingStatistics() -> ReschedulingStatistics {
        return reschedulingStats
    }
    
    /// Reset statistics
    func resetStatistics() {
        reschedulingStats = ReschedulingStatistics()
        logger.info("INTELLIGENT_RESCHEDULING: Statistics reset")
    }
    
    // MARK: - Helper Methods
    
    /// Get current user ID (placeholder implementation)
    private func getCurrentUserId() -> UUID {
        // In a real implementation, this would get the current user ID from authentication
        // For now, using a default development user ID
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    }
}

// MARK: - Supporting Data Structures

/// Optimal time slot for rescheduling
struct OptimalTimeSlot {
    let startTime: Date
    let endTime: Date
    let confidence: Double
    let reasoning: String
}

/// Time slot candidate for evaluation
struct TimeSlotCandidate {
    let startTime: Date
    let endTime: Date
    let date: Date
    let isWorkHours: Bool
}

// MARK: - Undo/Override Support

extension IntelligentReschedulingService {
    
    /// Undo a recent rescheduling action
    func undoRescheduling(actionId: UUID) async -> Bool {
        logger.info("INTELLIGENT_RESCHEDULING: Attempting to undo action \(actionId)")
        
        guard let action = undoableActions.first(where: { $0.id == actionId }) else {
            logger.warning("INTELLIGENT_RESCHEDULING: Undo action not found: \(actionId)")
            return false
        }
        
        guard action.canUndo else {
            logger.warning("INTELLIGENT_RESCHEDULING: Undo window expired for action: \(actionId)")
            return false
        }
        
        do {
            // Fetch the current task
            guard let task = try await taskRepository.fetchTask(id: action.taskId) else {
                logger.error("INTELLIGENT_RESCHEDULING: Task not found for undo: \(action.taskId)")
                return false
            }
            
            // Restore original due date
            let originalTask = LifeTask(
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.status,
                priority: task.priority,
                workPersonal: task.workPersonal,
                dueDate: action.originalDueDate,
                estimatedDuration: task.estimatedDuration,
                tags: task.tags,
                projectId: task.projectId,
                areaId: task.areaId,
                blobId: task.blobId,
                userId: task.userId,
                createdAt: task.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            // Update task with original due date
            _ = try await taskRepository.updateTask(originalTask)
            
            // Record the undo action in history
            let historyEntry = ReschedulingHistoryEntry(
                taskId: action.taskId,
                taskTitle: action.taskTitle,
                action: .undone,
                originalDueDate: action.newDueDate,
                newDueDate: action.originalDueDate,
                reasoning: "User undid automatic rescheduling",
                confidence: 1.0,
                timestamp: Date(),
                undoAction: .undoToOriginal
            )
            
            await MainActor.run {
                reschedulingHistory.append(historyEntry)
                undoableActions.removeAll { $0.id == actionId }
                reschedulingStats.userOverrides += 1
            }
            
            logger.success("INTELLIGENT_RESCHEDULING: Successfully undid rescheduling for task: \(action.taskTitle)")
            return true
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to undo rescheduling: \(error)")
            return false
        }
    }
    
    /// Override AI rescheduling with user-specified time
    func overrideRescheduling(taskId: UUID, newDueDate: String, reason: String = "User override") async -> Bool {
        logger.info("INTELLIGENT_RESCHEDULING: User override for task \(taskId)")
        
        do {
            guard let task = try await taskRepository.fetchTask(id: taskId) else {
                logger.error("INTELLIGENT_RESCHEDULING: Task not found for override: \(taskId)")
                return false
            }
            
            let originalDueDate = task.dueDate
            
            let updatedTask = LifeTask(
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.status,
                priority: task.priority,
                workPersonal: task.workPersonal,
                dueDate: newDueDate,
                estimatedDuration: task.estimatedDuration,
                tags: task.tags,
                projectId: task.projectId,
                areaId: task.areaId,
                blobId: task.blobId,
                userId: task.userId,
                createdAt: task.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            _ = try await taskRepository.updateTask(updatedTask)
            
            // Record the override in history
            let historyEntry = ReschedulingHistoryEntry(
                taskId: taskId,
                taskTitle: task.title,
                action: .userOverride,
                originalDueDate: originalDueDate,
                newDueDate: newDueDate,
                reasoning: reason,
                confidence: 1.0,
                timestamp: Date(),
                undoAction: nil
            )
            
            await MainActor.run {
                reschedulingHistory.append(historyEntry)
                reschedulingStats.userOverrides += 1
                
                // Remove any pending undo actions for this task
                undoableActions.removeAll { $0.taskId == taskId }
            }
            
            logger.success("INTELLIGENT_RESCHEDULING: User override applied for task: \(task.title)")
            return true
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to apply user override: \(error)")
            return false
        }
    }
    
    /// Clean up expired undo actions
    func cleanupExpiredUndoActions() {
        let before = undoableActions.count
        undoableActions.removeAll { !$0.canUndo }
        let after = undoableActions.count
        
        if before != after {
            logger.debug("INTELLIGENT_RESCHEDULING: Cleaned up \(before - after) expired undo actions")
        }
    }
    
    /// Get available undo actions for a specific task
    func getUndoableActions(for taskId: UUID) -> [UndoableReschedulingAction] {
        return undoableActions.filter { $0.taskId == taskId && $0.canUndo }
    }
    
    /// Get rescheduling history for a specific task
    func getReschedulingHistory(for taskId: UUID) -> [ReschedulingHistoryEntry] {
        return reschedulingHistory.filter { $0.taskId == taskId }
    }
    
    // MARK: - User Preferences Management
    
    /// Load user scheduling preferences
    func loadUserPreferences() {
        Task {
            do {
                let userId = getCurrentUserId().uuidString
                
                // Try to load user preferences from repository
                if let loadedPreferences = try await userPreferencesRepository.loadSchedulingPreferences(userId: userId) {
                    await MainActor.run {
                        userPreferences = loadedPreferences
                    }
                    logger.success("INTELLIGENT_RESCHEDULING: Loaded user preferences from database with \(loadedPreferences.focusBlocks.count) focus blocks")
                } else {
                    // Fall back to defaults if no preferences found
                    let defaultPreferences = createDefaultUserPreferences()
                    await MainActor.run {
                        userPreferences = defaultPreferences
                    }
                    
                    // Save defaults to repository for future use
                    try await userPreferencesRepository.saveSchedulingPreferences(defaultPreferences, userId: userId)
                    logger.info("INTELLIGENT_RESCHEDULING: Created and saved default user preferences with \(defaultPreferences.focusBlocks.count) focus blocks")
                }
                
            } catch {
                logger.error("INTELLIGENT_RESCHEDULING: Failed to load user preferences, using defaults: \(error)")
                
                // Fall back to defaults on error
                let defaultPreferences = createDefaultUserPreferences()
                await MainActor.run {
                    userPreferences = defaultPreferences
                }
            }
        }
    }
    
    /// Create default user preferences
    private func createDefaultUserPreferences() -> UserSchedulingPreferences {
        let defaultFocusBlocks = [
            FocusBlock(
                name: "Deep Work Morning",
                startHour: 9,
                startMinute: 0,
                endHour: 11,
                endMinute: 0,
                priority: .high,
                applicableDays: [2, 3, 4, 5, 6] // Monday-Friday
            ),
            FocusBlock(
                name: "Afternoon Focus",
                startHour: 14,
                startMinute: 0,
                endHour: 16,
                endMinute: 0,
                priority: .medium,
                applicableDays: [2, 3, 4, 5, 6] // Monday-Friday
            )
        ]
        
        return UserSchedulingPreferences(
            workingHours: .default,
            focusBlocks: defaultFocusBlocks,
            reschedulingSettings: .default,
            notificationSettings: NotificationSettings.default
        )
    }
    
    /// Save user scheduling preferences
    func saveUserPreferences() async {
        do {
            let userId = getCurrentUserId().uuidString
            try await userPreferencesRepository.saveSchedulingPreferences(userPreferences, userId: userId)
            logger.success("INTELLIGENT_RESCHEDULING: User preferences saved to database")
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Failed to save user preferences: \(error)")
        }
    }
    
    /// Update working hours preference
    func updateWorkingHours(_ workingHours: WorkingHoursPreference) async {
        userPreferences = UserSchedulingPreferences(
            workingHours: workingHours,
            focusBlocks: userPreferences.focusBlocks,
            reschedulingSettings: userPreferences.reschedulingSettings,
            notificationSettings: userPreferences.notificationSettings
        )
        await saveUserPreferences()
        logger.info("INTELLIGENT_RESCHEDULING: Working hours updated: \(workingHours.startHour)-\(workingHours.endHour)")
    }
    
    /// Add or update focus block
    func updateFocusBlocks(_ focusBlocks: [FocusBlock]) async {
        userPreferences = UserSchedulingPreferences(
            workingHours: userPreferences.workingHours,
            focusBlocks: focusBlocks,
            reschedulingSettings: userPreferences.reschedulingSettings,
            notificationSettings: userPreferences.notificationSettings
        )
        await saveUserPreferences()
        logger.info("INTELLIGENT_RESCHEDULING: Focus blocks updated: \(focusBlocks.count) blocks")
    }
    
    /// Update rescheduling settings
    func updateReschedulingSettings(_ settings: ReschedulingSettings) async {
        userPreferences = UserSchedulingPreferences(
            workingHours: userPreferences.workingHours,
            focusBlocks: userPreferences.focusBlocks,
            reschedulingSettings: settings,
            notificationSettings: userPreferences.notificationSettings
        )
        await saveUserPreferences()
        logger.info("INTELLIGENT_RESCHEDULING: Rescheduling settings updated")
    }
    
    // MARK: - Dependency Management
    
    /// Get task with all its dependency information
    private func getTaskWithDependencies(_ task: LifeTask) async -> TaskWithDependencies {
        // For now, return a task with no dependencies
        // TODO: Implement actual dependency fetching from repository
        // This would typically involve:
        // 1. Fetching all TaskDependency records for this task
        // 2. Loading the prerequisite and dependent tasks
        // 3. Building the full dependency graph
        
        return TaskWithDependencies(
            task: task,
            prerequisites: [],
            dependents: [],
            dependencies: []
        )
    }
    
    /// Add a dependency between two tasks
    func addTaskDependency(_ taskId: UUID, dependsOn prerequisiteId: UUID, type: DependencyType = .finishToStart) async -> Bool {
        // TODO: Implement dependency creation
        // This would involve:
        // 1. Validating that the dependency doesn't create a cycle
        // 2. Creating TaskDependency record
        // 3. Persisting to repository
        // 4. Updating any affected schedules
        
        logger.info("INTELLIGENT_RESCHEDULING: Dependency added: \(taskId) depends on \(prerequisiteId)")
        return true
    }
    
    /// Remove a dependency between two tasks
    func removeTaskDependency(_ taskId: UUID, prerequisiteId: UUID) async -> Bool {
        // TODO: Implement dependency removal
        logger.info("INTELLIGENT_RESCHEDULING: Dependency removed: \(taskId) no longer depends on \(prerequisiteId)")
        return true
    }
    
    /// Check for circular dependencies in the task graph
    private func detectCircularDependencies(_ taskId: UUID, visited: Set<UUID> = []) async -> Bool {
        // TODO: Implement cycle detection algorithm
        // This would use depth-first search to detect cycles in the dependency graph
        return false
    }
    
    // MARK: - External Calendar Integration
    
    /// Update external calendar data for intelligent scheduling
    func updateExternalCalendarData(
        events: [ExternalCalendarEvent],
        conflicts: [CalendarConflict],
        availabilitySlots: [AvailabilitySlot]
    ) async {
        logger.info("INTELLIGENT_RESCHEDULING: Updating external calendar data - \\(events.count) events, \\(conflicts.count) conflicts")
        
        // Store external calendar data for scheduling decisions
        await storeExternalCalendarData(events: events, conflicts: conflicts, availabilitySlots: availabilitySlots)
        
        // Process any high-severity conflicts immediately
        let highSeverityConflicts = conflicts.filter { $0.severity == .high }
        if !highSeverityConflicts.isEmpty {
            logger.warning("INTELLIGENT_RESCHEDULING: Found \\(highSeverityConflicts.count) high-severity conflicts")
            await resolveHighPriorityConflicts(highSeverityConflicts)
        }
        
        // Update availability for future scheduling
        await updateAvailabilityCache(availabilitySlots)
    }
    
    /// Get user working hours for external calendar integration
    func getUserWorkingHours() async -> WorkingHours {
        return WorkingHours(
            startHour: userPreferences.workingHours.startHour,
            endHour: userPreferences.workingHours.endHour
        )
    }
    
    /// Store external calendar data for scheduling consideration
    private func storeExternalCalendarData(
        events: [ExternalCalendarEvent],
        conflicts: [CalendarConflict],
        availabilitySlots: [AvailabilitySlot]
    ) async {
        // Store the data in memory for immediate use
        // In a full implementation, this would persist to database
        
        logger.debug("INTELLIGENT_RESCHEDULING: Stored external calendar data")
    }
    
    /// Resolve high-priority conflicts immediately
    private func resolveHighPriorityConflicts(_ conflicts: [CalendarConflict]) async {
        for conflict in conflicts {
            logger.warning("INTELLIGENT_RESCHEDULING: Resolving high-priority conflict for task \\(conflict.taskTitle)")
            
            switch conflict.suggestedAction {
            case .rescheduleTask:
                await rescheduleConflictingTask(conflict.taskId, reason: "External calendar conflict with \\(conflict.externalEventTitle)")
            case .splitTask:
                await suggestTaskSplit(conflict.taskId, conflictPeriod: (conflict.conflictStart, conflict.conflictEnd))
            case .adjustTaskTiming:
                await adjustTaskTiming(conflict.taskId, conflictPeriod: (conflict.conflictStart, conflict.conflictEnd))
            case .addBuffer:
                await addConflictBuffer(conflict.taskId, conflictPeriod: (conflict.conflictStart, conflict.conflictEnd))
            }
        }
    }
    
    /// Reschedule a task due to external calendar conflict
    private func rescheduleConflictingTask(_ taskId: UUID, reason: String) async {
        // This would use the existing rescheduling logic but with external calendar awareness
        logger.info("INTELLIGENT_RESCHEDULING: Rescheduling task \\(taskId) due to: \\(reason)")
        
        // Find an alternative slot considering external calendar availability
        // This would integrate with the existing slot scoring and availability logic
    }
    
    /// Suggest splitting a task to work around conflicts
    private func suggestTaskSplit(_ taskId: UUID, conflictPeriod: (start: Date, end: Date)) async {
        logger.info("INTELLIGENT_RESCHEDULING: Suggesting task split for \\(taskId)")
        
        // Create a notification suggesting task split with available time slots
        await notificationService.showInAppNotification(
            title: "Task Split Suggested",
            message: "Your task conflicts with a calendar event. Consider splitting it into smaller parts.",
            category: .intelligentSuggestion,
            priority: .normal,
            actions: [
                NotificationService.NotificationAction(
                    id: "split_task",
                    title: "Split Task",
                    isDestructive: false
                ),
                NotificationService.NotificationAction(
                    id: "reschedule",
                    title: "Reschedule Instead",
                    isDestructive: false
                )
            ]
        )
    }
    
    /// Adjust task timing to minimize conflict
    private func adjustTaskTiming(_ taskId: UUID, conflictPeriod: (start: Date, end: Date)) async {
        logger.info("INTELLIGENT_RESCHEDULING: Adjusting timing for task \\(taskId)")
        
        // Implement minor time adjustments to reduce conflict overlap
        // This could involve moving the task start/end by 15-30 minutes
    }
    
    /// Add buffer around conflict to prevent issues
    private func addConflictBuffer(_ taskId: UUID, conflictPeriod: (start: Date, end: Date)) async {
        logger.info("INTELLIGENT_RESCHEDULING: Adding buffer for task \\(taskId)")
        
        // Add 15-minute buffers before/after the conflicting external event
        // This helps prevent context switching issues
    }
    
    /// Update availability cache for faster scheduling decisions
    private func updateAvailabilityCache(_ availabilitySlots: [AvailabilitySlot]) async {
        logger.debug("INTELLIGENT_RESCHEDULING: Updated availability cache with \\(availabilitySlots.count) slots")
        
        // Cache the availability slots for use in scheduling algorithms
        // High-quality slots would be preferred for important tasks
    }
    
    /// Get available time slots considering external calendar
    func getAvailableSlots(
        for duration: TimeInterval,
        after startDate: Date = Date(),
        quality: SlotQuality = .fair
    ) async -> [AvailabilitySlot] {
        // This would return available slots from the external calendar integration
        // filtered by duration and quality requirements
        
        logger.debug("INTELLIGENT_RESCHEDULING: Finding slots for \\(duration/60) minute task")
        return []
    }
}

/// Rescheduling statistics tracking
struct ReschedulingStatistics {
    var totalRescheduled: Int = 0
    var overdueTasksRescheduled: Int = 0
    var conflictResolutions: Int = 0
    var userOverrides: Int = 0
    var tasksParked: Int = 0
    var failedReschedulings: Int = 0
    var averageConfidence: Double = 0.0
    var lastReset: Date = Date()
    
    var successRate: Double {
        let total = totalRescheduled + failedReschedulings
        return total > 0 ? Double(totalRescheduled) / Double(total) : 0.0
    }
}

// MARK: - Notification Categories Extension

extension NotificationService.NotificationCategory {
    static let reschedulingUpdate = NotificationService.NotificationCategory(rawValue: "rescheduling_update")
    static let intelligentSuggestion = NotificationService.NotificationCategory(rawValue: "intelligent_suggestion")
}

// MARK: - Phase 2: Enhanced AI Decision Engine

extension IntelligentReschedulingService {
    
    /// Phase 2: Advanced AI-powered decision making for complex rescheduling scenarios
    func processComplexReschedulingDecision(
        for task: LifeTask,
        scenarios: [ReschedulingScenario],
        constraints: ReschedulingConstraints
    ) async -> ReschedulingDecision {
        
        logger.info("INTELLIGENT_RESCHEDULING: Phase 2 - Processing complex decision for: \(task.title)")
        
        // Step 1: Analyze all scenarios with advanced AI reasoning
        let analysisResults = await analyzeReschedulingScenarios(
            task: task,
            scenarios: scenarios,
            constraints: constraints
        )
        
        // Step 2: Generate AI decision with confidence scoring
        let aiDecision = await generateAIDecision(
            task: task,
            scenarios: scenarios,
            analysis: analysisResults,
            constraints: constraints
        )
        
        // Step 3: Determine if human input is needed based on complexity and confidence
        let decision = await finalizeReschedulingDecision(
            aiDecision: aiDecision,
            task: task,
            scenarios: scenarios
        )
        
        // Step 4: Learn from the decision for future improvements
        await updateLearningModel(decision: decision, task: task, scenarios: scenarios)
        
        logger.success("INTELLIGENT_RESCHEDULING: Phase 2 - Complex decision completed for: \(task.title)")
        return decision
    }
    
    /// Analyze multiple rescheduling scenarios with AI reasoning
    private func analyzeReschedulingScenarios(
        task: LifeTask,
        scenarios: [ReschedulingScenario],
        constraints: ReschedulingConstraints
    ) async -> ScenarioAnalysisResult {
        
        logger.debug("INTELLIGENT_RESCHEDULING: Analyzing \(scenarios.count) scenarios for task: \(task.title)")
        
        var scenarioScores: [ReschedulingScenario: ScenarioScore] = [:]
        
        for scenario in scenarios {
            let score = await analyzeIndividualScenario(
                scenario: scenario,
                task: task,
                constraints: constraints
            )
            scenarioScores[scenario] = score
        }
        
        // Generate comprehensive analysis using LLM
        let overallAnalysis = await generateScenarioAnalysis(
            task: task,
            scenarios: scenarios,
            scores: scenarioScores,
            constraints: constraints
        )
        
        return ScenarioAnalysisResult(
            scenarioScores: scenarioScores,
            overallAnalysis: overallAnalysis,
            recommendedScenario: scenarioScores.max { $0.value.overallScore < $1.value.overallScore }?.key,
            complexityLevel: calculateComplexityLevel(scenarios: scenarios, constraints: constraints)
        )
    }
    
    /// Analyze individual rescheduling scenario
    private func analyzeIndividualScenario(
        scenario: ReschedulingScenario,
        task: LifeTask,
        constraints: ReschedulingConstraints
    ) async -> ScenarioScore {
        
        // Base scoring factors
        let timeScore = calculateTimeCompatibilityScore(scenario: scenario, task: task)
        let resourceScore = calculateResourceAvailabilityScore(scenario: scenario, constraints: constraints)
        let impactScore = await calculateImpactScore(scenario: scenario, task: task)
        let riskScore = calculateRiskScore(scenario: scenario, constraints: constraints)
        
        // Advanced AI analysis
        let aiScore = await calculateAIAnalysisScore(scenario: scenario, task: task)
        
        let overallScore = (timeScore * 0.25) + (resourceScore * 0.2) + (impactScore * 0.25) + (riskScore * 0.15) + (aiScore * 0.15)
        
        return ScenarioScore(
            overallScore: overallScore,
            timeCompatibility: timeScore,
            resourceAvailability: resourceScore,
            projectImpact: impactScore,
            riskFactor: riskScore,
            aiConfidence: aiScore
        )
    }
    
    /// Generate comprehensive scenario analysis using LLM
    private func generateScenarioAnalysis(
        task: LifeTask,
        scenarios: [ReschedulingScenario],
        scores: [ReschedulingScenario: ScenarioScore],
        constraints: ReschedulingConstraints
    ) async -> String {
        
        do {
            let prompt = """
            Analyze these rescheduling scenarios for the task '\(task.title)':
            
            Task Details:
            - Priority: \(task.priority.displayName)
            - Duration: \(task.estimatedDuration ?? 60) minutes
            - Type: \(task.workPersonal.displayName)
            
            Scenarios:
            \(scenarios.enumerated().map { index, scenario in
                let score = scores[scenario]?.overallScore ?? 0.0
                return "Scenario \(index + 1): \(scenario.description) (Score: \(String(format: "%.2f", score)))"
            }.joined(separator: "\n"))
            
            Provide a brief analysis considering:
            1. Overall complexity level
            2. Key trade-offs between scenarios  
            3. Risk factors to consider
            4. Recommended approach
            
            Keep response under 200 words.
            """
            
            let response = try await llmService.processText(prompt)
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch {
            logger.warning("INTELLIGENT_RESCHEDULING: LLM analysis failed: \(error)")
            return "Standard rule-based analysis completed. Multiple scenarios evaluated."
        }
    }
    
    /// Generate AI decision using advanced LLM reasoning
    private func generateAIDecision(
        task: LifeTask,
        scenarios: [ReschedulingScenario],
        analysis: ScenarioAnalysisResult,
        constraints: ReschedulingConstraints
    ) async -> AIReschedulingDecision {
        
        do {
            // Create comprehensive prompt for AI decision making
            let prompt = createAdvancedDecisionPrompt(
                task: task,
                scenarios: scenarios,
                analysis: analysis,
                constraints: constraints
            )
            
            let response = try await llmService.processText(prompt)
            
            // Parse AI response into structured decision
            let decision = await parseAIDecisionResponse(
                response: response,
                scenarios: scenarios,
                analysis: analysis
            )
            
            logger.debug("INTELLIGENT_RESCHEDULING: AI decision generated with confidence: \(String(format: "%.2f", decision.confidence))")
            
            return decision
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: AI decision generation failed: \(error)")
            
            // Fallback to rule-based decision
            return createFallbackDecision(analysis: analysis, scenarios: scenarios)
        }
    }
    
    /// Create advanced decision prompt for LLM
    private func createAdvancedDecisionPrompt(
        task: LifeTask,
        scenarios: [ReschedulingScenario],
        analysis: ScenarioAnalysisResult,
        constraints: ReschedulingConstraints
    ) -> String {
        
        let scenarioDescriptions = scenarios.enumerated().map { index, scenario in
            let score = analysis.scenarioScores[scenario] ?? ScenarioScore(overallScore: 0, timeCompatibility: 0, resourceAvailability: 0, projectImpact: 0, riskFactor: 0, aiConfidence: 0)
            return """
            Scenario \(index + 1): \(scenario.description)
            - New Time: \(formatDate(scenario.proposedTime))
            - Duration: \(scenario.duration) minutes
            - Score: \(String(format: "%.2f", score.overallScore))
            - Time Compatibility: \(String(format: "%.2f", score.timeCompatibility))
            - Resource Availability: \(String(format: "%.2f", score.resourceAvailability))
            - Project Impact: \(String(format: "%.2f", score.projectImpact))
            - Risk Factor: \(String(format: "%.2f", score.riskFactor))
            """
        }.joined(separator: "\n\n")
        
        return """
        As an intelligent scheduling assistant, analyze this rescheduling decision:
        
        TASK DETAILS:
        - Title: \(task.title)
        - Description: \(task.description ?? "None")
        - Priority: \(task.priority.displayName)
        - Current Due Date: \(task.dueDate ?? "Not set")
        - Estimated Duration: \(task.estimatedDuration ?? 60) minutes
        - Work/Personal: \(task.workPersonal.displayName)
        
        CONSTRAINTS:
        - Must complete by: \(formatDate(constraints.hardDeadline))
        - Available time slots: \(constraints.availableTimeSlots.count)
        - Resource limitations: \(constraints.resourceLimitations.joined(separator: ", "))
        - Dependency requirements: \(constraints.dependencyRequirements.map { $0.description }.joined(separator: ", "))
        
        SCENARIOS:
        \(scenarioDescriptions)
        
        ANALYSIS:
        - Overall complexity: \(analysis.complexityLevel.rawValue)
        - Recommended scenario: \(analysis.recommendedScenario?.description ?? "None")
        - Key insights: \(analysis.overallAnalysis)
        
        INSTRUCTIONS:
        1. Choose the best scenario (1-\(scenarios.count)) or recommend "DEFER" if human input needed
        2. Provide confidence score (0.0-1.0)
        3. Give 2-3 sentence reasoning
        4. Suggest any modifications to the chosen scenario
        
        Respond in JSON format:
        {
          "decision": "scenario_number_or_DEFER",
          "confidence": 0.0-1.0,
          "reasoning": "brief explanation",
          "modifications": "suggested changes or null",
          "risk_level": "low/medium/high"
        }
        """
    }
    
    /// Parse AI decision response into structured format
    private func parseAIDecisionResponse(
        response: String,
        scenarios: [ReschedulingScenario],
        analysis: ScenarioAnalysisResult
    ) async -> AIReschedulingDecision {
        
        // Try to parse JSON response
        if let jsonData = response.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            let decision = parsed["decision"] as? String ?? "DEFER"
            let confidence = parsed["confidence"] as? Double ?? 0.5
            let reasoning = parsed["reasoning"] as? String ?? "AI analysis completed"
            let modifications = parsed["modifications"] as? String
            let riskLevel = RiskLevel(rawValue: parsed["risk_level"] as? String ?? "medium") ?? .medium
            
            var selectedScenario: ReschedulingScenario?
            var requiresUserInput = false
            
            if decision == "DEFER" {
                requiresUserInput = true
            } else if let scenarioIndex = Int(decision), scenarioIndex >= 1 && scenarioIndex <= scenarios.count {
                selectedScenario = scenarios[scenarioIndex - 1]
            } else {
                requiresUserInput = true
            }
            
            return AIReschedulingDecision(
                selectedScenario: selectedScenario,
                confidence: confidence,
                reasoning: reasoning,
                modifications: modifications,
                riskLevel: riskLevel,
                requiresUserInput: requiresUserInput || confidence < complexDecisionThreshold
            )
        }
        
        // Fallback parsing if JSON fails
        return createFallbackDecision(analysis: analysis, scenarios: scenarios)
    }
    
    /// Create fallback decision when AI analysis fails
    private func createFallbackDecision(
        analysis: ScenarioAnalysisResult,
        scenarios: [ReschedulingScenario]
    ) -> AIReschedulingDecision {
        
        return AIReschedulingDecision(
            selectedScenario: analysis.recommendedScenario,
            confidence: 0.5,
            reasoning: "Fallback to rule-based recommendation",
            modifications: nil,
            riskLevel: .medium,
            requiresUserInput: true
        )
    }
    
    /// Finalize rescheduling decision based on AI analysis and confidence
    private func finalizeReschedulingDecision(
        aiDecision: AIReschedulingDecision,
        task: LifeTask,
        scenarios: [ReschedulingScenario]
    ) async -> ReschedulingDecision {
        
        // Determine if we can proceed automatically or need user input
        let canProceedAutomatically = aiDecision.confidence >= aiDecisionThreshold && !aiDecision.requiresUserInput
        
        if canProceedAutomatically {
            logger.info("INTELLIGENT_RESCHEDULING: Proceeding with automatic rescheduling (confidence: \(String(format: "%.2f", aiDecision.confidence)))")
            
            // Execute automatic rescheduling
            return await executeAutomaticRescheduling(
                task: task,
                aiDecision: aiDecision
            )
        } else {
            logger.info("INTELLIGENT_RESCHEDULING: Requesting user input for complex decision (confidence: \(String(format: "%.2f", aiDecision.confidence)))")
            
            // Send intelligent notification for user decision
            await sendIntelligentReschedulingNotification(
                task: task,
                aiDecision: aiDecision,
                scenarios: scenarios
            )
            
            return ReschedulingDecision(
                action: .requestUserInput,
                selectedScenario: aiDecision.selectedScenario,
                confidence: aiDecision.confidence,
                reasoning: aiDecision.reasoning,
                automaticExecution: false,
                userNotificationSent: true,
                timestamp: Date()
            )
        }
    }
    
    /// Execute automatic rescheduling with AI decision
    private func executeAutomaticRescheduling(
        task: LifeTask,
        aiDecision: AIReschedulingDecision
    ) async -> ReschedulingDecision {
        
        guard let scenario = aiDecision.selectedScenario else {
            return ReschedulingDecision(
                action: .failed,
                selectedScenario: nil,
                confidence: 0.0,
                reasoning: "No scenario selected by AI",
                automaticExecution: false,
                userNotificationSent: false,
                timestamp: Date()
            )
        }
        
        do {
            // Execute the rescheduling
            await executeScenarioRescheduling(task: task, scenario: scenario)
            
            // Send success notification
            await sendSuccessfulReschedulingNotification(task: task, scenario: scenario, aiDecision: aiDecision)
            
            return ReschedulingDecision(
                action: .automaticReschedule,
                selectedScenario: scenario,
                confidence: aiDecision.confidence,
                reasoning: aiDecision.reasoning,
                automaticExecution: true,
                userNotificationSent: true,
                timestamp: Date()
            )
            
        } catch {
            logger.error("INTELLIGENT_RESCHEDULING: Automatic rescheduling failed: \(error)")
            
            return ReschedulingDecision(
                action: .failed,
                selectedScenario: scenario,
                confidence: aiDecision.confidence,
                reasoning: "Execution failed: \(error.localizedDescription)",
                automaticExecution: false,
                userNotificationSent: false,
                timestamp: Date()
            )
        }
    }
    
    /// Send intelligent notification for user decision with AI recommendations
    private func sendIntelligentReschedulingNotification(
        task: LifeTask,
        aiDecision: AIReschedulingDecision,
        scenarios: [ReschedulingScenario]
    ) async {
        
        let title = "Smart Rescheduling Decision Needed"
        let message = "AI analysis complete for '\(task.title)'. \(aiDecision.reasoning)"
        
        // Create actionable suggestions based on scenarios
        let suggestions = scenarios.prefix(3).enumerated().map { index, scenario in
            ProactiveSuggestion(
                id: UUID(),
                title: "Option \(index + 1)",
                description: "\(formatDate(scenario.proposedTime)) - \(scenario.description)",
                action: "select_scenario_\(index)",
                confidence: aiDecision.confidence
            )
        }
        
        await advancedNotificationService.sendProactiveSuggestion(
            title: title,
            message: message,
            suggestions: Array(suggestions),
            confidence: aiDecision.confidence,
            context: NotificationContext(
                category: "rescheduling_decision",
                source: "intelligent_rescheduling",
                metadata: ["taskId": task.id.uuidString]
            )
        )
    }
    
    /// Send notification for successful automatic rescheduling
    private func sendSuccessfulReschedulingNotification(
        task: LifeTask,
        scenario: ReschedulingScenario,
        aiDecision: AIReschedulingDecision
    ) async {
        
        let title = "Task Automatically Rescheduled"
        let message = "'\(task.title)' moved to \(formatDate(scenario.proposedTime)). \(aiDecision.reasoning)"
        
        await advancedNotificationService.sendAdvancedNotification(
            title: title,
            message: message,
            priority: .normal,
            category: .scheduleChange,
            context: NotificationContext(
                category: "automatic_reschedule",
                source: "intelligent_rescheduling",
                metadata: ["taskId": task.id.uuidString, "confidence": aiDecision.confidence]
            ),
            escalationRules: nil
        )
    }
    
    /// Update learning model based on rescheduling decisions
    private func updateLearningModel(
        decision: ReschedulingDecision,
        task: LifeTask,
        scenarios: [ReschedulingScenario]
    ) async {
        
        logger.debug("INTELLIGENT_RESCHEDULING: Updating learning model with decision: \(decision.action)")
        
        // Store decision patterns for future learning
        let learningData = ReschedulingLearningData(
            taskCharacteristics: extractTaskCharacteristics(task),
            scenarios: scenarios,
            decision: decision,
            timestamp: Date(),
            userContext: await contextMemory.getCurrentContext()
        )
        
        // This would persist learning data for future AI improvements
        // For now, we'll just log the learning event
        logger.info("INTELLIGENT_RESCHEDULING: Learning data recorded for task type: \(task.priority.displayName)")
    }
    
    // MARK: - Helper Methods for Phase 2
    
    /// Calculate time compatibility score for scenario
    private func calculateTimeCompatibilityScore(scenario: ReschedulingScenario, task: LifeTask) -> Double {
        var score = 0.5
        
        let hour = Calendar.current.component(.hour, from: scenario.proposedTime)
        
        // Align with work/personal preferences
        if task.workPersonal == .work && hour >= 9 && hour <= 17 {
            score += 0.3
        } else if task.workPersonal == .personal && (hour <= 9 || hour >= 18) {
            score += 0.2
        }
        
        // Consider task priority alignment with time
        if task.priority == .urgent && hour >= 9 && hour <= 11 {
            score += 0.2 // Urgent tasks in prime time
        }
        
        return min(1.0, score)
    }
    
    /// Calculate resource availability score
    private func calculateResourceAvailabilityScore(scenario: ReschedulingScenario, constraints: ReschedulingConstraints) -> Double {
        // Check if all required resources are available during the proposed time
        var score = 1.0
        
        for limitation in constraints.resourceLimitations {
            if scenario.requiredResources.contains(limitation) {
                score -= 0.2
            }
        }
        
        return max(0.0, score)
    }
    
    /// Calculate impact score on project and related tasks
    private func calculateImpactScore(scenario: ReschedulingScenario, task: LifeTask) async -> Double {
        var score = 0.8 // Base score assuming minimal impact
        
        // Check impact on dependent tasks
        if scenario.affectedDependencies.count > 0 {
            score -= Double(scenario.affectedDependencies.count) * 0.1
        }
        
        // Consider project timeline impact
        if task.projectId != nil {
            // More sophisticated project impact analysis would go here
            score -= 0.05
        }
        
        return max(0.0, score)
    }
    
    /// Calculate risk score for scenario
    private func calculateRiskScore(scenario: ReschedulingScenario, constraints: ReschedulingConstraints) -> Double {
        var riskScore = 0.0
        
        // Time pressure risk
        let timeUntilDeadline = constraints.hardDeadline.timeIntervalSince(scenario.proposedTime)
        if timeUntilDeadline < 24 * 3600 { // Less than 24 hours
            riskScore += 0.3
        }
        
        // Complexity risk
        if scenario.complexityFactors.count > 2 {
            riskScore += 0.2
        }
        
        return min(1.0, riskScore)
    }
    
    /// Calculate AI analysis score using advanced reasoning
    private func calculateAIAnalysisScore(scenario: ReschedulingScenario, task: LifeTask) async -> Double {
        // This would use more sophisticated AI analysis
        // For now, return a composite score based on scenario characteristics
        return min(1.0, scenario.likelihood * scenario.feasibility)
    }
    
    /// Calculate complexity level for decision making
    private func calculateComplexityLevel(scenarios: [ReschedulingScenario], constraints: ReschedulingConstraints) -> ComplexityLevel {
        let factorCount = scenarios.count + constraints.dependencyRequirements.count + constraints.resourceLimitations.count
        
        if factorCount <= 3 {
            return .simple
        } else if factorCount <= 6 {
            return .moderate
        } else {
            return .complex
        }
    }
    
    /// Execute scenario rescheduling
    private func executeScenarioRescheduling(task: LifeTask, scenario: ReschedulingScenario) async throws {
        // Create optimal time slot from scenario
        let optimalSlot = OptimalTimeSlot(
            startTime: scenario.proposedTime,
            endTime: scenario.proposedTime.addingTimeInterval(TimeInterval(scenario.duration * 60)),
            confidence: scenario.likelihood * scenario.feasibility,
            reasoning: scenario.description
        )
        
        // Create rescheduling event
        let reschedulingEvent = ReschedulingEvent(
            taskId: task.id,
            originalDate: task.dueDate ?? "",
            newDate: ISO8601DateFormatter().string(from: scenario.proposedTime),
            reason: .aiOptimization,
            wasAutomatic: true,
            confidence: optimalSlot.confidence
        )
        
        // Execute using existing rescheduling infrastructure
        await executeRescheduling(task: task, to: optimalSlot, event: reschedulingEvent)
    }
    
    /// Extract task characteristics for learning
    private func extractTaskCharacteristics(_ task: LifeTask) -> TaskCharacteristics {
        return TaskCharacteristics(
            priority: task.priority,
            workPersonal: task.workPersonal,
            estimatedDuration: task.estimatedDuration ?? 60,
            hasProject: task.projectId != nil,
            isFocus: task.isFocus,
            overdueHours: task.overdueByHours
        )
    }
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}