import Foundation

/// Represents the core metacognitive processes based on educational psychology research
enum MetacognitiveProcess: String, Codable, CaseIterable, Identifiable {
    case planning = "Planning"
    case monitoring = "Monitoring"
    case evaluating = "Evaluating"
    case reflecting = "Reflecting"
    case regulating = "Regulating"
    
    var id: String { rawValue }
    
    /// Returns a child-friendly name for the process
    var childFriendlyName: String {
        switch self {
        case .planning:
            return "Getting Ready"
        case .monitoring:
            return "Checking My Progress"
        case .evaluating:
            return "How Did I Do?"
        case .reflecting:
            return "Thinking About My Thinking"
        case .regulating:
            return "Changing My Approach"
        }
    }
    
    /// Returns a description appropriate for the given journal mode
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .planning:
            switch mode {
            case .earlyChildhood:
                return "Thinking about what I want to do and how to do it"
            case .middleChildhood:
                return "Setting goals and figuring out steps to reach them"
            case .adolescent:
                return "Strategizing approaches and anticipating challenges before beginning a task"
            }
        case .monitoring:
            switch mode {
            case .earlyChildhood:
                return "Noticing if I'm doing okay or need help"
            case .middleChildhood:
                return "Checking if I'm on the right track while I'm working"
            case .adolescent:
                return "Assessing progress during a task and identifying when strategies need adjustment"
            }
        case .evaluating:
            switch mode {
            case .earlyChildhood:
                return "Thinking about what went well and what was hard"
            case .middleChildhood:
                return "Looking back at how I did and if I reached my goal"
            case .adolescent:
                return "Analyzing outcomes against objectives and identifying factors that influenced results"
            }
        case .reflecting:
            switch mode {
            case .earlyChildhood:
                return "Noticing how my brain is thinking"
            case .middleChildhood:
                return "Understanding how I learn and solve problems"
            case .adolescent:
                return "Examining my thought processes and recognizing patterns in my thinking"
            }
        case .regulating:
            switch mode {
            case .earlyChildhood:
                return "Trying a different way when something isn't working"
            case .middleChildhood:
                return "Changing my plan when I need to do something differently"
            case .adolescent:
                return "Adapting strategies based on feedback and changing circumstances"
            }
        }
    }
    
    /// Returns an icon name for the process
    var iconName: String {
        switch self {
        case .planning:
            return "list.bullet.clipboard"
        case .monitoring:
            return "gauge"
        case .evaluating:
            return "checkmark.circle"
        case .reflecting:
            return "brain"
        case .regulating:
            return "arrow.triangle.swap"
        }
    }
    
    /// Returns a color for the process
    var color: Color {
        switch self {
        case .planning:
            return Color(red: 0.2, green: 0.5, blue: 0.9)  // Blue
        case .monitoring:
            return Color(red: 0.9, green: 0.6, blue: 0.2)  // Orange
        case .evaluating:
            return Color(red: 0.3, green: 0.7, blue: 0.3)  // Green
        case .reflecting:
            return Color(red: 0.7, green: 0.3, blue: 0.8)  // Purple
        case .regulating:
            return Color(red: 0.9, green: 0.3, blue: 0.4)  // Red
        }
    }
}

/// Represents different learning contexts for metacognitive prompts
enum LearningContext: String, Codable, CaseIterable, Identifiable {
    case academic = "School Learning"
    case social = "Friends & Family"
    case hobby = "Hobbies & Interests"
    case challenge = "Difficult Situations"
    case success = "Accomplishments"
    case emotion = "Feelings & Emotions"
    case curiosity = "Questions & Curiosity"
    
    var id: String { rawValue }
    
    /// Returns an icon name for the context
    var iconName: String {
        switch self {
        case .academic:
            return "book"
        case .social:
            return "person.2"
        case .hobby:
            return "star"
        case .challenge:
            return "mountain.2"
        case .success:
            return "trophy"
        case .emotion:
            return "heart"
        case .curiosity:
            return "questionmark.circle"
        }
    }
    
    /// Returns a color for the context
    var color: Color {
        switch self {
        case .academic:
            return Color(red: 0.2, green: 0.4, blue: 0.8)  // Blue
        case .social:
            return Color(red: 0.8, green: 0.4, blue: 0.7)  // Pink
        case .hobby:
            return Color(red: 0.9, green: 0.7, blue: 0.2)  // Yellow
        case .challenge:
            return Color(red: 0.7, green: 0.3, blue: 0.3)  // Red
        case .success:
            return Color(red: 0.3, green: 0.7, blue: 0.4)  // Green
        case .emotion:
            return Color(red: 0.9, green: 0.4, blue: 0.4)  // Light Red
        case .curiosity:
            return Color(red: 0.4, green: 0.6, blue: 0.8)  // Light Blue
        }
    }
}

