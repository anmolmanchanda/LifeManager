//
// StatView.swift
// LifeManager
//
// Implements: v1.75 "Enhanced UI", v2.0 "Modular Architecture"
// Roadmap Reference: v1.75 Calendar Revolution → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Animated Statistics, Trend Indicators
//

import SwiftUI

/// Reusable statistics display component for showing key metrics
/// Clean, consistent visual element used across PARA views for data summary
/// Extracted from monolithic ContentView for better reusability
struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        StatView(
            title: "Active Projects",
            value: "12",
            color: .green
        )
        
        StatView(
            title: "Total Notes",
            value: "156",
            color: .blue
        )
        
        StatView(
            title: "Completed Tasks",
            value: "89",
            color: .orange
        )
    }
    .padding()
}