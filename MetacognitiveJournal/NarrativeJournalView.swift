import SwiftUI
import Combine

/// A modern, immersive journal entry view with narrative story generation capabilities
struct NarrativeJournalView: View {
    // MARK: - Properties
    @ObservedObject private var viewModel = JournalEntryViewModel()
    @State private var showGenreSelector = false
    @State private var showGeneratedStory = false
    @State private var animateTransform = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Animation Properties
    private let sparkleColors: [Color] = [.blue, .purple, .pink, .orange, .yellow]
    @State private var showSparkles = false
    @State private var sparkleOffsets: [CGSize] = []
    
    // Define a simple Prompt struct
    struct Prompt: Identifiable {
        let id = UUID()
        let text: String
        let icon: String
        var title: String { // Simple title derivation
            let words = text.split(separator: " ").prefix(3)
            return words.joined(separator: " ") + "..."
        }
    }

    // Static list of predefined prompts
    static let predefinedPrompts: [Prompt] = [
        Prompt(text: "What was the most significant challenge I faced today, and how did I approach it?", icon: "flame.fill"),
        Prompt(text: "Describe a moment when I felt particularly proud of myself recently.", icon: "star.fill"),
        Prompt(text: "What is one thing I learned today, either about myself or the world?", icon: "lightbulb.fill"),
        Prompt(text: "If I could give my past self advice based on today's experiences, what would it be?", icon: "arrowshape.turn.up.backward.fill"),
        Prompt(text: "How did my emotions influence my decisions or actions today?", icon: "brain.head.profile")
    ]

    // MARK: - Body
    var body: some View {
        ZStack {
            // Main Content
            journalContent
                .overlay(
                    errorOverlay
                )
            
            // Genre Selector
            if showGenreSelector {
                genreSelectorOverlay
            }
            
            // Generating Story Overlay
            if viewModel.isGeneratingStory {
                generatingStoryOverlay
            }
            
            // Generated Story
            if showGeneratedStory, let chapter = viewModel.chapter {
                generatedStoryOverlay(chapter: chapter)
            }
        }
        .onDisappear {
            // Save genre preference when view disappears
            viewModel.saveGenrePreference()
        }
    }
    
    // MARK: - Main Journal Content
    private var journalContent: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            // Editor
            editor
            
