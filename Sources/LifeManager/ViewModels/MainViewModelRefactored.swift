//
// MainViewModelRefactored.swift
// LifeManager
//
// Refactored MainViewModel using extracted ViewModels for better separation of concerns
// This is the new lean version that delegates to specialized ViewModels
//

import Foundation
import SwiftUI
import Combine

/// Refactored Main view model that coordinates specialized ViewModels
/// Acts as a facade/coordinator for the app's main functionality
@MainActor
class MainViewModelRefactored: ObservableObject {
    
    // MARK: - Child ViewModels
    
    @Published private(set) var coordinator: MainCoordinator
    @Published private(set) var brainDumpVM: BrainDumpViewModel
    @Published private(set) var paraVM: PARAManagementViewModel
    @Published private(set) var syncVM: SyncViewModel
    @Published private(set) var settingsVM: SettingsViewModel
    
    // MARK: - Core Services
    
    private let supabaseService = SupabaseService.shared
    private let llmService = LLMService.shared
    private let contextMemoryCoordinator = ContextMemoryCoordinator.shared
    private let logger = Logger.shared
    
    // MARK: - Authentication State
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    @Published var authSuccess: String?
    
    // MARK: - Development Mode
    
    private var isDevelopmentMode = true
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        logger.info("MainViewModel: Initializing refactored version")
        
        // Initialize child ViewModels
        self.coordinator = MainCoordinator()
        self.brainDumpVM = BrainDumpViewModel()
        self.paraVM = PARAManagementViewModel()
        self.syncVM = SyncViewModel()
        self.settingsVM = SettingsViewModel()
        
        setupBindings()
        setupAuthListener()
        
        // Initial data load
        Task {
            await initializeApp()
        }
        
        logger.info("MainViewModel: Initialization complete")
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind brain dump results to PARA updates
        brainDumpVM.$lastProcessedItems
            .sink { [weak self] items in
                guard !items.isEmpty else { return }
                Task {
                    await self?.paraVM.loadAllPARAData()
                }
            }
            .store(in: &cancellables)
        
