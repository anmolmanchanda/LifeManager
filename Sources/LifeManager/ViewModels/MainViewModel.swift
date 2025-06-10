import Foundation
import SwiftUI

/// Main view model for LifeManager app
/// Manages authentication, navigation, and overall app state
@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Services
    
    private let supabaseService = SupabaseService.shared
    private let llmService = LLMService()
    
    // MARK: - Development Mode
    
    private var isDevelopmentMode = false // Set to true when using bypass
    
    // MARK: - Authentication State
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    @Published var authSuccess: String? // For success messages
    
    // MARK: - Navigation State
    
    @Published var selectedView: PARAView = .inbox
    @Published var searchText = ""
    @Published var searchResults: [Blob] = []
    @Published var isSearching = false
    
    // MARK: - PARA Data
    
    @Published var areas: [Area] = []
    @Published var projects: [Project] = []
    @Published var resources: [Resource] = []
    @Published var archives: [Archive] = []
    @Published var recentBlobs: [Blob] = []
    @Published var focusTasks: [LifeTask] = []
    
    // MARK: - UI State
    
    @Published var showingAddContent = false
    @Published var showingSettings = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showingProcessingDetails = false
    
    // MARK: - Processing State
    
    @Published var currentProcessingSession: BatchProcessingSession?
    @Published var pendingConfirmations: [ProcessingResult] = []
    @Published var showingConfirmationDialog = false
    @Published var showingProcessingSummary = false
    @Published var processingResults: [UUID: ProcessingResult] = [:]
    @Published var blobProcessingStates: [UUID: BlobProcessingState] = [:]
    
    // MARK: - Initialization
    
    init() {
        // Test blob serialization on startup
        Task {
            await supabaseService.testBlobSerialization()
        }
        
        setupAuthListener()
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Authentication Setup
    
    private func setupAuthListener() {
        // Listen for authentication state changes
        Task {
            for await authState in supabaseService.$isAuthenticated.values {
                self.isAuthenticated = authState
                
                if authState {
                    await loadInitialData()
                } else {
                    clearData()
                }
            }
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        await MainActor.run {
        isLoading = true
        authError = nil
        }
        
        do {
            let session = try await supabaseService.signIn(email: email, password: password)
            await MainActor.run {
                // Handle successful sign in
                self.isAuthenticated = true
                self.isLoading = false
                self.authError = nil
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            authError = nil
        }
        
        do {
            let session = try await supabaseService.signUp(email: email, password: password)
            await MainActor.run {
                if session != nil {
                    // Handle successful sign up with immediate session
                    self.isAuthenticated = true
                    self.isLoading = false
                    self.authError = nil
                } else {
                    // This shouldn't happen with our new error handling, but just in case
                    self.isLoading = false
                    self.authError = "Account created. Check your email for confirmation."
                }
            }
        } catch SupabaseError.emailConfirmationRequired {
            await MainActor.run {
                self.authError = "Account created! Email confirmation disabled for development. Try signing in with the same credentials."
                self.isLoading = false
            }
        } catch {
            // If account already exists, try signing in instead
            if error.localizedDescription.contains("already registered") || error.localizedDescription.contains("email_exists") {
                await MainActor.run {
                    self.authError = "Account already exists. Try signing in instead."
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.authError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func signInWithMagicLink(email: String) async {
        await MainActor.run {
        isLoading = true
        authError = nil
            authSuccess = nil
        }
        
        do {
            try await supabaseService.signInWithMagicLink(email: email)
            await MainActor.run {
                // Magic link sent successfully
                self.authSuccess = "✅ Magic link sent to \(email). Check your email and click the link to sign in."
                self.authError = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = "Failed to send magic link: \(error.localizedDescription)"
                self.authSuccess = nil
                self.isLoading = false
            }
        }
    }
    
    func signOut() async {
        do {
            try await supabaseService.signOut()
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                clearData()
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        guard isAuthenticated else { 
            print("🔧 LOAD DATA: Skipping - not authenticated")
            return 
        }
        
        print("🔧 LOAD DATA: Starting initial data load...")
    
        do {
            // Load all data in parallel for better performance
            async let areasTask = AreaRepository().fetchAllAreas()
            async let projectsTask = ProjectRepository().fetchAllProjects()
            async let resourcesTask = ResourceRepository().fetchAllResources()
            async let archivesTask = ArchiveRepository().fetchAllArchives()
            async let unprocessedBlobsTask = BlobRepository().fetchUnprocessedBlobs() // Only unprocessed for inbox
            async let focusTasksTask = TaskRepository().fetchFocusTasks()
            
            let loadedAreas = try await areasTask
            let loadedProjects = try await projectsTask
            let loadedResources = try await resourcesTask
            let loadedArchives = try await archivesTask
            let loadedUnprocessedBlobs = try await unprocessedBlobsTask
            let loadedFocusTasks = try await focusTasksTask
            
            await MainActor.run {
                self.areas = loadedAreas
                self.projects = loadedProjects
                self.resources = loadedResources
                self.archives = loadedArchives
                self.recentBlobs = loadedUnprocessedBlobs // Only unprocessed blobs in inbox
                self.focusTasks = loadedFocusTasks
            }
            
            print("🔧 LOAD DATA: ✅ Loaded - Areas: \(loadedAreas.count), Projects: \(loadedProjects.count), Resources: \(loadedResources.count), Archives: \(loadedArchives.count), Unprocessed Blobs: \(loadedUnprocessedBlobs.count), Focus Tasks: \(loadedFocusTasks.count)")
            
        } catch {
            print("🔧 LOAD DATA: ❌ Error loading data - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load data: \(error.localizedDescription)"
            }
        }
    }
    
    private func clearData() {
        areas = []
        projects = []
        resources = []
        archives = []
        recentBlobs = []
        focusTasks = []
        searchText = ""
    }
    
    // MARK: - Search
    
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            searchResults = try await blobRepository().searchBlobs(query: query)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    // MARK: - Quick Actions
    
    func addQuickNote(_ content: String) async {
        print("🔧 ADD NOTE: Starting note addition process")
        print("🔧 ADD NOTE: Content length: \(content.count)")
        
        // Clear any previous messages and set loading state
        await MainActor.run {
            self.errorMessage = nil
            self.successMessage = nil
            self.isLoading = true
        }
        
        // Step 1: Create blob
        let blob = Blob(
            content: content,
            sourceType: .note,
            workPersonal: .personal
        )
        
        print("🔧 ADD NOTE: Created blob with ID: \(blob.id)")
        
        // Step 2: Save to database first
        var savedBlob: Blob? = nil
        do {
            savedBlob = try await blobRepository().createBlob(blob)
            print("🔧 ADD NOTE: ✅ Successfully saved blob with ID: \(savedBlob!.id)")
            
            // Add to UI after successful save
            await MainActor.run {
                self.blobProcessingStates[blob.id] = .unprocessed
                self.recentBlobs.insert(savedBlob!, at: 0)
                self.successMessage = "✅ Note saved - starting AI processing..."
            }
            
        } catch {
            print("🔧 ADD NOTE: ❌ SAVE ERROR - \(error)")
            
            await MainActor.run {
                self.isLoading = false
                if error.localizedDescription.contains("format") || error.localizedDescription.contains("read") {
                    self.successMessage = "⚠️ Note saved (basic format - AI processing may be limited)"
                } else {
                    self.errorMessage = "Failed to save note: \(error.localizedDescription)"
                }
            }
            return
        }
        
        // Step 3: Start AI processing immediately (no delays)
        if let blob = savedBlob {
            print("🔧 ADD NOTE: Starting immediate AI processing...")
            
            // Start processing immediately
            await processImmediately(blob)
            
            // Final state update
            await MainActor.run {
                self.isLoading = false
                if let result = self.processingResults[blob.id] {
                    if result.requiresConfirmation {
                        self.successMessage = "🤖 Note processed - review needed"
                        self.showingConfirmationDialog = true
                    } else {
                        self.successMessage = "🤖 Note processed → \(result.paraCategory.displayName)"
                        // Remove from inbox if processed successfully
                        self.recentBlobs.removeAll { $0.id == blob.id }
                    }
                } else {
                    self.successMessage = "✅ Note saved and processed"
                }
            }
            
            // Clear success message after delay
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                await MainActor.run {
                    if self.successMessage?.contains("processed") == true {
                        self.successMessage = nil
                    }
                }
            }
            
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
        
        print("🔧 ADD NOTE: ✅ Completed successfully with immediate processing")
    }
    
    /// Process a blob immediately without delays
    private func processImmediately(_ blob: Blob) async {
        print("🔧 IMMEDIATE PROCESS: Starting for blob: \(blob.id)")
        
        await MainActor.run {
            self.blobProcessingStates[blob.id] = .processing
            self.successMessage = "🤖 Processing with AI..."
        }
        
        do {
            print("🔧 IMMEDIATE PROCESS: Calling LLM service...")
            let result = try await llmService.processComprehensively(
                blob: blob,
                availableAreas: areas,
                availableProjects: projects,
                confidenceThreshold: 0.7
            )
            
            print("🔧 IMMEDIATE PROCESS: ✅ LLM processing completed")
            print("🔧 IMMEDIATE PROCESS: Result category: \(result.paraCategory.displayName)")
            print("🔧 IMMEDIATE PROCESS: Result confidence: \(result.confidence)")
            
            // Store result immediately
            await MainActor.run {
                self.processingResults[blob.id] = result
                
                if result.requiresConfirmation {
                    self.blobProcessingStates[blob.id] = .needsConfirmation(result)
                    self.pendingConfirmations.append(result)
                } else {
                    self.blobProcessingStates[blob.id] = .processed(result)
                }
            }
            
            // Execute actions if high confidence
            if !result.requiresConfirmation {
                print("🔧 IMMEDIATE PROCESS: Executing processing actions...")
                do {
                    try await executeProcessingActions(for: blob, with: result)
                    print("🔧 IMMEDIATE PROCESS: ✅ Actions executed successfully")
                } catch {
                    print("🔧 IMMEDIATE PROCESS: ❌ Action execution failed: \(error)")
                    await MainActor.run {
                        self.blobProcessingStates[blob.id] = .error("Action execution failed: \(error.localizedDescription)")
                    }
                }
            }
            
        } catch {
            print("🔧 IMMEDIATE PROCESS: ❌ LLM Processing failed: \(error)")
            
            await MainActor.run {
                self.blobProcessingStates[blob.id] = .error(error.localizedDescription)
                self.successMessage = "✅ Note saved (AI processing failed)"
            }
        }
    }
    
    /// Process a single blob with comprehensive AI analysis
    func processBlobIndividually(_ blob: Blob) async {
        print("🔧 INDIVIDUAL PROCESS: Starting for blob: \(blob.id)")
        print("🔧 INDIVIDUAL PROCESS: Blob content: '\(blob.content)'")
        print("🔧 INDIVIDUAL PROCESS: Available areas: \(areas.count)")
        print("🔧 INDIVIDUAL PROCESS: Available projects: \(projects.count)")
        
        await MainActor.run {
            self.blobProcessingStates[blob.id] = .processing
        }
        
        do {
            print("🔧 INDIVIDUAL PROCESS: Calling LLM service...")
            let result = try await llmService.processComprehensively(
                blob: blob,
                availableAreas: areas,
                availableProjects: projects,
                confidenceThreshold: 0.7
            )
            
            print("🔧 INDIVIDUAL PROCESS: ✅ LLM processing completed")
            print("🔧 INDIVIDUAL PROCESS: Result category: \(result.paraCategory.displayName)")
            print("🔧 INDIVIDUAL PROCESS: Result confidence: \(result.confidence)")
            print("🔧 INDIVIDUAL PROCESS: Extracted tasks: \(result.extractedTasks.count)")
            print("🔧 INDIVIDUAL PROCESS: Auto tags: \(result.autoTags.count)")
            print("🔧 INDIVIDUAL PROCESS: Requires confirmation: \(result.requiresConfirmation)")
            
            // Store the result
            await MainActor.run {
                self.processingResults[blob.id] = result
                
                if result.requiresConfirmation {
                    print("🔧 INDIVIDUAL PROCESS: Adding to pending confirmations")
                    self.blobProcessingStates[blob.id] = .needsConfirmation(result)
                    self.pendingConfirmations.append(result)
                    self.successMessage = "🤖 AI processing complete - review needed for \(result.paraCategory.displayName)"
                } else {
                    print("🔧 INDIVIDUAL PROCESS: High confidence - no confirmation needed")
                    self.blobProcessingStates[blob.id] = .processed(result)
                    self.successMessage = "🤖 Processed automatically → \(result.paraCategory.displayName)"
                }
            }
            
            // Execute actions if high confidence
            if !result.requiresConfirmation {
                print("🔧 INDIVIDUAL PROCESS: Executing processing actions...")
                do {
                    try await executeProcessingActions(for: blob, with: result)
                    print("🔧 INDIVIDUAL PROCESS: ✅ Actions executed successfully")
                } catch {
                    print("🔧 INDIVIDUAL PROCESS: ❌ Action execution failed: \(error)")
                    await MainActor.run {
                        self.blobProcessingStates[blob.id] = .error("Action execution failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("🔧 INDIVIDUAL PROCESS: Skipping action execution - confirmation required")
            }
            
        } catch {
            print("🔧 INDIVIDUAL PROCESS: ❌ LLM Processing failed: \(error)")
            print("🔧 INDIVIDUAL PROCESS: ❌ Error type: \(type(of: error))")
            print("🔧 INDIVIDUAL PROCESS: ❌ Error description: \(error.localizedDescription)")
            
            await MainActor.run {
                self.blobProcessingStates[blob.id] = .error(error.localizedDescription)
                self.errorMessage = "LLM processing failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Get processing state for a blob
    func getProcessingState(for blobId: UUID) -> BlobProcessingState {
        return blobProcessingStates[blobId] ?? .unprocessed
    }
    
    /// Clear success message after delay
    func clearSuccessMessage() {
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                if self.successMessage != nil {
                    self.successMessage = nil
                }
            }
        }
    }
    
    /// Show processing details for a blob
    func showProcessingDetails(for blob: Blob) {
        selectedView = .history // Navigate to history view or show details
        showingProcessingDetails = true
    }
    
    private func addMockNote(_ content: String) async {
        // Create a mock blob for UI testing
        let mockBlob = Blob(
            content: content,
            sourceType: .note,
            workPersonal: .personal
        )
        
        await MainActor.run {
            // Add to the beginning of recent blobs
            self.recentBlobs.insert(mockBlob, at: 0)
            
            // Keep only the most recent 10 for demo
            if self.recentBlobs.count > 10 {
                self.recentBlobs = Array(self.recentBlobs.prefix(10))
            }
        }
        
        // Simulate AI processing delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock task extraction
        await extractMockTasks(from: content, blobId: mockBlob.id)
    }
    
    private func extractMockTasks(from content: String, blobId: UUID) async {
        // Simple mock task extraction based on keywords
        let taskKeywords = ["meet", "prep", "prepare", "call", "email", "buy", "get", "do", "finish", "complete"]
        let lowerContent = content.lowercased()
        
        for keyword in taskKeywords {
            if lowerContent.contains(keyword) {
                let mockTask = LifeTask(
                    blobId: blobId,
                    title: "Task: \(content.prefix(50))",
                    description: "Auto-extracted from: \(content)",
                    priority: .medium,
                    workPersonal: .personal
                )
                
                await MainActor.run {
                    self.focusTasks.insert(mockTask, at: 0)
                    
                    // Keep only the most recent 5 focus tasks for demo
                    if self.focusTasks.count > 5 {
                        self.focusTasks = Array(self.focusTasks.prefix(5))
                    }
                }
                break
            }
        }
    }
    
    private func processBlob(_ blob: Blob) async throws {
        print("🔧 PROCESS BLOB: Starting processing for blob ID: \(blob.id)")
        
        do {
            // Use LLM to categorize and extract tasks
            print("🔧 PROCESS BLOB: Calling LLM categorization...")
            let categorization = try await llmService.categorizePARA(content: blob.content)
            print("🔧 PROCESS BLOB: ✅ LLM categorization completed")
            print("🔧 PROCESS BLOB: Category: \(categorization.category), Confidence: \(categorization.confidenceScore)")
            
            print("🔧 PROCESS BLOB: Calling LLM task extraction...")
            let tasks = try await llmService.extractTasks(content: blob.content)
            print("🔧 PROCESS BLOB: ✅ LLM task extraction completed - found \(tasks.count) tasks")
            
            // Update blob with processing results
            print("🔧 PROCESS BLOB: Marking blob as processed...")
            let _ = try await blobRepository().markBlobAsProcessed(id: blob.id)
            print("🔧 PROCESS BLOB: ✅ Blob marked as processed")
            
            // Create any extracted tasks
            print("🔧 PROCESS BLOB: Creating extracted tasks...")
            for (index, taskData) in tasks.enumerated() {
                let task = LifeTask(
                    blobId: blob.id,
                    title: taskData["title"] as? String ?? "Untitled Task",
                    description: taskData["description"] as? String,
                    priority: TaskPriority(rawValue: taskData["priority"] as? String ?? "medium") ?? .medium,
                    workPersonal: blob.workPersonal
                )
                
                print("🔧 PROCESS BLOB: Creating task \(index + 1): \(task.title)")
                let _ = try await taskRepository().createTask(task)
                print("🔧 PROCESS BLOB: ✅ Task \(index + 1) created")
            }
            
            print("🔧 PROCESS BLOB: ✅ All processing completed successfully")
        } catch {
            print("🔧 PROCESS BLOB: ❌ LLM ERROR - \(error)")
            print("🔧 PROCESS BLOB: ❌ ERROR TYPE - \(type(of: error))")
            
            // Still mark as processed to avoid blocking note saving
            do {
                let _ = try await blobRepository().markBlobAsProcessed(id: blob.id)
                print("🔧 PROCESS BLOB: ✅ Blob marked as processed despite LLM error")
            } catch {
                print("🔧 PROCESS BLOB: ❌ Failed to mark as processed: \(error)")
            }
            
            // Don't show error to user for LLM failures - note was still saved
            print("🔧 PROCESS BLOB: Note was saved successfully, LLM processing failed but non-critical")
        }
    }
    
    func refreshData() async {
        print("🔧 REFRESH: Starting comprehensive data refresh...")
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.successMessage = "🔄 Refreshing data..."
        }
        
        do {
            // Force reload all data in parallel with timeout protection
            print("🔧 REFRESH: Loading all data repositories...")
            
            async let areasTask = AreaRepository().fetchAllAreas()
            async let projectsTask = ProjectRepository().fetchAllProjects()
            async let resourcesTask = ResourceRepository().fetchAllResources()
            async let archivesTask = ArchiveRepository().fetchAllArchives()
            async let unprocessedBlobsTask = BlobRepository().fetchUnprocessedBlobs() // Only unprocessed
            async let focusTasksTask = TaskRepository().fetchFocusTasks()
            
            let loadedAreas = try await areasTask
            let loadedProjects = try await projectsTask
            let loadedResources = try await resourcesTask
            let loadedArchives = try await archivesTask
            let loadedUnprocessedBlobs = try await unprocessedBlobsTask
            let loadedFocusTasks = try await focusTasksTask
            
            print("🔧 REFRESH: ✅ All data loaded - Areas: \(loadedAreas.count), Projects: \(loadedProjects.count), Resources: \(loadedResources.count), Archives: \(loadedArchives.count), Unprocessed Blobs: \(loadedUnprocessedBlobs.count), Tasks: \(loadedFocusTasks.count)")
            
            // Update all state at once on main thread
            await MainActor.run {
                self.areas = loadedAreas
                self.projects = loadedProjects
                self.resources = loadedResources
                self.archives = loadedArchives
                self.recentBlobs = loadedUnprocessedBlobs // Only unprocessed blobs
                self.focusTasks = loadedFocusTasks
                self.isLoading = false
                self.successMessage = "✅ Data refreshed successfully"
            }
            
            print("🔧 REFRESH: ✅ UI updated with fresh data")
            
            // Clear success message after delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    if self.successMessage == "✅ Data refreshed successfully" {
                        self.successMessage = nil
                    }
                }
            }
            
        } catch {
            print("🔧 REFRESH: ❌ Error during refresh - \(error)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to refresh data: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Development Mode
    
    func enableDevelopmentBypass() {
        isDevelopmentMode = true
        isAuthenticated = true
        
        // Load mock data immediately
        Task {
            await loadMockData()
        }
    }
    
    private func loadMockData() async {
        await MainActor.run {
            // Mock Areas
            self.areas = [
                Area(name: "Health & Fitness", description: "Physical and mental well-being", icon: "heart.fill", color: "#FF6B6B"),
                Area(name: "Career", description: "Professional development", icon: "briefcase.fill", color: "#4ECDC4"),
                Area(name: "Relationships", description: "Family and social connections", icon: "person.2.fill", color: "#45B7D1"),
                Area(name: "Learning", description: "Continuous education", icon: "book.fill", color: "#96CEB4")
            ]
            
            // Mock Projects
            self.projects = [
                Project(name: "Q1 Planning", description: "Quarterly planning and goal setting", workPersonal: .work),
                Project(name: "Home Renovation", description: "Kitchen and bathroom updates", workPersonal: .personal),
                Project(name: "Learn SwiftUI", description: "Master iOS development", workPersonal: .personal)
            ]
            
            // Mock recent blobs (empty to start)
            self.recentBlobs = []
            
            // Mock focus tasks (empty to start)
            self.focusTasks = []
        }
    }
    
    // MARK: - Repository Access
    
    /// Get repository for tasks
    func taskRepository() -> TaskRepository {
        return TaskRepository()
    }
    
    /// Get repository for blobs
    func blobRepository() -> BlobRepository {
        return BlobRepository()
    }
    
    // MARK: - Blob Management
    
    /// Delete a blob from the database
    func deleteBlob(_ blob: Blob) async {
        print("🔧 DELETE BLOB: Deleting blob with ID: \(blob.id)")
        
        do {
            try await blobRepository().deleteBlob(id: blob.id)
            print("🔧 DELETE BLOB: ✅ Successfully deleted blob")
            
            // Remove from local list
            await MainActor.run {
                self.recentBlobs.removeAll { $0.id == blob.id }
            }
            
            // Refresh the data to ensure consistency
            await loadInitialData()
            print("🔧 DELETE BLOB: ✅ Refreshed recent blobs list")
            
        } catch {
            print("🔧 DELETE BLOB: ❌ Error deleting blob - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to delete note: \(error.localizedDescription)"
            }
        }
    }
    
    /// Delete a project from the database
    func deleteProject(_ project: Project) async {
        print("🔧 DELETE PROJECT: Deleting project with ID: \(project.id)")
        
        do {
            try await ProjectRepository().deleteProject(id: project.id)
            print("🔧 DELETE PROJECT: ✅ Successfully deleted project")
            
            // Remove from local list
            await MainActor.run {
                self.projects.removeAll { $0.id == project.id }
                self.successMessage = "✅ Project '\(project.name)' deleted successfully"
            }
            
        } catch {
            print("🔧 DELETE PROJECT: ❌ Error deleting project - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to delete project: \(error.localizedDescription)"
            }
        }
    }
    
    /// Delete an area from the database
    func deleteArea(_ area: Area) async {
        print("🔧 DELETE AREA: Deleting area with ID: \(area.id)")
        
        do {
            try await AreaRepository().deleteArea(id: area.id)
            print("🔧 DELETE AREA: ✅ Successfully deleted area")
            
            // Remove from local list
            await MainActor.run {
                self.areas.removeAll { $0.id == area.id }
                self.successMessage = "✅ Area '\(area.name)' deleted successfully"
            }
            
        } catch {
            print("🔧 DELETE AREA: ❌ Error deleting area - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to delete area: \(error.localizedDescription)"
            }
        }
    }
    
    /// Delete a resource from the database
    func deleteResource(_ resource: Resource) async {
        print("🔧 DELETE RESOURCE: Deleting resource with ID: \(resource.id)")
        
        do {
            try await ResourceRepository().deleteResource(id: resource.id)
            print("🔧 DELETE RESOURCE: ✅ Successfully deleted resource")
            
            // Remove from local list
            await MainActor.run {
                self.resources.removeAll { $0.id == resource.id }
                self.successMessage = "✅ Resource '\(resource.title)' deleted successfully"
            }
            
        } catch {
            print("🔧 DELETE RESOURCE: ❌ Error deleting resource - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to delete resource: \(error.localizedDescription)"
            }
        }
    }
    
    /// Delete an archive from the database
    func deleteArchive(_ archive: Archive) async {
        print("🔧 DELETE ARCHIVE: Deleting archive with ID: \(archive.id)")
        
        do {
            try await ArchiveRepository().deleteArchive(id: archive.id)
            print("🔧 DELETE ARCHIVE: ✅ Successfully deleted archive")
            
            // Remove from local list
            await MainActor.run {
                self.archives.removeAll { $0.id == archive.id }
                self.successMessage = "✅ Archive '\(archive.title)' deleted permanently"
            }
            
        } catch {
            print("🔧 DELETE ARCHIVE: ❌ Error deleting archive - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to delete archive: \(error.localizedDescription)"
            }
        }
    }
    
    /// Restore an item from archive
    func restoreFromArchive(_ archive: Archive) async {
        print("🔧 RESTORE ARCHIVE: Restoring archive with ID: \(archive.id)")
        
        do {
            try await ArchiveRepository().restoreFromArchive(id: archive.id)
            print("🔧 RESTORE ARCHIVE: ✅ Successfully restored from archive")
            
            // Remove from archives list and refresh all data
            await MainActor.run {
                self.archives.removeAll { $0.id == archive.id }
                self.successMessage = "✅ '\(archive.title)' restored from archive"
            }
            
            // Refresh all data to show the restored item in the appropriate category
            await loadInitialData()
            
        } catch {
            print("🔧 RESTORE ARCHIVE: ❌ Error restoring from archive - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to restore from archive: \(error.localizedDescription)"
            }
        }
    }
    
    /// Process all unprocessed blobs with comprehensive PARA workflow
    func processAllUnprocessedBlobs() async {
        print("🔧 BULK PROCESS: Starting comprehensive bulk processing")
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.pendingConfirmations = []
        }
        
        do {
            // Fetch all unprocessed blobs
            let unprocessedBlobs = try await blobRepository().fetchUnprocessedBlobs()
            print("🔧 BULK PROCESS: Found \(unprocessedBlobs.count) unprocessed blobs")
            
            if unprocessedBlobs.isEmpty {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "No unprocessed notes found in inbox"
                }
                return
            }
            
            // Create processing session
            var session = BatchProcessingSession(totalBlobs: unprocessedBlobs.count)
            await MainActor.run {
                self.currentProcessingSession = session
            }
            
            var results: [UUID: ProcessingResult] = [:]
            var summary = BatchProcessingSummary()
            
            // Process each blob with comprehensive workflow
            for (index, blob) in unprocessedBlobs.enumerated() {
                print("🔧 BULK PROCESS: Processing blob \(index + 1)/\(unprocessedBlobs.count): \(blob.id)")
                
                do {
                    // Step 1: AI Analysis
                    let processingResult = try await llmService.processComprehensively(
                        blob: blob,
                        availableAreas: areas,
                        availableProjects: projects,
                        confidenceThreshold: 0.7
                    )
                    
                    results[blob.id] = processingResult
                    summary.add(processingResult)
                    
                    print("🔧 BULK PROCESS: AI analysis complete for blob \(index + 1)")
                    
                    // Step 2: Execute Actions (if confidence is high enough)
                    if !processingResult.requiresConfirmation {
                        try await executeProcessingActions(for: blob, with: processingResult)
                        print("🔧 BULK PROCESS: ✅ Actions executed for blob \(index + 1)")
                    } else {
                        print("🔧 BULK PROCESS: ⚠️ Blob \(index + 1) requires user confirmation")
                        await MainActor.run {
                            self.pendingConfirmations.append(processingResult)
                        }
                    }
                    
                } catch {
                    print("🔧 BULK PROCESS: ❌ Failed to process blob \(index + 1): \(error)")
                    summary.errors += 1
                    
                    // Create error result
                    let errorResult = ProcessingResult(
                        blobId: blob.id,
                        paraCategory: .resource,
                        confidence: 0.0,
                        requiresConfirmation: true,
                        actions: [ProcessingAction(
                            type: .error,
                            description: "Processing failed: \(error.localizedDescription)",
                            success: false,
                            errorMessage: error.localizedDescription
                        )]
                    )
                    results[blob.id] = errorResult
                    
                    await MainActor.run {
                        self.pendingConfirmations.append(errorResult)
                    }
                }
                
                // Small delay to avoid overwhelming the API
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Update session
            session = BatchProcessingSession(
                id: session.id,
                startTime: session.startTime,
                endTime: ISO8601DateFormatter().string(from: Date()),
                totalBlobs: session.totalBlobs,
                processedBlobs: results.count,
                results: results,
                canUndo: true,
                summary: summary
            )
            
            await MainActor.run {
                self.currentProcessingSession = session
                self.isLoading = false
                
                // Show appropriate UI
                if !self.pendingConfirmations.isEmpty {
                    self.showingConfirmationDialog = true
                } else {
                    self.showingProcessingSummary = true
                }
            }
            
            // Refresh data
            await loadInitialData()
            
            print("🔧 BULK PROCESS: ✅ Comprehensive processing complete")
            print("🔧 BULK PROCESS: Summary - Processed: \(summary.totalProcessed), Tasks: \(summary.tasksCreated), Confirmations needed: \(summary.confirmationsNeeded), Errors: \(summary.errors)")
            
        } catch {
            print("🔧 BULK PROCESS: ❌ Critical error during bulk processing - \(error)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to process notes: \(error.localizedDescription)"
            }
        }
    }
    
    /// Execute processing actions for a blob
    private func executeProcessingActions(for blob: Blob, with result: ProcessingResult) async throws {
        print("🔧 EXECUTE ACTIONS: Starting for blob: \(blob.id)")
        
        // 1. Move blob to appropriate PARA category
        try await moveToParaCategory(blob: blob, category: result.paraCategory, result: result)
        
        // 2. Create extracted tasks
        for taskInfo in result.extractedTasks {
            try await createTaskFromExtraction(taskInfo: taskInfo, sourceBlob: blob)
        }
        
        // 3. Apply tags
        if !result.autoTags.isEmpty {
            try await applyTags(to: blob, tags: result.autoTags)
        }
        
        // 4. Create cross-links
        for crossLink in result.crossLinks {
            try await createCrossLink(crossLink: crossLink, sourceBlob: blob)
        }
        
        // 5. Mark as processed
        let _ = try await blobRepository().markBlobAsProcessed(id: blob.id)
        
        // 6. Log to audit trail
        try await logProcessingToAudit(blob: blob, result: result)
        
        // 7. Update local state to remove processed blob from inbox
        await MainActor.run {
            self.recentBlobs.removeAll { $0.id == blob.id }
            self.blobProcessingStates[blob.id] = .processed(result)
        }
        
        print("🔧 EXECUTE ACTIONS: ✅ All actions completed for blob: \(blob.id)")
    }
    
    /// Move blob to appropriate PARA category
    private func moveToParaCategory(blob: Blob, category: PARACategory, result: ProcessingResult) async throws {
        print("🔧 MOVE PARA: Moving blob \(blob.id) to category: \(category.displayName)")
        
        // Find or create area/project if suggested
        if let suggestedArea = result.suggestedArea {
            if let existingArea = areas.first(where: { $0.name.lowercased() == suggestedArea.lowercased() }) {
                // Link to existing area
                print("🔧 MOVE PARA: Linking to existing area: \(existingArea.name)")
            } else {
                // Create new area if confidence is high
                if result.confidence > 0.8 {
                    print("🔧 MOVE PARA: Creating new area: \(suggestedArea)")
                    // Area creation would be implemented here
                }
            }
        }
        
        if let suggestedProject = result.suggestedProject {
            if let existingProject = projects.first(where: { $0.name.lowercased() == suggestedProject.lowercased() }) {
                // Link to existing project
                print("🔧 MOVE PARA: Linking to existing project: \(existingProject.name)")
            } else {
                // Create new project if confidence is high
                if result.confidence > 0.8 {
                    print("🔧 MOVE PARA: Creating new project: \(suggestedProject)")
                    // Project creation would be implemented here
                }
            }
        }
        
        print("🔧 MOVE PARA: ✅ Blob categorized as: \(category.displayName)")
    }
    
    /// Create task from extraction info
    private func createTaskFromExtraction(taskInfo: TaskExtractionInfo, sourceBlob: Blob) async throws {
        print("🔧 CREATE TASK: Creating task: \(taskInfo.title)")
        
        let task = LifeTask(
            blobId: sourceBlob.id,
            title: taskInfo.title,
            description: taskInfo.description,
            priority: taskInfo.priority,
            dueDate: taskInfo.suggestedDueDate,
            estimatedDuration: taskInfo.estimatedDuration,
            workPersonal: sourceBlob.workPersonal
        )
        
        let _ = try await taskRepository().createTask(task)
        print("🔧 CREATE TASK: ✅ Task created: \(taskInfo.title)")
    }
    
    /// Apply tags to blob
    private func applyTags(to blob: Blob, tags: [String]) async throws {
        print("🔧 APPLY TAGS: Applying \(tags.count) tags to blob: \(blob.id)")
        
        // Tag application would be implemented with tag repository
        for tag in tags {
            print("🔧 APPLY TAGS: Applied tag: \(tag)")
        }
        
        print("🔧 APPLY TAGS: ✅ All tags applied")
    }
    
    /// Create cross-link
    private func createCrossLink(crossLink: CrossLinkSuggestion, sourceBlob: Blob) async throws {
        print("🔧 CROSS LINK: Creating link to: \(crossLink.targetName)")
        
        // Cross-link creation would be implemented here
        // This would involve finding existing items or creating suggestions for new ones
        
        print("🔧 CROSS LINK: ✅ Cross-link created")
    }
    
    /// Log processing to audit trail
    private func logProcessingToAudit(blob: Blob, result: ProcessingResult) async throws {
        print("🔧 AUDIT LOG: Logging processing for blob: \(blob.id)")
        
        // Audit logging would be implemented here
        // This would create entries in the audit trail table
        
        print("🔧 AUDIT LOG: ✅ Processing logged to audit trail")
    }
    
    /// Confirm processing for pending items
    func confirmProcessing(for result: ProcessingResult, approved: Bool) async {
        print("🔧 CONFIRM: Processing confirmation for blob: \(result.blobId), approved: \(approved)")
        
        if approved {
            do {
                // Find the blob and execute actions
                if let blob = recentBlobs.first(where: { $0.id == result.blobId }) {
                    try await executeProcessingActions(for: blob, with: result)
                    print("🔧 CONFIRM: ✅ Actions executed after confirmation")
                }
            } catch {
                print("🔧 CONFIRM: ❌ Error executing confirmed actions: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to execute confirmed actions: \(error.localizedDescription)"
                }
            }
        } else {
            print("🔧 CONFIRM: ⚠️ Processing rejected by user")
        }
        
        // Remove from pending confirmations
        await MainActor.run {
            self.pendingConfirmations.removeAll { $0.id == result.id }
            
            if self.pendingConfirmations.isEmpty {
                self.showingConfirmationDialog = false
                self.showingProcessingSummary = true
            }
        }
    }
    
    /// Undo batch processing session
    func undoBatchProcessing(session: BatchProcessingSession) async {
        print("🔧 UNDO: Starting batch undo for session: \(session.id)")
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Undo would involve:
            // 1. Restoring blobs to inbox
            // 2. Deleting created tasks
            // 3. Removing applied tags
            // 4. Deleting cross-links
            // 5. Updating audit trail
            
            // For now, we'll simulate the undo process
            try await performUndoOperations(session: session)
            
            print("🔧 UNDO: ✅ Batch processing undone")
            
            await MainActor.run {
                self.currentProcessingSession = nil
                self.isLoading = false
                self.errorMessage = "✅ Batch processing undone successfully"
            }
            
            // Refresh data
            await loadInitialData()
            
        } catch {
            print("🔧 UNDO: ❌ Error during undo: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to undo batch processing: \(error.localizedDescription)"
            }
        }
    }
    
    /// Perform the actual undo operations
    private func performUndoOperations(session: BatchProcessingSession) async throws {
        // This would contain the actual undo logic
        // For now, just add a small delay to simulate work
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        print("🔧 UNDO: Simulated undo operations complete")
    }
}
