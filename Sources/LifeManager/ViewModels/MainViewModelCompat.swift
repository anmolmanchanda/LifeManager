//
// MainViewModelCompat.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - Compatibility Wrapper
// Provides backward compatibility while transitioning to modular ViewModels
// This will replace MainViewModel.swift once all views are updated
//

import Foundation
import SwiftUI

// InboxHistoryItem is already defined in MainViewModel.swift

/// Compatibility wrapper that maintains the same API as the original MainViewModel
/// while delegating to the new modular ViewModels
/// This allows for gradual migration of views to the new architecture
@MainActor
class MainViewModelCompat: ObservableObject {
    
    // MARK: - Core ViewModels
    
    @Published var coreVM = CoreMainViewModel()
    
    // MARK: - Delegated Properties - Authentication
    
    var isAuthenticated: Bool { coreVM.isAuthenticated }
    var currentUser: User? { coreVM.currentUser }
    var isLoading: Bool { coreVM.isLoading }
    var authError: String? { coreVM.authError }
    var authSuccess: String? { coreVM.authSuccess }
    
    // MARK: - Delegated Properties - Navigation
    
    var selectedView: PARAView {
        get { coreVM.navigationVM.selectedView }
        set { coreVM.navigationVM.selectedView = newValue }
    }
    
    var searchText: String {
        get { coreVM.navigationVM.searchText }
        set { coreVM.navigationVM.searchText = newValue }
    }
    
    var searchResults: [Blob] { coreVM.navigationVM.searchResults }
    var isSearching: Bool { coreVM.navigationVM.isSearching }
    
    var selectedProject: Project? {
        get { coreVM.navigationVM.selectedProject }
        set { coreVM.navigationVM.selectedProject = newValue }
    }
    
    var selectedArea: Area? {
        get { coreVM.navigationVM.selectedArea }
        set { coreVM.navigationVM.selectedArea = newValue }
    }
    
    var showingAddContent: Bool {
        get { coreVM.navigationVM.showingAddContent }
        set { coreVM.navigationVM.showingAddContent = newValue }
    }
    
    var showingSettings: Bool {
        get { coreVM.navigationVM.showingSettings }
        set { coreVM.navigationVM.showingSettings = newValue }
    }
    
    var errorMessage: String? {
        get { coreVM.navigationVM.errorMessage }
        set { coreVM.navigationVM.errorMessage = newValue }
    }
    
    var successMessage: String? {
        get { coreVM.navigationVM.successMessage }
        set { coreVM.navigationVM.successMessage = newValue }
    }
    
    // MARK: - Delegated Properties - PARA Data
    
    var areas: [Area] { coreVM.paraDataVM.areas }
    var projects: [Project] { coreVM.paraDataVM.projects }
    var resources: [Resource] { coreVM.paraDataVM.resources }
    var archives: [Archive] { coreVM.paraDataVM.archives }
    var recentBlobs: [Blob] { coreVM.paraDataVM.recentBlobs }
    var focusTasks: [LifeTask] { coreVM.paraDataVM.focusTasks }
    
    var projectBlobs: [UUID: [Blob]] { coreVM.paraDataVM.projectBlobs }
    var areaBlobs: [UUID: [Blob]] { coreVM.paraDataVM.areaBlobs }
    var resourceBlobs: [Blob] { coreVM.paraDataVM.resourceBlobs }
    var archivedBlobs: [Blob] { coreVM.paraDataVM.archivedBlobs }
    
    var projectTasks: [UUID: [LifeTask]] { coreVM.paraDataVM.projectTasks }
    var areaTasks: [UUID: [LifeTask]] { coreVM.paraDataVM.areaTasks }
    
    // MARK: - Delegated Properties - Brain Dump
    
    var inboxInput: String {
        get { coreVM.brainDumpVM.inboxInput }
        set { coreVM.brainDumpVM.inboxInput = newValue }
    }
    
