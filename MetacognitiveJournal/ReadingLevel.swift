import Foundation

/// Reading levels for child users
enum ReadingLevel: String, Codable, CaseIterable, Identifiable, Comparable {
    case preReader = "Pre-Reader"
    case earlyReader = "Early Reader"
    case grade1to2 = "Grades 1-2"
    case grade3to4 = "Grades 3-4"
    case grade5to6 = "Grades 5-6"
    case grade7to8 = "Grades 7-8"
    case grade9Plus = "Grade 9+"
    
    var id: String { rawValue }
    
    /// Get the appropriate reading level based on age
    static func levelForAge(_ age: Int) -> ReadingLevel {
        switch age {
        case 6:
            return .earlyReader
        case 7...8:
            return .grade1to2
        case 9...10:
            return .grade3to4
        case 11...12:
            return .grade5to6
        case 13...14:
            return .grade7to8
        case 15...:
            return .grade9Plus
        default:
            return .preReader
        }
    }
    
    /// Get the reading level description
    var description: String {
        switch self {
        case .preReader:
            return "Just beginning to recognize letters and words"
        case .earlyReader:
            return "Starting to read simple words and sentences"
        case .grade1to2:
            return "Reading simple books with short sentences"
        case .grade3to4:
            return "Reading chapter books with more complex sentences"
        case .grade5to6:
            return "Reading longer books with varied vocabulary"
        case .grade7to8:
            return "Reading young adult books with complex themes"
        case .grade9Plus:
            return "Reading at or above high school level"
        }
    }
    
    /// Get the vocabulary complexity level
    var vocabularyComplexity: Int {
        switch self {
        case .preReader:
            return 1
        case .earlyReader:
            return 2
        case .grade1to2:
            return 3
        case .grade3to4:
            return 4
        case .grade5to6:
            return 5
        case .grade7to8:
            return 6
        case .grade9Plus:
            return 7
        }
    }
    
    /// Get the maximum sentence length recommended for this reading level
    var recommendedMaxSentenceLength: Int {
        switch self {
        case .preReader:
            return 5
        case .earlyReader:
            return 8
        case .grade1to2:
            return 12
        case .grade3to4:
            return 15
        case .grade5to6:
            return 20
        case .grade7to8:
            return 25
        case .grade9Plus:
            return 30
        }
    }
    
    /// Get appropriate font size for this reading level
    var recommendedFontSize: CGFloat {
        switch self {
        case .preReader, .earlyReader:
            return 22
        case .grade1to2:
            return 20
        case .grade3to4:
            return 18
        case .grade5to6:
            return 16
        case .grade7to8, .grade9Plus:
            return 14
        }
    }
    
    /// Determine if text-to-speech should be enabled by default
    var enableTextToSpeech: Bool {
        switch self {
        case .preReader, .earlyReader, .grade1to2:
            return true
        default:
            return false
        }
    }
}

// MARK: - Comparable Conformance
extension ReadingLevel {
    static func < (lhs: ReadingLevel, rhs: ReadingLevel) -> Bool {
        return lhs.vocabularyComplexity < rhs.vocabularyComplexity
    }
}
