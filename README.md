# ChatInsights MCP Server

> **Connect your digital life to AI assistants**

ChatInsights is a native macOS app that provides a Model Context Protocol (MCP) server, giving AI assistants like Claude Desktop secure access to your Messages, Contacts, Calendar, Reminders, Location, and Weather data.

## Features

### 🤖 MCP Server
- **Model Context Protocol support** - Works with Claude Desktop and other MCP clients
- **Privacy-first design** - All data stays on your Mac
- **Real-time access** - AI assistants can query your data on-demand
- **Secure permissions** - You control what services are enabled

### 📱 Supported Services

| Service | Description | Capabilities |
|---------|-------------|--------------|
| **Messages** 💬 | iMessage conversations | Fetch messages with specific participants, search by date range |
| **Contacts** 👥 | System contacts | Search by name, phone, or email; get your own contact info |
| **Calendar** 📅 | Calendar events | View events, create new events with recurrence and alarms |
| **Reminders** ✅ | Reminders/Tasks | View and create reminders with due dates and priorities |
| **Location** 📍 | Current location | Get coordinates and address, geocode addresses |
| **Weather** ⛅ | Weather data | Current conditions, temperature, wind, humidity |

### 🔒 Privacy & Security

- ✅ **Local-only processing** - Messages never leave your Mac by default
- ✅ **App Sandbox** - Restricted system access following Apple's security model
- ✅ **Granular permissions** - Enable only the services you want to share
- ✅ **No telemetry** - Zero data collection or tracking
- ✅ **Open source** - Audit the code yourself

## Getting Started

### Requirements

- **macOS 14.0 (Sonoma)** or later
- **Xcode 15+** for building from source
- **Claude Desktop** (or another MCP client)

### Installation

#### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/Morkeeth/chatinsight.git
cd chatinsight/ChatInsights

# Open in Xcode
open Package.swift

# Build and run (⌘R)
```

#### Option 2: Swift Package Manager

```bash
# Build
swift build

# Run the app
swift run ChatInsights

# Build the CLI server
swift build --product chatinsights-server
```

### Setup

#### 1. Launch ChatInsights

On first launch, you'll see a menu bar icon. Click it to access the app.

#### 2. Enable Services

Click the **server icon** in the menu bar popup to open MCP Services:

- **Messages**: Select your iMessage database (`~/Library/Messages/chat.db`)
- **Contacts**: Grant Contacts access through System Settings
- **Calendar**: Grant Calendar access
- **Reminders**: Grant Reminders access
- **Location**: Grant Location access when prompted
- **Weather**: Enabled by default (no permission needed)

#### 3. Start the MCP Server

Toggle the **MCP switch** in the menu bar to start the server. You'll see a green indicator when it's running.

#### 4. Connect to Claude Desktop

##### Automatic Configuration

1. Click **Settings** → **Configure Claude Desktop**
2. Click **Auto-Configure Claude Desktop**
3. Restart Claude Desktop

##### Manual Configuration

1. Open Claude Desktop Settings (⌘,)
2. Click "Developer" → "Edit Config"
3. Add ChatInsights to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "ChatInsights": {
      "command": "/path/to/chatinsights-server"
    }
  }
}
```

4. Restart Claude Desktop

#### 5. Use with Claude

Open Claude Desktop and you'll see **🔨 12** tools available. Try asking:

> "Show me my last conversation with Sarah"

> "What events do I have this week?"

> "Create a reminder to call mom tomorrow at 3pm"

> "What's the weather like where I am?"

> "Find me contacts with the name Johnson"

## MCP Tools Reference

### Messages

#### `fetchMessages`
Fetch messages with specific participants within a date range.

**Parameters:**
- `participant` (string, optional): Phone number or email
- `startDate` (string, optional): ISO 8601 format, defaults to 30 days ago
- `endDate` (string, optional): ISO 8601 format, defaults to now
- `limit` (number, optional): Max messages to return, default 100

**Returns:** JSON-LD formatted messages with Schema.org/Message type

### Contacts

