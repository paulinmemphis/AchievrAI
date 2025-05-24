import Foundation



struct StoryMetadata: Codable, Hashable {
    
    var sentimentScore: Double?

    
    var themes: [String]?

    
    var entities: [String]? 

    
    var keyPhrases: [String]?

    
}
