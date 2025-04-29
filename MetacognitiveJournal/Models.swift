import Foundation
import SwiftUI

// MARK: - Narrative Engine Models

/// Represents metadata extracted from user input
struct EntryMetadata: Codable, Hashable {
    let sentiment: String
    let themes: [String]
    let entities: [String]
    let keyPhrases: [String]
}

/// Structure to represent a story arc for narrative continuity
struct StoryArc: Codable, Identifiable {
    var id = UUID()
    let summary: String
    let chapterId: String
    let timestamp: Date
    let themes: [String]
    
    static func createFrom(chapter: ChapterResponse, themes: [String] = []) -> StoryArc {
        // Create a brief summary from the chapter text (first 100 chars)
        let summary = String(chapter.text.prefix(100)) + "..."
        return StoryArc(
            summary: summary,
            chapterId: chapter.chapterId,
            timestamp: Date(),
            themes: themes
        )
    }
}

/// Response from the metadata extraction API
struct MetadataResponse: Codable {
    let sentiment: String
    let themes: [String]
    let entities: [String]
    let keyPhrases: [String]
}

/// Represents a previous story arc for chapter generation context
struct PreviousArc: Codable {
    let summary: String
    let themes: [String]
    let chapterId: String
}

/// Request for chapter generation
struct ChapterGenerationRequest: Codable {
    let metadata: EntryMetadata
    let userId: String
    let genre: String
    let previousArcs: [PreviousArc]
}

/// Response from the chapter generation API
struct ChapterResponse: Codable, Identifiable, Equatable {
    var id: String { chapterId }
    let chapterId: String
    let text: String
    let cliffhanger: String
    let studentName: String?
    let feedback: String?
}

/// Structure representing a chapter of the story
struct Chapter: Codable, Identifiable {
    let id: String
    let text: String
    let cliffhanger: String
    let genre: String
    let creationDate: Date
}

/// Structure connecting a journal entry to a story chapter
struct StoryNode: Codable, Identifiable {
    let id: String
    let entryId: String
    let chapterId: String
    let parentId: String?
    let metadata: EntryMetadata
    let creationDate: Date
    var timestamp: Date { creationDate }
}

// MARK: - Shared Helper Types

/// A UUID wrapper that provides automatic Identifiable and Hashable conformance
struct IdentifiableUUID: Identifiable, Hashable {
    let id = UUID()
}

// MARK: - View Models

/// View model representing a node for display in the StoryMapView and ChapterView
struct StoryNodeViewModel: Identifiable, Hashable {
    let id: String                 // Unique ID (usually matches StoryNode.id)
    let chapterId: String          // ID of the associated chapter
    let title: String              // Display title (e.g., "Chapter X", "Node Y")
    let entryPreview: String       // Preview of the associated journal entry text
    let chapterPreview: String     // Preview of the generated chapter text
    let sentiment: Double          // Numerical sentiment score (e.g., -1.0 to 1.0)
    let themes: [String]           // Key themes extracted
    let creationDate: Date         // When the node was created
    let genre: String              // Genre of the chapter
    
    // Computed property for sentiment color
    var sentimentColor: Color {
        if sentiment > 0.1 {
            return Color.green
        } else if sentiment < -0.1 {
            return Color.red
        } else {
            return Color.blue
        }
    }

    // Initializer to create from a StoryNode and potentially Chapter/Entry data
    // Note: Fetching Chapter/Entry data might be needed for full previews
    // For now, uses placeholders for chapter/entry details.
    init(from node: StoryNode) {
        self.id = node.id
        self.chapterId = node.chapterId
        self.title = "Chapter \(node.chapterId.suffix(6))" // Example title
        self.sentiment = Double(node.metadata.sentiment) ?? 0.0 
        self.themes = node.metadata.themes
        self.creationDate = node.creationDate
        
        // Placeholders - requires fetching actual Chapter/Entry data elsewhere
        self.chapterPreview = "Chapter preview placeholder..."
        self.entryPreview = "Entry preview placeholder..."
        self.genre = "Unknown genre"
    }
    
    // Sample initializer for previews (if needed)
    init(id: String, chapterId: String, title: String, entryPreview: String, chapterPreview: String, sentiment: Double, themes: [String], creationDate: Date, genre: String) {
        self.id = id
        self.chapterId = chapterId
        self.title = title
        self.entryPreview = entryPreview
        self.chapterPreview = chapterPreview
        self.sentiment = sentiment
        self.themes = themes
        self.creationDate = creationDate
        self.genre = genre
    }

    // Static sample for previews
    static var sample: StoryNodeViewModel {
        StoryNodeViewModel(
            id: "sample-node-id",
            chapterId: "sample-chapter-id",
            title: "Sample Chapter",
            entryPreview: "Today was interesting...",
            chapterPreview: "The story continued with great adventure...",
            sentiment: 0.5,
            themes: ["Adventure", "Discovery"],
            creationDate: Date(),
            genre: "Fantasy"
        )
    }
}
