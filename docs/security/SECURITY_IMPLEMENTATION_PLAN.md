# Security Implementation Plan - Omni AI Application

## Overview
This plan addresses the critical security vulnerabilities identified in the security audit, organized by priority and implementation phases.

---

## Phase 1: Critical Issues (Week 1)
*Must be completed before any production deployment*

### 1.1 Firebase App Check Implementation

#### Files to Modify:
- `OmniAI/AppDelegate.swift`
- `functions/src/index.ts`
- `firebase.json`

#### Implementation Steps:

**Step 1: Enable App Check in Firebase Console**
```bash
# Navigate to Firebase Console > App Check
# Enable for iOS with DeviceCheck provider
```

**Step 2: iOS App Configuration**
```swift
// AppDelegate.swift
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Add App Check before Firebase configuration
        let providerFactory = AppCheckDebugProviderFactory()  // Debug mode
        // For production: let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        return true
    }
}
```

**Step 3: Cloud Functions Enforcement**
```typescript
// functions/src/index.ts
import {getAppCheck} from "firebase-admin/app-check";

export const generateAIResponse = onCall(
  {
    secrets: [openaiApiKey],
    enforceAppCheck: true,  // Add this line
    consumeAppCheckToken: true,  // Add this line
  },
  async (request) => {
    // Verify App Check token
    const appCheckToken = request.rawRequest.header("X-Firebase-AppCheck");
    if (!appCheckToken) {
      throw new HttpsError("unauthenticated", "App Check verification failed");
    }
    
    try {
      await getAppCheck().verifyToken(appCheckToken);
    } catch (error) {
      throw new HttpsError("unauthenticated", "Invalid App Check token");
    }
    
    // Continue with existing logic...
  }
);
```

---

### 1.2 Input Sanitization & Validation

#### Files to Create:
- `functions/src/security/inputValidator.ts`
- `functions/src/security/contentModerator.ts`

#### Implementation:

**Step 1: Create Input Validator**
```typescript
// functions/src/security/inputValidator.ts
export class InputValidator {
  private static readonly INJECTION_PATTERNS = [
    /\[system\]/gi,
    /\[assistant\]/gi,
    /ignore previous instructions/gi,
    /forget everything/gi,
    /new instructions:/gi,
    /act as/gi,
    /pretend to be/gi,
    /you are now/gi,
  ];
  
  private static readonly MAX_MESSAGE_LENGTH = 1000;
  private static readonly MIN_MESSAGE_LENGTH = 1;
  
  static sanitizeMessage(message: string): string {
    if (!message || typeof message !== 'string') {
      throw new Error('Invalid message format');
    }
    
    // Remove potential injection patterns
    let sanitized = message;
    for (const pattern of this.INJECTION_PATTERNS) {
      sanitized = sanitized.replace(pattern, '[FILTERED]');
    }
    
    // Trim and limit length
    sanitized = sanitized.trim();
    if (sanitized.length > this.MAX_MESSAGE_LENGTH) {
      sanitized = sanitized.substring(0, this.MAX_MESSAGE_LENGTH);
    }
    
    if (sanitized.length < this.MIN_MESSAGE_LENGTH) {
      throw new Error('Message too short');
    }
    
    // Remove control characters
    sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, '');
    
    return sanitized;
  }
  
  static validateSessionId(sessionId: string): boolean {
    const sessionPattern = /^[a-zA-Z0-9-]{20,50}$/;
    return sessionPattern.test(sessionId);
  }
  
  static validateMood(mood: string | undefined): string {
    const validMoods = ['balanced', 'creative', 'focused', 'empathetic'];
    if (!mood || !validMoods.includes(mood)) {
      return 'balanced';
    }
    return mood;
  }
}
```

**Step 2: Create Content Moderator**
```typescript
// functions/src/security/contentModerator.ts
import {OpenAI} from "openai";

export class ContentModerator {
  private openai: OpenAI;
  
  constructor(apiKey: string) {
    this.openai = new OpenAI({apiKey});
  }
  
  async isContentSafe(message: string): Promise<{safe: boolean; reason?: string}> {
    try {
      const moderation = await this.openai.moderations.create({
        input: message,
      });
      
      const result = moderation.results[0];
      if (result.flagged) {
        const flaggedCategories = Object.entries(result.categories)
          .filter(([_, flagged]) => flagged)
          .map(([category]) => category);
        
        return {
          safe: false,
          reason: `Content violates policies: ${flaggedCategories.join(', ')}`
        };
      }
      
      return {safe: true};
    } catch (error) {
      console.error('Moderation error:', error);
      // Fail open in case of API error, but log for review
      return {safe: true};
    }
  }
}
```

