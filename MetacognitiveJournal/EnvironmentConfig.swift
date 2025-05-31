import Foundation

/// Manages environment configuration settings
struct EnvironmentConfig {
    /// The environment (production, development, etc.)
    enum Environment: String {
        case development
        case staging
        case production
        
        /// The current environment based on build configuration
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            // Check for a manually set environment override first
            if let envOverride = UserDefaults.standard.string(forKey: "environment_override"),
               let env = Environment(rawValue: envOverride) {
                return env
            }
            
            // Default to production for release builds
            return .production
            #endif
        }
    }
    
    /// The base URL for API calls
    static var apiBaseURL: String {
        switch Environment.current {
        case .development:
            return "http://localhost:3000"
        case .staging:
            return "https://staging-api.achievrai.com"
        case .production:
            return "https://api.achievrai.com"
        }
    }
    
    /// Debug mode
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "enable_debug_mode")
        #endif
    }
    
    /// Maximum offline queue size
    static var maxOfflineQueueSize: Int {
        return UserDefaults.standard.integer(forKey: "max_offline_queue_size") > 0 ?
            UserDefaults.standard.integer(forKey: "max_offline_queue_size") : 50
    }
    
    /// API request timeout
    static var apiRequestTimeout: TimeInterval {
        return UserDefaults.standard.double(forKey: "api_request_timeout") > 0 ?
            UserDefaults.standard.double(forKey: "api_request_timeout") : 30.0
    }
    
    /// Whether to use secure storage
    static var useSecureStorage: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "use_secure_storage")
        #else
        return true
        #endif
    }
    
    /// Enforce TLS certificate validation
    static var enforceTLS: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "enforce_tls")
        #else
        return true
        #endif
    }
    
    /// Initialize default settings
    static func setupDefaults() {
        // Only set defaults if they haven't been set before
        let defaults = UserDefaults.standard
        
        let defaultSettings: [String: Any] = [
            "api_request_timeout": 30.0,
            "max_offline_queue_size": 50,
            "enable_debug_mode": false,
            "use_secure_storage": true,
            "enforce_tls": true
        ]
        
        for (key, value) in defaultSettings {
            if defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
    }
}

/// App-wide error types
enum AppError: Error {
    case networkError(Error)
    case serializationFailed
    case apiError(String)
    case persistenceError(String)
    case invalidURL
    case unauthorized
    case notFound
    case serverError
    case offlineMode
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serializationFailed:
            return "Failed to process data"
        case .apiError(let message):
            return "API error: \(message)"
        case .persistenceError(let message):
            return "Storage error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Authentication required"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .offlineMode:
            return "You're offline"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
