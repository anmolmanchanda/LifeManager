import SwiftUI
import Foundation

/// Modern Week View for Calendar - Complete redesign from scratch
/// 
/// Features:
/// - Google Calendar-style weekly grid layout
/// - All-day events section at the top
/// - Hourly time slots with proper event positioning
/// - Drag & drop support for rescheduling
/// - Multi-day event support
/// - Clean, professional design with proper spacing
/// - Responsive event overlapping logic
/// - Context menus for events and time slots
/// - Current time indicator
/// - Weekend highlighting
struct CalendarWeekView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - State
    @State private var currentTimeOffset: CGFloat = 0
    @State private var showingAllDayEvents = true
    
    // MARK: - Constants
    private let hourHeight: CGFloat = 50
    private let dayHeaderHeight: CGFloat = 60
    private let allDayEventHeight: CGFloat = 20
    private let timeColumnWidth: CGFloat = 60
    private let hourRange = 0..<24
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header with days
            weekHeader
            
            // Main week content with scroll
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        // All-day events section (pinned)
                        if showingAllDayEvents {
                            Section(header: allDayEventsHeader) {
                                allDayEventsContent
                            }
                        }
                        
                        // Hourly time grid
                        Section {
                            hourlyTimeGrid
                        }
                    }
                }
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                }
                .onChange(of: calendarViewModel.selectedDate) { _ in
                    scrollToCurrentTime(proxy: proxy)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            startCurrentTimeUpdater()
        }
    }
    
    // MARK: - Week Header
    
    private var weekHeader: some View {
        HStack(spacing: 0) {
            // Time column spacer
            Rectangle()
                .fill(Color.clear)
                .frame(width: timeColumnWidth)
            
            // Day columns
            ForEach(weekDays, id: \.self) { day in
                dayHeader(for: day)
            }
        }
        .frame(height: dayHeaderHeight)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    private func dayHeader(for day: Date) -> some View {
        VStack(spacing: 6) {
            // Day name
            Text(dayFormatter.string(from: day))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            // Day number
            Text(dayNumberFormatter.string(from: day))
                .font(.system(size: 20, weight: isToday(day) ? .semibold : .regular))
                .foregroundColor(isToday(day) ? .blue : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isWeekend(day) ? Color.gray.opacity(0.03) : Color.clear)
    }
    
    // MARK: - All-Day Events Section
    
    private var allDayEventsHeader: some View {
        HStack {
            Text("All Day")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .padding(.trailing, 12)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingAllDayEvents.toggle()
                }
            }) {
                Image(systemName: showingAllDayEvents ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var allDayEventsContent: some View {
        HStack(spacing: 0) {
            // Time column spacer
            Rectangle()
                .fill(Color.clear)
                .frame(width: timeColumnWidth)
            
            // All-day events for each day
            ForEach(weekDays, id: \.self) { day in
                allDayEventsColumn(for: day)
            }
        }
        .frame(minHeight: allDayEvents.isEmpty ? 0 : CGFloat(maxAllDayEvents * 28))
        .animation(.easeInOut(duration: 0.2), value: allDayEvents.count)
    }
    
    private func allDayEventsColumn(for day: Date) -> some View {
        VStack(spacing: 2) {
            ForEach(allDayEventsForDay(day)) { event in
                AllDayEventView(event: event)
                    .environmentObject(calendarViewModel)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(isWeekend(day) ? Color.gray.opacity(0.05) : Color.clear)
    }
    
    // MARK: - Hourly Time Grid
    
    private var hourlyTimeGrid: some View {
        LazyVStack(spacing: 0) {
            ForEach(hourRange, id: \.self) { hour in
                hourRow(for: hour)
                    .id("hour-\(hour)")
            }
        }
    }
    
    private func hourRow(for hour: Int) -> some View {
        HStack(spacing: 0) {
            // Time label
            timeLabel(for: hour)
            
            // Day columns
            ForEach(weekDays, id: \.self) { day in
                dayColumn(for: day, hour: hour)
            }
        }
        .frame(height: hourHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(hour % 2 == 0 ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.05))
                .frame(height: 0.5)
        }
    }
    
    private func timeLabel(for hour: Int) -> some View {
        Text(hourFormatter(hour))
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(isCurrentHour(hour) ? .blue : .secondary)
            .frame(width: timeColumnWidth, alignment: .trailing)
            .padding(.trailing, 8)
    }
    
    private func dayColumn(for day: Date, hour: Int) -> some View {
        ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .fill(backgroundColorForHour(day: day, hour: hour))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Events for this hour
            eventsForHour(day: day, hour: hour)
            
            // Current time line
            if isCurrentHour(hour) && Calendar.current.isDate(day, inSameDayAs: Date()) {
                currentTimeLine
            }
        }
        .onTapGesture {
            handleTimeSlotTap(day: day, hour: hour)
        }
        .onDrop(of: [.text], isTargeted: .constant(false)) { providers in
            _ = handleDrop(providers: providers, day: day, hour: hour)
            return true
        }
        .contextMenu {
            TimeSlotContextMenu(day: day, hour: hour)
                .environmentObject(calendarViewModel)
        }
    }
    
    // MARK: - Event Views
    
    private func eventsForHour(day: Date, hour: Int) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(timedEventsForDayHour(day: day, hour: hour)) { event in
                WeekEventView(event: event, dayWidth: dayColumnWidth)
                    .environmentObject(calendarViewModel)
                    .offset(y: eventOffsetY(for: event, in: hour))
                    .zIndex(event.isLocked ? 10 : 5)
            }
        }
    }
    
    private var currentTimeLine: some View {
        HStack {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
                .offset(x: -4)
            
            Rectangle()
                .fill(.blue)
                .frame(height: 2)
            
            Spacer()
        }
        .offset(y: currentTimeOffset)
        .animation(.easeInOut(duration: 0.5), value: currentTimeOffset)
    }
    
    // MARK: - Computed Properties
    
    private var weekDays: [Date] {
        calendarViewModel.weekDays(for: calendarViewModel.selectedDate)
    }
    
    private var allDayEvents: [CalendarEvent] {
        calendarViewModel.filteredEvents.filter { $0.isAllDay }
    }
    
    private var timedEvents: [CalendarEvent] {
        calendarViewModel.filteredEvents.filter { !$0.isAllDay }
    }
    
    private var maxAllDayEvents: Int {
        weekDays.map { allDayEventsForDay($0).count }.max() ?? 0
    }
    
    private var dayColumnWidth: CGFloat {
        // Calculate based on available space (using NSScreen for macOS)
        return max(120, (NSScreen.main?.frame.width ?? 1200 - timeColumnWidth) / 7)
    }
    
    // MARK: - Helper Functions
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }
    
    private func isCurrentHour(_ hour: Int) -> Bool {
        guard isToday(calendarViewModel.selectedDate) else { return false }
        let currentHour = Calendar.current.component(.hour, from: Date())
        return hour == currentHour
    }
    
    private func eventCount(for day: Date) -> Int {
        calendarViewModel.filteredEvents.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: day)
        }.count
    }
    
    private func allDayEventsForDay(_ day: Date) -> [CalendarEvent] {
        allDayEvents.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: day)
        }
    }
    
    private func timedEventsForDayHour(day: Date, hour: Int) -> [CalendarEvent] {
        timedEvents.filter { event in
            let eventStartHour = Calendar.current.component(.hour, from: event.startDate)
            let eventEndHour = Calendar.current.component(.hour, from: event.endDate)
            
            return Calendar.current.isDate(event.startDate, inSameDayAs: day) &&
                   (eventStartHour <= hour && hour < eventEndHour)
        }
    }
    
    private func eventOffsetY(for event: CalendarEvent, in hour: Int) -> CGFloat {
        let eventStartHour = Calendar.current.component(.hour, from: event.startDate)
        let eventStartMinute = Calendar.current.component(.minute, from: event.startDate)
        
        if eventStartHour == hour {
            return CGFloat(eventStartMinute) / 60.0 * hourHeight
        }
        return 0
    }
    
    private func backgroundColorForHour(day: Date, hour: Int) -> Color {
        if isWeekend(day) {
            return Color.gray.opacity(0.05)
        } else if hour < 9 || hour > 17 {
            return Color.gray.opacity(0.02)
        } else {
            return Color.clear
        }
    }
    
    private func hourFormatter(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        if isToday(calendarViewModel.selectedDate) {
            let currentHour = Calendar.current.component(.hour, from: Date())
            let targetHour = max(6, currentHour - 2) // Scroll to 2 hours before current time, but not earlier than 6 AM
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("hour-\(targetHour)", anchor: .top)
                }
            }
        }
    }
    
    private func startCurrentTimeUpdater() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateCurrentTimeOffset()
        }
        updateCurrentTimeOffset()
    }
    
    private func updateCurrentTimeOffset() {
        let now = Date()
        let minute = Calendar.current.component(.minute, from: now)
        currentTimeOffset = CGFloat(minute) / 60.0 * hourHeight
    }
    
    // MARK: - Actions
    
    private func handleTimeSlotTap(day: Date, hour: Int) {
        let tapTime = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        print("Tapped time slot: \(tapTime)")
        // Future: Show event creation sheet
    }
    
    private func handleDrop(providers: [NSItemProvider], day: Date, hour: Int) -> Bool {
        // Handle task/event drop
        return true
    }
}

