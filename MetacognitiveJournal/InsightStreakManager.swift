import Foundation
import Combine

// Using consolidated model definitions from MCJModels.swift

/// Manages user's insight streaks and rewards
class InsightStreakManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalInsights: Int = 0
    @Published var lastInsightDate: Date?
    @Published var recentInsights: [Insight] = []
    @Published var showRewardAnimation: Bool = false
    @Published var rewardType: RewardType = .basic
    
    // MARK: - Private Properties
    private let persistenceManager = StoryPersistenceManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let streakKey = "insight_current_streak"
        static let longestStreakKey = "insight_longest_streak"
        static let totalInsightsKey = "insight_total_count"
        static let lastInsightDateKey = "insight_last_date"
        static let recentInsightsKey = "recent_insights"
        static let streakBreakDays = 2 // Consider streak broken after 2 days
    }
    
    // MARK: - Initialization
    init() {
        loadStreakData()
        checkStreakStatus()
    }
    
    // MARK: - Public Methods
    
    /// Records a new insight generated from a journal entry
    /// - Parameters:
    ///   - text: The insight text
    ///   - category: The category of insight
    ///   - entryId: The ID of the source journal entry
    func recordInsight(text: String, category: InsightCategory, entryId: String) {
        // Create a new insight
        let insight = Insight(
            id: UUID(),
            content: text,
            category: category,
            timestamp: Date()
        )
        
        // Call the overload that accepts an Insight
        recordInsight(insight: insight)
    }
    
    /// Overload to record an insight directly from an Insight object
    /// - Parameter insight: The Insight object containing the details
    func recordInsight(insight: Insight) {
        // Add to recent insights
        recentInsights.insert(insight, at: 0)
        if recentInsights.count > 10 {
            recentInsights.removeLast()
        }
        
        // Update counters
        totalInsights += 1
        lastInsightDate = Date()
        
        // Check if we need to update the streak
        let currentDate = Calendar.current.startOfDay(for: Date())
        if let lastDate = lastInsightDate {
            let lastStreakDate = Calendar.current.startOfDay(for: lastDate)
            
            if lastStreakDate < currentDate {
                // New day, update streak
                currentStreak += 1
                
                // Update longest streak if needed
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
                
                // Determine if we should show a reward animation
                determineReward()
            }
        } else {
            // First ever insight
            currentStreak = 1
            longestStreak = 1
            
            // Show first insight reward
            rewardType = .firstInsight
            showRewardAnimation = true
        }
        
        // Save updated data
        saveStreakData()
    }
    
    /// Gets insights for a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of insights in that category
    func insights(for category: InsightCategory) -> [Insight] {
        return recentInsights.filter { $0.category == category }
    }
    
    /// Checks if user is maintaining a streak and updates status
    func checkStreakStatus() {
        guard let lastDate = lastInsightDate else { return }
        
        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: Date())
        let lastInsightDay = calendar.startOfDay(for: lastDate)
        
        if let daysBetween = calendar.dateComponents([.day], from: lastInsightDay, to: currentDate).day {
            if daysBetween >= Constants.streakBreakDays {
                // Break the streak
                currentStreak = 0
                saveStreakData()
            }
        }
    }
    
    /// Gets time remaining to maintain streak (in hours)
    func hoursRemainingToMaintainStreak() -> Int? {
        guard let lastDate = lastInsightDate else { return nil }
        
        let calendar = Calendar.current
        let currentDate = Date()
        let lastInsightDay = calendar.startOfDay(for: lastDate)
        
        // Get the end of "tomorrow" relative to the last insight
        guard let streakEndDate = calendar.date(byAdding: .day, value: Constants.streakBreakDays, to: lastInsightDay) else {
            return nil
        }
        
        let secondsRemaining = streakEndDate.timeIntervalSince(currentDate)
        let hoursRemaining = Int(secondsRemaining / 3600)
        
        return max(0, hoursRemaining)
    }
    
    // MARK: - Private Methods
    
    /// Loads streak data from persistence
    private func loadStreakData() {
        let defaults = UserDefaults.standard
        
        currentStreak = defaults.integer(forKey: Constants.streakKey)
        longestStreak = defaults.integer(forKey: Constants.longestStreakKey)
        totalInsights = defaults.integer(forKey: Constants.totalInsightsKey)
        
        if let dateData = defaults.object(forKey: Constants.lastInsightDateKey) as? Date {
            lastInsightDate = dateData
        }
        
        if let insightsData = defaults.data(forKey: Constants.recentInsightsKey) {
            do {
                let decoder = JSONDecoder()
                recentInsights = try decoder.decode([Insight].self, from: insightsData)
            } catch {
                print("Error decoding insights: \(error)")
                recentInsights = []
            }
        }
    }
    
    /// Saves streak data to persistence
    private func saveStreakData() {
        let defaults = UserDefaults.standard
        
        defaults.set(currentStreak, forKey: Constants.streakKey)
        defaults.set(longestStreak, forKey: Constants.longestStreakKey)
        defaults.set(totalInsights, forKey: Constants.totalInsightsKey)
        defaults.set(lastInsightDate, forKey: Constants.lastInsightDateKey)
        
        do {
            let encoder = JSONEncoder()
            let insightsData = try encoder.encode(recentInsights)
            defaults.set(insightsData, forKey: Constants.recentInsightsKey)
        } catch {
            print("Error encoding insights: \(error)")
        }
    }
    
    /// Determines what kind of reward to show based on streak
    private func determineReward() {
        // Base chance of showing a reward
        var showRewardChance = 0.3
        
        // Milestone streaks always show a reward
        if currentStreak == 3 {
            rewardType = .streak3
            showRewardAnimation = true
            return
        } else if currentStreak == 7 {
            rewardType = .streak7
            showRewardAnimation = true
            return
        } else if currentStreak == 14 {
            rewardType = .streak14
            showRewardAnimation = true
            return
        } else if currentStreak == 30 {
            rewardType = .streak30
            showRewardAnimation = true
            return
        } else if currentStreak == 60 {
            rewardType = .streak60
            showRewardAnimation = true
            return
        } else if currentStreak == 100 {
            rewardType = .streak100
            showRewardAnimation = true
            return
        } else if currentStreak % 10 == 0 {
            // Every 10 streaks after 100
            rewardType = .streakMilestone
            showRewardAnimation = true
            return
        }
        
        // Increase reward chance based on streak length
        if currentStreak > 10 {
            showRewardChance += 0.1
        }
        if currentStreak > 20 {
            showRewardChance += 0.1
        }
        
        // Random reward based on probability
        if Double.random(in: 0...1) < showRewardChance {
            rewardType = [.basic, .silver, .gold, .special].randomElement() ?? .basic
            showRewardAnimation = true
        } else {
            showRewardAnimation = false
        }
    }
}

