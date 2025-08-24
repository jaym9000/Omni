import Foundation

enum AuthProvider: String, Codable {
    case email
    case apple
    case google
    case anonymous
}

struct User: Codable, Identifiable {
    let id: UUID
    var authUserId: String? // Firebase Auth UID
    var email: String
    var displayName: String
    var emailVerified: Bool
    var authProvider: AuthProvider
    var avatarURL: String?
    var avatarImageName: String? // For local avatar selection
    var isPremium: Bool = false
    var biometricEnabled: Bool = false
    var dailyReminder: Bool = true
    
    // Timestamp properties for tracking changes  
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
    var guestMessageCount: Int = 0  // Deprecated - kept for backward compatibility
    var maxGuestMessages: Int = 1   // Reduced from 20 for aggressive monetization
    
    
    // RevenueCat subscription properties
    var revenueCatUserId: String?
    var subscriptionProductId: String?
    var subscriptionExpiresDate: Date?
    
    // User metadata for storing preferences
    var metadata: [String: Any]?
    var subscriptionEnvironment: String?
    var subscriptionStore: String?
    var subscriptionIsActive: Bool = false
    var subscriptionPeriodType: String?
    var subscriptionIsSandbox: Bool = false
    var lastSubscriptionEvent: String?
    var lastSubscriptionEventAt: Date?
    var hasBillingIssue: Bool = false
    
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
    
    // Custom CodingKeys for snake_case naming convention
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case email
        case displayName = "display_name"
        case emailVerified = "email_verified"
        case authProvider = "auth_provider"
        case avatarURL = "avatar_url"
        case avatarImageName = "avatar_image_name"
        case isPremium = "is_premium"
        case biometricEnabled = "biometric_enabled"
        case notificationsEnabled = "notifications_enabled"
        case dailyReminder = "daily_reminder"
        case _createdAt = "created_at"
        case _updatedAt = "updated_at"
        case companionName = "companion_name"
        case companionPersonality = "companion_personality"
        case dailyReminderTime = "daily_reminder_time"
        case biometricAuthEnabled = "biometric_auth_enabled"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case isGuest = "is_guest"
        case guestMessageCount = "guest_message_count"
        case maxGuestMessages = "max_guest_messages"
        case revenueCatUserId = "revenuecat_user_id"
        case subscriptionProductId = "subscription_product_id"
        case subscriptionExpiresDate = "subscription_expires_date"
        case subscriptionEnvironment = "subscription_environment"
        case subscriptionStore = "subscription_store"
        case subscriptionIsActive = "subscription_is_active"
        case subscriptionPeriodType = "subscription_period_type"
        case subscriptionIsSandbox = "subscription_is_sandbox"
        case lastSubscriptionEvent = "last_subscription_event"
        case lastSubscriptionEventAt = "last_subscription_event_at"
        case hasBillingIssue = "has_billing_issue"
    }
    
    // Custom initializer for database compatibility
    init(id: UUID, authUserId: String? = nil, email: String, displayName: String, emailVerified: Bool = false, authProvider: AuthProvider = .email) {
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
    static func createGuestUser(id: UUID, authUserId: String?) -> User {
        var guestUser = User(
            id: id,
            authUserId: authUserId,
            email: "guest@anonymous.local",
            displayName: "Guest User",
            emailVerified: false,
            authProvider: .anonymous
        )
        guestUser.isGuest = true
        guestUser.guestMessageCount = 0
        guestUser.maxGuestMessages = 1  // Only 1 message for guests
        return guestUser
    }
}