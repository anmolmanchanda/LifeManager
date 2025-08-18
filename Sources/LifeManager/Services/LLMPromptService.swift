//
// LLMPromptService.swift
// LifeManager
//
// Implements: v2.0 "Architecture Modularization" - LLM Prompt Management
// Extracted from LLMService as part of Phase 2B decomposition
// Manages prompt templates, generation, and prompt engineering logic
//

import Foundation

/// Manages LLM prompt templates and generation
/// Handles prompt engineering, template management, and dynamic prompt creation
/// Extracted from LLMService for better separation of concerns
class LLMPromptService: ObservableObject {
    
    static let shared = LLMPromptService()
    
    // MARK: - Dependencies
    
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Prompt Template Management
    
    /// Load prompt template with data substitution
    func loadPromptTemplate(_ templateName: String, with data: [String: AnyCodableValue]) throws -> String {
        // Try to load from file first
        if let templatePath = Bundle.main.path(forResource: templateName, ofType: "txt", inDirectory: "prompts/templates"),
           let template = try? String(contentsOfFile: templatePath) {
            return substituteVariables(in: template, with: data)
        }
        
        // Fall back to embedded templates
        return getEmbeddedTemplate(templateName, with: data)
    }
    
    /// Get embedded template with variable substitution
    private func getEmbeddedTemplate(_ templateName: String, with data: [String: AnyCodableValue]) -> String {
        let template = getTemplateContent(templateName)
        return substituteVariables(in: template, with: data)
    }
    
    /// Get template content by name
    private func getTemplateContent(_ templateName: String) -> String {
        switch templateName {
        case "para_categorization":
            return getParaCategorizationTemplate()
        case "task_extraction":
            return getTaskExtractionTemplate()
        case "task_priority":
            return getTaskPriorityTemplate()
        case "comprehensive_processing":
            return getComprehensiveProcessingTemplate()
        case "task_enhancement":
            return getTaskEnhancementTemplate()
        default:
            logger.warning("🎯 PROMPT: Unknown template '\(templateName)', using default")
            return getDefaultTemplate()
        }
    }
    
    // MARK: - Template Definitions
    
    private func getParaCategorizationTemplate() -> String {
        return """
        You are an expert productivity consultant specializing in the PARA method (Projects, Areas, Resources, Archives).

        Analyze the following content and categorize it according to PARA methodology:

        **Content to analyze:**
        {{content}}

        **Available Areas:** {{available_areas}}
        **Available Projects:** {{available_projects}}

        **Instructions:**
        1. Determine the most appropriate PARA category (Project, Area, Resource, or Archive)
        2. Suggest a specific Area or Project if applicable
        3. Provide confidence score (0.0-1.0)
        4. Extract any actionable tasks
        5. Suggest relevant tags

        **Response format (JSON):**
        {
          "category": "project|area|resource|archive",
          "confidence": 0.85,
          "suggested_area": "Area name or null",
          "suggested_project": "Project name or null", 
          "reasoning": "Brief explanation of categorization",
          "extracted_tasks": [
            {
              "title": "Task title",
              "priority": "low|medium|high|urgent",
              "estimated_duration": 30
            }
          ],
          "suggested_tags": ["tag1", "tag2"]
        }
        """
    }
    
    private func getTaskExtractionTemplate() -> String {
        return """
        You are an expert task extraction system. Analyze the following content and extract all actionable tasks.

        **Content to analyze:**
        {{content}}

        **Instructions:**
        1. Identify all actionable items that require completion
        2. Create clear, specific task titles
        3. Assign appropriate priorities based on urgency and importance
        4. Estimate completion time in minutes
        5. Suggest due dates if time-sensitive

        **Response format (JSON):**
        {
          "tasks": [
            {
              "title": "Clear, actionable task title",
              "description": "Additional context if needed",
              "priority": "low|medium|high|urgent",
              "estimated_duration": 30,
              "suggested_due_date": "YYYY-MM-DD or null",
              "tags": ["tag1", "tag2"],
              "confidence": 0.85
            }
          ],
          "summary": "Brief summary of extracted tasks"
        }
        """
    }
    
