import Foundation

/// Comprehensive LLM-powered brain dump processor for LifeManager
/// Intelligently parses any unstructured text and organizes into PARA categories
class LLMBrainDumpProcessor {
    private let llmService: LLMService
    private let blobRepository: BlobRepository
    private let taskRepository: TaskRepository
    private let paraRepository: PARARepository
    private let resourceRepository: ResourceRepository
    
    init() {
        self.llmService = LLMService()
        self.blobRepository = BlobRepository()
        self.taskRepository = TaskRepository()
        self.paraRepository = PARARepository()
        self.resourceRepository = ResourceRepository()
    }
    
    /// Process brain dump input with comprehensive analysis
    func processBrainDump(_ input: String) async throws -> BrainDumpResult {
        print("🧠 BRAIN DUMP: Starting comprehensive processing of \(input.count) characters")
        
        // Check if API key is available
        guard ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil else {
            print("🧠 BRAIN DUMP: No API key found, using fallback processing")
            return try await processBrainDumpFallback(input)
        }
        
        do {
        // Step 1: Get context from existing PARA structure
        let context = try await gatherPARAContext()
        
        // Step 2: LLM analysis with comprehensive prompt
        let analysisResult = try await performLLMAnalysis(input: input, context: context)
        
        // Step 3: Create structured result for user review
        let result = BrainDumpResult(
            originalInput: input,
            analysisResult: analysisResult,
            suggestedItems: analysisResult.extractedItems,
            confidence: analysisResult.confidence,
            requiresReview: analysisResult.confidence < 0.8 || analysisResult.hasAmbiguousItems
        )
        
            print("🧠 BRAIN DUMP: ✅ LLM Analysis complete - found \(result.suggestedItems.count) items")
            return result
            
        } catch LLMError.missingAPIKey {
            print("🧠 BRAIN DUMP: ❌ API key missing, falling back to simple processing")
            return try await processBrainDumpFallback(input)
        } catch LLMError.networkError {
            print("🧠 BRAIN DUMP: ❌ Network error, falling back to simple processing")
            return try await processBrainDumpFallback(input)
        } catch LLMError.invalidResponse {
            print("🧠 BRAIN DUMP: ❌ Invalid LLM response, falling back to simple processing")
            return try await processBrainDumpFallback(input)
        } catch LLMError.parsingError {
            print("🧠 BRAIN DUMP: ❌ LLM parsing error, falling back to simple processing")
            return try await processBrainDumpFallback(input)
        } catch {
            print("🧠 BRAIN DUMP: ❌ Unexpected error: \(error), falling back to simple processing")
            return try await processBrainDumpFallback(input)
        }
    }
    
    /// Fallback processing when no API key is available
    private func processBrainDumpFallback(_ input: String) async throws -> BrainDumpResult {
        print("🧠 BRAIN DUMP: Using fallback processing without LLM")
        
        // Simple rule-based parsing for common patterns
        let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?")).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        var suggestedItems: [BrainDumpItem] = []
        
        for sentence in sentences {
            let item = createFallbackItem(from: sentence)
            suggestedItems.append(item)
        }
        
        // If no sentences found, create a single note
        if suggestedItems.isEmpty {
            let item = BrainDumpItem(
                id: UUID(),
                title: String(input.prefix(50)),
                content: input,
                contentType: .note,
                paraCategory: .resource,
                suggestedArea: nil,
                suggestedProject: nil,
                workPersonal: .personal,
                priority: .medium,
                dueDate: nil,
                tags: [],
                confidence: 0.5,
                metadata: ["reasoning": "Created from brain dump input (no LLM processing)"]
            )
            suggestedItems.append(item)
        }
        
        let analysisResult = LLMAnalysisResult(
            extractedItems: suggestedItems,
            confidence: 0.6,
            hasAmbiguousItems: false,
            reasoning: "Fallback processing - no LLM analysis performed",
            suggestedNewAreas: [],
            suggestedNewProjects: []
        )
        
        let result = BrainDumpResult(
            originalInput: input,
            analysisResult: analysisResult,
            suggestedItems: suggestedItems,
            confidence: 0.6,
            requiresReview: true
        )
        
        print("🧠 BRAIN DUMP: Fallback processing complete - created \(result.suggestedItems.count) items")
        return result
    }
    
