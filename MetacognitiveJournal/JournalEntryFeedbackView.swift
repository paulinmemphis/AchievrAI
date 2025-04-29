import SwiftUI
import Combine
import Foundation

/// A view that displays a journal entry with adaptive feedback
struct JournalEntryFeedbackView: View {
    // MARK: - Environment
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Properties
    let journalEntry: JournalEntry
    let childId: String
    let journalMode: ChildJournalMode
    
    // MARK: - Services
    @ObservedObject var feedbackManager: AdaptiveFeedbackManager
    
    // MARK: - State
    @State private var feedback: AdaptiveFeedback?
    @State private var isLoadingFeedback = false
    @State private var showingFeedback = false
    @State private var showingChallenge = false
    @State private var selectedChallenge: MetacognitiveChallenge?
    @State private var showingSupport = false
    @State private var selectedSupport: LearningSupport?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Journal entry header
                    journalEntryHeader
                    
                    // Journal entry content
                    journalEntryContent
                    
                    // Feedback button
                    if feedback == nil && !isLoadingFeedback {
                        feedbackButton
                    }
                    
                    // Current challenge if one is selected
                    if let challenge = selectedChallenge {
                        currentChallengeView(challenge)
                    }
                    
                    // Current support if one is selected
                    if let support = selectedSupport {
                        currentSupportView(support)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            
            // Loading indicator
            if isLoadingFeedback {
                loadingView
            }
            
            // Feedback view as an overlay when showing
            if showingFeedback, let feedback = feedback {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Optional: tap outside to dismiss
                        // withAnimation { showingFeedback = false }
                    }
                
                AdaptiveFeedbackView(
                    feedback: feedback,
                    onChallengeAccepted: { challenge in
                        withAnimation {
                            selectedChallenge = challenge
                            showingFeedback = false
                        }
                    },
                    onSupportSelected: { support in
                        withAnimation {
                            selectedSupport = support
                            showingFeedback = false
                        }
                    },
                    onDismiss: {
                        withAnimation {
                            showingFeedback = false
                        }
                    }
                )
                .frame(maxWidth: 500)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Journal Entry")
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
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Journal Entry Header
    
    private var journalEntryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(journalEntry.assignmentName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            }
            
            // Mood
            HStack {
                Image(systemName: "face.smiling") // Consider using emotionalState.emoji here?
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                
                Text("Mood: \(journalEntry.emotionalState.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
            }
            
            Divider()
        }
    }
    
    // MARK: - Journal Entry Content
    
    private var journalEntryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Content
            Text(journalEntry.content)
                .font(.body)
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.selectedTheme.cardBackgroundColor)
                )
        }
    }
    
    // MARK: - Feedback Button
    
    private var feedbackButton: some View {
        Button(action: {
            generateFeedback()
        }) {
            HStack {
                Image(systemName: "lightbulb.fill")
                Text("Get Feedback")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.selectedTheme.accentColor)
            )
        }
        .padding(.vertical)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Creating personalized feedback...")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
        }
    }
    
    // MARK: - Challenge View
    
    private func currentChallengeView(_ challenge: MetacognitiveChallenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Current Challenge")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(challenge.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(challenge.targetSkill.color)
                
                Text(challenge.description)
                    .font(.body)
                    .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                
                HStack {
                    Image(systemName: challenge.targetSkill.iconName)
                        .foregroundColor(challenge.targetSkill.color)
                    
                    Text(challenge.targetSkill.childFriendlyName)
                        .font(.subheadline)
                        .foregroundColor(challenge.targetSkill.color)
                    
                    Spacer()
                    
                    Text("\(challenge.estimatedTimeMinutes) min")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                
                Button(action: {
                    withAnimation {
                        showingChallenge = true
                    }
                }) {
                    Text("View Challenge Details")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(challenge.targetSkill.color)
                        )
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(challenge.targetSkill.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(challenge.targetSkill.color, lineWidth: 1)
                            .opacity(0.5)
                    )
            )
        }
        .padding(.vertical)
    }
    
    // MARK: - Support View
    
    private func currentSupportView(_ support: LearningSupport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Learning Support")
                .font(.headline)
                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(support.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                HStack {
                    Image(systemName: support.supportType.iconName)
                        .foregroundColor(.blue)
                    
                    Text(support.supportType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    withAnimation {
                        showingSupport = true
                    }
                }) {
                    Text("View Support Details")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                            .opacity(0.5)
                    )
            )
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Methods
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: journalEntry.date)
    }
    
    private func generateFeedback() {
        isLoadingFeedback = true
        
        // Simulate network delay for demo purposes
        // In a real app, this would call the actual feedback generation API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            do {
                if let generatedFeedback = self.feedbackManager.generateFeedback(
                    for: self.journalEntry,
                    childId: self.childId,
                    mode: self.journalMode
                ) {
                    self.feedback = generatedFeedback
                    
                    withAnimation {
                        self.isLoadingFeedback = false
                        self.showingFeedback = true
                    }
                } else {
                    throw NSError(domain: "FeedbackError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Could not generate feedback for this entry."
                    ])
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingFeedback = false
                self.showingError = true
            }
        }
    }
}

// MARK: - Preview
struct JournalEntryFeedbackView_Previews: PreviewProvider {
    // Define static mock data needed for initialization
    static let mockChildId = UUID().uuidString
    static let mockJournalMode = ChildJournalMode.middleChildhood
    static let mockFeedbackManager = AdaptiveFeedbackManager() // Instantiate manager here

    static var previews: some View {
        NavigationView {
            // Sample Prompt Response for the mock entry
            let mockPromptResponse = PromptResponse(id: UUID(), prompt: "What did you learn?", response: "I learned how to solve multiplication problems.")
            
            // Mock JournalEntry using the correct initializer
            let mockEntry = JournalEntry(
                id: UUID(),
                assignmentName: "My Math Test",
                date: Date(),
                subject: .math,
                emotionalState: .satisfied,
                reflectionPrompts: [mockPromptResponse],
                aiSummary: "The user felt nervous but proud after applying strategies during a math test.", // Optional
                transcription: nil, // Optional
                audioURL: nil // Optional
            )
            
            // Initialize the view with the mock entry and a feedback manager
            JournalEntryFeedbackView(
                journalEntry: mockEntry,
                childId: mockChildId,          // Use static property
                journalMode: mockJournalMode,   // Use static property
                feedbackManager: mockFeedbackManager // Use static property
            )
            // Add environment objects needed by the view and its subcomponents
            .environmentObject(ThemeManager())
        }
    }
}
