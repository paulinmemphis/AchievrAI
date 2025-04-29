import SwiftUI
import Combine

/// A system that provides variable rewards to users based on their actions
class VariableRewardSystem: ObservableObject {
    // MARK: - Published Properties
    @Published var currentReward: Reward?
    @Published var rewardsEarned: [Reward] = []
    @Published var showRewardPopup: Bool = false
    @Published var streakDays: Int = 0
    @Published var totalPoints: Int = 0
    @Published var level: Int = 1
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let rewardSchedule: RewardSchedule
    private let rewardChances: [JournalRewardType: Double] = [
        .basic: 0.60,
        .silver: 0.25,
        .gold: 0.10,
        .special: 0.05
    ]
    
    // MARK: - Initialization
    init(rewardSchedule: RewardSchedule = .variable) {
        self.rewardSchedule = rewardSchedule
        loadSavedData()
    }
    
    // MARK: - Public Methods
    
    /// Records a user action and potentially grants a reward
    /// - Parameter action: The action performed by the user
    func recordAction(_ action: UserAction) {
        print("[VRS] Recording action: \(action.rawValue)") // Log action start
        // Apply points based on action type
        let pointsEarned = action.basePoints
        totalPoints += pointsEarned
        
        // Update level based on total points
        updateLevel()
        
        // Check if we should grant a reward based on schedule
        if shouldGrantReward(for: action) {
            let reward = generateReward(for: action)
            currentReward = reward
            rewardsEarned.append(reward)
            showRewardPopup = true
        }
        
        // Update streak if it's a daily action
        if action.affectsStreak {
            updateStreak()
        }
        
        // Save data
        print("[VRS] About to save data after action: \(action.rawValue)") // Log before save
        saveData()
        print("[VRS] Finished saving data after action: \(action.rawValue)") // Log after save
    }
    
    /// Acknowledges a reward, marking it as viewed
    func acknowledgeReward() {
        showRewardPopup = false
        currentReward = nil
    }
    
    /// Redeems a reward, removing it from the user's collection
    /// - Parameter reward: The reward to redeem
    func redeemReward(_ reward: Reward) {
        if let index = rewardsEarned.firstIndex(where: { $0.id == reward.id }) {
            rewardsEarned.remove(at: index)
            saveData()
        }
    }
    
    // MARK: - Private Methods
    
    /// Determines if a reward should be granted based on the current schedule
    /// - Parameter action: The action performed
    /// - Returns: Boolean indicating if a reward should be granted
    private func shouldGrantReward(for action: UserAction) -> Bool {
        // Track completion counts in UserDefaults
        let completionKey = "completion_count_\(action.rawValue)"
        let completionCount = userDefaults.integer(forKey: completionKey)
        
        // Update completion count
        userDefaults.set(completionCount + 1, forKey: completionKey)
        
        switch rewardSchedule {
        case .fixed:
            // Fixed schedule - reward after every N actions
            return (completionCount + 1) % action.fixedRewardInterval == 0
            
        case .variable:
            // Variable schedule - probability-based reward
            let baseChance = action.variableRewardChance
            let streakBonus = Double(min(streakDays, 10)) * 0.01
            let finalChance = min(baseChance + streakBonus, 0.95)
            
            return Double.random(in: 0...1) < finalChance
        }
    }
    
    /// Generates a reward based on the action performed
    /// - Parameter action: The action performed
    /// - Returns: A new reward
    private func generateReward(for action: UserAction) -> Reward {
        // Determine reward type using weighted random selection
        let rewardType = selectRewardType(for: action)
        
        // Generate a value based on the reward type
        let value = generateRewardValue(for: rewardType, action: action)
        
        // Create the reward
        return Reward(
            id: UUID().uuidString,
            type: rewardType,
            value: value,
            name: generateRewardName(for: rewardType, action: action),
            description: generateRewardDescription(for: rewardType, action: action, value: value),
            dateEarned: Date(),
            expiryDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            associatedAction: action
        )
    }
    
