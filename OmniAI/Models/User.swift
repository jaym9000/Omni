import Foundation

enum AuthProvider: String, Codable {
    case email
    case apple
    case google
    case anonymous
}

struct User: Codable, Identifiable {
    let id: UUID
    var authUserId: UUID? // References auth.users(id) for RLS
    var email: String
    var displayName: String
    var emailVerified: Bool
    var authProvider: AuthProvider
    var avatarURL: String?
    
    // Use separate properties for Supabase timestamp handling
    private var _createdAt: String
    private var _updatedAt: String
    
    // Companion settings
    var companionName: String = "Omni"
    var companionPersonality: String = "supportive"
    
    // User preferences
    var notificationsEnabled: Bool = true
    var dailyReminderTime: Date?
    var biometricAuthEnabled: Bool = false
    var hasCompletedOnboarding: Bool = false
    
    // Guest user properties
    var isGuest: Bool = false
    var guestConversationCount: Int = 0
    var maxGuestConversations: Int = 3
    
    // Computed properties for date handling
    var createdAt: Date {
        get { 
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: _createdAt) ?? Date()
        }
        set { 
            let formatter = ISO8601DateFormatter()
            _createdAt = formatter.string(from: newValue)
        }
    }
    
    var updatedAt: Date {
        get { 
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: _updatedAt) ?? Date()
        }
        set { 
            let formatter = ISO8601DateFormatter()
            _updatedAt = formatter.string(from: newValue)
        }
    }
    
    // Custom CodingKeys for Supabase snake_case naming
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case email
        case displayName = "display_name"
        case emailVerified = "email_verified"
        case authProvider = "auth_provider"
        case avatarURL = "avatar_url"
        case _createdAt = "created_at"
        case _updatedAt = "updated_at"
        case companionName = "companion_name"
        case companionPersonality = "companion_personality"
        case notificationsEnabled = "notifications_enabled"
        case dailyReminderTime = "daily_reminder_time"
        case biometricAuthEnabled = "biometric_auth_enabled"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case isGuest = "is_guest"
        case guestConversationCount = "guest_conversation_count"
        case maxGuestConversations = "max_guest_conversations"
    }
    
    // Custom initializer for Supabase compatibility
    init(id: UUID, authUserId: UUID? = nil, email: String, displayName: String, emailVerified: Bool = false, authProvider: AuthProvider = .email) {
        self.id = id
        self.authUserId = authUserId
        self.email = email
        self.displayName = displayName
        self.emailVerified = emailVerified
        self.authProvider = authProvider
        
        let now = ISO8601DateFormatter().string(from: Date())
        self._createdAt = now
        self._updatedAt = now
    }
    
    // Guest user initializer
    static func createGuestUser(id: UUID, authUserId: UUID) -> User {
        var guestUser = User(
            id: id,
            authUserId: authUserId,
            email: "guest@anonymous.local",
            displayName: "Guest User",
            emailVerified: false,
            authProvider: .anonymous
        )
        guestUser.isGuest = true
        guestUser.guestConversationCount = 0
        return guestUser
    }
}