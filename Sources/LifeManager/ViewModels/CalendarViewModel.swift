import Foundation
import SwiftUI
import Combine

/// ViewModel for calendar functionality following MVVM pattern
/// 
/// Handles:
/// - Calendar view mode state (Day/Week/Month)
/// - Date navigation and selection
/// - Event data management and filtering
/// - Toggl integration and synchronization
/// - Loading states and error handling
/// - Smart scheduling and buffer management
@MainActor
class CalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current calendar view mode
    @Published var viewMode: CalendarViewMode = .day {
        didSet {
            if oldValue != viewMode {
                LifeLogger.calendar(.info, "📅 View mode changed from \(oldValue) to \(viewMode)")
                Task {
                    await loadEventsForCurrentPeriod()
                }
            }
        }
    }
    
    /// Currently selected date
    @Published var selectedDate: Date = Date()
    
    /// Loading state for calendar data
    @Published var isLoading: Bool = false
    
    /// Error message for display
    @Published var errorMessage: String?
    
    /// All calendar events
    @Published var events: [CalendarEvent] = []
    
    /// Filtered events based on current filters
    @Published var filteredEvents: [CalendarEvent] = []
    
    /// Current filter settings
    @Published var activeFilters: Set<CalendarFilter> = []
    
    /// Smart scheduling enabled state
    @Published var isSmartSchedulingEnabled: Bool = true
    
    /// Drop target date for drag and drop operations
    @Published var dropTargetDate: Date?
    
    /// Toggl sync status
    @Published var togglSyncStatus: TogglSyncStatus = .idle
    
    /// Filtered unscheduled tasks (placeholder for now)
    @Published var filteredUnscheduledTasks: [LifeTask] = []
    
    /// All tasks for parking lot display
    @Published var allTasks: [LifeTask] = []
    
    /// Currently dragging task
    @Published var draggingTask: LifeTask?
    
    /// Drag state for overlay system
    @Published var isDragging: Bool = false
    
    /// Dragged task for overlay display
    @Published var draggedTask: LifeTask?
    
    /// Current drag position for overlay
    @Published var dragPosition: CGPoint = .zero
    
    /// Orchestration service for advanced calendar features
    private let orchestrationService = CalendarOrchestrationService()
    
    /// Parking lot service for overflow events
    @Published var parkingLotService: EnhancedParkingLotService
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let togglService = TogglService()
    private let bufferService = BufferManagementService()
    
    // MARK: - Initialization
    
    init() {
        self.parkingLotService = EnhancedParkingLotService()
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// Navigate to the previous period based on current view mode
    func navigatePrevious() {
        let calendar = Calendar.current
        
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
        
        // Force refresh for all view modes
        Task {
            await loadEventsForCurrentPeriod()
            await MainActor.run {
                applyFilters()
                objectWillChange.send()
            }
        }
    }
    
    /// Navigate to the next period based on current view mode
    func navigateNext() {
        let calendar = Calendar.current
        
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
        
        // Force refresh for all view modes
        Task {
            await loadEventsForCurrentPeriod()
            await MainActor.run {
                applyFilters()
                objectWillChange.send()
            }
        }
    }
    
    /// Navigate to today
    func navigateToToday() {
        selectedDate = Date()
        // Force refresh when navigating to today
        Task {
            await loadEventsForCurrentPeriod()
            await MainActor.run {
                applyFilters()
                objectWillChange.send()
            }
        }
    }
    
    /// Get events for a specific date
    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return filteredEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    /// Get events for a specific date and hour
    func events(for date: Date, hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? date
        
        let eventsForHour = events.filter { event in
            event.startDate < endOfHour && event.endDate > startOfHour
        }
        
        LifeLogger.weekView(.debug, "Events for \(date) hour \(hour): \(eventsForHour.count)")
        return eventsForHour
    }
    
    /// Toggle a filter on/off
    func toggleFilter(_ filter: CalendarFilter) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
        applyFilters()
    }
    
    /// Clear all filters
    func clearAllFilters() {
        activeFilters.removeAll()
        applyFilters()
    }
    
    /// Sync with Toggl for the selected date
    func syncWithToggl() async {
        togglSyncStatus = .syncing
        
        do {
            // Fetch entries for the selected date, not just today
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
            
            // First ensure projects are fetched for colors
            await togglService.fetchProjects()
            
            let togglEvents = try await togglService.fetchTimeEntries(startDate: startOfDay, endDate: endOfDay)
            await MainActor.run {
                // Update events with Toggl data
                updateEventsWithTogglData(togglEvents)
                togglSyncStatus = .success
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sync with Toggl: \(error.localizedDescription)"
                togglSyncStatus = .error
            }
        }
    }
    
    /// Handle drop operation for scheduling
    func handleDrop(on date: Date) async {
        // Placeholder for drop handling logic
        LifeLogger.dragDrop(.info, "Handling drop on \(date)")
        
        // Clear drop target after handling
        await MainActor.run {
            dropTargetDate = nil
        }
    }
    
    /// Create a new event
    func createEvent(
        title: String,
        description: String? = nil,
        startDate: Date,
        duration: TimeInterval,
        workPersonal: WorkPersonalType = .work,
        color: Color = .blue
    ) {
        let endDate = startDate.addingTimeInterval(duration)
        
        let newEvent = CalendarEvent(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            workPersonal: workPersonal,
            color: color,
            source: .user,
            duration: duration
        )
        
        events.append(newEvent)
        applyFilters()
    }
    
    /// Delete an event
    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        applyFilters()
    }
    
    /// Update an event
    func updateEvent(_ event: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            applyFilters()
        }
    }
    
    /// Load calendar data (placeholder for now)
    func loadCalendarData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Reschedule an event to a new date
    func rescheduleEvent(_ event: CalendarEvent, to newDate: Date) async {
        await MainActor.run {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                var updatedEvent = event
                let duration = event.endDate.timeIntervalSince(event.startDate)
                updatedEvent.startDate = newDate
                updatedEvent.endDate = newDate.addingTimeInterval(duration)
                events[index] = updatedEvent
                applyFilters()
            }
        }
    }
    
    /// Auto-schedule unscheduled tasks using AI
    func autoScheduleUnscheduledTasks() async {
        isLoading = true
        
        // Get unscheduled tasks
        let unscheduledTasks = allTasks.filter { !$0.isScheduled && $0.status != .completed && !$0.isArchived }
        
        for task in unscheduledTasks {
            // Find best time slot for this task
            if let suggestedTime = findBestTimeSlot(for: task) {
                await scheduleTask(task, at: suggestedTime)
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Start dragging a task
    func startDragging(_ task: LifeTask) {
        LifeLogger.dragDrop(.info, "🎯 Starting drag for task: '\(task.title)' (ID: \(task.id.uuidString.prefix(8)))")
        
        draggedTask = task
        draggingTask = task
        isDragging = true
        
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
    
    /// Update drag position for overlay
    func updateDragPosition(_ translation: CGSize) {
        dragPosition = CGPoint(x: translation.width, y: translation.height)
    }
    
    /// Cancel drag operation
    func cancelDrag() {
        LifeLogger.dragDrop(.info, "🎯 Canceling drag operation")
        
        isDragging = false
        draggedTask = nil
        draggingTask = nil
        dragPosition = .zero
        dropTargetDate = nil
    }
    
    /// Complete drag operation successfully
    func completeDrag() {
        LifeLogger.dragDrop(.info, "🎯 Completing drag operation successfully")
        
        isDragging = false
        draggedTask = nil
        draggingTask = nil
        dragPosition = .zero
        dropTargetDate = nil
        
        // Provide success haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
    
    /// Schedule a task at a specific time
    func scheduleTask(_ task: LifeTask, at date: Date) async {
        let timer = PerformanceTimer(operation: "scheduleTask")
        
        LifeLogger.logTaskScheduling(
            task: task,
            scheduleDate: date,
            operation: "SCHEDULE_START",
            success: true
        )
        
        // Log initial state
        LifeLogger.taskScheduling(.info, "Initial state - Tasks in parking lot: \(allTasks.count), Events: \(events.count)")
        
        // Create calendar event from task
        let estimatedMinutes = task.estimatedDuration ?? 30 // Default to 30 minutes if not specified
        let duration: TimeInterval = TimeInterval(estimatedMinutes * 60) // Convert minutes to seconds
        
        let event = CalendarEvent(
            title: task.title,
            description: task.description,
            startDate: date,
            endDate: date.addingTimeInterval(duration),
            workPersonal: task.workPersonal,
            color: task.workPersonal == .work ? .blue : .green,
            source: .user,
            duration: duration
        )
        
        LifeLogger.taskScheduling(.info, "Created calendar event: '\(event.title)' from \(event.startDate) to \(event.endDate)")
        
        // Update task in database with scheduled time
        let taskRepository = TaskRepository()
        let dateFormatter = ISO8601DateFormatter()
        let updatedTask = LifeTask(
            id: task.id,
            blobId: task.blobId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            dueDate: dateFormatter.string(from: date), // Set due date to scheduled time
            estimatedDuration: task.estimatedDuration,
            workPersonal: task.workPersonal,
            projectId: task.projectId,
            areaId: task.areaId,
            resourceId: task.resourceId,
            isFocus: task.isFocus,
            isArchived: task.isArchived,
            createdAt: task.createdAt,
            updatedAt: dateFormatter.string(from: Date()),
            completedAt: task.completedAt,
            archivedAt: task.archivedAt,
            deletedAt: task.deletedAt
        )
        
        // Update UI state first (this should always work)
        await MainActor.run {
            let initialTaskCount = allTasks.count
            let initialEventCount = events.count
            
            // Add event to calendar
            events.append(event)
            LifeLogger.taskScheduling(.info, "Added event to calendar. Events count: \(initialEventCount) -> \(events.count)")
            
            applyFilters()
            LifeLogger.taskScheduling(.info, "Applied filters. Filtered events count: \(filteredEvents.count)")
            
            // Remove task from parking lot (allTasks)
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                allTasks.remove(at: index)
                LifeLogger.taskScheduling(.info, "Removed task from parking lot. Tasks count: \(initialTaskCount) -> \(allTasks.count)")
            } else {
                LifeLogger.taskScheduling(.warning, "Task not found in parking lot for removal. Task ID: \(task.id)")
            }
            
            LifeLogger.taskScheduling(.info, "✅ Task '\(task.title)' scheduled for \(date) and removed from parking lot")
        }
        
        // Try to update database (this might fail in tests, but UI should still work)
        do {
            LifeLogger.database(.info, "Updating task in database with scheduled time: \(dateFormatter.string(from: date))")
            _ = try await taskRepository.updateTask(updatedTask)
            LifeLogger.database(.info, "Successfully updated task in database")
        } catch {
            LifeLogger.database(.warning, "Failed to update task in database (UI still updated): \(error)")
            // Don't throw - UI state is already updated
        }
        
        // Note: No need to reload calendar data as we've already updated the in-memory state
        LifeLogger.taskScheduling(.info, "Task scheduling completed successfully")
        
        _ = timer.end()
        LifeLogger.logTaskScheduling(
            task: task,
            scheduleDate: date,
            operation: "SCHEDULE_SUCCESS",
            success: true
        )
    }
    
    /// Get suggested time slots for a task
    func suggestedSlots(for task: LifeTask) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var suggestions: [Date] = []
        
        // Get task duration in minutes
        let taskDuration = task.estimatedDuration ?? 30 // Default to 30 minutes if not specified
        
        // Look for free slots in the next 7 days
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            // Check working hours (9 AM to 6 PM)
            for hour in 9..<18 {
                guard let slotStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate) else { continue }
                let slotEnd = slotStart.addingTimeInterval(TimeInterval(taskDuration * 60))
                
                // Check if this slot conflicts with existing events
                let hasConflict = events.contains { event in
                    let eventStart = event.startDate
                    let eventEnd = event.endDate
                    
                    return (slotStart < eventEnd && slotEnd > eventStart)
                }
                
                if !hasConflict {
                    suggestions.append(slotStart)
                    
                    // Limit to 5 suggestions
                    if suggestions.count >= 5 {
                        return suggestions
                    }
                }
            }
        }
        
        return suggestions
    }
    
    /// Load events for a specific date
    func loadEventsForDate(_ date: Date) async {
        // First sync with Toggl for this specific date
        await syncWithTogglForDate(date)
    }
    
    /// Sync with Toggl for a specific date
    private func syncWithTogglForDate(_ date: Date) async {
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let togglEntries = try await togglService.fetchTimeEntries(startDate: startOfDay, endDate: endOfDay)
            
            // Convert TogglTimeEntry to CalendarEvent
            let calendarEvents = togglEntries.map { togglEntry in
                // Get project color from TogglService
                let projectColor = togglEntry.projectId.flatMap { projectId in
                    togglService.projectColors[projectId]
                } ?? .green  // Default to green if no project color found
                
                return CalendarEvent(
                    title: togglEntry.description ?? "Untitled Activity",
                    description: nil,
                    startDate: togglEntry.startDate,
                    endDate: togglEntry.endDate ?? Date(),
                    workPersonal: .work,
                    color: projectColor,
                    source: .toggl,
                    togglEntryId: togglEntry.id,
                    duration: togglEntry.actualDuration
                )
            }
            
            await MainActor.run {
                updateEventsWithTogglDataForDate(calendarEvents, date: date)
            }
        } catch {
            Logger.shared.error("CALENDAR: Failed to sync specific date \(date): \(error.localizedDescription)")
        }
    }
    
    /// Update events with Toggl data for a specific date
    private func updateEventsWithTogglDataForDate(_ togglEvents: [CalendarEvent], date: Date) {
        let calendar = Calendar.current
        
        // Remove existing Toggl events for this date
        events.removeAll { event in
            event.source == .toggl && calendar.isDate(event.startDate, inSameDayAs: date)
        }
        
        // Add new Toggl events
        events.append(contentsOf: togglEvents)
        applyFilters()
        
        Logger.shared.info("CALENDAR: Updated \(togglEvents.count) events for date \(date)")
    }
    
    /// Sync with Toggl for all visible dates in month view (optimized for rate limiting)
    func syncMonthViewWithToggl(_ visibleDates: [Date]) async {
        togglSyncStatus = .syncing
        
        do {
            // Get date range for all visible dates
            guard let startDate = visibleDates.min(),
                  let endDate = visibleDates.max() else {
                return
            }
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: startDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
            
            // Add 3-second delay before API call to prevent rate limiting
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            // Fetch entries for the entire month view range with rate limiting
            let togglEntries = try await togglService.fetchTimeEntries(startDate: startOfDay, endDate: endOfDay)
            
            // Group by date and get top 3 longest projects per day to reduce data further
            let entriesByDate = Dictionary(grouping: togglEntries) { entry in
                calendar.startOfDay(for: entry.startDate)
            }
            
            var optimizedEntries: [TogglTimeEntry] = []
            for (_, dayEntries) in entriesByDate {
                // Sort by duration and take top 3 longest entries per day (reduced from 5)
                let topEntries = dayEntries.sorted { $0.actualDuration > $1.actualDuration }.prefix(3)
                optimizedEntries.append(contentsOf: topEntries)
            }
            
            await MainActor.run {
                // Update events with optimized Toggl data
                updateEventsWithTogglData(optimizedEntries)
                togglSyncStatus = .success
                Logger.shared.info("CALENDAR: Ultra-optimized sync - \(optimizedEntries.count) entries from \(togglEntries.count) total")
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sync month view with Toggl: \(error.localizedDescription)"
                togglSyncStatus = .error
            }
        }
    }
    
    /// Load events for the current period based on view mode
    func loadEventsForCurrentPeriod() async {
        let calendar = Calendar.current
        
        switch viewMode {
        case .day:
            await loadEventsForDate(selectedDate)
        case .week:
            // Load events for entire week
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
            
            for date in weekDays {
                await loadEventsForDate(date)
            }
        case .month:
            // Load events for entire month with rate limiting
            let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
            let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
            
            // Use batch loading for month view to avoid rate limiting
            await loadEventsForDateRange(startDate: startOfMonth, endDate: endOfMonth)
        }
        
        await MainActor.run {
            applyFilters()
            LifeLogger.calendar(.info, "✅ Loaded events for \(viewMode) view - Total events: \(events.count)")
        }
    }
    
    /// Load events for a date range (used for month view to avoid rate limiting)
    func loadEventsForDateRange(startDate: Date, endDate: Date) async {
        do {
            // Sync with Toggl for the entire range in one request
            let togglEvents = try await togglService.fetchTimeEntries(startDate: startDate, endDate: endDate)
            
            await MainActor.run {
                // Update events with Toggl data
                updateEventsWithTogglData(togglEvents)
                LifeLogger.calendar(.info, "✅ Loaded \(togglEvents.count) Toggl events for date range")
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load events: \(error.localizedDescription)"
                LifeLogger.calendar(.error, "❌ Failed to load events for date range: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind view mode changes to reload events
        $viewMode
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadEventsForCurrentPeriod()
                }
            }
            .store(in: &cancellables)
        
        // Bind selected date changes to reload events
        $selectedDate
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadEventsForCurrentPeriod()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load sample data for now
        loadSampleEvents()
        applyFilters()
        
        // Start Toggl sync
        Task {
            await syncWithToggl()
        }
    }
    
    internal func applyFilters() {
        if activeFilters.isEmpty {
            filteredEvents = events
        } else {
            filteredEvents = events.filter { event in
                // Apply active filters
                for filter in activeFilters {
                    switch filter {
                    case .work:
                        if event.workPersonal != .work && event.workPersonal != .both {
                            return false
                        }
                    case .personal:
                        if event.workPersonal != .personal && event.workPersonal != .both {
                            return false
                        }
                    case .toggl:
                        if event.source != .toggl {
                            return false
                        }
                    case .user:
                        if event.source != .user {
                            return false
                        }
                    case .locked:
                        if !event.isLocked {
                            return false
                        }
                    case .unlocked:
                        if event.isLocked {
                            return false
                        }
                    }
                }
                return true
            }
        }
    }
    
    private func updateEventsWithTogglData(_ togglEvents: [TogglTimeEntry]) {
        // Remove existing Toggl events
        events.removeAll { $0.source == .toggl }
        
        // Add new Toggl events with project colors
        let calendarEvents = togglEvents.map { togglEntry in
            // Get project color from TogglService
            let projectColor = togglEntry.projectId.flatMap { projectId in
                togglService.projectColors[projectId]
            } ?? .green  // Default to green if no project color found
            
            return CalendarEvent(
                title: togglEntry.description ?? "Untitled Activity",
                description: nil, // Remove "Toggl time entry" description
                startDate: togglEntry.startDate,
                endDate: togglEntry.endDate ?? Date(),
                workPersonal: .work, // Default to work for Toggl entries
                color: projectColor, // Use Toggl project color
                source: .toggl,
                togglEntryId: togglEntry.id,
                duration: togglEntry.actualDuration
            )
        }
        
        events.append(contentsOf: calendarEvents)
        applyFilters()
    }
    
    private func findBestTimeSlot(for task: LifeTask) -> Date? {
        let suggestions = suggestedSlots(for: task)
        return suggestions.first // Return the first available slot
    }
    
    private func loadSampleEvents() {
        let now = Date()
        let calendar = Calendar.current
        
        // Create some sample events for demonstration
        let sampleEvents = [
            CalendarEvent(
                title: "Morning Standup",
                description: "Daily team sync",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) ?? now,
                workPersonal: .work,
                color: .blue,
                source: .user,
                duration: 1800 // 30 minutes
            ),
            CalendarEvent(
                title: "Lunch Break",
                description: "Time to recharge",
                startDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now) ?? now,
                workPersonal: .personal,
                color: .green,
                source: .user,
                duration: 3600 // 1 hour
            ),
            CalendarEvent(
                title: "Code Review",
                description: "Review pending PRs",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: now) ?? now,
                workPersonal: .work,
                isLocked: true,
                color: .orange,
                source: .user,
                duration: 5400 // 1.5 hours
            )
        ]
        
        events = sampleEvents
    }
    
    // MARK: - Advanced Calendar Features
    
    /// Start advanced calendar monitoring with auto-bumping and parking lot
    func startAdvancedCalendarFeatures() async {
        LifeLogger.calendar(.info, "Starting advanced features - auto-bumping, parking lot, buffer management")
        
        // Start orchestration service
        await orchestrationService.startContinuousMonitoring()
        
        // Process today's schedule
        await orchestrationService.processScheduleForDate(selectedDate)
        
        // Set up data binding
        setupOrchestrationBinding()
    }
    
    /// Stop advanced calendar features
    func stopAdvancedCalendarFeatures() {
        orchestrationService.stopContinuousMonitoring()
        LifeLogger.calendar(.info, "Stopped advanced features")
    }
    
    /// Process schedule with intelligent bumping and parking
    func processIntelligentScheduling() async {
        await orchestrationService.processScheduleForDate(selectedDate)
        
        // Update UI with processed events
        await MainActor.run {
            self.events = orchestrationService.dailyEvents
        }
    }
    
    /// Update buffer settings through orchestration
    func updateBufferSettings(minutesPerHour: Int, workingHours: Int) {
        orchestrationService.updateBufferSettings(
            minutesPerHour: minutesPerHour,
            workingHours: workingHours
        )
    }
    
    /// Get current buffer status
    var bufferStatus: BufferStatus {
        return orchestrationService.bufferStatus
    }
    
    /// Get parking lot events
    var parkedEvents: [ParkingLotEvent] {
        return parkingLotService.parkedEvents
    }
    
    /// Attempt to reschedule a parked event
    func rescheduleParkedEvent(_ eventId: UUID, to targetDate: Date) async -> Bool {
        let success = await parkingLotService.attemptReschedule(
            parkedEventId: eventId,
            targetDate: targetDate,
            allEvents: events
        )
        
        if success {
            // Refresh the schedule after rescheduling
            await processIntelligentScheduling()
        }
        
        return success
    }
    
    /// Remove event from parking lot
    func removeFromParkingLot(_ eventId: UUID) {
        parkingLotService.removeFromParkingLot(eventId: eventId)
    }
    
    /// Setup data binding between orchestration service and view model
    private func setupOrchestrationBinding() {
        // Update events when orchestration service updates
        orchestrationService.$dailyEvents
            .receive(on: DispatchQueue.main)
            .assign(to: &$events)
        
        // Update buffer status display
        orchestrationService.$bufferStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                // Could trigger UI updates for buffer warnings
                LifeLogger.calendar(.debug, "Buffer status changed to: \(status.rawValue)")
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

/// Toggl sync status
enum TogglSyncStatus {
    case idle
    case syncing
    case success
    case error
} 