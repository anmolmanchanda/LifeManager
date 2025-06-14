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
                                CalendarHourCell(date: date, hour: hour)
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

/// Individual hour cell in the week view
struct CalendarHourCell: View {
    let date: Date
    let hour: Int
    
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var isHovered = false
    @State private var isDragTargeted = false
    
    var body: some View {
        let _ = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        let events = calendarViewModel.events(for: date, hour: hour)
        let isCurrentHour = Calendar.current.isDateInToday(date) && Calendar.current.component(.hour, from: Date()) == hour
        
        ZStack(alignment: .topLeading) {
            // Cell background
            RoundedRectangle(cornerRadius: isHovered ? 8 : 4)
                .fill(cellBackgroundColor)
                .frame(height: 60)
                .overlay {
                    RoundedRectangle(cornerRadius: isHovered ? 8 : 4)
                        .stroke(cellBorderColor, lineWidth: isCurrentHour ? 2 : 0.5)
                }
                .shadow(color: .black.opacity(isHovered ? 0.1 : 0), radius: isHovered ? 4 : 0, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            
            // Current time indicator
            if isCurrentHour {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue, .blue.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .offset(y: timeIndicatorOffset)
                    .animation(.easeInOut(duration: 0.3), value: timeIndicatorOffset)
            }
            
            // Events
            if !events.isEmpty {
                LazyVStack(spacing: 2) {
                    ForEach(events) { event in
                        CalendarEventView(event: event)
                            .environmentObject(calendarViewModel)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(4)
            }
            
            // Hover placeholder
            if isHovered && events.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                .opacity(0.8)
            }
            
            // Drop target indicator
            if isDragTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .scaleEffect(isDragTargeted ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isDragTargeted)
                    }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            handleTap()
        }
        .onDrop(of: [.text], isTargeted: $isDragTargeted) { providers in
            handleDrop()
            return true
        }
    }
    
    // MARK: - Computed Properties
    
    private var cellBackgroundColor: Color {
        if Calendar.current.isDateInToday(date) && Calendar.current.component(.hour, from: Date()) == hour {
            return Color.blue.opacity(0.08)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.05)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.3)
        }
    }
    
    private var cellBorderColor: Color {
        let isCurrentHour = Calendar.current.isDateInToday(date) && Calendar.current.component(.hour, from: Date()) == hour
        
        if isCurrentHour {
            return .blue
        } else if isHovered {
            return Color.secondary.opacity(0.5)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }
    
    private var timeIndicatorOffset: CGFloat {
        let now = Date()
        let currentMinute = Calendar.current.component(.minute, from: now)
        return CGFloat(currentMinute) / 60.0 * 58.0 // Proportional to cell height minus padding
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        print("Tapped on \(date) at hour \(hour)")
    }
    
    private func handleDrop() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        print("Dropped on \(date) at hour \(hour)")
    }
}

// MARK: - Preview

#Preview {
    CalendarWeekView()
        .environmentObject(CalendarViewModel())
        .frame(width: 800, height: 600)
} 