// MARK: - Supporting Types

// Note: Insight and InsightCategory types are now defined in MCJModels.swift
// The following extension adds functionality specific to InsightStreakManager

extension InsightCategory {
    var iconName: String {
        switch self {
        case .emotional: return "heart.fill"
        case .pattern: return "repeat"
        case .growth: return "leaf.fill"
        case .challenge: return "mountain.2.fill"
        case .metacognitive: return "brain"
        case .subject: return "book.fill"
        case .application: return "hammer.fill"
        case .connection: return "link"
        case .learning: return "graduationcap.fill"
        case .question: return "questionmark.circle.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .emotional: return "red"
        case .pattern: return "blue"
        case .growth: return "green"
        case .challenge: return "purple"
        case .metacognitive: return "cyan"
        case .subject: return "orange"
        case .application: return "brown"
        case .connection: return "indigo"
        case .learning: return "mint"
        case .question: return "teal"
        case .other: return "gray"
        }
    }
}

/// Types of rewards shown to the user
enum RewardType {
    case basic
    case silver
    case gold
    case special
    case firstInsight
    case streak3
    case streak7
    case streak14
    case streak30
    case streak60
    case streak100
    case streakMilestone
    
    var animationName: String {
        switch self {
        case .basic: return "reward-basic"
        case .silver: return "reward-silver"
        case .gold: return "reward-gold"
        case .special: return "reward-special"
        case .firstInsight: return "reward-first"
        case .streak3: return "reward-streak-3"
        case .streak7: return "reward-streak-7"
        case .streak14: return "reward-streak-14"
        case .streak30: return "reward-streak-30"
        case .streak60: return "reward-streak-60"
        case .streak100: return "reward-streak-100"
        case .streakMilestone: return "reward-milestone"
        }
    }
    
    var message: String {
        switch self {
        case .basic: return "New insight unlocked!"
        case .silver: return "Silver insight achievement!"
        case .gold: return "Gold insight breakthrough!"
        case .special: return "Special discovery unlocked!"
        case .firstInsight: return "First insight achieved! Great start!"
        case .streak3: return "3 day insight streak! You're on a roll!"
        case .streak7: return "One week insight streak! Awesome habit forming!"
        case .streak14: return "Two week insight streak! Impressive commitment!"
        case .streak30: return "30 day insight streak! You're transforming!"
        case .streak60: return "60 day insight streak! Remarkable consistency!"
        case .streak100: return "100 day insight streak! Legendary status!"
        case .streakMilestone: return "Milestone reached! Keep the insights flowing!"
        }
    }
}
