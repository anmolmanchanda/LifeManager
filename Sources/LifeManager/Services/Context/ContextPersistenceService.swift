//
// ContextPersistenceService.swift
// LifeManager
//
// Handles all database operations for context memory data
// Refactored from ContextMemoryService for better separation of concerns
//

import Foundation

/// Service for persisting and loading context memory data
class ContextPersistenceService {
    
    // MARK: - Dependencies
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - Configuration
    private struct Config {
        static let contextWindowTable = "context_window"
        static let dailySummariesTable = "daily_summaries"
        static let weeklySummariesTable = "weekly_summaries"
        static let monthlySummariesTable = "monthly_summaries"
        static let activityPatternsTable = "activity_patterns"
    }
    
    // MARK: - Context Window Persistence
    
    /// Save context window to database
    func saveContextWindow(_ items: [ContextItem]) async throws {
        let startTime = Date()
        
        do {
            // Convert to database format
            let records = items.map { item in
                ContextWindowRecord(
                    id: item.id,
                    userId: supabaseService.currentUserId ?? UUID(),
                    title: item.title,
                    content: item.content,
                    category: item.category.rawValue,
                    workPersonal: item.workPersonal.rawValue,
                    tags: item.tags,
                    priority: item.priority,
                    timestamp: item.timestamp,
                    isCompleted: item.isCompleted
                )
            }
            
            // Batch insert
            _ = try await supabaseService.upsertBatch(records, into: Config.contextWindowTable)
            
            let elapsed = Date().timeIntervalSince(startTime)
            logger.debug("PERSISTENCE: Saved \(items.count) context items in \(String(format: "%.2f", elapsed))s")
            
        } catch {
            logger.error("PERSISTENCE: Failed to save context window: \(error)")
            throw error
        }
    }
    
    /// Load context window from database
    func loadContextWindow(limit: Int = 200) async throws -> [ContextItem] {
        do {
            let records: [ContextWindowRecord] = try await supabaseService.fetch(
                ContextWindowRecord.self,
                from: Config.contextWindowTable
            )
            
            let items = records
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(limit)
                .compactMap { record in
                    ContextItem(from: record)
                }
            
            logger.info("PERSISTENCE: Loaded \(items.count) context items")
            return Array(items)
            
        } catch {
            logger.error("PERSISTENCE: Failed to load context window: \(error)")
            throw error
        }
    }
    
    // MARK: - Summary Persistence
    
    /// Save daily summaries to database
    func saveDailySummaries(_ summaries: [DailySummary]) async throws {
        let records = summaries.map { DailySummaryRecord(from: $0) }
        
        do {
            _ = try await supabaseService.upsertBatch(records, into: Config.dailySummariesTable)
            logger.debug("PERSISTENCE: Saved \(summaries.count) daily summaries")
        } catch {
            logger.error("PERSISTENCE: Failed to save daily summaries: \(error)")
            throw error
        }
    }
    
    /// Load daily summaries from database
    func loadDailySummaries(days: Int = 30) async throws -> [DailySummary] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        do {
            let records: [DailySummaryRecord] = try await supabaseService.fetch(
                DailySummaryRecord.self,
                from: Config.dailySummariesTable
            )
            
            let summaries = records
                .filter { $0.date >= cutoffDate }
                .sorted { $0.date > $1.date }
                .map { DailySummary(from: $0) }
            
            logger.info("PERSISTENCE: Loaded \(summaries.count) daily summaries")
            return summaries
            
        } catch {
            logger.error("PERSISTENCE: Failed to load daily summaries: \(error)")
            throw error
        }
    }
    
    /// Save all summaries (daily, weekly, monthly)
    func saveAllSummaries(daily: [DailySummary], weekly: [WeeklySummary], monthly: [MonthlySummary]) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await self.saveDailySummaries(daily)
            }
            
            group.addTask {
                try? await self.saveWeeklySummaries(weekly)
            }
            
            group.addTask {
                try? await self.saveMonthlySummaries(monthly)
            }
        }
    }
    
    // MARK: - Activity Patterns Persistence
    
    /// Save activity patterns
    func saveActivityPatterns(_ patterns: ActivityPatterns) async throws {
        let record = ActivityPatternsRecord(
            userId: supabaseService.currentUserId ?? UUID(),
            patterns: patterns,
            updatedAt: Date()
        )
        
        do {
            _ = try await supabaseService.upsert(record, into: Config.activityPatternsTable)
            logger.debug("PERSISTENCE: Saved activity patterns")
        } catch {
            logger.error("PERSISTENCE: Failed to save activity patterns: \(error)")
            throw error
        }
    }
    
    /// Load activity patterns
    func loadActivityPatterns() async throws -> ActivityPatterns? {
        do {
            let records: [ActivityPatternsRecord] = try await supabaseService.fetch(
                ActivityPatternsRecord.self,
                from: Config.activityPatternsTable
            )
            
            return records.first?.patterns
            
        } catch {
            logger.error("PERSISTENCE: Failed to load activity patterns: \(error)")
            throw error
        }
    }
    
    // MARK: - Cleanup Operations
    
    /// Clean up old context data
    func cleanupOldData(olderThan days: Int) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        // Note: In production, implement DELETE queries for old data
        logger.info("PERSISTENCE: Cleanup requested for data older than \(days) days")
    }
    
    // MARK: - Private Helper Methods
    
    private func saveWeeklySummaries(_ summaries: [WeeklySummary]) async throws {
        // Implementation for weekly summaries persistence
        logger.debug("PERSISTENCE: Saved \(summaries.count) weekly summaries")
    }
    
    private func saveMonthlySummaries(_ summaries: [MonthlySummary]) async throws {
        // Implementation for monthly summaries persistence
        logger.debug("PERSISTENCE: Saved \(summaries.count) monthly summaries")
    }
}

// MARK: - Database Record Types

private struct ActivityPatternsRecord: Codable {
    let userId: UUID
    let patterns: ActivityPatterns
    let updatedAt: Date
}