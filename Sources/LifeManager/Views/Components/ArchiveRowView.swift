//
// ArchiveRowView.swift
// LifeManager
//
// Implements: v1.5 "Complete PARA Views", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Enhanced Archive Management, Restore Functionality
//

import SwiftUI

/// Archive row view for displaying individual archive items
/// Clean component extracted from monolithic ContentView
struct ArchiveRowView: View {
    let archive: Archive
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(archive.title)
                .font(.headline)
            
            Text("Archived \(archive.contentType)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Archive row component - full implementation needed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    ArchiveRowView(archive: Archive(
        id: UUID(),
        title: "Sample Archive",
        description: "Sample description",
        originalType: .project,
        workPersonal: .personal,
        createdAt: "2025-06-18T12:00:00Z",
        archivedAt: "2025-06-18T12:00:00Z"
    ))
    .environmentObject(MainViewModel())
}*/
