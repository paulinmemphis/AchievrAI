import Foundation
import SwiftUI
import Combine

/// Manages the adaptive feedback system
class AdaptiveFeedbackManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Feedback provided to children
    @Published var feedbackHistory: [AdaptiveFeedback] = []
    
    /// Feedback patterns that can be recognized
    @Published var feedbackPatterns: [FeedbackPattern] = []
    
    /// Feedback templates for different types of feedback
    @Published var feedbackTemplates: [FeedbackTemplate] = []
    
    /// Progress tracking for each child
    @Published var progressTracking: [String: FeedbackProgress] = [:]
    
    /// Available metacognitive challenges
    @Published var availableChallenges: [MetacognitiveChallenge] = []
    
    /// Available learning supports
    @Published var availableSupports: [LearningSupport] = []
    
    // MARK: - Private Properties
    
    /// Developmental language patterns
    private var developmentalLanguage: DevelopmentalLanguage
    
    /// UserDefaults keys
    private let feedbackHistoryKey = "feedbackHistory"
    private let progressTrackingKey = "feedbackProgressTracking"
    
    /// Dependencies
    private let learningReflectionManager: LearningReflectionManager?
    private let emotionalAwarenessManager: EmotionalAwarenessManager?
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(learningReflectionManager: LearningReflectionManager? = nil,
         emotionalAwarenessManager: EmotionalAwarenessManager? = nil) {
        self.learningReflectionManager = learningReflectionManager
        self.emotionalAwarenessManager = emotionalAwarenessManager
        
        // Initialize developmental language using a static method
        self.developmentalLanguage = Self.initializeDevelopmentalLanguage()
        
        // Load data
        loadFeedbackHistory()
        loadProgressTracking()
        
        // Initialize feedback patterns, templates, challenges, and supports
        initializeFeedbackPatterns()
        initializeFeedbackTemplates()
        initializeMetacognitiveChallenges()
        initializeLearningSupports()
        
        // Set up subscriptions to other managers if available
        setupSubscriptions()
    }
    
    // MARK: - Feedback Generation Methods
    
    /// Generates feedback for a journal entry
    func generateFeedback(for journalEntry: JournalEntry, childId: String, mode: ChildJournalMode) -> AdaptiveFeedback? {
        // In a real app, this would analyze the journal entry content
        // For demo purposes, we'll create sample feedback
        
        // Get the child's progress tracking
        var progress = getProgressTracking(for: childId)
        
        // Determine the most appropriate feedback type based on the entry and child's history
        let feedbackType = determineFeedbackType(for: journalEntry, childProgress: progress)
        
        // Select a template for this feedback type
        guard let template = selectTemplate(for: feedbackType, mode: mode) else {
            return nil
        }
        
        // Generate the main feedback content
        let content = generateFeedbackContent(from: template, for: journalEntry, mode: mode)
        
        // Generate follow-up prompts
        let followUpPrompts = generateFollowUpPrompts(for: feedbackType, mode: mode)
        
        // Determine if we should include a challenge
        let challenge = shouldIncludeChallenge(for: childId, feedbackType: feedbackType) ?
            selectChallenge(for: childId, mode: mode) : nil
        
        // Determine if we should include learning support
        let support = shouldIncludeLearningSupport(for: journalEntry) ?
            selectLearningSupport(for: journalEntry, mode: mode) : nil
        
        // Create the feedback
        let feedback = AdaptiveFeedback(
            childId: childId,
            journalEntryId: journalEntry.id,
            feedbackType: feedbackType,
            content: content,
            supportingDetails: generateSupportingDetails(for: journalEntry, feedbackType: feedbackType),
            followUpPrompts: followUpPrompts,
            suggestedStrategies: generateStrategySuggestions(for: journalEntry, mode: mode),
            celebratedProgress: generateProgressCelebration(for: childId, feedbackType: feedbackType, mode: mode),
            challenge: challenge,
            learningSupport: support,
            developmentalLevel: mode
        )
        
        // Save the feedback to history
        feedbackHistory.append(feedback)
        saveFeedbackHistory()
        
        // Update progress tracking
        progress.recordFeedbackReceived()
        saveProgressTracking()
        
        return feedback
    }
    
    /// Determines the most appropriate feedback type for a journal entry
    private func determineFeedbackType(for journalEntry: JournalEntry, childProgress: FeedbackProgress) -> FeedbackType {
        // In a real app, this would use more sophisticated analysis
        // For demo purposes, we'll use a simple approach
        
        // Check for emotional content - EmotionalState is non-optional
        // Check for specific emotional states instead
        if journalEntry.emotionalState != .neutral {
            return .emotionalAwareness
        }
        
        // Check for metacognitive content
        if journalEntry.content.lowercased().contains("think") || 
           journalEntry.content.lowercased().contains("learn") {
            return .metacognitiveInsight
        }
        
        // Check for challenges or struggles
        if journalEntry.content.lowercased().contains("hard") || 
           journalEntry.content.lowercased().contains("difficult") {
            return .supportiveIntervention
        }
        
        // Check if we should celebrate progress
        if childProgress.feedbackReceived > 0 && 
           childProgress.feedbackReceived % 5 == 0 {
            return .celebrationOfProgress
        }
        
        // Default to encouragement or reflection prompt
        return [.encouragement, .reflectionPrompt].randomElement() ?? .encouragement
    }
    
    /// Selects a template for the given feedback type and developmental mode
    private func selectTemplate(for feedbackType: FeedbackType, mode: ChildJournalMode) -> FeedbackTemplate? {
        let templates = feedbackTemplates.filter { $0.type == feedbackType }
        return templates.randomElement()
    }
    
    /// Generates the main feedback content from a template
    private func generateFeedbackContent(from template: FeedbackTemplate, for journalEntry: JournalEntry, mode: ChildJournalMode) -> String {
        var content = template.template(for: mode)
        
        // Replace placeholders with actual content
        // In a real app, this would be more sophisticated
        content = content.replacingOccurrences(of: "{emotion}", with: journalEntry.emotionalState.rawValue)
        content = content.replacingOccurrences(of: "{topic}", with: journalEntry.assignmentName)
        
        // Add appropriate language patterns
        let patterns = developmentalLanguage.patternsFor(mode: mode)
        content = patterns.randomPhrase(type: .encouragement) + " " + content
        
        return content
    }
    
    /// Generates follow-up prompts for the given feedback type
    private func generateFollowUpPrompts(for feedbackType: FeedbackType, mode: ChildJournalMode) -> [String] {
        // In a real app, this would be more sophisticated
        switch feedbackType {
        case .metacognitiveInsight:
            return [
                "What helped you notice this about your thinking?",
                "How might you use this insight next time?",
                "When else have you noticed this pattern in your thinking?"
            ]
        case .emotionalAwareness:
            return [
                "What helped you recognize this feeling?",
                "How did your body feel when you experienced this?",
                "What strategies helped you manage this feeling?"
            ]
        case .growthOpportunity:
            return [
                "What's one small step you could take?",
                "What might help you grow in this area?",
                "Who could support you with this?"
            ]
        default:
            return [
                "What else have you noticed about your learning?",
                "What are you curious about exploring next?",
                "What strategy has been most helpful for you?"
            ]
        }
    }
    
    /// Generates supporting details for the feedback
    private func generateSupportingDetails(for journalEntry: JournalEntry, feedbackType: FeedbackType) -> String? {
        // In a real app, this would be more sophisticated
        switch feedbackType {
        case .metacognitiveInsight:
            return "When you notice your own thinking process, you're developing metacognitive skills that help you learn more effectively."
        case .emotionalAwareness:
            return "Understanding your emotions helps you make better decisions and learn more effectively."
        case .growthOpportunity:
            return "Challenges help your brain grow stronger, just like exercise helps your muscles grow."
        case .strategyRecommendation:
            return "Different strategies work for different situations. Finding what works best for you is an important skill."
        default:
            return nil
        }
    }
    
    /// Generates strategy suggestions based on the journal entry
    private func generateStrategySuggestions(for journalEntry: JournalEntry, mode: ChildJournalMode) -> [String]? {
        // In a real app, this would be more sophisticated
        // For demo purposes, we'll return some general strategies
        
        let strategies: [String]
        
        switch mode {
        case .earlyChildhood:
            strategies = [
                "Draw a picture of what you're thinking about",
                "Talk about it with someone you trust",
                "Take three deep breaths when you feel big feelings"
            ]
        case .middleChildhood:
            strategies = [
                "Break the problem into smaller steps",
                "Try explaining it to someone else",
                "Make a plan before you start"
            ]
        case .adolescent:
            strategies = [
                "Consider multiple perspectives or approaches",
                "Connect this to something you already know well",
                "Reflect on what strategies have worked in similar situations"
            ]
        }
        
        return strategies
    }
    
    /// Generates a celebration of progress
    private func generateProgressCelebration(for childId: String, feedbackType: FeedbackType, mode: ChildJournalMode) -> String? {
        // Only generate for celebration feedback type
        guard feedbackType == .celebrationOfProgress else {
            return nil
        }
        
        let progress = getProgressTracking(for: childId)
        let patterns = developmentalLanguage.patternsFor(mode: mode)
        
        let celebration = patterns.randomPhrase(type: .celebration)
        
        if progress.feedbackReceived >= 10 {
            return "\(celebration) You've written \(progress.feedbackReceived) journal entries that show your thinking process. Your metacognitive skills are growing!"
        } else {
            return "\(celebration) You're developing important thinking skills that will help you learn better."
        }
    }
    
    /// Determines if we should include a challenge
    private func shouldIncludeChallenge(for childId: String, feedbackType: FeedbackType) -> Bool {
        // In a real app, this would be more sophisticated
        let progress = getProgressTracking(for: childId)
        
        // Include a challenge every 3rd feedback, or for growth opportunity feedback
        return progress.feedbackReceived % 3 == 0 || feedbackType == .growthOpportunity
    }
    
    /// Selects an appropriate challenge
    private func selectChallenge(for childId: String, mode: ChildJournalMode) -> MetacognitiveChallenge? {
        // In a real app, this would be more sophisticated
        let progress = getProgressTracking(for: childId)
        
        // Filter challenges the child hasn't completed yet
        let uncompletedChallenges = availableChallenges.filter { !progress.challengesCompleted.contains($0.id) }
        
        // Filter by appropriate difficulty
        let appropriateChallenges: [MetacognitiveChallenge]
        
        switch progress.feedbackReceived {
        case 0...5:
            appropriateChallenges = uncompletedChallenges.filter { $0.difficulty == .starter }
        case 6...15:
            appropriateChallenges = uncompletedChallenges.filter { $0.difficulty == .explorer }
        case 16...30:
            appropriateChallenges = uncompletedChallenges.filter { $0.difficulty == .practitioner }
        case 31...50:
            appropriateChallenges = uncompletedChallenges.filter { $0.difficulty == .expert }
        default:
            appropriateChallenges = uncompletedChallenges.filter { $0.difficulty == .master }
        }
        
        return appropriateChallenges.randomElement() ?? uncompletedChallenges.first
    }
    
    /// Determines if we should include learning support
    private func shouldIncludeLearningSupport(for journalEntry: JournalEntry) -> Bool {
        // In a real app, this would be more sophisticated
        // For demo purposes, check for keywords indicating struggle
        let struggleKeywords = ["confused", "don't understand", "hard", "difficult", "stuck", "help"]
        
        return struggleKeywords.contains { journalEntry.content.lowercased().contains($0) }
    }
    
    /// Selects appropriate learning support
    private func selectLearningSupport(for journalEntry: JournalEntry, mode: ChildJournalMode) -> LearningSupport? {
        // In a real app, this would be more sophisticated
        // For demo purposes, select a random support
        return availableSupports.randomElement()
    }
    
    // MARK: - Progress Tracking Methods
    
    /// Records that a child implemented feedback
    func recordFeedbackImplemented(feedbackId: UUID, childId: String, type: FeedbackType) {
        var progress = getProgressTracking(for: childId)
        progress.recordFeedbackImplemented(type: type)
        saveProgressTracking()
    }
    
    /// Records that a child completed a challenge
    func recordChallengeCompleted(challengeId: UUID, childId: String, targetSkill: MetacognitiveProcess) {
        var progress = getProgressTracking(for: childId)
        progress.recordChallengeCompleted(challengeId, targetSkill: targetSkill)
        saveProgressTracking()
    }
    
    /// Gets feedback history for a specific child
    func getFeedbackHistory(for childId: String) -> [AdaptiveFeedback] {
        return feedbackHistory.filter { $0.childId == childId }
    }
    
    /// Gets progress tracking for a specific child
    func getProgressTracking(for childId: String) -> FeedbackProgress {
        if let existing = progressTracking[childId] {
            return existing
        } else {
            let newProgress = FeedbackProgress(childId: childId)
            progressTracking[childId] = newProgress
            return newProgress
        }
    }
    
    // MARK: - Initialization Methods
    
    /// Initializes developmental language patterns (static method)
    private static func initializeDevelopmentalLanguage() -> DevelopmentalLanguage {
        // Early childhood language (6-8 years)
        let earlyChildhood = LanguagePatterns(
            encouragementPhrases: [
                "Wow!", "Great job!", "I like how you're thinking!", "That's super!", "You're doing great!"
            ],
            transitionPhrases: [
                "Now,", "Let's see,", "Next,", "Also,", "And then,"
            ],
            questionStarters: [
                "What do you think about", "How did you feel when", "What happened when", "Why did you", "Can you tell me about"
            ],
            celebrationPhrases: [
                "Hooray!", "Amazing work!", "You did it!", "Fantastic job!", "That's awesome!"
            ],
            supportPhrases: [
                "Let's try together.", "I can help you with that.", "It's okay to find things tricky.", "Everyone needs help sometimes.", "Let's figure this out."
            ],
            challengePhrases: [
                "Try this fun activity:", "Here's a cool challenge:", "Let's play a thinking game:", "Want to try something fun?", "Here's a special mission:"
            ],
            metacognitiveVerbs: [
                "think about", "remember", "notice", "wonder", "figure out", "plan", "check"
            ],
            emotionalVocabulary: [
                "happy", "sad", "mad", "scared", "excited", "worried", "proud", "surprised"
            ]
        )
        
        // Middle childhood language (9-12 years)
        let middleChildhood = LanguagePatterns(
            encouragementPhrases: [
                "Nice insight!", "You're showing good thinking!", "That's thoughtful!", "Great observation!", "You're making good progress!"
            ],
            transitionPhrases: [
                "Additionally,", "Furthermore,", "Moving on,", "Another thing to consider,", "On a related note,"
            ],
            questionStarters: [
                "What strategy did you use to", "How did you decide to", "What were you thinking when", "Why might this be happening", "How would you explain"
            ],
            celebrationPhrases: [
                "Excellent progress!", "Well done!", "That's impressive!", "Great accomplishment!", "You've really improved!"
            ],
            supportPhrases: [
                "Let's break this down.", "There are different approaches we could try.", "It's normal to find this challenging.", "Let's think about this step by step.", "What part is most confusing?"
            ],
            challengePhrases: [
                "Here's a challenge to try:", "See if you can tackle this:", "This activity might help you grow:", "Try this strategy:", "Here's an opportunity to practice:"
            ],
            metacognitiveVerbs: [
                "reflect on", "analyze", "evaluate", "consider", "monitor", "organize", "compare", "question"
            ],
            emotionalVocabulary: [
                "frustrated", "anxious", "confident", "disappointed", "curious", "confused", "hopeful", "overwhelmed"
            ]
        )
        
        // Adolescent language (13-16 years)
        let adolescent = LanguagePatterns(
            encouragementPhrases: [
                "That's a perceptive observation.", "You're demonstrating strong metacognitive awareness.", "Your analysis shows depth.", "That's a sophisticated approach.", "You're developing valuable insights."
            ],
            transitionPhrases: [
                "Moreover,", "In addition to this,", "From another perspective,", "It's worth considering that,", "Building on this idea,"
            ],
            questionStarters: [
                "What factors influenced your", "How would you evaluate your", "What connections do you see between", "How might you apply this to", "What evidence supports your"
            ],
            celebrationPhrases: [
                "This represents significant growth.", "Your progress is noteworthy.", "This demonstrates real development.", "Your persistence has paid off.", "This shows meaningful advancement."
            ],
            supportPhrases: [
                "Let's examine this systematically.", "There are multiple approaches worth considering.", "This challenge is an opportunity for growth.", "Let's identify the specific obstacle.", "What assumptions might we need to reconsider?"
            ],
            challengePhrases: [
                "Consider this extension of your thinking:", "This challenge might deepen your understanding:", "Try applying this metacognitive strategy:", "This exercise builds on your current skills:", "Here's an opportunity to refine your approach:"
            ],
            metacognitiveVerbs: [
                "synthesize", "hypothesize", "critique", "differentiate", "extrapolate", "integrate", "deconstruct", "conceptualize"
            ],
            emotionalVocabulary: [
                "apprehensive", "ambivalent", "motivated", "disheartened", "enthusiastic", "perplexed", "gratified", "disillusioned"
            ]
        )
        
        return DevelopmentalLanguage(
            earlyChildhood: earlyChildhood,
            middleChildhood: middleChildhood,
            adolescent: adolescent
        )
    }
    
    /// Initializes feedback patterns
    private func initializeFeedbackPatterns() {
        // In a real app, these would be loaded from a database
        // For demo purposes, we'll create a few sample patterns
        feedbackPatterns = []
        
        // Add patterns here
    }
    
    /// Initializes feedback templates
    private func initializeFeedbackTemplates() {
        // In a real app, these would be loaded from a database
        feedbackTemplates = [
            // Encouragement templates
            FeedbackTemplate(
                name: "General Encouragement",
                type: .encouragement,
                templates: [
                    .earlyChildhood: "You're doing a great job with your journal! Your brain is growing stronger every time you write.",
                    .middleChildhood: "Your journaling shows that you're developing important thinking skills. Keep up the good work!",
                    .adolescent: "Your consistent reflection demonstrates commitment to your metacognitive development. This practice builds valuable skills."
                ],
                placeholders: [],
                followUpTemplates: [
                    "What did you enjoy about writing today?",
                    "What would you like to explore more in your next journal entry?"
                ]
            ),
            
            // Metacognitive insight templates
            FeedbackTemplate(
                name: "Recognizing Thinking Patterns",
                type: .metacognitiveInsight,
                templates: [
                    .earlyChildhood: "You noticed how your brain was working! When you wrote about {topic}, you were thinking about your own thinking.",
                    .middleChildhood: "You showed metacognition when writing about {topic}. You're becoming aware of how your mind works, which is an important skill.",
                    .adolescent: "Your reflection on {topic} demonstrates metacognitive awareness. Recognizing your thought processes is a sophisticated skill that enhances learning."
                ],
                placeholders: ["{topic}"],
                followUpTemplates: [
                    "What helped you notice this about your thinking?",
                    "How might you use this insight in other situations?"
                ]
            ),
            
            // Emotional awareness templates
            FeedbackTemplate(
                name: "Emotion Recognition",
                type: .emotionalAwareness,
                templates: [
                    .earlyChildhood: "You noticed you were feeling {emotion}! Knowing your feelings helps you understand yourself better.",
                    .middleChildhood: "You identified feeling {emotion}, which shows good emotional awareness. Understanding your emotions helps you learn better.",
                    .adolescent: "Your recognition of {emotion} demonstrates emotional intelligence. This awareness allows you to manage your emotional responses effectively."
                ],
                placeholders: ["{emotion}"],
                followUpTemplates: [
                    "How did your body feel when you experienced this emotion?",
                    "What helped you manage this feeling?"
                ]
            ),
            
            // Growth opportunity templates
            FeedbackTemplate(
                name: "Learning Challenge",
                type: .growthOpportunity,
                templates: [
                    .earlyChildhood: "When things are tricky, your brain grows stronger! Your journal shows you're working on something challenging.",
                    .middleChildhood: "You've identified a challenge in your learning. This is exactly when your brain grows the most!",
                    .adolescent: "You've recognized an area for growth in your learning process. This awareness is the first step toward developing new strategies and skills."
                ],
                placeholders: [],
                followUpTemplates: [
                    "What's one small step you could take?",
                    "What might help you with this challenge?"
                ]
            ) // Correct closing parenthesis for FeedbackTemplate initializer
            
            // Additional templates would be added here
        ]
    }
    
    /// Initializes metacognitive challenges
    private func initializeMetacognitiveChallenges() {
        // In a real app, these would be loaded from a database
        availableChallenges = [
            // Planning challenges
            MetacognitiveChallenge(
                title: "Goal Detective",
                description: "Practice setting clear goals before you start a task",
                steps: [
                    "Choose a task you need to do (homework, chore, project)",
                    "Write down what you want to accomplish",
                    "List 3 steps you'll take to reach your goal",
                    "After finishing, write about whether your plan worked"
                ],
                targetSkill: .planning,
                difficulty: .starter,
                estimatedTimeMinutes: 15,
                completionPrompt: "How did having a plan help you complete your task?"
            ),
            
            // Monitoring challenges
            MetacognitiveChallenge(
                title: "Progress Tracker",
                description: "Practice checking your progress while working",
                steps: [
                    "Start a task that takes at least 20 minutes",
                    "Set a timer to stop every 5 minutes",
                    "Each time the timer goes off, ask yourself: 'Am I on track? Do I need to adjust?'",
                    "Write down what you notice about your progress"
                ],
                targetSkill: .monitoring,
                difficulty: .explorer,
                estimatedTimeMinutes: 25,
                completionPrompt: "What did you learn by checking your progress regularly?"
            ),
            
            // Evaluating challenges
            MetacognitiveChallenge(
                title: "Strategy Detective",
                description: "Investigate which strategies work best for you",
                steps: [
                    "Choose a learning task (like memorizing information)",
                    "Try three different strategies (like visualization, repetition, teaching someone)",
                    "Rate how well each strategy worked for you",
                    "Write about which strategy worked best and why"
                ],
                targetSkill: .evaluating,
                difficulty: .practitioner,
                estimatedTimeMinutes: 30,
                completionPrompt: "How will knowing your best strategies help you in the future?"
            ) // Correct closing parenthesis for MetacognitiveChallenge initializer
            
            // Additional challenges would be added here
        ]
    }
    
    /// Initializes learning supports
    private func initializeLearningSupports() {
        // In a real app, these would be loaded from a database
        availableSupports = [
            // Emotional regulation supports
            LearningSupport(
                title: "Calm Corner",
                supportType: .emotionalRegulation,
                content: "When big feelings make it hard to think clearly, try this: Take 5 deep breaths, name your feeling, and remind yourself that all feelings are okay and temporary.",
                visualAid: "breath.bubble",
                exampleScenario: "When Maya felt frustrated with her math homework, she took 5 deep breaths and said 'I'm feeling frustrated, and that's okay. This feeling will pass.'",
                practiceActivity: "Draw a picture of your calm place - somewhere real or imaginary where you feel peaceful."
            ),
            
            // Learning strategy supports
            LearningSupport(
                title: "Chunking Method",
                supportType: .strategy,
                content: "When something seems too big or complicated, break it down into smaller pieces. Work on one small piece at a time.",
                visualAid: "square.grid.2x2",
                exampleScenario: "Instead of trying to write a whole story at once, Jamal broke it down: first characters, then setting, then problem, then solution.",
                practiceActivity: "Take something you're working on and list the smaller pieces you could break it into."
            ),
            
            // Visualization supports
            LearningSupport(
                title: "Mind Movie",
                supportType: .visualization,
                content: "Create a movie in your mind about what you're learning. See the details, colors, and movement. This helps your brain remember information better.",
                visualAid: "film",
                exampleScenario: "When learning about the water cycle, Sophia imagined a tiny water droplet named Splash going up into a cloud and then falling as rain.",
                practiceActivity: "Close your eyes and create a mind movie about something you're learning, then draw or describe what you saw."
            )
            
            // Additional supports would be added here
        ]
    }
    
    /// Sets up subscriptions to other managers
    private func setupSubscriptions() {
        // In a real app, this would subscribe to events from other managers
        // For example, when a new journal entry is created
    }
    
    // MARK: - Persistence Methods
    
    /// Saves feedback history to UserDefaults
    private func saveFeedbackHistory() {
        if let encodedData = try? JSONEncoder().encode(feedbackHistory) {
            UserDefaults.standard.set(encodedData, forKey: feedbackHistoryKey)
        }
    }
    
    /// Loads feedback history from UserDefaults
    private func loadFeedbackHistory() {
        if let historyData = UserDefaults.standard.data(forKey: feedbackHistoryKey),
           let history = try? JSONDecoder().decode([AdaptiveFeedback].self, from: historyData) {
            self.feedbackHistory = history
        }
    }
    
    /// Saves progress tracking to UserDefaults
    private func saveProgressTracking() {
        if let encodedData = try? JSONEncoder().encode(progressTracking) {
            UserDefaults.standard.set(encodedData, forKey: progressTrackingKey)
        }
    }
    
    /// Loads progress tracking from UserDefaults
    private func loadProgressTracking() {
        if let trackingData = UserDefaults.standard.data(forKey: progressTrackingKey),
           let tracking = try? JSONDecoder().decode([String: FeedbackProgress].self, from: trackingData) {
            self.progressTracking = tracking
        }
    }
}
