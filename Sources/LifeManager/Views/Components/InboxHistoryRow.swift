//
// InboxHistoryRow.swift
// LifeManager
//
// Implements: v1.25 "Enhanced UI", v2.0 "Modular Architecture"
// Roadmap Reference: v1.25 Intelligence & UI → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Enhanced History Details, Quick Actions
//

import SwiftUI

/// Individual row component for inbox processing history
/// Displays condensed information about previous brain dump operations
/// Clean, reusable component for historical context
struct InboxHistoryRow: View {
    let item: InboxHistoryItem
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(item.input.prefix(40)) + (item.input.count > 40 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(1)
                
                Text(RelativeDateTimeFormatter().localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.itemsCreated) items")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                if !item.categories.isEmpty {
                    Text(item.categories.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

#Preview {
    InboxHistoryRow(
        item: InboxHistoryItem(
            input: "Sample brain dump input for testing the history display",
            itemsCreated: 3,
            timestamp: Date(),
            categories: ["Tasks", "Notes"]
        )
    )
    .padding()
}