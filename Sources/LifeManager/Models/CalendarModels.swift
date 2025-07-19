import Foundation
import SwiftUI

// MARK: - Calendar View Models

/// Calendar view mode (month, week, day)
enum CalendarViewMode: String, CaseIterable {
    case month = "month"
    case week = "week"
    case day = "day"
    
    var displayName: String {
        switch self {
        case .month: return "Month"
        case .week: return "Week"
        case .day: return "Day"
        }
    }
    
    var icon: String {
        switch self {
        case .month: return "calendar"
        case .week: return "calendar.day.timeline.left"
        case .day: return "calendar.day.timeline.leading"
        }
    }
}

/// Calendar filter options for filtering events
enum CalendarFilter: String, CaseIterable, Hashable {
    case work = "work"
    case personal = "personal"
    case toggl = "toggl"
    case user = "user"
    case locked = "locked"
    case unlocked = "unlocked"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .toggl: return "Toggl"
        case .user: return "User"
        case .locked: return "Locked"
        case .unlocked: return "Unlocked"
        }
    }
}

/// Calendar event type for different content types
enum CalendarEventType: String, CaseIterable {
    case task = "task"
    case timeBlock = "time_block"
    case meeting = "meeting"
    case reminder = "reminder"
    case actualToggl = "actual_toggl"
    case plannedFuture = "planned_future"
    case userEvent = "user_event"
    
    var displayName: String {
        switch self {
        case .task: return "Task"
        case .timeBlock: return "Time Block"
        case .meeting: return "Meeting"
        case .reminder: return "Reminder"
        case .actualToggl: return "Actual Toggl"
        case .plannedFuture: return "Planned Future"
        case .userEvent: return "User Event"
        }
    }
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .timeBlock: return "clock.fill"
        case .meeting: return "person.2.fill"
        case .reminder: return "bell.fill"
        case .actualToggl: return "checkmark.circle"
        case .plannedFuture: return "clock.fill"
        case .userEvent: return "person.fill"
        }
    }
}

/// Calendar event model representing scheduled items
struct CalendarEvent: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date
    let type: CalendarEventType
    let priority: TaskPriority
    let workPersonal: WorkPersonalType
    let projectId: UUID?
    let areaId: UUID?
    let taskId: UUID?
    let isLocked: Bool
    let color: Color
    
    // Advanced Calendar Features
    var isActual: Bool = false
    var originalPlannedTime: DateInterval?
    var source: EventSource = .user
    var togglEntryId: Int?
    var isBumped: Bool = false
    var bumpedByMinutes: Int = 0
    var isImportant: Bool = false
    var daysInParkingLot: Int = 0
    
    let duration: TimeInterval // Duration in seconds
    
    enum EventSource: String {
        case user = "user"
        case toggl = "toggl"
        case lifeTask = "lifeTask"
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        type: CalendarEventType = .task,
        priority: TaskPriority = .medium,
        workPersonal: WorkPersonalType = .work,
        projectId: UUID? = nil,
        areaId: UUID? = nil,
        taskId: UUID? = nil,
        isLocked: Bool = false,
        color: Color = .blue,
        isActual: Bool = false,
        originalPlannedTime: DateInterval? = nil,
        source: EventSource = .user,
        togglEntryId: Int? = nil,
        isBumped: Bool = false,
        bumpedByMinutes: Int = 0,
        isImportant: Bool = false,
        daysInParkingLot: Int = 0,
        duration: TimeInterval
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.priority = priority
        self.workPersonal = workPersonal
        self.projectId = projectId
        self.areaId = areaId
        self.taskId = taskId
        self.isLocked = isLocked
        self.color = color
        self.isActual = isActual
        self.originalPlannedTime = originalPlannedTime
        self.source = source
        self.togglEntryId = togglEntryId
        self.isBumped = isBumped
        self.bumpedByMinutes = bumpedByMinutes
        self.isImportant = isImportant
        self.daysInParkingLot = daysInParkingLot
        self.duration = duration
    }
    
    /// Duration in minutes
    var durationMinutes: Int {
        Int(duration / 60)
    }
    
    /// Check if event overlaps with another event
    func overlaps(with other: CalendarEvent) -> Bool {
        startDate < other.endDate && endDate > other.startDate
    }
    
    /// Check if event is within a date range
    func isWithin(start: Date, end: Date) -> Bool {
        startDate >= start && endDate <= end
    }
    
    /// Determines if this event is in the past relative to current time
    var isInPast: Bool {
        return endDate < Date()
    }
    
    /// Determines if this event is currently happening
    var isHappening: Bool {
        let now = Date()
        return startDate <= now && endDate > now
    }
    
    /// Determines if this event is in the future
    var isInFuture: Bool {
        return startDate > Date()
    }
    
    /// Returns the appropriate event type based on time and source
    var eventType: CalendarEventType {
        if source == .toggl && (isInPast || isHappening) {
            return .actualToggl
        } else if isInFuture {
            return .plannedFuture
        } else {
            return .userEvent
        }
    }
    
    // Equatable conformance
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// Make CalendarEvent hashable based on id only
extension CalendarEvent: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Calendar filter settings model for filtering events and tasks
struct CalendarFilterSettings: Hashable {
    var selectedProjects: Set<UUID> = []
    var selectedAreas: Set<UUID> = []
    var selectedPriorities: Set<TaskPriority> = []
    var workPersonalFilter: WorkPersonalType?
    var showOnlyFocus: Bool = false
    var showCompleted: Bool = false
    var eventTypes: Set<CalendarEventType> = Set(CalendarEventType.allCases)
    
