//
//  BiometricAuthManager.swift
//  OmniAI
//
//  Biometric Authentication Manager (Face ID / Touch ID)
//

import LocalAuthentication
import SwiftUI

/// Manages biometric authentication (Face ID / Touch ID)
class BiometricAuthManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var isAvailable = false
    @Published var error: BiometricError?
    
    // MARK: - Properties
    
    private let context = LAContext()
    private let keychainManager = KeychainManager.shared
    private let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
    
    // Keys for storing biometric settings
    private let biometricEnabledKey = "BiometricAuthEnabled"
    private let lastAuthTimeKey = "LastBiometricAuthTime"
    private let authValidityDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init() {
        checkBiometricAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the device
    func checkBiometricAvailability() {
        var error: NSError?
        
        isAvailable = context.canEvaluatePolicy(policy, error: &error)
        
        if isAvailable {
            biometricType = context.biometryType
            print("✅ Biometric authentication available: \(biometricTypeString)")
        } else {
            biometricType = .none
            if let error = error {
                print("❌ Biometric authentication not available: \(error.localizedDescription)")
                handleLAError(error)
            }
        }
    }
    
    /// Authenticates the user using biometrics
    /// - Parameter reason: The reason for authentication shown to the user
    /// - Returns: True if authentication succeeded
    @MainActor
    func authenticate(reason: String? = nil) async -> Bool {
        // Check if biometric auth is enabled in settings
        guard isBiometricEnabled() else {
            print("⚠️ Biometric authentication is disabled in settings")
            return false
        }
        
        // Check if we recently authenticated
        if isRecentlyAuthenticated() {
            print("✅ Using recent biometric authentication")
            isAuthenticated = true
            return true
        }
        
        // Create new context for each authentication
        let context = LAContext()
        context.localizedCancelTitle = "Enter Password"
        context.localizedFallbackTitle = "Use Password"
        
        // Set timeout for authentication
        context.touchIDAuthenticationAllowableReuseDuration = 10
        
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            print("❌ Cannot evaluate biometric policy: \(error?.localizedDescription ?? "Unknown error")")
            handleLAError(error)
            return false
        }
        
        let authReason = reason ?? defaultAuthReason
        
        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: authReason
            )
            
            if success {
                print("✅ Biometric authentication successful")
                await MainActor.run {
                    self.isAuthenticated = true
                    self.error = nil
                }
                saveAuthenticationTime()
                return true
            } else {
                print("❌ Biometric authentication failed")
                await MainActor.run {
                    self.isAuthenticated = false
                    self.error = .authenticationFailed
                }
                return false
            }
        } catch let error as LAError {
            print("❌ Biometric authentication error: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
                self.handleLAError(error)
            }
            return false
        } catch {
            print("❌ Unexpected authentication error: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
                self.error = .unknown(error)
            }
            return false
        }
    }
    
    /// Authenticates with device passcode as fallback
    @MainActor
    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print("❌ Device authentication not available: \(error?.localizedDescription ?? "Unknown")")
            handleLAError(error)
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Enter passcode to access your account"
            )
            
            if success {
                print("✅ Passcode authentication successful")
                await MainActor.run {
                    self.isAuthenticated = true
                    self.error = nil
                }
                saveAuthenticationTime()
                return true
            }
            
            return false
        } catch {
            print("❌ Passcode authentication error: \(error)")
            await MainActor.run {
                self.isAuthenticated = false
                self.error = .unknown(error)
            }
            return false
        }
    }
    
    /// Enables or disables biometric authentication
    func setBiometricEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: biometricEnabledKey)
        
        if !enabled {
            // Clear authentication state
            isAuthenticated = false
            clearAuthenticationTime()
        }
        
        print("📱 Biometric authentication \(enabled ? "enabled" : "disabled")")
    }
    
    /// Checks if biometric authentication is enabled
    func isBiometricEnabled() -> Bool {
        // Default to enabled if available
        if !UserDefaults.standard.object(forKey: biometricEnabledKey).isNotNil {
            return isAvailable
        }
        return UserDefaults.standard.bool(forKey: biometricEnabledKey)
    }
    
    /// Resets authentication state
    func reset() {
        isAuthenticated = false
        error = nil
        clearAuthenticationTime()
    }
    
    // MARK: - Private Methods
    
    /// Handles LocalAuthentication errors
    private func handleLAError(_ error: Error?) {
        guard let error = error as? LAError else {
            self.error = nil
            return
        }
        
        switch error.code {
        case .authenticationFailed:
            self.error = .authenticationFailed
        case .userCancel:
            self.error = .userCancelled
        case .userFallback:
            self.error = .userFallback
        case .systemCancel:
            self.error = .systemCancelled
        case .passcodeNotSet:
            self.error = .passcodeNotSet
        case .biometryNotAvailable:
            self.error = .biometryNotAvailable
        case .biometryNotEnrolled:
            self.error = .biometryNotEnrolled
        case .biometryLockout:
            self.error = .biometryLockout
        default:
            self.error = .unknown(error)
        }
    }
    
    /// Saves the time of successful authentication
    private func saveAuthenticationTime() {
        // Temporarily disabled - needs KeychainKey update
        /*
        let timestamp = Date().timeIntervalSince1970
        try? keychainManager.saveString(
            "\(timestamp)",
            for: .lastBiometricAuth
        )
        */
    }
    
    /// Clears the authentication time
    private func clearAuthenticationTime() {
        // Temporarily disabled - needs KeychainKey update
        // try? keychainManager.delete(for: .lastBiometricAuth)
    }
    
    /// Checks if the user recently authenticated
    private func isRecentlyAuthenticated() -> Bool {
        // Temporarily disabled - needs KeychainKey update
        /*
        guard let timestampString = try? keychainManager.retrieveString(for: .lastBiometricAuth),
              let timestamp = Double(timestampString) else {
            return false
        }
        */
        return false
        
        // let elapsed = Date().timeIntervalSince1970 - timestamp
        // return elapsed < authValidityDuration
    }
    
    /// Default authentication reason based on biometric type
    private var defaultAuthReason: String {
        switch biometricType {
        case .faceID:
            return "Authenticate with Face ID to access your account"
        case .touchID:
            return "Authenticate with Touch ID to access your account"
        case .opticID:
            return "Authenticate with Optic ID to access your account"
        default:
            return "Authenticate to access your account"
        }
    }
    
    /// String representation of biometric type
    var biometricTypeString: String {
        switch biometricType {
        case .none:
            return "None"
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Icon name for biometric type
    var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.shield"
        }
    }
}

