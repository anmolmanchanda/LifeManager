import SwiftUI

/// Focus Item Row - Individual item in the focus list with AI reasoning and context
struct FocusItemRow: View {
    let item: FocusItem
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void
    
    @State private var isExpanded = false
    @State private var showingContextMenu = false
    @State private var dragOffset = CGSize.zero
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 12) {
                // Completion status / Selection checkbox
                Button(action: {
                    if isSelected {
                        onTap()
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            onTap()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(item.status == .completed ? .green : priorityColor, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if item.status == .completed {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                            
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and priority
                    HStack {
                        // Priority indicator
                        if item.priority != .medium {
                            Text("[\(item.priority.displayName)]")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(priorityColor)
                        }
                        
                        // Title
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(item.status == .completed ? .secondary : .primary)
                            .strikethrough(item.status == .completed)
                        
                        Spacer()
                        
                        // Duration badge
                        if let duration = item.estimatedDuration {
                            DurationBadge(duration: duration)
                        }
                    }
                    
                    // AI reasoning
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "brain")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .frame(width: 12)
                        
                        Text(item.aiReason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }
                    
                    // Context tags row
                    HStack {
                        // Project/Area context
                        if let projectId = item.projectId {
                            ContextTag(
                                icon: "folder",
                                text: "Project", // Would be actual project name
                                color: .blue
                            )
                        }
                        
                        if let areaId = item.areaId {
                            ContextTag(
                                icon: "rectangle.stack",
                                text: "Area", // Would be actual area name
                                color: .green
                            )
                        }
                        
                        // Work/Personal indicator
                        ContextTag(
                            icon: item.workPersonal == .work ? "briefcase" : "house",
                            text: item.workPersonal.rawValue.capitalized,
                            color: item.workPersonal == .work ? .orange : .mint
                        )
                        
                        // Energy level indicator
                        ContextTag(
                            icon: item.energyLevel.icon,
                            text: item.energyLevel.displayName,
                            color: item.energyLevel.color
                        )
                        
                        Spacer()
                        
                        // AI suggestion badge
                        if item.aiReason.contains("AI") || item.priority == .critical {
                            AIBadge()
                        }
                    }
                    
                    // Expanded details
                    if isExpanded {
                        ExpandedDetails(item: item)
                    }
                }
                
                // Actions menu
                Button(action: {
                    showingContextMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(dragOffset)
            .animation(.spring(response: 0.3), value: isExpanded)
            .animation(.spring(response: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            withAnimation(.spring()) {
                onLongPress()
            }
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let threshold: CGFloat = 60
                    
                    if value.translation.x > threshold {
                        // Swipe right - complete
                        withAnimation(.spring()) {
                            onSwipeRight()
                        }
                    } else if value.translation.x < -threshold {
                        // Swipe left - defer
                        withAnimation(.spring()) {
                            onSwipeLeft()
                        }
                    }
                    
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
        )
        .confirmationDialog("Item Actions", isPresented: $showingContextMenu) {
            if item.status != .completed {
                Button("Complete") {
                    onTap()
                }
                
                Button("Defer to Tomorrow") {
                    onSwipeLeft()
                }
                
                Button("Edit Priority") {
                    // TODO: Implement priority editing
                }
                
                Button("Reschedule") {
                    // TODO: Implement rescheduling
                }
            }
            
            Button("View Details") {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var backgroundColor: Color {
        if item.status == .completed {
            return Color(.systemGray6)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if item.status == .completed {
            return Color(.systemGray4)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var priorityColor: Color {
        item.priority.color
    }
}

// MARK: - Supporting Views

struct DurationBadge: View {
    let duration: Int // Minutes
    
    var body: some View {
        Text(durationText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(.systemGray5))
            .cornerRadius(4)
            .foregroundColor(.secondary)
    }
    
    private var durationText: String {
        if duration < 60 {
            return "\(duration)m"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }
}

struct ContextTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct AIBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star")
                .font(.caption2)
                .foregroundColor(.purple)
            
            Text("AI")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.purple)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(4)
    }
}

struct ExpandedDetails: View {
    let item: FocusItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)
            
            // Description if available
            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Additional metadata
            VStack(alignment: .leading, spacing: 4) {
                if let dueDate = item.dueDate {
                    MetadataRow(
                        icon: "calendar",
                        label: "Due",
                        value: formatDueDate(dueDate),
                        color: dueDateColor(dueDate)
                    )
                }
                
                MetadataRow(
                    icon: "speedometer",
                    label: "Complexity",
                    value: item.complexity.displayName,
                    color: .orange
                )
                
                if item.estimatedFocusBlocks > 1 {
                    MetadataRow(
                        icon: "square.stack",
                        label: "Focus Blocks",
                        value: "\(item.estimatedFocusBlocks)",
                        color: .purple
                    )
                }
                
                if item.canBeDoneOffline {
                    MetadataRow(
                        icon: "wifi.slash",
                        label: "Offline",
                        value: "Available",
                        color: .green
                    )
                }
                
                MetadataRow(
                    icon: "clock",
                    label: "Status",
                    value: item.status.displayName,
                    color: statusColor
                )
            }
        }
        .padding(.top, 4)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday (Overdue)"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        if date < Date() {
            return .red
        } else if Calendar.current.isDateInToday(date) {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var statusColor: Color {
        switch item.status {
        case .completed:
            return .green
        case .inProgress:
            return .blue
        case .pending:
            return .orange
        case .deferred:
            return .yellow
        case .cancelled:
            return .red
        }
    }
}

struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 12)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.tertiary)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}

#Preview {
    let sampleItem = FocusItem(
        sourceId: UUID(),
        sourceType: .task,
        title: "Fix critical bug in auth service",
        description: "The authentication service is throwing intermittent errors that need immediate attention",
        estimatedDuration: 120,
        priority: .high,
        urgency: .urgent,
        aiReason: "Due today, matches your morning focus block",
        dueDate: Date(),
        workPersonal: .work,
        projectId: UUID(),
        areaId: UUID(),
        status: .pending,
        energyLevel: .high,
        complexity: .complex,
        canBeDoneOffline: false,
        estimatedFocusBlocks: 3
    )
    
    return VStack(spacing: 16) {
        FocusItemRow(
            item: sampleItem,
            isSelected: false,
            onTap: { },
            onLongPress: { },
            onSwipeRight: { },
            onSwipeLeft: { }
        )
        
        FocusItemRow(
            item: sampleItem,
            isSelected: true,
            onTap: { },
            onLongPress: { },
            onSwipeRight: { },
            onSwipeLeft: { }
        )
    }
    .padding()
}