import Foundation

/// Enhanced Brain Dump Processor using OpenAI o1 reasoning and structured outputs
/// Capable of processing complex notes with medical data, schedules, rules, and goals
class EnhancedBrainDumpProcessor: ObservableObject {
    
    // MARK: - Properties
    private let llmService: LLMService
    private let embeddingsService: EmbeddingsService
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // Processing state
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingStage = ""
    
    // MARK: - Initialization
    init() {
        self.llmService = LLMService()
        self.embeddingsService = EmbeddingsService.shared
    }
    
    // MARK: - Main Processing Method
    func processComplexNotes(_ input: String) async throws -> ComplexBrainDumpResult {
        logger.info("ENHANCED_PROCESSOR: Starting complex note processing")
        isProcessing = true
        processingProgress = 0.0
        
        defer { 
            Task { @MainActor in
                self.isProcessing = false
            }
        }
        
        // Stage 1: Pre-process and segment the input
        processingStage = "Segmenting input..."
        processingProgress = 0.1
        let segments = await segmentInput(input)
        logger.debug("ENHANCED_PROCESSOR: Segmented into \(segments.count) parts")
        
        // Stage 2: Use o1 reasoning for deep analysis
        processingStage = "Analyzing with o1 reasoning..."
        processingProgress = 0.3
        let analysisResult = try await performO1Analysis(segments)
        
        // Stage 3: Extract structured data using GPT-4 with structured outputs
        processingStage = "Extracting structured data..."
        processingProgress = 0.5
        let structuredData = try await extractStructuredData(analysisResult)
        
        // Stage 4: Generate embeddings for semantic matching
        processingStage = "Generating embeddings..."
        processingProgress = 0.7
        let embeddings = try await generateEmbeddings(for: structuredData)
        
        // Stage 5: Cross-reference and link related items
        processingStage = "Linking related items..."
        processingProgress = 0.85
        let linkedData = await linkRelatedItems(structuredData, embeddings: embeddings)
        
        // Stage 6: Prepare final result
        processingStage = "Finalizing..."
        processingProgress = 0.95
        let result = await prepareFinalResult(linkedData, originalInput: input)
        
        processingProgress = 1.0
        logger.success("ENHANCED_PROCESSOR: Processing complete with \(result.totalItemsExtracted) items")
        
        return result
    }
    
    // MARK: - Stage 1: Input Segmentation
    private func segmentInput(_ input: String) async -> [InputSegment] {
        var segments: [InputSegment] = []
        
        // Detect different sections based on patterns
        let lines = input.components(separatedBy: .newlines)
        var currentSegment = InputSegment(type: .general, content: "")
        var currentType: SegmentType = .general
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // Detect segment type changes
            let detectedType = detectSegmentType(trimmed)
            
            if detectedType != currentType && !currentSegment.content.isEmpty {
                segments.append(currentSegment)
                currentSegment = InputSegment(type: detectedType, content: trimmed)
                currentType = detectedType
            } else {
                currentSegment.content += "\n" + trimmed
            }
        }
        
        if !currentSegment.content.isEmpty {
            segments.append(currentSegment)
        }
        