// MARK: - Biometric Error

enum BiometricError: LocalizedError, Identifiable {
    case authenticationFailed
    case userCancelled
    case userFallback
    case systemCancelled
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case unknown(Error)
    
    var id: String {
        switch self {
        case .authenticationFailed:
            return "authFailed"
        case .userCancelled:
            return "userCancelled"
        case .userFallback:
            return "userFallback"
        case .systemCancelled:
            return "systemCancelled"
        case .passcodeNotSet:
            return "passcodeNotSet"
        case .biometryNotAvailable:
            return "biometryNotAvailable"
        case .biometryNotEnrolled:
            return "biometryNotEnrolled"
        case .biometryLockout:
            return "biometryLockout"
        case .unknown:
            return "unknown"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled."
        case .userFallback:
            return "Please enter your password."
        case .systemCancelled:
            return "Authentication was cancelled by the system."
        case .passcodeNotSet:
            return "Device passcode is not set. Please set a passcode in Settings."
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .biometryLockout:
            return "Biometric authentication is locked. Please use your passcode."
        case .unknown(let error):
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Make sure your face or finger is properly positioned and try again."
        case .userFallback:
            return "You can use your password to sign in."
        case .passcodeNotSet:
            return "Go to Settings > Face ID & Passcode to set up a passcode."
        case .biometryNotEnrolled:
            return "Go to Settings > Face ID & Passcode to enroll your biometric data."
        case .biometryLockout:
            return "Enter your device passcode to unlock biometric authentication."
        default:
            return nil
        }
    }
}

// MARK: - Keychain Extension

extension KeychainKey {
    static let lastBiometricAuth = KeychainKey(rawValue: "com.jns.Omni.lastBiometricAuth")
}

// MARK: - Optional Extension

extension Optional {
    var isNotNil: Bool {
        return self != nil
    }
}