//
// TimelineView.swift
// LifeManager
//
// Implements: v1.5 "Timeline & Mind Map", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ✅ IMPLEMENTED June 19, 2025 (chronological timeline with timeframe filtering)
// Future: v2.5 Interactive Timeline, Gantt Integration
//

import SwiftUI

/// Timeline view for chronological display of tasks and events
/// Clean navigation component extracted from monolithic ContentView
struct TimelineView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedTimeframe: TimeFrame = .today
    @State private var timelineItems: [TimelineItem] = []
    
    enum TimeFrame: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var icon: String {
            switch self {
            case .today: return "calendar"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar.circle"
            case .all: return "timeline.selection"
            }
        }
    }
    
    struct TimelineItem: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let type: String
        let category: String
        let timestamp: Date
        let isCompleted: Bool
        let priority: TaskPriority
        
        var displayTime: String {
            let formatter = DateFormatter()
            if Calendar.current.isDateInToday(timestamp) {
                formatter.timeStyle = .short
                return formatter.string(from: timestamp)
            } else if Calendar.current.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
                formatter.dateFormat = "EEEE, h:mm a"
                return formatter.string(from: timestamp)
            } else {
                formatter.dateFormat = "MMM d, h:mm a"
                return formatter.string(from: timestamp)
            }
        }
        
        var timelineColor: Color {
            switch priority {
            case .high, .urgent: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Timeline")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Chronological view of tasks and events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Timeframe Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            Button(action: { selectedTimeframe = timeframe }) {
                                HStack(spacing: 4) {
                                    Image(systemName: timeframe.icon)
                                        .font(.caption)
                                    Text(timeframe.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTimeframe == timeframe ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Timeline Content
            if timelineItems.isEmpty {
                EmptyStateView(
                    title: "No items in timeline",
                    systemImage: "timeline.selection",
                    description: "Tasks and events will appear here based on your selected timeframe"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(timelineItems) { item in
                            TimelineItemRow(item: item)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .onAppear {
            loadTimelineItems()
        }
        .onChange(of: selectedTimeframe) { _ in
            loadTimelineItems()
        }
    }
    
    private func loadTimelineItems() {
        var items: [TimelineItem] = []
        let now = Date()
        let calendar = Calendar.current
        
        // Collect tasks from all categories
        let allTasks = viewModel.projectTasks.values.flatMap { $0 } + 
                      viewModel.areaTasks.values.flatMap { $0 } +
                      viewModel.focusTasks
        
        for task in allTasks {
            let shouldInclude: Bool
            
            let taskUpdatedDate = ISO8601DateFormatter().date(from: task.updatedAt) ?? now
            let taskDueDate = task.dueDate != nil ? ISO8601DateFormatter().date(from: task.dueDate!) : nil
            
            switch selectedTimeframe {
            case .today:
                shouldInclude = calendar.isDateInToday(taskUpdatedDate) || 
                               (taskDueDate != nil && calendar.isDateInToday(taskDueDate!))
            case .week:
                shouldInclude = calendar.isDate(taskUpdatedDate, equalTo: now, toGranularity: .weekOfYear) ||
                               (taskDueDate != nil && calendar.isDate(taskDueDate!, equalTo: now, toGranularity: .weekOfYear))
            case .month:
                shouldInclude = calendar.isDate(taskUpdatedDate, equalTo: now, toGranularity: .month) ||
                               (taskDueDate != nil && calendar.isDate(taskDueDate!, equalTo: now, toGranularity: .month))
            case .all:
                shouldInclude = true
            }
            
            if shouldInclude {
                let category = determineTaskCategory(task)
                let timestamp = taskDueDate ?? taskUpdatedDate
                
                items.append(TimelineItem(
                    title: task.title,
                    content: task.description ?? "No description",
                    type: "Task",
                    category: category,
                    timestamp: timestamp,
                    isCompleted: task.status == .completed,
                    priority: task.priority
                ))
            }
        }
        
        // Add recent projects
        for project in viewModel.projects {
            let shouldInclude: Bool
            let projectDate = ISO8601DateFormatter().date(from: project.updatedAt) ?? now
            
            switch selectedTimeframe {
            case .today:
                shouldInclude = calendar.isDateInToday(projectDate)
            case .week:
                shouldInclude = calendar.isDate(projectDate, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                shouldInclude = calendar.isDate(projectDate, equalTo: now, toGranularity: .month)
            case .all:
                shouldInclude = true
            }
            
            if shouldInclude {
                items.append(TimelineItem(
                    title: project.name,
                    content: project.description ?? "No description",
                    type: "Project",
                    category: "Projects",
                    timestamp: projectDate,
                    isCompleted: project.status == .completed,
                    priority: .medium
                ))
            }
        }
        
        // Sort by timestamp (most recent first)
        timelineItems = items.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func determineTaskCategory(_ task: LifeTask) -> String {
        // Try to find which category this task belongs to
        for (projectId, tasks) in viewModel.projectTasks {
            if tasks.contains(where: { $0.id == task.id }) {
                if let project = viewModel.projects.first(where: { $0.id == projectId }) {
                    return project.name
                }
                return "Projects"
            }
        }
        
        for (areaId, tasks) in viewModel.areaTasks {
            if tasks.contains(where: { $0.id == task.id }) {
                if let area = viewModel.areas.first(where: { $0.id == areaId }) {
                    return area.name
                }
                return "Areas"
            }
        }
        
        if viewModel.focusTasks.contains(where: { $0.id == task.id }) {
            return "Focus"
        }
        
        return "Tasks"
    }
}

struct TimelineItemRow: View {
    let item: TimelineView.TimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(item.timelineColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(NSColor.windowBackgroundColor), lineWidth: 3)
                    )
                
                if true { // Always show line for now
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.displayTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.type)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(item.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(item.category)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 4)
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    TimelineView()
        .environmentObject(MainViewModel())
}*/
