import Foundation
import SwiftUI

/// Represents different academic and non-academic learning areas
enum LearningArea: String, Codable, CaseIterable, Identifiable {
    // Academic subjects
    case math = "Math"
    case reading = "Reading"
    case writing = "Writing"
    case science = "Science"
    case socialStudies = "Social Studies"
    case language = "Languages"
    case arts = "Arts & Music"
    case physicalEducation = "Physical Education"
    
    // Non-academic learning
    case hobby = "Hobbies & Interests"
    case social = "Social Skills"
    case emotional = "Emotional Learning"
    case life = "Life Skills"
    case technology = "Technology"
    case creative = "Creative Projects"
    
    var id: String { rawValue }
    
    /// Returns an icon name for the learning area
    var iconName: String {
        switch self {
        case .math: return "function"
        case .reading: return "book"
        case .writing: return "pencil"
        case .science: return "atom"
        case .socialStudies: return "globe"
        case .language: return "text.bubble"
        case .arts: return "music.note"
        case .physicalEducation: return "figure.run"
        case .hobby: return "star"
        case .social: return "person.2"
        case .emotional: return "heart"
        case .life: return "house"
        case .technology: return "desktopcomputer"
        case .creative: return "paintbrush"
        }
    }
    
    /// Returns a color for the learning area
    var color: Color {
        switch self {
        case .math: return Color(red: 0.2, green: 0.5, blue: 0.9)  // Blue
        case .reading: return Color(red: 0.9, green: 0.3, blue: 0.3)  // Red
        case .writing: return Color(red: 0.3, green: 0.7, blue: 0.4)  // Green
        case .science: return Color(red: 0.7, green: 0.3, blue: 0.8)  // Purple
        case .socialStudies: return Color(red: 0.9, green: 0.6, blue: 0.2)  // Orange
        case .language: return Color(red: 0.5, green: 0.8, blue: 0.9)  // Light Blue
        case .arts: return Color(red: 0.9, green: 0.4, blue: 0.7)  // Pink
        case .physicalEducation: return Color(red: 0.2, green: 0.8, blue: 0.5)  // Teal
        case .hobby: return Color(red: 0.9, green: 0.8, blue: 0.2)  // Yellow
        case .social: return Color(red: 0.6, green: 0.4, blue: 0.8)  // Lavender
        case .emotional: return Color(red: 1.0, green: 0.5, blue: 0.5)  // Salmon
        case .life: return Color(red: 0.6, green: 0.5, blue: 0.3)  // Brown
        case .technology: return Color(red: 0.5, green: 0.5, blue: 0.5)  // Gray
        case .creative: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Amber
        }
    }
    
