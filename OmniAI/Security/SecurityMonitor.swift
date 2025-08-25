//
//  SecurityMonitor.swift
//  OmniAI
//
//  Real-time security monitoring and alerting system
//

import Foundation
import FirebaseFirestore
import FirebaseAnalytics
import UserNotifications
import CryptoKit

final class SecurityMonitor {
    
    // MARK: - Properties
    
    static let shared = SecurityMonitor()
    
    private let db = Firestore.firestore()
    private let auditLogger = AuditLogger.shared
    private var monitoringTimer: Timer?
    private var alertThresholds = AlertThresholds()
    
    private var securityMetrics = SecurityMetrics()
    private let metricsQueue = DispatchQueue(label: "com.omniai.security.metrics")
    
    private init() {
        setupMonitoring()
        loadAlertThresholds()
    }
    
    // MARK: - Monitoring Setup
    
    private func setupMonitoring() {
        // Start periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.performSecurityChecks()
        }
        
        // Monitor app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Security Checks
    
    private func performSecurityChecks() {
        Task {
            await checkForAnomalies()
            await checkRateLimits()
            await checkFailedAuthentications()
            await checkJailbreakStatus()
            await checkDataIntegrity()
            await checkNetworkSecurity()
            
            // Update dashboard
            await updateSecurityDashboard()
        }
    }
    
    // MARK: - Anomaly Detection
    
    private func checkForAnomalies() async {
        // Check for unusual patterns
        let recentEvents = await auditLogger.getRecentEvents(minutes: 5)
        
        // Detect rapid authentication attempts
        let authEvents = recentEvents.filter { $0.type == .authentication }
        if authEvents.count > alertThresholds.maxAuthAttemptsPerMinute {
            await triggerAlert(
                type: .suspiciousActivity,
                severity: .high,
                message: "Excessive authentication attempts detected",
                details: ["count": authEvents.count]
            )
        }
        
        // Detect unusual API usage patterns
        let apiEvents = recentEvents.filter { $0.type == .apiCall }
        let uniqueSessions = Set(apiEvents.compactMap { $0.sessionId })
        
        if uniqueSessions.count > alertThresholds.maxUniqueSessions {
            await triggerAlert(
                type: .suspiciousActivity,
                severity: .medium,
                message: "Unusual number of unique sessions",
                details: ["sessions": uniqueSessions.count]
            )
        }
        
        // Check for data exfiltration attempts
        let dataEvents = recentEvents.filter { $0.type == .dataAccess }
        let dataVolume = dataEvents.compactMap { $0.dataSize }.reduce(0, +)
        
        if dataVolume > alertThresholds.maxDataVolumePerMinute {
            await triggerAlert(
                type: .dataExfiltration,
                severity: .critical,
                message: "Potential data exfiltration detected",
                details: ["volume": dataVolume]
            )
        }
    }
    
    // MARK: - Rate Limit Monitoring
    
    private func checkRateLimits() async {
        do {
            let snapshot = try await db.collection("rate_limits")
                .whereField("timestamp", isGreaterThan: Date().addingTimeInterval(-300))
                .getDocuments()
            
            for document in snapshot.documents {
                let data = document.data()
                if let requests = data["requests"] as? Int,
                   requests > alertThresholds.maxRequestsPerUser {
                    
                    await triggerAlert(
                        type: .rateLimitExceeded,
                        severity: .medium,
                        message: "User exceeded rate limit",
                        details: ["userId": document.documentID, "requests": requests]
                    )
                }
            }
        } catch {
            print("Error checking rate limits: \(error)")
        }
    }
    
    // MARK: - Authentication Monitoring
    
    private func checkFailedAuthentications() async {
        let failedAuths = await auditLogger.getFailedAuthentications(minutes: 10)
        
        // Group by user/device
        var failuresByUser: [String: Int] = [:]
        for auth in failedAuths {
            let key = auth.userId ?? auth.deviceId ?? "unknown"
            failuresByUser[key, default: 0] += 1
        }
        
        // Check for brute force attempts
        for (user, count) in failuresByUser {
            if count > alertThresholds.maxFailedAuthPerUser {
                await triggerAlert(
                    type: .bruteForceAttempt,
                    severity: .high,
                    message: "Possible brute force attack",
                    details: ["user": user, "attempts": count]
                )
            }
        }
    }
    
    // MARK: - Jailbreak Monitoring
    
