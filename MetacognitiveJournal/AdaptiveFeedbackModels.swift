import Foundation
import SwiftUI

/// Represents a feedback response to a child's journal entry or reflection
struct AdaptiveFeedback: Identifiable, Codable {
    let id: UUID
    let childId: String
    let journalEntryId: UUID
    let timestamp: Date
    let feedbackType: FeedbackType
    let content: String
    let supportingDetails: String?
    let followUpPrompts: [String]?
    let suggestedStrategies: [String]?
    let celebratedProgress: String?
    let challenge: MetacognitiveChallenge?
    let learningSupport: LearningSupport?
    let developmentalLevel: ChildJournalMode
    
    init(childId: String,
         journalEntryId: UUID,
         feedbackType: FeedbackType,
         content: String,
         supportingDetails: String? = nil,
         followUpPrompts: [String]? = nil,
         suggestedStrategies: [String]? = nil,
         celebratedProgress: String? = nil,
         challenge: MetacognitiveChallenge? = nil,
         learningSupport: LearningSupport? = nil,
         developmentalLevel: ChildJournalMode) {
        self.id = UUID()
        self.childId = childId
        self.journalEntryId = journalEntryId
        self.timestamp = Date()
        self.feedbackType = feedbackType
        self.content = content
        self.supportingDetails = supportingDetails
        self.followUpPrompts = followUpPrompts
        self.suggestedStrategies = suggestedStrategies
        self.celebratedProgress = celebratedProgress
        self.challenge = challenge
        self.learningSupport = learningSupport
        self.developmentalLevel = developmentalLevel
    }
}

/// Types of feedback that can be provided
enum FeedbackType: String, Codable, CaseIterable {
    case encouragement = "Encouragement"
    case metacognitiveInsight = "Metacognitive Insight"
    case emotionalAwareness = "Emotional Awareness"
    case growthOpportunity = "Growth Opportunity"
    case strategyRecommendation = "Strategy Recommendation"
    case celebrationOfProgress = "Celebration of Progress"
    case reflectionPrompt = "Reflection Prompt"
    case supportiveIntervention = "Supportive Intervention"
    
    /// Returns an icon name for the feedback type
    var iconName: String {
        switch self {
        case .encouragement: return "heart.fill"
        case .metacognitiveInsight: return "brain"
        case .emotionalAwareness: return "face.smiling"
        case .growthOpportunity: return "arrow.up.forward"
        case .strategyRecommendation: return "lightbulb"
        case .celebrationOfProgress: return "star.fill"
        case .reflectionPrompt: return "bubble.left.fill"
        case .supportiveIntervention: return "hand.raised.fill"
        }
    }
    
    /// Returns a color for the feedback type
    var color: Color {
        switch self {
        case .encouragement: return Color(red: 0.9, green: 0.5, blue: 0.5) // Salmon
        case .metacognitiveInsight: return Color(red: 0.4, green: 0.5, blue: 0.9) // Blue
        case .emotionalAwareness: return Color(red: 0.9, green: 0.7, blue: 0.3) // Gold
        case .growthOpportunity: return Color(red: 0.3, green: 0.7, blue: 0.4) // Green
        case .strategyRecommendation: return Color(red: 0.5, green: 0.3, blue: 0.9) // Purple
        case .celebrationOfProgress: return Color(red: 0.9, green: 0.6, blue: 0.3) // Orange
        case .reflectionPrompt: return Color(red: 0.4, green: 0.7, blue: 0.9) // Light Blue
        case .supportiveIntervention: return Color(red: 0.9, green: 0.4, blue: 0.7) // Pink
        }
    }
}

/// Represents a metacognitive challenge offered to the child
struct MetacognitiveChallenge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let steps: [String]
    let targetSkill: MetacognitiveProcess
    let difficulty: ChallengeDifficulty
    let estimatedTimeMinutes: Int
    let completionPrompt: String
    
    init(title: String,
         description: String,
         steps: [String],
         targetSkill: MetacognitiveProcess,
         difficulty: ChallengeDifficulty,
         estimatedTimeMinutes: Int,
         completionPrompt: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.steps = steps
        self.targetSkill = targetSkill
        self.difficulty = difficulty
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.completionPrompt = completionPrompt
    }
}