        return segments
    }
    
    private func detectSegmentType(_ text: String) -> SegmentType {
        let lower = text.lowercased()
        
        if lower.contains("schedule") || lower.contains("routine") || text.contains(":") && text.contains("-") {
            return .schedule
        } else if lower.contains("dr") || lower.contains("appt") || lower.contains("mctd") || lower.contains("medication") || lower.contains("symptom") {
            return .medical
        } else if lower.contains("rule") || lower.contains("restriction") || lower.contains("no ") || lower.contains("don't") {
            return .rules
        } else if lower.contains("goal") || lower.contains("target") || lower.contains("by ") && (lower.contains("2025") || lower.contains("2026")) {
            return .goals
        } else if lower.contains("$") || lower.contains("expense") || lower.contains("budget") || lower.contains("cost") {
            return .financial
        } else if lower.contains("grocery") || lower.contains("buy") || lower.contains("shop") {
            return .shopping
        } else if lower.contains("feeling") || lower.contains("emotion") || lower.contains("overwhelmed") {
            return .journal
        } else {
            return .general
        }
    }
    
    // MARK: - Stage 2: O1 Reasoning Analysis
    private func performO1Analysis(_ segments: [InputSegment]) async throws -> O1AnalysisResult {
        let systemPrompt = getO1SystemPrompt()
        let userPrompt = buildO1UserPrompt(segments)
        
        // Use o1 model with reasoning effort
        let response = try await llmService.performO1Reasoning(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            reasoningEffort: "high", // Maximum reasoning for complex notes
            responseFormat: .json
        )
        
        // Parse the o1 response
        guard let data = response.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(O1AnalysisResult.self, from: data) else {
            throw ProcessingError.invalidO1Response
        }
        
        return analysis
    }
    
    private func getO1SystemPrompt() -> String {
        return """
        You are an expert life management assistant specialized in parsing complex personal notes.
        Your role is to deeply understand and structure unorganized information into actionable items.
        
        You excel at:
        1. Medical information extraction (conditions, symptoms, medications, appointments)
        2. Schedule and routine parsing (time blocks, recurring patterns)
        3. Personal rules and restrictions (date-bounded, conditional logic)
        4. Goal identification with milestones and dependencies
        5. Financial tracking and budgeting
        6. Relationship and contact management
        7. Emotional state and journal entries
        
        Use your reasoning capability to:
        - Infer connections between items
        - Detect temporal relationships
        - Identify dependencies and priorities
        - Recognize patterns and habits
        - Extract implicit deadlines and constraints
        """
    }
    
    private func buildO1UserPrompt(_ segments: [InputSegment]) -> String {
        var prompt = "Analyze the following personal notes and extract all actionable information:\n\n"
        
        for segment in segments {
            prompt += "[\(segment.type.rawValue.uppercased()) SECTION]\n"
            prompt += segment.content + "\n\n"
        }
        
        prompt += """
        
        Return a comprehensive JSON analysis with:
        1. All extracted items categorized by type
        2. Identified relationships and dependencies
        3. Temporal constraints and schedules
        4. Priority rankings based on urgency and importance
        5. Suggested PARA categorization for each item
        6. Confidence scores for ambiguous items
        """
        
        return prompt
    }
    
    // MARK: - Stage 3: Structured Data Extraction
    private func extractStructuredData(_ analysis: O1AnalysisResult) async throws -> StructuredBrainDumpData {
        // Use GPT-4 with structured outputs for reliable JSON
        let response = try await llmService.extractWithStructuredOutput(
            input: analysis,
            schema: StructuredBrainDumpData.schema
        )
        
        guard let data = response.data(using: .utf8),
              let structured = try? JSONDecoder().decode(StructuredBrainDumpData.self, from: data) else {
            throw ProcessingError.structuredExtractionFailed
        }
        
        return structured
    }
    
    // MARK: - Stage 4: Embeddings Generation
    private func generateEmbeddings(for data: StructuredBrainDumpData) async throws -> [ItemEmbedding] {
        var embeddings: [ItemEmbedding] = []
        
        // Generate embeddings for each item
        for item in data.allItems {
            let text = item.getEmbeddingText()
            let embedding = try await embeddingsService.generateEmbedding(for: text)
            embeddings.append(ItemEmbedding(itemId: item.id, embedding: embedding))
        }
        
        return embeddings
    }
    
    // MARK: - Stage 5: Link Related Items
    private func linkRelatedItems(_ data: StructuredBrainDumpData, embeddings: [ItemEmbedding]) async -> StructuredBrainDumpData {
        var linkedData = data
        
        // Find similar items using embeddings
        for i in 0..<embeddings.count {
            for j in (i+1)..<embeddings.count {
                let similarity = cosineSimilarity(embeddings[i].embedding, embeddings[j].embedding)
                if similarity > 0.8 { // High similarity threshold
                    linkedData.addRelationship(from: embeddings[i].itemId, to: embeddings[j].itemId, strength: similarity)
                }
            }
        }
        
        return linkedData
    }
    
    // MARK: - Stage 6: Prepare Final Result
    private func prepareFinalResult(_ data: StructuredBrainDumpData, originalInput: String) async -> ComplexBrainDumpResult {
        return ComplexBrainDumpResult(
            originalInput: originalInput,
            structuredData: data,
            processingMetadata: ProcessingMetadata(
                model: "o1-reasoning + gpt-4-structured",
                processingTime: Date(),
                confidence: data.overallConfidence,
                itemsExtracted: data.totalItems
            ),
            requiresReview: data.hasAmbiguousItems
        )
    }
    
    // MARK: - Database Operations
    func saveToDatabase(_ result: ComplexBrainDumpResult) async throws {
        logger.info("ENHANCED_PROCESSOR: Saving \(result.totalItemsExtracted) items to database")
        
        // Save each type of item to appropriate table
        for healthLog in result.structuredData.healthLogs {
            try await supabaseService.insert(healthLog, into: "health_logs")
        }
        
        for medication in result.structuredData.medications {
            try await supabaseService.insert(medication, into: "medication_tracking")
        }
        
        for rule in result.structuredData.personalRules {
            try await supabaseService.insert(rule, into: "personal_rules")
        }
        
        for goal in result.structuredData.goals {
            try await supabaseService.insert(goal, into: "goals")
        }
        
        for schedule in result.structuredData.schedules {
            try await supabaseService.insert(schedule, into: "schedules")
        }
        
        for appointment in result.structuredData.appointments {
            try await supabaseService.insert(appointment, into: "appointments")
        }
        
        // Save processing record
        let processingRecord = ProcessedNote(
            originalText: result.originalInput,
            itemsExtracted: result.totalItemsExtracted,
            processingModel: "o1-reasoning",
            confidenceScore: result.structuredData.overallConfidence,
            categoriesFound: result.structuredData.categoriesFound,
            entitiesExtracted: result.structuredData.entities,
            relationships: result.structuredData.relationships
        )
        
        try await supabaseService.insert(processingRecord, into: "processed_notes")
        
        logger.success("ENHANCED_PROCESSOR: All items saved successfully")
    }
    
    // MARK: - Helper Methods
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// MARK: - Supporting Types

