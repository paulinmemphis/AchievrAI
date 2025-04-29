import SwiftUI
import AVFoundation
import Combine

/// Main view for child journaling interface that adapts to developmental stage
struct ChildJournalEntryView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @StateObject private var promptManager = ChildJournalPromptManager()
    @State private var currentPrompt: JournalPrompt?
    @State private var textContent: String = ""
    @State private var drawingData: Data?
    @State private var audioURL: URL?
    @State private var selectedEmojis: [String] = []
    @State private var inputMode: InputMode = .text
    @State private var showingPromptPicker = false
    @State private var showingSaveConfirmation = false
    @State private var isReadingPrompt = false
    @State private var journalMode: ChildJournalMode = .middleChildhood
    @State private var readingLevel: ReadingLevel = .grade3to4
    @State private var childName: String = "Friend"
    @State private var avatarImage: String = "avatar1"
    @State private var showHint = false
    @State private var hintText = ""
    @State private var showConfetti = false
    
    // MARK: - Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with prompt
                promptHeader
                    .padding(.top)
                
                // Input area
                ChildJournalInputView(
                    text: $textContent,
                    drawingData: $drawingData,
                    audioURL: $audioURL,
                    selectedEmojis: $selectedEmojis,
                    inputMode: $inputMode,
                    journalMode: journalMode,
                    readingLevel: readingLevel
                )
                .padding(.vertical)
                
                // Action buttons
                actionButtons
                    .padding(.bottom)
            }
            
            // Prompt picker sheet
            if showingPromptPicker {
                promptPickerOverlay
            }
            
            // Save confirmation
            if showingSaveConfirmation {
                saveConfirmationOverlay
            }
            
            // Hint bubble
            if showHint {
                hintBubble
            }
            
            // Confetti animation
            if showConfetti {
                confettiView
            }
        }
        .onAppear {
            loadUserProfile()
            currentPrompt = promptManager.getRandomPrompt()
            
            // Show hint for younger children
            if journalMode == .earlyChildhood {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    hintText = "Tap the speaker to hear your prompt!"
                    showHint = true
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Journal")
                    .font(fontForAge(size: journalMode == .earlyChildhood ? 24 : 20, weight: .bold))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(fontForAge(size: 16, weight: .medium))
                }
            }
        }
    }
    
    // MARK: - Prompt Header
    
    private var promptHeader: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                // Avatar image
                Image(avatarImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(themeManager.selectedTheme.accentColor.opacity(0.2))
                    )
                    .padding(.trailing, 5)
                
                // Prompt text
                VStack(alignment: .leading, spacing: 5) {
                    if let prompt = currentPrompt {
                        Text(prompt.text)
                            .font(fontForAge(size: journalMode == .earlyChildhood ? 22 : 18, weight: .medium))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("What would you like to write about today?")
                            .font(fontForAge(size: journalMode == .earlyChildhood ? 22 : 18, weight: .medium))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                    }
                    
                    // Category tag if available
                    if let category = currentPrompt?.category {
                        HStack {
                            Image(systemName: category.iconName)
                                .font(.system(size: 12))
                            
                            Text(category.rawValue)
                                .font(.system(size: 12, design: .rounded))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(category.color.opacity(0.2))
                        )
                        .foregroundColor(category.color)
                    }
                }
                .padding(.trailing, 5)
                
                Spacer()
                
                // Audio button for prompt reading
                if currentPrompt?.hasAudio == true || journalMode == .earlyChildhood {
                    Button(action: {
                        if let prompt = currentPrompt {
                            readPromptAloud(prompt.text)
                        }
                    }) {
                        Image(systemName: isReadingPrompt ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.system(size: 22))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(themeManager.selectedTheme.accentColor.opacity(0.2))
                            )
                    }
                }
            }
            .padding(.horizontal)
            
            // Prompt change button
            Button(action: {
                showingPromptPicker = true
            }) {
                Text("Change Prompt")
                    .font(fontForAge(size: 14, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(themeManager.selectedTheme.accentColor, lineWidth: 1)
                    )
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(themeManager.selectedTheme.cardBackgroundColor)
                .shadow(radius: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Save button
            Button(action: {
                saveJournalEntry()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save")
                }
                .font(fontForAge(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(themeManager.selectedTheme.accentColor)
                )
            }
            
            // Clear button
            Button(action: {
                clearEntry()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Start Over")
                }
                .font(fontForAge(size: 16, weight: .medium))
                .foregroundColor(themeManager.selectedTheme.accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(themeManager.selectedTheme.accentColor, lineWidth: 1)
                )
            }
        }
        .padding()
    }
    
    // MARK: - Prompt Picker Overlay
    
    private var promptPickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingPromptPicker = false
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Choose a Prompt")
                        .font(fontForAge(size: 20, weight: .bold))
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                    
                    Spacer()
                    
                    Button(action: {
                        showingPromptPicker = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Category buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Random button
                        Button(action: {
                            currentPrompt = promptManager.getRandomPrompt()
                            showingPromptPicker = false
                        }) {
                            categoryButton(title: "Random", icon: "shuffle", color: .gray)
                        }
                        
                        // Category-specific buttons
                        ForEach(PromptCategory.allCases, id: \.self) { category in
                            Button(action: {
                                currentPrompt = promptManager.getPromptByCategory(category)
                                showingPromptPicker = false
                            }) {
                                categoryButton(title: category.rawValue, icon: category.iconName, color: category.color)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Favorite prompts
                if !promptManager.favoritePrompts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Favorites")
                            .font(fontForAge(size: 18, weight: .bold))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(promptManager.favoritePrompts) { prompt in
                                    Button(action: {
                                        currentPrompt = prompt
                                        showingPromptPicker = false
                                    }) {
                                        promptCard(prompt)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(themeManager.selectedTheme.backgroundColor)
            .cornerRadius(20)
            .padding()
        }
    }
    
    private func categoryButton(title: String, icon: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color)
                )
            
            Text(title)
                .font(fontForAge(size: 14, weight: .medium))
                .foregroundColor(themeManager.selectedTheme.accentColor)
        }
        .frame(width: 80)
    }
    
    private func promptCard(_ prompt: JournalPrompt) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(prompt.text)
                    .font(fontForAge(size: 16, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: prompt.category.iconName)
                        .font(.system(size: 12))
                    
                    Text(prompt.category.rawValue)
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundColor(prompt.category.color)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(themeManager.selectedTheme.cardBackgroundColor)
        .cornerRadius(10)
    }
    
    // MARK: - Save Confirmation Overlay
    
    private var saveConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingSaveConfirmation = false
                }
            
            VStack(spacing: 20) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Great job, \(childName)!")
                    .font(fontForAge(size: 24, weight: .bold))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                
                Text(getCompletionMessage())
                    .font(fontForAge(size: 18, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                    .multilineTextAlignment(.center)
                
                // Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showingSaveConfirmation = false
                        dismiss()
                    }) {
                        Text("Done")
                            .font(fontForAge(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.selectedTheme.accentColor)
                            )
                    }
                    
                    Button(action: {
                        showingSaveConfirmation = false
                        resetForNewEntry()
                    }) {
                        Text("Write Another")
                            .font(fontForAge(size: 16, weight: .medium))
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .stroke(themeManager.selectedTheme.accentColor, lineWidth: 1)
                            )
                    }
                }
                .padding(.top)
            }
            .padding(30)
            .background(themeManager.selectedTheme.backgroundColor)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
    }
    
    // MARK: - Hint Bubble
    
    private var hintBubble: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Text(hintText)
                    .font(fontForAge(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(themeManager.selectedTheme.accentColor)
                    )
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            showHint = false
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation {
                                showHint = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Confetti View
    
    private var confettiView: some View {
        // In a real app, this would be a proper confetti animation
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.random)
                    .frame(width: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfetti = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func fontForAge(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight, design: .default)
        }
    }
    
    private func loadUserProfile() {
        // Load journal mode
        if let modeString = UserDefaults.standard.string(forKey: "childJournalMode"),
           let mode = ChildJournalMode(rawValue: modeString) {
            journalMode = mode
        }
        
        // Load user profile
        if let profileData = UserDefaults.standard.data(forKey: "childUserProfile"),
           let profile = try? JSONDecoder().decode(ChildUserProfile.self, from: profileData) {
            childName = profile.name
            readingLevel = profile.readingLevel
            avatarImage = profile.avatarImage
        }
    }
    
    private func readPromptAloud(_ text: String) {
        isReadingPrompt = true
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = journalMode == .earlyChildhood ? 0.4 : 0.5
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
        
        // Hide the hint after reading starts
        showHint = false
        
        // Reset the flag when done
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isReadingPrompt = false
        }
    }
    
    private func saveJournalEntry() {
        // Check if there's any content to save
        let hasContent = !textContent.isEmpty || drawingData != nil || audioURL != nil || !selectedEmojis.isEmpty
        
        guard hasContent else {
            // Show hint if no content
            hintText = "Please add something to your journal first!"
            showHint = true
            return
        }
        
        // In a real app, this would save the journal entry to a database
        
        // Show success animation and confirmation
        showConfetti = true
        showingSaveConfirmation = true
        
        // Play success sound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func clearEntry() {
        // Reset all content
        textContent = ""
        drawingData = nil
        audioURL = nil
        selectedEmojis = []
        inputMode = .text
    }
    
    private func resetForNewEntry() {
        // Clear content
        clearEntry()
        
        // Get a new prompt
        currentPrompt = promptManager.getRandomPrompt()
    }
    
    private func getCompletionMessage() -> String {
        switch journalMode {
        case .earlyChildhood:
            return "You did an amazing job with your journal today! 🌟"
        case .middleChildhood:
            return "Your thoughts are important. Thanks for sharing them in your journal today!"
        case .adolescent:
            return "Your reflection shows thoughtfulness. Well done on completing your journal entry."
        }
    }
}

// MARK: - Extensions

extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

// MARK: - Preview
struct ChildJournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChildJournalEntryView()
                .environmentObject(ThemeManager())
        }
    }
}
