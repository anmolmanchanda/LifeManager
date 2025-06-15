import Foundation
import UserNotifications
import SwiftUI

/// Service for handling various types of notifications
@MainActor
class NotificationService: ObservableObject {
    
    static let shared = NotificationService()
    
    @Published var notificationPermissionGranted = false
    private var permissionRequested = false
    
    private init() {
        // Don't request permission during initialization - wait for first use
        NSLog("🔧 DEBUG: NotificationService init() completed safely")
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission from user (deferred until first use)
    private func requestNotificationPermissionIfNeeded() {
        guard !permissionRequested else { return }
        permissionRequested = true
        
        NSLog("🔧 DEBUG: Requesting notification permissions")
        
        // Safely handle UNUserNotificationCenter access with error handling
        do {
            // Check if we're running in a proper app bundle context
            guard Bundle.main.bundleIdentifier != nil else {
                NSLog("🔧 NOTIFICATIONS: ⚠️ Not running in app bundle context, skipping notifications")
                notificationPermissionGranted = false
                return
            }
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    self.notificationPermissionGranted = granted
                    if let error = error {
                        NSLog("🔧 NOTIFICATIONS: ❌ Permission error: \(error)")
                    } else {
                        NSLog("🔧 NOTIFICATIONS: ✅ Permission granted: \(granted)")
                    }
                }
            }
        } catch {
            NSLog("🔧 NOTIFICATIONS: ❌ Failed to access UNUserNotificationCenter: \(error)")
            notificationPermissionGranted = false
        }
    }
    
    // MARK: - Local Notifications
    
    /// Send immediate local notification
    func sendLocalNotification(
        title: String,
        body: String,
        category: NotificationCategory = .general,
        delay: TimeInterval = 0
    ) {
        // Request permission if not already requested
        requestNotificationPermissionIfNeeded()
        
        guard notificationPermissionGranted else {
            NSLog("🔧 NOTIFICATIONS: ⚠️ Permission not granted for local notification")
            return
        }
        
        // Check if we're running in a proper app bundle context
        guard Bundle.main.bundleIdentifier != nil else {
            NSLog("🔧 NOTIFICATIONS: ⚠️ Not running in app bundle context, skipping notification")
            return
        }
        
        do {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = category.sound
            content.categoryIdentifier = category.rawValue
            
            // Add action buttons for interactive notifications
            addNotificationActions(for: category)
            
            let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("🔧 NOTIFICATIONS: ❌ Failed to send notification: \(error)")
                } else {
                    print("🔧 NOTIFICATIONS: ✅ Sent notification: \(title)")
                }
            }
        } catch {
            NSLog("🔧 NOTIFICATIONS: ❌ Failed to send notification: \(error)")
        }
    }
    
    /// Schedule buffer warning notification
    func scheduleBufferWarning() {
        sendLocalNotification(
            title: "Calendar Overbooked ⚠️",
            body: "Your schedule has no buffer remaining. Consider rescheduling some events.",
            category: .bufferWarning
        )
    }
    
    /// Send parking lot notification
    func sendParkingNotification(eventTitle: String, reason: String) {
        sendLocalNotification(
            title: "Event Parked",
            body: "'\(eventTitle)' was moved to parking lot: \(reason)",
            category: .eventParked
        )
    }
    
    // MARK: - Enhanced Calendar Notifications
    
    /// Schedule event parked notification
    func scheduleEventParkedNotification(
        eventTitle: String,
        reason: String,
        isImportant: Bool
    ) async {
        let priority = isImportant ? "🔴" : "🟡"
        sendLocalNotification(
            title: "Event Parked \(priority)",
            body: "'\(eventTitle)' moved to parking lot - \(reason)",
            category: isImportant ? .criticalEvent : .eventParked
        )
    }
    
    /// Schedule event rescheduled notification
    func scheduleEventRescheduledNotification(
        eventTitle: String,
        newTime: Date
    ) async {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        sendLocalNotification(
            title: "Event Rescheduled ✅",
            body: "'\(eventTitle)' moved to \(formatter.string(from: newTime))",
            category: .eventRescheduled
        )
    }
    
    /// Schedule parking decision notification
    func scheduleParkingDecisionNotification(eventCount: Int) async {
        sendLocalNotification(
            title: "Decision Required 🤔",
            body: "\(eventCount) events need scheduling decisions. Which should be parked?",
            category: .decisionRequired
        )
    }
    
    /// Schedule auto-bump notification
    func scheduleAutoBumpNotification(
        eventTitle: String,
        bumpedByMinutes: Int,
        reason: String
    ) async {
        sendLocalNotification(
            title: "Event Auto-Bumped 📅",
            body: "'\(eventTitle)' moved \(bumpedByMinutes)min later - \(reason)",
            category: .eventBumped
        )
    }
    
    /// Schedule cascade bump notification
    func scheduleCascadeBumpNotification(eventCount: Int) async {
        sendLocalNotification(
            title: "Multiple Events Bumped ⚡",
            body: "\(eventCount) events rescheduled due to cascade effect",
            category: .cascadeBump
        )
    }
    
    /// Schedule buffer violation warning
    func scheduleBufferViolationWarning(
        remainingBuffer: Int,
        hoursAffected: Int
    ) async {
        sendLocalNotification(
            title: "Buffer Violation ⚠️",
            body: "Only \(remainingBuffer)min buffer left for \(hoursAffected)h period",
            category: .bufferWarning
        )
    }
    
    /// Schedule stale parking lot notification
    func scheduleStaleEventNotification(eventCount: Int) async {
        sendLocalNotification(
            title: "Stale Parked Events 📋",
            body: "\(eventCount) events have been parked for over a week",
            category: .staleEvents
        )
    }
    
    /// Send critical event notification
    func sendCriticalEventNotification(eventTitle: String) {
        sendLocalNotification(
            title: "Critical Event Needs Attention",
            body: "'\(eventTitle)' is marked critical but couldn't be scheduled today.",
            category: .criticalEvent
        )
    }
    
    /// Schedule escalated warning (15 minutes later)
    func scheduleEscalatedWarning() {
        sendLocalNotification(
            title: "Urgent: Calendar Review Required",
            body: "Your calendar is still overbooked. Please review your schedule immediately.",
            category: .escalatedWarning,
            delay: 900 // 15 minutes
        )
        
        // Schedule SMS/email backup after the notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 900) {
            Task {
                await self.sendEscalatedAlert()
            }
        }
    }
    
    // MARK: - Interactive Notification Actions
    
    private func addNotificationActions(for category: NotificationCategory) {
        // Check if we're running in a proper app bundle context
        guard Bundle.main.bundleIdentifier != nil else {
            NSLog("🔧 NOTIFICATIONS: ⚠️ Not running in app bundle context, skipping notification actions")
            return
        }
        
        do {
            let center = UNUserNotificationCenter.current()
            
            switch category {
        case .bufferWarning:
            let rescheduleAction = UNNotificationAction(
                identifier: "RESCHEDULE_ACTION",
                title: "Reschedule Events",
                options: [.foreground]
            )
            let parkAction = UNNotificationAction(
                identifier: "PARK_ACTION",
                title: "Park Low Priority",
                options: []
            )
            let dismissAction = UNNotificationAction(
                identifier: "DISMISS_ACTION",
                title: "Dismiss",
                options: []
            )
            
            let category = UNNotificationCategory(
                identifier: NotificationCategory.bufferWarning.rawValue,
                actions: [rescheduleAction, parkAction, dismissAction],
                intentIdentifiers: []
            )
            center.setNotificationCategories([category])
            
        case .criticalEvent:
            let reviewAction = UNNotificationAction(
                identifier: "REVIEW_ACTION",
                title: "Review Schedule",
                options: [.foreground]
            )
            let postponeAction = UNNotificationAction(
                identifier: "POSTPONE_ACTION",
                title: "Move to Tomorrow",
                options: []
            )
            
            let category = UNNotificationCategory(
                identifier: NotificationCategory.criticalEvent.rawValue,
                actions: [reviewAction, postponeAction],
                intentIdentifiers: []
            )
            center.setNotificationCategories([category])
            
        default:
            break
        }
        } catch {
            NSLog("🔧 NOTIFICATIONS: ❌ Failed to add notification actions: \(error)")
        }
    }
    
    // MARK: - External Notifications (SMS/Email)
    
    /// Send escalated alert via SMS or email
    private func sendEscalatedAlert() async {
        // First try SMS, then fall back to email
        let smsSuccess = await sendSMS()
        if !smsSuccess {
            await sendEmail()
        }
    }
    
    /// Send SMS notification (placeholder for Twilio integration)
    private func sendSMS() async -> Bool {
        // TODO: Implement Twilio SMS integration
        print("🔧 NOTIFICATIONS: 📱 Would send SMS alert (integration needed)")
        
        // Placeholder for actual SMS implementation:
        /*
        guard let twilioSID = Config.twilioSID,
              let twilioAuthToken = Config.twilioAuthToken,
              let phoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber") else {
            return false
        }
        
        let message = "LifeManager Alert: Your calendar is critically overbooked. Please review your schedule immediately."
        
        // Twilio API call would go here
        return await TwilioService.sendSMS(to: phoneNumber, message: message)
        */
        
        return false
    }
    
    /// Send email notification (placeholder for email service integration)
    private func sendEmail() async {
        // TODO: Implement email service integration
        print("🔧 NOTIFICATIONS: 📧 Would send email alert (integration needed)")
        
        // Placeholder for actual email implementation:
        /*
        guard let email = UserDefaults.standard.string(forKey: "userEmail") else {
            return
        }
        
        let subject = "LifeManager: Calendar Overbooked Alert"
        let body = """
        Your LifeManager calendar is critically overbooked with no buffer remaining.
        
        Please review your schedule and consider:
        - Rescheduling non-critical events
        - Moving events to the parking lot
        - Adjusting your buffer settings
        
        Open LifeManager to manage your schedule.
        """
        
        await EmailService.send(to: email, subject: subject, body: body)
        */
    }
    
    // MARK: - Badge Management
    
    /// Update app badge count
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("🔧 NOTIFICATIONS: ❌ Failed to update badge: \(error)")
            }
        }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        updateBadgeCount(0)
        print("🔧 NOTIFICATIONS: ✅ Cleared all notifications")
    }
}

