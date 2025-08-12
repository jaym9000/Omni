import Foundation

enum AuthProvider: String, Codable {
    case email
    case apple
    case google
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var displayName: String
    var emailVerified: Bool
    let authProvider: AuthProvider
    var avatarURL: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Companion settings
    var companionName: String = "Omni"
    var companionPersonality: String = "supportive"
    
    // User preferences
    var notificationsEnabled: Bool = true
    var dailyReminderTime: Date?
    var biometricAuthEnabled: Bool = false
}