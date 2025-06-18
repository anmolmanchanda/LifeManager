//
// TimelineView.swift
// LifeManager
//
// Implements: v1.5 "Timeline & Mind Map", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Interactive Timeline, Gantt Integration
//

import SwiftUI

/// Timeline view for chronological display of tasks and events
/// Clean navigation component extracted from monolithic ContentView
struct TimelineView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("Timeline")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Chronological view of tasks and events")
                .font(.caption)
                .foregroundColor(.secondary)
            
            EmptyStateView(
                title: "Timeline view",
                systemImage: "timeline.selection",
                description: "Full implementation will be extracted next"
            )
        }
    }
}

#Preview {
    TimelineView()
        .environmentObject(MainViewModel())
}