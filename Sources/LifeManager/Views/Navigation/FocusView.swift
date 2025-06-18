//
// FocusView.swift
// LifeManager
//
// Implements: v1.5 "Focus System", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion  
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Advanced Focus Algorithms, Time Boxing
//

import SwiftUI

/// Focus view for high-priority tasks and current work
struct FocusView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("Focus")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("High-priority tasks and current work")
                .font(.caption)
                .foregroundColor(.secondary)
            
            EmptyStateView(
                title: "Focus view",
                systemImage: "scope",
                description: "Full implementation will be extracted next"
            )
        }
    }
}

#Preview {
    FocusView()
        .environmentObject(MainViewModel())
}