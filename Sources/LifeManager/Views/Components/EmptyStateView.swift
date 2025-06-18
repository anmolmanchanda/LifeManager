//
// EmptyStateView.swift
// LifeManager
//
// Implements: v2.0 "Modular Architecture" - Reusable UI Components
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (created for modular architecture)
// Future: v2.5 Animated Empty States, Contextual Actions
//

import SwiftUI

/// Reusable empty state component for when collections have no items
/// Provides consistent visual feedback across all PARA views
/// Supports both modern ContentUnavailableView and fallback implementation
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        if #available(macOS 14.0, *) {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(description)
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No items yet",
        systemImage: "tray",
        description: "Items will appear here as you add them"
    )
    .frame(width: 400, height: 300)
}