enum SegmentType: String {
    case general, medical, schedule, rules, goals, financial, shopping, journal
}

struct InputSegment {
    let type: SegmentType
    var content: String
}

struct O1AnalysisResult: Codable {
    let items: [AnalyzedItem]
    let relationships: [ItemRelationship]
    let temporalConstraints: [TemporalConstraint]
    let priorities: [PriorityRanking]
    let confidence: Double
}

struct AnalyzedItem: Codable {
    let id: String
    let content: String
    let type: String
    let paraCategory: String
    let metadata: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case id, content, type, paraCategory, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(String.self, forKey: .type)
        paraCategory = try container.decode(String.self, forKey: .paraCategory)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(paraCategory, forKey: .paraCategory)
        // Simplified encoding for metadata
    }
}

struct ItemRelationship: Codable {
    let fromId: String
    let toId: String
    let relationshipType: String
    let strength: Double
}

struct TemporalConstraint: Codable {
    let itemId: String
    let startDate: Date?
    let endDate: Date?
    let recurrence: String?
}

struct PriorityRanking: Codable {
    let itemId: String
    let priority: Int
    let urgency: Int
    let importance: Int
}

struct StructuredBrainDumpData: Codable {
    var healthLogs: [HealthLog] = []
    var medications: [MedicationTracking] = []
    var personalRules: [EnhancedPersonalRule] = []
    var goals: [EnhancedGoal] = []
    var schedules: [Schedule] = []
    var appointments: [Appointment] = []
    var tasks: [Task] = []
    var notes: [Note] = []
    var journalEntries: [EnhancedJournalEntry] = []
    var financialEntries: [EnhancedFinancialEntry] = []
    var contacts: [Contact] = []
    
    var relationships: [ItemRelationship] = []
    var entities: [String: Any] = [:]
    var categoriesFound: [String] = []
    var overallConfidence: Double = 0.0
    var hasAmbiguousItems: Bool = false
    
    var totalItems: Int {
        healthLogs.count + medications.count + personalRules.count + goals.count +
        schedules.count + appointments.count + tasks.count + notes.count +
        journalEntries.count + financialEntries.count + contacts.count
    }
    
