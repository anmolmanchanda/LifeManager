import Foundation

/// LLM service for natural language processing and PARA categorization
/// Handles OpenAI/Claude API calls for content analysis and task extraction
class LLMService: ObservableObject {
    
    static let shared = LLMService()
    
    // MARK: - Configuration
    
    private struct APIConfig {
        static let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        static let claudeKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let claudeBaseURL = "https://api.anthropic.com/v1"
    }
    
    private enum LLMProvider {
        case openAI
        case claude
    }
    
    private let supabaseService = SupabaseService.shared
    private let preferredProvider: LLMProvider = .openAI // Can be configured
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Process natural language input and suggest PARA categorization
    func processNaturalLanguage(
        input: String,
        sourceType: SourceType = .note,
        availableAreas: [Area] = [],
        availableProjects: [Project] = []
    ) async throws -> PARAProcessingResult {
        
        let promptTemplate = "categorize_blob"
        let promptVersion = "v1.0"
        
        // Prepare input data
        let inputData: [String: AnyCodableValue] = [
            "content": .string(input),
            "source_type": .string(sourceType.rawValue),
            "available_areas": .array(availableAreas.map { .string($0.name) }),
            "available_projects": .array(availableProjects.map { .string($0.name) })
        ]
        
        // Load prompt template
        let promptText = try loadPromptTemplate(promptTemplate, with: inputData)
        
        // Call LLM API
        let startTime = Date()
        let response = try await callLLM(prompt: promptText)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        // Parse response
        let result = try parseCategorizationResponse(response)
        
        // Log prompt/response for optimization
        await logPromptExecution(
            template: promptTemplate,
            version: promptVersion,
            inputData: inputData,
            promptText: promptText,
            responseText: response,
            processingTime: processingTime,
            confidenceScore: result.confidenceScore
        )
        
        return result
    }
    
    /// Extract actionable tasks from content
    func extractTasks(
        from content: String,
        availableAreas: [Area] = [],
        availableProjects: [Project] = []
    ) async throws -> TaskExtractionResult {
        
        let promptTemplate = "extract_tasks"
        let promptVersion = "v1.0"
        
        let inputData: [String: AnyCodableValue] = [
            "content": .string(content),
            "available_areas": .array(availableAreas.map { .string($0.name) }),
            "available_projects": .array(availableProjects.map { .string($0.name) })
        ]
        
        let promptText = try loadPromptTemplate(promptTemplate, with: inputData)
        
        let startTime = Date()
        let response = try await callLLM(prompt: promptText)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        let result = try parseTaskExtractionResponse(response)
        
        await logPromptExecution(
            template: promptTemplate,
            version: promptVersion,
            inputData: inputData,
            promptText: promptText,
            responseText: response,
            processingTime: processingTime,
            confidenceScore: result.confidenceScore
        )
        
        return result
    }
    
    /// Suggest priority and due date for a task
    func suggestTaskPriority(
        title: String,
        description: String?,
        context: [String: AnyCodableValue] = [:]
    ) async throws -> TaskPriorityResult {
        
        let promptTemplate = "prioritize_task"
        let promptVersion = "v1.0"
        
        let inputData: [String: AnyCodableValue] = [
            "title": .string(title),
            "description": .string(description ?? ""),
            "context": .object(context)
        ]
        
        let promptText = "Analyze this task and suggest priority level and due date if applicable: '\(title)'. Description: '\(description ?? "")'. Consider urgency, importance, and any time constraints mentioned."
        
        let startTime = Date()
        let response = try await callLLM(prompt: promptText)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        let result = try parseTaskPriorityResponse(response)
        
        await logPromptExecution(
            template: promptTemplate,
            version: promptVersion,
            inputData: inputData,
            promptText: promptText,
            responseText: response,
            processingTime: processingTime,
            confidenceScore: result.confidenceScore
        )
        
        return result
    }
    
    // MARK: - Private Methods
    
    /// Load prompt template from file
    private func loadPromptTemplate(_ templateName: String, with data: [String: AnyCodableValue]) throws -> String {
        guard let templatePath = Bundle.main.path(forResource: templateName, ofType: "txt", inDirectory: "prompts/templates"),
              let template = try? String(contentsOfFile: templatePath) else {
            // Fallback to embedded templates
            return getEmbeddedTemplate(templateName, with: data)
        }
        
        // Replace placeholders with actual data
        var populatedTemplate = template
        for (key, value) in data {
            let placeholder = "{{\(key)}}"
            let replacement = stringValue(from: value)
            populatedTemplate = populatedTemplate.replacingOccurrences(of: placeholder, with: replacement)
        }
        
        return populatedTemplate
    }
    