/// Difficulty levels for metacognitive challenges
enum ChallengeDifficulty: String, Codable, CaseIterable, Comparable {
    case starter = "Starter"
    case explorer = "Explorer"
    case practitioner = "Practitioner"
    case expert = "Expert"
    case master = "Master"
    
    static func < (lhs: ChallengeDifficulty, rhs: ChallengeDifficulty) -> Bool {
        let order: [ChallengeDifficulty] = [.starter, .explorer, .practitioner, .expert, .master]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    /// Returns a child-friendly description based on age
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .starter:
            switch mode {
            case .earlyChildhood: return "Just starting out"
            case .middleChildhood: return "Beginning level"
            case .adolescent: return "Foundational challenge"
            }
        case .explorer:
            switch mode {
            case .earlyChildhood: return "Ready to explore"
            case .middleChildhood: return "Getting comfortable"
            case .adolescent: return "Developing skills"
            }
        case .practitioner:
            switch mode {
            case .earlyChildhood: return "Getting good at it"
            case .middleChildhood: return "Regular practice level"
            case .adolescent: return "Consistent application"
            }
        case .expert:
            switch mode {
            case .earlyChildhood: return "Really good at it"
            case .middleChildhood: return "Advanced skills"
            case .adolescent: return "Sophisticated application"
            }
        case .master:
            switch mode {
            case .earlyChildhood: return "Super brain power"
            case .middleChildhood: return "Master level"
            case .adolescent: return "Expert integration"
            }
        }
    }
}

/// Represents a just-in-time learning support
struct LearningSupport: Identifiable, Codable {
    let id: UUID
    let title: String
    let supportType: SupportType
    let content: String
    let visualAid: String? // Image or icon name
    let exampleScenario: String?
    let practiceActivity: String?
    
    init(title: String,
         supportType: SupportType,
         content: String,
         visualAid: String? = nil,
         exampleScenario: String? = nil,
         practiceActivity: String? = nil) {
        self.id = UUID()
        self.title = title
        self.supportType = supportType
        self.content = content
        self.visualAid = visualAid
        self.exampleScenario = exampleScenario
        self.practiceActivity = practiceActivity
    }
}

/// Types of learning supports
enum SupportType: String, Codable, CaseIterable {
    case strategy = "Learning Strategy"
    case scaffold = "Thinking Scaffold"
    case emotionalRegulation = "Emotional Regulation"
    case visualization = "Visualization Technique"
    case simplification = "Concept Simplification"
    case connection = "Making Connections"
    
    /// Returns an icon name for the support type
    var iconName: String {
        switch self {
        case .strategy: return "lightbulb"
        case .scaffold: return "rectangle.3.offgrid"
        case .emotionalRegulation: return "heart.circle"
        case .visualization: return "eye"
        case .simplification: return "arrow.down.right.and.arrow.up.left"
        case .connection: return "link"
        }
    }
}

/// Represents a feedback pattern that can be recognized in journal entries
struct FeedbackPattern: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let recognitionCriteria: [String]
    let feedbackTemplates: [ChildJournalMode: String]
    let followUpPrompts: [String]
    let suggestedChallenges: [MetacognitiveChallenge]
    
    init(name: String,
         description: String,
         recognitionCriteria: [String],
         feedbackTemplates: [ChildJournalMode: String],
         followUpPrompts: [String],
         suggestedChallenges: [MetacognitiveChallenge]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.recognitionCriteria = recognitionCriteria
        self.feedbackTemplates = feedbackTemplates
        self.followUpPrompts = followUpPrompts
        self.suggestedChallenges = suggestedChallenges
    }
    
    /// Returns the appropriate feedback template for the child's developmental stage
    func feedbackTemplate(for mode: ChildJournalMode) -> String {
        return feedbackTemplates[mode] ?? "Great thinking! You're developing your metacognitive skills."
    }
    
    /// Returns a random follow-up prompt
    var randomFollowUpPrompt: String {
        return followUpPrompts.randomElement() ?? "What else have you noticed about your thinking?"
    }
}

/// Represents a child's progress in receiving and responding to feedback
struct FeedbackProgress: Codable {
    let childId: String
    var feedbackReceived: Int
    var feedbackImplemented: Int
    var challengesCompleted: [UUID]
    var skillProgress: [MetacognitiveProcess: Int] // Skill -> progress level (1-5)
    var favoriteTypes: [FeedbackType: Int] // Type -> frequency of positive response
    var growthAreas: [String]
    var strengthAreas: [String]
    var lastFeedbackDate: Date?
    
