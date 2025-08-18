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
                .task {
                    // Monitor auth state changes for better debugging
                    for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                        switch event {
                        case .signedIn:
                            print("🔐 Auth State: User signed in - \(session?.user.id.uuidString ?? "unknown")")
                            authManager.checkAuthenticationStatus(allowDelay: false)
                        case .signedOut:
                            print("👋 Auth State: User signed out")
                            authManager.signOut()
                        case .initialSession:
                            print("🔄 Auth State: Initial session check")
                            authManager.checkAuthenticationStatus(allowDelay: false)
                        case .tokenRefreshed:
                            print("🔄 Auth State: Token refreshed")
                        default:
                            print("📱 Auth State: \(event)")
                        }
                    }
                }
                .onOpenURL { url in
                    // Handle Supabase auth redirects
                    Task {
                        do {
                            try await SupabaseManager.shared.client.auth.session(from: url)
                            print("✅ Successfully handled auth redirect: \(url)")
                        } catch {
                            print("❌ Failed to handle auth redirect: \(error)")
                        }
                    }
                }
        }
    }
}