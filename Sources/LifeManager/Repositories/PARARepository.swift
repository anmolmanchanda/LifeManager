import Foundation

// MARK: - Area Repository

/// Repository for managing Area (PARA Areas - ongoing responsibilities)
class AreaRepository: ObservableObject {
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CRUD Operations
    
    /// Create a new area
    func createArea(
        name: String,
        description: String? = nil,
        icon: String? = nil,
        color: String = "#3B82F6",
        workPersonal: WorkPersonalType = .personal
    ) async throws -> Area {
        let area = Area(
            name: name,
            description: description,
            icon: icon,
            color: color,
            workPersonal: workPersonal
        )
        
        return try await supabaseService.insert(area, into: SupabaseService.TableName.areas.rawValue)
    }
    
    /// Fetch all areas
    func fetchAllAreas() async throws -> [Area] {
        let response: [Area] = try await supabaseService.client
            .from(SupabaseService.TableName.areas.rawValue)
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch area by ID
    func fetchArea(id: UUID) async throws -> Area? {
        return try await supabaseService.fetchById(Area.self, from: SupabaseService.TableName.areas.rawValue, id: id)
    }
    
    /// Fetch areas by work/personal filter
    func fetchAreas(workPersonal: WorkPersonalType) async throws -> [Area] {
        return try await supabaseService.fetchByWorkPersonal(
            Area.self,
            from: SupabaseService.TableName.areas.rawValue,
            workPersonal: workPersonal
        )
    }
    
    /// Update area
    func updateArea(_ area: Area) async throws -> Area {
        return try await supabaseService.update(
            area,
            in: SupabaseService.TableName.areas.rawValue,
            matching: "id",
            value: area.id.uuidString
        )
    }
    
    /// Delete area
    func deleteArea(id: UUID) async throws {
        try await supabaseService.delete(
            from: SupabaseService.TableName.areas.rawValue,
            matching: "id",
            value: id.uuidString
        )
    }
    
    // MARK: - Analytics
    
    /// Get project count for each area
    func getProjectCountsByArea() async throws -> [UUID: Int] {
        let projects = try await supabaseService.fetch(Project.self, from: SupabaseService.TableName.projects.rawValue)
        var counts: [UUID: Int] = [:]
        
        for project in projects {
            if let areaId = project.areaId {
                counts[areaId, default: 0] += 1
            }
        }
        
        return counts
    }
}

// MARK: - Resource Repository

/// Repository for managing Resources (PARA Resources - reference materials)
class ResourceRepository: ObservableObject {
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CRUD Operations
    
    /// Create a new resource
    func createResource(
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
        workPersonal: WorkPersonalType = .personal
    ) async throws -> Resource {
        let resource = Resource(
            blobId: blobId,
            title: title,
            type: type,
            authors: authors,
            summary: summary,
            sourceUrl: sourceUrl,
            areaId: areaId,
            projectId: projectId,
            tags: tags,
            metadata: metadata,
            workPersonal: workPersonal
        )
        
        return try await supabaseService.insert(resource, into: SupabaseService.TableName.resources.rawValue)
    }
    
