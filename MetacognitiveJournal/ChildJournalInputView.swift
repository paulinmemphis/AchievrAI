import SwiftUI
import AVFoundation
import PencilKit

/// View that provides multiple input methods for children's journaling
struct ChildJournalInputView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Binding Properties
    @Binding var text: String
    @Binding var drawingData: Data?
    @Binding var audioURL: URL?
    @Binding var selectedEmojis: [String]
    @Binding var inputMode: InputMode
    
    // MARK: - State
    @State private var isRecording = false
    @State private var recordingSession: AVAudioSession?
    @State private var canvasView = PKCanvasView()
    @State private var showEmojiPicker = false
    @State private var showKeyboardSuggestions = false
    @State private var speechRecognizer: SpeechRecognizer
    @State private var isListening = false
    @State private var showTextToSpeech = false
    
    // MARK: - Properties
    let journalMode: ChildJournalMode
    let readingLevel: ReadingLevel
    
    private let emojiCategories = [
        ["😊", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😇", "😍"],
        ["😎", "🤩", "😋", "😛", "😜", "😝", "🤑", "🤗", "🤭", "🤫"],
        ["🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬"],
        ["😕", "😟", "🙁", "☹️", "😮", "😯", "😲", "😳", "🥺", "😦"],
        ["😧", "😨", "😰", "😥", "😢", "😭", "😱", "😖", "😣", "😞"],
        ["😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬", "😈", "👿"]
    ]
    
    private let suggestionWords: [String] = [
        "happy", "sad", "excited", "worried", "proud", "frustrated", 
        "confused", "curious", "surprised", "nervous", "calm", "angry",
        "learned", "discovered", "created", "helped", "shared", "tried",
        "thought", "felt", "wondered", "noticed", "remembered", "imagined",
        "because", "when", "sometimes", "today", "tomorrow", "yesterday"
    ]
    
    init(text: Binding<String>, drawingData: Binding<Data?>, audioURL: Binding<URL?>, selectedEmojis: Binding<[String]>, inputMode: Binding<InputMode>, journalMode: ChildJournalMode, readingLevel: ReadingLevel) {
        _text = text
        _drawingData = drawingData
        _audioURL = audioURL
        _selectedEmojis = selectedEmojis
        _inputMode = inputMode
        self.journalMode = journalMode
        self.readingLevel = readingLevel
        
        _speechRecognizer = State(initialValue: SpeechRecognizer())
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Input area
            ZStack {
                // Text input
                if inputMode == .text {
                    textInputView
                }
                
                // Drawing input
                if inputMode == .drawing {
                    drawingInputView
                }
                
                // Audio input
                if inputMode == .audio {
                    audioInputView
                }
                
                // Emoji input
                if inputMode == .emoji {
                    emojiInputView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.selectedTheme.cardBackgroundColor)
            .cornerRadius(15)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // Input mode selector
            inputModeSelector
                .padding()
            
            // Age-appropriate assistance
            if showKeyboardSuggestions && inputMode == .text {
                keyboardSuggestions
            }
        }
        .onAppear {
            setupAudioSession()
            speechRecognizer.configure(textBinding: $text)
        }
    }
    
    // MARK: - Input Views
    
    private var textInputView: some View {
        VStack {
            if journalMode == .earlyChildhood {
                HStack {
                    Button(action: {
                        showTextToSpeech.toggle()
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        startListening()
                    }) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 24))
                            .foregroundColor(isListening ? .red : themeManager.selectedTheme.accentColor)
                    }
                    .padding(.trailing)
                }
                .padding(.top)
            }
            
            if showTextToSpeech && journalMode == .earlyChildhood {
                Button(action: {
                    speakText(text.isEmpty ? "Type your thoughts here" : text)
                }) {
                    Text("Read aloud")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.selectedTheme.accentColor.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.bottom, 5)
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(journalMode == .earlyChildhood ? "Write or speak your thoughts..." : "Write your thoughts here...")
                        .font(fontForAge())
                        .foregroundColor(Color.gray.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .font(fontForAge())
                    .padding(5)
                    .background(themeManager.selectedTheme.backgroundColor)
                    .cornerRadius(10)
                    .onChange(of: text) { _ in
                        showKeyboardSuggestions = true
                    }
            }
            .padding()
        }
    }
    
    private var drawingInputView: some View {
        VStack {
            Text("Draw how you feel or what happened")
                .font(fontForAge())
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .padding(.top)
            
            CanvasView(canvasView: $canvasView, drawingData: $drawingData)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .padding()
            
            HStack(spacing: 20) {
                // Clear button
                Button(action: {
                    canvasView.drawing = PKDrawing()
                    drawingData = nil
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                
                // Color picker (simplified for children)
                ForEach([Color.black, Color.blue, Color.red, Color.green, Color.orange, Color.purple], id: \.self) { color in
                    Button(action: {
                        canvasView.tool = PKInkingTool(.pen, color: UIColor(color), width: 5)
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                }
                
                // Eraser
                Button(action: {
                    canvasView.tool = PKEraserTool(.vector)
                }) {
                    Image(systemName: "eraser")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            .padding(.bottom)
        }
    }
    
    private var audioInputView: some View {
        VStack {
            Text(isRecording ? "Recording..." : "Tap to record your voice")
                .font(fontForAge())
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .padding(.top)
            
            Spacer()
            
            // Record button
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : themeManager.selectedTheme.accentColor)
                        .frame(width: 80, height: 80)
                    
                    if isRecording {
                        Circle()
                            .stroke(Color.red, lineWidth: 4)
                            .frame(width: 100, height: 100)
                    }
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Playback controls (if recording exists)
            if audioURL != nil {
                HStack {
                    Button(action: {
                        playRecording()
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                    
                    Button(action: {
                        audioURL = nil
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
        }
    }
    
    private var emojiInputView: some View {
        VStack {
            Text("How are you feeling?")
                .font(fontForAge())
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .padding(.top)
            
            // Selected emojis
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(selectedEmojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: journalMode == .earlyChildhood ? 50 : 40))
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(themeManager.selectedTheme.accentColor.opacity(0.2))
                            )
                            .onTapGesture {
                                if let index = selectedEmojis.firstIndex(of: emoji) {
                                    selectedEmojis.remove(at: index)
                                }
                            }
                    }
                    
                    if selectedEmojis.isEmpty {
                        Text("Tap emojis below to add them")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 70)
            .padding(.vertical)
            
            // Emoji grid
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(emojiCategories, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: journalMode == .earlyChildhood ? 40 : 30))
                                    .onTapGesture {
                                        if !selectedEmojis.contains(emoji) && selectedEmojis.count < 5 {
                                            selectedEmojis.append(emoji)
                                            playHapticFeedback()
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Input Mode Selector
    
    private var inputModeSelector: some View {
        HStack(spacing: 20) {
            // Text mode
            inputModeButton(mode: .text, icon: "text.bubble", label: "Write")
            
            // Drawing mode
            inputModeButton(mode: .drawing, icon: "scribble", label: "Draw")
            
            // Audio mode
            inputModeButton(mode: .audio, icon: "mic", label: "Speak")
            
            // Emoji mode
            inputModeButton(mode: .emoji, icon: "face.smiling", label: "Emoji")
        }
        .padding(.horizontal)
        .background(themeManager.selectedTheme.backgroundColor)
    }
    
    private func inputModeButton(mode: InputMode, icon: String, label: String) -> some View {
        Button(action: {
            withAnimation {
                inputMode = mode
                showKeyboardSuggestions = mode == .text
            }
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(inputMode == mode ? themeManager.selectedTheme.accentColor : .gray)
                
                Text(label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(inputMode == mode ? themeManager.selectedTheme.accentColor : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(inputMode == mode ? 
                          themeManager.selectedTheme.accentColor.opacity(0.2) : 
                          Color.clear)
            )
        }
    }
    
    // MARK: - Keyboard Suggestions
    
    private var keyboardSuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filteredSuggestions(), id: \.self) { word in
                    Button(action: {
                        insertSuggestion(word)
                    }) {
                        Text(word)
                            .font(.system(size: 16, design: .rounded))
                            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                            .background(themeManager.selectedTheme.accentColor.opacity(0.15))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(themeManager.selectedTheme.backgroundColor)
    }
    
    // MARK: - Helper Methods
    
    private func fontForAge() -> Font {
        switch journalMode {
        case .earlyChildhood:
            return .system(size: 22, weight: .regular, design: .rounded)
        case .middleChildhood:
            return .system(size: 18, weight: .regular, design: .rounded)
        case .adolescent:
            return .system(size: 16, weight: .regular, design: .default)
        }
    }
    
    private func filteredSuggestions() -> [String] {
        // Return age-appropriate suggestions
        // In a real app, this would be more sophisticated
        switch journalMode {
        case .earlyChildhood:
            return Array(suggestionWords.prefix(10))
        case .middleChildhood:
            return Array(suggestionWords.prefix(20))
        case .adolescent:
            return suggestionWords
        }
    }
    
    private func insertSuggestion(_ word: String) {
        text += text.isEmpty ? word : " \(word)"
        playHapticFeedback()
    }
    
    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func setupAudioSession() {
        // In a real app, this would set up the AVAudioSession
    }
    
    private func startRecording() {
        // In a real app, this would start the audio recording
        isRecording = true
    }
    
    private func stopRecording() {
        // In a real app, this would stop the audio recording and save the file
        isRecording = false
        audioURL = URL(string: "recording.m4a")
    }
    
    private func playRecording() {
        // In a real app, this would play the recorded audio
    }
    
    private func startListening() {
        // In a real app, this would start speech recognition
        isListening = true
        
        // Simulate speech recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isListening = false
            text += " " + "I had fun playing with my friends today."
        }
    }
    
    private func speakText(_ text: String) {
        // In a real app, this would use AVSpeechSynthesizer
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}

// MARK: - Supporting Types

/// Input modes for the journal
enum InputMode: String, Codable {
    case text
    case drawing
    case audio
    case emoji
}

/// Canvas view for drawing
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawingData: Data?
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.backgroundColor = .white
        canvasView.isOpaque = false
        
        // Load existing drawing if available
        if let data = drawingData {
            if let drawing = try? PKDrawing(data: data) {
                canvasView.drawing = drawing
            }
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Save drawing when it changes
        drawingData = uiView.drawing.dataRepresentation()
    }
}

// MARK: - Helper Types and Extensions

/// Extension for convenient color initialization
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct ChildJournalInputView_Previews: PreviewProvider {
    static var previews: some View {
        ChildJournalInputViewWrapper(journalMode: .middleChildhood, readingLevel: .grade3to4)
    }
    
    struct ChildJournalInputViewWrapper: View {
        let journalMode: ChildJournalMode
        let readingLevel: ReadingLevel
        
        @State private var text: String = ""
        @State private var drawingData: Data?
        @State private var audioURL: URL?
        @State private var selectedEmojis: [String] = []
        @State private var inputMode: InputMode = .text
        
        var body: some View {
            NavigationView {
                ChildJournalInputView(text: $text,
                                      drawingData: $drawingData,
                                      audioURL: $audioURL,
                                      selectedEmojis: $selectedEmojis,
                                      inputMode: $inputMode,
                                      journalMode: journalMode,
                                      readingLevel: readingLevel)
                .navigationTitle("Journal Entry")
                .environmentObject(ThemeManager())
            }
        }
    }
}