            // Footer
            footer
        }
        .background(themeManager.selectedTheme.backgroundColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
    }
    
    // MARK: - Header Section
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("New Journal Entry")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showGenreSelector.toggle()
                    }
                }) {
                    HStack {
                        Text(NarrativeEngineConstants.genres[viewModel.selectedGenre] ?? "Fantasy")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(themeManager.selectedTheme.accentColor.opacity(0.15))
                    )
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // AI Nudges
            aiPromptRow
        }
        .padding(.bottom, 8)
        .background(themeManager.selectedTheme.backgroundColor)
    }
    
    // MARK: - AI Prompt Row
    private var aiPromptRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Use static prompts instead of AINudgeType
                ForEach(Self.predefinedPrompts) { prompt in
                    Button(action: {
                        // Append the selected prompt text
                        // Ensure newline is correctly escaped for the string
                        viewModel.entryText += "\n\n\(prompt.text)"
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: prompt.icon)
                                Text(prompt.title) // Use derived title
                                    .fontWeight(.medium)
                            }
                            
                            Text(prompt.text) // Show full text in caption
                                .font(.caption)
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                                .lineLimit(2) // Allow two lines for the prompt text
                        }
                        .padding(10)
                        .frame(width: 180, height: 80, alignment: .leading) // Adjusted frame
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.selectedTheme.cardBackgroundColor)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Text Editor
    private var editor: some View {
        VStack(spacing: 0) {
            // Text editor
            ZStack(alignment: .topLeading) {
                if viewModel.entryText.isEmpty {
                    Text("What's on your mind today?")
                        .foregroundColor(themeManager.selectedTheme.placeholderColor)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                
                TextEditor(text: $viewModel.entryText)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 200)
                    .background(Color.clear)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                    .lineSpacing(5)
            }
            .padding(.horizontal)
            
            // Word count indicator
            HStack {
                Spacer()
                
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    .padding(.trailing)
                    .padding(.bottom, 5)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.selectedTheme.inputBackgroundColor)
                .padding(.horizontal)
        )
    }
    
    // MARK: - Footer Section
    private var footer: some View {
        HStack {
            Button(action: {
                viewModel.clearEntry()
            }) {
                Text("Clear")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(themeManager.selectedTheme.dividerColor, lineWidth: 1)
                    )
            }
            
            Spacer()
            
            // Transform button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateTransform = true
                    scale = 1.1
                    rotation = 5
                    
                    // Setup sparkles
                    setupSparkleAnimation()
                }
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                        rotation = 0
                    }
                }
                
                // Start story generation process
                viewModel.saveEntryAndGenerateStory()
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Transform")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(themeManager.selectedTheme.accentColor)
                )
                .foregroundColor(.white)
                .scaleEffect(scale)
                .rotationEffect(Angle(degrees: rotation))
                .overlay(
                    sparkleView
                        .opacity(showSparkles ? 1 : 0)
                )
            }
            .disabled(viewModel.entryText.isEmpty || viewModel.isGeneratingStory)
        }
        .padding()
        .background(themeManager.selectedTheme.backgroundColor)
    }
    
    // MARK: - Sparkle Animation View
    private var sparkleView: some View {
        ZStack {
            ForEach(0..<8) { index in
                Circle()
                    .fill(sparkleColors[index % sparkleColors.count])
                    .frame(width: 8, height: 8)
                    .offset(sparkleOffsets.count > index ? sparkleOffsets[index] : .zero)
                    .opacity(showSparkles ? 0 : 1)
            }
        }
    }
    
    // MARK: - Genre Selector Overlay
    private var genreSelectorOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showGenreSelector = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("Choose Your Story Genre")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedTheme.textColor)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                    ForEach(NarrativeEngineConstants.genres.sorted(by: { $0.value < $1.value }), id: \.key) { key, value in
                        Button(action: {
                            viewModel.selectedGenre = key
                            withAnimation {
                                showGenreSelector = false
                            }
                        }) {
                            VStack {
                                Image(systemName: genreIcon(for: key))
                                    .font(.system(size: 30))
                                    .padding(.bottom, 5)
                                Text(value)
                                    .fontWeight(.medium)
                            }
                            .frame(minWidth: 120, minHeight: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedGenre == key ? 
                                          themeManager.selectedTheme.accentColor.opacity(0.2) : 
                                          themeManager.selectedTheme.cardBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(viewModel.selectedGenre == key ? 
                                                   themeManager.selectedTheme.accentColor : Color.clear, 
                                                   lineWidth: 2)
                                    )
                            )
                            .foregroundColor(viewModel.selectedGenre == key ?
                                            themeManager.selectedTheme.accentColor : themeManager.selectedTheme.textColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button(action: {
                    withAnimation {
                        showGenreSelector = false
                    }
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(themeManager.selectedTheme.accentColor)
                        )
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.selectedTheme.backgroundColor)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20)
            .padding(.horizontal, 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Generating Story Overlay
    private var generatingStoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                LottieView(name: "story-writing")
                    .frame(width: 200, height: 200)
                
                Text("Creating Your Story")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(viewModel.generationStep)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                
                ProgressView(value: viewModel.generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.selectedTheme.accentColor))
                    .frame(width: 250)
                    .animation(.easeInOut, value: viewModel.generationProgress)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Material.ultraThinMaterial)
                    )
            )
            .onChange(of: viewModel.chapter) { newChapter in
                if newChapter != nil && !viewModel.isGeneratingStory {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showGeneratedStory = true
                    }
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Generated Story Overlay
    private func generatedStoryOverlay(chapter: ChapterResponse) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    // Do nothing, prevent taps from passing through
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(NarrativeEngineConstants.genres[viewModel.selectedGenre] ?? "Story")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Your Personal Story")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showGeneratedStory = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                // Story text
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(chapter.text)
                            .foregroundColor(.white)
                            .lineSpacing(8)
                            .padding()
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Cliffhanger")
                                .font(.headline)
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                            
                            Text(chapter.cliffhanger)
                                .italic()
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 80)
                }
                
                // Footer with actions
                HStack(spacing: 20) {
                    Button(action: {
                        // Save to favorites logic would go here
                        withAnimation {
                            showGeneratedStory = false
                        }
                    }) {
                        VStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .padding(.bottom, 5)
                            Text("Save")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Share logic would go here
                        let textToShare = chapter.text
                        let av = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    }) {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .padding(.bottom, 5)
                            Text("Share")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Open map view
                        // This would navigate to the StoryMapView
                        withAnimation {
                            showGeneratedStory = false
                        }
                    }) {
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .padding(.bottom, 5)
                            Text("Story Map")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Continue writing logic
                        viewModel.clearEntry()
                        withAnimation {
                            showGeneratedStory = false
                        }
                    }) {
                        VStack {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20))
                                .padding(.bottom, 5)
                            Text("Continue")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
            .background(
                Image("story-background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.6))
                    .blur(radius: 2)
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20)
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Error Overlay
    private var errorOverlay: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(themeManager.selectedTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.selectedTheme.cardBackgroundColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                    )
                    .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Setup the sparkle animation
    private func setupSparkleAnimation() {
        // Initialize sparkle offsets
        var offsets: [CGSize] = []
        for _ in 0..<8 {
            offsets.append(.zero)
        }
        sparkleOffsets = offsets
        
        // Show sparkles
        showSparkles = true
        
        // Animate sparkles outward
        withAnimation(.easeOut(duration: 0.7)) {
            var newOffsets: [CGSize] = []
            for i in 0..<8 {
                let angle = Double(i) * (360.0 / 8.0) * .pi / 180.0
                let distance: CGFloat = 30
                let offset = CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                )
                newOffsets.append(offset)
            }
            sparkleOffsets = newOffsets
            
            // Fade out sparkles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showSparkles = false
                }
            }
        }
    }
    
    /// Get icon for genre
    private func genreIcon(for genre: String) -> String {
        switch genre {
        case "fantasy":
            return "wand.and.stars"
        case "scifi":
            return "airplane.circle"
        case "mystery":
            return "magnifyingglass"
        case "adventure":
            return "map"
        case "romance":
            return "heart"
        case "horror":
            return "theatermasks"
        case "historical":
            return "clock"
        case "comedy":
            return "face.smiling"
        default:
            return "book"
        }
    }
    
    /// Calculate word count
    private var wordCount: Int {
        viewModel.entryText.split(separator: " ").count
    }
}

// MARK: - Preview
struct NarrativeJournalView_Previews: PreviewProvider {
    static var previews: some View {
        NarrativeJournalView()
            .environmentObject(ThemeManager())
    }
}
