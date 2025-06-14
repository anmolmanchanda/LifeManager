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
        ZStack {
            // Main content layer
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
            
            // Drag overlay layer - appears above everything when dragging
            if calendarViewModel.isDragging, let draggedTask = calendarViewModel.draggedTask {
                DragOverlay(task: draggedTask, dragPosition: calendarViewModel.dragPosition)
                    .allowsHitTesting(false) // Don't interfere with drop zones
                    .zIndex(999999) // Highest z-index for dragged items
            }
        }
        .onAppear {
            setupCalendar()
            // Refresh parking lot with latest PARA tasks
            refreshParkingLotTasks()
        }
        .onChange(of: viewModel.selectedView) { _ in
            if viewModel.selectedView == .calendar {
                refreshParkingLotTasks()
            }
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
    
    /// Refreshes parking lot tasks from all PARA categories
    private func refreshParkingLotTasks() {
        Task {
            do {
                // Fetch all tasks from the database
                let taskRepository = TaskRepository()
                let allDatabaseTasks = try await taskRepository.fetchAllTasks()
                
                await MainActor.run {
                    // Combine focus tasks and all database tasks
                    var allTasks: [LifeTask] = []
                    
                    // Add focus tasks
                    allTasks.append(contentsOf: viewModel.focusTasks)
                    
                    // Add all tasks from database
                    allTasks.append(contentsOf: allDatabaseTasks)
                    
                    // Remove duplicates and filter out archived/deleted tasks
                    let uniqueTasks = Array(Set(allTasks))
                    let activeTasks = uniqueTasks.filter { !$0.isArchived && !$0.isDeleted }
                    
                    // Update calendar view model with tasks
                    calendarViewModel.allTasks = activeTasks
                    
                    print("🔄 Refreshed parking lot with \(activeTasks.count) tasks from PARA")
                }
            } catch {
                print("🔄 Failed to refresh parking lot tasks: \(error)")
            }
        }
    }
}

// MARK: - Drag Overlay Component

/// Overlay component that shows the dragged task above everything else
struct DragOverlay: View {
    let task: LifeTask
    let dragPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(priorityColor(task.priority))
                    .frame(width: 8, height: 8)
                
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlAccentColor).opacity(0.9))
        .foregroundColor(.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .frame(width: 200)
        .offset(x: dragPosition.x, y: dragPosition.y)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: dragPosition)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .environmentObject(MainViewModel())
} 