//
// PARAManagementViewModel.swift
// LifeManager
//
// Manages PARA methodology state and operations
// Extracted from MainViewModel to follow single responsibility principle
//

import Foundation
import SwiftUI
import Combine

/// Manages PARA (Projects, Areas, Resources, Archives) state and operations
@MainActor
class PARAManagementViewModel: ObservableObject {
    
    // MARK: - PARA Collections
    
    @Published var projects: [Project] = []
    @Published var areas: [Area] = []
    @Published var resources: [Resource] = []
    @Published var archives: [Archive] = []
    
    // MARK: - Selection State
    
    @Published var selectedProject: Project?
    @Published var selectedArea: Area?
    @Published var selectedResource: Resource?
    @Published var selectedArchive: Archive?
    @Published var selectedView: PARAView = .projects
    
    // MARK: - Associated Data
    
    @Published var projectTasks: [UUID: [LifeTask]] = [:]
    @Published var areaTasks: [UUID: [LifeTask]] = [:]
    @Published var projectBlobs: [UUID: [Blob]] = [:]
    @Published var areaBlobs: [UUID: [Blob]] = [:]
    @Published var resourceBlobs: [Blob] = []
    @Published var archivedBlobs: [Blob] = []
    
    // MARK: - UI State
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var filteredProjects: [Project] = []
    @Published var filteredAreas: [Area] = []
    
    // MARK: - Statistics
    
    @Published var projectStats: ProjectStatistics?
    @Published var areaStats: AreaStatistics?
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let contextMemoryCoordinator = ContextMemoryCoordinator.shared
    private let logger = Logger.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupSearchFilter()
        Task {
            await loadAllPARAData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadAllPARAData() async {
        isLoading = true
        
        do {
            async let projectsData = loadProjects()
            async let areasData = loadAreas()
            async let resourcesData = loadResources()
            async let archivesData = loadArchives()
            
            let (p, a, r, ar) = await (projectsData, areasData, resourcesData, archivesData)
            
            projects = p
            areas = a
            resources = r
            archives = ar
            
            // Load associated data
            await loadAssociatedData()
            
            // Update statistics
            updateStatistics()
            
            logger.info("PARA: Loaded \(projects.count) projects, \(areas.count) areas")
            
        } catch {
            logger.error("PARA: Failed to load data: \(error)")
            errorMessage = "Failed to load PARA data"
        }
        
        isLoading = false
    }
    
    private func loadProjects() async -> [Project] {
        do {
            return try await supabaseService.fetch(Project.self, from: "projects")
        } catch {
            logger.error("PARA: Failed to load projects: \(error)")
            return []
        }
    }
    
    private func loadAreas() async -> [Area] {
        do {
            return try await supabaseService.fetch(Area.self, from: "areas")
        } catch {
            logger.error("PARA: Failed to load areas: \(error)")
            return []
        }
    }
    
    private func loadResources() async -> [Resource] {
        do {
            return try await supabaseService.fetch(Resource.self, from: "resources")
        } catch {
            logger.error("PARA: Failed to load resources: \(error)")
            return []
        }
    }
    
    private func loadArchives() async -> [Archive] {
        do {
            return try await supabaseService.fetch(Archive.self, from: "archives")
        } catch {
            logger.error("PARA: Failed to load archives: \(error)")
            return []
        }
    }
    
    private func loadAssociatedData() async {
        // Load tasks for each project
        for project in projects {
            if let tasks = try? await supabaseService.fetchTasks(for: project.id) {
                projectTasks[project.id] = tasks
            }
        }
        
        // Load tasks for each area
        for area in areas {
            if let tasks = try? await supabaseService.fetchTasks(for: area.id) {
                areaTasks[area.id] = tasks
            }
        }
        
        // Load blobs
        await loadBlobs()
    }
    
    private func loadBlobs() async {
        do {
            let allBlobs = try await supabaseService.fetch(Blob.self, from: "blobs")
            
            // Categorize blobs
            for blob in allBlobs {
                switch blob.category {
                case .project:
                    if let projectId = blob.projectId {
                        projectBlobs[projectId, default: []].append(blob)
                    }
                case .area:
                    if let areaId = blob.areaId {
                        areaBlobs[areaId, default: []].append(blob)
                    }
                case .resource:
                    resourceBlobs.append(blob)
                case .archive:
                    archivedBlobs.append(blob)
                default:
                    break
                }
            }
        } catch {
            logger.error("PARA: Failed to load blobs: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func createProject(_ project: Project) async throws {
        let saved = try await supabaseService.insert(project, into: "projects")
        projects.append(saved)
        updateStatistics()
        
        // Add to context memory
        await contextMemoryCoordinator.addProject(saved)
    }
    
    func updateProject(_ project: Project) async throws {
        let updated = try await supabaseService.update(project, in: "projects")
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = updated
        }
        updateStatistics()
    }
    
    func archiveProject(_ project: Project) async throws {
        var archived = project
        archived.status = .archived
        archived.archivedAt = Date()
        
        try await updateProject(archived)
        
        // Move to archives
        let archive = Archive(
            id: UUID(),
            title: project.name,
            content: project.description ?? "",
            category: .project,
            originalId: project.id,
            archivedAt: Date(),
            metadata: ["originalProject": project]
        )
        
        try await supabaseService.insert(archive, into: "archives")
        archives.append(archive)
    }
    
    func deleteProject(_ project: Project) async throws {
        try await supabaseService.delete(project.id, from: "projects")
        projects.removeAll { $0.id == project.id }
        projectTasks.removeValue(forKey: project.id)
        projectBlobs.removeValue(forKey: project.id)
        updateStatistics()
    }
    
    func createArea(_ area: Area) async throws {
        let saved = try await supabaseService.insert(area, into: "areas")
        areas.append(saved)
        updateStatistics()
    }
    
    func updateArea(_ area: Area) async throws {
        let updated = try await supabaseService.update(area, in: "areas")
        if let index = areas.firstIndex(where: { $0.id == area.id }) {
            areas[index] = updated
        }
        updateStatistics()
    }
    
    func deleteArea(_ area: Area) async throws {
        try await supabaseService.delete(area.id, from: "areas")
        areas.removeAll { $0.id == area.id }
        areaTasks.removeValue(forKey: area.id)
        areaBlobs.removeValue(forKey: area.id)
        updateStatistics()
    }
    
    // MARK: - Task Management
    
    func moveTaskToProject(_ task: LifeTask, project: Project) async throws {
        var updatedTask = task
        updatedTask.projectId = project.id
        updatedTask.areaId = nil
        
        let saved = try await supabaseService.update(updatedTask, in: "tasks")
        
        // Update local state
        projectTasks[project.id, default: []].append(saved)
        
        // Remove from previous location
        for (areaId, tasks) in areaTasks {
            if tasks.contains(where: { $0.id == task.id }) {
                areaTasks[areaId]?.removeAll { $0.id == task.id }
            }
        }
    }
    
    func moveTaskToArea(_ task: LifeTask, area: Area) async throws {
        var updatedTask = task
        updatedTask.areaId = area.id
        updatedTask.projectId = nil
        
        let saved = try await supabaseService.update(updatedTask, in: "tasks")
        
        // Update local state
        areaTasks[area.id, default: []].append(saved)
        
        // Remove from previous location
        for (projectId, tasks) in projectTasks {
            if tasks.contains(where: { $0.id == task.id }) {
                projectTasks[projectId]?.removeAll { $0.id == task.id }
            }
        }
    }
    
    // MARK: - Search and Filter
    
    private func setupSearchFilter() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.filterContent(text)
            }
            .store(in: &cancellables)
    }
    
