import Foundation

//
// LLMService.swift
// LifeManager
//
// Implements: v1.0 "AI Categorization", v1.25 "Enhanced AI Processing", v1.5 "Enhanced Task Extraction"
// Roadmap Reference: v1.0 Foundation, v1.25 Intelligence & UI, v1.5 Advanced Features
// Status: ✅ COMPLETE as of June 14, 2025
// Future: v2.0 Multi-LLM Support, Advanced NLU, Smart Summarization
//

/// LLM service for natural language processing and PARA categorization
/// Handles OpenAI/Claude API calls for content analysis and task extraction
/// Core component of LifeManager's AI-powered productivity system
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
            
            // Fallback placeholder - set OPENAI_API_KEY environment variable
            return "your-openai-api-key-here"
        }
        
        static let claudeKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let claudeBaseURL = "https://api.anthropic.com/v1"
        
        private static func loadFromConfigFile() -> String? {
            // Try to load from config file in various locations
            let configPaths = [
                // Current working directory
                "config.txt",
                "api_key.txt",
                // App bundle directory
                Bundle.main.bundlePath + "/config.txt",
                Bundle.main.bundlePath + "/api_key.txt",
                // User home directory
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".lifemanager_config").path,
                // Documents directory
                FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("config.txt").path ?? "",
                // Application Support directory
                FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("LifeManager/config.txt").path ?? ""
            ]
            
            print("🔧 LLM CONFIG: Searching for config file in paths:")
            for path in configPaths {
                print("🔧 LLM CONFIG: Checking: \(path)")
                if let content = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
                   !content.isEmpty {
                    print("🔧 LLM CONFIG: ✅ Found config file at: \(path)")
                    print("🔧 LLM CONFIG: Raw content length: \(content.count)")
                    
                    // Extract API key from config file format
                    if content.contains("OPENAI_API_KEY=") {
                        let lines = content.components(separatedBy: .newlines)
                        for line in lines {
                            if line.hasPrefix("OPENAI_API_KEY=") {
                                let apiKey = String(line.dropFirst("OPENAI_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                                if !apiKey.isEmpty && !apiKey.contains("YOUR_API_KEY_HERE") {
                                    print("🔧 LLM CONFIG: ✅ Extracted API key, length: \(apiKey.count)")
                                    return apiKey
                                }
                            }
                        }
                        print("🔧 LLM CONFIG: ❌ Found OPENAI_API_KEY= but no valid key")
                    } else {
                        // Assume entire file content is the API key (for simple format)
                        if !content.contains("YOUR_API_KEY_HERE") && content.hasPrefix("sk-") {
                            print("🔧 LLM CONFIG: ✅ Using entire file as API key")
                            return content
                        }
                    }
                }
            }
            
            print("🔧 LLM CONFIG: ❌ No valid API key found in any config file")
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
            print("🔧 LLM SERVICE: ❌ WARNING - No OpenAI API key found")
        } else if APIConfig.openAIKey.contains("your-openai-api-key-here") {
            print("🔧 LLM SERVICE: ❌ WARNING - Using placeholder API key")
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
    
    /// Enhance existing tasks with comprehensive LLM processing
    /// Ensures all tasks have proper dates, times, durations, and priority scores
    func enhanceExistingTasks(_ tasks: [LifeTask]) async throws -> [TaskEnhancementResult] {
        print("🔧 LLM ENHANCE: Starting enhancement of \(tasks.count) existing tasks")
        
        var enhancementResults: [TaskEnhancementResult] = []
        
        for task in tasks {
            do {
                print("🔧 LLM ENHANCE: Processing task: \(task.title)")
                
                // Check if task needs enhancement
                let needsEnhancement = task.dueDate == nil || 
                                     task.estimatedDuration == nil || 
                                     task.priority == .medium // Default priority suggests it wasn't properly analyzed
                
                if needsEnhancement {
                    let enhancementResult = try await enhanceIndividualTask(task)
                    enhancementResults.append(enhancementResult)
                    print("🔧 LLM ENHANCE: ✅ Enhanced task: \(task.title)")
                } else {
                    // Task already has good data, create a no-change result
                    let result = TaskEnhancementResult(
                        originalTask: task,
                        enhancedTask: task,
                        priorityScore: task.priority.priorityScore,
                        priorityReasoning: "Task already has comprehensive data",
                        wasEnhanced: false,
                        confidence: 1.0
                    )
                    enhancementResults.append(result)
                    print("🔧 LLM ENHANCE: ⏭️ Skipped task (already enhanced): \(task.title)")
                }
            } catch {
                print("🔧 LLM ENHANCE: ❌ Failed to enhance task: \(task.title) - \(error)")
                // Create error result
                let errorResult = TaskEnhancementResult(
                    originalTask: task,
                    enhancedTask: task,
                    priorityScore: task.priority.priorityScore,
                    priorityReasoning: "Enhancement failed: \(error.localizedDescription)",
                    wasEnhanced: false,
                    confidence: 0.0
                )
                enhancementResults.append(errorResult)
            }
        }
        
        print("🔧 LLM ENHANCE: ✅ Completed enhancement of \(tasks.count) tasks")
        return enhancementResults
    }
    
    /// Enhance a single task with LLM processing
    private func enhanceIndividualTask(_ task: LifeTask) async throws -> TaskEnhancementResult {
        let promptTemplate = "enhance_task"
        let promptVersion = "v1.0"
        
        // Create enhancement prompt
        let promptText = createTaskEnhancementPrompt(for: task)
        
        let startTime = Date()
        let response = try await callLLM(prompt: promptText)
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        // Parse enhancement response
        let enhancement = try parseTaskEnhancementResponse(response, for: task)
        
        // Log the enhancement
        await logPromptExecution(
            template: promptTemplate,
            version: promptVersion,
            inputData: [
                "task_title": .string(task.title),
                "task_description": .string(task.description ?? ""),
                "current_priority": .string(task.priority.rawValue)
            ],
            promptText: promptText,
            responseText: response,
            processingTime: processingTime,
            confidenceScore: enhancement.confidence
        )
        
        return enhancement
    }
    
    /// Create task enhancement prompt
    private func createTaskEnhancementPrompt(for task: LifeTask) -> String {
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        return """
        You are an AI assistant specialized in task management and productivity optimization.
        
        Analyze this existing task and provide comprehensive enhancement with MANDATORY fields:
        
        **Existing Task:**
        Title: "\(task.title)"
        Description: "\(task.description ?? "No description")"
        Current Priority: \(task.priority.rawValue)
        Current Due Date: \(task.dueDate ?? "None")
        Current Duration: \(task.estimatedDuration?.description ?? "None") minutes
        Work/Personal: \(task.workPersonal.rawValue)
        Current Date/Time: \(currentDate)
        
        **CRITICAL ENHANCEMENT REQUIREMENTS:**
        You MUST provide ALL of the following for this task:
        
        1. **Priority Score (1-5 Scale):**
           - Score 5 (Urgent): Life-critical, legal deadlines, emergencies, blocking others
           - Score 4 (High): Important deadlines, key milestones, health/safety issues  
           - Score 3 (Medium): Regular work tasks, planned activities, moderate importance
           - Score 2 (Low): Nice-to-have, learning, non-urgent improvements
           - Score 1 (Lowest): Someday/maybe items, distant future planning
        
        2. **Smart Due Date Assignment:**
           - Analyze task title and description for time indicators
           - If no specific time mentioned, assign intelligent defaults:
             * Urgent (Score 5): Within 4 hours or next business day
             * High (Score 4): Within 1-2 days
             * Medium (Score 3): Within 1 week
             * Low (Score 2): Within 2 weeks
             * Lowest (Score 1): Within 1 month
           - Consider work/personal classification for scheduling
           - Use business hours for work tasks, flexible hours for personal
        
        3. **Duration Estimation:**
           - Quick tasks (calls, emails, decisions): 15-30 minutes
           - Planning/research: 60-120 minutes
           - Implementation/execution: 90-180 minutes
           - Deep work/creative: 120-240 minutes
           - Meetings/appointments: 30-60 minutes
           - Learning/skill development: 45-90 minutes
        
        4. **Priority Analysis:**
           - Identify urgency indicators (deadlines, time pressure, dependencies)
           - Assess importance factors (impact on goals, health, relationships)
           - Consider consequences of delay
           - Evaluate effort vs. impact ratio
        
        **Response Format (JSON):**
        {
          "enhanced_priority": "urgent|high|medium|low",
          "priority_score": 4,
          "priority_reasoning": "Detailed explanation of priority assessment",
          "suggested_due_date": "2024-01-15T14:00:00Z",
          "due_date_reasoning": "Why this date/time makes sense",
          "estimated_duration": 60,
          "duration_reasoning": "Why this duration is appropriate",
          "urgency_indicators": ["deadline", "dependency", "health"],
          "importance_factors": ["goal_impact", "relationship", "learning"],
          "time_block": "work_hours|evening|weekend|flexible",
          "enhancement_needed": true,
          "confidence": 0.9,
          "enhancement_summary": "Brief summary of what was enhanced and why"
        }
        
        **Guidelines:**
        - Be realistic about time estimates and deadlines
        - Consider the person's likely schedule and energy levels
        - Account for task complexity and potential obstacles
        - Prioritize based on actual impact and urgency, not just perception
        - Ensure due dates are achievable and motivating
        - Factor in preparation time and potential interruptions
        
        IMPORTANT: Every field must be populated with thoughtful, realistic values.
        """
    }
    
    /// Parse task enhancement response
    private func parseTaskEnhancementResponse(_ response: String, for task: LifeTask) throws -> TaskEnhancementResult {
        print("🔧 LLM ENHANCE PARSE: Parsing enhancement response for task: \(task.title)")
        
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse
        }
        
        // Parse enhanced priority
        let priorityScore = json["priority_score"] as? Int ?? task.priority.priorityScore
        let priorityString = json["enhanced_priority"] as? String ?? task.priority.rawValue
        let enhancedPriority = TaskPriority(rawValue: priorityString) ?? TaskPriority(fromScore: priorityScore)
        let priorityReasoning = json["priority_reasoning"] as? String ?? "Enhanced priority analysis"
        
        // Parse enhanced due date
        var enhancedDueDate = task.dueDate
        if let dueDateString = json["suggested_due_date"] as? String {
            let isoFormatter = ISO8601DateFormatter()
            if isoFormatter.date(from: dueDateString) != nil {
                enhancedDueDate = dueDateString
            } else {
                // Create smart default if parsing fails
                let defaultDate = createSmartDefaultDate(for: enhancedPriority)
                enhancedDueDate = isoFormatter.string(from: defaultDate)
            }
        } else if task.dueDate == nil {
            // No due date exists, create one
            let defaultDate = createSmartDefaultDate(for: enhancedPriority)
            enhancedDueDate = ISO8601DateFormatter().string(from: defaultDate)
        }
        
        // Parse enhanced duration
        let enhancedDuration = json["estimated_duration"] as? Int ?? task.estimatedDuration ?? {
            // Fallback duration based on priority
            switch enhancedPriority {
            case .urgent: return 30
            case .high: return 60
            case .medium: return 45
            case .low: return 30
            }
        }()
        
        // Create enhanced task
        let enhancedTask = LifeTask(
            id: task.id,
            blobId: task.blobId,
            title: task.title,
            description: task.description,
            priority: enhancedPriority,
            status: task.status,
            dueDate: enhancedDueDate,
            estimatedDuration: enhancedDuration,
            workPersonal: task.workPersonal,
            projectId: task.projectId,
            areaId: task.areaId,
            resourceId: task.resourceId,
            isFocus: task.isFocus,
            isArchived: task.isArchived,
            createdAt: task.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date()), // Update timestamp
            completedAt: task.completedAt,
            archivedAt: task.archivedAt
        )
        
        let wasEnhanced = enhancedTask.priority != task.priority || 
                         enhancedTask.dueDate != task.dueDate || 
                         enhancedTask.estimatedDuration != task.estimatedDuration
        
        let confidence = json["confidence"] as? Double ?? 0.8
        
        print("🔧 LLM ENHANCE PARSE: ✅ Enhanced task: \(task.title) (Priority: \(enhancedPriority.rawValue)/\(priorityScore), Due: \(enhancedDueDate ?? "none"), Duration: \(enhancedDuration)min)")
        
        return TaskEnhancementResult(
            originalTask: task,
            enhancedTask: enhancedTask,
            priorityScore: priorityScore,
            priorityReasoning: priorityReasoning,
            wasEnhanced: wasEnhanced,
            confidence: confidence
        )
    }
    
    // MARK: - Convenience Methods
    
    /// Quick PARA categorization for a blob content
    func categorizePARA(input: String, context: PARAContext) async throws -> PARAProcessingResult {
        print("🔧 LLM: Starting PARA categorization with enhanced prompt")
        
        // Build the comprehensive prompt
        let prompt = buildComprehensivePrompt(input: input, context: context)
        
        // Make the API call
        let response = try await makeAPICall(prompt: prompt)
        print("🔧 LLM: Received response from OpenAI API")
        
        // Parse the JSON response
        let extractedItems = try parseJSONResponse(response)
        print("🔧 LLM: Successfully parsed \(extractedItems.count) items from response")
        
        // Convert to PARAProcessingResult
        let result = PARAProcessingResult(
            category: "mixed",
            suggestedArea: nil,
            suggestedProject: nil,
            actionableTasks: [],
            tags: [],
            priority: .medium,
            workPersonal: .personal,
            confidenceScore: calculateAverageConfidence(from: extractedItems),
            reasoning: "Processed \(extractedItems.count) items with enhanced PARA categorization",
            extractedItems: extractedItems
        )
        
        print("🔧 LLM: PARA categorization completed successfully")
        return result
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
    func callLLM(prompt: String) async throws -> String {
        switch preferredProvider {
        case .openAI:
            return try await callOpenAI(prompt: prompt)
        case .claude:
            return try await callClaude(prompt: prompt)
        }
    }
    
    /// Call OpenAI API with retry logic
    private func callOpenAI(prompt: String) async throws -> String {
        print("🔧 LLM: Checking API key...")
        guard !APIConfig.openAIKey.isEmpty else {
            print("🔧 LLM: ❌ Missing OpenAI API key")
            throw LLMError.missingAPIKey
        }
        print("🔧 LLM: ✅ API key found (length: \(APIConfig.openAIKey.count))")
        
        let url = URL(string: "\(APIConfig.openAIBaseURL)/chat/completions")!
        print("🔧 LLM: Making request to: \(url)")
        
        // Retry logic for network reliability
        var lastError: Error?
        for attempt in 1...3 {
            do {
                print("🔧 LLM: Attempt \(attempt)/3")
                return try await performOpenAIRequest(url: url, prompt: prompt)
            } catch {
                lastError = error
                print("🔧 LLM: ❌ Attempt \(attempt) failed: \(error)")
                if attempt < 3 {
                    print("🔧 LLM: Waiting 2 seconds before retry...")
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
            }
        }
        
        throw lastError ?? LLMError.networkError
    }
    
    /// Perform the actual OpenAI API request
    private func performOpenAIRequest(url: URL, prompt: String) async throws -> String {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0 // Increase timeout to 120 seconds for complex brain dump processing
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a precise JSON generator. CRITICAL: Respond ONLY with a valid JSON array. No markdown, no explanations, no extra text. Start with [ and end with ]. Use double quotes for all strings. No trailing commas."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 4000,
            "temperature": 0.0
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
        request.timeoutInterval = 120.0 // Increase timeout to 120 seconds for complex brain dump processing
        
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
            reasoning: json["reasoning"] as? String ?? "",
            extractedItems: nil
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
        print("🔧 LLM EXTRACT: Extracting JSON from response")
        
        // Look for JSON between ```json and ```
        if let jsonStart = response.range(of: "```json") {
            let searchRange = jsonStart.upperBound..<response.endIndex
            if let jsonEnd = response.range(of: "```", range: searchRange) {
                let extracted = String(response[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("🔧 LLM EXTRACT: ✅ Found JSON in code block")
                return extracted
            }
        }
        
        // Look for JSON between { and } - find matching braces
        if let jsonStart = response.range(of: "{") {
            // Find the matching closing brace by counting braces
            var braceCount = 0
            var currentIndex = jsonStart.lowerBound
            
            while currentIndex < response.endIndex {
                let char = response[currentIndex]
                if char == "{" {
                    braceCount += 1
                } else if char == "}" {
                    braceCount -= 1
                    if braceCount == 0 {
                        // Found matching closing brace
                        let jsonEnd = response.index(after: currentIndex)
                        let extracted = String(response[jsonStart.lowerBound..<jsonEnd])
                        print("🔧 LLM EXTRACT: ✅ Found JSON with brace matching")
                        return extracted
                    }
                }
                currentIndex = response.index(after: currentIndex)
            }
        }
        
        print("🔧 LLM EXTRACT: ⚠️ No JSON structure found, returning original response")
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
                modelName: preferredProvider == .openAI ? "gpt-4.1" : "claude-3-sonnet",
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
        let currentDate = ISO8601DateFormatter().string(from: Date())
        _ = DateFormatter().string(from: Date()) // Reserved for future use
        
        return """
        You are an AI assistant specialized in the PARA methodology (Projects, Areas, Resources, Archives) for personal knowledge management and intelligent task management.
        
        Analyze this content comprehensively and provide a structured response with MANDATORY task enhancement:
        
        **Content to Process:**
        Content: "\(blob.content)"
        Source Type: \(blob.sourceType.rawValue)
        Work/Personal: \(blob.workPersonal.rawValue)
        Current Date/Time: \(currentDate)
        
        **Available Context:**
        Existing Areas: \(availableAreas.isEmpty ? "None" : availableAreas.joined(separator: ", "))
        Existing Projects: \(availableProjects.isEmpty ? "None" : availableProjects.joined(separator: ", "))
        
        **CRITICAL TASK REQUIREMENTS:**
        For EVERY task you extract, you MUST assign ALL of the following:
        
        1. **Priority Score (1-5 Scale):** 
           - Score 5 (Urgent): Life-critical, legal deadlines, emergencies, blocking others
           - Score 4 (High): Important deadlines, key milestones, health/safety issues
           - Score 3 (Medium): Regular work tasks, planned activities, moderate importance
           - Score 2 (Low): Nice-to-have, learning, non-urgent improvements
           - Score 1 (Lowest): Someday/maybe items, distant future planning
        
        2. **Smart Date Assignment:**
           - Parse temporal language: "tomorrow" = next day at appropriate time
           - "next week" = upcoming Monday at 9 AM
           - "this weekend" = upcoming Saturday at 10 AM
           - "Monday" = next occurrence at 9 AM
           - "in 2 hours" = current time + 2 hours
           - "tonight" = today at 7 PM
           - "ASAP"/"urgent" = within next 2 hours, priority score 5
           - No time mentioned = suggest intelligent default based on priority and type
        
        3. **Duration Estimation (minutes):**
           - Quick tasks (calls, emails, simple decisions): 15-30 minutes
           - Planning/research tasks: 60-120 minutes
           - Shopping/errands: 30-60 minutes
           - Deep work tasks: 120-240 minutes
           - Meetings: 30-60 minutes (unless specified)
           - Learning/reading: 45-90 minutes
           - Creative work: 90-180 minutes
        
        4. **Time Slot Assignment:**
           - Work tasks: Business hours (9 AM - 6 PM on weekdays)
           - Personal tasks: Evenings (6 PM - 10 PM) or weekends
           - Health/exercise: Early morning (7-9 AM) or evening (6-8 PM)
           - Shopping/errands: Weekend mornings or weekday evenings
           - Learning: Focused time blocks when alert
        
        **Enhanced Processing Instructions:**
        1. PARA Categorization with sub-category specificity
        2. Extract ALL actionable items as complete tasks
        3. For each task, analyze urgency indicators: deadlines, time pressure, consequences of delay
        4. Consider importance factors: impact on goals, health, relationships, work
        5. Cross-reference with available projects/areas for proper assignment
        6. Flag truly urgent tasks separately
        7. Provide reasoning for each priority score assignment
        
        **Response Format (JSON):**
        {
          "para_category": "project|area|resource|archive",
          "confidence": 0.85,
          "requires_confirmation": false,
          "suggested_area": "Health & Fitness" or null,
          "suggested_project": "Q1 Planning" or null,
          "sub_category": "Specific sub-category within the area/project",
          "extracted_tasks": [
            {
              "title": "Clear, actionable task title",
              "description": "Additional context and reasoning",
              "priority_score": 4,
              "priority": "high",
              "priority_reasoning": "Important deadline affecting team delivery",
              "estimated_duration": 45,
              "suggested_due_date": "2024-01-15T14:00:00Z",
              "suggested_due_reason": "Based on 'tomorrow afternoon' in content + business hours",
              "time_block": "work_hours|evening|weekend|flexible",
              "urgency_indicators": ["deadline", "blocking_others"],
              "importance_factors": ["work_milestone", "team_dependency"],
              "area": "Health & Fitness",
              "project": "Q1 Planning",
              "tags": ["workout", "planning", "health"],
              "is_focus": true,
              "work_personal": "work|personal|both",
              "confidence": 0.9
            }
          ],
          "auto_tags": ["tag1", "tag2", "tag3"],
          "summary": "Brief summary of content if lengthy",
          "cross_links": [
            {
              "type": "area|project|resource",
              "target_name": "Related item name",
              "confidence": 0.8,
              "reason": "Why this connection makes sense"
            }
          ],
          "reasoning": "Brief explanation of categorization and priority decisions"
        }
        
        **Priority Score Guidelines:**
        - **Score 5 (Urgent):** Deadlines today/tomorrow, emergencies, blocking critical path
        - **Score 4 (High):** Important deadlines this week, key health/safety, major milestones
        - **Score 3 (Medium):** Regular tasks, planned activities, moderate impact
        - **Score 2 (Low):** Nice-to-have improvements, learning, optimization
        - **Score 1 (Lowest):** Someday/maybe, brainstorming, distant future
        
        **Time Assignment Rules:**
        - Respect work/personal classification for scheduling
        - Consider energy levels for different task types
        - Account for realistic availability and context switching
        - Buffer time for task switching and preparation
        - Align with typical productivity patterns
        
        **Duration Estimation Factors:**
        - Task complexity and cognitive load
        - Required preparation and cleanup time
        - Potential interruptions and context switching
        - Learning curve for new or unfamiliar tasks
        - Communication and coordination overhead
        
        IMPORTANT: Every extracted task MUST have all fields populated. No empty durations, dates, or priority scores allowed.
        """
    }
    
    /// Create smart default date based on task priority
    private func createSmartDefaultDate(for priority: TaskPriority) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch priority {
        case .urgent:
            // Urgent tasks: within next 4 hours or next business day morning
            if let nextFewHours = calendar.date(byAdding: .hour, value: 4, to: now) {
                return nextFewHours
            }
            fallthrough
        case .high:
            // High priority: within next 2 days, business hours
            var targetDate = now
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                targetDate = tomorrow
                // Set to 9 AM business time
                let components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                if let businessTime = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: 9, minute: 0)) {
                    return businessTime
                }
            }
            return targetDate
        case .medium:
            // Medium priority: within a week, flexible timing
            if let nextWeek = calendar.date(byAdding: .day, value: 5, to: now) {
                let components = calendar.dateComponents([.year, .month, .day], from: nextWeek)
                if let flexibleTime = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: 10, minute: 0)) {
                    return flexibleTime
                }
            }
            return now
        case .low:
            // Low priority: within 2 weeks, weekend or evening time
            if let twoWeeks = calendar.date(byAdding: .day, value: 14, to: now) {
                let components = calendar.dateComponents([.year, .month, .day], from: twoWeeks)
                if let weekendTime = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: 14, minute: 0)) {
                    return weekendTime
                }
            }
            return now
        }
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
        print("🔧 LLM PARSE: Found \(tasksJson.count) task(s) to parse")
        
        let extractedTasks = tasksJson.compactMap { taskData -> TaskExtractionInfo? in
            guard let title = taskData["title"] as? String else {
                print("🔧 LLM PARSE: ❌ Task missing title")
                return nil
            }
            
            let description = taskData["description"] as? String
            
            // Enhanced priority handling with scoring
            let priorityScore = taskData["priority_score"] as? Int ?? 3
            let priorityString = taskData["priority"] as? String ?? "medium"
            let priority = TaskPriority(rawValue: priorityString) ?? TaskPriority(fromScore: priorityScore)
            let priorityReasoning = taskData["priority_reasoning"] as? String
            
            // Enhanced duration estimation
            let estimatedDuration = taskData["estimated_duration"] as? Int ?? {
                // Fallback duration estimation based on task type and priority
                switch priority {
                case .urgent: return 30  // Urgent tasks are often quick actions
                case .high: return 60    // High priority tasks need focused time
                case .medium: return 45  // Standard task duration
                case .low: return 30     // Low priority tasks are often quick
                }
            }()
            
            // Enhanced date parsing with smart defaults
            var suggestedDueDate: String? = nil
            if let dueDateString = taskData["suggested_due_date"] as? String {
                // Try to parse and validate the date
                let isoFormatter = ISO8601DateFormatter()
                if isoFormatter.date(from: dueDateString) != nil {
                    suggestedDueDate = dueDateString
                    print("🔧 LLM PARSE: ✅ Parsed due date: \(dueDateString)")
                } else {
                    // Try basic date format as fallback
                    let basicFormatter = DateFormatter()
                    basicFormatter.dateFormat = "yyyy-MM-dd"
                    if let basicDate = basicFormatter.date(from: dueDateString) {
                        suggestedDueDate = isoFormatter.string(from: basicDate)
                        print("🔧 LLM PARSE: ✅ Converted basic date: \(dueDateString) -> \(suggestedDueDate!)")
                    } else {
                        print("🔧 LLM PARSE: ⚠️ Invalid date format: \(dueDateString)")
                        // Assign smart default based on priority
                        let defaultDate = createSmartDefaultDate(for: priority)
                        let isoFormatter = ISO8601DateFormatter()
                        suggestedDueDate = isoFormatter.string(from: defaultDate)
                        print("🔧 LLM PARSE: ✅ Assigned smart default date: \(suggestedDueDate!)")
                    }
                }
            } else {
                // No date provided, create smart default
                let defaultDate = createSmartDefaultDate(for: priority)
                let isoFormatter = ISO8601DateFormatter()
                suggestedDueDate = isoFormatter.string(from: defaultDate)
                print("🔧 LLM PARSE: ✅ Created smart default date: \(suggestedDueDate!)")
            }
            
            let suggestedArea = taskData["area"] as? String ?? taskData["suggested_area"] as? String
            let suggestedProject = taskData["project"] as? String ?? taskData["suggested_project"] as? String
            let taskTags = taskData["tags"] as? [String] ?? []
            let taskConfidence = taskData["confidence"] as? Double ?? 0.8
            let timeBlock = taskData["time_block"] as? String
            let urgencyIndicators = taskData["urgency_indicators"] as? [String] ?? []
            let importanceFactors = taskData["importance_factors"] as? [String] ?? []
            
            print("🔧 LLM PARSE: ✅ Parsed enhanced task: \(title) (Priority: \(priority.rawValue)/\(priorityScore), Duration: \(estimatedDuration)min, Due: \(suggestedDueDate ?? "none"))")
            
            return TaskExtractionInfo(
                title: title,
                description: description,
                priority: priority,
                estimatedDuration: estimatedDuration,
                suggestedDueDate: suggestedDueDate,
                suggestedArea: suggestedArea,
                suggestedProject: suggestedProject,
                tags: taskTags,
                confidence: taskConfidence,
                priorityScore: priorityScore,
                priorityReasoning: priorityReasoning,
                urgencyIndicators: urgencyIndicators,
                importanceFactors: importanceFactors,
                timeBlock: timeBlock
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
    
    /// Parse brain dump response containing JSON array of items
    private func parseBrainDumpResponse(_ response: String) throws -> PARAProcessingResult {
        print("🔧 LLM PARSE: Parsing brain dump response")
        
        // Extract JSON array from response
        let jsonString = extractJSONArray(from: response)
        guard let data = jsonString.data(using: .utf8) else {
            print("🔧 LLM PARSE: ❌ Failed to convert JSON string to data")
            throw LLMError.parsingError
        }
        
        do {
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("🔧 LLM PARSE: ❌ Response is not a JSON array")
                throw LLMError.invalidResponse
            }
            
            print("🔧 LLM PARSE: ✅ Parsed JSON array with \(jsonArray.count) items")
            
            // Convert JSON array to BrainDumpItems
            var extractedItems: [BrainDumpItem] = []
            
            for (index, itemJson) in jsonArray.enumerated() {
                do {
                    let item = try parseBrainDumpItemFromJSON(itemJson)
                    extractedItems.append(item)
                    print("🔧 LLM PARSE: ✅ Item \(index + 1): \(item.title) (\(item.paraCategory.rawValue))")
                } catch {
                    print("🔧 LLM PARSE: ❌ Failed to parse item \(index + 1): \(error)")
                }
            }
            
            // Return result with extracted items
            return PARAProcessingResult(
                category: "multiple", // Indicates multiple items
                suggestedArea: nil,
                suggestedProject: nil,
                actionableTasks: [],
                tags: [],
                priority: .medium,
                workPersonal: .personal,
                confidenceScore: 0.9,
                reasoning: "Processed \(extractedItems.count) items using PARA method",
                extractedItems: extractedItems
            )
            
        } catch {
            print("🔧 LLM PARSE: ❌ JSON parsing error: \(error)")
            throw LLMError.parsingError
        }
    }
    
    /// Parse individual brain dump item from JSON
    private func parseBrainDumpItemFromJSON(_ json: [String: Any]) throws -> BrainDumpItem {
        guard let title = json["title"] as? String,
              let content = json["content"] as? String,
              let contentTypeString = json["content_type"] as? String,
              let paraCategoryString = json["para_category"] as? String else {
            throw LLMError.invalidResponse
        }
        
        let contentType = ContentType(rawValue: contentTypeString) ?? .note
        let paraCategory = PARACategory(rawValue: paraCategoryString) ?? .area
        let workPersonal = WorkPersonalType(rawValue: json["work_personal"] as? String ?? "personal") ?? .personal
        let priority = TaskPriority(rawValue: json["priority"] as? String ?? "medium") ?? .medium
        let confidence = json["confidence"] as? Double ?? 0.8
        let tags = json["tags"] as? [String] ?? []
        
        return BrainDumpItem(
            id: UUID(),
            title: title,
            content: content,
            contentType: contentType,
            paraCategory: paraCategory,
            suggestedArea: json["suggested_area"] as? String,
            suggestedProject: json["suggested_project"] as? String,
            workPersonal: workPersonal,
            priority: priority,
            dueDate: json["due_date"] as? String,
            tags: tags,
            confidence: confidence,
            metadata: ["reasoning": json["reasoning"] as? String ?? ""]
        )
    }
    
    /// Extract JSON array from LLM response with robust parsing
    private func extractJSONArray(from response: String) -> String {
        Logger.shared.debug("LLM EXTRACT: Extracting JSON array from response")
        
        // First, try to find JSON in code blocks
        if let jsonStart = response.range(of: "```json") {
            let searchStart = jsonStart.upperBound
            guard searchStart < response.endIndex else {
                Logger.shared.warning("LLM EXTRACT: Invalid range after ```json")
                return response.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            let searchRange = searchStart..<response.endIndex
            if let jsonEnd = response.range(of: "```", range: searchRange) {
                let extracted = String(response[searchStart..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                Logger.shared.success("LLM EXTRACT: Found JSON in code block")
                return extracted
            }
        }
        
        // Try to extract just the JSON array part with aggressive cleaning
        if let arrayStart = response.range(of: "[") {
            let startIndex = arrayStart.lowerBound
            
            // Find the last occurrence of ] to get the complete array
            _ = startIndex..<response.endIndex // Reserved for future use
            var lastBracketIndex: String.Index? = nil
            var currentIndex = startIndex
            
            // Find the last ] in the string
            while currentIndex < response.endIndex {
                if response[currentIndex] == "]" {
                    lastBracketIndex = currentIndex
                }
                guard let nextIndex = response.index(currentIndex, offsetBy: 1, limitedBy: response.endIndex) else { break }
                currentIndex = nextIndex
            }
            
            if let arrayEnd = lastBracketIndex {
                let candidateJSON = String(response[startIndex...arrayEnd])
                
                // Try to validate and clean this JSON
                if let cleanedJSON = cleanAndValidateJSON(candidateJSON) {
                    Logger.shared.success("LLM EXTRACT: Successfully cleaned and validated JSON")
                    return cleanedJSON
                }
            }
            
            // Fallback: try bracket counting with better error recovery
            let extracted = extractWithBracketCounting(from: response, startIndex: startIndex)
            if !extracted.isEmpty {
                return extracted
            }
        }
        
        // Last resort: try to find any JSON-like structure
        Logger.shared.warning("LLM EXTRACT: Using fallback JSON extraction")
        return extractFallbackJSON(from: response)
    }
    
    /// Clean and validate JSON string with aggressive fixing
    private func cleanAndValidateJSON(_ jsonString: String) -> String? {
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.hasSuffix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        
        // Remove any text before the first [ or after the last ]
        if let firstBracket = cleaned.firstIndex(of: "["),
           let lastBracket = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[firstBracket...lastBracket])
        }
        
        // Normalize whitespace
        cleaned = cleaned.replacingOccurrences(of: "\n", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "\r", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "\t", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        
        // Fix common JSON issues
        cleaned = cleaned.replacingOccurrences(of: ",}", with: "}")
        cleaned = cleaned.replacingOccurrences(of: ",]", with: "]")
        cleaned = cleaned.replacingOccurrences(of: ",,", with: ",")
        
        // Remove trailing commas before closing brackets
        cleaned = cleaned.replacingOccurrences(of: ",\\s*}", with: "}", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ",\\s*]", with: "]", options: .regularExpression)
        
        // Fix missing quotes around keys (common LLM error)
        cleaned = cleaned.replacingOccurrences(of: "([{,]\\s*)([a-zA-Z_][a-zA-Z0-9_]*):", with: "$1\"$2\":", options: .regularExpression)
        
        // Try to parse to validate
        if let data = cleaned.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: data) {
            Logger.shared.success("LLM EXTRACT: Successfully validated and cleaned JSON")
            return cleaned
        }
        
        Logger.shared.warning("LLM EXTRACT: JSON validation failed even after cleaning")
        return nil
    }
    
    /// Extract JSON with bracket counting
    private func extractWithBracketCounting(from response: String, startIndex: String.Index) -> String {
        var bracketCount = 0
        var currentIndex = startIndex
        var lastBracketIndex: String.Index? = nil
        var inString = false
        var escapeNext = false
        
        while currentIndex < response.endIndex {
            let char = response[currentIndex]
            
            if escapeNext {
                escapeNext = false
            } else if char == "\\" && inString {
                escapeNext = true
            } else if char == "\"" && !escapeNext {
                inString.toggle()
            } else if !inString {
                if char == "[" || char == "{" {
                    bracketCount += 1
                } else if char == "]" || char == "}" {
                    bracketCount -= 1
                    lastBracketIndex = currentIndex
                    if bracketCount == 0 {
                        break
                    }
                }
            }
            
            guard let nextIndex = response.index(currentIndex, offsetBy: 1, limitedBy: response.endIndex) else { break }
            currentIndex = nextIndex
        }
        
        if bracketCount == 0, let endIndex = lastBracketIndex {
            let extracted = String(response[startIndex...endIndex])
            Logger.shared.success("LLM EXTRACT: Found complete JSON with bracket counting")
            return extracted
        } else if bracketCount > 0, let lastIndex = lastBracketIndex {
            // Try to fix by adding missing brackets
            let partialJSON = String(response[startIndex...lastIndex])
            let fixedJSON = partialJSON + String(repeating: "]", count: bracketCount)
            Logger.shared.warning("LLM EXTRACT: Fixed JSON with \(bracketCount) missing brackets")
            return fixedJSON
        }
        
        return ""
    }
    
    /// Fallback JSON extraction for malformed responses
    private func extractFallbackJSON(from response: String) -> String {
        // Look for anything that looks like a JSON array
        let lines = response.components(separatedBy: .newlines)
        var jsonLines: [String] = []
        var inArray = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("[") {
                inArray = true
                jsonLines.append(trimmed)
            } else if inArray {
                jsonLines.append(trimmed)
                if trimmed.hasSuffix("]") {
                    break
                }
            }
        }
        
        if !jsonLines.isEmpty {
            let fallbackJSON = jsonLines.joined(separator: " ")
            Logger.shared.warning("LLM EXTRACT: Using fallback extraction")
            return fallbackJSON
        }
        
        // Ultimate fallback: return empty array
        Logger.shared.error("LLM EXTRACT: Could not extract any JSON, returning empty array")
        return "[]"
    }
    
    private func buildComprehensivePrompt(input: String, context: PARAContext) -> String {
        let projectsList = context.projects.map { "- \($0.name): \($0.description ?? "")" }.joined(separator: "\n")
        let areasList = context.areas.map { "- \($0.name): \($0.description ?? "")" }.joined(separator: "\n")
        let commonTags = context.commonTags.joined(separator: ", ")
        
        return """
        You are a production-quality PARA categorization engine for LifeManager. Your job is to deliver precise, actionable classification of brain dump inputs.

        **INPUT TO ANALYZE:**
        "\(input)"

        **EXISTING CONTEXT:**
        Current Projects: \(projectsList.isEmpty ? "None" : projectsList)
        Current Areas: \(areasList.isEmpty ? "None" : areasList)
        Common Tags: \(commonTags.isEmpty ? "None" : commonTags)

        **CRITICAL CONTENT TYPE RULES - DO NOT LABEL EVERYTHING AS "NOTE":**

        **TASK**: Specific actionable items with clear completion criteria
        - "Clean out old clothes for donation before July 10th" → TASK
        - "Log receipts for June expenses in finance tracker" → TASK
        - "Renew library card by end of the month" → TASK

        **APPOINTMENT**: Scheduled or time-specific actions requiring calendar blocking
        - "Schedule 1-on-1 with new team lead" → APPOINTMENT
        - "Ask Dr. Patel if I need to renew tetanus shot this year" → APPOINTMENT

        **RESOURCE**: Reference material, learning content, information to consume
        - "Read 'Atomic Habits' summary and save best ideas" → RESOURCE
        - "Watch WWDC 2025 sessions on Swift macros" → RESOURCE
        - "Try overnight oats recipe from NYT Cooking" → RESOURCE

        **PROJECT**: Multi-step outcomes with clear completion criteria and deadlines
        - "Create 'Wishlist' note for books and gadgets" → PROJECT
        - "Make packing checklist for Toronto conference in August" → PROJECT
        - "Update will and store a copy with estate documents" → PROJECT

        **GOAL**: Future aspirations, recurring habits, or long-term objectives
        - "Register for local improv class starting in September" → GOAL
        - "Brainstorm potential side-projects for autumn hackathon" → GOAL

        **ARCHIVE**: Storage, backup, or moving completed items
        - "Move 'Spring 2024 Project Plan' file to archives" → ARCHIVE
        - "Backup phone photos and clear space" → ARCHIVE

        **DATE & PRIORITY INTELLIGENCE:**
        - Extract ALL dates: "next week", "before July 10th", "Friday", "end of the month"
        - Convert to ISO format: "next week" → "2025-06-23", "before July 10th" → "2025-07-09"
        - Current date: 2025-06-14
        - **URGENT**: Deadlines in next 3 days
        - **HIGH**: This week deadlines, important milestones
        - **MEDIUM**: Planned but not urgent
        - **LOW**: Someday/maybe items

        **PARA ASSIGNMENT ACCURACY:**
        - **PROJECT**: Only for multi-step outcomes with clear completion criteria
        - **AREA**: Ongoing responsibilities (Health, Finance, Home, Work, Relationships)
        - **RESOURCE**: Reference material, learning content
        - **ARCHIVE**: Completed items, storage tasks

        **CONTEXT AWARENESS:**
        - Cross-check against existing Areas/Projects from context
        - If matching Project/Area exists, suggest linking
        - Create specific area names: "Personal Finance", "Health & Fitness", "Home Organization"

        **CONFIDENCE SCORING:**
        - Set confidence < 0.5 for ambiguous cases
        - Flag uncertain items for review
        - Be honest about classification uncertainty

        **CRITICAL: RESPOND WITH VALID JSON ARRAY ONLY - NO MARKDOWN, NO EXPLANATIONS, NO EXTRA TEXT**
        
        OUTPUT FORMAT: Pure JSON array starting with [ and ending with ]
        
        EXAMPLE OUTPUT:
        [{"title":"Email Maria about June invoice","content":"Email Maria the June invoice","content_type":"task","para_category":"project","suggested_area":"Work Administration","suggested_project":"Monthly Invoicing","work_personal":"work","priority":"high","due_date":"2025-06-16","tags":["email","invoice","urgent"],"confidence":0.9,"reasoning":"Clear work task with deadline"}]
        
        **STRICT JSON RULES:**
        - Start response with [ and end with ]
        - Use double quotes for ALL strings
        - NO trailing commas anywhere
        - NO line breaks inside strings
        - NO markdown formatting
        - NO explanatory text before or after JSON
        - Use null (not "null") for empty values
        - Escape quotes in content: "She said \"hello\""

        **PRODUCTION QUALITY REQUIREMENTS:**
        1. Split input into distinct items (each sentence = one item)
        2. NO generic "note" classifications - be precise
        3. Extract and convert ALL dates to ISO format
        4. Assign realistic urgency based on deadlines
        5. Link to existing context when possible
        6. Provide detailed reasoning for each decision
        7. Flag uncertain cases with low confidence
        8. Ensure JSON is valid and ready for database insertion

        **EXAMPLES FROM YOUR INPUT:**
        - "Remember to send birthday card to Maya next week" → Task, Personal Relationships, due: "2025-06-20", High priority
        - "Schedule 1-on-1 with new team lead" → Appointment, Work Management, High priority
        - "Research best high-protein vegetarian snacks for running" → Resource, Health & Fitness, Medium priority
        - "Create 'Wishlist' note for books and gadgets" → Project, Personal Organization, Medium priority
        - "Move 'Spring 2024 Project Plan' file to archives" → Archive, Work Organization, Low priority

        Return ONLY the JSON array - no other text. Be precise, not generic.
        """
    }
    
    private func calculateAverageConfidence(from items: [BrainDumpItem]) -> Double {
        guard !items.isEmpty else { return 0.0 }
        let totalConfidence = items.compactMap { $0.confidence }.reduce(0.0, +)
        return totalConfidence / Double(items.count)
    }
    
    private func makeAPICall(prompt: String) async throws -> String {
        return try await callLLM(prompt: prompt)
    }
    
    private func parseJSONResponse(_ response: String) throws -> [BrainDumpItem] {
        // Extract JSON from response
        let jsonString = extractJSONArray(from: response)
        
        // Parse JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw LLMError.parsingError
        }
        
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
            guard let jsonArray = jsonArray else {
                throw LLMError.parsingError
            }
            
            var items: [BrainDumpItem] = []
            for json in jsonArray {
                let item = try createBrainDumpItemFromJSON(json)
                items.append(item)
            }
            
            return items
        } catch {
            print("🔧 LLM: JSON parsing error: \(error)")
            throw LLMError.parsingError
        }
    }
    
    private func createBrainDumpItemFromJSON(_ json: [String: Any]) throws -> BrainDumpItem {
        guard let title = json["title"] as? String,
              let content = json["content"] as? String,
              let contentTypeString = json["content_type"] as? String,
              let paraCategoryString = json["para_category"] as? String,
              let workPersonalString = json["work_personal"] as? String,
              let priorityString = json["priority"] as? String else {
            throw LLMError.parsingError
        }
        
        // Parse enums with better defaults
        let contentType = ContentType(rawValue: contentTypeString) ?? .task
        let paraCategory = PARACategory(rawValue: paraCategoryString) ?? .area
        let workPersonal = WorkPersonalType(rawValue: workPersonalString) ?? .personal
        let priority = TaskPriority(rawValue: priorityString) ?? .medium
        
        // Parse optional fields
        let suggestedArea = json["suggested_area"] as? String
        let suggestedProject = json["suggested_project"] as? String
        let confidence = json["confidence"] as? Double ?? 0.8
        let reasoning = json["reasoning"] as? String ?? ""
        let tags = json["tags"] as? [String] ?? []
        
        // Parse due date
        var dueDate: String? = nil
        if let dueDateString = json["due_date"] as? String, !dueDateString.isEmpty && dueDateString != "null" {
            dueDate = dueDateString
        }
        
        return BrainDumpItem(
            id: UUID(),
            title: title,
            content: content,
            contentType: contentType,
            paraCategory: paraCategory,
            suggestedArea: suggestedArea,
            suggestedProject: suggestedProject,
            workPersonal: workPersonal,
            priority: priority,
            dueDate: dueDate,
            tags: tags,
            confidence: confidence,
            metadata: ["reasoning": reasoning]
        )
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
    let extractedItems: [BrainDumpItem]?
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