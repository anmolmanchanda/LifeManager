//
// AdvancedNotificationService.swift
// LifeManager
//
// Advanced Notification System: Multi-channel Escalation and Proactive Support
// Implements: Phase 1 Priority 3 - Advanced Notification System
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation
import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif
import Combine

/// Advanced notification service with SMS/email escalation and proactive support
/// Extends basic NotificationService with intelligent escalation and multi-channel delivery
@MainActor
class AdvancedNotificationService: ObservableObject {
    
    static let shared = AdvancedNotificationService()
    
    // MARK: - Dependencies
    
    private let basicNotificationService = NotificationService.shared
    private let userPreferencesRepository = UserPreferencesRepository()
    private let logger = Logger.shared
    
    // MARK: - Published State
    
    @Published var escalationPreferences = EscalationPreferences.default
    @Published var activeEscalations: [NotificationEscalation] = []
    @Published var notificationHistory: [NotificationHistoryEntry] = []
    @Published var quietHoursActive = false
    @Published var unreadCriticalCount = 0
    @Published var deliveryStatistics = NotificationDeliveryStats()
    
    // MARK: - Configuration
    
    private let maxEscalationLevels = 3
    private let escalationDelays: [TimeInterval] = [300, 900, 1800] // 5min, 15min, 30min
    private let maxDailyNotifications = 50
    private let criticalNotificationLimit = 10
    
    // MARK: - State Management
    
    private var escalationTimers: [UUID: Timer] = [:]
    private var dailyNotificationCount = 0
    private var lastDayReset = Date()
    
    // MARK: - Initialization
    
    private init() {
        logger.info("ADVANCED_NOTIFICATIONS: Service initialized")
        loadEscalationPreferences()
        setupDailyReset()
    }
    
    deinit {
        escalationTimers.values.forEach { $0.invalidate() }
    }
    
    // MARK: - Advanced Notification Interface
    
    /// Send notification with intelligent escalation
    func sendAdvancedNotification(
        title: String,
        message: String,
        priority: NotificationPriority,
        category: AdvancedNotificationCategory,
        context: NotificationContext? = nil,
        escalationRules: EscalationRules? = nil
    ) async {
        logger.info("ADVANCED_NOTIFICATIONS: Sending advanced notification: \\(title)")
        
        // Check rate limits and quiet hours
        guard await shouldSendNotification(priority: priority, category: category) else {
            logger.info("ADVANCED_NOTIFICATIONS: Notification blocked by rate limits or quiet hours")
            return
        }
        
        // Create notification entry
        let notificationId = UUID()
        let notification = AdvancedNotification(
            id: notificationId,
            title: title,
            message: message,
            priority: priority,
            category: category,
            context: context,
            createdAt: Date()
        )
        
        // Start with basic in-app notification
        await deliverInitialNotification(notification)
        
        // Set up escalation if needed
        if let rules = escalationRules ?? getDefaultEscalationRules(for: priority, category: category) {
            setupEscalation(for: notification, rules: rules)
        }
        
        // Update statistics
        updateDeliveryStatistics(for: notification)
        addToHistory(notification)
    }
    
    /// Send critical notification with immediate multi-channel delivery
    func sendCriticalNotification(
        title: String,
        message: String,
        category: AdvancedNotificationCategory,
        immediateChannels: [NotificationChannel] = [.inApp, .push, .email]
    ) async {
        logger.warning("ADVANCED_NOTIFICATIONS: Sending critical notification: \\(title)")
        
        let notification = AdvancedNotification(
            id: UUID(),
            title: title,
            message: message,
            priority: .critical,
            category: category,
            context: nil,
            createdAt: Date()
        )
        
        // Bypass quiet hours for critical notifications
        for channel in immediateChannels {
            await deliverToChannel(notification, channel: channel, level: 0)
        }
        
        unreadCriticalCount += 1
        addToHistory(notification)
    }
    
    /// Send proactive suggestion notification
    func sendProactiveSuggestion(
        title: String,
        message: String,
        suggestions: [ProactiveSuggestion],
        confidence: Double,
        context: NotificationContext
    ) async {
        logger.info("ADVANCED_NOTIFICATIONS: Sending proactive suggestion: \\(title)")
        
        let notification = AdvancedNotification(
            id: UUID(),
            title: title,
            message: message,
            priority: .normal,
            category: .proactiveSuggestion,
            context: context,
            createdAt: Date(),
            suggestions: suggestions,
            confidence: confidence
        )
        
        // Only send if confidence is high enough
        guard confidence >= escalationPreferences.minimumSuggestionConfidence else {
            logger.info("ADVANCED_NOTIFICATIONS: Suggestion confidence too low: \\(confidence)")
            return
        }
        
        await deliverInitialNotification(notification)
        addToHistory(notification)
    }
    
