//
//  SecureStorageMigrator.swift
//  OmniAI
//
//  Migrates sensitive data from UserDefaults to Keychain
//

import Foundation

/// Manages migration of sensitive data from UserDefaults to secure Keychain storage
class SecureStorageMigrator {
    
    // MARK: - Properties
    
    static let shared = SecureStorageMigrator()
    private let keychainManager = KeychainManager.shared
    private let service = "com.jns.Omni"
    
    /// Keys that potentially contain sensitive data
    private let sensitiveKeys = [
        // Authentication related
        "userToken",
        "refreshToken",
        "authToken",
        "accessToken",
        "firebaseToken",
        "sessionToken",
        "apiKey",
        
        // User data
        "userEmail",
        "userId",
        "userPassword", // Should never be stored, but check anyway
        "userProfile",
        "currentUser",
        
        // Session data
        "sessionData",
        "sessionId",
        "sessionKey",
        
        // Other potentially sensitive data
        "encryptionKey",
        "privateKey",
        "secretKey",
        "credentials",
        
        // App specific
        "offlineMessages",
        "pendingMessages",
        "draftMessages",
        "recentSearches",
        "userPreferences"
    ]
    
    /// Keys that should be checked for sensitive content
    private let suspiciousPatterns = [
        "token",
        "key",
        "secret",
        "password",
        "credential",
        "auth",
        "api",
        "private",
        "session"
    ]
    
    private let migrationCompleteKey = "SecureStorageMigrationComplete"
    private let migrationDateKey = "SecureStorageMigrationDate"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Performs migration of sensitive data to secure storage
    /// - Returns: Number of items migrated
    @discardableResult
    func performMigration() -> Int {
        // Check if migration was already completed
        if isMigrationComplete() {
            print("✅ Secure storage migration already completed")
            return 0
        }
        
        print("🔄 Starting secure storage migration...")
        
        var migratedCount = 0
        let userDefaults = UserDefaults.standard
        
        // Migrate known sensitive keys
        for key in sensitiveKeys {
            if migrateKey(key, from: userDefaults) {
                migratedCount += 1
            }
        }
        
        // Check all UserDefaults keys for suspicious patterns
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            let lowercaseKey = key.lowercased()
            
            // Skip if already migrated
            if sensitiveKeys.contains(key) {
                continue
            }
            
            // Check for suspicious patterns
            let isSuspicious = suspiciousPatterns.contains { pattern in
                lowercaseKey.contains(pattern)
            }
            
            if isSuspicious {
                print("⚠️ Found suspicious key: \(key)")
                if migrateKey(key, from: userDefaults) {
                    migratedCount += 1
                }
            }
        }
        
        // Mark migration as complete
        markMigrationComplete()
        
        print("✅ Migration complete: \(migratedCount) items moved to secure storage")
        
        // Clean up sensitive data from UserDefaults
        cleanupUserDefaults()
        
        return migratedCount
    }
    
    /// Checks if migration has been completed
    func isMigrationComplete() -> Bool {
        return UserDefaults.standard.bool(forKey: migrationCompleteKey)
    }
    
    /// Gets the date when migration was completed
    func getMigrationDate() -> Date? {
        return UserDefaults.standard.object(forKey: migrationDateKey) as? Date
    }
    
    /// Clears all potentially sensitive data from UserDefaults
    func cleanupUserDefaults() {
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        var cleanedCount = 0
        
        for (key, _) in dictionary {
            let lowercaseKey = key.lowercased()
            
            // Check if key might contain sensitive data
            let shouldRemove = suspiciousPatterns.contains { pattern in
                lowercaseKey.contains(pattern)
            }
            
            if shouldRemove {
                userDefaults.removeObject(forKey: key)
                cleanedCount += 1
                print("🧹 Removed potentially sensitive key from UserDefaults: \(key)")
            }
        }
        
        userDefaults.synchronize()
        
        if cleanedCount > 0 {
            print("✅ Cleaned \(cleanedCount) potentially sensitive items from UserDefaults")
        }
    }
    
    /// Validates that sensitive data is not in UserDefaults
    func validateSecureStorage() -> Bool {
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        var foundSensitive = false
        
        for (key, value) in dictionary {
            let lowercaseKey = key.lowercased()
            
            // Check key names
            let keySuspicious = suspiciousPatterns.contains { pattern in
                lowercaseKey.contains(pattern)
            }
            
            if keySuspicious {
                print("⚠️ WARNING: Potentially sensitive key in UserDefaults: \(key)")
                foundSensitive = true
            }
            
            // Check string values for sensitive patterns
            if let stringValue = value as? String {
                if looksLikeToken(stringValue) || looksLikeKey(stringValue) {
                    print("⚠️ WARNING: Potentially sensitive value in UserDefaults for key: \(key)")
                    foundSensitive = true
                }
            }
        }
        
        return !foundSensitive
    }
    
    // MARK: - Private Methods
    
    /// Migrates a specific key from UserDefaults to Keychain
    private func migrateKey(_ key: String, from userDefaults: UserDefaults) -> Bool {
        guard let value = userDefaults.object(forKey: key) else {
            return false
        }
        
        do {
            // Convert value to Data
            let data: Data
            
            if let stringValue = value as? String {
                data = stringValue.data(using: .utf8) ?? Data()
            } else if let dataValue = value as? Data {
                data = dataValue
            } else {
                // Try to serialize other types
                data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
            }
            
            // Create a namespaced key for Keychain
            let keychainKey = "migrated_\(key)"
            
            // Save to Keychain
            let success = keychainManager.saveData(data, forKey: keychainKey)
            
            if success {
                // Remove from UserDefaults
                userDefaults.removeObject(forKey: key)
                print("✅ Migrated '\(key)' to secure storage")
                return true
            } else {
                print("❌ Failed to migrate '\(key)' to Keychain")
                return false
            }
        } catch {
            print("❌ Error migrating '\(key)': \(error)")
            return false
        }
    }
    
    /// Marks the migration as complete
    private func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: migrationCompleteKey)
        UserDefaults.standard.set(Date(), forKey: migrationDateKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Checks if a string looks like a token
    private func looksLikeToken(_ string: String) -> Bool {
        // Tokens are typically long alphanumeric strings
        let tokenPattern = "^[A-Za-z0-9+/]{20,}={0,2}$|^[A-Za-z0-9_-]{20,}$"
        let regex = try? NSRegularExpression(pattern: tokenPattern)
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex?.firstMatch(in: string, options: [], range: range) != nil
    }
    
    /// Checks if a string looks like an API key
    private func looksLikeKey(_ string: String) -> Bool {
        // API keys often have specific patterns
        let keyPatterns = [
            "^sk_[a-zA-Z0-9]{24,}$", // Stripe-like
            "^pk_[a-zA-Z0-9]{24,}$",
            "^[A-Z0-9]{32,}$", // Generic uppercase
            "^[a-f0-9]{32,}$", // Hex format
        ]
        
        for pattern in keyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: string.utf16.count)
                if regex.firstMatch(in: string, options: [], range: range) != nil {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - KeychainManager Extension

extension KeychainManager {
    /// Saves data with a custom key (not from KeychainKey enum)
    func saveData(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.jns.Omni",
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves data with a custom key
    func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.jns.Omni",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        
        return nil
    }
}