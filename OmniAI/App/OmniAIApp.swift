import SwiftUI

@main
struct OmniAIApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var journalManager = JournalManager.shared
    @StateObject private var chatService = ChatService()
    @StateObject private var offlineManager = OfflineManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(premiumManager)
                .environmentObject(journalManager)
                .environmentObject(chatService)
                .environmentObject(offlineManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    // Start offline monitoring when app launches
                    offlineManager.startMonitoring()
                }
        }
    }
}