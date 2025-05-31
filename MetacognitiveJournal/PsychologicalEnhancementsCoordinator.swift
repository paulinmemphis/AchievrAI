import SwiftUI
import Combine

/// Coordinates the integration of psychological enhancement features into the app
class PsychologicalEnhancementsCoordinator: ObservableObject {
    // MARK: - Dependencies
    @Published var insightStreakManager: InsightStreakManager
    @Published var variableRewardSystem: VariableRewardSystem
    
    // MARK: - State
    @Published var showBodyAwarenessPrompt: Bool = false
    @Published var showJourneyProgressView: Bool = false
    @Published var showGrowthJourneyView: Bool = false
    @Published var showRewardsCollection: Bool = false
    
    // MARK: - Private properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        insightStreakManager = InsightStreakManager()
        variableRewardSystem = VariableRewardSystem()
        
        // Set up subscribers
        setupSubscribers()
        
        // Check for first launch experience
        checkFirstLaunchExperience()
    }
    
    // MARK: - Preview Support

    /// Static preview instance for SwiftUI previews.
    /// Initializes the coordinator without triggering potentially problematic side effects
    /// like UserDefaults access present in the regular init.
    static let preview: PsychologicalEnhancementsCoordinator = {
        let coordinator = PsychologicalEnhancementsCoordinator()
        // Manually set any default state usually handled by methods called in init()
        // that we want to bypass for previews (e.g., from checkFirstLaunchExperience).
        // Set to 'false' or a neutral state suitable for most previews.
        coordinator.showBodyAwarenessPrompt = false
        // Add any other necessary preview-specific state setup here.
        return coordinator
    }()

    // MARK: - Public Methods
    
    /// Records completion of a journal entry
    /// - Parameter journalEntry: The completed journal entry
    func recordJournalEntryCompletion(_ journalEntry: JournalEntry) {
        print("[PEC] recordJournalEntryCompletion called for entry ID: \(journalEntry.id)")
        showBodyAwarenessPrompt = true
        
        // Add a small delay before triggering reward system to allow UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // Record in VariableRewardSystem
            self?.variableRewardSystem.recordAction(.completedJournalEntry)
        }
        
        // Record in InsightStreakManager
        let insight = Insight(
            id: UUID(),
            content: extractInsightText(from: journalEntry),
            category: determineInsightCategory(from: journalEntry),
            timestamp: Date()
        )
        
        insightStreakManager.recordInsight(
            text: insight.content, 
            category: insight.category, 
            entryId: journalEntry.id.uuidString // Pass journal entry ID
        )
        
        // Update UserDefaults with latest completion
        userDefaults.set(Date().timeIntervalSince1970, forKey: "lastEntryTimestamp")
    }
    
    /// Records generation of a story chapter
    func recordStoryChapterGeneration() {
        // Record in VariableRewardSystem
        variableRewardSystem.recordAction(.generatedStoryChapter)
        
        // Randomly show journey progress (30% chance)
        if Double.random(in: 0...1) < 0.3 {
            showJourneyProgressView = true
        }
    }
    
    /// Records completion of a body awareness check-in
    func recordBodyAwarenessCompletion() {
        // Record in VariableRewardSystem
        variableRewardSystem.recordAction(.completedBodyScan)
        print("[PEC] recordBodyAwarenessCompletion called - action recorded")
        
        // Update UserDefaults with latest completion
        userDefaults.set(Date().timeIntervalSince1970, forKey: "lastBodyAwarenessTimestamp")
        
        // Reset the prompt flag
        showBodyAwarenessPrompt = false
        
        // Randomly trigger journey progress view (20% chance)
        if Double.random(in: 0...1) < 0.2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showJourneyProgressView = true
            }
        }
    }
    
    /// Records completion of a meta-reflection
    /// - Parameter insight: The insight gained from the meta-reflection
    func recordMetaReflection(insight: Insight) {
        // Record in InsightStreakManager
        insightStreakManager.recordInsight(insight: insight)
        
        // Record in VariableRewardSystem
        variableRewardSystem.recordAction(.metaReflection)
    }
    
    /// Shows the appropriate components based on the user's current state
    func showRelevantComponents() {
        // Check if we should show the streak journey view
        if insightStreakManager.currentStreak >= 3 && 
           (userDefaults.object(forKey: "lastProgressViewDate") == nil || 
            daysSinceLastProgressView() >= 3) {
            showJourneyProgressView = true
            userDefaults.set(Date().timeIntervalSince1970, forKey: "lastProgressViewDate")
        }
        
        // Check if we should show growth journey view
        let lastGrowthViewTimestamp = userDefaults.double(forKey: "lastGrowthViewDate")
        if lastGrowthViewTimestamp == 0 || 
           Date().timeIntervalSince1970 - lastGrowthViewTimestamp > 7 * 24 * 60 * 60 {
            if insightStreakManager.totalInsights >= 5 {
                showGrowthJourneyView = true
                userDefaults.set(Date().timeIntervalSince1970, forKey: "lastGrowthViewDate")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up subscribers to relevant publishers
    private func setupSubscribers() {
        // Listen for reward popup state changes
        variableRewardSystem.$showRewardPopup
            .sink { showPopup in
                if showPopup {
                    // Play haptic feedback for rewards
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            .store(in: &cancellables)
        
        // Listen for streak updates
        insightStreakManager.$showRewardAnimation
            .sink { showAnimation in
                if showAnimation {
                    // Trigger any streak celebration animations
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Checks if this is the first launch and triggers appropriate experiences
    private func checkFirstLaunchExperience() {
        let hasLaunchedBefore = userDefaults.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // This is the first launch
            showBodyAwarenessPrompt = true
            userDefaults.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    /// Calculates days since the last progress view was shown
    /// - Returns: Number of days since last progress view
    private func daysSinceLastProgressView() -> Int {
        let lastTimestamp = userDefaults.double(forKey: "lastProgressViewDate")
        let lastDate = Date(timeIntervalSince1970: lastTimestamp)
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.day], from: lastDate, to: now)
        return components.day ?? Int.max
    }
    
    /// Extracts insight text from a journal entry
    /// - Parameter journalEntry: The journal entry
    /// - Returns: Extracted insight text
    private func extractInsightText(from journalEntry: JournalEntry) -> String {
        // Simple extraction logic - just use the first reflection prompt
        if let firstPrompt = journalEntry.reflectionPrompts.first {
            return firstPrompt.response ?? ""
        }
        return "Journal completion insight"
    }
    
    /// Determines the category of an insight based on the journal entry
    /// - Parameter journalEntry: The journal entry
    /// - Returns: The determined insight category
    private func determineInsightCategory(from journalEntry: JournalEntry) -> InsightCategory {
        // Simple determination logic - could be more sophisticated in practice
        // Look for keywords in the reflections
        
        let fullText = journalEntry.reflectionPrompts
            .compactMap { $0.response }
            .joined(separator: " ")
            .lowercased()
        
        if fullText.contains("emotion") || fullText.contains("feel") || fullText.contains("sad") || 
           fullText.contains("happy") || fullText.contains("angry") {
            return .emotional
        }
        
        if fullText.contains("pattern") || fullText.contains("notice") || fullText.contains("observe") {
            return .pattern
        }
        
        if fullText.contains("grow") || fullText.contains("improve") || fullText.contains("better") {
            return .growth
        }
        
        if fullText.contains("strength") || fullText.contains("skill") || fullText.contains("able to") {
            return .growth // Map 'strength' to 'growth' since there's no 'strength' case in our consolidated enum
        }
        
        if fullText.contains("challenge") || fullText.contains("difficult") || fullText.contains("struggle") {
            return .challenge
        }
        
        // Default to pattern insights
        return .pattern
    }
}

// MARK: - View Modifiers

/// A view modifier that injects psychological enhancement components
struct PsychologicalEnhancementsViewModifier: ViewModifier {
    @ObservedObject var coordinator: PsychologicalEnhancementsCoordinator
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var growthMetricsManager: GrowthMetricsManager
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $coordinator.showBodyAwarenessPrompt) {
                NavigationStack {
                    BodyAwarenessPromptView()
                        .environmentObject(themeManager)
                        .onDisappear {
                            // coordinator.recordBodyAwarenessCompletion()
                        }
                }
            }
            .sheet(isPresented: $coordinator.showJourneyProgressView) {
                NavigationStack {
                    JourneyProgressView(insightStreakManager: coordinator.insightStreakManager)
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $coordinator.showGrowthJourneyView) {
                NavigationStack {
                    GrowthJourneyView(metricsManager: growthMetricsManager)
                        .environmentObject(themeManager)
                }
            }
            .sheet(isPresented: $coordinator.showRewardsCollection) {
                NavigationStack {
                    VariableRewardCollectionView(rewardSystem: coordinator.variableRewardSystem)
                        .environmentObject(themeManager)
                }
            }
            .overlay {
                Group { // Wrap in Group to ensure environment inheritance
                    if coordinator.variableRewardSystem.showRewardPopup {
                        RewardPopupView(rewardSystem: coordinator.variableRewardSystem)
                            .environmentObject(themeManager)
                            .transition(.opacity)
                    } else {
                        EmptyView() // Group needs content if condition is false
                    }
                }
            }
    }
}

// MARK: - View Extension
extension View {
    /// Adds psychological enhancement components to a view
    /// - Parameter coordinator: The psychological enhancements coordinator
    /// - Returns: A view with psychological enhancements
    func withPsychologicalEnhancements(_ coordinator: PsychologicalEnhancementsCoordinator) -> some View {
        self.modifier(PsychologicalEnhancementsViewModifier(coordinator: coordinator))
    }
}
