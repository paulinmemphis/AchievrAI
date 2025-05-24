import Foundation


struct StoryChapter: Codable, Identifiable, Hashable {
    
    var id: String = UUID().uuidString

    
    var text: String

    
    var cliffhanger: String?

    
    var originatingEntryId: String? 

    
    var timestamp: Date = Date()
}
