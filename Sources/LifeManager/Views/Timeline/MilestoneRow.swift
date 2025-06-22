//
// MilestoneRow.swift
// LifeManager
//
// Milestone Row: Interactive Milestone Display and Management
// Implements: v2.0 Timeline View milestone component with progress tracking
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Interactive milestone row with completion checkbox and progress indicators
/// Used within GoalTimelineCard for milestone management
struct MilestoneRow: View {
    let milestone: Milestone
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Checkbox
            Button(action: onToggle) {
                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(milestone.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Milestone Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(milestone.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(milestone.isCompleted)
                        .foregroundColor(milestone.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    // Due Date
                    if let dueDate = milestone.dueDate {
                        Text(DateFormatter.shortDate.string(from: dueDate))
                            .font(.caption)
                            .foregroundColor(isOverdue ? .red : .secondary)
                    }
                }
                
                // Description
                if let description = milestone.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Progress Indicator (if applicable)
                if let progress = milestone.progressPercentage, progress > 0 && !milestone.isCompleted {
                    progressBar(progress: progress)
                }
            }
            
            // Status Indicators
            VStack(spacing: 4) {
                if milestone.isBlocked {
                    Image(systemName: "lock.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if isOverdue && !milestone.isCompleted {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if milestone.priority == .high || milestone.priority == .urgent {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(milestoneBackgroundColor)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            milestoneContextMenu
        }
    }
    
    // MARK: - Progress Bar
    
    private func progressBar(progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 4)
                
                // Progress Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Context Menu
    
    private var milestoneContextMenu: some View {
        Group {
            if !milestone.isCompleted {
                Button("Mark Complete") {
                    onToggle()
                }
            } else {
                Button("Mark Incomplete") {
                    onToggle()
                }
            }
            
            Divider()
            
            Button("Edit Milestone") {
                // TODO: Implement milestone editing
            }
            
            Button("Add Sub-milestone") {
                // TODO: Implement sub-milestone creation
            }
            
            Divider()
            
            Button("Delete Milestone") {
                // TODO: Implement milestone deletion
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isOverdue: Bool {
        guard let dueDate = milestone.dueDate else { return false }
        return !milestone.isCompleted && dueDate < Date()
    }
    
    private var milestoneBackgroundColor: Color {
        if milestone.isCompleted {
            return Color.green.opacity(0.1)
        } else if isOverdue {
            return Color.red.opacity(0.1)
        } else if isHovered {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}