import Foundation
import SwiftUI

/// Service for managing parking lot events and overflow handling
@MainActor
class EnhancedParkingLotService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var parkedEvents: [ParkingLotEvent] = []
    @Published var isLoading: Bool = false
    @Published var pendingDecisions: [ParkingDecision] = []
    
    // MARK: - Private Properties
    
    private let llmService: LLMService
    private let bufferService = BufferManagementService()
    private let notificationService = NotificationService.shared
    
    // MARK: - Initialization
    
    init(llmService: LLMService = LLMService()) {
        self.llmService = llmService
    }
    
    // MARK: - Core Functions
    
    /// Move an event to parking lot
    func parkEvent(
        _ event: CalendarEvent,
        reason: ParkingReason,
        isImportant: Bool? = nil
    ) async {
        isLoading = true
        
        // Determine importance if not provided
        let eventImportance: Bool
        if let importance = isImportant {
            eventImportance = importance
        } else {
            eventImportance = await determineEventImportance(event)
        }
        
        let parkedEvent = ParkingLotEvent(
            originalEvent: event,
            reason: reason,
            isImportant: eventImportance,
            dateParked: Date(),
            daysInParkingLot: 0
        )
        
        parkedEvents.append(parkedEvent)
        
        // Send notification about parking
        await notificationService.scheduleEventParkedNotification(
            eventTitle: event.title,
            reason: reason.displayName,
            isImportant: eventImportance
        )
        
        print("🅿️ PARKING: Parked '\(event.title)' - Reason: \(reason.displayName), Important: \(eventImportance)")
        
        isLoading = false
    }
    
    /// Attempt to reschedule a parked event
    func attemptReschedule(
        parkedEventId: UUID,
        targetDate: Date,
        allEvents: [CalendarEvent]
    ) async -> Bool {
        
        guard let parkedEventIndex = parkedEvents.firstIndex(where: { $0.id == parkedEventId }) else {
            return false
        }
        
        let parkedEvent = parkedEvents[parkedEventIndex]
        let originalEvent = parkedEvent.originalEvent
        
        // Try to find available slot
        if let newSlot = bufferService.findNextAvailableSlot(
            duration: originalEvent.duration,
            events: allEvents,
            startingFrom: targetDate
        ) {
            // Create rescheduled event
            var rescheduledEvent = originalEvent
            rescheduledEvent.startDate = newSlot
            rescheduledEvent.endDate = newSlot.addingTimeInterval(originalEvent.duration)
            rescheduledEvent.isBumped = true
            rescheduledEvent.daysInParkingLot = parkedEvent.daysInParkingLot
            
            // Remove from parking lot
            parkedEvents.remove(at: parkedEventIndex)
        
            // Notify success
            await notificationService.scheduleEventRescheduledNotification(
                eventTitle: originalEvent.title,
                newTime: newSlot
            )
            
            print("🅿️ PARKING: ✅ Successfully rescheduled '\(originalEvent.title)' from parking lot")
            return true
        }
        
        print("🅿️ PARKING: ❌ Could not reschedule '\(originalEvent.title)' - no available slots")
        return false
    }
    
    /// Handle multiple events that need parking decisions
    func handleParkingDecisions(
        events: [CalendarEvent],
        conflicts: [CalendarEvent]
    ) async {
        
        // If only one event, auto-decide
        if events.count == 1 {
            let event = events[0]
            let isImportant = await determineEventImportance(event)
            await parkEvent(event, reason: .noAvailableSlots, isImportant: isImportant)
            return
        }
        
        // For multiple events, create decision request
        let decision = ParkingDecision(
            id: UUID(),
            events: events,
            conflicts: conflicts,
            createdAt: Date(),
            llmSuggestion: await generateLLMSuggestion(for: events)
        )
        
        pendingDecisions.append(decision)
        
        // Notify user of decision needed
        await notificationService.scheduleParkingDecisionNotification(
            eventCount: events.count
        )
    }
    
    /// Process user's parking decision
    func processUserDecision(
        decisionId: UUID,
        selectedEventIds: [UUID]
    ) async {
        
        guard let decisionIndex = pendingDecisions.firstIndex(where: { $0.id == decisionId }) else {
            return
        }
        
        let decision = pendingDecisions[decisionIndex]
        
        // Park selected events
        for eventId in selectedEventIds {
            if let event = decision.events.first(where: { $0.id == eventId }) {
                await parkEvent(event, reason: .userChoice)
            }
        }
        
        // Remove decision from pending
        pendingDecisions.remove(at: decisionIndex)
        
        print("🅿️ PARKING: ✅ Processed user decision - parked \(selectedEventIds.count) events")
    }
    
    /// Update days in parking lot for all parked events
    func updateParkingLotDays() {
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<parkedEvents.count {
            let daysSinceParked = calendar.dateComponents([.day], from: parkedEvents[i].dateParked, to: today).day ?? 0
            parkedEvents[i].daysInParkingLot = daysSinceParked
        }
    }
    
    /// Get events that have been parked for too long
    func getStaleParkedEvents(daysThreshold: Int = 7) -> [ParkingLotEvent] {
        return parkedEvents.filter { $0.daysInParkingLot >= daysThreshold }
    }
    
    /// Remove an event from parking lot
    func removeFromParkingLot(eventId: UUID) {
        parkedEvents.removeAll { $0.id == eventId }
        print("🅿️ PARKING: Removed event from parking lot")
    }
    
    // MARK: - LLM Integration
    
    /// Determine if an event is important using LLM
    private func determineEventImportance(_ event: CalendarEvent) async -> Bool {
        do {
            // Use the task priority method as a proxy for importance determination
            let result = try await llmService.suggestTaskPriority(
                title: event.title,
                description: event.description,
                context: [
                    "duration_minutes": .int(event.durationMinutes),
                    "event_type": .string(event.type.displayName)
                ]
            )
            
            // Consider urgent and high priority as important
            let isImportant = result.priority == .urgent || result.priority == .high
            
            print("🅿️ PARKING: LLM determined '\(event.title)' is \(isImportant ? "important" : "not important") (priority: \(result.priority))")
            return isImportant
            
        } catch {
            print("🅿️ PARKING: ❌ LLM error for importance - defaulting to important: \(error)")
            return true // Default to important if LLM fails
        }
    }
    
    /// Generate LLM suggestion for parking decisions
    private func generateLLMSuggestion(for events: [CalendarEvent]) async -> ParkingSuggestion {
        do {
            // Use task priority analysis for each event to determine parking recommendations
            var eventPriorities: [(CalendarEvent, TaskPriorityResult)] = []
            
            for event in events {
                let priorityResult = try await llmService.suggestTaskPriority(
                    title: event.title,
                    description: event.description,
                    context: [
                        "duration_minutes": .int(event.durationMinutes),
                        "event_type": .string(event.type.displayName),
                        "parking_decision": .bool(true)
                    ]
                )
                eventPriorities.append((event, priorityResult))
    }
    
            // Recommend parking lower priority events
            let lowPriorityEvents = eventPriorities.filter { _, priority in
                priority.priority == .low || priority.priority == .medium
            }
            
            let recommendedToPark = lowPriorityEvents.map { event, _ in event.id }
            let reasoning = "Recommended parking \(lowPriorityEvents.count) lower priority events out of \(events.count) total"
            
            return ParkingSuggestion(
                recommendedToPark: recommendedToPark,
                reasoning: reasoning,
                confidence: 0.8
            )
            
        } catch {
            print("🅿️ PARKING: ❌ LLM error for suggestions - using default: \(error)")
            return ParkingSuggestion(
                recommendedToPark: events.map { $0.id },
                reasoning: "Unable to analyze - defaulting to parking all events",
                confidence: 0.5
            )
        }
    }

}

