//
// MindMapView.swift
// LifeManager
//
// Implements: v1.5 "Timeline & Mind Map", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ✅ IMPLEMENTED June 19, 2025 (visual mind mapping with connections)
// Future: v2.5 Interactive Mind Maps, AI-Generated Connections
//

import SwiftUI

/// Mind map view for visual representation of connections between ideas
/// Clean navigation component with interactive node visualization
struct MindMapView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var selectedCategory: MindMapCategory = .all
    @State private var mindMapNodes: [MindMapNode] = []
    @State private var connections: [MindMapConnection] = []
    @State private var selectedNode: MindMapNode?
    @State private var dragOffset = CGSize.zero
    
    enum MindMapCategory: String, CaseIterable {
        case all = "All"
        case projects = "Projects"
        case areas = "Areas"
        case resources = "Resources"
        case tasks = "Tasks"
        
        var color: Color {
            switch self {
            case .all: return .primary
            case .projects: return .blue
            case .areas: return .green
            case .resources: return .orange
            case .tasks: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "circle.grid.cross"
            case .projects: return "folder"
            case .areas: return "square.stack.3d.up"
            case .resources: return "book"
            case .tasks: return "checkmark.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Mind Map")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Visual connections between ideas and concepts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MindMapCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                    Text(category.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? category.color : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
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
            
            // Mind Map Canvas
            if mindMapNodes.isEmpty {
                EmptyStateView(
                    title: "No connections to display",
                    systemImage: "brain.head.profile",
                    description: "Add projects, areas, and tasks to see their relationships"
                )
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // Background
                        Color(NSColor.controlBackgroundColor)
                            .opacity(0.3)
                        
                        // Connections
                        ForEach(connections) { connection in
                            MindMapConnectionView(connection: connection, nodes: mindMapNodes)
                        }
                        
                        // Nodes
                        ForEach(mindMapNodes) { node in
                            MindMapNodeView(
                                node: node,
                                isSelected: selectedNode?.id == node.id,
                                onTap: { selectedNode = selectedNode?.id == node.id ? nil : node }
                            )
                            .position(node.position)
                        }
                    }
                    .clipped()
                    .onAppear {
                        layoutNodes(in: geometry.size)
                    }
                }
            }
        }
        .onAppear {
            generateMindMapData()
        }
        .onChange(of: selectedCategory) { _ in
            generateMindMapData()
        }
    }

    
    private func generateMindMapData() {
        var nodes: [MindMapNode] = []
        var nodeConnections: [MindMapConnection] = []
        
        // Generate nodes based on selected category
        switch selectedCategory {
        case .all, .projects:
            for project in viewModel.projects {
                nodes.append(MindMapNode(
                    id: project.id,
                    title: project.name,
                    subtitle: project.description ?? "",
                    category: .projects,
                    size: .large,
                    position: .zero
                ))
            }
            
        case .areas:
            for area in viewModel.areas {
                nodes.append(MindMapNode(
                    id: area.id,
                    title: area.name,
                    subtitle: area.description ?? "",
                    category: .areas,
                    size: .large,
                    position: .zero
                ))
            }
            
        case .resources:
            for resource in viewModel.resources.prefix(20) {
                nodes.append(MindMapNode(
                    id: resource.id,
                    title: resource.title,
                    subtitle: String((resource.summary ?? "No summary").prefix(50)),
                    category: .resources,
                    size: .medium,
                    position: .zero
                ))
            }
            
        case .tasks:
            let allTasks = Array((viewModel.projectTasks.values.flatMap { $0 } + 
                                viewModel.areaTasks.values.flatMap { $0 } +
                                viewModel.focusTasks).prefix(25))
            
            for task in allTasks {
                nodes.append(MindMapNode(
                    id: task.id,
                    title: task.title,
                    subtitle: task.description ?? "No description",
                    category: .tasks,
                    size: task.priority == .high || task.priority == .urgent ? .medium : .small,
                    position: .zero
                ))
            }
        }
        
        // Generate connections based on relationships
        if selectedCategory == .all {
            // Connect projects to their tasks
            for (projectId, tasks) in viewModel.projectTasks {
                if let projectNode = nodes.first(where: { $0.id == projectId }) {
                    for task in tasks.prefix(5) {
                        if let taskNode = nodes.first(where: { $0.id == task.id }) {
                            nodeConnections.append(MindMapConnection(
                                id: UUID(),
                                fromId: projectNode.id,
                                toId: taskNode.id,
                                type: .hierarchy,
                                strength: 0.8
                            ))
                        }
                    }
                }
            }
            
            // Connect areas to their tasks
            for (areaId, tasks) in viewModel.areaTasks {
                if let areaNode = nodes.first(where: { $0.id == areaId }) {
                    for task in tasks.prefix(3) {
                        if let taskNode = nodes.first(where: { $0.id == task.id }) {
                            nodeConnections.append(MindMapConnection(
                                id: UUID(),
                                fromId: areaNode.id,
                                toId: taskNode.id,
                                type: .association,
                                strength: 0.6
                            ))
                        }
                    }
                }
            }
        }
        
        mindMapNodes = nodes
        connections = nodeConnections
    }
    
    private func layoutNodes(in size: CGSize) {
        guard !mindMapNodes.isEmpty else { return }
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = min(size.width, size.height) * 0.3
        
        // Use circular layout for simplicity
        for (index, _) in mindMapNodes.enumerated() {
            let angle = (Double(index) / Double(mindMapNodes.count)) * 2 * .pi
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            
            mindMapNodes[index].position = CGPoint(x: x, y: y)
        }
    }
}

struct MindMapNode: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let category: MindMapView.MindMapCategory
    let size: NodeSize
    var position: CGPoint
    
    enum NodeSize {
        case small, medium, large
        
        var radius: CGFloat {
            switch self {
            case .small: return 25
            case .medium: return 35
            case .large: return 45
            }
        }
    }
}

struct MindMapConnection: Identifiable {
    let id: UUID
    let fromId: UUID
    let toId: UUID
    let type: ConnectionType
    let strength: Double
    
    enum ConnectionType {
        case hierarchy, association, similarity
        
        var color: Color {
            switch self {
            case .hierarchy: return .blue
            case .association: return .green
            case .similarity: return .orange
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .hierarchy: return 3
            case .association: return 2
            case .similarity: return 1.5
            }
        }
    }
}

struct MindMapNodeView: View {
    let node: MindMapNode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(node.category.color)
                .frame(width: node.size.radius * 2, height: node.size.radius * 2)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Image(systemName: node.category.icon)
                        .font(.system(size: node.size.radius * 0.6))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 2) {
                Text(node.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: node.size.radius * 3)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct MindMapConnectionView: View {
    let connection: MindMapConnection
    let nodes: [MindMapNode]
    
    var body: some View {
        if let fromNode = nodes.first(where: { $0.id == connection.fromId }),
           let toNode = nodes.first(where: { $0.id == connection.toId }) {
            
            Path { path in
                path.move(to: fromNode.position)
                path.addLine(to: toNode.position)
            }
            .stroke(
                connection.type.color.opacity(connection.strength),
                lineWidth: connection.type.lineWidth
            )
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    MindMapView()
        .environmentObject(MainViewModel())
}*/
