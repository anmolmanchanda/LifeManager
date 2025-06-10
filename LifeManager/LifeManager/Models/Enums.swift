import Foundation

// MARK: - Database Enums

enum WorkPersonalType: String, CaseIterable, Codable {
    case work = "work"
    case personal = "personal"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .both: return "Both"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case urgent = "urgent"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case inbox = "inbox"
    case todo = "todo"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum ProjectStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
}

enum FinancialCategory: String, CaseIterable, Codable {
    case expense = "expense"
    case income = "income"
    case investment = "investment"
    case transfer = "transfer"
    
    var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .investment: return "Investment"
        case .transfer: return "Transfer"
        }
    }
}

enum ShowStatus: String, CaseIterable, Codable {
    case watching = "watching"
    case completed = "completed"
    case onHold = "on_hold"
    case dropped = "dropped"
    
    var displayName: String {
        switch self {
        case .watching: return "Watching"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        case .dropped: return "Dropped"
        }
    }
}

enum YouTubeType: String, CaseIterable, Codable {
    case video = "video"
    case playlist = "playlist"
    case reaction = "reaction"
    case review = "review"
    
    var displayName: String {
        switch self {
        case .video: return "Video"
        case .playlist: return "Playlist"
        case .reaction: return "Reaction"
        case .review: return "Review"
        }
    }
}

enum SourceType: String, CaseIterable, Codable {
    case email = "email"
    case note = "note"
    case journal = "journal"
    case recipe = "recipe"
    case diet = "diet"
    case screenshot = "screenshot"
    case inventory = "inventory"
    case show = "show"
    case youtube = "youtube"
    case grocery = "grocery"
    case insight = "insight"
    case knowledge = "knowledge"
    
    var displayName: String {
        switch self {
        case .email: return "Email"
        case .note: return "Note"
        case .journal: return "Journal"
        case .recipe: return "Recipe"
        case .diet: return "Diet"
        case .screenshot: return "Screenshot"
        case .inventory: return "Inventory"
        case .show: return "Show"
        case .youtube: return "YouTube"
        case .grocery: return "Grocery"
        case .insight: return "Insight"
        case .knowledge: return "Knowledge"
        }
    }
} 