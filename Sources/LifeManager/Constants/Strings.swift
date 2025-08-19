//
// Strings.swift
// LifeManager
//
// Created by AI Assistant on 2025-08-18
// Copyright © 2025 LifeManager. All rights reserved.
//

import Foundation

/// Centralized string constants to avoid hardcoded strings in code
enum Strings {
    
    // MARK: - Error Messages
    
    enum Error {
        static let loadProjectsFailed = "Failed to load projects"
        static let loadAreasFailed = "Failed to load areas"
        static let loadResourcesFailed = "Failed to load resources"
        static let loadArchivesFailed = "Failed to load archives"
        static let loadBlobsFailed = "Failed to load blobs"
        static let loadTasksFailed = "Failed to load tasks"
        static let updateProjectFailed = "Failed to update project"
        static let updateAreaFailed = "Failed to update area"
        static let updateResourceFailed = "Failed to update resource"
        static let updateArchiveFailed = "Failed to update archive"
        static let createProjectFailed = "Failed to create project"
        static let createAreaFailed = "Failed to create area"
        static let createResourceFailed = "Failed to create resource"
        static let createArchiveFailed = "Failed to create archive"
        static let deleteProjectFailed = "Failed to delete project"
        static let deleteAreaFailed = "Failed to delete area"
        static let deleteResourceFailed = "Failed to delete resource"
        static let deleteArchiveFailed = "Failed to delete archive"
        static let assignBlobFailed = "Failed to assign blob to"
        static let settingsExportFailed = "Failed to export settings"
        static let settingsImportFailed = "Failed to import settings"
    }
    
    // MARK: - Success Messages
    
    enum Success {
        static let projectCreated = "Project created successfully"
        static let areaCreated = "Area created successfully"
        static let resourceCreated = "Resource created successfully"
        static let archiveCreated = "Archive created successfully"
        static let settingsImported = "Settings imported successfully"
        static let settingsExported = "Settings exported successfully"
        static let dataRefreshed = "Data refreshed successfully"
    }
    
    // MARK: - Logger Messages
    
    enum Logger {
        static let loadingProjects = "Loading projects from database"
        static let loadingAreas = "Loading areas from database"
        static let loadingResources = "Loading resources from database"
        static let loadingArchives = "Loading archives from database"
        static let loadingBlobs = "Loading blobs for PARA categories"
        static let loadingTasks = "Loading tasks for projects and areas"
        static let refreshingData = "Refreshing all PARA data"
        static let loadComplete = "PARA data load complete"
        static let settingsReset = "Settings reset to defaults"
    }
    
    // MARK: - Settings Keys
    
    enum Settings {
        static let exportFileName = "lifemanager_settings.json"
        static let themeModeKey = "themeMode"
        static let accentColorKey = "accentColor"
        static let enableNotificationsKey = "enableNotifications"
        static let autoSaveKey = "autoSave"
        static let syncIntervalKey = "syncInterval"
    }
}