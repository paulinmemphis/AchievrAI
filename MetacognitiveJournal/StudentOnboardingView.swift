// File: StudentOnboardingView.swift
// Robust onboarding for students

import SwiftUI

struct StudentOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @State private var email = ""
    private let pages = [
        ("Welcome, Student!", "This journal helps you reflect, grow, and get helpful feedback from AI."),
        ("How to Use", "Answer prompts honestly. Speak or type about your day, feelings, and learning."),
        ("Privacy Matters", "Your reflections are private and secure. Only you (and your teacher/parent if you choose) can see them."),
        ("Get Started!", "Ready to begin your journaling journey?")
    ]
    var body: some View {
        VStack {
            if page < pages.count {
                Spacer()
                OnboardingIllustrations.student
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                    .padding(.bottom, 8)
                Text(pages[page].0)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                Text(pages[page].1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                if page == 2 {
                    Link("Read our FAQ", destination: OnboardingSupportLinks.faqURL)
                        .font(.footnote)
                        .padding(.top, 8)
                }
                Spacer()
                HStack {
                    ForEach(0..<pages.count + 1, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom)
                if page < pages.count - 1 {
                    Button(action: { withAnimation { page += 1 } }) {
                        Text("Next")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                } else {
                    Button(action: { withAnimation { page += 1 } }) {
                        Text("Set Up Account")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
            } else {
                OnboardingAccountSetupView(email: $email, isComplete: $isComplete, role: "student")
            }
        }
        .padding()
    }
}

// To revisit onboarding from settings:
func presentStudentOnboarding() -> some View {
    StudentOnboardingView(isComplete: .constant(false))
}
