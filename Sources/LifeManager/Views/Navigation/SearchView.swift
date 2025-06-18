//
// SearchView.swift
// LifeManager
//
// Implements: v1.5 "Search System", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Semantic Search, AI-Powered Query Enhancement
//

import SwiftUI

/// Search view for finding content across all PARA categories
/// Clean navigation component extracted from monolithic ContentView
struct SearchView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("Search")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Find content across all categories")
                .font(.caption)
                .foregroundColor(.secondary)
            
            EmptyStateView(
                title: "Search view",
                systemImage: "magnifyingglass",
                description: "Full implementation will be extracted next"
            )
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(MainViewModel())
}