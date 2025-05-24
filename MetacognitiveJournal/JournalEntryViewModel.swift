import Foundation
import Combine
import SwiftUI

@available(*, deprecated, message: "Use GuidedMultiModalJournalViewModel instead")
class JournalEntryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var entryText: String = ""
    @Published var selectedGenre: String = NarrativeEngineConstants.genres.first?.key ?? "fantasy"
    @Published var isGeneratingStory: Bool = false
    @Published var generationProgress: Double = 0
    @Published var generationStep: String = ""
    @Published var errorMessage: String? = nil
    @Published var chapter: ChapterResponse? = nil
    
    // MARK: - Internal Properties
    private let narrativeClient = NarrativeEngineClient()
    private let persistenceManager: StoryPersistenceManager
    private var userId: String
    private var cancellables = Set<AnyCancellable>()
    private var offlineQueue = OfflineRequestQueue.shared
    
    // MARK: - Initialization
    
    init(
        persistenceManager: StoryPersistenceManager = .shared,
        userId: String = UUID().uuidString
    ) {
        self.persistenceManager = persistenceManager
        self.userId = userId
        
        // Load user preferences for default genre
        if let savedGenre = UserDefaults.standard.string(forKey: "user_preferred_genre"),
           NarrativeEngineConstants.genres[savedGenre] != nil {
            self.selectedGenre = savedGenre
        }
    }
    
    // MARK: - Actions
    
    /// Saves the journal entry and generates a story chapter from it
    func saveEntryAndGenerateStory() {
        guard !entryText.isEmpty else {
            self.errorMessage = "Please write something before saving"
            return
        }
        
        // Reset state
        self.isGeneratingStory = true
        self.generationProgress = 0
        self.generationStep = "Saving journal entry..."
        self.errorMessage = nil
        self.chapter = nil
        
        // Create a journal entry object - adapted to match the existing JournalEntry model
        let journalEntry = JournalEntry(
            id: UUID(),
            assignmentName: "Personal Journal",
            date: Date(),
            subject: .english,  // Default subject
            emotionalState: .neutral, // Default state
            reflectionPrompts: [
                PromptResponse(id: UUID(), prompt: "Journal Entry", response: entryText)
            ]
        )
        
        // Save the entry
        persistenceManager.saveJournalEntry(journalEntry)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] savedEntry in
                self?.generateStoryFromEntry(savedEntry)
            }
            .store(in: &cancellables)
    }
    
    /// Saves a multi-modal journal entry and generates a story chapter from it
    func saveMultiModalEntryAndGenerateStory(multiModalEntry: MultiModal.JournalEntry) {
        // TODO: Implement saving the original MultiModal.JournalEntry if needed
        // e.g., persistenceManager.saveMultiModalJournalEntry(multiModalEntry)
        
        // Adapt the multi-modal entry to a standard entry for processing
        guard let unwrappedAdaptedEntry = MultiModal.adaptToStandardEntry(multiModalEntry) else {
            // Handle the case where adaptation fails
            self.errorMessage = "Failed to process the journal entry components."
            self.isGeneratingStory = false
            self.generationProgress = 0
            self.generationStep = "Error"
            // Log the error for debugging
            print("Error: MultiModal.adaptToStandardEntry returned nil")
            // Consider using a more robust error handling mechanism like ErrorHandler.shared.handle
            return // Stop execution if adaptation failed
        }
        
        // Reset state (similar to saveEntryAndGenerateStory)
        self.isGeneratingStory = true
        self.generationProgress = 0
        self.generationStep = "Saving multi-modal journal entry..."
        self.errorMessage = nil
        self.chapter = nil
        
        // Use the adapted entry for the existing story generation flow
        generateStoryFromEntry(unwrappedAdaptedEntry)
    }
    
    /// Clears the current entry text
    func clearEntry() {
        self.entryText = ""
    }
    
    /// Saves the user's preferred genre
    func saveGenrePreference() {
        UserDefaults.standard.set(selectedGenre, forKey: "user_preferred_genre")
    }
    
    // MARK: - Private Methods

    /// Converts a sentiment string (e.g., "positive", "neutral", "negative", or a numeric string) to a Double?.
    private func sentimentStringToScore(_ sentiment: String) -> Double? {
        let lowercasedSentiment = sentiment.lowercased()
        if let numericScore = Double(lowercasedSentiment) {
            return numericScore
        }
        switch lowercasedSentiment {
        case "positive", "very positive":
            return 0.8
        case "neutral":
            return 0.0
        case "negative", "very negative":
            return -0.8
        default:
            // Attempt to parse if it's a numeric string, otherwise nil
            return Double(sentiment)
        }
    }

    /// Generates a story chapter based on the journal entry content.
    /// - Parameter entry: The JournalEntry to process.
    private func generateStoryFromEntry(_ entry: MetacognitiveJournal.JournalEntry) {
        // Update progress
        self.generationProgress = 0.25
        self.generationStep = "Analyzing your entry..."

        // Check if we're online
        if NetworkMonitor.shared.isConnected {
            // Extract metadata from the entry text - get text from reflectionPrompts
            let entryText = entry.reflectionPrompts.first(where: { $0.prompt == "Journal Entry" })?.response ?? ""
            narrativeClient.extractMetadata(from: entryText)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                }, receiveValue: { [weak self] metadataResponse in
                    // Pass the original entry and the metadataResponse
                    self?.generateChapterFromMetadata(entry, metadata: metadataResponse)
                })
                .store(in: &cancellables)
        } else {
            // Queue for offline processing
            queueOfflineRequest(entry) // Assuming queueOfflineRequest takes an entry
        }
    }

    /// Generates a chapter using the extracted metadata
    /// - Parameters:
    ///   - entry: The original JournalEntry.
    ///   - metadata: The extracted metadata response.
    private func generateChapterFromMetadata(_ entry: MetacognitiveJournal.JournalEntry, metadata: MetadataResponse) {
        // Update progress
        self.generationProgress = 0.5
        self.generationStep = "Crafting your story..."

        // Get previous story arcs if available
        let previousArcs: [PreviousArc] = persistenceManager.getPreviousStoryArcs(limit: 3)

        // Convert MetadataResponse to EntryMetadata for the client
        let entryMetadata = EntryMetadata(
            sentiment: metadata.sentiment,
            themes: metadata.themes,
            entities: metadata.entities,
            keyPhrases: metadata.keyPhrases
        )

        // Generate the chapter
        narrativeClient.generateChapter(
            metadata: entryMetadata, // Use converted EntryMetadata
            userId: userId,
            genre: selectedGenre, // Use the user's selected genre for chapter generation
            previousArcs: previousArcs
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        }, receiveValue: { [weak self] chapterResponse in
            // Pass the original entry and the metadataResponse (original for StoryMetadata creation)
            self?.handleGeneratedChapter(chapterResponse, entry: entry, metadata: metadata)
        })
        .store(in: &cancellables)
    }

    /// Handles the generated chapter response
    /// - Parameters:
    ///   - chapterResponse: The generated chapter.
    ///   - entry: The original JournalEntry.
    ///   - metadata: The original metadata response from text analysis (MetadataResponse).
    private func handleGeneratedChapter(_ chapterResponse: ChapterResponse, entry: MetacognitiveJournal.JournalEntry, metadata: MetadataResponse) {
        // Update progress
        self.generationProgress = 0.75
        self.generationStep = "Saving your new chapter..."

        // 1. Create StoryMetadata (does not include genre)
        let storyMetadata = StoryMetadata(
            sentimentScore: sentimentStringToScore(metadata.sentiment),
            themes: metadata.themes,
            entities: metadata.entities,
            keyPhrases: metadata.keyPhrases
        )

        // 2. Create StoryChapter
        let storyChapter = StoryChapter(
            id: chapterResponse.id, // chapterResponse.id is chapterId
            text: chapterResponse.text,
            cliffhanger: chapterResponse.cliffhanger,
            originatingEntryId: entry.id.uuidString,
            timestamp: Date() // Use current date for chapter creation
        )

        // 3. Create StoryNode
        let storyNode = StoryNode(
            journalEntryId: entry.id.uuidString,
            chapterId: storyChapter.id,
            parentId: persistenceManager.storyArcs.sorted(by: { $0.timestamp > $1.timestamp }).first?.chapterId, // Link to most recent arc's chapterId
            metadataSnapshot: storyMetadata,
            createdAt: entry.date // Use entry's date for node creation
        )

        // 4. Save StoryChapter, then StoryNode
        persistenceManager.saveChapter(storyChapter)
            .flatMap { [weak self] () -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: AppError.unknown).eraseToAnyPublisher()
                }
                return self.persistenceManager.saveStoryNode(storyNode)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isGeneratingStory = false // Always reset this
                if case .failure(let error) = completion {
                    self.handleError(error)
                } else {
                    self.generationProgress = 1.0
                    self.generationStep = "Story chapter saved!"
                    self.chapter = chapterResponse // Update published chapter
                    AnalyticsManager.shared.logEvent(.chapterGenerated, properties: ["genre": self.selectedGenre])
                    // Optionally, trigger UI update or navigation
                }
            }, receiveValue: { /* No value expected from saveStoryNode */ })
            .store(in: &cancellables)
    }

    /// Finds the parent node ID for a new entry
    private func findParentNodeId(for entryId: String) -> String? {
        // Update progress
        self.generationProgress = 0.25
        self.generationStep = "Analyzing your entry..."
        
        // Check if we're online
        // return findParentNodeId(for: entryId) // FIXME: This caused infinite recursion! Implement actual logic.
        // TODO: Implement logic to find the actual parent node ID, likely using StoryPersistenceManager
        return nil // Temporary fix to prevent crash
    }
    
    /// Queues an entry for offline processing
    /// - Parameter entry: The journal entry to process offline
    private func queueOfflineRequest(_ entry: JournalEntry) {
        // Create a placeholder metadata for offline mode
        let _ = EntryMetadata( // Assign to _ to silence unused variable warning
            sentiment: "",
            themes: [],
            entities: [],
            keyPhrases: []
        )
        
        let offlineRequest = OfflineRequest(
            type: .generateStory,
            data: ["entryId": entry.id.uuidString, "genre": selectedGenre],
            creationDate: Date()
        )
        
        offlineQueue.addRequest(offlineRequest)
        
        // Update UI to reflect offline status
        self.generationProgress = 1.0
        self.generationStep = "Saved for offline processing"
        
        // Show a message to the user
        self.errorMessage = "You're offline. Your entry has been saved and will be processed when you're back online."
        
        // Complete the flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isGeneratingStory = false
        }
    }
    
    /// Handles errors during the process
    /// - Parameter error: The error that occurred
    private func handleError(_ error: Error) {
        // Reset generation state
        self.isGeneratingStory = false
        
        // Set error message based on error type
        if let appError = error as? AppError {
            switch appError {
            case .networkError(let urlError):
                if let urlError = urlError as? URLError, urlError.code == .notConnectedToInternet {
                    self.errorMessage = "You're offline. Please try again when you have internet connection."
                } else {
                    self.errorMessage = "Network error: \(urlError.localizedDescription)"
                }
            case .serializationFailed:
                self.errorMessage = "Failed to process your request. Please try again."
            case .apiError(let message):
                self.errorMessage = "API Error: \(message)"
            default:
                self.errorMessage = "An unexpected error occurred. Please try again."
            }
        } else {
            self.errorMessage = "An unexpected error occurred. Please try again."
        }
        
        print("Error in JournalEntryViewModel: \(error.localizedDescription)")
    }
}
