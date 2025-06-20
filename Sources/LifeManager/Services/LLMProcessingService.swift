//
// LLMProcessingService.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - LLM Response Processing
// Extracted from LLMService as part of Phase 2B decomposition
// Handles response parsing, PARA categorization, and high-level AI processing logic
//

import Foundation

/// Manages LLM response processing and PARA methodology integration
/// Handles response parsing, categorization logic, and business rule application
/// Extracted from LLMService for better separation of concerns
class LLMProcessingService: ObservableObject {
    
    static let shared = LLMProcessingService()
    
    // MARK: - Dependencies
    
    private let communicationService = LLMCommunicationService.shared
    private let promptService = LLMPromptService.shared
    private let configService = LLMConfigurationService.shared
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - High-Level Processing Methods
    
    /// Process natural language input for PARA categorization
    func processNaturalLanguage(
        input: String,
        availableAreas: [String] = [],
        availableProjects: [String] = [],
        confidenceThreshold: Double = 0.7
    ) async throws -> PARAProcessingResult {
        
        logger.info("🧠 PROCESSING: Starting natural language processing")
        
        let prompt = promptService.createCategorizationPrompt(
            content: input,
            availableAreas: availableAreas,
            availableProjects: availableProjects
        )
        
        let response = try await communicationService.callLLM(prompt: prompt)
        let result = try parseCategorizationResponse(response)
        
        // Apply confidence threshold
        if result.confidence < confidenceThreshold {
            logger.warning("🧠 PROCESSING: Low confidence (\(result.confidence)) below threshold (\(confidenceThreshold))")
        }
        
        logger.success("🧠 PROCESSING: Categorized as \(result.category) with confidence \(result.confidence)")
        return result
    }
    
    /// Extract actionable tasks from content
    func extractTasks(
        from content: String,
        context: String = ""
    ) async throws -> TaskExtractionResult {
        
        logger.info("🧠 PROCESSING: Starting task extraction")
        
        let prompt = promptService.createTaskExtractionPrompt(content: content)
        let response = try await communicationService.callLLM(prompt: prompt)
        let result = try parseTaskExtractionResponse(response)
        
        logger.success("🧠 PROCESSING: Extracted \(result.tasks.count) tasks")
        return result
    }
    
    /// Suggest task priority based on content analysis
    func suggestTaskPriority(
        title: String,
        description: String,
        context: String = ""
    ) async throws -> TaskPriorityResult {
        
        logger.info("🧠 PROCESSING: Analyzing task priority")
        
        let prompt = promptService.createTaskPriorityPrompt(
            title: title,
            description: description,
            context: context
        )
        
        let response = try await communicationService.callLLM(prompt: prompt)
        let result = try parseTaskPriorityResponse(response)
        
        logger.success("🧠 PROCESSING: Suggested priority: \(result.priority)")
        return result
    }
    
    /// Process content comprehensively using all available context
    func processComprehensively(
        blob: Blob,
        availableAreas: [String] = [],
        availableProjects: [String] = [],
        confidenceThreshold: Double = 0.7
    ) async throws -> ProcessingResult {
        
        logger.info("🧠 PROCESSING: Starting comprehensive processing")
        
        let prompt = promptService.createComprehensivePrompt(
            for: blob,
            availableAreas: availableAreas,
            availableProjects: availableProjects,
            confidenceThreshold: confidenceThreshold
        )
        
        let response = try await communicationService.callLLM(prompt: prompt)
        let result = try parseComprehensiveResponse(response, for: blob)
        
        logger.success("🧠 PROCESSING: Comprehensive analysis complete")
        return result
    }
    
