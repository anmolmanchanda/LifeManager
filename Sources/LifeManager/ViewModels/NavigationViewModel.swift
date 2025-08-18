//
// NavigationViewModel.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - Navigation State Management
// Extracted from MainViewModel as part of Phase 2A decomposition
// Manages view navigation, search state, and UI presentation logic
//

import Foundation
import SwiftUI

/// Manages navigation state and UI presentation for LifeManager
/// Handles view switching, search functionality, and modal presentations
/// Extracted from MainViewModel for better separation of concerns
@MainActor
class NavigationViewModel: ObservableObject {
    
    // MARK: - Navigation State
    
    @Published var selectedView: PARAView = .inbox
    @Published var searchText = ""
    @Published var searchResults: [Blob] = []
    @Published var isSearching = false
    
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
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - Navigation Actions
    
    /// Navigate to a specific PARA view
    func navigate(to view: PARAView) {
        selectedView = view
        logger.info("📱 NAVIGATION: Switched to \(view)")
    }
    
    /// Select a project and navigate to its detail view
    func selectProject(_ project: Project) {
        selectedProject = project
        selectedView = .projects
        logger.info("📱 NAVIGATION: Selected project: \(project.name)")
    }
    
    /// Select an area and navigate to its detail view
    func selectArea(_ area: Area) {
        selectedArea = area
        selectedView = .areas
        logger.info("📱 NAVIGATION: Selected area: \(area.name)")
    }
    
    /// Clear current navigation selection
    func clearSelection() {
        selectedProject = nil
        selectedArea = nil
        selectedResourceCategory = nil
        selectedArchiveCategory = nil
        logger.info("📱 NAVIGATION: Cleared selection")
    }
    
    // MARK: - Search Functionality
    
    /// Perform search across all content
    func performSearch() async {
        guard !searchText.isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let results = try await supabaseService.searchBlobs(query: searchText)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
            
            logger.success("🔍 SEARCH: Found \(results.count) results for '\(searchText)'")
            
        } catch {
            await MainActor.run {
                searchResults = []
                isSearching = false
                errorMessage = "Search failed: \(error.localizedDescription)"
            }
            
            logger.error("🔍 SEARCH: Failed - \(error)")
        }
    }
    
    /// Clear search results and text
    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
        logger.info("🔍 SEARCH: Cleared search")
    }
    
    // MARK: - Modal Presentation
    
    /// Show add content modal
    func showAddContent() {
        showingAddContent = true
        logger.info("📱 UI: Showing add content modal")
    }
    
    /// Hide add content modal
    func hideAddContent() {
        showingAddContent = false
        logger.info("📱 UI: Hiding add content modal")
    }
    
    /// Show settings modal
    func showSettings() {
        showingSettings = true
        logger.info("📱 UI: Showing settings modal")
    }
    
    /// Hide settings modal
    func hideSettings() {
        showingSettings = false
        logger.info("📱 UI: Hiding settings modal")
    }
    
    /// Show processing details modal
    func showProcessingDetails() {
        showingProcessingDetails = true
        logger.info("📱 UI: Showing processing details modal")
    }
    
    /// Hide processing details modal
    func hideProcessingDetails() {
        showingProcessingDetails = false
        logger.info("📱 UI: Hiding processing details modal")
    }
    
    // MARK: - Message Management
    
    /// Display success message
    func showSuccess(_ message: String) {
        successMessage = message
        logger.success("✅ UI: \(message)")
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.successMessage = nil
        }
    }
    
    /// Display error message
    func showError(_ message: String) {
        errorMessage = message
        logger.error("❌ UI: \(message)")
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.errorMessage = nil
        }
    }
    
    /// Clear all messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Helper Extensions

// PARAView displayName is already defined in CoreModels.swift