    /// Check if any filters are active
    var isActive: Bool {
        !selectedProjects.isEmpty ||
        !selectedAreas.isEmpty ||
        !selectedPriorities.isEmpty ||
        workPersonalFilter != nil ||
        showOnlyFocus ||
        !showCompleted ||
        eventTypes.count != CalendarEventType.allCases.count
    }
}

/// Available time slot for scheduling
struct AvailableTimeSlot {
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let isAvailable: Bool
    let priority: Int // Higher number = better slot
    
    init(startTime: Date, endTime: Date, isAvailable: Bool = true, priority: Int = 1) {
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        self.isAvailable = isAvailable
        self.priority = priority
    }
}

/// Smart scheduler for Motion AI-style automation
struct SmartScheduler {
    
    /// Generate available time slots within a date range
    static func generateAvailableSlots(
        from startDate: Date,
        to endDate: Date,
        existingEvents: [CalendarEvent],
        workingHours: ClosedRange<Int>,
        slotDuration: Int = 30
    ) -> [AvailableTimeSlot] {
        
        var availableSlots: [AvailableTimeSlot] = []
        let calendar = Calendar.current
        
        // Iterate through each day in the range
        var currentDate = startDate
        while currentDate <= endDate {
            // Generate slots for working hours only
            for hour in workingHours {
                guard let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: currentDate) else { continue }
                
                // Generate 30-minute slots within each hour
                for minute in stride(from: 0, to: 60, by: slotDuration) {
                    guard let slotStart = calendar.date(byAdding: .minute, value: minute, to: hourStart),
                          let slotEnd = calendar.date(byAdding: .minute, value: slotDuration, to: slotStart) else { continue }
                    
                    // Check if slot conflicts with existing events
                    let hasConflict = existingEvents.contains { event in
                        event.startDate < slotEnd && event.endDate > slotStart
                    }
                    
                    // Calculate priority based on time of day and existing workload
                    let priority = calculateSlotPriority(slotStart, workingHours: workingHours)
                    
                    let slot = AvailableTimeSlot(
                        startTime: slotStart,
                        endTime: slotEnd,
                        isAvailable: !hasConflict,
                        priority: priority
                    )
                    
                    availableSlots.append(slot)
                }
            }
            
            // Move to next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }
        
        return availableSlots.sorted { $0.priority > $1.priority }
    }
    
    /// Auto-schedule unscheduled tasks using intelligent algorithms
    static func autoScheduleTasks(
        unscheduled: [LifeTask],
        existingEvents: [CalendarEvent],
        availableSlots: [AvailableTimeSlot],
        workingHours: ClosedRange<Int>
    ) -> [CalendarEvent] {
        
        var newEvents: [CalendarEvent] = []
        var usedSlots: Set<Date> = []
        
        // Sort tasks by priority and due date urgency
        let sortedTasks = unscheduled.sorted { task1, task2 in
            // First by priority
            if task1.priority != task2.priority {
                return task1.priority.priorityScore > task2.priority.priorityScore
            }
            
            // Then by focus status
            if task1.isFocus != task2.isFocus {
                return task1.isFocus && !task2.isFocus
            }
            
            // Then by estimated duration (shorter tasks first for filling gaps)
            return (task1.estimatedDuration ?? 60) < (task2.estimatedDuration ?? 60)
        }
        
        // Schedule each task
        for task in sortedTasks {
            guard let duration = task.estimatedDuration else { continue }
            
            // Find best available slot
            if let bestSlot = findBestSlot(
                for: task,
                duration: duration,
                availableSlots: availableSlots,
                usedSlots: usedSlots
            ) {
                // Create calendar event
                let event = CalendarEvent(
                    title: task.title,
                    description: task.description,
                    startDate: bestSlot.startTime,
                    endDate: bestSlot.startTime.addingTimeInterval(TimeInterval(duration * 60)),
                    type: CalendarEventType.task,
                    priority: task.priority,
                    workPersonal: task.workPersonal,
                    projectId: task.projectId,
                    areaId: task.areaId,
                    taskId: task.id,
                    isLocked: false,
                    color: colorForTask(task),
                    duration: TimeInterval(duration * 60)
                )
                
                newEvents.append(event)
                usedSlots.insert(bestSlot.startTime)
            }
        }
        
        return newEvents
    }
    