    private func getTaskPriorityTemplate() -> String {
        return """
        You are an expert task prioritization system. Analyze the following task and determine its priority.

        **Task to analyze:**
        Title: {{task_title}}
        Description: {{task_description}}
        Context: {{task_context}}

        **Instructions:**
        1. Assess urgency (time-sensitive nature)
        2. Assess importance (impact and value)
        3. Consider dependencies and prerequisites
        4. Assign priority level with reasoning

        **Response format (JSON):**
        {
          "priority": "low|medium|high|urgent",
          "urgency_score": 0.75,
          "importance_score": 0.85,
          "reasoning": "Detailed explanation of priority assignment",
          "suggested_deadline": "YYYY-MM-DD or null",
          "time_sensitivity": "high|medium|low"
        }
        """
    }
    
    private func getComprehensiveProcessingTemplate() -> String {
        return """
        You are an expert productivity assistant using the PARA methodology. Analyze the following content comprehensively.

        **Content to analyze:**
        {{content}}

        **Context:**
        - Available Areas: {{available_areas}}
        - Available Projects: {{available_projects}}
        - Confidence Threshold: {{confidence_threshold}}

        **Instructions:**
        Perform a comprehensive analysis including:
        1. PARA categorization with high confidence
        2. Task extraction and prioritization
        3. Content summarization
        4. Cross-reference suggestions
        5. Actionable recommendations

        **Response format (JSON):**
        {
          "para_category": "project|area|resource|archive",
          "confidence": 0.90,
          "suggested_area": "Area name or null",
          "suggested_project": "Project name or null",
          "extracted_tasks": [
            {
              "title": "Task title",
              "priority": "low|medium|high|urgent",
              "estimated_duration": 30,
              "suggested_due_date": "YYYY-MM-DD or null"
            }
          ],
          "auto_tags": ["tag1", "tag2"],
          "summary": "Brief content summary",
          "cross_links": [
            {
              "type": "related_area|related_project|prerequisite",
              "target": "Target name",
              "reasoning": "Why this is related"
            }
          ],
          "actions": [
            {
              "type": "create_project|schedule_task|add_reminder",
              "description": "Action description",
              "priority": "high|medium|low"
            }
          ]
        }
        """
    }
    
    private func getTaskEnhancementTemplate() -> String {
        return """
        You are an expert task enhancement system. Improve the following task with additional context and suggestions.

        **Task to enhance:**
        Title: {{task_title}}
        Description: {{task_description}}
        Current Priority: {{current_priority}}
        Estimated Duration: {{estimated_duration}} minutes

        **Instructions:**
        1. Improve task clarity and specificity
        2. Suggest better time estimates
        3. Identify prerequisites and dependencies
        4. Recommend task breakdown if complex
        5. Suggest optimal scheduling

        **Response format (JSON):**
        {
          "enhanced_title": "Improved task title",
          "enhanced_description": "More detailed description",
          "improved_priority": "low|medium|high|urgent",
          "realistic_duration": 45,
          "prerequisites": ["prerequisite1", "prerequisite2"],
          "subtasks": [
            {
              "title": "Subtask title",
              "duration": 15
            }
          ],
          "optimal_scheduling": {
            "time_of_day": "morning|afternoon|evening",
            "energy_level": "high|medium|low",
            "focus_required": "high|medium|low"
          },
          "enhancement_reasoning": "Explanation of improvements made"
        }
        """
    }
    
    private func getDefaultTemplate() -> String {
        return """
        Please analyze the following content:

        {{content}}

        Provide a structured analysis with:
        1. Main topic identification
        2. Key points extraction
        3. Actionable items
        4. Categorization suggestions

        Response should be in JSON format with clear structure.
        """
    }
    
    // MARK: - Variable Substitution
    
    /// Substitute variables in template with provided data
    private func substituteVariables(in template: String, with data: [String: AnyCodableValue]) -> String {
        var result = template
        
        for (key, value) in data {
            let placeholder = "{{\(key)}}"
            let stringValue = stringValue(from: value)
            result = result.replacingOccurrences(of: placeholder, with: stringValue)
        }
        
        return result
    }
    
    /// Convert AnyCodableValue to string representation
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
    
    // MARK: - Specialized Prompt Generators
    
