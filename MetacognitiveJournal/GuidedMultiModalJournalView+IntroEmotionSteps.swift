import SwiftUI

// Extension for the introduction and emotion step views
extension GuidedMultiModalJournalView {
    
    // MARK: - Introduction Step
    
    /// The introduction view shown as the first step
    var introductionView: some View {
        VStack(spacing: 20) {
            // Welcome image
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                .padding()
            
            // Welcome text
            Text(viewModel.adaptTextForReadingLevel(viewModel.getIntroductionText()))
                .font(viewModel.fontForMode(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20) // Increased horizontal padding
                .padding(.bottom, 16)     // Increased bottom padding
            
            // Journal steps preview
            VStack(alignment: .leading, spacing: 12) {
                Text("In this journal entry, you'll:")
                    .font(viewModel.fontForMode(size: 16, weight: .bold))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                
                ForEach(GuidedMultiModalJournalViewModel.JournalStep.allCases.dropFirst(), id: \.self) { step in
                    HStack(spacing: 12) {
                        Image(systemName: step.systemImage)
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                        
                        Text(step.title)
                            .font(viewModel.fontForMode(size: 16))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Emotion Step
    
    /// The emotion selection view
    var emotionView: some View {
        VStack(spacing: 20) {
            // Emotion prompt
            Text(viewModel.adaptTextForReadingLevel(viewModel.getEmotionPrompt()))
                .font(viewModel.fontForMode(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                .padding()
            
            // Current emotion display
            if let selectedEmotion = viewModel.selectedEmotion {
                VStack(spacing: 8) {
                    Text("You selected:")
                        .font(viewModel.fontForMode(size: 16))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                    
                    Text(selectedEmotion.name)
                        .font(viewModel.fontForMode(size: 24, weight: .bold))
                        .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).primaryTextColor)
                    
                    // Emotion intensity indicator
                    HStack {
                        Text("Intensity:")
                            .font(viewModel.fontForMode(size: 14))
                            .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                        
                        // Intensity bars
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Rectangle()
                                    .fill(i <= selectedEmotion.intensity ? 
                                          Color(moodColor(for: selectedEmotion.category)) : 
                                          Color(.systemGray4))
                                    .frame(width: 20, height: 10)
                                    .cornerRadius(2)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Text("No emotion selected yet")
                    .font(viewModel.fontForMode(size: 16))
                    .foregroundColor(themeManager.themeForChildMode(viewModel.journalMode).secondaryTextColor)
                    .padding()
            }
            
            // Button to open emotion picker
            Button(action: {
                self.showingEmotionPickerSheet = true
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text(viewModel.selectedEmotion == nil ? "Select Emotion" : "Change Emotion")
                }
                .padding()
                .foregroundColor(.white)
                .background(themeManager.themeForChildMode(viewModel.journalMode).accentColor)
                .cornerRadius(8)
            }
            .padding(.top)
        }
    }
    
    // Use the moodColor function from GuidedMultiModalJournalView+InsightsReviewSteps.swift
}
