//
// SearchView.swift
// LifeManager
//
// Implements: v1.5 "Search System", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ✅ IMPLEMENTED June 19, 2025 (comprehensive search with category filtering)
// Future: v2.5 Semantic Search, AI-Powered Query Enhancement
//

import SwiftUI

/// Search view for finding content across all PARA categories
/// Clean navigation component extracted from monolithic ContentView
struct SearchView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    
    enum SearchCategory: String, CaseIterable {
        case all = "All"
        case projects = "Projects"
        case areas = "Areas"
        case resources = "Resources"
        case tasks = "Tasks"
        case notes = "Notes"
        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .projects: return "folder"
            case .areas: return "square.stack.3d.up"
            case .resources: return "book"
            case .tasks: return "checkmark.circle"
            case .notes: return "note.text"
            }
        }
    }
    
    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let category: SearchCategory
        let type: String
        let lastModified: Date
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Search")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search across all categories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
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
                                .background(selectedCategory == category ? Color.accentColor : Color(NSColor.controlBackgroundColor))
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
            
            // Results
            if isSearching {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                EmptyStateView(
                    title: "Start searching",
                    systemImage: "magnifyingglass",
                    description: "Enter text above to search across all your PARA content"
                )
            } else if searchResults.isEmpty {
                EmptyStateView(
                    title: "No results found",
                    systemImage: "magnifyingglass",
                    description: "Try adjusting your search terms or category filter"
                )
            } else {
                List(searchResults) { result in
                    SearchResultRow(result: result)
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: searchText) { _ in
            if searchText.count >= 2 {
                performSearch()
            } else if searchText.isEmpty {
                searchResults = []
            }
        }
        .onChange(of: selectedCategory) { _ in
            if !searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private func performSearch() {
        isSearching = true
        
        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            searchResults = mockSearchResults()
            isSearching = false
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchResults = []
        selectedCategory = .all
    }
    
    private func mockSearchResults() -> [SearchResult] {
        let query = searchText.lowercased()
        var results: [SearchResult] = []
        
        // Search in projects
        if selectedCategory == .all || selectedCategory == .projects {
            for project in viewModel.projects {
                if project.name.lowercased().contains(query) || 
                   (project.description?.lowercased().contains(query) ?? false) {
                    results.append(SearchResult(
                        title: project.name,
                        content: project.description ?? "No description",
                        category: .projects,
                        type: "Project",
                        lastModified: ISO8601DateFormatter().date(from: project.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Search in areas
        if selectedCategory == .all || selectedCategory == .areas {
            for area in viewModel.areas {
                if area.name.lowercased().contains(query) ||
                   (area.description?.lowercased().contains(query) ?? false) {
                    results.append(SearchResult(
                        title: area.name,
                        content: area.description ?? "No description",
                        category: .areas,
                        type: "Area",
                        lastModified: ISO8601DateFormatter().date(from: area.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Search in resources
        if selectedCategory == .all || selectedCategory == .resources {
            for resource in viewModel.resources {
                if resource.title.lowercased().contains(query) ||
                   (resource.summary?.lowercased().contains(query) ?? false) {
                    results.append(SearchResult(
                        title: resource.title,
                        content: resource.summary ?? "No summary",
                        category: .resources,
                        type: "Resource",
                        lastModified: ISO8601DateFormatter().date(from: resource.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Search in tasks
        if selectedCategory == .all || selectedCategory == .tasks {
            let allTasks = viewModel.projectTasks.values.flatMap { $0 } + 
                          viewModel.areaTasks.values.flatMap { $0 } +
                          viewModel.focusTasks
            
            for task in allTasks {
                if task.title.lowercased().contains(query) ||
                   (task.description?.lowercased().contains(query) ?? false) {
                    results.append(SearchResult(
                        title: task.title,
                        content: task.description ?? "No description",
                        category: .tasks,
                        type: "Task",
                        lastModified: ISO8601DateFormatter().date(from: task.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Sort by relevance (exact matches first, then by modification date)
        return results.sorted { first, second in
            let firstExact = first.title.lowercased() == query
            let secondExact = second.title.lowercased() == query
            
            if firstExact && !secondExact {
                return true
            } else if !firstExact && secondExact {
                return false
            } else {
                return first.lastModified > second.lastModified
            }
        }
    }
}

struct SearchResultRow: View {
    let result: SearchView.SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.category.icon)
                    .foregroundColor(.accentColor)
                    .font(.caption)
                
                Text(result.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Text(result.lastModified, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(result.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(result.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    SearchView()
        .environmentObject(MainViewModel())
}*/
