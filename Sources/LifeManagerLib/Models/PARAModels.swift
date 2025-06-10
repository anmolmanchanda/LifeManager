import Foundation

// MARK: - PARA Framework Models

/// Area: Ongoing responsibilities and spheres of activity
struct Area: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let icon: String?
    let color: String
    let workPersonal: WorkPersonalType
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case icon
        case color
        case workPersonal = "work_personal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        icon: String? = nil,
        color: String = "#3B82F6",
        workPersonal: WorkPersonalType = .personal,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.workPersonal = workPersonal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Resource: Reference materials and knowledge assets
struct Resource: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let title: String
    let type: String
    let authors: [String]
    let summary: String?
    let sourceUrl: String?
    let areaId: UUID?
    let projectId: UUID?
    let tags: [String]
    let metadata: [String: AnyCodableValue]
    let workPersonal: WorkPersonalType
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case title
        case type
        case authors
        case summary
        case sourceUrl = "source_url"
        case areaId = "area_id"
        case projectId = "project_id"
        case tags
        case metadata
        case workPersonal = "work_personal"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        title: String,
        type: String,
        authors: [String] = [],
        summary: String? = nil,
        sourceUrl: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        tags: [String] = [],
        metadata: [String: AnyCodableValue] = [:],
        workPersonal: WorkPersonalType = .personal,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.title = title
        self.type = type
        self.authors = authors
        self.summary = summary
        self.sourceUrl = sourceUrl
        self.areaId = areaId
        self.projectId = projectId
        self.tags = tags
        self.metadata = metadata
        self.workPersonal = workPersonal
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

/// Archive: Virtual view for all archived content
struct Archive: Codable, Identifiable {
    let id: UUID
    let contentType: String
    let title: String
    let sourceType: String
    let workPersonal: WorkPersonalType
    let archivedAt: String?
    let areaId: UUID?
    let projectId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case contentType = "content_type"
        case title
        case sourceType = "source_type"
        case workPersonal = "work_personal"
        case archivedAt = "archived_at"
        case areaId = "area_id"
        case projectId = "project_id"
    }
}

/// Prompt Log: For tracking LLM prompt/response pairs
struct PromptLog: Codable, Identifiable {
    let id: UUID
    let promptTemplate: String
    let promptVersion: String
    let inputData: [String: AnyCodableValue]
    let promptText: String
    let responseText: String
    let modelName: String
    let tokensUsed: Int?
    let processingTimeMs: Int?
    let confidenceScore: Double?
    let blobId: UUID?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case promptTemplate = "prompt_template"
        case promptVersion = "prompt_version"
        case inputData = "input_data"
        case promptText = "prompt_text"
        case responseText = "response_text"
        case modelName = "model_name"
        case tokensUsed = "tokens_used"
        case processingTimeMs = "processing_time_ms"
        case confidenceScore = "confidence_score"
        case blobId = "blob_id"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        promptTemplate: String,
        promptVersion: String,
        inputData: [String: AnyCodableValue],
        promptText: String,
        responseText: String,
        modelName: String,
        tokensUsed: Int? = nil,
        processingTimeMs: Int? = nil,
        confidenceScore: Double? = nil,
        blobId: UUID? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.promptTemplate = promptTemplate
        self.promptVersion = promptVersion
        self.inputData = inputData
        self.promptText = promptText
        self.responseText = responseText
        self.modelName = modelName
        self.tokensUsed = tokensUsed
        self.processingTimeMs = processingTimeMs
        self.confidenceScore = confidenceScore
        self.blobId = blobId
        self.createdAt = createdAt
    }
}

/// Resource Tag relationship
struct ResourceTag: Codable, Identifiable {
    let id: UUID
    let resourceId: UUID
    let tagId: UUID
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceId = "resource_id"
        case tagId = "tag_id"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        resourceId: UUID,
        tagId: UUID,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.resourceId = resourceId
        self.tagId = tagId
        self.createdAt = createdAt
    }
}

// MARK: - PARA Content Protocol

/// Protocol for content that can be organized using PARA methodology
protocol PARAContent {
    var id: UUID { get }
    var areaId: UUID? { get }
    var projectId: UUID? { get }
    var isArchived: Bool { get }
    var archivedAt: String? { get }
    var workPersonal: WorkPersonalType { get }
}

// MARK: - Resource Types

enum ResourceType: String, CaseIterable, Codable {
    case researchPaper = "research_paper"
    case article = "article"
    case video = "video"
    case book = "book"
    case guide = "guide"
    case template = "template"
    case tool = "tool"
    case reference = "reference"
    case playlist = "playlist"
    case insight = "insight"
    case recipe = "recipe"
    case course = "course"
    case podcast = "podcast"
    case document = "document"
    
    var displayName: String {
        switch self {
        case .researchPaper: return "Research Paper"
        case .article: return "Article"
        case .video: return "Video"
        case .book: return "Book"
        case .guide: return "Guide"
        case .template: return "Template"
        case .tool: return "Tool"
        case .reference: return "Reference"
        case .playlist: return "Playlist"
        case .insight: return "Insight"
        case .recipe: return "Recipe"
        case .course: return "Course"
        case .podcast: return "Podcast"
        case .document: return "Document"
        }
    }
} 