    var allItems: [any EnhancedBrainDumpItem] {
        var items: [any EnhancedBrainDumpItem] = []
        items.append(contentsOf: healthLogs)
        items.append(contentsOf: medications)
        items.append(contentsOf: personalRules)
        items.append(contentsOf: goals)
        items.append(contentsOf: schedules)
        items.append(contentsOf: appointments)
        items.append(contentsOf: tasks)
        items.append(contentsOf: notes)
        items.append(contentsOf: journalEntries)
        items.append(contentsOf: financialEntries)
        items.append(contentsOf: contacts)
        return items
    }
    
    mutating func addRelationship(from: String, to: String, strength: Double) {
        relationships.append(ItemRelationship(
            fromId: from,
            toId: to,
            relationshipType: "similar",
            strength: strength
        ))
    }
    
    static var schema: String {
        return """
        {
            "type": "object",
            "properties": {
                "healthLogs": { "type": "array", "items": { "$ref": "#/definitions/HealthLog" } },
                "medications": { "type": "array", "items": { "$ref": "#/definitions/MedicationTracking" } },
                "personalRules": { "type": "array", "items": { "$ref": "#/definitions/PersonalRule" } },
                "goals": { "type": "array", "items": { "$ref": "#/definitions/Goal" } },
                "schedules": { "type": "array", "items": { "$ref": "#/definitions/Schedule" } },
                "appointments": { "type": "array", "items": { "$ref": "#/definitions/Appointment" } },
                "tasks": { "type": "array", "items": { "$ref": "#/definitions/Task" } },
                "notes": { "type": "array", "items": { "$ref": "#/definitions/Note" } },
                "journalEntries": { "type": "array", "items": { "$ref": "#/definitions/JournalEntry" } },
                "financialEntries": { "type": "array", "items": { "$ref": "#/definitions/FinancialEntry" } },
                "contacts": { "type": "array", "items": { "$ref": "#/definitions/Contact" } }
            }
        }
        """
    }
}

struct ItemEmbedding {
    let itemId: String
    let embedding: [Float]
}

struct ComplexBrainDumpResult {
    let originalInput: String
    let structuredData: StructuredBrainDumpData
    let processingMetadata: ProcessingMetadata
    let requiresReview: Bool
    
    var totalItemsExtracted: Int {
        structuredData.totalItems
    }
}

struct ProcessingMetadata {
    let model: String
    let processingTime: Date
    let confidence: Double
    let itemsExtracted: Int
}

struct ProcessedNote: Codable {
    let originalText: String
    let itemsExtracted: Int
    let processingModel: String
    let confidenceScore: Double
    let categoriesFound: [String]
    let entitiesExtracted: [String: Any]
    let relationships: [ItemRelationship]
}

// Protocol for all brain dump items
protocol EnhancedBrainDumpItem: Codable {
    var id: String { get }
    func getEmbeddingText() -> String
}

// Placeholder model structs (extend with full implementations)
struct HealthLog: EnhancedBrainDumpItem, Codable {
    let id: String
    let condition: String
    let symptoms: [String]
    let severity: Int?
    let medications: [String]?
    let notes: String?
    
    init(id: String = UUID().uuidString, condition: String, symptoms: [String], severity: Int? = nil, medications: [String]? = nil, notes: String? = nil) {
        self.id = id
        self.condition = condition
        self.symptoms = symptoms
        self.severity = severity
        self.medications = medications
        self.notes = notes
    }
    
    func getEmbeddingText() -> String {
        return "Health: \(condition) with symptoms: \(symptoms.joined(separator: ", "))"
    }
}

struct MedicationTracking: EnhancedBrainDumpItem, Codable {
    let id: String
    let name: String
    let dosage: String
    let frequency: String?
    let startDate: Date?
    let endDate: Date?
    
    init(id: String = UUID().uuidString, name: String, dosage: String, frequency: String? = nil, startDate: Date? = nil, endDate: Date? = nil) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
    }
    
    func getEmbeddingText() -> String {
        return "Medication: \(name) \(dosage)"
    }
}

