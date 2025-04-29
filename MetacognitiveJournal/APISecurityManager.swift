//
//  APISecurityManager.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/17/25.
//

import Foundation
import UIKit

class APISecurityManager {
    static let shared = APISecurityManager()
    
    private let rateLimiter = APIRateLimiter()
    private var jwtToken: String?
    private var lastTokenRefresh: Date?
    private let tokenRefreshInterval: TimeInterval = 3600 // 1 hour
    
    // API request with rate limiting and security headers
    func makeSecureRequest(endpoint: String, method: String, parameters: [String: Any] = [:], 
                           completion: @escaping (Data?, Error?) -> Void) {
        // Check rate limiting
        guard rateLimiter.isRequestAllowed(for: endpoint) else {
            let error = NSError(
                domain: "APISecurityManager",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."]
            )
            completion(nil, error)
            return
        }
        
        // Record this request
        rateLimiter.recordRequest(for: endpoint)
        
        // Check if we need to refresh the token
        refreshTokenIfNeeded { [weak self] refreshed in
            guard let self = self else { return }
            
            // Create the secure API client
            let apiClient = SecureAPIClient(
                baseURL: URL(string: "https://api.example.com")!,
                apiKey: self.getApiKey(),
                secretKey: self.getSecretKey()
            )
            
            // Prepare parameters with additional security information
            var secureParameters = parameters
            secureParameters["device_id"] = self.getDeviceIdentifier()
            secureParameters["app_version"] = self.getAppVersion()
            
            // Add auth token if available
            var headers: [String: String] = [:]
            if let token = self.jwtToken {
                headers["Authorization"] = "Bearer \(token)"
            }
            
            // Make the request with the secure client
            apiClient.makeRequest(
                endpoint: endpoint,
                method: method,
                parameters: secureParameters,
                headers: headers
            ) { data, error in
                // Handle specific API security errors
                if let error = error as NSError?, error.domain == "APIClient" {
                    if error.code == 401 {
                        self.jwtToken = nil
                        self.lastTokenRefresh = nil

                        print("API authentication failure for endpoint: \(endpoint)")

                        self.refreshTokenIfNeeded { refreshed in
                            if refreshed {
                                self.makeSecureRequest(
                                    endpoint: endpoint,
                                    method: method,
                                    parameters: parameters,
                                    completion: completion
                                )
                            } else {
                                completion(nil, error)
                            }
                        }
                        return
                    } else if error.code == 403 {
                        print("API access forbidden for endpoint: \(endpoint)")
                    }
                }

                completion(data, error)
                        }
        }
    }
    
    // Refresh the authentication token if needed
    private func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        if jwtToken == nil || lastTokenRefresh == nil || 
           Date().timeIntervalSince(lastTokenRefresh!) >= tokenRefreshInterval {
            // Need to refresh token
            authenticateWithServer { [weak self] token, error in
                if let token = token {
                    self?.jwtToken = token
                    self?.lastTokenRefresh = Date()
                    completion(true)
                } else {
                    // Authentication failed
                    print("Failed to refresh authentication token: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        } else {
            // Token is still valid
            completion(true)
        }
    }
    
    // Authenticate with the server
    private func authenticateWithServer(completion: @escaping (String?, Error?) -> Void) {
        // Implement your authentication logic here
        // This is a simplified example
        let apiKey = getApiKey()
        let deviceId = getDeviceIdentifier()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        
        // Generate a signature for the authentication request
        let signatureBase = apiKey + deviceId + timestamp
        let signature = generateHMAC(data: signatureBase, key: getSecretKey())
        
        // Create authentication request
        let url = URL(string: "https://api.example.com/auth")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare authentication parameters
        let authParams: [String: Any] = [
            "api_key": apiKey,
            "device_id": deviceId,
            "timestamp": timestamp,
            "signature": signature,
            "app_version": getAppVersion()
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: authParams)
        } catch {
            completion(nil, error)
            return
        }
        
        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "Authentication", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    completion(token, nil)
                } else {
                    completion(nil, NSError(domain: "Authentication", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
                }
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    // Public API key accessor for service
    public func getAPIKeyForService(_ service: String) -> String? {
        // For now, only support 'OpenAI'
        if service == "OpenAI" {
            let key = getApiKey()
            return key.isEmpty ? nil : key
        }
        return nil
    }
    // Helper methods
    private func getApiKey() -> String {
        // Retrieve securely from Keychain
        let key = "AppAPIKey" // Define a standard key name
        do {
            let data = try KeychainManager.retrieve(key: key)
            return String(data: data, encoding: .utf8) ?? ""
        } catch KeychainManager.KeychainError.itemNotFound {
            print("Error: API Key not found in Keychain for key '\(key)'. Ensure it's provisioned correctly.")
            // Handle missing key - returning empty might cause auth failure, which is intended.
            return ""
        } catch {
            print("Error retrieving API Key from Keychain: \(error)")
            return ""
        }
    }

    private func getSecretKey() -> String {
        // Retrieve securely from Keychain
        let key = "AppAPISecret" // Define a standard key name
        do {
            let data = try KeychainManager.retrieve(key: key)
            return String(data: data, encoding: .utf8) ?? ""
        } catch KeychainManager.KeychainError.itemNotFound {
            print("Error: API Secret not found in Keychain for key '\(key)'. Ensure it's provisioned correctly.")
            return ""
        } catch {
            print("Error retrieving API Secret from Keychain: \(error)")
            return ""
        }
    }

    private func getDeviceIdentifier() -> String {
        // Use a secure device identifier 
        // This implementation is simplified - normally you'd use Keychain
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    private func getAppVersion() -> String {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(versionNumber) (\(buildNumber))"
    }
    
    // Generate HMAC signature (simplified)
    private func generateHMAC(data: String, key: String) -> String {
        // This is a simplified implementation
        // In a real app, use CryptoKit's HMAC implementation
        return "generated-hmac-signature"
    }
}
