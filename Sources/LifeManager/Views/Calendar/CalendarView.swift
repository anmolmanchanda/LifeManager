import SwiftUI
import Foundation

/// Main calendar view for time-based content organization and scheduling
/// 
/// This view provides a comprehensive calendar interface with:
/// - Multiple view modes (Day, Week, Month)
/// - Toggl integration for time tracking
/// - Task parking lot sidebar
/// - Smart scheduling capabilities
/// - Event management and filtering
struct CalendarView: View {
    // MARK: - Dependencies
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    // MARK: - State
    @State private var showingCreateEvent = false
    @State private var showingTaskDetails: LifeTask?
    
    // MARK: - Body
    var body: some View {
        HSplitView {
            // PARA Tasks Parking Lot Sidebar
            PARATasksParkingLot()
                .environmentObject(viewModel)
                .environmentObject(calendarViewModel)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
                .clipped()
            
            // Main Calendar Content
            VStack(spacing: 0) {
                CalendarHeaderView()
                    .environmentObject(calendarViewModel)
                
                CalendarMainView()
                    .environmentObject(calendarViewModel)
            }
            .frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            setupCalendar()
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView(calendarViewModel: calendarViewModel)
        }
        .sheet(item: $showingTaskDetails) { task in
            TaskDetailsView(task: task)
                .environmentObject(viewModel)
        }
        .alert("Calendar Error", isPresented: .constant(calendarViewModel.errorMessage != nil)) {
            Button("OK") {
                calendarViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = calendarViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up the calendar view with necessary dependencies and data loading
    private func setupCalendar() {
        // Calendar setup is handled by the ViewModel's initialization
        // No additional setup needed here
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .environmentObject(MainViewModel())
} 