// MARK: - Supporting Types

/// Notification categories for different types of alerts
enum NotificationCategory: String, CaseIterable {
    case general = "GENERAL"
    case bufferWarning = "BUFFER_WARNING"
    case eventParked = "EVENT_PARKED"
    case criticalEvent = "CRITICAL_EVENT"
    case escalatedWarning = "ESCALATED_WARNING"
    case eventRescheduled = "EVENT_RESCHEDULED"
    case decisionRequired = "DECISION_REQUIRED"
    case eventBumped = "EVENT_BUMPED"
    case cascadeBump = "CASCADE_BUMP"
    case staleEvents = "STALE_EVENTS"
    
    var sound: UNNotificationSound {
        switch self {
        case .general, .eventParked, .eventRescheduled, .eventBumped:
            return .default
        case .bufferWarning, .staleEvents:
            return UNNotificationSound(named: UNNotificationSoundName("warning.caf"))
        case .criticalEvent, .escalatedWarning, .decisionRequired, .cascadeBump:
            return UNNotificationSound(named: UNNotificationSoundName("critical.caf"))
        }
    }
}

/// Configuration for external notification services
struct NotificationConfig {
    static let twilioSID = ProcessInfo.processInfo.environment["TWILIO_SID"]
    static let twilioAuthToken = ProcessInfo.processInfo.environment["TWILIO_AUTH_TOKEN"]
    static let twilioFromNumber = ProcessInfo.processInfo.environment["TWILIO_FROM_NUMBER"]
    
    static let emailService = ProcessInfo.processInfo.environment["EMAIL_SERVICE_API_KEY"]
    static let emailFromAddress = ProcessInfo.processInfo.environment["EMAIL_FROM_ADDRESS"]
}

// MARK: - Extensions

extension UNUserNotificationCenter {
    /// Set badge count with completion handler
    func setBadgeCount(_ count: Int, completion: @escaping (Error?) -> Void) {
        setBadgeCount(count, withCompletionHandler: completion)
    }
} 