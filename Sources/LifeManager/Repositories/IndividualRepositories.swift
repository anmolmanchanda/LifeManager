import Foundation

/// Repository for managing Areas data
class AreaRepository {
    
    private let supabaseService = SupabaseService.shared
    
    func fetchAllAreas() async throws -> [Area] {
        return try await supabaseService.fetch(Area.self, from: SupabaseService.TableName.areas.rawValue)
    }
    
    func fetchArea(id: UUID) async throws -> Area? {
        let areas: [Area] = try await supabaseService.fetch(Area.self, from: SupabaseService.TableName.areas.rawValue)
        return areas.first { $0.id == id }
    }
    
    func createArea(_ area: Area) async throws -> Area {
        let createdArea = try await supabaseService.insert(area, into: SupabaseService.TableName.areas.rawValue)
        
        // Generate embedding for the area
        let content = "\(createdArea.name). \(createdArea.description ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdArea.id,
            content: content,
            type: "area"
        )
        
        return createdArea
    }
    
    func updateArea(_ area: Area) async throws -> Area {
        let updatedArea = try await supabaseService.update(area, in: SupabaseService.TableName.areas.rawValue, matching: "id", value: area.id.uuidString)
        
        // Regenerate embedding for the updated area
        let content = "\(updatedArea.name). \(updatedArea.description ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: updatedArea.id,
            content: content,
            type: "area"
        )
        
        return updatedArea
    }
    
    func deleteArea(id: UUID) async throws {
        try await supabaseService.delete(from: SupabaseService.TableName.areas.rawValue, matching: "id", value: id.uuidString)
    }
}

/// Repository for managing Projects data
class ProjectRepository {
    
    private let supabaseService = SupabaseService.shared
    
    func fetchAllProjects() async throws -> [Project] {
        return try await supabaseService.fetch(Project.self, from: SupabaseService.TableName.projects.rawValue)
    }
    
    func fetchProject(id: UUID) async throws -> Project? {
        let projects: [Project] = try await supabaseService.fetch(Project.self, from: SupabaseService.TableName.projects.rawValue)
        return projects.first { $0.id == id }
    }
    
    func createProject(_ project: Project) async throws -> Project {
        let createdProject = try await supabaseService.insert(project, into: SupabaseService.TableName.projects.rawValue)
        
        // Generate embedding for the project
        let content = "\(createdProject.name). \(createdProject.description ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdProject.id,
            content: content,
            type: "project"
        )
        
        return createdProject
    }
    
    func updateProject(_ project: Project) async throws -> Project {
        let updatedProject = try await supabaseService.update(project, in: SupabaseService.TableName.projects.rawValue, matching: "id", value: project.id.uuidString)
        
        // Regenerate embedding for the updated project
        let content = "\(updatedProject.name). \(updatedProject.description ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: updatedProject.id,
            content: content,
            type: "project"
        )
        
        return updatedProject
    }
    
    func deleteProject(id: UUID) async throws {
        try await supabaseService.delete(from: SupabaseService.TableName.projects.rawValue, matching: "id", value: id.uuidString)
    }
}

/// Repository for managing Resources data
class ResourceRepository {
    
    private let supabaseService = SupabaseService.shared
    
    func fetchAllResources() async throws -> [Resource] {
        return try await supabaseService.fetch(Resource.self, from: SupabaseService.TableName.resources.rawValue)
    }
    
    func fetchResource(id: UUID) async throws -> Resource? {
        let resources: [Resource] = try await supabaseService.fetch(Resource.self, from: SupabaseService.TableName.resources.rawValue)
        return resources.first { $0.id == id }
    }
    
    func createResource(_ resource: Resource) async throws -> Resource {
        let createdResource = try await supabaseService.insert(resource, into: SupabaseService.TableName.resources.rawValue)
        
        // Generate embedding for the resource
        let content = "\(createdResource.title). \(createdResource.summary ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdResource.id,
            content: content,
            type: "resource"
        )
        
        return createdResource
    }
    
    func updateResource(_ resource: Resource) async throws -> Resource {
        let updatedResource = try await supabaseService.update(resource, in: SupabaseService.TableName.resources.rawValue, matching: "id", value: resource.id.uuidString)
        
        // Regenerate embedding for the updated resource
        let content = "\(updatedResource.title). \(updatedResource.summary ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: updatedResource.id,
            content: content,
            type: "resource"
        )
        
        return updatedResource
    }
    
    func deleteResource(id: UUID) async throws {
        try await supabaseService.delete(from: SupabaseService.TableName.resources.rawValue, matching: "id", value: id.uuidString)
    }
}

/// Repository for managing Archives data
class ArchiveRepository {
    
    private let supabaseService = SupabaseService.shared
    
    func fetchAllArchives() async throws -> [Archive] {
        return try await supabaseService.fetch(Archive.self, from: SupabaseService.TableName.archives.rawValue)
    }
    
    func fetchArchive(id: UUID) async throws -> Archive? {
        let archives: [Archive] = try await supabaseService.fetch(Archive.self, from: SupabaseService.TableName.archives.rawValue)
        return archives.first { $0.id == id }
    }
    
    func createArchive(_ archive: Archive) async throws -> Archive {
        let createdArchive = try await supabaseService.insert(archive, into: SupabaseService.TableName.archives.rawValue)
        
        // Generate embedding for the archive
        let content = "\(createdArchive.title). \(createdArchive.reason ?? "")".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdArchive.id,
            content: content,
            type: "archive"
        )
        
        return createdArchive
    }
    
    func deleteArchive(id: UUID) async throws {
        try await supabaseService.delete(from: SupabaseService.TableName.archives.rawValue, matching: "id", value: id.uuidString)
    }
    
    func restoreFromArchive(id: UUID) async throws {
        // This would involve complex logic to restore items to their original categories
        // For now, we'll just delete from archives (implementation would be more complex)
        try await deleteArchive(id: id)
    }
}

/// Repository for managing Journal Entries data
class JournalRepository {
    
    private let supabaseService = SupabaseService.shared
    
    func fetchAllJournalEntries() async throws -> [JournalEntry] {
        return try await supabaseService.fetch(JournalEntry.self, from: SupabaseService.TableName.journalEntries.rawValue)
    }
    
    func fetchJournalEntry(id: UUID) async throws -> JournalEntry? {
        let entries: [JournalEntry] = try await supabaseService.fetch(JournalEntry.self, from: SupabaseService.TableName.journalEntries.rawValue)
        return entries.first { $0.id == id }
    }
    
    func createJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        let createdEntry = try await supabaseService.insert(entry, into: SupabaseService.TableName.journalEntries.rawValue)
        
        // Generate embedding for the journal entry
        let content = "\(createdEntry.title). \(createdEntry.content)".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdEntry.id,
            content: content,
            type: "journal"
        )
        
        return createdEntry
    }
    
    func updateJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        let updatedEntry = try await supabaseService.update(entry, in: SupabaseService.TableName.journalEntries.rawValue, matching: "id", value: entry.id.uuidString)
        
        // Regenerate embedding for the updated journal entry
        let content = "\(updatedEntry.title). \(updatedEntry.content)".trimmingCharacters(in: .whitespaces)
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: updatedEntry.id,
            content: content,
            type: "journal"
        )
        
        return updatedEntry
    }
    
    func deleteJournalEntry(id: UUID) async throws {
        try await supabaseService.delete(from: SupabaseService.TableName.journalEntries.rawValue, matching: "id", value: id.uuidString)
    }
} 