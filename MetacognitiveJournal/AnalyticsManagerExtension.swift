import Foundation
import Combine

// MARK: - Journal Analytics Extension
extension AnalyticsManager {
    
    // MARK: - Journal Analytics Event Types
    
    /// Additional analytics event types specific to journaling
    enum JournalAnalyticsEventType: String, Codable {
        case journalEntryCreated = "journal_entry_created"
        case journalEntryEdited = "journal_entry_edited"
        case voiceJournalCompleted = "voice_journal_completed"
        case insightGenerated = "insight_generated"
        case topicExtracted = "topic_extracted"
        case sentimentAnalyzed = "sentiment_analyzed"
        case reflectionDepthAnalyzed = "reflection_depth_analyzed"
    }
    
    // MARK: - Journal Analytics Methods
    
    /// Tracks when a journal entry is created
    func trackJournalEntryCreation(entryId: String, wordCount: Int, promptCount: Int, tags: [String]) {
        let properties: [String: String] = [
            "entry_id": entryId,
            "word_count": "\(wordCount)",
            "prompt_count": "\(promptCount)",
            "tags": tags.joined(separator: ",")
        ]
        
        logEvent(.userInteraction, properties: properties.merging(["action": "journal_entry_created"]) { (_, new) in new })
    }
    
    /// Tracks when topics are extracted from journal entries
    func trackTopicExtraction(entryIds: [String], topicCount: Int, topTopics: [String]) {
        let properties: [String: String] = [
            "entry_ids": entryIds.joined(separator: ","),
            "topic_count": "\(topicCount)",
            "top_topics": topTopics.prefix(5).joined(separator: ",")
        ]
        
        logEvent(.userInteraction, properties: properties.merging(["action": "topic_extracted"]) { (_, new) in new })
    }
    
    /// Tracks when sentiment analysis is performed
    func trackSentimentAnalysis(entryIds: [String], averageSentiment: Double) {
        let properties: [String: String] = [
            "entry_ids": entryIds.joined(separator: ","),
            "average_sentiment": String(format: "%.2f", averageSentiment)
        ]
        
        logEvent(.userInteraction, properties: properties.merging(["action": "sentiment_analyzed"]) { (_, new) in new })
    }
    
    /// Tracks when reflection depth analysis is performed
    func trackReflectionDepthAnalysis(entryIds: [String], averageDepth: Double) {
        let properties: [String: String] = [
            "entry_ids": entryIds.joined(separator: ","),
            "average_depth": String(format: "%.2f", averageDepth)
        ]
        
        logEvent(.userInteraction, properties: properties.merging(["action": "reflection_depth_analyzed"]) { (_, new) in new })
    }
    
    // MARK: - Journal Analytics Insights
    
    /// Get the most common topics across all journal entries
    func getMostCommonTopics() -> [String: Int] {
        var topicCounts: [String: Int] = [:]
        
        // Filter for topic extraction events
        let topicEvents = events.filter { 
            $0.properties["action"] == "topic_extracted" 
        }
        
        // Count topic occurrences
        for event in topicEvents {
            if let topicsString = event.properties["top_topics"] {
                let topics = topicsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                
                for topic in topics {
                    topicCounts[topic, default: 0] += 1
                }
            }
        }
        
        return topicCounts
    }
    
    /// Get the sentiment trend over time
    func getSentimentTrend(timeframe: TimeInterval = 30 * 24 * 60 * 60) -> [(date: Date, sentiment: Double)] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = now.addingTimeInterval(-timeframe)
        
        // Filter for sentiment analysis events within the timeframe
        let sentimentEvents = events.filter { 
            $0.properties["action"] == "sentiment_analyzed" && 
            $0.timestamp >= startDate 
        }
        
        // Group by day
        var sentimentByDay: [Date: [Double]] = [:]
        
        for event in sentimentEvents {
            if let sentimentString = event.properties["average_sentiment"],
               let sentiment = Double(sentimentString) {
                
                // Get start of day for the timestamp
                let day = calendar.startOfDay(for: event.timestamp)
                
                // Add sentiment to the day's list
                sentimentByDay[day, default: []].append(sentiment)
            }
        }
        
        // Calculate average sentiment for each day
        var trend: [(date: Date, sentiment: Double)] = []
        
        for (day, sentiments) in sentimentByDay {
            let averageSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)
            trend.append((date: day, sentiment: averageSentiment))
        }
        
        // Sort by date
        return trend.sorted { $0.date < $1.date }
    }
}
