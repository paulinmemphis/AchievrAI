import Foundation
import SwiftUI
import Combine

/// Manages the learning reflection framework
class LearningReflectionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// The user's learning profile
    @Published var learningProfile: LearningProfile
    
    /// Available learning challenges by area
    @Published var learningChallenges: [LearningArea: [LearningChallenge]] = [:]
    
    /// User's active learning goals
    @Published var activeGoals: [LearningGoal] = []
    
    /// User's completed learning goals
    @Published var completedGoals: [LearningGoal] = []
    
    /// User's learning reflections
    @Published var reflections: [LearningReflection] = []
    
    /// Growth mindset achievements
    @Published var achievements: [GrowthMindsetAchievement] = []
    
    /// User's earned achievements
    @Published var earnedAchievements: [UUID] = []
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private let profileKey = "learningProfile"
    private let goalsKey = "learningGoals"
    private let reflectionsKey = "learningReflections"
    private let achievementsKey = "earnedAchievements"
    
    /// Child's journal mode for age-appropriate content
    private var journalMode: ChildJournalMode = .middleChildhood
    
    // MARK: - Initialization
    
    init(userId: String) {
        // Initialize with empty profile or load existing
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(LearningProfile.self, from: profileData) {
            self.learningProfile = profile
        } else {
            self.learningProfile = LearningProfile(userId: userId)
        }
        
        // Load goals, reflections, and achievements
        loadGoals()
        loadReflections()
        loadAchievements()
        
        // Set journal mode based on user profile if available
        if let modeString = UserDefaults.standard.string(forKey: "childJournalMode"),
           let mode = ChildJournalMode(rawValue: modeString) {
            self.journalMode = mode
        }
        
        // Initialize learning challenges
        initializeLearningChallenges()
        
        // Initialize growth mindset achievements
        initializeAchievements()
    }
    
    // MARK: - Learning Profile Methods
    
    /// Updates the user's learning profile
    func updateProfile(_ profile: LearningProfile) {
        self.learningProfile = profile
        saveProfile()
    }
    
    /// Updates a learning preference strength
    func updateLearningPreference(_ preference: LearningPreference, strength: Int) {
        learningProfile.updateLearningPreference(preference, rating: strength)
        saveProfile()
    }
    
    /// Updates a strategy effectiveness rating
    func updateStrategyEffectiveness(_ strategy: LearningStrategy, rating: Int) {
        learningProfile.updateStrategyEffectiveness(strategy, rating: rating)
        saveProfile()
    }
    
    /// Adds a preferred learning area
    func addPreferredArea(_ area: LearningArea) {
        learningProfile.addPreferredArea(area)
        saveProfile()
    }
    
    /// Adds a challenging learning area
    func addChallengingArea(_ area: LearningArea) {
        learningProfile.addChallengingArea(area)
        saveProfile()
    }
    
    // MARK: - Learning Goals Methods
    
    /// Creates a new learning goal
    func createGoal(title: String, description: String, area: LearningArea, targetDate: Date? = nil, steps: [String] = []) {
        let goalSteps = steps.map { LearningGoalStep(description: $0) }
        
        let reflectionPrompts = generateReflectionPrompts(for: area, journalMode: journalMode)
        
        let newGoal = LearningGoal(
            title: title,
            description: description,
            area: area,
            targetDate: targetDate,
            steps: goalSteps,
            reflectionPrompts: reflectionPrompts
        )
        
        activeGoals.append(newGoal)
        saveGoals()
        
        // Check for achievement
        checkForAchievement(.goalSetter)
    }
    
    /// Updates the progress of a learning goal
    func updateGoalProgress(_ goalId: UUID, progress: Double) {
        if let index = activeGoals.firstIndex(where: { $0.id == goalId }) {
            activeGoals[index].progress = min(1.0, max(0.0, progress))
            
            // Check if goal is now complete
            if activeGoals[index].progress >= 1.0 {
                completeGoal(goalId)
            } else {
                saveGoals()
            }
        }
    }
    
    /// Completes a goal step
    func completeGoalStep(_ goalId: UUID, stepId: UUID) {
        if let goalIndex = activeGoals.firstIndex(where: { $0.id == goalId }) {
            if let stepIndex = activeGoals[goalIndex].steps.firstIndex(where: { $0.id == stepId }) {
                activeGoals[goalIndex].steps[stepIndex].isCompleted = true
                activeGoals[goalIndex].steps[stepIndex].completedDate = Date()
                
                // Update overall progress
                let completedSteps = activeGoals[goalIndex].steps.filter { $0.isCompleted }.count
                let totalSteps = activeGoals[goalIndex].steps.count
                activeGoals[goalIndex].progress = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0.0
                
                // Check if all steps are complete
                if completedSteps == totalSteps {
                    completeGoal(goalId)
                } else {
                    saveGoals()
                }
                
                // Check for achievement
                checkForAchievement(.progressMaker)
            }
        }
    }
    
    /// Marks a goal as complete
    func completeGoal(_ goalId: UUID) {
        if let index = activeGoals.firstIndex(where: { $0.id == goalId }) {
            var completedGoal = activeGoals[index]
            completedGoal.completedDate = Date()
            completedGoal.progress = 1.0
            
            // Move from active to completed
            activeGoals.remove(at: index)
            completedGoals.append(completedGoal)
            
            // Update profile stats
            learningProfile.incrementCompletedGoals()
            learningProfile.addGrowthPoints(10)
            
            saveGoals()
            saveProfile()
            
            // Check for achievements
            checkForAchievement(.goalAchiever)
            if learningProfile.completedGoals >= 5 {
                checkForAchievement(.persistentLearner)
            }
        }
    }
    
    // MARK: - Learning Reflection Methods
    
    /// Creates a new learning reflection
    func createReflection(area: LearningArea, 
                          topic: String,
                          whatLearned: String,
                          howLearned: String,
                          challenges: String? = nil,
                          strategies: [LearningStrategy] = [],
                          emotions: [String] = [],
                          connections: String? = nil,
                          nextSteps: String? = nil,
                          relatedGoalIds: [UUID]? = nil) {
        
        let newReflection = LearningReflection(
            area: area,
            topic: topic,
            whatLearned: whatLearned,
            howLearned: howLearned,
            challenges: challenges,
            strategies: strategies,
            emotions: emotions,
            connections: connections,
            nextSteps: nextSteps,
            relatedGoalIds: relatedGoalIds
        )
        
        reflections.append(newReflection)
        
        // Update profile stats
        learningProfile.incrementReflectionCount(for: area)
        learningProfile.addGrowthPoints(5)
        
        // Update strategy effectiveness if provided
        for strategy in strategies {
            let currentRating = learningProfile.effectiveStrategies[strategy, default: 0]
            learningProfile.updateStrategyEffectiveness(strategy, rating: currentRating + 1)
        }
        
        saveReflections()
        saveProfile()
        
        // Check for achievements
        checkForAchievement(.reflectiveThinker)
        if reflections.count >= 10 {
            checkForAchievement(.metacognitiveMaster)
        }
    }
    
    /// Gets reflections for a specific learning area
    func getReflections(for area: LearningArea) -> [LearningReflection] {
        return reflections.filter { $0.area == area }
    }
    
    /// Gets reflections related to a specific goal
    func getReflections(for goalId: UUID) -> [LearningReflection] {
        return reflections.filter { $0.relatedGoalIds?.contains(goalId) == true }
    }
    
    // MARK: - Learning Challenges Methods
    
    /// Gets challenges for a specific learning area
    func getChallenges(for area: LearningArea) -> [LearningChallenge] {
        return learningChallenges[area] ?? []
    }
    
    /// Gets age-appropriate challenges for the current journal mode
    func getAgeSuitableChallenges() -> [LearningChallenge] {
        var suitableChallenges: [LearningChallenge] = []
        
        for challenges in learningChallenges.values {
            for challenge in challenges {
                // Filter based on journal mode
                // In a real implementation, we would have more sophisticated filtering
                suitableChallenges.append(challenge)
            }
        }
        
        return suitableChallenges
    }
    
    // MARK: - Growth Mindset Methods
    
    /// Checks if an achievement has been earned and awards it if not already earned
    func checkForAchievement(_ type: AchievementType) {
        let achievementId = getAchievementId(for: type)
        
        if let id = achievementId, !earnedAchievements.contains(id) {
            earnedAchievements.append(id)
            
            if let achievement = achievements.first(where: { $0.id == id }) {
                learningProfile.addGrowthPoints(achievement.pointValue)
            }
            
            saveAchievements()
            saveProfile()
        }
    }
    
    /// Gets earned achievements
    func getEarnedAchievements() -> [GrowthMindsetAchievement] {
        return achievements.filter { earnedAchievements.contains($0.id) }
    }
    
    /// Gets unearned achievements
    func getUnearnedAchievements() -> [GrowthMindsetAchievement] {
        return achievements.filter { !earnedAchievements.contains($0.id) }
    }
    
    // MARK: - Recommendation Methods
    
    /// Gets recommended strategies for a specific learning area
    func getRecommendedStrategies(for area: LearningArea) -> [LearningStrategy] {
        // First check if we have effective strategies from user history
        let effectiveStrategies = learningProfile.getMostEffectiveStrategies(limit: 2)
        
        // Get strategies recommended for the user's learning preferences
        let preferenceStrategies = learningProfile.getStrongestPreferences()
            .flatMap { $0.recommendedStrategies() }
        
        // Combine and remove duplicates
        var recommendations = effectiveStrategies
        for strategy in preferenceStrategies {
            if !recommendations.contains(strategy) {
                recommendations.append(strategy)
            }
            if recommendations.count >= 5 {
                break
            }
        }
        
        // If we still need more, add some general good strategies for the area
        if recommendations.count < 3 {
            let generalStrategies: [LearningStrategy]
            
            switch area {
            case .math:
                generalStrategies = [.practice, .chunking, .visualization]
            case .reading:
                generalStrategies = [.visualization, .questioning, .connection]
            case .writing:
                generalStrategies = [.organization, .chunking, .reflection]
            case .science:
                generalStrategies = [.questioning, .connection, .visualization]
            case .socialStudies:
                generalStrategies = [.connection, .visualization, .summarizing]
            case .language:
                generalStrategies = [.repetition, .mnemonics, .practice]
            case .arts:
                generalStrategies = [.practice, .reflection, .realWorld]
            case .physicalEducation:
                generalStrategies = [.practice, .chunking, .reflection]
            case .hobby:
                generalStrategies = [.practice, .realWorld, .reflection]
            case .social:
                generalStrategies = [.reflection, .realWorld, .teaching]
            case .emotional:
                generalStrategies = [.reflection, .connection, .visualization]
            case .life:
                generalStrategies = [.realWorld, .practice, .reflection]
            case .technology:
                generalStrategies = [.practice, .chunking, .teaching]
            case .creative:
                generalStrategies = [.visualization, .connection, .reflection]
            }
            
            for strategy in generalStrategies {
                if !recommendations.contains(strategy) {
                    recommendations.append(strategy)
                }
                if recommendations.count >= 5 {
                    break
                }
            }
        }
        
        return Array(recommendations.prefix(5))
    }
    
    /// Gets reflection prompts for a specific learning area and journal mode
    func getReflectionPrompts(for area: LearningArea) -> [String] {
        return generateReflectionPrompts(for: area, journalMode: journalMode)
    }
    
    // MARK: - Private Helper Methods
    
    /// Saves the user's learning profile to UserDefaults
    private func saveProfile() {
        if let encodedData = try? JSONEncoder().encode(learningProfile) {
            UserDefaults.standard.set(encodedData, forKey: profileKey)
        }
    }
    
    /// Saves goals to UserDefaults
    private func saveGoals() {
        let allGoals = activeGoals + completedGoals
        if let encodedData = try? JSONEncoder().encode(allGoals) {
            UserDefaults.standard.set(encodedData, forKey: goalsKey)
        }
    }
    
    /// Loads goals from UserDefaults
    private func loadGoals() {
        if let goalsData = UserDefaults.standard.data(forKey: goalsKey),
           let goals = try? JSONDecoder().decode([LearningGoal].self, from: goalsData) {
            activeGoals = goals.filter { $0.completedDate == nil }
            completedGoals = goals.filter { $0.completedDate != nil }
        }
    }
    
    /// Saves reflections to UserDefaults
    private func saveReflections() {
        if let encodedData = try? JSONEncoder().encode(reflections) {
            UserDefaults.standard.set(encodedData, forKey: reflectionsKey)
        }
    }
    
    /// Loads reflections from UserDefaults
    private func loadReflections() {
        if let reflectionsData = UserDefaults.standard.data(forKey: reflectionsKey),
           let loadedReflections = try? JSONDecoder().decode([LearningReflection].self, from: reflectionsData) {
            reflections = loadedReflections
        }
    }
    
    /// Saves earned achievements to UserDefaults
    private func saveAchievements() {
        UserDefaults.standard.set(earnedAchievements.map { $0.uuidString }, forKey: achievementsKey)
    }
    
    /// Loads earned achievements from UserDefaults
    private func loadAchievements() {
        if let achievementStrings = UserDefaults.standard.stringArray(forKey: achievementsKey) {
            earnedAchievements = achievementStrings.compactMap { UUID(uuidString: $0) }
        }
    }
    
    /// Initializes learning challenges
    private func initializeLearningChallenges() {
        // Initialize with predefined challenges
        // In a real app, this might load from a database or API
        
        // Math challenges
        let mathChallenges = [
            LearningChallenge(
                name: "Math Anxiety",
                area: .math,
                description: "Feeling nervous or worried when doing math",
                commonEmotions: ["Anxiety", "Frustration", "Worry"],
                recommendedStrategies: [.chunking, .practice, .visualization],
                supportingPrompts: [
                    "What specific part of math makes you feel nervous?",
                    "When did you start feeling this way about math?",
                    "What's one small math problem you feel confident solving?"
                ],
                growthMindsetStatements: [
                    "Math skills grow with practice, just like muscles.",
                    "Making mistakes in math helps your brain grow stronger.",
                    "Many successful people struggled with math at first."
                ]
            ),
            LearningChallenge(
                name: "Problem-Solving Blocks",
                area: .math,
                description: "Getting stuck when trying to solve math problems",
                commonEmotions: ["Confusion", "Frustration", "Overwhelm"],
                recommendedStrategies: [.chunking, .visualization, .questioning],
                supportingPrompts: [
                    "What do you understand about the problem so far?",
                    "Could you draw a picture of what the problem is asking?",
                    "What's one strategy you could try first?"
                ],
                growthMindsetStatements: [
                    "Getting stuck is part of the learning process.",
                    "Each problem you tackle makes your brain stronger.",
                    "Great mathematicians get stuck too - they just keep trying."
                ]
            )
        ]
        
        // Reading challenges
        let readingChallenges = [
            LearningChallenge(
                name: "Reading Comprehension",
                area: .reading,
                description: "Difficulty understanding what you read",
                commonEmotions: ["Confusion", "Frustration", "Discouragement"],
                recommendedStrategies: [.visualization, .questioning, .summarizing],
                supportingPrompts: [
                    "What images come to mind when you read this passage?",
                    "What questions do you have about what you just read?",
                    "Can you tell the story in your own words?"
                ],
                growthMindsetStatements: [
                    "Your reading brain gets stronger every time you practice.",
                    "Understanding comes with time and practice.",
                    "Every reader was a beginner once."
                ]
            ),
            LearningChallenge(
                name: "Reading Fluency",
                area: .reading,
                description: "Reading slowly or with difficulty",
                commonEmotions: ["Embarrassment", "Frustration", "Impatience"],
                recommendedStrategies: [.repetition, .practice, .chunking],
                supportingPrompts: [
                    "What happens when you try to read aloud?",
                    "Which words are most challenging for you?",
                    "How do you feel when you have to read in front of others?"
                ],
                growthMindsetStatements: [
                    "Reading speed improves with practice.",
                    "Your brain is making new connections every time you read.",
                    "Many great readers started out reading slowly."
                ]
            )
        ]
        
        // Writing challenges
        let writingChallenges = [
            LearningChallenge(
                name: "Writer's Block",
                area: .writing,
                description: "Difficulty getting started or continuing writing",
                commonEmotions: ["Frustration", "Anxiety", "Overwhelm"],
                recommendedStrategies: [.chunking, .visualization, .connection],
                supportingPrompts: [
                    "What's one small part you could write about first?",
                    "What would make this writing task more interesting for you?",
                    "Could you draw or talk about your ideas before writing them?"
                ],
                growthMindsetStatements: [
                    "All writers get stuck sometimes - it's normal.",
                    "Writing is a skill that grows with practice.",
                    "First drafts are supposed to be messy - that's how ideas develop."
                ]
            )
        ]
        
        // Add challenges to the dictionary
        learningChallenges[.math] = mathChallenges
        learningChallenges[.reading] = readingChallenges
        learningChallenges[.writing] = writingChallenges
        
        // In a complete implementation, we would add challenges for all learning areas
    }
    
    /// Initializes growth mindset achievements
    private func initializeAchievements() {
        achievements = [
            GrowthMindsetAchievement(
                name: "Goal Setter",
                description: "Created your first learning goal",
                iconName: "target",
                pointValue: 10,
                congratulatoryMessage: "Great job setting a clear goal for your learning journey!"
            ),
            GrowthMindsetAchievement(
                name: "Progress Maker",
                description: "Completed steps toward your learning goals",
                iconName: "arrow.up.right",
                pointValue: 15,
                congratulatoryMessage: "You're making progress! Each step forward is growth."
            ),
            GrowthMindsetAchievement(
                name: "Goal Achiever",
                description: "Completed your first learning goal",
                iconName: "checkmark.circle",
                pointValue: 25,
                congratulatoryMessage: "Congratulations on achieving your goal! Your persistence paid off!"
            ),
            GrowthMindsetAchievement(
                name: "Reflective Thinker",
                description: "Created your first learning reflection",
                iconName: "brain",
                pointValue: 15,
                congratulatoryMessage: "Excellent reflection! Thinking about your learning helps your brain grow."
            ),
            GrowthMindsetAchievement(
                name: "Strategy Explorer",
                description: "Tried 3 different learning strategies",
                iconName: "lightbulb",
                pointValue: 20,
                congratulatoryMessage: "You're exploring different ways to learn - that's what great learners do!"
            ),
            GrowthMindsetAchievement(
                name: "Challenge Embracer",
                description: "Reflected on a learning challenge",
                iconName: "mountain.2",
                pointValue: 20,
                congratulatoryMessage: "You faced a challenge head-on! That's how your brain grows stronger."
            ),
            GrowthMindsetAchievement(
                name: "Persistent Learner",
                description: "Completed 5 learning goals",
                iconName: "star",
                pointValue: 30,
                congratulatoryMessage: "Your persistence is impressive! You've shown true dedication to learning."
            ),
            GrowthMindsetAchievement(
                name: "Metacognitive Master",
                description: "Created 10 learning reflections",
                iconName: "crown",
                pointValue: 35,
                congratulatoryMessage: "You've become a master of thinking about your thinking!"
            )
        ]
    }
    
    /// Generates reflection prompts for a specific learning area and journal mode
    private func generateReflectionPrompts(for area: LearningArea, journalMode: ChildJournalMode) -> [String] {
        // Base prompts that work for all areas
        var basePrompts: [String]
        
        switch journalMode {
        case .earlyChildhood:
            basePrompts = [
                "What did I learn today?",
                "What was fun about learning this?",
                "What was hard about learning this?",
                "How did I feel while learning?",
                "What do I want to learn more about?"
            ]
        case .middleChildhood:
            basePrompts = [
                "What's the most important thing I learned?",
                "What strategies helped me learn this?",
                "What questions do I still have?",
                "How does this connect to things I already know?",
                "What was challenging and how did I handle it?"
            ]
        case .adolescent:
            basePrompts = [
                "What were the key concepts I learned and why are they significant?",
                "Which learning strategies were most effective and why?",
                "How has my understanding of this topic evolved?",
                "What connections can I make between this and other areas?",
                "What metacognitive insights did I gain from this experience?"
            ]
        }
        
        // Add area-specific prompts
        var areaPrompts: [String] = []
        
        switch area {
        case .math:
            switch journalMode {
            case .earlyChildhood:
                areaPrompts = [
                    "What math patterns did I notice?",
                    "How did I solve the math problem?",
                    "What math tools helped me?"
                ]
            case .middleChildhood:
                areaPrompts = [
                    "What problem-solving strategies worked best for me?",
                    "How did I check if my answers made sense?",
                    "What connections did I find between different math concepts?"
                ]
            case .adolescent:
                areaPrompts = [
                    "How did I approach complex problems and what reasoning did I use?",
                    "What mathematical patterns or relationships did I discover?",
                    "How might I apply these mathematical concepts in real-world contexts?"
                ]
            }
        case .reading:
            switch journalMode {
            case .earlyChildhood:
                areaPrompts = [
                    "What was my favorite part of the story?",
                    "What pictures did I see in my mind while reading?",
                    "What would I ask the characters?"
                ]
            case .middleChildhood:
                areaPrompts = [
                    "What predictions did I make while reading?",
                    "How did the characters change in the story?",
                    "What questions did I ask myself while reading?"
                ]
            case .adolescent:
                areaPrompts = [
                    "What themes or messages did I identify in the text?",
                    "How did my interpretation evolve as I read?",
                    "What literary techniques did the author use effectively?"
                ]
            }
        // Additional cases for other learning areas would be implemented similarly
        default:
            // No additional area-specific prompts
            break
        }
        
        // Combine and return
        return basePrompts + areaPrompts
    }
    
    /// Gets the achievement ID for a given achievement type
    private func getAchievementId(for type: AchievementType) -> UUID? {
        let achievementName: String
        
        switch type {
        case .goalSetter:
            achievementName = "Goal Setter"
        case .progressMaker:
            achievementName = "Progress Maker"
        case .goalAchiever:
            achievementName = "Goal Achiever"
        case .reflectiveThinker:
            achievementName = "Reflective Thinker"
        case .strategyExplorer:
            achievementName = "Strategy Explorer"
        case .challengeEmbracer:
            achievementName = "Challenge Embracer"
        case .persistentLearner:
            achievementName = "Persistent Learner"
        case .metacognitiveMaster:
            achievementName = "Metacognitive Master"
        }
        
        return achievements.first(where: { $0.name == achievementName })?.id
    }
}

/// Achievement types for the growth mindset system
enum AchievementType {
    case goalSetter
    case progressMaker
    case goalAchiever
    case reflectiveThinker
    case strategyExplorer
    case challengeEmbracer
    case persistentLearner
    case metacognitiveMaster
}
