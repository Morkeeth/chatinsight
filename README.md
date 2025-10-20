# ChatInsights

> Know who matters. Never lose touch.

ChatInsights is a native macOS app that analyzes your messaging patterns across multiple platforms (starting with iMessage) to help you maintain meaningful relationships.

## Features

### 📊 Smart Analytics
- Track message frequency and recency for all contacts
- Calculate importance scores based on conversation patterns
- Visualize communication trends over time
- Understand your response times and conversation initiation patterns

### 🔔 Gentle Reminders
- Weekly notifications suggesting who to reach out to
- Intelligent prioritization based on relationship strength and time since last contact
- Customizable thresholds and notification schedules

### 🤖 AI-Powered Insights (Optional)
- Sentiment analysis of conversations
- Personalized message suggestions
- Topic identification and relationship patterns
- Powered by OpenAI GPT (requires API key)

### 🔒 Privacy-First
- **All data stays on your Mac** - zero telemetry, zero cloud storage
- Runs in macOS sandbox with minimal permissions
- Optional AI features only send data when explicitly enabled
- Open source and transparent

## Getting Started

### Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building from source)
- Access to your iMessage database

### Building from Source

1. Clone this repository:
```bash
git clone https://github.com/morkeeth/chatinsights.git
cd chatinsights/ChatInsights
```

2. Open the project:
```bash
open Package.swift
```

3. In Xcode, select your development team in the Signing & Capabilities tab

4. Build and run (⌘R)

### First Launch

1. **Welcome Screen**: Review the app features and value proposition
2. **Database Selection**: You'll be prompted to select your iMessage database
   - Navigate to `~/Library/Messages/chat.db`
   - Grant access through the file picker
3. **Analysis**: The app will analyze your messages and display insights
4. **Notifications**: Enable weekly reminders in Settings (optional)

## Usage

### Menu Bar

ChatInsights lives in your menu bar for quick access:
- Click the icon to see quick stats and top reach-out suggestions
- Access full dashboard and settings
- Manually trigger analysis

### Dashboard

The main dashboard shows:
- Complete contact list sorted by importance
- Reach-out suggestions at the top
- Detailed stats for each contact
- Search and filter capabilities

### Settings

Customize your experience:
- Set OpenAI API key for AI features
- Configure notification schedule (which day of week)
- Adjust reach-out threshold (days without contact)
- Set minimum message count for analysis

## Architecture

```
ChatInsights/
├── App/                          # UI Layer
│   ├── Views/
│   │   ├── LandingPageView       # Beautiful onboarding
│   │   ├── DashboardView         # Main analytics UI
│   │   └── SettingsView          # Configuration
│   └── MenuBarController         # Menu bar integration
├── DataLayer/
│   ├── MessageDatabase/          # iMessage DB access
│   │   ├── iMessageReader        # SQLite queries
│   │   ├── TypedstreamDecoder    # Apple format decoder
│   │   └── ChatDBModels          # Data models
│   ├── Analytics/                # Analysis engine
│   │   ├── ContactAnalyzer       # Metrics calculation
│   │   └── ReachOutSuggestor     # Suggestion algorithm
│   └── Storage/
│       └── LocalDatabase         # Caching layer
└── Services/
    ├── OpenAIService             # Optional AI features
    ├── NotificationManager       # System notifications
    └── SchedulerService          # Weekly analysis
```

## Platform Roadmap

### Phase 1: iMessage ✅
- Direct SQLite database access
- Typedstream format decoding
- Full conversation history

### Phase 2: Telegram (Coming Soon)
- **Effort**: Low-Medium
- Open API access
- Local database parsing

### Phase 3: WhatsApp
- **Effort**: High
- Export file parsing
- Encryption handling

### Future Platforms
- Email (IMAP/Exchange)
- Instagram DMs (data export)
- Facebook Messenger (data export)

## Privacy & Security

ChatInsights takes your privacy seriously:

- ✅ **Local-only data processing** - messages never leave your Mac
- ✅ **App Sandbox** - restricted system access
- ✅ **No telemetry** - we don't know who uses the app
- ✅ **No ads or tracking** - completely free
- ✅ **Open source** - audit the code yourself
- ⚠️ **OpenAI integration** - when enabled, sends conversation snippets to OpenAI API (user controlled)

## Contributing

Contributions are welcome! Areas where help is needed:

- [ ] Additional platform integrations (Telegram, WhatsApp)
- [ ] Improved typedstream decoder
- [ ] Better contact name resolution
- [ ] Export features (CSV, JSON)
- [ ] Visualization improvements
- [ ] Tests and documentation

## Credits

Inspired by:
- [iMCP](https://github.com/mattt/iMCP) by @mattt - for iMessage database access patterns
- [Remess](https://github.com/FO214/remess) by @FO214 - for message extraction approach
- [imessage-exporter](https://github.com/ReagentX/imessage-exporter) by @ReagentX - for typedstream decoding

## License

MIT License - see LICENSE file for details

## Support

- 🐛 **Found a bug?** Open an issue
- 💡 **Have an idea?** Start a discussion
- ⭐ **Like the project?** Star it on GitHub!

---

Made with ❤️ for staying connected

