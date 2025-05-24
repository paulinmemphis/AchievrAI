import Foundation
import NaturalLanguage


class OnDeviceMetadataExtractor {

    
    
    func extractMetadata(from text: String) -> StoryMetadata {
        var sentimentScore: Double?
        var themes: [String] = []
        var entities: [String] = []
        var keyPhrases: [String] = []

        
        let sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
        sentimentTagger.string = text
        let (sentiment, _) = sentimentTagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if let sentimentValue = sentiment?.rawValue {
            sentimentScore = Double(sentimentValue)
        }

        
        let entityTagger = NLTagger(tagSchemes: [.nameType])
        entityTagger.string = text
        let entityOptions: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        entityTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: entityOptions) { tag, tokenRange in
            if let tag = tag,
               (tag == .personalName || tag == .placeName || tag == .organizationName) {
                entities.append(String(text[tokenRange]))
            }
            return true
        }
        
        entities = Array(NSOrderedSet(array: entities)) as? [String] ?? entities


        
        
        
        let lemmaTagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        lemmaTagger.string = text
        let lemmaOptions: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        var potentialKeywords: [String] = []

        lemmaTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: lemmaOptions) { lexicalTag, tokenRange in
            if let lexicalTag = lexicalTag, (lexicalTag == .noun || lexicalTag == .verb) {
                
                lemmaTagger.string = String(text[tokenRange]) 
                let (lemma, _) = lemmaTagger.tag(at: text.startIndex, unit: .word, scheme: .lemma)
                if let lemma = lemma?.rawValue, !lemma.isEmpty, lemma.count > 2 { 
                     potentialKeywords.append(lemma.lowercased())
                }
            }
            return true
        }
        
        
        let keywordCounts = potentialKeywords.reduce(into: [:]) { counts, keyword in counts[keyword, default: 0] += 1 }
        let sortedKeywords = keywordCounts.sorted { $0.value > $1.value }
        themes = sortedKeywords.prefix(5).map { $0.key } 
        
        
        keyPhrases = themes


        return StoryMetadata(
            sentimentScore: sentimentScore,
            themes: themes.isEmpty ? nil : themes,
            entities: entities.isEmpty ? nil : entities,
            keyPhrases: keyPhrases.isEmpty ? nil : keyPhrases
        )
    }
}