    init(childId: String) {
        self.childId = childId
        self.feedbackReceived = 0
        self.feedbackImplemented = 0
        self.challengesCompleted = []
        self.skillProgress = [:]
        self.favoriteTypes = [:]
        self.growthAreas = []
        self.strengthAreas = []
        self.lastFeedbackDate = nil
    }
    
    /// Records that feedback was received
    mutating func recordFeedbackReceived() {
        feedbackReceived += 1
        lastFeedbackDate = Date()
    }
    
    /// Records that feedback was implemented
    mutating func recordFeedbackImplemented(type: FeedbackType) {
        feedbackImplemented += 1
        favoriteTypes[type, default: 0] += 1
    }
    
    /// Records a completed challenge
    mutating func recordChallengeCompleted(_ challengeId: UUID, targetSkill: MetacognitiveProcess) {
        if !challengesCompleted.contains(challengeId) {
            challengesCompleted.append(challengeId)
            skillProgress[targetSkill, default: 0] += 1
        }
    }
    
    /// Adds a growth area
    mutating func addGrowthArea(_ area: String) {
        if !growthAreas.contains(area) {
            growthAreas.append(area)
        }
    }
    
    /// Adds a strength area
    mutating func addStrengthArea(_ area: String) {
        if !strengthAreas.contains(area) {
            strengthAreas.append(area)
        }
    }
    
    /// Gets the most effective feedback types
    func getMostEffectiveTypes(limit: Int = 2) -> [FeedbackType] {
        return favoriteTypes.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}

/// Represents a feedback template with age-appropriate variations
struct FeedbackTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: FeedbackType
    let templates: [ChildJournalMode: String]
    let placeholders: [String]
    let followUpTemplates: [String]
    
    init(name: String,
         type: FeedbackType,
         templates: [ChildJournalMode: String],
         placeholders: [String],
         followUpTemplates: [String]) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.templates = templates
        self.placeholders = placeholders
        self.followUpTemplates = followUpTemplates
    }
    
    /// Returns the appropriate template for the child's developmental stage
    func template(for mode: ChildJournalMode) -> String {
        return templates[mode] ?? templates[.middleChildhood] ?? "Great thinking!"
    }
    
    /// Returns a random follow-up template
    var randomFollowUpTemplate: String {
        return followUpTemplates.randomElement() ?? "What do you think about that?"
    }
}

/// Collection of language patterns for different developmental stages
struct DevelopmentalLanguage: Codable {
    let earlyChildhood: LanguagePatterns
    let middleChildhood: LanguagePatterns
    let adolescent: LanguagePatterns
    
    /// Gets language patterns for a specific developmental stage
    func patternsFor(mode: ChildJournalMode) -> LanguagePatterns {
        switch mode {
        case .earlyChildhood: return earlyChildhood
        case .middleChildhood: return middleChildhood
        case .adolescent: return adolescent
        }
    }
}

/// Language patterns appropriate for a specific developmental stage
struct LanguagePatterns: Codable {
    let encouragementPhrases: [String]
    let transitionPhrases: [String]
    let questionStarters: [String]
    let celebrationPhrases: [String]
    let supportPhrases: [String]
    let challengePhrases: [String]
    let metacognitiveVerbs: [String]
    let emotionalVocabulary: [String]
    
    /// Returns a random phrase of the specified type
    func randomPhrase(type: PhraseType) -> String {
        switch type {
        case .encouragement: return encouragementPhrases.randomElement() ?? "Great job!"
        case .transition: return transitionPhrases.randomElement() ?? "Now,"
        case .question: return questionStarters.randomElement() ?? "What do you think about"
        case .celebration: return celebrationPhrases.randomElement() ?? "Wonderful!"
        case .support: return supportPhrases.randomElement() ?? "I'm here to help."
        case .challenge: return challengePhrases.randomElement() ?? "Try this:"
        }
    }
    
    /// Returns a random metacognitive verb
    var randomMetacognitiveVerb: String {
        return metacognitiveVerbs.randomElement() ?? "think about"
    }
    
    /// Returns a random emotional vocabulary word
    var randomEmotionalWord: String {
        return emotionalVocabulary.randomElement() ?? "feel"
    }
}

/// Types of phrases in language patterns
enum PhraseType {
    case encouragement
    case transition
    case question
    case celebration
    case support
    case challenge
}
