//
// HistoryView.swift
// LifeManager
//
// Implements: v1.5 "Search System", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Activity Analytics, Historical Trends
//

import SwiftUI

/// History view for browsing past activities and changes
/// Clean navigation component extracted from monolithic ContentView
struct HistoryView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Browse past activities and changes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            EmptyStateView(
                title: "History view",
                systemImage: "clock.arrow.circlepath",
                description: "Full implementation will be extracted next"
            )
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(MainViewModel())
}