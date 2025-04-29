// File: InsightAnalyzer.swift
import Foundation
import Combine

/// Analyzes journal entries to extract cumulative insights and learning patterns
@MainActor
class InsightAnalyzer: ObservableObject {
    // MARK: - Published Properties
    
    /// Loading state
    @Published var isAnalyzing: Bool = false
    
    /// Error state
    @Published var analyzerError: Error?
    
    /// Learning patterns identified across journal entries
    @Published var learningPatterns: [MCJLearningPattern] = []
    
    /// Growth metrics calculated from journal entries
    @Published var growthMetrics: [MCJGrowthMetric] = []
    
    // MARK: - Dependencies
    private let journalStore: JournalStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(journalStore: JournalStore) {
        self.journalStore = journalStore
    }
    
    // MARK: - Public Methods
    
    /// Analyzes all journal entries to identify learning patterns and growth metrics
    func analyzePatterns() async {
        isAnalyzing = true
        analyzerError = nil
        
        // In a real implementation, this would analyze patterns across entries
        // For now, we'll create some sample patterns and metrics
        
        // Sample learning patterns
        let samplePatterns = [
            MCJLearningPattern(
                title: "Consistent Reflection",
                description: "You tend to reflect more deeply when in a calm emotional state.",
                type: .emotional,
                relevanceScore: 0.85
            ),
            MCJLearningPattern(
                title: "Subject Connections",
                description: "You frequently make connections between different subjects in your journal entries.",
                type: .subject,
                relevanceScore: 0.75
            )
        ]
        
        // Sample growth metrics
        let sampleMetrics = [
            MCJGrowthMetric(
                title: "Reflection Depth",
                description: "Your reflection depth has increased over time.",
                value: 3,
                type: .depth
            ),
            MCJGrowthMetric(
                title: "Subject Diversity",
                description: "You've expanded the range of subjects you reflect on.",
                value: 2,
                type: .diversity
            )
        ]
        
        // Simulate some processing time
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update the published properties on the main thread
        self.learningPatterns = samplePatterns
        self.growthMetrics = sampleMetrics
        self.isAnalyzing = false
    }
    
    /// Generates cumulative insights for a specific journal entry based on historical data
    /// - Parameter entry: The journal entry to generate insights for
    /// - Returns: An array of historical insights
    func generateCumulativeInsights(for entry: JournalEntry) async -> [HistoricalInsight] {
        var insights: [HistoricalInsight] = []
        
        // Get previous entries for the same subject
        let previousEntries = journalStore.entries
            .filter { $0.subject == entry.subject && $0.date < entry.date }
            .sorted(by: { $0.date < $1.date })
        
        // If this is the first entry for this subject, return basic insights
        if previousEntries.isEmpty {
            insights.append(HistoricalInsight(
                content: "This is your first entry about \(entry.subject.rawValue). Keep reflecting to build your knowledge in this area.",
                category: .subject
            ))
            return insights
        }
        
        // Add subject progression insight
        insights.append(HistoricalInsight(
            content: "This is your \(previousEntries.count + 1)th entry about \(entry.subject.rawValue). You're building a consistent practice of reflection in this subject.",
            category: .subject,
            relevance: 0.8
        ))
        
        // Look for emotional state patterns
        let emotionalStates = previousEntries.map { $0.emotionalState }
        if let mostCommonState = findMostCommon(in: emotionalStates),
           mostCommonState != entry.emotionalState {
            insights.append(HistoricalInsight(
                content: "Your emotional state has shifted from your typical \(mostCommonState.rawValue.lowercased()) to \(entry.emotionalState.rawValue.lowercased()). This change may offer new perspectives on the subject.",
                category: .emotional,
                relevance: 0.9
            ))
        }
        
        // Add growth insight if we have enough entries
        if previousEntries.count >= 3 {
            insights.append(HistoricalInsight(
                content: "Your reflections in \(entry.subject.rawValue) have evolved from initial exploration to deeper analysis. Continue building on this foundation.",
                category: .growth,
                relevance: 0.75
            ))
        }
        
        return insights
    }
    
    // MARK: - Private Methods
    
    /// Analyzes patterns in subjects across entries
    private func analyzeSubjectPatterns(entries: [JournalEntry]) -> [MCJLearningPattern] {
        var patterns: [MCJLearningPattern] = []
        
        // Count entries by subject
        let subjectCounts = Dictionary(grouping: entries, by: { $0.subject })
            .mapValues { $0.count }
            .sorted(by: { $0.value > $1.value })
        
        // Add pattern for most common subject
        if let mostCommonSubject = subjectCounts.first {
            patterns.append(MCJLearningPattern(
                id: UUID(),
                title: "Frequent Subject",
                description: "You've created \(mostCommonSubject.value) entries about \(mostCommonSubject.key.rawValue), making it your most common subject.",
                type: .subject,
                relevanceScore: 0.9
            ))
        }
        
        // Add pattern for subject diversity
        if subjectCounts.count > 1 {
            patterns.append(MCJLearningPattern(
                id: UUID(),
                title: "Subject Diversity",
                description: "You've reflected on \(subjectCounts.count) different subjects, with varying levels of engagement.",
                type: .diversity,
                relevanceScore: 0.7
            ))
        }
        
        return patterns
    }
    
