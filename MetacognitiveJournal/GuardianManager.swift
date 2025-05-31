import Foundation
import SwiftUI
import Combine

/// Manages the guardian interface and related functionality
class GuardianManager: ObservableObject {
    // MARK: - Published Properties
    
    /// The current guardian
    @Published var currentGuardian: Guardian?
    
    /// Children associated with the current guardian
    @Published var associatedChildren: [ChildUserProfile] = []
    
    /// Privacy settings for each child
    @Published var privacySettings: [String: ChildPrivacySettings] = [:]
    
    /// Insights for the current guardian
    @Published var insights: [GuardianInsight] = []
    
    /// Observations made by the current guardian
    @Published var observations: [GuardianObservation] = []
    
    /// Prompts created by the current guardian
    @Published var prompts: [GuardianPrompt] = []
    
    /// Resources available to the current guardian
    @Published var resources: [GuardianResource] = []
    
    /// Filtered resources based on relevance
    @Published var relevantResources: [GuardianResource] = []
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private let guardianKey = "currentGuardian"
    private let privacySettingsKey = "childPrivacySettings"
    private let insightsKey = "guardianInsights"
    private let observationsKey = "guardianObservations"
    private let promptsKey = "guardianPrompts"
    
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
        
        loadGuardian()
        loadPrivacySettings()
        loadInsights()
        loadObservations()
        loadPrompts()
        initializeResources()
        
