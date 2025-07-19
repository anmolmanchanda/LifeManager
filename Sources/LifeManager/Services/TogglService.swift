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
    
    // MARK: - Enhanced Rate Limiting & Request Queue
    private var lastRequestTime: Date = Date.distantPast
    private let minimumRequestInterval: TimeInterval = 3.0 // Increased to 3 seconds
    private var requestQueue: [APIRequest] = []
    private var isProcessingQueue = false
    
    // Request queue item
    private struct APIRequest {
        let id = UUID()
        let urlRequest: URLRequest
        let completion: (Result<Data, Error>) -> Void
    }
    
    // MARK: - Caching
    private var cachedTimeEntries: [String: ([TogglTimeEntry], Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
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
        // DISABLED: Complete service shutdown to prevent keychain access
        Logger.shared.info("TOGGL: Service completely disabled to prevent keychain access")
        self.isConnected = false
        self.apiToken = "" // Clear any API token
        self.workspaceId = "" // Clear workspace ID
    }
    
    // MARK: - Configuration
    
    /// Configure Toggl service with API key and workspace
    func configure(apiKey: String, workspaceId: String) {
        // DISABLED: Prevent any configuration to avoid keychain access
        Logger.shared.info("TOGGL: Configuration disabled to prevent keychain access")
        self.isConnected = false
        // Do not set any tokens or make any network calls
    }
    
    // MARK: - Enhanced Rate Limiting with Queue Processing
    
    /// Process request queue with proper rate limiting
    private func processRequestQueue() async {
        guard !isProcessingQueue && !requestQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        while !requestQueue.isEmpty {
            let request = requestQueue.removeFirst()
            
            // Ensure minimum interval between requests
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
            if timeSinceLastRequest < minimumRequestInterval {
                let waitTime = minimumRequestInterval - timeSinceLastRequest
                Logger.shared.info("TOGGL: Queue processing - waiting \(waitTime)s for rate limit")
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request.urlRequest)
                
                // Handle 429 Rate Limiting with exponential backoff
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                    Logger.shared.info("TOGGL: 429 Rate Limited - implementing exponential backoff")
                    
                    // Exponential backoff: 5, 10, 20 seconds
                    let backoffDelay: TimeInterval = min(5.0 * pow(2.0, Double(requestQueue.count)), 20.0)
                    Logger.shared.info("TOGGL: Backing off for \(backoffDelay)s")
                    
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    
                    // Re-queue the request
                    requestQueue.insert(request, at: 0)
                    continue
                }
                
                lastRequestTime = Date()
                request.completion(.success(data))
                
            } catch {
                Logger.shared.info("TOGGL: Queue request failed: \(error)")
                request.completion(.failure(error))
            }
        }
        
        isProcessingQueue = false
    }
    
    /// Queue a request with rate limiting
    private func queueRequest(_ urlRequest: URLRequest) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let request = APIRequest(urlRequest: urlRequest) { result in
                continuation.resume(with: result)
            }
            
            requestQueue.append(request)
            
            Task {
                await processRequestQueue()
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
        
        Logger.shared.info("TOGGL: Testing connection to \(urlString)")
        
        let data = try await queueRequest(request)
        
        Logger.shared.info("TOGGL: ✅ API connection successful")
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.shared.info("TOGGL: User info: \(responseString.prefix(200))...")
        }
        return true
    }
    
    // MARK: - Enhanced API Methods with Caching
    
    /// Fetch time entries for a specific date range with caching
    func fetchTimeEntries(startDate: Date, endDate: Date) async throws -> [TogglTimeEntry] {
        guard isConnected else {
            throw TogglError.notConfigured
        }
        
        // Create cache key
        let isoFormatter = ISO8601DateFormatter()
        let startString = isoFormatter.string(from: startDate)
        let endString = isoFormatter.string(from: endDate)
        let cacheKey = "\(startString)-\(endString)"
        
        // Check cache first
        if let (cachedEntries, cacheTime) = cachedTimeEntries[cacheKey],
           Date().timeIntervalSince(cacheTime) < cacheValidityDuration {
            Logger.shared.info("TOGGL: ✅ Using cached entries (\(cachedEntries.count) entries)")
            await MainActor.run {
                self.timeEntries = cachedEntries
                self.lastSyncDate = cacheTime
            }
            return cachedEntries
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "\(baseURL)/me/time_entries?start_date=\(startString)&end_date=\(endString)"
        
        guard let url = URL(string: urlString) else {
            throw TogglError.invalidURL
        }
        
        var request = URLRequest(url: url)
        let credentials = "\(apiToken):api_token"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        Logger.shared.info("TOGGL: Fetching entries from \(startString) to \(endString)")
        Logger.shared.info("TOGGL: URL: \(urlString)")
        
        do {
            let data = try await queueRequest(request)
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.shared.info("TOGGL: Raw response: \(responseString.prefix(500))...")
            }
            
            let entries = try JSONDecoder().decode([TogglTimeEntry].self, from: data)
            
            // Cache the results
            cachedTimeEntries[cacheKey] = (entries, Date())
            
            await MainActor.run {
                self.timeEntries = entries
                self.lastSyncDate = Date()
            }
            
            Logger.shared.info("TOGGL: ✅ Fetched \(entries.count) time entries")
            for entry in entries {
                Logger.shared.info("TOGGL: Entry - '\(entry.description ?? "Unnamed")' from \(entry.start) to \(entry.stop ?? "running")")
            }
            
            return entries
            
        } catch {
            Logger.shared.info("TOGGL: ❌ Error fetching time entries: \(error)")
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
        
        Logger.shared.info("TOGGL: Fetching today's entries")
        Logger.shared.info("TOGGL: Local start: \(startOfDay)")
        Logger.shared.info("TOGGL: Local end: \(endOfDay)")
        
        return try await fetchTimeEntries(startDate: startOfDay, endDate: endOfDay)
    }
    
    /// Fetch projects for workspace to get colors
    func fetchProjects() async {
        guard isConnected else { return }
        
        do {
            let urlString = "\(baseURL)/workspaces/\(workspaceId)/projects"
            
            guard let url = URL(string: urlString) else {
                Logger.shared.info("TOGGL: ❌ Invalid projects URL")
                return
            }
            
            var request = URLRequest(url: url)
            let credentials = "\(apiToken):api_token"
            let credentialsData = credentials.data(using: .utf8)!
            let base64Credentials = credentialsData.base64EncodedString()
            
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            Logger.shared.info("TOGGL: Fetching projects from \(urlString)")
            
            let data = try await queueRequest(request)
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
                
                Logger.shared.info("TOGGL: ✅ Fetched \(fetchedProjects.count) projects with colors")
            }
            
        } catch {
            Logger.shared.info("TOGGL: ❌ Error fetching projects: \(error)")
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
            let data = try await queueRequest(request)
            
            if data.isEmpty {
                Logger.shared.info("TOGGL: No current entry running")
                return nil // No current entry
            }
            
            let entry = try JSONDecoder().decode(TogglTimeEntry.self, from: data)
            Logger.shared.info("TOGGL: Current entry: \(entry.description ?? "Unnamed")")
            return entry
            
        } catch {
            Logger.shared.info("TOGGL: ❌ Error fetching current entry: \(error)")
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
                    Logger.shared.info("TOGGL: ✅ Polling update completed")
                } catch {
                    Logger.shared.info("TOGGL: ❌ Polling error: \(error)")
                }
            }
        }
        
        Logger.shared.info("TOGGL: ✅ Started polling every 60 seconds")
    }
    
    /// Stop polling for time entries
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        Logger.shared.info("TOGGL: Stopped polling")
    }
    
    // MARK: - Utility Methods
    
    /// Convert Toggl time entry to calendar event
    func convertToCalendarEvent(_ entry: TogglTimeEntry) -> CalendarEvent {
        let startDate = entry.startDate
        let endDate = entry.endDate ?? Date()
        let calculatedDuration = endDate.timeIntervalSince(startDate)
        
        Logger.shared.info("TOGGL: Converting entry '\(entry.description ?? "Unnamed")'")
        Logger.shared.info("TOGGL: Start: \(startDate), End: \(endDate)")
        Logger.shared.info("TOGGL: Duration: \(Int(calculatedDuration/60)) minutes")
        
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
        
        Logger.shared.info("TOGGL: Converting entry '\(entry.description ?? "Unnamed")' with color")
        Logger.shared.info("TOGGL: Start: \(startDate), End: \(endDate)")
        Logger.shared.info("TOGGL: Duration: \(Int(calculatedDuration/60)) minutes")
        if let projectId = entry.projectId {
            Logger.shared.info("TOGGL: Project ID: \(projectId), Color: \(projectColor)")
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
        Logger.shared.info("TOGGL: ❌ Failed to parse start date: \(start)")
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
        
        Logger.shared.info("TOGGL: ❌ Failed to parse stop date: \(stop)")
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

 