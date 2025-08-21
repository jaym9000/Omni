import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

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
    
    // Firebase reference
    private let firebaseManager = FirebaseManager.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    @Published var isAppleUser = false
    @Published var isLoading = false
    
    private var currentNonce: String?
    
    init() {
        // Don't call checkAuthenticationStatus() from init to avoid threading issues
        // It will be called from the app's onAppear
    }
    
    func checkAuthenticationStatus(allowDelay: Bool = false) {
        // Setup Firebase auth state listener
        authStateListener = firebaseManager.auth.addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }
            
            Task {
                if let firebaseUser = firebaseUser {
                    // User is signed in
                    print("🔥 Firebase user detected: \(firebaseUser.uid)")
                    
                    // Try to fetch user from Firestore
                    if let userProfile = try? await self.firebaseManager.fetchUser(userId: firebaseUser.uid) {
                        await MainActor.run {
                            self.currentUser = userProfile
                            self.isAuthenticated = true
                            self.isEmailVerified = firebaseUser.isEmailVerified
                            self.isAppleUser = userProfile.authProvider == .apple
                            
                            // Save to UserDefaults
                            if let encoded = try? JSONEncoder().encode(userProfile) {
                                UserDefaults.standard.set(encoded, forKey: "currentUser")
                            }
                        }
                    } else if firebaseUser.isAnonymous {
                        // Handle anonymous user
                        let guestUser = User.createGuestUser(
                            id: UUID(),
                            authUserId: firebaseUser.uid
                        )
                        
                        await MainActor.run {
                            self.currentUser = guestUser
                            self.isAuthenticated = true
                            self.isEmailVerified = true
                        }
                    }
                } else {
                    // No user is signed in
                    await MainActor.run {
                        self.currentUser = nil
                        self.isAuthenticated = false
                        self.isEmailVerified = true
                        self.isAppleUser = false
                    }
                }
            }
        }
        
        // Also check UserDefaults for immediate UI update
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            self.isEmailVerified = user.emailVerified
            self.isAppleUser = user.authProvider == .apple
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
        
        do {
            // Sign in with Firebase Auth
            let authResult = try await firebaseManager.auth.signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user
            
            // Check if user exists in Firestore
            var userProfile = try await firebaseManager.fetchUser(userId: firebaseUser.uid)
            
            // If user doesn't exist in Firestore, create one
            if userProfile == nil {
                userProfile = User(
                    id: UUID(),
                    authUserId: firebaseUser.uid,
                    email: email,
                    displayName: firebaseUser.displayName ?? email.components(separatedBy: "@").first ?? "User",
                    emailVerified: firebaseUser.isEmailVerified,
                    authProvider: .email
                )
                
                // Save to Firestore
                try await firebaseManager.saveUser(userProfile!)
            }
            
            // Create constant for concurrent access
            let finalUserProfile = userProfile
            
            await MainActor.run {
                self.currentUser = finalUserProfile
                self.isAuthenticated = true
                self.isEmailVerified = firebaseUser.isEmailVerified
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(finalUserProfile) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        } catch {
            // Convert Firebase errors to our custom errors
            if let nsError = error as NSError? {
                let code = AuthErrorCode(rawValue: nsError.code)
                switch code {
                case .invalidEmail:
                    throw AuthError.invalidEmail
                case .wrongPassword, .invalidCredential:
                    throw AuthError.invalidCredentials
                case .userNotFound:
                    throw AuthError.userNotFound
                case .tooManyRequests:
                    throw AuthError.rateLimitExceeded(retryAfter: Date().addingTimeInterval(60))
                default:
                    throw AuthError.signInFailed
                }
            }
            throw AuthError.signInFailed
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
        
        do {
            // Create user with Firebase Auth
            let authResult = try await firebaseManager.auth.createUser(withEmail: email, password: password)
            let firebaseUser = authResult.user
            
            // Update display name
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Send verification email
            try await firebaseUser.sendEmailVerification()
            
            // Create user profile
            let userProfile = User(
                id: UUID(),
                authUserId: firebaseUser.uid,
                email: email,
                displayName: displayName,
                emailVerified: false,
                authProvider: .email
            )
            
            // Save to Firestore
            try await firebaseManager.saveUser(userProfile)
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isAuthenticated = true
                self.isEmailVerified = false
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(userProfile) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
        } catch {
            // Convert Firebase errors to our custom errors
            if let nsError = error as NSError? {
                let code = AuthErrorCode(rawValue: nsError.code)
                switch code {
                case .invalidEmail:
                    throw AuthError.invalidEmail
                case .emailAlreadyInUse:
                    throw AuthError.emailAlreadyInUse
                case .weakPassword:
                    throw AuthError.weakPassword
                case .tooManyRequests:
                    throw AuthError.rateLimitExceeded(retryAfter: Date().addingTimeInterval(60))
                default:
                    throw AuthError.signUpFailed
                }
            }
            throw AuthError.signUpFailed
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
            
            // Extract identity token and authorization code
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                print("❌ Unable to fetch identity token")
                throw AuthError.signInFailed
            }
            
            // Generate nonce for security
            let nonce = randomNonceString()
            currentNonce = nonce
            
            // Create OAuth credential for Firebase
            let credential = OAuthProvider.appleCredential(
                withIDToken: identityToken,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // Sign in with Firebase using Apple credential
            let authResult = try await firebaseManager.auth.signIn(with: credential)
            let firebaseUser = authResult.user
            
            print("✅ Firebase Apple Sign-In successful: \(firebaseUser.uid)")
            
            // Extract user information
            let email = appleIDCredential.email ?? firebaseUser.email ?? "apple.user@privaterelay.appleid.com"
            let fullName = appleIDCredential.fullName
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .isEmpty ? firebaseUser.displayName ?? "Apple User" : [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            // Check if user exists in Firestore
            var userProfile = try? await firebaseManager.fetchUser(userId: firebaseUser.uid)
            
            // If user doesn't exist in Firestore, create one
            if userProfile == nil {
                userProfile = User(
                    id: UUID(),
                    authUserId: firebaseUser.uid,
                    email: email,
                    displayName: displayName,
                    emailVerified: true, // Apple emails are pre-verified
                    authProvider: .apple
                )
                
                // Save to Firestore
                try await firebaseManager.saveUser(userProfile!)
                print("✅ New Apple user saved to Firestore")
            } else {
                print("✅ Existing Apple user found in Firestore")
            }
            
            // Create constant for concurrent access
            let finalUserProfile = userProfile
            
            await MainActor.run {
                self.currentUser = finalUserProfile
                self.isAuthenticated = true
                self.isEmailVerified = true
                self.isAppleUser = true
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(finalUserProfile) {
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
                print("❌ Unable to fetch identity token")
                throw AuthError.signInFailed
            }
            
            // Use existing nonce if available, or generate new one
            let nonce = currentNonce ?? randomNonceString()
            
            // Create OAuth credential for Firebase
            let credential = OAuthProvider.appleCredential(
                withIDToken: identityToken,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // Sign in with Firebase using Apple credential
            let authResult = try await firebaseManager.auth.signIn(with: credential)
            let firebaseUser = authResult.user
            
            print("✅ Firebase Apple Sign-In successful: \(firebaseUser.uid)")
            
            // Extract user information
            let email = appleIDCredential.email ?? firebaseUser.email ?? "apple.user@privaterelay.appleid.com"
            let fullName = appleIDCredential.fullName
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .isEmpty ? firebaseUser.displayName ?? "Apple User" : [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            // Check if user exists in Firestore
            var userProfile = try? await firebaseManager.fetchUser(userId: firebaseUser.uid)
            
            // If user doesn't exist in Firestore, create one
            if userProfile == nil {
                userProfile = User(
                    id: UUID(),
                    authUserId: firebaseUser.uid,
                    email: email,
                    displayName: displayName,
                    emailVerified: true, // Apple emails are pre-verified
                    authProvider: .apple
                )
                
                // Save to Firestore
                try await firebaseManager.saveUser(userProfile!)
                print("✅ New Apple user saved to Firestore")
            } else {
                print("✅ Existing Apple user found in Firestore")
            }
            
            // Create constant for concurrent access
            let finalUserProfile = userProfile
            
            await MainActor.run {
                self.currentUser = finalUserProfile
                self.isAuthenticated = true
                self.isEmailVerified = true
                self.isAppleUser = true
                
                // Save to UserDefaults as backup
                if let encoded = try? JSONEncoder().encode(finalUserProfile) {
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
            // Sign in anonymously with Firebase
            let authResult = try await firebaseManager.auth.signInAnonymously()
            let firebaseUser = authResult.user
            
            print("✅ Firebase anonymous sign-in successful: \(firebaseUser.uid)")
            
            // Create guest user profile
            let guestUser = User.createGuestUser(
                id: UUID(),
                authUserId: firebaseUser.uid
            )
            
            // Save to Firestore for consistency
            try await firebaseManager.saveUser(guestUser)
            
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
            
            print("✅ Guest session created successfully")
        } catch {
            print("❌ Failed to create guest session: \(error)")
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
            // Get the current anonymous Firebase user
            guard let firebaseUser = firebaseManager.auth.currentUser, firebaseUser.isAnonymous else {
                throw AuthError.userNotFound
            }
            
            // Create email credential
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            
            // Link the anonymous account with the email credential
            let authResult = try await firebaseUser.link(with: credential)
            let linkedUser = authResult.user
            
            // Update display name
            let changeRequest = linkedUser.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Send verification email
            try await linkedUser.sendEmailVerification()
            
            print("✅ Guest account converted to email account: \(linkedUser.uid)")
            
            // Update the user profile
            var updatedUser = currentUser
            updatedUser.email = email
            updatedUser.displayName = displayName
            updatedUser.authProvider = .email
            updatedUser.isGuest = false
            updatedUser.emailVerified = false
            updatedUser.updatedAt = Date()
            
            // Update in Firestore
            try await firebaseManager.saveUser(updatedUser)
            
            // Create constant for concurrent access
            let finalUser = updatedUser
            
            await MainActor.run {
                self.currentUser = finalUser
                self.isEmailVerified = false
                
                // Update UserDefaults
                if let encoded = try? JSONEncoder().encode(finalUser) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
            }
            
            print("✅ Guest successfully converted to permanent account")
        } catch {
            print("❌ Failed to convert guest account: \(error)")
            if let nsError = error as NSError? {
                let code = AuthErrorCode(rawValue: nsError.code)
                switch code {
                case .emailAlreadyInUse:
                    throw AuthError.emailAlreadyInUse
                case .weakPassword:
                    throw AuthError.weakPassword
                case .invalidEmail:
                    throw AuthError.invalidEmail
                default:
                    throw AuthError.signUpFailed
                }
            }
            throw AuthError.signUpFailed
        }
    }
    
    func signOut() {
        do {
            // Sign out from Firebase
            try firebaseManager.auth.signOut()
            
            Task { @MainActor in
                currentUser = nil
                isAuthenticated = false
                isEmailVerified = true
                isAppleUser = false
            }
            
            UserDefaults.standard.removeObject(forKey: "currentUser")
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            
            print("✅ Successfully signed out")
        } catch {
            print("❌ Error signing out: \(error)")
        }
    }
    
    func sendVerificationEmail() async throws {
        guard let user = currentUser else { 
            throw AuthError.userNotFound
        }
        
        // TODO: Implement Firebase email verification
        print("✅ Verification email would be sent to \(user.email)")
    }
    
    func checkEmailVerification() async throws {
        // TODO: Implement Firebase email verification check
        // For now, just mark as verified after a delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
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
        // TODO: Implement Firebase password reset
        print("Password reset would be sent to \(email)")
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
        
        // TODO: Implement Firebase profile update
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
        
        // Update in Firebase
        if let user = currentUser {
            do {
                try await firebaseManager.saveUser(user)
                print("✅ Onboarding completion saved to Firebase")
            } catch {
                print("❌ Failed to save onboarding completion to Firebase: \(error)")
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
        
        // Update in Firebase
        if let user = currentUser {
            do {
                try await firebaseManager.saveUser(user)
                print("✅ Companion settings saved to Firebase")
            } catch {
                print("❌ Failed to save companion settings to Firebase: \(error)")
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
        
        // TODO: Update in Firebase
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
        
        // TODO: Update in Firebase
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
    
    // MARK: - Native Apple Sign-In Implementation
    
    private func signInWithAppleNative() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                // Generate and save nonce for this request
                let nonce = randomNonceString()
                currentNonce = nonce
                
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
                
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