    /// Returns a child-friendly description based on age
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .math:
            switch mode {
            case .earlyChildhood: return "Numbers and shapes"
            case .middleChildhood: return "Working with numbers and solving math problems"
            case .adolescent: return "Mathematical concepts, problem-solving, and numerical reasoning"
            }
        case .reading:
            switch mode {
            case .earlyChildhood: return "Reading books and stories"
            case .middleChildhood: return "Understanding and enjoying what you read"
            case .adolescent: return "Comprehending and analyzing texts across different genres"
            }
        case .writing:
            switch mode {
            case .earlyChildhood: return "Writing letters and stories"
            case .middleChildhood: return "Expressing your ideas in writing"
            case .adolescent: return "Communicating effectively through various written formats"
            }
        case .science:
            switch mode {
            case .earlyChildhood: return "Exploring how things work"
            case .middleChildhood: return "Learning about nature and doing experiments"
            case .adolescent: return "Scientific inquiry, experimentation, and understanding natural phenomena"
            }
        case .socialStudies:
            switch mode {
            case .earlyChildhood: return "Learning about people and places"
            case .middleChildhood: return "History, geography, and how communities work"
            case .adolescent: return "Historical events, geographical concepts, and civic understanding"
            }
        case .language:
            switch mode {
            case .earlyChildhood: return "Learning new words and languages"
            case .middleChildhood: return "Speaking and understanding different languages"
            case .adolescent: return "Acquiring proficiency in foreign languages and communication"
            }
        case .arts:
            switch mode {
            case .earlyChildhood: return "Drawing, painting, and music"
            case .middleChildhood: return "Creating art and making music"
            case .adolescent: return "Artistic expression, musical composition, and creative interpretation"
            }
        case .physicalEducation:
            switch mode {
            case .earlyChildhood: return "Moving your body and playing games"
            case .middleChildhood: return "Sports, fitness, and teamwork"
            case .adolescent: return "Physical fitness, sports performance, and health maintenance"
            }
        case .hobby:
            switch mode {
            case .earlyChildhood: return "Things you like to do for fun"
            case .middleChildhood: return "Activities you enjoy in your free time"
            case .adolescent: return "Personal interests and activities pursued for enjoyment"
            }
        case .social:
            switch mode {
            case .earlyChildhood: return "Getting along with others"
            case .middleChildhood: return "Making friends and working together"
            case .adolescent: return "Interpersonal relationships and effective communication"
            }
        case .emotional:
            switch mode {
            case .earlyChildhood: return "Understanding feelings"
            case .middleChildhood: return "Knowing and managing your emotions"
            case .adolescent: return "Emotional intelligence and self-regulation"
            }
        case .life:
            switch mode {
            case .earlyChildhood: return "Taking care of yourself"
            case .middleChildhood: return "Important skills for everyday life"
            case .adolescent: return "Practical skills for independence and daily functioning"
            }
        case .technology:
            switch mode {
            case .earlyChildhood: return "Using computers and devices"
            case .middleChildhood: return "Digital skills and online learning"
            case .adolescent: return "Digital literacy, programming, and technological applications"
            }
        case .creative:
            switch mode {
            case .earlyChildhood: return "Making new things"
            case .middleChildhood: return "Creating projects and using your imagination"
            case .adolescent: return "Creative problem-solving and innovative project development"
            }
        }
    }
}

/// Represents different learning strategies
enum LearningStrategy: String, Codable, CaseIterable, Identifiable {
    case visualization = "Visualization"
    case repetition = "Repetition"
    case mnemonics = "Memory Tricks"
    case chunking = "Breaking It Down"
    case questioning = "Asking Questions"
    case teaching = "Teaching Others"
    case practice = "Practice"
    case connection = "Making Connections"
    case summarizing = "Summarizing"
    case collaboration = "Working Together"
    case selfTesting = "Testing Yourself"
    case organization = "Organizing Information"
    case reflection = "Thinking About Learning"
    case realWorld = "Real-World Application"
    
    var id: String { rawValue }
    
    /// Returns an icon name for the strategy
    var iconName: String {
        switch self {
        case .visualization: return "eye"
        case .repetition: return "repeat"
        case .mnemonics: return "brain"
        case .chunking: return "square.grid.2x2"
        case .questioning: return "questionmark.circle"
        case .teaching: return "person.2"
        case .practice: return "figure.walk"
        case .connection: return "link"
        case .summarizing: return "list.bullet"
        case .collaboration: return "person.3"
        case .selfTesting: return "checkmark.circle"
        case .organization: return "folder"
        case .reflection: return "thought.bubble"
        case .realWorld: return "globe"
        }
    }
    
