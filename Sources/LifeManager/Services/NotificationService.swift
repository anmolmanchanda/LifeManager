import Foundation

/// Simple notification service stub
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    func showNotification(_ message: String) {
        print("NOTIFICATION: \(message)")
    }
    
    func scheduleNotification(at date: Date, message: String) {
        print("SCHEDULED NOTIFICATION for \(date): \(message)")
    }
    
    func scheduleBufferViolationWarning(_ warning: String) {
        print("BUFFER WARNING: \(warning)")
    }
    
    func scheduleBufferViolationWarning(remainingBuffer: Int, hoursAffected: Int) async {
        print("BUFFER VIOLATION: \(remainingBuffer) minutes remaining, \(hoursAffected) hours affected")
    }
    
    func scheduleAutoBumpNotification(_ message: String) {
        print("AUTO BUMP: \(message)")
    }
    
    func scheduleAutoBumpNotification(eventTitle: String, bumpedByMinutes: Int, originalTime: Date) async {
        print("AUTO BUMP: \(eventTitle) bumped by \(bumpedByMinutes) minutes from \(originalTime)")
    }
    
    func scheduleCascadeBumpNotification(_ message: String) {
        print("CASCADE BUMP: \(message)")
    }
    
    func scheduleCascadeBumpNotification(eventCount: Int) async {
        print("CASCADE BUMP: \(eventCount) events affected")
    }
    
    func scheduleBufferWarning(_ warning: String = "Buffer violation detected") {
        print("BUFFER WARNING: \(warning)")
    }
    
    func scheduleEscalatedWarning(_ warning: String = "Escalated buffer warning") {
        print("ESCALATED WARNING: \(warning)")
    }
    
    func scheduleStaleEventNotification(_ message: String) {
        print("STALE EVENT: \(message)")
    }
    
    func scheduleStaleEventNotification(eventCount: Int) async {
        print("STALE EVENT: \(eventCount) stale events found")
    }
}