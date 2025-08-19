//
// ActivityPatternService.swift
// LifeManager
//
// Tracks and analyzes user activity patterns for context optimization
// Refactored from ContextMemoryService for better separation of concerns
//

import Foundation

/// Service for tracking and analyzing user activity patterns
class ActivityPatternService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentActivityLevel: ActivityLevel = .medium
    @Published var peakHours: [Int] = []
    @Published var dailyAverage: Double = 0.0
    @Published var workPersonalRatio: Double = 0.5
    @Published var patterns: ActivityPatterns = ActivityPatterns()
    
    // MARK: - Configuration
    private struct Config {
        static let lowActivityThreshold = 10  // items per day
        static let highActivityThreshold = 30 // items per day
        static let historyDays = 30          // days to analyze
        static let minDataPoints = 7         // minimum days for analysis
    }
    
    // MARK: - Private Properties
    private let logger = Logger.shared
    private var activityHistory: [Date: Int] = [:]
    private var hourlyDistribution: [Int: Int] = [:]
    private var categoryDistribution: [PARACategory: Int] = [:]
    
    // MARK: - Public Methods
    
    /// Update patterns with new context items
    func updatePatterns(with items: [ContextItem]) async {
        await MainActor.run {
            // Update hourly distribution
            for item in items {
                let hour = Calendar.current.component(.hour, from: item.timestamp)
                hourlyDistribution[hour, default: 0] += 1
            }
            
            // Update category distribution
            for item in items {
                categoryDistribution[item.category, default: 0] += 1
            }
            
            // Update daily count
            let today = Calendar.current.startOfDay(for: Date())
            activityHistory[today, default: 0] += items.count
            
            // Recalculate patterns
            calculateActivityLevel()
            calculatePeakHours()
            calculateDailyAverage()
            updateActivityPatterns()
        }
        
        logger.debug("ACTIVITY: Updated patterns with \(items.count) new items")
    }
    
    /// Get current activity level
    func getActivityLevel() -> ActivityLevel {
        return currentActivityLevel
    }
    
    /// Calculate work vs personal ratio from recent items
    func calculateWorkPersonalRatio(from items: [ContextItem]) -> Double {
        guard !items.isEmpty else { return 0.5 }
        
        let workCount = items.filter { $0.workPersonal == .work }.count
        let ratio = Double(workCount) / Double(items.count)
        
        return ratio
    }
    
    /// Predict optimal window size based on activity
    func predictOptimalWindowSize() -> Int {
        switch currentActivityLevel {
        case .low:
            return 50
        case .medium:
            return 100
        case .high:
            return 150
        case .veryHigh:
            return 200
        }
    }
    
    /// Get activity statistics for a date range
    func getActivityStats(for days: Int = 7) -> ActivityStats {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        var totalItems = 0
        var activeDays = 0
        
        for day in 0..<days {
            if let date = Calendar.current.date(byAdding: .day, value: -day, to: endDate) {
                let dayStart = Calendar.current.startOfDay(for: date)
                if let count = activityHistory[dayStart], count > 0 {
                    totalItems += count
                    activeDays += 1
                }
            }
        }
        
        return ActivityStats(
            totalItems: totalItems,
            activeDays: activeDays,
            averagePerDay: activeDays > 0 ? Double(totalItems) / Double(activeDays) : 0,
            peakHours: Array(peakHours.prefix(3))
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateActivityLevel() {
        let average = dailyAverage
        
        if average < Double(Config.lowActivityThreshold) {
            currentActivityLevel = .low
        } else if average < 20 {
            currentActivityLevel = .medium
        } else if average < Double(Config.highActivityThreshold) {
            currentActivityLevel = .high
        } else {
            currentActivityLevel = .veryHigh
        }
    }
    
    private func calculatePeakHours() {
        let sortedHours = hourlyDistribution
            .sorted { $0.value > $1.value }
            .map { $0.key }
        
        peakHours = Array(sortedHours.prefix(5))
    }
    
    private func calculateDailyAverage() {
        let recentDays = Config.historyDays
        let endDate = Date()
        var totalItems = 0
        var daysWithActivity = 0
        
        for day in 0..<recentDays {
            if let date = Calendar.current.date(byAdding: .day, value: -day, to: endDate) {
                let dayStart = Calendar.current.startOfDay(for: date)
                if let count = activityHistory[dayStart], count > 0 {
                    totalItems += count
                    daysWithActivity += 1
                }
            }
        }
        
        dailyAverage = daysWithActivity > 0 ? Double(totalItems) / Double(daysWithActivity) : 0
    }
    
    private func updateActivityPatterns() {
        patterns = ActivityPatterns(
            averageDailyActivity: dailyAverage,
            peakHours: peakHours,
            activityLevel: currentActivityLevel,
            workPersonalRatio: workPersonalRatio,
            lastUpdated: Date()
        )
    }
}

// MARK: - Supporting Types

enum ActivityLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
}

struct ActivityPatterns: Codable {
    var averageDailyActivity: Double = 0
    var peakHours: [Int] = []
    var activityLevel: ActivityLevel = .medium
    var workPersonalRatio: Double = 0.5
    var lastUpdated: Date = Date()
}

struct ActivityStats {
    let totalItems: Int
    let activeDays: Int
    let averagePerDay: Double
    let peakHours: [Int]
}