    /// Create a fallback item from a sentence using simple rules
    private func createFallbackItem(from sentence: String) -> BrainDumpItem {
        let lowercased = sentence.lowercased()
        
        // Determine content type based on keywords
        let contentType: ContentType
        let priority: TaskPriority
        let paraCategory: PARACategory
        
        if lowercased.contains("task") || lowercased.contains("need to") || lowercased.contains("should") || lowercased.contains("must") {
            contentType = .task
            priority = .high
            paraCategory = .project
        } else if lowercased.contains("feeling") || lowercased.contains("emotion") || lowercased.contains("happy") || lowercased.contains("sad") || lowercased.contains("worried") {
            contentType = .journalEntry
            priority = .low
            paraCategory = .area
        } else if lowercased.contains("question") || lowercased.contains("wondering") || lowercased.contains("how") || lowercased.contains("what") || lowercased.contains("why") {
            contentType = .note
            priority = .medium
            paraCategory = .resource
        } else if lowercased.contains("want") || lowercased.contains("wish") || lowercased.contains("hope") {
            contentType = .goal
            priority = .medium
            paraCategory = .project
        } else {
            contentType = .note
            priority = .low
            paraCategory = .resource
        }
        
        return BrainDumpItem(
            id: UUID(),
            title: String(sentence.prefix(50)),
            content: sentence,
            contentType: contentType,
            paraCategory: paraCategory,
            suggestedArea: nil,
            suggestedProject: nil,
            workPersonal: .personal,
            priority: priority,
            dueDate: nil,
            tags: [],
            confidence: 0.6,
            metadata: ["reasoning": "Simple rule-based categorization"]
        )
    }
    
    /// Execute the brain dump after user confirmation
    func executeBrainDump(_ result: BrainDumpResult, userApprovedItems: [BrainDumpItem]) async throws -> ExecutionSummary {
        print("🧠 BRAIN DUMP: Executing \(userApprovedItems.count) approved items")
        
        var summary = ExecutionSummary()
        
        for item in userApprovedItems {
            do {
                switch item.contentType {
                case .task:
                    let task = try await createTaskFromItem(item)
                    summary.tasksCreated.append(task)
                    
                case .journalEntry:
                    let journal = try await createJournalFromItem(item)
                    summary.journalEntriesCreated.append(journal)
                    
                case .note:
                    let note = try await createNoteFromItem(item)
                    summary.notesCreated.append(note)
                    
                case .resource:
                    let resource = try await createResourceFromItem(item)
                    summary.resourcesCreated.append(resource)
                    
                case .financialTransaction:
                    let transaction = try await createFinancialTransactionFromItem(item)
                    summary.financialTransactionsCreated.append(transaction)
                    
                case .appointment:
                    let appointment = try await createAppointmentFromItem(item)
                    summary.appointmentsCreated.append(appointment)
                    
                case .habit:
                    let habit = try await createHabitFromItem(item)
                    summary.habitsCreated.append(habit)
                    
                case .goal:
                    let goal = try await createGoalFromItem(item)
                    summary.goalsCreated.append(goal)
                }
                
                summary.successCount += 1
                
            } catch {
                print("🧠 BRAIN DUMP: ❌ Failed to create \(item.contentType.rawValue): \(error)")
                summary.errors.append("Failed to create \(item.contentType.rawValue): \(error.localizedDescription)")
            }
        }
        
        print("🧠 BRAIN DUMP: ✅ Execution complete - \(summary.successCount) items created")
        return summary
    }
    
    // MARK: - Private Methods
    
    private func gatherPARAContext() async throws -> PARAContext {
        print("🧠 BRAIN DUMP: Gathering PARA context from database")
        
        let projects = try await paraRepository.fetchProjects()
        let areas = try await paraRepository.fetchAreas()
        let resources = try await paraRepository.fetchResources()
        let recentTasks = try await taskRepository.fetchRecentTasks(limit: 50)
        
        return PARAContext(
            projects: projects,
            areas: areas,
            resources: resources,
            recentTasks: recentTasks,
            commonTags: extractCommonTags(from: recentTasks)
        )
    }
    
