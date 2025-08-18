//
// SettingsViewModel.swift
// LifeManager
//
// Manages application settings and preferences
// Extracted from MainViewModel to follow single responsibility principle
//

import Foundation
import SwiftUI
import Combine

/// Manages application settings and user preferences
@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - General Settings
    
    @Published var appTheme: AppTheme = .system
    @Published var accentColor: Color = .blue
    @Published var fontSize: FontSize = .medium
    @Published var enableHaptics = true
    @Published var enableSounds = true
    
    // MARK: - PARA Settings
    
    @Published var defaultProjectView: ProjectViewType = .kanban
    @Published var showArchivedItems = false
    @Published var autoArchiveAfterDays = 90
    @Published var enableAutoTagging = true
    
    // MARK: - Brain Dump Settings
    
    @Published var brainDumpModel: LLMModel = .gpt4
    @Published var maxTokens = 4000
    @Published var temperature = 0.7
    @Published var enableSmartSuggestions = true
    @Published var autoSaveDrafts = true
    
    // MARK: - Calendar Settings
    
    @Published var defaultCalendarView: CalendarViewType = .week
    @Published var workingHoursStart = 9
    @Published var workingHoursEnd = 17
    @Published var weekStartsOn: Weekday = .monday
    @Published var enableBufferTime = true
    @Published var defaultBufferMinutes = 15
    
    // MARK: - Notification Settings
    
    @Published var enableNotifications = true
    @Published var taskReminders = true
    @Published var projectDeadlines = true
    @Published var dailySummary = true
    @Published var dailySummaryTime = Date()
    
    // MARK: - Integration Settings
    
    @Published var togglApiKey = ""
    @Published var togglEnabled = false
    @Published var calendarSyncEnabled = false
    @Published var selectedCalendars: Set<String> = []
    
    // MARK: - Privacy Settings
    
    @Published var analyticsEnabled = false
    @Published var crashReportingEnabled = true
    @Published var dataRetentionDays = 365
    
    // MARK: - Advanced Settings
    
    @Published var debugMode = false
    @Published var verboseLogging = false
    @Published var exportFormat: ExportFormat = .json
    @Published var backupFrequency: BackupFrequency = .weekly
    @Published var lastBackupDate: Date?
    
    // MARK: - Account Settings
    
    @Published var userProfile: UserProfile?
    @Published var emailNotifications = true
    @Published var marketingEmails = false
    @Published var workPersonalSeparation = true
    
    // MARK: - UI State
    
    @Published var isLoading = false
    @Published var saveStatus: SaveStatus = .idle
    @Published var errorMessage: String?
    @Published var showingResetConfirmation = false
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var saveDebouncer: AnyCancellable?
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
        setupAutoSave()
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        isLoading = true
        
        // Load from UserDefaults
        loadLocalSettings()
        
        // Load from remote if available
        Task {
            await loadRemoteSettings()
            isLoading = false
        }
    }
    
    private func loadLocalSettings() {
        let defaults = UserDefaults.standard
        
        // General
        if let themeRaw = defaults.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeRaw) {
            appTheme = theme
        }
        
        if let colorData = defaults.data(forKey: "accentColor") {
            // Decode color
        }
        
        if let sizeRaw = defaults.string(forKey: "fontSize"),
           let size = FontSize(rawValue: sizeRaw) {
            fontSize = size
        }
        
        enableHaptics = defaults.bool(forKey: "enableHaptics")
        enableSounds = defaults.bool(forKey: "enableSounds")
        
        // PARA
        showArchivedItems = defaults.bool(forKey: "showArchivedItems")
        autoArchiveAfterDays = defaults.integer(forKey: "autoArchiveAfterDays")
        enableAutoTagging = defaults.bool(forKey: "enableAutoTagging")
        
        // Brain Dump
        if let modelRaw = defaults.string(forKey: "brainDumpModel"),
           let model = LLMModel(rawValue: modelRaw) {
            brainDumpModel = model
        }
        
        maxTokens = defaults.integer(forKey: "maxTokens")
        if maxTokens == 0 { maxTokens = 4000 }
        
        temperature = defaults.double(forKey: "temperature")
        if temperature == 0 { temperature = 0.7 }
        
        enableSmartSuggestions = defaults.bool(forKey: "enableSmartSuggestions")
        autoSaveDrafts = defaults.bool(forKey: "autoSaveDrafts")
        
        // Calendar
        workingHoursStart = defaults.integer(forKey: "workingHoursStart")
        if workingHoursStart == 0 { workingHoursStart = 9 }
        
        workingHoursEnd = defaults.integer(forKey: "workingHoursEnd")
        if workingHoursEnd == 0 { workingHoursEnd = 17 }
        
        enableBufferTime = defaults.bool(forKey: "enableBufferTime")
        defaultBufferMinutes = defaults.integer(forKey: "defaultBufferMinutes")
        if defaultBufferMinutes == 0 { defaultBufferMinutes = 15 }
        
        // Notifications
        enableNotifications = defaults.bool(forKey: "enableNotifications")
        taskReminders = defaults.bool(forKey: "taskReminders")
        projectDeadlines = defaults.bool(forKey: "projectDeadlines")
        dailySummary = defaults.bool(forKey: "dailySummary")
        
        // Privacy
        analyticsEnabled = defaults.bool(forKey: "analyticsEnabled")
        crashReportingEnabled = defaults.bool(forKey: "crashReportingEnabled")
        dataRetentionDays = defaults.integer(forKey: "dataRetentionDays")
        if dataRetentionDays == 0 { dataRetentionDays = 365 }
        
        // Advanced
        debugMode = defaults.bool(forKey: "debugMode")
        verboseLogging = defaults.bool(forKey: "verboseLogging")
        
        logger.info("SETTINGS: Loaded local settings")
    }
    
    private func loadRemoteSettings() async {
        guard let userId = supabaseService.currentUserId else { return }
        
        do {
            let settings = try await supabaseService.fetchUserSettings(userId: userId)
            applyRemoteSettings(settings)
            
            logger.info("SETTINGS: Loaded remote settings")
            
        } catch {
            logger.error("SETTINGS: Failed to load remote settings: \(error)")
        }
    }
    
    private func applyRemoteSettings(_ settings: [String: Any]) {
        // Apply remote settings to local state
        if let theme = settings["theme"] as? String,
           let appTheme = AppTheme(rawValue: theme) {
            self.appTheme = appTheme
        }
        
        // Apply other settings...
    }
    
    // MARK: - Save Settings
    
    private func setupAutoSave() {
        // Debounce saves to avoid excessive writes
        saveDebouncer = objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.saveSettings()
                }
            }
    }
    
    func saveSettings() async {
        saveStatus = .saving
        
        // Save locally
        saveLocalSettings()
        
        // Save remotely
        do {
            try await saveRemoteSettings()
            saveStatus = .saved
            
            logger.success("SETTINGS: Saved successfully")
            
            // Reset status after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.saveStatus = .idle
            }
            
        } catch {
            logger.error("SETTINGS: Save failed: \(error)")
            saveStatus = .failed
            errorMessage = "Failed to save settings"
        }
    }
    
    private func saveLocalSettings() {
        let defaults = UserDefaults.standard
        
        // General
        defaults.set(appTheme.rawValue, forKey: "appTheme")
        defaults.set(fontSize.rawValue, forKey: "fontSize")
        defaults.set(enableHaptics, forKey: "enableHaptics")
        defaults.set(enableSounds, forKey: "enableSounds")
        
        // PARA
        defaults.set(showArchivedItems, forKey: "showArchivedItems")
        defaults.set(autoArchiveAfterDays, forKey: "autoArchiveAfterDays")
        defaults.set(enableAutoTagging, forKey: "enableAutoTagging")
        
        // Brain Dump
        defaults.set(brainDumpModel.rawValue, forKey: "brainDumpModel")
        defaults.set(maxTokens, forKey: "maxTokens")
        defaults.set(temperature, forKey: "temperature")
        defaults.set(enableSmartSuggestions, forKey: "enableSmartSuggestions")
        defaults.set(autoSaveDrafts, forKey: "autoSaveDrafts")
        
        // Calendar
        defaults.set(workingHoursStart, forKey: "workingHoursStart")
        defaults.set(workingHoursEnd, forKey: "workingHoursEnd")
        defaults.set(enableBufferTime, forKey: "enableBufferTime")
        defaults.set(defaultBufferMinutes, forKey: "defaultBufferMinutes")
        
        // Notifications
        defaults.set(enableNotifications, forKey: "enableNotifications")
        defaults.set(taskReminders, forKey: "taskReminders")
        defaults.set(projectDeadlines, forKey: "projectDeadlines")
        defaults.set(dailySummary, forKey: "dailySummary")
        
        // Privacy
        defaults.set(analyticsEnabled, forKey: "analyticsEnabled")
        defaults.set(crashReportingEnabled, forKey: "crashReportingEnabled")
        defaults.set(dataRetentionDays, forKey: "dataRetentionDays")
        
        // Advanced
        defaults.set(debugMode, forKey: "debugMode")
        defaults.set(verboseLogging, forKey: "verboseLogging")
    }
    
    private func saveRemoteSettings() async throws {
        guard let userId = supabaseService.currentUserId else { return }
        
        let settings = createSettingsDict()
        try await supabaseService.updateUserSettings(userId: userId, settings: settings)
    }
    
    private func createSettingsDict() -> [String: Any] {
        return [
            "theme": appTheme.rawValue,
            "fontSize": fontSize.rawValue,
            "enableHaptics": enableHaptics,
            "enableSounds": enableSounds,
            "showArchivedItems": showArchivedItems,
            "autoArchiveAfterDays": autoArchiveAfterDays,
            "enableAutoTagging": enableAutoTagging,
            "brainDumpModel": brainDumpModel.rawValue,
            "maxTokens": maxTokens,
            "temperature": temperature,
            "enableSmartSuggestions": enableSmartSuggestions,
            "workingHoursStart": workingHoursStart,
            "workingHoursEnd": workingHoursEnd,
            "enableNotifications": enableNotifications,
            "analyticsEnabled": analyticsEnabled,
            "debugMode": debugMode
        ]
    }
    
    // MARK: - Reset Settings
    
    func resetToDefaults() {
        // Reset all settings to defaults
        appTheme = .system
        accentColor = .blue
        fontSize = .medium
        enableHaptics = true
        enableSounds = true
        
        showArchivedItems = false
        autoArchiveAfterDays = 90
        enableAutoTagging = true
        
        brainDumpModel = .gpt4
        maxTokens = 4000
        temperature = 0.7
        enableSmartSuggestions = true
        autoSaveDrafts = true
        
        workingHoursStart = 9
        workingHoursEnd = 17
        enableBufferTime = true
        defaultBufferMinutes = 15
        
        enableNotifications = true
        taskReminders = true
        projectDeadlines = true
        dailySummary = true
        
        analyticsEnabled = false
        crashReportingEnabled = true
        dataRetentionDays = 365
        
        debugMode = false
        verboseLogging = false
        
        Task {
            await saveSettings()
        }
        
        logger.info("SETTINGS: Reset to defaults")
    }
    
    // MARK: - Export/Import
    
    func exportSettings() -> Data? {
        let settings = createSettingsDict()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            logger.info("SETTINGS: Exported successfully")
            return data
        } catch {
            logger.error("SETTINGS: Export failed: \(error)")
            return nil
        }
    }
    
    func importSettings(from data: Data) {
        do {
            if let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                applyRemoteSettings(settings)
                
                Task {
                    await saveSettings()
                }
                
                logger.info("SETTINGS: Imported successfully")
            }
        } catch {
            logger.error("SETTINGS: Import failed: \(error)")
            errorMessage = "Failed to import settings"
        }
    }
}

// MARK: - Supporting Types

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

enum FontSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
}

enum ProjectViewType: String, CaseIterable {
    case list = "List"
    case kanban = "Kanban"
    case timeline = "Timeline"
}

enum CalendarViewType: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

enum Weekday: String, CaseIterable {
    case sunday = "Sunday"
    case monday = "Monday"
}

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case markdown = "Markdown"
}

enum BackupFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum SaveStatus {
    case idle
    case saving
    case saved
    case failed
}

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let name: String?
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date
}