#### `searchContacts`
Search contacts by name, phone number, or email.

**Parameters:**
- `query` (string, required): Search term
- `limit` (number, optional): Max results, default 10

**Returns:** JSON-LD formatted contacts with Schema.org/Person type

#### `getMe`
Get information about the current user.

**Returns:** JSON-LD Person object with your contact info

### Calendar

#### `fetchCalendarEvents`
Fetch calendar events within a date range.

**Parameters:**
- `startDate` (string, optional): ISO 8601 format, defaults to today
- `endDate` (string, optional): ISO 8601 format, defaults to 7 days from start
- `calendarNames` (array, optional): Filter by calendar names

**Returns:** JSON-LD formatted events with Schema.org/Event type

#### `createCalendarEvent`
Create a new calendar event.

**Parameters:**
- `title` (string, required): Event title
- `startDate` (string, required): ISO 8601 format
- `endDate` (string, required): ISO 8601 format
- `location` (string, optional): Event location
- `notes` (string, optional): Event description
- `calendarName` (string, optional): Target calendar
- `allDay` (boolean, optional): All-day event flag
- `alarmMinutesBefore` (number, optional): Reminder minutes before

### Reminders

#### `fetchReminders`
Fetch reminders with optional filtering.

**Parameters:**
- `completed` (boolean, optional): Filter by completion status
- `listName` (string, optional): Filter by list name
- `limit` (number, optional): Max results, default 50

**Returns:** JSON-LD formatted reminders with Schema.org/Action type

#### `createReminder`
Create a new reminder.

**Parameters:**
- `title` (string, required): Reminder title
- `notes` (string, optional): Description
- `dueDate` (string, optional): ISO 8601 format
- `priority` (string, optional): "High", "Medium", "Low", or "None"
- `listName` (string, optional): Target reminder list

### Location

#### `getCurrentLocation`
Get the current device location.

**Returns:** JSON-LD formatted place with Schema.org/Place type including coordinates and address

#### `geocodeAddress`
Convert an address to coordinates.

**Parameters:**
- `address` (string, required): Address to geocode

**Returns:** JSON-LD Place with coordinates

### Weather

#### `getWeather`
Get current weather conditions.

**Parameters:**
- `latitude` (number, optional): Latitude coordinate
- `longitude` (number, optional): Longitude coordinate
- `address` (string, optional): Address (alternative to lat/lon)

**Returns:** JSON-LD WeatherForecast with current conditions

## Architecture

```
ChatInsights/
├── App/                              # macOS SwiftUI App
│   ├── Views/
│   │   ├── MCPServicesView          # Service configuration UI
│   │   ├── ClaudeDesktopHelper      # Setup assistant
│   │   ├── DashboardView            # Analytics UI
│   │   └── SettingsView             # App settings
│   └── MenuBarController            # Menu bar integration
│
├── CLI/                              # MCP Server CLI
│   └── main.swift                   # Stdio transport server
│
├── MCPCore/                          # Shared MCP Infrastructure
│   ├── MCPServer.swift              # Main server implementation
│   ├── BonjourService.swift         # App-CLI communication
│   ├── JSONLD.swift                 # JSON-LD & Schema.org support
│   ├── MCPToolProtocol.swift        # Tool interface
│   └── Tools/                       # Individual tool implementations
│       ├── MessagesTool.swift
│       ├── ContactsTool.swift
│       ├── CalendarTool.swift
│       ├── RemindersTool.swift
│       ├── LocationTool.swift
│       └── WeatherTool.swift
│
└── DataLayer/                        # Data access layer
    └── MessageDatabase/             # iMessage database reader
        ├── iMessageReader.swift
        └── TypedstreamDecoder.swift
```

### How It Works

1. **App (ChatInsights.app)**: Manages permissions and runs the MCP server via Bonjour
2. **CLI (chatinsights-server)**: Stdio-based MCP server that proxies requests to the app
3. **Bonjour**: Local network service discovery for secure app-CLI communication
4. **JSON-LD**: All responses use Schema.org vocabularies for structured data

