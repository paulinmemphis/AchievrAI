import SwiftUI
import Combine

// MARK: - Supporting Types

/// Types of emotions for selection
enum EmotionType: String, CaseIterable {
    case joy = "Joy"
    case sadness = "Sadness"
    case anger = "Anger"
    case fear = "Fear"
    case disgust = "Disgust"
    case surprise = "Surprise"
    case anticipation = "Anticipation"
    case trust = "Trust"
    case anxiety = "Anxiety"
    case contentment = "Contentment"
    case shame = "Shame"
    case pride = "Pride"
    case confusion = "Confusion"
    case boredom = "Boredom"
    
    var iconName: String {
        switch self {
        case .joy: return "face.smiling.fill"
        case .sadness: return "cloud.drizzle.fill"
        case .anger: return "flame.fill"
        case .fear: return "exclamationmark.triangle.fill"
        case .disgust: return "hand.thumbsdown.fill"
        case .surprise: return "star.fill"
        case .anticipation: return "sparkles"
        case .trust: return "hand.raised.fill"
        case .anxiety: return "waveform.path.ecg"
        case .contentment: return "heart.fill"
        case .shame: return "eye.slash.fill"
        case .pride: return "medal.fill"
        case .confusion: return "questionmark"
        case .boredom: return "zzz"
        }
    }
    
    var color: Color {
        switch self {
        case .joy: return .yellow
        case .sadness: return .blue
        case .anger: return .red
        case .fear: return .purple
        case .disgust: return .green
        case .surprise: return .orange
        case .anticipation: return .pink
        case .trust: return .mint
        case .anxiety: return .indigo
        case .contentment: return .teal
        case .shame: return .brown
        case .pride: return .cyan
        case .confusion: return .gray
        case .boredom: return .secondary
        }
    }
}

/// Body areas for selection
enum BodyArea: String, CaseIterable {
    case head = "Head"
    case throat = "Throat"
    case chest = "Chest"
    case stomach = "Stomach"
    case lowerBack = "Lower Back"
    case arms = "Arms"
    case hands = "Hands"
    case legs = "Legs"
    case feet = "Feet"
    
    var offset: CGSize {
        switch self {
        case .head: return CGSize(width: 0, height: -80)
        case .throat: return CGSize(width: 0, height: -55)
        case .chest: return CGSize(width: 0, height: -30)
        case .stomach: return CGSize(width: 0, height: -5)
        case .lowerBack: return CGSize(width: 0, height: 20)
        case .arms: return CGSize(width: -30, height: -20)
        case .hands: return CGSize(width: -40, height: 0)
        case .legs: return CGSize(width: 0, height: 50)
        case .feet: return CGSize(width: 0, height: 90)
        }
    }
}

/// Breathing phases
enum BreathingPhase {
    case inhale
    case exhale
    
    var instruction: String {
        switch self {
        case .inhale: return "Breathe in..."
        case .exhale: return "Breathe out..."
        }
    }
}

