import Foundation
import SwiftUI

/// Manages age-appropriate journaling prompts for children
class ChildJournalPromptManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPrompt: JournalPrompt?
    @Published var favoritePrompts: [JournalPrompt] = []
    @Published var recentPrompts: [JournalPrompt] = []
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private var allPrompts: [JournalPrompt] = []
    private var journalMode: ChildJournalMode = .middleChildhood
    private var readingLevel: ReadingLevel = .grade3to4
    
    // MARK: - Initialization
    init() {
        loadSettings()
        loadPrompts()
        loadFavoritePrompts()
        loadRecentPrompts()
    }
    
    // MARK: - Public Methods
    
    /// Gets a random prompt appropriate for the child's age and reading level
    func getRandomPrompt() -> JournalPrompt {
        let filteredPrompts = allPrompts.filter { prompt in
            prompt.ageRanges.contains(journalMode) &&
            prompt.readingLevel <= readingLevel
        }
        
        guard !filteredPrompts.isEmpty else {
            // Fallback to a simple prompt if no appropriate prompts are found
            return JournalPrompt(
                id: UUID().uuidString,
                text: "How are you feeling today?",
                category: .emotions,
                ageRanges: [.earlyChildhood, .middleChildhood, .adolescent],
                readingLevel: .preReader,
                hasAudio: true,
                hasVisualSupport: true
            )
        }
        
        // Avoid repeating recent prompts if possible
        let candidatePrompts = filteredPrompts.filter { prompt in
            !recentPrompts.contains { $0.id == prompt.id }
        }
        
        let selectedPrompt = candidatePrompts.isEmpty ? 
            filteredPrompts.randomElement()! : 
            candidatePrompts.randomElement()!
        
        currentPrompt = selectedPrompt
        addToRecentPrompts(selectedPrompt)
        return selectedPrompt
    }
    
    /// Gets a prompt by category
    func getPromptByCategory(_ category: PromptCategory) -> JournalPrompt {
        let filteredPrompts = allPrompts.filter { prompt in
            prompt.category == category &&
            prompt.ageRanges.contains(journalMode) &&
            prompt.readingLevel <= readingLevel
        }
        
        guard !filteredPrompts.isEmpty else {
            // Fallback to a random prompt in this category
            return getRandomPrompt()
        }
        
        let selectedPrompt = filteredPrompts.randomElement()!
        currentPrompt = selectedPrompt
        addToRecentPrompts(selectedPrompt)
        return selectedPrompt
    }
    
    /// Adds a prompt to favorites
    func addToFavorites(_ prompt: JournalPrompt) {
        if !favoritePrompts.contains(where: { $0.id == prompt.id }) {
            favoritePrompts.append(prompt)
            saveFavoritePrompts()
        }
    }
    
    /// Removes a prompt from favorites
    func removeFromFavorites(_ prompt: JournalPrompt) {
        favoritePrompts.removeAll { $0.id == prompt.id }
        saveFavoritePrompts()
    }
    
    /// Updates the user's journal mode and reading level
    func updateSettings(journalMode: ChildJournalMode, readingLevel: ReadingLevel) {
        self.journalMode = journalMode
        self.readingLevel = readingLevel
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        if let modeString = userDefaults.string(forKey: "childJournalMode"),
           let mode = ChildJournalMode(rawValue: modeString) {
            journalMode = mode
        }
        
        if let profileData = userDefaults.data(forKey: "childUserProfile"),
           let profile = try? JSONDecoder().decode(ChildUserProfile.self, from: profileData) {
            readingLevel = profile.readingLevel
        }
    }
    
    private func saveSettings() {
        userDefaults.set(journalMode.rawValue, forKey: "childJournalMode")
    }
    
    private func loadPrompts() {
        // In a real app, this would load from a JSON file or API
        allPrompts = PromptCategory.allCases.flatMap { category in
            createPromptsForCategory(category)
        }
    }
    
    private func loadFavoritePrompts() {
        if let data = userDefaults.data(forKey: "childFavoritePrompts"),
           let prompts = try? JSONDecoder().decode([JournalPrompt].self, from: data) {
            favoritePrompts = prompts
        }
    }
    
    private func saveFavoritePrompts() {
        if let data = try? JSONEncoder().encode(favoritePrompts) {
            userDefaults.set(data, forKey: "childFavoritePrompts")
        }
    }
    
    private func loadRecentPrompts() {
        if let data = userDefaults.data(forKey: "childRecentPrompts"),
           let prompts = try? JSONDecoder().decode([JournalPrompt].self, from: data) {
            recentPrompts = prompts
        }
    }
    
    private func addToRecentPrompts(_ prompt: JournalPrompt) {
        // Remove the prompt if it's already in the list
        recentPrompts.removeAll { $0.id == prompt.id }
        
        // Add to the beginning of the list
        recentPrompts.insert(prompt, at: 0)
        
        // Keep only the 10 most recent prompts
        if recentPrompts.count > 10 {
            recentPrompts = Array(recentPrompts.prefix(10))
        }
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(recentPrompts) {
            userDefaults.set(data, forKey: "childRecentPrompts")
        }
    }
    
    private func createPromptsForCategory(_ category: PromptCategory) -> [JournalPrompt] {
        switch category {
        case .emotions:
            return createEmotionPrompts()
        case .learning:
            return createLearningPrompts()
        case .social:
            return createSocialPrompts()
        case .creativity:
            return createCreativityPrompts()
        case .reflection:
            return createReflectionPrompts()
        case .goals:
            return createGoalPrompts()
        }
    }
    
    // MARK: - Prompt Creation Methods
    
    private func createEmotionPrompts() -> [JournalPrompt] {
        return [
            // Early Childhood (6-8)
            JournalPrompt(
                id: UUID().uuidString,
                text: "How are you feeling today? You can draw your feeling or pick an emoji.",
                category: .emotions,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What made you smile today?",
                category: .emotions,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Did anything make you feel sad? Draw or tell about it.",
                category: .emotions,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Middle Childhood (9-12)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What was the strongest emotion you felt today? What caused it?",
                category: .emotions,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "When did you feel proud of yourself today? What happened?",
                category: .emotions,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Did you feel frustrated with anything today? How did you handle it?",
                category: .emotions,
                ageRanges: [.middleChildhood],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: false
            ),
            
            // Adolescent (13-16)
            JournalPrompt(
                id: UUID().uuidString,
                text: "Describe a situation that triggered mixed emotions for you. What were those emotions and why do you think you felt that way?",
                category: .emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "How do your emotions affect your decision-making? Reflect on a recent example.",
                category: .emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "When you feel overwhelmed, what strategies help you regulate your emotions?",
                category: .emotions,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            )
        ]
    }
    
    private func createLearningPrompts() -> [JournalPrompt] {
        return [
            // Early Childhood (6-8)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's one new thing you learned today?",
                category: .learning,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What was easy to learn today? What was hard?",
                category: .learning,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Middle Childhood (9-12)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What subject did you enjoy learning about today? Why did you like it?",
                category: .learning,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Was there something you didn't understand today? What questions do you still have?",
                category: .learning,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            
            // Adolescent (13-16)
            JournalPrompt(
                id: UUID().uuidString,
                text: "How did you approach a challenging learning task today? What strategies did you use?",
                category: .learning,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What connections did you make between what you're learning now and something you already knew?",
                category: .learning,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            )
        ]
    }
    
    private func createSocialPrompts() -> [JournalPrompt] {
        return [
            // Early Childhood (6-8)
            JournalPrompt(
                id: UUID().uuidString,
                text: "Who did you play with today? What did you do?",
                category: .social,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Did you help someone today? How did it make you feel?",
                category: .social,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Middle Childhood (9-12)
            JournalPrompt(
                id: UUID().uuidString,
                text: "Did you work with others on a team or group today? What went well? What was challenging?",
                category: .social,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Was there a disagreement or conflict today? How was it resolved?",
                category: .social,
                ageRanges: [.middleChildhood],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: false
            ),
            
            // Adolescent (13-16)
            JournalPrompt(
                id: UUID().uuidString,
                text: "How do you think your actions affected others today? Consider both positive and negative impacts.",
                category: .social,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Think about a social situation from someone else's perspective. How might they have experienced it differently than you?",
                category: .social,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            )
        ]
    }
    
    private func createCreativityPrompts() -> [JournalPrompt] {
        return [
            // Early Childhood (6-8)
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could be any animal for a day, what would you be? Draw or tell why!",
                category: .creativity,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Imagine you found a magic box. What's inside? Draw or tell your story!",
                category: .creativity,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Middle Childhood (9-12)
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could invent something to solve a problem, what would it be and how would it work?",
                category: .creativity,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Create a short story that starts with: 'The door opened to reveal...'",
                category: .creativity,
                ageRanges: [.middleChildhood],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: false
            ),
            
            // Adolescent (13-16)
            JournalPrompt(
                id: UUID().uuidString,
                text: "If you could redesign your school or community to make it better, what changes would you make and why?",
                category: .creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Choose an issue you care about. Imagine and describe a creative solution that hasn't been tried before.",
                category: .creativity,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            )
        ]
    }
    
    private func createReflectionPrompts() -> [JournalPrompt] {
        return [
            // Early Childhood (6-8)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What was your favorite part of today?",
                category: .reflection,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What made you laugh today?",
                category: .reflection,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Middle Childhood (9-12)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What was challenging for you today? How did you handle it?",
                category: .reflection,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "Think about a mistake you made recently. What did you learn from it?",
                category: .reflection,
                ageRanges: [.middleChildhood],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: false
            ),
            
            // Adolescent (13-16)
            JournalPrompt(
                id: UUID().uuidString,
                text: "How have your thoughts or opinions about something important changed over time? What caused this change?",
                category: .reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What assumptions did you make today that might not be true? How could you test them?",
                category: .reflection,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            )
        ]
    }
    
    private func createGoalPrompts() -> [JournalPrompt] {
        return [
            // Early Childhood (6-8)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something you want to get better at?",
                category: .goals,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What do you want to do tomorrow?",
                category: .goals,
                ageRanges: [.earlyChildhood],
                readingLevel: .grade1to2,
                hasAudio: true,
                hasVisualSupport: true
            ),
            
            // Middle Childhood (9-12)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a goal you're working on? What steps have you taken so far?",
                category: .goals,
                ageRanges: [.middleChildhood],
                readingLevel: .grade3to4,
                hasAudio: true,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's something new you'd like to learn? How could you start learning it?",
                category: .goals,
                ageRanges: [.middleChildhood],
                readingLevel: .grade5to6,
                hasAudio: true,
                hasVisualSupport: false
            ),
            
            // Adolescent (13-16)
            JournalPrompt(
                id: UUID().uuidString,
                text: "What's a long-term goal you have? What smaller goals will help you get there?",
                category: .goals,
                ageRanges: [.adolescent],
                readingLevel: .grade5to6,
                hasAudio: false,
                hasVisualSupport: false
            ),
            JournalPrompt(
                id: UUID().uuidString,
                text: "What obstacles might get in the way of a goal you're working toward? How could you overcome them?",
                category: .goals,
                ageRanges: [.adolescent],
                readingLevel: .grade9Plus,
                hasAudio: false,
                hasVisualSupport: false
            )
        ]
    }
}

