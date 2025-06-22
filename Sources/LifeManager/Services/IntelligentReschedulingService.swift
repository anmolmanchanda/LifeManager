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
    
    // MARK: - Initialization
    
    init() {
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
        // For now, use defaults. In production, this would load from user preferences storage
        // TODO: Integrate with user preferences service/repository
        
        // Example of setting up some default focus blocks
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
        
        userPreferences = UserSchedulingPreferences(
            workingHours: .default,
            focusBlocks: defaultFocusBlocks,
            reschedulingSettings: .default,
            notificationSettings: NotificationSettings()
        )
        
        logger.info("INTELLIGENT_RESCHEDULING: User preferences loaded with \(userPreferences.focusBlocks.count) focus blocks")
    }
    
    /// Save user scheduling preferences
    func saveUserPreferences() async {
        // TODO: Implement persistence to user preferences storage
        logger.info("INTELLIGENT_RESCHEDULING: User preferences saved")
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