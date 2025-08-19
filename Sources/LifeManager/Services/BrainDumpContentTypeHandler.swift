//
// BrainDumpContentTypeHandler.swift
// LifeManager
//
// Implements: v2.0 "Intelligence Expansion" - Rich Content Type Support
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Processing Pipeline
// Status: ✅ PRODUCTION - Enterprise-grade content type handling
//
// Purpose: Handles 10+ different content types from brain dump processing
// with specialized parsing, validation, and database creation logic.
//

import Foundation

// MARK: - Database Record Types

struct TaskRecord: Codable {
    let id: String
    let title: String
    let description: String
    let priority: String
    let status: String
    let work_personal: String
    let due_date: String?
    let tags: [String]
    let project_id: String?
    let area_id: String?
}

struct ProjectRecord: Codable {
    let id: String
    let title: String
    let description: String
    let status: String
    let work_personal: String
    let priority: String
    let tags: [String]
    let start_date: String?
    let end_date: String?
}

struct ResourceRecord: Codable {
    let id: String
    let title: String
    let content: String
    let url: String?
    let resource_type: String
    let work_personal: String
    let tags: [String]
    let area_id: String?
}

struct AreaRecord: Codable {
    let id: String
    let name: String
    let description: String
    let work_personal: String
}

struct NoteRecord: Codable {
    let id: String
    let title: String
    let content: String
    let note_type: String
    let work_personal: String
    let tags: [String]
    let project_id: String?
    let area_id: String?
}

struct BlobRecord: Codable {
    let id: String
    let content: String
    let source_type: String
    let work_personal: String
    let metadata: [String: [String]]?
}

struct JournalRecord: Codable {
    let id: String
    let blob_id: String
    let summary: String
    let area_id: String?
    let project_id: String?
    let tags: [String]?
}

struct CalendarEventRecord: Codable {
    let id: String
    let title: String
    let description: String
    let start_date: String
    let end_date: String
    let type: String
    let work_personal: String
}

struct HabitRecord: Codable {
    let id: String
    let title: String
    let description: String
    let frequency: String
    let work_personal: String
    let area_id: String?
}

struct GoalRecord: Codable {
    let id: String
    let title: String
    let description: String
    let target_date: String?
    let work_personal: String
    let project_id: String?
    let area_id: String?
}

struct FinancialTransactionRecord: Codable {
    let id: String
    let amount: Double
    let description: String
    let transaction_type: String
    let category: String
    let date: String
    let work_personal: String
}

struct MedicationRecord: Codable {
    let id: String
    let name: String
    let dosage: String
    let frequency: String
    let notes: String
    let start_date: String
}

struct HealthLogRecord: Codable {
    let id: String
    let type: String
    let description: String
    let details: String
    let date: String
    let tags: [String]
}

struct PersonalRuleRecord: Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let priority: String
    let is_active: Bool
    let work_personal: String
}

