import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedContact: Contact?
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return appState.contacts
        }
        return appState.contacts.filter { contact in
            contact.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
            contact.id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with contact list
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search contacts...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .padding()
                
                // Reach out suggestions section
                if !appState.reachOutSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Reach Outs")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(appState.reachOutSuggestions.prefix(5)) { contact in
                            ReachOutCard(contact: contact)
                                .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
                
                // All contacts list
                List(filteredContacts, selection: $selectedContact) { contact in
                    ContactRow(contact: contact)
                        .tag(contact)
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { appState.refreshData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(appState.isAnalyzing)
                }
            }
        } detail: {
            if let contact = selectedContact {
                ContactDetailView(contact: contact)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select a contact to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            if appState.contacts.isEmpty {
                appState.refreshData()
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [
                        Color.blue.opacity(0.7),
                        Color.purple.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(contact.initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("\(contact.totalMessages) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(contact.lastMessageDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(contact.daysSinceLastMessage > 30 ? .orange : .secondary)
                }
            }
            
            Spacer()
            
            // Importance indicator
            if contact.importanceScore > 0.7 {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ReachOutCard: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(contact.daysSinceLastMessage) days since last message")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ContactDetailView: View {
    let contact: Contact
    @State private var conversationStats: ConversationStats?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                Color.blue.opacity(0.7),
                                Color.purple.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(contact.initials)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    
                    Text(contact.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(contact.id)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Messages",
                        value: "\(contact.totalMessages)",
                        icon: "bubble.left.and.bubble.right",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Sent",
                        value: "\(contact.sentByUser)",
                        icon: "arrow.up.circle",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Received",
                        value: "\(contact.receivedByUser)",
                        icon: "arrow.down.circle",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "Last Contact",
                        value: "\(contact.daysSinceLastMessage)d ago",
                        icon: "clock",
                        color: contact.daysSinceLastMessage > 30 ? .orange : .blue
                    )
                    
                    StatCard(
                        title: "Importance",
                        value: String(format: "%.0f%%", contact.importanceScore * 100),
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    StatCard(
                        title: "You Start",
                        value: String(format: "%.0f%%", (conversationStats?.initiationRatio ?? 0.5) * 100),
                        icon: "hand.raised",
                        color: .indigo
                    )
                }
                .padding(.horizontal)
                
                // Message frequency chart
                if let stats = conversationStats, !stats.messageFrequency.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message Frequency")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(Array(stats.messageFrequency.sorted(by: { $0.key < $1.key })), id: \.key) { date, count in
                                BarMark(
                                    x: .value("Date", date),
                                    y: .value("Messages", count)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: { openMessages() }) {
                        Label("Send Message", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadConversationStats()
        }
    }
    
    func loadConversationStats() {
        Task {
            // Fetch detailed stats from database
            conversationStats = await ContactAnalyzer().getConversationStats(for: contact.id)
        }
    }
    
    func openMessages() {
        // Open Messages app with this contact
        let phoneNumber = contact.id.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "sms:\(phoneNumber)") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppState())
    }
}