    /// Get embedded template as fallback
    private func getEmbeddedTemplate(_ templateName: String, with data: [String: AnyCodableValue]) -> String {
        switch templateName {
        case "categorize_blob":
            let content = stringValue(from: data["content"] ?? .string(""))
            let sourceType = stringValue(from: data["source_type"] ?? .string("note"))
            
            return """
            Analyze this content and categorize it according to PARA methodology:
            
            Content: "\(content)"
            Source Type: \(sourceType)
            
            Determine if this is a Project, Area, Resource, or should be Archived.
            Also suggest appropriate tags, priority, and work/personal classification.
            
            Respond with JSON:
            {
              "category": "project|area|resource|archive",
              "suggested_area": "area_name_if_applicable",
              "suggested_project": "project_name_if_applicable",
              "actionable_tasks": ["task1", "task2"],
              "tags": ["tag1", "tag2"],
              "priority": "urgent|high|medium|low",
              "work_personal": "work|personal|both",
              "confidence_score": 0.85,
              "reasoning": "explanation"
            }
            """
            
        case "extract_tasks":
            let content = stringValue(from: data["content"] ?? .string(""))
            
            return """
            Extract actionable tasks from this content:
            
            Content: "\(content)"
            
            Return as JSON array:
            [
              {
                "title": "Clear, actionable task title",
                "description": "Additional context if needed",
                "priority": "urgent|high|medium|low",
                "estimated_duration": minutes_as_integer,
                "due_date": "YYYY-MM-DD or null",
                "area": "matching_area_name_or_null",
                "project": "matching_project_name_or_null",
                "tags": ["context", "energy_level"],
                "is_focus": false
              }
            ]
            """
            
        default:
            return "Process this content: \(stringValue(from: data["content"] ?? .string("")))"
        }
    }
    
    /// Call LLM API based on configured provider
    private func callLLM(prompt: String) async throws -> String {
        switch preferredProvider {
        case .openAI:
            return try await callOpenAI(prompt: prompt)
        case .claude:
            return try await callClaude(prompt: prompt)
        }
    }
    
    /// Call OpenAI API
    private func callOpenAI(prompt: String) async throws -> String {
        guard !APIConfig.openAIKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        
        let url = URL(string: "\(APIConfig.openAIBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = response?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return content
    }
    
    /// Call Claude API
    private func callClaude(prompt: String) async throws -> String {
        guard !APIConfig.claudeKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        
        let url = URL(string: "\(APIConfig.claudeBaseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.claudeKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body = [
            "model": "claude-3-sonnet-20240229",
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let content = response?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return text
    }
    
    /// Parse PARA categorization response
    private func parseCategorizationResponse(_ response: String) throws -> PARAProcessingResult {
        // Try to extract JSON from response
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse
        }
        
        return PARAProcessingResult(
            category: json["category"] as? String ?? "resource",
            suggestedArea: json["suggested_area"] as? String,
            suggestedProject: json["suggested_project"] as? String,
            actionableTasks: json["actionable_tasks"] as? [String] ?? [],
            tags: json["tags"] as? [String] ?? [],
            priority: TaskPriority(rawValue: json["priority"] as? String ?? "medium") ?? .medium,
            workPersonal: WorkPersonalType(rawValue: json["work_personal"] as? String ?? "personal") ?? .personal,
            confidenceScore: json["confidence_score"] as? Double ?? 0.5,
            reasoning: json["reasoning"] as? String ?? ""
        )
    }
    
    /// Parse task extraction response
    private func parseTaskExtractionResponse(_ response: String) throws -> TaskExtractionResult {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw LLMError.invalidResponse
        }
        
        let extractedTasks = jsonArray.compactMap { taskJson -> ExtractedTask? in
            guard let title = taskJson["title"] as? String else { return nil }
            
            return ExtractedTask(
                title: title,
                description: taskJson["description"] as? String,
                priority: TaskPriority(rawValue: taskJson["priority"] as? String ?? "medium") ?? .medium,
                estimatedDuration: taskJson["estimated_duration"] as? Int,
                dueDate: taskJson["due_date"] as? String,
                suggestedArea: taskJson["area"] as? String,
                suggestedProject: taskJson["project"] as? String,
                tags: taskJson["tags"] as? [String] ?? [],
                isFocus: taskJson["is_focus"] as? Bool ?? false
            )
        }
        
        return TaskExtractionResult(
            tasks: extractedTasks,
            confidenceScore: 0.8 // Default confidence
        )
    }
    