**Step 3: Update Cloud Function**
```typescript
// functions/src/index.ts
import {InputValidator} from "./security/inputValidator";
import {ContentModerator} from "./security/contentModerator";

export const generateAIResponse = onCall(
  {secrets: [openaiApiKey], enforceAppCheck: true},
  async (request) => {
    const {message, sessionId, mood} = request.body;
    
    // Validate session ID
    if (!InputValidator.validateSessionId(sessionId)) {
      throw new HttpsError("invalid-argument", "Invalid session ID");
    }
    
    // Sanitize and validate message
    let sanitizedMessage: string;
    try {
      sanitizedMessage = InputValidator.sanitizeMessage(message);
    } catch (error) {
      throw new HttpsError("invalid-argument", error.message);
    }
    
    // Validate mood
    const validatedMood = InputValidator.validateMood(mood);
    
    // Content moderation
    const moderator = new ContentModerator(openaiApiKey.value());
    const moderationResult = await moderator.isContentSafe(sanitizedMessage);
    
    if (!moderationResult.safe) {
      throw new HttpsError(
        "invalid-argument", 
        moderationResult.reason || "Content policy violation"
      );
    }
    
    // Continue with AI processing using sanitizedMessage...
  }
);
```

---

### 1.3 API Key Security Enhancement

#### Implementation Steps:

**Step 1: Configure API Key Restrictions (Google Cloud Console)**
```bash
# Script to configure API restrictions
#!/bin/bash
# save as: configure_api_restrictions.sh

PROJECT_ID="omni-ai-project"
API_KEY="AIzaSyBlw1nOxqwPGk6yVWWiZdGy3dZc6Mo9DAo"

# Restrict API key to specific APIs
gcloud services api-keys update $API_KEY \
  --project=$PROJECT_ID \
  --allowed-apis=firebase.googleapis.com,firebaseapp.googleapis.com

# Restrict to iOS app bundle ID
gcloud services api-keys update $API_KEY \
  --project=$PROJECT_ID \
  --allowed-bundle-ids=com.jns.Omni

# Set allowed IPs (for server-side usage)
gcloud services api-keys update $API_KEY \
  --project=$PROJECT_ID \
  --allowed-ips=YOUR_SERVER_IP
```

**Step 2: Implement Rate Limiting for OpenAI**
```typescript
// functions/src/security/rateLimiter.ts
import * as admin from "firebase-admin";

export class OpenAIRateLimiter {
  private static readonly LIMITS = {
    guest: {
      requestsPerDay: 3,
      tokensPerDay: 1000,
      requestsPerMinute: 1,
    },
    free: {
      requestsPerDay: 50,
      tokensPerDay: 10000,
      requestsPerMinute: 3,
    },
    premium: {
      requestsPerDay: 1000,
      tokensPerDay: 100000,
      requestsPerMinute: 10,
    },
  };
  
  static async checkAndUpdateLimits(
    userId: string,
    userType: 'guest' | 'free' | 'premium',
    tokens: number
  ): Promise<{allowed: boolean; reason?: string}> {
    const db = admin.firestore();
    const limitsRef = db.collection('rateLimits').doc(userId);
    
    return await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(limitsRef);
      const now = Date.now();
      const today = new Date().toDateString();
      
      let data = doc.exists ? doc.data() : {
        requestsToday: 0,
        tokensToday: 0,
        lastRequestTime: 0,
        dateKey: today,
        minuteRequests: [],
      };
      
      // Reset daily counters if new day
      if (data.dateKey !== today) {
        data = {
          requestsToday: 0,
          tokensToday: 0,
          lastRequestTime: now,
          dateKey: today,
          minuteRequests: [],
        };
      }
      
      // Check minute rate limit
      const oneMinuteAgo = now - 60000;
      data.minuteRequests = data.minuteRequests.filter(
        (time: number) => time > oneMinuteAgo
      );
      
      const limits = this.LIMITS[userType];
      
      if (data.minuteRequests.length >= limits.requestsPerMinute) {
        return {
          allowed: false,
          reason: 'Rate limit exceeded. Please wait a minute.',
        };
      }
      
      if (data.requestsToday >= limits.requestsPerDay) {
        return {
          allowed: false,
          reason: 'Daily request limit reached.',
        };
      }
      
      if (data.tokensToday + tokens > limits.tokensPerDay) {
        return {
          allowed: false,
          reason: 'Daily token limit reached.',
        };
      }
      
      // Update counters
      data.requestsToday += 1;
      data.tokensToday += tokens;
      data.lastRequestTime = now;
      data.minuteRequests.push(now);
      
      transaction.set(limitsRef, data);
      
      return {allowed: true};
    });
  }
}
```