    /// Selects a reward type based on weighted probabilities
    /// - Parameter action: The user action
    /// - Returns: The selected reward type
    private func selectRewardType(for action: UserAction) -> JournalRewardType {
        let random = Double.random(in: 0...1)
        var cumulativeProbability = 0.0
        
        for (type, probability) in rewardChances {
            cumulativeProbability += probability
            if random < cumulativeProbability {
                return type
            }
        }
        
        return .basic // Default fallback
    }
    
    /// Generates a value for the reward based on its type
    /// - Parameters:
    ///   - type: The reward type
    ///   - action: The associated user action
    /// - Returns: The reward value
    private func generateRewardValue(for type: JournalRewardType, action: UserAction) -> Int {
        switch type {
        case .basic:
            return Int.random(in: 5...15)
        case .silver:
            return Int.random(in: 20...40)
        case .gold:
            return Int.random(in: 50...100)
        case .special:
            return Int.random(in: 150...300)
        case .milestone:
            return 500
        }
    }
    
    /// Generates a name for the reward
    /// - Parameters:
    ///   - type: The reward type
    ///   - action: The associated user action
    /// - Returns: A name for the reward
    private func generateRewardName(for type: JournalRewardType, action: UserAction) -> String {
        let baseNames: [JournalRewardType: [String]] = [
            .basic: ["Star", "Token", "Badge"],
            .silver: ["Silver Star", "Medal", "Trophy"],
            .gold: ["Gold Star", "Premium Badge", "Crown"],
            .special: ["Rare Gem", "Diamond", "Cosmic Reward"],
            .milestone: ["Achievement Award", "Milestone Trophy", "Legacy Badge"]
        ]
        
        let actionNames: [UserAction: [String]] = [
            .completedJournalEntry: ["Reflection", "Journal", "Writer's"],
            .generatedStoryChapter: ["Storyteller", "Novelist", "Creative"],
            .completedBodyScan: ["Mindful", "Awareness", "Presence"],
            .metaReflection: ["Insight", "Wisdom", "Metacognitive"]
        ]
        
        let baseName = baseNames[type]?.randomElement() ?? "Reward"
        let actionName = actionNames[action]?.randomElement() ?? "Explorer's"
        
        return "\(actionName) \(baseName)"
    }
    
    /// Generates a description for the reward
    /// - Parameters:
    ///   - type: The reward type
    ///   - action: The associated user action
    ///   - value: The reward value
    /// - Returns: A description for the reward
    private func generateRewardDescription(for type: JournalRewardType, action: UserAction, value: Int) -> String {
        let baseDescriptions: [JournalRewardType: [String]] = [
            .basic: [
                "A small token of appreciation for your effort.",
                "Keep up the good work!",
                "A stepping stone on your journey."
            ],
            .silver: [
                "An impressive achievement worth celebrating.",
                "Your dedication is paying off!",
                "You're making remarkable progress."
            ],
            .gold: [
                "A magnificent reward for exceptional dedication.",
                "Your commitment is truly inspiring!",
                "A testament to your growth mindset."
            ],
            .special: [
                "An extraordinary reward for your outstanding journey.",
                "A rare acknowledgment of your exceptional progress.",
                "Something truly special for your remarkable achievement."
            ],
            .milestone: [
                "A landmark achievement in your personal growth journey.",
                "A significant milestone that marks your transformation.",
                "A monumental accomplishment worth celebrating."
            ]
        ]
        
        let description = baseDescriptions[type]?.randomElement() ?? "A reward for your effort."
        
        return "\(description) Worth \(value) points."
    }
    
