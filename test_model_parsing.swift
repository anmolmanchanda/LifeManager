#!/usr/bin/env swift

import Foundation

// Copy the TogglTimeEntry struct from the main codebase
struct TogglTimeEntry: Codable, Identifiable {
    let id: Int
    let description: String?
    let start: String
    let stop: String?
    let duration: Int
    let projectId: Int?
    let workspaceId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case start
        case stop
        case duration
        case projectId = "project_id"
        case workspaceId = "workspace_id"
    }
    
    // Computed properties for easier date handling
    var startDate: Date {
        // Toggl uses ISO8601 format with timezone info
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: start) {
            return date
        }
        
        // Fallback without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: start) {
            return date
        }
        
        // Last resort fallback
        print("🔧 TOGGL: ❌ Failed to parse start date: \(start)")
        return Date()
    }
    
    var endDate: Date? {
        guard let stop = stop else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: stop) {
            return date
        }
        
        // Fallback without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: stop) {
            return date
        }
        
        print("🔧 TOGGL: ❌ Failed to parse stop date: \(stop)")
        return nil
    }
    
    var isRunning: Bool {
        return stop == nil && duration < 0
    }
    
    var actualDuration: TimeInterval {
        if let endDate = endDate {
            return endDate.timeIntervalSince(startDate)
        } else if isRunning {
            return Date().timeIntervalSince(startDate)
        } else {
            return TimeInterval(abs(duration))
        }
    }
}

// Test data from the actual API response
let sampleJsonData = """
[
    {
        "id": 3972178761,
        "workspace_id": 4310831,
        "project_id": 161857184,
        "task_id": null,
        "billable": false,
        "start": "2025-06-11T18:02:47+00:00",
        "stop": null,
        "duration": -1749664967,
        "description": "LifeManager",
        "tags": ["To do in"],
        "tag_ids": [8185405],
        "duronly": true,
        "at": "2025-06-11T18:04:01.128464Z",
        "server_deleted_at": null,
        "user_id": 5760596,
        "uid": 5760596,
        "wid": 4310831,
        "pid": 161857184
    },
    {
        "id": 3972173902,
        "workspace_id": 4310831,
        "project_id": 161857221,
        "task_id": null,
        "billable": false,
        "start": "2025-06-11T18:01:02+00:00",
        "stop": "2025-06-11T18:02:47+00:00",
        "duration": 105,
        "description": "Messages",
        "tags": ["Talk"],
        "tag_ids": [8141535],
        "duronly": true,
        "at": "2025-06-11T18:03:57.290487Z",
        "server_deleted_at": null,
        "user_id": 5760596,
        "uid": 5760596,
        "wid": 4310831,
        "pid": 161857221
    }
]
""".data(using: .utf8)!

func testTogglModelParsing() {
    print("🔧 MODEL TEST: Starting TogglTimeEntry parsing test...")
    
    do {
        let entries = try JSONDecoder().decode([TogglTimeEntry].self, from: sampleJsonData)
        print("✅ Successfully decoded \(entries.count) entries")
        
        for (index, entry) in entries.enumerated() {
            print("\n📋 Entry \(index + 1):")
            print("   ID: \(entry.id)")
            print("   Description: \(entry.description ?? "No description")")
            print("   Raw Start: \(entry.start)")
            print("   Raw Stop: \(entry.stop ?? "null")")
            print("   Duration: \(entry.duration)")
            print("   Is Running: \(entry.isRunning)")
            
            // Test date parsing
            let startDate = entry.startDate
            let endDate = entry.endDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            print("   Parsed Start: \(dateFormatter.string(from: startDate))")
            if let endDate = endDate {
                print("   Parsed End: \(dateFormatter.string(from: endDate))")
            } else {
                print("   Parsed End: null (running)")
            }
            
            print("   Actual Duration: \(Int(entry.actualDuration)) seconds (\(Int(entry.actualDuration/60)) minutes)")
        }
        
    } catch {
        print("❌ Failed to decode JSON: \(error)")
    }
}

testTogglModelParsing() 