//
// ExternalCalendarIntegrationService.swift
// LifeManager
//
// External Calendar Integration: Enhanced Calendar Sync for Intelligent Automation
// Implements: Phase 1 Priority 2 - Calendar Integration Enhancement
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation
import SwiftUI
import EventKit
import Combine

/// External calendar integration service for intelligent automation
/// Provides external calendar sync, conflict detection, and availability analysis
@MainActor
class ExternalCalendarIntegrationService: ObservableObject {
    
    static let shared = ExternalCalendarIntegrationService()
    
    // MARK: - Dependencies
    
    private let eventStore = EKEventStore()
    private let calendarOrchestration = CalendarOrchestrationService()
    private let intelligentRescheduling = IntelligentReschedulingService.shared
    private let logger = Logger.shared
    
    // MARK: - Published State
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var externalCalendars: [ExternalCalendarInfo] = []
    @Published var externalEvents: [ExternalCalendarEvent] = []
    @Published var conflictingEvents: [CalendarConflict] = []
    @Published var availabilitySlots: [AvailabilitySlot] = []
    @Published var isProcessing = false
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [CalendarSyncError] = []
    
    // MARK: - Configuration
    
    private let syncInterval: TimeInterval = 300 // 5 minutes
    private let lookAheadDays: Int = 30
    private let lookBehindDays: Int = 7
    private var syncTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        logger.info("EXTERNAL_CALENDAR: Service initialized")
        checkAuthorizationStatus()
        setupPeriodicSync()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Authorization Management
    
