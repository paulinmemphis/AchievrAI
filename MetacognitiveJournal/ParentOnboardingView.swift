// File: ParentOnboardingView.swift
// Robust onboarding for parents

import SwiftUI

struct ParentOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @State private var email = ""
    private let pages = [
        ("Welcome, Parent!", "Support your child's growth with secure, AI-powered journaling."),
        ("Parental Controls", "You can enable controls to monitor or guide your child's journaling experience."),
        ("Privacy & Security", "Your child's data is encrypted and private. You decide what is shared."),
        ("Get Started!", "Set preferences and begin supporting your child's journey.")
    ]
    var body: some View {
        VStack {
            Spacer()
            if page < pages.count {
                OnboardingIllustrations.parent
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
                OnboardingAccountSetupView(email: $email, isComplete: $isComplete, role: "parent")
            }
        }
        .padding()
    }
}

// To revisit onboarding from settings:
func presentParentOnboarding() -> some View {
    ParentOnboardingView(isComplete: .constant(false))
}