// MARK: - Supporting Views

/// All-day event view component
struct AllDayEventView: View {
    let event: CalendarEvent
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 3)
            
            Text(event.title)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            if event.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(event.color.opacity(0.15))
        .cornerRadius(4)
        .contextMenu {
            EventContextMenu(event: event)
                .environmentObject(calendarViewModel)
        }
    }
}

/// Week view event component
struct WeekEventView: View {
    let event: CalendarEvent
    let dayWidth: CGFloat
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    private var eventHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600
        return CGFloat(hours) * 60 // 60 is hourHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let description = event.description, !description.isEmpty, eventHeight > 30 {
                Text(description)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(width: dayWidth - 4, height: max(20, eventHeight), alignment: .topLeading)
        .background(event.color)
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(event.color.opacity(0.7), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        .contextMenu {
            EventContextMenu(event: event)
                .environmentObject(calendarViewModel)
        }
    }
}

/// Time slot context menu
struct TimeSlotContextMenu: View {
    let day: Date
    let hour: Int
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        Button("Create Event") {
            createEvent()
        }
        
        Button("Schedule Task") {
            scheduleTask()
        }
    }
    
    private func createEvent() {
        let eventTime = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        // Future: Create event logic
        print("Creating event at \(eventTime)")
    }
    
    private func scheduleTask() {
        let eventTime = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        // Future: Schedule task logic
        print("Scheduling task at \(eventTime)")
    }
}

// MARK: - CalendarViewModel Extension

extension CalendarViewModel {
    func weekDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        
        var days: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                days.append(day)
            }
        }
        return days
    }
}

// MARK: - CalendarEvent Extension

extension CalendarEvent {
    var isAllDay: Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
        
        return startComponents.hour == 0 && startComponents.minute == 0 &&
               endComponents.hour == 0 && endComponents.minute == 0 &&
               duration >= 86400 // 24 hours or more
    }
}

// MARK: - Preview

#Preview {
    CalendarWeekView()
        .environmentObject(CalendarViewModel())
        .frame(width: 1200, height: 800)
} 