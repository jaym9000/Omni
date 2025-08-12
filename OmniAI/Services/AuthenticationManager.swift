import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isEmailVerified = true
    @Published var isAppleUser = false
    @Published var isLoading = false
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Check if user is logged in from UserDefaults/Keychain
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            self.isEmailVerified = user.emailVerified
            self.isAppleUser = user.authProvider == .apple
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            emailVerified: true,
            authProvider: .email
        )
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.isEmailVerified = true
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: displayName,
            emailVerified: false,
            authProvider: .email
        )
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.isEmailVerified = false
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
    }
    
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate Apple Sign In
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            email: "apple.user@privaterelay.appleid.com",
            displayName: "Apple User",
            emailVerified: true,
            authProvider: .apple
        )
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.isEmailVerified = true
            self.isAppleUser = true
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        isEmailVerified = true
        isAppleUser = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    func sendVerificationEmail() async throws {
        // Simulate sending verification email
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func checkEmailVerification() async throws {
        // Simulate checking email verification
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            self.isEmailVerified = true
            if var user = currentUser {
                user.emailVerified = true
                self.currentUser = user
                
                // Update UserDefaults
                if let encoded = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        }
    }
    
    func resetPassword(email: String) async throws {
        // Simulate password reset
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func updateProfile(displayName: String, avatarEmoji: String? = nil, bio: String? = nil) async {
        await MainActor.run {
            guard var user = self.currentUser else { return }
            
            // Update user properties
            user.displayName = displayName
            if let avatarEmoji = avatarEmoji {
                user.avatarURL = avatarEmoji
            }
            user.updatedAt = Date()
            
            self.currentUser = user
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
    }
    
    func updateCompanionSettings(name: String, personality: String) async {
        await MainActor.run {
            guard var user = self.currentUser else { return }
            
            user.companionName = name
            user.companionPersonality = personality
            user.updatedAt = Date()
            
            self.currentUser = user
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
    }
    
    func toggleBiometricAuth(_ enabled: Bool) async {
        await MainActor.run {
            guard var user = self.currentUser else { return }
            
            user.biometricAuthEnabled = enabled
            user.updatedAt = Date()
            
            self.currentUser = user
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
    }
}