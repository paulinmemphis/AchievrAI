import Foundation
import AVFoundation
import Speech
import Combine

/// Handles audio recording and speech recognition for voice journaling.
class AudioRecorder: ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var audioURL: URL?
    @Published var transcription = ""
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Public Methods
    
    /// Request microphone and speech recognition permissions
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { status in
            let speechAuthorized = (status == .authorized)
            
            // Request microphone authorization
            AVAudioSession.sharedInstance().requestRecordPermission { micAuthorized in
                // Both permissions must be granted
                DispatchQueue.main.async {
                    completion(speechAuthorized && micAuthorized)
                }
            }
        }
    }
    
    /// Start recording audio and transcribing
    func startRecording() throws {
        // Reset previous recording session
        if isRecording {
            stopRecording()
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create URL for recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voicejournal_\(Date().timeIntervalSince1970).m4a")
        self.audioURL = audioFilename
        
        // Setup audio recording
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Start speech recognition
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create speech recognition request or recognizer not available"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcription = result.bestTranscription.formattedString
                }
            }
            
            // Only stop if there's an actual error, not just when results are final
            if let error = error {
                print("Speech recognition error: \(error)")
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recording
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.record()
        
        isRecording = true
    }
    
    /// Stop recording audio
    func stopRecording() {
        audioRecorder?.stop()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
    }
    
    /// Transcribe an existing audio file
    func transcribe(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = audioURL else {
            completion(.failure(NSError(domain: "AudioRecorder", code: 2, userInfo: [NSLocalizedDescriptionKey: "No audio file available"])))
            return
        }
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(NSError(domain: "AudioRecorder", code: 3, userInfo: [NSLocalizedDescriptionKey: "No transcription result"])))
                return
            }
            
            completion(.success(result.bestTranscription.formattedString))
        }
    }
}
