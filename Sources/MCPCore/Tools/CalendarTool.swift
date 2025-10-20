import Foundation
import EventKit

/// Calendar tool - provides access to calendar events
public class CalendarTool: MCPToolProtocol {
    public let name = "fetchCalendarEvents"
    public let description = "Fetch calendar events within a date range. Returns events as JSON-LD formatted data."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "startDate": [
                    "type": "string",
                    "description": "Start date in ISO 8601 format (e.g., '2024-01-01T00:00:00Z'). Defaults to today if not specified."
                ],
                "endDate": [
                    "type": "string",
                    "description": "End date in ISO 8601 format. Defaults to 7 days from start if not specified."
                ],
                "calendarNames": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Optional array of calendar names to filter by"
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
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                throw MCPToolError.permissionDenied("Calendar access denied. Please grant access through System Settings.")
            }
        }
        
        // Parse dates
        let startDate = parseDate(arguments["startDate"] as? String) ?? Date()
        let endDate = parseDate(arguments["endDate"] as? String) ?? Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        
        let calendarNames = arguments["calendarNames"] as? [String]
        
        // Fetch events
        let events = fetchEvents(startDate: startDate, endDate: endDate, calendarNames: calendarNames)
        
        // Convert to JSON-LD
        let jsonLDEvents = events.map { event in
            convertEventToJSONLD(event)
        }
        
        return formatJSONLDArray(jsonLDEvents)
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return isoFormatter.date(from: dateString)
    }
    
    private func fetchEvents(startDate: Date, endDate: Date, calendarNames: [String]?) -> [EKEvent] {
        var calendars = eventStore.calendars(for: .event)
        
        // Filter by calendar names if provided
        if let names = calendarNames {
            calendars = calendars.filter { names.contains($0.title) }
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        return eventStore.events(matching: predicate)
    }
    
    private func convertEventToJSONLD(_ event: EKEvent) -> [String: Any] {
        let startDateString = isoFormatter.string(from: event.startDate)
        let endDateString = isoFormatter.string(from: event.endDate)
        
        let location = event.location ?? event.structuredLocation?.title
        
        let jsonLD = JSONLD.Event(
            name: event.title ?? "Untitled Event",
            startDate: startDateString,
            endDate: endDateString,
            location: location,
            description: event.notes,
            eventStatus: event.status == .confirmed ? "EventScheduled" : "EventCancelled"
        )
        
        return jsonLD.toJSONLD()
    }
}

/// Create Calendar Event tool
public class CreateCalendarEventTool: MCPToolProtocol {
    public let name = "createCalendarEvent"
    public let description = "Create a new calendar event with customizable settings."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "title": [
                    "type": "string",
                    "description": "Event title"
                ],
                "startDate": [
                    "type": "string",
                    "description": "Start date in ISO 8601 format"
                ],
                "endDate": [
                    "type": "string",
                    "description": "End date in ISO 8601 format"
                ],
                "location": [
                    "type": "string",
                    "description": "Event location (optional)"
                ],
                "notes": [
                    "type": "string",
                    "description": "Event notes/description (optional)"
                ],
                "calendarName": [
                    "type": "string",
                    "description": "Name of calendar to add event to (defaults to default calendar)"
                ],
                "allDay": [
                    "type": "boolean",
                    "description": "Whether this is an all-day event (defaults to false)"
                ],
                "alarmMinutesBefore": [
                    "type": "number",
                    "description": "Set alarm N minutes before event (optional)"
                ]
            ],
            "required": ["title", "startDate", "endDate"]
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
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                throw MCPToolError.permissionDenied("Calendar access denied.")
            }
        }
        
        guard let title = arguments["title"] as? String else {
            throw MCPToolError.missingArgument("title")
        }
        
        guard let startDateString = arguments["startDate"] as? String,
              let startDate = isoFormatter.date(from: startDateString) else {
            throw MCPToolError.invalidArgument("Invalid startDate format")
        }
        
        guard let endDateString = arguments["endDate"] as? String,
              let endDate = isoFormatter.date(from: endDateString) else {
            throw MCPToolError.invalidArgument("Invalid endDate format")
        }
        
        // Find calendar
        var calendar: EKCalendar?
        if let calendarName = arguments["calendarName"] as? String {
            calendar = eventStore.calendars(for: .event).first { $0.title == calendarName }
            if calendar == nil {
                throw MCPToolError.invalidArgument("Calendar '\(calendarName)' not found")
            }
        } else {
            calendar = eventStore.defaultCalendarForNewEvents
        }
        
        guard let targetCalendar = calendar else {
            throw MCPToolError.executionFailed("No calendar available")
        }
        
        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = targetCalendar
        event.isAllDay = arguments["allDay"] as? Bool ?? false
        
        if let location = arguments["location"] as? String {
            event.location = location
        }
        
        if let notes = arguments["notes"] as? String {
            event.notes = notes
        }
        
        if let alarmMinutes = arguments["alarmMinutesBefore"] as? Int {
            let alarm = EKAlarm(relativeOffset: TimeInterval(-alarmMinutes * 60))
            event.addAlarm(alarm)
        }
        
        // Save event
        try eventStore.save(event, span: .thisEvent)
        
        let result: [String: Any] = [
            "success": true,
            "eventId": event.eventIdentifier ?? "",
            "message": "Event '\(title)' created successfully"
        ]
        
        return formatJSONLD(result)
    }
}

