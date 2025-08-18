//
// PARADataViewModel.swift
// LifeManager
//
// Created by AI Assistant on 2025-08-18
// Copyright © 2025 LifeManager. All rights reserved.
//

import Foundation
import SwiftUI

/// Manages PARA framework data and content relationships
/// Handles Projects, Areas, Resources, Archives and their associated Blobs and Tasks
/// Extracted from MainViewModel for better separation of concerns and data management
@MainActor
class PARADataViewModel: ObservableObject {
    
    // MARK: - PARA Categories
    
    @Published var areas: [Area] = []
    @Published var projects: [Project] = []
    @Published var resources: [Resource] = []
    @Published var archives: [Archive] = []
    @Published var recentBlobs: [Blob] = []
    @Published var focusTasks: [LifeTask] = []
    
    // MARK: - PARA Content (Blobs assigned to categories)
    
    @Published var projectBlobs: [UUID: [Blob]] = [:] // projectId -> blobs
    @Published var areaBlobs: [UUID: [Blob]] = [:] // areaId -> blobs
    @Published var resourceBlobs: [Blob] = []  // All resource-categorized blobs
    @Published var archivedBlobs: [Blob] = [] // All archived blobs
    
    // MARK: - PARA Tasks (Tasks assigned to categories)
    
    @Published var projectTasks: [UUID: [LifeTask]] = [:] // projectId -> tasks
    @Published var areaTasks: [UUID: [LifeTask]] = [:] // areaId -> tasks
    
    // MARK: - Loading State
    
    @Published var isLoadingData = false
    @Published var lastDataRefresh: Date?
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - Data Loading
    
    /// Load all PARA data from database
    func loadAllData() async {
        await MainActor.run {
            isLoadingData = true
        }
        
        logger.info("📊 PARA: Loading all PARA data...")
        
        async let areasTask = loadAreas()
        async let projectsTask = loadProjects()
        async let resourcesTask = loadResources()
        async let archivesTask = loadArchives()
        async let blobsTask = loadRecentBlobs()
        async let tasksTask = loadFocusTasks()
        
        // Wait for all data to load
        await areasTask
        await projectsTask
        await resourcesTask
        await archivesTask
        await blobsTask
        await tasksTask
        
        // Load associated content
        await loadAssociatedContent()
        
        await MainActor.run {
            isLoadingData = false
            lastDataRefresh = Date()
        }
        
        logger.success("📊 PARA: Data loaded")
    }
    
    /// Load areas from database
    private func loadAreas() async {
        do {
            let loadedAreas = try await supabaseService.fetch(Area.self, from: "areas")
            
            await MainActor.run {
                areas = loadedAreas.sorted { $0.name < $1.name }
            }
            
            logger.info("📊 PARA: Loaded \(loadedAreas.count) areas")
            
        } catch {
            logger.error("📊 PARA: Load failed - \(error)")
        }
    }
    
    /// Load projects from database
    private func loadProjects() async {
        do {
            let loadedProjects = try await supabaseService.fetch(Project.self, from: "projects")
            
            await MainActor.run {
                projects = loadedProjects.sorted { $0.name < $1.name }
            }
            
            logger.info("📊 PARA: Loaded \(loadedProjects.count) projects")
            
        } catch {
            logger.error("📊 PARA: Load failed - \(error)")
        }
    }
    
    /// Load resources from database
    private func loadResources() async {
        do {
            let loadedResources = try await supabaseService.fetch(Resource.self, from: "resources")
            
            await MainActor.run {
                resources = loadedResources.sorted { $0.title < $1.title }
            }
            
            logger.info("📊 PARA: Loaded \(loadedResources.count) resources")
            
        } catch {
            logger.error("📊 PARA: Load failed - \(error)")
        }
    }
    
    /// Load archives from database
    private func loadArchives() async {
        do {
            let loadedArchives = try await supabaseService.fetch(Archive.self, from: "archives")
            
            await MainActor.run {
                archives = loadedArchives.sorted { $0.title < $1.title }
            }
            
            logger.info("📊 PARA: Loaded \(loadedArchives.count) archives")
            
        } catch {
            logger.error("📊 PARA: Load failed - \(error)")
        }
    }
    
    /// Load recent blobs
    private func loadRecentBlobs() async {
        let loadedBlobs: [Blob] = [] // TODO: Implement fetchRecentBlobs
        
        await MainActor.run {
            recentBlobs = loadedBlobs
        }
        
        logger.info("📊 PARA: Loaded \(loadedBlobs.count) recent blobs")
    }
    
    /// Load focus tasks
    private func loadFocusTasks() async {
        let loadedTasks: [LifeTask] = [] // TODO: Implement fetchFocusTasks
        
        await MainActor.run {
            focusTasks = loadedTasks
        }
        
        logger.info("📊 PARA: Loaded \(loadedTasks.count) focus tasks")
    }
    
    /// Load associated content for all PARA categories
    private func loadAssociatedContent() async {
        await loadProjectContent()
        await loadAreaContent()
        await loadResourceContent()
        await loadArchivedContent()
    }
    
    /// Load blobs and tasks associated with projects
    private func loadProjectContent() async {
        var newProjectBlobs: [UUID: [Blob]] = [:]
        var newProjectTasks: [UUID: [LifeTask]] = [:]
        
        for project in projects {
            // Load project blobs (placeholder implementation)
            let blobs: [Blob] = [] // TODO: Implement fetchBlobsForProject
            newProjectBlobs[project.id] = blobs
            
            // Load project tasks (placeholder implementation)  
            let tasks: [LifeTask] = [] // TODO: Implement fetchTasksForProject
            newProjectTasks[project.id] = tasks
        }
        
        await MainActor.run {
            projectBlobs = newProjectBlobs
            projectTasks = newProjectTasks
        }
        
        logger.info("📊 PARA: Loaded content for \(projects.count) projects")
    }
    