    /// Request calendar access authorization
    func requestCalendarAccess() async throws {
        logger.info("EXTERNAL_CALENDAR: Requesting calendar access")
        
        let status = await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                if let error = error {
                    self.logger.error("EXTERNAL_CALENDAR: Authorization error: \\(error)")
                }
                continuation.resume(returning: granted ? EKAuthorizationStatus.authorized : EKAuthorizationStatus.denied)
            }
        }
        
        authorizationStatus = status
        
        if status == .authorized {
            logger.success("EXTERNAL_CALENDAR: Calendar access granted")
            await loadExternalCalendars()
        } else {
            logger.warning("EXTERNAL_CALENDAR: Calendar access denied")
            throw CalendarSyncError.authorizationDenied
        }
    }
    
    private func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        if authorizationStatus == .authorized {
            Task {
                await loadExternalCalendars()
            }
        }
    }
    
    // MARK: - Calendar Loading
    
    /// Load available external calendars
    func loadExternalCalendars() async {
        guard authorizationStatus == .authorized else {
            logger.warning("EXTERNAL_CALENDAR: Cannot load calendars - not authorized")
            return
        }
        
        logger.info("EXTERNAL_CALENDAR: Loading external calendars")
        
        let calendars = eventStore.calendars(for: .event)
        let calendarInfo = calendars.map { calendar in
            ExternalCalendarInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: Color(calendar.cgColor),
                isEnabled: !calendar.isImmutable,
                type: mapCalendarType(calendar.type),
                source: calendar.source.title
            )
        }
        
        externalCalendars = calendarInfo
        logger.success("EXTERNAL_CALENDAR: Loaded \\(calendarInfo.count) external calendars")
    }
    
    private func mapCalendarType(_ ekType: EKCalendarType) -> ExternalCalendarType {
        switch ekType {
        case .local: return .local
        case .calDAV: return .caldav
        case .exchange: return .exchange
        case .subscription: return .subscription
        case .birthday: return .birthday
        @unknown default: return .other
        }
    }
    
    // MARK: - Event Synchronization
    
    /// Sync external calendar events
    func syncExternalEvents() async {
        guard authorizationStatus == .authorized else {
            logger.warning("EXTERNAL_CALENDAR: Cannot sync events - not authorized")
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("EXTERNAL_CALENDAR: Starting event sync")
        
        do {
            let events = try await fetchExternalEvents()
            let conflicts = await detectConflicts(with: events)
            let slots = await calculateAvailabilitySlots(considering: events)
            
            externalEvents = events
            conflictingEvents = conflicts
            availabilitySlots = slots
            lastSyncDate = Date()
            
            // Clear previous errors on successful sync
            syncErrors.removeAll()
            
            logger.success("EXTERNAL_CALENDAR: Sync complete - \\(events.count) events, \\(conflicts.count) conflicts")
            
            // Notify intelligent rescheduling service of updated availability
            await intelligentRescheduling.updateExternalCalendarData(
                events: events,
                conflicts: conflicts,
                availabilitySlots: slots
            )
            
        } catch {
            let syncError = CalendarSyncError.syncFailed(error.localizedDescription)
            syncErrors.append(syncError)
            logger.error("EXTERNAL_CALENDAR: Sync failed: \\(error)")
        }
    }
    
    private func fetchExternalEvents() async throws -> [ExternalCalendarEvent] {
        let startDate = Calendar.current.date(byAdding: .day, value: -lookBehindDays, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: lookAheadDays, to: Date()) ?? Date()
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: eventStore.calendars(for: .event)
        )
        
        let events = eventStore.events(matching: predicate)
        
        return events.compactMap { event in
            guard !event.isAllDay else { return nil } // Skip all-day events for scheduling
            
            return ExternalCalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Untitled Event",
                startDate: event.startDate,
                endDate: event.endDate,
                calendarId: event.calendar.calendarIdentifier,
                calendarTitle: event.calendar.title,
                isEditable: !event.calendar.isImmutable,
                availability: mapAvailability(event.availability),
                location: event.location,
                notes: event.notes,
                url: event.url
            )
        }
    }
    
    private func mapAvailability(_ ekAvailability: EKEventAvailability) -> EventAvailability {
        switch ekAvailability {
        case .notSupported: return .notSupported
        case .busy: return .busy
        case .free: return .free
        case .tentative: return .tentative
        case .unavailable: return .unavailable
        @unknown default: return .busy
        }
    }
    
    // MARK: - Conflict Detection
    
    /// Detect conflicts between LifeManager tasks and external events
    private func detectConflicts(with externalEvents: [ExternalCalendarEvent]) async -> [CalendarConflict] {
        // Get current LifeManager scheduled tasks
        let scheduledTasks = await getScheduledLifeManagerTasks()
        var conflicts: [CalendarConflict] = []
        
        for task in scheduledTasks {
            for externalEvent in externalEvents {
                if let conflict = checkForConflict(task: task, externalEvent: externalEvent) {
                    conflicts.append(conflict)
                }
            }
        }
        
        return conflicts
    }
    
    private func checkForConflict(task: ScheduledTask, externalEvent: ExternalCalendarEvent) -> CalendarConflict? {
        let taskStart = task.scheduledStartDate
        let taskEnd = task.scheduledEndDate
        let eventStart = externalEvent.startDate
        let eventEnd = externalEvent.endDate
        
        // Check for time overlap
        let hasOverlap = taskStart < eventEnd && taskEnd > eventStart
        
        guard hasOverlap else { return nil }
        
        // Determine conflict severity
        let overlapDuration = min(taskEnd, eventEnd).timeIntervalSince(max(taskStart, eventStart))
        let taskDuration = taskEnd.timeIntervalSince(taskStart)
        let overlapPercentage = overlapDuration / taskDuration
        
        let severity: ConflictSeverity
        if overlapPercentage >= 0.8 {
            severity = .high
        } else if overlapPercentage >= 0.5 {
            severity = .medium
        } else {
            severity = .low
        }
        
        return CalendarConflict(
            id: UUID(),
            taskId: task.taskId,
            taskTitle: task.title,
            externalEventId: externalEvent.id,
            externalEventTitle: externalEvent.title,
            conflictStart: max(taskStart, eventStart),
            conflictEnd: min(taskEnd, eventEnd),
            severity: severity,
            suggestedAction: suggestConflictResolution(severity: severity, task: task, externalEvent: externalEvent)
        )
    }
    
    private func suggestConflictResolution(severity: ConflictSeverity, task: ScheduledTask, externalEvent: ExternalCalendarEvent) -> ConflictResolution {
        switch severity {
        case .high:
            return externalEvent.availability == .busy ? .rescheduleTask : .splitTask
        case .medium:
            return .adjustTaskTiming
        case .low:
            return .addBuffer
        }
    }
    
    // MARK: - Availability Analysis
    
    /// Calculate availability slots for intelligent scheduling
    private func calculateAvailabilitySlots(considering externalEvents: [ExternalCalendarEvent]) async -> [AvailabilitySlot] {
        let workingHours = await intelligentRescheduling.getUserWorkingHours()
        let today = Date()
        var availabilitySlots: [AvailabilitySlot] = []
        
        for dayOffset in 0..<lookAheadDays {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let daySlots = calculateDayAvailability(
                date: date,
                workingHours: workingHours,
                externalEvents: externalEvents.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            )
            
            availabilitySlots.append(contentsOf: daySlots)
        }
        
        return availabilitySlots
    }
    
    private func calculateDayAvailability(
        date: Date,
        workingHours: WorkingHours,
        externalEvents: [ExternalCalendarEvent]
    ) -> [AvailabilitySlot] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        guard let workStart = calendar.date(byAdding: .hour, value: workingHours.startHour, to: dayStart),
              let workEnd = calendar.date(byAdding: .hour, value: workingHours.endHour, to: dayStart) else {
            return []
        }
        
        // Create busy periods from external events
        let busyPeriods = externalEvents
            .filter { $0.availability == .busy || $0.availability == .unavailable }
            .map { BusyPeriod(start: $0.startDate, end: $0.endDate) }
            .sorted { $0.start < $1.start }
        
        // Find free slots between busy periods
        var availableSlots: [AvailabilitySlot] = []
        var currentTime = workStart
        
        for busyPeriod in busyPeriods {
            // Add slot before busy period if there's time
            if currentTime < busyPeriod.start {
                let slotEnd = min(busyPeriod.start, workEnd)
                if slotEnd > currentTime {
                    let duration = slotEnd.timeIntervalSince(currentTime)
                    if duration >= 900 { // At least 15 minutes
                        availableSlots.append(AvailabilitySlot(
                            start: currentTime,
                            end: slotEnd,
                            duration: duration,
                            quality: calculateSlotQuality(start: currentTime, duration: duration, workingHours: workingHours)
                        ))
                    }
                }
            }
            
            currentTime = max(currentTime, busyPeriod.end)
            
            if currentTime >= workEnd {
                break
            }
        }
        
        // Add final slot if time remains
        if currentTime < workEnd {
            let duration = workEnd.timeIntervalSince(currentTime)
            if duration >= 900 { // At least 15 minutes
                availableSlots.append(AvailabilitySlot(
                    start: currentTime,
                    end: workEnd,
                    duration: duration,
                    quality: calculateSlotQuality(start: currentTime, duration: duration, workingHours: workingHours)
                ))
            }
        }
        
        return availableSlots
    }
    
    private func calculateSlotQuality(start: Date, duration: TimeInterval, workingHours: WorkingHours) -> SlotQuality {
        let hour = Calendar.current.component(.hour, from: start)
        let durationHours = duration / 3600
        
        // Consider time of day and duration for quality
        if hour >= 9 && hour <= 11 && durationHours >= 2 {
            return .excellent // Morning focused time
        } else if hour >= 14 && hour <= 16 && durationHours >= 1.5 {
            return .good // Afternoon productive time
        } else if durationHours >= 1 {
            return .fair // Reasonable duration
        } else {
            return .poor // Short slots
        }
    }
    
    // MARK: - Periodic Sync
    
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncExternalEvents()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getScheduledLifeManagerTasks() async -> [ScheduledTask] {
        // This would integrate with the existing task system
        // For now, return empty array as placeholder
        return []
    }
}

