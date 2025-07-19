import Foundation
import SwiftUI

// MARK: - Core Protocol

/// Protocol for PARA (Projects, Areas, Resources, Archives) content
/// Provides unified interface for all content types in the system
protocol PARAContent {
    var id: UUID { get }
    var workPersonal: WorkPersonalType { get }
    var projectId: UUID? { get }
    var areaId: UUID? { get }
    var isArchived: Bool { get }
    var createdAt: String { get }
    var updatedAt: String { get }
    var archivedAt: String? { get }
}

// MARK: - Core Models

/// Blob represents unstructured content input
/// This is the primary input mechanism for all content in v1.0
struct Blob: Codable, Identifiable, PARAContent {
    let id: UUID
    let content: String
    let sourceType: SourceType
    let workPersonal: WorkPersonalType
    let processed: Bool
    let projectId: UUID?
    let areaId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, content, processed
        case sourceType = "source_type"
        case workPersonal = "work_personal"
        case projectId = "project_id"
        case areaId = "area_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(id: UUID = UUID(), content: String, sourceType: SourceType, workPersonal: WorkPersonalType, processed: Bool = false, projectId: UUID? = nil, areaId: UUID? = nil, isArchived: Bool = false) {
        self.id = id
        self.content = content
        self.sourceType = sourceType
        self.workPersonal = workPersonal
        self.processed = processed
        self.projectId = projectId
        self.areaId = areaId
        self.isArchived = isArchived
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
        self.archivedAt = nil
    }
    
    // Custom decoder to handle potential format issues
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        sourceType = try container.decode(SourceType.self, forKey: .sourceType)
        workPersonal = try container.decode(WorkPersonalType.self, forKey: .workPersonal)
        
        // Optional fields with defaults
        processed = try container.decodeIfPresent(Bool.self, forKey: .processed) ?? false
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        areaId = try container.decodeIfPresent(UUID.self, forKey: .areaId)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        
        // Date fields with fallback handling
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = createdAtString
        } else {
            createdAt = ISO8601DateFormatter().string(from: Date())
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = updatedAtString
        } else {
            updatedAt = ISO8601DateFormatter().string(from: Date())
        }
        
        archivedAt = try container.decodeIfPresent(String.self, forKey: .archivedAt)
    }
    
    // Custom encoder to ensure proper format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(workPersonal, forKey: .workPersonal)
        try container.encode(processed, forKey: .processed)
        try container.encodeIfPresent(projectId, forKey: .projectId)
        try container.encodeIfPresent(areaId, forKey: .areaId)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(archivedAt, forKey: .archivedAt)
    }
}

/// Project represents outcome-based work with specific deliverables
struct Project: Codable, Identifiable, PARAContent {
    let id: UUID
    let name: String
    let description: String?
    let status: ProjectStatus
    let workPersonal: WorkPersonalType
    let dueDate: String?
    let areaId: UUID?
    let projectId: UUID? // Always nil for projects (they don't belong to other projects)
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let completedAt: String?
    let archivedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case workPersonal = "work_personal"
        case dueDate = "due_date"
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case archivedAt = "archived_at"
    }
    
    init(id: UUID = UUID(), name: String, description: String? = nil, status: ProjectStatus = .active, workPersonal: WorkPersonalType, dueDate: String? = nil, areaId: UUID? = nil, isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.workPersonal = workPersonal
        self.dueDate = dueDate
        self.areaId = areaId
        self.projectId = nil
        self.isArchived = isArchived
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
        self.completedAt = nil
        self.archivedAt = nil
    }
}

// MARK: - Supporting Types

