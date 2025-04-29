import SwiftUI
import Combine

/// A premium reading experience for story chapters
struct NarrativeChapterView: View, JournalEntrySavable {
    // MARK: - Properties
    let chapter: Chapter
    let journalEntryId: String
    
    @State private var fontSize: CGFloat = 18
    @State private var readingMode: ReadingMode = .standard
    @State private var showChapterSettings = false
    @State private var showControls = true
    @State private var scrollOffset: CGFloat = 0
    @State private var showSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    // Journal store for saving entries
    @EnvironmentObject var journalStore: JournalStore
    
    // MARK: - Reading Modes
    enum ReadingMode: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case sepia = "Sepia"
        case night = "Night Mode"
        
        var id: String { rawValue }
        
        var backgroundColor: Color {
            switch self {
            case .standard: return .white
            case .sepia: return Color(red: 249/255, green: 241/255, blue: 228/255)
            case .night: return Color(red: 25/255, green: 25/255, blue: 30/255)
            }
        }
        
        var textColor: Color {
            switch self {
            case .standard: return .black
            case .sepia: return Color(red: 73/255, green: 54/255, blue: 41/255)
            case .night: return Color(red: 219/255, green: 219/255, blue: 219/255)
            }
        }
        
        var accentColor: Color {
            switch self {
            case .standard: return .blue
            case .sepia: return .brown
            case .night: return .purple
            }
        }
        