    private func filterContent(_ searchText: String) {
        if searchText.isEmpty {
            filteredProjects = projects
            filteredAreas = areas
        } else {
            let lowercased = searchText.lowercased()
            
            filteredProjects = projects.filter { project in
                project.name.lowercased().contains(lowercased) ||
                (project.description?.lowercased().contains(lowercased) ?? false)
            }
            
            filteredAreas = areas.filter { area in
                area.name.lowercased().contains(lowercased) ||
                (area.description?.lowercased().contains(lowercased) ?? false)
            }
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        projectStats = ProjectStatistics(
            total: projects.count,
            active: projects.filter { $0.status == .active }.count,
            onHold: projects.filter { $0.status == .onHold }.count,
            completed: projects.filter { $0.status == .completed }.count,
            totalTasks: projectTasks.values.flatMap { $0 }.count
        )
        
        areaStats = AreaStatistics(
            total: areas.count,
            withTasks: areas.filter { areaTasks[$0.id]?.isEmpty == false }.count,
            totalTasks: areaTasks.values.flatMap { $0 }.count
        )
    }
    
    // MARK: - Navigation
    
    func selectProject(_ project: Project?) {
        selectedProject = project
        selectedArea = nil
        selectedResource = nil
        selectedArchive = nil
        
        if project != nil {
            selectedView = .projects
        }
    }
    
    func selectArea(_ area: Area?) {
        selectedArea = area
        selectedProject = nil
        selectedResource = nil
        selectedArchive = nil
        
        if area != nil {
            selectedView = .areas
        }
    }
    
    func navigateTo(_ view: PARAView) {
        selectedView = view
    }
}

// MARK: - Supporting Types

// PARAView enum is defined in CoreModels.swift
// Using the shared definition to avoid duplication

struct ProjectStatistics {
    let total: Int
    let active: Int
    let onHold: Int
    let completed: Int
    let totalTasks: Int
}

struct AreaStatistics {
    let total: Int
    let withTasks: Int
    let totalTasks: Int
}