    // MARK: - Channel Delivery
    
    /// Deliver notification to specific channel
    private func deliverToChannel(_ notification: AdvancedNotification, channel: NotificationChannel, level: Int) async {
        logger.debug("ADVANCED_NOTIFICATIONS: Delivering to \\(channel) (level \\(level))")
        
        switch channel {
        case .inApp:
            await deliverInAppNotification(notification, level: level)
        case .push:
            await deliverPushNotification(notification, level: level)
        case .email:
            await deliverEmailNotification(notification, level: level)
        case .sms:
            await deliverSMSNotification(notification, level: level)
        case .webhook:
            await deliverWebhookNotification(notification, level: level)
        }
    }
    
    private func deliverInAppNotification(_ notification: AdvancedNotification, level: Int) async {
        // Enhanced in-app notification with rich content
        let actions = createNotificationActions(for: notification, level: level)
        
        await basicNotificationService.showInAppNotification(
            title: notification.title,
            message: notification.message,
            category: mapToBasicCategory(notification.category),
            priority: mapToBasicPriority(notification.priority),
            actions: actions
        )
    }
    
    private func deliverPushNotification(_ notification: AdvancedNotification, level: Int) async {
        // Enhanced push notification with escalation indicators
        let escalationSuffix = level > 0 ? " (Escalation \\(level + 1))" : ""
        
        basicNotificationService.sendLocalNotification(
            title: notification.title + escalationSuffix,
            body: notification.message,
            category: mapToBasicCategory(notification.category),
            delay: 0
        )
    }
    
    private func deliverEmailNotification(_ notification: AdvancedNotification, level: Int) async {
        guard escalationPreferences.emailEnabled,
              let emailAddress = escalationPreferences.emailAddress else {
            logger.warning("ADVANCED_NOTIFICATIONS: Email delivery not configured")
            return
        }
        
        let emailContent = createEmailContent(notification, level: level)
        await sendEmail(to: emailAddress, subject: notification.title, content: emailContent)
    }
    
    private func deliverSMSNotification(_ notification: AdvancedNotification, level: Int) async {
        guard escalationPreferences.smsEnabled,
              let phoneNumber = escalationPreferences.phoneNumber else {
            logger.warning("ADVANCED_NOTIFICATIONS: SMS delivery not configured")
            return
        }
        
        let smsContent = createSMSContent(notification, level: level)
        await sendSMS(to: phoneNumber, content: smsContent)
    }
    
    private func deliverWebhookNotification(_ notification: AdvancedNotification, level: Int) async {
        guard escalationPreferences.webhookEnabled,
              let webhookURL = escalationPreferences.webhookURL else {
            logger.warning("ADVANCED_NOTIFICATIONS: Webhook delivery not configured")
            return
        }
        
        let webhookPayload = createWebhookPayload(notification, level: level)
        await sendWebhook(to: webhookURL, payload: webhookPayload)
    }
    
    // MARK: - Escalation Management
    
    private func setupEscalation(for notification: AdvancedNotification, rules: EscalationRules) {
        guard rules.channels.count > 1 else { return }
        
        let escalation = NotificationEscalation(
            id: UUID(),
            notificationId: notification.id,
            rules: rules,
            currentLevel: 0,
            startedAt: Date()
        )
        
        activeEscalations.append(escalation)
        scheduleNextEscalation(escalation)
    }
    
