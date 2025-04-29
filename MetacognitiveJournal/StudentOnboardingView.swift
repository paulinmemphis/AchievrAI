// File: StudentOnboardingView.swift
// Robust onboarding for students

import SwiftUI

struct StudentOnboardingView: View {
    @Binding var isComplete: Bool
    var ageGroup: AgeGroup = .child
    @State private var page = 0
    @State private var email = ""
    
    private var pages: [(String, String)] {
        switch ageGroup {
        case .child:
            return [
                ("Hi there! 👋", "This journal is your safe place to write or talk about your day and feelings."),
                ("It’s Fun!", "You can draw, write, or use your voice. Grown-ups can help if you want!"),
                ("Safe & Private", "Only you and your parent/teacher can see your journal. Ready to start?"),
                ("Let’s Go!", "Tap below to begin your adventure!")
            ]
        case .teen:
            return [
                ("Welcome!", "This journal is for your thoughts, feelings, and growth—powered by AI just for you."),
                ("How it Works", "Be honest and real. Your reflections are private unless you choose to share."),
                ("Privacy & Control", "You control your data. Learn more about privacy anytime."),
                ("Ready?", "Let’s get started with your first entry!")
            ]
        default:
            return [
                ("Welcome, Student!", "This journal helps you reflect, grow, and get helpful feedback from AI."),
                ("How to Use", "Answer prompts honestly. Speak or type about your day, feelings, and learning."),
                ("Privacy Matters", "Your reflections are private and secure. Only you (and your teacher/parent if you choose) can see them."),
                ("Get Started!", "Ready to begin your journaling journey?")
            ]
        }
    }
    
    private var illustration: Image {
        switch ageGroup {
        case .child: return Image(systemName: "face.smiling")
        case .teen: return Image(systemName: "person.crop.circle.badge.checkmark")
        default: return OnboardingIllustrations.student
        }
    }
    
    private var buttonText: String {
        if page < pages.count - 1 {
            return "Next"
        } else {
            switch ageGroup {
            case .child: return "Let’s Go!"
            case .teen: return "Start Journaling"
            default: return "Set Up Account"
            }
        }
    }
    
    var body: some View { 
        VStack {
            if page < pages.count {
                Spacer()
                illustration
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
                if page == 2 && ageGroup != .child {
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
                Button(action: { withAnimation { page += 1 } }) {
                    Text(buttonText)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            } else {
                if ageGroup == .child {
                    // For children, skip account setup and complete onboarding
                    VStack(spacing: 24) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        Text("You’re all set!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Button("Start Journaling") {
                            isComplete = true
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    OnboardingAccountSetupView(email: $email, isComplete: $isComplete, role: "student")
                }
            }
        }
        .padding()
    }
}

// To revisit onboarding from settings:
func presentStudentOnboarding() -> some View {
    StudentOnboardingView(isComplete: .constant(false))
}