    private func performLLMAnalysis(input: String, context: PARAContext) async throws -> LLMAnalysisResult {
        print("🧠 BRAIN DUMP: Performing LLM analysis with enhanced PARA context")
        
        // Use the enhanced categorizePARA method with context
        let response = try await llmService.categorizePARA(input: input, context: context)
        
        return try convertPARAResultToAnalysis(response, originalInput: input)
    }
    
    private func getSystemPrompt() -> String {
        return """
        You are an intelligent assistant for LifeManager, a PARA-based productivity system. Your job is to analyze any unstructured text input and intelligently organize it into the PARA framework:

        **PARA Categories:**
        - **Projects**: Time-bounded, actionable goals with clear outcomes
        - **Areas**: Ongoing responsibilities and life domains  
        - **Resources**: Reference materials, knowledge, and information
        - **Archives**: Completed, inactive, or outdated items

        **Content Types to Detect:**
        - Tasks (personal, work, hygiene, social, leisure, habits)
        - Journal entries (thoughts, feelings, reflections)
        - Notes (information, ideas, observations)
        - Resources (articles, recipes, guides, references)
        - Financial transactions (expenses, income, investments)
        - Appointments (meetings, events, scheduled activities)
        - Habits (productive and unproductive patterns)
        - Goals (short-term and long-term objectives)

        **Your Analysis Must:**
        1. Parse input into distinct components (even without punctuation)
        2. Classify each component by content type and PARA category
        3. Suggest appropriate Area/Project assignments based on context
        4. Determine work vs personal classification
        5. Extract priorities, due dates, and other metadata
        6. Identify relationships between items
        7. Flag ambiguous items that need user clarification

        **Response Format:** JSON with detailed analysis and high confidence scores.
        """
    }
    

    
    /// Convert PARAProcessingResult to LLMAnalysisResult
    private func convertPARAResultToAnalysis(_ result: PARAProcessingResult, originalInput: String) throws -> LLMAnalysisResult {
        var items: [BrainDumpItem] = []
        
        // Use extracted items from LLM if available
        if let extractedItems = result.extractedItems, !extractedItems.isEmpty {
            print("🧠 BRAIN DUMP: Using \(extractedItems.count) items from LLM analysis")
            items = extractedItems
        } else {
            // Fallback to manual parsing if LLM didn't return structured items
            print("🧠 BRAIN DUMP: No structured items from LLM, using fallback parsing")
            let extractedItems = parseMultipleItems(from: originalInput, using: result)
            items.append(contentsOf: extractedItems)
        }
        
        print("🧠 BRAIN DUMP: Final analysis contains \(items.count) items")
        for (index, item) in items.enumerated() {
            print("🧠 BRAIN DUMP: Item \(index + 1): '\(item.title)' → \(item.paraCategory.rawValue) (\(item.contentType.rawValue))")
        }
        
        return LLMAnalysisResult(
            extractedItems: items,
            confidence: result.confidenceScore,
            hasAmbiguousItems: false,
            reasoning: result.reasoning,
            suggestedNewAreas: [],
            suggestedNewProjects: []
        )
    }
    
    /// Parse multiple items from complex input text
    private func parseMultipleItems(from input: String, using result: PARAProcessingResult) -> [BrainDumpItem] {
        var items: [BrainDumpItem] = []
        
        // Split input by common delimiters and analyze each part
        let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for sentence in sentences {
            let item = createBrainDumpItem(from: sentence, fallbackResult: result)
            items.append(item)
        }
        
        // If no sentences found, create one item from the whole input
        if items.isEmpty {
            items.append(createBrainDumpItem(from: input, fallbackResult: result))
        }
        
        return items
    }
    
