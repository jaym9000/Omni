import Foundation
import FirebaseAuth

class TokenManager {
    static let shared = TokenManager()
    
    private let keychainManager = KeychainManager.shared
    private var refreshTimer: Timer?
    private let tokenExpirationBuffer: TimeInterval = 300 // 5 minutes before expiration
    
    private init() {
        setupTokenRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Token Management
    
    func saveFirebaseToken() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        
        // Get the ID token
        let token = try await currentUser.getIDToken()
        try keychainManager.saveString(token, for: .firebaseToken)
        
        // Get token result for expiration time
        let tokenResult = try await currentUser.getIDTokenResult()
        
        // Schedule refresh before expiration
        scheduleTokenRefresh(expirationDate: tokenResult.expirationDate)
        
        print("✅ Firebase token saved to Keychain")
    }
    
    func getValidToken() async throws -> String {
        // First try to get from Keychain
        if let cachedToken = try? keychainManager.retrieveString(for: .firebaseToken) {
            // Verify it's still valid
            if let currentUser = Auth.auth().currentUser {
                let tokenResult = try await currentUser.getIDTokenResult()
                
                // Check if token is still valid
                if tokenResult.expirationDate > Date() {
                    return cachedToken
                }
            }
        }
        
        // Token is expired or doesn't exist, refresh it
        return try await refreshToken()
    }
    
    func refreshToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        
        // Force refresh the token
        let token = try await currentUser.getIDToken(forcingRefresh: true)
        try keychainManager.saveString(token, for: .firebaseToken)
        
        // Get new expiration date and schedule next refresh
        let tokenResult = try await currentUser.getIDTokenResult(forcingRefresh: true)
        scheduleTokenRefresh(expirationDate: tokenResult.expirationDate)
        
        print("✅ Firebase token refreshed")
        return token
    }
    
    func clearTokens() throws {
        try keychainManager.clearTokens()
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("✅ All tokens cleared from Keychain")
    }
    
    // MARK: - Automatic Token Refresh
    
    private func setupTokenRefreshTimer() {
        // Check for token refresh every minute
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAndRefreshTokenIfNeeded()
            }
        }
    }
    
    private func scheduleTokenRefresh(expirationDate: Date?) {
        guard let expirationDate = expirationDate else { return }
        
        // Calculate when to refresh (5 minutes before expiration)
        let refreshDate = expirationDate.addingTimeInterval(-tokenExpirationBuffer)
        
        // If refresh time is in the past or very soon, refresh immediately
        if refreshDate <= Date() {
            Task {
                try? await refreshToken()
            }
        }
    }
    
    private func checkAndRefreshTokenIfNeeded() async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            // This will automatically refresh if needed
            _ = try await getValidToken()
        } catch {
            print("❌ Failed to refresh token in background: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    func validateSession() async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            return false
        }
        
        // Reload user to get latest auth state
        try await currentUser.reload()
        
        // Check if user is still valid
        guard currentUser.uid.isEmpty == false else {
            return false
        }
        
        // Refresh token if needed
        _ = try await getValidToken()
        
        return true
    }
    
    func handleAppDidBecomeActive() {
        Task {
            do {
                // Validate session when app becomes active
                let isValid = try await validateSession()
                if !isValid {
                    // Session invalid, sign out
                    try Auth.auth().signOut()
                    try clearTokens()
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("SessionExpired"),
                        object: nil
                    )
                }
            } catch {
                print("❌ Failed to validate session: \(error)")
            }
        }
    }
    
    func handleAppWillResignActive() {
        // Save current token state before app goes to background
        Task {
            try? await saveFirebaseToken()
        }
    }
}

// MARK: - Token Storage Model

struct AuthTokens: Codable {
    let idToken: String
    let refreshToken: String?
    let expirationDate: Date
    let userId: String
    
    var isExpired: Bool {
        return expirationDate <= Date()
    }
    
    var needsRefresh: Bool {
        // Refresh if less than 5 minutes until expiration
        return expirationDate.timeIntervalSinceNow < 300
    }
}