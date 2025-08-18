//
// CalendarHeaderView.swift - CLEAR ALL RESOURCES FIX
// This version implements honest "Clear All Data" functionality
//

import SwiftUI

// MARK: - Clear All Data Implementation
extension CalendarHeaderView {
    
    /// FIXED: Clear All Data Button - now honest about what it clears
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
    
    /// FIXED: Confirmation Dialog - now accurate about what gets deleted
    private var clearAllConfirmationAlert: some View {
        EmptyView()
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
    }
    
    /// FIXED: Comprehensive Clear All Data Implementation
    /// Now actually deletes all PARA content types as promised
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
            
            Logger.shared.info("CLEAR ALL: Starting deletion - Tasks: \\(allTasks.count), Resources: \\(allResources.count), Projects: \\(allProjects.count), Areas: \\(allAreas.count), Archives: \\(allArchives.count)")
            
            // Delete all tasks
            for task in allTasks {
                try await taskRepository.deleteTask(id: task.id)
            }
            Logger.shared.debug("CLEAR ALL: Deleted \\(allTasks.count) tasks")
            
            // Delete all resources  
            for resource in allResources {
                try await resourceRepository.deleteResource(id: resource.id)
            }
            Logger.shared.debug("CLEAR ALL: Deleted \\(allResources.count) resources")
            
            // Delete all projects
            for project in allProjects {
                try await projectRepository.deleteProject(id: project.id)
            }
            Logger.shared.debug("CLEAR ALL: Deleted \\(allProjects.count) projects")
            
            // Delete all areas
            for area in allAreas {
                try await areaRepository.deleteArea(id: area.id)
            }
            Logger.shared.debug("CLEAR ALL: Deleted \\(allAreas.count) areas")
            
            // Delete all archives
            for archive in allArchives {
                try await archiveRepository.deleteArchive(id: archive.id)
            }
            Logger.shared.debug("CLEAR ALL: Deleted \\(allArchives.count) archives")
            
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
            Logger.shared.success("CLEAR ALL: Successfully deleted all \\(totalDeleted) items")
            
        } catch {
            Logger.shared.error("CLEAR ALL: Error - \\(error)")
            await MainActor.run {
                calendarViewModel.errorMessage = "Failed to delete all data: \\(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Integration Instructions
/*
To apply this fix to the existing CalendarHeaderView.swift:

1. Replace the clearAllTasksButton computed property with clearAllDataButton
2. Update the alert configuration with clearAllConfirmationAlert
3. Replace the clearAllTasks() method with clearAllData()
4. Update button references in the main view hierarchy

Key Changes:
- Button text: "Clear All" → "Clear All Data"
- Help text: Now mentions all data types accurately
- Dialog: Updated title and message for clarity
- Implementation: Actually deletes all PARA content types
- UI State: Clears all MainViewModel PARA arrays
- Logging: Comprehensive reporting of deletion progress

This fix ensures the UI button does exactly what it promises to do.
*/