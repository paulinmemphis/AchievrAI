import SwiftUI
import Combine

/// Coordinates between the adaptive feedback system and the story generation feature
class StoryFeedbackCoordinator: ObservableObject {
    // MARK: - Singleton
    static let shared = StoryFeedbackCoordinator()
    
    // MARK: - Published Properties
    @Published var isProcessingEntry = false
    @Published var latestChapter: StoryChapter?
    @Published var storyNodes: [MultiModal.StoryNode] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let feedbackManager = AdaptiveFeedbackManager()
    private let apiBaseURL = "https://api.achievrai.com"
    
    // MARK: - Initialization
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    // MARK: - Public Methods
    
    /// Process a journal entry to generate both adaptive feedback and a story chapter
    /// - Parameters:
    ///   - entry: The journal entry to process
    ///   - childId: The ID of the child
    ///   - journalMode: The developmental mode of the child's journal
    ///   - completion: Callback with result containing both feedback and story chapter
    func processJournalEntry(
        entry: JournalEntry,
        childId: String,
        journalMode: ChildJournalMode,
        completion: @escaping (Result<(AdaptiveFeedback, StoryChapter?), Error>) -> Void
    ) {
        isProcessingEntry = true
        
        // Step 1: Generate adaptive feedback
        guard let feedback = feedbackManager.generateFeedback(
            for: entry,
            childId: childId,
            mode: journalMode
        ) else {
            isProcessingEntry = false
            completion(.failure(CoordinatorError.feedbackGenerationFailed))
            return
        }
        
        // Step 2: Extract metadata from the journal entry
        extractMetadata(from: entry.content) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let metadata):
                // Step 3: Generate story chapter using the metadata
                self.generateStoryChapter(
                    metadata: metadata,
                    userId: childId,
                    previousArcs: self.getPreviousStoryArcs(for: childId)
                ) { chapterResult in
                    self.isProcessingEntry = false
                    
                    switch chapterResult {
                    case .success(let chapter):
                        // Store the story node
                        let storyNode = MultiModal.StoryNode(
                            entryId: entry.id,
                            chapterId: chapter.chapterId,
                            parentId: self.storyNodes.last?.chapterId,
                            metadata: metadata
                        )
                        self.storyNodes.append(storyNode)
                        self.latestChapter = chapter
                        
                        // Return both feedback and chapter
                        completion(.success((feedback, chapter)))
                        
                    case .failure(let error):
                        // Return feedback but no chapter
                        completion(.success((feedback, nil)))
                        self.errorMessage = error.localizedDescription
                    }
                }
                
            case .failure(let error):
                self.isProcessingEntry = false
                // Return feedback but no chapter
                completion(.success((feedback, nil)))
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Fetches the story map for a specific child
    /// - Parameters:
    ///   - childId: The ID of the child
    ///   - completion: Callback with the result containing story nodes
    func fetchStoryMap(for childId: String, completion: @escaping (Result<[MultiModal.StoryNode], Error>) -> Void) {
        // In a real app, this would fetch from the API
        // For now, we'll return the locally stored nodes
        completion(.success(storyNodes))
    }
    
    // MARK: - Private Methods
    
