//
// CalendarParkingLot.swift - PRIORITY 4: CALENDAR ARCHIVE TAB
// Add archive tab to show recently deleted tasks in parking lot
//

// MARK: - Enhanced TaskFilter Enum (Lines 10-34)
// Add archive case to existing TaskFilter enum:

enum TaskFilter: CaseIterable {
    case all, scheduled, unscheduled, focus, work, personal, archive  // ADDED: archive
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .scheduled: return "Scheduled" 
        case .unscheduled: return "Unscheduled"
        case .focus: return "Focus"
        case .work: return "Work"
        case .personal: return "Personal"
        case .archive: return "Archive"  // ADDED
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
        case .archive: return "archivebox"  // ADDED
        }
    }
}

// MARK: - Add Recently Deleted Tasks State
// Add after line 8 (existing @State variables):

@State private var recentlyDeletedTasks: [LifeTask] = []
@State private var isLoadingArchive = false

// MARK: - Enhanced Filtered Tasks Logic  
// Update the filteredTasks computed property to handle archive filter:

private var filteredTasks: [LifeTask] {
    if selectedFilter == .archive {
        // Return recently deleted tasks for archive view
        return filterArchiveTasks()
    }
    
    // Existing logic for other filters
    let allTasks = getAllTasks()
    let activeTasksOnly = allTasks.filter { !$0.isArchived && !$0.isDeleted }
    
    let filtered = activeTasksOnly.filter { task in
        switch selectedFilter {
        case .all: return true
        case .scheduled: return task.isScheduled
        case .unscheduled: return !task.isScheduled  
        case .focus: return viewModel.focusTasks.contains { $0.id == task.id }
        case .work: return task.workPersonal == .work
        case .personal: return task.workPersonal == .personal
        case .archive: return false // Handled above
        }
    }
    
    // Apply search filter
    if searchText.isEmpty {
        return filtered
    } else {
        return filtered.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText) ||
            (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - Archive Tasks Filter Logic
// Add new method to handle archive filtering:

private func filterArchiveTasks() -> [LifeTask] {
    let filtered = recentlyDeletedTasks
    
    // Apply search filter to archived tasks
    if searchText.isEmpty {
        return filtered
    } else {
        return filtered.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText) ||
            (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - Load Recently Deleted Tasks
// Add method to load archive data:

private func loadRecentlyDeletedTasks() async {
    guard selectedFilter == .archive else { return }
    
    isLoadingArchive = true
    do {
        let taskRepository = TaskRepository()
        let deleted = try await taskRepository.fetchRecentlyDeletedTasks()
        
        await MainActor.run {
            recentlyDeletedTasks = deleted
            isLoadingArchive = false
        }
        
        Logger.shared.debug("PARKING_LOT: Loaded \(deleted.count) recently deleted tasks")
    } catch {
        Logger.shared.error("PARKING_LOT: Failed to load archive: \(error)")
        await MainActor.run {
            isLoadingArchive = false
        }
    }
}

// MARK: - Enhanced Header for Archive View
// Update header text when archive is selected (around line 42):

Text(selectedFilter == .archive ? "Recently Deleted" : "Tasks Parking Lot")
    .font(.subheadline)
    .fontWeight(.semibold)
    .lineLimit(1)

Text(selectedFilter == .archive ? "Deleted tasks (24hr retention)" : "All tasks from PARA")
    .font(.caption2)
    .foregroundColor(.secondary)
    .lineLimit(1)

// MARK: - Archive-Specific Task Row
// Add archive task row component:

struct ArchiveTaskRow: View {
    let task: LifeTask
    let onRestore: () async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    if let deletedAt = task.deletedAt {
                        Text("Deleted: \(formatDeletedDate(deletedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if task.canBePermanentlyDeleted {
                        Text("⚠️ Expires soon")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await onRestore()
                }
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.borderless)
            .help("Restore task")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
    
    private func formatDeletedDate(_ deletedAt: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: deletedAt) else {
            return deletedAt
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Enhanced Task List with Archive Support
// Update the task list section to handle archive view:

if selectedFilter == .archive {
    // Archive view with restore functionality
    if isLoadingArchive {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading archived tasks...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    } else if filteredTasks.isEmpty {
        Text("No deleted tasks")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    } else {
        ForEach(filteredTasks) { task in
            ArchiveTaskRow(task: task) {
                await restoreTask(task)
            }
        }
    }
} else {
    // Existing active tasks view (keep current implementation)
    ForEach(filteredTasks) { task in
        // Existing TaskRow implementation
    }
}

// MARK: - Restore Task Functionality
// Add restore method:

private func restoreTask(_ task: LifeTask) async {
    do {
        let taskRepository = TaskRepository()
        try await taskRepository.restoreDeletedTask(id: task.id)
        
        // Refresh archive list
        await loadRecentlyDeletedTasks()
        
        // Refresh main data to show restored task
        await viewModel.refreshData()
        
        Logger.shared.success("PARKING_LOT: Restored task: \(task.title)")
    } catch {
        Logger.shared.error("PARKING_LOT: Failed to restore task: \(error)")
    }
}

// MARK: - Filter Change Handler
// Update filter change to load archive data:

.onChange(of: selectedFilter) { _, newFilter in
    if newFilter == .archive {
        Task {
            await loadRecentlyDeletedTasks()
        }
    }
}

/*
INTEGRATION INSTRUCTIONS:
=========================

In CalendarParkingLot.swift (PARATasksParkingLot):

1. Add "archive" case to TaskFilter enum (line 11)
2. Add archive icon "archivebox" (line 32)  
3. Add recentlyDeletedTasks and isLoadingArchive state variables
4. Update filteredTasks computed property to handle archive filter
5. Add filterArchiveTasks() method
6. Add loadRecentlyDeletedTasks() method
7. Update header text for archive view
8. Add ArchiveTaskRow component 
9. Update task list section with archive view
10. Add restoreTask() method
11. Add .onChange(of: selectedFilter) handler

This provides a complete archive tab in the calendar parking lot
showing recently deleted tasks with restore functionality and
24-hour retention warning indicators.

RESULT:
=======
✅ Archive tab in parking lot filter
✅ Recently deleted tasks display
✅ Restore functionality with one click
✅ 24-hour retention warnings  
✅ Search works in archive view
✅ Proper loading states
✅ Automatic refresh after restore
*/