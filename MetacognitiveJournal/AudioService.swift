import Foundation
import AVFoundation
import Speech
import SwiftUI // Added for ObservableObject

// MARK: - Audio Service Class
// Provides audio recording and transcription services for the app
class AudioService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioURL: URL?
    private let speechRecognizer = SFSpeechRecognizer()
    
    // Published property to potentially observe recording state if needed externally
    @Published var isRecording = false

    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        let tempDir = FileManager.default.temporaryDirectory
        // Ensure unique filename to avoid conflicts if multiple instances exist (though unlikely with @StateObject)
        audioURL = tempDir.appendingPathComponent("dictationRecording-\(UUID().uuidString).m4a") 

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let url = audioURL else {
             throw NSError(domain: "AudioRecorderError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio URL."])
        }

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true // Keep enabled if needed for UI feedback

            if audioRecorder?.record() ?? false {
                DispatchQueue.main.async {
                     self.isRecording = true
                 }
            } else {
                 throw NSError(domain: "AudioRecorderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "AVAudioRecorder failed to start recording."])
            }
        } catch {
            print("Failed to configure or start recording session: \(error)")
            // Clean up resources if setup failed
            cleanupAudioFile(clearRecorder: true)
            throw error // Re-throw the error
        }
    }

    func stopRecording() {
        guard audioRecorder?.isRecording ?? false else { return } // Check if actually recording
        audioRecorder?.stop()
        // Delegate method audioRecorderDidFinishRecording handles cleanup and state change
    }

    func transcribe(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = audioURL, FileManager.default.fileExists(atPath: url.path) else {
            completion(.failure(NSError(domain: "AudioRecorderError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio file URL is missing or file does not exist."])))
            audioURL = nil // Clear potentially invalid URL
            return
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            completion(.failure(NSError(domain: "AudioRecorderError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available."])))
            cleanupAudioFile(clearRecorder: false) // Cleanup audio file if recognizer isn't available
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)

        recognizer.recognitionTask(with: request) { (result, error) in
            // Don't clean up the audio file until we have the final result
            // This ensures the recognition continues until completion
            
            if let error = error {
                self.cleanupAudioFile(clearRecorder: false) // Clean up on error
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                self.cleanupAudioFile(clearRecorder: false) // Clean up on nil result
                completion(.failure(NSError(domain: "AudioRecorderError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Recognition result was nil."])))
                return
            }

            // Only report the final result and clean up when done
            if result.isFinal {
                self.cleanupAudioFile(clearRecorder: false) // Clean up after getting final result
                completion(.success(result.bestTranscription.formattedString))
            }
            // Don't call completion for partial results - let recognition continue
        }
    }
    
    // Combined cleanup function
    private func cleanupAudioFile(clearRecorder: Bool) {
         // Stop recorder if requested and it's running
         if clearRecorder {
             audioRecorder?.stop()
             audioRecorder = nil
         }
         
         // Remove audio file
         if let url = audioURL {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    print("Cleaned up audio file: \(url.lastPathComponent)")
                }
            } catch {
                print("Error cleaning up audio file: \(error)")
            }
             audioURL = nil // Ensure URL is cleared after cleanup attempt
        }
         
        // Update recording state on main thread
        if isRecording { // Only update if state was true
             DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
    
    // MARK: - AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("AVAudioRecorder finished recording. Success: \(flag)")
        // Cleanup audio file but don't clear the recorder instance itself
        cleanupAudioFile(clearRecorder: false) 
        if !flag {
            // Handle unsuccessful recording finish if needed (e.g., show error)
            // Note: transcribe might fail later anyway if file is bad.
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("AVAudioRecorder encode error: \(error?.localizedDescription ?? "Unknown error")")
        // Critical error, stop and cleanup everything
        cleanupAudioFile(clearRecorder: true)
        // Potentially propagate this error back to the UI
    }
    
    // Deinit for safety, ensure resources are released if object is destroyed unexpectedly
    deinit {
        print("AudioRecorder deinit")
        cleanupAudioFile(clearRecorder: true)
        // Deactivate audio session? Maybe not here, depends on app lifecycle.
        // try? AVAudioSession.sharedInstance().setActive(false)
    }
}
