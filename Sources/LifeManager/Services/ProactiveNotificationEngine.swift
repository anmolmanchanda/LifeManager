import Foundation

/// Proactive notification engine stub
class ProactiveNotificationEngine: ObservableObject {
    static let shared = ProactiveNotificationEngine()
    
    private init() {}
    
    @Published var isActive = false
    
    func startProactiveNotifications() {
        isActive = true
    }
    
    func stopProactiveNotifications() {
        isActive = false
    }
    
    func sendAchievementNotification(_ message: String) {
        print("ACHIEVEMENT: \(message)")
    }
}