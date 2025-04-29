//
//  DateFormatterCache.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//


import Foundation

// MARK: - Cache for Formatted Dates

class DateFormatterCache {
    static let shared = DateFormatterCache()
    
    private let formatter = DateFormatter()
    private var cache: [Date: String] = [:]
    private let dateFormat: String
    
    private init() {
        self.dateFormat = "MMM d, yyyy"
        formatter.dateFormat = dateFormat
    }
    
    func string(from date: Date) -> String {
        if let cached = cache[date] {
            return cached
        }
        
        let formatted = formatter.string(from: date)
        
        // Keep cache size reasonable
        if cache.count > 100 {
            cache.removeAll(keepingCapacity: true)
        }
        
        cache[date] = formatted
        return formatted
    }
    
    func clearCache() {
        cache.removeAll(keepingCapacity: true)
    }
}