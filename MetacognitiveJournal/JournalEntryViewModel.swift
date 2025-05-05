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
        // Note: We might still need to save the adapted entry if persistence expects it
        // Or adjust the flow to pass the adapted entry directly without saving it first
        // For now, let's assume generateStoryFromEntry handles the rest
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
                }, receiveValue: { [weak self] metadata in
                    // Convert metadata to EntryMetadata for StoryNode
                    let entryMetadata = EntryMetadata(
                        sentiment: metadata.sentiment,
                        themes: metadata.themes,
                        entities: metadata.entities,
                        keyPhrases: metadata.keyPhrases
                    )
                    self?.generateChapterFromMetadata(entryMetadata, entryId: entry.id.uuidString)
                })
                .store(in: &cancellables)
        } else {
            // Queue for offline processing
            self.queueOfflineRequest(entry)
        }
    }
    
    /// Generates a chapter using the extracted metadata
    /// - Parameters:
    ///   - metadata: The extracted metadata
    ///   - entryId: The ID of the journal entry
    private func generateChapterFromMetadata(_ metadata: EntryMetadata, entryId: String) {
        // Update progress
        self.generationProgress = 0.5
        self.generationStep = "Crafting your story..."
        
        // Get previous story arcs if available
        let previousArcs: [PreviousArc] = persistenceManager.getPreviousStoryArcs(limit: 3)
        
        // Generate the chapter
        narrativeClient.generateChapter(
            metadata: metadata,
            userId: userId,
            genre: selectedGenre,
            previousArcs: previousArcs
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        }, receiveValue: { [weak self] chapterResponse in
            self?.handleGeneratedChapter(chapterResponse, entryId: entryId, metadata: metadata)
        })
        .store(in: &cancellables)
    }
    
    /// Handles the generated chapter response
    /// - Parameters:
    ///   - chapterResponse: The generated chapter
    ///   - entryId: The ID of the journal entry
    ///   - metadata: The entry metadata
    private func handleGeneratedChapter(_ chapterResponse: ChapterResponse, entryId: String, metadata: EntryMetadata) {
        // Update progress
        self.generationProgress = 0.75
        self.generationStep = "Adding finishing touches..."
        
        // Create a StoryNode to connect entry and chapter
        let storyNode = StoryNode(
            id: UUID().uuidString,
            entryId: entryId,
            chapterId: chapterResponse.chapterId,
            parentId: findParentNodeId(for: entryId),
            metadata: metadata,
            creationDate: Date()
        )
        
        // Save the chapter and story node
        persistenceManager.saveChapter(
            Chapter(
                id: chapterResponse.chapterId,
                text: chapterResponse.text,
                cliffhanger: chapterResponse.cliffhanger,
                genre: selectedGenre,
                creationDate: Date()
            )
        )
        .flatMap { _ in
            // After saving the chapter, save the story node
            return self.persistenceManager.saveStoryNode(storyNode)
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            if case .failure(let error) = completion {
                self?.handleError(error)
            } else {
                // Completed successfully
                self?.generationProgress = 1.0
                self?.generationStep = "Complete!"
                
                // Delay to show the 100% state briefly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.isGeneratingStory = false
                }
            }
        } receiveValue: { [weak self] _ in
            // Set the generated chapter for display
            self?.chapter = chapterResponse
        }
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
