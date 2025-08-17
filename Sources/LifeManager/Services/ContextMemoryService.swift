//
// ContextMemoryService.swift
// LifeManager
//
// Implements: v2.0 "Active Context Memory" - Sliding Window + Summarized History
// Roadmap Reference: v2.0 Intelligence Expansion
// Status: ⏳ IN PROGRESS as of June 14, 2025
// Future: v2.5 Advanced Context Analysis, Predictive Context
//

import Foundation

/// Service for managing active context memory and summarized history
/// Maintains sliding window of recent items and rolling summaries for contextual PARA processing
class ContextMemoryService: ObservableObject {
    
    static let shared = ContextMemoryService()
    
    // MARK: - Configuration
    
    private struct ContextConfig {
        static let minSlidingWindowSize = 50
        static let maxSlidingWindowSize = 200
        static let defaultSlidingWindowSize = 100
        static let dailySummaryRetentionDays = 30
        static let weeklySummaryRetentionWeeks = 12
        static let monthlySummaryRetentionMonths = 6
        static let contextUpdateInterval: TimeInterval = 300 // 5 minutes
        static let lowActivityThreshold = 10 // items per day
        static let highActivityThreshold = 30 // items per day
    }
    
    // MARK: - Published State
    
    @Published var activeContextWindow: [ContextItem] = []
    @Published var dailySummaries: [DailySummary] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    @Published var monthlySummaries: [MonthlySummary] = []
    @Published var contextStats: ContextStats = ContextStats()
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let llmService = LLMService.shared
    private let logger = Logger.shared
    
    // MARK: - Internal State
    