    /// Fetch all resources (excluding archived)
    func fetchAllResources() async throws -> [Resource] {
        let response: [Resource] = try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .select()
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch resource by ID
    func fetchResource(id: UUID) async throws -> Resource? {
        return try await supabaseService.fetchById(Resource.self, from: SupabaseService.TableName.resources.rawValue, id: id)
    }
    
    /// Fetch resources by type
    func fetchResources(type: String) async throws -> [Resource] {
        let response: [Resource] = try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .select()
            .eq("type", value: type)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch resources by area
    func fetchResources(areaId: UUID) async throws -> [Resource] {
        let response: [Resource] = try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .select()
            .eq("area_id", value: areaId.uuidString)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch resources by project
    func fetchResources(projectId: UUID) async throws -> [Resource] {
        let response: [Resource] = try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .select()
            .eq("project_id", value: projectId.uuidString)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Update resource
    func updateResource(_ resource: Resource) async throws -> Resource {
        return try await supabaseService.update(
            resource,
            in: SupabaseService.TableName.resources.rawValue,
            matching: "id",
            value: resource.id.uuidString
        )
    }
    
    /// Archive resource
    func archiveResource(id: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .update(["is_archived": true])
            .eq("id", value: id.uuidString)
            .execute()
        
        try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .update(["archived_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Unarchive resource
    func unarchiveResource(id: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .update(["is_archived": false, "archived_at": nil])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Delete resource
    func deleteResource(id: UUID) async throws {
        try await supabaseService.delete(
            from: SupabaseService.TableName.resources.rawValue,
            matching: "id",
            value: id.uuidString
        )
    }
    
    // MARK: - Search and Filtering
    
    /// Search resources by title and summary
    func searchResources(query: String) async throws -> [Resource] {
        let response: [Resource] = try await supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .select()
            .textSearch("title,summary", query: query)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Advanced search with filters
    func searchResources(
        query: String? = nil,
        type: String? = nil,
        areaId: UUID? = nil,
        projectId: UUID? = nil,
        workPersonal: WorkPersonalType? = nil
    ) async throws -> [Resource] {
        var queryBuilder = supabaseService.client
            .from(SupabaseService.TableName.resources.rawValue)
            .select()
            .eq("is_archived", value: false)
        
        if let query = query {
            queryBuilder = queryBuilder.textSearch("title,summary", query: query)
        }
        
        if let type = type {
            queryBuilder = queryBuilder.eq("type", value: type)
        }
        
        if let areaId = areaId {
            queryBuilder = queryBuilder.eq("area_id", value: areaId.uuidString)
        }
        
        if let projectId = projectId {
            queryBuilder = queryBuilder.eq("project_id", value: projectId.uuidString)
        }
        
        if let workPersonal = workPersonal {
            queryBuilder = queryBuilder.eq("work_personal", value: workPersonal.rawValue)
        }
        
        let response: [Resource] = try await queryBuilder
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Tag Operations
    
    /// Assign tag to resource
    func assignTag(resourceId: UUID, tagId: UUID) async throws -> ResourceTag {
        let resourceTag = ResourceTag(resourceId: resourceId, tagId: tagId)
        return try await supabaseService.insert(resourceTag, into: SupabaseService.TableName.resourceTags.rawValue)
    }
    
    /// Remove tag from resource
    func removeTag(resourceId: UUID, tagId: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.resourceTags.rawValue)
            .delete()
            .eq("resource_id", value: resourceId.uuidString)
            .eq("tag_id", value: tagId.uuidString)
            .execute()
    }
    
    /// Fetch resource tags
    func fetchResourceTags(resourceId: UUID) async throws -> [ResourceTag] {
        let response: [ResourceTag] = try await supabaseService.client
            .from(SupabaseService.TableName.resourceTags.rawValue)
            .select()
            .eq("resource_id", value: resourceId.uuidString)
            .execute()
            .value
        
        return response
    }
}

// MARK: - Archive Repository

/// Repository for managing archived content across all PARA categories
class ArchiveRepository: ObservableObject {
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Fetch Archives
    
    /// Fetch all archived content
    func fetchAllArchives() async throws -> [Archive] {
        let response: [Archive] = try await supabaseService.client
            .from("archives")
            .select()
            .order("archived_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch archives by content type
    func fetchArchives(contentType: String) async throws -> [Archive] {
        let response: [Archive] = try await supabaseService.client
            .from("archives")
            .select()
            .eq("content_type", value: contentType)
            .order("archived_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch archives by area
    func fetchArchives(areaId: UUID) async throws -> [Archive] {
        let response: [Archive] = try await supabaseService.client
            .from("archives")
            .select()
            .eq("area_id", value: areaId.uuidString)
            .order("archived_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch archives by project
    func fetchArchives(projectId: UUID) async throws -> [Archive] {
        let response: [Archive] = try await supabaseService.client
            .from("archives")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("archived_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Archive Operations
    
    /// Archive any PARAContent item
    func archiveContent<T: PARAContent>(_ content: T, tableName: String) async throws {
        try await supabaseService.client
            .from(tableName)
            .update(["is_archived": true])
            .eq("id", value: content.id.uuidString)
            .execute()
        
        try await supabaseService.client
            .from(tableName)
            .update(["archived_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: content.id.uuidString)
            .execute()
    }
    
    /// Unarchive any PARAContent item
    func unarchiveContent<T: PARAContent>(_ content: T, tableName: String) async throws {
        try await supabaseService.client
            .from(tableName)
            .update([
                "is_archived": false,
                "archived_at": nil
            ])
            .eq("id", value: content.id.uuidString)
            .execute()
    }
    
    /// Bulk archive items older than specified days
    func bulkArchiveOldContent(
        tableName: String,
        olderThanDays: Int,
        status: String? = nil
    ) async throws -> Int {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -olderThanDays, to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()
        let cutoffDateString = isoFormatter.string(from: cutoffDate)
        
        var queryBuilder = try supabaseService.client
            .from(tableName)
            .update(["is_archived": true])
            .lt("updated_at", value: cutoffDateString)
            .eq("is_archived", value: false)
        
        if let status = status {
            queryBuilder = queryBuilder.eq("status", value: status)
        }
        
        _ = try await queryBuilder.execute()
        
        // Update archived_at timestamp in a separate call
        var timestampBuilder = try supabaseService.client
            .from(tableName)
            .update(["archived_at": ISO8601DateFormatter().string(from: Date())])
            .lt("updated_at", value: cutoffDateString)
            .eq("is_archived", value: true)
        
        if let status = status {
            timestampBuilder = timestampBuilder.eq("status", value: status)
        }
        
        try await timestampBuilder.execute()
        
        // Note: Supabase doesn't return affected count directly
        // You might need to implement a count query if needed
        return 0
    }
    
    // MARK: - Analytics
    
    /// Get archive count by content type
    func getArchiveCountByType() async throws -> [String: Int] {
        let archives = try await fetchAllArchives()
        var counts: [String: Int] = [:]
        
        for archive in archives {
            counts[archive.contentType, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get archive count by area
    func getArchiveCountByArea() async throws -> [UUID: Int] {
        let archives = try await fetchAllArchives()
        var counts: [UUID: Int] = [:]
        
        for archive in archives {
            if let areaId = archive.areaId {
                counts[areaId, default: 0] += 1
            }
        }
        
        return counts
    }
}

// MARK: - Prompt Log Repository

/// Repository for managing LLM prompt logs and versioning
class PromptLogRepository: ObservableObject {
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CRUD Operations
    
    /// Log a prompt/response pair
    func logPrompt(
        template: String,
        version: String,
        inputData: [String: AnyCodableValue],
        promptText: String,
        responseText: String,
        modelName: String,
        tokensUsed: Int? = nil,
        processingTimeMs: Int? = nil,
        confidenceScore: Double? = nil,
        blobId: UUID? = nil
    ) async throws -> PromptLog {
        let promptLog = PromptLog(
            promptTemplate: template,
            promptVersion: version,
            inputData: inputData,
            promptText: promptText,
            responseText: responseText,
            modelName: modelName,
            tokensUsed: tokensUsed,
            processingTimeMs: processingTimeMs,
            confidenceScore: confidenceScore,
            blobId: blobId
        )
        
        return try await supabaseService.insert(promptLog, into: SupabaseService.TableName.promptLogs.rawValue)
    }
    
    /// Fetch all prompt logs
    func fetchAllPromptLogs() async throws -> [PromptLog] {
        let response: [PromptLog] = try await supabaseService.client
            .from(SupabaseService.TableName.promptLogs.rawValue)
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch prompt logs by template
    func fetchPromptLogs(template: String) async throws -> [PromptLog] {
        let response: [PromptLog] = try await supabaseService.client
            .from(SupabaseService.TableName.promptLogs.rawValue)
            .select()
            .eq("prompt_template", value: template)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch prompt logs by template and version
    func fetchPromptLogs(template: String, version: String) async throws -> [PromptLog] {
        let response: [PromptLog] = try await supabaseService.client
            .from(SupabaseService.TableName.promptLogs.rawValue)
            .select()
            .eq("prompt_template", value: template)
            .eq("prompt_version", value: version)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Analytics
    
    /// Get performance metrics for a specific template
    func getTemplateMetrics(template: String) async throws -> (avgTokens: Double, avgTime: Double, avgConfidence: Double) {
        let logs = try await fetchPromptLogs(template: template)
        
        let tokensUsed = logs.compactMap { $0.tokensUsed }.map { Double($0) }
        let processingTimes = logs.compactMap { $0.processingTimeMs }.map { Double($0) }
        let confidenceScores = logs.compactMap { $0.confidenceScore }
        
        let avgTokens = tokensUsed.isEmpty ? 0 : tokensUsed.reduce(0, +) / Double(tokensUsed.count)
        let avgTime = processingTimes.isEmpty ? 0 : processingTimes.reduce(0, +) / Double(processingTimes.count)
        let avgConfidence = confidenceScores.isEmpty ? 0 : confidenceScores.reduce(0, +) / Double(confidenceScores.count)
        
        return (avgTokens: avgTokens, avgTime: avgTime, avgConfidence: avgConfidence)
    }
}

// MARK: - ProjectRepository

/// Repository for managing Project data operations
class ProjectRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CRUD Operations
    
    /// Create a new project
    func createProject(
        name: String,
        description: String? = nil,
        status: ProjectStatus = .active,
        workPersonal: WorkPersonalType,
        dueDate: String? = nil,
        areaId: UUID? = nil
    ) async throws -> Project {
        let project = Project(
            name: name,
            description: description,
            status: status,
            workPersonal: workPersonal,
            dueDate: dueDate,
            areaId: areaId
        )
        
        return try await supabaseService.insert(project, into: SupabaseService.TableName.projects.rawValue)
    }
    
    /// Fetch all projects
    func fetchAllProjects() async throws -> [Project] {
        return try await supabaseService.fetch(Project.self, from: SupabaseService.TableName.projects.rawValue)
    }
    
    /// Fetch project by ID
    func fetchProject(id: UUID) async throws -> Project? {
        return try await supabaseService.fetchById(Project.self, from: SupabaseService.TableName.projects.rawValue, id: id)
    }
    
    /// Fetch active projects
    func fetchActiveProjects() async throws -> [Project] {
        let response: [Project] = try await supabaseService.client
            .from(SupabaseService.TableName.projects.rawValue)
            .select()
            .eq("status", value: ProjectStatus.active.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Update project
    func updateProject(_ project: Project) async throws -> Project {
        return try await supabaseService.update(
            project,
            in: SupabaseService.TableName.projects.rawValue,
            matching: "id",
            value: project.id.uuidString
        )
    }
    
    /// Delete project
    func deleteProject(id: UUID) async throws {
        try await supabaseService.delete(
            from: SupabaseService.TableName.projects.rawValue,
            matching: "id",
            value: id.uuidString
        )
    }
} 