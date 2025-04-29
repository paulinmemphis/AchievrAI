//
//  AIJournalEntryView.swift
//  MetacognitiveJournal
//

import SwiftUI
import Combine

/// A view for creating journal entries with AI-powered insights and story generation
struct AIJournalEntryView: View, JournalEntrySavable {
    // MARK: - Environment Objects
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var psychologicalEnhancementsCoordinator: PsychologicalEnhancementsCoordinator
    
    // MARK: - State
    @StateObject private var viewModel: AIJournalEntryViewModel
    
    // MARK: - Initialization
    init(initialText: String? = nil) {
        _viewModel = StateObject(wrappedValue: AIJournalEntryViewModel(initialText: initialText))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("Journal Entry")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        
                        Spacer()
                        
                        Button(action: {
                            // Save entry
                            Task {
                                await generateAIInsights()
                            }
                        }) {
                            Text("Generate Insights")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(themeManager.selectedTheme.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Assignment name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assignment Title")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        
                        TextField("Enter assignment name", text: $viewModel.assignmentName)
                            .padding()
                            .background(themeManager.selectedTheme.cardBackgroundColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Subject and emotional state selectors
                    HStack(spacing: 12) {
                        // Subject selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            
                            Button(action: {
                                viewModel.showingSubjectPicker = true
                            }) {
                                HStack {
                                    Image(systemName: subjectIcon(for: viewModel.selectedSubject))
                                    Text(viewModel.selectedSubject.rawValue)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .padding()
                                .background(themeManager.selectedTheme.cardBackgroundColor)
                                .cornerRadius(8)
                            }
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        }
                        
                        // Emotional state selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How do you feel?")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            
                            Button(action: {
                                viewModel.showingEmotionalPicker = true
                            }) {
                                HStack {
                                    Text(viewModel.emotionalState.emoji)
                                    Text(viewModel.emotionalState.rawValue)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .padding()
                                .background(themeManager.selectedTheme.cardBackgroundColor)
                                .cornerRadius(8)
                            }
                            .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reflection prompts
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Reflection Prompts")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.showingAddPromptSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                            }
                        }
                        
                        if viewModel.reflectionPrompts.isEmpty {
                            Text("No prompts added yet. Tap + to add a prompt.")
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                                .italic()
                                .padding()
                        } else {
                            ForEach(viewModel.reflectionPrompts) { prompt in
                                PromptResponseView(prompt: prompt, onDelete: {
                                    viewModel.promptToDelete = prompt
                                    viewModel.showingDeleteAlert = true
                                }, onResponseChanged: { newResponse in
                                    // Find the prompt in the array and update its response
                                    if let index = viewModel.reflectionPrompts.firstIndex(where: { $0.id == prompt.id }) {
                                        viewModel.reflectionPrompts[index].response = newResponse
                                        
                                        // Debounce the insight generation to avoid too many API calls
                                        // Only update insights if the response is at least 10 characters long
                                        if newResponse.count > 10 {
                                            Task {
                                                // Wait a bit to avoid generating insights on every keystroke
                                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                                await viewModel.generateAIInsights(analyzer: viewModel.analyzer)
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // AI Insights section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Insights")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                            
                            if viewModel.isLoadingAI {
                                ProgressView()
                                    .padding(.leading, 8)
                            } else {
                                Text("Tone: \(viewModel.aiTone)")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                                    .padding(.leading, 8)
                                
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        await viewModel.generateAIInsights(analyzer: viewModel.analyzer)
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(themeManager.selectedTheme.accentColor)
                                }
                            }
                        }
                        
                        Text(viewModel.aiInsights)
                            .padding()
                            .background(themeManager.selectedTheme.cardBackgroundColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Story generation section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generate Story Chapter")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        
                        Button(action: {
                            saveEntryAndGenerateChapter()
                        }) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Create Story Chapter")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.selectedTheme.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            
            // Loading overlay for chapter generation
            if viewModel.isGeneratingChapter {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Generating your story chapter...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ProgressView(value: viewModel.generationProgress, total: 1.0)
                            .frame(width: 200)
                            .tint(.white)
                        
                        if let error = viewModel.chapterGenerationError {
                            Text("Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSubjectPicker) {
            SubjectPickerView(selectedSubject: $viewModel.selectedSubject)
        }
        .sheet(isPresented: $viewModel.showingEmotionalPicker) {
            EmotionalStatePickerView(selectedState: $viewModel.emotionalState)
        }
        .sheet(isPresented: $viewModel.showingGenrePicker) {
            GenrePickerView(genres: viewModel.genreOptions) { genre in
                beginChapterGeneration(genre: genre)
            }
        }
        .sheet(isPresented: $viewModel.showingStoryMap) {
            EnhancedStoryMapView()
        }
        .sheet(isPresented: $viewModel.showingAddPromptSheet) {
            AddPromptView(onAdd: { prompt in
                let newPrompt = PromptResponse(id: UUID(), prompt: prompt, response: nil)
                viewModel.reflectionPrompts.append(newPrompt)
            })
        }
        .alert("Delete Prompt", isPresented: $viewModel.showingDeleteAlert, presenting: viewModel.promptToDelete) { prompt in
            Button("Delete", role: .destructive) {
                if let index = viewModel.reflectionPrompts.firstIndex(where: { $0.id == prompt.id }) {
                    viewModel.reflectionPrompts.remove(at: index)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { prompt in
            Text("Are you sure you want to delete this prompt?")
        }
        .alert("Entry Saved", isPresented: $viewModel.showingSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your journal entry has been saved successfully.")
        }
        .onAppear {
            // Set the analyzer in the view model
            viewModel.analyzer = analyzer
            
            // Initialize with default prompts if empty
            if viewModel.reflectionPrompts.isEmpty {
                viewModel.reflectionPrompts = [
                    PromptResponse(id: UUID(), prompt: "What did you learn today?", response: nil),
                    PromptResponse(id: UUID(), prompt: "What was challenging?", response: nil),
                    PromptResponse(id: UUID(), prompt: "How will you apply this knowledge?", response: nil)
                ]
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate SF Symbol for a given subject
    func subjectIcon(for subject: K12Subject) -> String {
        switch subject {
        case .math:
            return "function"
        case .science:
            return "atom"
        case .english:
            return "book"
        case .history:
            return "clock"
        case .art:
            return "paintpalette"
        case .music:
            return "music.note"
        case .computerScience:
            return "desktopcomputer"
        case .physicalEducation:
            return "figure.walk"
        case .foreignLanguage:
            return "globe"
        case .socialStudies:
            return "person.2"
        case .biology:
            return "leaf"
        case .chemistry:
            return "flask"
        case .physics:
            return "bolt"
        case .geography:
            return "map"
        case .economics:
            return "chart.bar"
        case .writing:
            return "pencil"
        case .reading:
            return "text.book.closed"
        case .other:
            return "questionmark.circle"
        }
    }
    
    // MARK: - Actions
    
    /// Saves the journal entry and initiates chapter generation
    func saveEntryAndGenerateChapter() {
        // Show genre selection before proceeding to generation
        viewModel.showingGenrePicker = true
    }
    
    /// Begins the chapter generation process with the selected genre
    func beginChapterGeneration(genre: String) {
        // Create a journal entry from the current state
        let entry = createJournalEntry(
            content: viewModel.reflectionPrompts.compactMap { $0.response }.joined(separator: "\n\n"),
            title: viewModel.assignmentName,
            subject: viewModel.selectedSubject,
            emotionalState: viewModel.emotionalState,
            summary: "Journal entry about \(viewModel.assignmentName)",
            metadata: nil
        )
        
        // Save the entry to the journal store
        journalStore.saveEntry(entry)
        
        // Start the chapter generation in the view model
        viewModel.beginChapterGeneration(genre: genre, journalStore: journalStore)
    }
    
    /// Generates AI insights for the journal entry
    func generateAIInsights() async {
        await viewModel.generateAIInsights(analyzer: analyzer)
    }
}

// MARK: - JournalEntrySavable Protocol Implementation
extension AIJournalEntryView {
    func createJournalEntry(
        content: String,
        title: String,
        subject: K12Subject,
        emotionalState: EmotionalState,
        summary: String,
        metadata: EntryMetadata?
    ) -> JournalEntry {
        // Create a prompt response with the content
        let promptResponse = PromptResponse(
            id: UUID(),
            prompt: "Story Content",
            response: content
        )
        
        // Create and return the journal entry
        return JournalEntry(
            id: UUID(),
            assignmentName: title,
            date: Date(),
            subject: subject,
            emotionalState: emotionalState,
            reflectionPrompts: [promptResponse],
            aiSummary: summary,
            metadata: metadata ?? EntryMetadata(
                sentiment: "Neutral",
                themes: [],
                entities: [],
                keyPhrases: []
            )
        )
    }
    
    func showSaveConfirmation(for entryTitle: String) {
        // Implementation for showing save confirmation
        viewModel.showingSaveConfirmation = true
    }
}
