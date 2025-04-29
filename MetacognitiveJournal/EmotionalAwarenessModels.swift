import Foundation
import SwiftUI

/// Represents an emotion with age-appropriate descriptions and properties
struct Emotion: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let intensity: EmotionIntensity
    let category: EmotionCategory
    let descriptions: [ChildJournalMode: String]
    // Store color components instead of SwiftUI.Color for Codable conformance
    let colorRed: Double
    let colorGreen: Double
    let colorBlue: Double
    let colorOpacity: Double
    var color: Color { // Computed property to access the SwiftUI Color
        Color(red: colorRed, green: colorGreen, blue: colorBlue, opacity: colorOpacity)
    }
    let icon: String
    let relatedEmotions: [String]
    let commonTriggers: [String]
    let bodyFeelings: [String]
    let helpfulThoughts: [String]
    let regulationStrategies: [RegulationStrategyType]
    
    init(name: String,
         intensity: EmotionIntensity,
         category: EmotionCategory,
         descriptions: [ChildJournalMode: String],
         color: Color,
         icon: String,
         relatedEmotions: [String],
         commonTriggers: [String],
         bodyFeelings: [String],
         helpfulThoughts: [String],
         regulationStrategies: [RegulationStrategyType]) {
        self.id = UUID()
        self.name = name
        self.intensity = intensity
        self.category = category
        self.descriptions = descriptions
        // Extract components from the Color struct
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.colorRed = Double(red)
        self.colorGreen = Double(green)
        self.colorBlue = Double(blue)
        self.colorOpacity = Double(alpha)
        self.icon = icon
        self.relatedEmotions = relatedEmotions
        self.commonTriggers = commonTriggers
        self.bodyFeelings = bodyFeelings
        self.helpfulThoughts = helpfulThoughts
        self.regulationStrategies = regulationStrategies
    }
    
    /// Returns the appropriate description for the child's developmental stage
    func description(for mode: ChildJournalMode) -> String {
        return descriptions[mode] ?? "A feeling that everyone has sometimes"
    }
    
    /// Returns whether this emotion is age-appropriate for the given mode
    func isAppropriate(for mode: ChildJournalMode) -> Bool {
        // All basic emotions are appropriate for all ages
        if category == .primary {
            return true
        }
        
        // For complex emotions, check if we have an age-appropriate description
        return descriptions[mode] != nil
    }
    
    /// Returns a simplified version of this emotion for younger children if needed
    func simplified(for mode: ChildJournalMode) -> Emotion? {
        // If the emotion is already appropriate, return nil (no simplification needed)
        if category.isAppropriate(for: mode) {
            return nil
        }
        
        // Otherwise, find a related primary emotion that's appropriate
        // This would be implemented with a lookup to find a simpler alternative
        return nil
    }
    
    static func == (lhs: Emotion, rhs: Emotion) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, name, intensity, category, descriptions, icon, relatedEmotions, commonTriggers, bodyFeelings, helpfulThoughts, regulationStrategies
        // Map color components
        case colorRed, colorGreen, colorBlue, colorOpacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        intensity = try container.decode(EmotionIntensity.self, forKey: .intensity)
        category = try container.decode(EmotionCategory.self, forKey: .category)
        descriptions = try container.decode([ChildJournalMode: String].self, forKey: .descriptions)
        colorRed = try container.decode(Double.self, forKey: .colorRed)
        colorGreen = try container.decode(Double.self, forKey: .colorGreen)
        colorBlue = try container.decode(Double.self, forKey: .colorBlue)
        colorOpacity = try container.decode(Double.self, forKey: .colorOpacity)
        icon = try container.decode(String.self, forKey: .icon)
        relatedEmotions = try container.decode([String].self, forKey: .relatedEmotions)
        commonTriggers = try container.decode([String].self, forKey: .commonTriggers)
        bodyFeelings = try container.decode([String].self, forKey: .bodyFeelings)
        helpfulThoughts = try container.decode([String].self, forKey: .helpfulThoughts)
        regulationStrategies = try container.decode([RegulationStrategyType].self, forKey: .regulationStrategies)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(category, forKey: .category)
        try container.encode(descriptions, forKey: .descriptions)
        try container.encode(colorRed, forKey: .colorRed)
        try container.encode(colorGreen, forKey: .colorGreen)
        try container.encode(colorBlue, forKey: .colorBlue)
        try container.encode(colorOpacity, forKey: .colorOpacity)
        try container.encode(icon, forKey: .icon)
        try container.encode(relatedEmotions, forKey: .relatedEmotions)
        try container.encode(commonTriggers, forKey: .commonTriggers)
        try container.encode(bodyFeelings, forKey: .bodyFeelings)
        try container.encode(helpfulThoughts, forKey: .helpfulThoughts)
        try container.encode(regulationStrategies, forKey: .regulationStrategies)
    }
}

