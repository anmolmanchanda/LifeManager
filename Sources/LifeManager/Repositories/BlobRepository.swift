import Foundation

/// Repository for managing Blob data operations
class BlobRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CRUD Operations
    
    /// Create a new blob
    func createBlob(
        content: String,
        sourceType: SourceType,
        workPersonal: WorkPersonalType = .personal
    ) async throws -> Blob {
        let blob = Blob(
            content: content,
            sourceType: sourceType,
            workPersonal: workPersonal
        )
        
        let createdBlob = try await supabaseService.insert(
            blob,
            into: SupabaseService.TableName.blobs.rawValue
        )
        
        // Generate embedding for the blob content
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdBlob.id,
            content: createdBlob.content,
            type: "blob"
        )
        
        return createdBlob
    }
    
    /// Create blob from Blob object
    func createBlob(_ blob: Blob) async throws -> Blob {
        let createdBlob = try await supabaseService.insert(
            blob,
            into: SupabaseService.TableName.blobs.rawValue
        )
        
        // Generate embedding for the blob content
        await EmbeddingsService.shared.generateEmbeddingForPARAItem(
            id: createdBlob.id,
            content: createdBlob.content,
            type: "blob"
        )
        
        return createdBlob
    }
    
    /// Fetch all blobs
    func fetchAllBlobs() async throws -> [Blob] {
        return try await supabaseService.fetch(Blob.self, from: SupabaseService.TableName.blobs.rawValue)
    }
    
    /// Fetch blob by ID
    func fetchBlob(id: UUID) async throws -> Blob? {
        return try await supabaseService.fetchById(Blob.self, from: SupabaseService.TableName.blobs.rawValue, id: id)
    }
    
    /// Fetch unprocessed blobs (inbox)
    func fetchUnprocessedBlobs() async throws -> [Blob] {
        let response: [Blob] = try await supabaseService.client
            .from(SupabaseService.TableName.blobs.rawValue)
            .select()
            .eq("processed", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch processed blobs (for PARA categorization)
    func fetchProcessedBlobs() async throws -> [Blob] {
        let response: [Blob] = try await supabaseService.client
            .from(SupabaseService.TableName.blobs.rawValue)
            .select()
            .eq("processed", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch blobs by source type
    func fetchBlobs(sourceType: SourceType) async throws -> [Blob] {
        let response: [Blob] = try await supabaseService.client
            .from(SupabaseService.TableName.blobs.rawValue)
            .select()
            .eq("source_type", value: sourceType.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch blobs by work/personal filter
    func fetchBlobs(workPersonal: WorkPersonalType) async throws -> [Blob] {
        return try await supabaseService.fetchByWorkPersonal(
            Blob.self,
            from: SupabaseService.TableName.blobs.rawValue,
            workPersonal: workPersonal
        )
    }
    
    /// Update blob
    func updateBlob(_ blob: Blob) async throws -> Blob {
        return try await supabaseService.update(
            blob,
            in: SupabaseService.TableName.blobs.rawValue,
            matching: "id",
            value: blob.id.uuidString
        )
    }
    
    /// Mark blob as processed
    func markBlobAsProcessed(id: UUID) async throws -> Blob {
        guard let blob = try await fetchBlob(id: id) else {
            throw SupabaseError.notFound
        }
        
        // Create a new blob instance with processed = true
        let updatedBlob = Blob(
            id: blob.id,
            content: blob.content,
            sourceType: blob.sourceType,
            workPersonal: blob.workPersonal,
            processed: true,
            projectId: blob.projectId,
            areaId: blob.areaId,
            isArchived: blob.isArchived
        )
        
        return try await updateBlob(updatedBlob)
    }
    
    /// Delete blob
    func deleteBlob(id: UUID) async throws {
        try await supabaseService.delete(
            from: SupabaseService.TableName.blobs.rawValue,
            matching: "id",
            value: id.uuidString
        )
    }
    
    // MARK: - Search Operations
    
    /// Search blobs by content
    func searchBlobs(query: String) async throws -> [Blob] {
        return try await supabaseService.searchBlobs(query: query)
    }
    
    /// Search blobs with filters
    func searchBlobs(
        query: String,
        sourceType: SourceType? = nil,
        workPersonal: WorkPersonalType? = nil,
        processed: Bool? = nil
    ) async throws -> [Blob] {
        var queryBuilder = supabaseService.client
            .from(SupabaseService.TableName.blobs.rawValue)
            .select()
            .textSearch("content", query: query)
        
        if let sourceType = sourceType {
            queryBuilder = queryBuilder.eq("source_type", value: sourceType.rawValue)
        }
        
        if let workPersonal = workPersonal {
            queryBuilder = queryBuilder.eq("work_personal", value: workPersonal.rawValue)
        }
        
        if let processed = processed {
            queryBuilder = queryBuilder.eq("processed", value: processed)
        }
        
        let response: [Blob] = try await queryBuilder
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Category and Tag Operations
    
    /// Assign category to blob
    func assignCategory(blobId: UUID, categoryId: UUID, confidenceScore: Double = 0.5) async throws -> BlobCategory {
        let blobCategory = BlobCategory(
            blobId: blobId,
            categoryId: categoryId,
            confidenceScore: confidenceScore
        )
        
        return try await supabaseService.insert(blobCategory, into: SupabaseService.TableName.blobCategories.rawValue)
    }
    
    /// Assign tag to blob
    func assignTag(blobId: UUID, tagId: UUID) async throws -> BlobTag {
        let blobTag = BlobTag(blobId: blobId, tagId: tagId)
        return try await supabaseService.insert(blobTag, into: SupabaseService.TableName.blobTags.rawValue)
    }
    
    /// Fetch blob categories
    func fetchBlobCategories(blobId: UUID) async throws -> [BlobCategory] {
        let response: [BlobCategory] = try await supabaseService.client
            .from(SupabaseService.TableName.blobCategories.rawValue)
            .select()
            .eq("blob_id", value: blobId.uuidString)
            .execute()
            .value
        
        return response
    }
    
    /// Fetch blob tags
    func fetchBlobTags(blobId: UUID) async throws -> [BlobTag] {
        let response: [BlobTag] = try await supabaseService.client
            .from(SupabaseService.TableName.blobTags.rawValue)
            .select()
            .eq("blob_id", value: blobId.uuidString)
            .execute()
            .value
        
        return response
    }
    
    /// Remove category from blob
    func removeCategory(blobId: UUID, categoryId: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.blobCategories.rawValue)
            .delete()
            .eq("blob_id", value: blobId.uuidString)
            .eq("category_id", value: categoryId.uuidString)
            .execute()
    }
    
    /// Remove tag from blob
    func removeTag(blobId: UUID, tagId: UUID) async throws {
        try await supabaseService.client
            .from(SupabaseService.TableName.blobTags.rawValue)
            .delete()
            .eq("blob_id", value: blobId.uuidString)
            .eq("tag_id", value: tagId.uuidString)
            .execute()
    }
    
    // MARK: - Analytics and Reporting
    
    /// Get blob count by source type
    func getBlobCountBySourceType() async throws -> [String: Int] {
        // This would require a custom SQL query or aggregation
        // For now, fetch all and count in-memory (not optimal for large datasets)
        let blobs = try await fetchAllBlobs()
        var counts: [String: Int] = [:]
        
        for blob in blobs {
            let sourceType = blob.sourceType.rawValue
            counts[sourceType, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get recent blobs (last N days)
    func fetchRecentBlobs(days: Int = 7) async throws -> [Blob] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()
        let startDateString = isoFormatter.string(from: startDate)
        
        let response: [Blob] = try await supabaseService.client
            .from(SupabaseService.TableName.blobs.rawValue)
            .select()
            .gte("created_at", value: startDateString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
} 