// MARK: - Supporting Types

/// Represents a journaling prompt with metadata
struct JournalPrompt: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let category: PromptCategory
    let ageRanges: [ChildJournalMode]
    let readingLevel: ReadingLevel
    let hasAudio: Bool
    let hasVisualSupport: Bool
    
    static func == (lhs: JournalPrompt, rhs: JournalPrompt) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Categories for journal prompts
enum PromptCategory: String, Codable, CaseIterable, Identifiable {
    case emotions = "Emotions"
    case learning = "Learning"
    case social = "Social"
    case creativity = "Creativity"
    case reflection = "Reflection"
    case goals = "Goals"

    var id: String { self.rawValue }

    // Provide an associated icon for each category
    var iconName: String {
        switch self {
        case .emotions:
            return "heart.fill"
        case .learning:
            return "book.fill"
        case .social:
            return "person.2.fill"
        case .creativity:
            return "lightbulb.fill"
        case .reflection:
            return "brain.head.profile"
        case .goals:
            return "star.fill"
        }
    }
    
    // Provide an associated emoji for each category
    var emoji: String {
        switch self {
        case .emotions: return "💖"
        case .learning: return "🧠"
        case .social: return "🤝"
        case .creativity: return "🎨"
        case .reflection: return "🤔"
        case .goals: return "🎯"
        }
    }

    // Provide an associated color for each category
    var color: Color {
        switch self {
        case .emotions:
            return .red
        case .learning:
            return .blue
        case .social:
            return .green
        case .creativity:
            return .purple
        case .reflection:
            return .orange
        case .goals:
            return .yellow
        }
    }
}

// Removed duplicate enum definitions below, as they exist in their own files.
