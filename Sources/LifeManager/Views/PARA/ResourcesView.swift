//
// ResourcesView.swift
// LifeManager
//
// Implements: v1.5 "Complete PARA Views", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Resource Analytics, Smart Categorization
//

import SwiftUI

/// Resources view for PARA methodology - Reference materials and knowledge assets
/// Features AI-organized categories, work/personal filtering, and statistics
/// Clean, focused component extracted from monolithic ContentView
struct ResourcesView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private let resourceCategories = [
        "Research Papers", "Articles", "Videos", "Books", 
        "Guides", "Recipes", "Insights", "References"
    ]
    
    private var filteredResources: [Resource] {
        guard let filter = workPersonalFilter else { return viewModel.resources }
        return viewModel.resources.filter { $0.workPersonal == filter }
    }
    
    private var filteredResourceBlobs: [Blob] {
        guard let filter = workPersonalFilter else { return viewModel.resourceBlobs }
        return viewModel.resourceBlobs.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI transparency and Work/Personal toggle
            VStack(spacing: 16) {
                HStack {
                    Text("Resources")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Work/Personal filter toggle
                    HStack(spacing: 4) {
                        FilterToggleButton(
                            title: "Personal",
                            isSelected: workPersonalFilter == .personal,
                            action: {
                                workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                            }
                        )
                        
                        FilterToggleButton(
                            title: "Work",
                            isSelected: workPersonalFilter == .work,
                            action: {
                                workPersonalFilter = workPersonalFilter == .work ? nil : .work
                            }
                        )
                    }
                    
                    // AI processing status
                    if !filteredResourceBlobs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            
                            Text("AI organized \(filteredResourceBlobs.count) references")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Quick stats
                if !filteredResources.isEmpty || !filteredResourceBlobs.isEmpty {
                    HStack(spacing: 20) {
                        StatView(
                            title: "Resource Types", 
                            value: "\(filteredResources.count)",
                            color: .purple
                        )
                        StatView(
                            title: "AI References", 
                            value: "\(filteredResourceBlobs.count)",
                            color: .blue
                        )
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            if filteredResources.isEmpty && filteredResourceBlobs.isEmpty {
                EmptyStateView(
                    title: "No resources yet",
                    systemImage: "books.vertical",
                    description: "AI will organize reference materials and knowledge items here"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Formal Resources (created by user/system)
                        if !filteredResources.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "books.vertical")
                                        .foregroundColor(.purple)
                                    Text("Curated Resources")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                ForEach(filteredResources) { resource in
                                    ResourceRowView(resource: resource)
                                        .environmentObject(viewModel)
                                }
                            }
                        }
                        
                        // AI-Organized References by Category
                        if !filteredResourceBlobs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "brain")
                                        .foregroundColor(.blue)
                                    Text("AI-Organized References")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                // Group resource blobs by inferred category
                                ForEach(resourceCategories, id: \.self) { category in
                                    let categoryBlobs = getCategoryBlobs(category: category)
                                    if !categoryBlobs.isEmpty {
                                        ResourceCategorySection(
                                            category: category,
                                            blobs: categoryBlobs
                                        )
                                        .environmentObject(viewModel)
                                    }
                                }
                                
                                // Uncategorized resources
                                let uncategorizedBlobs = filteredResourceBlobs.filter { blob in
                                    !resourceCategories.contains { category in
                                        blobMatchesCategory(blob: blob, category: category)
                                    }
                                }
                                
                                if !uncategorizedBlobs.isEmpty {
                                    ResourceCategorySection(
                                        category: "General References",
                                        blobs: uncategorizedBlobs
                                    )
                                    .environmentObject(viewModel)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    private func getCategoryBlobs(category: String) -> [Blob] {
        return filteredResourceBlobs.filter { blob in
            blobMatchesCategory(blob: blob, category: category)
        }
    }
    
    private func blobMatchesCategory(blob: Blob, category: String) -> Bool {
        let content = blob.content.lowercased()
        switch category {
        case "Research Papers":
            return content.contains("research") || content.contains("paper") || content.contains("study")
        case "Articles":
            return content.contains("article") || content.contains("blog") || content.contains("post")
        case "Videos":
            return content.contains("video") || content.contains("youtube") || content.contains("watch")
        case "Books":
            return content.contains("book") || content.contains("read") || content.contains("chapter")
        case "Guides":
            return content.contains("guide") || content.contains("tutorial") || content.contains("how to")
        case "Recipes":
            return content.contains("recipe") || content.contains("cook") || content.contains("ingredient")
        case "Insights":
            return content.contains("insight") || content.contains("learning") || content.contains("takeaway")
        case "References":
            return content.contains("reference") || content.contains("link") || content.contains("source")
        default:
            return false
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    ResourcesView()
        .environmentObject(MainViewModel())
        .frame(width: 800, height: 600)
}*/
