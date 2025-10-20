import Foundation

class ContactAnalyzer {
    private let minMessagesThreshold: Int
    
    init() {
        self.minMessagesThreshold = UserDefaults.standard.integer(forKey: "minMessagesForImportance")
        if self.minMessagesThreshold == 0 {
            UserDefaults.standard.set(10, forKey: "minMessagesForImportance")
        }
    }
    
    func analyzeContacts(from messages: [Message]) async -> [Contact] {
        // Group messages by contact
        var contactMessages: [String: [Message]] = [:]
        
        for message in messages {
            let contactId = message.handleId
            contactMessages[contactId, default: []].append(message)
        }
        
        var contacts: [Contact] = []
        
        for (contactId, messages) in contactMessages {
            guard messages.count >= minMessagesThreshold else { continue }
            
            let sortedMessages = messages.sorted { $0.date > $1.date }
            guard let lastMessage = sortedMessages.first else { continue }
            
            let sentByUser = messages.filter { $0.isFromMe }.count
            let receivedByUser = messages.count - sentByUser
            
            let daysSinceLastMessage = Calendar.current.dateComponents(
                [.day],
                from: lastMessage.date,
                to: Date()
            ).day ?? 0
            
            let importanceScore = calculateImportance(
                messageCount: messages.count,
                daysSinceLast: daysSinceLastMessage,
                sentByUser: sentByUser,
                receivedByUser: receivedByUser
            )
            
            let contact = Contact(
                id: contactId,
                name: await iMessageReader.shared.getContactName(for: contactId),
                lastMessageDate: lastMessage.date,
                totalMessages: messages.count,
                sentByUser: sentByUser,
                receivedByUser: receivedByUser,
                daysSinceLastMessage: daysSinceLastMessage,
                importanceScore: importanceScore
            )
            
            contacts.append(contact)
        }
        
        // Sort by importance score
        return contacts.sorted { $0.importanceScore > $1.importanceScore }
    }
    
    func getConversationStats(for contactId: String) async -> ConversationStats? {
        guard let messages = await iMessageReader.shared.fetchMessages() else {
            return nil
        }
        
        let contactMessages = messages.filter { $0.handleId == contactId }
        guard !contactMessages.isEmpty else { return nil }
        
        // Calculate message frequency by day
        var frequencyByDay: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for message in contactMessages {
            let day = calendar.startOfDay(for: message.date)
            frequencyByDay[day, default: 0] += 1
        }
        
        // Calculate average response time
        let avgResponseTime = calculateAverageResponseTime(messages: contactMessages)
        
        // Calculate initiation ratio (% of conversations started by user)
        let initiationRatio = calculateInitiationRatio(messages: contactMessages)
        
        return ConversationStats(
            contactId: contactId,
            messageFrequency: frequencyByDay,
            avgResponseTime: avgResponseTime,
            initiationRatio: initiationRatio,
            sentiment: nil // Will be populated by OpenAI service
        )
    }
    
    private func calculateImportance(
        messageCount: Int,
        daysSinceLast: Int,
        sentByUser: Int,
        receivedByUser: Int
    ) -> Double {
        // Frequency component (normalized)
        let frequencyScore = min(Double(messageCount) / 1000.0, 1.0)
        
        // Recency component (decays over time)
        let recencyWeight = 1.0 / (Double(daysSinceLast) + 1.0)
        let recencyScore = min(recencyWeight * 30.0, 1.0) // Normalize to 30 days
        
        // Balance component (prefer balanced conversations)
        let balance = Double(min(sentByUser, receivedByUser)) / Double(max(sentByUser, receivedByUser, 1))
        let balanceScore = balance
        
        // Weighted combination
        let importance = (frequencyScore * 0.4) + (recencyScore * 0.4) + (balanceScore * 0.2)
        
        return importance
    }
    
    private func calculateAverageResponseTime(messages: [Message]) -> TimeInterval {
        let sortedMessages = messages.sorted { $0.date < $1.date }
        var responseTimes: [TimeInterval] = []
        
        for i in 0..<sortedMessages.count - 1 {
            let current = sortedMessages[i]
            let next = sortedMessages[i + 1]
            
            // If sender switches, it's a response
            if current.isFromMe != next.isFromMe {
                let responseTime = next.date.timeIntervalSince(current.date)
                // Only count reasonable response times (< 24 hours)
                if responseTime > 0 && responseTime < 86400 {
                    responseTimes.append(responseTime)
                }
            }
        }
        
        if responseTimes.isEmpty {
            return 0
        }
        
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    private func calculateInitiationRatio(messages: [Message]) -> Double {
        let sortedMessages = messages.sorted { $0.date < $1.date }
        var userInitiated = 0
        var totalConversations = 0
        
        // Define conversation gap (30 minutes)
        let conversationGap: TimeInterval = 1800
        
        var lastMessageDate: Date?
        
        for message in sortedMessages {
            if let lastDate = lastMessageDate {
                let timeSinceLastMessage = message.date.timeIntervalSince(lastDate)
                
                // New conversation if gap is large enough
                if timeSinceLastMessage > conversationGap {
                    totalConversations += 1
                    if message.isFromMe {
                        userInitiated += 1
                    }
                }
            } else {
                // First message
                totalConversations += 1
                if message.isFromMe {
                    userInitiated += 1
                }
            }
            
            lastMessageDate = message.date
        }
        
        if totalConversations == 0 {
            return 0.5
        }
        
        return Double(userInitiated) / Double(totalConversations)
    }
}