    var inboxHistory: [InboxHistoryItem] { coreVM.brainDumpVM.inboxHistory }
    var isProcessingInbox: Bool { coreVM.brainDumpVM.isProcessingInbox }
    var showingBrainDumpReview: Bool { coreVM.brainDumpVM.showingBrainDumpReview }
    var brainDumpResult: BrainDumpResult? { coreVM.brainDumpVM.brainDumpResult }
    var brainDumpProgressMessage: String { coreVM.brainDumpVM.brainDumpProgressMessage }
    
    // MARK: - Services Access (for backward compatibility)
    
    internal var llmService: LLMServiceCoordinator { LLMServiceCoordinator.shared }
    
    // MARK: - Initialization
    
    init() {
        // Core ViewModels are initialized automatically
        // Set up observation of sub-ViewModels to trigger updates
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe changes in sub-ViewModels and propagate to this ViewModel
        coreVM.objectWillChange.sink { _ in
            self.objectWillChange.send()
        }.store(in: &cancellables)
        
        coreVM.navigationVM.objectWillChange.sink { _ in
            self.objectWillChange.send()
        }.store(in: &cancellables)
        
        coreVM.paraDataVM.objectWillChange.sink { _ in
            self.objectWillChange.send()
        }.store(in: &cancellables)
        
        coreVM.brainDumpVM.objectWillChange.sink { _ in
            self.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Delegated Authentication Methods
    
    func signIn(email: String, password: String) async {
        await coreVM.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async {
        await coreVM.signUp(email: email, password: password)
    }
    
    func signOut() async {
        await coreVM.signOut()
    }
    
    func bypassAuth() async {
        await coreVM.bypassAuth()
    }
    
    // MARK: - Delegated Navigation Methods
    
    func performSearch() async {
        await coreVM.navigationVM.performSearch()
    }
    
    func clearSearch() {
        coreVM.navigationVM.clearSearch()
    }
    
    // MARK: - Delegated Brain Dump Methods
    
    func processBrainDump() async throws {
        try await coreVM.brainDumpVM.processBrainDump()
    }
    
    func completeBrainDump(_ summary: ExecutionSummary) {
        // This method signature exists in the original MainViewModel
        // For now, delegate to dismiss review
        coreVM.brainDumpVM.dismissBrainDumpReview()
        coreVM.handleSuccess("Brain dump completed successfully!")
    }
    
    // MARK: - Delegated Data Methods
    
    func refreshAllData() async {
        await coreVM.refreshAllData()
    }
    
    func refreshCategory(_ category: PARACategory) async {
        await coreVM.refreshCategory(category)
    }
    
    // MARK: - Utility Methods
    
    func getBlobs(for project: Project) -> [Blob] {
        return coreVM.paraDataVM.getBlobs(for: project)
    }
    
    func getTasks(for project: Project) -> [LifeTask] {
        return coreVM.paraDataVM.getTasks(for: project)
    }
    
    func getBlobs(for area: Area) -> [Blob] {
        return coreVM.paraDataVM.getBlobs(for: area)
    }
    
    func getTasks(for area: Area) -> [LifeTask] {
        return coreVM.paraDataVM.getTasks(for: area)
    }
    
    func getTotalItemCount(for project: Project) -> Int {
        return coreVM.paraDataVM.getTotalItemCount(for: project)
    }
    
    func getTotalItemCount(for area: Area) -> Int {
        return coreVM.paraDataVM.getTotalItemCount(for: area)
    }
    
    // MARK: - Additional Methods from Original MainViewModel
    
    /// Get active projects (not completed)
    func getActiveProjects() -> [Project] {
        return coreVM.paraDataVM.getActiveProjects()
    }
    
    /// Get overdue tasks across all categories
    func getOverdueTasks() -> [LifeTask] {
        return coreVM.paraDataVM.getOverdueTasks()
    }
    
    /// Get processing statistics
    func getProcessingStatistics() -> ProcessingStatistics {
        return coreVM.brainDumpVM.getProcessingStatistics()
    }
    
    /// Get PARA statistics
    func getPARAStatistics() -> PARAStatistics {
        return coreVM.paraDataVM.getStatistics()
    }
    
    /// Get app state summary
    func getAppStateSummary() -> AppStateSummary {
        return coreVM.getAppStateSummary()
    }
}

// MARK: - Combine Import

import Combine