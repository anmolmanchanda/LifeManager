import Foundation

/// LLM service for natural language processing and PARA categorization
/// Handles OpenAI/Claude API calls for content analysis and task extraction
class LLMService: ObservableObject {
    
    static let shared = LLMService()
    
    // MARK: - Configuration
    
    private struct APIConfig {
        static var openAIKey: String {
            // Try multiple sources for API key
            if let configKey = loadFromConfigFile() {
                return configKey
            }
            
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
                return envKey
            }
            
            // Fallback to hardcoded key for development (remove in production)
            return "your-openai-api-key-here"
        }
        
        static let claudeKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let claudeBaseURL = "https://api.anthropic.com/v1"
        
        private static func loadFromConfigFile() -> String? {
            // Try to load from config file in app directory
            let configPaths = [
                "config.txt",
                "api_key.txt",
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".lifemanager_config").path
            ]
            
            for path in configPaths {
                if let content = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
                   !content.isEmpty {
                    return content
                }
            }
            
            return nil
        }
    }
    
    private enum LLMProvider {
        case openAI
        case claude
    }
    
    private let supabaseService = SupabaseService.shared
    private let preferredProvider: LLMProvider = .openAI // Can be configured
    
    public init() {
        print("🔧 LLM SERVICE: Initializing LLM Service...")
        print("🔧 LLM SERVICE: OpenAI API Key present: \(!APIConfig.openAIKey.isEmpty)")
        print("🔧 LLM SERVICE: OpenAI API Key length: \(APIConfig.openAIKey.count)")
        print("🔧 LLM SERVICE: Preferred provider: \(preferredProvider)")
        
        if APIConfig.openAIKey.isEmpty {
            print("🔧 LLM SERVICE: ❌ WARNING - No OpenAI API key found in environment")
        } else {
            print("🔧 LLM SERVICE: ✅ OpenAI API key configured")
            print("🔧 LLM SERVICE: API key prefix: \(APIConfig.openAIKey.prefix(20))...")
        }
    }
    
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
    
    /// Comprehensive PARA processing with full workflow
    func processComprehensively(
        blob: Blob,
        availableAreas: [Area] = [],
        availableProjects: [Project] = [],
        confidenceThreshold: Double = 0.7
    ) async throws -> ProcessingResult {
        
        print("🔧 LLM COMPREHENSIVE: Starting comprehensive processing for blob: \(blob.id)")
        
        let availableAreaNames = availableAreas.map { $0.name }
        let availableProjectNames = availableProjects.map { $0.name }
        
        let promptTemplate = "comprehensive_para_processing"
        let promptVersion = "v2.0"
        
        let inputData: [String: AnyCodableValue] = [
            "content": .string(blob.content),
            "source_type": .string(blob.sourceType.rawValue),
            "work_personal": .string(blob.workPersonal.rawValue),
            "available_areas": .array(availableAreaNames.map { .string($0) }),
            "available_projects": .array(availableProjectNames.map { .string($0) }),
            "confidence_threshold": .double(confidenceThreshold)
        ]
        
        let promptText = createComprehensivePrompt(for: blob, availableAreas: availableAreaNames, availableProjects: availableProjectNames, confidenceThreshold: confidenceThreshold)
        
        let startTime = Date()
        let response = try await callLLM(prompt: promptText)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        print("🔧 LLM COMPREHENSIVE: ✅ Received response, parsing...")
        let result = try parseComprehensiveResponse(response, for: blob)
        
        // Log the processing
        await logPromptExecution(
            template: promptTemplate,
            version: promptVersion,
            inputData: inputData,
            promptText: promptText,
            responseText: response,
            processingTime: processingTime,
            confidenceScore: result.confidence
        )
        
        print("🔧 LLM COMPREHENSIVE: ✅ Processing complete with confidence: \(result.confidence)")
        return result
    }
    
    // MARK: - Convenience Methods
    
    /// Quick PARA categorization for a blob content
    func categorizePARA(content: String) async throws -> PARAProcessingResult {
        return try await processNaturalLanguage(input: content)
    }
    
    /// Quick task extraction from content
    func extractTasks(content: String) async throws -> [[String: Any]] {
        let result = try await extractTasks(from: content)
        
        // Convert ExtractedTask objects to dictionary format for backward compatibility
        return result.tasks.map { task in
            return [
                "title": task.title,
                "description": task.description ?? "",
                "priority": task.priority.rawValue
            ]
        }
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
        print("🔧 LLM: Checking API key...")
        guard !APIConfig.openAIKey.isEmpty else {
            print("🔧 LLM: ❌ Missing OpenAI API key")
            throw LLMError.missingAPIKey
        }
        print("🔧 LLM: ✅ API key found (length: \(APIConfig.openAIKey.count))")
        
        let url = URL(string: "\(APIConfig.openAIBaseURL)/chat/completions")!
        print("🔧 LLM: Making request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 2000,
            "temperature": 0.3
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("🔧 LLM: ✅ Request body created, size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("🔧 LLM: ❌ Failed to serialize request body: \(error)")
            throw LLMError.parsingError
        }
        
        print("🔧 LLM: Sending API request...")
        do {
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = httpResponse as? HTTPURLResponse {
                print("🔧 LLM: Received HTTP response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let errorBody = String(data: data, encoding: .utf8) {
                        print("🔧 LLM: ❌ API Error (\(httpResponse.statusCode)): \(errorBody)")
                    }
                    throw LLMError.networkError
                }
            }
            
            print("🔧 LLM: ✅ Response received, size: \(data.count) bytes")
            
            guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("🔧 LLM: ❌ Failed to parse response as JSON")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔧 LLM: Raw response: \(responseString)")
                }
                throw LLMError.invalidResponse
            }
            
            print("🔧 LLM: ✅ Response parsed as JSON")
            
            guard let choices = response["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("🔧 LLM: ❌ Invalid response structure")
                print("🔧 LLM: Response keys: \(response.keys)")
                throw LLMError.invalidResponse
            }
            
            print("🔧 LLM: ✅ Content extracted, length: \(content.count) characters")
            return content
            
        } catch {
            print("🔧 LLM: ❌ Network error: \(error)")
            throw LLMError.networkError
        }
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
        
        let body: [String: Any] = [
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
                modelName: preferredProvider == .openAI ? "gpt-4o-mini" : "claude-3-sonnet",
                tokensUsed: nil, // Could be parsed from API response
                processingTimeMs: processingTime,
                confidenceScore: confidenceScore
            )
            
            _ = try await supabaseService.insert(promptLog, into: SupabaseService.TableName.promptLogs.rawValue)
        } catch {
            print("Failed to log prompt execution: \(error)")
        }
    }
    
    /// Create comprehensive processing prompt
    private func createComprehensivePrompt(for blob: Blob, availableAreas: [String], availableProjects: [String], confidenceThreshold: Double) -> String {
        return """
        You are an AI assistant specialized in the PARA methodology (Projects, Areas, Resources, Archives) for personal knowledge management.
        
        Analyze this content comprehensively and provide a structured response:
        
        **Content to Process:**
        Content: "\(blob.content)"
        Source Type: \(blob.sourceType.rawValue)
        Work/Personal: \(blob.workPersonal.rawValue)
        
        **Available Context:**
        Existing Areas: \(availableAreas.isEmpty ? "None" : availableAreas.joined(separator: ", "))
        Existing Projects: \(availableProjects.isEmpty ? "None" : availableProjects.joined(separator: ", "))
        
        **Instructions:**
        1. PARA Categorization: Determine if this is a Project, Area, Resource, or Archive
        2. Task Extraction: Find any actionable items with priorities and time estimates
        3. Auto-Tagging: Generate relevant tags for searchability
        4. Summarization: Create a 1-2 sentence summary if content is lengthy (>100 words)
        5. Cross-Links: Identify connections to existing or suggested new PARA items
        6. Confidence Assessment: Rate your confidence (0.0-1.0) for each decision
        
        **Response Format (JSON):**
        {
          "para_category": "project|area|resource|archive",
          "confidence": 0.85,
          "reasoning": "Brief explanation for categorization",
          "suggested_area": "area_name_or_null",
          "suggested_project": "project_name_or_null",
          "requires_confirmation": false,
          
          "extracted_tasks": [
            {
              "title": "Clear actionable task",
              "description": "Additional context",
              "priority": "urgent|high|medium|low",
              "estimated_duration": 30,
              "suggested_due_date": "2024-01-15",
              "suggested_area": "area_name",
              "suggested_project": "project_name",
              "tags": ["context", "energy"],
              "confidence": 0.9
            }
          ],
          
          "auto_tags": ["keyword1", "keyword2", "context"],
          
          "summary": "Brief 1-2 sentence summary (if content >100 words)",
          
          "cross_links": [
            {
              "type": "project|area|resource|person|location",
              "target_name": "Existing item name",
              "is_new_suggestion": false,
              "confidence": 0.8,
              "pre_filled_details": {
                "description": "Suggested description for new item"
              }
            }
          ],
          
          "actions_taken": [
            {
              "type": "categorized|task_extracted|tagged|summarized|cross_linked",
              "description": "What was done",
              "success": true
            }
          ]
        }
        
        **Guidelines:**
        - Projects: Have specific outcomes and deadlines
        - Areas: Ongoing responsibilities to maintain standards
        - Resources: Reference materials for future use
        - Archives: Inactive items from other categories
        - Set requires_confirmation=true if confidence < \(confidenceThreshold)
        - Extract only genuinely actionable tasks
        - Tags should be helpful for search and context
        - Cross-links should be meaningful connections
        """
    }
    
    /// Parse comprehensive processing response
    private func parseComprehensiveResponse(_ response: String, for blob: Blob) throws -> ProcessingResult {
        print("🔧 LLM PARSE: Starting to parse comprehensive response")
        print("🔧 LLM PARSE: Raw response length: \(response.count) characters")
        print("🔧 LLM PARSE: Raw response preview: \(response.prefix(200))...")
        
        let jsonString = extractJSON(from: response)
        print("🔧 LLM PARSE: Extracted JSON length: \(jsonString.count) characters")
        print("🔧 LLM PARSE: Extracted JSON: \(jsonString)")
        
        guard let data = jsonString.data(using: .utf8) else {
            print("🔧 LLM PARSE: ❌ Failed to convert JSON string to data")
            throw LLMError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("🔧 LLM PARSE: ❌ Failed to parse JSON data")
            throw LLMError.invalidResponse
        }
        
        print("🔧 LLM PARSE: ✅ JSON parsed successfully")
        print("🔧 LLM PARSE: JSON keys: \(json.keys)")
        
        // Parse PARA category
        let categoryString = json["para_category"] as? String ?? "resource"
        let paraCategory = PARACategory(rawValue: categoryString) ?? .resource
        print("🔧 LLM PARSE: PARA category: \(categoryString) -> \(paraCategory)")
        
        let confidence = json["confidence"] as? Double ?? 0.5
        let requiresConfirmation = json["requires_confirmation"] as? Bool ?? (confidence < 0.7)
        print("🔧 LLM PARSE: Confidence: \(confidence), Requires confirmation: \(requiresConfirmation)")
        
        // Parse extracted tasks
        let tasksJson = json["extracted_tasks"] as? [[String: Any]] ?? []
        print("🔧 LLM PARSE: Found \(tasksJson.count) tasks in JSON")
        
        let extractedTasks = tasksJson.compactMap { taskJson -> TaskExtractionInfo? in
            guard let title = taskJson["title"] as? String else { 
                print("🔧 LLM PARSE: ⚠️ Skipping task without title")
                return nil 
            }
            
            print("🔧 LLM PARSE: Parsing task: \(title)")
            return TaskExtractionInfo(
                title: title,
                description: taskJson["description"] as? String,
                priority: TaskPriority(rawValue: taskJson["priority"] as? String ?? "medium") ?? .medium,
                estimatedDuration: taskJson["estimated_duration"] as? Int,
                suggestedDueDate: taskJson["suggested_due_date"] as? String,
                suggestedArea: taskJson["suggested_area"] as? String,
                suggestedProject: taskJson["suggested_project"] as? String,
                tags: taskJson["tags"] as? [String] ?? [],
                confidence: taskJson["confidence"] as? Double ?? 0.8
            )
        }
        print("🔧 LLM PARSE: Successfully parsed \(extractedTasks.count) tasks")
        
        // Parse auto tags
        let autoTags = json["auto_tags"] as? [String] ?? []
        print("🔧 LLM PARSE: Found \(autoTags.count) auto tags: \(autoTags)")
        
        // Parse cross-links
        let crossLinksJson = json["cross_links"] as? [[String: Any]] ?? []
        print("🔧 LLM PARSE: Found \(crossLinksJson.count) cross-links in JSON")
        
        let crossLinks = crossLinksJson.compactMap { linkJson -> CrossLinkSuggestion? in
            guard let typeString = linkJson["type"] as? String,
                  let type = CrossLinkType(rawValue: typeString),
                  let targetName = linkJson["target_name"] as? String else { 
                print("🔧 LLM PARSE: ⚠️ Skipping invalid cross-link")
                return nil 
            }
            
            return CrossLinkSuggestion(
                type: type,
                targetName: targetName,
                targetId: nil, // Would be populated by matching existing items
                isNewSuggestion: linkJson["is_new_suggestion"] as? Bool ?? false,
                confidence: linkJson["confidence"] as? Double ?? 0.8,
                preFilledDetails: linkJson["pre_filled_details"] as? [String: String] ?? [:]
            )
        }
        
        // Parse actions
        let actionsJson = json["actions_taken"] as? [[String: Any]] ?? []
        print("🔧 LLM PARSE: Found \(actionsJson.count) actions in JSON")
        
        let actions = actionsJson.compactMap { actionJson -> ProcessingAction? in
            guard let typeString = actionJson["type"] as? String,
                  let type = ProcessingActionType(rawValue: typeString),
                  let description = actionJson["description"] as? String else { 
                print("🔧 LLM PARSE: ⚠️ Skipping invalid action")
                return nil 
            }
            
            return ProcessingAction(
                type: type,
                description: description,
                success: actionJson["success"] as? Bool ?? true
            )
        }
        
        let result = ProcessingResult(
            blobId: blob.id,
            paraCategory: paraCategory,
            confidence: confidence,
            suggestedArea: json["suggested_area"] as? String,
            suggestedProject: json["suggested_project"] as? String,
            extractedTasks: extractedTasks,
            autoTags: autoTags,
            summary: json["summary"] as? String,
            crossLinks: crossLinks,
            requiresConfirmation: requiresConfirmation,
            actions: actions
        )
        
        print("🔧 LLM PARSE: ✅ Successfully created ProcessingResult")
        print("🔧 LLM PARSE: Final result - Category: \(result.paraCategory), Tasks: \(result.extractedTasks.count), Tags: \(result.autoTags.count)")
        
        return result
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