    /// Returns a color for the strategy
    var color: Color {
        switch self {
        case .visualization: return Color(red: 0.4, green: 0.7, blue: 0.9)  // Light blue
        case .repetition: return Color(red: 0.3, green: 0.8, blue: 0.4)  // Green
        case .mnemonics: return Color(red: 0.9, green: 0.6, blue: 0.3)  // Orange
        case .chunking: return Color(red: 0.8, green: 0.4, blue: 0.8)  // Purple
        case .questioning: return Color(red: 0.5, green: 0.5, blue: 0.9)  // Lavender
        case .teaching: return Color(red: 0.9, green: 0.4, blue: 0.6)  // Pink
        case .practice: return Color(red: 0.4, green: 0.6, blue: 0.8)  // Blue
        case .connection: return Color(red: 0.7, green: 0.5, blue: 0.3)  // Brown
        case .summarizing: return Color(red: 0.9, green: 0.5, blue: 0.5)  // Salmon
        case .collaboration: return Color(red: 0.5, green: 0.8, blue: 0.8)  // Teal
        case .selfTesting: return Color(red: 0.7, green: 0.9, blue: 0.3)  // Lime
        case .organization: return Color(red: 0.6, green: 0.6, blue: 0.6)  // Gray
        case .reflection: return Color(red: 0.7, green: 0.3, blue: 0.8)  // Purple
        case .realWorld: return Color(red: 0.2, green: 0.7, blue: 0.5)  // Teal
        }
    }
    
    /// Returns a child-friendly description based on age
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .visualization:
            switch mode {
            case .earlyChildhood: return "Making pictures in your mind"
            case .middleChildhood: return "Creating mental images of what you're learning"
            case .adolescent: return "Creating mental representations of concepts and information"
            }
        case .repetition:
            switch mode {
            case .earlyChildhood: return "Practicing over and over"
            case .middleChildhood: return "Repeating information to remember it better"
            case .adolescent: return "Systematic repetition to strengthen neural pathways and retention"
            }
        case .mnemonics:
            switch mode {
            case .earlyChildhood: return "Special tricks to remember things"
            case .middleChildhood: return "Memory tricks like rhymes or funny sentences"
            case .adolescent: return "Creating memory aids like acronyms or associative techniques"
            }
        case .chunking:
            switch mode {
            case .earlyChildhood: return "Breaking big things into little pieces"
            case .middleChildhood: return "Dividing information into smaller, manageable parts"
            case .adolescent: return "Organizing information into meaningful groups for easier processing"
            }
        case .questioning:
            switch mode {
            case .earlyChildhood: return "Asking lots of questions"
            case .middleChildhood: return "Being curious and asking why and how"
            case .adolescent: return "Generating questions to deepen understanding and critical thinking"
            }
        case .teaching:
            switch mode {
            case .earlyChildhood: return "Showing someone else what you learned"
            case .middleChildhood: return "Explaining what you know to someone else"
            case .adolescent: return "Reinforcing understanding by explaining concepts to others"
            }
        case .practice:
            switch mode {
            case .earlyChildhood: return "Doing it again and again"
            case .middleChildhood: return "Working on skills until they get easier"
            case .adolescent: return "Deliberate practice with focused attention on improvement"
            }
        case .connection:
            switch mode {
            case .earlyChildhood: return "Finding how things go together"
            case .middleChildhood: return "Connecting new information to things you already know"
            case .adolescent: return "Creating meaningful associations between new and existing knowledge"
            }
        case .summarizing:
            switch mode {
            case .earlyChildhood: return "Telling the main ideas"
            case .middleChildhood: return "Putting information in your own words"
            case .adolescent: return "Distilling key concepts into concise, meaningful summaries"
            }
        case .collaboration:
            switch mode {
            case .earlyChildhood: return "Learning with friends"
            case .middleChildhood: return "Working together in groups to learn"
            case .adolescent: return "Engaging in collaborative learning and discussion with peers"
            }
        case .selfTesting:
            switch mode {
            case .earlyChildhood: return "Checking what you remember"
            case .middleChildhood: return "Testing yourself to see what you've learned"
            case .adolescent: return "Using retrieval practice to strengthen memory and identify gaps"
            }
        case .organization:
            switch mode {
            case .earlyChildhood: return "Putting things in order"
            case .middleChildhood: return "Organizing information in a way that makes sense"
            case .adolescent: return "Structuring information logically to enhance understanding and recall"
            }
        case .reflection:
            switch mode {
            case .earlyChildhood: return "Thinking about what you learned"
            case .middleChildhood: return "Taking time to think about how you learned"
            case .adolescent: return "Metacognitive analysis of your learning process and outcomes"
            }
        case .realWorld:
            switch mode {
            case .earlyChildhood: return "Using what you learn in real life"
            case .middleChildhood: return "Finding ways to use new knowledge in everyday life"
            case .adolescent: return "Applying concepts to authentic contexts and real-world situations"
            }
        }
    }
    
    /// Returns example applications for different learning areas
    func examples(for area: LearningArea) -> [String] {
        switch self {
        case .visualization:
            switch area {
            case .math: return ["Picturing number lines", "Visualizing shapes and angles"]
            case .reading: return ["Creating mental images of story scenes", "Visualizing characters"]
            case .science: return ["Imagining molecules moving", "Picturing the solar system"]
            default: return ["Creating mental pictures of what you're learning"]
            }
        case .repetition:
            switch area {
            case .math: return ["Practicing multiplication tables", "Repeating formula steps"]
            case .language: return ["Repeating vocabulary words", "Practicing pronunciation"]
            case .arts: return ["Repeating musical scales", "Practicing brush strokes"]
            default: return ["Practicing key information multiple times"]
            }
        // Additional cases would be implemented similarly
        default: return ["Using this strategy to help with \(area.rawValue)"]
        }
    }
}

