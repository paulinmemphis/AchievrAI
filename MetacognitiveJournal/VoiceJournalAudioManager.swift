import Foundation
import AVFoundation
import Speech
import Combine

/// Handles audio recording and speech recognition for voice journaling.
class VoiceJournalAudioManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording: Bool = false
    @Published var transcribedText: String = ""
    @Published var errorMessage: String?
    @Published var audioFileURL: URL?

    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // Explicit locale, optional
    private let audioSession = AVAudioSession.sharedInstance()
    private var hasAttemptedFallback = false

    // MARK: - Recording & Recognition
    func startRecording() {
        errorMessage = nil

        // Ensure the recognizer is available for the locale
        guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available for the selected locale or device."
            isRecording = false // Stop if recognizer isn't working
            return
        }

        isRecording = true
        transcribedText = ""
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Error: Unable to create SFSpeechAudioBufferRecognitionRequest")
            finishRecording() // Clean up if request fails
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = !hasAttemptedFallback

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in // Use guarded request
            guard let self = self else { return }
            
            // Handle errors
            if let error = error as NSError? {
                // Try fallback to on-device recognition if server recognition fails
                if !self.hasAttemptedFallback, error.domain == "kAFAssistantErrorDomain", error.code == 1101 {
                    self.hasAttemptedFallback = true
                    self.finishRecording()
                    self.startRecording()
                    return
                }
                
                // Handle other errors
                DispatchQueue.main.async {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.finishRecording()
                }
                return
            }
            
            // Update transcription text as it comes in
            if let transcription = result?.bestTranscription.formattedString {
                DispatchQueue.main.async {
                    self.transcribedText = transcription
                }
            }
            
            // Only finish recording when explicitly told to do so by the user
            // Do NOT automatically finish when result.isFinal is true
            // This allows continuous transcription
        }

        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        let fileName = "voicejournal_\(Date().timeIntervalSince1970).caf"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docs.appendingPathComponent(fileName)
        audioFileURL = fileURL
        do {
            audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        } catch {
            errorMessage = "Audio file error: \(error.localizedDescription)"
        }

        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("Audio write failed: \(error)")
            }
        }

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine error: \(error.localizedDescription)"
        }
    }

    func finishRecording() {
        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }

    func reset() {
        isRecording = false
        transcribedText = ""
        errorMessage = nil
        audioFileURL = nil
        audioFile = nil
        recognitionTask = nil
        recognitionRequest = nil
        hasAttemptedFallback = false
    }
}
