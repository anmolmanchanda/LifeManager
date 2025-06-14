import Foundation
import SwiftUI

/// Toggl Track API Integration Service for Real-Time Time Tracking
/// 
/// CONFIGURATION REQUIRED:
/// 1. Get your Toggl Track API token from: https://track.toggl.com/profile
/// 2. Replace "YOUR_TOGGL_API_TOKEN_HERE" below with your actual API token
/// 3. Update the workspaceId with your workspace ID (found in Toggl Track URL)
///
@MainActor
class TogglService: ObservableObject {
    
    // MARK: - Configuration (UPDATE THESE VALUES)
    private var apiToken = "5134204247774c1e941370b3c54f878b"  // ⚠️ REPLACE WITH YOUR API TOKEN
    private var workspaceId = "4310831"  // ⚠️ REPLACE WITH YOUR WORKSPACE ID
    private let baseURL = "https://api.track.toggl.com/api/v9"
    
    // MARK: - Properties
    
    @Published var isConnected: Bool = false
    @Published var timeEntries: [TogglTimeEntry] = []
    @Published var isLoading: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var currentEntry: TogglTimeEntry? = nil
    @Published var projects: [TogglProject] = []
    @Published var projectColors: [Int: Color] = [:]
    
    // MARK: - Initialization
    
    init() {
        // Auto-configure if credentials are available
        if !apiToken.isEmpty && !workspaceId.isEmpty && apiToken != "YOUR_TOGGL_API_TOKEN_HERE" {
            configure(apiKey: apiToken, workspaceId: workspaceId)
        }
    }
    
    // MARK: - Configuration
    
    /// Configure Toggl service with API key and workspace
    func configure(apiKey: String, workspaceId: String) {
        self.apiToken = apiKey
        self.workspaceId = workspaceId
        self.isConnected = !apiKey.isEmpty && !workspaceId.isEmpty && apiKey != "YOUR_TOGGL_API_TOKEN_HERE"
        
        NSLog("🔧 TOGGL: Configured with workspace: \(workspaceId), connected: \(isConnected)")
        
        // Test connection and fetch projects
        Task {
            do {
                _ = try await testConnection()
                NSLog("🔧 TOGGL: ✅ Connection test successful")
                await fetchProjects()
            } catch {
                NSLog("🔧 TOGGL: ❌ Connection test failed: \(error)")
                await MainActor.run {
                    self.isConnected = false
                }
            }
        }
    }
    
