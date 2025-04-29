import Foundation
import SwiftUI

/// Represents the developmental stages for the child journal
enum ChildJournalMode: String, Codable, CaseIterable {
    case earlyChildhood = "Early Childhood" // Ages 6-8
    case middleChildhood = "Middle Childhood" // Ages 9-12
    case adolescent = "Adolescent" // Ages 13-16
    
    /// Get the appropriate mode based on age
    static func modeForAge(_ age: Int) -> ChildJournalMode {
        switch age {
        case 6...8:
            return .earlyChildhood
        case 9...12:
            return .middleChildhood
        case 13...16:
            return .adolescent
        default:
            // Default to middle childhood for ages outside the expected range
            return .middleChildhood
        }
    }
    
    /// Get the age range description for this mode
    var ageRange: String {
        switch self {
        case .earlyChildhood:
            return "Ages 6-8"
        case .middleChildhood:
            return "Ages 9-12"
        case .adolescent:
            return "Ages 13-16"
        }
    }
    
    /// Get the UI characteristics for this mode
    var uiCharacteristics: UICharacteristics {
        switch self {
        case .earlyChildhood:
            return UICharacteristics(
                primaryFontSize: 22,
                secondaryFontSize: 18,
                fontDesign: .rounded,
                animationIntensity: .high,
                usesSpeechSupport: true,
                usesSimplifiedUI: true
            )
        case .middleChildhood:
            return UICharacteristics(
                primaryFontSize: 18,
                secondaryFontSize: 16,
                fontDesign: .rounded,
                animationIntensity: .medium,
                usesSpeechSupport: false,
                usesSimplifiedUI: false
            )
        case .adolescent:
            return UICharacteristics(
                primaryFontSize: 16,
                secondaryFontSize: 14,
                fontDesign: .default,
                animationIntensity: .low,
                usesSpeechSupport: false,
                usesSimplifiedUI: false
            )
        }
    }
    
    /// Get the cognitive characteristics for this mode
    var cognitiveCharacteristics: CognitiveCharacteristics {
        switch self {
        case .earlyChildhood:
            return CognitiveCharacteristics(
                abstractionLevel: .concrete,
                promptComplexity: .simple,
                metacognitionLevel: .basic,
                vocabularyLevel: .basic,
                attentionSpan: .short
            )
        case .middleChildhood:
            return CognitiveCharacteristics(
                abstractionLevel: .developing,
                promptComplexity: .moderate,
                metacognitionLevel: .developing,
                vocabularyLevel: .intermediate,
                attentionSpan: .medium
            )
        case .adolescent:
            return CognitiveCharacteristics(
                abstractionLevel: .abstract,
                promptComplexity: .complex,
                metacognitionLevel: .advanced,
                vocabularyLevel: .advanced,
                attentionSpan: .long
            )
        }
    }
}

/// UI characteristics for different developmental stages
struct UICharacteristics {
    let primaryFontSize: CGFloat
    let secondaryFontSize: CGFloat
    let fontDesign: Font.Design
    let animationIntensity: AnimationIntensity
    let usesSpeechSupport: Bool
    let usesSimplifiedUI: Bool
    
    enum AnimationIntensity {
        case low, medium, high
    }
}

/// Cognitive characteristics for different developmental stages
struct CognitiveCharacteristics {
    let abstractionLevel: AbstractionLevel
    let promptComplexity: PromptComplexity
    let metacognitionLevel: MetacognitionLevel
    let vocabularyLevel: VocabularyLevel
    let attentionSpan: AttentionSpan
    
    enum AbstractionLevel {
        case concrete, developing, abstract
    }
    
    enum PromptComplexity {
        case simple, moderate, complex
    }
    
    enum MetacognitionLevel {
        case basic, developing, advanced
    }
    
    enum VocabularyLevel {
        case basic, intermediate, advanced
    }
    
    enum AttentionSpan {
        case short, medium, long
    }
}
