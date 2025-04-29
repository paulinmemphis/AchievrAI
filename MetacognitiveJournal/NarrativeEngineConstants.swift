import Foundation

/// Constants related to the Narrative Engine functionality
enum NarrativeEngineConstants {
    /// Base URL for the narrative engine API
    static let apiBaseURL = "http://localhost:3000"
    
    /// Available story genres
    static let genres = [
        "Fantasy": "Fantasy",
        "Sci-Fi": "Science Fiction",
        "Mystery": "Mystery",
        "Adventure": "Adventure",
        "Romance": "Romance",
        "Historical": "Historical Fiction",
        "Thriller": "Thriller",
        "Comedy": "Comedy",
        "Educational": "Educational",
        "Sports": "Sports"
    ]
    
    /// Default timeout for API requests
    static let defaultTimeout: TimeInterval = 30.0
    
    /// Maximum retry count for failed requests
    static let maxRetries = 3
    
    /// Cache duration in seconds (1 hour)
    static let cacheDuration: TimeInterval = 3600
    
    /// Maximum number of entries to queue offline
    static let maxOfflineQueueSize = 50
}

/// Extension to AppConstants to include narrative engine settings
extension AppConstants {
    /// Base URL for the API
    static var apiBaseURL: String {
        // First check if there's a debug override
        #if DEBUG
        if let debugURL = UserDefaults.standard.string(forKey: "debug_api_url") {
            return debugURL
        }
        #endif
        
        // Otherwise use the default
        return NarrativeEngineConstants.apiBaseURL
    }
    
    /// API key for authentication
    static var apiKey: String? {
        // In a real app, this would be stored securely in the keychain
        return UserDefaults.standard.string(forKey: "api_key")
    }
}
