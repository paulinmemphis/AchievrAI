import Foundation
import SwiftUI
import Combine

// Using consolidated model definitions from MCJModels.swift

/// Manager for collecting and analyzing growth metrics from journal entries and app usage
class GrowthMetricsManager: ObservableObject {
    // MARK: - Published Properties
    @Published var metrics: [MCJGrowthMetric] = []
    @Published var journeyPoints: [JourneyPoint] = []
    @Published var milestones: [Milestone] = []
    
    // MARK: - Dependencies
    private let journalStore: JournalStore
    private let insightStreakManager: InsightStreakManager
    private let bodyAwarenessManager: BodyAwarenessManager
    private let gamificationManager: GamificationManager
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init(journalStore: JournalStore, insightStreakManager: InsightStreakManager, gamificationManager: GamificationManager) {
        self.journalStore = journalStore
        self.insightStreakManager = insightStreakManager
        self.bodyAwarenessManager = BodyAwarenessManager.shared
        self.gamificationManager = gamificationManager
        
        // Set up subscribers to update metrics when data changes
        setupSubscribers()
    }
    
    // MARK: - Public Methods
    
    /// Loads growth metrics based on the selected timeframe
    /// - Parameter timeframe: The timeframe to analyze
    func loadGrowthMetrics(for timeframe: Timeframe) {
        // Calculate metrics based on real data
        let consistencyMetric = calculateConsistencyMetric(for: timeframe)
        let emotionalAwarenessMetric = calculateEmotionalAwarenessMetric(for: timeframe)
        let narrativeDepthMetric = calculateNarrativeDepthMetric(for: timeframe)
        let reflectionQualityMetric = calculateReflectionQualityMetric(for: timeframe)
        
        // Update the metrics array
        metrics = [
            consistencyMetric,
            emotionalAwarenessMetric,
            narrativeDepthMetric,
            reflectionQualityMetric
        ]
        
        // Update journey points and milestones
        updateJourneyPoints()
        updateMilestones()
    }
    
