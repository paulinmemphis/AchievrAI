// TutorialOverlay.swift
// MetacognitiveJournal

import SwiftUI

struct TutorialOverlay: View {
    @Binding var isVisible: Bool
    @State private var step: Int = 0
    
    let steps: [TutorialStep] = [
        TutorialStep(
            title: "Start Journaling",
            description: "Tap here to add your first journal entry. You can use text or voice!",
            highlightRect: .journalButton
        ),
        TutorialStep(
            title: "View Insights",
            description: "See personalized emotional insights and feedback here.",
            highlightRect: .insightsTab
        ),
        TutorialStep(
            title: "Explore Your Story Map",
            description: "Visualize your learning journey as a story map.",
            highlightRect: .storyMapTab
        ),
        TutorialStep(
            title: "Need Help?",
            description: "Access help and settings from the menu.",
            highlightRect: .settingsMenu
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            VStack(spacing: 32) {
                Spacer()
                Group {
                    Text(steps[step].title)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)
                    Text(steps[step].description)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Button(action: {
                    if step < steps.count - 1 {
                        step += 1
                    } else {
                        isVisible = false
                    }
                }) {
                    Text(step < steps.count - 1 ? "Next" : "Done")
                        .font(.headline)
                        .padding()
                        .frame(minWidth: 150)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .improvedAccessibility(label: step < steps.count - 1 ? "Next" : "Done", hint: step < steps.count - 1 ? "Go to next tutorial step" : "Dismiss tutorial", traits: .isButton)
                Spacer()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isVisible)
        .improvedAccessibility(label: "App tutorial overlay", hint: "Guides you through the main features of the app.")
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let highlightRect: HighlightRect
}

enum HighlightRect {
    case journalButton, insightsTab, storyMapTab, settingsMenu
}
