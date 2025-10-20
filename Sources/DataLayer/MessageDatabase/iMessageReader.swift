import Foundation
import GRDB

class iMessageReader {
    static let shared = iMessageReader()
    
    private var dbQueue: DatabaseQueue?
    private var databasePath: String?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        // Try to get database path from user defaults
        if let path = UserDefaults.standard.string(forKey: "iMessageDatabasePath") {
            databasePath = path
        } else {
            // Default path
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            databasePath = homeDirectory
                .appendingPathComponent("Library/Messages/chat.db")
                .path
        }
        
        // Restore bookmark if available
        if let bookmarkData = UserDefaults.standard.data(forKey: "iMessageDatabaseBookmark") {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                _ = url.startAccessingSecurityScopedResource()
                databasePath = url.path
            }
        }
        
        // Open database
        if let path = databasePath, FileManager.default.fileExists(atPath: path) {
            do {
                dbQueue = try DatabaseQueue(path: path)
            } catch {
                print("Error opening iMessage database: \(error)")
            }
        }
    }
    
    func fetchMessages(limit: Int = 10000) async -> [Message]? {
        guard let dbQueue = dbQueue else {
            print("Database not available")
            return nil
        }
        
        return try? await dbQueue.read { db in
            var messages: [Message] = []
            
            // Query messages with handles
            let sql = """
                SELECT 
                    m.ROWID,
                    m.guid,
                    m.text,
                    m.attributedBody,
                    m.handle_id,
                    m.date,
                    m.is_from_me,
                    m.cache_has_attachments,
                    h.id as contact_id,
                    cmj.chat_id
                FROM message m
                LEFT JOIN handle h ON m.handle_id = h.ROWID
                LEFT JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
                WHERE m.date > 0
                ORDER BY m.date DESC
                LIMIT ?
                """
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: [limit])
            
            for row in rows {
                let messageId = row["ROWID"] as Int64
                let text = row["text"] as? String
                let attributedBody = row["attributedBody"] as? Data
                let handleId = row["contact_id"] as? String ?? "Unknown"
                let date = row["date"] as? Int64 ?? 0
                let isFromMe = (row["is_from_me"] as? Int64 ?? 0) != 0
                let chatId = row["chat_id"] as? Int64 ?? 0
                let hasAttachments = (row["cache_has_attachments"] as? Int64 ?? 0) != 0
                
                // Decode message text
                var messageText = text
                if messageText == nil || messageText?.isEmpty == true, let bodyData = attributedBody {
                    // Try to decode attributedBody
                    messageText = TypedstreamDecoder.decodeWithUnarchiver(data: bodyData)
                        ?? TypedstreamDecoder.decode(attributedBody: bodyData)
                }
                
                // Fetch attachments if present
                var attachments: [Message.Attachment] = []
                if hasAttachments {
                    let attachmentSQL = """
                        SELECT a.filename, a.mime_type, a.transfer_name
                        FROM attachment a
                        JOIN message_attachment_join maj ON a.ROWID = maj.attachment_id
                        WHERE maj.message_id = ?
                        """
                    let attachmentRows = try Row.fetchAll(db, sql: attachmentSQL, arguments: [messageId])
                    
                    for attRow in attachmentRows {
                        attachments.append(Message.Attachment(
                            filename: attRow["filename"] as? String,
                            mimeType: attRow["mime_type"] as? String,
                            transferName: attRow["transfer_name"] as? String
                        ))
                    }
                }
                
                // Convert date
                let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
                let messageDate = referenceDate.addingTimeInterval(TimeInterval(date) / 1_000_000_000)
                
                let message = Message(
                    id: Int(messageId),
                    text: messageText,
                    attributedBody: attributedBody,
                    handleId: handleId,
                    date: messageDate,
                    isFromMe: isFromMe,
                    chatId: Int(chatId),
                    attachments: attachments
                )
                
                messages.append(message)
            }
            
            return messages
        }
    }
    
    func fetchChats() async -> [Chat]? {
        guard let dbQueue = dbQueue else { return nil }
        
        return try? await dbQueue.read { db in
            var chats: [Chat] = []
            
            let chatRecords = try ChatRecord.fetchAll(db)
            
            for chatRecord in chatRecords {
                // Get participants
                let participantSQL = """
                    SELECT h.id
                    FROM handle h
                    JOIN chat_handle_join chj ON h.ROWID = chj.handle_id
                    WHERE chj.chat_id = ?
                    """
                let participantRows = try Row.fetchAll(db, sql: participantSQL, arguments: [chatRecord.ROWID])
                let participants = participantRows.compactMap { $0["id"] as? String }
                
                let chat = Chat(
                    id: Int(chatRecord.ROWID),
                    guid: chatRecord.guid,
                    chatIdentifier: chatRecord.chat_identifier,
                    displayName: chatRecord.display_name,
                    participants: participants
                )
                
                chats.append(chat)
            }
            
            return chats
        }
    }
    
    func getContactName(for handleId: String) async -> String? {
        // Try to get name from Contacts framework
        // For now, return the handle ID
        // TODO: Integrate with Contacts.framework
        return nil
    }
}

