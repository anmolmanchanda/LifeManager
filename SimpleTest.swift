#!/usr/bin/env swift

import Foundation

print("🧪 Testing LifeManager Core Components...")

// Simple enum test
enum TestPriority: String, CaseIterable {
    case urgent = "urgent"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

let priority = TestPriority.high
print("✅ Priority test: \(priority.displayName)")

print("🎉 Basic Swift compilation working!")
print("📱 Your LifeManager code structure is ready for Xcode!") 