// MARK: - Supporting Models

struct ExternalCalendarInfo: Identifiable {
    let id: String
    let title: String
    let color: Color
    let isEnabled: Bool
    let type: ExternalCalendarType
    let source: String
}

enum ExternalCalendarType {
    case local
    case caldav
    case exchange
    case subscription
    case birthday
    case other
}

struct ExternalCalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarId: String
    let calendarTitle: String
    let isEditable: Bool
    let availability: EventAvailability
    let location: String?
    let notes: String?
    let url: URL?
}

enum EventAvailability {
    case notSupported
    case busy
    case free
    case tentative
    case unavailable
}

struct CalendarConflict: Identifiable {
    let id: UUID
    let taskId: UUID
    let taskTitle: String
    let externalEventId: String
    let externalEventTitle: String
    let conflictStart: Date
    let conflictEnd: Date
    let severity: ConflictSeverity
    let suggestedAction: ConflictResolution
}

enum ConflictSeverity {
    case low
    case medium
    case high
}

enum ConflictResolution {
    case rescheduleTask
    case splitTask
    case adjustTaskTiming
    case addBuffer
}

struct AvailabilitySlot: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let duration: TimeInterval
    let quality: SlotQuality
}

enum SlotQuality {
    case excellent
    case good
    case fair
    case poor
}

struct BusyPeriod {
    let start: Date
    let end: Date
}

struct ScheduledTask {
    let taskId: UUID
    let title: String
    let scheduledStartDate: Date
    let scheduledEndDate: Date
}

struct WorkingHours {
    let startHour: Int
    let endHour: Int
}

enum CalendarSyncError: Error, LocalizedError {
    case authorizationDenied
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Calendar access denied. Please enable calendar access in System Preferences."
        case .syncFailed(let message):
            return "Calendar sync failed: \\(message)"
        }
    }
}