import Foundation
import EventKit

/// Reminders tool - provides access to reminders
public class RemindersTool: MCPToolProtocol {
    public let name = "fetchReminders"
    public let description = "Fetch reminders, optionally filtered by completion status or list name."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "completed": [
                    "type": "boolean",
                    "description": "Filter by completion status. If not specified, returns all reminders."
                ],
                "listName": [
                    "type": "string",
                    "description": "Optional name of reminder list to filter by"
                ],
                "limit": [
                    "type": "number",
                    "description": "Maximum number of reminders to return. Defaults to 50."
                ]
            ]
        ]
    }
    
    private let eventStore = EKEventStore()
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    public init() {}
    
    public func execute(arguments: [String: Any]) async throws -> String {
        // Request access
        if #available(macOS 14.0, *) {
            let granted = try await eventStore.requestFullAccessToReminders()
            guard granted else {
                throw MCPToolError.permissionDenied("Reminders access denied. Please grant access through System Settings.")
            }
        }
        
        let completedFilter = arguments["completed"] as? Bool
        let listName = arguments["listName"] as? String
        let limit = arguments["limit"] as? Int ?? 50
        
        // Fetch reminders
        let reminders = try await fetchReminders(
            completed: completedFilter,
            listName: listName,
            limit: limit
        )
        
        // Convert to JSON-LD (using Action type from Schema.org)
        let jsonLDReminders = reminders.map { reminder in
            convertReminderToJSONLD(reminder)
        }
        
        return formatJSONLDArray(jsonLDReminders)
    }
    
    private func fetchReminders(completed: Bool?, listName: String?, limit: Int) async throws -> [EKReminder] {
        var calendars = eventStore.calendars(for: .reminder)
        
        // Filter by list name if provided
        if let name = listName {
            calendars = calendars.filter { $0.title == name }
        }
        
        let predicate = eventStore.predicateForReminders(in: calendars)
        
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                guard let reminders = reminders else {
                    continuation.resume(throwing: MCPToolError.executionFailed("Failed to fetch reminders"))
                    return
                }
                
                var filtered = reminders
                
                // Filter by completion status
                if let completed = completed {
                    filtered = filtered.filter { $0.isCompleted == completed }
                }
                
                // Limit results
                filtered = Array(filtered.prefix(limit))
                
                continuation.resume(returning: filtered)
            }
        }
    }
    
    private func convertReminderToJSONLD(_ reminder: EKReminder) -> [String: Any] {
        var props: [String: Any] = [
            "name": reminder.title ?? "Untitled",
            "actionStatus": reminder.isCompleted ? "CompletedActionStatus" : "PotentialActionStatus"
        ]
        
        if let dueDate = reminder.dueDateComponents?.date {
            props["scheduledTime"] = isoFormatter.string(from: dueDate)
        }
        
        if let notes = reminder.notes {
            props["description"] = notes
        }
        
        props["priority"] = priorityString(reminder.priority)
        
        if let calendar = reminder.calendar {
            props["location"] = calendar.title
        }
        
        return JSONLD.object(type: "Action", properties: props)
    }
    
    private func priorityString(_ priority: Int) -> String {
        switch priority {
        case 1: return "High"
        case 5: return "Medium"
        case 9: return "Low"
        default: return "None"
        }
    }
}

/// Create Reminder tool
public class CreateReminderTool: MCPToolProtocol {
    public let name = "createReminder"
    public let description = "Create a new reminder with customizable due date, priority, and alerts."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "title": [
                    "type": "string",
                    "description": "Reminder title"
                ],
                "notes": [
                    "type": "string",
                    "description": "Reminder notes/description (optional)"
                ],
                "dueDate": [
                    "type": "string",
                    "description": "Due date in ISO 8601 format (optional)"
                ],
                "priority": [
                    "type": "string",
                    "enum": ["High", "Medium", "Low", "None"],
                    "description": "Priority level (optional, defaults to None)"
                ],
                "listName": [
                    "type": "string",
                    "description": "Name of reminder list to add to (defaults to default list)"
                ]
            ],
            "required": ["title"]
        ]
    }
    
    private let eventStore = EKEventStore()
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    public init() {}
    
    public func execute(arguments: [String: Any]) async throws -> String {
        // Request access
        if #available(macOS 14.0, *) {
            let granted = try await eventStore.requestFullAccessToReminders()
            guard granted else {
                throw MCPToolError.permissionDenied("Reminders access denied.")
            }
        }
        
        guard let title = arguments["title"] as? String else {
            throw MCPToolError.missingArgument("title")
        }
        
        // Find calendar (list)
        var calendar: EKCalendar?
        if let listName = arguments["listName"] as? String {
            calendar = eventStore.calendars(for: .reminder).first { $0.title == listName }
            if calendar == nil {
                throw MCPToolError.invalidArgument("Reminder list '\(listName)' not found")
            }
        } else {
            calendar = eventStore.defaultCalendarForNewReminders()
        }
        
        guard let targetCalendar = calendar else {
            throw MCPToolError.executionFailed("No reminder list available")
        }
        
        // Create reminder
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = targetCalendar
        
        if let notes = arguments["notes"] as? String {
            reminder.notes = notes
        }
        
        if let dueDateString = arguments["dueDate"] as? String,
           let dueDate = isoFormatter.date(from: dueDateString) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }
        
        if let priorityStr = arguments["priority"] as? String {
            reminder.priority = priorityValue(priorityStr)
        }
        
        // Save reminder
        try eventStore.save(reminder, commit: true)
        
        let result: [String: Any] = [
            "success": true,
            "reminderId": reminder.calendarItemIdentifier,
            "message": "Reminder '\(title)' created successfully"
        ]
        
        return formatJSONLD(result)
    }
    
    private func priorityValue(_ priority: String) -> Int {
        switch priority {
        case "High": return 1
        case "Medium": return 5
        case "Low": return 9
        default: return 0
        }
    }
}

