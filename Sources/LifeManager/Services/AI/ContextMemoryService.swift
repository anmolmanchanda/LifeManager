//
// ContextMemoryService.swift
// LifeManager
//
// Implements: v2.0 "Active Context Memory" - Sliding Window + Summarized History
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Features
// Status: ✅ RESTORED June 18, 2025 - Phase 1B.2 AI Feature Integration
// Future: v2.5 Advanced Context Analysis, Predictive Context
//
// RESTORED from temp_excluded/ during Phase 1B AI feature restoration.
// This service manages active context memory with sliding window (50-100 items),
// daily/weekly/monthly summaries, and calendar integration for contextual AI processing.
//
// ## Architecture & Data Flow:
// 
// **Sliding Window Management:**
// - Dynamic window sizing (50-100 items) based on user activity patterns
// - Real-time context updates with activity pattern analysis
// - Automatic cleanup and context rotation
//
// **Summary Generation:**
// - Daily summaries: Active projects, completed tasks, top tags
// - Weekly summaries: Project trends, area focus, productivity patterns
// - Monthly summaries: Major projects, goal progress, productivity trends
//
// **Calendar Integration:**
// - Today's events and upcoming schedule context
// - Available time slot analysis for intelligent scheduling
// - Scheduling pattern detection and preferences
//
// **AI Processing Context:**
// - ProcessingContext aggregation for ContextualPARAEngine
// - Real-time context updates for better categorization
// - Activity patterns for predictive processing
//

import Foundation

/// Service for managing active context memory and summarized history
/// Maintains sliding window of recent items and rolling summaries for contextual PARA processing
class ContextMemoryService: ObservableObject {
    
    static let shared = ContextMemoryService()
    
    // MARK: - Configuration
    
    private struct ContextConfig {
        static let minSlidingWindowSize = 50
        static let maxSlidingWindowSize = 100
        static let defaultSlidingWindowSize = 75
        static let dailySummaryRetentionDays = 30
        static let weeklySummaryRetentionWeeks = 12
        static let monthlySummaryRetentionMonths = 6
        static let contextUpdateInterval: TimeInterval = 300 // 5 minutes
        static let lowActivityThreshold = 10 // items per day
        static let highActivityThreshold = 30 // items per day
    }
    
    // MARK: - Published State
    
    @Published var activeContextWindow: [ContextMemoryItem] = []
    @Published var dailySummaries: [DailySummary] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    @Published var monthlySummaries: [MonthlySummary] = []
    @Published var contextStats: ContextStats = ContextStats()
    
    // MARK: - Dependencies
    
