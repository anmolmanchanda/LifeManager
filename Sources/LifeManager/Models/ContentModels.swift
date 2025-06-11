import Foundation

// MARK: - Content Type Models

struct LifeTask: Codable, Identifiable, PARAContent, Hashable {
    let id: UUID
    let blobId: UUID?
    let title: String
    let description: String?
    let priority: TaskPriority
    let status: TaskStatus
    let dueDate: String?
    let estimatedDuration: Int?
    let workPersonal: WorkPersonalType
    let projectId: UUID?
    let areaId: UUID?
    let resourceId: UUID?
    let isFocus: Bool
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let completedAt: String?
    let archivedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case title
        case description
        case priority
        case status
        case dueDate = "due_date"
        case estimatedDuration = "estimated_duration"
        case workPersonal = "work_personal"
        case projectId = "project_id"
        case areaId = "area_id"
        case resourceId = "resource_id"
        case isFocus = "is_focus"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID? = nil,
        title: String,
        description: String? = nil,
        priority: TaskPriority = .medium,
        status: TaskStatus = .inbox,
        dueDate: String? = nil,
        estimatedDuration: Int? = nil,
        workPersonal: WorkPersonalType = .personal,
        projectId: UUID? = nil,
        areaId: UUID? = nil,
        resourceId: UUID? = nil,
        isFocus: Bool = false,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        completedAt: String? = nil,
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.title = title
        self.description = description
        self.priority = priority
        self.status = status
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.workPersonal = workPersonal
        self.projectId = projectId
        self.areaId = areaId
        self.resourceId = resourceId
        self.isFocus = isFocus
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.archivedAt = archivedAt
    }
    
    // Hashable conformance - use id for hashing
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance (required for Hashable)
    static func == (lhs: LifeTask, rhs: LifeTask) -> Bool {
        return lhs.id == rhs.id
    }
}

struct JournalEntry: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let summary: String?
    let mood: String?
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    // For PARAContent protocol compliance
    var workPersonal: WorkPersonalType { return .personal } // Journal entries are always personal
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case summary
        case mood
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        summary: String? = nil,
        mood: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.summary = summary
        self.mood = mood
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct TherapySession: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let sessionDate: String?
    let therapist: String?
    let summary: String?
    let insights: String?
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    // For PARAContent protocol compliance
    var workPersonal: WorkPersonalType { return .personal } // Therapy sessions are always personal
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case sessionDate = "session_date"
        case therapist
        case summary
        case insights
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        sessionDate: String? = nil,
        therapist: String? = nil,
        summary: String? = nil,
        insights: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.sessionDate = sessionDate
        self.therapist = therapist
        self.summary = summary
        self.insights = insights
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct FinancialEntry: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let amount: Double
    let currency: String
    let category: FinancialCategory
    let description: String?
    let transactionDate: String
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    // For PARAContent protocol compliance
    var workPersonal: WorkPersonalType { return .both } // Financial entries can be work or personal
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case amount
        case currency
        case category
        case description
        case transactionDate = "transaction_date"
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        amount: Double,
        currency: String = "USD",
        category: FinancialCategory,
        description: String? = nil,
        transactionDate: String,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.amount = amount
        self.currency = currency
        self.category = category
        self.description = description
        self.transactionDate = transactionDate
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct KnowledgeEntry: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let title: String
    let summary: String?
    let topic: String?
    let sourceUrl: String?
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    // For PARAContent protocol compliance
    var workPersonal: WorkPersonalType { return .both } // Knowledge can be work or personal
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case title
        case summary
        case topic
        case sourceUrl = "source_url"
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        title: String,
        summary: String? = nil,
        topic: String? = nil,
        sourceUrl: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.title = title
        self.summary = summary
        self.topic = topic
        self.sourceUrl = sourceUrl
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct Recipe: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let title: String
    let ingredients: String?
    let instructions: String?
    let sourceUrl: String?
    let nutrition: [String: AnyCodableValue]
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    var workPersonal: WorkPersonalType { return .personal }
    
    enum CodingKeys: String, CodingKey {
        case id, title, ingredients, instructions, nutrition
        case blobId = "blob_id"
        case sourceUrl = "source_url"
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        title: String,
        ingredients: String? = nil,
        instructions: String? = nil,
        sourceUrl: String? = nil,
        nutrition: [String: AnyCodableValue] = [:],
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.sourceUrl = sourceUrl
        self.nutrition = nutrition
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct Diet: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let title: String
    let meals: [String: AnyCodableValue]
    let notes: String?
    let startDate: String?
    let endDate: String?
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    var workPersonal: WorkPersonalType { return .personal }
    
    enum CodingKeys: String, CodingKey {
        case id, title, meals, notes
        case blobId = "blob_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        title: String,
        meals: [String: AnyCodableValue] = [:],
        notes: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.title = title
        self.meals = meals
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct Show: Codable, Identifiable, PARAContent {
    let id: UUID
    let blobId: UUID
    let title: String
    let season: Int?
    let episode: Int?
    let status: ShowStatus
    let platform: String?
    let notes: String?
    let areaId: UUID?
    let projectId: UUID?
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let archivedAt: String?
    
    var workPersonal: WorkPersonalType { return .personal }
    
    enum CodingKeys: String, CodingKey {
        case id, title, season, episode, status, platform, notes
        case blobId = "blob_id"
        case areaId = "area_id"
        case projectId = "project_id"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        title: String,
        season: Int? = nil,
        episode: Int? = nil,
        status: ShowStatus = .watching,
        platform: String? = nil,
        notes: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        isArchived: Bool = false,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date()),
        archivedAt: String? = nil
    ) {
        self.id = id
        self.blobId = blobId
        self.title = title
        self.season = season
        self.episode = episode
        self.status = status
        self.platform = platform
        self.notes = notes
        self.areaId = areaId
        self.projectId = projectId
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

struct Inventory: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let itemName: String
    let category: String?
    let quantity: Int
    let location: String?
    let expirationDate: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case itemName = "item_name"
        case category
        case quantity
        case location
        case expirationDate = "expiration_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        itemName: String,
        category: String? = nil,
        quantity: Int = 1,
        location: String? = nil,
        expirationDate: String? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.blobId = blobId
        self.itemName = itemName
        self.category = category
        self.quantity = quantity
        self.location = location
        self.expirationDate = expirationDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct YouTubeEntry: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let videoId: String?
    let title: String
    let channel: String?
    let playlist: String?
    let type: YouTubeType
    let watchedAt: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case videoId = "video_id"
        case title
        case channel
        case playlist
        case type
        case watchedAt = "watched_at"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        videoId: String? = nil,
        title: String,
        channel: String? = nil,
        playlist: String? = nil,
        type: YouTubeType = .video,
        watchedAt: String? = nil,
        notes: String? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.blobId = blobId
        self.videoId = videoId
        self.title = title
        self.channel = channel
        self.playlist = playlist
        self.type = type
        self.watchedAt = watchedAt
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct GroceryList: Codable, Identifiable {
    let id: UUID
    let blobId: UUID
    let listTitle: String
    let items: [AnyCodableValue]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case blobId = "blob_id"
        case listTitle = "list_title"
        case items
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        blobId: UUID,
        listTitle: String,
        items: [AnyCodableValue] = [],
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.blobId = blobId
        self.listTitle = listTitle
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 