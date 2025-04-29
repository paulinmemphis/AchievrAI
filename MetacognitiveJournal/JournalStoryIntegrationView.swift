import SwiftUI
import Combine

/// View that integrates journal feedback with story generation
struct JournalStoryIntegrationView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Properties
    let journalEntry: JournalEntry
    let childId: String
    let journalMode: ChildJournalMode
    
    // MARK: - State
    @State private var feedback: AdaptiveFeedback?
    @State private var storyChapter: StoryChapter?
    @State private var isLoading = true
    @State private var showingFeedback = false
    @State private var showingStoryChapter = false
    @State private var processingStage = 0
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var animateContent = false
    
    // MARK: - Services
    private let coordinator = StoryFeedbackCoordinator.shared
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            themeManager.themeForChildMode(journalMode).backgroundColor
                .ignoresSafeArea()
            
            // Main content
            if isLoading {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : -20)
                        
                        // Journal entry summary
                        journalSummaryView
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Feedback preview if available
                        if let feedback = feedback {
                            feedbackPreviewView(feedback)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        
                        // Story chapter preview if available
                        if let chapter = storyChapter {
                            storyChapterPreviewView(chapter)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                    .frame(maxWidth: 600)
                }
            }
        }
        .navigationTitle("Journal Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                }
            }
        }
        .sheet(isPresented: $showingFeedback) {
            if let feedback = feedback {
                NavigationView {
                    ZStack {
                        themeManager.themeForChildMode(journalMode).backgroundColor
                            .ignoresSafeArea()
                        
                        AdaptiveFeedbackView(
                            feedback: feedback,
                            onChallengeAccepted: { _ in
                                showingFeedback = false
                            },
                            onSupportSelected: { _ in
                                showingFeedback = false
                            },
                            onDismiss: {
                                showingFeedback = false
                            }
                        )
                        .padding()
                    }
                    .navigationTitle("Feedback")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingFeedback = false
                            }) {
                                Text("Close")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingStoryChapter) {
            if let chapter = storyChapter {
                NavigationView {
                    StoryChapterView(
                        chapter: chapter,
                        childId: childId,
                        journalMode: journalMode,
                        onContinueWriting: {
                            showingStoryChapter = false
                            // In a real app, this would navigate to a new journal entry view
                        }
                    )
                }
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            processJournalEntry()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                if processingStage == 0 {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                } else if processingStage == 1 {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                }
            }
            
            // Processing text
            Text(processingStageText)
                .font(.headline)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .multilineTextAlignment(.center)
            
            // Progress indicator
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            // Processing details
            Text(processingStageDetails)
                .font(.subheadline)
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Journal Entry")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Journal Summary View
    
    private var journalSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(journalEntry.assignmentName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
            
            // Mood - Always display as emotionalState is non-optional
            HStack {
                // Placeholder for emotion display
                Image(systemName: "face.smiling")
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                Text("Emotion: \(journalEntry.emotionalState.rawValue)") // Display raw value for now
                    .font(.subheadline)
                    .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
            }
            
            // Content preview
            Text(journalEntry.content)
                .font(.body)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .lineLimit(4)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                )
            
            // Themes if available
            if let themes = journalEntry.metadata?.themes, !themes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(themeManager.themeForChildMode(journalMode).accentColor.opacity(0.2))
                                )
                                .foregroundColor(themeManager.themeForChildMode(journalMode).accentColor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).backgroundColor)
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Feedback Preview View
    
    private func feedbackPreviewView(_ feedback: AdaptiveFeedback) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: feedback.feedbackType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(feedback.feedbackType.color)
                    )
                    .shadow(radius: 2)
                
                VStack(alignment: .leading) {
                    Text("Feedback")
                        .font(.headline)
                        .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    
                    Text(feedbackTypeTitle(feedback.feedbackType))
                        .font(.subheadline)
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                }
                
                Spacer()
            }
            
            // Content preview
            Text(feedback.content)
                .font(.body)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .lineLimit(3)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(feedback.feedbackType.color.opacity(0.1))
                )
            
            // View full feedback button
            Button(action: {
                showingFeedback = true
            }) {
                Text("View Full Feedback")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(feedback.feedbackType.color)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Story Chapter Preview View
    
    private func storyChapterPreviewView(_ chapter: StoryChapter) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.purple)
                    )
                    .shadow(radius: 2)
                
                VStack(alignment: .leading) {
                    Text("Story Chapter")
                        .font(.headline)
                        .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                    
                    Text("Your journal entry inspired this chapter")
                        .font(.subheadline)
                        .foregroundColor(themeManager.themeForChildMode(journalMode).secondaryTextColor)
                }
                
                Spacer()
            }
            
            // Chapter title
            Text(chapter.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .padding(.top, 8)
            
            // Content preview
            Text(chapter.text.components(separatedBy: "\n\n").first ?? "")
                .font(.body)
                .foregroundColor(themeManager.themeForChildMode(journalMode).primaryTextColor)
                .lineLimit(3)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                )
            
            // Cliffhanger preview
            Text("Cliffhanger: \(chapter.cliffhanger)")
                .font(.subheadline)
                .italic()
                .foregroundColor(Color.purple)
                .padding(.horizontal)
            
            // View full chapter button
            Button(action: {
                showingStoryChapter = true
            }) {
                Text("Read Full Chapter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.themeForChildMode(journalMode).cardBackgroundColor)
                .shadow(radius: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: journalEntry.date)
    }
    
    private var processingStageText: String {
        switch processingStage {
        case 0:
            return "Analyzing your journal entry..."
        case 1:
            return "Creating personalized feedback..."
        case 2:
            return "Generating your story chapter..."
        default:
            return "Processing..."
        }
    }
    
    private var processingStageDetails: String {
        switch processingStage {
        case 0:
            return "We're looking at the thoughts and feelings in your journal entry to understand what matters to you."
        case 1:
            return "Based on your entry, we're creating personalized feedback to help you grow and learn."
        case 2:
            return "Your journal entry is inspiring the next chapter in your personalized story adventure!"
        default:
            return "Almost done..."
        }
    }
    
    private func feedbackTypeTitle(_ type: FeedbackType) -> String {
        switch type {
        case .encouragement:
            return "Keep Going!"
        case .metacognitiveInsight:
            return "Thinking Insight"
        case .emotionalAwareness:
            return "Emotional Awareness"
        case .growthOpportunity:
            return "Growth Opportunity"
        case .strategyRecommendation:
            return "Strategy Suggestion"
        case .celebrationOfProgress:
            return "Celebration!"
        case .reflectionPrompt:
            return "Think About This"
        case .supportiveIntervention:
            return "Learning Support"
        }
    }
    
    private func processJournalEntry() {
        isLoading = true
        
        // Simulate the processing stages with delays
        // In a real app, these would be actual API calls
        
        // Stage 1: Analyzing
        processingStage = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Stage 2: Creating feedback
            self.processingStage = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Stage 3: Generating story
                self.processingStage = 2
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // Process the journal entry using the coordinator
                    self.coordinator.processJournalEntry(
                        entry: self.journalEntry,
                        childId: self.childId,
                        journalMode: self.journalMode
                    ) { result in
                        switch result {
                        case .success(let (feedback, chapter)):
                            self.feedback = feedback
                            self.storyChapter = chapter
                            
                            // Finish loading and animate content in
                            self.isLoading = false
                            withAnimation(.easeOut(duration: 0.8)) {
                                self.animateContent = true
                            }
                            
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                            self.isLoading = false
                            self.showingError = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct JournalStoryIntegrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JournalStoryIntegrationView(
                journalEntry: JournalEntry(
                    id: UUID(),
                    assignmentName: "My Math Test",
                    date: Date(),
                    subject: .math,
                    emotionalState: .satisfied,
                    reflectionPrompts: []
                ),
                childId: "child1",
                journalMode: .middleChildhood
            )
            .environmentObject(ThemeManager())
            // .environmentObject(UserSettings()) // Commented out - Cannot find in scope
        }
    }
}