    /// Test the API connection
    func testConnection() async throws -> Bool {
        let urlString = "\(baseURL)/me"
        
        guard let url = URL(string: urlString) else {
            throw TogglError.invalidURL
        }
        
        var request = URLRequest(url: url)
        // Toggl API v9 uses basic auth with API token as username and "api_token" as password
        let credentials = "\(apiToken):api_token"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        NSLog("🔧 TOGGL: Testing connection to \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TogglError.invalidResponse
        }
        
        NSLog("🔧 TOGGL: Test response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw TogglError.unauthorized
        }
        
        if httpResponse.statusCode == 200 {
            NSLog("🔧 TOGGL: ✅ API connection successful")
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("🔧 TOGGL: User info: \(responseString.prefix(200))...")
            }
            return true
        } else {
            throw TogglError.apiError(httpResponse.statusCode)
        }
    }
    
    // MARK: - API Methods
    
    /// Fetch time entries for a specific date range
    func fetchTimeEntries(startDate: Date, endDate: Date) async throws -> [TogglTimeEntry] {
        guard isConnected else {
            throw TogglError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let isoFormatter = ISO8601DateFormatter()
        let startString = isoFormatter.string(from: startDate)
        let endString = isoFormatter.string(from: endDate)
        
        let urlString = "\(baseURL)/me/time_entries?start_date=\(startString)&end_date=\(endString)"
        
        guard let url = URL(string: urlString) else {
            throw TogglError.invalidURL
        }
        
        var request = URLRequest(url: url)
        // Fix authentication - use proper Basic auth format
        let credentials = "\(apiToken):api_token"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        NSLog("🔧 TOGGL: Fetching entries from \(startString) to \(endString)")
        NSLog("🔧 TOGGL: URL: \(urlString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TogglError.invalidResponse
            }
            
            NSLog("🔧 TOGGL: Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                throw TogglError.unauthorized
            }
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    NSLog("🔧 TOGGL: Error response: \(responseString)")
                }
                throw TogglError.apiError(httpResponse.statusCode)
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("🔧 TOGGL: Raw response: \(responseString.prefix(500))...")
            }
            
            let entries = try JSONDecoder().decode([TogglTimeEntry].self, from: data)
            
            await MainActor.run {
                self.timeEntries = entries
                self.lastSyncDate = Date()
            }
            
            NSLog("🔧 TOGGL: ✅ Fetched \(entries.count) time entries")
            for entry in entries {
                NSLog("🔧 TOGGL: Entry - '\(entry.description ?? "Unnamed")' from \(entry.start) to \(entry.stop ?? "running")")
            }
            
            return entries
            
        } catch {
            NSLog("🔧 TOGGL: ❌ Error fetching time entries: \(error)")
            throw error
        }
    }
    
    /// Fetch today's time entries
    func fetchTodaysEntries() async throws -> [TogglTimeEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get today in local timezone but convert to UTC for API
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        NSLog("🔧 TOGGL: Fetching today's entries")
        NSLog("🔧 TOGGL: Local start: \(startOfDay)")
        NSLog("🔧 TOGGL: Local end: \(endOfDay)")
        
        return try await fetchTimeEntries(startDate: startOfDay, endDate: endOfDay)
    }
    
    /// Fetch projects for workspace to get colors
    func fetchProjects() async {
        guard isConnected else { return }
        
        do {
            let urlString = "\(baseURL)/workspaces/\(workspaceId)/projects"
            
            guard let url = URL(string: urlString) else {
                NSLog("🔧 TOGGL: ❌ Invalid projects URL")
                return
            }
            
            var request = URLRequest(url: url)
            let credentials = "\(apiToken):api_token"
            let credentialsData = credentials.data(using: .utf8)!
            let base64Credentials = credentialsData.base64EncodedString()
            
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            NSLog("🔧 TOGGL: Fetching projects from \(urlString)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                NSLog("🔧 TOGGL: ❌ Invalid projects response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                let fetchedProjects = try JSONDecoder().decode([TogglProject].self, from: data)
                
                await MainActor.run {
                    self.projects = fetchedProjects
                    
                    // Build project color map
                    for project in fetchedProjects {
                        if let colorHex = project.color {
                            self.projectColors[project.id] = Color(hexString: colorHex) ?? Color.green
                        } else {
                            self.projectColors[project.id] = Color.green
                        }
                    }
                    
                    NSLog("🔧 TOGGL: ✅ Fetched \(fetchedProjects.count) projects with colors")
                }
            } else {
                NSLog("🔧 TOGGL: ❌ Failed to fetch projects: \(httpResponse.statusCode)")
            }
            
        } catch {
            NSLog("🔧 TOGGL: ❌ Error fetching projects: \(error)")
        }
    }
    
    /// Get current running entry
    func getCurrentEntry() async throws -> TogglTimeEntry? {
        guard isConnected else {
            throw TogglError.notConfigured
        }
        
        let urlString = "\(baseURL)/me/time_entries/current"
        
        guard let url = URL(string: urlString) else {
            throw TogglError.invalidURL
        }
        
        var request = URLRequest(url: url)
        let credentials = "\(apiToken):api_token"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TogglError.invalidResponse
            }
            
            NSLog("🔧 TOGGL: Current entry response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let entry = try JSONDecoder().decode(TogglTimeEntry.self, from: data)
                NSLog("🔧 TOGGL: Current entry: \(entry.description ?? "Unnamed")")
                return entry
            } else if httpResponse.statusCode == 204 {
                NSLog("🔧 TOGGL: No current entry running")
                return nil // No current entry
            } else {
                throw TogglError.apiError(httpResponse.statusCode)
            }
            
        } catch {
            NSLog("🔧 TOGGL: ❌ Error fetching current entry: \(error)")
            throw error
        }
    }
    
    // MARK: - Polling
    
    private var pollingTimer: Timer?
    
    /// Start polling for time entries every 60 seconds
    func startPolling() {
        guard isConnected else { return }
        
        stopPolling()
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task {
                do {
                    let _ = try await self.fetchTodaysEntries()
                    NSLog("🔧 TOGGL: ✅ Polling update completed")
                } catch {
                    NSLog("🔧 TOGGL: ❌ Polling error: \(error)")
                }
            }
        }
        
        NSLog("🔧 TOGGL: ✅ Started polling every 60 seconds")
    }
    
    /// Stop polling for time entries
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        NSLog("🔧 TOGGL: Stopped polling")
    }
    
    // MARK: - Utility Methods
    
    /// Convert Toggl time entry to calendar event
    func convertToCalendarEvent(_ entry: TogglTimeEntry) -> CalendarEvent {
        let startDate = entry.startDate
        let endDate = entry.endDate ?? Date()
        let calculatedDuration = endDate.timeIntervalSince(startDate)
        
        NSLog("🔧 TOGGL: Converting entry '\(entry.description ?? "Unnamed")'")
        NSLog("🔧 TOGGL: Start: \(startDate), End: \(endDate)")
        NSLog("🔧 TOGGL: Duration: \(Int(calculatedDuration/60)) minutes")
        
        return CalendarEvent(
            id: UUID(uuidString: String(entry.id)) ?? UUID(),
            title: entry.description ?? "Toggl Entry",
            startDate: startDate,
            endDate: endDate,
            type: .task,
            priority: .medium,
            workPersonal: .work,
            isActual: true,
            originalPlannedTime: nil,
            source: .toggl,
            togglEntryId: entry.id,
            duration: calculatedDuration
        )
    }
    
    /// Convert Toggl time entry to calendar event with project color
    func convertToCalendarEventWithColor(_ entry: TogglTimeEntry) -> CalendarEvent {
        let startDate = entry.startDate
        let endDate = entry.endDate ?? Date()
        let calculatedDuration = endDate.timeIntervalSince(startDate)
        
        // Get project color if available
        let projectColor = entry.projectId.flatMap { projectColors[$0] } ?? Color.green
        
        NSLog("🔧 TOGGL: Converting entry '\(entry.description ?? "Unnamed")' with color")
        NSLog("🔧 TOGGL: Start: \(startDate), End: \(endDate)")
        NSLog("🔧 TOGGL: Duration: \(Int(calculatedDuration/60)) minutes")
        if let projectId = entry.projectId {
            NSLog("🔧 TOGGL: Project ID: \(projectId), Color: \(projectColor)")
        }
        
        return CalendarEvent(
            id: UUID(uuidString: String(entry.id)) ?? UUID(),
            title: entry.description ?? "Toggl Entry",
            startDate: startDate,
            endDate: endDate,
            type: .task,
            priority: .medium,
            workPersonal: .work,
            color: projectColor,
            isActual: true,
            originalPlannedTime: nil,
            source: .toggl,
            togglEntryId: entry.id,
            duration: calculatedDuration
        )
    }
    
    /// Find matching Toggl entry for a planned event
    func findMatchingEntry(for plannedEvent: CalendarEvent, tolerance: TimeInterval = 900) -> TogglTimeEntry? {
        return timeEntries.first { entry in
            let entryStart = entry.startDate
            let plannedStart = plannedEvent.startDate
            
            // Check if titles match (fuzzy matching)
            let titlesMatch = entry.description?.lowercased().contains(plannedEvent.title.lowercased()) == true ||
                             plannedEvent.title.lowercased().contains(entry.description?.lowercased() ?? "")
            
            // Check if times are within tolerance (15 minutes by default)
            let timesMatch = abs(entryStart.timeIntervalSince(plannedStart)) <= tolerance
            
            return titlesMatch && timesMatch
        }
    }
}

// MARK: - Models

/// Toggl Time Entry model
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
        NSLog("🔧 TOGGL: ❌ Failed to parse start date: \(start)")
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
        
        NSLog("🔧 TOGGL: ❌ Failed to parse stop date: \(stop)")
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

/// Toggl Project model
struct TogglProject: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String?
    let active: Bool
    let workspaceId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case active
        case workspaceId = "workspace_id"
    }
}

/// Toggl API errors
enum TogglError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case apiError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Toggl service not configured. Please provide API key and workspace ID."
        case .invalidURL:
            return "Invalid Toggl API URL"
        case .invalidResponse:
            return "Invalid response from Toggl API"
        case .unauthorized:
            return "Unauthorized. Please check your Toggl API key."
        case .apiError(let code):
            return "Toggl API error: HTTP \(code)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Color {
    /// Initialize Color from hex string
    init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

 