    /// Load blobs and tasks associated with areas
    private func loadAreaContent() async {
        var newAreaBlobs: [UUID: [Blob]] = [:]
        var newAreaTasks: [UUID: [LifeTask]] = [:]
        
        for area in areas {
            // Load area blobs (placeholder implementation)
            let blobs: [Blob] = [] // TODO: Implement fetchBlobsForArea
            newAreaBlobs[area.id] = blobs
            
            // Load area tasks (placeholder implementation)
            let tasks: [LifeTask] = [] // TODO: Implement fetchTasksForArea
            newAreaTasks[area.id] = tasks
        }
        
        await MainActor.run {
            areaBlobs = newAreaBlobs
            areaTasks = newAreaTasks
        }
        
        logger.info("📊 PARA: Loaded content for \(areas.count) areas")
    }
    
    /// Load resource blobs
    private func loadResourceContent() async {
        let blobs: [Blob] = [] // TODO: Implement fetchBlobsForCategory
        
        await MainActor.run {
            resourceBlobs = blobs
        }
        
        logger.info("📊 PARA: Loaded \(blobs.count) resource blobs")
    }
    
    /// Load archived blobs
    private func loadArchivedContent() async {
        let blobs: [Blob] = [] // TODO: Implement fetchBlobsForCategory
        
        await MainActor.run {
            archivedBlobs = blobs
        }
        
        logger.info("📊 PARA: Loaded \(blobs.count) archived blobs")
    }
    
    // MARK: - Data Refresh
    
    /// Refresh specific category data
    func refreshCategory(_ category: PARACategory) async {
        logger.info("📊 PARA: Refreshing \(category) data...")
        
        switch category {
        case .project:
            await loadProjects()
            await loadProjectContent()
        case .area:
            await loadAreas()
            await loadAreaContent()
        case .resource:
            await loadResources()
            await loadResourceContent()
        case .archive:
            await loadArchives()
            await loadArchivedContent()
        }
        
        await MainActor.run {
            lastDataRefresh = Date()
        }
        
        logger.success("📊 PARA: \(category) data refreshed")
    }
    
    /// Force refresh all data
    func forceRefresh() async {
        logger.info("📊 PARA: Force refreshing all data...")
        await loadAllData()
    }
    
    // MARK: - Data Access Helpers
    
    /// Get blobs for a specific project
    func getBlobs(for project: Project) -> [Blob] {
        return projectBlobs[project.id] ?? []
    }
    
    /// Get tasks for a specific project
    func getTasks(for project: Project) -> [LifeTask] {
        return projectTasks[project.id] ?? []
    }
    
    /// Get blobs for a specific area
    func getBlobs(for area: Area) -> [Blob] {
        return areaBlobs[area.id] ?? []
    }
    
    /// Get tasks for a specific area
    func getTasks(for area: Area) -> [LifeTask] {
        return areaTasks[area.id] ?? []
    }
    
    /// Get total item count for a project
    func getTotalItemCount(for project: Project) -> Int {
        let blobCount = projectBlobs[project.id]?.count ?? 0
        let taskCount = projectTasks[project.id]?.count ?? 0
        return blobCount + taskCount
    }
    
    /// Get total item count for an area
    func getTotalItemCount(for area: Area) -> Int {
        let blobCount = areaBlobs[area.id]?.count ?? 0
        let taskCount = areaTasks[area.id]?.count ?? 0
        return blobCount + taskCount
    }
    
    /// Get all active projects (not completed)
    func getActiveProjects() -> [Project] {
        return projects.filter { $0.status != .completed }
    }
    
    /// Get completed projects
    func getCompletedProjects() -> [Project] {
        return projects.filter { $0.status == .completed }
    }
    
    /// Get overdue tasks across all categories
    func getOverdueTasks() -> [LifeTask] {
        let allTasks = getAllTasks()
        let now = Date()
        
        return allTasks.filter { task in
            guard let dueDateString = task.dueDate,
                  let dueDate = ISO8601DateFormatter().date(from: dueDateString) else { return false }
            return dueDate < now && task.status != .completed
        }
    }
    
    /// Get all tasks across all categories
    private func getAllTasks() -> [LifeTask] {
        var allTasks: [LifeTask] = focusTasks
        
        // Add project tasks
        for tasks in projectTasks.values {
            allTasks.append(contentsOf: tasks)
        }
        
        // Add area tasks
        for tasks in areaTasks.values {
            allTasks.append(contentsOf: tasks)
        }
        
        return allTasks
    }
    
    // MARK: - Statistics
    
    /// Get PARA statistics
    func getStatistics() -> PARAStatistics {
        let totalBlobs = recentBlobs.count + resourceBlobs.count + archivedBlobs.count +
                        projectBlobs.values.flatMap { $0 }.count +
                        areaBlobs.values.flatMap { $0 }.count
        
        let totalTasks = getAllTasks().count
        let completedTasks = getAllTasks().filter { $0.status == .completed }.count
        let overdueTasks = getOverdueTasks().count
        
        return PARAStatistics(
            totalProjects: projects.count,
            activeProjects: getActiveProjects().count,
            totalAreas: areas.count,
            totalResources: resources.count,
            totalArchives: archives.count,
            totalBlobs: totalBlobs,
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
            lastUpdated: lastDataRefresh ?? Date()
        )
    }
}

// MARK: - Supporting Types

struct PARAStatistics {
    let totalProjects: Int
    let activeProjects: Int
    let totalAreas: Int
    let totalResources: Int
    let totalArchives: Int
    let totalBlobs: Int
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let lastUpdated: Date
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}
