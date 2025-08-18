//
// SyncViewModel.swift
// LifeManager
//
// Manages data synchronization state and operations
// Extracted from MainViewModel to follow single responsibility principle
//

import Foundation
import SwiftUI
import Combine

/// Manages data synchronization with backend services
@MainActor
class SyncViewModel: ObservableObject {
    
    // MARK: - Sync State
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Float = 0.0
    @Published var pendingChanges = 0
    
    // MARK: - Sync Queue
    
    @Published var syncQueue: [SyncOperation] = []
    @Published var failedOperations: [FailedSyncOperation] = []
    
    // MARK: - Real-time Updates
    
    @Published var isRealTimeConnected = false
    @Published var reconnectAttempts = 0
    
    // MARK: - Conflict Resolution
    
    @Published var conflicts: [SyncConflict] = []
    @Published var showingConflictResolution = false
    
    // MARK: - Settings
    
    @Published var autoSyncEnabled = true
    @Published var syncInterval: TimeInterval = 300 // 5 minutes
    @Published var wifiOnlySync = false
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupAutoSync()
        setupRealTimeConnection()
        loadSyncSettings()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Manual Sync
    
    func syncNow() async {
        guard !isSyncing else {
            logger.info("SYNC: Already syncing")
            return
        }
        
        isSyncing = true
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Upload pending changes
            updateProgress(0.2, status: .uploadingChanges)
            try await uploadPendingChanges()
            
            // Download remote changes
            updateProgress(0.5, status: .downloadingChanges)
            try await downloadRemoteChanges()
            
            // Resolve conflicts
            updateProgress(0.7, status: .resolvingConflicts)
            await resolveConflicts()
            
            // Update local cache
            updateProgress(0.9, status: .updatingCache)
            await updateLocalCache()
            
            // Complete
            updateProgress(1.0, status: .completed)
            lastSyncTime = Date()
            pendingChanges = 0
            
            logger.success("SYNC: Completed successfully")
            
        } catch {
            logger.error("SYNC: Failed - \(error)")
            syncStatus = .failed(error.localizedDescription)
        }
        
