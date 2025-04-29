// File: AIJournalEntryView.swift
import SwiftUI
import Combine

/// A multi-step journal entry view with AI-powered tone and insights.
struct AIJournalEntryView: View {
    // Add UserProfile to access student name
    @EnvironmentObject var userProfile: UserProfile
    // ... (Existing @Environment properties) ...
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: JournalStore
    @EnvironmentObject private var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject private var themeManager: ThemeManager // Add ThemeManager
    
    // Story preferences for default genre
    @ObservedObject private var storyPreferences = StoryPreferencesManager.shared

    // --- Narrative Engine ---
    @StateObject private var narrativeAPIService = NarrativeAPIService() // Instantiate the service
    @State private var isGeneratingChapter = false
    @State private var chapterGenerationError: String? = nil
    @State private var generatedChapter: ChapterResponse? = nil
    @State private var showChapterSheet = false
    @State private var showGenreSelection = false
    @State private var selectedGenre = "" // Will be set from preferences
    @State private var cancellables = Set<AnyCancellable>() // To store Combine subscriptions


    // MARK: - Entry Inputs
    // ... (Existing @State properties) ...
    @State private var assignmentName = ""
    @State private var courseName = ""
    @State private var selectedSubject: K12Subject = .math
    @State private var emotionalReason = ""
    @State private var reflectionResponses: [String] = []
    @State private var selectedStrategies: Set<String> = []
    @State private var otherStrategies = ""

    // MARK: - AI Outputs
    @State private var aiTone = ""
    @State private var aiInsights = ""
    @State private var isLoadingAI = false
    @State private var aiError: String? = nil

    // MARK: - Control
    @State private var currentPage = 0
    private var prompts: [String] { analyzer.prompts }
    private let totalPages = 5