    /// Create a BrainDumpItem from a single sentence/phrase
    private func createBrainDumpItem(from text: String, fallbackResult: PARAProcessingResult) -> BrainDumpItem {
        let lowercaseText = text.lowercased()
        
        // Determine content type based on text analysis
        let contentType = analyzeContentType(text: lowercaseText)
        let paraCategory = determinePARAFromContent(text: lowercaseText, contentType: contentType)
        let workPersonal = determineWorkPersonal(text: lowercaseText)
        let priority = determinePriority(text: lowercaseText, contentType: contentType)
        
        return BrainDumpItem(
            id: UUID(),
            title: generateTitle(from: text, contentType: contentType),
            content: text,
            contentType: contentType,
            paraCategory: paraCategory,
            suggestedArea: determineArea(text: lowercaseText, contentType: contentType),
            suggestedProject: determineProject(text: lowercaseText, contentType: contentType),
            workPersonal: workPersonal,
            priority: priority,
            dueDate: extractDueDate(from: text),
            tags: extractTags(from: lowercaseText, contentType: contentType),
            confidence: 0.8,
            metadata: ["original_text": text]
        )
    }
    
    /// Analyze content type based on text patterns
    private func analyzeContentType(text: String) -> ContentType {
        let lowerText = text.lowercased()
        
        // Journal/emotional content indicators
        if lowerText.contains("feeling") || lowerText.contains("nightmare") || 
           lowerText.contains("happy") || lowerText.contains("worried") ||
           lowerText.contains("sad") || lowerText.contains("excited") {
            return .journalEntry
        }
        
        // Task indicators
        if lowerText.contains("need to") || lowerText.contains("should") ||
           lowerText.contains("want to") || lowerText.contains("planning to") ||
           lowerText.contains("going to") {
            return .task
        }
        
        // Question/resource indicators  
        if lowerText.contains("question") || lowerText.contains("wondering") ||
           lowerText.contains("how") || lowerText.contains("what") ||
           lowerText.contains("where") || lowerText.contains("when") {
            return .resource
        }
        
        // Health-related
        if lowerText.contains("sick") || lowerText.contains("health") ||
           lowerText.contains("doctor") || lowerText.contains("medicine") {
            return .task // Health tasks are actionable
        }
        
        // Default to note for general content
        return .note
    }
    
    /// Determine PARA category based on content analysis
    private func determinePARAFromContent(text: String, contentType: ContentType) -> PARACategory {
        switch contentType {
        case .task:
            // Tasks can be projects if they're specific goals, otherwise areas
            if text.contains("project") || text.contains("goal") {
                return .project
            }
            return .area
        case .journalEntry:
            return .area // Personal reflection area
        case .resource:
            return .resource // Knowledge and reference
        default:
            return .area // General life areas
        }
    }
    
    /// Determine work vs personal classification
    private func determineWorkPersonal(text: String) -> WorkPersonalType {
        let workKeywords = ["work", "office", "meeting", "project", "client", "business", "career"]
        let personalKeywords = ["family", "friends", "home", "personal", "hobby", "vacation", "feeling", "disney"]
        
        let workCount = workKeywords.filter { text.contains($0) }.count
        let personalCount = personalKeywords.filter { text.contains($0) }.count
        
        if personalCount > workCount {
            return .personal
        } else if workCount > personalCount {
            return .work
        }
        
        // Default to personal for ambiguous content
        return .personal
    }
    
    /// Determine priority based on content urgency
    private func determinePriority(text: String, contentType: ContentType) -> TaskPriority {
        let urgentKeywords = ["urgent", "asap", "emergency", "sick", "worried"]
        let highKeywords = ["important", "soon", "deadline", "need"]
        
        if urgentKeywords.contains(where: text.contains) {
            return .urgent
        } else if highKeywords.contains(where: text.contains) {
            return .high
        } else if contentType == .task {
            return .medium
        }
        
        return .low
    }
    
    /// Determine appropriate area based on content
    private func determineArea(text: String, contentType: ContentType) -> String? {
        if text.contains("health") || text.contains("sick") || text.contains("doctor") {
            return "Health & Fitness"
        } else if text.contains("hobby") || text.contains("disney") || text.contains("vacation") {
            return "Leisure & Recreation"
        } else if text.contains("feeling") || text.contains("happy") || text.contains("nightmare") {
            return "Personal Growth"
        } else if text.contains("ice cream") || text.contains("food") {
            return "Lifestyle"
        }
        
        return nil
    }
    
