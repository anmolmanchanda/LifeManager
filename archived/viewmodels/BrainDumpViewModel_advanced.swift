//
// BrainDumpViewModel.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - AI Processing State Management
// Extracted from MainViewModel as part of Phase 2A decomposition
// Manages brain dump processing, AI interactions, and processing workflows
//

import Foundation
import SwiftUI

/// Manages AI-powered brain dump processing and related workflows
/// Handles input processing, AI interactions, and result management
/// Extracted from MainViewModel for better separation of AI concerns
@MainActor
class BrainDumpViewModel: ObservableObject {
    
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
    
    // MARK: - Processing State
    
    @Published var currentProcessingSession: BrainDumpBatchSession?
    @Published var pendingConfirmations: [BrainDumpProcessingResult] = []
    @Published var showingConfirmationDialog = false
    @Published var showingProcessingSummary = false
    @Published var processingResults: [UUID: BrainDumpProcessingResult] = [:]
    @Published var blobProcessingStates: [UUID: BrainDumpBlobState] = [:]
    
    // MARK: - Timer State
    
    private var brainDumpProgressTimer: Timer?
    
    // MARK: - Dependencies
    
    private let brainDumpProcessor = LLMBrainDumpProcessor()
    private let llmService = LLMServiceCoordinator.shared
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    init() {
        loadInboxHistory()
    }
    
    deinit {
        brainDumpProgressTimer?.invalidate()
    }
    
    // MARK: - Brain Dump Processing
    
    /// Process brain dump input using AI
    func processBrainDump() async throws {
        guard !inboxInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("🧠 BRAIN DUMP: Empty input provided")
            return
        }
        
        let input = inboxInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await MainActor.run {
            isProcessingInbox = true
            brainDumpProgressMessage = "Analyzing your input..."
            brainDumpElapsedTime = 0
        }
        
        // Start progress timer
        startBrainDumpProgressTimer()
        
        logger.info("🧠 BRAIN DUMP: Starting processing - \(input.prefix(50))...")
        
