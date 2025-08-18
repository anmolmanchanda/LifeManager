#!/usr/bin/env swift

import Foundation

// Test Toggl API connection directly
let apiToken = "5134204247774c1e941370b3c54f878b"
let workspaceId = "4310831"
let baseURL = "https://api.track.toggl.com/api/v9"

func testTogglConnection() async {
    print("🔧 TOGGL TEST: Starting connection test...")
    
    // Test basic connection
    let urlString = "\(baseURL)/me"
    
    guard let url = URL(string: urlString) else {
        print("❌ Invalid URL: \(urlString)")
        return
    }
    
    var request = URLRequest(url: url)
    let credentials = "\(apiToken):api_token"
    let credentialsData = credentials.data(using: .utf8)!
    let base64Credentials = credentialsData.base64EncodedString()
    
    request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    print("🔧 TOGGL TEST: Testing connection to \(urlString)")
    print("🔧 TOGGL TEST: Using API token: \(apiToken.prefix(10))...")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            return
        }
        
        print("🔧 TOGGL TEST: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔧 TOGGL TEST: Response: \(responseString.prefix(500))")
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Connection successful!")
            await testFetchTimeEntries()
        } else {
            print("❌ Connection failed with status: \(httpResponse.statusCode)")
        }
        
    } catch {
        print("❌ Error: \(error)")
    }
}

func testFetchTimeEntries() async {
    print("\n🔧 TOGGL TEST: Testing time entries fetch...")
    
    // Get today's entries
    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
    
    let isoFormatter = ISO8601DateFormatter()
    let startString = isoFormatter.string(from: startOfDay)
    let endString = isoFormatter.string(from: endOfDay)
    
    let urlString = "\(baseURL)/me/time_entries?start_date=\(startString)&end_date=\(endString)"
    
    guard let url = URL(string: urlString) else {
        print("❌ Invalid URL: \(urlString)")
        return
    }
    
    var request = URLRequest(url: url)
    let credentials = "\(apiToken):api_token"
    let credentialsData = credentials.data(using: .utf8)!
    let base64Credentials = credentialsData.base64EncodedString()
    
    request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    print("🔧 TOGGL TEST: Fetching entries from \(startString) to \(endString)")
    print("🔧 TOGGL TEST: URL: \(urlString)")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            return
        }
        
        print("🔧 TOGGL TEST: Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔧 TOGGL TEST: Raw response: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            // Try to parse as JSON
            do {
                let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                print("✅ Successfully parsed JSON array with \(jsonArray?.count ?? 0) entries")
                
                if let entries = jsonArray {
                    for (index, entry) in entries.enumerated() {
                        print("📋 Entry \(index + 1):")
                        print("   Description: \(entry["description"] ?? "No description")")
                        print("   Start: \(entry["start"] ?? "No start")")
                        print("   Stop: \(entry["stop"] ?? "Running")")
                        print("   Duration: \(entry["duration"] ?? "No duration")")
                    }
                }
            } catch {
                print("❌ Failed to parse JSON: \(error)")
            }
        } else {
            print("❌ Failed to fetch time entries with status: \(httpResponse.statusCode)")
        }
        
    } catch {
        print("❌ Error fetching time entries: \(error)")
    }
}

// Run the test
Task {
    await testTogglConnection()
    exit(0)
}

// Keep the script running
RunLoop.main.run() 