/// Represents the intensity level of an emotion
enum EmotionIntensity: String, Codable, CaseIterable, Comparable {
    case mild = "A little bit"
    case moderate = "Medium"
    case strong = "Very strong"
    
    static func < (lhs: EmotionIntensity, rhs: EmotionIntensity) -> Bool {
        let order: [EmotionIntensity] = [.mild, .moderate, .strong]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    /// Returns a visual representation (e.g., number of waves or flames)
    var visualRepresentation: Int {
        switch self {
        case .mild: return 1
        case .moderate: return 2
        case .strong: return 3
        }
    }
    
    /// Returns a child-friendly description based on age
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .mild:
            switch mode {
            case .earlyChildhood: return "Just a little bit"
            case .middleChildhood: return "Noticeable but manageable"
            case .adolescent: return "Present but not overwhelming"
            }
        case .moderate:
            switch mode {
            case .earlyChildhood: return "Medium strong"
            case .middleChildhood: return "Definitely feeling it"
            case .adolescent: return "Significant intensity"
            }
        case .strong:
            switch mode {
            case .earlyChildhood: return "Really, really strong"
            case .middleChildhood: return "Very powerful feeling"
            case .adolescent: return "Intense and dominant"
            }
        }
    }
}

/// Represents categories of emotions
enum EmotionCategory: String, Codable, CaseIterable {
    case primary = "Basic Emotions"
    case secondary = "Mixed Emotions"
    case complex = "Complex Emotions"
    case learning = "Learning Emotions"
    case social = "Social Emotions"
    
    /// Returns a description appropriate for the child's developmental stage
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .primary:
            return "The main feelings everyone has"
        case .secondary:
            switch mode {
            case .earlyChildhood: return "Feelings that mix together"
            case .middleChildhood: return "Emotions that combine two feelings"
            case .adolescent: return "Emotions that blend multiple basic feelings"
            }
        case .complex:
            switch mode {
            case .earlyChildhood: return "Big feelings that are tricky"
            case .middleChildhood: return "More complicated emotions"
            case .adolescent: return "Sophisticated emotional states with cognitive components"
            }
        case .learning:
            switch mode {
            case .earlyChildhood: return "Feelings about learning new things"
            case .middleChildhood: return "Emotions we have when learning"
            case .adolescent: return "Emotions related to academic and intellectual experiences"
            }
        case .social:
            switch mode {
            case .earlyChildhood: return "Feelings about other people"
            case .middleChildhood: return "Emotions we have with friends and family"
            case .adolescent: return "Emotions connected to social relationships and interactions"
            }
        }
    }
    
    /// Returns whether this category is appropriate for the given mode
    func isAppropriate(for mode: ChildJournalMode) -> Bool {
        switch self {
        case .primary:
            return true // Appropriate for all ages
        case .secondary:
            return true // Appropriate for all ages
        case .complex:
            return mode != .earlyChildhood // Not for youngest children
        case .learning, .social:
            return true // Appropriate for all ages
        }
    }
}

/// Represents a regulation strategy type
enum RegulationStrategyType: String, Codable, CaseIterable, Identifiable {
    case breathing = "Breathing"
    case movement = "Movement"
    case distraction = "Distraction"
    case expression = "Expression"
    case reframing = "Reframing"
    case sensory = "Sensory"
    case social = "Social Support"
    case problemSolving = "Problem Solving"
    case acceptance = "Acceptance"
    case visualization = "Visualization"
    
    var id: String { rawValue }
    
    /// Returns an icon name for the strategy type
    var iconName: String {
        switch self {
        case .breathing: return "wind"
        case .movement: return "figure.walk"
        case .distraction: return "gamecontroller"
        case .expression: return "pencil.and.paper"
        case .reframing: return "brain"
        case .sensory: return "hand.raised.fill"
        case .social: return "person.2.fill"
        case .problemSolving: return "hammer"
        case .acceptance: return "heart.circle"
        case .visualization: return "eye"
        }
    }
    
    /// Returns a color for the strategy type
    var color: Color {
        switch self {
        case .breathing: return Color(red: 0.4, green: 0.7, blue: 0.9) // Light blue
        case .movement: return Color(red: 0.3, green: 0.8, blue: 0.4) // Green
        case .distraction: return Color(red: 0.9, green: 0.6, blue: 0.3) // Orange
        case .expression: return Color(red: 0.8, green: 0.4, blue: 0.8) // Purple
        case .reframing: return Color(red: 0.5, green: 0.5, blue: 0.9) // Lavender
        case .sensory: return Color(red: 0.9, green: 0.4, blue: 0.6) // Pink
        case .social: return Color(red: 0.4, green: 0.6, blue: 0.8) // Blue
        case .problemSolving: return Color(red: 0.7, green: 0.5, blue: 0.3) // Brown
        case .acceptance: return Color(red: 0.9, green: 0.5, blue: 0.5) // Salmon
        case .visualization: return Color(red: 0.5, green: 0.8, blue: 0.8) // Teal
        }
    }
    
