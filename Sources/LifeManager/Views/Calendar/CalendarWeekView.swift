import SwiftUI
import Foundation

/// Weekly calendar view - completely rebuilt for reliability
struct CalendarWeekView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    private let hours = Array(0..<24)
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let selectedDate = calendarViewModel.selectedDate
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header with day names and dates
            weekHeader
            
            // Main week grid
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 1) {
                    // Time column header (empty space)
                    Color.clear.frame(height: 30)
                    
                    // Day headers
                    ForEach(weekDays, id: \.self) { date in
                        dayHeader(for: date)
                    }
                    
                    // Hour rows
                    ForEach(hours, id: \.self) { hour in
                        // Time label
                        timeLabel(for: hour)
                        
                        // Day cells for this hour
                        ForEach(weekDays, id: \.self) { date in
                            weekCell(date: date, hour: hour)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadWeekData()
        }
    }
    
    // MARK: - Components
    
    private var weekHeader: some View {
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
    
    private var gridColumns: [GridItem] {
        [GridItem(.fixed(60))] + Array(repeating: GridItem(.flexible()), count: 7)
    }
    
    private func dayHeader(for date: Date) -> some View {
        VStack(spacing: 2) {
            Text(dayName(for: date))
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
    
    private func timeLabel(for hour: Int) -> some View {
        Text(formatHour(hour))
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: 60, alignment: .trailing)
            .padding(.trailing, 8)
    }
    
    private func weekCell(date: Date, hour: Int) -> some View {
        let events = calendarViewModel.events(for: date, hour: hour)
        let isCurrentHour = Calendar.current.isDateInToday(date) && Calendar.current.component(.hour, from: Date()) == hour
        
        return VStack(spacing: 1) {
            if !events.isEmpty {
                ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, event in
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(event.color)
                            .frame(width: 3, height: 14)
                        
                        Text(event.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 1)
                    .background(event.color.opacity(0.1))
                    .cornerRadius(2)
                }
                
                if events.count > 2 {
                    Text("+\(events.count - 2)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(isCurrentHour ? Color.blue.opacity(0.08) : Color.clear)
        .overlay {
            Rectangle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        }
    }
    
    // MARK: - Helper Methods
    
    private var weekRangeText: String {
        let calendar = Calendar.current
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: weekDays.first ?? Date()) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startText = formatter.string(from: weekDays.first ?? Date())
        let endText = formatter.string(from: endOfWeek)
        
        return "\(startText) - \(endText)"
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func loadWeekData() {
        Task {
            for date in weekDays {
                await calendarViewModel.loadEventsForDate(date)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarWeekView()
        .environmentObject(CalendarViewModel())
        .frame(width: 800, height: 600)
} 