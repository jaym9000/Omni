//
//  MessageEncryption.swift
//  OmniAI
//
//  End-to-end encryption for messages using CryptoKit
//

import Foundation
import CryptoKit
import CommonCrypto

final class MessageEncryption {
    
    // MARK: - Properties
    
    static let shared = MessageEncryption()
    private let keychainManager = KeychainManager.shared
    private let auditLogger = AuditLogger.shared
    
    private let symmetricKeyTag = "com.omniai.message.key"
    private let privateKeyTag = "com.omniai.private.key"
    private let publicKeyTag = "com.omniai.public.key"
    
    private init() {
        initializeEncryptionKeys()
    }
    
    // MARK: - Key Management
    
    private func initializeEncryptionKeys() {
        // Initialize symmetric key for message encryption
        if keychainManager.get(symmetricKeyTag) == nil {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            keychainManager.save(keyData, forKey: symmetricKeyTag)
            
            auditLogger.logEvent(
                type: .securityEvent,
                details: ["event": "encryption_key_generated", "type": "symmetric"]
            )
        }
        
        // Initialize key pair for key exchange
        if keychainManager.get(privateKeyTag) == nil {
            generateKeyPair()
        }
    }
    
    private func generateKeyPair() {
        let privateKey = P256.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Store private key
        let privateKeyData = privateKey.rawRepresentation
        keychainManager.save(privateKeyData, forKey: privateKeyTag)
        
        // Store public key
        let publicKeyData = publicKey.rawRepresentation
        keychainManager.save(publicKeyData, forKey: publicKeyTag)
        
        auditLogger.logEvent(
            type: .securityEvent,
            details: ["event": "keypair_generated", "algorithm": "P256"]
        )
    }
    
    // MARK: - Message Encryption
    
    /// Encrypt a message for secure transmission
    func encryptMessage(_ message: String, for recipientPublicKey: Data? = nil) throws -> EncryptedMessage {
        guard let messageData = message.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        // Get or generate symmetric key
        guard let keyData = keychainManager.get(symmetricKeyTag) else {
            throw EncryptionError.keyNotFound
        }
        
        let symmetricKey = SymmetricKey(data: keyData)
        
        // Generate nonce
        let nonce = AES.GCM.Nonce()
        
        // Encrypt message
        let sealedBox = try AES.GCM.seal(messageData, using: symmetricKey, nonce: nonce)
        
        // Combine nonce, ciphertext, and tag
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        // Create metadata
        let metadata = MessageMetadata(
            timestamp: Date(),
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            version: 1
        )
        
        // If recipient public key is provided, encrypt the symmetric key
        var encryptedKey: Data?
        if let recipientKey = recipientPublicKey {
            encryptedKey = try encryptSymmetricKey(keyData, for: recipientKey)
        }
        
        let encryptedMessage = EncryptedMessage(
            ciphertext: combined,
            encryptedKey: encryptedKey,
            metadata: metadata
        )
        
        // Log encryption event (without sensitive data)
        auditLogger.logEvent(
            type: .dataAccess,
            details: [
                "event": "message_encrypted",
                "size": messageData.count,
                "algorithm": "AES-GCM-256"
            ]
        )
        
        return encryptedMessage
    }
    
    /// Decrypt a message
    func decryptMessage(_ encryptedMessage: EncryptedMessage) throws -> String {
        // Get symmetric key
        var symmetricKeyData: Data
        
        if let encryptedKey = encryptedMessage.encryptedKey {
            // Decrypt the symmetric key using our private key
            symmetricKeyData = try decryptSymmetricKey(encryptedKey)
        } else {
            // Use stored symmetric key
            guard let keyData = keychainManager.get(symmetricKeyTag) else {
                throw EncryptionError.keyNotFound
            }
            symmetricKeyData = keyData
        }
        
        let symmetricKey = SymmetricKey(data: symmetricKeyData)
        
        // Decrypt message
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedMessage.ciphertext)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        guard let message = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        // Log decryption event
        auditLogger.logEvent(
            type: .dataAccess,
            details: [
                "event": "message_decrypted",
                "metadata": encryptedMessage.metadata.deviceId
            ]
        )
        
