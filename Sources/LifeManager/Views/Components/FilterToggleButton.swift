//
// FilterToggleButton.swift
// LifeManager
//
// Implements: v1.5 "Work/Personal Filtering", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Advanced Filtering Options, Multi-Select
//

import SwiftUI

/// Reusable toggle button component for filtering content by work/personal type
/// Clean, consistent UI element used across all PARA views
/// Extracted from monolithic ContentView for better reusability
struct FilterToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    HStack {
        FilterToggleButton(
            title: "Personal",
            isSelected: true,
            action: {}
        )
        
        FilterToggleButton(
            title: "Work",
            isSelected: false,
            action: {}
        )
    }
    .padding()
}*/
