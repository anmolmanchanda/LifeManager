import SwiftUI
import Foundation

/// Daily calendar view with detailed hourly timeline
/// 
/// Provides:
/// - Hourly time slots from midnight (00:00) to 11 PM (23:00)
/// - Event positioning within time slots
/// - Current time indicator
/// - Drag and drop support for scheduling
/// - Smooth scrolling to current time
struct CalendarDayView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - Constants
    private let hours = Array(0...23) // Midnight to 11 PM (24-hour format)
    private let hourHeight: CGFloat = 320 // Quadrupled from 80 to prevent overlapping completely
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 12) {
                    ForEach(hours, id: \.self) { hour in
                        CalendarDayHourView(
                            hour: hour
                        )
                        .environmentObject(calendarViewModel)
                        .id("hour-\(hour)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                scrollToCurrentTime(proxy: proxy)
            }
            .onChange(of: calendarViewModel.selectedDate) { _ in
                // Scroll to current time when date changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Private Methods
    
    /// Scrolls to the current time or 8 AM if not today
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let targetHour: Int
        
        if Calendar.current.isDateInToday(calendarViewModel.selectedDate) {
            let currentHour = Calendar.current.component(.hour, from: Date())
            // Scroll to current hour, now supporting full 24-hour range
            targetHour = max(0, min(23, currentHour))
        } else {
            // Default to 8 AM for other days
            targetHour = 8
        }
        
        withAnimation(.easeInOut(duration: 0.8)) {
            proxy.scrollTo("hour-\(targetHour)", anchor: .top)
        }
    }
}

// MARK: - Day Hour View Component

/// Individual hour row in the day view
struct CalendarDayHourView: View {
    // MARK: - Properties
    let hour: Int
    
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - State
    @State private var isHovered = false
    @State private var isDragTargeted = false
    
    // MARK: - Constants
    private let hourHeight: CGFloat = 320 // Quadrupled from 80 to prevent overlapping completely
    
    // MARK: - Computed Properties
    
    private var hourDate: Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: calendarViewModel.selectedDate
        ) ?? calendarViewModel.selectedDate
    }
    
    private var events: [CalendarEvent] {
        calendarViewModel.events(for: calendarViewModel.selectedDate, hour: hour)
    }
    
    private var isCurrentHour: Bool {
        Calendar.current.isDateInToday(calendarViewModel.selectedDate) &&
        Calendar.current.component(.hour, from: Date()) == hour
    }
    
    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: hourDate)
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            // Time label column
            timeColumn
            
            // Event content area
            eventArea
        }
        .frame(height: hourHeight)
        .background(backgroundColor)
        .overlay(alignment: .bottom) {
            // Hour separator line
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 0.5)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onDrop(of: [.text], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onTapGesture {
            handleTap()
        }
        .contextMenu {
            CalendarHourContextMenu(
                hourDate: hourDate,
                events: events,
                onCreateEvent: handleCreateEvent,
                onQuickSchedule: handleQuickSchedule,
                onShowAvailableTasks: handleShowAvailableTasks,
                onShowDetails: handleShowDetails,
                onClearTimeSlot: handleClearTimeSlot
            )
        }
    }
    
    // MARK: - Time Column
    
    private var timeColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(timeLabel)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isCurrentHour ? .blue : .secondary)
            
            if isCurrentHour {
                Text("now")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .opacity(0.8)
            }
        }
        .frame(width: 60, alignment: .trailing)
        .padding(.trailing, 12)
    }
    
    // MARK: - Event Area
    
    private var eventArea: some View {
        ZStack(alignment: .topLeading) {
            // Background with current time indicator
            RoundedRectangle(cornerRadius: 8)
                .fill(eventAreaBackgroundColor)
                .overlay {
                    if isCurrentHour {
                        currentTimeIndicator
                    }
                }
            
            // Events
            if !events.isEmpty {
                eventsStack
            } else if isHovered {
                hoverPlaceholder
            }
            
            // Drop target indicator
            if isDragTargeted {
                dropTargetIndicator
            }
        }
        .padding(.trailing, 16)
    }
    
    // MARK: - Current Time Indicator
    
    private var currentTimeIndicator: some View {
        GeometryReader { geometry in
            let currentMinute = Calendar.current.component(.minute, from: Date())
            let offset = CGFloat(currentMinute) / 60.0 * geometry.size.height
            
            Rectangle()
                .fill(LinearGradient(
                    colors: [.blue, .blue.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 2)
                .offset(y: offset)
                .animation(.easeInOut(duration: 0.3), value: offset)
        }
    }
    
    // MARK: - Events Stack
    
    private var eventsStack: some View {
        LazyVStack(spacing: 6) {
            ForEach(events) { event in
                CalendarEventView(event: event)
                    .environmentObject(calendarViewModel)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(8)
    }
    
    // MARK: - Hover Placeholder
    
    private var hoverPlaceholder: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue.opacity(0.7))
                
                Text("Schedule here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            Spacer()
        }
        .padding(8)
        .opacity(0.8)
    }
    
    // MARK: - Drop Target Indicator
    
    private var dropTargetIndicator: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.opacity(0.2))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .scaleEffect(isDragTargeted ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isDragTargeted)
            }
    }
    
    // MARK: - Computed Colors
    
    private var backgroundColor: Color {
        if isCurrentHour {
            return Color.blue.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var eventAreaBackgroundColor: Color {
        if isDragTargeted {
            return Color.blue.opacity(0.1)
        } else if isHovered && hourDate >= Date() {
            // Only show blue hover effect for current and future times
            return Color(NSColor.controlAccentColor).opacity(0.05)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.3)
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        
        // Handle scheduling at this time - placeholder for now
        print("Tapped on hour \(hour)")
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        LifeLogger.dragDrop(.info, "Drop initiated at \(timeLabel)")
        
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        
        // First try to use the dragged task from view model (most reliable)
        if let draggedTask = calendarViewModel.draggedTask {
            LifeLogger.logDragDropOperation(
                operation: "DROP_FROM_VIEWMODEL",
                taskId: draggedTask.id,
                taskTitle: draggedTask.title,
                sourceLocation: "ParkingLot",
                targetLocation: timeLabel,
                success: true
            )
            
            Task {
                await calendarViewModel.scheduleTask(draggedTask, at: hourDate)
                await MainActor.run {
                    calendarViewModel.completeDrag()
                    LifeLogger.dragDrop(.info, "✅ Scheduled task '\(draggedTask.title)' at \(timeLabel)")
                }
            }
            return
        }
        
        // Fallback: try to get task from draggable data
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.text") {
                provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
                    if let taskIdString = item as? String,
                       let taskId = UUID(uuidString: taskIdString) {
                        
                        Task { @MainActor in
                            if let task = calendarViewModel.allTasks.first(where: { $0.id == taskId }) {
                                LifeLogger.logDragDropOperation(
                                    operation: "DROP_FROM_DRAGGABLE",
                                    taskId: task.id,
                                    taskTitle: task.title,
                                    sourceLocation: "ParkingLot",
                                    targetLocation: timeLabel,
                                    success: true
                                )
                                
                                await calendarViewModel.scheduleTask(task, at: hourDate)
                                calendarViewModel.completeDrag()
                                LifeLogger.dragDrop(.info, "✅ Scheduled task '\(task.title)' at \(timeLabel)")
                            } else {
                                LifeLogger.dragDrop(.error, "Failed to find task with ID: \(taskIdString)")
                                calendarViewModel.cancelDrag()
                            }
                        }
                    } else {
                        LifeLogger.dragDrop(.error, "Failed to parse task ID from draggable data")
                        Task { @MainActor in
                            calendarViewModel.cancelDrag()
                        }
                    }
                }
                return
            }
        }
        
        // No valid drop data found
        LifeLogger.dragDrop(.warning, "No valid drop data found")
        Task { @MainActor in
            calendarViewModel.cancelDrag()
        }
    }
    
    private func handleCreateEvent() {
        LifeLogger.contextMenu(.info, "Creating new event at \(timeLabel)")
        
        // Create a new event at this time slot
        let estimatedDuration: TimeInterval = 3600 // 1 hour default
        
        let newEvent = CalendarEvent(
            title: "New Event",
            description: "Created at \(timeLabel)",
            startDate: hourDate,
            endDate: hourDate.addingTimeInterval(estimatedDuration),
            workPersonal: .work,
            color: .blue,
            source: .user,
            duration: estimatedDuration
        )
        
        let initialEventCount = calendarViewModel.events.count
        calendarViewModel.events.append(newEvent)
        calendarViewModel.applyFilters()
        
        LifeLogger.logContextMenuAction(
            action: "CREATE_EVENT",
            timeSlot: hourDate,
            eventCount: calendarViewModel.events.count,
            taskCount: calendarViewModel.allTasks.count,
            success: calendarViewModel.events.count > initialEventCount
        )
        
        LifeLogger.contextMenu(.info, "✅ Created new event at \(timeLabel)")
    }
    
    private func handleQuickSchedule() {
        // Schedule the first available task from parking lot
        if let firstTask = calendarViewModel.allTasks.first {
            Task {
                await calendarViewModel.scheduleTask(firstTask, at: hourDate)
            }
        } else {
            print("No tasks available in parking lot")
        }
    }
    
    private func handleShowAvailableTasks() {
        // Show available tasks in parking lot
        let taskCount = calendarViewModel.allTasks.count
        print("📋 Available tasks in parking lot: \(taskCount)")
        for (index, task) in calendarViewModel.allTasks.prefix(5).enumerated() {
            print("  \(index + 1). \(task.title)")
        }
        if taskCount > 5 {
            print("  ... and \(taskCount - 5) more")
        }
    }
    
    private func handleShowDetails() {
        // Show details for this time slot
        if events.isEmpty {
            print("📅 Time slot: \(timeLabel) - Available for scheduling")
        } else {
            print("📅 Time slot: \(timeLabel) - \(events.count) event(s)")
            for event in events {
                print("  • \(event.title) (\(event.source.rawValue))")
            }
        }
    }
    
    private func handleClearTimeSlot() {
        // Remove user-created events from this time slot
        let userEvents = events.filter { $0.source == .user }
        for event in userEvents {
            if let index = calendarViewModel.events.firstIndex(where: { $0.id == event.id }) {
                calendarViewModel.events.remove(at: index)
            }
        }
        print("🗑️ Cleared \(userEvents.count) user event(s) from \(timeLabel)")
    }
}

// MARK: - Calendar Hour Context Menu

/// Context menu for calendar hour slots
struct CalendarHourContextMenu: View {
    let hourDate: Date
    let events: [CalendarEvent]
    let onCreateEvent: () -> Void
    let onQuickSchedule: () -> Void
    let onShowAvailableTasks: () -> Void
    let onShowDetails: () -> Void
    let onClearTimeSlot: () -> Void
    
    var body: some View {
        Group {
            // Only show context menu for future events or non-Toggl events
            if hourDate > Date() || events.allSatisfy({ $0.source != .toggl }) {
                Button("Create Event") {
                    onCreateEvent()
                }
                
                Button("Quick Schedule Task") {
                    onQuickSchedule()
                }
                
                Button("Show Available Tasks") {
                    onShowAvailableTasks()
                }
                
                Button("Show Details") {
                    onShowDetails()
                }
                
                if !events.isEmpty {
                    Divider()
                    
                    Button("Clear Time Slot", role: .destructive) {
                        onClearTimeSlot()
                    }
                }
            } else {
                // Show limited context menu for past/Toggl events
                Button("Show Details") {
                    onShowDetails()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarDayView()
        .environmentObject(CalendarViewModel())
        .frame(width: 600, height: 800)
} 