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
    @Published var viewMode: CalendarViewMode = .day
    
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
        
        loadEventsForCurrentPeriod()
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
        
        loadEventsForCurrentPeriod()
    }
    
    /// Navigate to today
    func navigateToToday() {
        selectedDate = Date()
        loadEventsForCurrentPeriod()
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
        return events(for: date).filter { event in
            let eventHour = calendar.component(.hour, from: event.startDate)
            return eventHour == hour
        }
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
        print("Handling drop on \(date)")
        
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
        draggingTask = task
    }
    
    /// Cancel drag operation
    func cancelDrag() {
        draggingTask = nil
    }
    
    /// Update drag position during drag operation
    func updateDragPosition(_ translation: CGSize) {
        // Handle drag position updates for visual feedback
        // This could be used to show drop targets, preview scheduling, etc.
        print("Drag position updated: \(translation)")
    }
    
    /// Schedule a task at a specific time
    func scheduleTask(_ task: LifeTask, at date: Date) async {
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
        
        await MainActor.run {
            events.append(event)
            applyFilters()
            
            // Mark task as scheduled (you'd normally update this in the database)
            // Note: The LifeTask model uses isScheduled computed property based on dueDate
            // To properly mark as scheduled, we would need to update the dueDate with the specific time
            print("Task \(task.title) scheduled for \(date)")
        }
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
            print("🔧 TOGGL: Failed to sync specific date \(date): \(error.localizedDescription)")
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
        
        print("🔧 TOGGL: Updated \(togglEvents.count) events for date \(date)")
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
            
            // Fetch entries for the entire month view range with rate limiting
            let togglEntries = try await togglService.fetchTimeEntries(startDate: startOfDay, endDate: endOfDay)
            
            // Group by date and get top 5 longest projects per day to reduce data
            let entriesByDate = Dictionary(grouping: togglEntries) { entry in
                calendar.startOfDay(for: entry.startDate)
            }
            
            var optimizedEntries: [TogglTimeEntry] = []
            for (_, dayEntries) in entriesByDate {
                // Sort by duration and take top 5 longest entries per day
                let topEntries = dayEntries.sorted { $0.actualDuration > $1.actualDuration }.prefix(5)
                optimizedEntries.append(contentsOf: topEntries)
            }
            
            await MainActor.run {
                // Update events with optimized Toggl data
                updateEventsWithTogglData(optimizedEntries)
                togglSyncStatus = .success
                print("🔧 TOGGL: Optimized sync - \(optimizedEntries.count) entries from \(togglEntries.count) total")
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sync month view with Toggl: \(error.localizedDescription)"
                togglSyncStatus = .error
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // React to view mode changes
        $viewMode
            .sink { [weak self] _ in
                self?.loadEventsForCurrentPeriod()
            }
            .store(in: &cancellables)
        
        // React to date changes
        $selectedDate
            .sink { [weak self] _ in
                self?.loadEventsForCurrentPeriod()
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
    
    private func loadEventsForCurrentPeriod() {
        isLoading = true
        
        // Load events for the selected date
        Task {
            await syncWithToggl()
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func applyFilters() {
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
        print("🎭 CALENDAR: Starting advanced features - auto-bumping, parking lot, buffer management")
        
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
        print("🎭 CALENDAR: Stopped advanced features")
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
                print("🎭 CALENDAR: Buffer status changed to: \(status.rawValue)")
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