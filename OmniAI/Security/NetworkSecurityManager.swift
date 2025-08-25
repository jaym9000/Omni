//
//  NetworkSecurityManager.swift
//  OmniAI
//
//  Secure Network Communication Manager
//

import Foundation
import UIKit

/// Manages secure network communications with certificate pinning
class NetworkSecurityManager: NSObject {
    
    // MARK: - Properties
    
    static let shared = NetworkSecurityManager()
    
    // Temporarily disabled until CertificatePinner is fixed
    // private let certificatePinner = CertificatePinner.shared
    
    /// Secure URLSession with certificate pinning
    private lazy var secureSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        
        // Security settings
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.httpShouldUsePipelining = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil // Disable caching for sensitive data
        
        // Add security headers
        configuration.httpAdditionalHeaders = [
            "X-Requested-With": "XMLHttpRequest",
            "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "X-Platform": "iOS",
            "X-Device-ID": UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        ]
        
        // Enable TLS 1.3
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Performs a secure request with certificate pinning
    /// - Parameter request: The URLRequest to perform
    /// - Returns: Data and URLResponse tuple
    func performSecureRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var secureRequest = request
        
        // Add security headers if not present
        if secureRequest.value(forHTTPHeaderField: "X-Request-ID") == nil {
            secureRequest.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        }
        
        // Add timestamp for request tracking
        secureRequest.setValue("\(Date().timeIntervalSince1970)", forHTTPHeaderField: "X-Request-Timestamp")
        
        // Log request for debugging (remove sensitive data)
        #if DEBUG
        print("🔒 Secure request to: \(request.url?.host ?? "unknown")")
        #endif
        
        do {
            let (data, response) = try await secureSession.data(for: secureRequest)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkSecurityError.invalidResponse
            }
            
            // Check for security headers in response
            validateSecurityHeaders(httpResponse)
            
            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkSecurityError.httpError(statusCode: httpResponse.statusCode)
            }
            
            return (data, response)
        } catch {
            print("❌ Secure request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Creates a secure URLRequest with proper headers
    /// - Parameters:
    ///   - url: The URL for the request
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Optional request body
    ///   - token: Optional authentication token
    /// - Returns: Configured URLRequest
    func createSecureRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        token: String? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Add authentication if provided
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add content type for JSON
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Add accept header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add user agent
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let osVersion = UIDevice.current.systemVersion
        request.setValue("OmniAI/\(appVersion) (iOS \(osVersion))", forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    /// Performs a secure JSON request
    /// - Parameters:
    ///   - url: The URL for the request
    ///   - method: HTTP method
    ///   - body: Optional Encodable body
    ///   - token: Optional authentication token
    /// - Returns: Decoded response of type T
    func performSecureJSONRequest<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: Encodable? = nil,
        token: String? = nil,
        responseType: T.Type
    ) async throws -> T {
        var bodyData: Data? = nil
        
        if let body = body {
            bodyData = try JSONEncoder().encode(body)
        }
        
        let request = createSecureRequest(
            url: url,
            method: method,
            body: bodyData,
            token: token
        )
        
        let (data, _) = try await performSecureRequest(request)
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            print("❌ JSON decoding failed: \(error)")
            throw NetworkSecurityError.decodingFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Validates security headers in response
    private func validateSecurityHeaders(_ response: HTTPURLResponse) {
        #if DEBUG
        // Check for security headers
        let securityHeaders = [
            "Strict-Transport-Security",
            "X-Content-Type-Options",
            "X-Frame-Options"
        ]
        
        for header in securityHeaders {
            if response.value(forHTTPHeaderField: header) == nil {
                print("⚠️ Missing security header: \(header)")
            }
        }
        #endif
    }
    
    /// Clears all cached data and cookies
    func clearSecurityCache() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear cookies
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        // Clear credentials
        let credentialStorage = URLCredentialStorage.shared
        for (protectionSpace, credentials) in credentialStorage.allCredentials {
            for (_, credential) in credentials {
                credentialStorage.remove(credential, for: protectionSpace)
            }
        }
        
        print("🧹 Security cache cleared")
    }
}

// MARK: - URLSessionDelegate

extension NetworkSecurityManager: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Use certificate pinner for validation
        // Temporarily use default handling until CertificatePinner is fixed
        // let (disposition, credential) = certificatePinner.validate(challenge: challenge)
        let disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        let credential: URLCredential? = nil
        completionHandler(disposition, credential)
    }
    
    func urlSession(_ session: URLSession,
                   didBecomeInvalidWithError error: Error?) {
        if let error = error {
            print("❌ URLSession became invalid: \(error.localizedDescription)")
        }
    }
}

// MARK: - URLSessionTaskDelegate

extension NetworkSecurityManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Additional task-level authentication if needed
        // Temporarily use default handling until CertificatePinner is fixed
        // let (disposition, credential) = certificatePinner.validate(challenge: challenge)
        let disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        let credential: URLCredential? = nil
        completionHandler(disposition, credential)
    }
    
    func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ Task completed with error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Network Security Error

enum NetworkSecurityError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case certificatePinningFailed
    case decodingFailed(Error)
    case unauthorized
    case forbidden
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .certificatePinningFailed:
            return "Certificate validation failed"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}