/// A view that guides users through body awareness exercises for emotional regulation
struct BodyAwarenessPromptView: View {
    // MARK: - State
    @State private var selectedEmotion: EmotionType?
    @State private var bodyAreas: [BodyArea] = BodyArea.allCases
    @State private var selectedBodyAreas: Set<BodyArea> = []
    @State private var intensity: Double = 0.5
    @State private var breathCount: Int = 0
    @State private var isBreathing: Bool = false
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var breathingTimer: Timer?
    @State private var notes: String = ""
    @State private var showCompletionView: Bool = false
    @State private var isSaving: Bool = false
    
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var coordinator: PsychologicalEnhancementsCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            if showCompletionView {
                completionView
            } else {
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        header
                        
                        // Emotion Selection
                        emotionSelector
                        
                        // Body Map
                        bodyMapSection
                        
                        // Intensity Slider
                        intensitySection
                        
                        // Breathing Exercise
                        breathingExerciseSection
                        
                        // Notes
                        notesSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Body Awareness")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
            }
        }
        .onDisappear {
            breathingTimer?.invalidate()
            breathingTimer = nil
        }
    }
    
    // MARK: - Header Section
    private var header: some View {
        VStack(spacing: 12) {
            Text("Emotional Awareness Check-In")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.selectedTheme.textColor)
                .padding(.top, 10)
            
            Text("Take a moment to notice what's happening in your body right now. This helps build your emotional intelligence and self-regulation.")
                .font(.subheadline)
                .foregroundColor(themeManager.selectedTheme.imageColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Emotion Selector
    private var emotionSelector: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("What are you feeling right now?")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100))], spacing: 12) {
                ForEach(EmotionType.allCases, id: \.self) { emotion in
                    Button {
                        withAnimation {
                            selectedEmotion = emotion
                        }
                    } label: {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(selectedEmotion == emotion ? emotion.color : Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: emotion.iconName)
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            
                            Text(emotion.rawValue)
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.textColor)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedEmotion == emotion ? 
                                      emotion.color.opacity(0.1) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedEmotion == emotion ? 
                                               emotion.color : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
        )
    }
    
    // MARK: - Body Map Section
    private var bodyMapSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Where do you feel it in your body?")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            VStack {
                // Body map illustration
                ZStack {
                    // Background body silhouette
                    Image(systemName: "figure.stand")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .foregroundColor(themeManager.selectedTheme.textColor.opacity(0.2))
                    
                    // Selected body areas
                    ForEach(Array(selectedBodyAreas), id: \.self) { area in
                        Circle()
                            .fill(selectedEmotion?.color ?? themeManager.selectedTheme.accentColor)
                            .frame(width: 30, height: 30)
                            .opacity(0.7)
                            .offset(area.offset)
                    }
                }
                .padding(.vertical, 20)
                
                // Body area selection buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(bodyAreas, id: \.self) { area in
                            Button {
                                withAnimation {
                                    if selectedBodyAreas.contains(area) {
                                        selectedBodyAreas.remove(area)
                                    } else {
                                        selectedBodyAreas.insert(area)
                                    }
                                }
                            } label: {
                                Text(area.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedBodyAreas.contains(area) ? 
                                                 (selectedEmotion?.color ?? themeManager.selectedTheme.accentColor) : 
                                                 themeManager.selectedTheme.backgroundColor)
                                    )
                                    .foregroundColor(selectedBodyAreas.contains(area) ? .white : themeManager.selectedTheme.textColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 5)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
        )
    }
    
    // MARK: - Intensity Section
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("How intense is this feeling?")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Mild")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                    
                    Spacer()
                    
                    Text("Intense")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                }
                
                Slider(value: $intensity, in: 0...1, step: 0.01)
                    .accentColor(selectedEmotion?.color ?? themeManager.selectedTheme.accentColor)
                
                HStack {
                    Spacer()
                    
                    Text("\(Int(intensity * 100))%")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
        )
    }
    
    // MARK: - Breathing Exercise Section
    private var breathingExerciseSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Breathing Exercise")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                if !isBreathing {
                    Button {
                        startBreathingExercise()
                    } label: {
                        Text("Start")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                } else {
                    Button {
                        stopBreathingExercise()
                    } label: {
                        Text("Stop")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if isBreathing {
                VStack(spacing: 20) {
                    Text(breathingPhase.instruction)
                        .font(.title3)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Breathing circle animation
                    Circle()
                        .stroke(themeManager.selectedTheme.accentColor, lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(breathingPhase == .inhale ? 1.0 : 0.7)
                        .animation(.easeInOut(duration: breathingPhase == .inhale ? 4 : 4), value: breathingPhase)
                        .overlay(
                            Circle()
                                .fill(themeManager.selectedTheme.accentColor.opacity(0.2))
                                .scaleEffect(breathingPhase == .inhale ? 1.0 : 0.7)
                                .animation(.easeInOut(duration: breathingPhase == .inhale ? 4 : 4), value: breathingPhase)
                        )
                    
                    Text("Breath count: \(breathCount)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                Text("Taking a few deep breaths can help you connect with your body and regulate your emotions. Tap 'Start' when you're ready.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.imageColor)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
        )
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Any additional observations?")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.selectedTheme.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.selectedTheme.imageColor.opacity(0.5), lineWidth: 1)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.selectedTheme.backgroundColor)
        )
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveBodyAwareness()
        } label: {
            Text("Save Awareness Check-In")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.selectedTheme.accentColor)
                )
        }
        .padding(.vertical, 10)
        .disabled(selectedEmotion == nil)
        .opacity(selectedEmotion == nil ? 0.6 : 1.0)
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 30) {
            LottieView(name: "completion")
                .frame(width: 200, height: 200)
            
            Text("Awareness Check-In Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.selectedTheme.textColor)
            
            Text("Great job taking this moment to check in with your body. This practice builds your self-awareness and emotional regulation capacity over time.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.selectedTheme.imageColor)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Emotion:")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                    
                    Text(selectedEmotion?.rawValue ?? "")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
                
                HStack {
                    Text("Intensity:")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                    
                    Text("\(Int(intensity * 100))%")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
                
                HStack {
                    Text("Breaths taken:")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.imageColor)
                    
                    Text("\(breathCount)")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.textColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.selectedTheme.backgroundColor)
            )
            
            Button {
                dismiss()
            } label: {
                Text("Return to Journal")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.selectedTheme.accentColor)
                    )
            }
            .padding(.top, 20)
        }
        .padding()
        .transition(.opacity)
    }
    
    // MARK: - Methods
    
    /// Starts the breathing exercise
    private func startBreathingExercise() {
        isBreathing = true
        breathCount = 0
        breathingPhase = .inhale
        
        // Create a timer that alternates between inhale and exhale
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation {
                breathingPhase = breathingPhase == .inhale ? .exhale : .inhale
                if breathingPhase == .inhale {
                    breathCount += 1
                }
            }
        }
    }
    
    /// Stops the breathing exercise
    private func stopBreathingExercise() {
        breathingTimer?.invalidate()
        breathingTimer = nil
        isBreathing = false
    }
    
    /// Saves the body awareness check-in data
    private func saveBodyAwareness() {
        // Prevent double-saving
        guard !isSaving else { return }
        isSaving = true
        
        // Ensure we have an emotion selected
        guard let emotion = selectedEmotion else {
            isSaving = false
            return
        }
        
        // Create a new check-in record
        let checkIn = BodyAwarenessCheckIn(
            emotion: emotion.rawValue,
            intensity: intensity,
            bodyAreas: selectedBodyAreas.map { $0.rawValue },
            breathCount: breathCount,
            notes: notes
        )
        
        // Save to the BodyAwarenessManager
        let success = BodyAwarenessManager.shared.saveCheckIn(checkIn)
        
        // Notify the coordinator that a body awareness check-in was completed
        coordinator.recordBodyAwarenessCompletion()
        
        print("[BodyAwarenessPromptView] Check-in saved: \(success)")
        
        // Show completion view
        withAnimation {
            showCompletionView = true
            isSaving = false
        }
    }
}


// MARK: - Preview
struct BodyAwarenessPromptView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BodyAwarenessPromptView()
                .environmentObject(ThemeManager())
        }
    }
}
