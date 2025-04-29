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
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: currentPrompt)
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_en-US_compact") {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }

    /// Start recording and recognition, auto-saving after a 3s pause.
    func startRecording() {
        errorMessage = nil
        audioManager.startRecording()
    }

    // Auto-save logic can be handled by the view model or delegated to the manager if needed.
    // For now, auto-save is not implemented here; implement as needed based on new architecture.

    /// Stop recording and store the transcription.
    func finishRecording() {
        audioManager.finishRecording()
        if currentPromptIndex < responses.count {
            responses[currentPromptIndex] = transcribedText
        }
    }

    /// Advance to the next prompt and speak it.
    func nextPrompt() {
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
        var entry = JournalEntry(
            id: UUID(),
            assignmentName: "Voice Journal",
            date: Date(),
            subject: .math,
            emotionalState: .neutral,
            reflectionPrompts: zip(prompts, responses).map { prompt, response in
                PromptResponse(
                    id: UUID(),
                    prompt: prompt,
                    options: nil,
                    selectedOption: nil,
                    response: response,
                    isFavorited: false,
                    rating: 0
                )
            },
            aiTone: "Voice"
        )
        entry.transcription = responses.joined(separator: "\n")
        entry.audioURL = audioFileURL
        store.saveEntry(
            entry,
            audioURL: audioFileURL,
            transcription: entry.transcription ?? ""
        )
    }
}
