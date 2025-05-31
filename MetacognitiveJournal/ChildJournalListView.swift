import SwiftUI

/// View that displays a list of journal entries for a child with adaptive feedback
struct ChildJournalListView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Properties
    let childId: String
    let journalMode: ChildJournalMode
    let feedbackManager: AdaptiveFeedbackManager
    
    // MARK: - State
    @State private var journalEntries: [JournalEntry] = []
    @State private var selectedEntry: JournalEntry?
    @State private var showingEntryDetail = false
    @State private var showingNewEntry = false
    @State private var isLoading = true
    @State private var showingStoryView = false
    @State private var animateEntries = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.themeForChildMode(journalMode).backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if isLoading {
                    loadingView
                } else if journalEntries.isEmpty {
                    emptyStateView
                } else {
                    journalListView
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadJournalEntries()
        }
        .sheet(isPresented: $showingNewEntry) {
            // In a real app, this would be your journal entry creation view
            Text("New Journal Entry View")
                .onDisappear {
                    loadJournalEntries()
                }
        }
        .sheet(isPresented: $showingEntryDetail) {
            if let entry = selectedEntry {
                NavigationView {
                    JournalEntryFeedbackView(
                        journalEntry: entry,
                        childId: childId,
                        journalMode: journalMode,
                        feedbackManager: feedbackManager
                    )
                }
            }
        }
        .sheet(isPresented: $showingStoryView) {
            // In a real app, this would be your story view
            Text("Story View")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("My Journal")
                    .font(fontForMode(size: 28, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingStoryView = true
                }) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.2))
                        )
                }
                
                Button(action: {
                    showingNewEntry = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Journal prompt
            journalPromptView
        }
        .background(
            Rectangle()
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 3)
        )
    }
    
    // MARK: - Journal Prompt
    
    private var journalPromptView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Prompt:")
                .font(fontForMode(size: 16, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            
            Text(dailyPrompt)
                .font(fontForMode(size: 18))
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.themeForChildMode(journalMode).backgroundColor)
                )
            
            Button(action: {
                showingNewEntry = true
            }) {
                Text("Write about this")
                    .font(fontForMode(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.themeForChildMode(journalMode).accentColor)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
        )
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading your journal...")
                .font(fontForMode(size: 16))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book")
                .font(.system(size: 60))
                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.6))
            
            Text("Your journal is empty")
                .font(fontForMode(size: 20, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            
            Text("Start writing to see your thoughts come to life!")
                .font(fontForMode(size: 16))
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingNewEntry = true
            }) {
                Text("Write First Entry")
                    .font(fontForMode(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.themeForChildMode(journalMode).accentColor)
                    )
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Journal List View
    
    private var journalListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(journalEntries.enumerated()), id: \.element.id) { index, entry in
                    journalEntryCard(entry, index: index)
                        .opacity(animateEntries ? 1 : 0)
                        .offset(y: animateEntries ? 0 : 20)
                        .animation(
                            Animation.spring().delay(Double(index) * 0.05),
                            value: animateEntries
                        )
                }
            }
            .padding()
        }
        .onAppear {
            // Animate entries in when they appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateEntries = true
            }
        }
    }
    
    // MARK: - Journal Entry Card
    
    private func journalEntryCard(_ entry: JournalEntry, index: Int) -> some View {
        Button(action: {
            selectedEntry = entry
            showingEntryDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title and date
                HStack {
                    Text(entry.assignmentName)
                        .font(fontForMode(size: 18, weight: .bold))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    
                    Spacer()
                    
                    Text(formattedDate(entry.date))
                        .font(fontForMode(size: 12))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                }
                
                // Mood
                HStack {
                    Image(systemName: "face.smiling") // Use a representative icon
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    
                    Text("Feeling: \(entry.emotionalState.rawValue)")
                        .font(fontForMode(size: 14))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                }
                
                // Content preview
                Text(entry.transcription ?? "")
                    .font(fontForMode(size: 14))
                    .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    .lineLimit(3)
                    .padding(.vertical, 4)
                
                // Feedback indicator
                if hasFeedback(for: entry) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Has feedback")
                            .font(fontForMode(size: 12))
                            .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    }
                    .padding(.top, 4)
                }
                
                // Story chapter indicator
                if hasStoryChapter(for: entry) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.purple)
                        
                        Text("Added to your story")
                            .font(fontForMode(size: 12))
                            .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func loadJournalEntries() {
        isLoading = true
        
        // Simulate loading journal entries
        // In a real app, this would fetch from a database or API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.journalEntries = sampleJournalEntries
            self.isLoading = false
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func hasFeedback(for entry: JournalEntry) -> Bool {
        // In a real app, this would check if feedback exists for this entry
        return entry.id.hashValue % 2 == 0 // Just for demo purposes
    }
    
    private func hasStoryChapter(for entry: JournalEntry) -> Bool {
        // In a real app, this would check if a story chapter exists for this entry
        return entry.id.hashValue % 3 == 0 // Just for demo purposes
    }
    
    private func fontForMode(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch journalMode {
        case .earlyChildhood, .middleChildhood:
            return .system(size: size, weight: weight, design: .rounded)
        case .adolescent:
            return .system(size: size, weight: weight)
        }
    }
    
    // MARK: - Sample Data
    
    private var dailyPrompt: String {
        let prompts = [
            "What made you feel proud today?",
            "What was challenging for you today and how did you handle it?",
            "What's something new you learned today?",
            "How did you help someone today?",
            "What's something you want to improve at?"
        ]
        
        return prompts[Int.random(in: 0..<prompts.count)]
    }
    
    private var sampleJournalEntries: [JournalEntry] {
        [
            JournalEntry(
                id: UUID(),
                assignmentName: "My Math Test",
                date: Date().addingTimeInterval(-86400), // Yesterday
                subject: .math,
                emotionalState: .satisfied, // Corresponds to 'Proud'
                reflectionPrompts: [
                    PromptResponse(id: UUID(), prompt: "How did you feel before the test?", response: "A bit nervous."),
                    PromptResponse(id: UUID(), prompt: "What strategy did you use?", response: "Deep breathing and breaking down problems.")
                ],
                aiSummary: "The user felt nervous before a math test but used coping strategies like deep breathing and problem decomposition. They felt proud of their effort.",
                aiTone: "Positive, Reflective",
                transcription: nil,
                audioURL: nil,
                metadata: nil
            ),
            JournalEntry(
                id: UUID(),
                assignmentName: "Argument with My Friend",
                date: Date().addingTimeInterval(-172800), // 2 days ago
                subject: .socialStudies, // Or perhaps .other("Social Skills")
                emotionalState: .frustrated, // Mixed might map to frustrated or overwhelmed
                reflectionPrompts: [
                    PromptResponse(id: UUID(), prompt: "What happened during recess?", response: "My friend wouldn't share the ball."),
                    PromptResponse(id: UUID(), prompt: "How did you handle your anger?", response: "Took deep breaths and used my words.")
                ],
                aiSummary: "The user experienced conflict with a friend over sharing. They initially felt angry but managed their emotions using breathing techniques and communication, leading to a resolution.",
                aiTone: "Reflective, Resolved",
                transcription: nil,
                audioURL: nil,
                metadata: nil
            ),
            JournalEntry(
                id: UUID(),
                assignmentName: "Science Project",
                date: Date().addingTimeInterval(-259200), // 3 days ago
                subject: .science,
                emotionalState: .curious, // 'Excited' maps well to curious
                reflectionPrompts: [
                    PromptResponse(id: UUID(), prompt: "What is your project about?", response: "Growing plants."),
                    PromptResponse(id: UUID(), prompt: "What is a potential challenge?", response: "Remembering to measure daily.")
                ],
                aiSummary: "The user is excited about starting a science project on plants. They have planned the steps and identified potential challenges, like daily measurements, setting reminders to manage it.",
                aiTone: "Enthusiastic, Proactive",
                transcription: nil,
                audioURL: nil,
                metadata: nil
            ),
            // Add more sample entries if needed, following the standard JournalEntry structure
        ]
    }
}

// MARK: - Preview
struct ChildJournalListView_Previews: PreviewProvider {
    static var previews: some View {
        ChildJournalListView(
            childId: "child1",
            journalMode: .middleChildhood,
            feedbackManager: AdaptiveFeedbackManager()
        )
        .environmentObject(ThemeManager())
        .environmentObject(StoryPersistenceManager.preview)
        .environmentObject(AdaptiveFeedbackManager())
    }
}