/// Source type for content input
enum SourceType: String, CaseIterable, Codable {
    case note = "note"
    case journal = "journal"
    case email = "email"
    case meeting = "meeting"
    case idea = "idea"
    case research = "research"
    case recipe = "recipe"
    case financial = "financial"
    case inventory = "inventory"
    case knowledge = "knowledge"
    case therapy = "therapy"
    case media = "media"
    case grocery = "grocery"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Content type classification
enum ContentType: String, CaseIterable, Codable {
    case task = "task"
    case journal = "journal"
    case therapy = "therapy"
    case financial = "financial"
    case knowledge = "knowledge"
    case note = "note"
    case resource = "resource"
    case appointment = "appointment"
    case habit = "habit"
    case goal = "goal"
    case project = "project"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .task: return "Task"
        case .journal: return "Journal"
        case .therapy: return "Therapy"
        case .financial: return "Financial"
        case .knowledge: return "Knowledge"
        case .note: return "Note"
        case .resource: return "Resource"
        case .appointment: return "Appointment"
        case .habit: return "Habit"
        case .goal: return "Goal"
        case .project: return "Project"
        case .area: return "Area"
        }
    }
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .journal: return "book.pages"
        case .therapy: return "heart.circle"
        case .financial: return "dollarsign.circle"
        case .knowledge: return "lightbulb"
        case .note: return "note.text"
        case .resource: return "book"
        case .appointment: return "calendar"
        case .habit: return "repeat"
        case .goal: return "target"
        case .project: return "folder"
        case .area: return "square.stack.3d.up"
        }
    }
}

/// Work/Personal classification for all content
enum WorkPersonalType: String, CaseIterable, Codable {
    case work = "work"
    case personal = "personal"
    case both = "both"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Task priority levels
enum TaskPriority: String, CaseIterable, Codable {
    case urgent = "urgent"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
    
    var priorityScore: Int {
        switch self {
        case .urgent: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        }
    }
    
    init(fromScore score: Int) {
        switch score {
        case 5: self = .urgent
        case 4: self = .high
        case 3: self = .medium
        case 2, 1: self = .low
        default: self = .medium
        }
    }
}

/// Task status types
enum TaskStatus: String, CaseIterable, Codable {
    case inbox = "inbox"
    case todo = "todo"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

/// Project status types
enum ProjectStatus: String, CaseIterable, Codable {
    case planning = "planning"
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case cancelled = "cancelled"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .archived: return "Archived"
        }
    }
}

/// Financial category types
enum FinancialCategory: String, CaseIterable, Codable {
    case expense = "expense"
    case income = "income"
    case investment = "investment"
    case transfer = "transfer"
    
    var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .investment: return "Investment"
        case .transfer: return "Transfer"
        }
    }
}

/// Show/media status types
enum ShowStatus: String, CaseIterable, Codable {
    case watching = "watching"
    case completed = "completed"
    case onHold = "on_hold"
    case dropped = "dropped"
    
    var displayName: String {
        switch self {
        case .watching: return "Watching"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        case .dropped: return "Dropped"
        }
    }
}

/// YouTube content types
enum YouTubeType: String, CaseIterable, Codable {
    case video = "video"
    case playlist = "playlist"
    case reaction = "reaction"
    case review = "review"
    
    var displayName: String {
        switch self {
        case .video: return "Video"
        case .playlist: return "Playlist"
        case .reaction: return "Reaction"
        case .review: return "Review"
        }
    }
}

/// PARA view types for navigation
enum PARAView: String, CaseIterable {
    case inbox = "inbox"
    case projects = "projects"
    case areas = "areas"
    case resources = "resources"
    case archives = "archives"
    case focus = "focus"
    case search = "search"
    case history = "history"
    case tags = "tags"
    case mindmap = "mindmap"
    case calendar = "calendar"
    case timeline = "timeline"
    
    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .projects: return "Projects"
        case .areas: return "Areas"
        case .resources: return "Resources"
        case .archives: return "Archives"
        case .focus: return "Focus"
        case .search: return "Search"
        case .history: return "History"
        case .tags: return "Tags"
        case .mindmap: return "Mind Map"
        case .calendar: return "Calendar"
        case .timeline: return "Timeline"
        }
    }
}

// MARK: - Utility Types