    private var contextUpdateTimer: Timer?
    private let contextQueue = DispatchQueue(label: "context.memory", qos: .utility)
    private var currentWindowSize: Int = ContextConfig.defaultSlidingWindowSize
    private var activityPatterns: ActivityPatterns = ActivityPatterns()
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await loadContextMemory()
            startContextUpdateTimer()
        }
    }
    
    deinit {
        contextUpdateTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Add new items to active context window with dynamic sizing
    func addToContext(_ items: [PARAItem]) async {
        let contextItems = items.map { ContextItem(from: $0) }
        
        // Update activity patterns and adjust window size
        await updateActivityPatterns(with: contextItems)
        await adjustWindowSize()
        
        await MainActor.run {
            activeContextWindow.append(contentsOf: contextItems)
            
            // Maintain dynamic window size
            if activeContextWindow.count > currentWindowSize {
                let excess = activeContextWindow.count - currentWindowSize
                activeContextWindow.removeFirst(excess)
            }
            
            updateContextStats()
        }
        
        // Update summaries asynchronously
        await updateDailySummary(with: contextItems)
        await persistContextWindow()
        
        logger.debug("CONTEXT_MEMORY: Added \(contextItems.count) items, window size: \(currentWindowSize)")
    }
    
    /// Get current context for PARA processing
    func getCurrentContext() async -> ProcessingContext {
        return ProcessingContext(
            recentItems: Array(activeContextWindow.suffix(50)), // Most recent 50 items
            dailySummaries: Array(dailySummaries.prefix(7)), // Last 7 days
            weeklySummaries: Array(weeklySummaries.prefix(4)), // Last 4 weeks
            monthlySummaries: Array(monthlySummaries.prefix(3)), // Last 3 months
            contextStats: contextStats,
            timestamp: Date()
        )
    }
    
    /// Get context summary for LLM prompts
    func getContextSummary(for timeframe: ContextTimeframe = .week) async -> String {
        switch timeframe {
        case .day:
            return await getDailyContextSummary()
        case .week:
            return await getWeeklyContextSummary()
        case .month:
            return await getMonthlyContextSummary()
        case .all:
            return await getFullContextSummary()
        }
    }
    
    /// Get active projects and areas
    func getActiveItems() -> (projects: [String], areas: [String]) {
        let recentItems = Array(activeContextWindow.suffix(30))
        
        let projects = recentItems
            .filter { $0.category == .project && !$0.isCompleted }
            .map { $0.title }
            .uniqued()
        
        let areas = recentItems
            .filter { $0.category == .area }
            .map { $0.title }
            .uniqued()
        
        return (projects: projects, areas: areas)
    }
    
    /// Search context for similar items
    func searchContext(query: String, limit: Int = 10) -> [ContextItem] {
        let lowercaseQuery = query.lowercased()
        
        return activeContextWindow
            .filter { item in
                item.title.lowercased().contains(lowercaseQuery) ||
                item.content.lowercased().contains(lowercaseQuery) ||
                item.tags.contains { $0.lowercased().contains(lowercaseQuery) }
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get context patterns for personalization
    func getContextPatterns() -> ContextPatterns {
        let recentItems = Array(activeContextWindow.suffix(50))
        
        return ContextPatterns(
            frequentProjects: getFrequentItems(recentItems, category: .project),
            frequentAreas: getFrequentItems(recentItems, category: .area),
            commonTags: getCommonTags(recentItems),
            workPersonalRatio: getWorkPersonalRatio(recentItems),
            peakActivityHours: getPeakActivityHours(recentItems),
            averageItemsPerDay: getAverageItemsPerDay()
        )
    }
    
    // MARK: - Context Summaries
    
    private func getDailyContextSummary() async -> String {
        guard let todaySummary = dailySummaries.first(where: { Calendar.current.isDateInToday($0.date) }) else {
            return "No activity recorded for today."
        }
        
        return """
        Today's Activity:
        • Projects worked on: \(todaySummary.projectsActive.joined(separator: ", "))
        • Areas engaged: \(todaySummary.areasActive.joined(separator: ", "))
        • Tasks completed: \(todaySummary.tasksCompleted)
        • Resources added: \(todaySummary.resourcesAdded)
        • Focus areas: \(todaySummary.topTags.prefix(3).joined(separator: ", "))
        """
    }
    
    private func getWeeklyContextSummary() async -> String {
        let thisWeek = weeklySummaries.first ?? WeeklySummary(weekStartDate: Date())
        
        return """
        This Week's Context:
        • Top projects: \(thisWeek.topProjects.prefix(3).joined(separator: ", "))
        • Active areas: \(thisWeek.topAreas.prefix(3).joined(separator: ", "))
        • Total tasks: \(thisWeek.totalTasks)
        • Work/Personal split: \(thisWeek.workPersonalRatio)
        • Key themes: \(thisWeek.keyThemes.joined(separator: ", "))
        """
    }
    
    private func getMonthlyContextSummary() async -> String {
        let thisMonth = monthlySummaries.first ?? MonthlySummary(monthStartDate: Date())
        
        return """
        This Month's Context:
        • Major projects: \(thisMonth.majorProjects.joined(separator: ", "))
        • Focus areas: \(thisMonth.focusAreas.joined(separator: ", "))
        • Productivity trends: \(thisMonth.productivityTrends)
        • Goal progress: \(thisMonth.goalProgress)
        """
    }
    
    private func getFullContextSummary() async -> String {
        let daily = await getDailyContextSummary()
        let weekly = await getWeeklyContextSummary()
        let monthly = await getMonthlyContextSummary()
        
        return """
        \(daily)
        
        \(weekly)
        
        \(monthly)
        
        Overall Patterns:
        • Total items in context: \(activeContextWindow.count)
        • Most active category: \(contextStats.mostActiveCategory)
        • Average daily items: \(contextStats.averageDailyItems)
        """
    }
    
    // MARK: - Summary Generation
    
    private func updateDailySummary(with items: [ContextItem]) async {
        let today = Calendar.current.startOfDay(for: Date())
        
        await MainActor.run {
            if let existingIndex = dailySummaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                // Update existing summary
                dailySummaries[existingIndex].addItems(items)
            } else {
                // Create new daily summary
                let newSummary = DailySummary(date: today)
                newSummary.addItems(items)
                dailySummaries.insert(newSummary, at: 0)
                
                // Maintain retention limit
                if dailySummaries.count > ContextConfig.dailySummaryRetentionDays {
                    dailySummaries.removeLast()
                }
            }
        }
        
        // Update weekly summary if needed
        await updateWeeklySummary()
        
        // Persist summaries
        await persistDailySummaries()
    }
    
    private func updateWeeklySummary() async {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        await MainActor.run {
            if let existingIndex = weeklySummaries.firstIndex(where: { Calendar.current.isDate($0.weekStartDate, inSameDayAs: weekStart) }) {
                // Update existing weekly summary
                weeklySummaries[existingIndex] = generateWeeklySummary(for: weekStart)
            } else {
                // Create new weekly summary
                let newSummary = generateWeeklySummary(for: weekStart)
                weeklySummaries.insert(newSummary, at: 0)
                
                // Maintain retention limit
                if weeklySummaries.count > ContextConfig.weeklySummaryRetentionWeeks {
                    weeklySummaries.removeLast()
                }
            }
        }
        
        // Update monthly summary if needed
        await updateMonthlySummary()
    }
    
    private func updateMonthlySummary() async {
        let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        await MainActor.run {
            if let existingIndex = monthlySummaries.firstIndex(where: { Calendar.current.isDate($0.monthStartDate, inSameDayAs: monthStart) }) {
                // Update existing monthly summary
                monthlySummaries[existingIndex] = generateMonthlySummary(for: monthStart)
            } else {
                // Create new monthly summary
                let newSummary = generateMonthlySummary(for: monthStart)
                monthlySummaries.insert(newSummary, at: 0)
                
                // Maintain retention limit
                if monthlySummaries.count > ContextConfig.monthlySummaryRetentionMonths {
                    monthlySummaries.removeLast()
                }
            }
        }
    }
    
    private func generateWeeklySummary(for weekStart: Date) -> WeeklySummary {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
        let weekDailySummaries = dailySummaries.filter { summary in
            summary.date >= weekStart && summary.date < weekEnd
        }
        
        return WeeklySummary(
            weekStartDate: weekStart,
            dailySummaries: weekDailySummaries
        )
    }
    
    private func generateMonthlySummary(for monthStart: Date) -> MonthlySummary {
        let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? Date()
        let monthWeeklySummaries = weeklySummaries.filter { summary in
            summary.weekStartDate >= monthStart && summary.weekStartDate < monthEnd
        }
        
        return MonthlySummary(
            monthStartDate: monthStart,
            weeklySummaries: monthWeeklySummaries
        )
    }
    
    // MARK: - Context Analysis
    
    private func updateContextStats() {
        let totalItems = activeContextWindow.count
        let projectCount = activeContextWindow.filter { $0.category == .project }.count
        let areaCount = activeContextWindow.filter { $0.category == .area }.count
        let resourceCount = activeContextWindow.filter { $0.category == .resource }.count
        
        let mostActiveCategory: PARACategory
        if projectCount >= areaCount && projectCount >= resourceCount {
            mostActiveCategory = .project
        } else if areaCount >= resourceCount {
            mostActiveCategory = .area
        } else {
            mostActiveCategory = .resource
        }
        
        contextStats = ContextStats(
            totalItems: totalItems,
            projectCount: projectCount,
            areaCount: areaCount,
            resourceCount: resourceCount,
            mostActiveCategory: mostActiveCategory,
            averageDailyItems: calculateAverageDailyItems(),
            lastUpdated: Date()
        )
    }
    
    private func getFrequentItems(_ items: [ContextItem], category: PARACategory) -> [String] {
        let categoryItems = items.filter { $0.category == category }
        let titleCounts = Dictionary(grouping: categoryItems, by: { $0.title })
            .mapValues { $0.count }
        
        return titleCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func getCommonTags(_ items: [ContextItem]) -> [String] {
        let allTags = items.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
        
        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
    
    private func getWorkPersonalRatio(_ items: [ContextItem]) -> String {
        let workItems = items.filter { $0.workPersonal == .work }.count
        let personalItems = items.filter { $0.workPersonal == .personal }.count
        let total = workItems + personalItems
        
        guard total > 0 else { return "No data" }
        
        let workPercentage = Int((Double(workItems) / Double(total)) * 100)
        return "\(workPercentage)% work, \(100 - workPercentage)% personal"
    }
    
    private func getPeakActivityHours(_ items: [ContextItem]) -> [Int] {
        let hourCounts = Dictionary(grouping: items, by: { Calendar.current.component(.hour, from: $0.timestamp) })
            .mapValues { $0.count }
        
        return hourCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func getAverageItemsPerDay() -> Double {
        guard !dailySummaries.isEmpty else { return 0.0 }
        
        let totalItems = dailySummaries.reduce(0) { $0 + $1.totalItems }
        return Double(totalItems) / Double(dailySummaries.count)
    }
    
    private func calculateAverageDailyItems() -> Double {
        return getAverageItemsPerDay()
    }
    
    // MARK: - Dynamic Window Sizing
    
    private func updateActivityPatterns(with items: [ContextItem]) async {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        
        // Update daily activity count
        if let lastUpdateDay = activityPatterns.lastUpdateDate,
           Calendar.current.isDate(lastUpdateDay, inSameDayAs: today) {
            activityPatterns.todayItemCount += items.count
        } else {
            // New day - archive yesterday's count and start fresh
            if activityPatterns.todayItemCount > 0 {
                activityPatterns.dailyActivityHistory.append(activityPatterns.todayItemCount)
                if activityPatterns.dailyActivityHistory.count > 14 {
                    activityPatterns.dailyActivityHistory.removeFirst()
                }
            }
            activityPatterns.todayItemCount = items.count
        }
        
        activityPatterns.lastUpdateDate = now
        
        // Update peak activity hours
        let currentHour = Calendar.current.component(.hour, from: now)
        activityPatterns.hourlyActivity[currentHour, default: 0] += items.count
        
        // Update category distribution
        for item in items {
            activityPatterns.categoryDistribution[item.category, default: 0] += 1
        }
    }
    
    private func adjustWindowSize() async {
        let averageDailyActivity = activityPatterns.averageDailyActivity
        let recentTrend = activityPatterns.recentActivityTrend
        
        var newWindowSize = currentWindowSize
        
        // Base window size on activity level
        if averageDailyActivity < Double(ContextConfig.lowActivityThreshold) {
            // Low activity - smaller window for more focused context
            newWindowSize = ContextConfig.minSlidingWindowSize
        } else if averageDailyActivity > Double(ContextConfig.highActivityThreshold) {
            // High activity - larger window to maintain sufficient context
            newWindowSize = ContextConfig.maxSlidingWindowSize
        } else {
            // Medium activity - proportional sizing
            let ratio = (averageDailyActivity - Double(ContextConfig.lowActivityThreshold)) / 
                       (Double(ContextConfig.highActivityThreshold) - Double(ContextConfig.lowActivityThreshold))
            newWindowSize = ContextConfig.minSlidingWindowSize + 
                           Int(ratio * Double(ContextConfig.maxSlidingWindowSize - ContextConfig.minSlidingWindowSize))
        }
        
        // Adjust based on recent trend
        if recentTrend > 1.2 {
            // Increasing activity - expand window
            newWindowSize = min(newWindowSize + 10, ContextConfig.maxSlidingWindowSize)
        } else if recentTrend < 0.8 {
            // Decreasing activity - contract window
            newWindowSize = max(newWindowSize - 10, ContextConfig.minSlidingWindowSize)
        }
        
        // Update window size if changed
        if newWindowSize != currentWindowSize {
            currentWindowSize = newWindowSize
            logger.info("CONTEXT_MEMORY: Adjusted window size to \(currentWindowSize) (avg daily: \(String(format: "%.1f", averageDailyActivity)), trend: \(String(format: "%.2f", recentTrend)))")
        }
    }
    
    // MARK: - Persistence
    
    private func loadContextMemory() async {
        do {
            // Load active context window
            activeContextWindow = try await loadContextWindow()
            
            // Load summaries
            dailySummaries = try await loadDailySummaries()
            weeklySummaries = try await loadWeeklySummaries()
            monthlySummaries = try await loadMonthlySummaries()
            
            // Update stats
            await MainActor.run {
                updateContextStats()
            }
            
            print("🧠 CONTEXT: ✅ Loaded context memory - \(activeContextWindow.count) items in window")
            
        } catch {
            print("🧠 CONTEXT: ❌ Failed to load context memory: \(error)")
        }
    }
    
    private func persistContextWindow() async {
        // Implementation for persisting context window to database
        // This would integrate with your Supabase service
    }
    
    private func persistDailySummaries() async {
        // Implementation for persisting daily summaries to database
    }
    
    private func loadContextWindow() async throws -> [ContextItem] {
        // Implementation for loading context window from database
        return []
    }
    
    private func loadDailySummaries() async throws -> [DailySummary] {
        // Implementation for loading daily summaries from database
        return []
    }
    
    private func loadWeeklySummaries() async throws -> [WeeklySummary] {
        // Implementation for loading weekly summaries from database
        return []
    }
    
    private func loadMonthlySummaries() async throws -> [MonthlySummary] {
        // Implementation for loading monthly summaries from database
        return []
    }
    
    // MARK: - Timer Management
    
    private func startContextUpdateTimer() {
        contextUpdateTimer = Timer.scheduledTimer(withTimeInterval: ContextConfig.contextUpdateInterval, repeats: true) { _ in
            Task {
                await self.performPeriodicContextUpdate()
            }
        }
    }
    
    private func performPeriodicContextUpdate() async {
        // Periodic maintenance tasks
        await updateContextStats()
        await cleanupOldContext()
    }
    
    private func cleanupOldContext() async {
        // Remove expired cache entries and optimize storage
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -ContextConfig.dailySummaryRetentionDays, to: Date()) ?? Date()
        
        await MainActor.run {
            dailySummaries.removeAll { $0.date < cutoffDate }
        }
    }
}

// MARK: - Supporting Data Structures

struct ContextItem {
    let id: UUID
    let title: String
    let content: String
    let category: PARACategory
    let subcategory: String?
    let tags: [String]
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let timestamp: Date
    let isCompleted: Bool
    
    init(from paraItem: PARAItem) {
        self.id = UUID()
        self.title = paraItem.title
        self.content = paraItem.content
        self.category = paraItem.category
        self.subcategory = nil // PARAItem doesn't have subcategory
        self.tags = paraItem.tags
        self.workPersonal = paraItem.workPersonal
        self.priority = paraItem.priority
        self.timestamp = paraItem.createdAt
        self.isCompleted = paraItem.isCompleted
    }
}

class DailySummary: ObservableObject {
    let date: Date
    @Published var projectsActive: [String] = []
    @Published var areasActive: [String] = []
    @Published var tasksCompleted: Int = 0
    @Published var resourcesAdded: Int = 0
    @Published var topTags: [String] = []
    @Published var totalItems: Int = 0
    
    init(date: Date) {
        self.date = date
    }
    
    func addItems(_ items: [ContextItem]) {
        for item in items {
            switch item.category {
            case .project:
                if !projectsActive.contains(item.title) {
                    projectsActive.append(item.title)
                }
            case .area:
                if !areasActive.contains(item.title) {
                    areasActive.append(item.title)
                }
            case .resource:
                resourcesAdded += 1
            case .archive:
                break
            }
            
            if item.isCompleted {
                tasksCompleted += 1
            }
        }
        
        totalItems += items.count
        updateTopTags(from: items)
    }
    
    private func updateTopTags(from items: [ContextItem]) {
        let allTags = items.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 }).mapValues { $0.count }
        topTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
}

struct WeeklySummary {
    let weekStartDate: Date
    let dailySummaries: [DailySummary]
    
    init(weekStartDate: Date, dailySummaries: [DailySummary] = []) {
        self.weekStartDate = weekStartDate
        self.dailySummaries = dailySummaries
    }
    
    var topProjects: [String] {
        let allProjects = dailySummaries.flatMap { $0.projectsActive }
        return Array(Set(allProjects)).prefix(5).map { String($0) }
    }
    
    var topAreas: [String] {
        let allAreas = dailySummaries.flatMap { $0.areasActive }
        return Array(Set(allAreas)).prefix(5).map { String($0) }
    }
    
    var totalTasks: Int {
        return dailySummaries.reduce(0) { $0 + $1.tasksCompleted }
    }
    
    var workPersonalRatio: String {
        // Implementation would analyze work/personal distribution
        return "60% work, 40% personal"
    }
    
    var keyThemes: [String] {
        let allTags = dailySummaries.flatMap { $0.topTags }
        return Array(Set(allTags)).prefix(3).map { String($0) }
    }
}

struct MonthlySummary {
    let monthStartDate: Date
    let weeklySummaries: [WeeklySummary]
    
    init(monthStartDate: Date, weeklySummaries: [WeeklySummary] = []) {
        self.monthStartDate = monthStartDate
        self.weeklySummaries = weeklySummaries
    }
    
    var majorProjects: [String] {
        let allProjects = weeklySummaries.flatMap { $0.topProjects }
        return Array(Set(allProjects)).prefix(3).map { String($0) }
    }
    
    var focusAreas: [String] {
        let allAreas = weeklySummaries.flatMap { $0.topAreas }
        return Array(Set(allAreas)).prefix(3).map { String($0) }
    }
    
    var productivityTrends: String {
        // Implementation would analyze productivity patterns
        return "Increasing productivity trend"
    }
    
    var goalProgress: String {
        // Implementation would track goal completion
        return "3 of 5 monthly goals on track"
    }
}

struct ContextStats {
    let totalItems: Int
    let projectCount: Int
    let areaCount: Int
    let resourceCount: Int
    let mostActiveCategory: PARACategory
    let averageDailyItems: Double
    let lastUpdated: Date
    
    init() {
        self.totalItems = 0
        self.projectCount = 0
        self.areaCount = 0
        self.resourceCount = 0
        self.mostActiveCategory = .project
        self.averageDailyItems = 0.0
        self.lastUpdated = Date()
    }
    
    init(totalItems: Int, averageConfidence: Float, topCategories: [PARACategory], recentPatterns: [String]) {
        self.totalItems = totalItems
        self.projectCount = 0
        self.areaCount = 0
        self.resourceCount = 0
        self.mostActiveCategory = topCategories.first ?? .project
        self.averageDailyItems = 0.0
        self.lastUpdated = Date()
    }
    
    init(totalItems: Int, projectCount: Int, areaCount: Int, resourceCount: Int, mostActiveCategory: PARACategory, averageDailyItems: Double, lastUpdated: Date) {
        self.totalItems = totalItems
        self.projectCount = projectCount
        self.areaCount = areaCount
        self.resourceCount = resourceCount
        self.mostActiveCategory = mostActiveCategory
        self.averageDailyItems = averageDailyItems
        self.lastUpdated = lastUpdated
    }
}

struct ProcessingContext {
    let recentItems: [ContextItem]
    let dailySummaries: [DailySummary]
    let weeklySummaries: [WeeklySummary]
    let monthlySummaries: [MonthlySummary]
    let contextStats: ContextStats
    let timestamp: Date
}

struct ContextPatterns {
    let frequentProjects: [String]
    let frequentAreas: [String]
    let commonTags: [String]
    let workPersonalRatio: String
    let peakActivityHours: [Int]
    let averageItemsPerDay: Double
}

enum ContextTimeframe {
    case day, week, month, all
}

// Priority is defined as TaskPriority in CoreModels.swift

// MARK: - Extensions

// MARK: - Activity Patterns for Dynamic Window Sizing

struct ActivityPatterns {
    var todayItemCount: Int = 0
    var lastUpdateDate: Date? = nil
    var dailyActivityHistory: [Int] = []
    var hourlyActivity: [Int: Int] = [:]
    var categoryDistribution: [PARACategory: Int] = [:]
    
    var averageDailyActivity: Double {
        guard !dailyActivityHistory.isEmpty else { return Double(todayItemCount) }
        let total = dailyActivityHistory.reduce(0, +) + todayItemCount
        return Double(total) / Double(dailyActivityHistory.count + 1)
    }
    
    var recentActivityTrend: Double {
        guard dailyActivityHistory.count >= 3 else { return 1.0 }
        
        let recent = Array(dailyActivityHistory.suffix(3))
        let older = Array(dailyActivityHistory.prefix(max(0, dailyActivityHistory.count - 3)))
        
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let olderAvg = older.isEmpty ? recentAvg : Double(older.reduce(0, +)) / Double(older.count)
        
        return olderAvg > 0 ? recentAvg / olderAvg : 1.0
    }
    
    var peakActivityHours: [Int] {
        return hourlyActivity
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    var dominantCategory: PARACategory {
        return categoryDistribution
            .max { $0.value < $1.value }?
            .key ?? .project
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        return Array(Set(self))
    }
} 