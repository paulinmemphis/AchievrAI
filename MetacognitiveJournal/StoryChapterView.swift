import SwiftUI

/// View for displaying a story chapter generated from journal entries
struct StoryChapterView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Properties
    let chapter: StoryChapter
    let childId: String
    let journalMode: ChildJournalMode
    let onContinueWriting: (() -> Void)?
    
    // MARK: - State
    @State private var animateTitle = false
    @State private var animateContent = false
    @State private var animateCliffhanger = false
    @State private var readingProgress: CGFloat = 0
    @State private var showingContinuePrompt = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            themeManager.themeForChildMode(journalMode).backgroundColor
                .ignoresSafeArea()
            
            // Content ScrollView
            contentScrollView
        }
        .onAppear(perform: setupAnimations)
        .navigationBarTitle("", displayMode: .inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingContinuePrompt) { continuePromptSheet }
    }
    
    // MARK: - View Components
    
    /// The main scrollable content area
    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                chapterTitleView
                decorativeDividerView
                chapterContentView
                cliffhangerView
                continueButtonView
            }
            .frame(maxWidth: 600) // Limit width for readability
            .padding(.horizontal)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollViewOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
            calculateReadingProgress(offset: value)
        }
    }
    
    /// Displays the chapter title with animation
    private var chapterTitleView: some View {
        Text(chapter.title)
            .font(fontForMode(size: 28, weight: .bold))
            .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 40)
            .opacity(animateTitle ? 1 : 0)
            .offset(y: animateTitle ? 0 : -20)
    }
    
    /// A decorative divider with a book icon
    private var decorativeDividerView: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.3))
            
            Image(systemName: "book.fill")
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.3))
        }
        .padding(.horizontal)
        .opacity(animateTitle ? 1 : 0) // Animate with title
    }
    
    /// Displays the main chapter content with animation
    private var chapterContentView: some View {
        Text(chapter.text)
            .font(fontForMode(size: 18))
            .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            .lineSpacing(8)
            .padding(.vertical)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
    }
    
    /// Displays the cliffhanger if it exists, with animation
    @ViewBuilder
    private var cliffhangerView: some View {
        if !chapter.cliffhanger.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                    Text("To be continued...")
                        .font(fontForMode(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                }
                
                Text(chapter.cliffhanger)
                    .font(fontForMode(size: 17, weight: .medium))
                    .italic()
                    .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor.opacity(0.8))
            }
            .padding()
            .background(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.1))
            .cornerRadius(10)
            .opacity(animateCliffhanger ? 1 : 0)
            .offset(y: animateCliffhanger ? 0 : 20)
        }
    }
    
    /// Displays the 'Continue Writing' button if a callback is provided
    @ViewBuilder
    private var continueButtonView: some View {
        if let onContinueWriting = onContinueWriting {
            Button(action: {
                showingContinuePrompt = true // Show prompt
            }) {
                HStack {
                    Image(systemName: "pencil.line")
                    Text("Continue Writing")
                }
                .font(fontForMode(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(themeManager.themeForChildMode(journalMode).accentColor)
                .cornerRadius(12)
            }
            .padding(.bottom, 40)
            .opacity(animateCliffhanger ? 1 : 0) // Animate with cliffhanger
        }
    }
    
    /// The content for the toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
            }
        }
    }
    
    /// The sheet presented when asking to continue
    private var continuePromptSheet: some View {
        VStack {
            Text("Continue your story?")
                .font(.title2).bold()
            Text("Would you like to start a new journal entry to continue the story?")
                .multilineTextAlignment(.center)
                .padding()
            Button("Yes, let's write!") { 
                showingContinuePrompt = false
                onContinueWriting?() // Call the original callback
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
            
            Button("Not now") {
                showingContinuePrompt = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    /// Sets up the staggered animations for view elements
    private func setupAnimations() {
        // Trigger animations
        withAnimation(.easeOut(duration: 0.5)) {
            animateTitle = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            animateContent = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            animateCliffhanger = true
        }
    }
    
    /// Calculates reading progress based on scroll offset
    private func calculateReadingProgress(offset: CGFloat) {
        // Needs adjustment based on actual content height for accurate progress
        // For now, just use offset as a proxy, max offset can be determined empirically
        // Or ideally, measure content height
        let progress = max(0, min(1, (-offset) / 1000)) // Simplified progress
        self.readingProgress = progress
    }
    
    // MARK: - Helper Methods
    
    private func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight, design: .default)
        }
    }
}

// MARK: - Preference Key for Scroll Position

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

struct StoryChapterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoryChapterView(
                chapter: StoryChapter(
                    chapterId: UUID().uuidString,
                    title: "The Courage Quest",
                    text: "In the magical land of Eldoria, Alex discovered a hidden power within.\n\nFear tried to take hold, but Alex stood firm. With a deep breath and determined heart, the impossible suddenly seemed possible. The ancient book had mentioned a test of courage, but Alex never imagined it would come in this form.\n\nThe forest grew darker as Alex ventured deeper. Each step forward was a victory against the whispers of doubt that tried to turn them back. Sometimes the greatest adventures begin with the smallest acts of bravery.",
                    cliffhanger: "But as the ancient spell began to glow, everything was about to change..."
                ),
                childId: "child1",
                journalMode: .middleChildhood,
                onContinueWriting: {}
            )
            .environmentObject(ThemeManager())
        }
    }
}
