import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func sendWeeklyReminder(suggestions: [Contact]) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Reach Out!"
        content.body = ReachOutSuggestor.shared.getNotificationMessage(for: suggestions)
        content.sound = .default
        content.categoryIdentifier = "REACH_OUT"
        
        // Add contact names to user info for potential actions
        let contactInfo = suggestions.prefix(5).map { ["id": $0.id, "name": $0.displayName] }
        content.userInfo = ["contacts": contactInfo]
        
        // Trigger immediately (will be called by scheduler at right time)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "weekly-reach-out-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ChatInsights Test"
        content.body = "Notifications are working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