---

## Phase 2: High Priority Issues (Week 2-3)

### 2.1 Certificate Pinning Implementation

#### Files to Create:
- `OmniAI/Security/CertificatePinner.swift`
- `OmniAI/Security/NetworkSecurityManager.swift`

#### Implementation:

**Step 1: Create Certificate Pinner**
```swift
// OmniAI/Security/CertificatePinner.swift
import Foundation
import CryptoKit

class CertificatePinner: NSObject {
    private let pinnedCertificates: Set<String>
    
    init() {
        // SHA256 hashes of your server certificates
        self.pinnedCertificates = [
            "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Production cert
            "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=", // Backup cert
        ]
    }
    
    func validate(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Validate certificate chain
        var secresult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secresult)
        
        if status != errSecSuccess {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Extract and validate certificate
        guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        let certData = SecCertificateCopyData(certificate) as Data
        let certHash = SHA256.hash(data: certData)
        let hashString = "sha256/" + Data(certHash).base64EncodedString()
        
        if pinnedCertificates.contains(hashString) {
            let credential = URLCredential(trust: serverTrust)
            return (.useCredential, credential)
        }
        
        // Log the failure for debugging
        print("Certificate pinning failed. Hash: \(hashString)")
        return (.cancelAuthenticationChallenge, nil)
    }
}
```

**Step 2: Create Network Security Manager**
```swift
// OmniAI/Security/NetworkSecurityManager.swift
import Foundation

class NetworkSecurityManager: NSObject {
    static let shared = NetworkSecurityManager()
    private let certificatePinner = CertificatePinner()
    private lazy var secureSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.httpShouldUsePipelining = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Add security headers
        configuration.httpAdditionalHeaders = [
            "X-Requested-With": "XMLHttpRequest",
            "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()
    
    func performSecureRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await secureSession.data(for: request)
    }
}

extension NetworkSecurityManager: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let (disposition, credential) = certificatePinner.validate(challenge: challenge)
        completionHandler(disposition, credential)
    }
}
```

**Step 3: Update ChatService to Use Secure Network**
```swift
// OmniAI/Services/ChatService.swift
// Replace URLSession.shared with NetworkSecurityManager

private func callCloudFunction(message: String, sessionId: String, mood: MoodSetting) async throws -> String {
    // ... existing code ...
    
    // Replace this line:
    // let (data, _) = try await URLSession.shared.data(for: request)
    
    // With:
    let (data, _) = try await NetworkSecurityManager.shared.performSecureRequest(request)
    
    // ... rest of the code ...
}
```

---

### 2.2 Biometric Authentication Implementation

#### Files to Create:
- `OmniAI/Security/BiometricAuthManager.swift`

#### Implementation:

```swift
// OmniAI/Security/BiometricAuthManager.swift
import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    
    private let context = LAContext()
    private let keychainManager = KeychainManager.shared
    
    init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func authenticate(reason: String = "Authenticate to access your account") async -> Bool {
        context.localizedCancelTitle = "Enter Password"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            if success {
                // Store authentication timestamp
                keychainManager.saveData(
                    Date().timeIntervalSince1970.description.data(using: .utf8)!,
                    forKey: "lastBiometricAuth"
                )
            }
            
            return success
        } catch let error as LAError {
            handleAuthenticationError(error)
            return false
        } catch {
            print("Unexpected authentication error: \(error)")
            return false
        }
    }
    
    private func handleAuthenticationError(_ error: LAError) {
        switch error.code {
        case .authenticationFailed:
            print("Authentication failed")
        case .userCancel:
            print("User cancelled authentication")
        case .userFallback:
            print("User chose password fallback")
        case .biometryNotAvailable:
            print("Biometry not available")
        case .biometryNotEnrolled:
            print("Biometry not enrolled")
        case .biometryLockout:
            print("Biometry locked out")
        default:
            print("Authentication error: \(error.localizedDescription)")
        }
    }
    
    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Enter passcode to access your account"
            )
            
            await MainActor.run {
                self.isAuthenticated = success
            }
            
            return success
        } catch {
            print("Passcode authentication error: \(error)")
            return false
        }
    }
}
```

