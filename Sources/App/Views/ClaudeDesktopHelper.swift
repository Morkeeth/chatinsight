import SwiftUI
import AppKit

/// Helper view for configuring Claude Desktop
struct ClaudeDesktopHelper: View {
    @State private var showCopiedAlert = false
    @State private var configStatus: ConfigStatus = .unknown
    
    enum ConfigStatus: Equatable {
        case unknown
        case notInstalled
        case notConfigured
        case configured
        case error(String)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "terminal.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude Desktop Setup")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Connect ChatInsights to Claude Desktop")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Status
                    statusSection
                    
                    Divider()
                    
                    // Instructions
                    instructionsSection
                    
                    Divider()
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            checkClaudeDesktopConfig()
        }
        .alert("Command Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Server command copied to clipboard. Paste it into your Claude Desktop configuration.")
        }
    }
    
    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
            
            HStack {
                statusIcon
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var statusIcon: some View {
        switch configStatus {
        case .configured:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .notConfigured, .notInstalled:
            return Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        case .error:
            return Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .unknown:
            return Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.gray)
        }
    }
    
    private var statusTitle: String {
        switch configStatus {
        case .configured:
            return "✓ Claude Desktop Configured"
        case .notConfigured:
            return "Claude Desktop Not Configured"
        case .notInstalled:
            return "Claude Desktop Not Found"
        case .error(let message):
            return "Error: \(message)"
        case .unknown:
            return "Checking..."
        }
    }
    
    private var statusMessage: String {
        switch configStatus {
        case .configured:
            return "ChatInsights MCP server is configured and ready to use"
        case .notConfigured:
            return "Claude Desktop is installed but ChatInsights is not configured"
        case .notInstalled:
            return "Claude Desktop app not found on this system"
        case .error:
            return "Unable to check or modify configuration"
        case .unknown:
            return "Checking Claude Desktop configuration..."
        }
    }
    
    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Setup Instructions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionStep(
                    number: 1,
                    title: "Install Claude Desktop",
                    description: "Download from claude.ai if not already installed"
                )
                
                InstructionStep(
                    number: 2,
                    title: "Copy Server Command",
                    description: "Click 'Copy Command' below to copy the server path"
                )
                
                InstructionStep(
                    number: 3,
                    title: "Configure Claude Desktop",
                    description: "Click 'Auto-Configure' or manually edit the config file"
                )
                
                InstructionStep(
                    number: 4,
                    title: "Restart Claude Desktop",
                    description: "Quit and reopen Claude Desktop to load the configuration"
                )
            }
        }
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            
            VStack(spacing: 8) {
                Button(action: copyServerCommand) {
                    Label("Copy Server Command", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: autoConfigureClaudeDesktop) {
                    Label("Auto-Configure Claude Desktop", systemImage: "gearshape.arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(configStatus == .notInstalled)
                
                Button(action: openConfigFile) {
                    Label("Open Config File Manually", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(configStatus == .notInstalled)
                
                Button(action: openClaudeDesktop) {
                    Label("Open Claude Desktop", systemImage: "app.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(configStatus == .notInstalled)
            }
        }
    }
    
    // MARK: - Actions
    
    private func checkClaudeDesktopConfig() {
        let configPath = claudeDesktopConfigPath
        
        if !FileManager.default.fileExists(atPath: configPath) {
            // Check if Claude Desktop is installed
            if !isClaudeDesktopInstalled() {
                configStatus = .notInstalled
            } else {
                configStatus = .notConfigured
            }
            return
        }
        
        // Check if our server is configured
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mcpServers = json["mcpServers"] as? [String: Any],
              mcpServers["ChatInsights"] != nil else {
            configStatus = .notConfigured
            return
        }
        
        configStatus = .configured
    }
    
    private func copyServerCommand() {
        let serverPath = getServerExecutablePath()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(serverPath, forType: .string)
        showCopiedAlert = true
    }
    
    private func autoConfigureClaudeDesktop() {
        let configPath = claudeDesktopConfigPath
        let serverPath = getServerExecutablePath()
        
        // Create config directory if needed
        let configDir = (configPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        
        // Read existing config or create new
        var config: [String: Any] = [:]
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            config = json
        }
        
        // Add or update our server
        var mcpServers = config["mcpServers"] as? [String: Any] ?? [:]
        mcpServers["ChatInsights"] = [
            "command": serverPath,
            "args": []
        ]
        config["mcpServers"] = mcpServers
        
        // Write config
        do {
            let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: configPath))
            configStatus = .configured
            
            // Show success alert
            let alert = NSAlert()
            alert.messageText = "Configuration Updated"
            alert.informativeText = "Claude Desktop has been configured with ChatInsights MCP server. Please restart Claude Desktop."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } catch {
            configStatus = .error("Failed to write config: \(error.localizedDescription)")
        }
    }
    
    private func openConfigFile() {
        let configPath = claudeDesktopConfigPath
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: configPath) {
            let configDir = (configPath as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
            
            let initialConfig = ["mcpServers": [:]]
            if let data = try? JSONSerialization.data(withJSONObject: initialConfig, options: [.prettyPrinted]) {
                try? data.write(to: URL(fileURLWithPath: configPath))
            }
        }
        
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }
    
    private func openClaudeDesktop() {
        let appPath = "/Applications/Claude.app"
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: appPath), configuration: NSWorkspace.OpenConfiguration())
    }
    
    // MARK: - Helpers
    
    private var claudeDesktopConfigPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Claude/claude_desktop_config.json"
    }
    
    private func isClaudeDesktopInstalled() -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Claude.app")
    }
    
    private func getServerExecutablePath() -> String {
        // Get the path to the CLI executable
        // In development, this would be in .build/debug or .build/release
        // In production, it would be bundled with the app
        
        if let bundlePath = Bundle.main.bundlePath as String? {
            let executablePath = "\(bundlePath)/Contents/MacOS/chatinsights-server"
            if FileManager.default.fileExists(atPath: executablePath) {
                return executablePath
            }
        }
        
        // Fallback to swift run
        return "swift run chatinsights-server"
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// Preview
struct ClaudeDesktopHelper_Previews: PreviewProvider {
    static var previews: some View {
        ClaudeDesktopHelper()
    }
}

