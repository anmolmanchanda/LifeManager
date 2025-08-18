//
// ProjectsView.swift
// LifeManager
//
// Projects view for PARA methodology
// Extracted from ContentView for modularity
//

import SwiftUI

/// Main view for displaying and managing projects
struct ProjectsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var searchText = ""
    @State private var selectedStatus: ProjectStatus? = nil
    @State private var showingAddProject = false
    @State private var sortBy: ProjectSortOption = .deadline
    
    var filteredProjects: [Project] {
        var projects = viewModel.projects
        
        // Filter by search
        if !searchText.isEmpty {
            projects = projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                (project.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by status
        if let status = selectedStatus {
            projects = projects.filter { $0.status == status }
        }
        
        // Sort
        switch sortBy {
        case .name:
            projects.sort { $0.name < $1.name }
        case .deadline:
            projects.sort { a, b in
                if let aDeadline = a.deadline, let bDeadline = b.deadline {
                    return aDeadline < bDeadline
                } else if a.deadline != nil {
                    return true
                } else {
                    return false
                }
            }
        case .createdDate:
            projects.sort { $0.createdAt > $1.createdAt }
        case .status:
            projects.sort { $0.status.rawValue < $1.status.rawValue }
        }
        
        return projects
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ProjectsHeaderView(
                searchText: $searchText,
                selectedStatus: $selectedStatus,
                sortBy: $sortBy,
                showingAddProject: $showingAddProject
            )
            .padding()
            
            Divider()
            
            // Content
            if filteredProjects.isEmpty {
                EmptyProjectsView(searchActive: !searchText.isEmpty)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            let statusProjects = filteredProjects.filter { $0.status == status }
                            if !statusProjects.isEmpty {
                                ProjectSectionView(
                                    status: status,
                                    projects: statusProjects
                                )
                                .environmentObject(viewModel)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView()
                .environmentObject(viewModel)
        }
    }
}

/// Header for projects view with search and filters
struct ProjectsHeaderView: View {
    @Binding var searchText: String
    @Binding var selectedStatus: ProjectStatus?
    @Binding var sortBy: ProjectSortOption
    @Binding var showingAddProject: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Projects", systemImage: "folder.badge.star")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingAddProject = true }) {
                    Label("New Project", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Status Filter
                Picker("Status", selection: $selectedStatus) {
                    Text("All Status").tag(ProjectStatus?.none)
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        Label(status.displayName, systemImage: status.icon)
                            .tag(ProjectStatus?.some(status))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                // Sort
                Picker("Sort by", selection: $sortBy) {
                    ForEach(ProjectSortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
        }
    }
}

/// Section view for projects grouped by status
struct ProjectSectionView: View {
    let status: ProjectStatus
    let projects: [Project]
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Label(status.displayName, systemImage: status.icon)
                    .font(.headline)
                    .foregroundColor(status.color)
                
                Text("(\(projects.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            if isExpanded {
                ForEach(projects) { project in
                    ProjectCardView(project: project)
                        .environmentObject(viewModel)
                }
            }
        }
    }
}

/// Card view for individual project
struct ProjectCardView: View {
    let project: Project
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isHovered = false
    @State private var showingDetails = false
    
    var taskCount: Int {
        viewModel.projectTasks[project.id]?.count ?? 0
    }
    
    var blobCount: Int {
        viewModel.projectBlobs[project.id]?.count ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                    
                    if let description = project.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Status Badge
                StatusBadge(status: project.status)
            }
            
            // Metadata
            HStack(spacing: 16) {
                if let deadline = project.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(isDeadlineNear(deadline) ? .orange : .secondary)
                }
                
                Label("\(taskCount) tasks", systemImage: "checklist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(blobCount) items", systemImage: "doc.stack")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Work/Personal Badge
                WorkPersonalBadge(type: project.workPersonal)
            }
            
            // Progress Bar
            if taskCount > 0 {
                let completedTasks = viewModel.projectTasks[project.id]?.filter { $0.isCompleted }.count ?? 0
                ProgressBar(value: Double(completedTasks) / Double(taskCount))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHovered ? project.status.color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            viewModel.selectedProject = project
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            ProjectDetailView(project: project)
                .environmentObject(viewModel)
        }
    }
    
    private func isDeadlineNear(_ deadline: Date) -> Bool {
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        return daysUntilDeadline <= 7 && daysUntilDeadline >= 0
    }
}

/// Empty state for projects view
struct EmptyProjectsView: View {
    let searchActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchActive ? "magnifyingglass" : "folder.badge.star")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchActive ? "No projects found" : "No projects yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(searchActive ? "Try adjusting your search or filters" : "Create your first project to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Supporting Types

enum ProjectSortOption: String, CaseIterable {
    case name = "Name"
    case deadline = "Deadline"
    case createdDate = "Created Date"
    case status = "Status"
    
    var displayName: String { rawValue }
}

extension ProjectStatus {
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "play.circle"
        case .onHold: return "pause.circle"
        case .completed: return "checkmark.circle"
        case .archived: return "archivebox"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}