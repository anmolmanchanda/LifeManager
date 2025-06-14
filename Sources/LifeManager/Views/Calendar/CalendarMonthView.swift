import SwiftUI
import Foundation

/// Monthly calendar view with traditional grid layout
/// 
/// Provides:
/// - Traditional month grid with day cells
/// - Event indicators on each day
/// - Navigation between months
/// - Today highlighting
/// - Event count badges
struct CalendarMonthView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Month grid
            CalendarMonthGrid()
                .environmentObject(calendarViewModel)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Sync all visible month dates with Toggl when month view appears
            Task {
                let calendar = Calendar.current
                let startOfMonth = calendar.dateInterval(of: .month, for: calendarViewModel.selectedDate)?.start ?? calendarViewModel.selectedDate
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
                
                var visibleDates: [Date] = []
                var currentDate = startOfWeek
                
                // Generate 6 weeks worth of dates (42 days) - same as monthDays
                for _ in 0..<42 {
                    visibleDates.append(currentDate)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
                
                await calendarViewModel.syncMonthViewWithToggl(visibleDates)
            }
        }
    }
}

// MARK: - Calendar Month Grid Component

/// Grid component for the monthly calendar layout
struct CalendarMonthGrid: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack {
                ForEach(dayNames, id: \.self) { dayName in
                    Text(dayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(monthDays, id: \.self) { date in
                    CalendarMonthDayCell(date: date)
                        .environmentObject(calendarViewModel)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var monthDays: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: calendarViewModel.selectedDate)?.start ?? calendarViewModel.selectedDate
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        var currentDate = startOfWeek
        
        // Generate 6 weeks worth of days (42 days)
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
}

// MARK: - Calendar Month Day Cell Component

/// Individual day cell in the month view
struct CalendarMonthDayCell: View {
    let date: Date
    
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundColor(dayTextColor)
            
            Spacer()
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(cellBackgroundColor)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(cellBorderColor, lineWidth: isToday ? 2 : 0.5)
        }
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            handleTap()
        }
        .task {
            // Load events for this date if not already loaded
            if dayEvents.isEmpty {
                await calendarViewModel.loadEventsForDate(date)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: calendarViewModel.selectedDate, toGranularity: .month)
    }
    
    private var dayEvents: [CalendarEvent] {
        calendarViewModel.events(for: date)
    }
    
    private var dayTextColor: Color {
        if isToday {
            return .blue
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var cellBackgroundColor: Color {
        if !dayEvents.isEmpty {
            // Fill entire cell with dominant project color
            let totalDayTime = dayEvents.reduce(0) { total, event in
                total + event.duration
            }
            
            if totalDayTime > 0 {
                // Find the event with the longest duration (dominant color)
                let dominantEvent = dayEvents.max { event1, event2 in
                    event1.duration < event2.duration
                }
                
                if let dominant = dominantEvent {
                    return dominant.color.opacity(0.3) // Semi-transparent fill
                }
            }
        }
        
        if isToday {
            return Color.blue.opacity(0.1)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.05)
        } else if isCurrentMonth {
            return Color(NSColor.controlBackgroundColor)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.5)
        }
    }
    
    private var cellBorderColor: Color {
        if isToday {
            return .blue
        } else if isHovered {
            return Color.secondary.opacity(0.5)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        
        // Navigate to the selected date
        calendarViewModel.selectedDate = date
        
        // Switch to day view for detailed view
        calendarViewModel.viewMode = .day
    }
}

// MARK: - Preview

#Preview {
    CalendarMonthView()
        .environmentObject(CalendarViewModel())
        .frame(width: 800, height: 600)
} 