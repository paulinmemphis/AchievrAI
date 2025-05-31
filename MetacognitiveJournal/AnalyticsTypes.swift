// AnalyticsTypes.swift
// Contains enums shared by Analytics-related views
import Foundation

/// Time frames for filtering journal entries
public enum TimeFrame: String, CaseIterable, Identifiable, Codable {
    case week, month, year, all
    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .all: return "All"
        }
    }
}

/// Types of insights available in analytics
public enum InsightType: String, CaseIterable, Identifiable, Codable {
    case mood, topics, patterns, growth
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .mood: return "Mood"
        case .topics: return "Topics"
        case .patterns: return "Patterns"
        case .growth: return "Growth"
        }
    }
    public var icon: String {
        switch self {
        case .mood: return "face.smiling"
        case .topics: return "text.book.closed"
        case .patterns: return "waveform.path.ecg"
        case .growth: return "leaf"
        }
    }
}