---

### 2.3 Secure UserDefaults Migration

#### Files to Create:
- `OmniAI/Security/SecureStorageMigrator.swift`

#### Implementation:

```swift
// OmniAI/Security/SecureStorageMigrator.swift
import Foundation

class SecureStorageMigrator {
    static let shared = SecureStorageMigrator()
    private let keychainManager = KeychainManager.shared
    
    // Keys that contain sensitive data
    private let sensitiveKeys = [
        "userToken",
        "refreshToken",
        "userEmail",
        "userId",
        "sessionData",
        "offlineMessages",
        "encryptionKey"
    ]
    
    func migrateToSecureStorage() {
        let userDefaults = UserDefaults.standard
        var migrationCount = 0
        
        for key in sensitiveKeys {
            if let data = userDefaults.object(forKey: key) {
                // Convert to Data if needed
                let dataToStore: Data
                if let stringData = data as? String {
                    dataToStore = stringData.data(using: .utf8) ?? Data()
                } else if let actualData = data as? Data {
                    dataToStore = actualData
                } else {
                    dataToStore = try? JSONSerialization.data(withJSONObject: data, options: []) ?? Data()
                }
                
                // Save to Keychain
                if keychainManager.saveData(dataToStore, forKey: "migrated_\(key)") {
                    // Remove from UserDefaults
                    userDefaults.removeObject(forKey: key)
                    migrationCount += 1
                    print("Migrated \(key) to secure storage")
                }
            }
        }
        
        if migrationCount > 0 {
            userDefaults.set(Date(), forKey: "secureStorageMigrationDate")
            userDefaults.synchronize()
            print("Migration complete: \(migrationCount) items moved to secure storage")
        }
    }
    
    func clearSensitiveUserDefaults() {
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        
        for (key, _) in dictionary {
            // Check if key might contain sensitive data
            let lowercaseKey = key.lowercased()
            if lowercaseKey.contains("token") ||
               lowercaseKey.contains("password") ||
               lowercaseKey.contains("secret") ||
               lowercaseKey.contains("key") ||
               lowercaseKey.contains("auth") ||
               lowercaseKey.contains("user") {
                userDefaults.removeObject(forKey: key)
                print("Removed potentially sensitive key: \(key)")
            }
        }
        
        userDefaults.synchronize()
    }
}
```

---

### 2.4 Audit Logging System

#### Files to Create:
- `OmniAI/Security/AuditLogger.swift`
- `functions/src/security/auditLogger.ts`

#### Implementation:

**iOS Audit Logger:**
```swift
// OmniAI/Security/AuditLogger.swift
import Foundation
import FirebaseFirestore
import CryptoKit

enum AuditEventType: String {
    case authentication = "AUTH"
    case dataAccess = "DATA_ACCESS"
    case dataModification = "DATA_MODIFY"
    case securityEvent = "SECURITY"
    case error = "ERROR"
    case payment = "PAYMENT"
}

struct AuditEvent {
    let id: String = UUID().uuidString
    let timestamp: Date = Date()
    let type: AuditEventType
    let userId: String?
    let action: String
    let metadata: [String: Any]
    let deviceInfo: [String: String]
    let hash: String?
    
    init(type: AuditEventType, userId: String?, action: String, metadata: [String: Any] = [:]) {
        self.type = type
        self.userId = userId
        self.action = action
        self.metadata = metadata
        self.deviceInfo = AuditLogger.getDeviceInfo()
        self.hash = nil
    }
    
    func withHash() -> AuditEvent {
        let dataString = "\(id)\(timestamp)\(type.rawValue)\(userId ?? "")\(action)"
        let hash = SHA256.hash(data: dataString.data(using: .utf8)!)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        var event = self
        event.hash = hashString
        return event
    }
}

class AuditLogger {
    static let shared = AuditLogger()
    private let db = Firestore.firestore()
    private let localQueue = DispatchQueue(label: "audit.logger.queue")
    private var pendingEvents: [AuditEvent] = []
    
    func log(_ event: AuditEvent) {
        let hashedEvent = event.withHash()
        
        // Store locally first
        localQueue.async {
            self.pendingEvents.append(hashedEvent)
            self.flushIfNeeded()
        }
        
        // Send to server
        Task {
            await self.sendToServer(hashedEvent)
        }
    }
    
    private func sendToServer(_ event: AuditEvent) async {
        do {
            try await db.collection("auditLogs").document(event.id).setData([
                "timestamp": event.timestamp,
                "type": event.type.rawValue,
                "userId": event.userId ?? NSNull(),
                "action": event.action,
                "metadata": event.metadata,
                "deviceInfo": event.deviceInfo,
                "hash": event.hash ?? NSNull()
            ])
        } catch {
            print("Failed to send audit log: \(error)")
            // Keep in local queue for retry
        }
    }
    
    private func flushIfNeeded() {
        if pendingEvents.count > 100 {
            // Batch send to server
            let eventsToSend = pendingEvents
            pendingEvents.removeAll()
            
            Task {
                for event in eventsToSend {
                    await sendToServer(event)
                }
            }
        }
    }
    
    static func getDeviceInfo() -> [String: String] {
        return [
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ]
    }
}
```