// MARK: - Supporting Types

struct ParkingLotEvent: Identifiable {
    let id: UUID = UUID()
    let originalEvent: CalendarEvent
    let reason: ParkingReason
    let isImportant: Bool
    let dateParked: Date
    var daysInParkingLot: Int
    
    var displayTitle: String {
        let badge = daysInParkingLot > 0 ? " (\(daysInParkingLot)d)" : ""
        return originalEvent.title + badge
    }
}

enum ParkingReason: String, CaseIterable {
    case noAvailableSlots = "no_slots"
    case bufferViolation = "buffer_violation"
    case userChoice = "user_choice"
    case bumpCascade = "bump_cascade"
    case conflictResolution = "conflict_resolution"
    
    var displayName: String {
        switch self {
        case .noAvailableSlots: return "No Available Slots"
        case .bufferViolation: return "Buffer Violation"
        case .userChoice: return "User Choice"
        case .bumpCascade: return "Bump Cascade"
        case .conflictResolution: return "Conflict Resolution"
        }
    }
}

struct ParkingDecision: Identifiable {
    let id: UUID
    let events: [CalendarEvent]
    let conflicts: [CalendarEvent]
    let createdAt: Date
    let llmSuggestion: ParkingSuggestion
}

struct ParkingSuggestion {
    let recommendedToPark: [UUID]
    let reasoning: String
    let confidence: Double
} 