        return message
    }
    
    // MARK: - Key Exchange
    
    /// Get our public key for sharing
    func getPublicKey() -> Data? {
        return keychainManager.get(publicKeyTag)
    }
    
    /// Establish shared secret with another party
    func establishSharedSecret(with peerPublicKeyData: Data) throws -> Data {
        guard let privateKeyData = keychainManager.get(privateKeyTag) else {
            throw EncryptionError.keyNotFound
        }
        
        let privateKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
        let peerPublicKey = try P256.KeyAgreement.PublicKey(rawRepresentation: peerPublicKeyData)
        
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        
        // Derive symmetric key from shared secret
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "OmniAI-E2E".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        return symmetricKey.withUnsafeBytes { Data($0) }
    }
    
    // MARK: - Helper Methods
    
    private func encryptSymmetricKey(_ keyData: Data, for recipientPublicKeyData: Data) throws -> Data {
        let recipientKey = try P256.KeyAgreement.PublicKey(rawRepresentation: recipientPublicKeyData)
        
        guard let privateKeyData = keychainManager.get(privateKeyTag) else {
            throw EncryptionError.keyNotFound
        }
        
        let privateKey = try P256.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: recipientKey)
        
        // Derive encryption key
        let encryptionKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "KeyEncryption".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        // Encrypt the symmetric key
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(keyData, using: encryptionKey, nonce: nonce)
        
        return sealedBox.combined ?? Data()
    }
    
    private func decryptSymmetricKey(_ encryptedKeyData: Data) throws -> Data {
        guard let privateKeyData = keychainManager.get(privateKeyTag) else {
            throw EncryptionError.keyNotFound
        }
        
        // This would need the sender's public key in a real implementation
        // For now, using a simplified approach
        throw EncryptionError.notImplemented
    }
    
    // MARK: - Message Integrity
    
    /// Generate HMAC for message integrity
    func generateHMAC(for message: String) -> Data {
        guard let messageData = message.data(using: .utf8),
              let keyData = keychainManager.get(symmetricKeyTag) else {
            return Data()
        }
        
        let key = SymmetricKey(data: keyData)
        let hmac = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
        
        return Data(hmac)
    }
    
    /// Verify HMAC for message integrity
    func verifyHMAC(_ hmac: Data, for message: String) -> Bool {
        let computedHMAC = generateHMAC(for: message)
        return hmac == computedHMAC
    }
    
    // MARK: - Secure Deletion
    
    /// Securely delete encryption keys
    func deleteEncryptionKeys() {
        keychainManager.delete(symmetricKeyTag)
        keychainManager.delete(privateKeyTag)
        keychainManager.delete(publicKeyTag)
        
        auditLogger.logEvent(
            type: .securityEvent,
            details: ["event": "encryption_keys_deleted"]
        )
    }
}

// MARK: - Supporting Types

struct EncryptedMessage: Codable {
    let ciphertext: Data
    let encryptedKey: Data?
    let metadata: MessageMetadata
}

struct MessageMetadata: Codable {
    let timestamp: Date
    let deviceId: String
    let version: Int
}

enum EncryptionError: LocalizedError {
    case invalidInput
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input data for encryption"
        case .keyNotFound:
            return "Encryption key not found"
        case .encryptionFailed:
            return "Failed to encrypt message"
        case .decryptionFailed:
            return "Failed to decrypt message"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

// MARK: - ChatService Integration

extension MessageEncryption {
    
    /// Prepare message for secure transmission to Firebase
    func prepareSecureMessage(_ content: String, sessionId: String) -> [String: Any] {
        do {
            let encrypted = try encryptMessage(content)
            let hmac = generateHMAC(for: content)
            
            return [
                "encryptedContent": encrypted.ciphertext.base64EncodedString(),
                "hmac": hmac.base64EncodedString(),
                "sessionId": sessionId,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "encrypted": true
            ]
        } catch {
            // Fallback to unencrypted if encryption fails
            auditLogger.logEvent(
                type: .error,
                details: [
                    "event": "encryption_failed",
                    "error": error.localizedDescription
                ]
            )
            
            return [
                "content": content,
                "sessionId": sessionId,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "encrypted": false
            ]
        }
    }
    
    /// Process secure response from Firebase
    func processSecureResponse(_ response: [String: Any]) -> String? {
        if let encrypted = response["encrypted"] as? Bool, encrypted,
           let ciphertextString = response["encryptedContent"] as? String,
           let ciphertext = Data(base64Encoded: ciphertextString) {
            
            // Verify HMAC if present
            if let hmacString = response["hmac"] as? String,
               let hmac = Data(base64Encoded: hmacString) {
                // Create encrypted message object
                let encryptedMessage = EncryptedMessage(
                    ciphertext: ciphertext,
                    encryptedKey: nil,
                    metadata: MessageMetadata(
                        timestamp: Date(),
                        deviceId: "server",
                        version: 1
                    )
                )
                
                do {
                    let decrypted = try decryptMessage(encryptedMessage)
                    
                    // Verify integrity
                    if verifyHMAC(hmac, for: decrypted) {
                        return decrypted
                    } else {
                        auditLogger.logEvent(
                            type: .securityEvent,
                            details: ["event": "hmac_verification_failed"]
                        )
                    }
                } catch {
                    auditLogger.logEvent(
                        type: .error,
                        details: [
                            "event": "decryption_failed",
                            "error": error.localizedDescription
                        ]
                    )
                }
            }
        }
        
        // Fallback to unencrypted content
        return response["content"] as? String
    }
}