        // Set up subscriptions to other managers if available
        setupSubscriptions()
    }
    
    // MARK: - Authentication Methods
    
    /// Logs in a guardian
    func loginGuardian(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // In a real app, this would authenticate against a secure backend
        // For demo purposes, we'll create a mock guardian if one doesn't exist
        
        if currentGuardian == nil {
            let mockGuardian = Guardian(
                name: "Parent User",
                email: email,
                relationship: .parent,
                childIds: ["child1"]
            )
            
            self.currentGuardian = mockGuardian
            saveGuardian()
            
            // Create mock child profile if needed
            createMockChildIfNeeded()
            
            completion(true, nil)
        } else if currentGuardian?.email == email {
            // Update last login date
            currentGuardian?.lastLoginDate = Date()
            saveGuardian()
            completion(true, nil)
        } else {
            completion(false, "Invalid credentials")
        }
    }
    
    /// Logs out the current guardian
    func logoutGuardian() {
        currentGuardian = nil
        UserDefaults.standard.removeObject(forKey: guardianKey)
    }
    
    // MARK: - Child Management Methods
    
    /// Loads child profiles associated with the current guardian
    func loadAssociatedChildren() {
        guard let guardian = currentGuardian else { return }
        
        // In a real app, this would fetch from a database
        // For demo purposes, we'll create mock data
        
        associatedChildren = []
        
        for childId in guardian.childIds {
            if let profileData = UserDefaults.standard.data(forKey: "childUserProfile_\(childId)"),
               let profile = try? JSONDecoder().decode(ChildUserProfile.self, from: profileData) {
                associatedChildren.append(profile)
            }
        }
        
        // Load privacy settings for each child
        for childId in guardian.childIds {
            if privacySettings[childId] == nil {
                // Fetch age from stored profile
                let age: Int
                if let profileData = UserDefaults.standard.data(forKey: "childUserProfile_\(childId)"),
                   let profile = try? JSONDecoder().decode(ChildUserProfile.self, from: profileData) {
                    age = profile.age
                } else {
                    age = 0 // Default age if profile not found (handle appropriately)
                }
                privacySettings[childId] = ChildPrivacySettings(childId: childId, age: age)
                savePrivacySettings()
            }
        }
    }
    
    /// Updates privacy settings for a child
    func updatePrivacySettings(childId: String, settings: ChildPrivacySettings) {
        privacySettings[childId] = settings
        savePrivacySettings()
    }
    
    /// Checks if the current guardian has access to a specific data type for a child
    func hasAccessTo(dataType: GuardianDataType, forChildId childId: String) -> Bool {
        guard let guardian = currentGuardian,
              let settings = privacySettings[childId] else {
            return false
        }
        
        let accessLevel = settings.accessLevelFor(guardianId: guardian.id)
        return accessLevel.accessibleDataTypes.contains(dataType)
    }
    
    // MARK: - Insight Methods
    
    /// Creates a new insight for a child
    func createInsight(childId: String,
                       title: String,
                       description: String,
                       insightType: GuardianInsightType,
                       dataType: GuardianDataType,
                       suggestedActions: [String]? = nil,
                       relatedResources: [String]? = nil,
                       requiresAttention: Bool = false) {
        
        // Check if guardian has access to this data type
        guard hasAccessTo(dataType: dataType, forChildId: childId) else {
            return
        }
        
        let insight = GuardianInsight(
            childId: childId,
            title: title,
            description: description,
            insightType: insightType,
            dataType: dataType,
            suggestedActions: suggestedActions,
            relatedResources: relatedResources,
            requiresAttention: requiresAttention
        )
        
        insights.append(insight)
        saveInsights()
        
        // Update relevant resources
        updateRelevantResources()
    }
    
    /// Gets insights for a specific child
    func getInsights(forChildId childId: String) -> [GuardianInsight] {
        return insights.filter { $0.childId == childId }
    }
    
    /// Gets insights of a specific type
    func getInsights(ofType type: GuardianInsightType) -> [GuardianInsight] {
        return insights.filter { $0.insightType == type }
    }
    
    /// Marks an insight as acknowledged
    func acknowledgeInsight(_ insightId: UUID) {
        if let index = insights.firstIndex(where: { $0.id == insightId }) {
            insights[index].acknowledged = true
            saveInsights()
        }
    }
    
    // MARK: - Observation Methods
    
    /// Creates a new observation for a child
    func createObservation(childId: String,
                           context: ObservationContext,
                           observation: String,
                           emotions: [String]? = nil,
                           strategies: [String]? = nil) {
        
        guard let guardian = currentGuardian,
              let settings = privacySettings[childId],
              settings.allowGuardianObservations else {
            return
        }
        
        let visibleToChild = settings.showGuardianObservationsToChild
        
        let newObservation = GuardianObservation(
            guardianId: guardian.id,
            childId: childId,
            context: context,
            observation: observation,
            emotions: emotions,
            strategies: strategies,
            visibleToChild: visibleToChild
        )
        
        observations.append(newObservation)
        saveObservations()
        
        // Generate insights based on observations if appropriate
        analyzeObservationForInsights(newObservation)
    }
    
    /// Gets observations for a specific child
    func getObservations(forChildId childId: String) -> [GuardianObservation] {
        return observations.filter { $0.childId == childId }
    }
    
    /// Gets observations in a specific context
    func getObservations(inContext context: ObservationContext) -> [GuardianObservation] {
        return observations.filter { $0.context == context }
    }
    
    // MARK: - Prompt Methods
    
    /// Creates a new journal prompt for a child
    func createPrompt(childId: String,
                      promptText: String,
                      context: String? = nil,
                      learningArea: LearningArea? = nil,
                      emotionalFocus: String? = nil) {
        
        guard let guardian = currentGuardian,
              let settings = privacySettings[childId],
              settings.allowGuardianPrompts else {
            return
        }
        
        var newPrompt = GuardianPrompt(
            guardianId: guardian.id,
            childId: childId,
            promptText: promptText,
            context: context,
            learningArea: learningArea,
            emotionalFocus: emotionalFocus
        )
        
        // Set initial status based on whether approval is required
        if settings.promptApprovalRequired {
            // Status remains pending
        } else {
            newPrompt.status = .approved
        }
        
        prompts.append(newPrompt)
        savePrompts()
    }
    
    /// Updates the status of a prompt
    func updatePromptStatus(_ promptId: UUID, status: PromptStatus) {
        if let index = prompts.firstIndex(where: { $0.id == promptId }) {
            prompts[index].status = status
            savePrompts()
        }
    }
    
    /// Records a child's response to a prompt
    func recordPromptResponse(_ promptId: UUID, response: String) {
        if let index = prompts.firstIndex(where: { $0.id == promptId }) {
            prompts[index].childResponse = response
            prompts[index].responseDate = Date()
            prompts[index].status = .completed
            savePrompts()
        }
    }
    
    /// Gets prompts for a specific child
    func getPrompts(forChildId childId: String) -> [GuardianPrompt] {
        return prompts.filter { $0.childId == childId }
    }
    
    /// Gets prompts with a specific status
    func getPrompts(withStatus status: PromptStatus) -> [GuardianPrompt] {
        return prompts.filter { $0.status == status }
    }
    
    // MARK: - Resource Methods
    
    /// Gets resources relevant to a specific child
    func getResources(forChildId childId: String) -> [GuardianResource] {
        // Fetch child profile using childId from UserDefaults
        guard let profileData = UserDefaults.standard.data(forKey: "childUserProfile_\(childId)"),
              let child = try? JSONDecoder().decode(ChildUserProfile.self, from: profileData),
              let guardian = currentGuardian else {
            return []
        }
        
        return resources.filter { resource in
            // Check if the resource is relevant for this guardian type
            let isForGuardianType = resource.targetAudience.contains(guardian.relationship)
            
            // Check if the resource is age-appropriate
            let isAgeAppropriate = resource.relevantAges.contains(child.age)
            
            return isForGuardianType && isAgeAppropriate
        }
    }
    
    /// Gets resources for a specific learning area
    func getResources(forLearningArea area: LearningArea) -> [GuardianResource] {
        return resources.filter { $0.learningAreas?.contains(area) == true }
    }
    
    /// Gets resources focused on specific emotions
    func getResources(forEmotionalFocus emotion: String) -> [GuardianResource] {
        return resources.filter { $0.emotionalFocus?.contains(emotion) == true }
    }
    
    /// Updates relevant resources based on recent insights and observations
    func updateRelevantResources() {
        // Get recent unacknowledged insights
        let recentInsights = insights.filter { !$0.acknowledged }
        
        // Extract learning areas and emotional focuses from insights
        var learningAreas: Set<LearningArea> = []
        var emotionalFocuses: Set<String> = []
        
        for insight in recentInsights {
            if insight.dataType == .learningChallenges || insight.dataType == .learningProgress,
               let learningArea = getLearningAreaFromInsight(insight) {
                learningAreas.insert(learningArea)
            }
            
            if insight.dataType == .emotionalTrends || insight.dataType == .emotionalPatterns,
               let emotion = getEmotionFromInsight(insight) {
                emotionalFocuses.insert(emotion)
            }
        }
        
        // Filter resources based on relevance
        relevantResources = resources.filter { resource in
            let matchesLearningArea = resource.learningAreas?.contains(where: { learningAreas.contains($0) }) == true
            let matchesEmotion = resource.emotionalFocus?.contains(where: { emotionalFocuses.contains($0) }) == true
            
            return matchesLearningArea || matchesEmotion
        }
    }
    
    // MARK: - Progress Tracking Methods
    
    /// Gets metacognitive progress for a specific child
    func getMetacognitiveProgress(forChildId childId: String) -> [String: Any]? {
        // Check access permissions
        guard hasAccessTo(dataType: .metacognitiveSkills, forChildId: childId),
              let learningManager = learningReflectionManager else {
            return nil
        }
        
        // In a real app, this would extract data from the learning manager
        // For demo purposes, we'll return mock data
        
        return [
            "planningLevel": "Developing",
            "monitoringLevel": "Practicing",
            "evaluatingLevel": "Beginner",
            "reflectingLevel": "Developing",
            "regulatingLevel": "Beginner",
            "overallLevel": "Developing",
            "journalEntriesWithMetacognition": 12,
            "completedChallenges": 3,
            "growthPoints": 45
        ]
    }
    
    /// Gets emotional awareness progress for a specific child
    func getEmotionalProgress(forChildId childId: String) -> [String: Any]? {
        // Check access permissions
        guard hasAccessTo(dataType: .emotionalPatterns, forChildId: childId) else {
            return nil
        }
        
        // In a real app, this would extract data from the emotional awareness manager
        // For demo purposes, we'll return mock data
        
        return [
            "recognizedEmotions": 15,
            "frequentEmotions": ["Happy", "Frustrated", "Curious"],
            "effectiveStrategies": ["Deep breathing", "Taking a break", "Talking it out"],
            "journalEntriesWithEmotionalContent": 18
        ]
    }
    
    // MARK: - Private Helper Methods
    
    /// Sets up subscriptions to other managers
    private func setupSubscriptions() {
        // In a real app, this would subscribe to events from other managers
        // For example, when a new journal entry is created with emotional content
    }
    
    /// Analyzes an observation for potential insights
    private func analyzeObservationForInsights(_ observation: GuardianObservation) {
        // In a real app, this would analyze the observation and potentially create insights
        // For demo purposes, we'll create a simple insight if emotions are provided
        
        if let emotions = observation.emotions, !emotions.isEmpty {
            let emotion = emotions[0]
            
            createInsight(
                childId: observation.childId,
                title: "\(emotion) observed in \(observation.context.rawValue.lowercased()) context",
                description: "You observed that your child was feeling \(emotion.lowercased()) during a \(observation.context.rawValue.lowercased()) situation. This might be worth exploring further.",
                insightType: .emotionalAlert,
                dataType: .emotionalPatterns,
                suggestedActions: ["Ask open-ended questions about the experience", "Look for patterns in similar situations"],
                requiresAttention: emotion == "Anxious" || emotion == "Sad" || emotion == "Angry"
            )
        }
    }
    
    /// Extracts a learning area from an insight if possible
    private func getLearningAreaFromInsight(_ insight: GuardianInsight) -> LearningArea? {
        // In a real app, this would parse the insight to extract the learning area
        // For demo purposes, we'll return nil
        return nil
    }
    
    /// Extracts an emotion from an insight if possible
    private func getEmotionFromInsight(_ insight: GuardianInsight) -> String? {
        // In a real app, this would parse the insight to extract the emotion
        // For demo purposes, we'll return nil
        return nil
    }
    
    /// Creates a mock child if needed for demo purposes
    private func createMockChildIfNeeded() {
        guard let guardian = currentGuardian else { return }
        
        for childId in guardian.childIds {
            let key = "childUserProfile_\(childId)"
            
            if UserDefaults.standard.data(forKey: key) == nil {
                let mockChild = ChildUserProfile(
                    name: "Alex",
                    age: 10,
                    readingLevel: .grade3to4,
                    avatarImage: "avatar1"
                )
                
                if let encodedData = try? JSONEncoder().encode(mockChild) {
                    UserDefaults.standard.set(encodedData, forKey: key)
                }
                
                // Create privacy settings for this child
                let settings = ChildPrivacySettings(childId: childId, age: mockChild.age)
                privacySettings[childId] = settings
                savePrivacySettings()
            }
        }
    }
    
    /// Initializes resources for guardians
    private func initializeResources() {
        // In a real app, these would be loaded from a database
        resources = [
            GuardianResource(
                title: "Supporting Metacognitive Development at Home",
                description: "Practical strategies for parents to foster metacognitive thinking in everyday activities",
                resourceType: .article,
                targetAudience: [.parent, .otherFamily, .otherCaregiver],
                relevantAges: 6...12,
                content: "Content would go here...",
                externalLinks: ["https://example.com/metacognition-home"]
            ),
            GuardianResource(
                title: "Classroom Strategies for Metacognitive Growth",
                description: "Evidence-based approaches to integrate metacognitive practices into classroom activities",
                resourceType: .strategy,
                targetAudience: [.teacher],
                relevantAges: 6...16,
                learningAreas: [.math, .reading, .writing, .science],
                content: "Content would go here...",
                externalLinks: ["https://example.com/metacognition-classroom"]
            ),
            GuardianResource(
                title: "Helping Children Manage Math Anxiety",
                description: "Understanding and addressing anxiety related to mathematics",
                resourceType: .strategy,
                targetAudience: [.parent, .teacher, .counselor],
                relevantAges: 8...14,
                learningAreas: [.math],
                emotionalFocus: ["Anxiety", "Frustration"],
                content: "Content would go here...",
                externalLinks: ["https://example.com/math-anxiety"]
            ),
            GuardianResource(
                title: "Emotional Awareness Conversation Starters",
                description: "Age-appropriate questions to help children identify and discuss their emotions",
                resourceType: .conversation,
                targetAudience: [.parent, .counselor, .therapist, .otherFamily],
                relevantAges: 6...16,
                emotionalFocus: ["All emotions"],
                content: "Content would go here...",
                externalLinks: ["https://example.com/emotion-conversations"]
            ),
            GuardianResource(
                title: "Growth Mindset Activities for Children",
                description: "Fun activities to promote a growth mindset and resilience",
                resourceType: .activity,
                targetAudience: [.parent, .teacher, .otherFamily],
                relevantAges: 6...12,
                content: "Content would go here...",
                externalLinks: ["https://example.com/growth-mindset"]
            )
        ]
    }
    
    // MARK: - Persistence Methods
    
    /// Saves the current guardian to UserDefaults
    private func saveGuardian() {
        if let guardian = currentGuardian,
           let encodedData = try? JSONEncoder().encode(guardian) {
            UserDefaults.standard.set(encodedData, forKey: guardianKey)
        }
    }
    
    /// Loads the guardian from UserDefaults
    private func loadGuardian() {
        if let guardianData = UserDefaults.standard.data(forKey: guardianKey),
           let guardian = try? JSONDecoder().decode(Guardian.self, from: guardianData) {
            self.currentGuardian = guardian
            loadAssociatedChildren()
        }
    }
    
    /// Saves privacy settings to UserDefaults
    private func savePrivacySettings() {
        if let encodedData = try? JSONEncoder().encode(privacySettings) {
            UserDefaults.standard.set(encodedData, forKey: privacySettingsKey)
        }
    }
    
    /// Loads privacy settings from UserDefaults
    private func loadPrivacySettings() {
        if let settingsData = UserDefaults.standard.data(forKey: privacySettingsKey),
           let settings = try? JSONDecoder().decode([String: ChildPrivacySettings].self, from: settingsData) {
            self.privacySettings = settings
        }
    }
    
    /// Saves insights to UserDefaults
    private func saveInsights() {
        if let encodedData = try? JSONEncoder().encode(insights) {
            UserDefaults.standard.set(encodedData, forKey: insightsKey)
        }
    }
    
    /// Loads insights from UserDefaults
    private func loadInsights() {
        if let insightsData = UserDefaults.standard.data(forKey: insightsKey),
           let loadedInsights = try? JSONDecoder().decode([GuardianInsight].self, from: insightsData) {
            self.insights = loadedInsights
        }
    }
    
    /// Saves observations to UserDefaults
    private func saveObservations() {
        if let encodedData = try? JSONEncoder().encode(observations) {
            UserDefaults.standard.set(encodedData, forKey: observationsKey)
        }
    }
    
    /// Loads observations from UserDefaults
    private func loadObservations() {
        if let observationsData = UserDefaults.standard.data(forKey: observationsKey),
           let loadedObservations = try? JSONDecoder().decode([GuardianObservation].self, from: observationsData) {
            self.observations = loadedObservations
        }
    }
    
    /// Saves prompts to UserDefaults
    private func savePrompts() {
        if let encodedData = try? JSONEncoder().encode(prompts) {
            UserDefaults.standard.set(encodedData, forKey: promptsKey)
        }
    }
    
    /// Loads prompts from UserDefaults
    private func loadPrompts() {
        if let promptsData = UserDefaults.standard.data(forKey: promptsKey),
           let loadedPrompts = try? JSONDecoder().decode([GuardianPrompt].self, from: promptsData) {
            self.prompts = loadedPrompts
        }
    }
}
