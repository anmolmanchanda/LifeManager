import Foundation

/// Repository for managing personal PARA rules and user corrections
class PersonalRulesRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - Personal Rules CRUD
    
    /// Save a personal rule to database
    func createPersonalRule(_ rule: PersonalPARARule) async throws -> PersonalPARARule {
        do {
            // Convert to database model
            let ruleData = PersonalPARARuleData(
                id: rule.id,
                pattern: rule.pattern,
                targetCategory: rule.targetClassification.category.rawValue,
                targetSubcategory: rule.targetClassification.subcategory,
                confidence: rule.confidence,
                description: rule.description,
                ruleType: rule.ruleType.rawValue,
                createdFromCorrections: rule.createdFrom.count,
                usageCount: rule.usageCount,
                isActive: rule.isActive,
                metadata: try JSONEncoder().encode(rule.metadata),
                createdAt: rule.createdAt,
                lastUsed: rule.lastUsed,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            let savedRule: PersonalPARARuleData = try await supabaseService.insert(
                ruleData,
                into: "personal_para_rules"
            )
            
            logger.success("PERSONAL_RULES_REPO: Created personal rule: \(rule.pattern)")
            return try convertToPersonalRule(savedRule)
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to create personal rule: \(error)")
            throw error
        }
    }
    
    /// Load all personal rules for a user
    func fetchPersonalRules(userId: String) async throws -> [PersonalPARARule] {
        do {
            let response: [PersonalPARARuleData] = try await supabaseService.client
                .from("personal_para_rules")
                .select()
                .eq("user_id", value: userId)
                .order("confidence", ascending: false)
                .execute()
                .value
            
            let rules = try response.compactMap { try convertToPersonalRule($0) }
            
            logger.success("PERSONAL_RULES_REPO: Loaded \(rules.count) personal rules for user \(userId)")
            return rules
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to load personal rules: \(error)")
            throw error
        }
    }
    
    /// Update personal rule confidence and usage
    func updatePersonalRule(_ rule: PersonalPARARule) async throws -> PersonalPARARule {
        do {
            let updateData: [String: Any] = [
                "confidence": rule.confidence,
                "usage_count": rule.usageCount,
                "is_active": rule.isActive,
                "last_used": rule.lastUsed?.ISO8601Format() ?? NSNull(),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabaseService.client
                .from("personal_para_rules")
                .update(updateData)
                .eq("id", value: rule.id.uuidString)
                .execute()
            
            logger.success("PERSONAL_RULES_REPO: Updated personal rule: \(rule.pattern)")
            return rule
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to update personal rule: \(error)")
            throw error
        }
    }
    
    /// Delete a personal rule
    func deletePersonalRule(id: UUID) async throws {
        do {
            try await supabaseService.client
                .from("personal_para_rules")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            
            logger.success("PERSONAL_RULES_REPO: Deleted personal rule \(id)")
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to delete personal rule: \(error)")
            throw error
        }
    }
    
    /// Fetch rules applicable to a specific task
    func fetchApplicableRules(for task: LifeTask, userId: String) async throws -> [PersonalPARARule] {
        do {
            // Get all active rules for the user
            let allRules = try await fetchPersonalRules(userId: userId)
            
            // Filter rules that apply to this task
            let applicableRules = allRules.filter { rule in
                rule.isActive && rule.appliesTo(task)
            }
            
            logger.debug("PERSONAL_RULES_REPO: Found \(applicableRules.count) applicable rules for task: \(task.title)")
            return applicableRules
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to fetch applicable rules: \(error)")
            throw error
        }
    }
    
    // MARK: - User Corrections CRUD
    
    /// Save a user correction to database
    func createUserCorrection(_ correction: UserCorrection) async throws -> UserCorrection {
        do {
            let correctionData = UserCorrectionData(
                id: correction.id,
                userId: getCurrentUserId(),
                originalItemId: correction.originalItemId,
                originalCategory: correction.originalItem.paraClassification.category.rawValue,
                originalSubcategory: correction.originalItem.paraClassification.subcategory,
                correctedCategory: correction.correctedClassification.category.rawValue,
                correctedSubcategory: correction.correctedClassification.subcategory,
                userFeedback: correction.userFeedback,
                confidence: correction.confidence,
                reasoning: correction.reasoning,
                correctionType: correction.correctionType,
                metadata: try JSONEncoder().encode(correction.metadata),
                createdAt: correction.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            let _: UserCorrectionData = try await supabaseService.insert(
                correctionData,
                into: "user_corrections"
            )
            
            logger.success("PERSONAL_RULES_REPO: Created user correction for item \(correction.originalItemId)")
            return correction
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to create user correction: \(error)")
            throw error
        }
    }
    
    /// Load user corrections for analysis
    func fetchUserCorrections(userId: String, limit: Int = 100) async throws -> [UserCorrection] {
        do {
            let response: [UserCorrectionData] = try await supabaseService.client
                .from("user_corrections")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            let corrections = try response.compactMap { try convertToUserCorrection($0) }
            
            logger.success("PERSONAL_RULES_REPO: Loaded \(corrections.count) user corrections for user \(userId)")
            return corrections
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to load user corrections: \(error)")
            throw error
        }
    }
    
    /// Fetch corrections for a specific pattern
    func fetchCorrectionsForPattern(_ pattern: String, userId: String) async throws -> [UserCorrection] {
        do {
            // For now, filter in memory - could be optimized with database queries
            let allCorrections = try await fetchUserCorrections(userId: userId, limit: 500)
            
            let matchingCorrections = allCorrections.filter { correction in
                correction.originalItem.originalItem.content.lowercased().contains(pattern.lowercased())
            }
            
            logger.debug("PERSONAL_RULES_REPO: Found \(matchingCorrections.count) corrections for pattern: \(pattern)")
            return matchingCorrections
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to fetch corrections for pattern: \(error)")
            throw error
        }
    }
    
    // MARK: - Rule Effectiveness Tracking
    
    /// Save rule effectiveness data
    func saveRuleEffectiveness(_ effectiveness: RuleEffectiveness) async throws {
        do {
            let effectivenessData = RuleEffectivenessData(
                id: UUID(),
                ruleId: effectiveness.rule.id,
                successRate: effectiveness.successRate,
                confidenceImprovement: effectiveness.averageConfidenceImprovement,
                timesSaved: effectiveness.timesSaved,
                lastImpact: effectiveness.lastImpact,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            let _: RuleEffectivenessData = try await supabaseService.insert(
                effectivenessData,
                into: "rule_effectiveness"
            )
            
            logger.debug("PERSONAL_RULES_REPO: Saved effectiveness data for rule \(effectiveness.rule.id)")
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to save rule effectiveness: \(error)")
            throw error
        }
    }
    
    /// Clean up old corrections based on retention policy
    func cleanupOldCorrections(retentionDays: Int = 180) async throws {
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
            let cutoffString = ISO8601DateFormatter().string(from: cutoffDate)
            
            try await supabaseService.client
                .from("user_corrections")
                .delete()
                .lt("created_at", value: cutoffString)
                .execute()
            
            logger.info("PERSONAL_RULES_REPO: Cleaned up old corrections older than \(retentionDays) days")
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to cleanup old corrections: \(error)")
            throw error
        }
    }
    
    /// Clean up inactive rules based on expiration policy
    func cleanupInactiveRules(expirationDays: Int = 90) async throws {
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -expirationDays, to: Date()) ?? Date()
            let cutoffString = ISO8601DateFormatter().string(from: cutoffDate)
            
            try await supabaseService.client
                .from("personal_para_rules")
                .delete()
                .eq("is_active", value: false)
                .or("last_used.is.null,last_used.lt.\(cutoffString)")
                .lt("confidence", value: 0.3)
                .execute()
            
            logger.info("PERSONAL_RULES_REPO: Cleaned up inactive rules older than \(expirationDays) days")
            
        } catch {
            logger.error("PERSONAL_RULES_REPO: Failed to cleanup inactive rules: \(error)")
            throw error
        }
    }
    
    // MARK: - Conversion Helpers
    
    /// Convert database model to domain model
    private func convertToPersonalRule(_ data: PersonalPARARuleData) throws -> PersonalPARARule {
        let metadata = try JSONDecoder().decode([String: String].self, from: data.metadata)
        
        guard let ruleType = PersonalPARARule.RuleType(rawValue: data.ruleType),
              let category = PARACategory(rawValue: data.targetCategory) else {
            throw RepositoryError.invalidData("Invalid rule type or category")
        }
        
        let targetClassification = PARAClassification(
            category: category,
            subcategory: data.targetSubcategory
        )
        
        return PersonalPARARule(
            id: data.id,
            pattern: data.pattern,
            targetClassification: targetClassification,
            confidence: data.confidence,
            description: data.description,
            ruleType: ruleType,
            createdFrom: [], // Would need to reconstruct from related corrections
            createdAt: data.createdAt,
            lastUsed: data.lastUsed,
            usageCount: data.usageCount,
            isActive: data.isActive,
            metadata: metadata
        )
    }
    
    /// Convert database model to domain model for corrections
    private func convertToUserCorrection(_ data: UserCorrectionData) throws -> UserCorrection {
        let metadata = try JSONDecoder().decode([String: String].self, from: data.metadata)
        
        guard let originalCategory = PARACategory(rawValue: data.originalCategory),
              let correctedCategory = PARACategory(rawValue: data.correctedCategory) else {
            throw RepositoryError.invalidData("Invalid category in correction data")
        }
        
        let originalClassification = PARAClassification(
            category: originalCategory,
            subcategory: data.originalSubcategory
        )
        
        let correctedClassification = PARAClassification(
            category: correctedCategory,
            subcategory: data.correctedSubcategory
        )
        
        // Create a simplified ContextualPARAItem for the correction
        // In a real implementation, this would reconstruct the full item
        let originalItem = ContextualPARAItem(
            originalItem: PARAItem(
                id: data.originalItemId,
                title: "Correction Item",
                content: "Item content",
                contentType: .task,
                paraCategory: originalCategory,
                workPersonal: .personal,
                priority: .medium,
                tags: [],
                createdAt: data.createdAt,
                isCompleted: false
            ),
            paraClassification: originalClassification,
            confidence: 0.5,
            reasoning: "Original classification",
            detectedKeywords: [],
            suggestedActions: [],
            relatedItems: []
        )
        
        return UserCorrection(
            id: data.id,
            originalItem: originalItem,
            correctedClassification: correctedClassification,
            userFeedback: data.userFeedback,
            timestamp: ISO8601DateFormatter().date(from: data.createdAt) ?? Date(),
            context: nil
        )
    }
    
    /// Get current user ID (placeholder implementation)
    private func getCurrentUserId() -> String {
        // In a real implementation, this would get the current user ID from authentication
        return "dev@lifemanager.local"
    }
}

