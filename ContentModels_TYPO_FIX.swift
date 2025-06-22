//
// ContentModels.swift - TYPO FIX  
// Fix typo in LifeTask model property name
//

// MARK: - Fix Typo in LifeTask (Line 119)
// Replace:
// var canBePermalentlyDeleted: Bool {

// With:
var canBePermanentlyDeleted: Bool {
    guard let deletedAt = deletedAt else { return false }
    
    guard let deletedDate = ISO8601DateFormatter().date(from: deletedAt) else {
        return false
    }
    
    let hoursSinceDeleted = Date().timeIntervalSince(deletedDate) / 3600
    return hoursSinceDeleted >= 24
}

/*
INTEGRATION INSTRUCTIONS:

In ContentModels.swift line 119:
- Change "canBePermalentlyDeleted" to "canBePermanentlyDeleted" (add missing "n")

This fixes the typo that would cause compilation errors when the soft delete system is activated.
*/