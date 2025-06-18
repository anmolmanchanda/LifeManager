//
// ResourceRowView.swift
// LifeManager
//
// Implements: v1.5 "Complete PARA Views", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Enhanced Resource Display, Quick Actions
//

import SwiftUI

/// Resource row view for displaying individual resource items
/// Clean component extracted from monolithic ContentView
struct ResourceRowView: View {
    let resource: Resource
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(resource.title)
                .font(.headline)
            
            if let description = resource.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Resource row component - full implementation needed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlColor))
        .cornerRadius(8)
    }
}

#Preview {
    ResourceRowView(resource: Resource(
        id: UUID(),
        title: "Sample Resource",
        description: "Sample description",
        url: "https://example.com",
        workPersonal: .personal,
        createdAt: "2025-06-18T12:00:00Z",
        updatedAt: "2025-06-18T12:00:00Z"
    ))
    .environmentObject(MainViewModel())
}