    /// Updates the user's level based on total points
    private func updateLevel() {
        // Calculate level based on points (using a simple formula)
        // Each level requires 20% more points than the previous
        var pointsRequired = 100.0
        var calculatedLevel = 1
        var pointsAccumulated = 0.0
        
        while pointsAccumulated + pointsRequired <= Double(totalPoints) {
            pointsAccumulated += pointsRequired
            calculatedLevel += 1
            pointsRequired *= 1.2 // 20% increase per level
        }
        
        // Only trigger level-up event if the level has increased
        if calculatedLevel > level {
            level = calculatedLevel
            // Generate a milestone reward for level-up
            let levelUpReward = Reward(
                id: UUID().uuidString,
                type: .milestone,
                value: calculatedLevel * 100,
                name: "Level \(calculatedLevel) Achievement",
                description: "You've reached level \(calculatedLevel)! Your dedication to personal growth is impressive.",
                dateEarned: Date(),
                expiryDate: nil, // Milestone rewards don't expire
                associatedAction: .levelUp
            )
            currentReward = levelUpReward
            rewardsEarned.append(levelUpReward)
            showRewardPopup = true
        }
    }
    
    /// Updates the user's streak
    private func updateStreak() {
        let calendar = Calendar.current
        
        // Get last recorded date
        if let lastDateString = userDefaults.string(forKey: "lastStreakDate"),
           let lastDate = ISO8601DateFormatter().date(from: lastDateString) {
            
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let lastRecordedDay = calendar.startOfDay(for: lastDate)
            
            if calendar.isDate(lastRecordedDay, inSameDayAs: yesterday) || calendar.isDate(lastRecordedDay, inSameDayAs: today) {
                // If last recorded day was yesterday or today, increment streak
                if !calendar.isDate(lastRecordedDay, inSameDayAs: today) {
                    streakDays += 1
                }
            } else {
                // Streak broken
                streakDays = 1
            }
        } else {
            // First day of streak
            streakDays = 1
        }
        
        // Save today's date
        userDefaults.set(ISO8601DateFormatter().string(from: Date()), forKey: "lastStreakDate")
        
        // Check for streak milestones
        checkStreakMilestones()
    }
    
    /// Checks for streak milestone achievements
    private func checkStreakMilestones() {
        let streakMilestones = [3, 7, 14, 30, 60, 90, 180, 365]
        
        if streakMilestones.contains(streakDays) {
            // Create milestone reward for streak
            let streakReward = Reward(
                id: UUID().uuidString,
                type: .milestone,
                value: streakDays * 10,
                name: "\(streakDays)-Day Streak Achievement",
                description: "You've maintained your practice for \(streakDays) consecutive days! Your consistency is building powerful habits.",
                dateEarned: Date(),
                expiryDate: nil, // Milestone rewards don't expire
                associatedAction: .streak
            )
            currentReward = streakReward
            rewardsEarned.append(streakReward)
            showRewardPopup = true
        }
    }
    
    /// Loads saved data from UserDefaults
    private func loadSavedData() {
        // Load total points
        totalPoints = userDefaults.integer(forKey: "totalPoints")
        
        // Load level
        level = userDefaults.integer(forKey: "rewardLevel")
        
        // Load streak data
        streakDays = userDefaults.integer(forKey: "streakDays")
        
        // Load rewards
        if let rewardsData = userDefaults.data(forKey: "rewardsEarned") {
            do {
                let decoder = JSONDecoder()
                rewardsEarned = try decoder.decode([Reward].self, from: rewardsData)
            } catch {
                print("Failed to decode rewards: \(error)")
            }
        }
    }
    
