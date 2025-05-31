//
//  NewEntryView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/14/25.
//
// File: NewEntryView.swift
import SwiftUI
import AVFoundation
import Speech

// Define which field is being dictated
enum DictationField: Hashable {
    case assignmentName
    case emotionalState
    case reflection(prompt: String) // Use prompt to identify reflection field
}

/// A view for creating or editing a journal entry.
struct NewEntryView: View {
    @EnvironmentObject private var journalStore: JournalStore
    @EnvironmentObject private var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject private var parentalControlManager: ParentalControlManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var gamificationManager: GamificationManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NewEntryViewModel
    
    // Coordinator is now passed in
    let coordinator: PsychologicalEnhancementsCoordinator
    let initialEntryData: EntryEditingData?

    init(coordinator: PsychologicalEnhancementsCoordinator, initialEntryData: EntryEditingData? = nil) {
        self.coordinator = coordinator // Assign passed-in coordinator
        self.initialEntryData = initialEntryData
        // Correct argument order for ViewModel init
        _viewModel = StateObject(wrappedValue: NewEntryViewModel(coordinator: coordinator, initialEntryData: initialEntryData))
    }

    // MARK: - Entry State
    @State private var entryId: UUID? // Store the ID if editing
    @State private var assignmentName: String = ""
    @State private var selectedSubject: K12Subject = .other // Default subject
    @State private var emotionalStateText: String = "" // Main text field
    @State private var responses: [String: String] = [:] // Reflection answers
    @State private var selectedEmoticon: String = ""
    @State private var isEditingExistingEntry = false
    @State private var showingSaveError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    // --- Speech Recognition State ---
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false // We might rely on audioRecorder.isRecording now
    @State private var permissionsGranted = false
    @State private var transcriptionErrorWrapper: TranscriptionErrorWrapper? = nil // Use wrapper
    @State private var activeDictationField: DictationField? = nil // Track active field
    
