import Foundation

class SchedulerService {
    static let shared = SchedulerService()
    
    private var weeklyTimer: Timer?
    
    private init() {}
    
    func scheduleWeeklyAnalysis() {
        // Cancel existing timer
        cancelWeeklyAnalysis()
        
        // Get configured day and time
        let notificationDay = UserDefaults.standard.integer(forKey: "notificationDay") // 0 = Sunday
        
        // Calculate next notification time
        guard let nextDate = calculateNextNotificationDate(weekday: notificationDay) else {
            return
        }
        
        let timeInterval = nextDate.timeIntervalSinceNow
        
        // Schedule timer
        weeklyTimer = Timer.scheduledTimer(withTimeInterval: max(timeInterval, 1), repeats: false) { [weak self] _ in
            self?.performWeeklyAnalysis()
            // Reschedule for next week
            self?.scheduleWeeklyAnalysis()
        }
        
        print("Scheduled next analysis for \(nextDate)")
    }
    
    func cancelWeeklyAnalysis() {
        weeklyTimer?.invalidate()
        weeklyTimer = nil
    }
    
    private func calculateNextNotificationDate(weekday: Int) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Target time: 6 PM
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: now)
        components.hour = 18
        components.minute = 0
        components.second = 0
        
        // Find next occurrence of target weekday
        let currentWeekday = calendar.component(.weekday, from: now) - 1 // 0-indexed
        let targetWeekday = weekday
        
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: now)
    }
    
    private func performWeeklyAnalysis() {
        Task {
            print("Performing weekly analysis...")
            
            // Fetch and analyze messages
            guard let messages = await iMessageReader.shared.fetchMessages() else {
                print("Failed to fetch messages")
                return
            }
            
            let analyzer = ContactAnalyzer()
            let contacts = await analyzer.analyzeContacts(from: messages)
            let suggestions = ReachOutSuggestor.shared.getSuggestions(from: contacts)
            
            // Save to database
            try? await LocalDatabase.shared.saveContacts(contacts)
            await LocalDatabase.shared.logAnalysis(
                contactCount: contacts.count,
                messageCount: messages.count,
                suggestionCount: suggestions.count
            )
            
            // Save last analyzed date
            UserDefaults.standard.set(Date(), forKey: "lastAnalyzedDate")
            
            // Send notification if there are suggestions
            if ReachOutSuggestor.shared.shouldNotifyUser(suggestions: suggestions) {
                NotificationManager.shared.sendWeeklyReminder(suggestions: suggestions)
            }
            
            print("Weekly analysis complete: \(contacts.count) contacts, \(suggestions.count) suggestions")
        }
    }
    
    // Public method to trigger analysis manually
    func triggerManualAnalysis() {
        performWeeklyAnalysis()
    }
}

