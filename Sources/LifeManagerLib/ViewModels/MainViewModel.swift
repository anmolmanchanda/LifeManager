import Foundation
import SwiftUI

/// Main view model for LifeManager app
/// Manages authentication, navigation, and overall app state
@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Services
    
    private let supabaseService = SupabaseService.shared
    private let llmService = LLMService.shared
    
    // MARK: - Authentication State
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    
    // MARK: - Navigation State
    
    @Published var selectedSidebarItem: SidebarItem = .inbox
    @Published var searchText = ""
    @Published var isSearching = false
    
    // MARK: - PARA Data
    
    @Published var areas: [Area] = []
    @Published var projects: [Project] = []
    @Published var recentBlobs: [Blob] = []
    @Published var focusTasks: [Task] = []
    
    // MARK: - UI State
    
    @Published var showingAddContent = false
    @Published var showingSettings = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    init() {
        setupAuthListener()
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Authentication
    
    private func setupAuthListener() {
        // Listen for authentication state changes
        Task {
            for await authState in supabaseService.$isAuthenticated.values {
                self.isAuthenticated = authState
                self.currentUser = supabaseService.currentUser
                
                if authState {
                    await loadUserData()
                } else {
                    clearUserData()
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        
        do {
            _ = try await supabaseService.signIn(email: email, password: password)
        } catch {
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInWithMagicLink(email: String) async {
        isLoading = true
        authError = nil
        
        do {
            try await supabaseService.signInWithMagicLink(email: email)
            authError = "Check your email for the sign-in link"
        } catch {
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabaseService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        if supabaseService.isAuthenticated {
            await loadUserData()
        }
    }
    
    private func loadUserData() async {
        do {
            async let areasTask = AreaRepository().fetchAllAreas()
            async let projectsTask = ProjectRepository().fetchAllProjects()
            async let blobsTask = BlobRepository().fetchRecentBlobs(limit: 10)
            async let focusTasksTask = TaskRepository().fetchFocusTasks()
            
            self.areas = try await areasTask
            self.projects = try await projectsTask
            self.recentBlobs = try await blobsTask
            self.focusTasks = try await focusTasksTask
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }
    
    private func clearUserData() {
        areas = []
        projects = []
        recentBlobs = []
        focusTasks = []
    }
    
    // MARK: - Search
    
    func search(query: String) async {
        guard !query.isEmpty else { return }
        
        isSearching = true
        
        do {
            let searchResults = try await supabaseService.searchAll(query: query)
            // Handle search results - could update a published searchResults property
            print("Search found: \(searchResults.blobs.count) blobs, \(searchResults.tasks.count) tasks, \(searchResults.resources.count) resources")
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    // MARK: - Quick Actions
    
    func addQuickNote(_ content: String) async {
        guard !content.isEmpty else { return }
        
        do {
            // Create blob
            let blob = Blob(
                content: content,
                sourceType: .note,
                workPersonal: .personal
            )
            
            let savedBlob = try await supabaseService.insert(blob, into: SupabaseService.TableName.blobs)
            
            // Process with LLM
            let processingResult = try await llmService.processNaturalLanguage(
                input: content,
                sourceType: .note,
                availableAreas: areas,
                availableProjects: projects
            )
            
            // Create suggested tasks if any
            if !processingResult.actionableTasks.isEmpty {
                for taskTitle in processingResult.actionableTasks {
                    let task = Task(
                        blobId: savedBlob.id,
                        title: taskTitle,
                        priority: processingResult.priority,
                        workPersonal: processingResult.workPersonal
                    )
                    
                    _ = try await supabaseService.insert(task, into: SupabaseService.TableName.tasks)
                }
            }
            
            // Refresh data
            await loadUserData()
            
        } catch {
            errorMessage = "Failed to add note: \(error.localizedDescription)"
        }
    }
    
    func refreshData() async {
        await loadUserData()
    }
}

// MARK: - Supporting Types

enum SidebarItem: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case areas = "Areas"
    case projects = "Projects"
    case resources = "Resources"
    case archives = "Archives"
    case focus = "Focus"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .inbox: return "tray"
        case .areas: return "circle.grid.3x3"
        case .projects: return "folder"
        case .resources: return "book"
        case .archives: return "archivebox"
        case .focus: return "target"
        }
    }
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Repository Extensions

extension MainViewModel {
    
    /// Get repository for areas
    func areaRepository() -> AreaRepository {
        return AreaRepository()
    }
    
    /// Get repository for projects
    func projectRepository() -> ProjectRepository {
        return ProjectRepository()
    }
    
    /// Get repository for tasks
    func taskRepository() -> TaskRepository {
        return TaskRepository()
    }
    
    /// Get repository for blobs
    func blobRepository() -> BlobRepository {
        return BlobRepository()
    }
    
    /// Get repository for resources
    func resourceRepository() -> ResourceRepository {
        return ResourceRepository()
    }
}

// Placeholder repositories - these would be implemented
class ProjectRepository {
    func fetchAllProjects() async throws -> [Project] {
        return try await SupabaseService.shared.fetch(Project.self, from: SupabaseService.TableName.projects)
    }
}

class BlobRepository {
    func fetchRecentBlobs(limit: Int) async throws -> [Blob] {
        let response: [Blob] = try await SupabaseService.shared.client
            .from(SupabaseService.TableName.blobs)
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }
}

class TaskRepository {
    func fetchFocusTasks() async throws -> [Task] {
        let response: [Task] = try await SupabaseService.shared.client
            .from(SupabaseService.TableName.tasks)
            .select()
            .eq("is_focus", value: true)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
} 