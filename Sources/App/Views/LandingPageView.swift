import SwiftUI

struct LandingPageView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.9),
                    Color(red: 0.6, green: 0.4, blue: 1.0),
                    Color(red: 0.3, green: 0.5, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    FeaturePage(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track What Matters",
                        description: "See who you talk to most, when you last connected, and how your relationships are trending.",
                        color: .blue
                    )
                    .tag(1)
                    
                    FeaturePage(
                        icon: "bell.badge",
                        title: "Never Forget",
                        description: "Get gentle weekly reminders about the people you should reach out to. Stay connected effortlessly.",
                        color: .purple
                    )
                    .tag(2)
                    
                    FeaturePage(
                        icon: "lock.shield",
                        title: "Completely Private",
                        description: "All your data stays on your Mac. We never send anything to the cloud (except optional AI insights).",
                        color: .green
                    )
                    .tag(3)
                    
                    SetupPage()
                        .tag(4)
                }
                .tabViewStyle(.automatic)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Page indicators and navigation
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    if currentPage < 4 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text(currentPage == 0 ? "Get Started" : "Continue")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.9))
                                .frame(width: 200, height: 44)
                                .background(Color.white)
                                .cornerRadius(22)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 600, height: 700)
        .onAppear {
            isAnimating = true
        }
    }
}

struct WelcomePage: View {
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App icon/logo
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    scale = 1.0
                }
            }
            
            VStack(spacing: 12) {
                Text("ChatInsights")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Know who matters. Never lose touch.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(40)
    }
}

struct FeaturePage: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.white)
                .symbolEffect(.bounce, value: isVisible)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }
            
            Spacer()
        }
        .padding(40)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = true
            }
        }
    }
}

struct SetupPage: View {
    @EnvironmentObject var appState: AppState
    @State private var isSelectingDatabase = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                Text("Ready to Start")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("We need access to your iMessage database to analyze your conversations. Don't worry — everything stays on your Mac.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }
            
            Button(action: {
                selectDatabase()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                    Text("Select iMessage Database")
                }
                .font(.headline)
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.9))
                .frame(width: 280, height: 50)
                .background(Color.white)
                .cornerRadius(25)
            }
            .buttonStyle(.plain)
            .disabled(isSelectingDatabase)
            
            if isSelectingDatabase {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
            
            Spacer()
        }
        .padding(40)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    func selectDatabase() {
        isSelectingDatabase = true
        
        let panel = NSOpenPanel()
        panel.message = "Select your iMessage database (chat.db)"
        panel.prompt = "Select"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.database]
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Messages")
        
        panel.begin { response in
            isSelectingDatabase = false
            
            if response == .OK, let url = panel.url {
                // Save database path
                UserDefaults.standard.set(url.path, forKey: "iMessageDatabasePath")
                
                // Grant sandbox access
                _ = url.startAccessingSecurityScopedResource()
                
                // Save bookmark
                if let bookmarkData = try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    UserDefaults.standard.set(bookmarkData, forKey: "iMessageDatabaseBookmark")
                }
                
                // Complete onboarding
                appState.completeOnboarding()
                appState.hasMessageAccess = true
                
                // Initial data load
                appState.refreshData()
            }
        }
    }
}

struct LandingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LandingPageView()
            .environmentObject(AppState())
    }
}

