//
// CalendarHeaderView.swift - PRIORITY 2: CLEAR ALL RESOURCES FIX
// This patch fixes the Clear All button to actually clear all PARA content as promised
//

// MARK: - Clear All Data Button Fix (Lines 207-228)
// Replace clearAllTasksButton with clearAllDataButton

private var clearAllDataButton: some View {
    Button(action: {
        showingClearAllConfirmation = true
    }) {
        HStack(spacing: 4) {
            Image(systemName: "trash.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text("Clear All Data")  // CHANGED: Was "Clear All"
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.red)
        .cornerRadius(8)
        .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    .buttonStyle(.plain)
    .help("Delete all data including tasks, resources, projects, areas, and archives")  // CHANGED: More accurate
}

// MARK: - Confirmation Dialog Fix (Lines 54-63)
// Update the alert to be accurate about what gets deleted

.alert("Clear All Data", isPresented: $showingClearAllConfirmation) {  // CHANGED: Title
    Button("Cancel", role: .cancel) { }
    Button("Delete All", role: .destructive) {
        Task {
            await clearAllData()  // CHANGED: Method name
        }
    }
} message: {
    Text("Are you sure you want to delete ALL data including tasks, resources, projects, areas, and archives? This action cannot be undone.")  // CHANGED: Accurate description
}

// MARK: - Comprehensive Clear All Data Implementation (Lines 340-380)
// Replace clearAllTasks() with clearAllData() that actually deletes everything

private func clearAllData() async {
    do {
        // Initialize all repositories
        let taskRepository = TaskRepository()
        let resourceRepository = ResourceRepository()
        let projectRepository = ProjectRepository()
        let areaRepository = AreaRepository()
        let archiveRepository = ArchiveRepository()
        
        // Fetch all data types to get counts for logging
        let allTasks = try await taskRepository.fetchAllTasks()
        let allResources = try await resourceRepository.fetchAllResources()
        let allProjects = try await projectRepository.fetchAllProjects()
        let allAreas = try await areaRepository.fetchAllAreas()
        let allArchives = try await archiveRepository.fetchAllArchives()
        
        Logger.shared.info("CLEAR ALL: Starting deletion - Tasks: \(allTasks.count), Resources: \(allResources.count), Projects: \(allProjects.count), Areas: \(allAreas.count), Archives: \(allArchives.count)")
        
        // Delete all tasks
        for task in allTasks {
            try await taskRepository.deleteTask(id: task.id)
        }
        Logger.shared.debug("CLEAR ALL: Deleted \(allTasks.count) tasks")
        
        // Delete all resources  
        for resource in allResources {
            try await resourceRepository.deleteResource(id: resource.id)
        }
        Logger.shared.debug("CLEAR ALL: Deleted \(allResources.count) resources")
        
        // Delete all projects
        for project in allProjects {
            try await projectRepository.deleteProject(id: project.id)
        }
        Logger.shared.debug("CLEAR ALL: Deleted \(allProjects.count) projects")
        
        // Delete all areas
        for area in allAreas {
            try await areaRepository.deleteArea(id: area.id)
        }
        Logger.shared.debug("CLEAR ALL: Deleted \(allAreas.count) areas")
        
        // Delete all archives
        for archive in allArchives {
            try await archiveRepository.deleteArchive(id: archive.id)
        }
        Logger.shared.debug("CLEAR ALL: Deleted \(allArchives.count) archives")
        
        // Clear UI state comprehensively
        await MainActor.run {
            // Clear calendar view model
            calendarViewModel.allTasks = []
            calendarViewModel.events = []
            
            // Clear main view model PARA data
            mainViewModel.areaTasks = [:]
            mainViewModel.projectTasks = [:]
            mainViewModel.focusTasks = []
            mainViewModel.areas = []           // NEW: Clear areas
            mainViewModel.projects = []       // NEW: Clear projects  
            mainViewModel.resources = []      // NEW: Clear resources
            mainViewModel.archives = []       // NEW: Clear archives
        }
        
        // Refresh all data to ensure UI consistency
        await calendarViewModel.loadCalendarData()
        await mainViewModel.refreshData()
        
        let totalDeleted = allTasks.count + allResources.count + allProjects.count + allAreas.count + allArchives.count
        Logger.shared.success("CLEAR ALL: Successfully deleted all \(totalDeleted) items")
        
    } catch {
        Logger.shared.error("CLEAR ALL: Error - \(error)")
        await MainActor.run {
            calendarViewModel.errorMessage = "Failed to delete all data: \(error.localizedDescription)"
        }
    }
}

/*
INTEGRATION INSTRUCTIONS:

In CalendarHeaderView.swift, make these changes:

1. Line 124: Replace `clearAllTasksButton` with `clearAllDataButton`
2. Line 207-228: Replace the clearAllTasksButton implementation with clearAllDataButton above
3. Line 54-63: Update the alert configuration as shown above  
4. Line 340-380: Replace clearAllTasks() method with clearAllData() method above
5. Line 58: Update the button action to call clearAllData() instead of clearAllTasks()

This ensures the Clear All button actually does what its help text promises - deletes ALL PARA content types, not just tasks.
*/