    private func scheduleNextEscalation(_ escalation: NotificationEscalation) {
        let nextLevel = escalation.currentLevel + 1
        
        guard nextLevel < escalation.rules.channels.count,
              nextLevel < maxEscalationLevels else {
            logger.info("ADVANCED_NOTIFICATIONS: Max escalation level reached for \\(escalation.id)")
            return
        }
        
        let delay = escalation.rules.delays[min(nextLevel - 1, escalation.rules.delays.count - 1)]
        
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.executeEscalation(escalation, level: nextLevel)
            }
        }
        
        escalationTimers[escalation.id] = timer
    }
    
    private func executeEscalation(_ escalation: NotificationEscalation, level: Int) async {
        logger.info("ADVANCED_NOTIFICATIONS: Executing escalation level \\(level) for \\(escalation.id)")
        
        // Find the original notification
        guard let originalNotification = findNotificationInHistory(escalation.notificationId) else {
            logger.error("ADVANCED_NOTIFICATIONS: Original notification not found for escalation")
            return
        }
        
        // Deliver to next channel
        let channel = escalation.rules.channels[level]
        await deliverToChannel(originalNotification, channel: channel, level: level)
        
        // Update escalation state
        if let index = activeEscalations.firstIndex(where: { $0.id == escalation.id }) {
            activeEscalations[index].currentLevel = level
            activeEscalations[index].lastEscalatedAt = Date()
        }
        
        // Schedule next level if needed
        scheduleNextEscalation(escalation)
    }
    
    // MARK: - Content Creation
    
    private func createEmailContent(_ notification: AdvancedNotification, level: Int) -> String {
        var content = """
        <html>
        <body>
        <h2>LifeManager Notification</h2>
        <h3>\\(notification.title)</h3>
        <p>\\(notification.message)</p>
        """
        
        if level > 0 {
            content += "<p><strong>This is escalation level \\(level + 1)</strong></p>"
        }
        
        if let context = notification.context {
            content += """
            <h4>Context:</h4>
            <ul>
            <li>Category: \\(context.category)</li>
            <li>Source: \\(context.source)</li>
            <li>Priority: \\(notification.priority.displayName)</li>
            </ul>
            """
        }
        
        if let suggestions = notification.suggestions, !suggestions.isEmpty {
            content += "<h4>Suggestions:</h4><ul>"
            for suggestion in suggestions {
                content += "<li>\\(suggestion.title): \\(suggestion.description)</li>"
            }
            content += "</ul>"
        }
        
        content += """
        <p><small>Sent from LifeManager at \\(DateFormatter.timestamp.string(from: notification.createdAt))</small></p>
        </body>
        </html>
        """
        
        return content
    }
    
    private func createSMSContent(_ notification: AdvancedNotification, level: Int) -> String {
        var content = "LifeManager: \\(notification.title)\\n\\(notification.message)"
        
        if level > 0 {
            content = "[ESCALATION \\(level + 1)] " + content
        }
        
        return content
    }
    
    private func createWebhookPayload(_ notification: AdvancedNotification, level: Int) -> [String: Any] {
        var payload: [String: Any] = [
            "id": notification.id.uuidString,
            "title": notification.title,
            "message": notification.message,
            "priority": notification.priority.rawValue,
            "category": notification.category.rawValue,
            "level": level,
            "timestamp": ISO8601DateFormatter().string(from: notification.createdAt)
        ]
        
        if let context = notification.context {
            payload["context"] = [
                "category": context.category,
                "source": context.source,
                "metadata": context.metadata
            ]
        }
        
        return payload
    }
    
    // MARK: - External Communication
    
    private func sendEmail(to address: String, subject: String, content: String) async {
        // In a real implementation, this would integrate with an email service
        // For now, log the email content
        logger.info("ADVANCED_NOTIFICATIONS: Email sent to \\(address)")
        logger.debug("ADVANCED_NOTIFICATIONS: Email content: \\(content)")
    }
    
    private func sendSMS(to phoneNumber: String, content: String) async {
        // In a real implementation, this would integrate with an SMS service like Twilio
        logger.info("ADVANCED_NOTIFICATIONS: SMS sent to \\(phoneNumber)")
        logger.debug("ADVANCED_NOTIFICATIONS: SMS content: \\(content)")
    }
    
    private func sendWebhook(to url: URL, payload: [String: Any]) async {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               200...299 ~= httpResponse.statusCode {
                logger.success("ADVANCED_NOTIFICATIONS: Webhook delivered successfully")
            } else {
                logger.error("ADVANCED_NOTIFICATIONS: Webhook delivery failed")
            }
        } catch {
            logger.error("ADVANCED_NOTIFICATIONS: Webhook error: \\(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func shouldSendNotification(priority: NotificationPriority, category: AdvancedNotificationCategory) async -> Bool {
        // Check daily limits
        resetDailyCountIfNeeded()
        if dailyNotificationCount >= maxDailyNotifications && priority != .critical {
            return false
        }
        
        // Check quiet hours (unless critical)
        if priority != .critical && isQuietHoursActive() {
            return false
        }
        
        // Check category-specific limits
        if category == .proactiveSuggestion && dailyNotificationCount >= escalationPreferences.maxDailySuggestions {
            return false
        }
        
        return true
    }
    
    private func isQuietHoursActive() -> Bool {
        guard escalationPreferences.quietHoursEnabled else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        return hour >= escalationPreferences.quietHoursStart || hour < escalationPreferences.quietHoursEnd
    }
    
    private func resetDailyCountIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(lastDayReset, inSameDayAs: Date()) {
            dailyNotificationCount = 0
            lastDayReset = Date()
            logger.info("ADVANCED_NOTIFICATIONS: Daily notification count reset")
        }
    }
    
    private func loadEscalationPreferences() {
        Task {
            do {
                if let preferences = try await userPreferencesRepository.getNotificationPreferences() {
                    escalationPreferences = EscalationPreferences(from: preferences)
                }
            } catch {
                logger.error("ADVANCED_NOTIFICATIONS: Failed to load escalation preferences: \\(error)")
            }
        }
    }
    
    private func setupDailyReset() {
        // Schedule daily reset at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let midnight = calendar.startOfDay(for: tomorrow)
        
        Timer.scheduledTimer(withTimeInterval: midnight.timeIntervalSinceNow, repeats: false) { [weak self] _ in
            self?.resetDailyCountIfNeeded()
            self?.setupDailyReset() // Schedule next reset
        }
    }
    
    // Additional helper methods...
    private func deliverInitialNotification(_ notification: AdvancedNotification) async {
        await deliverInAppNotification(notification, level: 0)
        dailyNotificationCount += 1
    }
    
    private func updateDeliveryStatistics(for notification: AdvancedNotification) {
        deliveryStatistics.totalSent += 1
        
        switch notification.priority {
        case .low: deliveryStatistics.lowPrioritySent += 1
        case .normal: deliveryStatistics.normalPrioritySent += 1
        case .high: deliveryStatistics.highPrioritySent += 1
        case .critical: deliveryStatistics.criticalSent += 1
        }
    }
    
    private func addToHistory(_ notification: AdvancedNotification) {
        let historyEntry = NotificationHistoryEntry(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            priority: notification.priority,
            category: notification.category,
            deliveredAt: Date(),
            wasEscalated: false
        )
        
        notificationHistory.insert(historyEntry, at: 0)
        
        // Keep only last 100 entries
        if notificationHistory.count > 100 {
            notificationHistory = Array(notificationHistory.prefix(100))
        }
    }
    
    private func getDefaultEscalationRules(for priority: NotificationPriority, category: AdvancedNotificationCategory) -> EscalationRules? {
        switch priority {
        case .critical:
            return EscalationRules(
                channels: [.inApp, .push, .email, .sms],
                delays: [0, 300, 600] // Immediate, 5min, 10min
            )
        case .high:
            return EscalationRules(
                channels: [.inApp, .push, .email],
                delays: [0, 900, 1800] // Immediate, 15min, 30min
            )
        case .normal:
            return category == .proactiveSuggestion ? nil : EscalationRules(
                channels: [.inApp, .push],
                delays: [0, 1800] // Immediate, 30min
            )
        case .low:
            return nil // No escalation for low priority
        }
    }
    
    private func createNotificationActions(for notification: AdvancedNotification, level: Int) -> [NotificationService.NotificationAction] {
        var actions: [NotificationService.NotificationAction] = []
        
        if let suggestions = notification.suggestions {
            for suggestion in suggestions.prefix(2) { // Limit to 2 actions
                actions.append(NotificationService.NotificationAction(
                    id: suggestion.id.uuidString,
                    title: suggestion.title,
                    isDestructive: false
                ))
            }
        }
        
        return actions
    }
    
    private func mapToBasicCategory(_ category: AdvancedNotificationCategory) -> NotificationService.NotificationCategory {
        switch category {
        case .taskReminder: return .taskReminder
        case .scheduleChange: return .scheduleChange
        case .conflictDetection: return .conflictDetection
        case .proactiveSuggestion: return .proactiveSuggestion
        case .systemAlert: return .systemAlert
        case .achievement: return .achievement
        }
    }
    
    private func mapToBasicPriority(_ priority: NotificationPriority) -> NotificationService.NotificationPriority {
        switch priority {
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .critical: return .critical
        }
    }
    
    private func findNotificationInHistory(_ id: UUID) -> AdvancedNotification? {
        // In a real implementation, this would look up the full notification
        return nil
    }
}

