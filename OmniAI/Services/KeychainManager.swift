import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case unexpectedData
    case unhandledError(status: OSStatus)
    case encodingError
    case decodingError
}

enum KeychainKey: String, CaseIterable {
    case userProfile = "com.jns.Omni.userProfile"
    case authToken = "com.jns.Omni.authToken"
    case refreshToken = "com.jns.Omni.refreshToken"
    case firebaseToken = "com.jns.Omni.firebaseToken"
    case loginAttempts = "com.jns.Omni.loginAttempts"
    case lastFailedLogin = "com.jns.Omni.lastFailedLogin"
    case accountLockTime = "com.jns.Omni.accountLockTime"
    // case lastBiometricAuth = "com.jns.Omni.lastBiometricAuth" // Temporarily disabled
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.jns.Omni"
    private let accessGroup: String? = nil // Add if using app groups
    
    private init() {}
    
    // MARK: - Public Methods
    
    func save<T: Codable>(_ item: T, for key: KeychainKey) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(item) else {
            throw KeychainError.encodingError
        }
        
        try save(data, for: key.rawValue)
    }
    
    func retrieve<T: Codable>(_ type: T.Type, for key: KeychainKey) throws -> T? {
        guard let data = try retrieve(for: key.rawValue) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let item = try? decoder.decode(type, from: data) else {
            throw KeychainError.decodingError
        }
        
        return item
    }
    
    func saveString(_ string: String, for key: KeychainKey) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        try save(data, for: key.rawValue)
    }
    
    func retrieveString(for key: KeychainKey) throws -> String? {
        guard let data = try retrieve(for: key.rawValue) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(for key: KeychainKey) throws {
        try delete(for: key.rawValue)
    }
    
    func deleteAll() throws {
        for key in KeychainKey.allCases {
            try? delete(for: key)
        }
    }
    
    // MARK: - Token Management
    
    func saveAuthToken(_ token: String) throws {
        try saveString(token, for: .authToken)
    }
    
    func retrieveAuthToken() throws -> String? {
        return try retrieveString(for: .authToken)
    }
    
    func saveRefreshToken(_ token: String) throws {
        try saveString(token, for: .refreshToken)
    }
    
    func retrieveRefreshToken() throws -> String? {
        return try retrieveString(for: .refreshToken)
    }
    
    func clearTokens() throws {
        try? delete(for: .authToken)
        try? delete(for: .refreshToken)
        try? delete(for: .firebaseToken)
    }
    
    // Generic save and get for Data
    func save(_ data: Data, forKey key: KeychainKey) throws {
        try save(data, for: key.rawValue)
    }
    
    func get(forKey key: KeychainKey) -> Data? {
        return try? retrieve(for: key.rawValue)
    }
    
    // Overloaded delete method
    func delete(_ key: KeychainKey) throws {
        try delete(for: key.rawValue)
    }
    
    // MARK: - Rate Limiting Support
    
    func incrementLoginAttempts() throws -> Int {
        let currentAttempts = (try? retrieveString(for: .loginAttempts)).flatMap(Int.init) ?? 0
        let newAttempts = currentAttempts + 1
        try saveString("\(newAttempts)", for: .loginAttempts)
        
        // Save timestamp of this failed attempt
        let now = Date().timeIntervalSince1970
        try saveString("\(now)", for: .lastFailedLogin)
        
        return newAttempts
    }
    
    func resetLoginAttempts() throws {
        try? delete(for: .loginAttempts)
        try? delete(for: .lastFailedLogin)
        try? delete(for: .accountLockTime)
    }
    
    func getLoginAttempts() throws -> Int {
        return (try? retrieveString(for: .loginAttempts)).flatMap(Int.init) ?? 0
    }
    
    func lockAccount(until date: Date) throws {
        let timestamp = date.timeIntervalSince1970
        try saveString("\(timestamp)", for: .accountLockTime)
    }
    
    func getAccountLockTime() throws -> Date? {
        guard let timestampString = try? retrieveString(for: .accountLockTime),
              let timestamp = Double(timestampString) else {
            return nil
        }
        
        let lockDate = Date(timeIntervalSince1970: timestamp)
        
        // If lock time has passed, clear it
        if lockDate < Date() {
            try? delete(for: .accountLockTime)
            return nil
        }
        
        return lockDate
    }
    
    // MARK: - Private Methods
    
    private func save(_ data: Data, for key: String) throws {
        var query = createQuery(for: key)
        query[kSecValueData as String] = data
        
        // Try to update first
        var attributesToUpdate = [String: Any]()
        attributesToUpdate[kSecValueData as String] = data
        
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            // Item doesn't exist, add it
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            
            if addStatus != errSecSuccess {
                throw KeychainError.unhandledError(status: addStatus)
            }
        default:
            throw KeychainError.unhandledError(status: updateStatus)
        }
    }
    
    private func retrieve(for key: String) throws -> Data? {
        var query = createQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func delete(for key: String) throws {
        let query = createQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func createQuery(for key: String) -> [String: Any] {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        query[kSecAttrAccount as String] = key
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateFromUserDefaults() {
        // Migrate user profile if exists
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                try save(userData, for: KeychainKey.userProfile.rawValue)
                // Remove from UserDefaults after successful migration
                UserDefaults.standard.removeObject(forKey: "currentUser")
                print("✅ Successfully migrated user profile to Keychain")
            } catch {
                print("❌ Failed to migrate user profile to Keychain: \(error)")
            }
        }
    }
}