import SwiftUI

struct SettingsView: View {
    @AppStorage("openAIKey") private var openAIKey = ""
    @AppStorage("weeklyNotificationsEnabled") private var weeklyNotificationsEnabled = true
    @AppStorage("notificationDay") private var notificationDay = 0 // 0 = Sunday
    @AppStorage("reachOutThresholdDays") private var reachOutThresholdDays = 14
    @AppStorage("minMessagesForImportance") private var minMessagesForImportance = 10
    
    @State private var showingSaveConfirmation = false
    
    let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        Form {
            Section("OpenAI Integration") {
                SecureField("API Key", text: $openAIKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Optional: Add your OpenAI API key to enable AI-powered insights like sentiment analysis and message suggestions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Notifications") {
                Toggle("Enable Weekly Reminders", isOn: $weeklyNotificationsEnabled)
                
                if weeklyNotificationsEnabled {
                    Picker("Notification Day", selection: $notificationDay) {
                        ForEach(0..<7) { day in
                            Text(weekDays[day]).tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Analysis Settings") {
                Stepper("Reach out after \(reachOutThresholdDays) days",
                       value: $reachOutThresholdDays, in: 7...90, step: 7)
                
                Text("Contacts you haven't messaged in this many days will appear in reach out suggestions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Stepper("Minimum messages: \(minMessagesForImportance)",
                       value: $minMessagesForImportance, in: 5...100, step: 5)
                
                Text("Only contacts with at least this many messages will be included in analysis.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Privacy") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("All your data stays on your Mac")
                            .font(.headline)
                    }
                    
                    Text("ChatInsights stores all message data locally. We never send your messages to external servers, except when using OpenAI features (which you control).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/morkeeth/chatinsights")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 600)
        .onChange(of: weeklyNotificationsEnabled) { _, enabled in
            if enabled {
                SchedulerService.shared.scheduleWeeklyAnalysis()
            } else {
                SchedulerService.shared.cancelWeeklyAnalysis()
            }
        }
        .onChange(of: notificationDay) { _, _ in
            if weeklyNotificationsEnabled {
                SchedulerService.shared.scheduleWeeklyAnalysis()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

