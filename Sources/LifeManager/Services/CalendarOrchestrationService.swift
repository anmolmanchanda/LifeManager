import Foundation
import SwiftUI

/// Master orchestration service for advanced calendar functionality
@MainActor
class CalendarOrchestrationService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CalendarOrchestrationService()
    
    // MARK: - Published Properties
    
    @Published var isProcessing: Bool = false
    @Published var lastUpdateTime: Date = Date()
    @Published var bufferStatus: BufferStatus = .healthy
    @Published var dailyEvents: [CalendarEvent] = []
    @Published var actualEvents: [CalendarEvent] = []
    @Published var plannedEvents: [CalendarEvent] = []
    
    // MARK: - Services
    
    private let bufferService = BufferManagementService()
    private let parkingService: EnhancedParkingLotService
    private let togglService = TogglService()
    private let notificationService = NotificationService.shared
    private let llmService = LLMServiceCoordinator.shared
    
    // MARK: - Configuration
    
    @Published var bufferMinutesPerHour: Int = 5
    @Published var workingHours: Int = 8
    @Published var autoRefreshInterval: TimeInterval = 60 // 60 seconds
    
    // MARK: - State Tracking
    
    private var refreshTimer: Timer?
    private var lastTogglFetch: Date = Date.distantPast
    private var processingQueue = DispatchQueue(label: "calendar.orchestration", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        self.parkingService = EnhancedParkingLotService(llmService: llmService)
        setupOrchestration()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Process daily schedule with Toggl integration and auto-bumping
    func processScheduleForDate(_ date: Date) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("CALENDAR ORCHESTRATION: Processing schedule for \(formatDate(date))")
        
        do {
            // 1. Fetch latest Toggl data
            await fetchTogglActuals(for: date)
            
            // 2. Separate actual vs planned events
            categorizeEvents(for: date)
            
            // 3. Check buffer status
            await updateBufferStatus(for: date)
            
            // 4. Process conflicts and auto-bump
            await processConflictsAndBumps(for: date)
            
            // 5. Handle overflow to parking lot
            await handleOverflowEvents()
            
            // 6. Update parking lot days
            parkingService.updateParkingLotDays()
            
            // 7. Check for stale parked events
            await checkStaleParkedEvents()
            
            lastUpdateTime = Date()
            Logger.shared.success("CALENDAR ORCHESTRATION: Schedule processing complete")
            
        } catch {
            Logger.shared.error("CALENDAR ORCHESTRATION: Error processing schedule: \(error)")
        }
    }
    
    /// Start continuous monitoring
    func startContinuousMonitoring() {
        Logger.shared.info("CALENDAR ORCHESTRATION: Starting continuous monitoring")
        startAutoRefresh()
    }
    
    /// Stop continuous monitoring
    func stopContinuousMonitoring() {
        Logger.shared.info("CALENDAR ORCHESTRATION: Stopping continuous monitoring")
        stopAutoRefresh()
    }
    
    /// Manually trigger schedule refresh
    func refreshSchedule() async {
        await processScheduleForDate(Date())
    }
    
    /// Update buffer configuration
    func updateBufferSettings(minutesPerHour: Int, workingHours: Int) {
        self.bufferMinutesPerHour = minutesPerHour
        self.workingHours = workingHours
        
        bufferService.updateBufferConfiguration(minutesPerHour: minutesPerHour)
        
        Logger.shared.info("CALENDAR ORCHESTRATION: Updated buffer settings: \(minutesPerHour)min/hour, \(workingHours)h workday")
        
        // Reprocess today's schedule with new settings
        Task {
            await processScheduleForDate(Date())
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupOrchestration() {
        // Configure buffer service
        bufferService.bufferMinutesPerHour = bufferMinutesPerHour
        
        Logger.shared.success("CALENDAR ORCHESTRATION: Orchestration service initialized")
    }
    
    private func startAutoRefresh() {
        stopAutoRefresh() // Ensure no duplicate timers
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { _ in
            Task { @MainActor in
                if self.shouldAutoRefresh() {
                    await self.refreshSchedule()
                }
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func shouldAutoRefresh() -> Bool {
        // Only auto-refresh during working hours and if user is active
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Working hours: 7 AM to 7 PM
        return hour >= 7 && hour <= 19
    }
    
    // MARK: - Toggl Integration
    
    private func fetchTogglActuals(for date: Date) async {
        let timeSinceLastFetch = Date().timeIntervalSince(lastTogglFetch)
        guard timeSinceLastFetch > 30 else { return } // Rate limit: max once per 30 seconds
        
        Logger.shared.info("CALENDAR ORCHESTRATION: Fetching Toggl actuals for \(formatDate(date))")
        
        do {
            _ = try await togglService.fetchTodaysEntries()
            lastTogglFetch = Date()
            
            // Convert Toggl entries to CalendarEvents
            await convertTogglToCalendarEvents(for: date)
            
            Logger.shared.success("CALENDAR ORCHESTRATION: Toggl actuals fetched and converted")
            
        } catch {
            Logger.shared.error("CALENDAR ORCHESTRATION: Error fetching Toggl data: \(error)")
        }
    }
    
    private func convertTogglToCalendarEvents(for date: Date) async {
        // Get today's Toggl entries from the service
        let togglEntries = togglService.timeEntries
        
        actualEvents = togglEntries.compactMap { entry -> CalendarEvent? in
            guard let endDate = entry.endDate else { return nil }
            
            return CalendarEvent(
                title: entry.description ?? "Toggl Entry",
                description: "Actual time tracked",
                startDate: entry.startDate,
                endDate: endDate,
                workPersonal: .work, // Default assumption
                color: .green, // Use green for Toggl entries
                isActual: true,
                source: .toggl,
                togglEntryId: entry.id,
                duration: entry.actualDuration
            )
        }
        
        Logger.shared.info("CALENDAR ORCHESTRATION: Converted \(actualEvents.count) Toggl entries to calendar events")
    }
    
    // MARK: - Event Categorization
    
    private func categorizeEvents(for date: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        // Filter all daily events for the specified date
        dailyEvents = (actualEvents + plannedEvents).filter { event in
            event.startDate >= dayStart && event.startDate < dayEnd
        }.sorted { $0.startDate < $1.startDate }
        
        Logger.shared.info("CALENDAR ORCHESTRATION: Categorized events - Daily: \(dailyEvents.count), Actual: \(actualEvents.count), Planned: \(plannedEvents.count)")
    }
    
    // MARK: - Buffer Management
    
    private func updateBufferStatus(for date: Date) async {
        let remainingBuffer = bufferService.calculateRemainingBuffer(
            events: dailyEvents,
            for: date,
            workingHours: workingHours
        )
        
        let isOverbooked = bufferService.checkOverbooking(
            events: dailyEvents,
            for: date,
            workingHours: workingHours
        )
        
        // Update buffer status
        if isOverbooked {
            bufferStatus = .critical
            await notificationService.scheduleBufferViolationWarning(
                remainingBuffer: remainingBuffer,
                hoursAffected: workingHours
            )
        } else if remainingBuffer < 15 { // Less than 15 minutes total buffer
            bufferStatus = .warning
        } else {
            bufferStatus = .healthy
        }
        
        Logger.shared.info("CALENDAR ORCHESTRATION: Buffer status: \(bufferStatus.rawValue), Remaining: \(remainingBuffer)min")
    }
    
    // MARK: - Conflict Resolution & Auto-Bumping
    
    private func processConflictsAndBumps(for date: Date) async {
        Logger.shared.info("CALENDAR ORCHESTRATION: Processing conflicts and auto-bumps")
        
        var eventsToProcess = plannedEvents
        var bumpedEvents: [CalendarEvent] = []
        var cascadeCount = 0
        
        // Find and resolve conflicts with actual events
        for actualEvent in actualEvents {
            let conflictingPlanned = eventsToProcess.filter { plannedEvent in
                eventsOverlap(actualEvent, plannedEvent)
            }
            
            for conflictEvent in conflictingPlanned {
                Logger.shared.warning("CALENDAR ORCHESTRATION: Conflict detected: '\(actualEvent.title)' vs '\(conflictEvent.title)'")
                
                // Remove conflicting planned event
                eventsToProcess.removeAll { $0.id == conflictEvent.id }
                
                // Try to reschedule the planned event
                if let newSlot = await findRescheduleSlot(for: conflictEvent, after: actualEvent.endDate) {
                    var bumpedEvent = conflictEvent
                    let bumpMinutes = Int(newSlot.timeIntervalSince(conflictEvent.startDate) / 60)
                    
                    bumpedEvent.startDate = newSlot
                    bumpedEvent.endDate = newSlot.addingTimeInterval(conflictEvent.duration)
                    bumpedEvent.isBumped = true
                    bumpedEvent.bumpedByMinutes = bumpMinutes
                    bumpedEvent.originalPlannedTime = DateInterval(
                        start: conflictEvent.startDate, 
                        end: conflictEvent.endDate
                    )
                    
                    bumpedEvents.append(bumpedEvent)
                    
                    await notificationService.scheduleAutoBumpNotification(
                        eventTitle: conflictEvent.title,
                        bumpedByMinutes: bumpMinutes,
                        reason: "Conflict with actual: \(actualEvent.title)"
                    )
                    
                    Logger.shared.success("CALENDAR ORCHESTRATION: Bumped '\(conflictEvent.title)' by \(bumpMinutes) minutes")
                    
                } else {
                    // Can't reschedule - needs to go to parking lot
                    await parkingService.parkEvent(
                        conflictEvent,
                        reason: .conflictResolution
                    )
                    
                    Logger.shared.warning("CALENDAR ORCHESTRATION: Parked '\(conflictEvent.title)' - no available slots")
                }
            }
        }
        
        // Check for cascade bumps (bumped events causing more bumps)
        await processCascadeBumps(bumpedEvents: bumpedEvents)
        
        // Update planned events list
        plannedEvents = eventsToProcess + bumpedEvents
    }
    
    private func processCascadeBumps(bumpedEvents: [CalendarEvent]) async {
        var currentBumped = bumpedEvents
        var cascadeCount = 0
        let maxCascades = 5 // Prevent infinite loops
        
        while !currentBumped.isEmpty && cascadeCount < maxCascades {
            var nextCascade: [CalendarEvent] = []
            
            for bumpedEvent in currentBumped {
                // Check if this bumped event conflicts with other planned events
                let newConflicts = plannedEvents.filter { plannedEvent in
                    plannedEvent.id != bumpedEvent.id && eventsOverlap(bumpedEvent, plannedEvent)
                }
                
                for conflictEvent in newConflicts {
                    // Try to bump the conflicting event further
                    if let newSlot = await findRescheduleSlot(for: conflictEvent, after: bumpedEvent.endDate) {
                        var cascadeBumped = conflictEvent
                        let bumpMinutes = Int(newSlot.timeIntervalSince(conflictEvent.startDate) / 60)
                        
                        cascadeBumped.startDate = newSlot
                        cascadeBumped.endDate = newSlot.addingTimeInterval(conflictEvent.duration)
                        cascadeBumped.isBumped = true
                        cascadeBumped.bumpedByMinutes = bumpMinutes
                        
                        nextCascade.append(cascadeBumped)
                        
                        // Remove from planned events
                        plannedEvents.removeAll { $0.id == conflictEvent.id }
                        
                        Logger.shared.info("CALENDAR ORCHESTRATION: Cascade bump: '\(conflictEvent.title)' by \(bumpMinutes)min")
                    } else {
                        // Park the event that can't be bumped
                        await parkingService.parkEvent(conflictEvent, reason: .bumpCascade)
                        plannedEvents.removeAll { $0.id == conflictEvent.id }
                    }
                }
            }
            
            currentBumped = nextCascade
            cascadeCount += 1
        }
        
        if cascadeCount > 0 {
            await notificationService.scheduleCascadeBumpNotification(eventCount: cascadeCount)
            Logger.shared.info("CALENDAR ORCHESTRATION: Processed \(cascadeCount) cascade levels")
        }
    }
    
    // MARK: - Scheduling Logic
    
    private func findRescheduleSlot(for event: CalendarEvent, after minStartTime: Date) async -> Date? {
        return bufferService.findNextAvailableSlot(
            duration: event.duration,
            events: dailyEvents + actualEvents,
            startingFrom: minStartTime,
            workingHours: workingHours
        )
    }
    
    private func eventsOverlap(_ event1: CalendarEvent, _ event2: CalendarEvent) -> Bool {
        return event1.startDate < event2.endDate && event2.startDate < event1.endDate
    }
    
    // MARK: - Overflow Handling
    
    private func handleOverflowEvents() async {
        // Check for events that couldn't be rescheduled
        let todayEnd = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        
        let overflowEvents = plannedEvents.filter { event in
            event.endDate > todayEnd && event.source != .toggl
        }
        
        if !overflowEvents.isEmpty {
            await parkingService.handleParkingDecisions(
                events: overflowEvents,
                conflicts: actualEvents
            )
            
            Logger.shared.info("CALENDAR ORCHESTRATION: Handled \(overflowEvents.count) overflow events")
        }
    }
    
    // MARK: - Maintenance
    
    private func checkStaleParkedEvents() async {
        let staleEvents = parkingService.getStaleParkedEvents(daysThreshold: 7)
        
        if !staleEvents.isEmpty {
            await notificationService.scheduleStaleEventNotification(eventCount: staleEvents.count)
            Logger.shared.info("CALENDAR ORCHESTRATION: Found \(staleEvents.count) stale parked events")
        }
    }
    
    // MARK: - Utilities
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum BufferStatus: String, CaseIterable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        @unknown default:
            return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
} 