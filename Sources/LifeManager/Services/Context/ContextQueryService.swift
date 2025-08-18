//
// ContextQueryService.swift
// LifeManager
//
// Provides search and query capabilities for context data
// Refactored from ContextMemoryService for better separation of concerns
//

import Foundation

/// Service for querying and searching context data
class ContextQueryService {
    
    // MARK: - Dependencies
    private let logger = Logger.shared
    
    // MARK: - Public Methods
    
    /// Search context items by query string
    func searchContext(_ items: [ContextItem], query: String, limit: Int = 10) -> [ContextItem] {
        guard !query.isEmpty else { return Array(items.prefix(limit)) }
        
        let lowercaseQuery = query.lowercased()
        
        let results = items
            .filter { item in
                item.title.lowercased().contains(lowercaseQuery) ||
                item.content.lowercased().contains(lowercaseQuery) ||
                item.tags.contains { $0.lowercased().contains(lowercaseQuery) }
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
        
        logger.debug("QUERY: Found \(results.count) matches for '\(query)'")
        return Array(results)
    }
    
    /// Get frequent items by category
    func getFrequentItems(_ items: [ContextItem], category: PARACategory, limit: Int = 5) -> [String] {
        let categoryItems = items.filter { $0.category == category }
        
        let titleCounts = Dictionary(grouping: categoryItems, by: { $0.title })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        return Array(titleCounts)
    }
    
    /// Get common tags across all items
    func getCommonTags(_ items: [ContextItem], limit: Int = 10) -> [String] {
        let allTags = items.flatMap { $0.tags }
        
        let tagCounts = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        return Array(tagCounts)
    }
    
    /// Get active projects from context
    func getActiveProjects(_ items: [ContextItem]) -> [String] {
        return items
            .filter { $0.category == .project && !$0.isCompleted }
            .map { $0.title }
            .uniqued()
            .sorted()
    }
    
    /// Get active areas from context
    func getActiveAreas(_ items: [ContextItem]) -> [String] {
        return items
            .filter { $0.category == .area }
            .map { $0.title }
            .uniqued()
            .sorted()
    }
    
    /// Get context patterns from items
    func getContextPatterns(_ items: [ContextItem]) -> ContextPatterns {
        let projects = getFrequentItems(items, category: .project)
        let areas = getFrequentItems(items, category: .area)
        let tags = getCommonTags(items)
        let workPersonalRatio = calculateWorkPersonalRatio(items)
        let peakHours = calculatePeakActivityHours(items)
        let avgPerDay = calculateAverageItemsPerDay(items)
        
        return ContextPatterns(
            frequentProjects: projects,
            frequentAreas: areas,
            commonTags: tags,
            workPersonalRatio: formatRatio(workPersonalRatio),
            peakActivityHours: peakHours,
            averageItemsPerDay: avgPerDay
        )
    }
    
    /// Filter items by date range
    func filterByDateRange(_ items: [ContextItem], from startDate: Date, to endDate: Date) -> [ContextItem] {
        return items.filter { item in
            item.timestamp >= startDate && item.timestamp <= endDate
        }
    }
    
    /// Filter items by work/personal type
    func filterByType(_ items: [ContextItem], type: WorkPersonalType) -> [ContextItem] {
        return items.filter { $0.workPersonal == type }
    }
    
    /// Filter items by category
    func filterByCategory(_ items: [ContextItem], category: PARACategory) -> [ContextItem] {
        return items.filter { $0.category == category }
    }
    
    /// Filter items by completion status
    func filterByCompletion(_ items: [ContextItem], completed: Bool) -> [ContextItem] {
        return items.filter { $0.isCompleted == completed }
    }
    
    /// Get items with specific tags
    func filterByTags(_ items: [ContextItem], tags: [String]) -> [ContextItem] {
        let lowercaseTags = tags.map { $0.lowercased() }
        
        return items.filter { item in
            let itemTags = item.tags.map { $0.lowercased() }
            return !Set(itemTags).isDisjoint(with: Set(lowercaseTags))
        }
    }
    
    /// Get statistics for items
    func getStatistics(_ items: [ContextItem]) -> ContextStatistics {
        let categoryCounts = Dictionary(grouping: items, by: { $0.category })
            .mapValues { $0.count }
        
        let typeCounts = Dictionary(grouping: items, by: { $0.workPersonal })
            .mapValues { $0.count }
        
        let completedCount = items.filter { $0.isCompleted }.count
        let avgPriority = items.isEmpty ? 0 : items.reduce(0) { $0 + $1.priority } / items.count
        
        return ContextStatistics(
            totalItems: items.count,
            categoryCounts: categoryCounts,
            typeCounts: typeCounts,
            completedCount: completedCount,
            pendingCount: items.count - completedCount,
            averagePriority: avgPriority,
            dateRange: getDateRange(items)
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateWorkPersonalRatio(_ items: [ContextItem]) -> Double {
        guard !items.isEmpty else { return 0.5 }
        
        let workCount = items.filter { $0.workPersonal == .work }.count
        return Double(workCount) / Double(items.count)
    }
    
    private func formatRatio(_ ratio: Double) -> String {
        let workPercent = Int(ratio * 100)
        let personalPercent = 100 - workPercent
        return "\(workPercent)% work, \(personalPercent)% personal"
    }
    
    private func calculatePeakActivityHours(_ items: [ContextItem]) -> [Int] {
        let hourCounts = Dictionary(grouping: items) { item in
            Calendar.current.component(.hour, from: item.timestamp)
        }.mapValues { $0.count }
        
        return hourCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func calculateAverageItemsPerDay(_ items: [ContextItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        
        let dates = Set(items.map { Calendar.current.startOfDay(for: $0.timestamp) })
        return Double(items.count) / Double(dates.count)
    }
    
    private func getDateRange(_ items: [ContextItem]) -> (start: Date?, end: Date?) {
        guard !items.isEmpty else { return (nil, nil) }
        
        let sorted = items.sorted { $0.timestamp < $1.timestamp }
        return (sorted.first?.timestamp, sorted.last?.timestamp)
    }
}

// MARK: - Supporting Types

struct ContextPatterns {
    let frequentProjects: [String]
    let frequentAreas: [String]
    let commonTags: [String]
    let workPersonalRatio: String
    let peakActivityHours: [Int]
    let averageItemsPerDay: Double
}

struct ContextStatistics {
    let totalItems: Int
    let categoryCounts: [PARACategory: Int]
    let typeCounts: [WorkPersonalType: Int]
    let completedCount: Int
    let pendingCount: Int
    let averagePriority: Int
    let dateRange: (start: Date?, end: Date?)
}

// MARK: - Array Extension

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}