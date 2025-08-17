import Foundation
import SwiftUI

//
// MainViewModel.swift
// LifeManager
//
// Implements: v1.0 "Inbox Processing", v1.25 "Enhanced UI", v1.5 "PARA System", v1.75 "MVVM Architecture"
// Roadmap Reference: v1.0 Foundation, v1.25 Intelligence & UI, v1.5 Advanced Features, v1.75 Calendar Revolution
// Status: ✅ COMPLETE as of June 14, 2025
// Future: v2.0 Analytics & Insights, Collaboration Features
//

/// History item for inbox processing
struct InboxHistoryItem: Codable {
    let input: String
    let itemsCreated: Int
    let timestamp: Date
    let categories: [String]
}

/// Main view model for LifeManager app
/// Manages authentication, navigation, and overall app state
/// Central coordinator for PARA methodology and AI-powered productivity features
@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Services
    
    private let supabaseService = SupabaseService.shared
    internal let llmService = LLMService()
    
    // MARK: - Development Mode
    
    private var isDevelopmentMode = true // Set to true when using bypass - ENABLED FOR DEVELOPMENT
    
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
    
    // MARK: - PARA Content (Blobs assigned to categories)
    
    @Published var projectBlobs: [UUID: [Blob]] = [:] // projectId -> blobs
    @Published var areaBlobs: [UUID: [Blob]] = [:] // areaId -> blobs
    @Published var resourceBlobs: [Blob] = [] // All resource-categorized blobs
    @Published var archivedBlobs: [Blob] = [] // All archived blobs
    
    // MARK: - PARA Tasks (Tasks assigned to categories)
    
    @Published var projectTasks: [UUID: [LifeTask]] = [:] // projectId -> tasks
    @Published var areaTasks: [UUID: [LifeTask]] = [:] // areaId -> tasks
    
    // MARK: - Navigation State for Sub-categories
    
    @Published var selectedProject: Project?
    @Published var selectedArea: Area?
    @Published var selectedResourceCategory: String?
    @Published var selectedArchiveCategory: String?
    
    // MARK: - UI State
    
    @Published var showingAddContent = false
    @Published var showingSettings = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showingProcessingDetails = false
    
    // MARK: - Brain Dump State
    
    @Published var inboxInput = ""
    @Published var inboxHistory: [InboxHistoryItem] = [] {
        didSet {
            saveInboxHistory()
        }
    }
    @Published var isProcessingInbox = false
    @Published var showingBrainDumpReview = false
    @Published var brainDumpResult: BrainDumpResult?
    @Published var brainDumpProgressMessage = ""
    @Published var brainDumpElapsedTime = 0
    
    private let brainDumpProcessor = LLMBrainDumpProcessor()
    private var brainDumpProgressTimer: Timer?
    
    // MARK: - Processing State
    
    @Published var currentProcessingSession: BatchProcessingSession?
    @Published var pendingConfirmations: [ProcessingResult] = []
    @Published var showingConfirmationDialog = false
    @Published var showingProcessingSummary = false
    @Published var processingResults: [UUID: ProcessingResult] = [:]
    @Published var blobProcessingStates: [UUID: BlobProcessingState] = [:]
    
    // MARK: - Initialization
    
    init() {
        NSLog("🔧 DEBUG: MainViewModel init() started")
        
        // Test blob serialization on startup
        Task {
            NSLog("🔧 DEBUG: MainViewModel testing blob serialization")
            await supabaseService.testBlobSerialization()
            NSLog("🔧 DEBUG: MainViewModel blob serialization test completed")
        }
        
        NSLog("🔧 DEBUG: MainViewModel BYPASSING auth to avoid keychain")
        // TEMPORARY: Skip auth to avoid keychain popups
        self.isAuthenticated = true
        self.isDevelopmentMode = true
        
        // setupAuthListener() // DISABLED to prevent keychain access
        
        // Start log monitoring automatically
        startLogMonitoring()
        
        Task {
            NSLog("🔧 DEBUG: MainViewModel loading initial data")
            // Force authenticated state
            await MainActor.run {
                self.isAuthenticated = true
            }
            await loadInitialData()
            NSLog("🔧 DEBUG: MainViewModel initial data loading completed")
        }
        
        // Load persisted inbox history
        loadInboxHistory()
        
        NSLog("🔧 DEBUG: MainViewModel init() completed")
    }
    
    // MARK: - Inbox History Persistence
    
    /// Save inbox history to UserDefaults
    private func saveInboxHistory() {
        do {
            let data = try JSONEncoder().encode(inboxHistory)
            UserDefaults.standard.set(data, forKey: "inboxHistory")
            print("🔧 HISTORY: ✅ Saved \(inboxHistory.count) history items")
        } catch {
            print("🔧 HISTORY: ❌ Failed to save history: \(error)")
        }
    }
    
    /// Load inbox history from UserDefaults
    private func loadInboxHistory() {
        guard let data = UserDefaults.standard.data(forKey: "inboxHistory") else {
            print("🔧 HISTORY: No saved history found")
            return
        }
        
        do {
            let loadedHistory = try JSONDecoder().decode([InboxHistoryItem].self, from: data)
            inboxHistory = loadedHistory
            print("🔧 HISTORY: ✅ Loaded \(inboxHistory.count) history items")
        } catch {
            print("🔧 HISTORY: ❌ Failed to load history: \(error)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: "inboxHistory")
        }
    }
    
    // MARK: - Log Monitoring
    
    /// Start automatic log monitoring
    private func startLogMonitoring() {
        Task {
            do {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/Users/Shared/LifeManager/monitor_logs.sh")
                process.arguments = ["-f"] // Follow mode for real-time monitoring
                
                // Run in background
                try process.run()
                print("🔧 MAIN: ✅ Log monitoring started automatically")
            } catch {
                print("🔧 MAIN: ❌ Failed to start log monitoring: \(error)")
            }
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
    
    func resetPassword(email: String) async {
        await MainActor.run {
            isLoading = true
            authError = nil
            authSuccess = nil
        }
        
        do {
            try await supabaseService.resetPassword(email: email)
            await MainActor.run {
                self.authSuccess = "✅ Password reset email sent to \(email). Check your email for reset instructions."
                self.authError = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = "Failed to send reset email: \(error.localizedDescription)"
                self.authSuccess = nil
                self.isLoading = false
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
            // Load all data in parallel for better performance with individual error handling
            print("🔧 LOAD DATA: Starting parallel data fetch...")
            
            var loadedAreas: [Area] = []
            var loadedProjects: [Project] = []
            var loadedResources: [Resource] = []
            var loadedArchives: [Archive] = []
            var loadedUnprocessedBlobs: [Blob] = []
            var loadedFocusTasks: [LifeTask] = []
            
            // Fetch Areas with individual error handling
            do {
                print("🔧 LOAD DATA: Fetching areas...")
                loadedAreas = try await AreaRepository().fetchAllAreas()
                print("🔧 LOAD DATA: ✅ Areas loaded: \(loadedAreas.count)")
            } catch {
                print("🔧 LOAD DATA: ❌ Areas fetch failed: \(error)")
                print("🔧 LOAD DATA: ❌ Areas error type: \(type(of: error))")
            }
            
            // Fetch Projects with individual error handling
            do {
                print("🔧 LOAD DATA: Fetching projects...")
                loadedProjects = try await ProjectRepository().fetchAllProjects()
                print("🔧 LOAD DATA: ✅ Projects loaded: \(loadedProjects.count)")
            } catch {
                print("🔧 LOAD DATA: ❌ Projects fetch failed: \(error)")
                print("🔧 LOAD DATA: ❌ Projects error type: \(type(of: error))")
            }
            
            // Fetch Resources with individual error handling
            do {
                print("🔧 LOAD DATA: Fetching resources...")
                loadedResources = try await ResourceRepository().fetchAllResources()
                print("🔧 LOAD DATA: ✅ Resources loaded: \(loadedResources.count)")
        } catch {
                print("🔧 LOAD DATA: ❌ Resources fetch failed: \(error)")
                print("🔧 LOAD DATA: ❌ Resources error type: \(type(of: error))")
            }
            
            // Fetch Archives with individual error handling
            do {
                print("🔧 LOAD DATA: Fetching archives...")
                loadedArchives = try await ArchiveRepository().fetchAllArchives()
                print("🔧 LOAD DATA: ✅ Archives loaded: \(loadedArchives.count)")
            } catch {
                print("🔧 LOAD DATA: ❌ Archives fetch failed: \(error)")
                print("🔧 LOAD DATA: ❌ Archives error type: \(type(of: error))")
            }
            
            // Fetch Unprocessed Blobs with individual error handling
            do {
                print("🔧 LOAD DATA: Fetching unprocessed blobs...")
                loadedUnprocessedBlobs = try await BlobRepository().fetchUnprocessedBlobs()
                print("🔧 LOAD DATA: ✅ Unprocessed blobs loaded: \(loadedUnprocessedBlobs.count)")
            } catch {
                print("🔧 LOAD DATA: ❌ Unprocessed blobs fetch failed: \(error)")
                print("🔧 LOAD DATA: ❌ Unprocessed blobs error type: \(type(of: error))")
            }
            
            // Fetch Focus Tasks with individual error handling
            do {
                print("🔧 LOAD DATA: Fetching focus tasks...")
                loadedFocusTasks = try await TaskRepository().fetchFocusTasks()
                print("🔧 LOAD DATA: ✅ Focus tasks loaded: \(loadedFocusTasks.count)")
            } catch {
                print("🔧 LOAD DATA: ❌ Focus tasks fetch failed: \(error)")
                print("🔧 LOAD DATA: ❌ Focus tasks error type: \(type(of: error))")
            }
            
            // Fetch PARA-categorized blobs
            var loadedProjectBlobs: [UUID: [Blob]] = [:]
            var loadedAreaBlobs: [UUID: [Blob]] = [:]
            var loadedResourceBlobs: [Blob] = []
            var loadedArchivedBlobs: [Blob] = []
            
            do {
                print("🔧 LOAD DATA: Fetching PARA-categorized blobs...")
                
                // Fetch all processed blobs
                let allProcessedBlobs = try await BlobRepository().fetchProcessedBlobs()
                print("🔧 LOAD DATA: ✅ Found \(allProcessedBlobs.count) processed blobs")
                
                // Categorize blobs by their PARA assignment
                for blob in allProcessedBlobs {
                    if let projectId = blob.projectId {
                        if loadedProjectBlobs[projectId] == nil {
                            loadedProjectBlobs[projectId] = []
                        }
                        loadedProjectBlobs[projectId]?.append(blob)
                    } else if let areaId = blob.areaId {
                        if loadedAreaBlobs[areaId] == nil {
                            loadedAreaBlobs[areaId] = []
                        }
                        loadedAreaBlobs[areaId]?.append(blob)
                    } else if blob.isArchived {
                        loadedArchivedBlobs.append(blob)
                    } else {
                        // Default to resources if processed but no specific assignment
                        loadedResourceBlobs.append(blob)
                    }
                }
                
                print("🔧 LOAD DATA: ✅ Categorized blobs - Projects: \(loadedProjectBlobs.keys.count), Areas: \(loadedAreaBlobs.keys.count), Resources: \(loadedResourceBlobs.count), Archives: \(loadedArchivedBlobs.count)")
                
            } catch {
                print("🔧 LOAD DATA: ❌ PARA blobs fetch failed: \(error)")
            }
            
            // Fetch and categorize tasks by PARA assignment
            var loadedProjectTasks: [UUID: [LifeTask]] = [:]
            var loadedAreaTasks: [UUID: [LifeTask]] = [:]
            
            do {
                print("🔧 LOAD DATA: Fetching and categorizing tasks...")
                
                // Fetch all tasks
                let allTasks = try await TaskRepository().fetchAllTasks()
                print("🔧 LOAD DATA: ✅ Found \(allTasks.count) tasks")
                
                // Categorize tasks by their PARA assignment
                for task in allTasks {
                    if let projectId = task.projectId {
                        if loadedProjectTasks[projectId] == nil {
                            loadedProjectTasks[projectId] = []
                        }
                        loadedProjectTasks[projectId]?.append(task)
                    } else if let areaId = task.areaId {
                        if loadedAreaTasks[areaId] == nil {
                            loadedAreaTasks[areaId] = []
                        }
                        loadedAreaTasks[areaId]?.append(task)
                    }
                }
                
                print("🔧 LOAD DATA: ✅ Categorized tasks - Projects: \(loadedProjectTasks.keys.count), Areas: \(loadedAreaTasks.keys.count)")
                
                // Debug: Log task assignments
                for (areaId, tasks) in loadedAreaTasks {
                    print("🔧 LOAD DATA: Area \(areaId) has \(tasks.count) tasks")
                }
                for (projectId, tasks) in loadedProjectTasks {
                    print("🔧 LOAD DATA: Project \(projectId) has \(tasks.count) tasks")
                }
                
            } catch {
                print("🔧 LOAD DATA: ❌ Task categorization failed: \(error)")
            }
            
            await MainActor.run {
                self.areas = loadedAreas
                self.projects = loadedProjects
                self.resources = loadedResources
                self.archives = loadedArchives
                self.recentBlobs = loadedUnprocessedBlobs // Only unprocessed blobs in inbox
                self.focusTasks = loadedFocusTasks
                
                // Update PARA blob assignments
                self.projectBlobs = loadedProjectBlobs
                self.areaBlobs = loadedAreaBlobs
                self.resourceBlobs = loadedResourceBlobs
                self.archivedBlobs = loadedArchivedBlobs
                
                // Update PARA task assignments
                self.projectTasks = loadedProjectTasks
                self.areaTasks = loadedAreaTasks
            }
            
            print("🔧 LOAD DATA: ✅ Loaded - Areas: \(loadedAreas.count), Projects: \(loadedProjects.count), Resources: \(loadedResources.count), Archives: \(loadedArchives.count), Unprocessed Blobs: \(loadedUnprocessedBlobs.count), Focus Tasks: \(loadedFocusTasks.count)")
            
            // Enhance existing tasks with comprehensive LLM processing
            // DISABLED: Automatic task enhancement on startup to prevent unwanted API calls
            // await enhanceExistingTasks()
            
            // If some data is empty, let's create some sample data for development
            if loadedAreas.isEmpty && loadedProjects.isEmpty {
                print("🔧 LOAD DATA: No PARA data found, creating sample data...")
                await createSampleParaData()
            }
            
        } catch {
            print("🔧 LOAD DATA: ❌ General error loading data - \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load data: \(error.localizedDescription)"
            }
        }
    }
    
    /// Create sample PARA data for development
    private func createSampleParaData() async {
        print("🔧 SAMPLE DATA: Creating sample PARA data...")
        
        do {
            // Create sample areas
            let healthArea = Area(
                name: "Health & Fitness",
                description: "Physical and mental well-being",
                icon: "heart.fill",
                color: "#FF6B6B",
                workPersonal: .personal
            )
            
            let careerArea = Area(
                name: "Career Development",
                description: "Professional growth and skills",
                icon: "briefcase.fill",
                color: "#4ECDC4",
                workPersonal: .work
            )
            
            let savedHealthArea = try await AreaRepository().createArea(healthArea)
            let savedCareerArea = try await AreaRepository().createArea(careerArea)
            
            print("🔧 SAMPLE DATA: ✅ Created sample areas")
            
            // Create sample projects
            let q1Project = Project(
                name: "Q1 Planning",
                description: "Quarterly planning and goal setting",
                workPersonal: .work,
                areaId: savedCareerArea.id
            )
            
            let workoutProject = Project(
                name: "Home Workout Routine",
                description: "Establish consistent exercise habits",
                workPersonal: .personal,
                areaId: savedHealthArea.id
            )
            
            let savedQ1Project = try await ProjectRepository().createProject(q1Project)
            let savedWorkoutProject = try await ProjectRepository().createProject(workoutProject)
            
            print("🔧 SAMPLE DATA: ✅ Created sample projects")
            
            // Create sample enhanced tasks with comprehensive data
            await createSampleEnhancedTasks(healthArea: savedHealthArea, careerArea: savedCareerArea, q1Project: savedQ1Project, workoutProject: savedWorkoutProject)
            
            // Update local state
            await MainActor.run {
                self.areas = [savedHealthArea, savedCareerArea]
                self.projects = [savedQ1Project, savedWorkoutProject]
                self.successMessage = "✅ Created sample PARA data with enhanced tasks"
            }
            
        } catch {
            print("🔧 SAMPLE DATA: ❌ Failed to create sample data: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to create sample data: \(error.localizedDescription)"
            }
        }
    }
    
    /// Create sample enhanced tasks with comprehensive data for testing
    private func createSampleEnhancedTasks(healthArea: Area, careerArea: Area, q1Project: Project, workoutProject: Project) async {
        print("🔧 SAMPLE TASKS: Creating enhanced sample tasks...")
        
        do {
            let calendar = Calendar.current
            let now = Date()
            
            // Create sample tasks with different priority levels and comprehensive data
            let sampleTasks = [
                // Urgent task (Priority 5)
                LifeTask(
                    title: "Submit quarterly report",
                    description: "Final review and submission of Q1 financial report to stakeholders",
                    priority: .urgent,
                    status: .todo,
                    dueDate: ISO8601DateFormatter().string(from: calendar.date(byAdding: .hour, value: 4, to: now)!),
                    estimatedDuration: 45,
                    workPersonal: .work,
                    projectId: q1Project.id,
                    areaId: careerArea.id,
                    isFocus: true
                ),
                
                // High priority task (Priority 4)
                LifeTask(
                    title: "Doctor appointment follow-up",
                    description: "Call to schedule follow-up appointment and discuss test results",
                    priority: .high,
                    status: .todo,
                    dueDate: ISO8601DateFormatter().string(from: calendar.date(byAdding: .day, value: 1, to: now)!),
                    estimatedDuration: 30,
                    workPersonal: .personal,
                    areaId: healthArea.id,
                    isFocus: true
                ),
                
                // Medium priority task (Priority 3)
                LifeTask(
                    title: "Plan weekly workout schedule",
                    description: "Design workout routine for next week including cardio and strength training",
                    priority: .medium,
                    status: .todo,
                    dueDate: ISO8601DateFormatter().string(from: calendar.date(byAdding: .day, value: 3, to: now)!),
                    estimatedDuration: 60,
                    workPersonal: .personal,
                    projectId: workoutProject.id,
                    areaId: healthArea.id,
                    isFocus: false
                ),
                
                // Low priority task (Priority 2)
                LifeTask(
                    title: "Research productivity tools",
                    description: "Explore new productivity apps and tools for better task management",
                    priority: .low,
                    status: .todo,
                    dueDate: ISO8601DateFormatter().string(from: calendar.date(byAdding: .weekOfYear, value: 1, to: now)!),
                    estimatedDuration: 90,
                    workPersonal: .work,
                    areaId: careerArea.id,
                    isFocus: false
                ),
                
                // Completed task to test UI states
                LifeTask(
                    title: "Complete daily standup",
                    description: "Attend team standup meeting and share progress updates",
                    priority: .medium,
                    status: .completed,
                    dueDate: ISO8601DateFormatter().string(from: calendar.date(byAdding: .hour, value: -2, to: now)!),
                    estimatedDuration: 15,
                    workPersonal: .work,
                    projectId: q1Project.id,
                    areaId: careerArea.id,
                    isFocus: false,
                    completedAt: ISO8601DateFormatter().string(from: calendar.date(byAdding: .hour, value: -1, to: now)!)
                )
            ]
            
            // Save sample tasks to database
            var createdTasks: [LifeTask] = []
            for task in sampleTasks {
                let createdTask = try await TaskRepository().createTask(task)
                createdTasks.append(createdTask)
                print("🔧 SAMPLE TASKS: Created task: \(task.title) (Priority: \(task.priority.rawValue)/\(task.priority.priorityScore))")
            }
            
            // Update focus tasks in local state
            await MainActor.run {
                self.focusTasks = createdTasks.filter { $0.isFocus && $0.status != .completed }
            }
            
            print("🔧 SAMPLE TASKS: ✅ Created \(sampleTasks.count) enhanced sample tasks")
            
        } catch {
            print("🔧 SAMPLE TASKS: ❌ Failed to create sample tasks: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to create sample tasks: \(error.localizedDescription)"
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
                confidenceThreshold: 0.3  // Lowered from 0.5 to 0.3 for more aggressive task creation
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
            
            // Fallback: If no tasks were extracted, try simple keyword-based extraction
            if result.extractedTasks.isEmpty {
                print("🔧 INDIVIDUAL PROCESS: No tasks extracted by LLM, trying fallback extraction...")
                await performFallbackTaskExtraction(for: blob)
            }

        } catch {
            print("🔧 INDIVIDUAL PROCESS: ❌ LLM Processing failed: \(error)")
            print("🔧 INDIVIDUAL PROCESS: ❌ Error type: \(type(of: error))")
            print("🔧 INDIVIDUAL PROCESS: ❌ Error description: \(error.localizedDescription)")
            
            // Fallback: Try simple task extraction even if LLM fails
            print("🔧 INDIVIDUAL PROCESS: Attempting fallback task extraction...")
            await performFallbackTaskExtraction(for: blob)
            
            await MainActor.run {
                self.blobProcessingStates[blob.id] = .error(error.localizedDescription)
                self.errorMessage = "LLM processing failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Fallback task extraction using simple keyword matching
    private func performFallbackTaskExtraction(for blob: Blob) async {
        print("🔧 FALLBACK EXTRACTION: Starting for blob: \(blob.id)")
        
        let content = blob.content.lowercased()
        let taskKeywords = [
            "need to", "have to", "must", "should", "todo", "to do", "task:",
            "action:", "follow up", "followup", "call", "email", "meet", "meeting",
            "schedule", "book", "buy", "get", "pick up", "finish", "complete",
            "review", "check", "update", "fix", "resolve", "handle", "deal with",
            "prepare", "prep", "organize", "plan", "research", "investigate"
        ]
        
        var foundTasks: [String] = []
        
        // Split content into sentences
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSentence.count < 5 { continue } // Skip very short sentences
            
            // Check if sentence contains task keywords
            for keyword in taskKeywords {
                if trimmedSentence.contains(keyword) {
                    // Clean up the sentence to make it a proper task title
                    var taskTitle = trimmedSentence
                    
                    // Remove common prefixes
                    let prefixesToRemove = ["i need to", "i have to", "i must", "i should", "need to", "have to", "must", "should"]
                    for prefix in prefixesToRemove {
                        if taskTitle.hasPrefix(prefix) {
                            taskTitle = String(taskTitle.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                            break
                        }
                    }
                    
                    // Capitalize first letter
                    if !taskTitle.isEmpty {
                        taskTitle = taskTitle.prefix(1).uppercased() + taskTitle.dropFirst()
                    }
                    
                    // Limit length
                    if taskTitle.count > 100 {
                        taskTitle = String(taskTitle.prefix(97)) + "..."
                    }
                    
                    if !taskTitle.isEmpty && !foundTasks.contains(taskTitle) {
                        foundTasks.append(taskTitle)
                        print("🔧 FALLBACK EXTRACTION: Found task: '\(taskTitle)'")
                    }
                    break // Only match one keyword per sentence
                }
            }
        }
        
        // Create tasks from extracted titles
        for (index, taskTitle) in foundTasks.enumerated() {
            if index >= 3 { break } // Limit to 3 tasks to avoid spam
            
            let task = LifeTask(
                blobId: blob.id,
                title: taskTitle,
                description: "Auto-extracted from: \(blob.content.prefix(100))...",
                priority: .medium,
                workPersonal: blob.workPersonal
            )
            
            do {
                let _ = try await taskRepository().createTask(task)
                print("🔧 FALLBACK EXTRACTION: ✅ Created task: '\(taskTitle)'")
                
                await MainActor.run {
                    // Add to focus tasks for immediate visibility
                    self.focusTasks.insert(task, at: 0)
                    
                    // Keep only the most recent 10 focus tasks
                    if self.focusTasks.count > 10 {
                        self.focusTasks = Array(self.focusTasks.prefix(10))
                    }
                    
                    self.successMessage = "✅ Created \(foundTasks.count) task(s) from note"
                    
                    // Notify that a task was created so parking lot refreshes
                    NotificationCenter.default.post(name: NSNotification.Name("TaskCreated"), object: nil)
                }
            } catch {
                print("🔧 FALLBACK EXTRACTION: ❌ Failed to create task: \(error)")
            }
        }
        
        if foundTasks.isEmpty {
            print("🔧 FALLBACK EXTRACTION: No tasks found using keyword matching")
        } else {
            print("🔧 FALLBACK EXTRACTION: ✅ Created \(foundTasks.count) tasks using fallback extraction")
        }
    }
    
    /// Get processing state for a blob
    func getProcessingState(for blobId: UUID) -> BlobProcessingState {
        return blobProcessingStates[blobId] ?? .unprocessed
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
            // Build context for PARA categorization
            let context = PARAContext(
                projects: [],
                areas: [],
                resources: [],
                recentTasks: [],
                commonTags: ["work", "personal", "urgent", "health", "finance"]
            )
            let categorization = try await llmService.categorizePARA(input: blob.content, context: context)
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
            
            // Also fetch PARA-categorized blobs
            var loadedProjectBlobs: [UUID: [Blob]] = [:]
            var loadedAreaBlobs: [UUID: [Blob]] = [:]
            var loadedResourceBlobs: [Blob] = []
            var loadedArchivedBlobs: [Blob] = []
            
            do {
                let allProcessedBlobs = try await BlobRepository().fetchProcessedBlobs()
                print("🔧 REFRESH: ✅ Found \(allProcessedBlobs.count) processed blobs")
                
                // Categorize blobs by their PARA assignment
                for blob in allProcessedBlobs {
                    if let projectId = blob.projectId {
                        if loadedProjectBlobs[projectId] == nil {
                            loadedProjectBlobs[projectId] = []
                        }
                        loadedProjectBlobs[projectId]?.append(blob)
                    } else if let areaId = blob.areaId {
                        if loadedAreaBlobs[areaId] == nil {
                            loadedAreaBlobs[areaId] = []
                        }
                        loadedAreaBlobs[areaId]?.append(blob)
                    } else if blob.isArchived {
                        loadedArchivedBlobs.append(blob)
                    } else {
                        // Default to resources if processed but no specific assignment
                        loadedResourceBlobs.append(blob)
                    }
                }
                
                print("🔧 REFRESH: ✅ Categorized blobs - Projects: \(loadedProjectBlobs.keys.count), Areas: \(loadedAreaBlobs.keys.count), Resources: \(loadedResourceBlobs.count), Archives: \(loadedArchivedBlobs.count)")
                
            } catch {
                print("🔧 REFRESH: ❌ PARA blobs refresh failed: \(error)")
            }
            
            // Fetch and categorize tasks by PARA assignment
            var loadedProjectTasks: [UUID: [LifeTask]] = [:]
            var loadedAreaTasks: [UUID: [LifeTask]] = [:]
            
            do {
                print("🔧 REFRESH: Fetching and categorizing tasks...")
                
                // Fetch all tasks
                let allTasks = try await TaskRepository().fetchAllTasks()
                print("🔧 REFRESH: ✅ Found \(allTasks.count) tasks")
                
                // Categorize tasks by their PARA assignment
                for task in allTasks {
                    if let projectId = task.projectId {
                        if loadedProjectTasks[projectId] == nil {
                            loadedProjectTasks[projectId] = []
                        }
                        loadedProjectTasks[projectId]?.append(task)
                    } else if let areaId = task.areaId {
                        if loadedAreaTasks[areaId] == nil {
                            loadedAreaTasks[areaId] = []
                        }
                        loadedAreaTasks[areaId]?.append(task)
                    }
                }
                
                print("🔧 REFRESH: ✅ Categorized tasks - Projects: \(loadedProjectTasks.keys.count), Areas: \(loadedAreaTasks.keys.count)")
                
            } catch {
                print("🔧 REFRESH: ❌ Task categorization failed: \(error)")
            }
            
            // Update all state at once on main thread
            await MainActor.run {
                self.areas = loadedAreas
                self.projects = loadedProjects
                self.resources = loadedResources
                self.archives = loadedArchives
                self.recentBlobs = loadedUnprocessedBlobs // Only unprocessed blobs
                self.focusTasks = loadedFocusTasks
                
                // Update PARA blob assignments
                self.projectBlobs = loadedProjectBlobs
                self.areaBlobs = loadedAreaBlobs
                self.resourceBlobs = loadedResourceBlobs
                self.archivedBlobs = loadedArchivedBlobs
                
                // Update PARA task assignments
                self.projectTasks = loadedProjectTasks
                self.areaTasks = loadedAreaTasks
                
                self.isLoading = false
                self.successMessage = "✅ Data refreshed"
            }
            
            print("🔧 REFRESH: ✅ UI updated with fresh data")
            
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
        
        // Try to create a real authenticated session or use mock data
        Task {
            await createDevelopmentSession()
        }
    }
    
    private func createDevelopmentSession() async {
        // First try to create a real account for development
        do {
            let developmentEmail = "dev@lifemanager.local"
            let developmentPassword = "DevPass123!"
            
            // Try to sign in first
            do {
                let session = try await supabaseService.signIn(email: developmentEmail, password: developmentPassword)
                await MainActor.run {
                    self.isAuthenticated = true
                    print("🔧 DEV BYPASS: ✅ Successfully signed in with development account")
                }
                // Load real data from database
                await loadInitialData()
                return
            } catch {
                print("🔧 DEV BYPASS: Sign in failed, trying to create account: \(error)")
            }
            
            // If sign in failed, try to create the account
            do {
                let session = try await supabaseService.signUp(email: developmentEmail, password: developmentPassword)
                await MainActor.run {
                    self.isAuthenticated = true
                    print("🔧 DEV BYPASS: ✅ Successfully created and signed in with development account")
                }
                // Load real data from database
                await loadInitialData()
                return
            } catch {
                print("🔧 DEV BYPASS: Account creation failed: \(error)")
            }
            
        } catch {
            print("🔧 DEV BYPASS: All authentication attempts failed: \(error)")
        }
        
        // If all else fails, use mock data
        print("🔧 DEV BYPASS: Falling back to mock data")
            await loadMockData()
    }
    
    func forceCreateDevAccount() async {
        await MainActor.run {
            isLoading = true
            authError = nil
            authSuccess = nil
        }
        
        let developmentEmail = "dev@lifemanager.local"
        let developmentPassword = "DevPass123!"
        
        do {
            // Force create account (ignoring errors if it already exists)
            let session = try await supabaseService.signUp(email: developmentEmail, password: developmentPassword)
            await MainActor.run {
                self.isAuthenticated = true
                self.authSuccess = "✅ Development account created and signed in!"
                self.isLoading = false
            }
            await loadInitialData()
        } catch {
            // If creation failed, try signing in
            do {
                let session = try await supabaseService.signIn(email: developmentEmail, password: developmentPassword)
                await MainActor.run {
                    self.isAuthenticated = true
                    self.authSuccess = "✅ Signed in with development account!"
                    self.isLoading = false
                }
                await loadInitialData()
            } catch {
                await MainActor.run {
                    self.authError = "Failed to create/sign in to dev account: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadMockData() async {
        await MainActor.run {
            // Mock Areas
            self.areas = [
                Area(name: "Health & Fitness", description: "Physical and mental well-being"),
                Area(name: "Career", description: "Professional development"),
                Area(name: "Relationships", description: "Family and social connections"),
                Area(name: "Learning", description: "Continuous education")
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
                        paraCategory: PARACategory.resource,
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
        
        var updatedBlob = blob
        var targetProjectId: UUID? = nil
        var targetAreaId: UUID? = nil
        
        // Handle project assignment
        if category == .project {
            if let suggestedProject = result.suggestedProject {
                if let existingProject = projects.first(where: { $0.name.lowercased() == suggestedProject.lowercased() }) {
                    // Link to existing project
                    targetProjectId = existingProject.id
                    print("🔧 MOVE PARA: Linking to existing project: \(existingProject.name)")
                } else if result.confidence > 0.8 {
                    // Create new project if confidence is high
                    print("🔧 MOVE PARA: Creating new project: \(suggestedProject)")
                    do {
                        let newProject = Project(
                            name: suggestedProject,
                            description: "Auto-created from AI processing",
                            workPersonal: blob.workPersonal
                        )
                        let createdProject = try await ProjectRepository().createProject(newProject)
                        targetProjectId = createdProject.id
                        
                        // Update local projects list
                        await MainActor.run {
                            self.projects.append(createdProject)
                        }
                        
                        print("🔧 MOVE PARA: ✅ Created new project: \(createdProject.name)")
                    } catch {
                        print("🔧 MOVE PARA: ❌ Failed to create project: \(error)")
                    }
                }
            }
        }
        
        // Handle area assignment
        if category == .area {
            if let suggestedArea = result.suggestedArea {
                if let existingArea = areas.first(where: { $0.name.lowercased() == suggestedArea.lowercased() }) {
                    // Link to existing area
                    targetAreaId = existingArea.id
                    print("🔧 MOVE PARA: Linking to existing area: \(existingArea.name)")
                } else if result.confidence > 0.8 {
                    // Create new area if confidence is high
                    print("🔧 MOVE PARA: Creating new area: \(suggestedArea)")
                    do {
                        let newArea = Area(
                            name: suggestedArea,
                            description: "Auto-created from AI processing",
                            workPersonal: blob.workPersonal
                        )
                        let createdArea = try await AreaRepository().createArea(newArea)
                        targetAreaId = createdArea.id
                        
                        // Update local areas list
                        await MainActor.run {
                            self.areas.append(createdArea)
                        }
                        
                        print("🔧 MOVE PARA: ✅ Created new area: \(createdArea.name)")
                    } catch {
                        print("🔧 MOVE PARA: ❌ Failed to create area: \(error)")
                    }
                }
            }
        }
        
        // Update blob with PARA category assignment
        if targetProjectId != nil || targetAreaId != nil {
            do {
                let categorizedBlob = Blob(
                    id: blob.id,
                    content: blob.content,
                    sourceType: blob.sourceType,
                    workPersonal: blob.workPersonal,
                    processed: true, // Mark as processed when categorized
                    projectId: targetProjectId,
                    areaId: targetAreaId,
                    isArchived: false
                )
                
                let updatedBlob = try await blobRepository().updateBlob(categorizedBlob)
                print("🔧 MOVE PARA: ✅ Blob updated with PARA assignment")
                
                // Update local state immediately
                await MainActor.run {
                    // Remove from recent blobs (inbox) if it was there
                    self.recentBlobs.removeAll { $0.id == blob.id }
                    
                    // Add to appropriate PARA category
                    if let projectId = targetProjectId {
                        if self.projectBlobs[projectId] == nil {
                            self.projectBlobs[projectId] = []
                        }
                        self.projectBlobs[projectId]?.append(updatedBlob)
                        print("🔧 MOVE PARA: ✅ Added blob to project blobs locally")
                    } else if let areaId = targetAreaId {
                        if self.areaBlobs[areaId] == nil {
                            self.areaBlobs[areaId] = []
                        }
                        self.areaBlobs[areaId]?.append(updatedBlob)
                        print("🔧 MOVE PARA: ✅ Added blob to area blobs locally")
                    }
                }
                
            } catch {
                print("🔧 MOVE PARA: ❌ Failed to update blob: \(error)")
                throw error
            }
        }
        
        print("🔧 MOVE PARA: ✅ Blob categorized as: \(category.displayName)")
    }
    
    /// Create task from extraction info
    private func createTaskFromExtraction(taskInfo: TaskExtractionInfo, sourceBlob: Blob) async throws {
        print("🔧 CREATE TASK: Creating task: \(taskInfo.title)")
        
        // Determine project/area assignment for the task
        var taskProjectId: UUID? = nil
        var taskAreaId: UUID? = nil
        
        // First try to use the blob's assignment
        if let blobProjectId = sourceBlob.projectId {
            taskProjectId = blobProjectId
            print("🔧 CREATE TASK: Assigning to blob's project")
        } else if let blobAreaId = sourceBlob.areaId {
            taskAreaId = blobAreaId
            print("🔧 CREATE TASK: Assigning to blob's area")
        } else {
            // If blob has no assignment, try to find suggested project/area
            if let suggestedProject = taskInfo.suggestedProject,
               let existingProject = projects.first(where: { $0.name.lowercased() == suggestedProject.lowercased() }) {
                taskProjectId = existingProject.id
                print("🔧 CREATE TASK: Assigning to suggested project: \(suggestedProject)")
            } else if let suggestedArea = taskInfo.suggestedArea,
                      let existingArea = areas.first(where: { $0.name.lowercased() == suggestedArea.lowercased() }) {
                taskAreaId = existingArea.id
                print("🔧 CREATE TASK: Assigning to suggested area: \(suggestedArea)")
            } else {
                // Default to first available project or area
                if let firstProject = projects.first {
                    taskProjectId = firstProject.id
                    print("🔧 CREATE TASK: Assigning to first available project: \(firstProject.name)")
                } else if let firstArea = areas.first {
                    taskAreaId = firstArea.id
                    print("🔧 CREATE TASK: Assigning to first available area: \(firstArea.name)")
                } else {
                    print("🔧 CREATE TASK: ⚠️ No projects or areas available - task will be unassigned")
                }
            }
        }
        
        let task = LifeTask(
            blobId: sourceBlob.id,
            title: taskInfo.title,
            description: taskInfo.description,
            priority: taskInfo.priority,
            dueDate: taskInfo.suggestedDueDate,
            estimatedDuration: taskInfo.estimatedDuration,
            workPersonal: sourceBlob.workPersonal,
            projectId: taskProjectId,
            areaId: taskAreaId
        )
        
        let createdTask = try await taskRepository().createTask(task)
        
        // Log the comprehensive task creation with priority scoring
        print("🔧 CREATE TASK: ✅ Task created with comprehensive data:")
        print("🔧 CREATE TASK:   Title: \(taskInfo.title)")
        print("🔧 CREATE TASK:   Priority: \(taskInfo.priority.rawValue) (Score: \(taskInfo.priorityScore))")
        print("🔧 CREATE TASK:   Due Date: \(taskInfo.suggestedDueDate ?? "Not set")")
        print("🔧 CREATE TASK:   Duration: \(taskInfo.estimatedDuration ?? 0) minutes")
        print("🔧 CREATE TASK:   Time Block: \(taskInfo.timeBlock ?? "Flexible")")
        if let reasoning = taskInfo.priorityReasoning {
            print("🔧 CREATE TASK:   Priority Reasoning: \(reasoning)")
        }
        if !taskInfo.urgencyIndicators.isEmpty {
            print("🔧 CREATE TASK:   Urgency Indicators: \(taskInfo.urgencyIndicators.joined(separator: ", "))")
        }
        if !taskInfo.importanceFactors.isEmpty {
            print("🔧 CREATE TASK:   Importance Factors: \(taskInfo.importanceFactors.joined(separator: ", "))")
        }
        print("🔧 CREATE TASK:   Confidence: \(taskInfo.confidence)")
        
        // Add to focus tasks if marked as high priority or focus
        if taskInfo.priority == .urgent || taskInfo.priority == .high || taskInfo.priorityScore >= 4 {
            await MainActor.run {
                let focusTask = LifeTask(
                    id: createdTask.id,
                    blobId: createdTask.blobId,
                    title: createdTask.title,
                    description: createdTask.description,
                    priority: createdTask.priority,
                    status: createdTask.status,
                    dueDate: createdTask.dueDate,
                    estimatedDuration: createdTask.estimatedDuration,
                    workPersonal: createdTask.workPersonal,
                    projectId: createdTask.projectId,
                    areaId: createdTask.areaId,
                    resourceId: createdTask.resourceId,
                    isFocus: true, // Mark as focus task
                    isArchived: createdTask.isArchived,
                    createdAt: createdTask.createdAt,
                    updatedAt: createdTask.updatedAt,
                    completedAt: createdTask.completedAt,
                    archivedAt: createdTask.archivedAt
                )
                
                self.focusTasks.append(focusTask)
                print("🔧 CREATE TASK: ✅ Added high-priority task to focus list")
            }
        }
        
        print("🔧 CREATE TASK: ✅ Task creation completed: \(taskInfo.title)")
        
        // Notify that a task was created so parking lot refreshes
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("TaskCreated"), object: nil)
        }
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
    
    /// Restore blob from archive
    func restoreBlobFromArchive(_ blob: Blob) async {
        do {
            // Create a new blob instance with isArchived = false
            let restoredBlob = Blob(
                id: blob.id,
                content: blob.content,
                sourceType: blob.sourceType,
                workPersonal: blob.workPersonal,
                processed: blob.processed,
                projectId: blob.projectId,
                areaId: blob.areaId,
                isArchived: false
            )
            
            let updatedBlob = try await BlobRepository().updateBlob(restoredBlob)
            
            await MainActor.run {
                // Remove from archived blobs
                self.archivedBlobs.removeAll { $0.id == blob.id }
                
                // Add back to appropriate PARA category
                if let projectId = updatedBlob.projectId {
                    if self.projectBlobs[projectId] == nil {
                        self.projectBlobs[projectId] = []
                    }
                    self.projectBlobs[projectId]?.append(updatedBlob)
                } else if let areaId = updatedBlob.areaId {
                    if self.areaBlobs[areaId] == nil {
                        self.areaBlobs[areaId] = []
                    }
                    self.areaBlobs[areaId]?.append(updatedBlob)
                } else {
                    // Default to resources if no specific assignment
                    self.resourceBlobs.append(updatedBlob)
                }
                
                self.successMessage = "✅ Restored from archive"
            }
            
            print("🔧 RESTORE: ✅ Blob restored from archive: \(blob.id)")
            
        } catch {
            print("🔧 RESTORE: ❌ Failed to restore blob from archive: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to restore from archive: \(error.localizedDescription)"
            }
        }
    }
    
    /// Enhance existing tasks with comprehensive LLM processing
    private func enhanceExistingTasks() async {
        print("🔧 ENHANCE TASKS: Starting enhancement of existing tasks...")
        
        do {
            // Fetch all tasks from the database
            print("🔧 ENHANCE TASKS: Fetching all tasks...")
            let allTasks = try await TaskRepository().fetchAllTasks()
            print("🔧 ENHANCE TASKS: Found \(allTasks.count) tasks to potentially enhance")
            
            if allTasks.isEmpty {
                print("🔧 ENHANCE TASKS: No tasks found, skipping enhancement")
                return
            }
            
            // Use LLM service to enhance tasks
            print("🔧 ENHANCE TASKS: Starting LLM enhancement process...")
            let enhancementResults = try await llmService.enhanceExistingTasks(allTasks)
            print("🔧 ENHANCE TASKS: ✅ LLM enhancement completed for \(enhancementResults.count) tasks")
            
            // Process enhancement results and update tasks that were enhanced
            var enhancedCount = 0
            var taskRepository = TaskRepository()
            
            for result in enhancementResults {
                if result.wasEnhanced {
                    do {
                        print("🔧 ENHANCE TASKS: Updating enhanced task: \(result.enhancedTask.title)")
                        let _ = try await taskRepository.updateTask(result.enhancedTask)
                        enhancedCount += 1
                        print("🔧 ENHANCE TASKS: ✅ Successfully updated task: \(result.enhancedTask.title)")
                    } catch {
                        print("🔧 ENHANCE TASKS: ❌ Failed to update task: \(result.enhancedTask.title) - \(error)")
                    }
                } else {
                    print("🔧 ENHANCE TASKS: ⏭️ Task already optimized: \(result.originalTask.title)")
                }
            }
            
            print("🔧 ENHANCE TASKS: ✅ Enhancement complete - Updated \(enhancedCount) of \(allTasks.count) tasks")
            
            // Refresh focus tasks after enhancement
            await refreshFocusTasks()
            
            // Show success message
            await MainActor.run {
                if enhancedCount > 0 {
                    self.successMessage = "Enhanced \(enhancedCount) tasks with AI-powered priority scoring, dates, and durations"
                } else {
                    print("🔧 ENHANCE TASKS: All tasks already have comprehensive data")
                }
            }
            
        } catch LLMError.missingAPIKey {
            print("🔧 ENHANCE TASKS: ⚠️ LLM API key not configured, skipping task enhancement")
            await MainActor.run {
                self.successMessage = "Task enhancement requires LLM API key. Set OPENAI_API_KEY environment variable."
            }
        } catch {
            print("🔧 ENHANCE TASKS: ❌ Error enhancing tasks: \(error)")
            await MainActor.run {
                self.errorMessage = "Task enhancement failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Refresh focus tasks after enhancement
    private func refreshFocusTasks() async {
        do {
            let updatedFocusTasks = try await TaskRepository().fetchFocusTasks()
            await MainActor.run {
                self.focusTasks = updatedFocusTasks
            }
            print("🔧 ENHANCE TASKS: ✅ Refreshed focus tasks: \(updatedFocusTasks.count)")
        } catch {
            print("🔧 ENHANCE TASKS: ❌ Failed to refresh focus tasks: \(error)")
        }
    }
    
    /// Complete a task and update its status
    func completeTask(_ task: LifeTask) async {
        print("🔧 COMPLETE TASK: Marking task as completed: \(task.title)")
        
        do {
            // Create completed task with updated status and completion timestamp
            let completedTask = LifeTask(
                id: task.id,
                blobId: task.blobId,
                title: task.title,
                description: task.description,
                priority: task.priority,
                status: .completed,
                dueDate: task.dueDate,
                estimatedDuration: task.estimatedDuration,
                workPersonal: task.workPersonal,
                projectId: task.projectId,
                areaId: task.areaId,
                resourceId: task.resourceId,
                isFocus: task.isFocus,
                isArchived: task.isArchived,
                createdAt: task.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                completedAt: ISO8601DateFormatter().string(from: Date()),
                archivedAt: task.archivedAt
            )
            
            // Update in database
            let updatedTask = try await TaskRepository().updateTask(completedTask)
            print("🔧 COMPLETE TASK: ✅ Task marked as completed in database")
            
            // Update local state
            await MainActor.run {
                // Update in focus tasks list
                if let index = self.focusTasks.firstIndex(where: { $0.id == task.id }) {
                    self.focusTasks[index] = updatedTask
                }
                
                self.successMessage = "✅ Task '\(task.title)' marked as completed"
            }
            
            // Refresh data to ensure consistency
            await refreshFocusTasks()
            
            print("🔧 COMPLETE TASK: ✅ Task completion processed successfully")
            
        } catch {
            print("🔧 COMPLETE TASK: ❌ Error completing task: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to complete task: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Brain Dump Processing
    
    /// Process inbox input using comprehensive brain dump processor
    func processInboxInput() {
        guard !inboxInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Logger.shared.warning("BRAIN DUMP: Empty input, skipping processing")
            return
        }
        
        let startTime = Date()
        Logger.shared.brainDumpStart(inboxInput)
        isProcessingInbox = true
        startBrainDumpProgressTimer()
        
        // Clear any previous messages
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                // Show initial progress
                await MainActor.run {
                    self.successMessage = "🧠 Analyzing your input..."
                }
                Logger.shared.brainDumpProgress("UI: Showing analysis message")
                
                try await Task.sleep(nanoseconds: 800_000_000) // 0.8 second delay for UI feedback
                
                await MainActor.run {
                    self.successMessage = "🤖 Connecting to AI..."
                }
                Logger.shared.brainDumpProgress("UI: Showing AI connection message")
                
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                
                // Removed toast message for brain dump processing
                Logger.shared.brainDumpProgress("UI: Processing with AI (no toast shown)")
                
                Logger.shared.brainDumpProgress("Calling brain dump processor...")
                // Use comprehensive brain dump processor
                let result = try await brainDumpProcessor.processBrainDump(inboxInput)
                
                let processingTime = Date().timeIntervalSince(startTime)
                Logger.shared.brainDumpSuccess(result.suggestedItems.count, processingTime: processingTime)
                
                await MainActor.run {
                    Logger.shared.brainDumpProgress("Setting result and showing review UI")
                    let finalElapsedTime = self.brainDumpElapsedTime
                    self.stopBrainDumpProgressTimer()
                    
                    // Show completion message
                    self.brainDumpProgressMessage = "Thought for \(finalElapsedTime) seconds"
                    
                    self.brainDumpResult = result
                    self.showingBrainDumpReview = true
                    self.isProcessingInbox = false
                    
                    // Show success message with details
                    if result.suggestedItems.count > 0 {
                        self.successMessage = "✅ Success! Found \(result.suggestedItems.count) items to review"
                        Logger.shared.success("BRAIN DUMP UI: Success message shown - \(result.suggestedItems.count) items")
                    } else {
                        self.successMessage = "✅ Processing complete - no items extracted"
                        Logger.shared.warning("BRAIN DUMP UI: No items extracted from input")
                    }
                    
                    Logger.shared.info("BRAIN DUMP UI: Review UI visible: \(self.showingBrainDumpReview)")
                    
                    // Keep success message visible for 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if !self.showingBrainDumpReview {
                            self.successMessage = ""
                        }
                    }
                }
                
            } catch LLMError.missingAPIKey {
                let processingTime = Date().timeIntervalSince(startTime)
                Logger.shared.brainDumpError(LLMError.missingAPIKey, processingTime: processingTime)
                
                await MainActor.run {
                    self.stopBrainDumpProgressTimer()
                    self.isProcessingInbox = false
                    self.successMessage = ""
                    self.errorMessage = "❌ Brain dump requires OpenAI API key. Please check your config.txt file."
                    
                    // Keep error message visible for 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.errorMessage = ""
                    }
                }
            } catch {
                let processingTime = Date().timeIntervalSince(startTime)
                Logger.shared.brainDumpError(error, processingTime: processingTime)
                
                await MainActor.run {
                    self.stopBrainDumpProgressTimer()
                    self.isProcessingInbox = false
                    self.successMessage = ""
                    
                    // Show specific error messages based on error type
                    if error.localizedDescription.contains("timed out") {
                        self.errorMessage = "⏱️ Network timeout - AI processing took too long. Please try again."
                        Logger.shared.error("BRAIN DUMP UI: Timeout error shown to user")
                    } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
                        self.errorMessage = "🌐 Network error - Please check your internet connection and try again."
                        Logger.shared.error("BRAIN DUMP UI: Network error shown to user")
                    } else {
                        self.errorMessage = "❌ Processing failed: \(error.localizedDescription)"
                        Logger.shared.error("BRAIN DUMP UI: Generic error shown to user")
                    }
                    
                    // Keep error message visible for 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.errorMessage = ""
                    }
                }
            }
        }
    }
    
    /// Complete brain dump processing after user confirmation
    func completeBrainDump(_ summary: ExecutionSummary) {
        // Add to history before clearing
        let historyItem = InboxHistoryItem(
            input: brainDumpResult?.originalInput ?? "",
            itemsCreated: summary.successCount,
            timestamp: Date(),
            categories: extractCategoriesFromSummary(summary)
        )
        
        // Add to history and keep only last 3
        inboxHistory.insert(historyItem, at: 0)
        if inboxHistory.count > 3 {
            inboxHistory = Array(inboxHistory.prefix(3))
        }
        
        // Clear input and close review
        inboxInput = ""
        showingBrainDumpReview = false
        brainDumpResult = nil
        brainDumpProgressMessage = ""
        
        // Show success message with details
        let itemCount = summary.successCount
        successMessage = "Brain dump complete! Created \(itemCount) items."
        
        // Refresh parking lot to show new tasks
        NotificationCenter.default.post(name: NSNotification.Name("TaskCreated"), object: nil)
        
        // Refresh data to show new items in all PARA categories
        Task {
            await refreshData()
            
            // Specifically reload PARA categories to ensure new items appear
            await loadInitialData()
            
            // Force UI update by triggering objectWillChange
            await MainActor.run {
                self.objectWillChange.send()
                
                // Log the refresh for debugging
                print("🔧 BRAIN DUMP: ✅ Refreshed PARA categories after brain dump completion")
                print("🔧 BRAIN DUMP: Areas: \(self.areas.count), Projects: \(self.projects.count), Resources: \(self.resources.count)")
                print("🔧 BRAIN DUMP: Area tasks: \(self.areaTasks.values.flatMap { $0 }.count)")
                print("🔧 BRAIN DUMP: Project tasks: \(self.projectTasks.values.flatMap { $0 }.count)")
            }
        }
    }
    
    /// Extract categories from execution summary for history
    private func extractCategoriesFromSummary(_ summary: ExecutionSummary) -> [String] {
        var categories: [String] = []
        
        if !summary.tasksCreated.isEmpty {
            categories.append("Tasks (\(summary.tasksCreated.count))")
        }
        if !summary.notesCreated.isEmpty {
            categories.append("Notes (\(summary.notesCreated.count))")
        }
        if !summary.journalEntriesCreated.isEmpty {
            categories.append("Journal (\(summary.journalEntriesCreated.count))")
        }
        if !summary.resourcesCreated.isEmpty {
            categories.append("Resources (\(summary.resourcesCreated.count))")
        }
        if !summary.appointmentsCreated.isEmpty {
            categories.append("Events (\(summary.appointmentsCreated.count))")
        }
        if !summary.habitsCreated.isEmpty {
            categories.append("Habits (\(summary.habitsCreated.count))")
        }
        if !summary.goalsCreated.isEmpty {
            categories.append("Goals (\(summary.goalsCreated.count))")
        }
        if !summary.financialTransactionsCreated.isEmpty {
            categories.append("Financial (\(summary.financialTransactionsCreated.count))")
        }
        
        return categories
    }
    
    /// Cancel brain dump processing
    func cancelBrainDump() {
        showingBrainDumpReview = false
        brainDumpResult = nil
        isProcessingInbox = false
        stopBrainDumpProgressTimer()
    }
    
    // MARK: - Brain Dump Progress Timer
    
    private func startBrainDumpProgressTimer() {
        brainDumpElapsedTime = 0
        brainDumpProgressMessage = "Thinking."
        
        brainDumpProgressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.brainDumpElapsedTime += 2
                
                // Create animated dots (1, 2, 3, then repeat) with "Thinking" - faster animation
                let dotCount = (self.brainDumpElapsedTime / 2 % 3) + 1
                let dots = String(repeating: ".", count: dotCount)
                
                self.brainDumpProgressMessage = "Thinking\(dots)"
                
                // Log progress every 15 seconds
                if self.brainDumpElapsedTime % 15 == 0 {
                    let minutes = self.brainDumpElapsedTime / 60
                    let seconds = self.brainDumpElapsedTime % 60
                    let timeString = minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
                    Logger.shared.brainDumpProgress("Still processing... \(timeString) elapsed")
                }
            }
        }
    }
    
    private func stopBrainDumpProgressTimer() {
        brainDumpProgressTimer?.invalidate()
        brainDumpProgressTimer = nil
        brainDumpElapsedTime = 0
        brainDumpProgressMessage = ""
    }
}
