// File: VoiceJournalViewModel.swift
import Foundation
import AVFoundation
import Combine

/// Manages the state and logic for the voice journaling feature.
///
/// This class handles audio recording, playback, speech recognition (transcription),
/// and updates the UI through its published properties.
class VoiceJournalViewModel: ObservableObject {
    // MARK: - Prompts
    
    /// The list of prompts for the journaling session.
    @Published var prompts: [String]
    
    /// The index of the current prompt.
    @Published var currentPromptIndex: Int = 0

    // MARK: - Recording & Transcription
    
    /// The list of user responses to the prompts.
    @Published var responses: [String]
    
    /// The transcribed text from the speech recognition process.
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    @Published var audioFileURL: URL?

    private let synthesizer = AVSpeechSynthesizer()
    private var cancellables = Set<AnyCancellable>()
    private let audioManager = VoiceJournalAudioManager()

    /// Initializes the ViewModel with a list of prompts.
    ///
    /// - Parameter prompts: The list of prompts for the journaling session.
    init(prompts: [String]) {
        self.prompts = prompts
        self.responses = Array(repeating: "", count: prompts.count)
        // Observe audio manager's published properties
        audioManager.$isRecording.assign(to: &$isRecording)
        audioManager.$transcribedText.assign(to: &$transcribedText)
        audioManager.$errorMessage.assign(to: &$errorMessage)
        audioManager.$audioFileURL.assign(to: &$audioFileURL)
        // Auto-play the first prompt on launch
        speakPrompt()
    }

    /// The current prompt text.
    var currentPrompt: String {
        prompts.indices.contains(currentPromptIndex)
            ? prompts[currentPromptIndex]
            : ""
    }

    /// Speak the current prompt with a natural Siri voice.
    func speakPrompt() {
        guard currentPromptIndex < prompts.count else { return }
        let utterance = AVSpeechUtterance(string: prompts[currentPromptIndex])
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
    }
    
    func startRecording() {
        // Reset the audio manager to ensure a clean state
        audioManager.reset()
        
        // Start recording with the audio manager
        audioManager.startRecording()
        isRecording = true
        
        // Schedule auto-save timer when recording starts
        startAutoSaveTimer()
    }
    
    func stopRecording() {
        // Explicitly tell the audio manager to finish recording
        audioManager.finishRecording()
        isRecording = false
        
        // Add the transcribed text to the responses
        if currentPromptIndex < prompts.count {
            responses[currentPromptIndex] = transcribedText
        }
        
        // Save progress when recording stops
        autoSaveCurrentProgress()
    }
    
    @Published var isComplete: Bool = false
    
    func nextPrompt() {
        guard currentPromptIndex < prompts.count - 1 else {
            // We've reached the end of the prompts
            isComplete = true
            return
        }
        
        // Save the current response
        responses[currentPromptIndex] = transcribedText
        
        // Move to the next prompt
        currentPromptIndex += 1
        transcribedText = ""
        
        // Auto-save when moving to next prompt
        autoSaveCurrentProgress()
    }
    
    // MARK: - Auto-save functionality
    
    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 30 // Auto-save every 30 seconds
    
    private func startAutoSaveTimer() {
        // Cancel any existing timer
        autoSaveTimer?.invalidate()
        
        // Create a new timer
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.autoSaveCurrentProgress()
        }
    }
    
    private func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func autoSaveCurrentProgress() {
        // Update the current response with latest transcribed text
        if currentPromptIndex < prompts.count {
            responses[currentPromptIndex] = transcribedText
        }
        
        // Save to UserDefaults for recovery
        let progressData = [
            "responses": responses,
            "currentPromptIndex": currentPromptIndex,
            "transcribedText": transcribedText,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        UserDefaults.standard.set(progressData, forKey: "voiceJournalAutoSave")
        print("Auto-saved voice journal progress at \(Date().formatted())")
    }
    
    private func loadAutoSavedProgress() {
        guard let progressData = UserDefaults.standard.dictionary(forKey: "voiceJournalAutoSave") else {
            return
        }
        
        // Check if auto-save is recent (within the last 24 hours)
        if let timestamp = progressData["timestamp"] as? TimeInterval {
            let savedDate = Date(timeIntervalSince1970: timestamp)
            let now = Date()
            let hoursSinceSave = now.timeIntervalSince(savedDate) / 3600
            
            // Only restore if saved within the last 24 hours
            if hoursSinceSave <= 24 {
                if let savedResponses = progressData["responses"] as? [String] {
                    responses = savedResponses
                }
                
                if let savedPromptIndex = progressData["currentPromptIndex"] as? Int {
                    currentPromptIndex = savedPromptIndex
                }
                
                if let savedTranscribedText = progressData["transcribedText"] as? String {
                    transcribedText = savedTranscribedText
                }
                
                print("Restored auto-saved voice journal from \(savedDate.formatted())")
            }
        }
    }
    
    func saveCurrentEntry() {
        // Ensure we have at least one response
        guard !responses.isEmpty else {
            errorMessage = "No responses to save"
            return
        }
        
        // Create prompt-response pairs
        var promptResponses: [PromptResponse] = []
        for i in 0..<prompts.count {
            if i < responses.count {
                let promptResponse = PromptResponse(
                    id: UUID(),
                    prompt: prompts[i],
                    response: responses[i]
                )
                promptResponses.append(promptResponse)
            }
        }
        
        // Create a new journal entry
        let entry = JournalEntry(
            id: UUID(),
            assignmentName: "Voice Journal - \(Date().formatted(date: .abbreviated, time: .shortened))",
            date: Date(),
            subject: .english,
            emotionalState: EmotionalState.neutral,
            reflectionPrompts: promptResponses
        )
        
        // We need a reference to the journal store to save the entry
        // This will be handled by the saveCurrentEntry(in:) method
        
        // Clear auto-save data
        UserDefaults.standard.removeObject(forKey: "voiceJournalAutoSave")
        
        // Reset the view model
        reset()
    }
    
    private func reset() {
        // Stop any timers
        stopAutoSaveTimer()
        
        // Reset state
        currentPromptIndex = 0
        responses = Array(repeating: "", count: prompts.count)
        transcribedText = ""
        isComplete = false
        errorMessage = nil
    }

    /// Finish recording and store the transcription.
    func finishRecording() {
        audioManager.finishRecording()
        if currentPromptIndex < responses.count {
            responses[currentPromptIndex] = transcribedText
        }
    }

    /// Advance to the next prompt and speak it.
    func advanceToNextPrompt() {
        finishRecording()
        if currentPromptIndex + 1 < prompts.count {
            currentPromptIndex += 1
            transcribedText = ""
            speakPrompt()
        }
    }

    /// Save the entire session as one journal entry.
    ///
    /// - Parameter store: The journal store to save the entry to.
    func saveCurrentEntry(in store: JournalStore) {
        // Use the JournalEntrySavable implementation to create the entry
        var entry = createJournalEntryWithMetadata()
        
        // Add voice-specific properties
        entry.transcription = responses.joined(separator: "\n")
        entry.audioURL = audioFileURL
        
        // Save the entry with audio data
        store.saveEntry(entry, audioURL: audioFileURL, transcription: entry.transcription ?? "")
        
        // Show confirmation
        showSaveConfirmation(for: entry.assignmentName)
    }
}
