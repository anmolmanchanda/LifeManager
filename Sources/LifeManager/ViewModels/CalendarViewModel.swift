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
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let togglService = TogglService()
    private let bufferService = BufferManagementService()
    
    // MARK: - Initialization
    
    init() {
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
    
    /// Sync with Toggl
    func syncWithToggl() async {
        togglSyncStatus = .syncing
        
        do {
            let togglEvents = try await togglService.fetchTodaysEntries()
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
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoading = false
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
        
        // Add new Toggl events
        let calendarEvents = togglEvents.map { togglEntry in
            CalendarEvent(
                title: togglEntry.description ?? "Toggl Entry",
                description: "Toggl time entry",
                startDate: togglEntry.startDate,
                endDate: togglEntry.endDate ?? Date(),
                workPersonal: .work, // Default to work for Toggl entries
                color: .green,
                source: .toggl,
                togglEntryId: togglEntry.id,
                duration: togglEntry.actualDuration
            )
        }
        
        events.append(contentsOf: calendarEvents)
        applyFilters()
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
                color: .orange,
                source: .user,
                isLocked: true,
                duration: 5400 // 1.5 hours
            )
        ]
        
        events = sampleEvents
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