import SwiftUI
import FirebaseCore

// AppDelegate for Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
        return true
    }
    
    // Handle URL callbacks for OAuth (Apple Sign In)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
}

@main
struct OmniAIApp: App {
    // Connect AppDelegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var journalManager = JournalManager.shared
    @StateObject private var chatService = ChatService()
    @StateObject private var offlineManager = OfflineManager()
    @StateObject private var moodManager = MoodManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    private let tokenManager = TokenManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(premiumManager)
                .environmentObject(journalManager)
                .environmentObject(chatService)
                .environmentObject(offlineManager)
                .environmentObject(moodManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    // Start offline monitoring when app launches
                    offlineManager.startMonitoring()
                    // Connect authManager to chatService for guest limits
                    chatService.setAuthManager(authManager)
                    // Initialize authentication status asynchronously with delay for session restoration
                    authManager.checkAuthenticationStatus(allowDelay: true)
                }
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        // App became active - validate session
                        tokenManager.handleAppDidBecomeActive()
                    case .inactive:
                        // App is inactive
                        break
                    case .background:
                        // App went to background - save token state
                        tokenManager.handleAppWillResignActive()
                    @unknown default:
                        break
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { _ in
                    // Handle session expiration
                    authManager.isAuthenticated = false
                    authManager.currentUser = nil
                }
                .onOpenURL { url in
                    // Handle auth redirects
                    print("📱 Received URL: \(url)")
                }
        }
    }
}