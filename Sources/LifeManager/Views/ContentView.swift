//
// ContentView.swift
// LifeManager
//
// Implements: v2.0 "Modular Architecture" - Core Container + Navigation
// Roadmap Reference: v1.75 Calendar Revolution → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (modularized from 5,668 lines to focused components)
// Future: v2.5 Dynamic Layout, Context-Aware UI
//

import SwiftUI
import Foundation
import AppKit

/// Main content view for LifeManager - Core Application Container
/// Provides authentication flow and main app interface coordination
/// Clean, focused container extracted from monolithic ContentView
struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                MainAppView()
                    .environmentObject(viewModel)
            } else {
                AuthenticationView()
                    .environmentObject(viewModel)
            }
        }
        .overlay(alignment: .bottom) {
            // Success toast
            if let successMessage = viewModel.successMessage {
                ToastView(message: successMessage, type: .success) {
                    viewModel.successMessage = nil
                }
                .padding(.bottom, 20)
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .overlay(alignment: .bottom) {
            // Error toast (only for critical errors)
            if let errorMessage = viewModel.errorMessage, shouldShowError(errorMessage) {
                ToastView(message: errorMessage, type: .error) {
                viewModel.errorMessage = nil
            }
                .padding(.bottom, viewModel.successMessage != nil ? 80 : 20)
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .onAppear {
            // Ensure window comes to front when content appears
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Determine if error should be shown to user (only critical errors)
    private func shouldShowError(_ errorMessage: String) -> Bool {
        // Only show errors that the user can act upon or are truly critical
        let criticalErrors = [
            "Authentication failed",
            "Network connection",
            "Permission denied",
            "Account"
        ]
        
        // Don't show serialization or processing errors - these are handled internally
        let internalErrors = [
            "Failed to save note",
            "couldn't be read",
            "correct format",
            "Processing failed",
            "LLM"
        ]
        
        // If it's an internal error, don't show it
        for internalError in internalErrors {
            if errorMessage.contains(internalError) {
                return false
            }
        }
        
        // Only show if it's a critical error
        return criticalErrors.contains { errorMessage.contains($0) }
    }
}

/// Main authenticated app interface with PARA navigation
/// Central coordinator for navigation split view and global app state
struct MainAppView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                SidebarView()
                    .environmentObject(viewModel)
                    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
            },
            detail: {
                PARADetailView()
                    .environmentObject(viewModel)
            }
        )
        .searchable(text: $viewModel.searchText, prompt: "Search across all content")
        .onSubmit(of: .search) {
            Task {
                await viewModel.search(query: viewModel.searchText)
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task {
                        await viewModel.refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        })
    }
}

/// Detail view coordinator for PARA content display
/// Routes to appropriate view based on navigation selection
struct PARADetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        Group {
            switch viewModel.selectedView {
            case .inbox:
                InboxView()
            case .projects:
                ProjectsView()
            case .areas:
                AreasView()
            case .resources:
                ResourcesView()
            case .archives:
                ArchivesView()
            case .focus:
                FocusView()
            case .calendar:
                CalendarView()
            case .timeline:
                TimelineView()
            case .mindmap:
                MindMapView()
            case .tags:
                TagsView()
            case .search:
                SearchView()
            case .history:
                HistoryView()
            }
        }
        .environmentObject(viewModel)
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    ContentView()
        .frame(width: 1200, height: 800)
}*/
