//
// MainCoordinator.swift
// LifeManager
//
// Coordinates navigation and scene management
// Extracted from MainViewModel to follow single responsibility principle
//

import Foundation
import SwiftUI

/// Manages navigation state and scene coordination
@MainActor
class MainCoordinator: ObservableObject {
    
    // MARK: - Navigation State
    
    @Published var selectedTab: MainTab = .brainDump
    @Published var showingSettings = false
    @Published var showingCalendar = false
    @Published var showingReview = false
    @Published var showingContextualPARA = false
    
    // MARK: - Sheet Presentation
    
    @Published var activeSheet: SheetType?
    @Published var activeFullScreenCover: FullScreenCoverType?
    
    // MARK: - Alert State
    
    @Published var alertItem: AlertItem?
    @Published var showingAlert = false
    
    // MARK: - Dependencies
    
    private let logger = Logger.shared
    
    // MARK: - Navigation Methods
    
    func navigate(to tab: MainTab) {
        selectedTab = tab
        logger.info("NAVIGATION: Switched to \(tab.rawValue)")
    }
    
    func presentSheet(_ sheet: SheetType) {
        activeSheet = sheet
        logger.info("NAVIGATION: Presenting sheet: \(sheet)")
    }
    
    func presentFullScreen(_ cover: FullScreenCoverType) {
        activeFullScreenCover = cover
        logger.info("NAVIGATION: Presenting fullscreen: \(cover)")
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
    
    func dismissFullScreen() {
        activeFullScreenCover = nil
    }
    
    func showAlert(_ alert: AlertItem) {
        alertItem = alert
        showingAlert = true
    }
    
    // MARK: - Scene Management
    
    func openSettings() {
        showingSettings = true
    }
    
    func openCalendar() {
        showingCalendar = true
    }
    
    func openReview() {
        showingReview = true
    }
    
    func openContextualPARA() {
        showingContextualPARA = true
    }
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        switch components.host {
        case "braindump":
            navigate(to: .brainDump)
        case "projects":
            navigate(to: .projects)
        case "calendar":
            openCalendar()
        case "settings":
            openSettings()
        default:
            logger.warn("NAVIGATION: Unknown deep link: \(url)")
        }
    }
}

// MARK: - Supporting Types

enum MainTab: String, CaseIterable {
    case brainDump = "Brain Dump"
    case projects = "Projects"
    case areas = "Areas"
    case resources = "Resources"
    case archive = "Archive"
    
    var icon: String {
        switch self {
        case .brainDump: return "brain"
        case .projects: return "folder.badge.star"
        case .areas: return "square.grid.2x2"
        case .resources: return "books.vertical"
        case .archive: return "archivebox"
        }
    }
}

enum SheetType: Identifiable {
    case taskDetail(TaskItem)
    case projectDetail(Project)
    case quickAdd
    case export
    case importData
    
    var id: String {
        switch self {
        case .taskDetail(let task): return "task-\(task.id)"
        case .projectDetail(let project): return "project-\(project.id)"
        case .quickAdd: return "quick-add"
        case .export: return "export"
        case .importData: return "import"
        }
    }
}

enum FullScreenCoverType: Identifiable {
    case onboarding
    case review
    case brainDumpProcessor
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .review: return "review"
        case .brainDumpProcessor: return "processor"
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?
    
    static func error(_ message: String) -> AlertItem {
        AlertItem(
            title: "Error",
            message: message,
            primaryButton: .default(Text("OK")),
            secondaryButton: nil
        )
    }
    
    static func confirmation(
        title: String,
        message: String?,
        onConfirm: @escaping () -> Void
    ) -> AlertItem {
        AlertItem(
            title: title,
            message: message,
            primaryButton: .destructive(Text("Confirm"), action: onConfirm),
            secondaryButton: .cancel()
        )
    }
}