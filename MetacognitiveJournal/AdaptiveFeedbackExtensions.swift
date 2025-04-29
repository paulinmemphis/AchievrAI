import SwiftUI

// MARK: - Extensions for AdaptiveFeedbackView

/* // Temporarily commented out due to unclear redeclaration error
extension Color {
    static var random: Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}
*/

// REMOVED: FeedbackType extensions for iconName and color were duplicates

// REMOVED: SupportType extension for iconName was a duplicate

// REMOVED: MetacognitiveSkill extension was targeting the wrong type (should be MetacognitiveProcess)
//          and was redundant as MetacognitiveProcess defines iconName, color, etc.
/*
extension MetacognitiveSkill {
    var iconName: String {
        switch self {
        case .planning:
            return "calendar"
        case .monitoring:
            return "gauge"
        case .evaluating:
            return "checkmark.circle"
        case .reflecting:
            return "person.thought.bubble"
        case .adapting:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .planning:
            return .blue
        case .monitoring:
            return .orange
        case .evaluating:
            return .green
        case .reflecting:
            return .purple
        case .adapting:
            return .red
        }
    }
    
    var childFriendlyName: String {
        switch self {
        case .planning:
            return "Planning Ahead"
        case .monitoring:
            return "Checking Progress"
        case .evaluating:
            return "Looking at Results"
        case .reflecting:
            return "Thinking About Thinking"
        case .adapting:
            return "Changing Strategies"
        }
    }
}
*/

// REMOVED: ChallengeDifficulty extension for description(for:) was a duplicate
