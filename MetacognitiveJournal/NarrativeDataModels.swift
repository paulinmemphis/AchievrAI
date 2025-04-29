import Foundation

// MARK: - Metadata Endpoint

struct MetadataRequest: Codable {
    let text: String
}

struct MetadataResponse: Codable, Hashable {
    let sentiment: String
    let themes: [String]
    let entities: [String]
    let keyPhrases: [String]
    // Optional: Add sentiment_score if needed
    // let sentimentScore: Double?
}

// MARK: - Chapter Generation Endpoint

struct ChapterGenerationRequest: Codable {
    let metadata: MetadataResponse // Re-use the response struct
    let userId: String
    let genre: String
    let studentName: String // Add student name for personalization
    let previousArcs: [String]? // Optional array of strings
}

struct ChapterResponse: Codable, Identifiable {
    let chapterId: String
    let text: String
    let cliffhanger: String
    let studentName: String
    let feedback: String
    
    // Conform to Identifiable using chapterId
    var id: String { chapterId }
}

// MARK: - Story Node (For potential future use in StoryMapView)

struct StoryNode: Codable, Identifiable {
    let id = UUID() // Local UUID for SwiftUI Identifiable conformance
    let entryId: UUID // Link to the original JournalEntry ID
    let chapterId: String // Link to the generated chapter ID
    let parentId: UUID? // Link to the previous StoryNode's entryId (for tree structure)
    let metadata: MetadataResponse
    let chapter: ChapterResponse // Store the generated chapter data
    let timestamp: Date = Date()
}
