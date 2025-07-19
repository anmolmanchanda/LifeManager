import Foundation

/// Repository for managing user preferences related to intelligent automation
class UserPreferencesRepository: ObservableObject {
    
    // MARK: - Properties
    
    private let supabaseService = SupabaseService.shared
    private let logger = Logger.shared
    
    // MARK: - User Scheduling Preferences
    
    /// Save user scheduling preferences to database
    func saveSchedulingPreferences(_ preferences: UserSchedulingPreferences) async throws {
        do {
            // Convert preferences to database format
            let preferencesData = UserSchedulingPreferencesData(
                id: UUID(),
                workingHoursStartHour: preferences.workingHours.startHour,
                workingHoursEndHour: preferences.workingHours.endHour,
                workingHoursWorkDays: preferences.workingHours.workDays,
                workingHoursTimeZone: preferences.workingHours.timeZone,
                focusBlocks: try JSONEncoder().encode(preferences.focusBlocks),
                reschedulingSettings: try JSONEncoder().encode(preferences.reschedulingSettings),
                notificationSettings: try JSONEncoder().encode(preferences.notificationSettings),
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            // Check if preferences already exist for this user
            let existingPreferences = try await fetchSchedulingPreferencesData()
            
            if let existing = existingPreferences {
                // Update existing preferences
                let updatedData = UserSchedulingPreferencesData(
                    id: existing.id,
                    workingHoursStartHour: preferences.workingHours.startHour,
                    workingHoursEndHour: preferences.workingHours.endHour,
                    workingHoursWorkDays: preferences.workingHours.workDays,
                    workingHoursTimeZone: preferences.workingHours.timeZone,
                    focusBlocks: try JSONEncoder().encode(preferences.focusBlocks),
                    reschedulingSettings: try JSONEncoder().encode(preferences.reschedulingSettings),
                    notificationSettings: try JSONEncoder().encode(preferences.notificationSettings),
                    createdAt: existing.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
                
                let _: UserSchedulingPreferencesData = try await supabaseService.update(
                    updatedData,
                    in: "user_scheduling_preferences",
                    matching: "id",
                    value: existing.id.uuidString
                )
            } else {
                // Insert new preferences
                let _: UserSchedulingPreferencesData = try await supabaseService.insert(
                    preferencesData,
                    into: "user_scheduling_preferences"
                )
            }
            
            logger.success("USER_PREFERENCES: Saved scheduling preferences")
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to save scheduling preferences: \(error)")
            throw error
        }
    }
    
    /// Load user scheduling preferences from database
    func loadSchedulingPreferences() async throws -> UserSchedulingPreferences? {
        do {
            guard let data = try await fetchSchedulingPreferencesData() else {
                logger.debug("USER_PREFERENCES: No scheduling preferences found")
                return nil
            }
            
            // Decode JSON data
            let focusBlocks = try JSONDecoder().decode([FocusBlock].self, from: data.focusBlocks)
            let reschedulingSettings = try JSONDecoder().decode(ReschedulingSettings.self, from: data.reschedulingSettings)
            let notificationSettings = try JSONDecoder().decode(NotificationSettings.self, from: data.notificationSettings)
            
            let preferences = UserSchedulingPreferences(
                workingHours: WorkingHoursPreference(
                    startHour: data.workingHoursStartHour,
                    endHour: data.workingHoursEndHour,
                    workDays: data.workingHoursWorkDays,
                    timeZone: data.workingHoursTimeZone
                ),
                focusBlocks: focusBlocks,
                reschedulingSettings: reschedulingSettings,
                notificationSettings: notificationSettings
            )
            
            logger.success("USER_PREFERENCES: Loaded scheduling preferences")
            return preferences
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to load scheduling preferences: \(error)")
            throw error
        }
    }
    
    /// Fetch raw scheduling preferences data from database
    private func fetchSchedulingPreferencesData() async throws -> UserSchedulingPreferencesData? {
        let response: [UserSchedulingPreferencesData] = try await supabaseService.client
            .from("user_scheduling_preferences")
            .select()
            .order("updated_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    // MARK: - Notification Preferences
    
    /// Save notification preferences to database
    func saveNotificationPreferences(
        _ preferences: [NotificationType: NotificationPreference],
    ) async throws {
        do {
            // Clear existing preferences for this user
            try await supabaseService.client
                .from("notification_preferences")
                .delete()
                    .execute()
            
            // Insert new preferences
            for (_, preference) in preferences {
                let preferenceData = NotificationPreferenceData(
                    id: preference.id,
                    userId: preference.userId,
                    notificationType: preference.notificationType.rawValue,
                    isEnabled: preference.isEnabled,
                    preferredTiming: try? JSONEncoder().encode(preference.preferredTiming),
                    frequency: preference.frequency.rawValue,
                    customSettings: try JSONEncoder().encode(preference.customSettings),
                    createdAt: preference.createdAt,
                    updatedAt: preference.updatedAt
                )
                
                let _: NotificationPreferenceData = try await supabaseService.insert(
                    preferenceData,
                    into: "notification_preferences"
                )
            }
            
            logger.success("USER_PREFERENCES: Saved \(preferences.count) notification preferences")
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to save notification preferences: \(error)")
            throw error
        }
    }
    
    /// Load notification preferences from database
    func loadNotificationPreferences() async throws -> [NotificationType: NotificationPreference] {
        do {
            let response: [NotificationPreferenceData] = try await supabaseService.client
                .from("notification_preferences")
                .select()
                    .execute()
                .value
            
            var preferences: [NotificationType: NotificationPreference] = [:]
            
            for data in response {
                guard let notificationType = NotificationType(rawValue: data.notificationType),
                      let frequency = NotificationFrequency(rawValue: data.frequency) else {
                    logger.warning("USER_PREFERENCES: Invalid notification type or frequency in database")
                    continue
                }
                
                let preferredTiming: SchedulingTimeSlot? = {
                    guard let timingData = data.preferredTiming else { return nil }
                    return try? JSONDecoder().decode(SchedulingTimeSlot.self, from: timingData)
                }()
                
                let customSettings = (try? JSONDecoder().decode([String: AnyCodableValue].self, from: data.customSettings)) ?? [:]
                
                let preference = NotificationPreference(
                    id: data.id,
                    userId: data.userId ?? "",
                    notificationType: notificationType,
                    isEnabled: data.isEnabled,
                    preferredTiming: preferredTiming,
                    frequency: frequency,
                    customSettings: customSettings,
                    createdAt: data.createdAt,
                    updatedAt: data.updatedAt
                )
                
                preferences[notificationType] = preference
            }
            
            logger.success("USER_PREFERENCES: Loaded \(preferences.count) notification preferences")
            return preferences
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to load notification preferences: \(error)")
            throw error
        }
    }
    
    // MARK: - Scheduling Patterns
    
    /// Save a scheduling pattern to database
    func saveSchedulingPattern(_ pattern: SchedulingPattern) async throws {
        do {
            let _: SchedulingPattern = try await supabaseService.insert(
                pattern,
                into: "scheduling_patterns"
            )
            
            logger.success("USER_PREFERENCES: Saved scheduling pattern \(pattern.patternType)")
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to save scheduling pattern: \(error)")
            throw error
        }
    }
    
    /// Load scheduling patterns for a user
    func loadSchedulingPatterns() async throws -> [SchedulingPattern] {
        do {
            let response: [SchedulingPattern] = try await supabaseService.client
                .from("scheduling_patterns")
                .select()
                    .order("confidence", ascending: false)
                .execute()
                .value
            
            logger.success("USER_PREFERENCES: Loaded \(response.count) scheduling patterns")
            return response
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to load scheduling patterns: \(error)")
            throw error
        }
    }
    
    /// Update scheduling pattern usage
    func updateSchedulingPatternUsage(patternId: UUID) async throws {
        do {
            // Increment usage count and update last used date
            try await supabaseService.client
                .from("scheduling_patterns")
                .update([
                    "usage_count": "usage_count + 1",
                    "last_used": ISO8601DateFormatter().string(from: Date()),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: patternId.uuidString)
                .execute()
            
            logger.debug("USER_PREFERENCES: Updated usage for scheduling pattern \(patternId)")
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to update scheduling pattern usage: \(error)")
            throw error
        }
    }
    
    // MARK: - Priority Intelligence Cache
    
    /// Save priority intelligence to cache
    func savePriorityIntelligence(_ intelligence: PriorityIntelligence) async throws {
        do {
            let _: PriorityIntelligence = try await supabaseService.insert(
                intelligence,
                into: "priority_intelligence_cache"
            )
            
            logger.debug("USER_PREFERENCES: Cached priority intelligence for task \(intelligence.taskId)")
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to cache priority intelligence: \(error)")
            throw error
        }
    }
    
    /// Load priority intelligence from cache
    func loadPriorityIntelligence(taskId: UUID) async throws -> PriorityIntelligence? {
        do {
            let response: [PriorityIntelligence] = try await supabaseService.client
                .from("priority_intelligence_cache")
                .select()
                .eq("task_id", value: taskId.uuidString)
                .order("calculated_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            let intelligence = response.first
            if let intelligence = intelligence {
                logger.debug("USER_PREFERENCES: Retrieved cached priority intelligence for task \(taskId)")
            }
            
            return intelligence
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to load priority intelligence: \(error)")
            throw error
        }
    }
    
    /// Clean up expired priority intelligence entries
    func cleanupExpiredPriorityIntelligence() async throws {
        do {
            let now = ISO8601DateFormatter().string(from: Date())
            
            try await supabaseService.client
                .from("priority_intelligence_cache")
                .delete()
                .lt("expires_at", value: now)
                .execute()
            
            logger.debug("USER_PREFERENCES: Cleaned up expired priority intelligence entries")
            
        } catch {
            logger.error("USER_PREFERENCES: Failed to cleanup expired priority intelligence: \(error)")
            throw error
        }
    }
}

// MARK: - Database Models

/// Database model for user scheduling preferences
struct UserSchedulingPreferencesData: Codable, Identifiable {
    let id: UUID
    let workingHoursStartHour: Int
    let workingHoursEndHour: Int
    let workingHoursWorkDays: [Int]
    let workingHoursTimeZone: String
    let focusBlocks: Data
    let reschedulingSettings: Data
    let notificationSettings: Data
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case workingHoursStartHour = "working_hours_start_hour"
        case workingHoursEndHour = "working_hours_end_hour"
        case workingHoursWorkDays = "working_hours_work_days"
        case workingHoursTimeZone = "working_hours_time_zone"
        case focusBlocks = "focus_blocks"
        case reschedulingSettings = "rescheduling_settings"
        case notificationSettings = "notification_settings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Database model for notification preferences
struct NotificationPreferenceData: Codable, Identifiable {
    let id: UUID
    let userId: String?
    let notificationType: String
    let isEnabled: Bool
    let preferredTiming: Data?
    let frequency: String
    let customSettings: Data
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case notificationType = "notification_type"
        case isEnabled = "is_enabled"
        case preferredTiming = "preferred_timing"
        case frequency
        case customSettings = "custom_settings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}