//
// ProjectSectionView.swift
// LifeManager
//
// Implements: v1.5 "Complete PARA Views", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Enhanced Project Management, Gantt Integration
//

import SwiftUI

/// Project section view for expandable project display with tasks and notes
/// Clean component extracted from monolithic ContentView
struct ProjectSectionView: View {
    let project: Project
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(project.title)
                .font(.headline)
            
            Text("Project section component - full implementation needed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
    }
}

#Preview {
    ProjectSectionView(project: Project(
        id: UUID(),
        title: "Sample Project",
        description: "Sample description",
        status: .active,
        workPersonal: .personal,
        createdAt: "2025-06-18T12:00:00Z",
        updatedAt: "2025-06-18T12:00:00Z"
    ))
    .environmentObject(MainViewModel())
}