        do {
            let result = try await brainDumpProcessor.processBrainDump(input)
            
            await MainActor.run {
                brainDumpResult = result
                showingBrainDumpReview = true
                isProcessingInbox = false
                brainDumpProgressMessage = ""
                
                // Add to history
                let historyItem = InboxHistoryItem(
                    input: input,
                    itemsCreated: result.suggestedItems.count,
                    timestamp: Date(),
                    categories: result.suggestedItems.map { $0.paraCategory.rawValue }
                )
                inboxHistory.insert(historyItem, at: 0)
                
                // Clear input
                inboxInput = ""
            }
            
            stopBrainDumpProgressTimer()
            logger.success("🧠 BRAIN DUMP: Processing complete - \(result.suggestedItems.count) items generated")
            
        } catch {
            await MainActor.run {
                isProcessingInbox = false
                brainDumpProgressMessage = ""
            }
            
            stopBrainDumpProgressTimer()
            logger.error("🧠 BRAIN DUMP: Processing failed - \(error)")
            
            throw error
        }
    }
    
    /// Execute brain dump with user-approved items
    func executeBrainDump(approvedItems: [EnhancedBrainDumpItem]) async throws -> ExecutionSummary {
        guard let result = brainDumpResult else {
            throw BrainDumpError.noResultToExecute
        }
        
        logger.info("🧠 EXECUTION: Starting with \(approvedItems.count) approved items")
        
        do {
            let summary = try await brainDumpProcessor.executeBrainDump(result, userApprovedItems: approvedItems)
            
            await MainActor.run {
                showingBrainDumpReview = false
                brainDumpResult = nil
            }
            
            logger.success("🧠 EXECUTION: Complete - \(summary.itemsCreated) items created")
            return summary
            
        } catch {
            logger.error("🧠 EXECUTION: Failed - \(error)")
            throw error
        }
    }
    
    /// Cancel brain dump processing
    func cancelBrainDumpProcessing() {
        stopBrainDumpProgressTimer()
        
        isProcessingInbox = false
        brainDumpProgressMessage = ""
        brainDumpElapsedTime = 0
        
        logger.info("🧠 BRAIN DUMP: Processing cancelled")
    }
    
    /// Dismiss brain dump review
    func dismissBrainDumpReview() {
        showingBrainDumpReview = false
        brainDumpResult = nil
        logger.info("🧠 BRAIN DUMP: Review dismissed")
    }
    
    // MARK: - Progress Timer Management
    
    private func startBrainDumpProgressTimer() {
        stopBrainDumpProgressTimer() // Ensure no existing timer
        
        brainDumpProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.brainDumpElapsedTime += 1
                
                // Update progress message based on elapsed time
                if self.brainDumpElapsedTime < 5 {
                    self.brainDumpProgressMessage = "Analyzing your input..."
                } else if self.brainDumpElapsedTime < 10 {
                    self.brainDumpProgressMessage = "Categorizing content..."
                } else if self.brainDumpElapsedTime < 15 {
                    self.brainDumpProgressMessage = "Applying personal rules..."
                } else {
                    self.brainDumpProgressMessage = "Finalizing suggestions..."
                }
            }
        }
    }
    
    private func stopBrainDumpProgressTimer() {
        brainDumpProgressTimer?.invalidate()
        brainDumpProgressTimer = nil
    }
    
    // MARK: - Batch Processing
    
    /// Start a new batch processing session
    func startBatchProcessing(_ blobs: [Blob]) async {
        let session = BrainDumpBatchSession(
            id: UUID(),
            blobs: blobs,
            startTime: Date(),
            status: .processing
        )
        
        await MainActor.run {
            currentProcessingSession = session
            processingResults = [:]
            blobProcessingStates = [:]
        }
        
        logger.info("🔄 BATCH: Started processing \(blobs.count) blobs")
        
        // Initialize processing states
        for blob in blobs {
            await MainActor.run {
                blobProcessingStates[blob.id] = BrainDumpBlobState(
                    id: blob.id,
                    status: .pending,
                    progress: 0.0
                )
            }
        }
        
        // Process blobs in parallel batches
        await processBlobsBatch(blobs)
    }
    
    /// Process blobs in batches
    private func processBlobsBatch(_ blobs: [Blob]) async {
        let batchSize = 5 // Process 5 blobs at a time
        let batches = blobs.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            logger.info("🔄 BATCH: Processing batch \(batchIndex + 1)/\(batches.count)")
            
            await withTaskGroup(of: Void.self) { group in
                for blob in batch {
                    group.addTask {
                        await self.processBlob(blob)
                    }
                }
            }
        }
        
        // Complete batch processing
        await completeBatchProcessing()
    }
    
    /// Process a single blob
    private func processBlob(_ blob: Blob) async {
        await MainActor.run {
            blobProcessingStates[blob.id]?.status = .processing
            blobProcessingStates[blob.id]?.progress = 0.1
        }
        
        do {
            // Simulate AI processing with progress updates
            for progress in stride(from: 0.2, through: 0.9, by: 0.2) {
                await MainActor.run {
                    blobProcessingStates[blob.id]?.progress = progress
                }
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Process with LLM (placeholder implementation)
            let result = (processedContent: blob.content, confidence: 0.8, suggestions: ["Processed via brain dump"])
            
            let processingResult = BrainDumpProcessingResult(
                id: UUID(),
                blobId: blob.id,
                originalContent: blob.content,
                processedContent: result.processedContent,
                confidence: result.confidence,
                suggestions: result.suggestions,
                timestamp: Date()
            )
            
            await MainActor.run {
                processingResults[blob.id] = processingResult
                blobProcessingStates[blob.id]?.status = .completed
                blobProcessingStates[blob.id]?.progress = 1.0
            }
            
            logger.success("🔄 BLOB: Processed blob \(blob.id)")
            
        } catch {
            await MainActor.run {
                blobProcessingStates[blob.id]?.status = .failed
                blobProcessingStates[blob.id]?.progress = 0.0
            }
            
            logger.error("🔄 BLOB: Failed to process blob \(blob.id) - \(error)")
        }
    }
    
    /// Complete batch processing
    private func completeBatchProcessing() async {
        await MainActor.run {
            currentProcessingSession?.status = .completed
            currentProcessingSession?.endTime = Date()
            showingProcessingSummary = true
        }
        
        let successCount = processingResults.values.count
        let totalCount = currentProcessingSession?.blobs.count ?? 0
        
        logger.success("🔄 BATCH: Completed - \(successCount)/\(totalCount) successful")
    }
    
    /// Cancel batch processing
    func cancelBatchProcessing() {
        currentProcessingSession?.status = .cancelled
        currentProcessingSession = nil
        processingResults = [:]
        blobProcessingStates = [:]
        
        logger.info("🔄 BATCH: Processing cancelled")
    }
    
    // MARK: - Confirmation Management
    
    /// Add processing result for confirmation
    func addPendingConfirmation(_ result: BrainDumpProcessingResult) {
        pendingConfirmations.append(result)
        if pendingConfirmations.count == 1 {
            showingConfirmationDialog = true
        }
    }
    
    /// Confirm a processing result
    func confirmProcessingResult(_ result: BrainDumpProcessingResult) {
        pendingConfirmations.removeAll { $0.id == result.id }
        
        if pendingConfirmations.isEmpty {
            showingConfirmationDialog = false
        }
        
        logger.info("✅ CONFIRM: Approved processing result for blob \(result.blobId)")
    }
    
    /// Reject a processing result
    func rejectProcessingResult(_ result: BrainDumpProcessingResult) {
        pendingConfirmations.removeAll { $0.id == result.id }
        
        if pendingConfirmations.isEmpty {
            showingConfirmationDialog = false
        }
        
        logger.info("❌ REJECT: Rejected processing result for blob \(result.blobId)")
    }
    
    // MARK: - Inbox History Management
    
    /// Load inbox history from UserDefaults
    private func loadInboxHistory() {
        do {
            if let data = UserDefaults.standard.data(forKey: "inboxHistory") {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                inboxHistory = try decoder.decode([InboxHistoryItem].self, from: data)
                logger.info("📚 HISTORY: Loaded \(inboxHistory.count) items")
            }
        } catch {
            logger.error("📚 HISTORY: Failed to load - \(error)")
            inboxHistory = []
        }
    }
    
    /// Save inbox history to UserDefaults
    private func saveInboxHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(inboxHistory)
            UserDefaults.standard.set(data, forKey: "inboxHistory")
            logger.info("📚 HISTORY: Saved \(inboxHistory.count) items")
        } catch {
            logger.error("📚 HISTORY: Failed to save - \(error)")
        }
    }
    
    /// Clear inbox history
    func clearInboxHistory() {
        inboxHistory = []
        UserDefaults.standard.removeObject(forKey: "inboxHistory")
        logger.info("📚 HISTORY: Cleared all items")
    }
    
    /// Get recent history items
    func getRecentHistory(limit: Int = 10) -> [InboxHistoryItem] {
        return Array(inboxHistory.prefix(limit))
    }
    
    // MARK: - Statistics
    
    /// Get processing statistics
    func getProcessingStatistics() -> ProcessingStatistics {
        let totalProcessed = inboxHistory.count
        let totalItemsCreated = inboxHistory.reduce(0) { $0 + $1.itemsCreated }
        let averageItemsPerSession = totalProcessed > 0 ? Double(totalItemsCreated) / Double(totalProcessed) : 0.0
        
        let recentSessions = inboxHistory.prefix(10)
        let recentAverageItems = recentSessions.isEmpty ? 0.0 : Double(recentSessions.reduce(0) { $0 + $1.itemsCreated }) / Double(recentSessions.count)
        
        return ProcessingStatistics(
            totalSessions: totalProcessed,
            totalItemsCreated: totalItemsCreated,
            averageItemsPerSession: averageItemsPerSession,
            recentAverageItems: recentAverageItems,
            lastProcessed: inboxHistory.first?.timestamp
        )
    }
}

// MARK: - Supporting Types

enum BrainDumpError: Error, LocalizedError {
    case noResultToExecute
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noResultToExecute:
            return "No brain dump result available to execute"
        case .processingFailed(let message):
            return "Brain dump processing failed: \(message)"
        }
    }
}

struct BrainDumpBatchSession {
    let id: UUID
    let blobs: [Blob]
    let startTime: Date
    var endTime: Date?
    var status: BatchProcessingStatus
}

enum BatchProcessingStatus {
    case processing, completed, cancelled, failed
}

struct BrainDumpBlobState {
    let id: UUID
    var status: ProcessingStatus
    var progress: Double
}

enum ProcessingStatus {
    case pending, processing, completed, failed
}

struct BrainDumpProcessingResult {
    let id: UUID
    let blobId: UUID
    let originalContent: String
    let processedContent: String
    let confidence: Double
    let suggestions: [String]
    let timestamp: Date
}

struct ProcessingStatistics {
    let totalSessions: Int
    let totalItemsCreated: Int
    let averageItemsPerSession: Double
    let recentAverageItems: Double
    let lastProcessed: Date?
}

// Array chunking extension is already defined in EmbeddingsService.swift