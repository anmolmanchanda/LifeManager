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
    
    // MARK: - Configuration
    
    private let monitoringInterval: TimeInterval = 300 // 5 minutes
    private let maxReschedulingCascade = 5
    private let reschedulingConfidenceThreshold = 0.7
    
    // MARK: - Initialization
    
    init() {
        logger.info("INTELLIGENT_RESCHEDULING: Service initialized")
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
        
        do {
            // Step 1: Calculate priority intelligence
            let priorityIntelligence = await calculatePriorityIntelligence(for: task)
            
            // Step 2: Find optimal rescheduling slot
            let optimalSlot = await findOptimalReschedulingSlot(
                for: task,
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
        for task: LifeTask,
        priorityIntelligence: PriorityIntelligence
    ) async -> OptimalTimeSlot? {
        
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
            // Skip weekends for work tasks (unless user preferences indicate otherwise)
            let weekday = calendar.component(.weekday, currentDate)
            if task.workPersonal == .work && (weekday == 1 || weekday == 7) {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                continue
            }
            
            // Generate slots throughout the day
            let workDayStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: currentDate) ?? currentDate
            let workDayEnd = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: currentDate) ?? currentDate
            
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
        
        // Time of day preferences
        let hour = Calendar.current.component(.hour, from: slot.startTime)
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
            
            // Record rescheduling event (this would need a repository implementation)
            // await reschedulingEventRepository.create(event)
            
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