/// Enterprise-grade handler for rich content types in brain dump processing
/// Supports 10+ content types with specialized processing logic
@MainActor
class BrainDumpContentTypeHandler: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BrainDumpContentTypeHandler()
    
    // MARK: - Dependencies
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    private let embeddingsService = BrainDumpEmbeddingsService.shared
    
    // MARK: - State
    @Published var isProcessing = false
    @Published var processingStats = ProcessingStats()
    
    // MARK: - Models
    struct ProcessingStats {
        var totalProcessed = 0
        var successfulCreations = 0
        var failedCreations = 0
        var contentTypeBreakdown: [ContentType: Int] = [:]
        
        mutating func recordSuccess(for type: ContentType) {
            totalProcessed += 1
            successfulCreations += 1
            contentTypeBreakdown[type, default: 0] += 1
        }
        
        mutating func recordFailure(for type: ContentType) {
            totalProcessed += 1
            failedCreations += 1
        }
    }
    
    struct ContentTypeMetadata {
        let supportedTypes: [ContentType] = [
            .task, .note, .journal, .resource,
            .project, .area, .appointment,
            .habit, .goal, .financial,
            .therapy, .knowledge, .medication,
            .healthLog, .personalRule
        ]
        
        func getHandler(for type: ContentType) -> ContentHandler? {
            switch type {
            case .task: return TaskHandler()
            case .note: return NoteHandler()
            case .journal: return JournalHandler()
            case .resource: return ResourceHandler()
            case .project: return ProjectHandler()
            case .area: return AreaHandler()
            case .appointment: return AppointmentHandler()
            case .habit: return HabitHandler()
            case .goal: return GoalHandler()
            case .financial: return FinancialHandler()
            case .therapy: return TherapyHandler()
            case .knowledge: return KnowledgeHandler()
            case .medication: return MedicationHandler()
            case .healthLog: return HealthLogHandler()
            case .personalRule: return PersonalRuleHandler()
            default: return nil
            }
        }
    }
    
    private let metadata = ContentTypeMetadata()
    
    private init() {
        logger.info("BrainDumpContentTypeHandler initialized with \(metadata.supportedTypes.count) content types")
    }
    
    // MARK: - Public Methods
    
    /// Process and create database entry for any content type
    func processContentItem(_ item: EnhancedBrainDumpItem) async throws -> ContentCreationResult {
        logger.debug("Processing \(item.contentType.rawValue): \(item.title)")
        
        guard let handler = metadata.getHandler(for: item.contentType) else {
            logger.warning("No handler for content type: \(item.contentType.rawValue)")
            throw ContentTypeError.unsupportedType(item.contentType.rawValue)
        }
        
        do {
            // Validate item before processing
            try handler.validate(item)
            
            // Create database entry
            let result = try await handler.create(item, using: supabaseService)
            
            // Generate embeddings
            _ = await embeddingsService.generateEmbeddingForItem(item)
            
            // Update stats
            processingStats.recordSuccess(for: item.contentType)
            
            logger.success("✅ Created \(item.contentType.rawValue): \(item.title)")
            return result
            
        } catch {
            processingStats.recordFailure(for: item.contentType)
            logger.error("Failed to create \(item.contentType.rawValue): \(error)")
            throw error
        }
    }
    
    /// Process multiple items in batch
    func processContentItems(_ items: [EnhancedBrainDumpItem]) async -> BatchProcessingResult {
        isProcessing = true
        processingStats = ProcessingStats()
        
        defer { isProcessing = false }
        
        logger.info("Processing \(items.count) content items")
        
        var results: [ContentCreationResult] = []
        var errors: [ProcessingError] = []
        
        for item in items {
            do {
                let result = try await processContentItem(item)
                results.append(result)
            } catch {
                errors.append(ProcessingError(
                    itemId: item.id,
                    itemTitle: item.title,
                    contentType: item.contentType,
                    error: error
                ))
            }
        }
        
        return BatchProcessingResult(
            successfulCreations: results,
            errors: errors,
            stats: processingStats
        )
    }
    
    // MARK: - Content Type Handlers
    
    protocol ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult
    }
    
    // MARK: Task Handler
    struct TaskHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Task must have a title")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let task = TaskRecord(
                id: item.id.uuidString,
                title: item.title,
                description: item.content,
                priority: item.priority.rawValue,
                status: "inbox",
                work_personal: item.workPersonal.rawValue,
                due_date: item.dueDate,
                tags: item.tags,
                project_id: item.suggestedProject,
                area_id: item.suggestedArea
            )
            
            try await service.insert(task, into: "tasks")
            
            return ContentCreationResult(
                id: item.id,
                type: .task,
                title: item.title,
                databaseTable: "tasks"
            )
        }
    }
    
    // MARK: Note Handler
    struct NoteHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.content.isEmpty else {
                throw ContentTypeError.validationFailed("Note must have content")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let blob = BlobRecord(
                id: item.id.uuidString,
                content: item.content,
                source_type: "note",
                work_personal: item.workPersonal.rawValue,
                metadata: ["title": [item.title], "tags": item.tags]
            )
            
            try await service.insert(blob, into: "blobs")
            
            return ContentCreationResult(
                id: item.id,
                type: .note,
                title: item.title,
                databaseTable: "blobs"
            )
        }
    }
    
    // MARK: Journal Handler
    struct JournalHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.content.isEmpty else {
                throw ContentTypeError.validationFailed("Journal entry must have content")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            // First create blob
            let blobId = UUID()
            let blob = BlobRecord(
                id: blobId.uuidString,
                content: item.content,
                source_type: "journal",
                work_personal: item.workPersonal.rawValue,
                metadata: nil
            )
            
            try await service.insert(blob, into: "blobs")
            
            // Then create journal entry
            let journal = JournalRecord(
                id: item.id.uuidString,
                blob_id: blobId.uuidString,
                summary: item.title,
                area_id: item.suggestedArea,
                project_id: item.suggestedProject,
                tags: nil
            )
            
            try await service.insert(journal, into: "journal_entries")
            
            return ContentCreationResult(
                id: item.id,
                type: .journal,
                title: item.title,
                databaseTable: "journal_entries"
            )
        }
    }
    
    // MARK: Resource Handler
    struct ResourceHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Resource must have a title")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            // First create blob
            let blobId = UUID()
            let blob = BlobRecord(
                id: blobId.uuidString,
                content: item.content,
                source_type: "resource",
                work_personal: item.workPersonal.rawValue,
                metadata: nil
            )
            
            try await service.insert(blob, into: "blobs")
            
            // Then create resource
            let resource = ResourceRecord(
                id: item.id.uuidString,
                title: item.title,
                content: item.content,
                url: nil,
                resource_type: "reference",
                work_personal: item.workPersonal.rawValue,
                tags: item.tags,
                area_id: item.suggestedArea
            )
            
            try await service.insert(resource, into: "resources")
            
            return ContentCreationResult(
                id: item.id,
                type: .resource,
                title: item.title,
                databaseTable: "resources"
            )
        }
    }
    
    // MARK: Project Handler
    struct ProjectHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Project must have a name")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let project = ProjectRecord(
                id: item.id.uuidString,
                title: item.title,
                description: item.content,
                status: "active",
                work_personal: item.workPersonal.rawValue,
                priority: item.priority.rawValue,
                tags: item.tags,
                start_date: nil,
                end_date: nil
            )
            
            try await service.insert(project, into: "projects")
            
            return ContentCreationResult(
                id: item.id,
                type: .project,
                title: item.title,
                databaseTable: "projects"
            )
        }
    }
    
    // MARK: Area Handler
    struct AreaHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Area must have a name")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let area = AreaRecord(
                id: item.id.uuidString,
                name: item.title,
                description: item.content,
                work_personal: item.workPersonal.rawValue
            )
            
            try await service.insert(area, into: "areas")
            
            return ContentCreationResult(
                id: item.id,
                type: .area,
                title: item.title,
                databaseTable: "areas"
            )
        }
    }
    
    // MARK: Appointment Handler
    struct AppointmentHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Appointment must have a title")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            // Extract or calculate dates
            let startDate = extractDate(from: item) ?? Date().addingTimeInterval(86400) // Tomorrow
            let endDate = startDate.addingTimeInterval(3600) // 1 hour duration
            
            let event = CalendarEventRecord(
                id: item.id.uuidString,
                title: item.title,
                description: item.content,
                start_date: ISO8601DateFormatter().string(from: startDate),
                end_date: ISO8601DateFormatter().string(from: endDate),
                type: "meeting",
                work_personal: item.workPersonal.rawValue
            )
            
            try await service.insert(event, into: "calendar_events")
            
            return ContentCreationResult(
                id: item.id,
                type: .appointment,
                title: item.title,
                databaseTable: "calendar_events"
            )
        }
        
        private func extractDate(from item: EnhancedBrainDumpItem) -> Date? {
            if let dateString = item.dueDate {
                return ISO8601DateFormatter().date(from: dateString)
            }
            return nil
        }
    }
    
    // MARK: Habit Handler
    struct HabitHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Habit must have a title")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let habit = HabitRecord(
                id: item.id.uuidString,
                title: item.title,
                description: item.content,
                frequency: "daily",
                work_personal: item.workPersonal.rawValue,
                area_id: item.suggestedArea
            )
            
            try await service.insert(habit, into: "habits")
            
            return ContentCreationResult(
                id: item.id,
                type: .habit,
                title: item.title,
                databaseTable: "habits"
            )
        }
    }
    
    // MARK: Goal Handler
    struct GoalHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Goal must have a title")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let targetDate = item.dueDate != nil ? item.dueDate : ISO8601DateFormatter().string(from: Date().addingTimeInterval(2592000)) // 30 days
            
            let goal = GoalRecord(
                id: item.id.uuidString,
                title: item.title,
                description: item.content,
                target_date: targetDate,
                work_personal: item.workPersonal.rawValue,
                project_id: item.suggestedProject,
                area_id: item.suggestedArea
            )
            
            try await service.insert(goal, into: "goals")
            
            return ContentCreationResult(
                id: item.id,
                type: .goal,
                title: item.title,
                databaseTable: "goals"
            )
        }
    }
    
    // MARK: Financial Handler
    struct FinancialHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.content.isEmpty else {
                throw ContentTypeError.validationFailed("Financial transaction must have details")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let amount = extractAmount(from: item.content) ?? 0.0
            let transactionType = detectTransactionType(from: item.content)
            
            let transaction = FinancialTransactionRecord(
                id: item.id.uuidString,
                amount: amount,
                description: item.title,
                transaction_type: transactionType,
                category: item.suggestedArea ?? "general",
                date: ISO8601DateFormatter().string(from: Date()),
                work_personal: item.workPersonal.rawValue
            )
            
            try await service.insert(transaction, into: "financial_transactions")
            
            return ContentCreationResult(
                id: item.id,
                type: .financial,
                title: item.title,
                databaseTable: "financial_transactions"
            )
        }
        
        private func extractAmount(from text: String) -> Double? {
            let patterns = [
                "\\$([0-9]+\\.?[0-9]*)",
                "([0-9]+\\.?[0-9]*)\\s*(?:dollars?|USD|\\$)",
                "([0-9]+\\.?[0-9]*)"
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let nsText = text as NSString
                    let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                    
                    if let match = results.first {
                        let matchRange = match.range(at: results.count > 1 ? 1 : 0)
                        if matchRange.location != NSNotFound {
                            let matchString = nsText.substring(with: matchRange)
                            return Double(matchString)
                        }
                    }
                }
            }
            return nil
        }
        
        private func detectTransactionType(from text: String) -> String {
            let lowercased = text.lowercased()
            if lowercased.contains("income") || lowercased.contains("earned") || lowercased.contains("received") {
                return "income"
            } else if lowercased.contains("spent") || lowercased.contains("bought") || lowercased.contains("paid") {
                return "expense"
            }
            return "expense"
        }
    }
    
    // MARK: Therapy Handler
    struct TherapyHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.content.isEmpty else {
                throw ContentTypeError.validationFailed("Therapy entry must have content")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            // Create as special journal entry with therapy tag
            let blobId = UUID()
            let blob = BlobRecord(
                id: blobId.uuidString,
                content: item.content,
                source_type: "therapy",
                work_personal: "personal",
                metadata: nil
            )
            
            try await service.insert(blob, into: "blobs")
            
            let journal = JournalRecord(
                id: item.id.uuidString,
                blob_id: blobId.uuidString,
                summary: item.title,
                area_id: nil,
                project_id: nil,
                tags: ["therapy"]
            )
            
            try await service.insert(journal, into: "journal_entries")
            
            return ContentCreationResult(
                id: item.id,
                type: .therapy,
                title: item.title,
                databaseTable: "journal_entries"
            )
        }
    }
    
    // MARK: Knowledge Handler
    struct KnowledgeHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.content.isEmpty else {
                throw ContentTypeError.validationFailed("Knowledge entry must have content")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            // Create as resource with knowledge type
            let blobId = UUID()
            let blob = BlobRecord(
                id: blobId.uuidString,
                content: item.content,
                source_type: "knowledge",
                work_personal: item.workPersonal.rawValue,
                metadata: nil
            )
            
            try await service.insert(blob, into: "blobs")
            
            let resource = ResourceRecord(
                id: item.id.uuidString,
                title: item.title,
                content: item.content,
                url: nil,
                resource_type: "knowledge",
                work_personal: item.workPersonal.rawValue,
                tags: item.tags,
                area_id: nil
            )
            
            try await service.insert(resource, into: "resources")
            
            return ContentCreationResult(
                id: item.id,
                type: .knowledge,
                title: item.title,
                databaseTable: "resources"
            )
        }
    }
    
    // MARK: Medication Handler
    struct MedicationHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Medication must have a name")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let medication = MedicationRecord(
                id: item.id.uuidString,
                name: item.title,
                dosage: extractDosage(from: item.content),
                frequency: extractFrequency(from: item.content),
                notes: item.content,
                start_date: ISO8601DateFormatter().string(from: Date())
            )
            
            try await service.insert(medication, into: "medications")
            
            return ContentCreationResult(
                id: item.id,
                type: .medication,
                title: item.title,
                databaseTable: "medications"
            )
        }
        
        private func extractDosage(from text: String) -> String {
            // Simple extraction logic - could be enhanced with regex
            if text.lowercased().contains("mg") {
                return text
            }
            return "See notes"
        }
        
        private func extractFrequency(from text: String) -> String {
            let lowercased = text.lowercased()
            if lowercased.contains("daily") { return "daily" }
            if lowercased.contains("twice") { return "twice daily" }
            if lowercased.contains("weekly") { return "weekly" }
            return "as needed"
        }
    }
    
    // MARK: Health Log Handler
    struct HealthLogHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.content.isEmpty else {
                throw ContentTypeError.validationFailed("Health log must have content")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let healthLog = HealthLogRecord(
                id: item.id.uuidString,
                type: detectHealthType(from: item.content),
                description: item.title,
                details: item.content,
                date: ISO8601DateFormatter().string(from: Date()),
                tags: item.tags
            )
            
            try await service.insert(healthLog, into: "health_logs")
            
            return ContentCreationResult(
                id: item.id,
                type: .healthLog,
                title: item.title,
                databaseTable: "health_logs"
            )
        }
        
        private func detectHealthType(from text: String) -> String {
            let lowercased = text.lowercased()
            if lowercased.contains("symptom") { return "symptom" }
            if lowercased.contains("pain") { return "pain" }
            if lowercased.contains("mood") { return "mood" }
            if lowercased.contains("sleep") { return "sleep" }
            if lowercased.contains("exercise") { return "exercise" }
            return "general"
        }
    }
    
    // MARK: Personal Rule Handler
    struct PersonalRuleHandler: ContentHandler {
        func validate(_ item: EnhancedBrainDumpItem) throws {
            guard !item.title.isEmpty else {
                throw ContentTypeError.validationFailed("Personal rule must have a title")
            }
        }
        
        func create(_ item: EnhancedBrainDumpItem, using service: SupabaseService) async throws -> ContentCreationResult {
            let rule = PersonalRuleRecord(
                id: item.id.uuidString,
                title: item.title,
                description: item.content,
                category: item.suggestedArea ?? "general",
                priority: item.priority.rawValue,
                is_active: true,
                work_personal: item.workPersonal.rawValue
            )
            
            try await service.insert(rule, into: "personal_rules")
            
            return ContentCreationResult(
                id: item.id,
                type: .personalRule,
                title: item.title,
                databaseTable: "personal_rules"
            )
        }
    }
}

// MARK: - Supporting Types

struct ContentCreationResult {
    let id: UUID
    let type: ContentType
    let title: String
    let databaseTable: String
}

struct BatchProcessingResult {
    let successfulCreations: [ContentCreationResult]
    let errors: [ProcessingError]
    let stats: BrainDumpContentTypeHandler.ProcessingStats
}

struct ProcessingError {
    let itemId: UUID
    let itemTitle: String
    let contentType: ContentType
    let error: Error
}

enum ContentTypeError: LocalizedError {
    case unsupportedType(String)
    case validationFailed(String)
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "Unsupported content type: \(type)"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}

// MARK: - Extended ContentType Support
extension ContentType {
    static let extendedTypes: [ContentType] = [
        .task, .note, .journal, .resource,
        .project, .area, .appointment,
        .habit, .goal, .financial,
        .therapy, .knowledge, .medication,
        .healthLog, .personalRule
    ]
}