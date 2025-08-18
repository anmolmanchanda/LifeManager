//
// BrainDumpViewModel.swift
// LifeManager
//
// Manages brain dump input processing
// Extracted from MainViewModel to follow single responsibility principle
//

import Foundation
import SwiftUI
import Combine

/// Manages brain dump input and processing state
@MainActor
class BrainDumpViewModel: ObservableObject {
    
    // MARK: - Input State
    
    @Published var inputText = ""
    @Published var isProcessing = false
    @Published var processingProgress: Float = 0.0
    @Published var processingStage = ProcessingStage.idle
    
    // MARK: - Processing Results
    
    @Published var lastProcessedItems: [PARAItem] = []
    @Published var processingHistory: [ProcessingRecord] = []
    @Published var showingResults = false
    
    // MARK: - UI State
    
    @Published var toastMessage: ToastMessage?
    @Published var showingToast = false
    @Published var characterCount = 0
    @Published var wordCount = 0
    
    // MARK: - Configuration
    
    let maxInputLength = 10000
    let maxHistoryItems = 50
    
    // MARK: - Dependencies
    
    private let llmService = LLMService.shared
    private let supabaseService = SupabaseService.shared
    private let contextMemoryCoordinator = ContextMemoryCoordinator.shared
    private let logger = Logger.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupTextObserver()
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    func processBrainDump() async {
        guard !inputText.isEmpty else {
            showToast(.warning("Please enter some text to process"))
            return
        }
        
        guard !isProcessing else {
            logger.warn("BRAIN_DUMP: Already processing")
            return
        }
        
        isProcessing = true
        processingProgress = 0.0
        processingStage = .preparingContext
        
        do {
            // Get context for better processing
            updateProgress(0.2, stage: .preparingContext)
            let context = await contextMemoryCoordinator.getRelevantContext()
            
            // Process with LLM
            updateProgress(0.4, stage: .analyzingItems)
            let result = try await llmService.processBrainDump(
                inputText,
                context: context
            )
            
            // Save to database
            updateProgress(0.7, stage: .updatingContext)
            let savedItems = try await saveProcessedItems(result.items)
            
            // Update context memory
            updateProgress(0.9, stage: .updatingContext)
            await contextMemoryCoordinator.addToContext(savedItems)
            
            // Complete
            updateProgress(1.0, stage: .idle)
            
            lastProcessedItems = savedItems
            addToHistory(ProcessingRecord(
                input: inputText,
                items: savedItems,
                timestamp: Date()
            ))
            
            showToast(.success("Processed \(savedItems.count) items"))
            showingResults = true
            clearInput()
            
        } catch {
            logger.error("BRAIN_DUMP: Processing failed: \(error)")
            showToast(.error("Processing failed: \(error.localizedDescription)"))
        }
        
        isProcessing = false
        processingStage = .idle
    }
    
    func clearInput() {
        inputText = ""
        characterCount = 0
        wordCount = 0
    }
    
    func undoLastProcessing() async {
        guard let lastRecord = processingHistory.first else {
            showToast(.warning("No processing to undo"))
            return
        }
        
        do {
            // Delete items from database
            for item in lastRecord.items {
                try await supabaseService.delete(item.id, from: "items")
            }
            
            // Remove from history
            processingHistory.removeFirst()
            
            // Restore input
            inputText = lastRecord.input
            
            showToast(.success("Undone last processing"))
            
        } catch {
            logger.error("BRAIN_DUMP: Undo failed: \(error)")
            showToast(.error("Undo failed: \(error.localizedDescription)"))
        }
    }
    
    func loadSavedDraft() {
        if let draft = UserDefaults.standard.string(forKey: "brainDumpDraft") {
            inputText = draft
            showToast(.info("Draft loaded"))
        }
    }
    
    func saveDraft() {
        UserDefaults.standard.set(inputText, forKey: "brainDumpDraft")
        showToast(.success("Draft saved"))
    }
    
    func handleFileDrop(_ url: URL) async {
        do {
            let content = try String(contentsOf: url)
            
            if inputText.isEmpty {
                inputText = content
            } else {
                inputText += "\n\n" + content
            }
            
            showToast(.success("File imported"))
            
        } catch {
            logger.error("BRAIN_DUMP: File import failed: \(error)")
            showToast(.error("Could not import file"))
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTextObserver() {
        $inputText
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.updateTextStats(text)
                self?.autoSaveDraft(text)
            }
            .store(in: &cancellables)
    }
    
    private func updateTextStats(_ text: String) {
        characterCount = text.count
        wordCount = text.split(separator: " ").count
    }
    
    private func autoSaveDraft(_ text: String) {
        if !text.isEmpty {
            UserDefaults.standard.set(text, forKey: "brainDumpDraft")
        }
    }
    
    private func updateProgress(_ progress: Float, stage: ProcessingStage) {
        processingProgress = progress
        processingStage = stage
    }
    
    private func saveProcessedItems(_ items: [BrainDumpItem]) async throws -> [PARAItem] {
        var savedItems: [PARAItem] = []
        
        for item in items {
            let paraItem = item.toPARAItem()
            let saved = try await supabaseService.insert(paraItem, into: "items")
            savedItems.append(saved)
        }
        
        return savedItems
    }
    
    private func addToHistory(_ record: ProcessingRecord) {
        processingHistory.insert(record, at: 0)
        
        // Limit history size
        if processingHistory.count > maxHistoryItems {
            processingHistory = Array(processingHistory.prefix(maxHistoryItems))
        }
        
        // Save to UserDefaults
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "processingHistory"),
           let history = try? JSONDecoder().decode([ProcessingRecord].self, from: data) {
            processingHistory = history
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(processingHistory) {
            UserDefaults.standard.set(data, forKey: "processingHistory")
        }
    }
    
    private func showToast(_ message: ToastMessage) {
        toastMessage = message
        showingToast = true
        
        // Auto-dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showingToast = false
        }
    }
}

// MARK: - Supporting Types

struct ProcessingRecord: Codable, Identifiable {
    let id = UUID()
    let input: String
    let items: [PARAItem]
    let timestamp: Date
}

enum ToastMessage {
    case success(String)
    case warning(String)
    case error(String)
    case info(String)
    
    var text: String {
        switch self {
        case .success(let msg), .warning(let msg), 
             .error(let msg), .info(let msg):
            return msg
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Extensions

extension BrainDumpViewModel {
    
    var canProcess: Bool {
        !inputText.isEmpty && !isProcessing
    }
    
    var inputProgress: Float {
        Float(characterCount) / Float(maxInputLength)
    }
    
    var processingStatusText: String {
        switch processingStage {
        case .idle:
            return "Ready"
        case .preparingContext:
            return "Preparing context..."
        case .splittingInput:
            return "Analyzing input..."
        case .analyzingItems:
            return "Processing items..."
        case .applyingCorrections:
            return "Applying rules..."
        case .generatingClarifications:
            return "Generating questions..."
        case .updatingContext:
            return "Updating memory..."
        }
    }
    
    func formattedWordCount() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: wordCount)) ?? "0"
    }
}