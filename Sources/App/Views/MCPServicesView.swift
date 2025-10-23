import SwiftUI
import Contacts
import EventKit
import MCPCore

/// View for managing MCP service permissions
struct MCPServicesView: View {
    @StateObject private var serviceManager = MCPServiceManager.shared
    @State private var showDatabasePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "server.rack")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MCP Services")
                        .font(.headline)
                    Text("Enable services for AI assistants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Server status indicator
                Circle()
                    .fill(serviceManager.isServerRunning ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text(serviceManager.isServerRunning ? "Running" : "Stopped")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Messages Service
                    ServiceRow(
                        icon: "message.fill",
                        iconColor: .green,
                        name: "Messages",
                        description: "Access to iMessage history",
                        isEnabled: serviceManager.services["messages"]?.isEnabled ?? false
                    ) {
                        showDatabasePicker = true
                    }
                    
                    // Contacts Service
                    ServiceRow(
                        icon: "person.2.fill",
                        iconColor: .blue,
                        name: "Contacts",
                        description: "Search and access contacts",
                        isEnabled: serviceManager.services["contacts"]?.isEnabled ?? false
                    ) {
                        await serviceManager.requestContactsAccess()
                    }
                    
                    // Calendar Service
                    ServiceRow(
                        icon: "calendar",
                        iconColor: .red,
                        name: "Calendar",
                        description: "View and create calendar events",
                        isEnabled: serviceManager.services["calendar"]?.isEnabled ?? false
                    ) {
                        await serviceManager.requestCalendarAccess()
                    }
                    
                    // Reminders Service
                    ServiceRow(
                        icon: "checklist",
                        iconColor: .orange,
                        name: "Reminders",
                        description: "View and create reminders",
                        isEnabled: serviceManager.services["reminders"]?.isEnabled ?? false
                    ) {
                        await serviceManager.requestRemindersAccess()
                    }
                    
                    // Location Service
                    ServiceRow(
                        icon: "location.fill",
                        iconColor: .purple,
                        name: "Location",
                        description: "Access current location",
                        isEnabled: serviceManager.services["location"]?.isEnabled ?? false
                    ) {
                        await serviceManager.requestLocationAccess()
                    }
                    
                    // Weather Service
                    ServiceRow(
                        icon: "cloud.sun.fill",
                        iconColor: .cyan,
                        name: "Weather",
                        description: "Get weather information",
                        isEnabled: serviceManager.services["weather"]?.isEnabled ?? false
                    ) {
                        // Weather doesn't need special permission
                        await serviceManager.enableService("weather")
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
        .fileImporter(
            isPresented: $showDatabasePicker,
            allowedContentTypes: [.database],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task {
                    await serviceManager.setMessagesDatabase(url: url)
                }
            }
        }
    }
}

struct ServiceRow: View {
    let icon: String
    let iconColor: Color
    let name: String
    let description: String
    let isEnabled: Bool
    let onEnable: () async -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isEnabled ? iconColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(isEnabled ? iconColor : .gray)
                    .font(.system(size: 18))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Enable button
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 80, height: 32)
            } else if isEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
            } else {
                Button("Enable") {
                    isLoading = true
                    Task {
                        await onEnable()
                        isLoading = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Service Manager

@MainActor
class MCPServiceManager: ObservableObject {
    static let shared = MCPServiceManager()
    
    @Published var services: [String: ServiceStatus] = [:]
    @Published var isServerRunning = false
    
    private let bonjourService = BonjourService()
    
    init() {
        setupServices()
        checkServiceStatuses()
    }
    
    private func setupServices() {
        services = [
            "messages": ServiceStatus(name: "Messages", isEnabled: false),
            "contacts": ServiceStatus(name: "Contacts", isEnabled: false),
            "calendar": ServiceStatus(name: "Calendar", isEnabled: false),
            "reminders": ServiceStatus(name: "Reminders", isEnabled: false),
            "location": ServiceStatus(name: "Location", isEnabled: false),
            "weather": ServiceStatus(name: "Weather", isEnabled: false)
        ]
    }
    
    func checkServiceStatuses() {
        // Check Contacts
        let contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
        services["contacts"]?.isEnabled = (contactsStatus == .authorized)
        
        // Check Calendar
        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        services["calendar"]?.isEnabled = (calendarStatus == .fullAccess || calendarStatus == .authorized)
        
        // Check Reminders
        let remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
        services["reminders"]?.isEnabled = (remindersStatus == .fullAccess || remindersStatus == .authorized)
        
        // Check Messages
        if let dbPath = UserDefaults.standard.string(forKey: "iMessageDatabasePath"),
           FileManager.default.fileExists(atPath: dbPath) {
            services["messages"]?.isEnabled = true
        }
        
        // Weather is always available
        services["weather"]?.isEnabled = true
    }
    
    func startServer() {
        guard !isServerRunning else { return }
        
        do {
            try bonjourService.startAdvertising()
            isServerRunning = true
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        bonjourService.stopAdvertising()
        isServerRunning = false
    }
    
    func requestContactsAccess() async {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            services["contacts"]?.isEnabled = granted
        } catch {
            print("Contacts access error: \(error)")
        }
    }
    
    func requestCalendarAccess() async {
        let store = EKEventStore()
        do {
            if #available(macOS 14.0, *) {
                let granted = try await store.requestFullAccessToEvents()
                services["calendar"]?.isEnabled = granted
            }
        } catch {
            print("Calendar access error: \(error)")
        }
    }
    
    func requestRemindersAccess() async {
        let store = EKEventStore()
        do {
            if #available(macOS 14.0, *) {
                let granted = try await store.requestFullAccessToReminders()
                services["reminders"]?.isEnabled = granted
            }
        } catch {
            print("Reminders access error: \(error)")
        }
    }
    
    func requestLocationAccess() async {
        // Location access is requested by LocationTool when first used
        services["location"]?.isEnabled = true
    }
    
    func enableService(_ serviceName: String) async {
        services[serviceName]?.isEnabled = true
    }
    
    func setMessagesDatabase(url: URL) async {
        // Save security-scoped bookmark
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access database")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "iMessageDatabaseBookmark")
            UserDefaults.standard.set(url.path, forKey: "iMessageDatabasePath")
            services["messages"]?.isEnabled = true
        } catch {
            print("Failed to save bookmark: \(error)")
        }
    }
}

struct ServiceStatus {
    let name: String
    var isEnabled: Bool
}

// MARK: - UTType Extension for Database

import UniformTypeIdentifiers

extension UTType {
    static var database: UTType {
        UTType(filenameExtension: "db") ?? .data
    }
}

