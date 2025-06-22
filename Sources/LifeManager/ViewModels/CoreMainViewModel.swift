//
// CoreMainViewModel.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - Core App State Management
// Extracted from MainViewModel as part of Phase 2A decomposition
// Manages authentication, core app lifecycle, and coordination between ViewModels
//

import Foundation
import SwiftUI

/// Core application view model that coordinates all other ViewModels
/// Manages authentication, app lifecycle, and central coordination
/// Extracted from MainViewModel for better separation of concerns
@MainActor
class CoreMainViewModel: ObservableObject {
    
    // MARK: - Sub-ViewModels
    
    @Published var navigationVM = NavigationViewModel()
    @Published var paraDataVM = PARADataViewModel()
    @Published var brainDumpVM = BrainDumpViewModel()
    
    // MARK: - Authentication State
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    @Published var authSuccess: String?
    
    // MARK: - Development Mode
    
    private var isDevelopmentMode = false // FIXED: Set to false for production deployment
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    init() {
        logger.info("🔧 CORE: MainViewModel init() started")
        
        // Test blob serialization on startup
        Task {
            logger.info("🔧 CORE: Testing blob serialization")
            await supabaseService.testBlobSerialization()
            logger.info("🔧 CORE: Blob serialization test completed")
        }
        
        logger.info("🔧 CORE: Setting up auth listener")
        setupAuthListener()
        
        // Start log monitoring automatically
        startLogMonitoring()
        
        Task {
            logger.info("🔧 CORE: Loading initial data")
            await loadInitialData()
            logger.info("🔧 CORE: Initial data loading completed")
        }
        
        logger.info("🔧 CORE: MainViewModel init() completed")
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
                logger.success("🔧 CORE: Log monitoring started automatically")
            } catch {
                logger.error("🔧 CORE: Failed to start log monitoring: \(error)")
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
            authSuccess = nil
        }
        
        logger.info("🔐 AUTH: Attempting sign in for email: \(email)")
        
        do {
            let session = try await supabaseService.signIn(email: email, password: password)
            let user = User(
                id: session.user.id.uuidString,
                email: session.user.email ?? email,
                createdAt: session.user.createdAt.ISO8601Format()
            )
            
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
                isLoading = false
                authSuccess = "Successfully signed in!"
                logger.success("🔐 AUTH: Sign in successful for user: \(user.email)")
            }
            
