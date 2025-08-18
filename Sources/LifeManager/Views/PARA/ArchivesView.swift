//
// ArchivesView.swift
// LifeManager
//
// Implements: v1.5 "Complete PARA Views", v2.0 "Modular Architecture"  
// Roadmap Reference: v1.5 Advanced Features → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Archive Analytics, Auto-Archiving Rules
//

import SwiftUI

/// Archives view for PARA methodology - Completed and inactive information
/// Features completed task tracking, archive categories, and restore functionality
/// Clean, focused component extracted from monolithic ContentView
struct ArchivesView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var completedTasks: [LifeTask] = []
    @State private var recentlyDeletedTasks: [LifeTask] = []
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private let archiveCategories = [
        "Recently Deleted", "Completed Tasks", "Completed Projects", "Inactive Areas", "Old Resources", 
        "Past Notes", "Outdated References", "Historical Data"
    ]
    
    private var filteredArchives: [Archive] {
        guard let filter = workPersonalFilter else { return viewModel.archives }
        return viewModel.archives.filter { $0.workPersonal == filter }
    }
    
    private var filteredArchivedBlobs: [Blob] {
        guard let filter = workPersonalFilter else { return viewModel.archivedBlobs }
        return viewModel.archivedBlobs.filter { $0.workPersonal == filter }
    }
    
    private var filteredCompletedTasks: [LifeTask] {
        guard let filter = workPersonalFilter else { return completedTasks }
        return completedTasks.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI transparency and Work/Personal toggle
            VStack(spacing: 16) {
                HStack {
                    Text("Archives")
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
                    
                    // Archive stats
                    if !filteredCompletedTasks.isEmpty || !filteredArchivedBlobs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("\(filteredCompletedTasks.count) completed • \(filteredArchivedBlobs.count) archived")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Description
                Text("Completed tasks and archived items from Projects, Areas, and Resources")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            if filteredArchives.isEmpty && filteredArchivedBlobs.isEmpty && filteredCompletedTasks.isEmpty {
                EmptyStateView(
                    title: "No archived items",
                    systemImage: "archivebox",
                    description: "Completed projects and inactive items will appear here"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Formal Archives (created by user/system)
                        if !filteredArchives.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "archivebox")
                                        .foregroundColor(.gray)
                                    Text("Formal Archives")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                ForEach(filteredArchives) { archive in
                                    ArchiveRowView(archive: archive)
                                        .environmentObject(viewModel)
                                }
                            }
                        }
                        
                        // AI-Archived Content by Category
                        if !filteredArchivedBlobs.isEmpty || !filteredCompletedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "brain")
                                        .foregroundColor(.blue)
                                    Text("AI-Archived Content")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                // Group content by inferred category (tasks and blobs)
                                ForEach(archiveCategories, id: \.self) { category in
                                    let categoryBlobs = getArchiveCategoryBlobs(category: category)
                                    let categoryTasks = getArchiveCategoryTasks(category: category)
                                    if !categoryBlobs.isEmpty || !categoryTasks.isEmpty {
                                        ArchiveCategorySection(
                                            category: category,
                                            blobs: categoryBlobs,
                                            tasks: categoryTasks
                                        )
                                        .environmentObject(viewModel)
                                    }
                                }
                                
                                // Uncategorized archived items
                                let uncategorizedBlobs = filteredArchivedBlobs.filter { blob in
                                    !archiveCategories.contains { category in
                                        archiveBlobMatchesCategory(blob: blob, category: category)
                                    }
                                }
                                
                                if !uncategorizedBlobs.isEmpty {
                                    ArchiveCategorySection(
                                        category: "General Archives",
                                        blobs: uncategorizedBlobs,
                                        tasks: []
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
                await loadCompletedTasks()
                await loadRecentlyDeletedTasks()
            }
        }
    }
    
    private func loadCompletedTasks() async {
        do {
            let taskRepository = TaskRepository()
            let completed = try await taskRepository.fetchTasks(status: .completed)
            await MainActor.run {
                self.completedTasks = completed
            }
        } catch {
            print("Failed to load completed tasks: \(error.localizedDescription)")
        }
    }
    
    private func loadRecentlyDeletedTasks() async {
        do {
            let taskRepository = TaskRepository()
            let deleted = try await taskRepository.fetchRecentlyDeletedTasks()
            await MainActor.run {
                self.recentlyDeletedTasks = deleted
            }
        } catch {
            print("Failed to load recently deleted tasks: \(error.localizedDescription)")
        }
    }
    
    private func getArchiveCategoryBlobs(category: String) -> [Blob] {
        return filteredArchivedBlobs.filter { blob in
            archiveBlobMatchesCategory(blob: blob, category: category)
        }
    }
    
    private func getArchiveCategoryTasks(category: String) -> [LifeTask] {
        if category == "Completed Tasks" {
            return filteredCompletedTasks
        }
        return []
    }
    
    private func archiveBlobMatchesCategory(blob: Blob, category: String) -> Bool {
        let content = blob.content.lowercased()
        let createdDateString = blob.createdAt
        
        // Parse the date string to Date object
        let formatter = ISO8601DateFormatter()
        let createdDate = formatter.date(from: createdDateString) ?? Date()
        
        let isOld = Calendar.current.dateInterval(of: .month, for: createdDate)?.start ?? Date() < Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        switch category {
        case "Recently Deleted":
            return false // Tasks are handled separately
        case "Completed Tasks":
            return false // Tasks are handled separately
        case "Completed Projects":
            return content.contains("completed") || content.contains("finished") || content.contains("done")
        case "Inactive Areas":
            return content.contains("stopped") || content.contains("paused") || content.contains("inactive")
        case "Old Resources":
            return isOld && (content.contains("reference") || content.contains("resource"))
        case "Past Notes":
            return isOld && blob.sourceType == .note
        case "Outdated References":
            return isOld && (content.contains("link") || content.contains("url") || content.contains("http"))
        case "Historical Data":
            return isOld
        default:
            return false
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    ArchivesView()
        .environmentObject(MainViewModel())
        .frame(width: 800, height: 600)
}*/