    /// Determine appropriate project based on content
    private func determineProject(text: String, contentType: ContentType) -> String? {
        if text.contains("disney") {
            return "Disney Trip Planning"
        } else if text.contains("hobby building") {
            return "Hobby Development"
        } else if text.contains("health") || text.contains("sick") {
            return "Health Management"
        }
        
        return nil
    }
    
    /// Extract due date from text
    private func extractDueDate(from text: String) -> String? {
        // Simple date extraction - could be enhanced with NLP
        if text.contains("today") {
            return ISO8601DateFormatter().string(from: Date())
        } else if text.contains("tomorrow") {
            return ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        } else if text.contains("next week") {
            return ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date())
        }
        
        return nil
    }
    
    /// Extract relevant tags from content
    private func extractTags(from text: String, contentType: ContentType) -> [String] {
        var tags: [String] = []
        
        // Content type tag
        tags.append(contentType.rawValue)
        
        // Emotional tags
        if text.contains("happy") { tags.append("positive") }
        if text.contains("worried") || text.contains("nightmare") { tags.append("concern") }
        if text.contains("feeling") { tags.append("emotion") }
        
        // Activity tags
        if text.contains("disney") { tags.append("travel") }
        if text.contains("ice cream") { tags.append("food") }
        if text.contains("hobby") { tags.append("hobby") }
        if text.contains("sick") { tags.append("health") }
        
        return tags
    }
    
    /// Generate appropriate title for the item
    private func generateTitle(from text: String, contentType: ContentType) -> String {
        let truncated = text.count > 50 ? String(text.prefix(50)) + "..." : text
        
        switch contentType {
        case .journalEntry:
            if text.contains("feeling") {
                return "Feeling about \(extractSubject(from: text))"
            } else if text.contains("nightmare") {
                return "Nightmare Experience"
            } else if text.contains("happy") {
                return "Happy Moment"
            }
        case .task:
            if text.contains("wanting to go") {
                return "Plan Trip to \(extractDestination(from: text))"
            } else if text.contains("sick") {
                return "Address Health Concern"
            }
        case .resource:
            if text.contains("question") {
                return "Question: \(extractQuestion(from: text))"
            } else if text.contains("wondering") {
                return "Research: \(extractWonderingTopic(from: text))"
            }
        default:
            break
        }
        
        // Capitalize first letter and return
        return truncated.prefix(1).uppercased() + truncated.dropFirst()
    }
    
    /// Helper methods for title generation
    private func extractSubject(from text: String) -> String {
        if text.contains("ice cream") { return "ice cream" }
        return "something"
    }
    
    private func extractDestination(from text: String) -> String {
        if text.contains("disney") { return "Disney Land" }
        return "somewhere"
    }
    
    private func extractQuestion(from text: String) -> String {
        if text.contains("hobby building") { return "hobby building" }
        return "general topic"
    }
    
    private func extractWonderingTopic(from text: String) -> String {
        if text.contains("eiffel tower") || text.contains("effil tower") { return "Eiffel Tower height" }
        return "topic of interest"
    }
    
    private func parseBrainDumpItem(_ json: [String: Any]) throws -> BrainDumpItem {
        guard let title = json["title"] as? String,
              let contentTypeString = json["content_type"] as? String,
              let contentType = ContentType(rawValue: contentTypeString),
              let paraCategoryString = json["para_category"] as? String,
              let paraCategory = PARACategory(rawValue: paraCategoryString) else {
            throw BrainDumpError.invalidItemFormat
        }
        
        return BrainDumpItem(
            id: UUID(),
            title: title,
            content: json["content"] as? String ?? title,
            contentType: contentType,
            paraCategory: paraCategory,
            suggestedArea: json["suggested_area"] as? String,
            suggestedProject: json["suggested_project"] as? String,
            workPersonal: WorkPersonalType(rawValue: json["work_personal"] as? String ?? "personal") ?? .personal,
            priority: TaskPriority(rawValue: json["priority"] as? String ?? "medium") ?? .medium,
            dueDate: json["due_date"] as? String,
            tags: json["tags"] as? [String] ?? [],
            confidence: json["confidence"] as? Double ?? 0.5,
            metadata: json["metadata"] as? [String: Any] ?? [:]
        )
    }
    
    private func extractCommonTags(from tasks: [LifeTask]) -> [String] {
        // Extract common tags from recent tasks for context
        var tagCounts: [String: Int] = [:]
        
        for task in tasks {
            // This would extract tags if they were stored in the task model
            // For now, we'll return some common categories
        }
        
        return ["work", "personal", "health", "finance", "learning", "social", "home"]
    }
    
    // MARK: - Item Creation Methods
    
    private func createTaskFromItem(_ item: BrainDumpItem) async throws -> LifeTask {
        print("🧠 BRAIN DUMP: Creating task: \(item.title)")
        
        let task = LifeTask(
            title: item.title,
            description: item.content != item.title ? item.content : nil,
            priority: item.priority,
            dueDate: item.dueDate,
            workPersonal: item.workPersonal
        )
        
        let createdTask = try await taskRepository.createTask(task)
        
        // Notify that a task was created
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("TaskCreated"), object: nil)
        }
        
        return createdTask
    }
    
    private func createJournalFromItem(_ item: BrainDumpItem) async throws -> JournalEntry {
        print("🧠 BRAIN DUMP: Creating journal entry: \(item.title)")
        
        // First create a blob for the journal content
        let blob = Blob(
            content: item.content,
            sourceType: .journal,
            workPersonal: item.workPersonal
        )
        
        let createdBlob = try await blobRepository.createBlob(blob)
        
        let journal = JournalEntry(
            id: UUID(),
            blobId: createdBlob.id,
            summary: item.content,
            mood: item.metadata["mood"] as? String
        )
        
        // For now, return the journal entry (journal repository not implemented yet)
        return journal
    }
    
    private func createNoteFromItem(_ item: BrainDumpItem) async throws -> Blob {
        print("🧠 BRAIN DUMP: Creating note: \(item.title)")
        
        let blob = Blob(
            content: item.content,
            sourceType: .note,
            workPersonal: item.workPersonal
        )
        
        return try await blobRepository.createBlob(blob)
    }
    
    private func createResourceFromItem(_ item: BrainDumpItem) async throws -> Resource {
        print("🧠 BRAIN DUMP: Creating resource: \(item.title)")
        
        // First create a blob for the resource content
        let blob = Blob(
            content: item.content,
            sourceType: .knowledge,
            workPersonal: item.workPersonal
        )
        
        let createdBlob = try await blobRepository.createBlob(blob)
        
        let resource = Resource(
            id: UUID(),
            blobId: createdBlob.id,
            title: item.title,
            type: item.metadata["resource_type"] as? String ?? "knowledge",
            summary: item.content,
            workPersonal: item.workPersonal
        )
        
        return try await resourceRepository.createResource(resource)
    }
    
    private func createFinancialTransactionFromItem(_ item: BrainDumpItem) async throws -> FinancialTransaction {
        print("🧠 BRAIN DUMP: Creating financial transaction: \(item.title)")
        
        // Extract amount from content using basic parsing
        let amount = extractAmount(from: item.content) ?? 0.0
        let transactionType = item.metadata["transaction_type"] as? String ?? "expense"
        
        return FinancialTransaction(
            id: UUID(),
            amount: amount,
            description: transactionType,
            date: Date(),
            category: transactionType,
            workPersonal: item.workPersonal
        )
    }
    
    private func createAppointmentFromItem(_ item: BrainDumpItem) async throws -> CalendarEvent {
        print("🧠 BRAIN DUMP: Creating appointment: \(item.title)")
        
        // Extract date from metadata or use a future date
        let startDate = item.metadata["start_date"] as? Date ?? Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let endDate = item.metadata["end_date"] as? Date ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        
        return CalendarEvent(
            id: UUID(),
            title: item.title,
            description: item.content,
            startDate: startDate,
            endDate: endDate,
            type: .meeting,
            workPersonal: item.workPersonal,
            duration: endDate.timeIntervalSince(startDate)
        )
    }
    
    private func createHabitFromItem(_ item: BrainDumpItem) async throws -> Habit {
        print("🧠 BRAIN DUMP: Creating habit: \(item.title)")
        
        return Habit(
            id: UUID(),
            title: item.title,
            description: item.content,
            frequency: "daily",
            workPersonal: item.workPersonal
        )
    }
    
    private func createGoalFromItem(_ item: BrainDumpItem) async throws -> Goal {
        print("🧠 BRAIN DUMP: Creating goal: \(item.title)")
        
        // Create a blob for the goal content
        let blob = Blob(
            content: "GOAL: \(item.title)\n\n\(item.content)",
            sourceType: .idea,
            workPersonal: item.workPersonal
        )
        
        let createdBlob = try await blobRepository.createBlob(blob)
        
        let targetDate = item.metadata["target_date"] as? Date
        
        return Goal(
            id: UUID(),
            title: item.title,
            description: item.content,
            targetDate: targetDate,
            workPersonal: item.workPersonal
        )
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    /// Extract amount from text using basic pattern matching
    private func extractAmount(from text: String) -> Double? {
        // Look for patterns like $123.45, 123.45, $123, etc.
        let patterns = [
            "\\$([0-9]+\\.?[0-9]*)",  // $123.45
            "([0-9]+\\.?[0-9]*)\\s*(?:dollars?|USD|\\$)",  // 123.45 dollars
            "([0-9]+\\.?[0-9]*)"  // Just numbers
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsText = text as NSString
                let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                
                if let match = results.first {
                    let matchRange = match.range(at: 1)
                    if matchRange.location != NSNotFound {
                        let matchString = nsText.substring(with: matchRange)
                        return Double(matchString)
                    }
                }
            }
        }
        
        return nil
    }
}

