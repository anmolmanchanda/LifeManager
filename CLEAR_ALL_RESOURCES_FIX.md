# Clear All Resources Fix for LifeManager

## Issue: Clear All Button Promises but Doesn't Deliver

**File:** `/Users/Shared/LifeManager/Sources/LifeManager/Views/Calendar/CalendarHeaderView.swift`

### Current Problem
The Clear All button promises to delete resources but only deletes tasks:

- **Help text (line 227):** "Delete all tasks from parking lot, calendar, projects, areas, and resources"
- **Dialog message (line 62):** "delete ALL tasks from parking lot, calendar, projects, areas, and resources"
- **Actual implementation:** Only calls `taskRepository.deleteTask()` for tasks

### Required Fixes

#### 1. Update Button Text and Help
**Lines 216-227:** Change "Clear All" to "Clear All Data" and update help text

```swift
Text("Clear All Data")
    .font(.system(size: 12, weight: .medium))
    .foregroundColor(.white)
```

```swift
.help("Delete all data including tasks, resources, projects, areas, and archives")
```

#### 2. Update Confirmation Dialog
**Lines 54-63:** Update dialog title and message

```swift
.alert("Clear All Data", isPresented: $showingClearAllConfirmation) {
    Button("Cancel", role: .cancel) { }
    Button("Delete All", role: .destructive) {
        Task {
            await clearAllData() // renamed method
        }
    }
} message: {
    Text("Are you sure you want to delete ALL data including tasks, resources, projects, areas, and archives? This action cannot be undone.")
}
```

#### 3. Implement Comprehensive clearAllData Method
**Lines 340-380:** Replace `clearAllTasks()` with comprehensive `clearAllData()`:

```swift
private func clearAllData() async {
    do {
        // Initialize all repositories
        let taskRepository = TaskRepository()
        let resourceRepository = ResourceRepository()
        let projectRepository = ProjectRepository()
        let areaRepository = AreaRepository()
        let archiveRepository = ArchiveRepository()
        
        // Fetch all data types
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
        
        // Clear UI state
        await MainActor.run {
            calendarViewModel.allTasks = []
            calendarViewModel.events = []
            mainViewModel.areaTasks = [:]
            mainViewModel.projectTasks = [:]
            mainViewModel.focusTasks = []
            mainViewModel.areas = []
            mainViewModel.projects = []
            mainViewModel.resources = []
            mainViewModel.archives = []
        }
        
        // Refresh all data
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
```

### Import Required Repositories
Add repository imports at the top of the file if not already present:

```swift
// At the top of CalendarHeaderView.swift, ensure these are available:
// TaskRepository, ResourceRepository, ProjectRepository, AreaRepository, ArchiveRepository
```

### Benefits of This Fix

1. **Honesty:** Button now does what it promises
2. **Comprehensive:** Actually clears all PARA data as expected
3. **User Experience:** Clear labeling and confirmation dialog
4. **Safety:** Maintains confirmation dialog for destructive action
5. **Consistency:** Matches user expectations from UI text

### Testing Verification

After implementing this fix:

1. **Create test data:** Add tasks, resources, projects, areas
2. **Verify button text:** Should show "Clear All Data"
3. **Test confirmation:** Dialog should mention all data types
4. **Execute clear:** All PARA tabs should be empty after clearing
5. **Database verification:** Confirm all tables are cleared
6. **UI refresh:** All views should show empty state correctly

### Performance Considerations

For large datasets, consider:
- Progress indicators during deletion
- Batch deletion for better performance
- Background processing to avoid UI blocking
- Cancellation capability for long operations

### Priority: HIGH
This fix resolves user trust issues where the UI promises functionality that doesn't work as described.