/// Represents different learning preferences
enum LearningPreference: String, Codable, CaseIterable, Identifiable {
    case visual = "Visual"
    case auditory = "Auditory"
    case kinesthetic = "Hands-on"
    case reading = "Reading/Writing"
    case social = "Social Learning"
    case solitary = "Independent Learning"
    case logical = "Logical/Mathematical"
    case verbal = "Verbal"
    
    var id: String { rawValue }
    
    /// Returns an icon name for the preference
    var iconName: String {
        switch self {
        case .visual: return "eye"
        case .auditory: return "ear"
        case .kinesthetic: return "hand.raised"
        case .reading: return "book"
        case .social: return "person.2"
        case .solitary: return "person"
        case .logical: return "function"
        case .verbal: return "text.bubble"
        }
    }
    
    /// Returns a color for the preference
    var color: Color {
        switch self {
        case .visual: return Color(red: 0.4, green: 0.7, blue: 0.9)  // Light blue
        case .auditory: return Color(red: 0.9, green: 0.6, blue: 0.3)  // Orange
        case .kinesthetic: return Color(red: 0.3, green: 0.8, blue: 0.4)  // Green
        case .reading: return Color(red: 0.7, green: 0.3, blue: 0.8)  // Purple
        case .social: return Color(red: 0.9, green: 0.4, blue: 0.6)  // Pink
        case .solitary: return Color(red: 0.5, green: 0.5, blue: 0.9)  // Lavender
        case .logical: return Color(red: 0.5, green: 0.8, blue: 0.8)  // Teal
        case .verbal: return Color(red: 0.9, green: 0.5, blue: 0.5)  // Salmon
        }
    }
    
    /// Returns a child-friendly description based on age
    func description(for mode: ChildJournalMode) -> String {
        switch self {
        case .visual:
            switch mode {
            case .earlyChildhood: return "Learning by seeing pictures and videos"
            case .middleChildhood: return "Understanding best through images, diagrams, and watching"
            case .adolescent: return "Processing information effectively through visual representations and demonstrations"
            }
        case .auditory:
            switch mode {
            case .earlyChildhood: return "Learning by listening and hearing"
            case .middleChildhood: return "Understanding best through listening and talking"
            case .adolescent: return "Processing information effectively through verbal explanations and discussions"
            }
        case .kinesthetic:
            switch mode {
            case .earlyChildhood: return "Learning by moving and touching"
            case .middleChildhood: return "Understanding best through hands-on activities"
            case .adolescent: return "Processing information effectively through physical interaction and experiential learning"
            }
        case .reading:
            switch mode {
            case .earlyChildhood: return "Learning from books and writing"
            case .middleChildhood: return "Understanding best through reading and writing things down"
            case .adolescent: return "Processing information effectively through textual content and written expression"
            }
        case .social:
            switch mode {
            case .earlyChildhood: return "Learning with other people"
            case .middleChildhood: return "Understanding best when working with others"
            case .adolescent: return "Processing information effectively through group discussion and collaborative work"
            }
        case .solitary:
            switch mode {
            case .earlyChildhood: return "Learning by yourself"
            case .middleChildhood: return "Understanding best when working alone"
            case .adolescent: return "Processing information effectively through independent study and reflection"
            }
        case .logical:
            switch mode {
            case .earlyChildhood: return "Learning by figuring things out step by step"
            case .middleChildhood: return "Understanding best through patterns and reasoning"
            case .adolescent: return "Processing information effectively through logical analysis and systematic approaches"
            }
        case .verbal:
            switch mode {
            case .earlyChildhood: return "Learning by talking and using words"
            case .middleChildhood: return "Understanding best through speaking and using language"
            case .adolescent: return "Processing information effectively through linguistic expression and verbal processing"
            }
        }
    }
    
