//
// AreasView.swift
// LifeManager
//
// Areas view for PARA methodology
// Extracted from ContentView for modularity
//

import SwiftUI

/// Main view for displaying and managing areas
struct AreasView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var searchText = ""
    @State private var showingAddArea = false
    @State private var selectedWorkPersonal: WorkPersonalType? = nil
    
    var filteredAreas: [Area] {
        var areas = viewModel.areas
        
        // Filter by search
        if !searchText.isEmpty {
            areas = areas.filter { area in
                area.name.localizedCaseInsensitiveContains(searchText) ||
                (area.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by work/personal
        if let workPersonal = selectedWorkPersonal {
            areas = areas.filter { $0.workPersonal == workPersonal }
        }
        
        return areas.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            AreasHeaderView(
                searchText: $searchText,
                selectedWorkPersonal: $selectedWorkPersonal,
                showingAddArea: $showingAddArea
            )
            .padding()
            
            Divider()
            
            // Content
            if filteredAreas.isEmpty {
                EmptyAreasView(searchActive: !searchText.isEmpty)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredAreas) { area in
                            AreaCardView(area: area)
                                .environmentObject(viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddArea) {
            AddAreaView()
                .environmentObject(viewModel)
        }
    }
}

/// Header for areas view
struct AreasHeaderView: View {
    @Binding var searchText: String
    @Binding var selectedWorkPersonal: WorkPersonalType?
    @Binding var showingAddArea: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Areas", systemImage: "square.grid.2x2")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingAddArea = true }) {
                    Label("New Area", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search areas...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Work/Personal Filter
                Picker("Type", selection: $selectedWorkPersonal) {
                    Text("All").tag(WorkPersonalType?.none)
                    Text("Work").tag(WorkPersonalType?.some(.work))
                    Text("Personal").tag(WorkPersonalType?.some(.personal))
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
    }
}

/// Card view for individual area
struct AreaCardView: View {
    let area: Area
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isHovered = false
    @State private var isExpanded = false
    
    var taskCount: Int {
        viewModel.areaTasks[area.id]?.count ?? 0
    }
    
    var blobCount: Int {
        viewModel.areaBlobs[area.id]?.count ?? 0
    }
    
    var activeTasks: [LifeTask] {
        viewModel.areaTasks[area.id]?.filter { !$0.isCompleted } ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(area.name)
                        .font(.headline)
                    
                    if let description = area.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Chevron for expansion
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.caption)
                    Text("\(taskCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "doc.stack")
                        .font(.caption)
                    Text("\(blobCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                WorkPersonalBadge(type: area.workPersonal)
            }
            
            // Expanded Content
            if isExpanded && !activeTasks.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    
                    ForEach(activeTasks.prefix(3)) { task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(task.isCompleted ? .green : .secondary)
                            
                            Text(task.title)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let priority = task.priority {
                                PriorityIndicator(priority: priority)
                            }
                        }
                    }
                    
                    if activeTasks.count > 3 {
                        Text("+ \(activeTasks.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            viewModel.selectedArea = area
        }
    }
}

/// Empty state for areas view
struct EmptyAreasView: View {
    let searchActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchActive ? "magnifyingglass" : "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchActive ? "No areas found" : "No areas yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(searchActive ? "Try adjusting your search or filters" : "Create your first area to organize ongoing responsibilities")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Priority indicator for tasks
struct PriorityIndicator: View {
    let priority: Priority
    
    var body: some View {
        Circle()
            .fill(priority.color)
            .frame(width: 6, height: 6)
    }
}