    /// Returns a description appropriate for the child's developmental stage
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .breathing:
            switch mode {
            case .earlyChildhood: return "Taking slow breaths to calm down"
            case .middleChildhood: return "Using breathing techniques to regulate emotions"
            case .adolescent: return "Employing breathing exercises to modulate emotional intensity"
            }
        case .movement:
            switch mode {
            case .earlyChildhood: return "Moving your body to feel better"
            case .middleChildhood: return "Using physical activity to change your feelings"
            case .adolescent: return "Engaging in physical movement to process and release emotions"
            }
        case .distraction:
            switch mode {
            case .earlyChildhood: return "Doing something fun to feel better"
            case .middleChildhood: return "Taking a break from big feelings by doing something else"
            case .adolescent: return "Temporarily shifting attention to regulate emotional intensity"
            }
        case .expression:
            switch mode {
            case .earlyChildhood: return "Telling or showing how you feel"
            case .middleChildhood: return "Putting your feelings into words, art, or actions"
            case .adolescent: return "Articulating or creatively expressing emotional experiences"
            }
        case .reframing:
            switch mode {
            case .earlyChildhood: return "Thinking happy thoughts instead"
            case .middleChildhood: return "Changing how you think about a situation"
            case .adolescent: return "Cognitively restructuring your perspective on a situation"
            }
        case .sensory:
            switch mode {
            case .earlyChildhood: return "Using your senses to feel calm"
            case .middleChildhood: return "Finding things that feel, sound, or look calming"
            case .adolescent: return "Utilizing sensory experiences to regulate emotional states"
            }
        case .social:
            switch mode {
            case .earlyChildhood: return "Getting help from someone you trust"
            case .middleChildhood: return "Talking to others when you have big feelings"
            case .adolescent: return "Seeking social connection and support during emotional challenges"
            }
        case .problemSolving:
            switch mode {
            case .earlyChildhood: return "Fixing what made you upset"
            case .middleChildhood: return "Finding solutions to problems causing your feelings"
            case .adolescent: return "Addressing the underlying causes of emotional reactions"
            }
        case .acceptance:
            switch mode {
            case .earlyChildhood: return "It's okay to feel this way"
            case .middleChildhood: return "Accepting that all feelings are okay to have"
            case .adolescent: return "Acknowledging and validating emotions without judgment"
            }
        case .visualization:
            switch mode {
            case .earlyChildhood: return "Imagining happy places"
            case .middleChildhood: return "Using your imagination to picture calming scenes"
            case .adolescent: return "Creating mental imagery to influence emotional states"
            }
        }
    }
}

/// Represents a specific regulation strategy with implementation details
struct RegulationStrategy: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: RegulationStrategyType
    let descriptions: [String: String]
    let steps: [String]
    let minimumAge: Int
    let visualCue: String // Icon or image name
    let journalPrompts: [String]
    let effectiveness: [Emotion.ID: Int] // Track effectiveness for different emotions (1-5)
    
    init(name: String,
         type: RegulationStrategyType,
         descriptions: [String: String],
         steps: [String],
         minimumAge: Int,
         visualCue: String,
         journalPrompts: [String],
         effectiveness: [Emotion.ID: Int] = [:]) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.descriptions = descriptions
        self.steps = steps
        self.minimumAge = minimumAge
        self.visualCue = visualCue
        self.journalPrompts = journalPrompts
        self.effectiveness = effectiveness
    }
    
    /// Returns the appropriate description for the child's developmental stage
    func description(for mode: ChildJournalMode) -> String {
        return descriptions[mode.rawValue] ?? type.description(for: mode)
    }
    
    /// Returns whether this strategy is age-appropriate for the given mode
    func isAppropriate(for mode: ChildJournalMode) -> Bool {
        switch mode {
        case .earlyChildhood:
            return minimumAge <= 8
        case .middleChildhood:
            return minimumAge <= 12
        case .adolescent:
            return true
        }
    }
    
    /// Returns a random journal prompt for reflection after using this strategy
    var randomJournalPrompt: String {
        return journalPrompts.randomElement() ?? "How did this strategy help you with your feelings?"
    }
}

