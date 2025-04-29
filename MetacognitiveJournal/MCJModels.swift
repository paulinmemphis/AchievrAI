// File: MCJModels.swift
// This file contains all model definitions for the MetacognitiveJournal app

import Foundation
import SwiftUI
import Combine

// MARK: - Insight Categories

/// Categories of insights to help organize and filter them
public enum InsightCategory: String, Codable, CaseIterable {
    case learning = "Learning"
    case challenge = "Challenge"
    case application = "Application"
    case connection = "Connection"
    case pattern = "Pattern"
    case growth = "Growth"
    case question = "Question"
    case subject = "Subject-Specific"
    case emotional = "Emotional"
    case metacognitive = "Metacognitive"
    case other = "Other"
}

// MARK: - Historical Insights

/// Represents an insight generated at a specific point in time for a journal entry
public struct HistoricalInsight: Identifiable, Codable, Hashable {
    /// Unique identifier for the insight
    public let id: UUID
    
    /// The date when this insight was generated
    public let timestamp: Date
    
    /// The actual insight text content
    public let content: String
    
    /// Category or type of insight
    public let category: InsightCategory
    
    /// Optional relevance score (0.0 to 1.0) indicating how important this insight is
    public let relevance: Double?
    
    /// Initialize a new historical insight
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - timestamp: When the insight was generated (defaults to current time)
    ///   - content: The insight text
    ///   - category: The category of insight
    ///   - relevance: Optional relevance score
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        content: String,
        category: InsightCategory,
        relevance: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.category = category
        self.relevance = relevance
    }
}

// MARK: - Learning Patterns

/// Represents a detected pattern across journal entries
public struct MCJLearningPattern: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: PatternType
    public let relevanceScore: Double // 0.0 to 1.0
    
    public enum PatternType: String, Codable, CaseIterable {
        case subject
        case emotional
        case theme
        case growth
        case diversity
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: PatternType,
        relevanceScore: Double
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.relevanceScore = relevanceScore
    }
}

// MARK: - Growth Metrics

/// Represents a metric measuring growth over time
public struct MCJGrowthMetric: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    public let value: Int // Can be positive or negative
    public let type: MetricType
    
    public enum MetricType: String, Codable, CaseIterable {
        case depth
        case consistency
        case diversity
        case emotionalGrowth
    }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        value: Int,
        type: MetricType
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.value = value
        self.type = type
    }
}

// MARK: - Insights

/// Represents a single insight from a journal entry
public struct Insight: Identifiable, Codable, Hashable {
    public let id: UUID
    public let content: String
    public let category: InsightCategory
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        content: String,
        category: InsightCategory,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.timestamp = timestamp
    }
}

// MARK: - Thread Safety Helpers

/// Extension to ensure publishers deliver values on the main thread
extension Publisher {
    public func receiveOnMain() -> AnyPublisher<Output, Failure> {
        return self
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - JournalEntry Extensions

/// Add Hashable conformance to JournalEntry
extension JournalEntry {
    public static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