    /// Enhance existing tasks with AI suggestions
    func enhanceExistingTasks(_ tasks: [LifeTask]) async throws -> [TaskEnhancementResult] {
        logger.info("🧠 PROCESSING: Enhancing \(tasks.count) tasks")
        
        var results: [TaskEnhancementResult] = []
        
        for task in tasks {
            do {
                let result = try await enhanceIndividualTask(task)
                results.append(result)
            } catch {
                logger.error("🧠 PROCESSING: Failed to enhance task \(task.title): \(error)")
                // Continue with other tasks
            }
        }
        
        logger.success("🧠 PROCESSING: Enhanced \(results.count)/\(tasks.count) tasks")
        return results
    }
    
    // MARK: - Individual Task Enhancement
    
    private func enhanceIndividualTask(_ task: LifeTask) async throws -> TaskEnhancementResult {
        let prompt = promptService.createTaskEnhancementPrompt(for: task)
        let response = try await communicationService.callLLM(prompt: prompt)
        return try parseTaskEnhancementResponse(response, for: task)
    }
    
    // MARK: - Response Parsing
    
    private func parseCategorizationResponse(_ response: String) throws -> PARAProcessingResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMCommunicationError.parseError("Invalid JSON in categorization response")
        }
        
        guard let categoryString = json["category"] as? String,
              let category = PARACategory(rawValue: categoryString) else {
            throw LLMCommunicationError.parseError("Missing or invalid category in response")
        }
        
        let confidence = json["confidence"] as? Double ?? 0.5
        let suggestedArea = json["suggested_area"] as? String
        let suggestedProject = json["suggested_project"] as? String
        let reasoning = json["reasoning"] as? String ?? ""
        
        // Parse extracted tasks
        var extractedTasks: [TaskExtractionInfo] = []
        if let tasksArray = json["extracted_tasks"] as? [[String: Any]] {
            for taskJson in tasksArray {
                if let title = taskJson["title"] as? String,
                   let priorityString = taskJson["priority"] as? String,
                   let priority = TaskPriority(rawValue: priorityString) {
                    
                    let task = TaskExtractionInfo(
                        title: title,
                        priority: priority,
                        estimatedDuration: taskJson["estimated_duration"] as? Int,
                        confidence: taskJson["confidence"] as? Double ?? 0.7
                    )
                    extractedTasks.append(task)
                }
            }
        }
        
        // Parse suggested tags
        let suggestedTags = json["suggested_tags"] as? [String] ?? []
        
        return PARAProcessingResult(
            category: category,
            confidence: confidence,
            suggestedArea: suggestedArea,
            suggestedProject: suggestedProject,
            extractedTasks: extractedTasks,
            autoTags: suggestedTags,
            reasoning: reasoning
        )
    }
    
    private func parseTaskExtractionResponse(_ response: String) throws -> TaskExtractionResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMCommunicationError.parseError("Invalid JSON in task extraction response")
        }
        
        guard let tasksArray = json["tasks"] as? [[String: Any]] else {
            throw LLMCommunicationError.parseError("Missing tasks array in response")
        }
        
        var tasks: [TaskExtractionInfo] = []
        
        for taskJson in tasksArray {
            guard let title = taskJson["title"] as? String else { continue }
            
            let priorityString = taskJson["priority"] as? String ?? "medium"
            let priority = TaskPriority(rawValue: priorityString) ?? .medium
            
            let task = TaskExtractionInfo(
                title: title,
                description: taskJson["description"] as? String,
                priority: priority,
                estimatedDuration: taskJson["estimated_duration"] as? Int,
                suggestedDueDate: taskJson["suggested_due_date"] as? String,
                tags: taskJson["tags"] as? [String] ?? [],
                confidence: taskJson["confidence"] as? Double ?? 0.7
            )
            
            tasks.append(task)
        }
        
        let summary = json["summary"] as? String ?? ""
        
        return TaskExtractionResult(
            tasks: tasks,
            summary: summary,
            totalTasksFound: tasks.count
        )
    }
    
    private func parseTaskPriorityResponse(_ response: String) throws -> TaskPriorityResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMCommunicationError.parseError("Invalid JSON in task priority response")
        }
        
        let priorityString = json["priority"] as? String ?? "medium"
        let priority = TaskPriority(rawValue: priorityString) ?? .medium
        
        return TaskPriorityResult(
            priority: priority,
            urgencyScore: json["urgency_score"] as? Double ?? 0.5,
            importanceScore: json["importance_score"] as? Double ?? 0.5,
            reasoning: json["reasoning"] as? String ?? "",
            suggestedDeadline: json["suggested_deadline"] as? String,
            timeSensitivity: json["time_sensitivity"] as? String ?? "medium"
        )
    }
    
    private func parseComprehensiveResponse(_ response: String, for blob: Blob) throws -> ProcessingResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMCommunicationError.parseError("Invalid JSON in comprehensive response")
        }
        
        let categoryString = json["para_category"] as? String ?? "resource"
        let category = PARACategory(rawValue: categoryString) ?? .resource
        let confidence = json["confidence"] as? Double ?? 0.5
        
        // Parse extracted tasks
        var extractedTasks: [TaskExtractionInfo] = []
        if let tasksArray = json["extracted_tasks"] as? [[String: Any]] {
            for taskJson in tasksArray {
                if let title = taskJson["title"] as? String {
                    let priorityString = taskJson["priority"] as? String ?? "medium"
                    let priority = TaskPriority(rawValue: priorityString) ?? .medium
                    
                    let task = TaskExtractionInfo(
                        title: title,
                        priority: priority,
                        estimatedDuration: taskJson["estimated_duration"] as? Int,
                        suggestedDueDate: taskJson["suggested_due_date"] as? String
                    )
                    extractedTasks.append(task)
                }
            }
        }
        
        // Parse cross-links
        var crossLinks: [LLMCrossLinkSuggestion] = []
        if let linksArray = json["cross_links"] as? [[String: Any]] {
            for linkJson in linksArray {
                if let type = linkJson["type"] as? String,
                   let target = linkJson["target"] as? String,
                   let reasoning = linkJson["reasoning"] as? String {
                    crossLinks.append(LLMCrossLinkSuggestion(
                        type: type,
                        target: target,
                        reasoning: reasoning
                    ))
                }
            }
        }
        
        // Parse actions
        var actions: [LLMProcessingAction] = []
        if let actionsArray = json["actions"] as? [[String: Any]] {
            for actionJson in actionsArray {
                if let type = actionJson["type"] as? String,
                   let description = actionJson["description"] as? String {
                    actions.append(LLMProcessingAction(
                        type: type,
                        description: description,
                        priority: actionJson["priority"] as? String ?? "medium"
                    ))
                }
            }
        }
        
        return ProcessingResult(
            blobId: blob.id,
            paraCategory: category,
            confidence: confidence,
            suggestedArea: json["suggested_area"] as? String,
            suggestedProject: json["suggested_project"] as? String,
            extractedTasks: extractedTasks,
            autoTags: json["auto_tags"] as? [String] ?? [],
            summary: json["summary"] as? String,
            crossLinks: crossLinks,
            requiresConfirmation: confidence < 0.8,
            actions: actions
        )
    }
    
    private func parseTaskEnhancementResponse(_ response: String, for task: LifeTask) throws -> TaskEnhancementResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMCommunicationError.parseError("Invalid JSON in task enhancement response")
        }
        
        let enhancedTitle = json["enhanced_title"] as? String ?? task.title
        let enhancedDescription = json["enhanced_description"] as? String ?? task.description
        
        let priorityString = json["improved_priority"] as? String ?? task.priority.rawValue
        let improvedPriority = TaskPriority(rawValue: priorityString) ?? task.priority
        
        let realisticDuration = json["realistic_duration"] as? Int ?? task.estimatedDuration ?? 30
        
        // Parse subtasks
        var subtasks: [SubtaskSuggestion] = []
        if let subtasksArray = json["subtasks"] as? [[String: Any]] {
            for subtaskJson in subtasksArray {
                if let title = subtaskJson["title"] as? String {
                    subtasks.append(SubtaskSuggestion(
                        title: title,
                        duration: subtaskJson["duration"] as? Int ?? 15
                    ))
                }
            }
        }
        
        // Parse optimal scheduling
        var optimalScheduling: OptimalScheduling?
        if let schedulingJson = json["optimal_scheduling"] as? [String: Any] {
            optimalScheduling = OptimalScheduling(
                timeOfDay: schedulingJson["time_of_day"] as? String ?? "morning",
                energyLevel: schedulingJson["energy_level"] as? String ?? "medium",
                focusRequired: schedulingJson["focus_required"] as? String ?? "medium"
            )
        }
        
        return TaskEnhancementResult(
            originalTask: task,
            enhancedTitle: enhancedTitle,
            enhancedDescription: enhancedDescription,
            improvedPriority: improvedPriority,
            realisticDuration: realisticDuration,
            prerequisites: json["prerequisites"] as? [String] ?? [],
            subtasks: subtasks,
            optimalScheduling: optimalScheduling,
            enhancementReasoning: json["enhancement_reasoning"] as? String ?? ""
        )
    }
    
    // MARK: - Utility Methods
    
    /// Extract JSON content from LLM response
    private func extractJSON(from response: String) -> String {
        // Try to find JSON within code blocks first
        let codeBlockPattern = "```(?:json)?\\s*([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
           let range = Range(match.range(at: 1), in: response) {
            return String(response[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find JSON by looking for { ... } structure
        if let startIndex = response.firstIndex(of: "{"),
           let endIndex = response.lastIndex(of: "}") {
            let range = startIndex...endIndex
            return String(response[range])
        }
        
        // If no JSON structure found, return the entire response
        logger.warning("🧠 PARSING: No clear JSON structure found, using entire response")
        return response
    }
    
    // MARK: - Convenience Methods
    
    /// Quick PARA categorization
    func categorizePARA(input: String) async throws -> PARAProcessingResult {
        return try await processNaturalLanguage(input: input)
    }
    
    /// Quick task extraction
    func extractTasks(content: String) async throws -> [[String: Any]] {
        let result = try await extractTasks(from: content)
        
        return result.tasks.map { task in
            var dict: [String: Any] = [
                "title": task.title,
                "priority": task.priority.rawValue,
                "confidence": task.confidence
            ]
            
            if let description = task.description {
                dict["description"] = description
            }
            
            if let duration = task.estimatedDuration {
                dict["estimated_duration"] = duration
            }
            
            if let dueDate = task.suggestedDueDate {
                dict["suggested_due_date"] = dueDate
            }
            
            if !task.tags.isEmpty {
                dict["tags"] = task.tags
            }
            
            return dict
        }
    }
    
    // MARK: - Logging and Analytics
    
    /// Log prompt execution for analytics
    private func logPromptExecution(
        templateName: String,
        promptLength: Int,
        responseLength: Int,
        processingTime: TimeInterval,
        success: Bool
    ) {
        let logEntry = PromptLogEntry(
            templateName: templateName,
            promptLength: promptLength,
            responseLength: responseLength,
            processingTime: processingTime,
            success: success,
            timestamp: Date()
        )
        
        logger.info("🧠 ANALYTICS: \(templateName) - Success: \(success), Time: \(String(format: "%.2f", processingTime))s")
        
        // TODO: Store analytics data for optimization
    }
}

// MARK: - Supporting Types

struct PromptLogEntry {
    let templateName: String
    let promptLength: Int
    let responseLength: Int
    let processingTime: TimeInterval
    let success: Bool
    let timestamp: Date
}

struct SubtaskSuggestion {
    let title: String
    let duration: Int
}

struct OptimalScheduling {
    let timeOfDay: String
    let energyLevel: String
    let focusRequired: String
}

struct LLMLLMCrossLinkSuggestion {
    let type: String
    let target: String
    let reasoning: String
}

struct LLMLLMProcessingAction {
    let type: String
    let description: String
    let priority: String
}