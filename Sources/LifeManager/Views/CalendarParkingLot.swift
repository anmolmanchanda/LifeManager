import SwiftUI

/// PARA Tasks Parking Lot - Enhanced sidebar showing all tasks from PARA categories
struct PARATasksParkingLot: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    enum TaskFilter: CaseIterable {
        case all, scheduled, unscheduled, focus, work, personal
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .scheduled: return "Scheduled" 
            case .unscheduled: return "Unscheduled"
            case .focus: return "Focus"
            case .work: return "Work"
            case .personal: return "Personal"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .scheduled: return "calendar"
            case .unscheduled: return "clock.badge.questionmark"
            case .focus: return "target"
            case .work: return "briefcase"
            case .personal: return "house"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with filters - made more compact
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tasks Parking Lot")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text("All tasks from PARA")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredTasks.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Search bar - more compact
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(5)
                
                // Filter picker - more compact with scrollable segments
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: filter.icon)
                                        .font(.system(size: 9))
                                    Text(filter.displayName)
                                        .font(.system(size: 9))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedFilter == filter ? Color.blue : Color.clear)
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: 24)
                
                // Auto-schedule section for unscheduled tasks
                if selectedFilter == .unscheduled && !unscheduledTasks.isEmpty {
                    Button(action: {
                        Task {
                            await calendarViewModel.autoScheduleUnscheduledTasks()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.white)
                                .font(.system(size: 11))
                            Text("Auto-Schedule \(unscheduledTasks.count)")
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(calendarViewModel.isLoading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Divider
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.1), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
            
            // Tasks list
            if filteredTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredTasks) { task in
                            ParkingLotTaskRow(task: task)
                                .environmentObject(calendarViewModel)
                                .environmentObject(viewModel)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .padding(.top, 4)
                }
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .clipped() // Prevent overflow outside bounds
        .zIndex(100) // Ensure parking lot appears above calendar views
    }
    
    private var filteredTasks: [LifeTask] {
        var tasks = allTasksFromPARA
        
        // Apply search filter
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .scheduled:
            tasks = tasks.filter { $0.isScheduled }
        case .unscheduled:
            tasks = tasks.filter { !$0.isScheduled }
        case .focus:
            tasks = tasks.filter { $0.isFocus }
        case .work:
            tasks = tasks.filter { $0.workPersonal == .work || $0.workPersonal == .both }
        case .personal:
            tasks = tasks.filter { $0.workPersonal == .personal || $0.workPersonal == .both }
        }
        
        // Sort by priority and due date
        return tasks.sorted { task1, task2 in
            if task1.priority.priorityScore != task2.priority.priorityScore {
                return task1.priority.priorityScore > task2.priority.priorityScore
            }
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            if task1.dueDate != nil && task2.dueDate == nil {
                return true
            }
            if task1.dueDate == nil && task2.dueDate != nil {
                return false
            }
            return task1.createdAt > task2.createdAt
        }
    }
    
    private var allTasksFromPARA: [LifeTask] {
        // Combine all tasks from different sources
        var allTasks: [LifeTask] = []
        
        // Add focus tasks
        allTasks.append(contentsOf: viewModel.focusTasks)
        
        // Add tasks from calendar view model (which loads from database)
        allTasks.append(contentsOf: calendarViewModel.allTasks)
        
        // Remove duplicates, archived tasks, and deleted tasks
        let uniqueTasks = Array(Set(allTasks))
        return uniqueTasks.filter { !$0.isArchived && !$0.isDeleted }
    }
    
    private var unscheduledTasks: [LifeTask] {
        return filteredTasks.filter { !$0.isScheduled }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: selectedFilter == .all ? "checkmark.circle.fill" : selectedFilter.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No tasks found"
        case .scheduled: return "No scheduled tasks"
        case .unscheduled: return "All tasks scheduled!"
        case .focus: return "No focus tasks"
        case .work: return "No work tasks"
        case .personal: return "No personal tasks"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Create some tasks or check your PARA organization."
        case .scheduled: return "Tasks with due dates will appear here."
        case .unscheduled: return "Great job! All your tasks have time slots."
        case .focus: return "Mark important tasks as focus to see them here."  
        case .work: return "Work-related tasks will appear here."
        case .personal: return "Personal tasks will appear here."
        }
    }
}

