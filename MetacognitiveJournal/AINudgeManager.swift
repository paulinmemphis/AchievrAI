import Foundation
import Combine
import UserNotifications

// Add GamificationManager and LearningPattern support

/// Manages proactive AI-generated well-being nudges based on journal data.
class AINudgeManager: ObservableObject {
    static let shared = AINudgeManager()
    @Published var latestNudge: String? = nil
    private var cancellables = Set<AnyCancellable>()
    private let analyzer = MetacognitiveAnalyzer()
    private let nudgeTemplates = [
        "Remember to take a mindful break today!",
        "Try writing down three things you’re grateful for.",
        "If you’re feeling overwhelmed, pause and breathe deeply.",
        "Celebrate your progress, no matter how small.",
        "Reflect on a recent success—big or small!"
    ]
    private let gamification = GamificationManager()
    private let userProfile = UserProfile()
    // Optionally inject learning pattern (if detected elsewhere)
    var learningPattern: LearningPattern? = nil

    func scheduleProactiveNudge(for entries: [JournalEntry]) {
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
                scheduleLocalNotification(with: nudge)
            }
        }
    }
    
    private func generateNudge(from entries: [JournalEntry]) async -> String {
        // 1. Personalized streak message
        if gamification.streak > 1 {
            return "🔥 You're on a \(gamification.streak)-day journaling streak, \(userProfile.name)! Keep it up!"
        }
        // 2. Mood history-based nudge, enhanced with learning pattern
        if let moodNudge = moodTrendNudge(from: entries) {
            if let pattern = learningPattern, let rec = pattern.recommendations.randomElement() {
                return moodNudge + "\nLearning tip: " + rec
            }
            return moodNudge
        }
        // 3. Learning pattern recommendation (if available)
        if let pattern = learningPattern, let rec = pattern.recommendations.randomElement() {
            return "Tip for your learning style: \(rec)"
        }
        // 4. Recent AI summary
        if let recent = entries.first, let aiSummary = recent.aiSummary, !aiSummary.isEmpty {
            return "AI Insight: \(aiSummary)"
        }
        // 5. Fallback to template
        return nudgeTemplates.randomElement() ?? "Remember to check in with yourself today!"
    }

    /// Detects the dominant learning pattern based on keywords in recent journal entries.
    private func detectLearningPattern(from entries: [JournalEntry]) -> LearningPattern? {
        guard !entries.isEmpty else { return nil }
        let text = entries.prefix(10).flatMap { entry in
            entry.reflectionPrompts.map { $0.response ?? "" }
        }.joined(separator: " ").lowercased()
        var patternScores: [LearningPattern: Int] = [:]
        for pattern in LearningPattern.allCases {
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
    
    private func scheduleLocalNotification(with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Well-being Nudge"
        content.body = message
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false) // Demo: 10s
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