// MARK: - Database Models

/// Database model for personal PARA rules
struct PersonalPARARuleData: Codable, Identifiable {
    let id: UUID
    let pattern: String
    let targetCategory: String
    let targetSubcategory: String?
    let confidence: Float
    let description: String
    let ruleType: String
    let createdFromCorrections: Int
    let usageCount: Int
    let isActive: Bool
    let metadata: Data
    let createdAt: Date
    let lastUsed: Date?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case pattern
        case targetCategory = "target_category"
        case targetSubcategory = "target_subcategory"
        case confidence
        case description
        case ruleType = "rule_type"
        case createdFromCorrections = "created_from_corrections"
        case usageCount = "usage_count"
        case isActive = "is_active"
        case metadata
        case createdAt = "created_at"
        case lastUsed = "last_used"
        case updatedAt = "updated_at"
    }
}

/// Database model for user corrections
struct UserCorrectionData: Codable, Identifiable {
    let id: UUID
    let userId: String
    let originalItemId: UUID
    let originalCategory: String
    let originalSubcategory: String?
    let correctedCategory: String
    let correctedSubcategory: String?
    let userFeedback: String?
    let confidence: Float
    let reasoning: String
    let correctionType: String
    let metadata: Data
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case originalItemId = "original_item_id"
        case originalCategory = "original_category"
        case originalSubcategory = "original_subcategory"
        case correctedCategory = "corrected_category"
        case correctedSubcategory = "corrected_subcategory"
        case userFeedback = "user_feedback"
        case confidence
        case reasoning
        case correctionType = "correction_type"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Database model for rule effectiveness tracking
struct RuleEffectivenessData: Codable, Identifiable {
    let id: UUID
    let ruleId: UUID
    let successRate: Float
    let confidenceImprovement: Float
    let timesSaved: Int
    let lastImpact: Date?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case ruleId = "rule_id"
        case successRate = "success_rate"
        case confidenceImprovement = "confidence_improvement"
        case timesSaved = "times_saved"
        case lastImpact = "last_impact"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Repository errors
enum RepositoryError: Error, LocalizedError {
    case invalidData(String)
    case notFound
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .notFound:
            return "Record not found"
        case .updateFailed:
            return "Update operation failed"
        }
    }
}

// MARK: - Extensions

/// Extension to handle LifeTask in addition to ContextualPARAItem
extension PersonalPARARule {
    
    /// Check if rule applies to a LifeTask
    func appliesTo(_ task: LifeTask) -> Bool {
        let content = "\(task.title) \(task.description ?? "")".lowercased()
        let pattern = self.pattern.lowercased()
        
        switch ruleType {
        case .keyword:
            return content.contains(pattern)
        case .phrase:
            return content.hasPrefix(pattern)
        case .categoryOverride:
            return true // Always applies, but with lower priority
        case .contextual:
            return content.contains(pattern) // More complex logic could be added
        }
    }
}