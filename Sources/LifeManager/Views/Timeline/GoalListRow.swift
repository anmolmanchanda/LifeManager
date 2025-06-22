//
// GoalListRow.swift
// LifeManager
//
// Goal List Row: Compact Goal Display for List View Mode
// Implements: v2.0 Timeline View goal list row with essential information
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Compact goal row for Timeline View list mode
/// Displays essential goal information in a condensed format
struct GoalListRow: View {
    let goal: Goal
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Goal Content
            VStack(alignment: .leading, spacing: 6) {
                // Goal Name and Priority
                HStack {
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if goal.priority == .high || goal.priority == .urgent {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                            Text(goal.priority.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(priorityColor)
                    }
                }
                
                // Description
                if let description = goal.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Progress and Timeline
                HStack(spacing: 16) {
                    // Progress
                    HStack(spacing: 6) {
                        ProgressView(value: goal.progressPercentage)
                            .frame(width: 80)
                        
                        Text("\\(Int(goal.progressPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(progressColor)
                    }
                    
                    Spacer()
                    
                    // Timeline Info
                    timelineInfo
                }
                
                // Tags and Status
                HStack(spacing: 8) {
                    // Status Badge
                    Text(goal.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                    
                    // Category
                    Text(goal.category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                    
                    // Work/Personal
                    Text(goal.workPersonal.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // AI Indicators
                    aiIndicators
                }
            }
            
            // Action Indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1.0 : 0.5)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(rowBackgroundColor)
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            goalContextMenu
        }
    }
    
    // MARK: - Timeline Info
    
    private var timelineInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let targetDate = goal.targetDate {
                Text("Target: \\(DateFormatter.shortDate.string(from: targetDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let predictedDate = goal.predictedCompletionDate,
               predictedDate != goal.targetDate {
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text("\\(DateFormatter.shortDate.string(from: predictedDate))")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    // MARK: - AI Indicators
    
    private var aiIndicators: some View {
        HStack(spacing: 8) {
            if goal.riskLevel != .low {
                HStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(goal.riskLevel.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(riskLevelColor)
            }
            
            if goal.onTrackScore < 0.8 {
                HStack(spacing: 2) {
                    Image(systemName: "gauge")
                        .font(.caption2)
                    Text("\\(Int(goal.onTrackScore * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(onTrackColor)
            }
            
            if goal.velocityTrend == .declining {
                HStack(spacing: 2) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.caption2)
                    Text("Declining")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Context Menu
    
    private var goalContextMenu: some View {
        Group {
            Button("View Details") {
                onTap()
            }
            
            Button("Edit Goal") {
                // TODO: Implement goal editing
            }
            
            Divider()
            
            if goal.status != .completed {
                Button("Mark Complete") {
                    // TODO: Implement goal completion
                }
            }
            
            Button("Add Milestone") {
                // TODO: Implement milestone creation
            }
            
            Divider()
            
            Button("Archive Goal") {
                // TODO: Implement goal archiving
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var rowBackgroundColor: Color {
        if goal.status == .completed {
            return Color.green.opacity(0.05)
        } else if goal.riskLevel == .high || goal.riskLevel == .critical {
            return Color.red.opacity(0.05)
        } else if isHovered {
            return Color.accentColor.opacity(0.05)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var statusColor: Color {
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
}

/* #Preview // DISABLED FOR STABILIZATION
GoalListRow(
    goal: Goal(
        projectId: UUID(),
        name: "Launch Mobile App",
        description: "Complete development and launch of the mobile application with full feature set"
    ),
    onTap: {}
)
.padding()
}*/