            await loadInitialData()
            
        } catch {
            await MainActor.run {
                isLoading = false
                authError = error.localizedDescription
                logger.error("🔐 AUTH: Sign in failed: \(error)")
            }
        }
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            authError = nil
            authSuccess = nil
        }
        
        logger.info("🔐 AUTH: Attempting sign up for email: \(email)")
        
        do {
            let session = try await supabaseService.signUp(email: email, password: password)
            
            if let session = session {
                let user = User(
                    id: session.user.id.uuidString,
                    email: session.user.email ?? email,
                    createdAt: session.user.createdAt.ISO8601Format()
                )
                
                await MainActor.run {
                    currentUser = user
                    isAuthenticated = true
                    isLoading = false
                    authSuccess = "Account created successfully!"
                    logger.success("🔐 AUTH: Sign up successful for user: \(user.email)")
                }
                
                await loadInitialData()
            } else {
                await MainActor.run {
                    isLoading = false
                    authError = "Sign up failed - confirmation may be required"
                    logger.error("🔐 AUTH: Sign up returned no session")
                }
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                authError = error.localizedDescription
                logger.error("🔐 AUTH: Sign up failed: \(error)")
            }
        }
    }
    
    /// Sign out current user
    func signOut() async {
        logger.info("🔐 AUTH: Signing out user")
        
        do {
            try await supabaseService.signOut()
            
            await MainActor.run {
                currentUser = nil
                isAuthenticated = false
                authSuccess = "Successfully signed out!"
                logger.success("🔐 AUTH: Sign out successful")
            }
            
            clearData()
            
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
                logger.error("🔐 AUTH: Sign out failed: \(error)")
            }
        }
    }
    
    /// Development bypass authentication
    func bypassAuth() async {
        guard isDevelopmentMode else {
            logger.warning("🔐 AUTH: Bypass attempted but not in development mode")
            return
        }
        
        logger.info("🔐 AUTH: Using development bypass")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Placeholder development user
            let devUser = User(
                id: "00000000-0000-0000-0000-000000000001",
                email: "dev@lifemanager.local",
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            await MainActor.run {
                currentUser = devUser
                isAuthenticated = true
                isLoading = false
                authSuccess = "Development mode activated!"
                logger.success("🔐 AUTH: Development bypass successful")
            }
            
            await loadInitialData()
            
        } catch {
            await MainActor.run {
                isLoading = false
                authError = "Development bypass failed: \(error.localizedDescription)"
                logger.error("🔐 AUTH: Development bypass failed: \(error)")
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Load initial data when authenticated
    private func loadInitialData() async {
        guard isAuthenticated else {
            logger.info("📊 CORE: Skipping data load - not authenticated")
            return
        }
        
        logger.info("📊 CORE: Loading initial application data")
        
        await MainActor.run {
            isLoading = true
        }
        
        // Load data in parallel across ViewModels
        async let paraDataLoad = paraDataVM.loadAllData()
        
        // Wait for all data to load
        await paraDataLoad
        
        await MainActor.run {
            isLoading = false
        }
        
        logger.success("📊 CORE: Initial data loading completed")
    }
    
    /// Clear all data on sign out
    private func clearData() {
        logger.info("📊 CORE: Clearing all application data")
        
        // Clear navigation state
        navigationVM.clearSelection()
        navigationVM.clearSearch()
        navigationVM.clearMessages()
        
        // Clear PARA data
        paraDataVM.areas = []
        paraDataVM.projects = []
        paraDataVM.resources = []
        paraDataVM.archives = []
        paraDataVM.recentBlobs = []
        paraDataVM.focusTasks = []
        paraDataVM.projectBlobs = [:]
        paraDataVM.areaBlobs = [:]
        paraDataVM.resourceBlobs = []
        paraDataVM.archivedBlobs = []
        paraDataVM.projectTasks = [:]
        paraDataVM.areaTasks = [:]
        
        // Clear brain dump state
        brainDumpVM.dismissBrainDumpReview()
        brainDumpVM.cancelBrainDumpProcessing()
        brainDumpVM.cancelBatchProcessing()
        
        logger.info("📊 CORE: Data cleared successfully")
    }
    
    // MARK: - Refresh Actions
    
    /// Refresh all application data
    func refreshAllData() async {
        logger.info("🔄 CORE: Refreshing all application data")
        
        await MainActor.run {
            isLoading = true
        }
        
        await paraDataVM.forceRefresh()
        
        await MainActor.run {
            isLoading = false
        }
        
        navigationVM.showSuccess("Data refreshed successfully!")
        logger.success("🔄 CORE: Data refresh completed")
    }
    
    /// Refresh specific PARA category
    func refreshCategory(_ category: PARACategory) async {
        logger.info("🔄 CORE: Refreshing \(category) data")
        
        await paraDataVM.refreshCategory(category)
        navigationVM.showSuccess("\(category.rawValue.capitalized) data refreshed!")
        
        logger.success("🔄 CORE: \(category) refresh completed")
    }
    
    // MARK: - Error Handling
    
    /// Handle global application errors
    func handleError(_ error: Error, context: String = "") {
        let errorMessage = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        
        navigationVM.showError(errorMessage)
        logger.error("🚨 CORE: Application error - \(errorMessage)")
    }
    
    /// Handle success messages
    func handleSuccess(_ message: String) {
        navigationVM.showSuccess(message)
        logger.success("✅ CORE: \(message)")
    }
    
    // MARK: - App State Management
    
    /// Get current application state summary
    func getAppStateSummary() -> AppStateSummary {
        let paraStats = paraDataVM.getStatistics()
        let processingStats = brainDumpVM.getProcessingStatistics()
        
        return AppStateSummary(
            isAuthenticated: isAuthenticated,
            currentUser: currentUser?.email,
            selectedView: navigationVM.selectedView,
            paraStatistics: paraStats,
            processingStatistics: processingStats,
            isProcessing: brainDumpVM.isProcessingInbox || paraDataVM.isLoadingData,
            lastDataRefresh: paraDataVM.lastDataRefresh
        )
    }
    
    /// Check if user has completed onboarding
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    /// Mark onboarding as completed
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        logger.info("🎯 CORE: Onboarding completed")
    }
    
    // MARK: - Development Utilities
    
    /// Enable/disable development mode
    func setDevelopmentMode(_ enabled: Bool) {
        isDevelopmentMode = enabled
        logger.info("🔧 CORE: Development mode \(enabled ? "enabled" : "disabled")")
    }
    
    /// Get development mode status
    func getDevelopmentMode() -> Bool {
        return isDevelopmentMode
    }
    
    /// Reset application to initial state (development only)
    func resetApplication() {
        guard isDevelopmentMode else {
            logger.warning("🔧 CORE: Reset attempted but not in development mode")
            return
        }
        
        logger.info("🔧 CORE: Resetting application to initial state")
        
        Task {
            await signOut()
            
            // Clear all UserDefaults
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "inboxHistory")
            
            // Clear brain dump history
            brainDumpVM.clearInboxHistory()
            
            logger.success("🔧 CORE: Application reset completed")
            handleSuccess("Application reset to initial state")
        }
    }
}

// MARK: - Supporting Types

struct AppStateSummary {
    let isAuthenticated: Bool
    let currentUser: String?
    let selectedView: PARAView
    let paraStatistics: PARAStatistics
    let processingStatistics: ProcessingStatistics
    let isProcessing: Bool
    let lastDataRefresh: Date?
    
    var summary: String {
        var parts: [String] = []
        
        if isAuthenticated {
            parts.append("Authenticated: \(currentUser ?? "Unknown")")
        } else {
            parts.append("Not authenticated")
        }
        
        parts.append("View: \(selectedView.displayName)")
        parts.append("Projects: \(paraStatistics.activeProjects)/\(paraStatistics.totalProjects)")
        parts.append("Tasks: \(paraStatistics.completedTasks)/\(paraStatistics.totalTasks)")
        
        if isProcessing {
            parts.append("Processing...")
        }
        
        return parts.joined(separator: " | ")
    }
}