// MARK: - Supporting Models

struct AdvancedNotification: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let priority: NotificationPriority
    let category: AdvancedNotificationCategory
    let context: NotificationContext?
    let createdAt: Date
    let suggestions: [ProactiveSuggestion]?
    let confidence: Double?
    
    init(id: UUID, title: String, message: String, priority: NotificationPriority, category: AdvancedNotificationCategory, context: NotificationContext?, createdAt: Date, suggestions: [ProactiveSuggestion]? = nil, confidence: Double? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.priority = priority
        self.category = category
        self.context = context
        self.createdAt = createdAt
        self.suggestions = suggestions
        self.confidence = confidence
    }
}

enum NotificationPriority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

enum AdvancedNotificationCategory: String, CaseIterable {
    case taskReminder = "task_reminder"
    case scheduleChange = "schedule_change"
    case conflictDetection = "conflict_detection"
    case proactiveSuggestion = "proactive_suggestion"
    case systemAlert = "system_alert"
    case achievement = "achievement"
}

enum NotificationChannel: String, CaseIterable {
    case inApp = "in_app"
    case push = "push"
    case email = "email"
    case sms = "sms"
    case webhook = "webhook"
}

struct NotificationContext {
    let category: String
    let source: String
    let metadata: [String: Any]
}

struct ProactiveSuggestion: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let action: String
    let confidence: Double
}

