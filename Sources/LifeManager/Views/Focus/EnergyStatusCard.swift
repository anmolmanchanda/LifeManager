import SwiftUI

/// Energy Status Card - Shows AI-analyzed mood and energy with contextual suggestions
struct EnergyStatusCard: View {
    let moodAssessment: DailyMoodAssessment
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack(spacing: 16) {
                // Mood emoji and energy indicator
                VStack(spacing: 8) {
                    Text(moodAssessment.overallMood.emoji)
                        .font(.system(size: 32))
                    
                    HStack(spacing: 4) {
                        Image(systemName: moodAssessment.energyLevel.icon)
                            .foregroundColor(moodAssessment.energyLevel.color)
                        Text(energyText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(moodAssessment.energyLevel.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(moodAssessment.overallMood.displayName) | \(moodAssessment.energyLevel.displayName)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // AI confidence indicator
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            Text("\(Int(moodAssessment.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Primary AI insight
                    if let primaryInsight = primaryAIInsight {
                        Text(primaryInsight)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(defaultSuggestion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Data source indicator
                    HStack {
                        Image(systemName: dataSourceIcon)
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        Text("Based on \(moodAssessment.dataSource.displayName)")
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        Spacer()
                    }
                }
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            EnergyStatusDetailView(moodAssessment: moodAssessment)
        }
    }
    
    private var energyText: String {
        switch moodAssessment.energyLevel {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    private var backgroundColor: Color {
        moodAssessment.overallMood.color.opacity(0.1)
    }
    
    private var borderColor: Color {
        moodAssessment.overallMood.color.opacity(0.3)
    }
    
    private var primaryAIInsight: String? {
        // Get the most actionable insight
        moodAssessment.insights.first(where: { $0.actionable })?.insight
    }
    
    private var defaultSuggestion: String {
        switch (moodAssessment.energyLevel, moodAssessment.focusCapacity) {
        case (.high, .excellent), (.high, .good):
            return "Great time for complex tasks and deep work"
        case (.high, .average):
            return "Good energy for tackling medium complexity tasks"
        case (.medium, .good), (.medium, .excellent):
            return "Perfect for a mix of focused and routine tasks"
        case (.medium, .average):
            return "Consider moderate complexity work with breaks"
        case (.low, _):
            return "Focus on simple tasks and organization"
        default:
            return "Listen to your body and adjust task difficulty accordingly"
        }
    }
    
    private var dataSourceIcon: String {
        switch moodAssessment.dataSource {
        case .brainDumpAnalysis:
            return "text.bubble"
        case .completionPatterns:
            return "checkmark.circle"
        case .activityAnalysis:
            return "chart.line.uptrend.xyaxis"
        case .languageAnalysis:
            return "text.magnifyingglass"
        case .temporalPatterns:
            return "clock"
        }
    }
}

// MARK: - Energy Status Detail View

struct EnergyStatusDetailView: View {
    let moodAssessment: DailyMoodAssessment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with emoji and main status
                    VStack(spacing: 16) {
                        Text(moodAssessment.overallMood.emoji)
                            .font(.system(size: 64))
                        
                        VStack(spacing: 8) {
                            Text(moodAssessment.overallMood.displayName)
                                .font(.title)
                                .fontWeight(.semibold)
                            
                            Text("Energy: \(moodAssessment.energyLevel.displayName)")
                                .font(.headline)
                                .foregroundColor(moodAssessment.energyLevel.color)
                        }
                    }
                    .padding(.top)
                    
                    // Detailed metrics
                    VStack(spacing: 16) {
                        MetricRow(
                            title: "Focus Capacity",
                            value: moodAssessment.focusCapacity.displayName,
                            icon: "brain.head.profile",
                            color: focusCapacityColor
                        )
                        
                        MetricRow(
                            title: "Stress Level",
                            value: moodAssessment.stressLevel.displayName,
                            icon: "heart.text.square",
                            color: stressLevelColor
                        )
                        
                        MetricRow(
                            title: "AI Confidence",
                            value: "\(Int(moodAssessment.confidence * 100))%",
                            icon: "brain",
                            color: .purple
                        )
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    
                    // AI Insights
                    if !moodAssessment.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.yellow)
                                Text("AI Insights")
                                    .font(.headline)
                            }
                            
                            ForEach(moodAssessment.insights) { insight in
                                InsightRow(insight: insight)
                            }
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Suggested Actions
                    if !moodAssessment.suggestedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet.circle")
                                    .foregroundColor(.blue)
                                Text("Suggested Actions")
                                    .font(.headline)
                            }
                            
                            ForEach(moodAssessment.suggestedActions, id: \.self) { action in
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(action)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Data source information
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("Analysis Source")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(moodAssessment.dataSource.displayName)
                            .font(.subheadline)
                        
                        Text("Generated at \(formatTime(moodAssessment.createdAt))")
                            .font(.caption)
                            .foregroundColor(.tertiary)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Energy Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private var focusCapacityColor: Color {
        switch moodAssessment.focusCapacity {
        case .excellent, .good:
            return .green
        case .average:
            return .orange
        case .poor, .veryPoor:
            return .red
        }
    }
    
    private var stressLevelColor: Color {
        switch moodAssessment.stressLevel {
        case .low:
            return .green
        case .moderate:
            return .orange
        case .high, .veryHigh:
            return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct InsightRow: View {
    let insight: MoodInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: categoryIcon)
                .foregroundColor(categoryColor)
                .font(.caption)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.insight)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text(insight.category.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if insight.actionable {
                        Text("Actionable")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var categoryIcon: String {
        switch insight.category {
        case .productivity:
            return "chart.line.uptrend.xyaxis"
        case .wellbeing:
            return "heart"
        case .patterns:
            return "waveform.path"
        case .recommendations:
            return "lightbulb"
        }
    }
    
    private var categoryColor: Color {
        switch insight.category {
        case .productivity:
            return .blue
        case .wellbeing:
            return .green
        case .patterns:
            return .purple
        case .recommendations:
            return .orange
        }
    }
}

#Preview {
    let sampleAssessment = DailyMoodAssessment(
        date: "2024-01-15",
        overallMood: .positive,
        energyLevel: .high,
        stressLevel: .low,
        focusCapacity: .good,
        confidence: 0.85,
        dataSource: .completionPatterns,
        insights: [
            MoodInsight(
                category: .productivity,
                insight: "High completion rate indicates strong productivity today",
                confidence: 0.8,
                actionable: false
            ),
            MoodInsight(
                category: .recommendations,
                insight: "High energy - good time for complex tasks",
                confidence: 0.7,
                actionable: true
            )
        ],
        suggestedActions: [
            "Tackle complex or creative tasks",
            "Good time for deep work sessions"
        ]
    )
    
    return VStack {
        EnergyStatusCard(moodAssessment: sampleAssessment)
            .padding()
        Spacer()
    }
}