    /// Saves data to UserDefaults
    private func saveData() {
        // Save points, level, streak
        userDefaults.set(totalPoints, forKey: "totalPoints")
        userDefaults.set(level, forKey: "level")
        userDefaults.set(streakDays, forKey: "streakDays")
        userDefaults.set(Date().timeIntervalSince1970, forKey: "lastStreakUpdate")
        print("[VRS] Saving points: \(totalPoints), level: \(level), streak: \(streakDays)")
        
        // Save earned rewards (requires encoding)
        print("[VRS] Attempting to encode \(rewardsEarned.count) rewards.") // Log before encode
        // Add detailed logging for the reward being added
        if let latestReward = rewardsEarned.last {
            print("[VRS] Encoding latest reward: ID=\(latestReward.id), Type=\(latestReward.type.rawValue), Action=\(latestReward.associatedAction.rawValue)")
        }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(rewardsEarned)
            userDefaults.set(data, forKey: "rewardsEarned")
            print("[VRS] Successfully encoded and saved rewards.") // Log success
        } catch {
            print("[VRS] Failed to encode rewards: \(error)") // Log error
            // CRASH MIGHT HAPPEN HERE OR DURING ENCODE
        }
    }
}

// MARK: - Supporting Types

/// Types of user actions that can earn rewards
enum UserAction: String, Codable, CaseIterable {
    case completedJournalEntry
    case generatedStoryChapter
    case completedBodyScan
    case metaReflection
    case streak
    case levelUp
    
    /// Base points for this action
    var basePoints: Int {
        switch self {
        case .completedJournalEntry: return 10
        case .generatedStoryChapter: return 15
        case .completedBodyScan: return 8
        case .metaReflection: return 20
        case .streak: return 0  // Special case, handled separately
        case .levelUp: return 0 // Special case, handled separately
        }
    }
    
    /// Whether this action affects the user's streak
    var affectsStreak: Bool {
        switch self {
        case .completedJournalEntry, .generatedStoryChapter, .completedBodyScan:
            return true
        case .metaReflection, .streak, .levelUp:
            return false
        }
    }
    
    /// Interval for fixed reward schedule
    var fixedRewardInterval: Int {
        switch self {
        case .completedJournalEntry: return 3
        case .generatedStoryChapter: return 2
        case .completedBodyScan: return 4
        case .metaReflection: return 1
        case .streak, .levelUp: return 1
        }
    }
    
    /// Base chance for variable reward schedule
    var variableRewardChance: Double {
        switch self {
        case .completedJournalEntry: return 0.3
        case .generatedStoryChapter: return 0.4
        case .completedBodyScan: return 0.25
        case .metaReflection: return 0.5
        case .streak, .levelUp: return 1.0
        }
    }
}

/// Types of rewards
enum JournalRewardType: String, Codable, CaseIterable {
    case basic
    case silver
    case gold
    case special
    case milestone
    
    var color: Color {
        switch self {
        case .basic: return .blue
        case .silver: return .gray
        case .gold: return .yellow
        case .special: return .purple
        case .milestone: return .orange
        }
    }
    
    var iconName: String {
        switch self {
        case .basic: return "star.fill"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .special: return "sparkles"
        case .milestone: return "trophy.fill"
        }
    }
}

/// Reward scheduling approaches
enum RewardSchedule {
    case fixed
    case variable
}

/// A reward given to the user
struct Reward: Identifiable, Codable {
    let id: String
    let type: JournalRewardType
    let value: Int
    let name: String
    let description: String
    let dateEarned: Date
    let expiryDate: Date?
    let associatedAction: UserAction
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
}

// MARK: - Reward Popup View
struct RewardPopupView: View {
    @ObservedObject var rewardSystem: VariableRewardSystem
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            // Reward popup
            VStack(spacing: 20) {
                if let reward = rewardSystem.currentReward {
                    // Header
                    Text("Reward Earned!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    // Reward animation
                    ZStack {
                        Circle()
                            .fill(reward.type.color.opacity(0.2))
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .fill(reward.type.color.opacity(0.4))
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: reward.type.iconName)
                            .font(.system(size: 50))
                            .foregroundColor(reward.type.color)
                            .symbolEffect(.bounce, options: .repeating)
                    }
                    .padding()
                    
                    // Reward details
                    Text(reward.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    
                    Text(reward.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                        .padding(.horizontal)
                    
                    // Points value
                    HStack {
                        Image(systemName: "plusminus.circle.fill")
                            .foregroundColor(reward.type.color)
                        
                        Text("+\(reward.value) points")
                            .font(.headline)
                            .foregroundColor(reward.type.color)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.selectedTheme.backgroundColor)
                    )
                    
                    // Close button
                    Button {
                        rewardSystem.acknowledgeReward()
                    } label: {
                        Text("Awesome!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.selectedTheme.accentColor)
                            )
                    }
                    .padding(.top, 10)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.selectedTheme.backgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
            )
            .padding(30)
        }
    }
}

