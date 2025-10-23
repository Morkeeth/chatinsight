import Foundation
import GRDB

/// Messages tool - provides access to iMessage history
public class MessagesTool: MCPToolProtocol {
    public let name = "fetchMessages"
    public let description = "Fetch messages with specific participants within a date range. Returns messages as JSON-LD formatted data."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "participant": [
                    "type": "string",
                    "description": "Phone number or email of the conversation participant (e.g., '+12345678901' or 'name@example.com')"
                ],
                "startDate": [
                    "type": "string",
                    "description": "Start date in ISO 8601 format (e.g., '2024-01-01T00:00:00Z'). Defaults to 30 days ago if not specified."
                ],
                "endDate": [
                    "type": "string",
                    "description": "End date in ISO 8601 format (e.g., '2024-12-31T23:59:59Z'). Defaults to now if not specified."
                ],
                "limit": [
                    "type": "number",
                    "description": "Maximum number of messages to return. Defaults to 100."
                ]
            ]
        ]
    }
    
    private let databasePath: String
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    public init(databasePath: String) {
        self.databasePath = databasePath
    }
    
    public func execute(arguments: [String: Any]) async throws -> String {
        // Parse arguments
        let participant = arguments["participant"] as? String
        let limit = arguments["limit"] as? Int ?? 100
        
        // Parse dates
        let endDate = parseDate(arguments["endDate"] as? String) ?? Date()
        let startDate = parseDate(arguments["startDate"] as? String) ?? Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        // Open database
        guard FileManager.default.fileExists(atPath: databasePath) else {
            throw MCPToolError.permissionDenied("iMessage database not accessible. Please grant access through the app.")
        }
        
        let dbQueue = try DatabaseQueue(path: databasePath)
        
        // Fetch messages
        let messages = try await dbQueue.read { [self] db in
            try self.fetchMessages(
                db: db,
                participant: participant,
                startDate: startDate,
                endDate: endDate,
                limit: limit
            )
        }
        
        // Convert to JSON-LD
        let jsonLDMessages = messages.map { message in
            convertMessageToJSONLD(message)
        }
        
        return formatJSONLDArray(jsonLDMessages)
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return isoFormatter.date(from: dateString)
    }
    
    private func fetchMessages(
        db: Database,
        participant: String?,
        startDate: Date,
        endDate: Date,
        limit: Int
    ) throws -> [MessageRecord] {
        // Convert dates to Apple's reference date format (nanoseconds since 2001-01-01)
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        let startTimestamp = Int64(startDate.timeIntervalSince(referenceDate) * 1_000_000_000)
        let endTimestamp = Int64(endDate.timeIntervalSince(referenceDate) * 1_000_000_000)
        
        var sql = """
            SELECT 
                m.ROWID,
                m.guid,
                m.text,
                m.attributedBody,
                m.date,
                m.is_from_me,
                h.id as handle_id,
                h.service as service
            FROM message m
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE m.date >= ? AND m.date <= ?
            """
        
        var arguments: [DatabaseValueConvertible] = [startTimestamp, endTimestamp]
        
        if let participant = participant {
            sql += " AND h.id LIKE ?"
            arguments.append("%\(participant)%")
        }
        
        sql += " ORDER BY m.date DESC LIMIT ?"
        arguments.append(limit)
        
        let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
        
        return rows.map { row in
            MessageRecord(
                id: row["ROWID"] ?? 0,
                guid: row["guid"] ?? "",
                text: row["text"],
                attributedBody: row["attributedBody"],
                date: row["date"] ?? 0,
                isFromMe: (row["is_from_me"] as? Int64 ?? 0) != 0,
                handleId: row["handle_id"] ?? "Unknown",
                service: row["service"] ?? "iMessage"
            )
        }
    }
    
    private func convertMessageToJSONLD(_ message: MessageRecord) -> [String: Any] {
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(message.date) / 1_000_000_000)
        let dateString = isoFormatter.string(from: date)
        
        let sender = message.isFromMe ? "You" : message.handleId
        let recipient = message.isFromMe ? message.handleId : "You"
        
        var text = message.text ?? ""
        if text.isEmpty, let bodyData = message.attributedBody {
            // Try to decode attributedBody
            text = decodeAttributedBody(bodyData) ?? "[Message content unavailable]"
        }
        
        let jsonLD = JSONLD.Message(
            dateCreated: dateString,
            text: text.isEmpty ? nil : text,
            sender: JSONLD.Person(name: sender),
            recipient: JSONLD.Person(name: recipient)
        )
        
        return jsonLD.toJSONLD()
    }
    
    private func decodeAttributedBody(_ data: Data) -> String? {
        // Try NSKeyedUnarchiver first
        if let attributed = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self,
            from: data
        ) {
            return attributed.string
        }
        
        // Try typedstream decoder (simplified version)
        // Note: Full implementation would use TypedstreamDecoder
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
}

// MARK: - Data Models

struct MessageRecord {
    let id: Int64
    let guid: String
    let text: String?
    let attributedBody: Data?
    let date: Int64
    let isFromMe: Bool
    let handleId: String
    let service: String
}

