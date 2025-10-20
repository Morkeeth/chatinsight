import Foundation
import GRDB

class LocalDatabase {
    static let shared = LocalDatabase()
    
    private var dbQueue: DatabaseQueue?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("ChatInsights", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        let dbPath = appDirectory.appendingPathComponent("analytics.db").path
        
        do {
            dbQueue = try DatabaseQueue(path: dbPath)
            try createTables()
        } catch {
            print("Error setting up local database: \(error)")
        }
    }
    
    private func createTables() throws {
        try dbQueue?.write { db in
            // Contacts cache table
            try db.create(table: "cached_contacts", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text)
                t.column("lastMessageDate", .datetime).notNull()
                t.column("totalMessages", .integer).notNull()
                t.column("sentByUser", .integer).notNull()
                t.column("receivedByUser", .integer).notNull()
                t.column("daysSinceLastMessage", .integer).notNull()
                t.column("importanceScore", .double).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Conversation stats cache table
            try db.create(table: "conversation_stats", ifNotExists: true) { t in
                t.column("contactId", .text).primaryKey()
                t.column("avgResponseTime", .double).notNull()
                t.column("initiationRatio", .double).notNull()
                t.column("sentiment", .text)
                t.column("messageFrequency", .text) // JSON-encoded dictionary
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Analysis history table
            try db.create(table: "analysis_history", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("analyzedAt", .datetime).notNull()
                t.column("contactCount", .integer).notNull()
                t.column("messageCount", .integer).notNull()
                t.column("reachOutSuggestions", .integer).notNull()
            }
        }
    }
    
    // MARK: - Contact Operations
    
    func saveContacts(_ contacts: [Contact]) async throws {
        try await dbQueue?.write { db in
            for contact in contacts {
                try db.execute(
                    sql: """
                    INSERT OR REPLACE INTO cached_contacts 
                    (id, name, lastMessageDate, totalMessages, sentByUser, receivedByUser, 
                     daysSinceLastMessage, importanceScore, updatedAt)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        contact.id,
                        contact.name,
                        contact.lastMessageDate,
                        contact.totalMessages,
                        contact.sentByUser,
                        contact.receivedByUser,
                        contact.daysSinceLastMessage,
                        contact.importanceScore,
                        Date()
                    ]
                )
            }
        }
    }
    
    func loadContacts() async -> [Contact]? {
        try? await dbQueue?.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT * FROM cached_contacts 
                ORDER BY importanceScore DESC
                """)
            
            return rows.map { row in
                Contact(
                    id: row["id"],
                    name: row["name"],
                    lastMessageDate: row["lastMessageDate"],
                    totalMessages: row["totalMessages"],
                    sentByUser: row["sentByUser"],
                    receivedByUser: row["receivedByUser"],
                    daysSinceLastMessage: row["daysSinceLastMessage"],
                    importanceScore: row["importanceScore"]
                )
            }
        }
    }
    
    // MARK: - Stats Operations
    
    func saveConversationStats(_ stats: ConversationStats) async throws {
        let frequencyJSON = try JSONEncoder().encode(stats.messageFrequency)
        let frequencyString = String(data: frequencyJSON, encoding: .utf8)
        
        try await dbQueue?.write { db in
            try db.execute(
                sql: """
                INSERT OR REPLACE INTO conversation_stats 
                (contactId, avgResponseTime, initiationRatio, sentiment, messageFrequency, updatedAt)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    stats.contactId,
                    stats.avgResponseTime,
                    stats.initiationRatio,
                    stats.sentiment,
                    frequencyString,
                    Date()
                ]
            )
        }
    }
    
    func logAnalysis(contactCount: Int, messageCount: Int, suggestionCount: Int) async {
        try? await dbQueue?.write { db in
            try db.execute(
                sql: """
                INSERT INTO analysis_history (analyzedAt, contactCount, messageCount, reachOutSuggestions)
                VALUES (?, ?, ?, ?)
                """,
                arguments: [Date(), contactCount, messageCount, suggestionCount]
            )
        }
    }
}

