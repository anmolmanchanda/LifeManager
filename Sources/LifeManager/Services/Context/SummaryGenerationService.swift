//
// SummaryGenerationService.swift
// LifeManager
//
// Generates and manages daily, weekly, and monthly summaries
// Refactored from ContextMemoryService for better separation of concerns
//

import Foundation

/// Service for generating and managing context summaries at different time scales
class SummaryGenerationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var dailySummaries: [DailySummary] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    @Published var monthlySummaries: [MonthlySummary] = []
    @Published var isGenerating: Bool = false
    
    // MARK: - Configuration
    private struct Config {
        static let dailySummaryRetentionDays = 30
        static let weeklySummaryRetentionWeeks = 12
        static let monthlySummaryRetentionMonths = 6
        static let summaryGenerationHour = 23  // 11 PM
    }
    
    // MARK: - Dependencies
    private let logger = Logger.shared
    private let llmService = LLMService.shared
    private var summaryTimer: Timer?
    
    // MARK: - Initialization
    init() {
        scheduleDailySummaryGeneration()
    }
    
    deinit {
        summaryTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Generate daily summary for a specific date
    func generateDailySummary(for date: Date, items: [ContextItem]) async -> DailySummary {
        let summary = DailySummary(date: date)
        summary.addItems(items)
        
        await MainActor.run {
            // Update or add summary
            if let index = dailySummaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                dailySummaries[index] = summary
            } else {
                dailySummaries.insert(summary, at: 0)
                
                // Maintain retention limit
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -Config.dailySummaryRetentionDays, to: Date())!
                dailySummaries.removeAll { $0.date < cutoffDate }
            }
        }
        
        logger.info("SUMMARY: Generated daily summary for \(date) with \(items.count) items")
        return summary
    }
    
    /// Generate weekly summary
    func generateWeeklySummary(for weekStart: Date) async -> WeeklySummary {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        
        let weekDailies = dailySummaries.filter { summary in
            summary.date >= weekStart && summary.date < weekEnd
        }
        
        let summary = WeeklySummary(weekStartDate: weekStart, dailySummaries: weekDailies)
        
        await MainActor.run {
            if let index = weeklySummaries.firstIndex(where: { $0.weekStartDate == weekStart }) {
                weeklySummaries[index] = summary
            } else {
                weeklySummaries.insert(summary, at: 0)
                
                // Maintain retention limit
                let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -Config.weeklySummaryRetentionWeeks, to: Date())!
                weeklySummaries.removeAll { $0.weekStartDate < cutoffDate }
            }
        }
        
        logger.info("SUMMARY: Generated weekly summary for week starting \(weekStart)")
        return summary
    }
    
    /// Generate monthly summary
    func generateMonthlySummary(for monthStart: Date) async -> MonthlySummary {
        let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
        
        let monthWeeklies = weeklySummaries.filter { summary in
            summary.weekStartDate >= monthStart && summary.weekStartDate < monthEnd
        }
        
        let summary = MonthlySummary(monthStartDate: monthStart, weeklySummaries: monthWeeklies)
        
        await MainActor.run {
            if let index = monthlySummaries.firstIndex(where: { $0.monthStartDate == monthStart }) {
                monthlySummaries[index] = summary
            } else {
                monthlySummaries.insert(summary, at: 0)
                
                // Maintain retention limit
                let cutoffDate = Calendar.current.date(byAdding: .month, value: -Config.monthlySummaryRetentionMonths, to: Date())!
                monthlySummaries.removeAll { $0.monthStartDate < cutoffDate }
            }
        }
        
        logger.info("SUMMARY: Generated monthly summary for month starting \(monthStart)")
        return summary
    }
    
    /// Get formatted summary for a timeframe
    func getFormattedSummary(for timeframe: ContextTimeframe) async -> String {
        switch timeframe {
        case .day:
            return formatDailySummary()
        case .week:
            return formatWeeklySummary()
        case .month:
            return formatMonthlySummary()
        case .all:
            return await formatCompleteSummary()
        }
    }
    
    /// Update summaries with new items
    func updateSummaries(with items: [ContextItem]) async {
        // Group items by day
        let itemsByDay = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }
        
        // Update daily summaries
        for (date, dayItems) in itemsByDay {
            _ = await generateDailySummary(for: date, items: dayItems)
        }
        
        // Check if we need to generate weekly summary
        if shouldGenerateWeeklySummary() {
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start
            _ = await generateWeeklySummary(for: weekStart)
        }
        
        // Check if we need to generate monthly summary
        if shouldGenerateMonthlySummary() {
            let monthStart = Calendar.current.dateInterval(of: .month, for: Date())!.start
            _ = await generateMonthlySummary(for: monthStart)
        }
    }
    
    /// Clean up old summaries
    func cleanupOldSummaries() {
        let dailyCutoff = Calendar.current.date(byAdding: .day, value: -Config.dailySummaryRetentionDays, to: Date())!
        let weeklyCutoff = Calendar.current.date(byAdding: .weekOfYear, value: -Config.weeklySummaryRetentionWeeks, to: Date())!
        let monthlyCutoff = Calendar.current.date(byAdding: .month, value: -Config.monthlySummaryRetentionMonths, to: Date())!
        
        let oldDailies = dailySummaries.filter { $0.date < dailyCutoff }.count
        let oldWeeklies = weeklySummaries.filter { $0.weekStartDate < weeklyCutoff }.count
        let oldMonthlies = monthlySummaries.filter { $0.monthStartDate < monthlyCutoff }.count
        
        dailySummaries.removeAll { $0.date < dailyCutoff }
        weeklySummaries.removeAll { $0.weekStartDate < weeklyCutoff }
        monthlySummaries.removeAll { $0.monthStartDate < monthlyCutoff }
        
        if oldDailies + oldWeeklies + oldMonthlies > 0 {
            logger.info("SUMMARY: Cleaned up \(oldDailies) daily, \(oldWeeklies) weekly, \(oldMonthlies) monthly summaries")
        }
    }
    
    // MARK: - Private Methods
    
    private func formatDailySummary() -> String {
        guard let today = dailySummaries.first(where: { Calendar.current.isDateInToday($0.date) }) else {
            return "No activity recorded for today."
        }
        
        return """
        Today's Activity:
        • Projects: \(today.projectsActive.joined(separator: ", "))
        • Areas: \(today.areasActive.joined(separator: ", "))
        • Tasks completed: \(today.tasksCompleted)
        • Resources added: \(today.resourcesAdded)
        • Focus: \(today.topTags.prefix(3).joined(separator: ", "))
        """
    }
    
    private func formatWeeklySummary() -> String {
        guard let thisWeek = weeklySummaries.first else {
            return "No weekly summary available."
        }
        
        return """
        This Week:
        • Top projects: \(thisWeek.topProjects.joined(separator: ", "))
        • Active areas: \(thisWeek.topAreas.joined(separator: ", "))
        • Tasks: \(thisWeek.totalTasks)
        • Themes: \(thisWeek.keyThemes.joined(separator: ", "))
        """
    }
    
    private func formatMonthlySummary() -> String {
        guard let thisMonth = monthlySummaries.first else {
            return "No monthly summary available."
        }
        
        return """
        This Month:
        • Major projects: \(thisMonth.majorProjects.joined(separator: ", "))
        • Focus areas: \(thisMonth.focusAreas.joined(separator: ", "))
        • Productivity: \(thisMonth.productivityTrends)
        """
    }
    
    private func formatCompleteSummary() async -> String {
        let daily = formatDailySummary()
        let weekly = formatWeeklySummary()
        let monthly = formatMonthlySummary()
        
        return [daily, weekly, monthly].joined(separator: "\n\n")
    }
    
    private func shouldGenerateWeeklySummary() -> Bool {
        let today = Date()
        let weekday = Calendar.current.component(.weekday, from: today)
        return weekday == 1  // Sunday
    }
    
    private func shouldGenerateMonthlySummary() -> Bool {
        let today = Date()
        let day = Calendar.current.component(.day, from: today)
        return day == 1  // First day of month
    }
    
    private func scheduleDailySummaryGeneration() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: Date())
        components.hour = Config.summaryGenerationHour
        components.minute = 0
        
        if let nextRun = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            let interval = nextRun.timeIntervalSince(Date())
            
            summaryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                Task {
                    await self.performScheduledSummaryGeneration()
                    self.scheduleDailySummaryGeneration()  // Reschedule for next day
                }
            }
        }
    }
    
    private func performScheduledSummaryGeneration() async {
        isGenerating = true
        logger.info("SUMMARY: Starting scheduled summary generation")
        
        // Generate today's summary
        let today = Calendar.current.startOfDay(for: Date())
        // Note: In production, fetch today's items from database
        
        // Clean up old summaries
        cleanupOldSummaries()
        
        isGenerating = false
        logger.info("SUMMARY: Completed scheduled summary generation")
    }
}