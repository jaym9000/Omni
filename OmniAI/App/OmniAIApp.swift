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
                    // Connect authManager to chatService for guest limits
                    chatService.setAuthManager(authManager)
                    // Initialize authentication status asynchronously with delay for session restoration
                    authManager.checkAuthenticationStatus(allowDelay: true)
                }
                .onOpenURL { url in
                    // Handle auth redirects
                    // TODO: Handle Firebase auth redirects
                    print("📱 Received URL: \(url)")
                }
        }
    }
}