    /// Returns recommended strategies for this learning preference
    func recommendedStrategies() -> [LearningStrategy] {
        switch self {
        case .visual:
            return [.visualization, .organization, .connection]
        case .auditory:
            return [.teaching, .questioning, .summarizing]
        case .kinesthetic:
            return [.practice, .realWorld, .chunking]
        case .reading:
            return [.summarizing, .organization, .selfTesting]
        case .social:
            return [.collaboration, .teaching, .questioning]
        case .solitary:
            return [.reflection, .selfTesting, .organization]
        case .logical:
            return [.chunking, .connection, .questioning]
        case .verbal:
            return [.teaching, .summarizing, .mnemonics]
        }
    }
}

/// Represents a learning challenge in a specific area
struct LearningChallenge: Identifiable, Codable {
    let id: UUID
    let name: String
    let area: LearningArea
    let description: String
    let commonEmotions: [String]
    let recommendedStrategies: [LearningStrategy]
    let supportingPrompts: [String]
    let growthMindsetStatements: [String]
    
    init(name: String,
         area: LearningArea,
         description: String,
         commonEmotions: [String],
         recommendedStrategies: [LearningStrategy],
         supportingPrompts: [String],
         growthMindsetStatements: [String]) {
        self.id = UUID()
        self.name = name
        self.area = area
        self.description = description
        self.commonEmotions = commonEmotions
        self.recommendedStrategies = recommendedStrategies
        self.supportingPrompts = supportingPrompts
        self.growthMindsetStatements = growthMindsetStatements
    }
    
    /// Returns a random supporting prompt
    var randomSupportingPrompt: String {
        return supportingPrompts.randomElement() ?? "How could you approach this challenge differently?"
    }
    
    /// Returns a random growth mindset statement
    var randomGrowthMindsetStatement: String {
        return growthMindsetStatements.randomElement() ?? "Your brain grows when you face challenges!"
    }
}

/// Represents a learning goal with tracking
struct LearningGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let area: LearningArea
    let createdDate: Date
    let targetDate: Date?
    var steps: [LearningGoalStep]
    let reflectionPrompts: [String]
    var completedDate: Date?
    var progress: Double // 0.0 to 1.0
    
    init(title: String,
         description: String,
         area: LearningArea,
         targetDate: Date? = nil,
         steps: [LearningGoalStep] = [],
         reflectionPrompts: [String] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.area = area
        self.createdDate = Date()
        self.targetDate = targetDate
        self.steps = steps
        self.reflectionPrompts = reflectionPrompts
        self.completedDate = nil
        self.progress = 0.0
    }
    
    /// Returns whether the goal is completed
    var isCompleted: Bool {
        return completedDate != nil
    }
    
    /// Returns whether the goal is overdue
    var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return !isCompleted && Date() > targetDate
    }
    
    /// Returns a random reflection prompt
    var randomReflectionPrompt: String {
        return reflectionPrompts.randomElement() ?? "How are you progressing toward this goal?"
    }
}

