import Foundation

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
    case active = "active"
    case completed = "completed"
    case archived = "archived"
    
    var displayName: String {
        return rawValue.capitalized
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