import Foundation
import Supabase

/// Core Supabase service for LifeManager
/// Provides centralized access to Supabase client and configuration
class SupabaseService: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = SupabaseService()
    
    /// Supabase client instance
    let client: SupabaseClient
    
    /// Configuration for Supabase connection
    private struct SupabaseConfig {
        // TODO: Replace with your actual Supabase URL and anon key
        static let url = "https://your-project-id.supabase.co"
        static let anonKey = "your-anon-key-here"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize Supabase client with configuration
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    // MARK: - Authentication
    
    /// Check if user is currently authenticated
    var isAuthenticated: Bool {
        return client.auth.session != nil
    }
    
    /// Get current user session
    var currentSession: Session? {
        return client.auth.session
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> Session {
        let session = try await client.auth.signIn(email: email, password: password)
        return session
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String) async throws -> Session {
        let session = try await client.auth.signUp(email: email, password: password)
        return session
    }
    
    /// Sign out current user
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Database Operations
    
    /// Generic method to insert a record into any table
    func insert<T: Codable>(_ record: T, into table: String) async throws -> T {
        let response: [T] = try await client
            .from(table)
            .insert(record)
            .execute()
            .value
        
        guard let insertedRecord = response.first else {
            throw SupabaseError.insertFailed
        }
        
        return insertedRecord
    }
    
    /// Generic method to update a record in any table
    func update<T: Codable>(_ record: T, in table: String, matching column: String, value: String) async throws -> T {
        let response: [T] = try await client
            .from(table)
            .update(record)
            .eq(column, value: value)
            .execute()
            .value
        
        guard let updatedRecord = response.first else {
            throw SupabaseError.updateFailed
        }
        
        return updatedRecord
    }
    
    /// Generic method to delete a record from any table
    func delete(from table: String, matching column: String, value: String) async throws {
        try await client
            .from(table)
            .delete()
            .eq(column, value: value)
            .execute()
    }
    
    /// Generic method to fetch records from any table
    func fetch<T: Codable>(_ type: T.Type, from table: String) async throws -> [T] {
        let response: [T] = try await client
            .from(table)
            .select()
            .execute()
            .value
        
        return response
    }
    
    /// Generic method to fetch a single record by ID
    func fetchById<T: Codable>(_ type: T.Type, from table: String, id: UUID) async throws -> T? {
        let response: [T] = try await client
            .from(table)
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        return response.first
    }
    
    // MARK: - Real-time Subscriptions
    
    /// Subscribe to changes in a specific table
    func subscribeToTable(_ table: String, callback: @escaping (RealtimeMessage) -> Void) async throws {
        let subscription = await client
            .channel("public:\(table)")
            .on(.all) { message in
                callback(message)
            }
            .subscribe()
    }
    
    // MARK: - Search Operations
    
    /// Full-text search in blobs content
    func searchBlobs(query: String) async throws -> [Blob] {
        let response: [Blob] = try await client
            .from("blobs")
            .select()
            .textSearch("content", query: query)
            .execute()
            .value
        
        return response
    }
    
    /// Filter records by work/personal type
    func fetchByWorkPersonal<T: Codable>(_ type: T.Type, from table: String, workPersonal: WorkPersonalType) async throws -> [T] {
        let response: [T] = try await client
            .from(table)
            .select()
            .eq("work_personal", value: workPersonal.rawValue)
            .execute()
            .value
        
        return response
    }
}

// MARK: - Custom Errors

enum SupabaseError: Error, LocalizedError {
    case insertFailed
    case updateFailed
    case deleteFailed
    case fetchFailed
    case notFound
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .insertFailed:
            return "Failed to insert record"
        case .updateFailed:
            return "Failed to update record"
        case .deleteFailed:
            return "Failed to delete record"
        case .fetchFailed:
            return "Failed to fetch records"
        case .notFound:
            return "Record not found"
        case .invalidConfiguration:
            return "Invalid Supabase configuration"
        }
    }
}

// MARK: - Table Names

extension SupabaseService {
    /// Enum containing all table names for type safety
    enum TableName {
        static let blobs = "blobs"
        static let categories = "categories"
        static let tags = "tags"
        static let projects = "projects"
        static let journalEntries = "journal_entries"
        static let therapySessions = "therapy_sessions"
        static let tasks = "tasks"
        static let financialEntries = "financial_entries"
        static let knowledgeEntries = "knowledge_entries"
        static let recipes = "recipes"
        static let diets = "diets"
        static let inventories = "inventories"
        static let shows = "shows"
        static let youtubeEntries = "youtube_entries"
        static let groceryLists = "grocery_lists"
        static let blobCategories = "blob_categories"
        static let blobTags = "blob_tags"
        static let taskTags = "task_tags"
        static let blobHistory = "blob_history"
        static let taskHistory = "task_history"
    }
} 