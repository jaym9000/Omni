import Foundation
import CryptoKit
import Security

/// Manages client-side encryption for sensitive data
final class EncryptionManager {
    static let shared = EncryptionManager()
    
    private let keychainService = "com.jns.Omni.encryption"
    private let symmetricKeyAccount = "userSymmetricKey"
    
    private init() {}
    
    // MARK: - Key Management
    
    /// Generate or retrieve the user's encryption key
    func getUserKey() -> SymmetricKey? {
        // Try to retrieve existing key from Keychain
        if let existingKey = retrieveKeyFromKeychain() {
            return existingKey
        }
        
        // Generate new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        if saveKeyToKeychain(newKey) {
            return newKey
        }
        
        return nil
    }
    
    /// Save encryption key to Keychain
    private func saveKeyToKeychain(_ key: SymmetricKey) -> Bool {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: symmetricKeyAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing key
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve encryption key from Keychain
    private func retrieveKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: symmetricKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Encryption/Decryption
    
    /// Encrypt a string message
    func encryptMessage(_ plaintext: String) -> EncryptedMessage? {
        guard let key = getUserKey(),
              let data = plaintext.data(using: .utf8) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            // Combine nonce + ciphertext + tag for storage
            guard let combined = sealedBox.combined else {
                return nil
            }
            
            return EncryptedMessage(
                encryptedData: combined.base64EncodedString(),
                isEncrypted: true
            )
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    /// Decrypt an encrypted message
    func decryptMessage(_ encryptedMessage: EncryptedMessage) -> String? {
        guard encryptedMessage.isEncrypted,
              let key = getUserKey(),
              let combined = Data(base64Encoded: encryptedMessage.encryptedData) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combined)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    /// Delete user's encryption key (for data deletion)
    func deleteUserKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: symmetricKeyAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Audit Logging
    
    /// Log administrative access (for compliance)
    func logAdministrativeAccess(action: String, userId: String?) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = """
        [AUDIT] \(timestamp)
        Action: \(action)
        User: \(userId ?? "anonymous")
        Device: \(UIDevice.current.identifierForVendor?.uuidString ?? "unknown")
        """
        
        // In production, send this to a secure audit log service
        #if DEBUG
        print(logEntry)
        #endif
    }
}

// MARK: - Encrypted Message Model

struct EncryptedMessage: Codable {
    let encryptedData: String
    let isEncrypted: Bool
    
    // Metadata that remains unencrypted for functionality
    var metadata: MessageMetadata?
}

struct MessageMetadata: Codable {
    let timestamp: Date
    let messageLength: Int
    let hasAttachment: Bool
    
    init(from plaintext: String) {
        self.timestamp = Date()
        self.messageLength = plaintext.count
        self.hasAttachment = false
    }
}