import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit

enum AuthError: Error, LocalizedError {
    case signUpFailed
    case signInFailed
    case userNotFound
    case invalidCredentials
    case weakPassword
    case invalidEmail
    case rateLimitExceeded(retryAfter: Date?)
    case emailAlreadyInUse
    case accountLocked
    
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
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Too many failed attempts. Try again after \(formatter.string(from: retryAfter))"
            } else {
                return "Too many failed attempts. Please try again later"
            }
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .accountLocked:
            return "Account temporarily locked due to failed login attempts"
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
    private var currentNonce: String?
    
    init() {
        // Don't call checkAuthenticationStatus() from init to avoid threading issues
        // It will be called from the app's onAppear
    }
    
    func checkAuthenticationStatus(allowDelay: Bool = false) {
        // Check if user is logged in from UserDefaults/Keychain for immediate UI update
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            self.isEmailVerified = user.emailVerified
            self.isAppleUser = user.authProvider == .apple
        }
        
        Task {
            // Add delay for initial session restoration if requested
            if allowDelay {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            do {
                // Check if there's an active Supabase session
                let session = try await supabase.auth.session
                
                if session.accessToken.isEmpty {
                    print("⚠️ Empty access token, checking UserDefaults fallback")
                    // Don't immediately sign out - check if we have valid cached data
                    if let userData = UserDefaults.standard.data(forKey: "currentUser"),
                       let user = try? JSONDecoder().decode(User.self, from: userData) {
                        print("📱 Using cached user data from UserDefaults")
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
                    return
                }
                
                print("🔐 Checking authentication status for user: \(session.user.id)")
                
                // Fetch user profile from Supabase
                do {
                    // First try by auth_user_id (correct way)
                    let userProfile: User = try await supabase
                        .from("users")
                        .select()
                        .eq("auth_user_id", value: session.user.id)
                        .single()
                        .execute()
                        .value
                    
                    print("✅ User found in public.users table")
                    print("   - Public User ID: \(userProfile.id)")
                    print("   - Auth User ID: \(userProfile.authUserId?.uuidString ?? "nil")")
                    
                    await MainActor.run {
                        self.currentUser = userProfile
                        self.isAuthenticated = true
                        self.isEmailVerified = userProfile.emailVerified
                        self.isAppleUser = userProfile.authProvider == .apple
                        
                        // Update UserDefaults with fresh data
                        if let encoded = try? JSONEncoder().encode(userProfile) {
                            UserDefaults.standard.set(encoded, forKey: "currentUser")
                        }
                    }
                } catch {
                    print("⚠️ User not found by auth_user_id, checking legacy format where id = auth_user_id...")
                    
                    // Try legacy format where id = auth_user_id (for old users)
                    do {
                        let legacyUserProfile: User = try await supabase
                            .from("users")
                            .select()
                            .eq("id", value: session.user.id)
                            .single()
                            .execute()
                            .value
                        
                        print("⚠️ Found legacy user where id = auth_user_id")
                        print("   - Will use this user but data structure is legacy")
                        
                        await MainActor.run {
                            self.currentUser = legacyUserProfile
                            self.isAuthenticated = true
                            self.isEmailVerified = legacyUserProfile.emailVerified
                            self.isAppleUser = legacyUserProfile.authProvider == .apple
                            
                            // Update UserDefaults with fresh data
                            if let encoded = try? JSONEncoder().encode(legacyUserProfile) {
                                UserDefaults.standard.set(encoded, forKey: "currentUser")
                            }
                        }
                        return
                    } catch {
                        print("⚠️ User exists in auth but not in public.users table. Attempting to create user record...")
                        
                        // Try to create missing user record based on auth data
                        await createMissingUserRecord(from: session)
                    }
                }
                
            } catch {
                print("❌ Authentication check failed: \(error)")
                
                // Check if it's just a sessionMissing error (not necessarily a real failure)
                let errorString = error.localizedDescription.lowercased()
                if errorString.contains("sessionmissing") || errorString.contains("session") {
                    print("⚠️ Session missing error - checking UserDefaults fallback")
                    
                    // Fallback to UserDefaults for cached session
                    if let userData = UserDefaults.standard.data(forKey: "currentUser"),
                       let user = try? JSONDecoder().decode(User.self, from: userData) {
                        print("📱 Using cached user data from UserDefaults")
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                            self.isEmailVerified = user.emailVerified
                            self.isAppleUser = user.authProvider == .apple
                        }
                        return
                    }
                }
                
                // Only sign out for genuine authentication failures
                print("🚫 Genuine authentication failure, signing out")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    private func createMissingUserRecord(from session: Session) async {
        do {
            print("🔨 Creating missing user record for auth user: \(session.user.id)")
            
            // First check if user already exists (race condition protection)
            let userUUID = UUID(uuidString: session.user.id.uuidString) ?? UUID()
            
            do {
                let existingUser: User = try await supabase
                    .from("users")
                    .select()
                    .eq("auth_user_id", value: userUUID)
                    .single()
                    .execute()
                    .value
                
                print("✅ User record already exists, using existing record")
                
                await MainActor.run {
                    self.currentUser = existingUser
                    self.isAuthenticated = true
                    self.isEmailVerified = existingUser.emailVerified
                    self.isAppleUser = existingUser.authProvider == .apple
                    
                    // Update UserDefaults
                    if let encoded = try? JSONEncoder().encode(existingUser) {
                        UserDefaults.standard.set(encoded, forKey: "currentUser")
                    }
                }
                return
                
            } catch {
                // User doesn't exist, proceed to create
                print("📝 User doesn't exist, proceeding to create new record")
            }
            
            // Determine user type and create appropriate user record
            let userProfile: User
            
            if session.user.isAnonymous {
                // Create guest user record with new UUID for public.users table
                userProfile = User.createGuestUser(
                    id: UUID(), // New UUID for public.users.id
                    authUserId: userUUID // auth.users.id
                )
                print("👤 Creating guest user record")
            } else {
                // Create regular user record
                let email = session.user.email ?? "unknown@example.com"
                let displayName = session.user.userMetadata["full_name"] as? String ?? 
                                 email.components(separatedBy: "@").first ?? "User"
                
                userProfile = User(
                    id: UUID(), // New UUID for public.users.id
                    authUserId: userUUID, // auth.users.id
                    email: email,
                    displayName: displayName,
                    emailVerified: session.user.emailConfirmedAt != nil,
                    authProvider: .email // Default, could be improved with more metadata
                )
                print("👤 Creating regular user record for email: \(email)")
            }
            
            // Insert user into database
            try await supabase
                .from("users")
                .insert(userProfile)
                .execute()
            
            print("✅ Successfully created missing user record")
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isAuthenticated = true
                self.isEmailVerified = userProfile.emailVerified
                self.isAppleUser = userProfile.authProvider == .apple
                
                // Update UserDefaults
                if let encoded = try? JSONEncoder().encode(userProfile) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
            
        } catch {
            print("❌ Failed to create missing user record: \(error)")
            
            // Check if it's a duplicate key error (user was created by another process)
            if let supabaseError = error as? NSError, 
               supabaseError.code == 23505 || error.localizedDescription.contains("duplicate key") {
                print("⚠️ User record was created by another process, re-checking...")
                
                // Try to fetch the user record one more time
                let userUUID = UUID(uuidString: session.user.id.uuidString) ?? UUID()
                do {
                    let existingUser: User = try await supabase
                        .from("users")
                        .select()
                        .eq("id", value: userUUID)
                        .single()
                        .execute()
                        .value
                    
                    print("✅ Found user record after duplicate key error")
                    
                    await MainActor.run {
                        self.currentUser = existingUser
                        self.isAuthenticated = true
                        self.isEmailVerified = existingUser.emailVerified
                        self.isAppleUser = existingUser.authProvider == .apple
                        
                        // Update UserDefaults
                        if let encoded = try? JSONEncoder().encode(existingUser) {
                            UserDefaults.standard.set(encoded, forKey: "currentUser")
                        }
                    }
                    return
                    
                } catch {
                    print("❌ Still can't find user record after duplicate key error")
                }
            }
            
            // If we can't create or find the user record, sign out to avoid inconsistent state
            print("🚫 Signing out due to persistent user record issue")
            await MainActor.run {
                self.signOut()
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Validate email format
        try validateEmail(email)
        
        // Check rate limiting
        try await checkRateLimit(for: email)
        
        // Supabase integration for email/password sign in
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Create or update user profile in Supabase
            let userProfile = User(
                id: UUID(uuidString: authResponse.user.id.uuidString) ?? UUID(),
                authUserId: UUID(uuidString: authResponse.user.id.uuidString),
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
            
            // Reset rate limit on successful login
            await resetRateLimit(for: email)
            
        } catch {
            print("❌ Sign in failed: \(error)")
            
            // Record failed attempt
            await recordFailedAttempt(for: email)
            
            // Parse specific error types
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("invalid login credentials") {
                throw AuthError.invalidCredentials
            } else if errorMessage.contains("email not confirmed") {
                throw AuthError.signInFailed
            } else {
                throw AuthError.signInFailed
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        await MainActor.run { isLoading = true }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Validate email format
        try validateEmail(email)
        
        // Validate password strength
        try validatePassword(password)
        
        // Check rate limiting
        try await checkRateLimit(for: email)
        
        // Supabase integration for email/password sign up
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(displayName)]
            )
            
            let authUser = authResponse.user
            
            // The database trigger will automatically create the user profile
            // Wait a moment for the trigger to complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Fetch the created user profile
            do {
                let userProfile: User = try await supabase
                    .from("users")
                    .select()
                    .eq("auth_user_id", value: authUser.id)
                    .single()
                    .execute()
                    .value
                
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
                // If profile doesn't exist yet, create a temporary one
                let tempProfile = User(
                    id: UUID(),
                    authUserId: authUser.id,
                    email: email,
                    displayName: displayName,
                    emailVerified: authUser.emailConfirmedAt != nil,
                    authProvider: .email
                )
                
                await MainActor.run {
                    self.currentUser = tempProfile
                    self.isAuthenticated = true
                    self.isEmailVerified = tempProfile.emailVerified
                }
            }
        } catch {
            print("❌ Sign up failed: \(error)")
            
            // Record failed attempt
            await recordFailedAttempt(for: email)
            
            // Parse specific error types
            let errorMessage = error.localizedDescription.lowercased()
            
            // Check for RLS policy violations
            if errorMessage.contains("row-level security policy") || errorMessage.contains("42501") {
                print("⚠️ RLS policy violation - database schema may need updating")
                print("   Run supabase_migration_fix.sql in Supabase dashboard")
                throw AuthError.signUpFailed
            } else if errorMessage.contains("user already registered") || errorMessage.contains("email address is already registered") {
                throw AuthError.emailAlreadyInUse
            } else if errorMessage.contains("duplicate key") || errorMessage.contains("23505") {
                // User might already exist, try to sign in instead
                print("⚠️ User might already exist, suggesting sign-in instead")
                throw AuthError.emailAlreadyInUse
            } else {
                throw AuthError.signUpFailed
            }
        }
    }
    
    func signInWithApple() async throws {
        await MainActor.run { isLoading = true }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Get Apple ID credential using native Sign in with Apple
            let appleIDCredential = try await signInWithAppleNative()
            
            // Extract identity token
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                throw AuthError.signInFailed
            }
            
            // Sign in to Supabase with Apple ID token
            let authResponse = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken
                )
            )
            
            // Extract user information
            let email = appleIDCredential.email ?? authResponse.user.email ?? "apple.user@privaterelay.appleid.com"
            let fullName = appleIDCredential.fullName
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .isEmpty ? "Apple User" : [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            // Create user profile
            let userProfile = User(
                id: UUID(uuidString: authResponse.user.id.uuidString) ?? UUID(),
                authUserId: UUID(uuidString: authResponse.user.id.uuidString),
                email: email,
                displayName: displayName,
                emailVerified: true,
                authProvider: .apple
            )
            
            // Check if user exists and preserve onboarding status
            var profileToSave = userProfile
            do {
                let existingUser: User = try await supabase
                    .from("users")
                    .select()
                    .eq("auth_user_id", value: userProfile.authUserId ?? userProfile.id)
                    .single()
                    .execute()
                    .value
                
                // Preserve onboarding status from existing user
                profileToSave.hasCompletedOnboarding = existingUser.hasCompletedOnboarding
            } catch {
                // User doesn't exist, use default onboarding status
                profileToSave.hasCompletedOnboarding = false
            }
            
            // Insert or update user in database
            try await supabase
                .from("users")
                .upsert(profileToSave)
                .execute()
            
            await MainActor.run {
                self.currentUser = profileToSave
                self.isAuthenticated = true
                self.isEmailVerified = true
                self.isAppleUser = true
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(profileToSave) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
            
        } catch {
            print("❌ Apple Sign-In error: \(error)")
            throw AuthError.signInFailed
        }
    }
    
    // Handle Apple Sign-In from SignInWithAppleButton
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async throws {
        await MainActor.run { isLoading = true }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        print("🍎 Processing Apple Sign-In result...")
        
        switch result {
        case .success(let authorization):
            print("✅ Apple authorization successful")
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("❌ Failed to cast to ASAuthorizationAppleIDCredential")
                throw AuthError.signInFailed
            }
            
            // Extract identity token
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                print("❌ Failed to extract identity token")
                throw AuthError.signInFailed
            }
            
            print("🔐 Identity token extracted successfully")
            
            // Sign in to Supabase with Apple ID token (without nonce for simplicity)
            let authResponse = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken
                )
            )
            
            print("✅ Supabase authentication successful for user: \(authResponse.user.id)")
            
            // Extract user information
            let email = appleIDCredential.email ?? authResponse.user.email ?? "apple.user@privaterelay.appleid.com"
            let fullName = appleIDCredential.fullName
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .isEmpty ? "Apple User" : [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            // Create user profile
            let userProfile = User(
                id: UUID(uuidString: authResponse.user.id.uuidString) ?? UUID(),
                authUserId: UUID(uuidString: authResponse.user.id.uuidString),
                email: email,
                displayName: displayName,
                emailVerified: true,
                authProvider: .apple
            )
            
            // Check if user exists and preserve onboarding status
            var profileToSave = userProfile
            do {
                let existingUser: User = try await supabase
                    .from("users")
                    .select()
                    .eq("auth_user_id", value: userProfile.authUserId ?? userProfile.id)
                    .single()
                    .execute()
                    .value
                
                // Preserve onboarding status from existing user
                profileToSave.hasCompletedOnboarding = existingUser.hasCompletedOnboarding
            } catch {
                // User doesn't exist, use default onboarding status
                profileToSave.hasCompletedOnboarding = false
            }
            
            // Insert or update user in database
            try await supabase
                .from("users")
                .upsert(profileToSave)
                .execute()
            
            await MainActor.run {
                self.currentUser = profileToSave
                self.isAuthenticated = true
                self.isEmailVerified = true
                self.isAppleUser = true
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(profileToSave) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
            
        case .failure(let error):
            print("❌ Apple Sign-In failed with error: \(error)")
            print("   - Error type: \(type(of: error))")
            if let authError = error as? ASAuthorizationError {
                print("   - ASAuthorizationError code: \(authError.code)")
                print("   - ASAuthorizationError description: \(authError.localizedDescription)")
            }
            throw AuthError.signInFailed
        }
    }
    
    func startGuestSession() async throws {
        await MainActor.run { isLoading = true }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Create anonymous Supabase user
            let authResponse = try await supabase.auth.signInAnonymously()
            print("🔐 Created anonymous auth user: \(authResponse.user.id)")
            
            // Convert Supabase user ID to proper UUID
            guard let userUUID = UUID(uuidString: authResponse.user.id.uuidString) else {
                throw AuthError.signInFailed
            }
            
            // Check if user already exists in public.users table by auth_user_id
            do {
                let existingUser: User = try await supabase
                    .from("users")
                    .select()
                    .eq("auth_user_id", value: userUUID)
                    .single()
                    .execute()
                    .value
                
                print("✅ Found existing guest user in database")
                
                await MainActor.run {
                    self.currentUser = existingUser
                    self.isAuthenticated = true
                    self.isEmailVerified = true
                    self.isAppleUser = false
                    
                    // Save to UserDefaults
                    if let encoded = try? JSONEncoder().encode(existingUser) {
                        UserDefaults.standard.set(encoded, forKey: "currentUser")
                    }
                }
                return
                
            } catch {
                // User doesn't exist, create new one
                print("📝 Creating new guest user record")
            }
            
            // Create guest user profile with auth user ID
            let guestUser = User.createGuestUser(
                id: userUUID,
                authUserId: userUUID
            )
            
            // Upsert guest user into public.users table
            try await supabase
                .from("users")
                .upsert(guestUser)
                .execute()
            
            print("✅ Successfully created guest user in public.users table")
            
            await MainActor.run {
                self.currentUser = guestUser
                self.isAuthenticated = true
                self.isEmailVerified = true  // Guest users don't need email verification
                self.isAppleUser = false
                
                // Save to UserDefaults
                if let encoded = try? JSONEncoder().encode(guestUser) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        } catch {
            print("❌ Error creating guest session: \(error)")
            print("   - Error type: \(type(of: error))")
            if let supabaseError = error as? NSError {
                print("   - Supabase error code: \(supabaseError.code)")
                print("   - Supabase error description: \(supabaseError.localizedDescription)")
            }
            
            // Don't fall back to local user - throw the error to surface the real issue
            throw AuthError.signInFailed
        }
    }
    
    func convertGuestToRealAccount(email: String, password: String, displayName: String) async throws {
        guard let currentUser = currentUser, currentUser.isGuest else {
            throw AuthError.userNotFound
        }
        
        await MainActor.run { isLoading = true }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Convert anonymous user to real account by updating user attributes
            let userAttributes = UserAttributes(
                email: email,
                password: password
            )
            try await supabase.auth.update(user: userAttributes)
            
            // Create updated user profile
            var updatedUser = currentUser
            updatedUser.email = email
            updatedUser.displayName = displayName
            updatedUser.authProvider = .email
            updatedUser.isGuest = false
            updatedUser.emailVerified = false
            updatedUser.updatedAt = Date()
            
            // Update user in database
            try await supabase
                .from("users")
                .update(updatedUser)
                .eq("id", value: currentUser.id)
                .execute()
            
            await MainActor.run {
                self.currentUser = updatedUser
                self.isEmailVerified = false
                
                // Update UserDefaults
                if let encoded = try? JSONEncoder().encode(updatedUser) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        } catch {
            print("❌ Guest to real account conversion failed: \(error)")
            throw AuthError.signUpFailed
        }
    }
    
    func signOut() {
        Task { @MainActor in
            currentUser = nil
            isAuthenticated = false
            isEmailVerified = true
            isAppleUser = false
        }
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
        guard let user = currentUser else { 
            throw AuthError.userNotFound
        }
        
        // Supabase email verification - use correct type
        do {
            // For new sign ups, use .signup type for verification
            try await supabase.auth.resend(
                email: user.email,
                type: .signup  // Changed from .emailChange to .signup
            )
            print("✅ Verification email sent to \(user.email)")
        } catch {
            print("❌ Error sending verification email: \(error)")
            throw AuthError.signUpFailed
        }
    }
    
    func checkEmailVerification() async throws {
        // Poll Supabase for actual verification status
        var attempts = 0
        let maxAttempts = 60 // Check for 60 seconds max
        
        while attempts < maxAttempts {
            do {
                // Get fresh user data from Supabase
                let session = try await supabase.auth.session
                let isVerified = session.user.emailConfirmedAt != nil
                
                if isVerified {
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
                    
                    // Also update in database
                    if let user = currentUser {
                        var updatedUser = user
                        updatedUser.emailVerified = true
                        
                        try await supabase
                            .from("users")
                            .update(updatedUser)
                            .eq("id", value: user.id)
                            .execute()
                    }
                    
                    print("✅ Email verified successfully")
                    return
                }
                
                // Wait 1 second before next check
                try await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1
                
            } catch {
                print("❌ Error checking verification: \(error)")
                // Continue polling despite errors
            }
        }
        
        print("⚠️ Email verification check timed out after \(maxAttempts) seconds")
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
            let updatedUser = createUpdatedUser(from: user, displayName: displayName, avatarEmoji: avatarEmoji)
            
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
    
    func markOnboardingCompleted() async {
        await MainActor.run {
            guard var user = self.currentUser else { return }
            
            user.hasCompletedOnboarding = true
            user.updatedAt = Date()
            
            self.currentUser = user
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
        
        // Update in Supabase
        guard let user = currentUser else { return }
        
        do {
            var updatedUser = user
            updatedUser.hasCompletedOnboarding = true
            updatedUser.updatedAt = Date()
            
            try await supabase
                .from("users")
                .update(updatedUser)
                .eq("id", value: user.id)
                .execute()
        } catch {
            print("Error updating onboarding status: \(error)")
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
            let updatedUser = createUpdatedUserForCompanion(from: user, name: name, personality: personality)
            
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
    
    func incrementGuestConversationCount() async {
        await MainActor.run {
            guard var user = self.currentUser, user.isGuest else { return }
            
            user.guestConversationCount += 1
            user.updatedAt = Date()
            
            self.currentUser = user
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
        
        // Update in Supabase
        guard let user = currentUser else { return }
        
        do {
            var updatedUser = user
            updatedUser.guestConversationCount = user.guestConversationCount
            updatedUser.updatedAt = Date()
            
            try await supabase
                .from("users")
                .update(updatedUser)
                .eq("id", value: user.id)
                .execute()
        } catch {
            print("Error updating guest conversation count: \(error)")
            // Continue with local update only
        }
    }
    
    // MARK: - Nonce Generation for Apple Sign-In Security
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Validation Functions
    
    private func validateEmail(_ email: String) throws {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidEmail
        }
        
        // Block common disposable email domains for security
        let disposableDomains = ["10minutemail.com", "tempmail.org", "guerrillamail.com"]
        let domain = email.components(separatedBy: "@").last?.lowercased() ?? ""
        
        if disposableDomains.contains(domain) {
            throw AuthError.invalidEmail
        }
    }
    
    private func validatePassword(_ password: String) throws {
        // Check minimum length
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        // Check for uppercase letter
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }
        
        // Check for lowercase letter
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }
        
        // Check for digit
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }
        
        // Check for common weak passwords
        let weakPatterns = ["password", "123456", "qwerty", "letmein", "admin", "welcome"]
        for pattern in weakPatterns {
            if password.lowercased().contains(pattern) {
                throw AuthError.weakPassword
            }
        }
    }
    
    private func checkRateLimit(for email: String) async throws {
        // For now, skip rate limit checks as RPC functions aren't set up
        // This would normally check against a rate_limits table
        print("⚠️ Rate limit check skipped - RPC functions not configured")
    }
    
    private func recordFailedAttempt(for email: String, userId: UUID? = nil) async {
        // For now, skip recording failed attempts as RPC functions aren't set up
        print("⚠️ Failed attempt recording skipped - RPC functions not configured")
    }
    
    private func resetRateLimit(for email: String) async {
        // For now, skip resetting rate limits as RPC functions aren't set up
        print("⚠️ Rate limit reset skipped - RPC functions not configured")
    }
    
    // MARK: - Helper Functions
    
    private func createUpdatedUser(from user: User, displayName: String, avatarEmoji: String?) -> User {
        var updatedUser = user
        updatedUser.displayName = displayName
        if let avatarEmoji = avatarEmoji {
            updatedUser.avatarURL = avatarEmoji
        }
        updatedUser.updatedAt = Date()
        return updatedUser
    }
    
    private func createUpdatedUserForCompanion(from user: User, name: String, personality: String) -> User {
        var updatedUser = user
        updatedUser.companionName = name
        updatedUser.companionPersonality = personality
        updatedUser.updatedAt = Date()
        return updatedUser
    }
    
    // MARK: - Native Apple Sign-In Implementation
    
    private func signInWithAppleNative() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                
                // Create a temporary coordinator for this request
                let coordinator = AppleSignInCoordinatorTemp { result in
                    continuation.resume(with: result)
                }
                
                authorizationController.delegate = coordinator
                authorizationController.presentationContextProvider = coordinator
                
                // Keep the coordinator alive during the async operation
                withExtendedLifetime(coordinator) {
                    authorizationController.performRequests()
                }
            }
        }
    }
}

// MARK: - Temporary Apple Sign-In Coordinator
@MainActor
private class AppleSignInCoordinatorTemp: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(AuthError.signInFailed))
            return
        }
        
        completion(.success(appleIDCredential))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}