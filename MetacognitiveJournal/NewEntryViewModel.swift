// NewEntryViewModel.swift
// ViewModel for NewEntryView to manage state, dictation, and logic
import SwiftUI
import AVFoundation
import Speech

class NewEntryViewModel: ObservableObject {
    // Completion handler for dismissing the view (set by the view)
    var onComplete: (() -> Void)?

    // Entry State
    @Published var entryId: UUID? = nil
    @Published var assignmentName: String = ""
    @Published var selectedSubject: K12Subject = .other
    @Published var emotionalStateText: String = ""
    @Published var responses: [String: String] = [:]
    @Published var selectedEmoticon: String = ""
    @Published var isEditingExistingEntry = false
    @Published var showingSaveError = false
    @Published var errorMessage = ""
    @Published var isSaving = false
    
    // Speech Recognition State
    @Published var isRecording = false
    @Published var permissionsGranted = false
    @Published var transcriptionErrorWrapper: TranscriptionErrorWrapper? = nil
    @Published var activeDictationField: DictationField? = nil
    
    private let audioRecorder = AudioRecorder()
    
    // Data dependencies
    var journalStore: JournalStore?
    var analyzer: MetacognitiveAnalyzer?
    var coordinator: PsychologicalEnhancementsCoordinator?
    
    // Init
    init(journalStore: JournalStore? = nil, analyzer: MetacognitiveAnalyzer? = nil, coordinator: PsychologicalEnhancementsCoordinator? = nil, initialEntryData: EntryEditingData? = nil) {
        self.journalStore = journalStore
        self.analyzer = analyzer
        self.coordinator = coordinator
        if let data = initialEntryData {
            self.emotionalStateText = data.text
            self.entryId = data.id
            self.isEditingExistingEntry = true
        }
    }
    
    // MARK: - Data Loading
    func loadEntryData() {
        guard isEditingExistingEntry, let id = entryId, let journalStore = journalStore else { return }
        if let entry = journalStore.entries.first(where: { $0.id == id }) {
            self.assignmentName = entry.assignmentName
            self.selectedSubject = entry.subject
            self.responses = entry.reflectionPrompts.reduce(into: [:]) { $0[$1.prompt] = $1.response }
            self.selectedEmoticon = mapEmotionalStateToEmoji(entry.emotionalState)
            self.emotionalStateText = entry.transcription ?? ""
        }
    }
    
    // MARK: - Dictation Logic
    func triggerPermissionRequest() {
        requestPermissions { granted in
            DispatchQueue.main.async {
                self.permissionsGranted = granted
                if !granted {
                    self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Microphone and Speech Recognition permissions are required for dictation.")
                }
            }
        }
    }
    
    func toggleDictation(for field: DictationField) {
        if isRecording {
            if activeDictationField == field {
                stopDictation()
            } else {
                stopDictation()
            }
        } else {
            startDictation(for: field)
        }
    }
    
    func startDictation(for field: DictationField) {
        guard permissionsGranted else {
            transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Permissions not granted. Please enable Microphone and Speech Recognition access in Settings.")
            triggerPermissionRequest()
            return
        }
        transcriptionErrorWrapper = nil
        activeDictationField = field
        do {
            try audioRecorder.startRecording()
            isRecording = true
        } catch {
            self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Failed to start recording: \(error.localizedDescription)")
            isRecording = false
            activeDictationField = nil
        }
    }
    
    func stopDictation() {
        guard isRecording else { return }
        audioRecorder.stopRecording()
        isRecording = false
        audioRecorder.transcribe { result in
            DispatchQueue.main.async {
                self.handleTranscriptionResult(result)
                self.activeDictationField = nil
            }
        }
    }
    
    private func handleTranscriptionResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let transcript):
            guard !transcript.isEmpty else {
                self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Transcription was empty.")
                return
            }
            switch activeDictationField {
            case .assignmentName:
                assignmentName = transcript
            case .emotionalState:
                emotionalStateText = transcript
            case .reflection(let prompt):
                responses[prompt] = transcript
            case .none:
                break
            }
        case .failure(let error):
            self.transcriptionErrorWrapper = TranscriptionErrorWrapper(message: "Transcription failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Save Logic
    var canSave: Bool {
        !assignmentName.isEmpty && !responses.values.allSatisfy({ $0.isEmpty }) && !isSaving
    }

    func saveEntry(gamificationManager: GamificationManager?) {
        guard canSave, let journalStore = journalStore else { return }
        isSaving = true
        errorMessage = ""

        let feeling = emotionalStateText
        let currentEmotionalState = mapFeelingToEmotionalState(feeling)

        // Build reflection prompts
        let reflectionPrompts = responses.map { prompt, response in
            PromptResponse(id: UUID(), prompt: prompt, response: response)
        }

        let entryToSave = JournalEntry(
            id: entryId ?? UUID(),
            assignmentName: assignmentName,
            date: Date(),
            subject: selectedSubject,
            emotionalState: currentEmotionalState,
            reflectionPrompts: reflectionPrompts,
            aiSummary: nil,
            aiTone: nil,
            transcription: emotionalStateText.isEmpty ? nil : emotionalStateText,
            audioURL: nil
        )
        journalStore.saveEntry(entryToSave)
        gamificationManager?.recordJournalEntry()
        coordinator?.recordJournalEntryCompletion(entryToSave)
        
        isSaving = false
        onComplete?()
    }

    // Helper to map feeling string to EmotionalState
    private func mapFeelingToEmotionalState(_ feeling: String) -> EmotionalState {
        switch feeling {
        case "😀", "🥳": return .confident
        case "😐": return .neutral
        case "😢": return .frustrated
        case "😡", "😱": return .overwhelmed
        default:
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

    // MARK: - Helpers
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
}