        isSyncing = false
        
        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if case .completed = self?.syncStatus {
                self?.syncStatus = .idle
            }
        }
    }
    
    // MARK: - Auto Sync
    
    private func setupAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.autoSyncEnabled else { return }
            
            Task {
                await self.performAutoSync()
            }
        }
    }
    
    private func performAutoSync() async {
        guard shouldPerformAutoSync() else { return }
        
        logger.info("SYNC: Starting auto-sync")
        await syncNow()
    }
    
    private func shouldPerformAutoSync() -> Bool {
        // Check network conditions
        if wifiOnlySync && !isOnWiFi() {
            return false
        }
        
        // Check if there are pending changes
        return pendingChanges > 0 || needsSync()
    }
    
    private func needsSync() -> Bool {
        guard let lastSync = lastSyncTime else { return true }
        return Date().timeIntervalSince(lastSync) > syncInterval
    }
    
    // MARK: - Real-time Connection
    
    private func setupRealTimeConnection() {
        Task {
            await connectRealTime()
        }
    }
    
    private func connectRealTime() async {
        do {
            try await supabaseService.setupRealTimeSubscriptions()
            isRealTimeConnected = true
            reconnectAttempts = 0
            
            logger.info("SYNC: Real-time connection established")
            
        } catch {
            logger.error("SYNC: Real-time connection failed - \(error)")
            isRealTimeConnected = false
            
            // Retry with exponential backoff
            await retryRealTimeConnection()
        }
    }
    
    private func retryRealTimeConnection() async {
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 60.0)
        
        logger.info("SYNC: Retrying connection in \(delay) seconds")
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        await connectRealTime()
    }
    
    // MARK: - Sync Operations
    
    private func uploadPendingChanges() async throws {
        let operations = syncQueue.filter { $0.direction == .upload }
        
        for operation in operations {
            try await performSyncOperation(operation)
            syncQueue.removeAll { $0.id == operation.id }
        }
    }
    
    private func downloadRemoteChanges() async throws {
        // Fetch latest data from all tables
        let tables = ["projects", "areas", "tasks", "blobs", "resources", "archives"]
        
        for table in tables {
            let lastSync = lastSyncTime ?? Date.distantPast
            try await fetchChanges(from: table, since: lastSync)
        }
    }
    
    private func fetchChanges(from table: String, since date: Date) async throws {
        let query = supabaseService.client
            .from(table)
            .select()
            .gte("updated_at", date.ISO8601Format())
        
        let response = try await query.execute()
        
        // Process changes
        await processRemoteChanges(response.data, table: table)
    }
    
    private func processRemoteChanges(_ data: Data, table: String) async {
        // Parse and apply changes based on table
        logger.info("SYNC: Processing changes for \(table)")
    }
    
    private func performSyncOperation(_ operation: SyncOperation) async throws {
        switch operation.type {
        case .create:
            try await supabaseService.insert(operation.data, into: operation.table)
        case .update:
            try await supabaseService.updateRaw(operation.data, in: operation.table)
        case .delete:
            if let id = operation.recordId {
                try await supabaseService.delete(id, from: operation.table)
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflicts() async {
        guard !conflicts.isEmpty else { return }
        
        for conflict in conflicts {
            let resolution = await determineResolution(for: conflict)
            await applyResolution(resolution, to: conflict)
        }
        
        conflicts.removeAll()
    }
    
    private func determineResolution(for conflict: SyncConflict) async -> ConflictResolution {
        // Auto-resolve based on strategy
        switch conflict.type {
        case .updateConflict:
            return .useRemote // Default to server version
        case .deleteConflict:
            return .keepLocal // Prefer keeping data
        case .createConflict:
            return .merge // Attempt to merge
        }
    }
    
    private func applyResolution(_ resolution: ConflictResolution, to conflict: SyncConflict) async {
        switch resolution {
        case .useLocal:
            // Keep local version
            await queueSyncOperation(conflict.localData, type: .update, table: conflict.table)
        case .useRemote:
            // Accept remote version
            await updateLocalCache()
        case .merge:
            // Merge changes
            if let merged = mergeConflict(conflict) {
                await queueSyncOperation(merged, type: .update, table: conflict.table)
            }
        case .skip:
            // Do nothing
            break
        }
    }
    
    private func mergeConflict(_ conflict: SyncConflict) -> Any? {
        // Implement merge logic based on data type
        return nil
    }
    
    // MARK: - Queue Management
    
    func queueSyncOperation(_ data: Any, type: SyncOperationType, table: String) async {
        let operation = SyncOperation(
            id: UUID(),
            type: type,
            table: table,
            data: data,
            recordId: nil,
            direction: .upload,
            timestamp: Date()
        )
        
        syncQueue.append(operation)
        pendingChanges += 1
    }
    
    func retryFailedOperations() async {
        let operations = failedOperations
        failedOperations.removeAll()
        
        for failed in operations {
            syncQueue.append(failed.operation)
        }
        
        await syncNow()
    }
    
    // MARK: - Cache Management
    
    private func updateLocalCache() async {
        // Update local cache with synced data
        logger.info("SYNC: Updating local cache")
    }
    
    // MARK: - Settings
    
    private func loadSyncSettings() {
        autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        syncInterval = UserDefaults.standard.double(forKey: "syncInterval")
        wifiOnlySync = UserDefaults.standard.bool(forKey: "wifiOnlySync")
        
        if syncInterval == 0 {
            syncInterval = 300 // Default 5 minutes
        }
    }
    
    func saveSyncSettings() {
        UserDefaults.standard.set(autoSyncEnabled, forKey: "autoSyncEnabled")
        UserDefaults.standard.set(syncInterval, forKey: "syncInterval")
        UserDefaults.standard.set(wifiOnlySync, forKey: "wifiOnlySync")
        
        // Restart auto-sync timer
        syncTimer?.invalidate()
        if autoSyncEnabled {
            setupAutoSync()
        }
    }
    
    // MARK: - Helpers
    
    private func updateProgress(_ progress: Float, status: SyncStatus) {
        syncProgress = progress
        syncStatus = status
    }
    
    private func isOnWiFi() -> Bool {
        // Check network type
        // This is a simplified check - implement proper network detection
        return true
    }
}

// MARK: - Supporting Types

enum SyncStatus: Equatable {
    case idle
    case syncing
    case uploadingChanges
    case downloadingChanges
    case resolvingConflicts
    case updatingCache
    case completed
    case failed(String)
    
    var description: String {
        switch self {
        case .idle: return "Ready to sync"
        case .syncing: return "Syncing..."
        case .uploadingChanges: return "Uploading changes..."
        case .downloadingChanges: return "Downloading updates..."
        case .resolvingConflicts: return "Resolving conflicts..."
        case .updatingCache: return "Updating cache..."
        case .completed: return "Sync completed"
        case .failed(let error): return "Sync failed: \(error)"
        }
    }
}

struct SyncOperation {
    let id: UUID
    let type: SyncOperationType
    let table: String
    let data: Any
    let recordId: UUID?
    let direction: SyncDirection
    let timestamp: Date
}

enum SyncOperationType {
    case create
    case update
    case delete
}

enum SyncDirection {
    case upload
    case download
}

struct FailedSyncOperation {
    let operation: SyncOperation
    let error: Error
    let timestamp: Date
    let retryCount: Int
}

struct SyncConflict {
    let id: UUID
    let type: ConflictType
    let table: String
    let localData: Any
    let remoteData: Any
    let localTimestamp: Date
    let remoteTimestamp: Date
}

enum ConflictType {
    case updateConflict
    case deleteConflict
    case createConflict
}

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
    case skip
}