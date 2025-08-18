import SwiftUI
import Foundation

/// Calendar header component with navigation and view mode controls
/// 
/// Provides:
/// - Previous/Next navigation buttons
/// - Today button for quick navigation
/// - Current date/period display
/// - Filter controls with active filter indicators
/// - Smart scheduling toggle
/// - View mode picker (Day/Week/Month)
struct CalendarHeaderView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // MARK: - State
    @State private var showingFilters = false
    @State private var showingClearAllConfirmation = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                // Navigation Controls
                navigationControls
                
                Spacer()
                
                // Current Date Display
                currentDateDisplay
                
                Spacer()
                
                // Action Controls
                actionControls
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            // View Mode Picker
            viewModePicker
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 0.5)
        }
        .alert("Clear All Data", isPresented: $showingClearAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task {
                    await clearAllData()
                }
            }
        } message: {
            Text("Are you sure you want to delete ALL data including tasks, resources, projects, areas, and archives? This action cannot be undone.")
        }
    }
    
    // MARK: - Navigation Controls
    
    private var navigationControls: some View {
        HStack(spacing: 12) {
            Button(action: { calendarViewModel.navigatePrevious() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help("Previous period")
            
            Button("Today") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    calendarViewModel.navigateToToday()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .help("Go to today")
            
            Button(action: { calendarViewModel.navigateNext() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help("Next period")
        }
    }
    
    // MARK: - Current Date Display
    
    private var currentDateDisplay: some View {
        VStack(spacing: 2) {
            Text(formatDateForCurrentView())
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(periodSubtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Action Controls
    
    private var actionControls: some View {
        HStack(spacing: 12) {
            // Clear All Data Button
            clearAllDataButton
            
            // Filter Button
            filterButton
            
            // Smart Scheduling Toggle
            smartSchedulingButton
            
            // Sync Button
            syncButton
        }
    }
    
    // MARK: - Filter Button
    
    private var filterButton: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingFilters.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(hasActiveFilters ? .white : .secondary)
                    .frame(width: 36, height: 36)
                    .background(hasActiveFilters ? 
                               AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(Color(NSColor.controlBackgroundColor)))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(hasActiveFilters ? 0.2 : 0.1), radius: hasActiveFilters ? 3 : 1, x: 0, y: 1)
                
                if hasActiveFilters {
                    Text("\(calendarViewModel.activeFilters.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .buttonStyle(.plain)
        .help("Filter calendar events")
        .popover(isPresented: $showingFilters) {
            CalendarFilterView()
                .environmentObject(calendarViewModel)
        }
    }
    
    // MARK: - Smart Scheduling Button
    
    private var smartSchedulingButton: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                calendarViewModel.isSmartSchedulingEnabled.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: calendarViewModel.isSmartSchedulingEnabled ? 
                      "brain.filled.head.profile" : "brain.head.profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(calendarViewModel.isSmartSchedulingEnabled ? .white : .secondary)
                
                Text("Smart")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(calendarViewModel.isSmartSchedulingEnabled ? .white : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(calendarViewModel.isSmartSchedulingEnabled ? 
                       AnyView(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                       AnyView(Color(NSColor.controlBackgroundColor)))
            .cornerRadius(12)
            .shadow(color: .black.opacity(calendarViewModel.isSmartSchedulingEnabled ? 0.2 : 0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .help("Toggle smart scheduling")
    }
    
    // MARK: - Clear All Data Button
    
    private var clearAllDataButton: some View {
        Button(action: {
            showingClearAllConfirmation = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Clear All Data")
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
        .help("Delete all data including tasks, resources, projects, areas, and archives")
    }
    
    // MARK: - Sync Button
    
    private var syncButton: some View {
        Button(action: {
            Task {
                await calendarViewModel.syncWithToggl()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: syncIconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(syncIconColor)
                
                Text("Sync")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help("Sync with Toggl")
        .disabled(calendarViewModel.togglSyncStatus == .syncing)
    }
    
    // MARK: - View Mode Picker
    
    private var viewModePicker: some View {
        Picker("", selection: $calendarViewModel.viewMode) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Text(mode.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveFilters: Bool {
        !calendarViewModel.activeFilters.isEmpty
    }
    
    private var periodSubtitle: String {
        switch calendarViewModel.viewMode {
        case .day:
            return "Daily View"
        case .week:
            return "Weekly View"
        case .month:
            return "Monthly View"
        }
    }
    
    private var syncIconName: String {
        switch calendarViewModel.togglSyncStatus {
        case .idle:
            return "arrow.clockwise"
        case .syncing:
            return "arrow.clockwise"
        case .success:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var syncIconColor: Color {
        switch calendarViewModel.togglSyncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDateForCurrentView() -> String {
        let formatter = DateFormatter()
        
        switch calendarViewModel.viewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        case .week:
            let weekStart = calendarViewModel.selectedDate.startOfWeek
            let calendar = Calendar.current
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: calendarViewModel.selectedDate)
            }
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        }
        
        return formatter.string(from: calendarViewModel.selectedDate)
    }
    
    // MARK: - Clear All Data Method
    
    /// FIXED: Clear All Data - now actually deletes all PARA content as promised
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
}

// MARK: - Calendar Filter View Component

/// Filter view for calendar events
struct CalendarFilterView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter Events")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(CalendarFilter.allCases, id: \.self) { filter in
                    FilterToggleRow(filter: filter)
                        .environmentObject(calendarViewModel)
                }
            }
            
            HStack {
                Spacer()
                
                if !calendarViewModel.activeFilters.isEmpty {
                    Button("Clear All") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            calendarViewModel.clearAllFilters()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .frame(width: 200)
    }
}

// MARK: - Filter Toggle Row Component

/// Individual filter toggle row
struct FilterToggleRow: View {
    let filter: CalendarFilter
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { calendarViewModel.activeFilters.contains(filter) },
            set: { _ in calendarViewModel.toggleFilter(filter) }
        )) {
            Text(filter.rawValue)
                .font(.system(size: 14))
        }
        .toggleStyle(.checkbox)
    }
}

// MARK: - Preview

/* #Preview // DISABLED FOR STABILIZATION
    CalendarHeaderView()
        .environmentObject(CalendarViewModel())
        .environmentObject(MainViewModel())
        .frame(width: 800)
} */