/// Represents a mood entry in the child's journal
struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let emotionId: UUID
    let intensity: EmotionIntensity
    let context: String?
    let triggers: [String]?
    let bodyFeelings: [String]?
    let thoughts: String?
    let behaviors: String?
    let strategiesUsed: [UUID]?
    let strategiesEffectiveness: [UUID: Int]?
    let journalEntryId: UUID?
    
    init(emotionId: UUID,
         intensity: EmotionIntensity,
         context: String? = nil,
         triggers: [String]? = nil,
         bodyFeelings: [String]? = nil,
         thoughts: String? = nil,
         behaviors: String? = nil,
         strategiesUsed: [UUID]? = nil,
         strategiesEffectiveness: [UUID: Int]? = nil,
         journalEntryId: UUID? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.emotionId = emotionId
        self.intensity = intensity
        self.context = context
        self.triggers = triggers
        self.bodyFeelings = bodyFeelings
        self.thoughts = thoughts
        self.behaviors = behaviors
        self.strategiesUsed = strategiesUsed
        self.strategiesEffectiveness = strategiesEffectiveness
        self.journalEntryId = journalEntryId
    }
}

/// Represents a visual metaphor for emotions that children can relate to
struct EmotionalMetaphor: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let applicableEmotions: [UUID]
    let visualAsset: String
    let interactiveElements: [String]
    let journalPrompts: [String]
    let minimumAge: Int
    
    init(name: String,
         description: String,
         applicableEmotions: [UUID],
         visualAsset: String,
         interactiveElements: [String],
         journalPrompts: [String],
         minimumAge: Int) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.applicableEmotions = applicableEmotions
        self.visualAsset = visualAsset
        self.interactiveElements = interactiveElements
        self.journalPrompts = journalPrompts
        self.minimumAge = minimumAge
    }
    
    /// Returns whether this metaphor is age-appropriate for the given mode
    func isAppropriate(for mode: ChildJournalMode) -> Bool {
        switch mode {
        case .earlyChildhood:
            return minimumAge <= 8
        case .middleChildhood:
            return minimumAge <= 12
        case .adolescent:
            return true
        }
    }
}

/// Represents the connection between thoughts, feelings, and behaviors
struct EmotionalConnection: Identifiable, Codable {
    let id: UUID
    let emotionId: UUID
    let commonThoughts: [String]
    let commonBehaviors: [String]
    let alternativeThoughts: [String]
    let helpfulBehaviors: [String]
    let journalPrompts: [String]
    
    init(emotionId: UUID,
         commonThoughts: [String],
         commonBehaviors: [String],
         alternativeThoughts: [String],
         helpfulBehaviors: [String],
         journalPrompts: [String]) {
        self.id = UUID()
        self.emotionId = emotionId
        self.commonThoughts = commonThoughts
        self.commonBehaviors = commonBehaviors
        self.alternativeThoughts = alternativeThoughts
        self.helpfulBehaviors = helpfulBehaviors
        self.journalPrompts = journalPrompts
    }
    
    /// Returns a random journal prompt for exploring this connection
    var randomJournalPrompt: String {
        return journalPrompts.randomElement() ?? "How do your thoughts affect your feelings and actions?"
    }
}

/// Represents a user's emotional awareness profile
struct EmotionalAwarenessProfile: Codable {
    var userId: String
    var recognizedEmotions: [UUID]
    var frequentEmotions: [UUID: Int]
    var effectiveStrategies: [UUID: Int]
    var emotionTriggerPatterns: [String: [UUID]]
    var journalEntriesWithEmotionalContent: Int
    var lastAssessmentDate: Date?
    
    init(userId: String) {
        self.userId = userId
        self.recognizedEmotions = []
        self.frequentEmotions = [:]
        self.effectiveStrategies = [:]
        self.emotionTriggerPatterns = [:]
        self.journalEntriesWithEmotionalContent = 0
        self.lastAssessmentDate = nil
    }
    
    /// Adds a recognized emotion
    mutating func addRecognizedEmotion(_ emotionId: UUID) {
        if !recognizedEmotions.contains(emotionId) {
            recognizedEmotions.append(emotionId)
        }
    }
    
    /// Increments the frequency count for an emotion
    mutating func incrementEmotionFrequency(_ emotionId: UUID) {
        frequentEmotions[emotionId, default: 0] += 1
    }
    
    /// Updates the effectiveness rating for a strategy
    mutating func updateStrategyEffectiveness(_ strategyId: UUID, rating: Int) {
        effectiveStrategies[strategyId] = rating
    }
    
    /// Adds a trigger pattern for an emotion
    mutating func addTriggerPattern(_ trigger: String, for emotionId: UUID) {
        emotionTriggerPatterns[trigger, default: []].append(emotionId)
    }
    
    /// Increments the count of journal entries with emotional content
    mutating func incrementJournalEntriesWithEmotionalContent() {
        journalEntriesWithEmotionalContent += 1
    }
    
    /// Returns the most effective strategies based on ratings
    func getMostEffectiveStrategies(limit: Int = 3) -> [UUID] {
        return effectiveStrategies.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}
