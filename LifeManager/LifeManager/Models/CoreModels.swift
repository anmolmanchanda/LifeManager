import Foundation

// MARK: - Core Data Models

struct Blob: Codable, Identifiable {
    let id: UUID
    let content: String
    let sourceType: SourceType
    let context: [String: AnyCodableValue]
    let workPersonal: WorkPersonalType
    let processed: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case sourceType = "source_type"
        case context
        case workPersonal = "work_personal"
        case processed
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        content: String,
        sourceType: SourceType,
        context: [String: AnyCodableValue] = [:],
        workPersonal: WorkPersonalType = .personal,
        processed: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.content = content
        self.sourceType = sourceType
        self.context = context
        self.workPersonal = workPersonal
        self.processed = processed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

struct Project: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let status: ProjectStatus
    let workPersonal: WorkPersonalType
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case status
        case workPersonal = "work_personal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        status: ProjectStatus = .active,
        workPersonal: WorkPersonalType = .personal,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.workPersonal = workPersonal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

// MARK: - Helper Types

/// A type-erased codable value that can represent any JSON value
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
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: AnyCodableValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(AnyCodableValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode AnyCodableValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
} 