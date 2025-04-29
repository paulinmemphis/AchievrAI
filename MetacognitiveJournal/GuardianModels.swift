import Foundation
import SwiftUI

/// Represents a guardian (parent, teacher, or other caregiver)
struct Guardian: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let relationship: GuardianRelationship
    let childIds: [String]
    var preferences: GuardianPreferences
    var lastLoginDate: Date?
    
    init(name: String, email: String, relationship: GuardianRelationship, childIds: [String]) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.relationship = relationship
        self.childIds = childIds
        self.preferences = GuardianPreferences()
        self.lastLoginDate = nil
    }
}

/// Represents the relationship between guardian and child
enum GuardianRelationship: String, Codable, CaseIterable {
    case parent = "Parent"
    case teacher = "Teacher"
    case counselor = "School Counselor"
    case therapist = "Therapist"
    case otherFamily = "Other Family Member"
    case otherCaregiver = "Other Caregiver"
    
    /// Returns access level appropriate for this relationship type
    var defaultAccessLevel: PrivacyAccessLevel {
        switch self {
        case .parent, .otherFamily:
            return .comprehensive
        case .teacher:
            return .educational
        case .counselor, .therapist:
            return .therapeutic
        case .otherCaregiver:
            return .basic
        }
    }
}

/// Represents guardian preferences for the interface
struct GuardianPreferences: Codable {
    var notificationPreferences: NotificationPreferences
    var insightPreferences: InsightPreferences
    var interfacePreferences: InterfacePreferences
    
    init() {
        self.notificationPreferences = NotificationPreferences()
        self.insightPreferences = InsightPreferences()
        self.interfacePreferences = InterfacePreferences()
    }
}

/// Notification preferences for guardians
struct NotificationPreferences: Codable {
    var emailNotificationsEnabled: Bool = true
    var pushNotificationsEnabled: Bool = true
    var emotionalAlerts: Bool = true
    var learningMilestones: Bool = true
    var journalActivity: Bool = false
    var weeklyDigest: Bool = true
    var notificationFrequency: NotificationFrequency = .weekly
}

/// Frequency options for notifications
enum NotificationFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every Two Weeks"
    case monthly = "Monthly"
    case never = "Never"
}

/// Insight preferences for guardians
struct InsightPreferences: Codable {
    var emotionalInsights: Bool = true
    var learningPatterns: Bool = true
    var metacognitiveProgress: Bool = true
    var challengeAreas: Bool = true
    var strengthAreas: Bool = true
    var goalProgress: Bool = true
}

/// Interface preferences for guardians
struct InterfacePreferences: Codable {
    var theme: String = "Default"
    var dashboardLayout: String = "Standard"
    var language: String = "English"
    var accessibilityOptions: [String] = []
}

/// Represents a privacy access level for guardian viewing
enum PrivacyAccessLevel: String, Codable, CaseIterable, Comparable {
    case minimal = "Minimal"
    case basic = "Basic"
    case educational = "Educational"
    case therapeutic = "Therapeutic"
    case comprehensive = "Comprehensive"
    
    static func < (lhs: PrivacyAccessLevel, rhs: PrivacyAccessLevel) -> Bool {
        let order: [PrivacyAccessLevel] = [.minimal, .basic, .educational, .therapeutic, .comprehensive]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    /// Returns a description of this access level
    var description: String {
        switch self {
        case .minimal:
            return "Basic activity and well-being indicators only"
        case .basic:
            return "General emotional trends and learning progress"
        case .educational:
            return "Learning patterns, challenges, and metacognitive development"
        case .therapeutic:
            return "Detailed emotional patterns and specific journal insights"
        case .comprehensive:
            return "Full access to insights while maintaining journal content privacy"
        }
    }
    
    /// Returns what types of data are accessible at this level
    var accessibleDataTypes: [GuardianDataType] {
        switch self {
        case .minimal:
            return [.activitySummary, .wellbeingIndicators]
        case .basic:
            return [.activitySummary, .wellbeingIndicators, .emotionalTrends, .learningProgress]
        case .educational:
            return [.activitySummary, .wellbeingIndicators, .emotionalTrends, .learningProgress, 
                    .learningChallenges, .metacognitiveSkills, .learningStrategies]
        case .therapeutic:
            return [.activitySummary, .wellbeingIndicators, .emotionalTrends, .learningProgress, 
                    .learningChallenges, .metacognitiveSkills, .learningStrategies,
                    .emotionalPatterns, .journalThemes]
        case .comprehensive:
            return GuardianDataType.allCases
        }
    }
}

/// Types of data that can be shared with guardians
enum GuardianDataType: String, Codable, CaseIterable {
    case activitySummary = "Activity Summary"
    case wellbeingIndicators = "Well-being Indicators"
    case emotionalTrends = "Emotional Trends"
    case emotionalPatterns = "Detailed Emotional Patterns"
    case learningProgress = "Learning Progress"
    case learningChallenges = "Learning Challenges"
    case metacognitiveSkills = "Metacognitive Skills"
    case learningStrategies = "Learning Strategies"
    case journalThemes = "Journal Themes"
    case goalProgress = "Goal Progress"
    case strengthsAndInterests = "Strengths and Interests"
}

/// Represents privacy settings for a child
struct ChildPrivacySettings: Codable {
    let childId: String
    var defaultAccessLevel: PrivacyAccessLevel
    var guardianSpecificSettings: [UUID: PrivacyAccessLevel] // Guardian ID to access level
    var sharedDataTypes: [GuardianDataType]
    var privateJournalTags: [String]
    var privateEmotions: [String]
    var allowGuardianPrompts: Bool
    var promptApprovalRequired: Bool
    var allowGuardianObservations: Bool
    var showGuardianObservationsToChild: Bool
    
