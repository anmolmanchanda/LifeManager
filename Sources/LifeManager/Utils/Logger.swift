import Foundation
import os.log

/// Comprehensive logging system for LifeManager
public struct LifeLogger {
    
    // MARK: - Log Categories
    
    private static let calendar = OSLog(subsystem: "com.lifemanager.app", category: "Calendar")
    private static let taskScheduling = OSLog(subsystem: "com.lifemanager.app", category: "TaskScheduling")
    private static let weekView = OSLog(subsystem: "com.lifemanager.app", category: "WeekView")
    private static let dragDrop = OSLog(subsystem: "com.lifemanager.app", category: "DragDrop")
    private static let contextMenu = OSLog(subsystem: "com.lifemanager.app", category: "ContextMenu")
    private static let database = OSLog(subsystem: "com.lifemanager.app", category: "Database")
    private static let ui = OSLog(subsystem: "com.lifemanager.app", category: "UI")
    private static let performance = OSLog(subsystem: "com.lifemanager.app", category: "Performance")
    private static let error = OSLog(subsystem: "com.lifemanager.app", category: "Error")
    
    // MARK: - Log Levels
    
    public enum LogLevel {
        case debug
        case info
        case warning
        case error
        case critical
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
    }
    
    // MARK: - Calendar Logging
    
