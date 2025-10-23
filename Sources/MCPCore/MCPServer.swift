import Foundation

/// Main MCP Server implementation
public actor MCPServer {
    private var tools: [String: MCPToolProtocol] = [:]
    private let databasePath: String?
    
    public init(databasePath: String? = nil) {
        self.databasePath = databasePath
    }
    
    public func registerTools() {
        // Messages tool (requires database path)
        if let dbPath = databasePath {
            tools["fetchMessages"] = MessagesTool(databasePath: dbPath)
        }
        
        // Contacts tools
        tools["searchContacts"] = ContactsTool()
        tools["getMe"] = MeContactTool()
        
        // Calendar tools
        tools["fetchCalendarEvents"] = CalendarTool()
        tools["createCalendarEvent"] = CreateCalendarEventTool()
        
        // Reminders tools
        tools["fetchReminders"] = RemindersTool()
        tools["createReminder"] = CreateReminderTool()
        
        // Location tools
        tools["getCurrentLocation"] = LocationTool()
        tools["geocodeAddress"] = GeocodeTool()
        
        // Weather tool
        if #available(macOS 13.0, *) {
            tools["getWeather"] = WeatherTool()
        }
    }
    
    public func listTools() -> [[String: Any]] {
        return tools.values.map { tool in
            [
                "name": tool.name,
                "description": tool.description,
                "inputSchema": tool.inputSchema
            ]
        }
    }
    
    public func executeTool(name: String, arguments: [String: Any]) async throws -> String {
        guard let tool = tools[name] else {
            throw MCPToolError.executionFailed("Tool '\(name)' not found")
        }
        
        return try await tool.execute(arguments: arguments)
    }
    
    public func getInfo() -> [String: Any] {
        return [
            "name": "ChatInsights MCP Server",
            "version": "1.0.0",
            "capabilities": [
                "messages": databasePath != nil,
                "contacts": true,
                "calendar": true,
                "reminders": true,
                "location": true,
                "weather": true
            ]
        ]
    }
}

