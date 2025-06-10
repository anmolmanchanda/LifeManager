import Foundation

/// Configuration example file
/// Copy this to Config.swift and fill in your actual values
/// Add Config.swift to your .gitignore to keep secrets safe

struct Config {
    // MARK: - Supabase Configuration
    static let supabaseURL = "https://cwxvmyqzhuskjwvttlbu.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3eHZteXF6aHVza2p3dnR0bGJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MjA1MTcsImV4cCI6MjA2NTA5NjUxN30.RJn7qOhY4_GghBTux8O74VvEpgv9IPSZavAEH0L61U4"
    
    // MARK: - LLM API Configuration
    static let openAIKey = "your-openai-api-key-here"
    static let claudeKey = "your-claude-api-key-here"
    
    // MARK: - Development Settings
    static let environment = "development"
    static let logLevel = "debug"
    
    // MARK: - Feature Flags (v1.0 only)
    static let enableNaturalLanguageInput = true
    static let enablePARAOrganization = true
    static let enableFullTextSearch = true
    static let enableManualFocus = true
    static let enableVersionHistory = true
    
    // v1.5+ features (disabled for v1.0)
    static let enableAutomatedRescheduling = false
    static let enableFocusMode = false
    static let enableRecurringTasks = false
    
    // v2.0+ features (disabled for v1.0)
    static let enableCalendarSync = false
    static let enableAutomatedScheduling = false
    static let enableCollaboration = false
}

/// Environment variable reading utility
enum EnvironmentReader {
    static func getValue(for key: String, defaultValue: String = "") -> String {
        return ProcessInfo.processInfo.environment[key] ?? defaultValue
    }
    
    static func getBool(for key: String, defaultValue: Bool = false) -> Bool {
        guard let value = ProcessInfo.processInfo.environment[key] else {
            return defaultValue
        }
        return value.lowercased() == "true"
    }
} 