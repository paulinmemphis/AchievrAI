import SwiftUI
import Combine

/// A modern, age-appropriate prompt view that adapts to the user's age group
struct EnhancedPromptView: View {
    // MARK: - Properties
    @Binding var promptResponse: PromptResponse
    @EnvironmentObject private var userProfile: UserProfile
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var promptManager = AgeAppropriatePromptManager(userProfile: UserProfile())
    
    @State private var isAnimating = false
    @State private var showConfetti = false
    @State private var responseText = ""
    @State private var selectedOption = ""
    @State private var showEmojiFeedback = false
    @State private var selectedEmoji = ""
    @State private var showHint = false
    
    // MARK: - Computed Properties
    private var uxStyle: UXCustomization {
        promptManager.uiCustomizations
    }
    
    private var isChild: Bool {
        userProfile.ageGroup == .child
    }
    
    private var isTeen: Bool {
        userProfile.ageGroup == .teen
    }
    
    private var hasResponse: Bool {
        !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedOption.isEmpty
    }
    
    private var promptCategory: PromptCategory {
        // Map the prompt text to a category (simplified for demo)
        let text = promptResponse.prompt.lowercased()
        
        if text.contains("feel") || text.contains("emotion") {
            return .emotions
        } else if text.contains("learn") || text.contains("skill") {
            return .learning
        } else if text.contains("imagine") || text.contains("creative") {
            return .creativity
        } else { // Includes grateful/thankful and general reflection
            return .reflection
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with category and emoji
            promptHeader
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Prompt text
                    promptText
                    
                    // Options if available
                    if let options = promptResponse.options, !options.isEmpty {
                        optionsView(options: options)
                    }
                    
                    // Free text response
                    responseEditor
                    
                    // Emoji feedback for children
                    if isChild && !showEmojiFeedback {
                        childEmojiSelector
                    }
                    
                    // Save button
                    saveButton
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(backgroundView)
        .cornerRadius(uxStyle.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            confettiView
                .opacity(showConfetti ? 1 : 0)
        )
        .onAppear {
            setupInitialState()
            animateIn()
        }
    }
    
    // MARK: - View Components
    
    /// Header with category and emoji
    private var promptHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(promptCategory.rawValue)
                    .font(uxStyle.secondaryFont)
                    .foregroundColor(promptCategory.color)
                    .fontWeight(.bold)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -10)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(promptCategory.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: promptCategory.iconName)
                    .font(.title2)
                    .foregroundColor(promptCategory.color)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.5)
            }
        }
        .padding()
        .background(
            promptCategory.color
                .opacity(0.1)
                .cornerRadius(uxStyle.cornerRadius)
        )
    }
    
    /// Prompt text with age-appropriate styling
    private var promptText: some View {
        Text(promptResponse.prompt)
            .font(uxStyle.primaryFont)
            .foregroundColor(themeManager.selectedTheme.textColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                    .fill(themeManager.selectedTheme.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Options selector with age-appropriate styling
    private func optionsView(options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isChild ? "Pick one:" : "Select an option:")
                .font(uxStyle.secondaryFont)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            if isChild {
                // Child-friendly option buttons
                childOptionButtons(options: options)
            } else {
                // Teen/Adult segmented picker
                Picker("", selection: $selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedOption) { newValue in
                    promptResponse.selectedOption = newValue
                    
                    // Haptic feedback for teens
                    if isTeen {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                .fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.7))
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Child-friendly option buttons
    private func childOptionButtons(options: [String]) -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedOption = option
                        promptResponse.selectedOption = option
                    }
                }) {
                    HStack {
                        Text(option)
                            .font(uxStyle.bodyFont)
                            .foregroundColor(selectedOption == option ? .white : themeManager.selectedTheme.textColor)
                            .padding()
                        
                        Spacer()
                        
                        if selectedOption == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .padding(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(selectedOption == option ? uxStyle.primaryColor : Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(selectedOption == option ? uxStyle.primaryColor : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    /// Text editor for response
    private var responseEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isChild ? "My Thoughts:" : "Your Response:")
                    .font(uxStyle.secondaryFont)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                
                Spacer()
                
                if showHint {
                    Button(action: {
                        showHint = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        showHint = true
                    }) {
                        Label("Hint", systemImage: "lightbulb")
                            .font(.caption)
                            .foregroundColor(uxStyle.secondaryColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if showHint {
                hintView
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $responseText)
                    .font(uxStyle.bodyFont)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .frame(minHeight: isChild ? 120 : 150)
                    .padding(10)
                    .background(themeManager.selectedTheme.inputBackgroundColor)
                    .cornerRadius(uxStyle.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                            .stroke(themeManager.selectedTheme.dividerColor, lineWidth: 1)
                    )
                    .onChange(of: responseText) { newValue in
                        promptResponse.response = newValue
                    }
                
                if responseText.isEmpty {
                    Text(uxStyle.textEntryPrompt)
                        .font(uxStyle.bodyFont)
                        .foregroundColor(themeManager.selectedTheme.placeholderColor)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                .fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.7))
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Hint view with writing suggestions
    private var hintView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Writing Tips:")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(uxStyle.secondaryColor)
            
            if isChild {
                Text("• Try starting with 'I feel...' or 'Today I...'")
                Text("• You can write about what happened")
                Text("• You can share how it made you feel")
            } else if isTeen {
                Text("• Consider what led to this feeling or situation")
                Text("• How might this connect to other experiences?")
                Text("• What might you do differently next time?")
            } else {
                Text("• Consider both emotional and analytical perspectives")
                Text("• Reflect on patterns or recurring themes")
                Text("• How might this insight inform future actions?")
            }
        }
        .font(.caption)
        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(uxStyle.secondaryColor.opacity(0.1))
        )
        .transition(.opacity)
    }
    
    /// Emoji selector for children
    private var childEmojiSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How did writing this make you feel?")
                .font(uxStyle.secondaryFont)
                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            
            HStack(spacing: 15) {
                ForEach(["😀", "😊", "😐", "😢", "😡"], id: \.self) { emoji in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedEmoji = emoji
                            showEmojiFeedback = true
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }) {
                        Text(emoji)
                            .font(.system(size: 30))
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji ? 
                                          uxStyle.primaryColor.opacity(0.2) : 
                                          Color.clear)
                            )
                            .scaleEffect(selectedEmoji == emoji ? 1.2 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: uxStyle.cornerRadius)
                .fill(themeManager.selectedTheme.cardBackgroundColor.opacity(0.7))
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Save button with age-appropriate styling
    private var saveButton: some View {
        Button(action: saveResponse) {
            Text(uxStyle.saveButtonText)
                .font(uxStyle.secondaryFont)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Group {
                        switch uxStyle.buttonStyle {
                        case .standard:
                            RoundedRectangle(cornerRadius: 8)
                        case .rounded:
                            RoundedRectangle(cornerRadius: 16)
                        case .capsule:
                            Capsule()
                        }
                    }
                    .foregroundColor(hasResponse ? uxStyle.accentColor : Color.gray)
                )
                .shadow(color: hasResponse ? uxStyle.accentColor.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                .scaleEffect(hasResponse ? 1 : 0.98)
        }
        .disabled(!hasResponse)
        .padding(.top, 20)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }
    
    /// Background view with age-appropriate styling
    private var backgroundView: some View {
        ZStack {
            themeManager.selectedTheme.backgroundColor
            
            if isChild {
                // Fun background for children
                VStack {
                    HStack {
                        ForEach(0..<3) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(uxStyle.secondaryColor.opacity(0.1))
                                .font(.system(size: CGFloat.random(in: 20...40)))
                                .offset(x: CGFloat.random(in: -100...100), 
                                        y: CGFloat.random(in: -50...50))
                        }
                    }
                    Spacer()
                }
                
                // Bottom decoration
                VStack {
                    Spacer()
                    HStack {
                        ForEach(0..<5) { _ in
                            Circle()
                                .fill(uxStyle.primaryColor.opacity(0.1))
                                .frame(width: CGFloat.random(in: 20...60), 
                                       height: CGFloat.random(in: 20...60))
                                .offset(x: CGFloat.random(in: -100...100), 
                                        y: CGFloat.random(in: -20...20))
                        }
                    }
                }
            } else if isTeen {
                // Subtle gradient for teens
                LinearGradient(
                    gradient: Gradient(colors: [
                        uxStyle.backgroundColor,
                        uxStyle.primaryColor.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
    /// Confetti celebration view
    private var confettiView: some View {
        ZStack {
            ForEach(0..<20) { i in
                Circle()
                    .fill(
                        [uxStyle.primaryColor, uxStyle.secondaryColor, uxStyle.accentColor][i % 3]
                    )
                    .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 50...300),
                        y: CGFloat.random(in: 50...100)
                    )
                    .offset(y: showConfetti ? 400 : 0)
                    .opacity(showConfetti ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1)
                            .delay(Double.random(in: 0...0.3))
                            .repeatCount(1),
                        value: showConfetti
                    )
            }
        }
    }
    
    // MARK: - Methods
    
    /// Set up the initial state
    private func setupInitialState() {
        // Initialize response text and selected option from binding
        responseText = promptResponse.response ?? ""
        selectedOption = promptResponse.selectedOption ?? ""
    }
    
    /// Animate the view in
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5)) {
            isAnimating = true
        }
    }
    
    /// Save the response
    private func saveResponse() {
        // Update the prompt response
        promptResponse.response = responseText
        promptResponse.selectedOption = selectedOption
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show confetti for children and teens
        if isChild || isTeen {
            withAnimation {
                showConfetti = true
            }
            
            // Hide confetti after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
        
        // Additional feedback for children
        if isChild && !selectedEmoji.isEmpty {
            showEmojiFeedback = true
        }
    }
}

// MARK: - Preview
struct EnhancedPromptView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Child preview
            childPreview
                .previewDisplayName("Child (6-12)")
            
            // Teen preview
            teenPreview
                .previewDisplayName("Teen (13-17)")
            
            // Adult preview
            adultPreview
                .previewDisplayName("Adult (18+)")
        }
        .padding()
        .background(Color(.systemBackground))
        .environmentObject(ThemeManager())
    }
    
    static var childPreview: some View {
        let userProfile = UserProfile()
        userProfile.setAgeGroup(.child)
        
        return EnhancedPromptView(
            promptResponse: .constant(
                PromptResponse(
                    id: UUID(),
                    prompt: "What made you super happy today?",
                    options: nil,
                    selectedOption: nil,
                    response: nil
                )
            )
        )
        .environmentObject(userProfile)
    }
    
    static var teenPreview: some View {
        let userProfile = UserProfile()
        userProfile.setAgeGroup(.teen)
        
        return EnhancedPromptView(
            promptResponse: .constant(
                PromptResponse(
                    id: UUID(),
                    prompt: "If your life was a movie or show, what genre would it be right now?",
                    options: ["Action/Adventure", "Comedy", "Drama", "Sci-Fi", "Documentary"],
                    selectedOption: nil,
                    response: nil
                )
            )
        )
        .environmentObject(userProfile)
    }
    
    static var adultPreview: some View {
        let userProfile = UserProfile()
        userProfile.setAgeGroup(.adult)
        
        return EnhancedPromptView(
            promptResponse: .constant(
                PromptResponse(
                    id: UUID(),
                    prompt: "What's one area of personal growth you're currently focused on?",
                    options: nil,
                    selectedOption: nil,
                    response: nil
                )
            )
        )
        .environmentObject(userProfile)
    }
}