/// Any codable value for dynamic data storage
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case object([String: AnyCodableValue])
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([AnyCodableValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodableValue].self) {
            self = .object(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.typeMismatch(AnyCodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode AnyCodableValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

// MARK: - Extensions for User (Supabase Auth)

/// User type from Supabase Auth
struct User: Codable {
    let id: String
    let email: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

/// Session type from Supabase Auth
struct Session: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

/// Realtime message type from Supabase
struct RealtimeMessage: Codable {
    let eventType: String
    let payload: [String: AnyCodableValue]
    
    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case payload
    }
}

struct Category: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
    }
}

struct Tag: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#3B82F6",
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}

// MARK: - Relationship Models

struct BlobCategory: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let categoryId: UUID
    let confidenceScore: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case categoryId = "category_id"
        case confidenceScore = "confidence_score"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        categoryId: UUID,
        confidenceScore: Double = 0.5,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.blobId = blobId
        self.categoryId = categoryId
        self.confidenceScore = confidenceScore
        self.createdAt = createdAt
    }
}

struct BlobTag: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let tagId: UUID
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case tagId = "tag_id"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        tagId: UUID,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.blobId = blobId
        self.tagId = tagId
        self.createdAt = createdAt
    }
}

struct TaskTag: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let tagId: UUID
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case tagId = "tag_id"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        tagId: UUID,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.taskId = taskId
        self.tagId = tagId
        self.createdAt = createdAt
    }
}

// MARK: - Processing Results

/// Comprehensive result from AI processing of a blob
struct ProcessingResult: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let paraCategory: PARACategory
    let confidence: Double
    let suggestedArea: String?
    let suggestedProject: String?
    let extractedTasks: [TaskExtractionInfo]
    let autoTags: [String]
    let summary: String?
    let crossLinks: [CrossLinkSuggestion]
    let requiresConfirmation: Bool
    let processingTimestamp: String
    let actions: [ProcessingAction]
    
    init(id: UUID = UUID(), blobId: UUID, paraCategory: PARACategory, confidence: Double, suggestedArea: String? = nil, suggestedProject: String? = nil, extractedTasks: [TaskExtractionInfo] = [], autoTags: [String] = [], summary: String? = nil, crossLinks: [CrossLinkSuggestion] = [], requiresConfirmation: Bool = false, actions: [ProcessingAction] = []) {
        self.id = id
        self.blobId = blobId
        self.paraCategory = paraCategory
        self.confidence = confidence
        self.suggestedArea = suggestedArea
        self.suggestedProject = suggestedProject
        self.extractedTasks = extractedTasks
        self.autoTags = autoTags
        self.summary = summary
        self.crossLinks = crossLinks
        self.requiresConfirmation = requiresConfirmation
        self.processingTimestamp = ISO8601DateFormatter().string(from: Date())
        self.actions = actions
    }
}

/// PARA category enumeration
enum PARACategory: String, CaseIterable, Codable {
    case project = "project"
    case area = "area"
    case resource = "resource"
    case archive = "archive"
    
    var displayName: String {
        switch self {
        case .project: return "Project"
        case .area: return "Area"
        case .resource: return "Resource"
        case .archive: return "Archive"
        }
    }
    
    var icon: String {
        switch self {
        case .project: return "target"
        case .area: return "square.stack.3d.up"
        case .resource: return "book.stack"
        case .archive: return "archivebox"
        }
    }
}

/// Generic PARA item for contextual processing
struct PARAItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let contentType: ContentType
    let paraCategory: PARACategory
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let createdAt: Date
    let tags: [String]
    let isCompleted: Bool
    let category: PARACategory // Alias for paraCategory for compatibility
    
    init(id: UUID = UUID(), title: String, content: String, contentType: ContentType, paraCategory: PARACategory, workPersonal: WorkPersonalType, priority: TaskPriority, createdAt: Date = Date(), tags: [String] = [], isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.contentType = contentType
        self.paraCategory = paraCategory
        self.category = paraCategory // Set alias
        self.workPersonal = workPersonal
        self.priority = priority
        self.createdAt = createdAt
        self.tags = tags
        self.isCompleted = isCompleted
    }
}