    /// Generates insights for a specific metric
    /// - Parameter metric: The metric to generate insights for
    /// - Returns: Array of insight strings
    func generateInsights(for metric: MCJGrowthMetric) -> [String] {
        switch metric.type {
        case .consistency:
            return generateConsistencyInsights(metric)
        case .emotionalGrowth:
            return generateEmotionalAwarenessInsights(metric)
        case .depth:
            return generateNarrativeDepthInsights(metric)
        case .diversity:
            return generateReflectionQualityInsights(metric)
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up subscribers to update metrics when data changes
    private func setupSubscribers() {
        // Subscribe to journal store changes
        journalStore.$entries
            .sink { [weak self] _ in
                self?.loadGrowthMetrics(for: .month)
            }
            .store(in: &cancellables)
        
        // Subscribe to streak changes
        insightStreakManager.$currentStreak
            .sink { [weak self] _ in
                self?.updateJourneyPoints()
                self?.updateMilestones()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Metric Calculations
    
    /// Calculates the consistency metric
    private func calculateConsistencyMetric(for timeframe: Timeframe) -> MCJGrowthMetric {
        let entries = journalStore.entries
        let historicalValues = calculateHistoricalConsistencyValues(for: timeframe)
        let currentValue = historicalValues.last ?? 0
        let previousValue = historicalValues.count > 1 ? historicalValues[historicalValues.count - 2] : 0
        let trend = previousValue > 0 ? (currentValue - previousValue) / previousValue : 0
        
        return MCJGrowthMetric(
            id: UUID(),
            title: "Consistency",
            description: "Percentage of days with journal entries",
            value: Int(currentValue),
            type: .consistency
        )
    }
    
    /// Calculates the emotional awareness metric
    private func calculateEmotionalAwarenessMetric(for timeframe: Timeframe) -> MCJGrowthMetric {
        let checkIns = bodyAwarenessManager.checkIns
        let historicalValues = calculateHistoricalEmotionalAwarenessValues(for: timeframe)
        let currentValue = historicalValues.last ?? 0
        let previousValue = historicalValues.count > 1 ? historicalValues[historicalValues.count - 2] : 0
        let trend = previousValue > 0 ? (currentValue - previousValue) / previousValue : 0
        
        return MCJGrowthMetric(
            id: UUID(),
            title: "Emotional Awareness",
            description: "Recognition of emotional patterns",
            value: Int(currentValue),
            type: .emotionalGrowth
        )
    }
    
    /// Calculates the narrative depth metric
    private func calculateNarrativeDepthMetric(for timeframe: Timeframe) -> MCJGrowthMetric {
        // This would ideally use data from the narrative engine
        let historicalValues = calculateHistoricalNarrativeDepthValues(for: timeframe)
        let currentValue = historicalValues.last ?? 0
        let previousValue = historicalValues.count > 1 ? historicalValues[historicalValues.count - 2] : 0
        let trend = previousValue > 0 ? (currentValue - previousValue) / previousValue : 0
        
        return MCJGrowthMetric(
            id: UUID(),
            title: "Narrative Depth",
            description: "Richness of your personal story",
            value: Int(currentValue),
            type: .depth
        )
    }
    
    /// Calculates the reflection quality metric
    private func calculateReflectionQualityMetric(for timeframe: Timeframe) -> MCJGrowthMetric {
        // This would ideally use data from the metacognitive analyzer
        let historicalValues = calculateHistoricalReflectionQualityValues(for: timeframe)
        let currentValue = historicalValues.last ?? 0
        let previousValue = historicalValues.count > 1 ? historicalValues[historicalValues.count - 2] : 0
        let trend = previousValue > 0 ? (currentValue - previousValue) / previousValue : 0
        
        return MCJGrowthMetric(
            id: UUID(),
            title: "Reflection Quality",
            description: "Depth of self-reflection insights",
            value: Int(currentValue),
            type: .diversity
        )
    }
    
    // MARK: - Historical Value Calculations
    
    /// Calculates historical consistency values
    private func calculateHistoricalConsistencyValues(for timeframe: Timeframe) -> [Double] {
        let entries = journalStore.entries
        
        // Get the date range based on timeframe
        let (startDate, endDate, divisions) = getDateRange(for: timeframe)
        
        // Calculate consistency for each division
        var values: [Double] = []
        
        for i in 0..<divisions {
            let divisionStart = Calendar.current.date(byAdding: getDateComponent(for: timeframe), value: i, to: startDate)!
            let divisionEnd = i < divisions - 1 
                ? Calendar.current.date(byAdding: getDateComponent(for: timeframe), value: i + 1, to: startDate)!
                : endDate
            
            let divisionEntries = entries.filter { entry in
                entry.date >= divisionStart && entry.date < divisionEnd
            }
            
            // Calculate the percentage of days with entries
            let totalDays = Calendar.current.dateComponents([.day], from: divisionStart, to: divisionEnd).day ?? 1
            let daysWithEntries = Set(divisionEntries.map { Calendar.current.startOfDay(for: $0.date) }).count
            let percentage = min(100, Double(daysWithEntries) / Double(totalDays) * 100)
            
            values.append(percentage)
        }
        
        return values
    }
    
    /// Calculates historical emotional awareness values
    private func calculateHistoricalEmotionalAwarenessValues(for timeframe: Timeframe) -> [Double] {
        let checkIns = bodyAwarenessManager.checkIns
        
        // Get the date range based on timeframe
        let (startDate, endDate, divisions) = getDateRange(for: timeframe)
        
        // Calculate emotional awareness for each division
        var values: [Double] = []
        
        for i in 0..<divisions {
            let divisionStart = Calendar.current.date(byAdding: getDateComponent(for: timeframe), value: i, to: startDate)!
            let divisionEnd = i < divisions - 1 
                ? Calendar.current.date(byAdding: getDateComponent(for: timeframe), value: i + 1, to: startDate)!
                : endDate
            
            let divisionCheckIns = checkIns.filter { checkIn in
                checkIn.date >= divisionStart && checkIn.date < divisionEnd
            }
            
            // Calculate a score based on number of check-ins and variety of emotions
            let checkInCount = divisionCheckIns.count
            let emotionVariety = Set(divisionCheckIns.map { $0.emotion }).count
            
            // Simple formula: base score + bonus for variety
            let baseScore = min(70, Double(checkInCount) * 10)
            let varietyBonus = min(30, Double(emotionVariety) * 5)
            
            values.append(baseScore + varietyBonus)
        }
        
        // If no data, provide some starter values
        if values.isEmpty {
            values = [40, 45, 50, 55, 60, 65]
        }
        
        return values
    }
    
    /// Calculates historical narrative depth values
    private func calculateHistoricalNarrativeDepthValues(for timeframe: Timeframe) -> [Double] {
        // This would ideally use data from the narrative engine
        // For now, we'll use a combination of entry length and word variety
        
        let entries = journalStore.entries
        
        // Get the date range based on timeframe
        let (startDate, endDate, divisions) = getDateRange(for: timeframe)
        
        // Calculate narrative depth for each division
        var values: [Double] = []
        
        for i in 0..<divisions {
            let divisionStart = Calendar.current.date(byAdding: getDateComponent(for: timeframe), value: i, to: startDate)!
            let divisionEnd = i < divisions - 1 
                ? Calendar.current.date(byAdding: getDateComponent(for: timeframe), value: i + 1, to: startDate)!
                : endDate
            
            let divisionEntries = entries.filter { entry in
                entry.date >= divisionStart && entry.date < divisionEnd
            }
            
            // Calculate average entry length and word variety
            let totalWords = divisionEntries.reduce(0) { $0 + $1.content.split(separator: " ").count }
            let averageWords = divisionEntries.isEmpty ? 0 : Double(totalWords) / Double(divisionEntries.count)
            
            // Simple formula: score based on average words
            let score = min(100, averageWords / 2)
            
            values.append(score)
        }
        
        // If no data, provide some starter values
        if values.isEmpty {
            values = [40, 48, 55, 62, 70, 78]
        }
        
        return values
    }
    
    /// Calculates historical reflection quality values
    private func calculateHistoricalReflectionQualityValues(for timeframe: Timeframe) -> [Double] {
        // This would ideally use data from the metacognitive analyzer
        // For now, we'll use a combination of entry frequency and streak data
        
        // Get the date range based on timeframe
        let (startDate, endDate, divisions) = getDateRange(for: timeframe)
        
        // Calculate reflection quality for each division
        var values: [Double] = []
        
        for i in 0..<divisions {
            // For now, use a formula based on streak and points
            let streakValue = Double(insightStreakManager.currentStreak) * 2
            let pointsValue = Double(gamificationManager.points) / 100
            
            // Combine with some randomness for variation
            let baseValue = min(85, streakValue + pointsValue)
            let randomVariation = Double.random(in: -5...5)
            
            values.append(max(0, min(100, baseValue + randomVariation)))
        }
        
        // If no data, provide some starter values
        if values.isEmpty {
            values = [75, 80, 82, 85, 88, 90]
        }
        
        return values
    }
    
    // MARK: - Journey Points and Milestones
    
    /// Updates the journey points based on user progress
    private func updateJourneyPoints() {
        let entries = journalStore.entries
        let firstEntryDate = entries.sorted(by: { $0.date < $1.date }).first?.date
        
        // Create journey points based on actual user progress
        var points: [JourneyPoint] = []
        
        // First Journal Entry
        points.append(
            JourneyPoint(
                id: "first_entry",
                index: 1,
                title: "First Journal Entry",
                completed: !entries.isEmpty,
                dateCompleted: firstEntryDate
            )
        )
        
        // First Story Chapter
        let hasStoryChapter = userDefaults.bool(forKey: "hasGeneratedStoryChapter")
        let storyChapterDate = Date(timeIntervalSince1970: userDefaults.double(forKey: "firstStoryChapterDate"))
        
        points.append(
            JourneyPoint(
                id: "first_story",
                index: 2,
                title: "First Story Chapter",
                completed: hasStoryChapter,
                dateCompleted: hasStoryChapter ? storyChapterDate : nil
            )
        )
        
        // 7-Day Streak
        let has7DayStreak = insightStreakManager.longestStreak >= 7
        let streak7Date = Date(timeIntervalSince1970: userDefaults.double(forKey: "streak7Date"))
        
        points.append(
            JourneyPoint(
                id: "week_streak",
                index: 3,
                title: "7-Day Streak",
                completed: has7DayStreak,
                dateCompleted: has7DayStreak ? streak7Date : nil
            )
        )
        
        // First Major Insight
        let hasInsight = userDefaults.bool(forKey: "hasReceivedInsight")
        let insightDate = Date(timeIntervalSince1970: userDefaults.double(forKey: "firstInsightDate"))
        
        points.append(
            JourneyPoint(
                id: "first_insight",
                index: 4,
                title: "First Major Insight",
                completed: hasInsight,
                dateCompleted: hasInsight ? insightDate : nil
            )
        )
        
        // 30-Day Streak
        let has30DayStreak = insightStreakManager.longestStreak >= 30
        let streak30Date = Date(timeIntervalSince1970: userDefaults.double(forKey: "streak30Date"))
        
        points.append(
            JourneyPoint(
                id: "month_streak",
                index: 5,
                title: "30-Day Streak",
                completed: has30DayStreak,
                dateCompleted: has30DayStreak ? streak30Date : nil
            )
        )
        
        // Narrative Mastery (10+ story chapters)
        let storyChapterCount = userDefaults.integer(forKey: "storyChapterCount")
        let hasNarrativeMastery = storyChapterCount >= 10
        let narrativeMasteryDate = Date(timeIntervalSince1970: userDefaults.double(forKey: "narrativeMasteryDate"))
        
        points.append(
            JourneyPoint(
                id: "narrative_mastery",
                index: 6,
                title: "Narrative Mastery",
                completed: hasNarrativeMastery,
                dateCompleted: hasNarrativeMastery ? narrativeMasteryDate : nil
            )
        )
        
        journeyPoints = points
    }
    
    /// Updates the milestones based on user progress
    private func updateMilestones() {
        var updatedMilestones: [Milestone] = []
        
        // Consistent Writer (7-day streak)
        let has7DayStreak = insightStreakManager.longestStreak >= 7
        let streak7Date = Date(timeIntervalSince1970: userDefaults.double(forKey: "streak7Date"))
        
        updatedMilestones.append(
            Milestone(
                id: "consistent_writer",
                title: "Consistent Writer",
                description: "Maintained a 7-day journaling streak, building a solid foundation for your growth journey.",
                iconName: "pencil.circle.fill",
                achieved: has7DayStreak,
                dateAchieved: has7DayStreak ? streak7Date : nil,
                progress: min(7, insightStreakManager.currentStreak),
                total: 7,
                color: .blue
            )
        )
        
        // Story Weaver (10 story chapters)
        let storyChapterCount = userDefaults.integer(forKey: "storyChapterCount")
        let hasStoryWeaver = storyChapterCount >= 10
        let storyWeaverDate = Date(timeIntervalSince1970: userDefaults.double(forKey: "storyWeaverDate"))
        
        updatedMilestones.append(
            Milestone(
                id: "story_weaver",
                title: "Story Weaver",
                description: "Generated 10 personalized story chapters from your journal entries.",
                iconName: "book.fill",
                achieved: hasStoryWeaver,
                dateAchieved: hasStoryWeaver ? storyWeaverDate : nil,
                progress: min(10, storyChapterCount),
                total: 10,
                color: .purple
            )
        )
        
        // Emotional Explorer (15 body awareness check-ins)
        let checkInCount = bodyAwarenessManager.totalCheckIns
        let hasEmotionalExplorer = checkInCount >= 15
        let emotionalExplorerDate = Date(timeIntervalSince1970: userDefaults.double(forKey: "emotionalExplorerDate"))
        
        updatedMilestones.append(
            Milestone(
                id: "emotional_explorer",
                title: "Emotional Explorer",
                description: "Completed 15 body awareness check-ins, strengthening your emotional regulation skills.",
                iconName: "heart.fill",
                achieved: hasEmotionalExplorer,
                dateAchieved: hasEmotionalExplorer ? emotionalExplorerDate : nil,
                progress: min(15, checkInCount),
                total: 15,
                color: .red
            )
        )
        
        // Insight Master (20 insights)
        let insightCount = userDefaults.integer(forKey: "totalInsightsGenerated")
        let hasInsightMaster = insightCount >= 20
        let insightMasterDate = Date(timeIntervalSince1970: userDefaults.double(forKey: "insightMasterDate"))
        
        updatedMilestones.append(
            Milestone(
                id: "insight_master",
                title: "Insight Master",
                description: "Unlocked 20 personalized insights that reveal patterns in your thinking and behavior.",
                iconName: "lightbulb.fill",
                achieved: hasInsightMaster,
                dateAchieved: hasInsightMaster ? insightMasterDate : nil,
                progress: min(20, insightCount),
                total: 20,
                color: .yellow
            )
        )
        
        milestones = updatedMilestones
    }
    
    // MARK: - Insight Generation
    
    /// Generates insights for the consistency metric
    private func generateConsistencyInsights(_ metric: MCJGrowthMetric) -> [String] {
        let entries = journalStore.entries
        
        // No entries yet
        if entries.isEmpty {
            return ["Start journaling regularly to see consistency insights."]
        }
        
        var insights: [String] = []
        
        // Trend-based insight
        if metric.trend > 0.1 {
            insights.append("Your consistency has improved by \(Int(metric.trend * 100))% compared to last period.")
        } else if metric.trend < -0.1 {
            insights.append("Your consistency has decreased by \(Int(abs(metric.trend) * 100))% compared to last period.")
        } else {
            insights.append("Your consistency has remained stable compared to last period.")
        }
        
        // Time-based insight
        let entriesByHour = Dictionary(grouping: entries) { entry in
            Calendar.current.component(.hour, from: entry.date)
        }
        
        if let mostCommonHour = entriesByHour.max(by: { $0.value.count < $1.value.count })?.key {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "ha"
            let date = Calendar.current.date(bySettingHour: mostCommonHour, minute: 0, second: 0, of: Date())!
            insights.append("You tend to journal most often around \(timeFormatter.string(from: date).lowercased()).")
        }
        
        // Streak-based insight
        if insightStreakManager.currentStreak > 0 {
            insights.append("Your current journaling streak is \(insightStreakManager.currentStreak) days. Keep it going!")
        }
        
        return insights
    }
    
    /// Generates insights for the emotional awareness metric
    private func generateEmotionalAwarenessInsights(_ metric: MCJGrowthMetric) -> [String] {
        let checkIns = bodyAwarenessManager.checkIns
        
        // No check-ins yet
        if checkIns.isEmpty {
            return ["Complete body awareness check-ins to see emotional awareness insights."]
        }
        
        var insights: [String] = []
        
        // Trend-based insight
        if metric.trend > 0.05 {
            insights.append("You're getting better at identifying nuanced emotions.")
        }
        
        // Emotion frequency insight
        let emotionCounts = Dictionary(grouping: checkIns) { $0.emotion }.mapValues { $0.count }
        if let mostCommonEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key {
            insights.append("'\(mostCommonEmotion.capitalized)' is your most frequently recorded emotion.")
        }
        
        // Body awareness insight
        let bodyAreaCounts = checkIns.flatMap { $0.bodyAreas }.reduce(into: [String: Int]()) { counts, area in
            counts[area, default: 0] += 1
        }
        
        if let mostCommonArea = bodyAreaCounts.max(by: { $0.value < $1.value })?.key {
            insights.append("You most often feel emotions in your \(mostCommonArea.lowercased()).")
        }
        
        return insights
    }
    
    /// Generates insights for the narrative depth metric
    private func generateNarrativeDepthInsights(_ metric: MCJGrowthMetric) -> [String] {
        let entries = journalStore.entries
        let storyChapterCount = userDefaults.integer(forKey: "storyChapterCount")
        
        // No entries or chapters yet
        if entries.isEmpty || storyChapterCount == 0 {
            return ["Create more journal entries and story chapters to see narrative depth insights."]
        }
        
        var insights: [String] = []
        
        // Trend-based insight
        if metric.trend > 0.1 {
            insights.append("Your story chapters are becoming significantly more detailed.")
        }
        
        // Entry length insight
        let averageWordCount = entries.reduce(0) { $0 + $1.content.split(separator: " ").count } / max(1, entries.count)
        if averageWordCount > 200 {
            insights.append("Your journal entries are quite detailed, averaging \(averageWordCount) words.")
        } else if averageWordCount > 100 {
            insights.append("Your journal entries have a good level of detail, averaging \(averageWordCount) words.")
        } else {
            insights.append("Consider adding more detail to your journal entries to enrich your narrative.")
        }
        
        // Story chapter insight
        if storyChapterCount > 0 {
            insights.append("You've generated \(storyChapterCount) story chapters from your journal entries.")
        }
        
        return insights
    }
    
    /// Generates insights for the reflection quality metric
    private func generateReflectionQualityInsights(_ metric: MCJGrowthMetric) -> [String] {
        let entries = journalStore.entries
        let insightCount = userDefaults.integer(forKey: "totalInsightsGenerated")
        
        // No entries or insights yet
        if entries.isEmpty || insightCount == 0 {
            return ["Create more journal entries to see reflection quality insights."]
        }
        
        var insights: [String] = []
        
        // Trend-based insight
        if metric.trend > 0.05 {
            insights.append("Your reflections show deeper metacognitive thinking.")
        }
        
        // Insight count insight
        if insightCount > 0 {
            insights.append("You've received \(insightCount) personalized insights from your journal entries.")
        }
        
        // Question mark insight (rough proxy for reflective questions)
        let questionCount = entries.reduce(0) { $0 + $1.content.components(separatedBy: "?").count - 1 }
        if questionCount > 10 {
            insights.append("You ask yourself thoughtful questions in your journal, which deepens reflection.")
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    /// Gets the date range for a timeframe
    private func getDateRange(for timeframe: Timeframe) -> (startDate: Date, endDate: Date, divisions: Int) {
        let endDate = Date()
        var startDate: Date
        var divisions: Int
        
        switch timeframe {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            divisions = 7
        case .month:
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
            divisions = 4
        case .year:
            startDate = Calendar.current.date(byAdding: .month, value: -12, to: endDate)!
            divisions = 6
        case .allTime:
            startDate = Calendar.current.date(byAdding: .year, value: -3, to: endDate)!
            divisions = 6
        }
        
        return (startDate, endDate, divisions)
    }
    
    /// Gets the date component for a timeframe
    private func getDateComponent(for timeframe: Timeframe) -> Calendar.Component {
        switch timeframe {
        case .week:
            return .day
        case .month:
            return .weekOfMonth
        case .year:
            return .month
        case .allTime:
            return .year
        }
    }
}
