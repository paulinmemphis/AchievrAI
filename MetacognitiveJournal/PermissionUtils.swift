import Foundation
import Speech
import AVFoundation

// MARK: - Global Permission Helper
func requestPermissions(completion: @escaping (Bool) -> Void) {
    // Request Speech Recognition permission
    SFSpeechRecognizer.requestAuthorization { authStatus in
        // Then, request Microphone permission
        // Use the newer API for iOS 17+
        AVAudioApplication.requestRecordPermission { audioStatus in // Call as static method
            // Combine results and call completion handler on the main thread
            DispatchQueue.main.async {
                let speechGranted = (authStatus == .authorized)
                let micGranted = audioStatus
                print("Permission Status - Speech: \(speechGranted), Mic: \(micGranted)")
                completion(speechGranted && micGranted)
            }
        }
    }
}
