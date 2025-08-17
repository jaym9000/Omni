import Foundation
import SwiftUI
import Supabase

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
    
    private let supabase = SupabaseManager.shared.client
    
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
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        
        // Supabase integration for email/password sign in
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Create or update user profile in Supabase
            let userProfile = User(
                id: UUID(uuidString: authResponse.user.id.uuidString) ?? UUID(),
                email: email,
                displayName: email.components(separatedBy: "@").first ?? "User",
                emailVerified: authResponse.user.emailConfirmedAt != nil,
                authProvider: .email
            )
            
            // Insert or update user in database
            try await supabase
                .from("users")
                .upsert(userProfile)
                .execute()
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isAuthenticated = true
                self.isEmailVerified = userProfile.emailVerified
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(userProfile) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        } catch {
            // Keep fallback mock behavior for development
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
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        
        // Supabase integration for email/password sign up
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Create user profile in Supabase
            let userProfile = User(
                id: UUID(uuidString: authResponse.user.id.uuidString) ?? UUID(),
                email: email,
                displayName: displayName,
                emailVerified: authResponse.user.emailConfirmedAt != nil,
                authProvider: .email
            )
            
            // Insert user in database
            try await supabase
                .from("users")
                .insert(userProfile)
                .execute()
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isAuthenticated = true
                self.isEmailVerified = userProfile.emailVerified
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(userProfile) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        } catch {
            // Keep fallback mock behavior for development
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
        }
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
        
        // Supabase sign out
        Task {
            do {
                try await supabase.auth.signOut()
            } catch {
                print("Error signing out from Supabase: \(error)")
            }
        }
    }
    
    func sendVerificationEmail() async throws {
        guard let user = currentUser else { return }
        
        // Supabase email verification
        do {
            try await supabase.auth.resend(
                email: user.email,
                type: .emailChange
            )
        } catch {
            print("Error sending verification email: \(error)")
            // Continue with mock behavior
        }
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
        // Supabase password reset
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            print("Error sending password reset: \(error)")
            // Continue with mock behavior
        }
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
        
        // Supabase profile update
        guard let user = currentUser else { return }
        
        do {
            var updatedUser = user
            updatedUser.displayName = displayName
            if let avatarEmoji = avatarEmoji {
                updatedUser.avatarURL = avatarEmoji
            }
            updatedUser.updatedAt = Date()
            
            try await supabase
                .from("users")
                .update(updatedUser)
                .eq("id", value: user.id)
                .execute()
        } catch {
            print("Error updating profile: \(error)")
            // Continue with local update only
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
        
        // Supabase companion settings update
        guard let user = currentUser else { return }
        
        do {
            var updatedUser = user
            updatedUser.companionName = name
            updatedUser.companionPersonality = personality
            updatedUser.updatedAt = Date()
            
            try await supabase
                .from("users")
                .update(updatedUser)
                .eq("id", value: user.id)
                .execute()
        } catch {
            print("Error updating companion settings: \(error)")
            // Continue with local update only
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
        
        // Supabase biometric auth update
        guard let user = currentUser else { return }
        
        do {
            var updatedUser = user
            updatedUser.biometricAuthEnabled = enabled
            updatedUser.updatedAt = Date()
            
            try await supabase
                .from("users")
                .update(updatedUser)
                .eq("id", value: user.id)
                .execute()
        } catch {
            print("Error updating biometric setting: \(error)")
            // Continue with local update only
        }
    }
}