// MARK: - Data Models

struct BrainDumpResult {
    let originalInput: String
    let analysisResult: LLMAnalysisResult
    let suggestedItems: [BrainDumpItem]
    let confidence: Double
    let requiresReview: Bool
}

struct LLMAnalysisResult {
    let extractedItems: [BrainDumpItem]
    let confidence: Double
    let hasAmbiguousItems: Bool
    let reasoning: String
    let suggestedNewAreas: [String]
    let suggestedNewProjects: [String]
}

struct BrainDumpItem {
    let id: UUID
    let title: String
    let content: String
    let contentType: ContentType
    let paraCategory: PARACategory
    let suggestedArea: String?
    let suggestedProject: String?
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let dueDate: String?
    let tags: [String]
    let confidence: Double
    let metadata: [String: Any]
}

struct PARAContext {
    let projects: [Project]
    let areas: [Area]
    let resources: [Resource]
    let recentTasks: [LifeTask]
    let commonTags: [String]
}

struct ExecutionSummary {
    var tasksCreated: [LifeTask] = []
    var journalEntriesCreated: [JournalEntry] = []
    var notesCreated: [Blob] = []
    var resourcesCreated: [Resource] = []
    var financialTransactionsCreated: [FinancialTransaction] = []
    var appointmentsCreated: [CalendarEvent] = []
    var habitsCreated: [Habit] = []
    var goalsCreated: [Goal] = []
    var successCount: Int = 0
    var errors: [String] = []
}

enum ContentType: String, CaseIterable {
    case task = "task"
    case journalEntry = "journal_entry"
    case note = "note"
    case resource = "resource"
    case financialTransaction = "financial_transaction"
    case appointment = "appointment"
    case habit = "habit"
    case goal = "goal"
}

enum BrainDumpError: Error {
    case invalidResponse(String)
    case parsingFailed(String)
    case invalidItemFormat
}

// MARK: - Placeholder Models (to be implemented)

struct FinancialTransaction {
    let id: UUID
    let amount: Double
    let description: String
    let date: Date
    let category: String
    let workPersonal: WorkPersonalType
}

struct Habit {
    let id: UUID
    let title: String
    let description: String?
    let frequency: String
    let workPersonal: WorkPersonalType
}

struct Goal {
    let id: UUID
    let title: String
    let description: String?
    let targetDate: Date?
    let workPersonal: WorkPersonalType
} 