import Foundation
import Combine


class StoryManager: ObservableObject {
    
    @Published var storyNodes: [StoryNode] = []

    
    @Published var chapters: [String: StoryChapter] = [:] 

    private let metadataExtractor = OnDeviceMetadataExtractor()
    private let storyGenerator = OnDeviceStoryGenerator()

    
    

    init() {
        
        
    }

    
    
    
    
    
    @discardableResult
    func generateAndAddChapter(
        forJournalEntryText text: String,
        entryId: String,
        genre: StoryGenre 
    ) -> StoryChapter? {

        let metadata = metadataExtractor.extractMetadata(from: text)
        let chapter = storyGenerator.generateChapter(from: metadata, genre: genre, entryId: entryId)

        
        chapters[chapter.id] = chapter

        
        let storyNode = StoryNode(
            journalEntryId: entryId,
            chapterId: chapter.id,
            metadataSnapshot: metadata, 
            createdAt: Date() 
        )
        storyNodes.append(storyNode)

        
        storyNodes.sort { $0.createdAt < $1.createdAt }
        
        print("Successfully generated Chapter ID: \(chapter.id) for Entry ID: \(entryId) with Genre: \(genre.rawValue)")
        

        
        objectWillChange.send()

        return chapter
    }

    

    
    func getChapter(byId id: String) -> StoryChapter? {
        return chapters[id]
    }

    
    func getNodes(forEntryId entryId: String) -> [StoryNode] {
        return storyNodes.filter { $0.journalEntryId == entryId }
    }

    
    func getAllChaptersChronologically() -> [StoryChapter] {
        
        return storyNodes.compactMap { chapters[$0.chapterId] }
    }
    
    
    func getAllStoryNodes() -> [StoryNode] {
        return storyNodes.sorted { $0.createdAt < $1.createdAt }
    }

    
    
    
}
