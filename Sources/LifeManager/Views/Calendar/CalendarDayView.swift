import SwiftUI
import Foundation

/// Daily calendar view with detailed hourly timeline
/// 
/// Provides:
/// - Hourly time slots from 6 AM to 11 PM
/// - Event positioning within time slots
/// - Current time indicator
/// - Drag and drop support for scheduling
/// - Smooth scrolling to current time
struct CalendarDayView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - Constants
    private let hours = Array(6...23) // 6 AM to 11 PM
    private let hourHeight: CGFloat = 80
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
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
            // Scroll to current hour, but ensure it's within our range
            targetHour = max(6, min(23, currentHour))
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
    private let hourHeight: CGFloat = 80
    
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
            handleDrop()
            return true
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
        .onTapGesture {
            handleTap()
        }
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
        LazyVStack(spacing: 4) {
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
        } else if isHovered {
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
    
    private func handleDrop() {
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        
        // Handle drop scheduling - placeholder for now
        print("Dropped on hour \(hour)")
    }
}

// MARK: - Preview

#Preview {
    CalendarDayView()
        .environmentObject(CalendarViewModel())
        .frame(width: 600, height: 800)
} 