        // Bind sync status to UI updates
        syncVM.$syncStatus
            .sink { [weak self] status in
                switch status {
                case .failed(let error):
                    self?.coordinator.showAlert(.error(error))
                case .completed:
                    self?.logger.success("Sync completed successfully")
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Bind settings changes
        settingsVM.objectWillChange
            .sink { [weak self] _ in
                self?.applySettingsChanges()
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthListener() {
        Task {
            for await authState in supabaseService.authStateChanges {
                await handleAuthStateChange(authState)
            }
        }
    }
    
    // MARK: - Initialization
    
    private func initializeApp() async {
        isLoading = true
        
        do {
            // Check authentication
            if let session = supabaseService.currentSession {
                await handleSuccessfulAuth(session)
            } else if isDevelopmentMode {
                await setupDevelopmentMode()
            }
            
            // Load initial data
            if isAuthenticated {
                await loadAllData()
            }
            
        } catch {
            logger.error("MainViewModel: Initialization failed: \(error)")
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        
        do {
            let session = try await supabaseService.signIn(email: email, password: password)
            await handleSuccessfulAuth(session)
            authSuccess = "Successfully signed in!"
            
        } catch {
            logger.error("Sign in failed: \(error)")
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        authError = nil
        
        do {
            let session = try await supabaseService.signUp(email: email, password: password)
            await handleSuccessfulAuth(session)
            authSuccess = "Account created successfully!"
            
        } catch {
            logger.error("Sign up failed: \(error)")
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabaseService.signOut()
            
            // Clear all data
            await clearAllData()
            
            isAuthenticated = false
            currentUser = nil
            authSuccess = "Signed out successfully"
            
        } catch {
            logger.error("Sign out failed: \(error)")
            authError = error.localizedDescription
        }
    }
    
    private func handleAuthStateChange(_ authState: AuthState) async {
        switch authState {
        case .signedIn(let session):
            await handleSuccessfulAuth(session)
        case .signedOut:
            isAuthenticated = false
            currentUser = nil
            await clearAllData()
        }
    }
    
    private func handleSuccessfulAuth(_ session: Session) async {
        isAuthenticated = true
        
        // Load user profile
        if let userId = UUID(uuidString: session.user.id) {
            currentUser = try? await supabaseService.fetchUser(userId: userId)
        }
        
        // Load all data
        await loadAllData()
        
        // Start sync
        await syncVM.syncNow()
        
        logger.success("Authentication successful for user: \(session.user.email ?? "unknown")")
    }
    
    private func setupDevelopmentMode() async {
        logger.info("Running in development mode")
        
        isAuthenticated = true
        currentUser = User(
            id: UUID(),
            email: "dev@lifemanager.local",
            name: "Development User",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await loadAllData()
    }
    
    // MARK: - Data Management
    
    func loadAllData() async {
        logger.info("Loading all data...")
        
        async let paraData = paraVM.loadAllPARAData()
        async let contextData = contextMemoryCoordinator.loadContext()
        async let settingsData = settingsVM.loadSettings()
        
        await paraData
        await contextData
        await settingsData
        
        logger.success("All data loaded successfully")
    }
    
    private func clearAllData() async {
        await paraVM.loadAllPARAData() // This will load empty data
        await contextMemoryCoordinator.clearAllContext()
        brainDumpVM.clearInput()
    }
    
    // MARK: - Brain Dump Processing
    
    func processBrainDump(_ input: String) async {
        brainDumpVM.inputText = input
        await brainDumpVM.processBrainDump()
        
        // Update context memory with results
        if !brainDumpVM.lastProcessedItems.isEmpty {
            await contextMemoryCoordinator.addToContext(brainDumpVM.lastProcessedItems)
        }
        
        // Sync changes
        if settingsVM.syncVM.autoSyncEnabled {
            await syncVM.syncNow()
        }
    }
    
    // MARK: - Quick Actions
    
    func quickAddTask(_ title: String) async {
        let task = LifeTask(
            id: UUID(),
            userId: currentUser?.id ?? UUID(),
            title: title,
            isCompleted: false,
            priority: .medium,
            workPersonal: .personal,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            let saved = try await supabaseService.insert(task, into: "tasks")
            
            // Add to context
            let paraItem = PARAItem(
                id: saved.id,
                content: saved.title,
                category: .task,
                workPersonal: saved.workPersonal,
                createdAt: saved.createdAt,
                updatedAt: saved.updatedAt
            )
            
            await contextMemoryCoordinator.addToContext([paraItem])
            
            coordinator.showAlert(.success("Task added successfully"))
            
        } catch {
            logger.error("Failed to add task: \(error)")
            coordinator.showAlert(.error("Failed to add task"))
        }
    }
    
    func quickAddProject(_ name: String, description: String?) async {
        let project = Project(
            id: UUID(),
            userId: currentUser?.id ?? UUID(),
            name: name,
            description: description,
            status: .active,
            deadline: nil,
            workPersonal: .personal,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await paraVM.createProject(project)
            coordinator.showAlert(.success("Project created successfully"))
            
        } catch {
            logger.error("Failed to create project: \(error)")
            coordinator.showAlert(.error("Failed to create project"))
        }
    }
    
    // MARK: - Settings Application
    
    private func applySettingsChanges() {
        // Apply theme
        switch settingsVM.appTheme {
        case .dark:
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        case .light:
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        case .system:
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
        
        // Apply other settings
        logger.setVerbose(settingsVM.verboseLogging)
        
        // Update sync settings
        syncVM.autoSyncEnabled = settingsVM.syncVM.autoSyncEnabled
        syncVM.syncInterval = settingsVM.syncVM.syncInterval
    }
    
    // MARK: - Navigation Helpers
    
    func navigateToTab(_ tab: MainTab) {
        coordinator.navigate(to: tab)
    }
    
    func showSettings() {
        coordinator.openSettings()
    }
    
    func showCalendar() {
        coordinator.openCalendar()
    }
    
    func showReview() {
        coordinator.openReview()
    }
    
    // MARK: - Search
    
    func search(_ query: String) async {
        guard !query.isEmpty else {
            paraVM.searchText = ""
            return
        }
        
        paraVM.searchText = query
        
        // Also search in context
        let contextResults = await contextMemoryCoordinator.searchContext(query)
        
        logger.info("Search completed: \(paraVM.filteredProjects.count) projects, \(contextResults.count) context items")
    }
}

// MARK: - Alert Extensions

extension AlertItem {
    static func success(_ message: String) -> AlertItem {
        AlertItem(
            title: "Success",
            message: message,
            primaryButton: .default(Text("OK")),
            secondaryButton: nil
        )
    }
}

// MARK: - Supporting Types

enum AuthState {
    case signedIn(Session)
    case signedOut
}

struct Session {
    let user: SessionUser
    let accessToken: String
    let refreshToken: String?
}

struct SessionUser {
    let id: String
    let email: String?
}