    /// Create comprehensive processing prompt for a blob
    func createComprehensivePrompt(for blob: Blob, availableAreas: [String], availableProjects: [String], confidenceThreshold: Double) -> String {
        let data: [String: AnyCodableValue] = [
            "content": .string(blob.content),
            "available_areas": .array(availableAreas.map { .string($0) }),
            "available_projects": .array(availableProjects.map { .string($0) }),
            "confidence_threshold": .double(confidenceThreshold)
        ]
        
        do {
            return try loadPromptTemplate("comprehensive_processing", with: data)
        } catch {
            logger.error("🎯 PROMPT: Failed to load comprehensive template: \(error)")
            return getEmbeddedTemplate("comprehensive_processing", with: data)
        }
    }
    
    /// Create task enhancement prompt for a task
    func createTaskEnhancementPrompt(for task: LifeTask) -> String {
        let data: [String: AnyCodableValue] = [
            "task_title": .string(task.title),
            "task_description": .string(task.description ?? ""),
            "current_priority": .string(task.priority.rawValue),
            "estimated_duration": .int(task.estimatedDuration ?? 30)
        ]
        
        do {
            return try loadPromptTemplate("task_enhancement", with: data)
        } catch {
            logger.error("🎯 PROMPT: Failed to load task enhancement template: \(error)")
            return getEmbeddedTemplate("task_enhancement", with: data)
        }
    }
    
    /// Create PARA categorization prompt
    func createCategorizationPrompt(content: String, availableAreas: [String], availableProjects: [String]) -> String {
        let data: [String: AnyCodableValue] = [
            "content": .string(content),
            "available_areas": .array(availableAreas.map { .string($0) }),
            "available_projects": .array(availableProjects.map { .string($0) })
        ]
        
        do {
            return try loadPromptTemplate("para_categorization", with: data)
        } catch {
            logger.error("🎯 PROMPT: Failed to load categorization template: \(error)")
            return getEmbeddedTemplate("para_categorization", with: data)
        }
    }
    
    /// Create task extraction prompt
    func createTaskExtractionPrompt(content: String) -> String {
        let data: [String: AnyCodableValue] = [
            "content": .string(content)
        ]
        
        do {
            return try loadPromptTemplate("task_extraction", with: data)
        } catch {
            logger.error("🎯 PROMPT: Failed to load task extraction template: \(error)")
            return getEmbeddedTemplate("task_extraction", with: data)
        }
    }
    
    /// Create task priority analysis prompt
    func createTaskPriorityPrompt(title: String, description: String, context: String) -> String {
        let data: [String: AnyCodableValue] = [
            "task_title": .string(title),
            "task_description": .string(description),
            "task_context": .string(context)
        ]
        
        do {
            return try loadPromptTemplate("task_priority", with: data)
        } catch {
            logger.error("🎯 PROMPT: Failed to load task priority template: \(error)")
            return getEmbeddedTemplate("task_priority", with: data)
        }
    }
    
    // MARK: - Prompt Validation
    
    /// Validate prompt template for required variables
    func validateTemplate(_ template: String, requiredVariables: [String]) -> ValidationResult {
        var missingVariables: [String] = []
        
        for variable in requiredVariables {
            let placeholder = "{{\(variable)}}"
            if !template.contains(placeholder) {
                missingVariables.append(variable)
            }
        }
        
        return ValidationResult(
            isValid: missingVariables.isEmpty,
            missingVariables: missingVariables,
            templateLength: template.count
        )
    }
    
    /// Get prompt statistics
    func getPromptStatistics(for prompt: String) -> PromptStatistics {
        let words = prompt.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let estimatedTokens = words.count // Rough estimate: 1 word ≈ 1 token
        
        return PromptStatistics(
            characterCount: prompt.count,
            wordCount: words.count,
            estimatedTokens: estimatedTokens,
            templateVariables: extractTemplateVariables(from: prompt)
        )
    }
    
    /// Extract template variables from prompt
    private func extractTemplateVariables(from prompt: String) -> [String] {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: prompt) else { return nil }
            return String(prompt[range])
        }
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let missingVariables: [String]
    let templateLength: Int
}

struct PromptStatistics {
    let characterCount: Int
    let wordCount: Int
    let estimatedTokens: Int
    let templateVariables: [String]
}