/// Task extraction information
struct TaskExtractionInfo: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let priority: TaskPriority
    let estimatedDuration: Int? // in minutes
    let suggestedDueDate: String?
    let suggestedArea: String?
    let suggestedProject: String?
    let tags: [String]
    let confidence: Double
    let priorityScore: Int
    let priorityReasoning: String?
    let urgencyIndicators: [String]
    let importanceFactors: [String]
    let timeBlock: String?
    
    init(id: UUID = UUID(), title: String, description: String? = nil, priority: TaskPriority = .medium, estimatedDuration: Int? = nil, suggestedDueDate: String? = nil, suggestedArea: String? = nil, suggestedProject: String? = nil, tags: [String] = [], confidence: Double = 0.8, priorityScore: Int? = nil, priorityReasoning: String? = nil, urgencyIndicators: [String] = [], importanceFactors: [String] = [], timeBlock: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.suggestedDueDate = suggestedDueDate
        self.suggestedArea = suggestedArea
        self.suggestedProject = suggestedProject
        self.tags = tags
        self.confidence = confidence
        self.priorityScore = priorityScore ?? priority.priorityScore
        self.priorityReasoning = priorityReasoning
        self.urgencyIndicators = urgencyIndicators
        self.importanceFactors = importanceFactors
        self.timeBlock = timeBlock
    }
}

/// Cross-link suggestion for connecting to existing PARA items
struct CrossLinkSuggestion: Codable, Identifiable {
    let id: UUID
    let type: CrossLinkType
    let targetName: String
    let targetId: UUID?
    let isNewSuggestion: Bool
    let confidence: Double
    let preFilledDetails: [String: String]
    
    init(id: UUID = UUID(), type: CrossLinkType, targetName: String, targetId: UUID? = nil, isNewSuggestion: Bool = false, confidence: Double = 0.8, preFilledDetails: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.targetName = targetName
        self.targetId = targetId
        self.isNewSuggestion = isNewSuggestion
        self.confidence = confidence
        self.preFilledDetails = preFilledDetails
    }
}

enum CrossLinkType: String, Codable {
    case project = "project"
    case area = "area"
    case resource = "resource"
    case person = "person"
    case location = "location"
}

/// Individual processing action taken
struct ProcessingAction: Codable, Identifiable {
    let id: UUID
    let type: ProcessingActionType
    let description: String
    let details: [String: String]
    let timestamp: String
    let success: Bool
    let errorMessage: String?
    
    init(id: UUID = UUID(), type: ProcessingActionType, description: String, details: [String: String] = [:], success: Bool = true, errorMessage: String? = nil) {
        self.id = id
        self.type = type
        self.description = description
        self.details = details
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.success = success
        self.errorMessage = errorMessage
    }
}

enum ProcessingActionType: String, Codable {
    case categorized = "categorized"
    case taskExtracted = "task_extracted"
    case tagged = "tagged"
    case summarized = "summarized"
    case crossLinked = "cross_linked"
    case moved = "moved"
    case confirmed = "confirmed"
    case error = "error"
}

/// Batch processing session for undo functionality
struct BatchProcessingSession: Codable, Identifiable {
    let id: UUID
    let startTime: String
    let endTime: String?
    let totalBlobs: Int
    let processedBlobs: Int
    let results: [UUID: ProcessingResult] // blobId -> result
    let canUndo: Bool
    let summary: BatchProcessingSummary
    
    init(id: UUID = UUID(), totalBlobs: Int) {
        self.id = id
        self.startTime = ISO8601DateFormatter().string(from: Date())
        self.endTime = nil
        self.totalBlobs = totalBlobs
        self.processedBlobs = 0
        self.results = [:]
        self.canUndo = true
        self.summary = BatchProcessingSummary()
    }
    
