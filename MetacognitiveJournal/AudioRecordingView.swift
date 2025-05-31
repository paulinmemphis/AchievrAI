import SwiftUI
import AVFoundation
import Combine

/// Extension for multi-modal audio recording components
extension MultiModal {
    // MARK: - Audio Recording View Model
    class AudioRecordingViewModel: ObservableObject {
        // MARK: - Properties
        let journalMode: ChildJournalMode
        let onSave: (URL, String?) -> Void
        let onCancel: () -> Void
        let promptText: String?
        
        // MARK: - Published State
        @Published var audioRecorder: AVAudioRecorder?
        @Published var audioPlayer: AVAudioPlayer?
        @Published var recordingURL: URL?
        @Published var isRecording = false
        @Published var isPlaying = false
        @Published var recordingTime: TimeInterval = 0
        @Published var playbackTime: TimeInterval = 0
        @Published var transcription: String = ""
        @Published var showingTranscription = false
        @Published var recordingTitle: String = ""
        @Published var recordingPermissionGranted = false
        @Published var animateMicrophone = false
        @Published var recordingLevel: CGFloat = 0
        @Published var showingPromptGuide = false
        
        // Private properties
        private var recordingTimer: Timer?
        private var playbackTimer: Timer?
        private var audioPlayerDelegate: AudioPlayerDelegate?
        
        init(journalMode: ChildJournalMode, onSave: @escaping (URL, String?) -> Void, onCancel: @escaping () -> Void, promptText: String?) {
            self.journalMode = journalMode
            self.onSave = onSave
            self.onCancel = onCancel
            self.promptText = promptText
        }
        
