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
        return try await supabaseService.insert(area, into: SupabaseService.TableName.areas.rawValue)
    }
    
    func updateArea(_ area: Area) async throws -> Area {
        return try await supabaseService.update(area, in: SupabaseService.TableName.areas.rawValue, matching: "id", value: area.id.uuidString)
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
        return try await supabaseService.insert(project, into: SupabaseService.TableName.projects.rawValue)
    }
    
    func updateProject(_ project: Project) async throws -> Project {
        return try await supabaseService.update(project, in: SupabaseService.TableName.projects.rawValue, matching: "id", value: project.id.uuidString)
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
        return try await supabaseService.insert(resource, into: SupabaseService.TableName.resources.rawValue)
    }
    
    func updateResource(_ resource: Resource) async throws -> Resource {
        return try await supabaseService.update(resource, in: SupabaseService.TableName.resources.rawValue, matching: "id", value: resource.id.uuidString)
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
        return try await supabaseService.insert(archive, into: SupabaseService.TableName.archives.rawValue)
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