struct EnhancedPersonalRule: EnhancedBrainDumpItem, Codable {
    let id: String
    let ruleText: String
    let ruleType: String?
    let priority: Int?
    let startDate: Date?
    let endDate: Date?
    
    init(id: String = UUID().uuidString, ruleText: String, ruleType: String? = nil, priority: Int? = nil, startDate: Date? = nil, endDate: Date? = nil) {
        self.id = id
        self.ruleText = ruleText
        self.ruleType = ruleType
        self.priority = priority
        self.startDate = startDate
        self.endDate = endDate
    }
    
    func getEmbeddingText() -> String {
        return "Rule: \(ruleText)"
    }
}

struct EnhancedGoal: EnhancedBrainDumpItem, Codable {
    let id: String
    let title: String
    let description: String?
    let targetDate: Date?
    let category: String?
    let progress: Int?
    
    init(id: String = UUID().uuidString, title: String, description: String? = nil, targetDate: Date? = nil, category: String? = nil, progress: Int? = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.category = category
        self.progress = progress
    }
    
    func getEmbeddingText() -> String {
        return "Goal: \(title)"
    }
}

struct Schedule: EnhancedBrainDumpItem, Codable {
    let id: String
    let title: String
    let timeBlocks: [[String: String]]
    let scheduleType: String?
    let recurrencePattern: String?
    
    init(id: String = UUID().uuidString, title: String, timeBlocks: [[String: String]], scheduleType: String? = nil, recurrencePattern: String? = nil) {
        self.id = id
        self.title = title
        self.timeBlocks = timeBlocks
        self.scheduleType = scheduleType
        self.recurrencePattern = recurrencePattern
    }
    
    func getEmbeddingText() -> String {
        return "Schedule: \(title)"
    }
}

struct Appointment: EnhancedBrainDumpItem, Codable {
    let id: String
    let title: String
    let date: Date?
    let appointmentType: String?
    let location: String?
    let notes: String?
    
    init(id: String = UUID().uuidString, title: String, date: Date? = nil, appointmentType: String? = nil, location: String? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.appointmentType = appointmentType
        self.location = location
        self.notes = notes
    }
    
    func getEmbeddingText() -> String {
        return "Appointment: \(title)"
    }
}

struct Note: EnhancedBrainDumpItem, Codable {
    let id: String
    let content: String
    let category: String?
    let tags: [String]?
    
    init(id: String = UUID().uuidString, content: String, category: String? = nil, tags: [String]? = nil) {
        self.id = id
        self.content = content
        self.category = category
        self.tags = tags
    }
    
    func getEmbeddingText() -> String {
        return content
    }
}

struct Contact: EnhancedBrainDumpItem, Codable {
    let id: String
    let name: String
    let relationship: String?
    let phone: String?
    let email: String?
    let notes: String?
    
    init(id: String = UUID().uuidString, name: String, relationship: String? = nil, phone: String? = nil, email: String? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.email = email
        self.notes = notes
    }
    
    func getEmbeddingText() -> String {
        return "Contact: \(name) (\(relationship ?? "unknown"))"
    }
}

struct EnhancedJournalEntry: EnhancedBrainDumpItem, Codable {
    let id: String
    let content: String
    let mood: String?
    let date: Date?
    
    init(id: String = UUID().uuidString, content: String, mood: String? = nil, date: Date? = nil) {
        self.id = id
        self.content = content
        self.mood = mood
        self.date = date
    }
    
    func getEmbeddingText() -> String {
        return "Journal: \(content)"
    }
}

struct EnhancedFinancialEntry: EnhancedBrainDumpItem, Codable {
    let id: String
    let description: String
    let amount: Double?
    let category: String?
    let date: Date?
    
    init(id: String = UUID().uuidString, description: String, amount: Double? = nil, category: String? = nil, date: Date? = nil) {
        self.id = id
        self.description = description
        self.amount = amount
        self.category = category
        self.date = date
    }
    
    func getEmbeddingText() -> String {
        return "Financial: \(description)"
    }
}

enum ProcessingError: Error {
    case invalidO1Response
    case structuredExtractionFailed
    case embeddingGenerationFailed
    case databaseSaveFailed
}