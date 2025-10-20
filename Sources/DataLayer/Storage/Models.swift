import Foundation

// MARK: - Contact Model
struct Contact: Identifiable, Codable, Hashable {
    let id: String // phone number or email
    let name: String?
    let lastMessageDate: Date
    let totalMessages: Int
    let sentByUser: Int
    let receivedByUser: Int
    let daysSinceLastMessage: Int
    let importanceScore: Double
    
    var displayName: String {
        name ?? id
    }
    
    var initials: String {
        if let name = name {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                return String(components[0].prefix(1)) + String(components[1].prefix(1))
            } else if let first = components.first {
                return String(first.prefix(2))
            }
        }
        return String(id.prefix(2)).uppercased()
    }
}

// MARK: - Conversation Stats
struct ConversationStats: Codable {
    let contactId: String
    let messageFrequency: [Date: Int] // Date histogram
    let avgResponseTime: TimeInterval
    let initiationRatio: Double // % of conversations started by user
    let sentiment: String? // from OpenAI
    
    enum CodingKeys: String, CodingKey {
        case contactId, avgResponseTime, initiationRatio, sentiment, messageFrequency
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contactId, forKey: .contactId)
        try container.encode(avgResponseTime, forKey: .avgResponseTime)
        try container.encode(initiationRatio, forKey: .initiationRatio)
        try container.encode(sentiment, forKey: .sentiment)
        
        // Encode dictionary with date timestamps
        let frequencyDict = messageFrequency.reduce(into: [String: Int]()) { result, item in
            result[String(item.key.timeIntervalSince1970)] = item.value
        }
        try container.encode(frequencyDict, forKey: .messageFrequency)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contactId = try container.decode(String.self, forKey: .contactId)
        avgResponseTime = try container.decode(TimeInterval.self, forKey: .avgResponseTime)
        initiationRatio = try container.decode(Double.self, forKey: .initiationRatio)
        sentiment = try container.decodeIfPresent(String.self, forKey: .sentiment)
        
        // Decode dictionary back to Date keys
        let frequencyDict = try container.decode([String: Int].self, forKey: .messageFrequency)
        messageFrequency = frequencyDict.reduce(into: [Date: Int]()) { result, item in
            if let timestamp = TimeInterval(item.key) {
                result[Date(timeIntervalSince1970: timestamp)] = item.value
            }
        }
    }
    
    init(contactId: String, messageFrequency: [Date: Int], avgResponseTime: TimeInterval, initiationRatio: Double, sentiment: String? = nil) {
        self.contactId = contactId
        self.messageFrequency = messageFrequency
        self.avgResponseTime = avgResponseTime
        self.initiationRatio = initiationRatio
        self.sentiment = sentiment
    }
}

// MARK: - Message Model (from iMessage DB)
struct Message: Identifiable {
    let id: Int
    let text: String?
    let attributedBody: Data?
    let handleId: String
    let date: Date
    let isFromMe: Bool
    let chatId: Int
    let attachments: [Attachment]
    
    struct Attachment {
        let filename: String?
        let mimeType: String?
        let transferName: String?
    }
}

// MARK: - Chat Model
struct Chat {
    let id: Int
    let guid: String
    let chatIdentifier: String?
    let displayName: String?
    let participants: [String] // handle IDs
}

