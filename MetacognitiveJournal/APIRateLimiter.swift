//
//  APIRateLimiter.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/17/25.
//


import Foundation

class APIRateLimiter {
    // Store last request timestamps by endpoint
    private var requestTimestamps: [String: [Date]] = [:]
    private let maxRequestsPerMinute: [String: Int] = [
        "login": 5,              // 5 login attempts per minute
        "password-reset": 2,     // 2 password reset requests per minute
        "user-profile": 30,      // 30 profile requests per minute
        "search": 60,            // 60 search requests per minute
        "default": 100           // Default rate limit
    ]
    
    // Clean old timestamps (older than 1 minute)
    private func cleanOldTimestamps() {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        
        for (endpoint, timestamps) in requestTimestamps {
            requestTimestamps[endpoint] = timestamps.filter { $0 > oneMinuteAgo }
        }
    }
    
    // Check if a request is allowed for the given endpoint
    func isRequestAllowed(for endpoint: String) -> Bool {
        cleanOldTimestamps()
        
        let timestamps = requestTimestamps[endpoint] ?? []
        let limit = maxRequestsPerMinute[endpoint] ?? maxRequestsPerMinute["default"]!
        
        return timestamps.count < limit
    }
    
    // Record a request for the given endpoint
    func recordRequest(for endpoint: String) {
        var timestamps = requestTimestamps[endpoint] ?? []
        timestamps.append(Date())
        requestTimestamps[endpoint] = timestamps
    }
}
