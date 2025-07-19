//
// GoalTimelineCard.swift
// LifeManager
//
// Goal Timeline Card: Interactive Goal Visualization with AI Insights
// Implements: v2.0 Timeline View goal card with progress tracking and milestone management
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Interactive goal card for Timeline View with progress visualization and AI insights
/// Displays goal status, milestones, progress bars, and quick actions
struct GoalTimelineCard: View {
    let goal: Goal
    let milestones: [Milestone]
    let onTap: () -> Void
    let onMilestoneToggle: (Milestone) -> Void
    
    @State private var isExpanded = false
    @State private var showingQuickActions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Goal Card
            goalHeaderCard
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .contextMenu {
                    goalContextMenu
                }
            
            // Expanded Content
            if isExpanded {
                expandedContentView
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Goal Header Card
    
    private var goalHeaderCard: some View {
        HStack(spacing: 16) {
            // Timeline Indicator
            VStack {
                Circle()
                    .fill(goalStatusColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                
                if !isLastGoal {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 3, height: 40)
                }
            }
            .frame(width: 16)
            
            // Goal Content
            VStack(alignment: .leading, spacing: 12) {
                // Header with Goal Name and Status
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Goal Name
                        Text(goal.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Goal Description
                        if let description = goal.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Status and Priority
                    VStack(alignment: .trailing, spacing: 4) {
                        // Status Badge
                        statusBadge
                        
                        // Priority Indicator
                        if goal.priority == .high || goal.priority == .urgent {
                            priorityIndicator
                        }
                    }
                }
                
                // Progress Section
                progressSection
                
                // Timeline Information
                timelineInfo
                
                // AI Insights Preview
                if goal.riskLevel != .low || goal.onTrackScore < 0.8 {
                    aiInsightsPreview
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .padding(.leading, 16)
    }
    
    // MARK: - Status and Priority Indicators
    
    private var statusBadge: some View {
        Text(goal.status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(goalStatusColor.opacity(0.2))
            .foregroundColor(goalStatusColor)
            .cornerRadius(12)
    }
    
    private var priorityIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption)
            Text(goal.priority.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(priorityColor)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\\(Int(goal.progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * goal.progressPercentage, height: 8)
                }
            }
            .frame(height: 8)
            
            // Milestone Overview
            if !milestones.isEmpty {
                milestoneOverview
            }
        }
    }
    
    private var milestoneOverview: some View {
        HStack {
            Text("\\(completedMilestonesCount)/\\(milestones.count) milestones")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(milestones.prefix(5), id: \.id) { milestone in
                    Circle()
                        .fill(milestone.isCompleted ? .green : .secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                if milestones.count > 5 {
                    Text("+\\(milestones.count - 5)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Timeline Information
    
    private var timelineInfo: some View {
        HStack(spacing: 16) {
            // Start Date
            if let startDate = goal.startDate {
                timelineInfoItem(
                    title: "Started",
                    date: startDate,
                    icon: "play.circle"
                )
            }
            
            // Target Date
            if let targetDate = goal.targetDate {
                timelineInfoItem(
                    title: "Target",
                    date: targetDate,
                    icon: "flag.checkered"
                )
            }
            
            // Predicted Completion
            if let predictedDate = goal.predictedCompletionDate,
               predictedDate != goal.targetDate {
                timelineInfoItem(
                    title: "Predicted",
                    date: predictedDate,
                    icon: "crystal.ball",
                    isAI: true
                )
            }
            
            Spacer()
        }
    }
    
    private func timelineInfoItem(title: String, date: Date, icon: String, isAI: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(isAI ? .purple : .secondary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isAI ? .purple : .secondary)
            }
            
            Text(DateFormatter.shortDate.string(from: date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - AI Insights Preview
    
    private var aiInsightsPreview: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.caption)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                if goal.riskLevel != .low {
                    Text("Risk Level: \\(goal.riskLevel.displayName)")
                        .font(.caption)
                        .foregroundColor(riskLevelColor)
                }
                
                if goal.onTrackScore < 0.8 {
                    Text("On Track: \\(Int(goal.onTrackScore * 100))%")
                        .font(.caption)
                        .foregroundColor(onTrackColor)
                }
            }
            
            Spacer()
            
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContentView: some View {
        VStack(spacing: 16) {
            Divider()
            
            // Detailed Milestones
            if !milestones.isEmpty {
                milestonesSection
            }
            
            // AI Recommendations
            aiRecommendationsSection
            
            // Quick Actions
            quickActionsSection
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(milestones.prefix(3), id: \.id) { milestone in
                MilestoneRow(
                    milestone: milestone,
                    onToggle: { onMilestoneToggle(milestone) }
                )
            }
            
            if milestones.count > 3 {
                Button("View All \\(milestones.count) Milestones") {
                    onTap()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundColor(.purple)
                Text("AI Insights")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if goal.velocityTrend == .declining {
                    insightRow(
                        icon: "chart.line.downtrend.xyaxis",
                        text: "Velocity declining - consider adjusting timeline",
                        color: .orange
                    )
                }
                
                if goal.riskLevel == .high || goal.riskLevel == .critical {
                    insightRow(
                        icon: "exclamationmark.triangle",
                        text: "Goal at risk - review dependencies and resources",
                        color: .red
                    )
                }
                
                if goal.onTrackScore > 0.9 {
                    insightRow(
                        icon: "checkmark.circle",
                        text: "On track for early completion",
                        color: .green
                    )
                }
            }
        }
    }
    
    private func insightRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button("View Details") {
                onTap()
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button("Add Milestone") {
                // TODO: Implement milestone creation
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Spacer()
            
            if goal.status == .active || goal.status == .inProgress {
                Button("Mark Complete") {
                    // TODO: Implement goal completion
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
    
    // MARK: - Context Menu
    
    private var goalContextMenu: some View {
        Group {
            Button("View Details") {
                onTap()
            }
            
            Button("Add Milestone") {
                // TODO: Implement milestone creation
            }
            
            Divider()
            
            Button("Edit Goal") {
                // TODO: Implement goal editing
            }
            
            if goal.status != .completed {
                Button("Mark Complete") {
                    // TODO: Implement goal completion
                }
            }
            
            Divider()
            
            Button("Archive Goal") {
                // TODO: Implement goal archiving
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardBackgroundColor: Color {
        if goal.status == .completed {
            return Color.green.opacity(0.05)
        } else if goal.riskLevel == .high || goal.riskLevel == .critical {
            return Color.red.opacity(0.05)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var goalStatusColor: Color {
        switch goal.status {
        case .planning: return .blue
        case .active, .inProgress: return .green
        case .onHold: return .orange
        case .completed: return .green
        case .archived: return .secondary
        }
    }
    
    private var priorityColor: Color {
        switch goal.priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .secondary
        }
    }
    
    private var progressColor: Color {
        if goal.progressPercentage >= 0.8 {
            return .green
        } else if goal.progressPercentage >= 0.5 {
            return .blue
        } else if goal.progressPercentage >= 0.2 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var riskLevelColor: Color {
        switch goal.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
    
    private var onTrackColor: Color {
        if goal.onTrackScore >= 0.8 {
            return .green
        } else if goal.onTrackScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var completedMilestonesCount: Int {
        milestones.filter { $0.isCompleted }.count
    }
    
    private var isLastGoal: Bool {
        // TODO: Determine if this is the last goal in the list
        false
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}