/// Represents a metacognitive skill level
enum MetacognitiveLevel: String, Codable, CaseIterable, Comparable {
    case beginner = "Beginner"
    case developing = "Developing"
    case practicing = "Practicing"
    case advancing = "Advancing"
    case proficient = "Proficient"
    
    static func < (lhs: MetacognitiveLevel, rhs: MetacognitiveLevel) -> Bool {
        let order: [MetacognitiveLevel] = [.beginner, .developing, .practicing, .advancing, .proficient]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    /// Returns the next level in progression
    var nextLevel: MetacognitiveLevel? {
        switch self {
        case .beginner: return .developing
        case .developing: return .practicing
        case .practicing: return .advancing
        case .advancing: return .proficient
        case .proficient: return nil
        }
    }
    
    /// Returns a child-friendly description of this level
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .beginner:
            switch mode {
            case .earlyChildhood:
                return "Just starting to notice how I think"
            case .middleChildhood:
                return "Beginning to understand how my brain works"
            case .adolescent:
                return "Developing initial awareness of thought processes"
            }
        case .developing:
            switch mode {
            case .earlyChildhood:
                return "Learning to think about my thinking"
            case .middleChildhood:
                return "Getting better at understanding how I learn"
            case .adolescent:
                return "Building metacognitive awareness and basic strategies"
            }
        case .practicing:
            switch mode {
            case .earlyChildhood:
                return "Practicing how to plan and check my work"
            case .middleChildhood:
                return "Regularly using strategies to help me learn"
            case .adolescent:
                return "Consistently applying metacognitive strategies across contexts"
            }
        case .advancing:
            switch mode {
            case .earlyChildhood:
                return "Getting really good at thinking about my thinking"
            case .middleChildhood:
                return "Using different strategies for different situations"
            case .adolescent:
                return "Adapting metacognitive approaches based on task demands"
            }
        case .proficient:
            switch mode {
            case .earlyChildhood:
                return "I'm a thinking superhero!"
            case .middleChildhood:
                return "Expert at understanding how my brain works best"
            case .adolescent:
                return "Sophisticated metacognitive awareness with flexible strategy application"
            }
        }
    }
}

/// Represents a metacognitive prompt for journaling
struct MetacognitivePrompt: Identifiable, Codable {
    let id: UUID
    let process: MetacognitiveProcess
    let context: LearningContext
    let level: MetacognitiveLevel
    let promptText: String
    let sentenceStarters: [String]
    let followUpQuestions: [String]
    let minimumAge: Int
    let visualCue: String? // Icon or image name
    
    init(process: MetacognitiveProcess, 
         context: LearningContext, 
         level: MetacognitiveLevel, 
         promptText: String, 
         sentenceStarters: [String], 
         followUpQuestions: [String], 
         minimumAge: Int, 
         visualCue: String? = nil) {
        self.id = UUID()
        self.process = process
        self.context = context
        self.level = level
        self.promptText = promptText
        self.sentenceStarters = sentenceStarters
        self.followUpQuestions = followUpQuestions
        self.minimumAge = minimumAge
        self.visualCue = visualCue
    }
    
    /// Returns whether this prompt is appropriate for the given age
    func isAppropriate(for age: Int) -> Bool {
        return age >= minimumAge
    }
    
    /// Returns whether this prompt is appropriate for the given journal mode
    func isAppropriate(for mode: ChildJournalMode) -> Bool {
        switch mode {
        case .earlyChildhood:
            return minimumAge <= 8 && level <= .practicing
        case .middleChildhood:
            return minimumAge <= 12 && level <= .advancing
        case .adolescent:
            return true
        }
    }
}