    // Voice input helper (Placeholder - can be removed if voice input is handled elsewhere)
    @State private var voiceTranscription: String = "" // Keep this maybe?

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                EntryDetailsSectionView(
                    assignmentName: $viewModel.assignmentName,
                    selectedSubject: $viewModel.selectedSubject,
                    isRecording: viewModel.isRecording,
                    activeDictationField: viewModel.activeDictationField,
                    toggleDictation: viewModel.toggleDictation,
                    themeManager: themeManager
                )
                HowDidYouFeelSectionView(
                    selectedEmoticon: $viewModel.selectedEmoticon,
                    emotionalStateText: $viewModel.emotionalStateText,
                    isRecording: viewModel.isRecording,
                    activeDictationField: viewModel.activeDictationField,
                    toggleDictation: viewModel.toggleDictation
                )
                ReflectionSectionView(
                    prompts: analyzer.prompts,
                    responses: $viewModel.responses,
                    isRecording: viewModel.isRecording,
                    activeDictationField: viewModel.activeDictationField,
                    toggleDictation: viewModel.toggleDictation
                )
            }
            .padding()
        }
        .background(themeManager.selectedTheme.backgroundColor)
        .navigationTitle("New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Cancel", systemImage: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.saveEntry(gamificationManager: gamificationManager) }) {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Label("Save", systemImage: "checkmark")
                    }
                }
                .disabled(!viewModel.canSave)
            }
        }
        .alert(isPresented: $viewModel.showingSaveError) {
            Alert(
                title: Text("Save Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(item: $viewModel.transcriptionErrorWrapper) { errorWrapper in
            Alert(
                title: Text("Transcription Error"),
                message: Text(errorWrapper.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.journalStore = journalStore
            viewModel.analyzer = analyzer
            viewModel.onComplete = { dismiss() }
            viewModel.loadEntryData()
            viewModel.triggerPermissionRequest()
        }
    }

    // MARK: - Load Data
    private func loadEntryData() {
        guard isEditingExistingEntry, let id = entryId else { return }
        
        Task {
            // Find the entry directly in the store's published array
            // Accessing @Published property, ensure main actor safety if needed, 
            // but firstIndex(where:) on array should be safe. 
            // We'll update UI state on the main actor afterwards.
            if let entry = journalStore.entries.first(where: { $0.id == id }) {
                // Update view state on the main thread
                await MainActor.run {
                    self.assignmentName = entry.assignmentName
                    self.selectedSubject = entry.subject
                    self.responses = entry.reflectionPrompts.reduce(into: [:]) { $0[$1.prompt] = $1.response }
                    // emotionalStateText is already set from initialEntryData in init
                    // Map entry.emotionalState back to selectedEmoticon if needed
                    self.selectedEmoticon = mapEmotionalStateToEmoji(entry.emotionalState)
                    self.emotionalStateText = entry.transcription ?? ""
                }
            } else {
                // Handle case where entry couldn't be fetched (optional)
                print("Error: Could not fetch entry with ID \(id) to edit.")
                // Perhaps disable saving or show an error
            }
        }
    }
    
    // MARK: - View Components
    private var entryDetailsSection: some View {
        EntryDetailsSectionView(
            assignmentName: $assignmentName,
            selectedSubject: $selectedSubject,
            isRecording: isRecording,
            activeDictationField: activeDictationField,
            toggleDictation: { field in toggleDictation(for: field) },
            themeManager: themeManager
        )
    }

    private var howDidYouFeelSection: some View {
        HowDidYouFeelSectionView(
            selectedEmoticon: $selectedEmoticon,
            emotionalStateText: $emotionalStateText,
            isRecording: isRecording,
            activeDictationField: activeDictationField,
            toggleDictation: { field in toggleDictation(for: field) }
        )
    }

    private var reflectionSection: some View {
        ReflectionSectionView(
            prompts: analyzer.prompts,
            responses: $responses,
            isRecording: isRecording,
            activeDictationField: activeDictationField,
            toggleDictation: { field in toggleDictation(for: field) }
        )
    }

    // MARK: - Speech Recognition Logic
    private func triggerPermissionRequest() {
        requestPermissions { granted in
            self.permissionsGranted = granted
            if !granted {
                // Update wrapper
                self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Microphone and Speech Recognition permissions are required for dictation.")
            }
            print("Permissions requested. Granted: \(granted)")
        }
    }
    
    private func toggleDictation(for field: DictationField) {
        if isRecording {
            if activeDictationField == field {
                // Stop recording for the current field
                stopDictation()
            } else {
                // Trying to start for a new field while already recording for another
                // Optional: Show an error or just stop the current one first?
                // For simplicity, let's just stop the current one.
                stopDictation() 
                 // Consider starting the new one immediately or require another tap
            }
        } else {
            // Start recording for the selected field
            startDictation(for: field)
        }
    }
    
    private func startDictation(for field: DictationField) {
        guard permissionsGranted else {
            // Update wrapper
            transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Permissions not granted. Please enable Microphone and Speech Recognition access in Settings.")
            triggerPermissionRequest() // Try requesting again
            return
        }
        
        transcriptionErrorWrapper = nil // Clear wrapper
        activeDictationField = field
        do {
            try audioRecorder.startRecording()
            isRecording = true
            print("Dictation started for field: \(field)")
        } catch {
             // Update wrapper
             self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Failed to start recording: \(error.localizedDescription)")
             isRecording = false
             activeDictationField = nil
        }
    }
    
    private func stopDictation() {
        guard isRecording else { return }
        
        audioRecorder.stopRecording()
        isRecording = false
        print("Recording stopped for field: \(String(describing: activeDictationField)), starting transcription...")
        
        // Indicate transcription is processing (optional)
        
        audioRecorder.transcribe { result in
            DispatchQueue.main.async {
                handleTranscriptionResult(result)
                activeDictationField = nil // Reset active field after transcription attempt
            }
        }
    }
    
    private func handleTranscriptionResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let transcript):
            guard !transcript.isEmpty else {
                // Update wrapper
                self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Transcription was empty.")
                return
            }
            
            // Update the correct state variable based on the active field
            switch activeDictationField {
            case .assignmentName:
                assignmentName = transcript
            case .emotionalState:
                emotionalStateText = transcript
            case .reflection(let prompt):
                responses[prompt] = transcript
            case .none:
                print("Warning: Transcription finished but no active field was set.")
            }
            
        case .failure(let error):
            // Update wrapper
            self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Transcription failed: \(error.localizedDescription)")
            print("Detailed transcription error: \(error)")
        }
    }
    
    // MARK: - Other Functions
    private func mapEmotionalStateToEmoji(_ state: EmotionalState) -> String {
        switch state {
        case .confident: return "😎"
        case .confused: return "🤔"
        case .frustrated: return "😤"
        case .satisfied: return "😌"
        case .neutral: return "😐"
        case .curious: return "🧐"
        case .overwhelmed: return "😩"
        }
    }

    private func mapFeelingToEmotionalState(_ feeling: String) -> EmotionalState {
        switch feeling {
        case "😀", "🥳": return .confident
        case "😐": return .neutral
        case "😢": return .frustrated
        case "😡", "😱": return .overwhelmed
        default:
            // Try to match by text
            let lower = feeling.lowercased()
            if lower.contains("confident") { return .confident }
            if lower.contains("neutral") { return .neutral }
            if lower.contains("frustrat") { return .frustrated }
            if lower.contains("overwhelm") { return .overwhelmed }
            if lower.contains("curious") { return .curious }
            if lower.contains("confus") { return .confused }
            if lower.contains("satisf") { return .satisfied }
            return .neutral
        }
    }

    private var canSave: Bool {
        !assignmentName.isEmpty && !responses.values.allSatisfy({ $0.isEmpty }) && !isSaving
    }
    
    private func saveEntry() {
        guard canSave else { return }
        isSaving = true
        errorMessage = ""
        
        let feeling = emotionalStateText // Use the text field content directly
        let currentEmotionalState = mapFeelingToEmotionalState(feeling)
        
        // Construct the entry to save
        // Use existing entryId if editing, otherwise create a new UUID
        let entryToSave = JournalEntry(
            id: entryId ?? UUID(),
            assignmentName: assignmentName,
            date: Date(), // Use the current date
            subject: selectedSubject,
            emotionalState: currentEmotionalState,
            reflectionPrompts: responses.map { PromptResponse(id: UUID(), prompt: $0.key, response: $0.value) },
            transcription: emotionalStateText.isEmpty ? nil : emotionalStateText // Use the text field value
        )
        
        // saveEntry is synchronous and non-throwing, call directly
        journalStore.saveEntry(entryToSave)
        
        // Award gamification points for saving an entry
        gamificationManager.recordJournalEntry()
        
        // Dismiss the view
        // presentationMode.wrappedValue.dismiss() // Use presentationMode if available
        dismiss() // Assuming dismiss() comes from @Environment(\.dismiss)
    }
}

// MARK: - Error Wrapper for Alert
struct TranscriptionErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        // --- Preview for a New Entry --- 
        NavigationView {
            // Create instances needed for the preview
            let journalStore = JournalStore.preview
            let analyzer = MetacognitiveAnalyzer()
            let coordinator = PsychologicalEnhancementsCoordinator.preview // Use static preview instance
            let gamificationManager = GamificationManager()
            let themeManager = ThemeManager()
            let parentalControlManager = ParentalControlManager()
            let userProfile = UserProfile()

            NewEntryView(coordinator: coordinator)
                .environmentObject(journalStore) // Use the static preview store
                .environmentObject(analyzer)
                .environmentObject(coordinator) // Inject the preview coordinator
                .environmentObject(gamificationManager)
                .environmentObject(themeManager)
                .environmentObject(parentalControlManager)
                .environmentObject(userProfile)
        }
    }
}
