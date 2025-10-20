# ChatInsights Setup Guide

## Quick Start

### Option 1: Build with Xcode (Recommended)

1. Open Terminal and navigate to the project directory:
```bash
cd "/Users/morkeeth/CODE/Homemade APPLE MCP/ChatInsights"
```

2. Open the package in Xcode:
```bash
open Package.swift
```

3. In Xcode:
   - Select your development team in Signing & Capabilities
   - Set the bundle identifier (e.g., `com.yourname.chatinsights`)
   - Press ⌘R to build and run

### Option 2: Build with Swift Package Manager

1. Make the build script executable:
```bash
chmod +x build.sh
```

2. Run the build script:
```bash
./build.sh
```

3. Run the app:
```bash
swift run
```

## Setting Up iMessage Access

### 1. Full Disk Access (macOS 10.14+)

For the app to read your iMessage database, you'll need to grant Full Disk Access:

1. Open **System Settings** > **Privacy & Security** > **Full Disk Access**
2. Click the **+** button
3. Navigate to the built ChatInsights.app
4. Enable the toggle for ChatInsights

**Note**: The app will also prompt you to select the database file manually, which provides sandbox access without requiring Full Disk Access.

### 2. Database Location

Your iMessage database is located at:
```
~/Library/Messages/chat.db
```

To navigate there in Finder:
1. Press ⌘⇧G (Go to Folder)
2. Paste: `~/Library/Messages/`
3. Look for `chat.db`

## Configuration

### First Launch

1. **Welcome Screen**: Review features and privacy info
2. **Database Selection**: Select `chat.db` from `~/Library/Messages/`
3. **Initial Analysis**: Wait for first analysis to complete (30 seconds - 2 minutes)
4. **Dashboard**: Explore your conversation insights!

### Settings

Access settings from:
- Menu bar icon > Settings
- Dashboard > Settings button

Configure:
- **OpenAI API Key** (optional): For AI-powered insights
- **Weekly Notifications**: Enable/disable and set schedule
- **Reach Out Threshold**: Days before suggesting contact
- **Minimum Messages**: Filter out low-activity contacts

### OpenAI Integration (Optional)

To enable AI features:

1. Get an API key from [OpenAI](https://platform.openai.com/api-keys)
2. Open Settings in ChatInsights
3. Paste your API key in the "OpenAI Integration" section
4. Save settings

**Cost estimate**: ~$0.01-0.10 per week depending on usage

## Troubleshooting

### "Cannot find iMessage database"

**Solution**: Manually select the database
1. Open the app
2. Navigate to Settings
3. Click "Select Database"
4. Choose `~/Library/Messages/chat.db`

### "Permission Denied"

**Solution**: Grant Full Disk Access
1. System Settings > Privacy & Security > Full Disk Access
2. Add ChatInsights
3. Restart the app

### "Build Failed" Errors

**Common causes**:

1. **Missing Xcode Command Line Tools**:
```bash
xcode-select --install
```

2. **Wrong Swift version** (need 5.9+):
```bash
swift --version
```

3. **Dependency issues**:
```bash
swift package clean
swift package reset
swift package resolve
```

### Notifications Not Working

**Solution**: Enable notification permissions
1. System Settings > Notifications > ChatInsights
2. Enable "Allow Notifications"
3. Set alert style to "Alerts" (not Banners)

### App Crashes on Launch

**Check logs**:
```bash
log show --predicate 'process == "ChatInsights"' --last 1h
```

**Common fixes**:
1. Delete app data:
```bash
rm -rf ~/Library/Application\ Support/ChatInsights
```
2. Reset preferences:
```bash
defaults delete com.yourname.chatinsights
```
3. Rebuild:
```bash
swift package clean
swift build
```

## Development

### Project Structure

```
ChatInsights/
├── Package.swift              # Swift Package Manager config
├── Sources/
│   ├── App/                   # UI layer (SwiftUI)
│   ├── DataLayer/            # Data access & models
│   └── Services/             # Background services
├── Info.plist                # App metadata
├── ChatInsights.entitlements # Sandbox permissions
└── README.md                 # Documentation
```

### Running Tests

```bash
swift test
```

### Code Formatting

```bash
swift-format format -i -r Sources/
```

### Debugging

Enable verbose logging:
```bash
CHATINSIGHTS_DEBUG=1 swift run
```

View in Xcode debugger:
1. Open Package.swift in Xcode
2. Set breakpoints
3. Press ⌘R to run with debugger

## Updating

### Pull Latest Changes

```bash
git pull origin main
```

### Update Dependencies

```bash
swift package update
```

### Rebuild

```bash
swift package clean
swift build
```

## Uninstalling

1. Quit the app
2. Remove app from /Applications
3. Remove app data:
```bash
rm -rf ~/Library/Application\ Support/ChatInsights
rm -rf ~/Library/Caches/com.yourname.chatinsights
defaults delete com.yourname.chatinsights
```

## Support

- 📖 **Documentation**: See README.md
- 🐛 **Issues**: GitHub Issues
- 💬 **Discussions**: GitHub Discussions
- 📧 **Contact**: [your email]

## Next Steps

1. ✅ Build the app
2. ✅ Grant permissions
3. ✅ Select iMessage database
4. ✅ Explore your insights!
5. ⭐ Star the repo if you like it!

---

Happy analyzing! 🎉