---

## Phase 3: Medium Priority Issues (Week 4)

### 3.1 Enhanced Firebase Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isValidMessage() {
      return request.resource.data.keys().hasAll(['content', 'timestamp', 'role']) &&
             request.resource.data.content is string &&
             request.resource.data.content.size() > 0 &&
             request.resource.data.content.size() <= 1000 &&
             request.resource.data.timestamp is timestamp &&
             request.resource.data.role in ['user', 'assistant'];
    }
    
    function withinRateLimit() {
      return request.time < resource.data.lastWrite + duration.value(1, 's');
    }
    
    // Audit logs - read only for admins, write only from server
    match /auditLogs/{document} {
      allow read: if isAuthenticated() && 
                     request.auth.token.admin == true;
      allow write: if false; // Server-side only
    }
    
    // User profiles
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId) && 
                      request.resource.data.keys().hasAll(['email', 'createdAt']);
      allow update: if isOwner(userId) && 
                      request.resource.data.diff(resource.data).unchangedKeys().hasAll(['email', 'createdAt']);
      allow delete: if false; // Soft delete only
    }
    
    // Chat sessions
    match /users/{userId}/sessions/{sessionId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) && withinRateLimit();
      allow delete: if isOwner(userId);
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) && isValidMessage();
        allow update: if false; // Messages are immutable
        allow delete: if isOwner(userId);
      }
    }
    
    // Rate limiting documents
    match /rateLimits/{userId} {
      allow read: if isOwner(userId);
      allow write: if false; // Server-side only
    }
  }
}
```

### 3.2 End-to-End Encryption Implementation

```swift
// OmniAI/Security/E2EEncryption.swift
import CryptoKit
import Foundation

class E2EEncryption {
    private let keychainManager = KeychainManager.shared
    private var symmetricKey: SymmetricKey?
    
    init() {
        loadOrGenerateKey()
    }
    
    private func loadOrGenerateKey() {
        if let keyData = keychainManager.getData(forKey: "e2e_encryption_key") {
            self.symmetricKey = SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            keychainManager.saveData(keyData, forKey: "e2e_encryption_key")
            self.symmetricKey = newKey
        }
    }
    
    func encryptMessage(_ message: String) throws -> (ciphertext: Data, nonce: Data) {
        guard let key = symmetricKey,
              let messageData = message.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(messageData, using: key, nonce: nonce)
        
        return (sealedBox.ciphertext, Data(nonce))
    }
    
    func decryptMessage(ciphertext: Data, nonce: Data, tag: Data) throws -> String {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotFound
        }
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: ciphertext,
            tag: tag
        )
        
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let message = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return message
    }
}

enum EncryptionError: Error {
    case invalidInput
    case keyNotFound
    case decryptionFailed
}
```

---

## Phase 4: Testing & Validation (Week 5)

### 4.1 Security Test Suite

```swift
// OmniAITests/SecurityTests.swift
import XCTest
@testable import OmniAI

class SecurityTests: XCTestCase {
    
    func testCertificatePinning() {
        // Test certificate validation
    }
    
