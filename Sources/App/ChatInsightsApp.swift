import SwiftUI
import AppKit

@main
struct ChatInsightsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isFirstLaunch {
                LandingPageView()
                    .environmentObject(appState)
            } else {
                DashboardView()
                    .environmentObject(appState)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar
        menuBarController = MenuBarController()
        
        // Request notification permissions
        NotificationManager.shared.requestAuthorization()
        
        // Schedule weekly analysis
        SchedulerService.shared.scheduleWeeklyAnalysis()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar
        return false
    }
}

class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool
    @Published var hasMessageAccess: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var contacts: [Contact] = []
    @Published var reachOutSuggestions: [Contact] = []
    
    init() {
        // Check if first launch
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isFirstLaunch = false
    }
    
    func refreshData() {
        Task {
            await MainActor.run {
                isAnalyzing = true
            }
            
            // Read messages and analyze
            if let messages = await iMessageReader.shared.fetchMessages() {
                let analyzer = ContactAnalyzer()
                let analyzedContacts = await analyzer.analyzeContacts(from: messages)
                let suggestions = ReachOutSuggestor.shared.getSuggestions(from: analyzedContacts)
                
                await MainActor.run {
                    self.contacts = analyzedContacts
                    self.reachOutSuggestions = suggestions
                    self.isAnalyzing = false
                }
            }
        }
    }
}

