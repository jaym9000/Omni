import Foundation
import SwiftUI
// import Supabase // TODO: Re-enable when added to Xcode project

enum AuthError: Error, LocalizedError {
    case signUpFailed
    case signInFailed
    case userNotFound
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account"
        case .signInFailed:
            return "Failed to sign in"
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isEmailVerified = true
    @Published var isAppleUser = false
    @Published var isLoading = false
    
    // private let supabase = SupabaseManager.shared.client // TODO: Re-enable when added to Xcode project
    
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
        
        // TODO: Re-enable Supabase integration when added to Xcode project
        /*
        Task {
            do {
                // Check if there's an active Supabase session
                let session = try await supabase.auth.session
                
                if session.accessToken.isEmpty {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                    return
                }
                
                // Fetch user profile from Supabase
                let userProfile: User = try await supabase
                    .from("users")
                    .select()
                    .eq("id", value: session.user.id)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.currentUser = userProfile
                    self.isAuthenticated = true
                    self.isEmailVerified = userProfile.emailVerified
                    self.isAppleUser = userProfile.authProvider == .apple
                }
                
            } catch {
                // Fallback to UserDefaults for backward compatibility
                if let userData = UserDefaults.standard.data(forKey: "currentUser"),
                   let user = try? JSONDecoder().decode(User.self, from: userData) {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isEmailVerified = user.emailVerified
                        self.isAppleUser = user.authProvider == .apple
                    }
                } else {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                }
            }
        }
        */
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID(),
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
        
        // TODO: Re-enable Supabase integration when added to Xcode project
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID(),
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
        
        // TODO: Re-enable Supabase integration when added to Xcode project
    }
    
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate Apple Sign In
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID(),
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
        
        // TODO: Re-enable Supabase sign out when added to Xcode project
    }
    
    func sendVerificationEmail() async throws {
        guard let user = currentUser else { return }
        
        // Simulate sending verification email
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // TODO: Re-enable Supabase verification when added to Xcode project
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
        
        // TODO: Re-enable Supabase password reset when added to Xcode project
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
        
        // TODO: Re-enable Supabase profile update when added to Xcode project
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
        
        // TODO: Re-enable Supabase companion update when added to Xcode project
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
        
        // TODO: Re-enable Supabase biometric update when added to Xcode project
    }
}