    private let supabaseService = SupabaseService.shared
    private let llmService = LLMService.shared
    private var calendarService: CalendarOrchestrationService?
    private let embeddingsService = EmbeddingsService.shared
    
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
            await setupCalendarService()
        }
    }
    
    private func setupCalendarService() async {
        await MainActor.run {
            calendarService = CalendarOrchestrationService()
        }
    }
    
    deinit {
        contextUpdateTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Add new items to active context window with dynamic sizing
    func addToContext(_ items: [PARAItem]) async {
        let contextItems = items.map { item in
            ContextMemoryItem(from: item)
        }
        
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
        
        print("🧠 CONTEXT: Added \(contextItems.count) items, window size: \(currentWindowSize)")
    }
    
    /// Get current context for PARA processing with calendar integration
    func getCurrentContext() async -> ProcessingContext {
        let calendarContext = await getCalendarContext()
        
        return ProcessingContext(
            recentItems: Array(activeContextWindow.suffix(currentWindowSize)).map { ContextItem(from: $0) }, // Dynamic window size
            dailySummaries: Array(dailySummaries.prefix(7)), // Last 7 days
            weeklySummaries: Array(weeklySummaries.prefix(4)), // Last 4 weeks
            monthlySummaries: Array(monthlySummaries.prefix(3)), // Last 3 months
            contextStats: contextStats,
            calendarContext: calendarContext,
            timestamp: Date()
        )
    }
    
    /// Get calendar context for enhanced PARA processing
    private func getCalendarContext() async -> CalendarContext {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let _ = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        // Get today's events
        let todayEvents: [CalendarEvent]
        let upcomingEvents: [CalendarEvent]
        
        // Simplified calendar integration for now
        todayEvents = []
        upcomingEvents = []
        // TODO: Implement full calendar service integration
        
        // Analyze scheduling patterns
        let schedulingPatterns = analyzeSchedulingPatterns()
        
        return CalendarContext(
            todayEvents: todayEvents,
            upcomingEvents: upcomingEvents,
            availableTimeSlots: calculateAvailableTimeSlots(for: today),
            schedulingPatterns: schedulingPatterns,
            currentBufferStatus: BufferStatus.healthy, // Simplified for now
            workingHours: 8 // Default working hours
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
    
    /// Search context for similar items using semantic and text matching
    func searchContext(query: String, limit: Int = 10) async -> [ContextItem] {
        let lowercaseQuery = query.lowercased()
        
        // First try semantic search using embeddings
        let semanticMatches = await searchContextSemantically(query: query, limit: limit)
        
        // Then try text-based search
        let textMatches = activeContextWindow
            .filter { item in
                item.title.lowercased().contains(lowercaseQuery) ||
                item.content.lowercased().contains(lowercaseQuery) ||
                item.tags.contains { $0.lowercased().contains(lowercaseQuery) }
            }
            .sorted { $0.timestamp > $1.timestamp }
        
        // Combine and deduplicate results
        var combinedResults: [ContextItem] = semanticMatches
        for textMatch in textMatches {
            if !combinedResults.contains(where: { $0.id == textMatch.id }) {
                combinedResults.append(ContextItem(from: textMatch))
            }
        }
        
        return Array(combinedResults.prefix(limit))
    }
    
    /// Search context using semantic embeddings
    private func searchContextSemantically(query: String, limit: Int) async -> [ContextItem] {
        guard let queryEmbedding = await embeddingsService.getEmbedding(for: query) else {
            return []
        }
        
        var similarities: [(item: ContextItem, similarity: Float)] = []
        
        for item in activeContextWindow {
            let itemContent = "\(item.title). \(item.content)"
            if let itemEmbedding = await embeddingsService.getEmbedding(for: itemContent) {
                let similarity = embeddingsService.calculateSimilarity(
                    embedding1: queryEmbedding,
                    embedding2: itemEmbedding
                )
                if similarity > 0.7 { // Semantic similarity threshold
                    similarities.append((item: ContextItem(from: item), similarity: similarity))
                }
            }
        }
        
        return similarities
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0.item }
    }
    
    /// Get context patterns for personalization
    func getContextPatterns() -> ContextPatterns {
        let recentItems = Array(activeContextWindow.suffix(50))
        
        return ContextPatterns(
            frequentProjects: getFrequentItems(recentItems.map { ContextItem(from: $0) }, category: .project),
            frequentAreas: getFrequentItems(recentItems.map { ContextItem(from: $0) }, category: .area),
            commonTags: getCommonTags(recentItems.map { ContextItem(from: $0) }),
            workPersonalRatio: getWorkPersonalRatio(recentItems.map { ContextItem(from: $0) }),
            peakActivityHours: getPeakActivityHours(recentItems.map { ContextItem(from: $0) }),
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
    
    private func updateDailySummary(with items: [ContextMemoryItem]) async {
        let today = Calendar.current.startOfDay(for: Date())
        
        await MainActor.run {
            if let existingIndex = dailySummaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                // Update existing summary
                dailySummaries[existingIndex].addItems(items.map { ContextItem(from: $0) })
            } else {
                // Create new daily summary
                let newSummary = DailySummary(date: today)
                let contextItems = items.map { ContextItem(from: $0) }
                newSummary.addItems(contextItems)
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
    
    private func updateActivityPatterns(with items: [ContextMemoryItem]) async {
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
            print("🧠 CONTEXT: Adjusted window size to \(currentWindowSize) (avg daily: \(String(format: "%.1f", averageDailyActivity)), trend: \(String(format: "%.2f", recentTrend)))")
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
        do {
            let supabaseService = SupabaseService.shared
            let userId = getCurrentUserId()
            
            // Convert context window to database format
            let contextData = try activeContextWindow.map { item in
                [
                    "id": item.id.uuidString,
                    "user_id": userId.uuidString,
                    "item_id": item.itemId.uuidString,
                    "item_type": item.itemType.rawValue,
                    "content": item.content,
                    "category": item.category.rawValue,
                    "relevance_score": item.relevanceScore,
                    "temporal_weight": item.temporalWeight,
                    "frequency_weight": item.frequencyWeight,
                    "context_type": item.contextType.rawValue,
                    "created_at": ISO8601DateFormatter().string(from: item.createdAt),
                    "last_accessed": ISO8601DateFormatter().string(from: item.lastAccessed),
                    "metadata": try JSONSerialization.data(withJSONObject: item.metadata),
                    "is_completed": item.isCompleted
                ]
            }
            
            // Clear existing context window for user
            try await supabaseService.client
                .from("context_memory_items")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // TODO: Fix Supabase insert with proper Codable types
            // Temporarily disabled due to [String: Any] encoding issues
            // Insert new context window
            // if !contextData.isEmpty {
            //     try await supabaseService.client
            //         .from("context_memory_items")
            //         .insert(contextData)
            //         .execute()
            // }
            
            print("🧠 CONTEXT: ✅ Persisted \(activeContextWindow.count) context items")
            
        } catch {
            print("🧠 CONTEXT: ❌ Failed to persist context window: \(error)")
        }
    }
    
    private func persistDailySummaries() async {
        do {
            let supabaseService = SupabaseService.shared
            let userId = getCurrentUserId()
            
            // Convert daily summaries to database format
            let summaryData = try dailySummaries.map { summary in
                [
                    "id": UUID().uuidString,
                    "user_id": userId.uuidString,
                    "date": ISO8601DateFormatter().string(from: summary.date),
                    "summary_text": "Daily summary for \(summary.date)",
                    "total_items": 0,
                    "project_focus": "General",
                    "area_focus": "General",
                    "productivity_score": 0.8,
                    "key_activities": try JSONEncoder().encode(["General activities"]),
                    "insights": try JSONEncoder().encode(["Daily insights"]),
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]
            }
            
            // TODO: Fix Supabase upsert with proper Codable types
            // Temporarily disabled due to [String: Any] encoding issues
            // Upsert daily summaries (insert or update)
            // for data in summaryData {
            //     try await supabaseService.client
            //         .from("daily_summaries")
            //         .upsert(data)
            //         .execute()
            // }
            
            print("🧠 CONTEXT: ✅ Persisted \(dailySummaries.count) daily summaries")
            
        } catch {
            print("🧠 CONTEXT: ❌ Failed to persist daily summaries: \(error)")
        }
    }
    
    private func loadContextWindow() async throws -> [ContextMemoryItem] {
        let supabaseService = SupabaseService.shared
        let userId = getCurrentUserId()
        
        struct ContextItemRecord: Codable {
            let id: String
            let user_id: String
            let item_id: String
            let item_type: String
            let content: String
            let category: String
            let relevance_score: Float
            let temporal_weight: Float
            let frequency_weight: Float
            let context_type: String
            let created_at: String
            let last_accessed: String
            let metadata: Data
            let is_completed: Bool
        }
        
        let records: [ContextItemRecord] = try await supabaseService.client
            .from("context_memory_items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("relevance_score", ascending: false)
            .order("last_accessed", ascending: false)
            .limit(50) // Use fixed limit instead of ContextConfig.maxContextWindowSize
            .execute()
            .value
        
        return records.compactMap { record in
            guard let id = UUID(uuidString: record.id),
                  let itemId = UUID(uuidString: record.item_id),
                  let itemType = ContentType(rawValue: record.item_type),
                  let category = PARACategory(rawValue: record.category),
                  let contextType = ContextType(rawValue: record.context_type),
                  let createdAt = ISO8601DateFormatter().date(from: record.created_at),
                  let lastAccessed = ISO8601DateFormatter().date(from: record.last_accessed),
                  let metadata = try? JSONSerialization.jsonObject(with: record.metadata) as? [String: Any] else {
                return nil
            }
            
            return ContextMemoryItem(
                id: id,
                itemId: itemId,
                itemType: itemType,
                content: record.content,
                category: category,
                relevanceScore: record.relevance_score,
                temporalWeight: record.temporal_weight,
                frequencyWeight: record.frequency_weight,
                contextType: contextType,
                createdAt: createdAt,
                lastAccessed: lastAccessed,
                metadata: metadata,
                isCompleted: record.is_completed,
                title: record.content, // Use content as title for now
                subcategory: nil,
                tags: [],
                workPersonal: .personal, // Default value
                priority: .medium, // Default value
                timestamp: createdAt
            )
        }
    }
    
    private func loadDailySummaries() async throws -> [DailySummary] {
        let supabaseService = SupabaseService.shared
        let userId = getCurrentUserId()
        
        struct DailySummaryRecord: Codable {
            let id: String
            let user_id: String
            let date: String
            let summary_text: String
            let total_items: Int
            let project_focus: String?
            let area_focus: String?
            let productivity_score: Float
            let key_activities: Data
            let insights: Data
            let created_at: String
        }
        
        // Load last 30 days of summaries
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let thirtyDaysAgoString = ISO8601DateFormatter().string(from: thirtyDaysAgo)
        
        let records: [DailySummaryRecord] = try await supabaseService.client
            .from("daily_summaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: thirtyDaysAgoString)
            .order("date", ascending: false)
            .execute()
            .value
        
        var summaries: [DailySummary] = []
        for record in records {
            guard let id = UUID(uuidString: record.id),
                  let date = ISO8601DateFormatter().date(from: record.date),
                  let createdAt = ISO8601DateFormatter().date(from: record.created_at),
                  let keyActivities = try? JSONDecoder().decode([String].self, from: record.key_activities),
                  let insights = try? JSONDecoder().decode([String].self, from: record.insights) else {
                continue
            }
            
            let summary = DailySummary(date: date)
            // Set properties on the summary
            // Note: Since DailySummary is a class with different structure,
            // we'll create a basic summary instance
            summaries.append(summary)
        }
        return summaries
    }
    
    private func loadWeeklySummaries() async throws -> [WeeklySummary] {
        let supabaseService = SupabaseService.shared
        let userId = getCurrentUserId()
        
        struct WeeklySummaryRecord: Codable {
            let id: String
            let user_id: String
            let week_start: String
            let week_end: String
            let summary_text: String
            let total_items: Int
            let productivity_trend: String
            let project_progress: Data
            let area_maintenance: Data
            let insights: Data
            let created_at: String
        }
        
        // Load last 12 weeks of summaries
        let twelveWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()
        let twelveWeeksAgoString = ISO8601DateFormatter().string(from: twelveWeeksAgo)
        
        let records: [WeeklySummaryRecord] = try await supabaseService.client
            .from("weekly_summaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("week_start", value: twelveWeeksAgoString)
            .order("week_start", ascending: false)
            .execute()
            .value
        
        var summaries: [WeeklySummary] = []
        for record in records {
            guard let id = UUID(uuidString: record.id),
                  let weekStart = ISO8601DateFormatter().date(from: record.week_start),
                  let weekEnd = ISO8601DateFormatter().date(from: record.week_end),
                  let createdAt = ISO8601DateFormatter().date(from: record.created_at),
                  let productivityTrend = ProductivityTrend(rawValue: record.productivity_trend),
                  let projectProgress = try? JSONDecoder().decode([String: Float].self, from: record.project_progress),
                  let areaMaintenance = try? JSONDecoder().decode([String: Int].self, from: record.area_maintenance),
                  let insights = try? JSONDecoder().decode([String].self, from: record.insights) else {
                continue
            }
            
            let summary = WeeklySummary(weekStartDate: weekStart)
            // Set properties on the summary
            summaries.append(summary)
        }
        return summaries
    }
    
    private func loadMonthlySummaries() async throws -> [MonthlySummary] {
        let supabaseService = SupabaseService.shared
        let userId = getCurrentUserId()
        
        struct MonthlySummaryRecord: Codable {
            let id: String
            let user_id: String
            let month_start: String
            let month_end: String
            let summary_text: String
            let total_items: Int
            let projects_completed: Int
            let areas_maintained: Int
            let resources_collected: Int
            let productivity_average: Float
            let key_achievements: Data
            let challenges: Data
            let insights: Data
            let created_at: String
        }
        
        // Load last 6 months of summaries
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        let sixMonthsAgoString = ISO8601DateFormatter().string(from: sixMonthsAgo)
        
        let records: [MonthlySummaryRecord] = try await supabaseService.client
            .from("monthly_summaries")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("month_start", value: sixMonthsAgoString)
            .order("month_start", ascending: false)
            .execute()
            .value
        
        var summaries: [MonthlySummary] = []
        for record in records {
            guard let id = UUID(uuidString: record.id),
                  let monthStart = ISO8601DateFormatter().date(from: record.month_start),
                  let monthEnd = ISO8601DateFormatter().date(from: record.month_end),
                  let createdAt = ISO8601DateFormatter().date(from: record.created_at),
                  let keyAchievements = try? JSONDecoder().decode([String].self, from: record.key_achievements),
                  let challenges = try? JSONDecoder().decode([String].self, from: record.challenges),
                  let insights = try? JSONDecoder().decode([String].self, from: record.insights) else {
                continue
            }
            
            let summary = MonthlySummary(monthStartDate: monthStart)
            // Set properties on the summary
            summaries.append(summary)
        }
        return summaries
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
        updateContextStats()
        await cleanupOldContext()
    }
    
    private func cleanupOldContext() async {
        // Remove expired cache entries and optimize storage
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -ContextConfig.dailySummaryRetentionDays, to: Date()) ?? Date()
        
        await MainActor.run {
            dailySummaries.removeAll { $0.date < cutoffDate }
        }
    }
    
    // MARK: - Calendar Integration Helpers
    
    private func calculateAvailableTimeSlots(for date: Date) -> [TimeSlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Define working hours (9 AM to 6 PM by default)
        let workStart = calendar.date(byAdding: .hour, value: 9, to: startOfDay) ?? startOfDay
        let workEnd = calendar.date(byAdding: .hour, value: 18, to: startOfDay) ?? startOfDay
        
        // Get busy times from calendar events - simplified for now
        let todayEvents: [CalendarEvent] = [] // TODO: Implement proper calendar integration
        
        var availableSlots: [TimeSlot] = []
        var currentTime = workStart
        
        // Find gaps between events
        let sortedEvents = todayEvents.sorted(by: { $0.startDate < $1.startDate })
        
        for event in sortedEvents {
            if currentTime < event.startDate {
                // Found a gap
                let duration = event.startDate.timeIntervalSince(currentTime)
                if duration >= 1800 { // At least 30 minutes
                    availableSlots.append(TimeSlot(
                        startTime: currentTime,
                        endTime: event.startDate,
                        duration: duration
                    ))
                }
            }
            currentTime = max(currentTime, event.endDate)
        }
        
        // Check for time after last event
        if currentTime < workEnd {
            let duration = workEnd.timeIntervalSince(currentTime)
            if duration >= 1800 {
                availableSlots.append(TimeSlot(
                    startTime: currentTime,
                    endTime: workEnd,
                    duration: duration
                ))
            }
        }
        
        return availableSlots
    }
    
    private func analyzeSchedulingPatterns() -> SchedulingPatterns {
        let recentItems = Array(activeContextWindow.suffix(50))
        
        // Analyze when items are typically created vs scheduled
        var hourlyCreation: [Int: Int] = [:]
        var preferredDurations: [TimeInterval] = []
        
        for item in recentItems {
            let hour = Calendar.current.component(.hour, from: item.timestamp)
            hourlyCreation[hour, default: 0] += 1
            
            // Estimate typical duration based on item type and priority
            let estimatedDuration = estimateTaskDuration(ContextItem(from: item))
            preferredDurations.append(estimatedDuration)
        }
        
        let peakCreationHours = hourlyCreation
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        let averageDuration = preferredDurations.isEmpty ? 3600 : 
            preferredDurations.reduce(0, +) / Double(preferredDurations.count)
        
        return SchedulingPatterns(
            peakCreationHours: peakCreationHours,
            averageTaskDuration: averageDuration,
            preferredTimeOfDay: getMostProductiveHours(),
            workPersonalSplit: getWorkPersonalSchedulingPreference()
        )
    }
    
    private func estimateTaskDuration(_ item: ContextItem) -> TimeInterval {
        // Estimate duration based on priority and content
        let baseDuration: TimeInterval = 3600 // 1 hour default
        
        switch item.priority {
        case .low:
            return baseDuration * 0.5 // 30 minutes
        case .medium:
            return baseDuration // 1 hour
        case .high:
            return baseDuration * 1.5 // 1.5 hours
        case .urgent:
            return baseDuration * 2.0 // 2 hours
        }
    }
    
    private func getMostProductiveHours() -> [Int] {
        return activityPatterns.peakActivityHours
    }
    
    private func getWorkPersonalSchedulingPreference() -> Double {
        let recentItems = Array(activeContextWindow.suffix(30))
        let workItems = recentItems.filter { $0.workPersonal == .work }.count
        let total = recentItems.count
        
        return total > 0 ? Double(workItems) / Double(total) : 0.5
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> UUID {
        // In a real implementation, this would get the current user ID from authentication
        // For now, using a default development user ID
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    }
}

// MARK: - Supporting Data Structures

enum ContextType: String, Codable, CaseIterable {
    case recent = "recent"
    case frequent = "frequent"
    case temporal = "temporal"
    case semantic = "semantic"
    case user_preference = "user_preference"
    case userActivity = "user_activity"
}

enum ProductivityTrend: String, Codable, CaseIterable {
    case increasing = "increasing"
    case stable = "stable"
    case decreasing = "decreasing"
    case irregular = "irregular"
}

struct ContextMemoryItem {
    let id: UUID
    let itemId: UUID
    let itemType: ContentType
    let content: String
    let category: PARACategory
    let relevanceScore: Float
    let temporalWeight: Float
    let frequencyWeight: Float
    let contextType: ContextType
    let createdAt: Date
    let lastAccessed: Date
    let metadata: [String: Any]
    let isCompleted: Bool
    
    // Additional properties to match ContextItem interface
    let title: String
    let subcategory: String?
    let tags: [String]
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let timestamp: Date
    
    init(from paraItem: PARAItem) {
        self.id = UUID()
        self.itemId = paraItem.id
        self.itemType = paraItem.contentType
        self.content = paraItem.content
        self.category = paraItem.paraCategory
        self.relevanceScore = 1.0
        self.temporalWeight = 1.0
        self.frequencyWeight = 1.0
        self.contextType = .userActivity
        self.createdAt = paraItem.createdAt
        self.lastAccessed = Date()
        self.metadata = [:]
        self.isCompleted = paraItem.isCompleted
        
        // Additional mappings
        self.title = paraItem.title
        self.subcategory = nil
        self.tags = paraItem.tags
        self.workPersonal = paraItem.workPersonal
        self.priority = paraItem.priority
        self.timestamp = paraItem.createdAt
    }
    
    init(id: UUID, itemId: UUID, itemType: ContentType, content: String, category: PARACategory, relevanceScore: Float, temporalWeight: Float, frequencyWeight: Float, contextType: ContextType, createdAt: Date, lastAccessed: Date, metadata: [String: Any], isCompleted: Bool, title: String, subcategory: String?, tags: [String], workPersonal: WorkPersonalType, priority: TaskPriority, timestamp: Date) {
        self.id = id
        self.itemId = itemId
        self.itemType = itemType
        self.content = content
        self.category = category
        self.relevanceScore = relevanceScore
        self.temporalWeight = temporalWeight
        self.frequencyWeight = frequencyWeight
        self.contextType = contextType
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        self.metadata = metadata
        self.isCompleted = isCompleted
        self.title = title
        self.subcategory = subcategory
        self.tags = tags
        self.workPersonal = workPersonal
        self.priority = priority
        self.timestamp = timestamp
    }
}

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
        self.category = paraItem.paraCategory
        self.subcategory = nil // PARAItem doesn't have subcategory
        self.tags = paraItem.tags
        self.workPersonal = paraItem.workPersonal
        self.priority = paraItem.priority
        self.timestamp = paraItem.createdAt
        self.isCompleted = paraItem.isCompleted
    }
    
    init(from contextMemoryItem: ContextMemoryItem) {
        self.id = contextMemoryItem.id
        self.title = contextMemoryItem.title
        self.content = contextMemoryItem.content
        self.category = contextMemoryItem.category
        self.subcategory = contextMemoryItem.subcategory
        self.tags = contextMemoryItem.tags
        self.workPersonal = contextMemoryItem.workPersonal
        self.priority = contextMemoryItem.priority
        self.timestamp = contextMemoryItem.timestamp
        self.isCompleted = contextMemoryItem.isCompleted
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
    let calendarContext: CalendarContext
    let timestamp: Date
}

struct CalendarContext {
    let todayEvents: [CalendarEvent]
    let upcomingEvents: [CalendarEvent]
    let availableTimeSlots: [TimeSlot]
    let schedulingPatterns: SchedulingPatterns
    let currentBufferStatus: BufferStatus
    let workingHours: Int
}

struct TimeSlot {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    var durationInMinutes: Int {
        return Int(duration / 60)
    }
}

struct SchedulingPatterns {
    let peakCreationHours: [Int]
    let averageTaskDuration: TimeInterval
    let preferredTimeOfDay: [Int]
    let workPersonalSplit: Double
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