//
//  AuditLogger.swift
//  OmniAI
//
//  Comprehensive Audit Logging for Security Events
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CryptoKit

// MARK: - Audit Event Types

enum AuditEventType: String, Codable {
    // Authentication events
    case login = "AUTH_LOGIN"
    case logout = "AUTH_LOGOUT"
    case loginFailed = "AUTH_LOGIN_FAILED"
    case signUp = "AUTH_SIGNUP"
    case passwordReset = "AUTH_PASSWORD_RESET"
    case biometricAuth = "AUTH_BIOMETRIC"
    case sessionExpired = "AUTH_SESSION_EXPIRED"
    
    // Data access events
    case dataRead = "DATA_READ"
    case dataWrite = "DATA_WRITE"
    case dataDelete = "DATA_DELETE"
    case dataExport = "DATA_EXPORT"
    
    // Security events
    case suspiciousActivity = "SECURITY_SUSPICIOUS"
    case rateLimitExceeded = "SECURITY_RATE_LIMIT"
    case injectionAttempt = "SECURITY_INJECTION"
    case unauthorizedAccess = "SECURITY_UNAUTHORIZED"
    case certificatePinningFailed = "SECURITY_CERT_FAILED"
    
    // Payment events
    case subscriptionStarted = "PAYMENT_SUBSCRIPTION_START"
    case subscriptionCancelled = "PAYMENT_SUBSCRIPTION_CANCEL"
    case paymentFailed = "PAYMENT_FAILED"
    case refundProcessed = "PAYMENT_REFUND"
    
    // Error events
    case apiError = "ERROR_API"
    case networkError = "ERROR_NETWORK"
    case systemError = "ERROR_SYSTEM"
    
    // User actions
    case messagesSent = "USER_MESSAGE_SENT"
    case settingsChanged = "USER_SETTINGS_CHANGED"
    case accountDeleted = "USER_ACCOUNT_DELETED"
}

// MARK: - Audit Event Severity

enum AuditEventSeverity: String, Codable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

// MARK: - Audit Event

struct AuditEvent: Codable {
    let id: String
    let timestamp: Date
    let type: AuditEventType
    let severity: AuditEventSeverity
    let userId: String?
    let sessionId: String?
    let action: String
    let details: [String: String]
    let deviceInfo: [String: String]
    let ipAddress: String?
    let location: String?
    var hash: String?
    
    init(
        type: AuditEventType,
        severity: AuditEventSeverity = .info,
        userId: String? = nil,
        sessionId: String? = nil,
        action: String,
        details: [String: String] = [:],
        ipAddress: String? = nil,
        location: String? = nil
    ) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.type = type
        self.severity = severity
        self.userId = userId
        self.sessionId = sessionId
        self.action = action
        self.details = details
        self.deviceInfo = AuditLogger.getDeviceInfo()
        self.ipAddress = ipAddress
        self.location = location
    }
    
    /// Creates a hash of the event for integrity verification
    mutating func withHash() -> AuditEvent {
        let dataString = "\(id)\(timestamp.timeIntervalSince1970)\(type.rawValue)\(severity.rawValue)\(userId ?? "")\(action)"
        let hash = SHA256.hash(data: dataString.data(using: .utf8)!)
        self.hash = hash.compactMap { String(format: "%02x", $0) }.joined()
        return self
    }
    
    /// Converts to Firestore-compatible dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "timestamp": Timestamp(date: timestamp),
            "type": type.rawValue,
            "severity": severity.rawValue,
            "action": action,
            "deviceInfo": deviceInfo,
            "details": details
        ]
        
        if let userId = userId {
            dict["userId"] = userId
        }
        
        if let sessionId = sessionId {
            dict["sessionId"] = sessionId
        }
        
        if let ipAddress = ipAddress {
            dict["ipAddress"] = ipAddress
        }
        
        if let location = location {
            dict["location"] = location
        }
        
        if let hash = hash {
            dict["hash"] = hash
        }
        
        return dict
    }
}

// MARK: - Audit Logger

/// Manages security audit logging
class AuditLogger {
    
    // MARK: - Properties
    
    static let shared = AuditLogger()
    
    private let db = Firestore.firestore()
    private let localQueue = DispatchQueue(label: "audit.logger.queue", attributes: .concurrent)
    private let syncQueue = DispatchQueue(label: "audit.logger.sync")
    
    private var pendingEvents: [AuditEvent] = []
    private let maxPendingEvents = 100
    private let syncInterval: TimeInterval = 60 // Sync every minute
    
    private var syncTimer: Timer?
    private let auditCollection = "audit_logs"
    
    // Local storage for offline events
    private let localStorageKey = "PendingAuditEvents"
    
    private init() {
        loadPendingEvents()
        startSyncTimer()
    }
    
    // MARK: - Public Methods
    
    /// Logs an event with custom details
    func logEvent(type: AuditEventType, severity: AuditEventSeverity = .info, details: [String: Any]) {
        // Convert Any values to String
        let stringDetails = details.mapValues { "\($0)" }
        
        let event = AuditEvent(
            type: type,
            severity: severity,
            userId: Auth.auth().currentUser?.uid,
            sessionId: nil,
            action: type.rawValue,
            details: stringDetails
        )
        
        log(event)
    }
    