    private func checkJailbreakStatus() async {
        let isJailbroken = JailbreakDetector.shared.isJailbroken()
        
        metricsQueue.async {
            self.securityMetrics.jailbrokenDevices = isJailbroken ? 1 : 0
        }
        
        if isJailbroken {
            await triggerAlert(
                type: .jailbreakDetected,
                severity: .high,
                message: "Application running on jailbroken device",
                details: ["deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"]
            )
        }
    }
    
    // MARK: - Data Integrity
    
    private func checkDataIntegrity() async {
        // Verify audit log integrity
        let integrityValid = await auditLogger.verifyIntegrity()
        
        if !integrityValid {
            await triggerAlert(
                type: .dataIntegrityViolation,
                severity: .critical,
                message: "Audit log integrity check failed",
                details: ["component": "audit_logs"]
            )
        }
        
        // Check for unauthorized data modifications
        do {
            let snapshot = try await db.collection("users")
                .whereField("lastModified", isGreaterThan: Date().addingTimeInterval(-300))
                .getDocuments()
            
            for document in snapshot.documents {
                let data = document.data()
                if let modifiedBy = data["modifiedBy"] as? String,
                   modifiedBy != document.documentID {
                    
                    await triggerAlert(
                        type: .unauthorizedAccess,
                        severity: .high,
                        message: "Unauthorized data modification detected",
                        details: ["document": document.documentID, "modifiedBy": modifiedBy]
                    )
                }
            }
        } catch {
            print("Error checking data integrity: \(error)")
        }
    }
    
    // MARK: - Network Security
    
    private func checkNetworkSecurity() async {
        // Check certificate pinning status
        let pinningEnabled = NetworkSecurityManager.shared.isCertificatePinningEnabled
        
        if !pinningEnabled {
            await triggerAlert(
                type: .configurationIssue,
                severity: .medium,
                message: "Certificate pinning is disabled",
                details: ["component": "networking"]
            )
        }
        
        // Monitor for suspicious network activity
        let networkEvents = await auditLogger.getNetworkEvents(minutes: 5)
        
        // Check for connections to unknown hosts
        let knownHosts = ["firebaseapp.com", "googleapis.com", "apple.com", "openai.com"]
        
        for event in networkEvents {
            if let host = event.host,
               !knownHosts.contains(where: { host.contains($0) }) {
                
                await triggerAlert(
                    type: .suspiciousActivity,
                    severity: .medium,
                    message: "Connection to unknown host detected",
                    details: ["host": host]
                )
            }
        }
    }
    
    // MARK: - Alert Management
    
    private func triggerAlert(type: AlertType, severity: AlertSeverity, message: String, details: [String: Any]) async {
        // Log the alert
        auditLogger.logEvent(
            type: .securityEvent,
            details: [
                "alert_type": type.rawValue,
                "severity": severity.rawValue,
                "message": message,
                "details": details
            ]
        )
        
        // Update metrics
        metricsQueue.async {
            self.securityMetrics.totalAlerts += 1
            
            switch severity {
            case .low:
                self.securityMetrics.lowSeverityAlerts += 1
            case .medium:
                self.securityMetrics.mediumSeverityAlerts += 1
            case .high:
                self.securityMetrics.highSeverityAlerts += 1
            case .critical:
                self.securityMetrics.criticalAlerts += 1
            }
        }
        
        // Send to Firebase
        Analytics.logEvent("security_alert", parameters: [
            "type": type.rawValue,
            "severity": severity.rawValue,
            "message": message
        ])
        
        // Store in Firestore
        do {
            try await db.collection("security_alerts").addDocument(data: [
                "type": type.rawValue,
                "severity": severity.rawValue,
                "message": message,
                "details": details,
                "timestamp": FieldValue.serverTimestamp(),
                "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                "resolved": false
            ])
        } catch {
            print("Error storing alert: \(error)")
        }
        
        // Send push notification for critical alerts
        if severity == .critical {
            await sendPushNotification(message: message)
        }
    }
    