// MARK: - Rewards Collection View
struct VariableRewardCollectionView: View {
    @ObservedObject var rewardSystem: VariableRewardSystem
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: RewardTab = .active
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("My Rewards")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Text("Level \(rewardSystem.level)")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(themeManager.selectedTheme.accentColor)
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Stats row
            HStack(spacing: 20) {
                VStack {
                    Text("\(rewardSystem.totalPoints)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    Text("Total Points")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("\(rewardSystem.rewardsEarned.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    Text("Rewards")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("\(rewardSystem.streakDays)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.selectedTheme.textColor)
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.selectedTheme.backgroundColor)
            )
            .padding(.horizontal)
            .padding(.top)
            
            // Tabs
            HStack {
                ForEach(RewardTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? themeManager.selectedTheme.accentColor : themeManager.selectedTheme.textColor)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        Capsule()
                                            .fill(themeManager.selectedTheme.accentColor.opacity(0.1))
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top)
            
            // Rewards list
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(filteredRewards) { reward in
                        rewardCard(for: reward)
                    }
                    
                    if filteredRewards.isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
            .background(themeManager.selectedTheme.backgroundColor)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filtered rewards based on selected tab
    private var filteredRewards: [Reward] {
        switch selectedTab {
        case .active:
            return rewardSystem.rewardsEarned.filter { !($0.isExpired) }
        case .milestone:
            return rewardSystem.rewardsEarned.filter { $0.type == .milestone }
        case .expired:
            return rewardSystem.rewardsEarned.filter { $0.isExpired }
        }
    }
    
    // MARK: - Views
    
    /// Card view for an individual reward
    private func rewardCard(for reward: Reward) -> some View {
        HStack(spacing: 16) {
            // Reward icon
            ZStack {
                Circle()
                    .fill(reward.type.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: reward.type.iconName)
                    .font(.title2)
                    .foregroundColor(reward.type.color)
            }
            
            // Reward details
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Text(reward.description)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                HStack {
                    Text("Value: \(reward.value) points")
                        .font(.caption)
                        .foregroundColor(reward.type.color)
                    
                    Spacer()
                    
                    if let expiryDate = reward.expiryDate {
                        Text(expiryDate > Date() ? "Expires: \(expiryDate.formatted(.dateTime.day().month()))" : "Expired")
                            .font(.caption)
                            .foregroundColor(expiryDate > Date() ? themeManager.selectedTheme.textColor : .red)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
        )
    }
    
    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift")
                .font(.system(size: 50))
                .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.5))
            
            Text("No rewards yet!")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text("Keep using the app to earn rewards for your progress.")
                .font(.subheadline)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Supporting Types
enum RewardTab: String, CaseIterable {
    case active = "Active"
    case milestone = "Milestones"
    case expired = "Expired"
}

// MARK: - Preview
struct RewardSystemPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            // Reward popup preview
            RewardPopupView(rewardSystem: VariableRewardSystem())
                .environmentObject(ThemeManager())
                .previewDisplayName("Reward Popup")
            
            // Rewards collection preview
            VariableRewardCollectionView(rewardSystem: VariableRewardSystem())
                .environmentObject(ThemeManager())
                .previewDisplayName("Rewards Collection")
        }
    }
}