        var iconName: String {
            switch self {
            case .standard: return "sun.max"
            case .sepia: return "book.closed"
            case .night: return "moon"
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                readingBackground
                
                ScrollView {
                    GeometryReader { scrollGeometry in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: scrollGeometry.frame(in: .named("scrollView")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 30) {
                        chapterHeader
                        
                        chapterDivider
                            .padding(.bottom, 10)
                        
                        chapterContent
                        
                        cliffhangerSection
                        
                        chapterFooter
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                    .padding(.bottom, 100)
                    .animation(.easeOut, value: fontSize)
                }
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    scrollOffset = offset
                    withAnimation {
                        showControls = offset >= 0 || offset > scrollOffset
                    }
                }
                
                if showControls {
                    chapterControls
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if showChapterSettings {
                    settingsOverlay
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea()
            .statusBar(hidden: !showControls)
            .onTapGesture {
                withAnimation {
                    showControls.toggle()
                }
            }
            .alert("Journal Entry Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The story has been saved to your journal entries.")
            }
        }
    }
    
    // MARK: - Background
    private var readingBackground: some View {
        readingMode.backgroundColor
            .ignoresSafeArea()
    }
    
    // MARK: - Chapter Header
    private var chapterHeader: some View {
        VStack(spacing: 12) {
            Text(chapter.genre.uppercased())
                .font(.subheadline)
                .fontWeight(.semibold)
                .kerning(2)
                .foregroundColor(readingMode.textColor.opacity(0.6))
            
            Text("Chapter")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(readingMode.textColor)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(readingMode.textColor.opacity(0.7))
        }
        .padding(.vertical, 20)
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Chapter Divider
    private var chapterDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
            
            Image(systemName: "star.fill")
                .font(.caption)
            
            Rectangle()
                .frame(height: 1)
        }
        .foregroundColor(readingMode.textColor.opacity(0.4))
    }
    
    // MARK: - Chapter Content
    private var chapterContent: some View {
        Text(.init(chapter.text))
            .font(.system(size: fontSize))
            .lineSpacing(8)
            .foregroundColor(readingMode.textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 20)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Cliffhanger Section
    private var cliffhangerSection: some View {
        VStack(spacing: 15) {
            chapterDivider
            
            Text("The story continues...")
                .font(.headline)
                .foregroundColor(readingMode.textColor.opacity(0.8))
                .padding(.bottom, 10)
            
            Text(chapter.cliffhanger)
                .font(.system(size: fontSize))
                .italic()
                .foregroundColor(readingMode.textColor)
                .lineSpacing(8)
                .padding(.bottom, 20)
            
            Button {
                // Navigate to journal entry view to continue the story
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Continue Writing")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill($themeManager.selectedTheme.wrappedValue.accentColor)
                )
                .foregroundColor(.white)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Chapter Footer
    private var chapterFooter: some View {
        VStack(spacing: 20) {
            // Reading time indicator
            HStack {
                Image(systemName: "clock")
                Text("\(readingTimeMinutes) min read")
            }
            .font(.caption)
            .foregroundColor(readingMode.textColor.opacity(0.6))
            
            // Story map navigation
            Button {
                // Navigate to story map
            } label: {
                HStack {
                    Image(systemName: "map")
                    Text("View Story Map")
                }
                .font(.subheadline)
                .foregroundColor($themeManager.selectedTheme.wrappedValue.accentColor)
            }
            
            // Copyright
            Text("© \(Calendar.current.component(.year, from: Date())) AchievrAI - Your personal narrative journey")
                .font(.caption2)
                .foregroundColor(readingMode.textColor.opacity(0.4))
                .padding(.top, 10)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Chapter Controls
    private var chapterControls: some View {
        VStack {
            // Top navigation bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(readingMode.textColor)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(readingMode.backgroundColor.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        )
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        showChapterSettings.toggle()
                    }
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.headline)
                        .foregroundColor(readingMode.textColor)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(readingMode.backgroundColor.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        )
                }
                
                Button {
                    // Share functionality
                    let textToShare = chapter.text
                    let av = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                    // Get the window scene for iOS 15+
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(av, animated: true, completion: nil)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(readingMode.textColor)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(readingMode.backgroundColor.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        )
                }
                
                Button {
                    saveAsJournalEntry()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(readingMode.textColor)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(readingMode.backgroundColor.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            
            Spacer()
            
            // Progress indicator
            HStack {
                ProgressView(value: 0.5) // This should be dynamic based on reading progress
                    .progressViewStyle(LinearProgressViewStyle(tint: readingMode.accentColor))
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                Rectangle()
                    .fill(readingMode.backgroundColor.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
            )
        }
    }
    
    // MARK: - Settings Overlay
    private var settingsOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showChapterSettings = false
                    }
                }
            
            VStack(spacing: 25) {
                Text("Reading Settings")
                    .font(.headline)
                    .foregroundColor($themeManager.selectedTheme.wrappedValue.textColor)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Text Size")
                        .font(.subheadline)
                        .foregroundColor($themeManager.selectedTheme.wrappedValue.textColor.opacity(0.7))
                    
                    HStack {
                        Text("A")
                            .font(.system(size: 14))
                            .foregroundColor($themeManager.selectedTheme.wrappedValue.textColor)
                        
                        Slider(value: $fontSize, in: 14...24, step: 1)
                            .accentColor($themeManager.selectedTheme.wrappedValue.accentColor)
                        
                        Text("A")
                            .font(.system(size: 24))
                            .foregroundColor($themeManager.selectedTheme.wrappedValue.textColor)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Reading Mode")
                        .font(.subheadline)
                        .foregroundColor($themeManager.selectedTheme.wrappedValue.textColor.opacity(0.7))
                    
                    HStack(spacing: 15) {
                        ForEach(ReadingMode.allCases) { mode in
                            Button {
                                withAnimation {
                                    readingMode = mode
                                }
                            } label: {
                                VStack {
                                    Image(systemName: mode.iconName)
                                        .font(.system(size: 24))
                                        .foregroundColor(readingMode == mode ? 
                                                        $themeManager.selectedTheme.wrappedValue.accentColor : 
                                                        $themeManager.selectedTheme.wrappedValue.textColor)
                                        .padding(.bottom, 5)
                                    
                                    Text(mode.rawValue)
                                        .font(.caption)
                                        .foregroundColor(readingMode == mode ? 
                                                        $themeManager.selectedTheme.wrappedValue.accentColor : 
                                                        $themeManager.selectedTheme.wrappedValue.textColor)
                                }
                                .frame(width: 90, height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(mode.backgroundColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(readingMode == mode ? 
                                                       $themeManager.selectedTheme.wrappedValue.accentColor : 
                                                       Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                
                Button {
                    withAnimation {
                        showChapterSettings = false
                    }
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill($themeManager.selectedTheme.wrappedValue.accentColor)
                        )
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill($themeManager.selectedTheme.wrappedValue.backgroundColor)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20)
            .padding(.horizontal, 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Helper Properties
    /// Format the creation date
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: chapter.creationDate)
    }

    /// Calculate estimated reading time in minutes
    private var readingTimeMinutes: Int {
        let wordCount = chapter.text.split(separator: " ").count
        let averageWPM = 200 // Average adult reading speed
        let minutes = max(1, wordCount / averageWPM)
        return minutes
    }

    /// Saves the current chapter as a journal entry
    private func saveAsJournalEntry() {
        // Extract themes from the chapter if available
        let themes = chapter.genre.components(separatedBy: ",")
        
        // Create metadata from the chapter content
        let metadata = EntryMetadata(
            sentiment: "Positive", // You might want to analyze the text for sentiment
            themes: themes,
            entities: [],
            keyPhrases: []
        )
        
        // Create and save the journal entry using the protocol
        let entry = createJournalEntry(
            content: chapter.text,
            title: "Story Chapter: \(chapter.id)",
            subject: .english,
            emotionalState: .satisfied,
            summary: chapter.cliffhanger,
            metadata: metadata
        )
        
        // Save the entry to the journal store
        journalStore.saveEntry(entry)
        
        // Show confirmation
        showSaveConfirmation(for: entry.assignmentName)
    }
    
    // Show save confirmation alert
    func showSaveConfirmation(for entryTitle: String) {
        self.showSaveConfirmation = true
    }
}

// MARK: - Scroll Offset Key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct NarrativeChapterView_Previews: PreviewProvider {
    static var previews: some View {
        NarrativeChapterView(
            chapter: Chapter(
                id: "1",
                text: "Once upon a time in a world not unlike our own, there lived a person who dreamed of creating stories that moved hearts and minds...",
                cliffhanger: "But what they didn't know was that the greatest adventure was just about to begin...",
                genre: "fantasy",
                creationDate: Date()
            ),
            journalEntryId: "entry-1"
        )
        .environmentObject(ThemeManager())
    }
}
