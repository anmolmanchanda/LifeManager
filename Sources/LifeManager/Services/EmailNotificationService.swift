import Foundation
import SwiftUI

/// Email notification service for sending backup notifications when app notifications are not responded to
@MainActor
class EmailNotificationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isEnabled: Bool = false
    @Published var userEmail: String = ""
    @Published var smtpSettings: SMTPSettings?
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private var pendingNotifications: [PendingEmailNotification] = []
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Configuration
    
    /// Configure email settings
    func configureEmail(
        userEmail: String,
        smtpHost: String = "smtp.gmail.com",
        smtpPort: Int = 587,
        username: String,
        password: String
    ) {
        self.userEmail = userEmail
        self.smtpSettings = SMTPSettings(
            host: smtpHost,
            port: smtpPort,
            username: username,
            password: password,
            useSSL: true
        )
        self.isEnabled = true
        saveSettings()
    }
    
    /// Disable email notifications
    func disableEmailNotifications() {
        isEnabled = false
        smtpSettings = nil
        pendingNotifications.removeAll()
        saveSettings()
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule an email notification as backup to app notification
    func scheduleBackupEmail(
        for notification: AppNotification,
        delay: TimeInterval = 1800 // 30 minutes default
    ) {
        guard isEnabled, let _ = smtpSettings else { return }
        
        let emailNotification = PendingEmailNotification(
            id: UUID(),
            originalNotificationId: notification.id,
            scheduledTime: Date().addingTimeInterval(delay),
            subject: notification.title,
            body: createEmailBody(from: notification),
            priority: notification.priority
        )
        
        pendingNotifications.append(emailNotification)
        
        // Schedule the email to be sent
        Task {
            await scheduleEmailDelivery(emailNotification)
        }
    }
    
    /// Cancel backup email if app notification was responded to
    func cancelBackupEmail(for notificationId: UUID) {
        pendingNotifications.removeAll { $0.originalNotificationId == notificationId }
    }
    
    // MARK: - Email Delivery
    
    private func scheduleEmailDelivery(_ emailNotification: PendingEmailNotification) async {
        let delay = emailNotification.scheduledTime.timeIntervalSinceNow
        
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check if notification was cancelled
        guard pendingNotifications.contains(where: { $0.id == emailNotification.id }) else {
            return
        }
        
        await sendEmail(emailNotification)
        
        // Remove from pending list
        pendingNotifications.removeAll { $0.id == emailNotification.id }
    }
    
    private func sendEmail(_ emailNotification: PendingEmailNotification) async {
        guard let settings = smtpSettings else { return }
        
        let emailContent = EmailContent(
            to: userEmail,
            subject: emailNotification.subject,
            body: emailNotification.body,
            isHTML: true
        )
        
        do {
            let success = try await sendEmailViaSMTP(content: emailContent, settings: settings)
            if success {
                Logger.shared.success("EMAIL: Backup email sent successfully for: \(emailNotification.subject)")
            } else {
                Logger.shared.error("EMAIL: Failed to send backup email for: \(emailNotification.subject)")
            }
        } catch {
            Logger.shared.error("EMAIL: Error sending backup email: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SMTP Implementation
    
    private func sendEmailViaSMTP(content: EmailContent, settings: SMTPSettings) async throws -> Bool {
        // For now, this is a simplified implementation
        // In a production app, you would use a proper SMTP library like SwiftSMTP
        // or integrate with a service like SendGrid, Mailgun, etc.
        
        // Simulate email sending for demo purposes
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Return success for demonstration
        // In real implementation, this would connect to SMTP server and send email
        return true
    }
    
    // MARK: - Email Content Generation
    
    private func createEmailBody(from notification: AppNotification) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        <html>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #007AFF;">LifeManager Notification</h2>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3>\(notification.title)</h3>
                    <p>\(notification.body)</p>
                    
                    <div style="margin-top: 15px; font-size: 14px; color: #666;">
                        <p><strong>Time:</strong> \(formatter.string(from: notification.scheduledTime))</p>
                        <p><strong>Priority:</strong> \(notification.priority.displayName)</p>
                    </div>
                </div>
                
                <div style="background-color: #e3f2fd; padding: 15px; border-radius: 8px; border-left: 4px solid #007AFF;">
                    <p style="margin: 0; font-size: 14px;">
                        <strong>Note:</strong> This email was sent because you didn't respond to the in-app notification within 30 minutes.
                        Open LifeManager to manage your tasks and schedule.
                    </p>
                </div>
                
                <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
                    <p style="font-size: 12px; color: #999;">
                        Sent by LifeManager • \(formatter.string(from: Date()))
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Settings Persistence
    
    private func saveSettings() {
        userDefaults.set(isEnabled, forKey: "EmailNotifications.isEnabled")
        userDefaults.set(userEmail, forKey: "EmailNotifications.userEmail")
        
        if let settings = smtpSettings {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(settings) {
                userDefaults.set(data, forKey: "EmailNotifications.smtpSettings")
            }
        } else {
            userDefaults.removeObject(forKey: "EmailNotifications.smtpSettings")
        }
    }
    
    private func loadSettings() {
        isEnabled = userDefaults.bool(forKey: "EmailNotifications.isEnabled")
        userEmail = userDefaults.string(forKey: "EmailNotifications.userEmail") ?? ""
        
        if let data = userDefaults.data(forKey: "EmailNotifications.smtpSettings") {
            let decoder = JSONDecoder()
            smtpSettings = try? decoder.decode(SMTPSettings.self, from: data)
        }
    }
}

// MARK: - Supporting Models

struct SMTPSettings: Codable {
    let host: String
    let port: Int
    let username: String
    let password: String
    let useSSL: Bool
}

struct EmailContent {
    let to: String
    let subject: String
    let body: String
    let isHTML: Bool
}

struct PendingEmailNotification {
    let id: UUID
    let originalNotificationId: UUID
    let scheduledTime: Date
    let subject: String
    let body: String
    let priority: NotificationPriority
}

struct AppNotification {
    let id: UUID
    let title: String
    let body: String
    let scheduledTime: Date
    let priority: NotificationPriority
}

// NotificationPriority is now defined in IntelligentSchedulingModels.swift 