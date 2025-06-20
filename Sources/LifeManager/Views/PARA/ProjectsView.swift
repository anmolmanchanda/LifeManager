//
// ProjectsView.swift
// LifeManager
//
// Implements: v1.0 "PARA Framework", v1.75 "Enhanced UI", v2.0 "Modular Architecture"
// Roadmap Reference: v1.0 Foundation → v1.75 Calendar Revolution → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Project Analytics, Gantt Charts, Timeline View
//

import SwiftUI

/// Projects view for PARA methodology - Time-bound efforts with clear outcomes
/// Features AI processing transparency, statistics, and expandable project sections
/// Clean, focused component extracted from monolithic ContentView
struct ProjectsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private var filteredProjects: [Project] {
        guard let filter = workPersonalFilter else { return viewModel.projects }
        return viewModel.projects.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI processing info and Work/Personal toggle
            VStack(spacing: 16) {
                HStack {
                    Text("Projects")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Work/Personal filter toggle
                    HStack(spacing: 4) {
                        FilterToggleButton(
                            title: "Personal",
                            isSelected: workPersonalFilter == .personal,
                            action: {
                                workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                            }
                        )
                        
                        FilterToggleButton(
                            title: "Work",
                            isSelected: workPersonalFilter == .work,
                            action: {
                                workPersonalFilter = workPersonalFilter == .work ? nil : .work
                            }
                        )
                    }
                    
                    // AI processing status
                    if !viewModel.projectBlobs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "brain")
                                .foregroundColor(.blue)
                            
                            let totalProjectBlobs = viewModel.projectBlobs.values.flatMap { $0 }.count
                            Text("AI organized \(totalProjectBlobs) notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Quick stats
                if !filteredProjects.isEmpty {
                    HStack(spacing: 20) {
                        StatView(
                            title: "Active Projects", 
                            value: "\(filteredProjects.filter { $0.status == .active }.count)",
                            color: .green
                        )
                        StatView(
                            title: "Total Notes", 
                            value: "\(viewModel.projectBlobs.values.flatMap { $0 }.count)",
                            color: .blue
                        )
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Projects list with expandable sections
            if filteredProjects.isEmpty {
                EmptyStateView(
                    title: "No projects yet",
                    systemImage: "target",
                    description: "AI will create projects from your notes automatically"
                )
            } else {
                List {
                    ForEach(filteredProjects) { project in
                        ProjectSectionView(project: project)
                            .environmentObject(viewModel)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    ProjectsView()
        .environmentObject(MainViewModel())
        .frame(width: 800, height: 600)
}*/
