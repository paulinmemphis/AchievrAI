// OnboardingPagerView.swift
// MetacognitiveJournal

import SwiftUI

/// A view that displays onboarding pages with a paging horizontal scroll
struct OnboardingPagerView: View {
    @Binding var currentPage: Int
    let pages: [OnboardingPage]
    var onFinish: () -> Void
    
    var body: some View {
        VStack {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                        .improvedAccessibility(label: pages[index].title, hint: pages[index].description, traits: .isHeader)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Navigation buttons
            HStack {
                // Back button (hidden on first page)
                Button(action: {
                    withAnimation {
                        currentPage = max(currentPage - 1, 0)
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title)
                        .foregroundColor(currentPage > 0 ? .blue : .gray.opacity(0.5))
                }
                .improvedAccessibility(label: "Back", hint: "Go to previous onboarding page", traits: .isButton)
                .disabled(currentPage == 0)
                
                Spacer()
                
                // Next/Finish button
                Button(action: {
                    withAnimation {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            // On last page, trigger finish action
                            onFinish()
                        }
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "checkmark")
                    }
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 150)
                    .background(pages[currentPage].backgroundColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .improvedAccessibility(label: currentPage < pages.count - 1 ? "Next" : "Get Started", hint: currentPage < pages.count - 1 ? "Go to next onboarding page" : "Finish onboarding and start using the app", traits: .isButton)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

/// A view for displaying a single onboarding page
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer(minLength: 30)
            
            // Page icon or image
            if UIImage(named: page.imageName) != nil {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .cornerRadius(10)
                    .padding(.horizontal)
            } else {
                // Fallback to system image
                Image(systemName: page.systemImage)
                    .font(.system(size: 80))
                    .foregroundColor(page.backgroundColor)
                    .padding()
                    .background(
                        Circle()
                            .fill(page.backgroundColor.opacity(0.2))
                            .frame(width: 160, height: 160)
                    )
            }
            
            // Title and description
            VStack(alignment: .center, spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(page.subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

/// A styled button for role selection in the onboarding flow
struct RoleSelectionButton: View {
    let role: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(color)
                    .padding()
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                    .padding(.bottom, 4)
                
                Text(role)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(minWidth: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// A custom button style that scales slightly when pressed
struct ScaleButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingPagerView(
        currentPage: .constant(0),
        pages: [
            OnboardingPage(
                title: "Welcome to AchievrAI",
                subtitle: "Your personal metacognitive journal",
                description: "AchievrAI helps you reflect on your learning, track your progress, and grow your metacognitive skills.",
                imageName: "onboarding-welcome",
                systemImage: "lightbulb.fill",
                backgroundColor: .blue
            ),
            OnboardingPage(
                title: "Capture Your Thoughts",
                subtitle: "Journal your learning experiences",
                description: "Use text or voice to record your thoughts, feelings, and reflections about your learning process.",
                imageName: "onboarding-journal",
                systemImage: "text.book.closed.fill",
                backgroundColor: .purple
            )
        ],
        onFinish: {}
    )
}
