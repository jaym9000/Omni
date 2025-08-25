//
//  JailbreakDetector.swift
//  OmniAI
//
//  Jailbreak and rooted device detection for security
//

import Foundation
import UIKit
import CryptoKit

final class JailbreakDetector {
    
    // MARK: - Properties
    
    static let shared = JailbreakDetector()
    private let auditLogger = AuditLogger.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if the device is jailbroken
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        // Don't block simulator for development
        return false
        #else
        
        let checks = [
            checkSuspiciousFiles(),
            checkSuspiciousLinks(),
            checkWritableSystemPaths(),
            checkDynamicLibraries(),
            checkOpenPorts(),
            checkSandboxIntegrity(),
            checkSystemCalls()
        ]
        
        let isJailbroken = checks.contains(true)
        
        if isJailbroken {
            auditLogger.logEvent(
                type: .securityEvent,
                details: ["event": "jailbreak_detected", "timestamp": ISO8601DateFormatter().string(from: Date())]
            )
        }
        
        return isJailbroken
        #endif
    }
    
    /// Check for debugging or tampering
    func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if result == 0 {
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        
        return false
    }
    
    /// Verify app integrity
    func verifyAppIntegrity() -> Bool {
        // Check if app binary has been modified
        guard let bundlePath = Bundle.main.bundlePath.cString(using: .utf8) else {
            return false
        }
        
        let handle = dlopen(bundlePath, RTLD_LAZY)
        defer { dlclose(handle) }
        
        // Check for code injection
        let suspiciousLibraries = [
            "SubstrateLoader.dylib",
            "SSLKillSwitch2.dylib",
            "SSLKillSwitch.dylib",
            "MobileSubstrate.dylib",
            "FridaGadget.dylib",
            "cycript",
            "libcycript"
        ]
        
        for library in suspiciousLibraries {
            if dlopen(library, RTLD_LAZY) != nil {
                auditLogger.logEvent(
                    type: .securityEvent,
                    details: ["event": "suspicious_library_detected", "library": library]
                )
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func checkSuspiciousFiles() -> Bool {
        let suspiciousFiles = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/bin/ssh",
            "/usr/libexec/sftp-server",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/Installer.app",
            "/Applications/Unc0ver.app",
            "/Applications/Chimera.app",
            "/Applications/Electra.app",
            "/Applications/Th0r.app"
        ]
        
        for file in suspiciousFiles {
            if FileManager.default.fileExists(atPath: file) {
                return true
            }
        }
        
        return false
    }
    
    private func checkSuspiciousLinks() -> Bool {
        let suspiciousLinks = [
            "/var/lib/undecimus/apt",
            "/User/Applications/",
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/include",
            "/usr/libexec",
            "/usr/share"
        ]
        
        for link in suspiciousLinks {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: link)
                if let type = attributes[.type] as? FileAttributeType,
                   type == .typeSymbolicLink {
                    return true
                }
            } catch {
                continue
            }
        }
        
        return false
    }
    
    private func checkWritableSystemPaths() -> Bool {
        let systemPaths = [
            "/",
            "/root",
            "/private",
            "/jb"
        ]
        
        for path in systemPaths {
            do {
                let testFile = "\(path)/test_\(UUID().uuidString).txt"
                try "test".write(toFile: testFile, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(atPath: testFile)
                return true
            } catch {
                continue
            }
        }
        
        return false
    }
    
    private func checkDynamicLibraries() -> Bool {
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            if let imageName = _dyld_get_image_name(i) {
                let name = String(cString: imageName)
                
                let suspiciousLibraries = [
                    "substrate",
                    "cycript",
                    "sslkillswitch",
                    "rocketbootstrap",
                    "substitute"
                ]
                
                for suspicious in suspiciousLibraries {
                    if name.lowercased().contains(suspicious) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func checkOpenPorts() -> Bool {
        // Check for common SSH port
        let ports: [UInt16] = [22, 23, 1337]
        
        for port in ports {
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = port.bigEndian
            addr.sin_addr.s_addr = inet_addr("127.0.0.1")
            
            let sock = socket(AF_INET, SOCK_STREAM, 0)
            
            let result = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            
            close(sock)
            
            if result == 0 {
                return true
            }
        }
        
        return false
    }
    
    private func checkSandboxIntegrity() -> Bool {
        // Try to fork - should fail in a proper sandbox
        let pid = fork()
        
        if pid >= 0 {
            if pid == 0 {
                exit(0)
            }
            return true
        }
        
        return false
    }
    
    private func checkSystemCalls() -> Bool {
        // Check if restricted system calls are available
        var oldPolicy: Int32 = 0
        let ret = sysctlbyname("security.mac.vnode_enforce", &oldPolicy, nil, nil, 0)
        
        return ret == 0
    }
}

// MARK: - Security Response

extension JailbreakDetector {
    
    enum SecurityResponse {
        case allow
        case warn
        case block
    }
    
    func determineSecurityResponse() -> SecurityResponse {
        if isJailbroken() {
            // Log the detection
            auditLogger.logEvent(
                type: .securityEvent,
                details: [
                    "event": "jailbreak_response",
                    "action": "evaluating",
                    "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
                ]
            )
            
            #if DEBUG
            // In debug mode, just warn
            return .warn
            #else
            // In production, block sensitive features
            return .block
            #endif
        }
        
        if isBeingDebugged() {
            #if DEBUG
            return .allow
            #else
            return .block
            #endif
        }
        
        if !verifyAppIntegrity() {
            return .block
        }
        
        return .allow
    }
    
    func showSecurityAlert(in viewController: UIViewController) {
        let response = determineSecurityResponse()
        
        switch response {
        case .allow:
            break
            
        case .warn:
            let alert = UIAlertController(
                title: "Security Warning",
                message: "Your device appears to be jailbroken. Some features may not work correctly and your data may be at risk.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "I Understand", style: .default))
            viewController.present(alert, animated: true)
            
        case .block:
            let alert = UIAlertController(
                title: "Security Alert",
                message: "This app cannot run on jailbroken or compromised devices for security reasons.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                exit(0)
            })
            viewController.present(alert, animated: true)
        }
    }
}

// MARK: - C Function Declarations

private let CTL_KERN: Int32 = 1
private let KERN_PROC: Int32 = 14
private let KERN_PROC_PID: Int32 = 1
private let P_TRACED: Int32 = 0x00000800

@_silgen_name("sysctl")
private func sysctl(_: UnsafeMutablePointer<Int32>, _: u_int, _: UnsafeMutableRawPointer?, _: UnsafeMutablePointer<Int>?, _: UnsafeMutableRawPointer?, _: Int) -> Int32

@_silgen_name("sysctlbyname")
private func sysctlbyname(_: UnsafePointer<CChar>, _: UnsafeMutableRawPointer?, _: UnsafeMutablePointer<Int>?, _: UnsafeMutableRawPointer?, _: Int) -> Int32

@_silgen_name("dlopen")
private func dlopen(_: UnsafePointer<CChar>?, _: Int32) -> UnsafeMutableRawPointer?

@_silgen_name("dlclose")
private func dlclose(_: UnsafeMutableRawPointer?) -> Int32

private let RTLD_LAZY: Int32 = 0x1

@_silgen_name("_dyld_image_count")
private func _dyld_image_count() -> UInt32

@_silgen_name("_dyld_get_image_name")
private func _dyld_get_image_name(_: UInt32) -> UnsafePointer<CChar>?

@_silgen_name("fork")
private func fork() -> Int32

@_silgen_name("exit")
private func exit(_: Int32) -> Never

@_silgen_name("inet_addr")
private func inet_addr(_: UnsafePointer<CChar>) -> UInt32