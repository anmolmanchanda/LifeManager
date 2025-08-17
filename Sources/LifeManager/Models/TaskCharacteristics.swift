import Foundation

/// Characteristics and metadata for task analysis
struct TaskCharacteristics: Codable {
    let complexity: TaskComplexity
    let energyRequired: EnergyLevel
    let estimatedDuration: TimeInterval
    let requiresFocus: Bool
    let canBeInterrupted: Bool
    let bestTimeOfDay: TimeOfDay?
    let dependencies: [UUID]
    let tags: [String]
    
    enum TaskComplexity: String, Codable {
        case simple = "simple"
        case moderate = "moderate" 
        case complex = "complex"
        case veryComplex = "very_complex"
    }
    
    enum EnergyLevel: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case veryHigh = "very_high"
    }
    
    enum TimeOfDay: String, Codable {
        case earlyMorning = "early_morning"
        case morning = "morning"
        case midday = "midday"
        case afternoon = "afternoon"
        case evening = "evening"
        case night = "night"
        case anytime = "anytime"
    }
}

/// Extended task analysis for intelligent scheduling
extension TaskCharacteristics {
    
    /// Create default characteristics for a task
    static func defaultCharacteristics() -> TaskCharacteristics {
        return TaskCharacteristics(
            complexity: .moderate,
            energyRequired: .medium,
            estimatedDuration: 3600, // 1 hour default
            requiresFocus: true,
            canBeInterrupted: true,
            bestTimeOfDay: .anytime,
            dependencies: [],
            tags: []
        )
    }
    
    /// Analyze task title and description to infer characteristics
    static func analyze(title: String, description: String?) -> TaskCharacteristics {
        var complexity: TaskComplexity = .moderate
        var energy: EnergyLevel = .medium
        var duration: TimeInterval = 3600
        var requiresFocus = true
        var canBeInterrupted = true
        var bestTime: TimeOfDay? = .anytime
        
        let lowercaseTitle = title.lowercased()
        let lowercaseDesc = (description ?? "").lowercased()
        let combined = "\(lowercaseTitle) \(lowercaseDesc)"
        
        // Complexity analysis
        if combined.contains("simple") || combined.contains("quick") || combined.contains("easy") {
            complexity = .simple
            duration = 900 // 15 minutes
        } else if combined.contains("complex") || combined.contains("difficult") || combined.contains("detailed") {
            complexity = .complex
            duration = 7200 // 2 hours
        }
        
        // Energy analysis
        if combined.contains("brainstorm") || combined.contains("creative") || combined.contains("design") {
            energy = .high
            requiresFocus = true
            canBeInterrupted = false
        } else if combined.contains("review") || combined.contains("check") || combined.contains("routine") {
            energy = .low
            requiresFocus = false
        }
        
        // Time of day analysis
        if combined.contains("morning") {
            bestTime = .morning
        } else if combined.contains("afternoon") {
            bestTime = .afternoon
        } else if combined.contains("evening") {
            bestTime = .evening
        }
        
        return TaskCharacteristics(
            complexity: complexity,
            energyRequired: energy,
            estimatedDuration: duration,
            requiresFocus: requiresFocus,
            canBeInterrupted: canBeInterrupted,
            bestTimeOfDay: bestTime,
            dependencies: [],
            tags: extractTags(from: combined)
        )
    }
    
    private static func extractTags(from text: String) -> [String] {
        var tags: [String] = []
        
        // Extract hashtags
        let hashtagPattern = "#[a-zA-Z0-9_]+"
        if let regex = try? NSRegularExpression(pattern: hashtagPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            tags += matches.compactMap { match in
                if let range = Range(match.range, in: text) {
                    return String(text[range]).replacingOccurrences(of: "#", with: "")
                }
                return nil
            }
        }
        
        // Add context-based tags
        if text.contains("meeting") { tags.append("meeting") }
        if text.contains("email") { tags.append("email") }
        if text.contains("call") { tags.append("call") }
        if text.contains("review") { tags.append("review") }
        if text.contains("urgent") { tags.append("urgent") }
        
        return Array(Set(tags)) // Remove duplicates
    }
}