/// Individual task row in the parking lot
struct ParkingLotTaskRow: View {
    let task: LifeTask
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isDragging = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Priority and status indicator
                VStack(spacing: 4) {
                    Circle()
                        .fill(priorityColor(task.priority))
                        .frame(width: 12, height: 12)
                    
                    Rectangle()
                        .fill(statusColor(task.status))
                        .frame(width: 12, height: 3)
                        .cornerRadius(2)
                }
                
                // Task content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Metadata row
                    HStack(spacing: 8) {
                        // PARA assignment
                        if let projectId = task.projectId,
                           let project = viewModel.projects.first(where: { $0.id == projectId }) {
                            Label(project.name, systemImage: "target")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        } else if let areaId = task.areaId,
                                  let area = viewModel.areas.first(where: { $0.id == areaId }) {
                            Label(area.name, systemImage: "square.stack.3d.up")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        // Duration
                        if let duration = task.estimatedDuration {
                            Text("\(duration)m")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        // Work/Personal indicator
                        Image(systemName: task.workPersonal == .work ? "briefcase.fill" : "house.fill")
                            .font(.caption2)
                            .foregroundColor(task.workPersonal == .work ? .blue : .purple)
                    }
                }
                
                // Schedule status
                VStack(spacing: 4) {
                    if task.isScheduled {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if task.isFocus {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Quick actions for unscheduled tasks
            if !task.isScheduled && !calendarViewModel.suggestedSlots(for: task).isEmpty {
                HStack(spacing: 6) {
                    Text("Quick schedule:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(calendarViewModel.suggestedSlots(for: task).prefix(2), id: \.self) { time in
                        Button(time.calendarSuggestionFormat()) {
                            Task {
                                await calendarViewModel.scheduleTask(task, at: time)
                            }
                        }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding(10)
        .background(taskBackgroundColor)
        .cornerRadius(8)
        .shadow(color: .black.opacity(isDragging ? 0.15 : 0.05), radius: isDragging ? 4 : 2, x: 0, y: 1)
        .scaleEffect(isDragging ? 0.98 : (isHovered ? 1.02 : 1.0))
        .offset(isDragging ? .zero : .zero) // Don't offset the original task when dragging
        .opacity(isDragging ? 0.3 : 1.0) // Make original task semi-transparent when dragging
        .zIndex(1) // Keep consistent z-index
        .allowsHitTesting(true) // Always allow hit testing
        .background(isDragging ? Color.clear : Color.clear) // Ensure transparent background
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .draggable(task.id.uuidString) {
            // Custom drag preview
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlAccentColor).opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .contextMenu {
            TaskContextMenu(task: task)
                .environmentObject(calendarViewModel)
                .environmentObject(viewModel)
        }
        .gesture(
            // Use high priority drag gesture that doesn't interfere with context menu
            DragGesture(minimumDistance: 15) // Increased minimum distance
                .onChanged { value in
                    if !isDragging {
                        LifeLogger.dragDrop(.info, "🎯 Started dragging task: '\(task.title)' (ID: \(task.id.uuidString.prefix(8)))")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isDragging = true
                        }
                        calendarViewModel.startDragging(task)
                    }
                    calendarViewModel.updateDragPosition(value.translation)
                }
                .onEnded { value in
                    LifeLogger.dragDrop(.info, "🎯 Ended dragging task: '\(task.title)' at translation: \(value.translation)")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isDragging = false
                    }
                    
                    // Check if drag was successful (moved significant distance)
                    let dragDistance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                    if dragDistance > 75 { // Increased threshold
                        calendarViewModel.completeDrag()
                    } else {
                        calendarViewModel.cancelDrag()
                    }
                }
        )
    }
    
    private var taskBackgroundColor: Color {
        if isDragging {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor).opacity(0.9)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.7)
        }
    }
    

    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
    
    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .inbox: return .gray
        case .todo: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

/// Context menu for tasks in parking lot
struct TaskContextMenu: View {
    let task: LifeTask
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        Group {
            if task.status != .completed {
                Button(action: {
                    Task {
                        await markTaskComplete()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Complete")
                    }
                }
            }
            
            if !task.isScheduled {
                Button(action: {
                    Task {
                        await scheduleTaskQuickly()
                    }
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Quick Schedule")
                    }
                }
            }
            
            Button(action: {
                Task {
                    await moveTaskToArchive()
                }
            }) {
                HStack {
                    Image(systemName: "archivebox")
                    Text("Archive Task")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                Task {
                    await deleteTask()
                }
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Task")
                }
            }
        }
    }
    
    private func markTaskComplete() async {
        do {
            let taskRepository = TaskRepository()
            _ = try await taskRepository.updateTaskStatus(id: task.id, status: .completed)
            
            // Move completed task to archive automatically
            await moveCompletedTaskToArchive()
            
            // Refresh data
            await calendarViewModel.loadCalendarData()
            
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Failed to complete task: \(error.localizedDescription)"
            }
        }
    }
    
    private func moveCompletedTaskToArchive() async {
        do {
            let blobRepository = BlobRepository()
            if let blobId = task.blobId {
                // Fetch the current blob and update it with isArchived = true
                if var blob = try await blobRepository.fetchBlob(id: blobId) {
                    let archivedBlob = Blob(
                        id: blob.id,
                        content: blob.content,
                        sourceType: blob.sourceType,
                        workPersonal: blob.workPersonal,
                        processed: blob.processed,
                        projectId: blob.projectId,
                        areaId: blob.areaId,
                        isArchived: true
                    )
                    _ = try await blobRepository.updateBlob(archivedBlob)
                }
            }
        } catch {
            print("Failed to move completed task to archive: \(error.localizedDescription)")
        }
    }
    
    private func scheduleTaskQuickly() async {
        LifeLogger.contextMenu(.info, "⚡ Quick scheduling task: '\(task.title)'")
        let suggestedSlots = calendarViewModel.suggestedSlots(for: task)
        if let firstSlot = suggestedSlots.first {
            LifeLogger.contextMenu(.info, "⚡ Found suggested slot: \(firstSlot)")
            await calendarViewModel.scheduleTask(task, at: firstSlot)
        } else {
            LifeLogger.contextMenu(.warning, "⚡ No suggested slots found for task: '\(task.title)'")
        }
    }
    
    private func moveTaskToArchive() async {
        do {
            let blobRepository = BlobRepository()
            if let blobId = task.blobId {
                // Fetch the current blob and update it with isArchived = true
                if var blob = try await blobRepository.fetchBlob(id: blobId) {
                    let archivedBlob = Blob(
                        id: blob.id,
                        content: blob.content,
                        sourceType: blob.sourceType,
                        workPersonal: blob.workPersonal,
                        processed: blob.processed,
                        projectId: blob.projectId,
                        areaId: blob.areaId,
                        isArchived: true
                    )
                    _ = try await blobRepository.updateBlob(archivedBlob)
                
                    // Refresh data
                    await calendarViewModel.loadCalendarData()
                    
                    await MainActor.run {
                        viewModel.successMessage = "Task moved to archive"
                    }
                }
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Failed to archive task: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteTask() async {
        do {
            let taskRepository = TaskRepository()
            try await taskRepository.deleteTask(id: task.id)
            
            // Also delete associated blob if exists
            if let blobId = task.blobId {
                let blobRepository = BlobRepository()
                try await blobRepository.deleteBlob(id: blobId)
            }
            
            // Refresh data
            await calendarViewModel.loadCalendarData()
            
            await MainActor.run {
                viewModel.successMessage = "Task deleted successfully"
            }
            
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Failed to delete task: \(error.localizedDescription)"
            }
        }
    }
} 