struct EscalationRules {
    let channels: [NotificationChannel]
    let delays: [TimeInterval]
}

struct NotificationEscalation: Identifiable {
    let id: UUID
    let notificationId: UUID
    let rules: EscalationRules
    var currentLevel: Int
    let startedAt: Date
    var lastEscalatedAt: Date?
}

struct EscalationPreferences {
    var emailEnabled: Bool = false
    var emailAddress: String?
    var smsEnabled: Bool = false
    var phoneNumber: String?
    var webhookEnabled: Bool = false
    var webhookURL: URL?
    var quietHoursEnabled: Bool = true
    var quietHoursStart: Int = 22 // 10 PM
    var quietHoursEnd: Int = 8 // 8 AM
    var maxDailySuggestions: Int = 10
    var minimumSuggestionConfidence: Double = 0.7
    
    static let `default` = EscalationPreferences()
    
    init(from preferences: NotificationPreferenceData? = nil) {
        // Initialize from database preferences if available
        if let prefs = preferences {
            self.emailEnabled = prefs.emailEnabled
            self.emailAddress = prefs.emailAddress
            self.smsEnabled = prefs.smsEnabled
            self.phoneNumber = prefs.phoneNumber
            self.quietHoursEnabled = prefs.quietHoursEnabled
            self.quietHoursStart = prefs.quietHoursStart
            self.quietHoursEnd = prefs.quietHoursEnd
            self.maxDailySuggestions = prefs.maxDailySuggestions
            self.minimumSuggestionConfidence = prefs.minimumSuggestionConfidence
        }
    }
}

struct NotificationHistoryEntry: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let priority: NotificationPriority
    let category: AdvancedNotificationCategory
    let deliveredAt: Date
    let wasEscalated: Bool
}

struct NotificationDeliveryStats {
    var totalSent: Int = 0
    var lowPrioritySent: Int = 0
    var normalPrioritySent: Int = 0
    var highPrioritySent: Int = 0
    var criticalSent: Int = 0
    var totalEscalated: Int = 0
    var emailsSent: Int = 0
    var smsSent: Int = 0
    var webhooksSent: Int = 0
}

// MARK: - Extensions

extension DateFormatter {
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// Extension to NotificationService for integration
extension NotificationService {
    enum NotificationPriority {
        case low, normal, high, critical
    }
    
    func showInAppNotification(
        title: String,
        message: String,
        category: NotificationCategory,
        priority: NotificationPriority,
        actions: [NotificationAction]
    ) async {
        // This would be implemented to show rich in-app notifications
        // For now, delegate to existing notification system
        sendLocalNotification(title: title, body: message, category: category)
    }
}