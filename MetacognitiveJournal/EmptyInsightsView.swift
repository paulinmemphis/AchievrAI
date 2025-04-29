//
//  EmptyInsightsView.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

import SwiftUI

struct EmptyInsightsView: View {
    @State private var isAnimating = false
    @State private var showTip = false
    @EnvironmentObject var journalStore: JournalStore
    
    // Random tips for journaling
    private let journalingTips = [
        "Try journaling at the same time each day to build a habit.",
        "Focus on your emotions and how they affected your thinking.",
        "Reflect on what you learned today, not just what you did.",
        "Ask yourself: What challenged me today? How did I respond?",
        "Consider writing about your goals and progress toward them."
    ]
    
    // Get a random tip
    private var randomTip: String {
        journalingTips.randomElement() ?? journalingTips[0]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .opacity(isAnimating ? 1.0 : 0.6)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .shadow(color: .blue.opacity(0.3), radius: isAnimating ? 10 : 5, x: 0, y: 0)
                .accessibilityHidden(true)
                .padding(.bottom, 10)
            
            // Main message
            Text("Insights Coming Soon")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            // Explanation
            Text("You need at least \(AppConstants.minimumEntriesForAnalysis) journal entries to see personalized learning insights.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            
            // Progress indicator
            HStack(spacing: 15) {
                Text("\(journalStore.entries.count)/\(AppConstants.minimumEntriesForAnalysis) Entries")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                ProgressView(value: Double(journalStore.entries.count), total: Double(AppConstants.minimumEntriesForAnalysis))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 120)
            }
            .padding(.vertical, 5)
            
            // Call to action button
            Button(action: {
                // This should navigate to the journal entry creation screen
                // For now, we'll just toggle the tip
                withAnimation {
                    showTip.toggle()
                }
            }) {
                Text("Create New Entry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            // Journaling tip
            if showTip {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Journaling Tip:")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(randomTip)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.top, 15)
                .padding(.horizontal, 20)
                .transition(.opacity)
            }
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            // Start animation when view appears
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
struct EmptyInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyInsightsView()
            .environmentObject(JournalStore())
            .preferredColorScheme(.light)
        
        EmptyInsightsView()
            .environmentObject(JournalStore())
            .preferredColorScheme(.dark)
    }
}