    init(childId: String, age: Int) {
        self.childId = childId
        
        // Set age-appropriate defaults
        if age <= 8 {
            // Younger children have more guardian oversight
            self.defaultAccessLevel = .comprehensive
            self.allowGuardianPrompts = true
            self.promptApprovalRequired = false
            self.allowGuardianObservations = true
            self.showGuardianObservationsToChild = true
        } else if age <= 12 {
            // Middle childhood has balanced privacy
            self.defaultAccessLevel = .educational
            self.allowGuardianPrompts = true
            self.promptApprovalRequired = true
            self.allowGuardianObservations = true
            self.showGuardianObservationsToChild = true
        } else {
            // Adolescents have more privacy
            self.defaultAccessLevel = .basic
            self.allowGuardianPrompts = true
            self.promptApprovalRequired = true
            self.allowGuardianObservations = false
            self.showGuardianObservationsToChild = false
        }
        
        self.guardianSpecificSettings = [:]
        self.sharedDataTypes = defaultAccessLevel.accessibleDataTypes
        self.privateJournalTags = ["private", "secret"]
        self.privateEmotions = []
    }
    
    /// Gets the access level for a specific guardian
    func accessLevelFor(guardianId: UUID) -> PrivacyAccessLevel {
        return guardianSpecificSettings[guardianId] ?? defaultAccessLevel
    }
    
    /// Checks if a specific data type is shared
    func isDataTypeShared(_ dataType: GuardianDataType) -> Bool {
        return sharedDataTypes.contains(dataType)
    }
}

/// Represents an insight shared with a guardian
struct GuardianInsight: Identifiable, Codable {
    let id: UUID
    let childId: String
    let timestamp: Date
    let title: String
    let description: String
    let insightType: GuardianInsightType
    let dataType: GuardianDataType
    let suggestedActions: [String]?
    let relatedResources: [String]?
    let requiresAttention: Bool
    var acknowledged: Bool
    
    init(childId: String,
         title: String,
         description: String,
         insightType: GuardianInsightType,
         dataType: GuardianDataType,
         suggestedActions: [String]? = nil,
         relatedResources: [String]? = nil,
         requiresAttention: Bool = false) {
        self.id = UUID()
        self.childId = childId
        self.timestamp = Date()
        self.title = title
        self.description = description
        self.insightType = insightType
        self.dataType = dataType
        self.suggestedActions = suggestedActions
        self.relatedResources = relatedResources
        self.requiresAttention = requiresAttention
        self.acknowledged = false
    }
}

/// Types of insights for guardians
enum GuardianInsightType: String, Codable, CaseIterable {
    case emotionalAlert = "Emotional Alert"
    case learningMilestone = "Learning Milestone"
    case metacognitiveProgress = "Metacognitive Progress"
    case learningChallenge = "Learning Challenge"
    case patternDetected = "Pattern Detected"
    case strengthIdentified = "Strength Identified"
    case suggestionForSupport = "Suggestion for Support"
    
    /// Returns an icon name for the insight type
    var iconName: String {
        switch self {
        case .emotionalAlert: return "heart.fill"
        case .learningMilestone: return "flag.fill"
        case .metacognitiveProgress: return "brain"
        case .learningChallenge: return "exclamationmark.triangle"
        case .patternDetected: return "chart.line.uptrend.xyaxis"
        case .strengthIdentified: return "star.fill"
        case .suggestionForSupport: return "hand.raised.fill"
        }
    }
    
