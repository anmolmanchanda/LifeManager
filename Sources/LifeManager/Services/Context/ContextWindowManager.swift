//
// ContextWindowManager.swift
// LifeManager
//
// Manages the sliding window of active context items
// Refactored from ContextMemoryService for better separation of concerns
//

import Foundation
import Combine

/// Manages the sliding window of active context items with dynamic sizing
class ContextWindowManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeWindow: [ContextItem] = []
    @Published var windowSize: Int = 100
    @Published var itemCount: Int = 0
    
    // MARK: - Configuration
    private struct Config {
        static let minWindowSize = 50
        static let maxWindowSize = 200
        static let defaultWindowSize = 100
        static let pruneThreshold = 0.8  // Prune when 80% full
    }
    
    // MARK: - Private Properties
    private let logger = Logger.shared
    private let queue = DispatchQueue(label: "context.window", qos: .utility)
    private var lastPruneDate = Date()
    
    // MARK: - Public Methods
    
    /// Add new items to the context window
    func addItems(_ items: [PARAItem]) async {
        let contextItems = items.map { ContextItem(from: $0) }
        
        await MainActor.run {
            activeWindow.append(contentsOf: contextItems)
            
            // Maintain window size
            if activeWindow.count > windowSize {
                let excess = activeWindow.count - windowSize
                activeWindow.removeFirst(excess)
                logger.debug("CONTEXT_WINDOW: Removed \(excess) old items to maintain window size")
            }
            
            itemCount = activeWindow.count
        }
        
        logger.info("CONTEXT_WINDOW: Added \(items.count) items, window size: \(activeWindow.count)/\(windowSize)")
    }
    
    /// Get current window of context items
    func getCurrentWindow() -> [ContextItem] {
        return activeWindow
    }
    
    /// Get recent items from the window
    func getRecentItems(count: Int = 50) -> [ContextItem] {
        return Array(activeWindow.suffix(count))
    }
    
    /// Adjust window size based on activity level
    func adjustWindowSize(basedOn activityLevel: ActivityLevel) {
        let newSize: Int
        
        switch activityLevel {
        case .low:
            newSize = Config.minWindowSize
        case .medium:
            newSize = Config.defaultWindowSize
        case .high:
            newSize = 150
        case .veryHigh:
            newSize = Config.maxWindowSize
        }
        
        if newSize != windowSize {
            let oldSize = windowSize
            windowSize = newSize
            
            // Prune if necessary
            if activeWindow.count > newSize {
                let excess = activeWindow.count - newSize
                activeWindow.removeFirst(excess)
            }
            
            logger.info("CONTEXT_WINDOW: Adjusted size from \(oldSize) to \(newSize) based on \(activityLevel) activity")
        }
    }
    
    /// Remove oldest items from window
    func removeOldest(_ count: Int) {
        guard count > 0 && count <= activeWindow.count else { return }
        
        activeWindow.removeFirst(count)
        itemCount = activeWindow.count
        
        logger.debug("CONTEXT_WINDOW: Removed \(count) oldest items")
    }
    
    /// Clear all items from the window
    func clearWindow() {
        activeWindow.removeAll()
        itemCount = 0
        logger.info("CONTEXT_WINDOW: Cleared all items")
    }
    
    /// Prune old items based on age
    func pruneOldItems(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let originalCount = activeWindow.count
        
        activeWindow.removeAll { item in
            item.timestamp < cutoffDate
        }
        
        let removed = originalCount - activeWindow.count
        if removed > 0 {
            itemCount = activeWindow.count
            logger.info("CONTEXT_WINDOW: Pruned \(removed) items older than \(days) days")
        }
    }
    
    /// Get items filtered by category
    func getItems(by category: PARACategory) -> [ContextItem] {
        return activeWindow.filter { $0.category == category }
    }
    
    /// Get items filtered by work/personal type
    func getItems(by type: WorkPersonalType) -> [ContextItem] {
        return activeWindow.filter { $0.workPersonal == type }
    }
    
    /// Check if window needs pruning
    func shouldPrune() -> Bool {
        let fillRatio = Double(activeWindow.count) / Double(windowSize)
        return fillRatio > Config.pruneThreshold
    }
    
    /// Get window statistics
    func getWindowStats() -> WindowStats {
        let categories = Dictionary(grouping: activeWindow, by: { $0.category })
        let types = Dictionary(grouping: activeWindow, by: { $0.workPersonal })
        
        return WindowStats(
            totalItems: activeWindow.count,
            windowSize: windowSize,
            fillPercentage: Double(activeWindow.count) / Double(windowSize) * 100,
            oldestItem: activeWindow.first?.timestamp,
            newestItem: activeWindow.last?.timestamp,
            categoryCounts: categories.mapValues { $0.count },
            typeCounts: types.mapValues { $0.count }
        )
    }
}

// MARK: - Supporting Types

struct WindowStats {
    let totalItems: Int
    let windowSize: Int
    let fillPercentage: Double
    let oldestItem: Date?
    let newestItem: Date?
    let categoryCounts: [PARACategory: Int]
    let typeCounts: [WorkPersonalType: Int]
    
    var ageSpan: TimeInterval? {
        guard let oldest = oldestItem, let newest = newestItem else { return nil }
        return newest.timeIntervalSince(oldest)
    }
    
    var formattedAgeSpan: String {
        guard let span = ageSpan else { return "N/A" }
        
        let days = Int(span / 86400)
        let hours = Int((span.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}