    private func sendPushNotification(message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Security Alert"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error sending notification: \(error)")
        }
    }
    
    // MARK: - Dashboard Updates
    
    private func updateSecurityDashboard() async {
        let metrics = metricsQueue.sync { self.securityMetrics }
        
        // Update Firestore dashboard
        do {
            try await db.collection("security_dashboard")
                .document("current")
                .setData([
                    "timestamp": FieldValue.serverTimestamp(),
                    "totalAlerts": metrics.totalAlerts,
                    "criticalAlerts": metrics.criticalAlerts,
                    "highAlerts": metrics.highSeverityAlerts,
                    "mediumAlerts": metrics.mediumSeverityAlerts,
                    "lowAlerts": metrics.lowSeverityAlerts,
                    "jailbrokenDevices": metrics.jailbrokenDevices,
                    "failedAuths": metrics.failedAuthentications,
                    "rateLimitHits": metrics.rateLimitHits,
                    "suspiciousActivities": metrics.suspiciousActivities,
                    "lastUpdated": Date()
                ], merge: true)
        } catch {
            print("Error updating dashboard: \(error)")
        }
    }
    
    // MARK: - Configuration
    
    private func loadAlertThresholds() {
        // Load from remote config or use defaults
        Task {
            do {
                let snapshot = try await db.collection("config")
                    .document("alert_thresholds")
                    .getDocument()
                
                if let data = snapshot.data() {
                    alertThresholds.maxAuthAttemptsPerMinute = data["maxAuthAttemptsPerMinute"] as? Int ?? 10
                    alertThresholds.maxFailedAuthPerUser = data["maxFailedAuthPerUser"] as? Int ?? 5
                    alertThresholds.maxRequestsPerUser = data["maxRequestsPerUser"] as? Int ?? 100
                    alertThresholds.maxUniqueSessions = data["maxUniqueSessions"] as? Int ?? 50
                    alertThresholds.maxDataVolumePerMinute = data["maxDataVolumePerMinute"] as? Int ?? 10_000_000
                }
            } catch {
                print("Error loading thresholds: \(error)")
            }
        }
    }
    
    // MARK: - Lifecycle
    
    @objc private func appDidBecomeActive() {
        performSecurityChecks()
    }
    
    @objc private func appWillResignActive() {
        // Log session end
        auditLogger.logEvent(
            type: .sessionEvent,
            details: ["event": "session_end"]
        )
    }
    
    deinit {
        monitoringTimer?.invalidate()
    }
}

// MARK: - Supporting Types

enum AlertType: String {
    case suspiciousActivity = "suspicious_activity"
    case bruteForceAttempt = "brute_force"
    case rateLimitExceeded = "rate_limit"
    case jailbreakDetected = "jailbreak"
    case dataIntegrityViolation = "data_integrity"
    case unauthorizedAccess = "unauthorized_access"
    case dataExfiltration = "data_exfiltration"
    case configurationIssue = "configuration"
}

enum AlertSeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct AlertThresholds {
    var maxAuthAttemptsPerMinute = 10
    var maxFailedAuthPerUser = 5
    var maxRequestsPerUser = 100
    var maxUniqueSessions = 50
    var maxDataVolumePerMinute = 10_000_000 // 10MB
}

struct SecurityMetrics {
    var totalAlerts = 0
    var criticalAlerts = 0
    var highSeverityAlerts = 0
    var mediumSeverityAlerts = 0
    var lowSeverityAlerts = 0
    var jailbrokenDevices = 0
    var failedAuthentications = 0
    var rateLimitHits = 0
    var suspiciousActivities = 0
}

// MARK: - Public Interface

extension SecurityMonitor {
    
    /// Get current security status
    func getSecurityStatus() -> SecurityStatus {
        let metrics = metricsQueue.sync { self.securityMetrics }
        
        if metrics.criticalAlerts > 0 {
            return .critical
        } else if metrics.highSeverityAlerts > 0 {
            return .warning
        } else if metrics.mediumSeverityAlerts > 0 {
            return .caution
        } else {
            return .secure
        }
    }
    
    /// Manually trigger security scan
    func triggerSecurityScan() {
        performSecurityChecks()
    }
    
    /// Get security metrics
    func getMetrics() -> SecurityMetrics {
        return metricsQueue.sync { self.securityMetrics }
    }
    
    /// Reset metrics (for testing)
    func resetMetrics() {
        metricsQueue.async {
            self.securityMetrics = SecurityMetrics()
        }
    }
}

enum SecurityStatus {
    case secure
    case caution
    case warning
    case critical
    
    var color: UIColor {
        switch self {
        case .secure:
            return .systemGreen
        case .caution:
            return .systemYellow
        case .warning:
            return .systemOrange
        case .critical:
            return .systemRed
        }
    }
    
    var icon: String {
        switch self {
        case .secure:
            return "checkmark.shield.fill"
        case .caution:
            return "exclamationmark.shield.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.shield.fill"
        }
    }
}