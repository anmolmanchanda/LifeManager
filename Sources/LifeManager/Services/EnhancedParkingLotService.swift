import Foundation
import SwiftUI

/// Enhanced parking lot service with LLM-driven importance ranking
@MainActor
class EnhancedParkingLotService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var parkedEvents: [ParkedEvent] = []
    @Published var isAnalyzing: Bool = false
    
    private let llmService: LLMService
    private let taskRepository = TaskRepository()
    
    init(llmService: LLMService) {
        self.llmService = llmService
    }
    
    // MARK: - Parking Logic
    
    /// Park an event that couldn't be scheduled
    func parkEvent(
        _ event: CalendarEvent,
        reason: ParkingReason,
        mustHappenToday: Bool = false
    ) async {
        
        let importance = await analyzeEventImportance(event)
        
        let parkedEvent = ParkedEvent(
            originalEvent: event,
            parkedDate: Date(),
            reason: reason,
            importance: importance,
            mustHappenToday: mustHappenToday,
            daysParked: 1
        )
        
        parkedEvents.append(parkedEvent)
        parkedEvents.sort { $0.importance.rawValue > $1.importance.rawValue }
        
        print("🔧 PARKING: Parked '\(event.title)' with importance: \(importance)")
        
        // Send notification about parked event
        NotificationService.shared.sendParkingNotification(
            eventTitle: event.title,
            reason: reason.description
        )
        
        // If it's critical and must happen today, prompt user
        if importance == .critical && mustHappenToday {
            await promptUserForCriticalEvent(parkedEvent)
        }
    }
    
    /// Analyze event importance using LLM
    private func analyzeEventImportance(_ event: CalendarEvent) async -> EventImportance {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Use the task priority suggestion method as it's similar
            let result = try await llmService.suggestTaskPriority(
                title: event.title,
                description: event.description,
                context: [
                    "duration_minutes": .int(event.durationMinutes),
                    "start_time": .string(formatDate(event.startDate)),
                    "event_type": .string("calendar_event")
                ]
            )
            
            // Map task priority to event importance
            switch result.priority {
            case .urgent:
                return .critical
            case .high:
                return .high
            case .medium:
                return .medium
            case .low:
                return .low
            }
        } catch {
            print("🔧 PARKING: ❌ Error analyzing importance: \(error)")
            return .medium // Default fallback
        }
    }
    

    
    /// Prompt user for critical event that must happen today
    private func promptUserForCriticalEvent(_ parkedEvent: ParkedEvent) async {
        print("🔧 PARKING: 🚨 Critical event '\(parkedEvent.originalEvent.title)' needs attention!")
        
        // Send critical event notification
        NotificationService.shared.sendCriticalEventNotification(
            eventTitle: parkedEvent.originalEvent.title
        )
        
        // TODO: Show user notification/modal for decision
        // This would trigger a SwiftUI alert or modal in the UI
    }
    
    // MARK: - Event Management
    
    /// Remove event from parking lot (when rescheduled or cancelled)
    func removeParkedEvent(_ eventId: UUID) {
        parkedEvents.removeAll { $0.id == eventId }
        print("🔧 PARKING: Removed event from parking lot")
    }
    
    /// Update days parked for all events
    func updateDaysParked() {
        let calendar = Calendar.current
        
        for i in 0..<parkedEvents.count {
            let daysSince = calendar.dateComponents([.day], from: parkedEvents[i].parkedDate, to: Date()).day ?? 0
            parkedEvents[i].daysParked = max(1, daysSince + 1)
        }
        
        // Re-sort by importance and days parked
        parkedEvents.sort { event1, event2 in
            if event1.importance == event2.importance {
                return event1.daysParked > event2.daysParked
            }
            return event1.importance.rawValue > event2.importance.rawValue
        }
    }
    
    /// Get events that should be prioritized for rescheduling
    func getPriorityEvents() -> [ParkedEvent] {
        return parkedEvents.filter { event in
            event.importance == .critical || 
            (event.importance == .high && event.daysParked >= 2) ||
            event.mustHappenToday
        }
    }
    
    /// Suggest optimal rescheduling for parked events
    func suggestRescheduling(
        availableSlots: [DateInterval],
        bufferService: BufferManagementService
    ) async -> [ReschedulingSuggestion] {
        
        var suggestions: [ReschedulingSuggestion] = []
        
        for parkedEvent in parkedEvents.prefix(5) { // Limit to top 5 for performance
            let eventDuration = parkedEvent.originalEvent.duration
            
            // Find best available slot
            for slot in availableSlots {
                if slot.duration >= TimeInterval(eventDuration) {
                    let suggestion = ReschedulingSuggestion(
                        parkedEvent: parkedEvent,
                        suggestedSlot: slot,
                        confidence: calculateConfidence(parkedEvent: parkedEvent, slot: slot)
                    )
                    suggestions.append(suggestion)
                    break // Take first available slot
                }
            }
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    /// Calculate confidence score for a rescheduling suggestion
    private func calculateConfidence(parkedEvent: ParkedEvent, slot: DateInterval) -> Double {
        var confidence: Double = 0.5 // Base confidence
        
        // Higher confidence for more important events
        switch parkedEvent.importance {
        case .critical: confidence += 0.4
        case .high: confidence += 0.3
        case .medium: confidence += 0.1
        case .low: confidence += 0.0
        }
        
        // Higher confidence for events parked longer
        confidence += min(0.1 * Double(parkedEvent.daysParked), 0.3)
        
        // Lower confidence for slots that are far in the future
        let daysUntilSlot = Calendar.current.dateComponents([.day], from: Date(), to: slot.start).day ?? 0
        confidence -= min(0.05 * Double(daysUntilSlot), 0.2)
        
        return max(0.0, min(1.0, confidence))
    }
    
    // MARK: - Integration with Tasks
    
    /// Convert parked calendar event to LifeTask if needed
    func convertToTask(_ parkedEvent: ParkedEvent) async -> LifeTask? {
        let task = LifeTask(
            id: UUID(),
            title: parkedEvent.originalEvent.title,
            description: "Converted from parked calendar event",
            priority: mapImportanceToPriority(parkedEvent.importance),
            status: .todo,
            dueDate: ISO8601DateFormatter().string(from: parkedEvent.originalEvent.endDate),
            estimatedDuration: parkedEvent.originalEvent.durationMinutes,
            workPersonal: parkedEvent.originalEvent.workPersonal,
            projectId: parkedEvent.originalEvent.projectId,
            areaId: parkedEvent.originalEvent.areaId,
            isFocus: parkedEvent.importance == .critical,
            isArchived: false
        )
        
        do {
            let savedTask = try await taskRepository.createTask(task)
            print("🔧 PARKING: ✅ Converted parked event to task: \(savedTask.title)")
            
            // Remove from parking lot after conversion
            removeParkedEvent(parkedEvent.id)
            
            return savedTask
        } catch {
            print("🔧 PARKING: ❌ Error converting to task: \(error)")
            return nil
        }
    }
    
    /// Map event importance to task priority
    private func mapImportanceToPriority(_ importance: EventImportance) -> TaskPriority {
        switch importance {
        case .critical: return .urgent
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
    
    // MARK: - Utility Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Models

/// Parked event with metadata
struct ParkedEvent: Identifiable, Equatable {
    let id = UUID()
    let originalEvent: CalendarEvent
    let parkedDate: Date
    let reason: ParkingReason
    var importance: EventImportance
    let mustHappenToday: Bool
    var daysParked: Int
    
    static func == (lhs: ParkedEvent, rhs: ParkedEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Reason why an event was parked
enum ParkingReason {
    case overbooking
    case conflictWithActual
    case noAvailableSlot
    case userRequested
    case lowImportance
    
    var description: String {
        switch self {
        case .overbooking: return "Day was overbooked"
        case .conflictWithActual: return "Conflict with actual time entry"
        case .noAvailableSlot: return "No available time slot"
        case .userRequested: return "User requested"
        case .lowImportance: return "Low importance, auto-parked"
        }
    }
}

/// Event importance levels
enum EventImportance: Int, CaseIterable {
    case critical = 4
    case high = 3
    case medium = 2
    case low = 1
    
    var description: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .gray
        }
    }
}

/// Rescheduling suggestion
struct ReschedulingSuggestion {
    let parkedEvent: ParkedEvent
    let suggestedSlot: DateInterval
    let confidence: Double
    
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
} 