    var body: some View {
        // Use ZStack for overlay
        ZStack {
            // Original Content VStack
            VStack(spacing: 0) {
                // Top Bar (Disable Save/Next during generation)
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.red)
                        .disabled(isGeneratingChapter) // Disable during generation

                    Spacer()
                    Text("New Journal Entry")
                        .font(.headline)
                    Spacer()

                    Button(currentPage < totalPages - 1 ? "Next" : "Save & Create Story") { // Update button text
                        onNext()
                    }
                    .disabled(!canProceed(page: currentPage) || isGeneratingChapter) // Disable if cannot proceed or generating
                    .opacity(isGeneratingChapter ? 0.5 : 1.0) // Dim if generating
                }
                .padding()
                Divider()

                // Pages
                TabView(selection: $currentPage) {
                    basicInfoPage.tag(0)
                    emotionPage.tag(1)
                    reflectionsPage.tag(2)
                    strategiesPage.tag(3)
                    insightsPage.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                // Disable interaction with TabView during chapter generation
                .allowsHitTesting(!isGeneratingChapter)

            } // End Original VStack

            // --- Loading / Error Overlay ---
            if isGeneratingChapter || chapterGenerationError != nil {
                 Color.black.opacity(0.4) // Semi-transparent background
                     .ignoresSafeArea()
                     .zIndex(1) // Ensure overlay is on top

                 VStack(spacing: 20) {
                     if isGeneratingChapter {
                         ProgressView("Generating your next chapter...")
                             .progressViewStyle(CircularProgressViewStyle(tint: .white))
                             .foregroundColor(.white)
                     }
                     if let error = chapterGenerationError {
                         VStack {
                             Image(systemName: "exclamationmark.triangle.fill")
                                 .foregroundColor(.yellow)
                                 .font(.largeTitle)
                             Text("Chapter Generation Failed")
                                 .font(.headline)
                                 .foregroundColor(.white)
                             Text(error)
                                 .font(.caption)
                                 .foregroundColor(.gray)
                                 .multilineTextAlignment(.center)
                                 .padding(.horizontal)
                             Button("Dismiss") {
                                 // Clear error and allow view dismissal or retry?
                                 chapterGenerationError = nil
                                 // Should we dismiss the whole entry view here? Or let user decide?
                                 // For now, just clear the error overlay. User can use Cancel.
                             }
                             .buttonStyle(.borderedProminent)
                             .tint(.yellow)
                             .padding(.top)
                         }
                     }
                 }
                 .padding(30)
                 .background(Material.ultraThin) // Use a blur effect
                 .cornerRadius(15)
                 .shadow(radius: 10)
                 .zIndex(2) // Ensure VStack is above the background overlay
                 .transition(.opacity.combined(with: .scale)) // Add animation
            }

        } // End ZStack
        .animation(.easeInOut, value: isGeneratingChapter) // Animate overlay appearance
        .animation(.easeInOut, value: chapterGenerationError)
        .onAppear {
            // Initialize responses for prompts
            reflectionResponses = Array(repeating: "", count: prompts.count)
            
            // Initialize selectedGenre from preferences
            selectedGenre = storyPreferences.defaultGenre
        }
        // --- Sheet for Chapter View ---
        .sheet(isPresented: $showChapterSheet) {
            if let chapter = generatedChapter {
                ChapterView(chapter: chapter)
                    .environmentObject(themeManager) // Pass theme to sheet
            } else {
                 // Fallback: Show error or just dismiss if chapter data is missing unexpectedly
                 VStack {
                     Text("Error")
                         .font(.title)
                     Text("Could not load chapter data.")
                     Button("Dismiss") {
                         showChapterSheet = false // Dismiss the sheet
                         dismiss() // Dismiss the entry view too
                     }
                     .padding(.top)
                 }
            }
        }
        .sheet(isPresented: $showGenreSelection) {
            NavigationView {
                GenreSelectionView(selectedGenre: $selectedGenre, isPresented: $showGenreSelection)
                    .environmentObject(themeManager)
                    .environmentObject(storyPreferences)
                    .navigationBarItems(trailing: Button("Continue") {
                        // Save this genre as the default preference
                        storyPreferences.defaultGenre = selectedGenre
                        beginChapterGeneration()
                    })
            }
        }

    } // End Body

    // MARK: - Page Builders

    private var basicInfoPage: some View {
        Form {
            Section(header: Text("Assignment Details")) {
                TextField("Assignment Name", text: $assignmentName)
                TextField("Course Name", text: $courseName)
                Picker("Subject", selection: $selectedSubject) {
                    ForEach(K12Subject.allCases, id: \.self) { subject in
                        Text(subject.rawValue.capitalized).tag(subject)
                    }
                }
            }
        }
    }

    private var emotionPage: some View {
        Form {
            Section(header: Text("How did you feel about this assignment?")) {
                TextEditor(text: $emotionalReason.max(5000))
                    .frame(height: 100)
            }
        }
    }

    private var reflectionsPage: some View {
        Form {
            ForEach(0..<prompts.count, id: \.self) { idx in
                Section(header: Text(prompts[idx])) {
                    TextEditor(text: Binding(
                        get: { reflectionResponses[idx] },
                        set: { reflectionResponses[idx] = $0 }
                    ).max(5000))
                    .frame(height: 100)
                }
            }
        }
    }

    private var strategiesPage: some View {
        Form {
            Section(header: Text("What learning strategies did you use?")) {
                ForEach(["Breaking down problems", "Creating visual aids", "Practice and repetition"], id: \.self) { strategy in
                    Button(action: {
                        if selectedStrategies.contains(strategy) {
                            selectedStrategies.remove(strategy)
                        } else {
                            selectedStrategies.insert(strategy)
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedStrategies.contains(strategy) ? "checkmark.square" : "square")
                            Text(strategy)
                        }
                    }
                }
                TextEditor(text: $otherStrategies.max(5000))
                    .frame(height: 100)
            }
        }
    }

    private var insightsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingAI {
                ProgressView("Generating insights...")
            } else if let error = aiError {
                Text(error).foregroundColor(.red)
            } else {
                Text("Tone: \(aiTone)")
                Text("Insights:\n\(aiInsights)")
            }
            Spacer()
        }
        .padding()
        .task {
            await generateAIOutputs()
        }
    }

    // MARK: - Actions

    private func saveEntryAndGenerateChapter() {
        // Show genre selection before proceeding to generation
        showGenreSelection = true
    }

    private func beginChapterGeneration() {
        showGenreSelection = false
        isGeneratingChapter = true
        chapterGenerationError = nil
        generatedChapter = nil

        // Chain API Calls: Metadata -> Chapter Generation
        guard !isGeneratingChapter else { return }

        // Combine relevant text
        let combinedText = ([emotionalReason] + reflectionResponses).joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !combinedText.isEmpty else {
             // Save the entry without text for narrative? Or require text?
             // For now, let's just save and dismiss if no text.
             saveMinimalEntry() // Save only the basic JournalEntry part
             dismiss()
             return
         }

        // Create a variable to store metadata for later use
        var capturedMetadata: MetadataResponse? = nil
        
        narrativeAPIService.fetchMetadata(for: combinedText)
            .flatMap { metadataResponse -> AnyPublisher<ChapterResponse, APIServiceError> in
                // Save the entry *after* metadata is successfully fetched
                saveMinimalEntry() // Save the basic journal entry data now
                
                // Store metadata for later use when creating story arcs
                capturedMetadata = metadataResponse
                
                let userId = "user-placeholder"
                // Use the selected genre (toLowerCase to match server expectations)
                let genre = selectedGenre.lowercased()
                
                // Get recent story arcs for narrative continuity
                var previousArcs: [String] = []
                let persistenceManager = StoryPersistenceManager.shared
                // Use the most recent arcs to maintain narrative continuity
                previousArcs = persistenceManager.getRecentStoryArcs(count: 3)
                
                // Include student name from UserProfile
                let chapterRequest = ChapterGenerationRequest(
                    metadata: metadataResponse, 
                    userId: userId, 
                    genre: genre, 
                    studentName: userProfile.name,
                    previousArcs: previousArcs)
                return narrativeAPIService.generateChapter(requestData: chapterRequest)
            }
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            isGeneratingChapter = false // Stop loading indicator
            switch completion {
            case .finished:
                // Success state is handled mainly by receiveValue setting the chapter
                // If chapter isn't set here, something unexpected happened.
                if generatedChapter == nil {
                    chapterGenerationError = "Chapter generation finished, but no data was received."
                }
                // Don't set showChapterSheet here; let receiveValue handle it.
                case .failure(let error):
                    chapterGenerationError = error.localizedDescription
                    // Don't dismiss automatically on error; show the error overlay.
                }
            }, receiveValue: { chapterResponse in
                generatedChapter = chapterResponse
                
                // Create and save a new story arc for this chapter
                if let metadata = capturedMetadata {
                    let persistenceManager = StoryPersistenceManager.shared
                    // Get themes from the captured metadata
                    let themes = metadata.themes
                    let arc = StoryArc.createFrom(chapter: chapterResponse, themes: themes)
                    
                    // Save it for future narrative continuity
                    persistenceManager.saveStoryArc(arc) { result in
                        if case .failure(let error) = result {
                            print("Error saving story arc: \(error)")
                        }
                    }
                }
                
                showChapterSheet = true // Trigger sheet presentation *only* on successful receiveValue
            })
            .store(in: &cancellables)
    }

    // Helper to save the basic journal entry without waiting for chapter generation
    private func saveMinimalEntry() {
         let responses = prompts.enumerated().map { idx, prompt in
             PromptResponse(id: UUID(), prompt: prompt, response: reflectionResponses.indices.contains(idx) ? reflectionResponses[idx] : "")
         }
         let newEntry = JournalEntry(
             id: UUID(),
             assignmentName: assignmentName,
             date: Date(),
             subject: selectedSubject,
             emotionalState: EmotionalState.neutral, // Placeholder
             reflectionPrompts: responses,
             aiSummary: aiInsights, // Use existing AI insights
             aiTone: aiTone,        // Use existing AI tone
             transcription: nil,
             audioURL: nil
         )
         journalStore.saveEntry(newEntry)
         print("Minimal Journal Entry Saved: \(newEntry.id)")
     }

    private func onNext() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        } else {
            // Call the combined save and generate function
            saveEntryAndGenerateChapter()
            // Dismissal is now handled after sheet/error
        }
    }

    private func canProceed(page: Int) -> Bool {
        switch page {
        case 0: return !assignmentName.isEmpty && !courseName.isEmpty
        case 1: return !emotionalReason.isEmpty
        case 2: return indexValid(page: page) && !reflectionResponses[page].isEmpty
        case 3: return !selectedStrategies.isEmpty || !otherStrategies.isEmpty
        default: return true
        }
    }

    private func indexValid(page: Int) -> Bool {
        let idx = page
        return idx >= 0 && idx < reflectionResponses.count
    }

    private func generateAIOutputs() async {
        isLoadingAI = true
        aiError = nil
        do {
            aiTone = try await analyzer.analyzeTone(for: emotionalReason)
            let responses = prompts.enumerated().map { idx, prompt in
                PromptResponse(id: UUID(), prompt: prompt, response: reflectionResponses[idx])
            }
            aiInsights = try await analyzer.generateInsights(from: responses)
        } catch {
            aiError = error.localizedDescription
        }
        isLoadingAI = false
    }
}