## Technical Details

### iMessage Database Access

ChatInsights reads directly from the iMessage SQLite database at `~/Library/Messages/chat.db`. The app:
- Runs in App Sandbox for security
- Uses security-scoped bookmarks for database access
- Decodes Apple's proprietary typedstream format for message content

### MCP Protocol

The CLI executable communicates with MCP clients (like Claude Desktop) via:
- **Transport**: stdio (standard input/output)
- **Format**: JSON-RPC 2.0
- **SDK**: Official Swift MCP SDK from Model Context Protocol

### Permissions

Each service requires specific macOS permissions:
- **Messages**: File access to `chat.db` via sandbox bookmark
- **Contacts**: `com.apple.security.personal-information.addressbook`
- **Calendar**: `com.apple.security.calendars` entitlement
- **Reminders**: `com.apple.security.calendars` entitlement
- **Location**: Location Services authorization

## Development

### Building

```bash
# Build everything
swift build

# Build just the app
swift build --product ChatInsights

# Build just the CLI
swift build --product chatinsights-server

# Run tests
swift test
```

### Debugging

#### Using MCP Inspector

```bash
# Get the server command from ChatInsights menu
# Then run:
npx @modelcontextprotocol/inspector /path/to/chatinsights-server

# Open inspector at http://127.0.0.1:6274
```

#### Verbose Logging

```bash
# Run CLI with verbose output
chatinsights-server --verbose
```

### Project Structure

- **Sources/App**: SwiftUI application
- **Sources/CLI**: Command-line MCP server
- **Sources/MCPCore**: Shared MCP functionality
- **Sources/DataLayer**: Data access (iMessage, etc.)
- **Sources/Services**: Background services (notifications, scheduling)

## Contributing

Contributions are welcome! Areas where help is needed:

- [ ] Additional MCP tools (Email, Slack, etc.)
- [ ] Enhanced typedstream decoder for complex message formats
- [ ] Better contact name resolution from phone numbers
- [ ] Export functionality (CSV, JSON)
- [ ] Comprehensive test coverage
- [ ] Documentation and examples

## Troubleshooting

### "Cannot find iMessage database"

**Solution**: Grant Full Disk Access or manually select the database:
1. Open ChatInsights
2. Click server icon → Enable Messages
3. Navigate to `~/Library/Messages/chat.db`

### "Permission Denied" for Contacts/Calendar

**Solution**: Grant permissions through System Settings:
1. System Settings → Privacy & Security
2. Find the relevant section (Contacts, Calendars, etc.)
3. Enable ChatInsights

### Claude Desktop Not Recognizing Server

**Solution**: Verify configuration:
1. Check `~/Library/Application Support/Claude/claude_desktop_config.json`
2. Ensure the server path is correct
3. Restart Claude Desktop completely
4. Check Claude Desktop console for errors

### MCP Server Won't Start

**Solution**: Check Bonjour:
1. Ensure no firewall is blocking local network traffic
2. Check Console.app for ChatInsights logs
3. Try disabling and re-enabling MCP toggle

## Credits & Inspiration

- [iMCP](https://github.com/mattt/iMCP) by @mattt - Inspiration for MCP architecture and iMessage access patterns
- [Model Context Protocol](https://github.com/modelcontextprotocol) - Official MCP SDK
- [imessage-exporter](https://github.com/ReagentX/imessage-exporter) by @ReagentX - Typedstream decoding approach

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Disclaimer

iMessage® is a registered trademark of Apple Inc. This project is not affiliated with, endorsed, or sponsored by Apple Inc.

ChatInsights is an independent open-source project that provides read-only access to your local iMessage database and other Apple services through standard macOS APIs and security frameworks.

---

**Made with ❤️ for AI-powered personal productivity**

🌟 Star this repo if you find it useful!  
🐛 Found a bug? [Open an issue](https://github.com/Morkeeth/chatinsight/issues)  
💡 Have an idea? [Start a discussion](https://github.com/Morkeeth/chatinsight/discussions)