/// Represents a metacognitive challenge for skill building
struct MetacognitiveChallengeActivity: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let process: MetacognitiveProcess
    let level: MetacognitiveLevel
    let steps: [String]
    let minimumAge: Int
    let estimatedTimeMinutes: Int
    let completionMessage: String
    let learningOutcome: String
    
    init(title: String,
         description: String,
         process: MetacognitiveProcess,
         level: MetacognitiveLevel,
         steps: [String],
         minimumAge: Int,
         estimatedTimeMinutes: Int,
         completionMessage: String,
         learningOutcome: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.process = process
        self.level = level
        self.steps = steps
        self.minimumAge = minimumAge
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.completionMessage = completionMessage
        self.learningOutcome = learningOutcome
    }
    
    /// Returns whether this challenge is appropriate for the given age
    func isAppropriate(for age: Int) -> Bool {
        return age >= minimumAge
    }
    
    /// Returns whether this challenge is appropriate for the given journal mode
    func isAppropriate(for mode: ChildJournalMode) -> Bool {
        switch mode {
        case .earlyChildhood:
            return minimumAge <= 8 && level <= .practicing
        case .middleChildhood:
            return minimumAge <= 12 && level <= .advancing
        case .adolescent:
            return true
        }
    }
}

/// Represents a metacognitive insight that can be recognized and reinforced
struct MetacognitiveInsight: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let process: MetacognitiveProcess
    let level: MetacognitiveLevel
    let recognitionPatterns: [String]
    let reinforcementMessages: [String]
    let nextStepSuggestions: [String]
    
    init(name: String,
         description: String,
         process: MetacognitiveProcess,
         level: MetacognitiveLevel,
         recognitionPatterns: [String],
         reinforcementMessages: [String],
         nextStepSuggestions: [String]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.process = process
        self.level = level
        self.recognitionPatterns = recognitionPatterns
        self.reinforcementMessages = reinforcementMessages
        self.nextStepSuggestions = nextStepSuggestions
    }
    
    /// Returns a random reinforcement message
    var randomReinforcementMessage: String {
        reinforcementMessages.randomElement() ?? "Great metacognitive thinking!"
    }
    
    /// Returns a random next step suggestion
    var randomNextStepSuggestion: String {
        nextStepSuggestions.randomElement() ?? "Keep thinking about your thinking!"
    }
}

/// Represents a user's metacognitive profile
struct MetacognitiveProfile: Codable {
    var userId: String
    var processLevels: [MetacognitiveProcess: MetacognitiveLevel]
    var completedChallenges: [UUID]
    var insightsDiscovered: [UUID]
    var journalEntriesWithMetacognition: Int
    var lastAssessmentDate: Date?
    
    init(userId: String) {
        self.userId = userId
        self.processLevels = [:]
        self.completedChallenges = []
        self.insightsDiscovered = []
        self.journalEntriesWithMetacognition = 0
        self.lastAssessmentDate = nil
        
        // Initialize all processes at beginner level
        for process in MetacognitiveProcess.allCases {
            processLevels[process] = .beginner
        }
    }
    
    /// Returns the overall metacognitive level
    var overallLevel: MetacognitiveLevel {
        let levels = processLevels.values
        let sum = levels.reduce(0) { result, level in
            result + MetacognitiveLevel.allCases.firstIndex(of: level)!
        }
        let average = Double(sum) / Double(levels.count)
        let index = min(Int(round(average)), MetacognitiveLevel.allCases.count - 1)
        return MetacognitiveLevel.allCases[index]
    }
    
    /// Updates the level for a specific process
    mutating func updateLevel(for process: MetacognitiveProcess, to level: MetacognitiveLevel) {
        processLevels[process] = level
    }
    
    /// Adds a completed challenge
    mutating func addCompletedChallenge(_ challengeId: UUID) {
        if !completedChallenges.contains(challengeId) {
            completedChallenges.append(challengeId)
        }
    }
    
    /// Adds a discovered insight
    mutating func addDiscoveredInsight(_ insightId: UUID) {
        if !insightsDiscovered.contains(insightId) {
            insightsDiscovered.append(insightId)
        }
    }
    
    /// Increments the count of journal entries with metacognition
    mutating func incrementJournalEntriesWithMetacognition() {
        journalEntriesWithMetacognition += 1
    }
}

import SwiftUI

extension Color {
    static let metacognitivePlanning = Color(red: 0.2, green: 0.5, blue: 0.9)  // Blue
    static let metacognitiveMonitoring = Color(red: 0.9, green: 0.6, blue: 0.2)  // Orange
    static let metacognitiveEvaluating = Color(red: 0.3, green: 0.7, blue: 0.3)  // Green
    static let metacognitiveReflecting = Color(red: 0.7, green: 0.3, blue: 0.8)  // Purple
    static let metacognitiveRegulating = Color(red: 0.9, green: 0.3, blue: 0.4)  // Red
}
