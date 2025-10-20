import AppKit
import SwiftUI

class MenuBarController {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bubble.left.and.bubble.right.fill", accessibilityDescription: "ChatInsights")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

struct MenuBarPopoverView: View {
    @StateObject private var appState = AppState()
    @StateObject private var serviceManager = MCPServiceManager.shared
    @State private var showDashboard = false
    @State private var showSettings = false
    @State private var showMCPServices = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("ChatInsights")
                    .font(.headline)
                
                Spacer()
                
                // MCP Server toggle
                Toggle(isOn: Binding(
                    get: { serviceManager.isServerRunning },
                    set: { enabled in
                        if enabled {
                            serviceManager.startServer()
                        } else {
                            serviceManager.stopServer()
                        }
                    }
                )) {
                    Text("MCP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                
                Button(action: { showMCPServices = true }) {
                    Image(systemName: "server.rack")
                }
                .buttonStyle(.plain)
                .help("MCP Services")
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Quick stats
            if !appState.contacts.isEmpty {
                VStack(spacing: 12) {
                    StatRow(
                        icon: "person.2.fill",
                        label: "Total Contacts",
                        value: "\(appState.contacts.count)"
                    )
                    
                    StatRow(
                        icon: "bell.badge.fill",
                        label: "Reach Out To",
                        value: "\(appState.reachOutSuggestions.count)",
                        color: .orange
                    )
                    
                    if let lastAnalyzed = UserDefaults.standard.object(forKey: "lastAnalyzedDate") as? Date {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Updated \(lastAnalyzed, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Top reach outs
                if !appState.reachOutSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reach Out Soon")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(appState.reachOutSuggestions.prefix(3)) { contact in
                            MenuBarContactRow(contact: contact)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Analyzing messages...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            
            Spacer()
            
            Divider()
            
            // Actions
            VStack(spacing: 8) {
                Button(action: {
                    showDashboard = true
                    openDashboard()
                }) {
                    Label("Open Dashboard", systemImage: "chart.bar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    appState.refreshData()
                }) {
                    Label("Refresh Now", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(appState.isAnalyzing)
            }
            .padding()
        }
        .frame(width: 320, height: 400)
        .onAppear {
            if appState.contacts.isEmpty {
                appState.refreshData()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showMCPServices) {
            MCPServicesView()
        }
    }
    
    private func openDashboard() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Open main window
        if let window = NSApplication.shared.windows.first(where: { $0.title.isEmpty }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct MenuBarContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.subheadline)
                
                Text("\(contact.daysSinceLastMessage)d ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

