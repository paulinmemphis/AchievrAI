import SwiftUI
import Combine

/// A view for generating new story chapters based on journal entries
struct StoryGenerationView: View {
    // MARK: - Environment
    @EnvironmentObject private var narrativeEngineManager: NarrativeEngineManager
    @EnvironmentObject private var journalStore: JournalStore
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var selectedEntries: Set<UUID> = []
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0
    @State private var generationError: String? = nil
    @State private var generatedChapter: StoryNode? = nil
    @State private var showSuccessAlert = false
    
    // MARK: - Private Properties
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Genre Selection Card
                    genreCard
                    
                    // Journal Entry Selection
                    entriesSection
                    
                    // Generation Button
                    generateButton
                    
                    // Progress or Result
                    if isGenerating {
                        progressView
                    } else if let chapter = generatedChapter {
                        chapterPreview(chapter)
                    }
                }
                .padding()
            }
            .navigationTitle("Generate Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        narrativeEngineManager.showGenreSelection = true
                    }
                }
            }
            .sheet(isPresented: $narrativeEngineManager.showGenreSelection) {
                GenreSelectionView(
                    selectedGenre: $narrativeEngineManager.defaultGenre,
                    isPresented: $narrativeEngineManager.showGenreSelection
                )
            }
            .alert("Chapter Generated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your story chapter has been successfully generated and added to your story map.")
            }
            .alert(item: Binding(
                get: { generationError.map { ErrorWrapper(error: $0) } },
                set: { generationError = $0?.error }
            )) { errorWrapper in
                Alert(
                    title: Text("Generation Failed"),
                    message: Text(errorWrapper.error),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(timer) { _ in
                if isGenerating {
                    // Simulate progress for better UX
                    if generationProgress < 0.95 {
                        generationProgress += 0.01
                    }
                }
            }
            .background(themeManager.selectedTheme.backgroundColor)
        }
    }
    
    // MARK: - UI Components
    
    /// Genre selection card
    private var genreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Story Genre")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    narrativeEngineManager.showGenreSelection = true
                } label: {
                    Text("Change")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            
            HStack(spacing: 15) {
                // Genre icon
                Image(systemName: iconForGenre(narrativeEngineManager.defaultGenre))
                    .font(.title)
                    .foregroundColor(colorForGenre(narrativeEngineManager.defaultGenre))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(colorForGenre(narrativeEngineManager.defaultGenre).opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(narrativeEngineManager.defaultGenre)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(descriptionForGenre(narrativeEngineManager.defaultGenre))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
            
            // Sample text
            Text(sampleTextForGenre(narrativeEngineManager.defaultGenre))
                .font(.caption)
                .italic()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.5))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Journal entries selection section
    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Journal Entries")
                .font(.headline)
            
            Text("Choose entries to include in your story chapter")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(journalStore.entries.sorted(by: { $0.date > $1.date }).prefix(5)) { entry in
                        EntrySelectionRow(
                            entry: entry,
                            isSelected: selectedEntries.contains(entry.id),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedEntries.insert(entry.id)
                                } else {
                                    selectedEntries.remove(entry.id)
                                }
                            }
                        )
                    }
                }
            }
            .frame(height: 250)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Generate button
    private var generateButton: some View {
        Button {
            generateStoryChapter()
        } label: {
            Text(isGenerating ? "Generating..." : "Generate Chapter")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedEntries.isEmpty ? Color.gray : themeManager.selectedTheme.accentColor)
                )
        }
        .disabled(selectedEntries.isEmpty || isGenerating)
    }
    
    /// Progress view during generation
    private var progressView: some View {
        VStack(spacing: 15) {
            ProgressView(value: generationProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(themeManager.selectedTheme.accentColor)
            
            Text("Creating your story chapter...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Preview of the generated chapter
    private func chapterPreview(_ chapter: StoryNode) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Use chapterId as a fallback since StoryNode doesn't have a title property
            Text("Chapter \(chapter.chapterId)")
                .font(.title3)
                .fontWeight(.bold)
            
            // StoryNode doesn't have a content property, use a placeholder
            Text("Preview of chapter content...")
                .font(.body)
                .lineLimit(5)
            
            HStack {
                Spacer()
                
                Button {
                    // View in story map
                    showSuccessAlert = true
                } label: {
                    Text("View in Story Map")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Actions
    
    /// Generates a new story chapter using the NarrativeAPIService
    private func generateStoryChapter() {
        guard !selectedEntries.isEmpty else { return }
        
        isGenerating = true
        generationProgress = 0
        generationError = nil
        
        // Get the selected entries
        let entries = journalStore.entries.filter { selectedEntries.contains($0.id) }
        // Combine all reflection prompt responses as content
        let entryContents = entries.map { entry in 
            entry.reflectionPrompts.compactMap { $0.response }.joined(separator: "\n")
        }.joined(separator: "\n\n")
        
        // Create a cancellable set for our API requests
        var cancellables = Set<AnyCancellable>()
        
        // Step 1: Get metadata from the journal entries
        let apiService = NarrativeAPIService()
        
        // Update progress
        generationProgress = 0.1
        
        apiService.getMetadata(text: entryContents)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [self] completion in
                
                switch completion {
                case .finished:
                    break // Will continue in receiveValue
                case .failure(let error):
                    self.isGenerating = false
                    self.generationError = "Failed to analyze journal entries: \(error.localizedDescription)"
                    self.generationProgress = 0
                }
            }, receiveValue: { [self] metadata in
                
                // Update progress
                self.generationProgress = 0.3
                
                // Step 2: Generate a chapter using the metadata
                let userId = UUID().uuidString // In a real app, get this from UserProfile
                let studentName = "You" // In a real app, get this from UserProfile
                
                // Get previous story arcs for continuity
                let persistenceManager = StoryPersistenceManager.shared
                let previousArcs = persistenceManager.getPreviousStoryArcs(limit: 2)
                
                // Create the chapter generation request
                // Convert MetadataResponse to EntryMetadata
                let entryMetadata = EntryMetadata(
                    sentiment: metadata.sentiment,
                    themes: metadata.themes,
                    entities: metadata.entities,
                    keyPhrases: metadata.keyPhrases
                )
                
                let chapterRequest = ChapterGenerationRequest(
                    metadata: entryMetadata,
                    userId: userId,
                    genre: self.narrativeEngineManager.defaultGenre,
                    previousArcs: previousArcs
                )
                
                // Update progress
                self.generationProgress = 0.5
                
                // Generate the chapter
                apiService.generateChapter(requestData: chapterRequest)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { [self] completion in
                        
                        switch completion {
                        case .finished:
                            break // Will continue in receiveValue
                        case .failure(let error):
                            self.isGenerating = false
                            self.generationError = "Failed to generate story chapter: \(error.localizedDescription)"
                            self.generationProgress = 0
                        }
                    }, receiveValue: { [self] chapterResponse in
                        
                        // Update progress
                        self.generationProgress = 0.8
                        
                        // Create a StoryNode from the chapter response
                        // Create a sample metadata for the StoryNode
                        let sampleMetadata = EntryMetadata(
                            sentiment: "neutral",
                            themes: [self.narrativeEngineManager.defaultGenre],
                            entities: [],
                            keyPhrases: []
                        )

                        // Convert EntryMetadata to StoryMetadata for the StoryNode
                        let sentimentScoreFromSample: Double?
                        switch sampleMetadata.sentiment.lowercased() {
                            case "positive": sentimentScoreFromSample = 0.8
                            case "neutral": sentimentScoreFromSample = 0.0
                            case "negative": sentimentScoreFromSample = -0.8
                            default: sentimentScoreFromSample = nil
                        }
                        let convertedSampleMetadata = StoryMetadata(
                            sentimentScore: sentimentScoreFromSample,
                            themes: sampleMetadata.themes,
                            entities: sampleMetadata.entities,
                            keyPhrases: sampleMetadata.keyPhrases
                        )

                        // Get the first selected entry ID or generate a new one if none selected
                        let entryId = selectedEntries.first?.uuidString ?? UUID().uuidString
                        
                        let storyNode = StoryNode(
                            id: UUID().uuidString,
                            journalEntryId: entryId,
                            chapterId: chapterResponse.chapterId,
                            parentId: nil,
                            metadataSnapshot: convertedSampleMetadata,
                            createdAt: Date()
                        )
                        
                        // Save the generated chapter
                        persistenceManager.saveStoryNode(storyNode)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: { [self] completion in
                                
                                switch completion {
                                case .finished:
                                    // Update progress to complete
                                    self.generationProgress = 1.0
                                    
                                    // Notify the coordinator that a new chapter was generated
                                    self.narrativeEngineManager.processOfflineRequests()
                                    
                                    // Complete generation
                                    self.isGenerating = false
                                    
                                case .failure(let error):
                                    self.isGenerating = false
                                    self.generationError = "Failed to save story chapter: \(error.localizedDescription)"
                                    self.generationProgress = 0
                                }
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    })
                    .store(in: &cancellables)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    /// Gets the icon for a genre
    private func iconForGenre(_ genre: String) -> String {
        switch genre {
        case "Fantasy": return "wand.and.stars"
        case "Sci-Fi": return "helm.of.mercury"
        case "Mystery": return "magnifyingglass"
        case "Adventure": return "map"
        case "Romance": return "heart"
        case "Historical": return "clock.arrow.circlepath"
        case "Thriller": return "exclamationmark.triangle"
        case "Comedy": return "face.smiling"
        case "Educational": return "book"
        case "Sports": return "figure.run"
        default: return "book.fill"
        }
    }
    
    /// Gets the color for a genre
    private func colorForGenre(_ genre: String) -> Color {
        switch genre {
        case "Fantasy": return .purple
        case "Sci-Fi": return .blue
        case "Mystery": return .indigo
        case "Adventure": return .green
        case "Romance": return .pink
        case "Historical": return .brown
        case "Thriller": return .red
        case "Comedy": return .orange
        case "Educational": return .teal
        case "Sports": return .mint
        default: return .blue
        }
    }
    
    /// Gets the description for a genre
    private func descriptionForGenre(_ genre: String) -> String {
        switch genre {
        case "Fantasy": return "Magical worlds with mythical creatures, wizards, and epic quests"
        case "Sci-Fi": return "Future technology, space exploration, and scientific discoveries"
        case "Mystery": return "Puzzling events, clues, and detective work to solve a case"
        case "Adventure": return "Exciting journeys filled with challenges and discoveries"
        case "Romance": return "Relationships, emotional connections, and personal growth"
        case "Historical": return "Stories set in the past with authentic historical elements"
        case "Thriller": return "Suspenseful situations with high stakes and danger"
        case "Comedy": return "Humorous situations and witty dialogue to entertain"
        case "Educational": return "Learning-focused narratives with academic concepts"
        case "Sports": return "Athletic pursuits, teamwork, and competition"
        default: return "Engaging narratives that bring your journal entries to life"
        }
    }
    
    /// Gets sample text for a genre
    private func sampleTextForGenre(_ genre: String) -> String {
        switch genre {
        case "Fantasy": return "The ancient spell glowed between Elara's fingertips as the dragon circled overhead. This was her moment to prove herself to the Council of Mages."
        case "Sci-Fi": return "The neural interface hummed as Captain Vega connected to the ship's AI. 'Status report on the quantum drive,' she commanded silently."
        case "Mystery": return "Detective Harlow examined the peculiar markings on the door. 'The victim knew their assailant,' he murmured, 'this wasn't random.'"
        case "Adventure": return "The ancient map led them to the edge of the waterfall. 'The temple must be hidden behind it,' Alex said, securing the climbing rope."
        case "Romance": return "Their eyes met across the crowded room, and suddenly the music seemed to fade. Jordan knew in that moment everything was about to change."
        case "Historical": return "The year was 1863, and as the cannons sounded in the distance, Eleanor knew her family's plantation would never be the same."
        case "Thriller": return "The timer on the device ticked down as Morgan frantically searched for the disarm code. Only two minutes remained."
        case "Comedy": return "As the wedding cake slowly tipped over, Casey made a diving catch that landed them face-first in the frosting. The guests erupted in laughter."
        case "Educational": return "'The mitochondria,' explained Professor Lee, 'is like the power plant of the cell.' Sarah suddenly visualized tiny workers in an energy factory."
        case "Sports": return "Down by two with seconds on the clock, Riley took a deep breath and stepped up to the free-throw line. Everything had led to this moment."
        default: return "The narrative unfolded like pages from a personal journal, each moment revealing deeper insights into the character's journey."
        }
    }
    
    /// Gets a title word for a genre
    private func titleWordForGenre(_ genre: String) -> String {
        switch genre {
        case "Fantasy": return "Mystical"
        case "Sci-Fi": return "Stellar"
        case "Mystery": return "Enigmatic"
        case "Adventure": return "Daring"
        case "Romance": return "Passionate"
        case "Historical": return "Timeless"
        case "Thriller": return "Perilous"
        case "Comedy": return "Hilarious"
        case "Educational": return "Enlightening"
        case "Sports": return "Triumphant"
        default: return "Unexpected"
        }
    }
    
    /// Gets a setting for a genre
    private func settingForGenre(_ genre: String) -> String {
        switch genre {
        case "Fantasy": return "enchanted forest of Eldenwood"
        case "Sci-Fi": return "orbital station of Nova Prime"
        case "Mystery": return "fog-shrouded streets of Ravenhollow"
        case "Adventure": return "uncharted jungles of Meridian"
        case "Romance": return "charming coastal town of Harborview"
        case "Historical": return "bustling streets of 1920s Chicago"
        case "Thriller": return "abandoned facility deep underground"
        case "Comedy": return "chaotic family reunion at Lake Chuckle"
        case "Educational": return "prestigious halls of Thornfield Academy"
        case "Sports": return "championship arena with roaring crowds"
        default: return "journey of self-discovery"
        }
    }
    
    /// Gets keywords for a genre
    private func keywordsForGenre(_ genre: String) -> [String] {
        switch genre {
        case "Fantasy": return ["magic", "quests", "creatures", "kingdoms", "heroes"]
        case "Sci-Fi": return ["technology", "space", "future", "discovery", "aliens"]
        case "Mystery": return ["detective", "clues", "suspects", "investigation", "reveal"]
        case "Adventure": return ["journey", "exploration", "danger", "treasure", "wilderness"]
        case "Romance": return ["love", "relationships", "emotions", "connection", "growth"]
        case "Historical": return ["past", "events", "era", "figures", "authenticity"]
        case "Thriller": return ["suspense", "danger", "chase", "urgency", "threat"]
        case "Comedy": return ["humor", "laughter", "wit", "irony", "situational"]
        case "Educational": return ["learning", "concepts", "discovery", "knowledge", "understanding"]
        case "Sports": return ["competition", "teamwork", "victory", "challenge", "perseverance"]
        default: return ["narrative", "journey", "discovery", "growth", "insight"]
        }
    }
}

// MARK: - Supporting Views

/// A row for selecting a journal entry
struct EntrySelectionRow: View {
    let entry: JournalEntry
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.assignmentName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Combine reflection prompt responses for preview
                Text(entry.reflectionPrompts.compactMap { $0.response }.joined(separator: " ").prefix(50) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onTapGesture {
            onToggle(!isSelected)
        }
    }
}

// MARK: - Error Wrapper
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}

// MARK: - Preview
struct StoryGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        StoryGenerationView()
            .environmentObject(NarrativeEngineManager())
            .environmentObject(JournalStore())
            .environmentObject(ThemeManager())
    }
}