/// Represents a step in a learning goal
struct LearningGoalStep: Identifiable, Codable {
    let id: UUID
    let description: String
    var isCompleted: Bool
    var completedDate: Date?
    
    init(description: String) {
        self.id = UUID()
        self.description = description
        self.isCompleted = false
        self.completedDate = nil
    }
}

/// Represents a learning experience reflection
struct LearningReflection: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let area: LearningArea
    let topic: String
    let whatLearned: String
    let howLearned: String
    let challenges: String?
    let strategies: [LearningStrategy]
    let emotions: [String]
    let connections: String?
    let nextSteps: String?
    let relatedGoalIds: [UUID]?
    
    init(area: LearningArea,
         topic: String,
         whatLearned: String,
         howLearned: String,
         challenges: String? = nil,
         strategies: [LearningStrategy] = [],
         emotions: [String] = [],
         connections: String? = nil,
         nextSteps: String? = nil,
         relatedGoalIds: [UUID]? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.area = area
        self.topic = topic
        self.whatLearned = whatLearned
        self.howLearned = howLearned
        self.challenges = challenges
        self.strategies = strategies
        self.emotions = emotions
        self.connections = connections
        self.nextSteps = nextSteps
        self.relatedGoalIds = relatedGoalIds
    }
}

/// Represents a user's learning profile
struct LearningProfile: Codable {
    var userId: String
    var preferredLearningAreas: [LearningArea]
    var challengingLearningAreas: [LearningArea]
    var effectiveStrategies: [LearningStrategy: Int] // Strategy -> effectiveness rating
    var learningPreferences: [LearningPreference: Int] // Preference -> strength rating
    var completedGoals: Int
    var reflectionsCount: [LearningArea: Int] // Area -> number of reflections
    var growthPoints: Int
    
    init(userId: String) {
        self.userId = userId
        self.preferredLearningAreas = []
        self.challengingLearningAreas = []
        self.effectiveStrategies = [:]
        self.learningPreferences = [:]
        self.completedGoals = 0
        self.reflectionsCount = [:]
        self.growthPoints = 0
    }
    
    /// Updates the effectiveness rating for a strategy
    mutating func updateStrategyEffectiveness(_ strategy: LearningStrategy, rating: Int) {
        effectiveStrategies[strategy] = rating
    }
    
    /// Updates the strength rating for a learning preference
    mutating func updateLearningPreference(_ preference: LearningPreference, rating: Int) {
        learningPreferences[preference] = rating
    }
    
    /// Adds a preferred learning area
    mutating func addPreferredArea(_ area: LearningArea) {
        if !preferredLearningAreas.contains(area) {
            preferredLearningAreas.append(area)
        }
    }
    
    /// Adds a challenging learning area
    mutating func addChallengingArea(_ area: LearningArea) {
        if !challengingLearningAreas.contains(area) {
            challengingLearningAreas.append(area)
        }
    }
    
    /// Increments the count of reflections for an area
    mutating func incrementReflectionCount(for area: LearningArea) {
        reflectionsCount[area, default: 0] += 1
    }
    
    /// Increments the count of completed goals
    mutating func incrementCompletedGoals() {
        completedGoals += 1
    }
    
    /// Adds growth points for metacognitive achievements
    mutating func addGrowthPoints(_ points: Int) {
        growthPoints += points
    }
    
    /// Returns the most effective strategies based on ratings
    func getMostEffectiveStrategies(limit: Int = 3) -> [LearningStrategy] {
        return effectiveStrategies.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
    
    /// Returns the strongest learning preferences
    func getStrongestPreferences(limit: Int = 2) -> [LearningPreference] {
        return learningPreferences.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}

/// Represents a growth mindset achievement
struct GrowthMindsetAchievement: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let pointValue: Int
    let congratulatoryMessage: String
    
    init(name: String,
         description: String,
         iconName: String,
         pointValue: Int,
         congratulatoryMessage: String) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.iconName = iconName
        self.pointValue = pointValue
        self.congratulatoryMessage = congratulatoryMessage
    }
}
