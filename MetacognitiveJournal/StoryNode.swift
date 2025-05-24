import Foundation


struct StoryNode: Codable, Identifiable, Hashable {
    
    var id: String = UUID().uuidString

    
    var journalEntryId: String

    
    var chapterId: String

    
    
    
    var parentId: String?

    
    
    
    var metadataSnapshot: StoryMetadata?

    
    var createdAt: Date = Date()
}
