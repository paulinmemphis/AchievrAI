// NarrativeTutorialView.swift
import SwiftUI

struct NarrativeTutorialView: View {
    @Binding var showTutorial: Bool
    @State private var currentStep = 0
    @EnvironmentObject private var themeManager: ThemeManager
    
    let steps = [
        (title: "Your Journal, Your Story", 
         description: "Your journal entries are now transformed into chapters of your personal narrative.", 
         icon: "book.pages"),
        
        (title: "Sentiment Matters", 
         description: "The tone of your writing influences the direction of your story.", 
         icon: "waveform.path.ecg"),
        
        (title: "Growing Narrative", 
         description: "Each entry builds upon your story, creating a unique journey over time.", 
         icon: "arrow.triangle.branch")
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow tapping outside to dismiss
                    withAnimation {
                        showTutorial = false
                    }
                }
            
            // Tutorial card
            VStack(spacing: 24) {
                // Icon
                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                    .padding(.top)
                
                // Title
                Text(steps[currentStep].title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(steps[currentStep].description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? 
                                  themeManager.selectedTheme.accentColor : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Got it") {
                            withAnimation {
                                showTutorial = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            .transition(.opacity.combined(with: .scale))
        }
    }
}

// Preview provider
struct NarrativeTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        NarrativeTutorialView(showTutorial: .constant(true))
            .environmentObject(ThemeManager())
    }
}