    /// Returns a color for the insight type
    var color: Color {
        switch self {
        case .emotionalAlert: return Color(red: 0.9, green: 0.3, blue: 0.3) // Red
        case .learningMilestone: return Color(red: 0.3, green: 0.8, blue: 0.4) // Green
        case .metacognitiveProgress: return Color(red: 0.4, green: 0.5, blue: 0.9) // Blue
        case .learningChallenge: return Color(red: 0.9, green: 0.6, blue: 0.3) // Orange
        case .patternDetected: return Color(red: 0.5, green: 0.3, blue: 0.9) // Purple
        case .strengthIdentified: return Color(red: 0.9, green: 0.8, blue: 0.3) // Yellow
        case .suggestionForSupport: return Color(red: 0.3, green: 0.7, blue: 0.8) // Teal
        }
    }
}

/// Represents a guardian observation about a child
struct GuardianObservation: Identifiable, Codable {
    let id: UUID
    let guardianId: UUID
    let childId: String
    let timestamp: Date
    let context: ObservationContext
    let observation: String
    let emotions: [String]?
    let strategies: [String]?
    let visibleToChild: Bool
    var childAcknowledged: Bool
    
    init(guardianId: UUID,
         childId: String,
         context: ObservationContext,
         observation: String,
         emotions: [String]? = nil,
         strategies: [String]? = nil,
         visibleToChild: Bool) {
        self.id = UUID()
        self.guardianId = guardianId
        self.childId = childId
        self.timestamp = Date()
        self.context = context
        self.observation = observation
        self.emotions = emotions
        self.strategies = strategies
        self.visibleToChild = visibleToChild
        self.childAcknowledged = false
    }
}

/// Context for guardian observations
enum ObservationContext: String, Codable, CaseIterable {
    case home = "At Home"
    case school = "At School"
    case socialSituation = "Social Situation"
    case extracurricular = "Extracurricular Activity"
    case learningActivity = "Learning Activity"
    case emotionalEvent = "Emotional Event"
    case other = "Other Context"
    
    /// Returns an icon name for the context
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .school: return "book.fill"
        case .socialSituation: return "person.2.fill"
        case .extracurricular: return "sportscourt.fill"
        case .learningActivity: return "lightbulb.fill"
        case .emotionalEvent: return "heart.fill"
        case .other: return "square.fill"
        }
    }
}

/// Represents a journal prompt suggested by a guardian
struct GuardianPrompt: Identifiable, Codable {
    let id: UUID
    let guardianId: UUID
    let childId: String
    let timestamp: Date
    let promptText: String
    let context: String?
    let learningArea: LearningArea?
    let emotionalFocus: String?
    var status: PromptStatus
    var childResponse: String?
    var responseDate: Date?
    
    init(guardianId: UUID,
         childId: String,
         promptText: String,
         context: String? = nil,
         learningArea: LearningArea? = nil,
         emotionalFocus: String? = nil) {
        self.id = UUID()
        self.guardianId = guardianId
        self.childId = childId
        self.timestamp = Date()
        self.promptText = promptText
        self.context = context
        self.learningArea = learningArea
        self.emotionalFocus = emotionalFocus
        self.status = .pending
        self.childResponse = nil
        self.responseDate = nil
    }
}

/// Status of a guardian prompt
enum PromptStatus: String, Codable, CaseIterable {
    case pending = "Pending Approval"
    case approved = "Approved"
    case rejected = "Rejected"
    case completed = "Completed"
    case expired = "Expired"
}

/// Represents a resource for guardians to support metacognitive development
struct GuardianResource: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let resourceType: ResourceType
    let targetAudience: [GuardianRelationship]
    let relevantAges: ClosedRange<Int>
    let learningAreas: [LearningArea]?
    let emotionalFocus: [String]?
    let content: String
    let externalLinks: [String]?
    
    init(title: String,
         description: String,
         resourceType: ResourceType,
         targetAudience: [GuardianRelationship],
         relevantAges: ClosedRange<Int>,
         learningAreas: [LearningArea]? = nil,
         emotionalFocus: [String]? = nil,
         content: String,
         externalLinks: [String]? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.resourceType = resourceType
        self.targetAudience = targetAudience
        self.relevantAges = relevantAges
        self.learningAreas = learningAreas
        self.emotionalFocus = emotionalFocus
        self.content = content
        self.externalLinks = externalLinks
    }
}

/// Types of guardian resources
enum ResourceType: String, Codable, CaseIterable {
    case article = "Article"
    case activity = "Activity"
    case conversation = "Conversation Guide"
    case strategy = "Strategy"
    case reference = "Reference"
    case tool = "Tool"
    
    /// Returns an icon name for the resource type
    var iconName: String {
        switch self {
        case .article: return "doc.text"
        case .activity: return "figure.walk"
        case .conversation: return "text.bubble"
        case .strategy: return "lightbulb"
        case .reference: return "book"
        case .tool: return "hammer"
        }
    }
}