        func checkMicrophonePermission() {
            // Use AVAudioApplication for iOS 17+ compatibility
            if #available(iOS 17.0, *) {
                switch AVAudioApplication.shared.recordPermission {
                case .granted:
                    self.recordingPermissionGranted = true
                case .denied:
                    self.recordingPermissionGranted = false
                case .undetermined:
                    // Use AVAudioSession for permission request as AVAudioApplication doesn't have static requestRecordPermission
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            self.recordingPermissionGranted = granted
                        }
                    }
                @unknown default:
                    self.recordingPermissionGranted = false
                }
            } else {
                // Fallback for iOS 16 and earlier
                switch AVAudioSession.sharedInstance().recordPermission {
                case .granted:
                    self.recordingPermissionGranted = true
                case .denied:
                    self.recordingPermissionGranted = false
                case .undetermined:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            self.recordingPermissionGranted = granted
                        }
                    }
                @unknown default:
                    self.recordingPermissionGranted = false
                }
            }
        }
        
        func startRecording() {
            // Set up audio session
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default)
                try audioSession.setActive(true)
                
                // Set up recording settings
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                // Create a unique filename in the documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
                
                // Create and configure the audio recorder
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.prepareToRecord()
                
                // Start recording
                audioRecorder?.record()
                recordingURL = audioFilename
                isRecording = true
                animateMicrophone = true
                
                // Start the recording timer
                recordingTime = 0
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.recordingTime += 0.1
                    
                    // Update recording level for visualization
                    self.audioRecorder?.updateMeters()
                    if let power = self.audioRecorder?.averagePower(forChannel: 0) {
                        // Convert dB to a 0-1 scale (dB is negative, with 0 being loudest)
                        // Typical values range from -60 (quiet) to 0 (loud)
                        let normalizedPower = (power + 60) / 60
                        self.recordingLevel = CGFloat(max(0, min(1, normalizedPower)))
                    }
                }
            } catch {
                print("Recording failed: \(error.localizedDescription)")
            }
        }
        
        func stopRecording() {
            audioRecorder?.stop()
            audioRecorder = nil
            isRecording = false
            animateMicrophone = false
            recordingTimer?.invalidate()
            recordingTimer = nil
            
            // Default title based on duration
            if recordingTitle.isEmpty {
                recordingTitle = "Recording \(Date().formatted(date: .abbreviated, time: .shortened))" + (recordingTime < 1 ? " (Test)" : "")
            }
        }
        
        func startPlayback() {
            guard let url = recordingURL else { return }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                
                // Create and store a strong reference to the delegate
                audioPlayerDelegate = AudioPlayerDelegate(onFinish: { [weak self] in
                    guard let self = self else { return }
                    self.audioPlayer?.stop()
                    self.audioPlayer = nil
                    self.isPlaying = false
                    self.playbackTimer?.invalidate()
                    self.playbackTimer = nil
                })
                
                // Assign the delegate
                audioPlayer?.delegate = audioPlayerDelegate
                
                audioPlayer?.play()
                isPlaying = true
                
                // Start the playback timer
                playbackTime = 0
                playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    if let player = self.audioPlayer, player.isPlaying {
                        self.playbackTime = player.currentTime
                        
                        // Simulate recording level for visualization
                        // This is a simplified approach since AVAudioPlayer doesn't provide metering
                        let progress = player.currentTime / player.duration
                        let phase = sin(progress * 10) * 0.5 + 0.5 // Create a wave pattern
                        self.recordingLevel = CGFloat(phase)
                    }
                }
            } catch {
                print("Playback failed: \(error.localizedDescription)")
            }
        }
        
        func pausePlayback() {
            audioPlayer?.pause()
            isPlaying = false
            playbackTimer?.invalidate()
            playbackTimer = nil
        }
        
        func stopPlayback() {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying = false
            playbackTime = 0
            playbackTimer?.invalidate()
            playbackTimer = nil
        }
        
        func transcribeAudio() {
            // In a real app, this would use Speech Recognition API
            // For now, we'll simulate transcription with a delay
            showingTranscription = true
            
            // Simulate transcription process
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                // Generate a simulated transcription based on the prompt if available
                if let prompt = self.promptText {
                    self.transcription = self.generateSimulatedTranscription(based: prompt)
                } else {
                    self.transcription = "This is a simulated transcription of your audio recording. In a real app, this would use speech recognition to convert your voice to text. You could then use this text in your journal entry."
                }
            }
        }
        
        func generateSimulatedTranscription(based prompt: String) -> String {
            // This is a placeholder that would be replaced with actual speech recognition
            // For now, we'll generate a simulated response based on the prompt
            let responses = [
                "I think that \(prompt.lowercased()) is really interesting because it made me feel curious. I learned that when I try new things, sometimes it's hard at first but then it gets easier. I'm proud of myself for not giving up.",
                "When I was thinking about \(prompt.lowercased()), I remembered how I felt last time. It was challenging but I figured it out by breaking it into smaller steps. That's something I'm getting better at.",
                "Today I want to talk about \(prompt.lowercased()). It made me feel both excited and a little nervous. I think I'm getting better at understanding my feelings and knowing what helps me when things are difficult."
            ]
            
            return responses.randomElement() ?? "I recorded my thoughts about \(prompt.lowercased())."
        }
        
        func timeString(from timeInterval: TimeInterval) -> String {
            let minutes = Int(timeInterval) / 60
            let seconds = Int(timeInterval) % 60
            let tenths = Int((timeInterval - floor(timeInterval)) * 10)
            return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
        }
        
        func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            switch journalMode {
            case .earlyChildhood, .middleChildhood:
                return .system(size: size, weight: weight, design: .rounded)
            case .adolescent:
                return .system(size: size, weight: weight)
            }
        }
    }
    
    /// A view that allows recording, playback, and saving of audio for journal entries
    struct AudioRecordingView: View {
        // MARK: - Environment
        @EnvironmentObject private var themeManager: ThemeManager
        @StateObject private var viewModel: AudioRecordingViewModel
        
        // MARK: - Initialization
        init(journalMode: ChildJournalMode, onSave: @escaping (URL, String?) -> Void, onCancel: @escaping () -> Void, promptText: String?) {
            _viewModel = StateObject(wrappedValue: AudioRecordingViewModel(
                journalMode: journalMode,
                onSave: onSave,
                onCancel: onCancel,
                promptText: promptText
            ))
        }
        
        // MARK: - Body
        var body: some View {
            VStack(spacing: 0) {
                // Header
                recordingHeader
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Prompt if available
                        if let promptText = viewModel.promptText {
                            promptView(promptText)
                        }
                        
                        // Recording visualization
                        recordingVisualization
                        
                        // Controls
                        recordingControls
                        
                        // Recording info
                        if viewModel.recordingURL != nil {
                            recordingInfoView
                        }
                    }
                    .padding()
                }
                
                // Footer with actions
                recordingFooter
            }
            .background(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
            .onAppear {
                viewModel.checkMicrophonePermission()
            }
            .onDisappear {
                viewModel.stopRecording()
                viewModel.stopPlayback()
            }
            .sheet(isPresented: $viewModel.showingTranscription) {
                transcriptionSheet
            }
            .sheet(isPresented: $viewModel.showingPromptGuide) {
                promptGuideSheet
            }
        }
        
        // MARK: - Recording Header
        
        private var recordingHeader: some View {
            HStack {
                // Title
                Text("Voice Recording")
                    .font(viewModel.fontForMode(size: 18, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                
                Spacer()
                
                // Help button
                if viewModel.promptText != nil {
                    Button(action: {
                        viewModel.showingPromptGuide = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                    }
                }
            }
            .padding()
            .background(themeManager.themeForChildMode(viewModel.journalMode).cardBackgroundColor)
        }
        
        // MARK: - Prompt View
        
        private func promptView(_ prompt: String) -> some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Talk about...")
                    .font(viewModel.fontForMode(size: 16, weight: .medium))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                
                Text(prompt)
                    .font(viewModel.fontForMode(size: 18))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.themeForChildMode(viewModel.journalMode).cardBackgroundColor)
                    .shadow(radius: 2)
            )
        }
        
        // MARK: - Recording Visualization
        
        private var recordingVisualization: some View {
            VStack(spacing: 20) {
                // Microphone icon with animation
                ZStack {
                    // Background circle
                    Circle()
                        .fill(viewModel.isRecording ? Color.red.opacity(0.2) : themeManager.themeForChildMode(viewModel.journalMode).accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(viewModel.animateMicrophone ? 1.2 : 1.0)
                        .animation(
                            viewModel.isRecording ? 
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                                .default,
                            value: viewModel.animateMicrophone
                        )
                    
                    // Microphone icon
                    Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 50))
                        .foregroundColor(viewModel.isRecording ? .red : themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                        .scaleEffect(viewModel.animateMicrophone ? 1.1 : 1.0)
                        .animation(
                            viewModel.isRecording ? 
                                Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : 
                                .default,
                            value: viewModel.animateMicrophone
                        )
                }
                .padding(.vertical, 20)
                
                // Audio waveform visualization
                if viewModel.isRecording || viewModel.isPlaying {
                    audioWaveformView
                }
                
                // Timer display
                Text(viewModel.timeString(from: viewModel.isPlaying ? viewModel.playbackTime : viewModel.recordingTime))
                    .font(viewModel.fontForMode(size: 24, weight: .medium))
                    .foregroundColor(viewModel.isRecording ? .red : themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    .monospacedDigit()
                    .padding(.top, 10)
            }
        }
        
        // MARK: - Audio Waveform
        
        private var audioWaveformView: some View {
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(waveformBarColor(for: index))
                        .frame(width: 8, height: waveformBarHeight(for: index))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.recordingLevel)
                }
            }
            .frame(height: 60)
        }
        
        private func waveformBarColor(for index: Int) -> Color {
            if viewModel.isRecording {
                return .red.opacity(0.7 + Double(index % 3) * 0.1)
            } else {
                return themeManager.themeForChildMode(viewModel.journalMode).accentColor.opacity(0.7 + Double(index % 3) * 0.1)
            }
        }
        
        private func waveformBarHeight(for index: Int) -> CGFloat {
            // Create a wave-like pattern based on index and recording level
            let baseHeight: CGFloat = 10
            let maxAdditionalHeight: CGFloat = 40
            
            if viewModel.isRecording || viewModel.isPlaying {
                // Use recording level to influence height
                let position = Double(index) / 20.0 // 0 to 1
                let wave = sin(position * .pi * 2 + Double(viewModel.recordingLevel) * 5) * 0.5 + 0.5 // 0 to 1
                
                // Apply recording level as a multiplier
                let heightMultiplier = viewModel.recordingLevel * 0.8 + 0.2 // 0.2 to 1.0
                
                return baseHeight + maxAdditionalHeight * CGFloat(wave) * CGFloat(heightMultiplier)
            } else {
                // Static pattern when not recording
                return baseHeight + maxAdditionalHeight * 0.3
            }
        }
        
        // MARK: - Recording Controls
        
        private var recordingControls: some View {
            HStack(spacing: 40) {
                // Record/Stop recording button
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                            .frame(width: 70, height: 70)
                            .shadow(radius: 3)
                        
                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .disabled(!viewModel.recordingPermissionGranted)
                .opacity(viewModel.recordingPermissionGranted ? 1.0 : 0.5)
                
                // Playback controls (only visible when recording is available)
                if viewModel.recordingURL != nil && !viewModel.isRecording {
                    Button(action: {
                        if viewModel.isPlaying {
                            viewModel.pausePlayback()
                        } else {
                            viewModel.startPlayback()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeManager.themeForChildMode(viewModel.journalMode).cardBackgroundColor)
                                .frame(width: 60, height: 60)
                                .shadow(radius: 2)
                            
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                        }
                    }
                }
            }
            .padding(.vertical, 20)
        }
        
        // MARK: - Recording Info View
        
        private var recordingInfoView: some View {
            VStack(spacing: 16) {
                // Recording title
                TextField("Recording Title", text: $viewModel.recordingTitle)
                    .font(viewModel.fontForMode(size: 16, weight: .medium))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
                    )
                
                // Transcription button
                Button(action: {
                    viewModel.transcribeAudio()
                }) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 20))
                        
                        Text("See what you said")
                            .font(viewModel.fontForMode(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.themeForChildMode(viewModel.journalMode).cardBackgroundColor)
                    .shadow(radius: 2)
            )
        }
        
        // MARK: - Recording Footer
        
        private var recordingFooter: some View {
            HStack {
                // Cancel button
                Button(action: viewModel.onCancel) {
                    Text("Cancel")
                        .font(viewModel.fontForMode(size: 16, weight: .medium))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
                        )
                }
                
                Spacer()
                
                // Save button (only enabled when there's a recording)
                Button(action: {
                    if let url = viewModel.recordingURL {
                        viewModel.onSave(url, viewModel.recordingTitle.isEmpty ? "Voice Recording" : viewModel.recordingTitle)
                    }
                }) {
                    Text("Save Recording")
                        .font(viewModel.fontForMode(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.recordingURL != nil ? themeManager.themeForChildMode(viewModel.journalMode).accentColor : Color.gray)
                        )
                }
                .disabled(viewModel.recordingURL == nil)
            }
            .padding()
            .background(themeManager.themeForChildMode(viewModel.journalMode).cardBackgroundColor)
        }
        
        // MARK: - Transcription Sheet
        
        private var transcriptionSheet: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Here's what you said:")
                            .font(viewModel.fontForMode(size: 18, weight: .bold))
                            .padding(.bottom, 8)
                        
                        Text(viewModel.transcription)
                            .font(viewModel.fontForMode(size: 16))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
                            )
                    }
                    .padding()
                }
                .navigationBarTitle("Your Words", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    viewModel.showingTranscription = false
                })
            }
        }
        
        // MARK: - Prompt Guide Sheet
        
        private var promptGuideSheet: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tips for Recording")
                            .font(viewModel.fontForMode(size: 24, weight: .bold))
                            .padding(.bottom, 8)
                        
                        Text("Here are some ideas to help you talk about your thoughts and feelings:")
                            .font(viewModel.fontForMode(size: 16))
                        
                        promptTipItem(
                            title: "Start with 'I'",
                            description: "Begin with 'I think...' or 'I feel...' to focus on your experience",
                            examples: [
                                "I think math is getting easier for me",
                                "I feel proud when I finish my homework",
                                "I noticed that I get frustrated when..."
                            ]
                        )
                        
                        promptTipItem(
                            title: "Tell a story",
                            description: "Describe what happened, then how you felt, then what you thought",
                            examples: [
                                "First I tried to solve the problem, then I got stuck, and I felt...",
                                "When my friend said that, I felt... and I thought..."
                            ]
                        )
                        
                        promptTipItem(
                            title: "Compare",
                            description: "Compare how you felt before and after",
                            examples: [
                                "Before I was nervous, but after I felt confident",
                                "At first I thought it was too hard, but then I realized..."
                            ]
                        )
                        
                        promptTipItem(
                            title: "Use metaphors",
                            description: "Describe your thoughts or feelings like they're something else",
                            examples: [
                                "My brain felt like a computer with too many tabs open",
                                "My confidence grew like a plant getting taller",
                                "My worry felt like a heavy backpack"
                            ]
                        )
                        
                        Text("Remember, there's no right or wrong way to talk about your thoughts and feelings. Just speak from your heart!")
                            .font(viewModel.fontForMode(size: 16))
                            .padding(.top)
                    }
                    .padding()
                }
                .navigationBarTitle("Recording Guide", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    viewModel.showingPromptGuide = false
                })
            }
        }
        
        private func promptTipItem(title: String, description: String, examples: [String]) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(viewModel.fontForMode(size: 18, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                
                Text(description)
                    .font(viewModel.fontForMode(size: 16))
                
                Text("Examples:")
                    .font(viewModel.fontForMode(size: 14, weight: .medium))
                    .padding(.top, 4)
                
                ForEach(examples, id: \.self) { example in
                    HStack(alignment: .top) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .padding(.top, 6)
                        
                        Text(example)
                            .font(viewModel.fontForMode(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.themeForChildMode(viewModel.journalMode).backgroundColor)
            )
        }
    }
}

// MARK: - Audio Player Delegate

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Preview
struct AudioRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        MultiModal.AudioRecordingView(
            journalMode: .middleChildhood,
            onSave: { _, _ in },
            onCancel: {},
            promptText: "Tell me about something challenging you learned today and how you figured it out."
        )
        .environmentObject(ThemeManager())
    }
}
