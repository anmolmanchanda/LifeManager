import SwiftUI
import Foundation

/// Weekly calendar view with Google Calendar-style layout
/// 
/// Provides:
/// - 7-day week grid with hourly time slots
/// - Day headers with date information
/// - Time column with hour labels
/// - Event positioning within time slots
/// - Current time indicator
/// - Drag and drop support
struct CalendarWeekView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - Constants
    private let hours = Array(6...23) // 6 AM to 11 PM
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Week header
                    WeekHeaderView()
                        .environmentObject(calendarViewModel)
                    
                    // Week grid
                    LazyVGrid(columns: weekColumns, spacing: 1) {
                        // Time column header
                        Color.clear
                            .frame(width: 60, height: 30)
                        
                        // Day headers
                        ForEach(weekDays, id: \.self) { date in
                            VStack(spacing: 2) {
                                Text(dayOfWeekName(date))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Calendar.current.isDateInToday(date) ? .blue : .primary)
                            }
                            .frame(height: 30)
                        }
                        
                        // Hour rows
                        ForEach(hours, id: \.self) { hour in
                            // Time label
                            Text(formatHour(hour))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                                .padding(.trailing, 8)
                            
                            // Day cells for this hour
                            ForEach(weekDays, id: \.self) { date in
                                WeekHourCell(date: date, hour: hour)
                                    .environmentObject(calendarViewModel)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Scroll to current time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToCurrentHour()
            }
            // Load events for all days in the week
            Task {
                for date in weekDays {
                    await calendarViewModel.loadEventsForDate(date)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekColumns: [GridItem] {
        [GridItem(.fixed(60))] + Array(repeating: GridItem(.flexible()), count: 7)
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendarViewModel.selectedDate.startOfWeek
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    // MARK: - Helper Methods
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func dayOfWeekName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func scrollToCurrentHour() {
        // TODO: Implement scroll to current hour
        print("Scrolling to current hour")
    }
}

// MARK: - Week Header View Component

/// Header view for the weekly calendar showing navigation and current week
struct WeekHeaderView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Text("Week View")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(weekRangeText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var weekRangeText: String {
        let calendar = Calendar.current
        let startOfWeek = calendarViewModel.selectedDate.startOfWeek
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startText = formatter.string(from: startOfWeek)
        let endText = formatter.string(from: endOfWeek)
        
        return "\(startText) - \(endText)"
    }
}

// MARK: - Calendar Hour Cell Component

/// Simplified week hour cell that actually shows events
struct WeekHourCell: View {
    let date: Date
    let hour: Int
    
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var isHovered = false
    
    var body: some View {
        let hourEvents = calendarViewModel.events(for: date, hour: hour)
        let isCurrentHour = Calendar.current.isDateInToday(date) && Calendar.current.component(.hour, from: Date()) == hour
        
        VStack(spacing: 2) {
            // Events display
            if !hourEvents.isEmpty {
                ForEach(Array(hourEvents.prefix(2).enumerated()), id: \.offset) { _, event in
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(event.color)
                            .frame(width: 3, height: 16)
                        
                        Text(event.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 2)
                    .background(event.color.opacity(0.1))
                    .cornerRadius(3)
                }
                
                if hourEvents.count > 2 {
                    Text("+\(hourEvents.count - 2)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(isCurrentHour ? Color.blue.opacity(0.08) : Color.clear)
        .overlay {
            Rectangle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarWeekView()
        .environmentObject(CalendarViewModel())
        .frame(width: 800, height: 600)
} 