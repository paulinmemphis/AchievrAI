// StoryReadingView.swift
import SwiftUI

/// A view that presents all chapters in a continuous reading experience
struct StoryReadingView: View {
    let storyNodes: [StoryNode]
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedFontSize: CGFloat = 16
    @State private var showingSettings = false
    
    private let fontSizes: [CGFloat] = [14, 16, 18, 20, 22]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Your Personal Story")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
                
                // Chapters
                ForEach(storyNodes) { node in
                    chapterView(for: node)
                }
                
                // End mark
                Text("• • •")
                    .font(.title)
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(themeManager.selectedTheme.backgroundColor)
        .navigationTitle("Reading Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            readingSettingsView
        }
    }
    
    // View for a single chapter
    private func chapterView(for node: StoryNode) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chapter header
            HStack {
                Text("Chapter \(storyNodes.firstIndex(where: { $0.id == node.id })?.plus1 ?? 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(node.createdAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Chapter themes
            if !(node.metadataSnapshot?.themes?.isEmpty ?? true) {
                HStack {
                    ForEach((node.metadataSnapshot?.themes ?? []).prefix(3), id: \.self) { theme in
                        Text(theme)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                            )
                    }
                }
            }
            
            // Divider with sentiment indicator
            HStack {
                Circle()
                    .fill(sentimentColor(for: node.metadataSnapshot?.sentimentScore ?? 0))
                    .frame(width: 8, height: 8)
                
                Line()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                    .frame(height: 1)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 8)
            
            // Chapter text
            // StoryNode doesn't directly have a chapter property
            // We should retrieve the actual chapter using the chapterId
            // For now, using a placeholder
            Text("Chapter content for ID: \(node.chapterId)")
                .font(.system(size: selectedFontSize))
                .lineSpacing(selectedFontSize * 0.3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Reading settings view
    private var readingSettingsView: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Preferences")) {
                    VStack(alignment: .leading) {
                        Text("Font Size")
                            .font(.headline)
                        
                        HStack {
                            Text("A")
                                .font(.system(size: 14))
                            
                            Slider(value: $selectedFontSize, in: 14...22, step: 2)
                                .accentColor(themeManager.selectedTheme.accentColor)
                            
                            Text("A")
                                .font(.system(size: 22))
                        }
                        
                        // Font size presets
                        HStack {
                            ForEach(fontSizes, id: \.self) { size in
                                Button(action: {
                                    selectedFontSize = size
                                }) {
                                    Text("\(Int(size))")
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            selectedFontSize == size ?
                                            themeManager.selectedTheme.accentColor :
                                                Color(.tertiarySystemBackground)
                                        )
                                        .foregroundColor(selectedFontSize == size ? .white : .primary)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
    }
    
    // Helper to determine color based on sentiment
    private func sentimentColor(for sentimentScore: Double) -> Color {
        switch sentimentScore {
        case let x where x > 0.5:
            return .green
        case let x where x < -0.5:
            return .red
        default:
            return .purple // Default for neutral or unknown sentiment
        }
    }
}

// MARK: - Helper Extensions and Views

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

extension Int {
    var plus1: Int {
        return self + 1
    }
}

// MARK: - Preview
struct StoryReadingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoryReadingView(storyNodes: mockStoryNodes())
                .environmentObject(ThemeManager())
        }
    }
    
    // Create mock story nodes for preview
    private static func sentimentStringToScorePreview(_ sentiment: String) -> Double? {
        let lowercasedSentiment = sentiment.lowercased()
        if let numericScore = Double(lowercasedSentiment) {
            return numericScore
        }
        switch lowercasedSentiment {
        case "positive", "very positive": return 0.8
        case "neutral": return 0.0
        case "negative", "very negative": return -0.8
        default: return nil
        }
    }

    static func mockStoryNodes() -> [StoryNode] {
        let metadata1 = MetadataResponse(
            sentiment: "positive",
            themes: ["adventure", "discovery"],
            entities: ["forest", "mountain"],
            keyPhrases: ["ancient ruins"]
        )
        
        let metadata2 = MetadataResponse(
            sentiment: "tense",
            themes: ["danger", "mystery"],
            entities: ["cave", "stranger"],
            keyPhrases: ["strange sounds"]
        )
        
        let chapter1 = ChapterResponse(
            chapterId: "ch-1",
            text: "The forest floor crunched underfoot as Elara ventured deeper, the ancient map clutched in her hand. Strange symbols glowed faintly on the parchment, reacting to the proximity of the hidden grove. Suddenly, a twig snapped behind her, sharp and distinct in the unnerving silence.",
            cliffhanger: "A twig snapped behind her, sharp and distinct in the unnerving silence.",
            studentName: "Student",
            feedback: "Your journal entry inspired this exciting chapter!"
        )
        
        let chapter2 = ChapterResponse(
            chapterId: "ch-2",
            text: "Elara whirled around, hand instinctively reaching for the dagger at her belt. A tall figure stood partially obscured by shadow, watching her from between two ancient oaks. 'I've been expecting you,' the stranger said, voice unsettlingly calm. 'You have something that belongs to me.'",
            cliffhanger: "'You have something that belongs to me.'",
            studentName: "Student",
            feedback: "You're making wonderful progress in your learning journey!"
        )
        
        return [
            StoryNode(
                id: UUID().uuidString,
                journalEntryId: UUID().uuidString,
                chapterId: chapter1.chapterId,
                parentId: nil,
                metadataSnapshot: StoryMetadata(
                    sentimentScore: sentimentStringToScorePreview(metadata1.sentiment),
                    themes: metadata1.themes,
                    entities: metadata1.entities,
                    keyPhrases: metadata1.keyPhrases
                ),
                createdAt: Date()
            ),
            StoryNode(
                id: UUID().uuidString,
                journalEntryId: UUID().uuidString,
                chapterId: chapter2.chapterId,
                parentId: UUID().uuidString,
                metadataSnapshot: StoryMetadata(
                    sentimentScore: sentimentStringToScorePreview(metadata2.sentiment),
                    themes: metadata2.themes,
                    entities: metadata2.entities,
                    keyPhrases: metadata2.keyPhrases
                ),
                createdAt: Date()
            )
        ]
    }
}
