// File: OnboardingAccountSetup.swift
// Reusable account/email setup view for onboarding

import SwiftUI

struct OnboardingAccountSetupView: View {
    @Binding var email: String
    @Binding var isComplete: Bool
    var role: String
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Up Your Account")
                .font(.title2)
                .fontWeight(.bold)
            Text("Enter your email to receive updates, recover your account, or connect with your class.")
                .font(.body)
                .multilineTextAlignment(.center)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            Button("Continue") {
                isComplete = true
            }
            .disabled(email.isEmpty || !email.contains("@"))
            .frame(maxWidth: .infinity)
            .padding()
            .background(email.isEmpty || !email.contains("@") ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