    /// Extracts metadata from journal entry text using NLP
    private func extractMetadata(from text: String, completion: @escaping (Result<MultiModal.EntryMetadata, Error>) -> Void) {
        // Create the request to the metadata extraction endpoint
        guard let url = URL(string: "\(apiBaseURL)/api/metadata") else {
            completion(.failure(CoordinatorError.invalidURL))
            return
        }
        
        // Prepare the request body
        let requestBody = ["text": text]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(CoordinatorError.jsonEncodingFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For development/demo purposes, simulate the API call
        simulateMetadataExtraction(text: text, completion: completion)
        
        // In a real app, you would use this code to make the actual API call:
        /*
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: EntryMetadata.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completionStatus in
                    if case .failure(let error) = completionStatus {
                        completion(.failure(error))
                    }
                },
                receiveValue: { metadata in
                    completion(.success(metadata))
                }
            )
            .store(in: &cancellables)
        */
    }
    
    /// Generates a story chapter based on journal entry metadata
    private func generateStoryChapter(
        metadata: MultiModal.EntryMetadata,
        userId: String,
        previousArcs: [String],
        completion: @escaping (Result<StoryChapter, Error>) -> Void
    ) {
        // Create the request to the chapter generation endpoint
        guard let url = URL(string: "\(apiBaseURL)/api/generate-chapter") else {
            completion(.failure(CoordinatorError.invalidURL))
            return
        }
        
        // Determine the genre based on the child's preferences
        // In a real app, this would be fetched from the child's profile
        let genre = determineGenreForChild(userId: userId)
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "metadata": metadata.dictionary,
            "userId": userId,
            "genre": genre,
            "previousArcs": previousArcs
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(CoordinatorError.jsonEncodingFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For development/demo purposes, simulate the API call
        simulateChapterGeneration(metadata: metadata, genre: genre, completion: completion)
        
        // In a real app, you would use this code to make the actual API call:
        /*
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: StoryChapter.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completionStatus in
                    if case .failure(let error) = completionStatus {
                        completion(.failure(error))
                    }
                },
                receiveValue: { chapter in
                    completion(.success(chapter))
                }
            )
            .store(in: &cancellables)
        */
    }
    
    /// Gets previous story arcs for a child to maintain narrative continuity
    private func getPreviousStoryArcs(for childId: String) -> [String] {
        // In a real app, this would fetch from a database
        // For now, extract from the existing story nodes
        return storyNodes
            .filter { $0.entryId.uuidString.contains(childId) }
            .compactMap { node in
                guard let metadata = node.metadata else { return nil }
                return metadata.themes.first
            }
    }
    
    /// Determines the appropriate genre based on child preferences
    private func determineGenreForChild(userId: String) -> String {
        // In a real app, this would be fetched from the child's profile
        // For now, return a default genre
        let genres = ["fantasy", "adventure", "mystery", "science fiction"]
        return genres[abs(userId.hashValue) % genres.count]
    }
    
    // MARK: - Simulation Methods (for development/demo purposes)
    
    /// Simulates metadata extraction for development purposes
    private func simulateMetadataExtraction(text: String, completion: @escaping (Result<MultiModal.EntryMetadata, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Create simulated metadata based on the text content
            let sentiment = text.lowercased().contains("happy") || text.lowercased().contains("excited") ? "positive" :
                           text.lowercased().contains("sad") || text.lowercased().contains("angry") ? "negative" : "neutral"
            
            let themes = self.extractSimulatedThemes(from: text)
            let entities = self.extractSimulatedEntities(from: text)
            let keyPhrases = self.extractSimulatedKeyPhrases(from: text)
            
            let metadata = MultiModal.EntryMetadata(
                sentiment: sentiment,
                themes: themes,
                entities: entities,
                keyPhrases: keyPhrases
            )
            
            completion(.success(metadata))
        }
    }
    
    /// Simulates story chapter generation for development purposes
    private func simulateChapterGeneration(
        metadata: MultiModal.EntryMetadata,
        genre: String,
        completion: @escaping (Result<StoryChapter, Error>) -> Void
    ) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create a simulated chapter based on the metadata and genre
            let chapterId = UUID().uuidString
            
            // Generate a chapter title based on themes and sentiment
            let title = self.generateSimulatedTitle(metadata: metadata, genre: genre)
            
            // Generate chapter text based on metadata
            let text = self.generateSimulatedChapterText(metadata: metadata, genre: genre)
            
            // Generate a cliffhanger for the next chapter
            let cliffhanger = self.generateSimulatedCliffhanger(metadata: metadata, genre: genre)
            
            let chapter = StoryChapter(
                chapterId: chapterId,
                title: title,
                text: text,
                cliffhanger: cliffhanger
            )
            
            completion(.success(chapter))
        }
    }
    
    /// Extracts simulated themes from text
    private func extractSimulatedThemes(from text: String) -> [String] {
        var themes: [String] = []
        
        if text.lowercased().contains("friend") || text.lowercased().contains("together") {
            themes.append("friendship")
        }
        
        if text.lowercased().contains("learn") || text.lowercased().contains("school") || text.lowercased().contains("study") {
            themes.append("learning")
        }
        
        if text.lowercased().contains("afraid") || text.lowercased().contains("scared") || text.lowercased().contains("brave") {
            themes.append("courage")
        }
        
        if text.lowercased().contains("help") || text.lowercased().contains("kind") {
            themes.append("kindness")
        }
        
        if text.lowercased().contains("try") || text.lowercased().contains("hard") || text.lowercased().contains("practice") {
            themes.append("perseverance")
        }
        
        // Add a default theme if none were found
        if themes.isEmpty {
            themes.append("adventure")
        }
        
        return themes
    }
    