    func testBiometricAuthentication() {
        // Test biometric auth flow
    }
    
    func testEncryption() {
        // Test E2E encryption
    }
    
    func testInputSanitization() {
        // Test input validation
    }
    
    func testRateLimiting() {
        // Test rate limits
    }
}
```

### 4.2 Security Validation Script

```bash
#!/bin/bash
# security_validation.sh

echo "🔒 Running Security Validation..."

# Check for hardcoded secrets
echo "Checking for hardcoded secrets..."
grep -r "api[_-]key\|secret\|password" --include="*.swift" --include="*.ts" . | grep -v "//\|#"

# Check Firebase rules
echo "Testing Firebase security rules..."
firebase emulators:exec --only firestore "npm run test:security"

# Check dependencies for vulnerabilities
echo "Checking dependencies..."
npm audit
pod audit

# Run static analysis
echo "Running static analysis..."
swiftlint analyze

echo "✅ Security validation complete"
```

---

## Phase 5: Monitoring & Maintenance

### 5.1 Security Monitoring Dashboard

```typescript
// functions/src/monitoring/securityMonitor.ts
export class SecurityMonitor {
  static async detectAnomalies(userId: string): Promise<void> {
    // Check for unusual patterns
    // - Rapid request increases
    // - Geographic anomalies
    // - Time-based patterns
    // - Failed authentication attempts
  }
  
  static async alertOnSuspiciousActivity(event: any): Promise<void> {
    // Send alerts for:
    // - Multiple failed auth attempts
    // - Injection attempt patterns
    // - Rate limit violations
    // - Unusual API usage
  }
}
```

---

## Implementation Timeline

```mermaid
gantt
    title Security Implementation Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1 (Critical)
    App Check Implementation    :a1, 2025-01-24, 2d
    Input Sanitization         :a2, 2025-01-26, 2d
    API Key Security          :a3, 2025-01-28, 1d
    
    section Phase 2 (High)
    Certificate Pinning       :b1, 2025-01-29, 3d
    Biometric Auth           :b2, 2025-02-01, 2d
    UserDefaults Migration   :b3, 2025-02-03, 1d
    Audit Logging           :b4, 2025-02-04, 2d
    
    section Phase 3 (Medium)
    Firebase Rules          :c1, 2025-02-06, 2d
    E2E Encryption         :c2, 2025-02-08, 3d
    
    section Phase 4 (Testing)
    Security Testing       :d1, 2025-02-11, 3d
    Validation            :d2, 2025-02-14, 2d
    
    section Phase 5 (Ongoing)
    Monitoring Setup      :e1, 2025-02-16, 2d
    Documentation        :e2, 2025-02-18, 1d
```

---

## Success Metrics

### Security KPIs
- **API Abuse Rate**: < 0.1% of requests
- **Authentication Success Rate**: > 95%
- **Injection Attempts Blocked**: 100%
- **Certificate Pinning Success**: > 99.9%
- **Audit Log Coverage**: 100% of critical operations

### Performance Impact
- **Latency Increase**: < 50ms
- **CPU Usage**: < 5% increase
- **Memory Usage**: < 10MB increase
- **Battery Impact**: Negligible

---

## Rollback Plan

Each phase includes rollback capabilities:

1. **Feature Flags**: All security features behind flags
2. **Gradual Rollout**: 1% → 10% → 50% → 100%
3. **Monitoring**: Real-time metrics and alerts
4. **Backup**: Previous version maintained for 30 days
5. **Hotfix Process**: < 2 hour deployment capability

---

## Documentation Updates Required

1. **Developer Documentation**
   - Security architecture diagram
   - API security guidelines
   - Secure coding standards

2. **Operations Documentation**
   - Incident response playbook
   - Security monitoring guide
   - Audit log analysis

3. **User Documentation**
   - Privacy policy updates
   - Security features guide
   - Biometric setup instructions

---

## Conclusion

This implementation plan addresses all critical and high-priority security issues identified in the audit. Following this phased approach ensures:

1. **Immediate Risk Mitigation**: Critical vulnerabilities fixed first
2. **Minimal Disruption**: Gradual implementation with testing
3. **Comprehensive Coverage**: All identified issues addressed
4. **Future Protection**: Monitoring and maintenance processes

The total implementation time is approximately 5 weeks, with critical issues resolved in the first week.