    /// Analyzes patterns in emotional states across entries
    private func analyzeEmotionalPatterns(entries: [JournalEntry]) -> [MCJLearningPattern] {
        var patterns: [MCJLearningPattern] = []
        
        // Group entries by emotional state
        let emotionalCounts = Dictionary(grouping: entries, by: { $0.emotionalState })
            .mapValues { $0.count }
            .sorted(by: { $0.value > $1.value })
        
        // Add pattern for most common emotional state
        if let mostCommonEmotion = emotionalCounts.first {
            patterns.append(MCJLearningPattern(
                id: UUID(),
                title: "Emotional Trend",
                description: "You most frequently feel \(mostCommonEmotion.key.rawValue.lowercased()) when reflecting on your learning (\(mostCommonEmotion.value) entries).",
                type: .emotional,
                relevanceScore: 0.8
            ))
        }
        
        // Check for emotional growth over time
        if entries.count >= 6 {
            let sortedEntries = entries.sorted(by: { $0.date < $1.date })
            let midpoint = sortedEntries.count / 2
            let olderEntries = Array(sortedEntries[0..<midpoint])
            let recentEntries = Array(sortedEntries[midpoint...])
            
            let olderEmotions = olderEntries.map { $0.emotionalState }
            let recentEmotions = recentEntries.map { $0.emotionalState }
            
            let positiveEmotions: Set<EmotionalState> = [.confident, .satisfied, .curious]
            
            let olderPositiveCount = olderEmotions.filter { positiveEmotions.contains($0) }.count
            let recentPositiveCount = recentEmotions.filter { positiveEmotions.contains($0) }.count
            
            let recentPositiveRatio = Double(recentPositiveCount) / Double(recentEmotions.count)
            let olderPositiveRatio = Double(olderPositiveCount) / Double(olderEmotions.count)
            
            if recentPositiveRatio > olderPositiveRatio + 0.2 {
                patterns.append(MCJLearningPattern(
                    id: UUID(),
                    title: "Emotional Growth",
                    description: "Your recent entries show more positive emotional states compared to earlier entries, suggesting growing confidence in your learning.",
                    type: .growth,
                    relevanceScore: 0.85
                ))
            }
        }
        
        return patterns
    }
    
    /// Analyzes recurring themes across entries
    private func analyzeRecurringThemes(entries: [JournalEntry]) async -> [MCJLearningPattern] {
        var patterns: [MCJLearningPattern] = []
        
        // Extract themes from entries
        if let themes = await findRecurringThemes(in: entries), !themes.isEmpty {
            patterns.append(MCJLearningPattern(
                id: UUID(),
                title: "Recurring Themes",
                description: "You consistently reflect on \(themes.joined(separator: ", ")) across your journal entries.",
                type: .theme,
                relevanceScore: 0.75
            ))
        }
        
        return patterns
    }
    
    /// Calculates growth metrics based on journal entries
    private func calculateGrowthMetrics(entries: [JournalEntry]) -> [MCJGrowthMetric] {
        var metrics: [MCJGrowthMetric] = []
        
        // Skip if not enough entries
        if entries.count < 3 {
            return metrics
        }
        
        // Calculate reflection depth
        let averagePromptLength = entries
            .flatMap { $0.reflectionPrompts }
            .compactMap { $0.response }
            .map { $0.count }
            .reduce(0, +) / max(1, entries.flatMap { $0.reflectionPrompts }.count)
        
        let depthScore = min(5, max(1, averagePromptLength / 100))
        metrics.append(MCJGrowthMetric(
            id: UUID(),
            title: "Reflection Depth",
            description: "Your average reflection length indicates \(depthScore > 3 ? "deep" : "developing") engagement with the material.",
            value: depthScore,
            type: .depth
        ))
        
        // Calculate consistency
        let sortedEntries = entries.sorted(by: { $0.date < $1.date })
        if sortedEntries.count >= 2 {
            let dateIntervals = zip(sortedEntries, sortedEntries.dropFirst()).map { 
                Calendar.current.dateComponents([.day], from: $0.date, to: $1.date).day ?? 0 
            }
            let averageInterval = dateIntervals.reduce(0, +) / max(1, dateIntervals.count)
            
            let consistencyScore = min(5, max(1, 8 - averageInterval))
            metrics.append(MCJGrowthMetric(
                id: UUID(),
                title: "Reflection Consistency",
                description: "You reflect approximately every \(averageInterval) days, showing \(consistencyScore > 3 ? "strong" : "developing") consistency.",
                value: consistencyScore,
                type: .consistency
            ))
        }
        
        return metrics
    }
    
    /// Finds the most common element in an array
    private func findMostCommon<T: Hashable>(in array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Finds recurring themes across journal entries
    private func findRecurringThemes(in entries: [JournalEntry]) async -> [String]? {
        // Extract all text from entries
        let text = entries
            .flatMap { entry in
                entry.reflectionPrompts.compactMap { $0.response }
            }
            .joined(separator: " ")
            .lowercased()
        
        // Simple word frequency analysis
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 4 } // Only consider words with 5+ characters
        
        // Count word frequencies
        var wordCounts: [String: Int] = [:]
        for word in words {
            wordCounts[word, default: 0] += 1
        }
        
        // Filter to words that appear multiple times
        let commonWords = wordCounts
            .filter { $0.value >= 3 } // Word appears at least 3 times
            .sorted { $0.value > $1.value }
            .prefix(5) // Take top 5 most common words
            .map { $0.key }
        
        return commonWords.isEmpty ? nil : Array(commonWords)
    }
}
