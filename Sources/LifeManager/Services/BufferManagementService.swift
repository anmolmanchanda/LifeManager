import Foundation
import SwiftUI

/// Service for managing calendar buffers and preventing overbooking
@MainActor
class BufferManagementService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var bufferMinutesPerHour: Int = 5
    @Published var isOverbooked: Bool = false
    @Published var remainingBufferMinutes: Int = 0
    @Published var bufferWarningShown: Bool = false
    
    private let calendar = Calendar.current
    
    // MARK: - Buffer Calculations
    
    /// Calculate total required buffer minutes for a day
    func calculateRequiredBuffer(workingHours: Int) -> Int {
        return workingHours * bufferMinutesPerHour
    }
    
    /// Calculate total scheduled minutes for a day
    func calculateScheduledMinutes(events: [CalendarEvent], for date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        return events
            .filter { event in
                event.startDate >= dayStart && event.startDate < dayEnd
            }
            .reduce(0) { total, event in
                total + event.durationMinutes
            }
    }
    
    /// Calculate remaining buffer minutes for a day
    func calculateRemainingBuffer(events: [CalendarEvent], for date: Date, workingHours: Int = 8) -> Int {
        let totalWorkingMinutes = workingHours * 60
        let requiredBuffer = calculateRequiredBuffer(workingHours: workingHours)
        let scheduledMinutes = calculateScheduledMinutes(events: events, for: date)
        
        let availableMinutes = totalWorkingMinutes - scheduledMinutes
        let remainingBuffer = availableMinutes - requiredBuffer
        
        return max(0, remainingBuffer)
    }
    
    /// Check if day is overbooked
    func checkOverbooking(events: [CalendarEvent], for date: Date, workingHours: Int = 8) -> Bool {
        let totalWorkingMinutes = workingHours * 60
        let requiredBuffer = calculateRequiredBuffer(workingHours: workingHours)
        let scheduledMinutes = calculateScheduledMinutes(events: events, for: date)
        
        let isOverbooked = (scheduledMinutes + requiredBuffer) > totalWorkingMinutes
        
        DispatchQueue.main.async {
            self.isOverbooked = isOverbooked
            self.remainingBufferMinutes = max(0, totalWorkingMinutes - scheduledMinutes - requiredBuffer)
        }
        
        return isOverbooked
    }
    
    // MARK: - Event Scheduling
    
    /// Find next available time slot for an event
    func findNextAvailableSlot(
        duration: TimeInterval,
        events: [CalendarEvent],
        startingFrom: Date,
        workingHours: Int = 8
    ) -> Date? {
        
        let durationMinutes = Int(duration / 60)
        let calendar = Calendar.current
        
        // Start from the beginning of the working day
        let workingDayStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startingFrom) ?? startingFrom
        let workingDayEnd = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: startingFrom) ?? startingFrom
        
        // Get all events sorted by start time
        let dayEvents = events
            .filter { event in
                event.startDate >= workingDayStart && event.startDate <= workingDayEnd
            }
            .sorted { $0.startDate < $1.startDate }
        
        // Check if we can fit the event at the start of the day
        if dayEvents.isEmpty {
            if canScheduleEvent(duration: duration, at: workingDayStart, events: events, workingHours: workingHours) {
                return workingDayStart
            }
        }
        
        // Try to find a gap between existing events
        for i in 0..<dayEvents.count {
            let currentEvent = dayEvents[i]
            let nextEventStart = i + 1 < dayEvents.count ? dayEvents[i + 1].startDate : workingDayEnd
            
            let gapStart = currentEvent.endDate
            let gapDuration = nextEventStart.timeIntervalSince(gapStart)
            
            // Check if gap is large enough (including buffer)
            if gapDuration >= duration + TimeInterval(bufferMinutesPerHour * 60) {
                if canScheduleEvent(duration: duration, at: gapStart, events: events, workingHours: workingHours) {
                    return gapStart
                }
            }
        }
        
        // Try next day if no slot found today
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startingFrom) ?? startingFrom
        return findNextAvailableSlot(
            duration: duration,
            events: events,
            startingFrom: nextDay,
            workingHours: workingHours
        )
    }
    
    /// Check if an event can be scheduled at a specific time
    func canScheduleEvent(
        duration: TimeInterval,
        at startTime: Date,
        events: [CalendarEvent],
        workingHours: Int = 8
    ) -> Bool {
        
        let endTime = startTime.addingTimeInterval(duration)
        let durationMinutes = Int(duration / 60)
        
        // Create a temporary event to test scheduling
        let testEvent = CalendarEvent(
            id: UUID(),
            title: "Test",
            startDate: startTime,
            endDate: endTime,
            duration: duration
        )
        
        var testEvents = events
        testEvents.append(testEvent)
        
        let dayDate = calendar.startOfDay(for: startTime)
        
        // Check if this would cause overbooking
        return !checkOverbooking(events: testEvents, for: dayDate, workingHours: workingHours)
    }
    
    // MARK: - Auto-Bumping Logic
    
    /// Bump events forward when actual time entries create conflicts
    func bumpConflictingEvents(
        actualEvents: [CalendarEvent],
        plannedEvents: [CalendarEvent],
        workingHours: Int = 8
    ) -> [CalendarEvent] {
        
        var updatedEvents = plannedEvents
        var eventsToRemove: [UUID] = []
        var eventsToBump: [(event: CalendarEvent, conflict: CalendarEvent)] = []
        
        // Find conflicts between actual and planned events
        for actualEvent in actualEvents {
            for (index, plannedEvent) in updatedEvents.enumerated() {
                if eventsOverlap(actualEvent, plannedEvent) {
                    var bumpedEvent = plannedEvent
                    bumpedEvent.isBumped = true
                    bumpedEvent.originalPlannedTime = DateInterval(start: plannedEvent.startDate, end: plannedEvent.endDate)
                    
                    eventsToBump.append((event: bumpedEvent, conflict: actualEvent))
                    eventsToRemove.append(plannedEvent.id)
                }
            }
        }
        
        // Remove conflicting events from the list
        updatedEvents.removeAll { event in eventsToRemove.contains(event.id) }
        
        // Try to reschedule bumped events
        for (bumpedEvent, conflictEvent) in eventsToBump {
            let newStartTime = conflictEvent.endDate.addingTimeInterval(TimeInterval(bufferMinutesPerHour * 60))
            
            if let availableSlot = findNextAvailableSlot(
                duration: bumpedEvent.duration,
                events: updatedEvents + actualEvents,
                startingFrom: newStartTime,
                workingHours: workingHours
            ) {
                var rescheduledEvent = bumpedEvent
                let timeDiff = availableSlot.timeIntervalSince(bumpedEvent.startDate)
                rescheduledEvent.startDate = availableSlot
                rescheduledEvent.endDate = availableSlot.addingTimeInterval(bumpedEvent.duration)
                rescheduledEvent.bumpedByMinutes = Int(timeDiff / 60)
                
                updatedEvents.append(rescheduledEvent)
                
                print("🔧 BUFFER: ✅ Bumped '\(bumpedEvent.title)' by \(rescheduledEvent.bumpedByMinutes) minutes")
            } else {
                print("🔧 BUFFER: ⚠️ Could not reschedule '\(bumpedEvent.title)' - may need to park or move to next day")
                // This event will need to be handled by parking lot logic
            }
        }
        
        return updatedEvents
    }
    
    /// Check if two events overlap
    private func eventsOverlap(_ event1: CalendarEvent, _ event2: CalendarEvent) -> Bool {
        return event1.startDate < event2.endDate && event2.startDate < event1.endDate
    }
    
    // MARK: - Notifications & Warnings
    
    /// Check buffer status and trigger warnings if needed
    func checkBufferStatus(events: [CalendarEvent], for date: Date, workingHours: Int = 8) {
        let remaining = calculateRemainingBuffer(events: events, for: date, workingHours: workingHours)
        let isOverbooked = checkOverbooking(events: events, for: date, workingHours: workingHours)
        
        DispatchQueue.main.async {
            self.remainingBufferMinutes = remaining
            self.isOverbooked = isOverbooked
            
            if isOverbooked && !self.bufferWarningShown {
                self.triggerBufferWarning()
            }
        }
    }
    
    /// Trigger buffer warning notifications
    private func triggerBufferWarning() {
        bufferWarningShown = true
        
        print("🔧 BUFFER: ⚠️ Day is overbooked! No buffer remaining.")
        
        // Send immediate notification
        NotificationService.shared.scheduleBufferWarning()
        
        // Schedule escalated warning if not addressed
        DispatchQueue.main.asyncAfter(deadline: .now() + 900) { // 15 minutes
            if self.bufferWarningShown && self.isOverbooked {
                self.triggerEscalatedWarning()
            }
        }
    }
    
    /// Trigger escalated warning (SMS/Email)
    private func triggerEscalatedWarning() {
        print("🔧 BUFFER: 🚨 Escalated warning - user has not responded to overbooking notification")
        NotificationService.shared.scheduleEscalatedWarning()
    }
    
    /// Reset warning flags
    func resetWarnings() {
        bufferWarningShown = false
    }
    
    // MARK: - Configuration
    
    /// Update buffer minutes per hour
    func updateBufferConfiguration(minutesPerHour: Int) {
        bufferMinutesPerHour = max(0, min(30, minutesPerHour)) // Limit between 0-30 minutes
        print("🔧 BUFFER: Updated buffer to \(bufferMinutesPerHour) minutes per hour")
    }
}

// MARK: - Extensions

extension Date {
    /// Check if date is in the past
    var isPast: Bool {
        return self < Date()
    }
    
    /// Check if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
} 