import SwiftUI

// Extension for the insights and review step views
extension GuidedMultiModalJournalView {
    
    // MARK: - Insights Step
    
    /// The AI insights view
    var insightsView: some View {
        VStack(spacing: 20) {
            // Insights header
            Text("Journal Insights")
                .font(viewModel.fontForMode(size: 22, weight: .bold))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
            
            // Loading state
            if viewModel.isGeneratingInsights {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Generating insights from your journal entry...")
                        .font(viewModel.fontForMode(size: 16))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            } else {
                // Insights content
                VStack(alignment: .leading, spacing: 16) {
                    // Light bulb icon
                    HStack {
                        Spacer()
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        Spacer()
                    }
                    .padding(.bottom)
                    
                    // Insights text
                    Text(viewModel.adaptTextForReadingLevel(viewModel.aiInsights))
                        .font(viewModel.fontForMode(size: 16))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Error message if applicable
                    if let error = viewModel.aiError {
                        Text("Note: There was an issue generating detailed insights. These are simplified insights based on your entry.")
                            .font(viewModel.fontForMode(size: 14))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Regenerate button
                Button(action: {
                    Task {
                        await viewModel.generateInsights()
                    }
                }) {
                    Label("Regenerate Insights", systemImage: "arrow.clockwise")
                        .padding()
                        .foregroundColor(.white)
                        .background(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                        .cornerRadius(8)
                }
                .padding(.top)
            }
            
            // Age-appropriate explanation
            VStack(alignment: .leading, spacing: 8) {
                Text("What are insights?")
                    .font(viewModel.fontForMode(size: 16, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                
                Text(insightsExplanationForAge())
                    .font(viewModel.fontForMode(size: 14))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    /// Age-appropriate explanation of insights
    func insightsExplanationForAge() -> String {
        switch viewModel.journalMode {
        case .earlyChildhood:
            return "Insights are special thoughts about what you wrote. They help you notice important things about your feelings and ideas!"
            
        case .middleChildhood:
            return "Insights are observations about your journal entry that help you understand your thoughts and feelings better. They can show you patterns in how you learn and think."
            
        case .adolescent:
            return "Insights are reflective observations derived from analyzing your journal entry. They can reveal patterns in your thinking, emotional responses, and learning strategies that might not be immediately obvious."
        }
    }
    
    // MARK: - Review Step
    
    /// The review view for the completed journal entry
    var reviewView: some View {
        VStack(spacing: 20) {
            // Review header
            Text(viewModel.adaptTextForReadingLevel(viewModel.getReviewPrompt()))
                .font(viewModel.fontForMode(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                .padding()
            
            // Entry summary card
            VStack(alignment: .leading, spacing: 16) {
                // Title and date
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.entryTitle)
                            .font(viewModel.fontForMode(size: 20, weight: .bold))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                        
                        Text(formattedDate(Date()))
                            .font(viewModel.fontForMode(size: 14))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Emotion badge if available
                    if let emotion = viewModel.selectedEmotion {
                        emotionBadge(emotion)
                    }
                }
                
                Divider()
                
                // Prompt responses summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Reflections:")
                        .font(viewModel.fontForMode(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    
                    ForEach(viewModel.currentPrompts) { prompt in
                        if let response = viewModel.promptResponses[prompt.id], !response.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prompt.text)
                                    .font(viewModel.fontForMode(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                                
                                Text(response)
                                    .font(viewModel.fontForMode(size: 14))
                                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Media items summary if available
                if !viewModel.entry.mediaItems.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Media Items:")
                            .font(viewModel.fontForMode(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.entry.mediaItems) { item in
                                    mediaItemPreview(for: item)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 120)
                    }
                }
                
                // Insights summary
                if !viewModel.aiInsights.isEmpty && viewModel.aiInsights != "Complete your journal entry to generate insights." {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text("Key Insight:")
                                .font(viewModel.fontForMode(size: 16, weight: .semibold))
                                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                        }
                        
                        // Extract first insight bullet point
                        let firstInsight = viewModel.aiInsights
                            .components(separatedBy: "•")
                            .dropFirst() // Skip intro text
                            .first?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Great reflection!"
                        
                        Text(firstInsight)
                            .font(viewModel.fontForMode(size: 14))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                            .lineLimit(3)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Completion message
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                
                Text(completionMessageForAge())
                    .font(viewModel.fontForMode(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
            }
            .padding()
        }
    }
    
    /// Emotion badge view
    internal func emotionBadge(_ emotion: MultiModal.Emotion) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(moodColor(for: emotion.category)))
                .frame(width: 12, height: 12)
            
            Text(emotion.name)
                .font(viewModel.fontForMode(size: 14, weight: .medium))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
    
    /// Color for emotion category
    func moodColor(for category: String) -> UIColor {
        switch category.lowercased() {
        case "joy", "happiness", "excited":
            return .systemYellow
        case "sadness", "disappointed":
            return .systemBlue
        case "anger", "frustrated":
            return .systemRed
        case "fear", "anxious", "nervous":
            return .systemPurple
        case "surprise", "curious":
            return .systemOrange
        default:
            return .systemGray
        }
    }
    
    /// Age-appropriate completion message
    func completionMessageForAge() -> String {
        switch viewModel.journalMode {
        case .earlyChildhood:
            return "Awesome job! You finished your journal entry. Your thoughts and feelings are important!"
            
        case .middleChildhood:
            return "Great work completing your journal entry! Reflecting on your experiences helps you learn and grow."
            
        case .adolescent:
            return "Well done on completing this reflective exercise. Regular journaling builds metacognitive skills that support your learning and personal development."
        }
    }
    
    /// Format date for display
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