    /// Calculate priority score for a time slot
    private static func calculateSlotPriority(_ date: Date, workingHours: ClosedRange<Int>) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        var priority = 1
        
        // Prefer mid-morning and early afternoon
        if hour >= 9 && hour <= 11 {
            priority += 3 // Morning focus time
        } else if hour >= 13 && hour <= 15 {
            priority += 2 // Post-lunch focus time
        } else if hour >= 16 && hour <= 17 {
            priority += 1 // Late afternoon
        }
        
        // Prefer weekdays over weekends
        if dayOfWeek >= 2 && dayOfWeek <= 6 { // Monday-Friday
            priority += 2
        }
        
        // Prefer Tuesday-Thursday (peak productivity days)
        if dayOfWeek >= 3 && dayOfWeek <= 5 {
            priority += 1
        }
        
        return priority
    }
    
    /// Find the best available slot for a task
    private static func findBestSlot(
        for task: LifeTask,
        duration: Int,
        availableSlots: [AvailableTimeSlot],
        usedSlots: Set<Date>
    ) -> AvailableTimeSlot? {
        
        return availableSlots.first { slot in
            // Check if slot is available and not used
            slot.isAvailable &&
            !usedSlots.contains(slot.startTime) &&
            slot.durationMinutes >= duration &&
            // For focus tasks, prefer higher priority slots
            (!task.isFocus || slot.priority >= 3)
        }
    }
    
    /// Generate color for task based on its properties
    private static func colorForTask(_ task: LifeTask) -> Color {
        switch task.priority {
        case .critical:
            return .purple
        case .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return task.workPersonal == .work ? .blue : .purple
        case .low:
            return .green
        }
    }
}

// MARK: - Calendar Extensions

extension LifeTask {
    /// Convert task to calendar event
    func toCalendarEvent() -> CalendarEvent? {
        guard let dueDateString = dueDate,
              let dueDate = ISO8601DateFormatter().date(from: dueDateString),
              let duration = estimatedDuration else { return nil }
        
        let endDate = dueDate.addingTimeInterval(TimeInterval(duration * 60))
        
        return CalendarEvent(
            title: title,
            description: description,
            startDate: dueDate,
            endDate: endDate,
            type: CalendarEventType.task,
            priority: priority,
            workPersonal: workPersonal,
            projectId: projectId,
            areaId: areaId,
            taskId: id,
            isLocked: false,
            color: colorForPriority(priority),
            duration: TimeInterval(duration * 60)
        )
    }
    
    private func colorForPriority(_ priority: TaskPriority) -> Color {
        switch priority {
        case .critical: return .purple
        case .urgent: return .red
        case .high: return .orange
        case .medium: return workPersonal == .work ? .blue : .purple
        case .low: return .green
        }
    }
}

// MARK: - Date Extensions for Calendar

extension Date {
    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of day
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }
    
    /// Start of week (Sunday)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// End of week (Saturday)
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)?.addingTimeInterval(-1) ?? self
    }
    
    /// Start of month
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    
    /// End of month
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }
    
    /// Format for calendar day display (e.g., "Mon")
    func calendarDayFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// Format for calendar display (e.g., "2:30 PM")
    func calendarDisplayFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    /// Relative format for suggestions (e.g., "Today 2:30 PM", "Tomorrow 9:00 AM")
    func calendarSuggestionFormat() -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(self) {
            formatter.dateFormat = "'Today' h:mm a"
        } else if calendar.isDateInTomorrow(self) {
            formatter.dateFormat = "'Tomorrow' h:mm a"
        } else if calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: self)
    }
} 