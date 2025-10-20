import Foundation
import OpenAISwift

class OpenAIService {
    static let shared = OpenAIService()
    
    private var client: OpenAISwift?
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        // Check for API key in UserDefaults
        if let apiKey = UserDefaults.standard.string(forKey: "openAIKey"), !apiKey.isEmpty {
            let config = OpenAISwift.Config(apiKey: apiKey)
            client = OpenAISwift(config: config)
        }
    }
    
    func updateAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openAIKey")
        setupClient()
    }
    
    func analyzeSentiment(messages: [String]) async -> String? {
        guard let client = client else {
            print("OpenAI client not configured")
            return nil
        }
        
        // Take a sample of recent messages
        let sample = messages.prefix(20).joined(separator: "\n")
        
        let prompt = """
        Analyze the sentiment and tone of this conversation. Provide a brief 1-2 sentence summary:
        
        \(sample)
        """
        
        do {
            let result = try await client.sendCompletion(
                with: prompt,
                model: .gpt4(.gpt4),
                maxTokens: 100
            )
            
            return result.choices?.first?.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            print("OpenAI API error: \(error)")
            return nil
        }
    }
    
    func generateReachOutSuggestion(contact: Contact, recentMessages: [String]) async -> String? {
        guard let client = client else { return nil }
        
        let messagesPreview = recentMessages.prefix(10).joined(separator: "\n")
        
        let prompt = """
        Based on this conversation history with \(contact.displayName), suggest a friendly and natural message to reach out after \(contact.daysSinceLastMessage) days of no contact:
        
        Recent messages:
        \(messagesPreview)
        
        Provide only the suggested message, no explanation:
        """
        
        do {
            let result = try await client.sendCompletion(
                with: prompt,
                model: .gpt4,
                maxTokens: 150
            )
            
            return result.choices?.first?.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch {
            print("OpenAI API error: \(error)")
            return nil
        }
    }
    
    func identifyTopics(messages: [String]) async -> [String]? {
        guard let client = client else { return nil }
        
        let sample = messages.prefix(50).joined(separator: "\n")
        
        let prompt = """
        Identify the top 3-5 main topics discussed in this conversation. List them as comma-separated keywords:
        
        \(sample)
        
        Topics:
        """
        
        do {
            let result = try await client.sendCompletion(
                with: prompt,
                model: .gpt4,
                maxTokens: 50
            )
            
            if let topicsString = result.choices?.first?.text {
                return topicsString
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            }
        } catch {
            print("OpenAI API error: \(error)")
        }
        
        return nil
    }
    
    var isConfigured: Bool {
        client != nil
    }
}