    init(id: UUID, startTime: String, endTime: String?, totalBlobs: Int, processedBlobs: Int, results: [UUID: ProcessingResult], canUndo: Bool, summary: BatchProcessingSummary) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.totalBlobs = totalBlobs
        self.processedBlobs = processedBlobs
        self.results = results
        self.canUndo = canUndo
        self.summary = summary
    }
}

/// Processing state for individual blobs
enum BlobProcessingState: Codable {
    case unprocessed
    case processing
    case processed(ProcessingResult)
    case error(String)
    case needsConfirmation(ProcessingResult)
    
    var displayName: String {
        switch self {
        case .unprocessed: return "Unprocessed"
        case .processing: return "Processing..."
        case .processed(let result): return "Processed → \(result.paraCategory.displayName)"
        case .error(let message): return "Error: \(message)"
        case .needsConfirmation: return "Needs Review"
        }
    }
    
    var isProcessed: Bool {
        switch self {
        case .processed, .needsConfirmation: return true
        default: return false
        }
    }
    
    var color: Color {
        switch self {
        case .unprocessed: return .orange
        case .processing: return .blue
        case .processed: return .green
        case .error: return .red
        case .needsConfirmation: return .purple
        }
    }
}

/// Summary of batch processing results
struct BatchProcessingSummary: Codable {
    var tasksCreated: Int = 0
    var notesFiledAsProjects: Int = 0
    var notesFiledAsAreas: Int = 0
    var notesFiledAsResources: Int = 0
    var notesArchived: Int = 0
    var tagsApplied: Int = 0
    var crossLinksCreated: Int = 0
    var confirmationsNeeded: Int = 0
    var errors: Int = 0
    
    var totalProcessed: Int {
        return notesFiledAsProjects + notesFiledAsAreas + notesFiledAsResources + notesArchived
    }
    
    mutating func add(_ result: ProcessingResult) {
        if result.requiresConfirmation {
            confirmationsNeeded += 1
        }
        
        switch result.paraCategory {
        case .project: notesFiledAsProjects += 1
        case .area: notesFiledAsAreas += 1
        case .resource: notesFiledAsResources += 1
        case .archive: notesArchived += 1
        }
        
        tasksCreated += result.extractedTasks.count
        tagsApplied += result.autoTags.count
        crossLinksCreated += result.crossLinks.count
        
        if result.actions.contains(where: { !$0.success }) {
            errors += 1
        }
    }
}

// MARK: - Task Enhancement Results

/// Result of task enhancement processing
struct TaskEnhancementResult {
    let originalTask: LifeTask
    let enhancedTask: LifeTask
    let priorityScore: Int
    let priorityReasoning: String
    let wasEnhanced: Bool
    let confidence: Double
    
    init(originalTask: LifeTask, enhancedTask: LifeTask, priorityScore: Int, priorityReasoning: String, wasEnhanced: Bool, confidence: Double) {
        self.originalTask = originalTask
        self.enhancedTask = enhancedTask
        self.priorityScore = priorityScore
        self.priorityReasoning = priorityReasoning
        self.wasEnhanced = wasEnhanced
        self.confidence = confidence
    }
}

// MARK: - Unified System Enums

/// Unified pattern types for all services
enum UnifiedPatternType: String, CaseIterable, Codable {
    case recurring = "recurring"
    case temporal = "temporal" 
    case contextual = "contextual"
    case behavioral = "behavioral"
    case semantic = "semantic"
    case serviceUsage = "service_usage"
    case decisionMaking = "decision_making"
}

/// Unified optimization types for all services
enum UnifiedOptimizationType: String, CaseIterable, Codable {
    case responseTimeOptimization = "response_time_optimization"
    case coordinationImprovement = "coordination_improvement"
    case memoryOptimization = "memory_optimization"
    case errorReduction = "error_reduction"
    case serviceOptimization = "service_optimization"
    case databaseOptimization = "database_optimization"
    case aiOptimization = "ai_optimization"
    case cacheOptimization = "cache_optimization"
}

/// Unified risk level for all services
enum UnifiedRiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium" 
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Task Extraction Info 