    /// Parse task priority response
    private func parseTaskPriorityResponse(_ response: String) throws -> TaskPriorityResult {
        // Simple parsing for priority suggestions
        let lowerResponse = response.lowercased()
        
        let priority: TaskPriority
        if lowerResponse.contains("urgent") {
            priority = .urgent
        } else if lowerResponse.contains("high") {
            priority = .high
        } else if lowerResponse.contains("low") {
            priority = .low
        } else {
            priority = .medium
        }
        
        return TaskPriorityResult(
            priority: priority,
            suggestedDueDate: nil, // Could be enhanced to parse dates
            confidenceScore: 0.7,
            reasoning: response
        )
    }
    
    /// Extract JSON from LLM response
    private func extractJSON(from response: String) -> String {
        // Look for JSON between ```json and ``` or { and }
        if let jsonStart = response.range(of: "```json"),
           let jsonEnd = response.range(of: "```", range: jsonStart.upperBound..<response.endIndex) {
            return String(response[jsonStart.upperBound..<jsonEnd.lowerBound])
        }
        
        if let jsonStart = response.range(of: "{"),
           let jsonEnd = response.range(of: "}", options: .backwards) {
            return String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        }
        
        return response
    }
    
    /// Convert AnyCodableValue to String
    private func stringValue(from value: AnyCodableValue) -> String {
        switch value {
        case .string(let str):
            return str
        case .int(let int):
            return String(int)
        case .double(let double):
            return String(double)
        case .bool(let bool):
            return String(bool)
        case .array(let array):
            return array.map { stringValue(from: $0) }.joined(separator: ", ")
        case .object(let dict):
            return dict.map { "\($0.key): \(stringValue(from: $0.value))" }.joined(separator: ", ")
        case .null:
            return ""
        }
    }
    
    /// Log prompt execution for optimization
    private func logPromptExecution(
        template: String,
        version: String,
        inputData: [String: AnyCodableValue],
        promptText: String,
        responseText: String,
        processingTime: Int,
        confidenceScore: Double?
    ) async {
        do {
            let promptLog = PromptLog(
                promptTemplate: template,
                promptVersion: version,
                inputData: inputData,
                promptText: promptText,
                responseText: responseText,
                modelName: preferredProvider == .openAI ? "gpt-3.5-turbo" : "claude-3-sonnet",
                tokensUsed: nil, // Could be parsed from API response
                processingTimeMs: processingTime,
                confidenceScore: confidenceScore
            )
            
            _ = try await supabaseService.insert(promptLog, into: SupabaseService.TableName.promptLogs)
        } catch {
            print("Failed to log prompt execution: \(error)")
        }
    }
}

// MARK: - Result Types

struct PARAProcessingResult {
    let category: String
    let suggestedArea: String?
    let suggestedProject: String?
    let actionableTasks: [String]
    let tags: [String]
    let priority: TaskPriority
    let workPersonal: WorkPersonalType
    let confidenceScore: Double
    let reasoning: String
}

struct TaskExtractionResult {
    let tasks: [ExtractedTask]
    let confidenceScore: Double
}

struct ExtractedTask {
    let title: String
    let description: String?
    let priority: TaskPriority
    let estimatedDuration: Int?
    let dueDate: String?
    let suggestedArea: String?
    let suggestedProject: String?
    let tags: [String]
    let isFocus: Bool
}

struct TaskPriorityResult {
    let priority: TaskPriority
    let suggestedDueDate: String?
    let confidenceScore: Double
    let reasoning: String
}

// MARK: - Errors

enum LLMError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case networkError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing API key for LLM service"
        case .invalidResponse:
            return "Invalid response from LLM service"
        case .networkError:
            return "Network error when calling LLM service"
        case .parsingError:
            return "Error parsing LLM response"
        }
    }
} 