import Foundation

class RateLimiter {
    static let shared = RateLimiter()
    
    private let keychainManager = KeychainManager.shared
    
    // Configuration
    private let maxLoginAttempts = 5
    private let initialLockDuration: TimeInterval = 60 // 1 minute
    private let maxLockDuration: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Public Methods
    
    func checkIfAccountLocked() throws -> (isLocked: Bool, unlockTime: Date?) {
        guard let lockTime = try keychainManager.getAccountLockTime() else {
            return (false, nil)
        }
        
        if lockTime > Date() {
            return (true, lockTime)
        } else {
            // Lock expired, clear it
            try keychainManager.resetLoginAttempts()
            return (false, nil)
        }
    }
    
    func recordFailedAttempt(for email: String) throws -> (shouldLock: Bool, lockUntil: Date?) {
        let attempts = try keychainManager.incrementLoginAttempts()
        
        print("⚠️ Failed login attempt #\(attempts) for \(email)")
        
        if attempts >= maxLoginAttempts {
            // Calculate lock duration with exponential backoff
            let lockMultiplier = min(attempts - maxLoginAttempts + 1, 10)
            let lockDuration = min(initialLockDuration * Double(lockMultiplier), maxLockDuration)
            let lockUntil = Date().addingTimeInterval(lockDuration)
            
            try keychainManager.lockAccount(until: lockUntil)
            
            print("🔒 Account locked until \(lockUntil)")
            return (true, lockUntil)
        }
        
        return (false, nil)
    }
    
    func recordSuccessfulLogin() throws {
        try keychainManager.resetLoginAttempts()
        print("✅ Login successful, attempts counter reset")
    }
    
    func getRemainingAttempts() throws -> Int {
        let currentAttempts = try keychainManager.getLoginAttempts()
        return max(0, maxLoginAttempts - currentAttempts)
    }
    
    // MARK: - Guest Message Limits
    
    func checkGuestMessageLimit(currentCount: Int, maxCount: Int = 20) -> Bool {
        return currentCount < maxCount
    }
    
    func incrementGuestMessageCount(for userId: String) async throws -> (count: Int, limitReached: Bool) {
        // This would normally update in Firebase
        // For now, we'll track locally
        let key = "guestMessages_\(userId)"
        let currentCount = UserDefaults.standard.integer(forKey: key)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: key)
        
        let limitReached = newCount >= 20
        return (newCount, limitReached)
    }
    
    func resetGuestMessageCount(for userId: String) {
        let key = "guestMessages_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - API Rate Limiting
    
    private var apiCallTimestamps: [String: [Date]] = [:]
    private let apiCallQueue = DispatchQueue(label: "com.jns.Omni.rateLimiter")
    
    func checkAPIRateLimit(for endpoint: String, maxCalls: Int = 10, windowSeconds: TimeInterval = 60) -> Bool {
        return apiCallQueue.sync {
            let now = Date()
            let windowStart = now.addingTimeInterval(-windowSeconds)
            
            // Get existing timestamps for this endpoint
            var timestamps = apiCallTimestamps[endpoint] ?? []
            
            // Remove timestamps outside the window
            timestamps = timestamps.filter { $0 > windowStart }
            
            // Check if we're within the limit
            if timestamps.count < maxCalls {
                timestamps.append(now)
                apiCallTimestamps[endpoint] = timestamps
                return true
            }
            
            return false
        }
    }
    
    // MARK: - Password Reset Rate Limiting
    
    private var passwordResetAttempts: [String: Date] = [:]
    private let passwordResetCooldown: TimeInterval = 300 // 5 minutes
    
    func checkPasswordResetRateLimit(for email: String) -> (allowed: Bool, nextAllowedTime: Date?) {
        if let lastAttempt = passwordResetAttempts[email] {
            let nextAllowedTime = lastAttempt.addingTimeInterval(passwordResetCooldown)
            
            if Date() < nextAllowedTime {
                return (false, nextAllowedTime)
            }
        }
        
        passwordResetAttempts[email] = Date()
        return (true, nil)
    }
    
    // MARK: - Verification Email Rate Limiting
    
    private var verificationEmailAttempts: [String: Date] = [:]
    private let verificationEmailCooldown: TimeInterval = 60 // 1 minute
    
    func checkVerificationEmailRateLimit(for userId: String) -> (allowed: Bool, nextAllowedTime: Date?) {
        if let lastAttempt = verificationEmailAttempts[userId] {
            let nextAllowedTime = lastAttempt.addingTimeInterval(verificationEmailCooldown)
            
            if Date() < nextAllowedTime {
                return (false, nextAllowedTime)
            }
        }
        
        verificationEmailAttempts[userId] = Date()
        return (true, nil)
    }
}

// MARK: - Rate Limit Error Extension

extension AuthError {
    static func rateLimitError(for action: String, retryAfter: Date) -> AuthError {
        return .rateLimitExceeded(retryAfter: retryAfter)
    }
}