import Foundation

class ReachOutSuggestor {
    static let shared = ReachOutSuggestor()
    
    private init() {}
    
    func getSuggestions(from contacts: [Contact], limit: Int = 10) -> [Contact] {
        let thresholdDays = UserDefaults.standard.integer(forKey: "reachOutThresholdDays")
        let threshold = thresholdDays > 0 ? thresholdDays : 14
        
        // Filter contacts that haven't been contacted in threshold days
        let stalledContacts = contacts.filter { contact in
            contact.daysSinceLastMessage >= threshold
        }
        
        // Sort by importance score (higher = more important to reach out to)
        let sorted = stalledContacts.sorted { contact1, contact2 in
            // Prioritize by importance and recency
            let score1 = contact1.importanceScore * Double(contact1.daysSinceLastMessage)
            let score2 = contact2.importanceScore * Double(contact2.daysSinceLastMessage)
            return score1 > score2
        }
        
        return Array(sorted.prefix(limit))
    }
    
    func shouldNotifyUser(suggestions: [Contact]) -> Bool {
        // Check if notifications are enabled
        guard UserDefaults.standard.bool(forKey: "weeklyNotificationsEnabled") else {
            return false
        }
        
        // Check if there are meaningful suggestions
        return !suggestions.isEmpty && suggestions.count >= 3
    }
    
    func getNotificationMessage(for suggestions: [Contact]) -> String {
        let count = min(suggestions.count, 5)
        let names = suggestions.prefix(count).map { $0.displayName }
        
        if count == 1 {
            return "Time to reach out to \(names[0])!"
        } else if count == 2 {
            return "Reach out to \(names[0]) and \(names[1])"
        } else {
            let firstTwo = names.prefix(2).joined(separator: ", ")
            let remaining = count - 2
            return "Reach out to \(firstTwo) and \(remaining) other\(remaining > 1 ? "s" : "")"
        }
    }
}

