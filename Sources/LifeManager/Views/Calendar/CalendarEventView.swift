import SwiftUI
import Foundation

/// Individual event view component for calendar events
/// 
/// Provides:
/// - Event title and description display
/// - Color-coded priority and type indicators
/// - Time and duration information
/// - Work/Personal classification
/// - Interactive hover and tap states
/// - Context menu for event actions
struct CalendarEventView: View {
    // MARK: - Properties
    let event: CalendarEvent
    
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - State
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var showingContextMenu = false
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 6) {
            // Priority/type indicator
            priorityIndicator
            
            // Event content
            eventContent
            
            Spacer()
            
            // Status indicators
            statusIndicators
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(eventBackgroundColor)
        .cornerRadius(6)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(event.color.opacity(0.3), lineWidth: 1)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 3 : 1, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            handleTap()
        }
        .contextMenu {
            EventContextMenu(event: event)
                .environmentObject(calendarViewModel)
        }
    }
    
    // MARK: - Priority Indicator
    
    private var priorityIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(LinearGradient(
                colors: [event.color, event.color.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .frame(width: 4)
            .shadow(color: event.color.opacity(0.3), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Event Content
    
    private var eventContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Title
            Text(event.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Description (if available)
            if let description = event.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Time and duration
            timeAndDurationInfo
        }
    }
    
    // MARK: - Time and Duration Info
    
    private var timeAndDurationInfo: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            
            Text(timeDisplayText)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        VStack(spacing: 3) {
            // Work/Personal indicator
            workPersonalIndicator
            
            // Lock indicator (if locked)
            if event.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            }
            
            // Source indicator (Toggl vs User)
            sourceIndicator
        }
    }
    
    // MARK: - Work/Personal Indicator
    
    private var workPersonalIndicator: some View {
        ZStack {
            Circle()
                .fill(workPersonalColor.opacity(0.2))
                .frame(width: 12, height: 12)
            
            Text(workPersonalInitial)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(workPersonalColor)
        }
    }
    
    // MARK: - Source Indicator
    
    private var sourceIndicator: some View {
        Group {
            if event.source == .toggl {
                Image(systemName: "timer")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "person")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var eventBackgroundColor: Color {
        if isPressed {
            return event.color.opacity(0.2)
        } else if isHovered {
            return event.color.opacity(0.15)
        } else {
            return event.color.opacity(0.1)
        }
    }
    
    private var timeDisplayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTime = formatter.string(from: event.startDate)
        return "\(startTime) • \(Int(event.duration / 60))min"
    }
    
    private var workPersonalColor: Color {
        switch event.workPersonal {
        case .work:
            return .blue
        case .personal:
            return .green
        case .both:
            return .purple
        }
    }
    
    private var workPersonalInitial: String {
        switch event.workPersonal {
        case .work:
            return "W"
        case .personal:
            return "P"
        case .both:
            return "B"
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        
        // Animate press
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
        
        // Handle event selection/editing
        print("Tapped on event: \(event.title)")
    }
}

// MARK: - Event Context Menu Component

/// Context menu for calendar events
struct EventContextMenu: View {
    let event: CalendarEvent
    
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        Group {
            Button(action: {
                editEvent()
            }) {
                Label("Edit Event", systemImage: "pencil")
            }
            
            Button(action: {
                duplicateEvent()
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(action: {
                rescheduleEvent()
            }) {
                Label("Reschedule", systemImage: "calendar.badge.clock")
            }
            
            if event.source == .user {
                Button(action: {
                    toggleLock()
                }) {
                    Label(event.isLocked ? "Unlock" : "Lock", 
                          systemImage: event.isLocked ? "lock.open" : "lock")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                deleteEvent()
            }) {
                Label("Delete Event", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func editEvent() {
        print("Edit event: \(event.title)")
    }
    
    private func duplicateEvent() {
        print("Duplicate event: \(event.title)")
    }
    
    private func rescheduleEvent() {
        print("Reschedule event: \(event.title)")
    }
    
    private func toggleLock() {
        print("Toggle lock for event: \(event.title)")
    }
    
    private func deleteEvent() {
        print("Delete event: \(event.title)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CalendarEventView(event: CalendarEvent.sampleWorkEvent)
            .environmentObject(CalendarViewModel())
        
        CalendarEventView(event: CalendarEvent.samplePersonalEvent)
            .environmentObject(CalendarViewModel())
        
        CalendarEventView(event: CalendarEvent.sampleTogglEvent)
            .environmentObject(CalendarViewModel())
    }
    .padding()
    .frame(width: 300)
}

// MARK: - Sample Data Extension

extension CalendarEvent {
    static let sampleWorkEvent = CalendarEvent(
        id: UUID(),
        title: "Team Meeting",
        description: "Weekly standup with the development team",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600), // 1 hour later
        workPersonal: .work,
        isLocked: false,
        color: .blue,
        source: .user,
        duration: 3600 // 1 hour
    )
    
    static let samplePersonalEvent = CalendarEvent(
        id: UUID(),
        title: "Gym Workout",
        description: "Leg day at the gym",
        startDate: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(9000), // 1.5 hours later
        workPersonal: .personal,
        isLocked: true,
        color: .green,
        source: .user,
        duration: 5400 // 1.5 hours
    )
    
    static let sampleTogglEvent = CalendarEvent(
        id: UUID(),
        title: "Code Review",
        description: "Reviewing pull requests",
        startDate: Date().addingTimeInterval(7200),
        endDate: Date().addingTimeInterval(9000), // 30 minutes later
        workPersonal: .work,
        isLocked: false,
        color: .orange,
        source: .toggl,
        duration: 1800 // 30 minutes
    )
} 