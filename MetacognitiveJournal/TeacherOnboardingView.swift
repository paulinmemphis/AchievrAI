// File: TeacherOnboardingView.swift
import SwiftUI
// Robust onboarding for teachers

import SwiftUI

struct TeacherOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @State private var email = ""
    private let pages = [
        ("Welcome, Teacher!", "Empower your students with reflective, AI-powered journaling."),
        ("Class Setup", "Easily onboard your class. Monitor progress and provide feedback.") ,
        ("Privacy & Analytics", "Student data is secure. You get insights, not raw entries, unless shared."),
        ("Get Started!", "Create your class and invite students.")
    ]
    var body: some View {
        VStack {
            Spacer()
            OnboardingIllustrations.teacher
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
                Link("Contact Support", destination: OnboardingSupportLinks.supportURL)
                    .font(.footnote)
                    .padding(.top, 2)
            }
            Spacer()
            HStack {
                ForEach(0..<pages.count + 1, id: \ .self) { i in
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
            } else if page == pages.count - 1 {
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
            } else {
                OnboardingAccountSetupView(email: $email, isComplete: $isComplete, role: "teacher")
            }
        }
        .padding()
    }
}

// To revisit onboarding from settings:
func presentTeacherOnboarding() -> some View {
    TeacherOnboardingView(isComplete: .constant(false))
}