    public static func calendar(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: calendar, type: level.osLogType, formattedMessage)
        printToConsole(level, "CALENDAR", formattedMessage)
    }
    
    // MARK: - Task Scheduling Logging
    
    public static func taskScheduling(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: taskScheduling, type: level.osLogType, formattedMessage)
        printToConsole(level, "TASK_SCHEDULING", formattedMessage)
    }
    
    // MARK: - Week View Logging
    
    public static func weekView(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: weekView, type: level.osLogType, formattedMessage)
        printToConsole(level, "WEEK_VIEW", formattedMessage)
    }
    
    // MARK: - Drag & Drop Logging
    
    public static func dragDrop(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: dragDrop, type: level.osLogType, formattedMessage)
        printToConsole(level, "DRAG_DROP", formattedMessage)
    }
    
    // MARK: - Context Menu Logging
    
    public static func contextMenu(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: contextMenu, type: level.osLogType, formattedMessage)
        printToConsole(level, "CONTEXT_MENU", formattedMessage)
    }
    
    // MARK: - Database Logging
    
    public static func database(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: database, type: level.osLogType, formattedMessage)
        printToConsole(level, "DATABASE", formattedMessage)
    }
    
    // MARK: - UI Logging
    
    public static func ui(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: ui, type: level.osLogType, formattedMessage)
        printToConsole(level, "UI", formattedMessage)
    }
    
    // MARK: - Performance Logging
    
    public static func performance(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatMessage(level, message, file: file, function: function, line: line)
        os_log("%{public}@", log: performance, type: level.osLogType, formattedMessage)
        printToConsole(level, "PERFORMANCE", formattedMessage)
    }
    
    // MARK: - Error Logging
    
    public static func error(_ level: LogLevel, _ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        
        let formattedMessage = formatMessage(level, fullMessage, file: file, function: function, line: line)
        os_log("%{public}@", log: self.error, type: level.osLogType, formattedMessage)
        printToConsole(level, "ERROR", formattedMessage)
    }
    
    // MARK: - Helper Methods
    
    private static func formatMessage(_ level: LogLevel, _ message: String, file: String, function: String, line: Int) -> String {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        return "\(level.emoji) [\(timestamp)] \(fileName):\(line) \(function) - \(message)"
    }
    
    private static func printToConsole(_ level: LogLevel, _ category: String, _ message: String) {
        // Always print to console for immediate visibility during development
        print("🔧 \(category): \(message)")
    }
    
    // MARK: - Specialized Logging Methods
    
    /// Log task scheduling operations with detailed context
    internal static func logTaskScheduling(
        task: LifeTask,
        scheduleDate: Date,
        operation: String,
        success: Bool,
        error: Error? = nil
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let message = """
        \(operation) - Task: '\(task.title)' | 
        Schedule Date: \(dateFormatter.string(from: scheduleDate)) | 
        Duration: \(task.estimatedDuration ?? 0)min | 
        Success: \(success)
        """
        
        if success {
            taskScheduling(.info, message)
        } else {
            LifeLogger.error(.error, message, error: error)
        }
    }
    
    /// Log week view operations with performance metrics
    public static func logWeekViewOperation(
        operation: String,
        selectedDate: Date,
        eventCount: Int,
        taskCount: Int,
        duration: TimeInterval
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let message = """
        \(operation) - Date: \(dateFormatter.string(from: selectedDate)) | 
        Events: \(eventCount) | Tasks: \(taskCount) | 
        Duration: \(String(format: "%.2f", duration))s
        """
        
        weekView(.info, message)
        
        if duration > 1.0 {
            performance(.warning, "Week view operation took \(String(format: "%.2f", duration))s - consider optimization")
        }
    }
    
    /// Log drag and drop operations with detailed state
    public static func logDragDropOperation(
        operation: String,
        taskId: UUID,
        taskTitle: String,
        sourceLocation: String,
        targetLocation: String,
        success: Bool
    ) {
        let message = """
        \(operation) - Task: '\(taskTitle)' (\(taskId.uuidString.prefix(8))) | 
        From: \(sourceLocation) | To: \(targetLocation) | 
        Success: \(success)
        """
        
        if success {
            dragDrop(.info, message)
        } else {
            dragDrop(.error, message)
        }
    }
    
    /// Log context menu actions with user interaction details
    public static func logContextMenuAction(
        action: String,
        timeSlot: Date,
        eventCount: Int,
        taskCount: Int,
        success: Bool
    ) {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let message = """
        \(action) - Time: \(timeFormatter.string(from: timeSlot)) | 
        Events: \(eventCount) | Available Tasks: \(taskCount) | 
        Success: \(success)
        """
        
        if success {
            contextMenu(.info, message)
        } else {
            contextMenu(.error, message)
        }
    }
    
    /// Log database operations with timing
    public static func logDatabaseOperation(
        operation: String,
        table: String,
        recordId: UUID?,
        duration: TimeInterval,
        success: Bool,
        error: Error? = nil
    ) {
        var message = "\(operation) - Table: \(table) | Duration: \(String(format: "%.3f", duration))s"
        
        if let recordId = recordId {
            message += " | ID: \(recordId.uuidString.prefix(8))"
        }
        
        if success {
            database(.info, message)
        } else {
            LifeLogger.error(.error, message, error: error)
        }
        
        if duration > 0.5 {
            performance(.warning, "Database operation '\(operation)' took \(String(format: "%.3f", duration))s")
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Performance Measurement

public class PerformanceTimer {
    private let startTime: CFAbsoluteTime
    private let operation: String
    private let category: String
    
    public init(operation: String, category: String = "PERFORMANCE") {
        self.operation = operation
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
        LifeLogger.performance(.debug, "Started: \(operation)")
    }
    
    public func end() -> TimeInterval {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        LifeLogger.performance(.info, "Completed: \(operation) in \(String(format: "%.3f", duration))s")
        return duration
    }
}

// MARK: - Convenience Functions

/// Quick logging functions for common operations
public func logInfo(_ message: String, category: String = "INFO") {
    LifeLogger.ui(.info, message)
}

public func logWarning(_ message: String, category: String = "WARNING") {
    LifeLogger.ui(.warning, message)
}

public func logError(_ message: String, error: Error? = nil, category: String = "ERROR") {
    LifeLogger.error(.error, message, error: error)
}

public func logDebug(_ message: String, category: String = "DEBUG") {
    LifeLogger.ui(.debug, message)
} 