    /// Extracts simulated entities from text
    private func extractSimulatedEntities(from text: String) -> [String] {
        var entities: [String] = []
        
        // Simple word-based entity extraction
        let words = text.split(separator: " ")
        for word in words {
            let lowercased = word.lowercased()
            
            // Check for capitalized words that might be names
            if word.first?.isUppercase == true && word.count > 1 && !["I", "My", "The", "A", "An"].contains(String(word)) {
                entities.append(String(word))
            }
            
            // Check for common places
            if ["school", "park", "home", "library", "playground"].contains(lowercased) {
                entities.append(String(lowercased))
            }
        }
        
        return Array(Set(entities)) // Remove duplicates
    }
    
    /// Extracts simulated key phrases from text
    private func extractSimulatedKeyPhrases(from text: String) -> [String] {
        var keyPhrases: [String] = []
        
        // Split text into sentences
        let sentences = text.components(separatedBy: [".","!", "?"])
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 5 && trimmed.count < 50 {
                // Short sentences that might be meaningful
                keyPhrases.append(trimmed)
            }
        }
        
        // Limit to 3 key phrases
        return Array(keyPhrases.prefix(3))
    }
    
    /// Generates a simulated chapter title
    private func generateSimulatedTitle(metadata: MultiModal.EntryMetadata, genre: String) -> String {
        let themeWord = metadata.themes.first ?? "adventure"
        
        let fantasyTitles = [
            "The \(themeWord.capitalized) Quest",
            "Magic of \(themeWord.capitalized)",
            "The Enchanted \(themeWord.capitalized)"
        ]
        
        let adventureTitles = [
            "Journey to \(themeWord.capitalized)",
            "The Great \(themeWord.capitalized)",
            "Discovering \(themeWord.capitalized)"
        ]
        
        let mysteryTitles = [
            "The Secret of \(themeWord.capitalized)",
            "Mystery at \(themeWord.capitalized)",
            "The Hidden \(themeWord.capitalized)"
        ]
        
        let scifiTitles = [
            "Space \(themeWord.capitalized)",
            "The \(themeWord.capitalized) Dimension",
            "Future \(themeWord.capitalized)"
        ]
        
        switch genre {
        case "fantasy":
            return fantasyTitles[abs(themeWord.hashValue) % fantasyTitles.count]
        case "adventure":
            return adventureTitles[abs(themeWord.hashValue) % adventureTitles.count]
        case "mystery":
            return mysteryTitles[abs(themeWord.hashValue) % mysteryTitles.count]
        case "science fiction":
            return scifiTitles[abs(themeWord.hashValue) % scifiTitles.count]
        default:
            return "The \(themeWord.capitalized) Story"
        }
    }
    
    /// Generates simulated chapter text
    private func generateSimulatedChapterText(metadata: MultiModal.EntryMetadata, genre: String) -> String {
        let theme = metadata.themes.first ?? "adventure"
        let entity = metadata.entities.first ?? "character"
        let sentiment = metadata.sentiment
        
        // Create a character name if none exists
        let characterName = entity.first?.isUppercase == true ? entity : "Alex"
        
        // Generate different chapter openings based on genre
        let opening: String
        switch genre {
        case "fantasy":
            opening = "In the magical land of Eldoria, \(characterName) discovered a hidden power within."
        case "adventure":
            opening = "As the sun rose over the mountains, \(characterName) prepared for the greatest adventure yet."
        case "mystery":
            opening = "The old clock struck midnight as \(characterName) found the mysterious note under the door."
        case "science fiction":
            opening = "The spaceship's computers beeped softly as \(characterName) gazed out at the stars."
        default:
            opening = "Once upon a time, \(characterName) embarked on an incredible journey."
        }
        
        // Generate middle section based on theme and sentiment
        let middle: String
        switch theme {
        case "friendship":
            if sentiment == "positive" {
                middle = "Together with trusted friends, they faced the challenge with courage and laughter. Each person contributed their unique talents, making the group stronger than any individual could be alone."
            } else {
                middle = "The path ahead seemed lonely, but \(characterName) remembered that true friendship could weather any storm. Sometimes the greatest bonds are formed during the most difficult times."
            }
        case "learning":
            if sentiment == "positive" {
                middle = "With each new discovery, \(characterName)'s understanding grew. Knowledge was like a torch illuminating the darkness, revealing possibilities that were previously hidden."
            } else {
                middle = "The lessons were difficult, requiring patience and persistence. \(characterName) struggled but refused to give up, knowing that growth often comes from the greatest challenges."
            }
        case "courage":
            if sentiment == "positive" {
                middle = "Fear tried to take hold, but \(characterName) stood firm. With a deep breath and determined heart, the impossible suddenly seemed possible."
            } else {
                middle = "The shadows loomed large and threatening. \(characterName) trembled but took one step forward, then another. Sometimes courage isn't about being fearless, but about moving forward despite the fear."
            }
        case "kindness":
            if sentiment == "positive" {
                middle = "A simple act of compassion created ripples that spread far beyond what \(characterName) could see. In helping others, they discovered a strength within themselves."
            } else {
                middle = "In a world that sometimes seemed cold, \(characterName) chose warmth. The path of kindness wasn't always easy, but it was always right."
            }
        case "perseverance":
            if sentiment == "positive" {
                middle = "Despite setbacks, \(characterName) continued forward, one determined step at a time. Success wasn't about never falling, but about rising every time you fall."
            } else {
                middle = "The challenge seemed insurmountable, testing \(characterName)'s resolve to its limits. Yet with each attempt, the impossible became slightly more possible."
            }
        default:
            middle = "The journey continued with unexpected twists and turns. \(characterName) discovered that the greatest adventures often come from the most unexpected beginnings."
        }
        
        // Combine sections into a complete chapter
        return "\(opening)\n\n\(middle)"
    }
    
    /// Generates a simulated cliffhanger for the next chapter
    private func generateSimulatedCliffhanger(metadata: MultiModal.EntryMetadata, genre: String) -> String {
        let theme = metadata.themes.first ?? "adventure"
        
        let fantasyCliffhangers = [
            "But as the ancient spell began to glow, everything was about to change...",
            "The magical doorway appeared out of nowhere, beckoning them forward...",
            "Little did they know, the prophecy was just beginning to unfold..."
        ]
        
        let adventureCliffhangers = [
            "The map revealed a hidden path that no one had discovered before...",
            "As they reached the summit, an unexpected sight left them speechless...",
            "The journey was far from over; in fact, it was just beginning..."
        ]
        
        let mysteryCliffhangers = [
            "The final clue made no sense—until they looked at it upside down...",
            "Someone had been watching them the entire time...",
            "The locked box contained a secret that would change everything..."
        ]
        
        let scifiCliffhangers = [
            "The strange signal from deep space suddenly became clear...",
            "The technology wasn't just advanced—it wasn't from Earth at all...",
            "Time itself seemed to bend around them as the device activated..."
        ]
        
        switch genre {
        case "fantasy":
            return fantasyCliffhangers[abs(theme.hashValue) % fantasyCliffhangers.count]
        case "adventure":
            return adventureCliffhangers[abs(theme.hashValue) % adventureCliffhangers.count]
        case "mystery":
            return mysteryCliffhangers[abs(theme.hashValue) % mysteryCliffhangers.count]
        case "science fiction":
            return scifiCliffhangers[abs(theme.hashValue) % scifiCliffhangers.count]
        default:
            return "What would happen next? Only time would tell..."
        }
    }
}

// MARK: - Error Types

/// Errors specific to the StoryFeedbackCoordinator
enum CoordinatorError: Error, LocalizedError {
    case feedbackGenerationFailed
    case invalidURL
    case jsonEncodingFailed
    case networkError(String)
    case apiError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .feedbackGenerationFailed:
            return "Failed to generate adaptive feedback."
        case .invalidURL:
            return "Invalid URL for API request."
        case .jsonEncodingFailed:
            return "Failed to encode request data."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError:
            return "Failed to decode API response."
        }
    }
}

// MARK: - Data Models

// Removed redundant MediaEntryMetadata declaration - using MultiModal.EntryMetadata instead

/// A chapter in the child's personalized story
struct StoryChapter: Identifiable, Codable {
    let chapterId: String
    let title: String
    let text: String
    let cliffhanger: String
    
    var id: String { chapterId }
}

// Removed redundant MediaStoryNode declaration - using MultiModal.StoryNode instead
