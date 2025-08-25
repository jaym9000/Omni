//
//  CertificatePinner.swift
//  OmniAI
//
//  Certificate Pinning for Enhanced Network Security
//

import Foundation
import CryptoKit

/// Manages certificate pinning for secure network connections
class CertificatePinner: NSObject {
    
    // MARK: - Properties
    
    /// SHA256 hashes of pinned certificates
    /// These should be the actual certificate hashes from your servers
    private let pinnedCertificates: Set<String> = [
        // Firebase/Google certificates (you'll need to update these with actual hashes)
        "sha256/GTS1C3", // Google Trust Services
        "sha256/GTS1O1", // Google Trust Services
        // Add your actual certificate hashes here
        // To get the hash: echo | openssl s_client -connect YOUR_DOMAIN:443 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    ]
    
    /// Backup pins for certificate rotation
    private let backupPins: Set<String> = [
        // Add backup certificate hashes here for rotation
    ]
    
    /// Whether to allow self-signed certificates in DEBUG mode
    private let allowSelfSignedInDebug = true
    
    // MARK: - Singleton
    
    static let shared = CertificatePinner()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Validates a certificate challenge
    /// - Parameter challenge: The authentication challenge from URLSession
    /// - Returns: Tuple with disposition and optional credential
    func validate(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            print("⚠️ Certificate pinning: Invalid authentication method")
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Get the host being connected to
        let host = challenge.protectionSpace.host
        
        // Skip pinning for certain hosts in development
        #if DEBUG
        if shouldSkipPinning(for: host) {
            print("📌 Skipping certificate pinning for host: \(host) (DEBUG mode)")
            let credential = URLCredential(trust: serverTrust)
            return (.useCredential, credential)
        }
        #endif
        
        // Perform certificate validation
        var secresult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secresult)
        
        if status != errSecSuccess {
            print("❌ Certificate validation failed: SecTrustEvaluate error")
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Check if we should pin this host
        if shouldPinCertificate(for: host) {
            // Extract and validate certificate
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
                print("❌ Certificate pinning: Unable to extract certificate")
                return (.cancelAuthenticationChallenge, nil)
            }
            
            // Get public key from certificate
            let certData = SecCertificateCopyData(certificate) as Data
            let certHash = SHA256.hash(data: certData)
            let hashString = "sha256/" + Data(certHash).base64EncodedString()
            
            // Check if certificate is pinned
            if pinnedCertificates.contains(hashString) || backupPins.contains(hashString) {
                print("✅ Certificate pinning successful for: \(host)")
                let credential = URLCredential(trust: serverTrust)
                return (.useCredential, credential)
            } else {
                // Log the hash for debugging (remove in production)
                #if DEBUG
                print("⚠️ Certificate hash not pinned: \(hashString)")
                print("   Host: \(host)")
                
                if allowSelfSignedInDebug {
                    print("   Allowing connection in DEBUG mode")
                    let credential = URLCredential(trust: serverTrust)
                    return (.useCredential, credential)
                }
                #endif
                
                print("❌ Certificate pinning failed for: \(host)")
                return (.cancelAuthenticationChallenge, nil)
            }
        }
        
        // For non-pinned hosts, use default validation
        let credential = URLCredential(trust: serverTrust)
        return (.useCredential, credential)
    }
    
    // MARK: - Private Methods
    
    /// Determines if certificate pinning should be applied to a host
    private func shouldPinCertificate(for host: String) -> Bool {
        // Pin certificates for these domains
        let pinnedDomains = [
            "firebaseapp.com",
            "googleapis.com",
            "firebaseio.com",
            "firebase.google.com",
            "cloudfunctions.net",
            "run.app", // Cloud Run domains
        ]
        
        return pinnedDomains.contains { host.contains($0) }
    }
    
    /// Determines if pinning should be skipped (development only)
    private func shouldSkipPinning(for host: String) -> Bool {
        #if DEBUG
        // Skip pinning for localhost and development servers
        let skipHosts = [
            "localhost",
            "127.0.0.1",
            "0.0.0.0",
            "10.0.2.2", // Android emulator
        ]
        
        return skipHosts.contains { host.contains($0) }
        #else
        return false
        #endif
    }
    
    /// Updates pinned certificates (for certificate rotation)
    func updatePinnedCertificates(_ newHashes: Set<String>) {
        // This would be called when you need to update certificates
        // In production, you might fetch these from a secure configuration endpoint
        print("📌 Updating pinned certificates")
        // Implementation depends on your certificate rotation strategy
    }
    
    /// Extracts the public key from a certificate
    private func publicKey(from certificate: SecCertificate) -> SecKey? {
        var publicKey: SecKey?
        
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        if let trust = trust, trustCreationStatus == errSecSuccess {
            publicKey = SecTrustCopyKey(trust)
        }
        
        return publicKey
    }
    
    /// Gets SHA256 hash of a public key
    private func sha256Hash(of publicKey: SecKey) -> String? {
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }
        
        let hash = SHA256.hash(data: publicKeyData)
        return Data(hash).base64EncodedString()
    }
}

// MARK: - URLSession Extension

extension URLSession {
    /// Creates a URLSession with certificate pinning enabled
    static func createPinnedSession(delegate: URLSessionDelegate? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(
            configuration: configuration,
            delegate: delegate ?? CertificatePinningDelegate.shared,
            delegateQueue: nil
        )
        
        return session
    }
}

// MARK: - Certificate Pinning Delegate

class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    static let shared = CertificatePinningDelegate()
    
    private override init() {
        super.init()
    }
    
    func urlSession(_ session: URLSession,
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let (disposition, credential) = CertificatePinner.shared.validate(challenge: challenge)
        completionHandler(disposition, credential)
    }
}