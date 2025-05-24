import Foundation


enum StoryGenre: String, CaseIterable, Identifiable, Codable {
    case fantasy = "Fantasy"
    case adventure = "Adventure"
    case sliceOfLife = "Slice of Life"
    case mystery = "Mystery"
    case sciFi = "Science Fiction"

    var id: String { self.rawValue }
}


class OnDeviceStoryGenerator {

    
    
    
    
    func generateChapter(from metadata: StoryMetadata, genre: StoryGenre, entryId: String) -> StoryChapter {
        var chapterText = "Once upon a time..."
        var cliffhangerText: String? = "What would happen next?"

        
        switch genre {
        case .fantasy:
            chapterText = "In a realm of magic and wonder, "
            if let themes = metadata.themes, !themes.isEmpty {
                chapterText += "our story unfolds around themes of \(themes.joined(separator: ", ")). "
            }
            if let sentiment = metadata.sentimentScore {
                if sentiment > 0.3 {
                    chapterText += "A joyous energy filled the air. "
                } else if sentiment < -0.3 {
                    chapterText += "A shadow of doubt crept in. "
                } else {
                    chapterText += "The atmosphere was calm and thoughtful. "
                }
            }
            chapterText += "And so, the adventure began."
            cliffhangerText = "But a mysterious figure watched from the shadows..."
        case .adventure:
            chapterText = "The call to adventure was strong! "
            if let entities = metadata.entities, !entities.isEmpty {
                chapterText += "Our hero, perhaps named \(entities.first!), "
            } else {
                chapterText += "A brave soul "
            }
            chapterText += "set out to explore "
            if let themes = metadata.themes, !themes.isEmpty {
                chapterText += "the secrets of \(themes.first ?? "unknown lands"). "
            } else {
                chapterText += "uncharted territories. "
            }
            cliffhangerText = "What dangers awaited around the next bend?"
        case .sliceOfLife:
            chapterText = "It was an ordinary day, but something felt different. "
            if let keyPhrases = metadata.keyPhrases, !keyPhrases.isEmpty {
                chapterText += "Thoughts about \(keyPhrases.joined(separator: " and ")) lingered. "
            }
            if let sentiment = metadata.sentimentScore {
                if sentiment > 0.5 {
                    chapterText += "A feeling of happiness blossomed. "
                } else if sentiment < -0.5 {
                    chapterText += "A touch of melancholy was present. "
                } else {
                    chapterText += "It was a moment of quiet reflection. "
                }
            }
            cliffhangerText = "How would this day truly unfold?"
        case .mystery:
            chapterText = "A puzzling event had just occurred. "
            if let themes = metadata.themes, !themes.isEmpty {
                chapterText += "Clues related to \(themes.joined(separator: " and ")) were scattered about. "
            }
            if let entities = metadata.entities, !entities.isEmpty {
                chapterText += "Was \(entities.first ?? "someone") involved? "
            }
            chapterText += "The air was thick with unanswered questions."
            cliffhangerText = "The biggest clue was yet to be discovered."
         case .sciFi:
            chapterText = "In the distant future, or perhaps a galaxy far away, "
            if let themes = metadata.themes, !themes.isEmpty {
                chapterText += "humanity (or what was left of it) grappled with \(themes.joined(separator: ", ")). "
            }
            if let sentiment = metadata.sentimentScore {
                if sentiment > 0.3 {
                    chapterText += "A beacon of hope shone through the cosmos. "
                } else if sentiment < -0.3 {
                    chapterText += "A sense of cosmic dread loomed. "
                } else {
                    chapterText += "The vastness of space offered a moment of clarity. "
                }
            }
            chapterText += "A new journey through the stars was about to begin."
            cliffhangerText = "But an unknown signal echoed from the void..."
        }
        
        
        if !chapterText.contains(metadata.keyPhrases?.first ?? UUID().uuidString) { 
            if let keyPhrases = metadata.keyPhrases, !keyPhrases.isEmpty {
                chapterText += " The essence of '\(keyPhrases.first!)' was palpable."
            }
        }


        return StoryChapter(
            text: chapterText,
            cliffhanger: cliffhangerText,
            originatingEntryId: entryId
        )
    }
}
