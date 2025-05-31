import Foundation
import Combine
import UserNotifications
import SwiftUI
// Using consolidated model definitions from MCJModels.swift

/// Manages proactive AI-generated well-being nudges based on journal data.
class AINudgeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var latestNudge: String? = nil
    @Published var showNudge: Bool = false
    @Published var nudgeHistory: [NudgeItem] = []
    @Published var learningPattern: LearningStylePattern? = nil // Using LearningStylePattern from LearningPattern.swift
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let nudgeTemplates = [
        "Remember to take a mindful break today!",
        "Try writing down three things you're grateful for.",
        "If you're feeling overwhelmed, pause and breathe deeply.",
        "Celebrate your progress, no matter how small.",
        "Reflect on a recent success—big or small!"
    ]
    
    // MARK: - Dependencies
    private var journalStore: JournalStore? = nil
    private var gamificationManager: GamificationManager? = nil
    private var userProfile: UserProfile? = nil
    private var analyzer: MetacognitiveAnalyzer? = nil
    
    // MARK: - Initialization
    init() {
        // Default initialization for preview
    }
    
    /// Initialize with dependencies
    func configure(journalStore: JournalStore, gamificationManager: GamificationManager, userProfile: UserProfile, analyzer: MetacognitiveAnalyzer) {
        self.journalStore = journalStore
        self.gamificationManager = gamificationManager
        self.userProfile = userProfile
        self.analyzer = analyzer
        
        // Set up subscriptions
        setupSubscriptions()
        
        // Load nudge history from UserDefaults
        loadNudgeHistory()
        
        // Request notification permissions
        requestNotificationPermissions()
    }

    // MARK: - Public Methods
    
    /// Schedules a proactive nudge based on journal entries
    func scheduleProactiveNudge() {
        guard let journalStore = journalStore, !journalStore.entries.isEmpty else { return }
        
        let entries = journalStore.entries.sorted(by: { $0.date > $1.date })
        
        // Auto-detect learning pattern from journal content
        if let detected = detectLearningPattern(from: entries) {
            learningPattern = detected
        }
        
        // Generate nudge based on mood trends or AI summary
        Task {
            let nudge = await generateNudge(from: entries)
            
            // Ensure UI updates happen on the main thread
            await MainActor.run {
                latestNudge = nudge
                showNudge = true
                
                // Add to history
                let nudgeItem = NudgeItem(id: UUID(), text: nudge, date: Date())
                nudgeHistory.insert(nudgeItem, at: 0)
                if nudgeHistory.count > 20 { // Keep only the most recent 20
                    nudgeHistory = Array(nudgeHistory.prefix(20))
                }
                saveNudgeHistory()
                
                // Schedule notification if app is in background
                scheduleLocalNotification(with: nudge)
            }
        }
    }
    
    /// Dismisses the current nudge
    func dismissNudge() {
        showNudge = false
    }
    
    /// Clears nudge history
    func clearNudgeHistory() {
        nudgeHistory = []
        saveNudgeHistory()
    }
    
    /// Saves nudge history to UserDefaults
    private func saveNudgeHistory() {
        if let encoded = try? JSONEncoder().encode(nudgeHistory) {
            UserDefaults.standard.set(encoded, forKey: "AINudgeHistory")
        }
    }
    
    /// Loads nudge history from UserDefaults
    private func loadNudgeHistory() {
        if let data = UserDefaults.standard.data(forKey: "AINudgeHistory"),
           let decoded = try? JSONDecoder().decode([NudgeItem].self, from: data) {
            nudgeHistory = decoded
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up subscriptions to relevant publishers
    private func setupSubscriptions() {
        // Listen for new journal entries
        journalStore?.$entries
            .debounce(for: .seconds(5), scheduler: RunLoop.main) // Debounce to avoid too frequent updates
            .sink { [weak self] _ in
                // Check if we should show a nudge (randomly, about 30% of the time)
                if Double.random(in: 0...1) < 0.3 {
                    self?.scheduleProactiveNudge()
                }
            }
            .store(in: &cancellables)
        
        // Timer to occasionally show nudges (every 24 hours)
        Timer.publish(every: 24 * 60 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.scheduleProactiveNudge()
            }
            .store(in: &cancellables)
    }
    
    /// Requests permission for local notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Handle permission result if needed
        }
    }
    
    /// Generates a personalized nudge based on journal entries
    private func generateNudge(from entries: [JournalEntry]) async -> String {
        // 1. Personalized streak message
        if let gamificationManager = gamificationManager, gamificationManager.streak > 1 {
            let name = userProfile?.name ?? "there"
            return "🔥 You're on a \(gamificationManager.streak)-day journaling streak, \(name)! Keep it up!"
        }
        
        // 2. Mood history-based nudge, enhanced with learning pattern
        if let moodNudge = moodTrendNudge(from: entries) {
            if let pattern = learningPattern, let rec = pattern.recommendations.randomElement() {
                return moodNudge + "\n\nLearning tip: " + rec
            }
            return moodNudge
        }
        
        // 3. Learning pattern recommendation (if available)
        if let pattern = learningPattern, let rec = pattern.recommendations.randomElement() {
            return "Tip for your \(pattern.rawValue) learning style: \(rec)"
        }
        
        // 4. Recent AI summary
        if let recent = entries.first, let aiSummary = recent.aiSummary, !aiSummary.isEmpty {
            return "AI Insight: \(aiSummary)"
        }
        
        // 5. Fallback to template
        return nudgeTemplates.randomElement() ?? "Remember to check in with yourself today!"
    }

    /// Detects the dominant learning pattern based on keywords in recent journal entries.
    /// - Parameter entries: Array of journal entries to analyze
    /// - Returns: The detected learning pattern or nil if insufficient data
    private func detectLearningPattern(from entries: [JournalEntry]) -> LearningStylePattern? {
        guard !entries.isEmpty else { return nil }
        let text = entries.prefix(10).flatMap { entry in
            entry.reflectionPrompts.map { $0.response ?? "" }
        }.joined(separator: " ").lowercased()
        var patternScores: [LearningStylePattern: Int] = [:]
        for pattern in LearningStylePattern.allCases {
            let matches = pattern.keywords.filter { text.contains($0) }.count
            patternScores[pattern] = matches
        }
        // Return the pattern with the most matches if at least 2 matches
        if let (best, score) = patternScores.max(by: { $0.value < $1.value }), score >= 2 {
            return best
        }
        return nil
    }

    // Analyze mood trends for custom nudge
    private func moodTrendNudge(from entries: [JournalEntry]) -> String? {
        guard entries.count > 2 else { return nil }
        let recent = entries.prefix(7)
        let moodCounts = Dictionary(grouping: recent, by: { $0.emotionalState }).mapValues { $0.count }
        if let (topMood, count) = moodCounts.max(by: { $0.value < $1.value }) {
            switch topMood {
            case .confident where count >= 3:
                return "You've been feeling confident lately—celebrate your wins!"
            case .frustrated where count >= 3:
                return "Noticed some frustration—remember to take breaks and be kind to yourself."
            case .overwhelmed where count >= 2:
                return "If you're feeling overwhelmed, try a short walk or deep breathing."
            case .curious where count >= 3:
                return "Your curiosity is shining—explore something new today!"
            case .neutral where count >= 3:
                return "A steady week—consider mixing up your routine for fresh inspiration."
            default:
                break
            }
        }
        return nil
    }
    
    // Duplicate methods removed - using the ones defined earlier in the file
    
    /// Schedules a local notification with the nudge message
    private func scheduleLocalNotification(with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Well-being Nudge"
        content.body = message
        content.sound = .default
        
        // Schedule for a random time in the next 1-3 hours
        let randomInterval = Double.random(in: 3600...10800) // 1-3 hours in seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: randomInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

/// Represents a single nudge item with text and date
struct NudgeItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date
}
