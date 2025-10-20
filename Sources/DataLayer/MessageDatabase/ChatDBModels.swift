import Foundation
import GRDB

// MARK: - Database Record Models
struct MessageRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "message"
    
    let ROWID: Int64
    let guid: String
    let text: String?
    let attributedBody: Data?
    let handle_id: Int64?
    let date: Int64
    let date_read: Int64?
    let date_delivered: Int64?
    let is_from_me: Int64
    let is_read: Int64
    let cache_has_attachments: Int64
    let associated_message_guid: String?
    let associated_message_type: Int64?
    
    var dateValue: Date {
        // iMessage stores dates as nanoseconds since 2001-01-01
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        return referenceDate.addingTimeInterval(TimeInterval(date) / 1_000_000_000)
    }
    
    var isFromMe: Bool {
        is_from_me != 0
    }
    
    var hasAttachments: Bool {
        cache_has_attachments != 0
    }
}

struct HandleRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "handle"
    
    let ROWID: Int64
    let id: String
    let country: String?
    let service: String
    let uncanonicalized_id: String?
}

struct ChatRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "chat"
    
    let ROWID: Int64
    let guid: String
    let style: Int64
    let state: Int64
    let account_id: String?
    let chat_identifier: String?
    let service_name: String?
    let room_name: String?
    let account_login: String?
    let display_name: String?
}

struct ChatMessageJoinRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "chat_message_join"
    
    let chat_id: Int64
    let message_id: Int64
    let message_date: Int64
}

struct ChatHandleJoinRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "chat_handle_join"
    
    let chat_id: Int64
    let handle_id: Int64
}

struct AttachmentRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "attachment"
    
    let ROWID: Int64
    let guid: String
    let created_date: Int64?
    let filename: String?
    let mime_type: String?
    let transfer_name: String?
    let total_bytes: Int64?
}

struct MessageAttachmentJoinRecord: Codable, FetchableRecord, TableRecord {
    static let databaseTableName = "message_attachment_join"
    
    let message_id: Int64
    let attachment_id: Int64
}

