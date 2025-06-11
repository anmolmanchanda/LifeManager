import Foundation
import SwiftUI
import Combine

/// Calendar view model managing calendar state and operations
@MainActor
class CalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var viewMode: CalendarViewMode = .week
    @Published var selectedDate: Date = Date()
    @Published var events: [CalendarEvent] = []
    @Published var unscheduledTasks: [LifeTask] = []
    @Published var filter: CalendarFilter = CalendarFilter()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingFilters = false
    @Published var showingAutoSchedule = false
    @Published var autoScheduleEnabled = false
    
    // Motion AI-style features
    @Published var smartSchedulingEnabled = true
    @Published var lockedTimeBlocks: [CalendarEvent] = []
    @Published var workingHours: ClosedRange<Int> = 9...18
    @Published var focusTimeBlocks: [CalendarEvent] = []
    
    // Drag and drop state
    @Published var draggingTask: LifeTask?
    @Published var dragOffset: CGSize = .zero
    @Published var dropTargetDate: Date?
    
    // MARK: - Private Properties
    
    private let taskRepository = TaskRepository()
    private let projectRepository = ProjectRepository()
    private let areaRepository = AreaRepository()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Get current date range based on view mode
    var currentDateRange: (start: Date, end: Date) {
        switch viewMode {
        case .day:
            return (selectedDate.startOfDay, selectedDate.endOfDay)
        case .week:
            return (selectedDate.startOfWeek, selectedDate.endOfWeek)
        case .month:
            return (selectedDate.startOfMonth, selectedDate.endOfMonth)
        }
    }
    
    /// Get filtered events for current view
    var filteredEvents: [CalendarEvent] {
        let range = currentDateRange
        return events.filter { event in
            event.startDate >= range.start && event.startDate <= range.end &&
            passesFilter(event)
        }
    }
    
    /// Get filtered unscheduled tasks
    var filteredUnscheduledTasks: [LifeTask] {
        return unscheduledTasks.filter { task in
            passesTaskFilter(task)
        }
    }
    
    /// Check if any filters are active
    var hasActiveFilters: Bool {
        filter.isActive
    }
    
    // MARK: - Initialization
    
    init() {
        setupAutoRefresh()
    }
    
    // MARK: - Public Methods
    
    /// Load calendar data
    func loadCalendarData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load tasks and convert to events
            let tasks = try await taskRepository.fetchAllTasks()
            let scheduledTasks = tasks.filter { $0.dueDate != nil && !$0.isArchived }
            let unscheduled = tasks.filter { $0.dueDate == nil && !$0.isArchived && $0.status != .completed }
            
            // Convert scheduled tasks to calendar events
            let taskEvents = scheduledTasks.compactMap { $0.toCalendarEvent() }
            
            // Load locked time blocks and focus blocks
            let lockedBlocks = await loadLockedTimeBlocks()
            let focusBlocks = await loadFocusTimeBlocks()
            
            await MainActor.run {
                self.events = taskEvents + lockedBlocks + focusBlocks
                self.unscheduledTasks = unscheduled
                self.lockedTimeBlocks = lockedBlocks
                self.focusTimeBlocks = focusBlocks
                self.isLoading = false
            }
            
            // Auto-schedule if enabled
            if autoScheduleEnabled {
                await autoScheduleUnscheduledTasks()
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load calendar data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Change view mode
    func changeViewMode(_ mode: CalendarViewMode) {
        viewMode = mode
    }
    
    /// Navigate to previous period
    func navigatePrevious() {
        switch viewMode {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    /// Navigate to next period
    func navigateNext() {
        switch viewMode {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
    
    /// Go to today
    func goToToday() {
        selectedDate = Date()
    }
    
    /// Schedule task at specific time
    func scheduleTask(_ task: LifeTask, at date: Date) async {
        guard let duration = task.estimatedDuration else { return }
        
        let endDate = date.addingTimeInterval(TimeInterval(duration * 60))
        
        // Check for conflicts
        let conflicts = events.filter { event in
            event.startDate < endDate && event.endDate > date
        }
        
        if !conflicts.isEmpty && !conflicts.allSatisfy({ !$0.isLocked }) {
            errorMessage = "Cannot schedule task: conflicts with locked time block"
            return
        }
        
        do {
            // Update task with new due date
            let updatedTask = LifeTask(
                id: task.id,
                blobId: task.blobId,
                title: task.title,
                description: task.description,
                priority: task.priority,
                status: task.status,
                dueDate: ISO8601DateFormatter().string(from: date),
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
                archivedAt: task.archivedAt
            )
            
            _ = try await taskRepository.updateTask(updatedTask)
            
            // Refresh calendar data
            await loadCalendarData()
            
        } catch {
            errorMessage = "Failed to schedule task: \(error.localizedDescription)"
        }
    }
    
    /// Reschedule existing event
    func rescheduleEvent(_ event: CalendarEvent, to newDate: Date) async {
        guard let taskId = event.taskId else { return }
        
        do {
            if let task = try await taskRepository.fetchTask(id: taskId) {
                await scheduleTask(task, at: newDate)
            }
        } catch {
            errorMessage = "Failed to reschedule event: \(error.localizedDescription)"
        }
    }
    
    /// Auto-schedule unscheduled tasks using Motion AI-style logic
    func autoScheduleUnscheduledTasks() async {
        guard !unscheduledTasks.isEmpty else { return }
        
        let range = currentDateRange
        let availableSlots = SmartScheduler.generateAvailableSlots(
            from: range.start,
            to: range.end,
            existingEvents: events,
            workingHours: workingHours
        )
        
        let newEvents = SmartScheduler.autoScheduleTasks(
            unscheduled: unscheduledTasks,
            existingEvents: events,
            availableSlots: availableSlots,
            workingHours: workingHours
        )
        
        // Update tasks in database
        for event in newEvents {
            if let taskId = event.taskId,
               let task = unscheduledTasks.first(where: { $0.id == taskId }) {
                await scheduleTask(task, at: event.startDate)
            }
        }
    }
    
    /// Create locked time block
    func createLockedTimeBlock(
        title: String,
        startDate: Date,
        duration: Int,
        description: String? = nil
    ) async {
        let endDate = startDate.addingTimeInterval(TimeInterval(duration * 60))
        
        let lockedBlock = CalendarEvent(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            type: CalendarEventType.timeBlock,
            priority: TaskPriority.high,
            workPersonal: WorkPersonalType.work,
            projectId: nil,
            areaId: nil,
            taskId: nil,
            isLocked: true,
            color: Color.gray
        )
        
        lockedTimeBlocks.append(lockedBlock)
        events.append(lockedBlock)
        
        // TODO: Persist locked time blocks to database
    }
    
    /// Create focus time block
    func createFocusTimeBlock(
        title: String,
        startDate: Date,
        duration: Int,
        projectId: UUID? = nil
    ) async {
        let endDate = startDate.addingTimeInterval(TimeInterval(duration * 60))
        
        let focusBlock = CalendarEvent(
            title: title,
            description: "Deep focus time",
            startDate: startDate,
            endDate: endDate,
            type: CalendarEventType.timeBlock,
            priority: TaskPriority.high,
            workPersonal: WorkPersonalType.work,
            projectId: projectId,
            areaId: nil,
            taskId: nil,
            isLocked: false,
            color: Color.green
        )
        
        focusTimeBlocks.append(focusBlock)
        events.append(focusBlock)
        
        // TODO: Persist focus time blocks to database
    }
    
    /// Update filter settings
    func updateFilter(_ newFilter: CalendarFilter) {
        filter = newFilter
    }
    
    /// Clear all filters
    func clearFilters() {
        filter = CalendarFilter()
    }
    
    /// Toggle auto-scheduling
    func toggleAutoSchedule() {
        autoScheduleEnabled.toggle()
        if autoScheduleEnabled {
            Task {
                await autoScheduleUnscheduledTasks()
            }
        }
    }
    
    // MARK: - Drag and Drop Methods
    
    /// Start dragging a task
    func startDragging(_ task: LifeTask) {
        draggingTask = task
        dragOffset = .zero
    }
    
    /// Update drag position
    func updateDragPosition(_ offset: CGSize) {
        dragOffset = offset
    }
    
    /// Handle drop on date
    func handleDrop(on date: Date) async {
        guard let task = draggingTask else { return }
        
        await scheduleTask(task, at: date)
        
        // Reset drag state
        draggingTask = nil
        dragOffset = .zero
        dropTargetDate = nil
    }
    
    /// Cancel drag operation
    func cancelDrag() {
        draggingTask = nil
        dragOffset = .zero
        dropTargetDate = nil
    }
    
    // MARK: - Private Methods
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        // Refresh every minute to keep calendar current
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.loadCalendarData()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Check if event passes current filter
    private func passesFilter(_ event: CalendarEvent) -> Bool {
        // Project filter
        if !filter.selectedProjects.isEmpty {
            guard let projectId = event.projectId,
                  filter.selectedProjects.contains(projectId) else {
                return false
            }
        }
        
        // Area filter
        if !filter.selectedAreas.isEmpty {
            guard let areaId = event.areaId,
                  filter.selectedAreas.contains(areaId) else {
                return false
            }
        }
        
        // Priority filter
        if !filter.selectedPriorities.isEmpty {
            guard filter.selectedPriorities.contains(event.priority) else {
                return false
            }
        }
        
        // Work/Personal filter
        if let workPersonalFilter = filter.workPersonalFilter {
            guard event.workPersonal == workPersonalFilter else {
                return false
            }
        }
        
        // Focus filter
        if filter.showOnlyFocus {
            guard event.type == .timeBlock || 
                  (event.taskId != nil && events.contains { $0.taskId == event.taskId && $0.type == .timeBlock }) else {
                return false
            }
        }
        
        return true
    }
    
    /// Check if task passes current filter
    private func passesTaskFilter(_ task: LifeTask) -> Bool {
        // Project filter
        if !filter.selectedProjects.isEmpty {
            guard let projectId = task.projectId,
                  filter.selectedProjects.contains(projectId) else {
                return false
            }
        }
        
        // Area filter
        if !filter.selectedAreas.isEmpty {
            guard let areaId = task.areaId,
                  filter.selectedAreas.contains(areaId) else {
                return false
            }
        }
        
        // Priority filter
        if !filter.selectedPriorities.isEmpty {
            guard filter.selectedPriorities.contains(task.priority) else {
                return false
            }
        }
        
        // Work/Personal filter
        if let workPersonalFilter = filter.workPersonalFilter {
            guard task.workPersonal == workPersonalFilter else {
                return false
            }
        }
        
        // Focus filter
        if filter.showOnlyFocus {
            guard task.isFocus else {
                return false
            }
        }
        
        // Completed filter
        if !filter.showCompleted {
            guard task.status != .completed else {
                return false
            }
        }
        
        return true
    }
    
    /// Load locked time blocks (placeholder - implement with persistence)
    private func loadLockedTimeBlocks() async -> [CalendarEvent] {
        // TODO: Load from database
        return []
    }
    
    /// Load focus time blocks (placeholder - implement with persistence)
    private func loadFocusTimeBlocks() async -> [CalendarEvent] {
        // TODO: Load from database or generate from focus tasks
        return []
    }
}

// MARK: - Calendar Helper Methods

extension CalendarViewModel {
    
    /// Get events for a specific date
    func events(for date: Date) -> [CalendarEvent] {
        let dayStart = date.startOfDay
        let dayEnd = date.endOfDay
        
        return filteredEvents.filter { event in
            event.startDate >= dayStart && event.startDate <= dayEnd
        }.sorted { $0.startDate < $1.startDate }
    }
    
    /// Get events for a specific hour
    func events(for date: Date, hour: Int) -> [CalendarEvent] {
        guard let hourStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date),
              let hourEnd = Calendar.current.date(byAdding: .hour, value: 1, to: hourStart) else {
            return []
        }
        
        return filteredEvents.filter { event in
            event.startDate < hourEnd && event.endDate > hourStart
        }
    }
    
    /// Check if a time slot is available
    func isSlotAvailable(at date: Date, duration: Int) -> Bool {
        let endDate = date.addingTimeInterval(TimeInterval(duration * 60))
        
        return !events.contains { event in
            event.startDate < endDate && event.endDate > date
        }
    }
    
    /// Get suggested time slots for a task
    func suggestedSlots(for task: LifeTask) -> [Date] {
        guard let duration = task.estimatedDuration else { return [] }
        
        let range = currentDateRange
        let availableSlots = SmartScheduler.generateAvailableSlots(
            from: range.start,
            to: range.end,
            existingEvents: events,
            workingHours: workingHours
        )
        
        return availableSlots
            .filter { $0.isAvailable && $0.durationMinutes >= duration }
            .prefix(5) // Top 5 suggestions
            .map { $0.startTime }
    }
    
    /// Format date for current view mode
    func formatDateForView(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        case .week:
            let weekStart = date.startOfWeek
            let weekEnd = date.endOfWeek
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        }
        
        return formatter.string(from: date)
    }
} 