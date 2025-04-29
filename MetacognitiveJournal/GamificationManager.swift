import SwiftUI

/// Holds the state variables for gamification to enable easy Codable persistence.
struct GamificationState: Codable {
    var points: Int = 0
    var level: Int = 1
    var streak: Int = 0
    var badges: [String] = []
    var lastEntryDate: Date? = nil
}

/// Manages the gamification aspects of the journaling app, including points, levels, streaks, and badges.
///
/// This class is an `ObservableObject` to allow SwiftUI views to react to changes in gamification state.
/// It persists its state securely using the Keychain.
class GamificationManager: ObservableObject {
    // MARK: - Published Properties

    /// The user's current points towards the next level.
    @Published private(set) var points: Int = 0

    /// The user's current level.
    @Published private(set) var level: Int = 1

    /// The user's current consecutive daily journaling streak.
    @Published private(set) var streak: Int = 0

    /// An array of unique identifiers for badges the user has earned.
    @Published private(set) var badges: [String] = []

    /// The date of the last journal entry recorded, used for streak calculation.
    @Published private(set) var lastEntryDate: Date? = nil

    // MARK: - Constants

    /// The number of points required to advance per level (multiplied by the current level).
    private let pointsPerLevel = 100
    /// The base number of points awarded for each journal entry.
    private let pointsPerEntry = 10
    /// The bonus points awarded for maintaining a streak each day.
    private let pointsPerStreakDay = 5

    // Public getter for points needed for the current level
    /// Calculates the total points required to reach the *next* level from the start of the current level.
    var pointsNeededForLevel: Int {
        level * pointsPerLevel
    }

    // Key for Keychain persistence
    private let keychainKey = "gamificationState"
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()

    // MARK: - Initialization

    /// Initializes the GamificationManager and loads the persisted state.
    init() {
        loadState()
        checkStreak() // Check streak on initialization
    }

    // MARK: - Public Methods

    /// Records that a journal entry has been made.
    ///
    /// This method updates the streak, awards points, checks for new badges, and saves the state.
    func recordJournalEntry() {
        let now = Date()
        var pointsAwarded = pointsPerEntry

        // Check and update streak
        if let lastDate = lastEntryDate {
            if Calendar.current.isDateInYesterday(lastDate) {
                streak += 1
                pointsAwarded += pointsPerStreakDay
            } else if !Calendar.current.isDateInToday(lastDate) {
                // Streak broken if not yesterday and not today
                streak = 1 // Start new streak
            } // Else: multiple entries today, no streak change
        } else {
            streak = 1 // First entry ever
        }
        
        lastEntryDate = now
        addPoints(pointsAwarded)
        checkForNewBadges() // Check if new badges were earned
        saveState()
    }

    /// Adds points to the user's total, handles leveling up, and saves the state.
    ///
    /// - Parameter amount: The number of points to add.
    func addPoints(_ amount: Int) {
        points += amount
        // Check for level up
        while points >= level * pointsPerLevel {
            points -= level * pointsPerLevel // Deduct points required for the current level
            level += 1
            // TODO: Trigger level up notification/animation
        }
        saveState()
    }

    // MARK: - Badges (Example Logic)

    /// Checks if any new badges should be awarded based on the current state.
    private func checkForNewBadges() {
        // Example: Badge for first entry
        // TODO: Implement badge check for 'firstEntry'. Requires access to JournalStore.
        // Cannot access JournalStore directly here. Dependency needs proper injection or refactoring.

        // Example: Badge for 7-day streak
        if !badges.contains("streak7") && streak >= 7 {
             awardBadge("streak7")
        }
        // Example: Badge for reaching level 5
        if !badges.contains("level5") && level >= 5 {
            awardBadge("level5")
        }
        // Add more badge logic here...
    }

    /// Awards a new badge if the user hasn't already earned it.
    ///
    /// - Parameter badgeId: The unique identifier of the badge to award.
    private func awardBadge(_ badgeId: String) {
        guard !badges.contains(badgeId) else { return }
        badges.append(badgeId)
        // TODO: Trigger badge earned notification/animation
        print("Awarded badge: \(badgeId)")
        saveState()
    }

    // MARK: - Streak Handling

    /// Checks the current streak and resets it if necessary.
    private func checkStreak() {
        guard let lastDate = lastEntryDate else { return }
        // If the last entry was not today or yesterday, reset streak
        if !Calendar.current.isDateInToday(lastDate) && !Calendar.current.isDateInYesterday(lastDate) {
            streak = 0
            saveState()
        }
    }

    // MARK: - Persistence

    /// Saves the current gamification state securely to the Keychain.
    private func saveState() {
        let currentState = GamificationState(points: points,
                                            level: level,
                                            streak: streak,
                                            badges: badges,
                                            lastEntryDate: lastEntryDate)
        do {
            let data = try encoder.encode(currentState)
            try KeychainManager.save(key: keychainKey, data: data)
        } catch {
            // Log error or handle appropriately
            print("Error saving gamification state to Keychain: \(error)")
        }
    }

    /// Loads the gamification state from the Keychain.
    private func loadState() {
        do {
            let data = try KeychainManager.retrieve(key: keychainKey)
            let loadedState = try decoder.decode(GamificationState.self, from: data)
            // Update published properties
            self.points = loadedState.points
            self.level = loadedState.level
            self.streak = loadedState.streak
            self.badges = loadedState.badges
            self.lastEntryDate = loadedState.lastEntryDate
        } catch KeychainManager.KeychainError.itemNotFound {
            // First launch or state not found, use defaults (already set in property initializers)
            print("Gamification state not found in Keychain. Using defaults.")
        } catch {
            // Log error or handle appropriately
            print("Error loading gamification state from Keychain: \(error)")
            // Potentially reset to defaults if decoding fails
        }
    }

    /// Retrieves details (name and system icon name) for a given badge identifier.
    ///
    /// - Parameter badgeId: The unique identifier of the badge.
    /// - Returns: A tuple containing the badge's name and SF Symbol icon name. Returns default values if the ID is unknown.
    func badgeDetails(for badgeId: String) -> (name: String, description: String, icon: String) {
        switch badgeId {
            case "firstEntry": return ("First Step", "You completed your first journal entry!", "figure.walk")
            case "streak7": return ("Consistent", "Achieved a 7-day journaling streak!", "calendar.badge.clock")
            case "level5": return ("Level 5 Reached", "You reached level 5!", "star.fill")
            default: return ("Unknown Badge", "", "questionmark.diamond.fill")
        }
    }

    // TODO: Need access to JournalStore for some badge logic.
    // This implies GamificationManager should either be passed JournalStore
    // or live alongside it where both can be accessed (e.g., injected together).
    // For now, badge logic needing JournalStore is commented out or needs adjustment.
}