    /// Logs an audit event
    func log(_ event: AuditEvent) {
        var hashedEvent = event
        hashedEvent = hashedEvent.withHash()
        
        // Store locally first
        syncQueue.async {
            self.pendingEvents.append(hashedEvent)
            self.savePendingEvents()
            
            // Flush if we have too many pending events
            if self.pendingEvents.count >= self.maxPendingEvents {
                self.flushEvents()
            }
        }
        
        // Try to send immediately if online
        Task {
            await self.sendEvent(hashedEvent)
        }
        
        // Log to console in debug mode
        #if DEBUG
        print("📝 Audit: [\(hashedEvent.severity.rawValue)] \(hashedEvent.type.rawValue) - \(hashedEvent.action)")
        #endif
    }
    
    /// Logs an authentication event
    func logAuthentication(
        type: AuditEventType,
        userId: String?,
        success: Bool,
        details: [String: String] = [:]
    ) {
        let severity: AuditEventSeverity = success ? .info : .warning
        var eventDetails = details
        eventDetails["success"] = "\(success)"
        
        let event = AuditEvent(
            type: type,
            severity: severity,
            userId: userId,
            action: success ? "Authentication successful" : "Authentication failed",
            details: eventDetails
        )
        
        log(event)
    }
    
    /// Logs a security event
    func logSecurityEvent(
        type: AuditEventType,
        userId: String? = nil,
        details: [String: String] = [:]
    ) {
        let event = AuditEvent(
            type: type,
            severity: .warning,
            userId: userId,
            action: "Security event detected",
            details: details
        )
        
        log(event)
    }
    
    /// Logs a data access event
    func logDataAccess(
        operation: String,
        resource: String,
        userId: String?,
        success: Bool = true
    ) {
        let type: AuditEventType
        switch operation.lowercased() {
        case "read":
            type = .dataRead
        case "write", "create", "update":
            type = .dataWrite
        case "delete":
            type = .dataDelete
        default:
            type = .dataRead
        }
        
        let event = AuditEvent(
            type: type,
            severity: .info,
            userId: userId,
            action: "\(operation) \(resource)",
            details: [
                "operation": operation,
                "resource": resource,
                "success": "\(success)"
            ]
        )
        
        log(event)
    }
    
    /// Logs an error event
    func logError(
        error: Error,
        userId: String? = nil,
        context: String? = nil
    ) {
        let event = AuditEvent(
            type: .systemError,
            severity: .error,
            userId: userId,
            action: "Error occurred",
            details: [
                "error": error.localizedDescription,
                "context": context ?? "Unknown",
                "errorType": String(describing: type(of: error))
            ]
        )
        
        log(event)
    }
    
    /// Forces synchronization of pending events
    func forceSyncEvents() {
        syncQueue.async {
            self.flushEvents()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sends a single event to Firestore
    private func sendEvent(_ event: AuditEvent) async {
        do {
            try await db.collection(auditCollection)
                .document(event.id)
                .setData(event.toDictionary())
            
            // Remove from pending if successfully sent
            syncQueue.async {
                self.pendingEvents.removeAll { $0.id == event.id }
                self.savePendingEvents()
            }
        } catch {
            // Keep in pending for retry
            print("❌ Failed to send audit event: \(error)")
        }
    }
    
    /// Flushes all pending events to Firestore
    private func flushEvents() {
        let eventsToSend = pendingEvents
        
        guard !eventsToSend.isEmpty else { return }
        
        print("📤 Flushing \(eventsToSend.count) audit events...")
        
        Task {
            for event in eventsToSend {
                await sendEvent(event)
            }
        }
    }
    
    /// Starts the sync timer
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            self.forceSyncEvents()
        }
    }
    
    /// Saves pending events to local storage
    private func savePendingEvents() {
        do {
            let data = try JSONEncoder().encode(pendingEvents)
            UserDefaults.standard.set(data, forKey: localStorageKey)
        } catch {
            print("❌ Failed to save pending audit events: \(error)")
        }
    }
    
    /// Loads pending events from local storage
    private func loadPendingEvents() {
        // Implementation depends on how you want to persist events
        // For now, we'll just initialize with empty array
        pendingEvents = []
    }
    
    /// Gets device information
    static func getDeviceInfo() -> [String: String] {
        return [
            "model": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        ]
    }
}

// MARK: - Convenience Extensions

extension AuditLogger {
    
    /// Logs a successful login
    func logLogin(userId: String, method: String) {
        logAuthentication(
            type: .login,
            userId: userId,
            success: true,
            details: ["method": method]
        )
    }
    
    /// Logs a failed login attempt
    func logLoginFailed(email: String, reason: String) {
        logAuthentication(
            type: .loginFailed,
            userId: nil,
            success: false,
            details: [
                "email": email,
                "reason": reason
            ]
        )
    }
    
    /// Logs a logout
    func logLogout(userId: String) {
        log(AuditEvent(
            type: .logout,
            userId: userId,
            action: "User logged out"
        ))
    }
    
    /// Logs rate limit exceeded
    func logRateLimitExceeded(userId: String?, endpoint: String) {
        logSecurityEvent(
            type: .rateLimitExceeded,
            userId: userId,
            details: [
                "endpoint": endpoint,
                "timestamp": "\(Date().timeIntervalSince1970)"
            ]
        )
    }
    
    /// Logs suspicious activity
    func logSuspiciousActivity(userId: String?, activity: String, details: [String: String] = [:]) {
        var eventDetails = details
        eventDetails["activity"] = activity
        
        logSecurityEvent(
            type: .suspiciousActivity,
            userId: userId,
            details: eventDetails
        )
    }
}