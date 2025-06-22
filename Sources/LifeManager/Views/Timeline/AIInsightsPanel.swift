//
// AIInsightsPanel.swift
// LifeManager
//
// AI Insights Panel: Timeline AI Recommendations and Analysis
// Implements: v2.0 Timeline View AI insights with recommendations and pattern analysis
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// AI insights panel for Timeline View displaying recommendations and analysis
/// Shows pattern recognition, risk assessment, and optimization suggestions
struct AIInsightsPanel: View {
    let insights: [TimelineInsight]
    @State private var selectedCategory: InsightCategory = .all
    @State private var isExpanded = true
    
    enum InsightCategory: String, CaseIterable {
        case all = "All"
        case progress = "Progress"
        case patterns = "Patterns"
        case risks = "Risks"
        case opportunities = "Opportunities"
        case predictions = "Predictions"
        
        var icon: String {
            switch self {
            case .all: return "brain"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .patterns: return "waveform.path.ecg"
            case .risks: return "exclamationmark.triangle"
            case .opportunities: return "lightbulb"
            case .predictions: return "crystal.ball"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .purple
            case .progress: return .blue
            case .patterns: return .green
            case .risks: return .red
            case .opportunities: return .orange
            case .predictions: return .purple
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            insightsHeader
            
            if isExpanded {
                // Category Filter
                categoryFilter
                
                // Insights Content
                insightsContent
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Header
    
    private var insightsHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.body)
                    .foregroundColor(.purple)
                
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\\(filteredInsights.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InsightCategory.allCases, id: \\.self) { category in
                    categoryButton(for: category)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }
    
    private func categoryButton(for category: InsightCategory) -> some View {
        Button(action: { selectedCategory = category }) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                let count = insights.filter { matchesCategory($0, category) }.count
                if count > 0 && category != .all {
                    Text("\\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(category.color)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedCategory == category ? category.color : Color.secondary.opacity(0.1))
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Insights Content
    
    private var insightsContent: some View {
        LazyVStack(spacing: 12) {
            if filteredInsights.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredInsights.prefix(5), id: \\.id) { insight in
                    InsightCard(insight: insight)
                }
                
                if filteredInsights.count > 5 {
                    showMoreButton
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No insights available")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("AI is analyzing your timeline patterns")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    private var showMoreButton: some View {
        Button("Show All \\(filteredInsights.count) Insights") {
            // TODO: Implement full insights view
        }
        .font(.caption)
        .foregroundColor(.accentColor)
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    
    private var filteredInsights: [TimelineInsight] {
        if selectedCategory == .all {
            return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
        } else {
            return insights.filter { matchesCategory($0, selectedCategory) }
                           .sorted { $0.priority.rawValue > $1.priority.rawValue }
        }
    }
    
    private func matchesCategory(_ insight: TimelineInsight, _ category: InsightCategory) -> Bool {
        switch category {
        case .all: return true
        case .progress: return insight.category == .progress
        case .patterns: return insight.category == .patterns
        case .risks: return insight.category == .risks
        case .opportunities: return insight.category == .opportunities
        case .predictions: return insight.category == .predictions
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: TimelineInsight
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: insight.category.icon)
                        .font(.body)
                        .foregroundColor(insight.category.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(insight.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                }
                
                Spacer()
                
                // Priority and Confidence
                VStack(alignment: .trailing, spacing: 4) {
                    priorityBadge
                    confidenceBadge
                }
            }
            
            // Expanded Details
            if isExpanded && !insight.details.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(insight.details, id: \\.self) { detail in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(insight.category.color)
                                .frame(width: 4, height: 4)
                            
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            // Actions
            if insight.hasActionableRecommendations {
                actionButtons
            }
        }
        .padding(12)
        .background(insight.category.color.opacity(0.05))
        .cornerRadius(12)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var priorityBadge: some View {
        Text(insight.priority.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(insight.priority.color)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var confidenceBadge: some View {
        Text("\\(Int(insight.confidence * 100))%")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Apply") {
                // TODO: Implement insight application
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(insight.category.color)
            .foregroundColor(.white)
            .cornerRadius(6)
            
            Button("Dismiss") {
                // TODO: Implement insight dismissal
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(.secondary)
            .cornerRadius(6)
            
            Spacer()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions

extension TimelineInsightCategory {
    var icon: String {
        switch self {
        case .progress: return "chart.line.uptrend.xyaxis"
        case .patterns: return "waveform.path.ecg"
        case .risks: return "exclamationmark.triangle"
        case .opportunities: return "lightbulb"
        case .predictions: return "crystal.ball"
        }
    }
    
    var color: Color {
        switch self {
        case .progress: return .blue
        case .patterns: return .green
        case .risks: return .red
        case .opportunities: return .orange
        case .predictions: return .purple
        }
    }
}

extension TimelineInsightPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}