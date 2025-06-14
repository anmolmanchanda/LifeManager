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
        HStack(spacing: 8) {
            // Time display before title
            Text(startTimeText)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            // Event title and duration
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    // Duration after title
                    Text(durationText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                // Only show description if it exists and is meaningful
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            

        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
    

    
    // MARK: - Status Indicators
    
    private var statusIndicators: some View {
        VStack(spacing: 3) {
            // Only show lock indicator for locked events
            if event.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            }
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
            switch event.eventType {
            case .actualToggl:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            case .plannedFuture:
                Image(systemName: "clock.badge")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            case .userEvent:
                Image(systemName: "person.circle")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            default:
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
    }
    
    // MARK: - Computed Properties
    
    private var eventBackgroundColor: Color {
        let baseOpacity: Double = isPressed ? 0.2 : (isHovered ? 0.15 : 0.1)
        
        // Adjust color based on event type
        switch event.eventType {
        case .actualToggl:
            // Past/actual events - more solid, completed feel
            return event.color.opacity(baseOpacity + 0.05)
        case .plannedFuture:
            // Future/planned events - lighter, tentative feel
            return event.color.opacity(baseOpacity - 0.02)
        case .userEvent:
            // User events - standard appearance
            return event.color.opacity(baseOpacity)
        default:
            return event.color.opacity(baseOpacity)
        }
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
    
    private var startTimeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: event.startDate)
    }
    
    private var durationText: String {
        let minutes = Int(event.duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        } else {
            return "\(minutes)m"
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